# Continuous-time chains and the M/M/1 queue -- the check behind the card.  Only math primitives.
# One server; calls arrive at 4 an hour; a service ends at rate 5 an hour.  Time is in hours.
# Roads: closed forms; Euler steps; uniformization; a generic solve of pi G = 0; the jump chain
# reweighted by holding times; seeded simulations with standard errors.
from math import exp, log, sqrt
LAM, MU, SEED = 4.0, 5.0, 20260929
RHO, MASK = LAM / MU, (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def expo(self, rate): return -log(1.0 - self.uniform()) / rate   # a holding time, in hours
def gen(cap, lam=LAM, mu=MU):          # generator G of one server with room for cap in the system
    G = [[0.0] * (cap + 1) for _ in range(cap + 1)]
    for n in range(cap + 1):
        if n < cap: G[n][n + 1] = lam
        if n > 0: G[n][n - 1] = mu
        G[n][n] = -sum(G[n])
    return G
def solve(A, b):                        # Gaussian elimination with partial pivoting
    n = len(A)
    M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        piv = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[piv] = M[piv], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            if f != 0.0:
                for k in range(c, n + 1): M[r][k] -= f * M[c][k]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][k] * x[k] for k in range(i + 1, n))) / M[i][i]
    return x
def stationary(G):                      # pi G = 0, last equation swapped for "shares add to 1"
    n = len(G)
    A = [[G[i][j] for i in range(n)] for j in range(n)]
    A[-1] = [1.0] * n
    return solve(A, [0.0] * (n - 1) + [1.0])
def unif(lam, mu, cap, times, kmax):    # p(t) = sum_k e^(-Ct) (Ct)^k / k! * p(0) K^k, K = I + G/C
    C = lam + mu
    v = [1.0] + [0.0] * cap             # start empty
    w = [exp(-C * t) for t in times]
    out = [[wi * x for x in v] for wi in w]
    for k in range(1, kmax + 1):
        v = [v[n] * (1.0 - (lam if n < cap else 0.0) / C - (mu if n > 0 else 0.0) / C)
             + (v[n - 1] * lam / C if n > 0 else 0.0) + (v[n + 1] * mu / C if n < cap else 0.0) for n in range(cap + 1)]
        for i in range(len(times)):
            w[i] *= C * times[i] / k
            out[i] = [o + w[i] * x for o, x in zip(out[i], v)]
    return out
G2 = gen(1)
exact = lambda t: LAM / (LAM + MU) * (1.0 - exp(-(LAM + MU) * t))
print("two-state G, rows idle, busy: " + "; ".join(", ".join(f"{x:.1f}" for x in r) for r in G2))
print(f"road 1, closed form, busy from idle: 6 min {exact(0.1):.4f}, 15 min {exact(0.25):.4f}, long run 4/9 = {LAM / (LAM + MU):.4f}")
print(f"half-way to 4/9 after ln 2 / 9 hours = {60 * log(2) / (LAM + MU):.2f} min; served per hour {LAM * MU / (LAM + MU):.2f}")
errs = []
for steps in (5, 10, 20, 40, 80):
    h, p = 0.25 / steps, [1.0, 0.0]
    for _ in range(steps): p = [p[0] + h * (p[0] * G2[0][0] + p[1] * G2[1][0]), p[1] + h * (p[0] * G2[0][1] + p[1] * G2[1][1])]
    errs.append(abs(p[1] - exact(0.25)))
    print(f"road 2, Euler step {60 * h:.4f} min: busy at 15 min {p[1]:.6f}, error {errs[-1]:.6f}")
assert errs[-1] < errs[0] / 10          # first-order method, step 16 times smaller
u2 = unif(LAM, MU, 1, [0.25], 40)[0][1]
print(f"road 3, uniformization, busy at 15 min: {u2:.10f}; closed form {exact(0.25):.10f}")
assert abs(u2 - exact(0.25)) < 1e-12
g, R, busy = SplitMix64(SEED), 100000, 0
for _ in range(R):
    t, s = 0.0, 0
    while True:
        t += g.expo(LAM if s == 0 else MU)
        if t > 0.25: break
        s = 1 - s
    busy += s
ph, se = busy / R, sqrt(busy / R * (1 - busy / R) / R)
print(f"road 4, simulated busy at 15 min, {R} runs: {ph:.4f} +- {se:.4f}")
assert abs(ph - exact(0.25)) < 4 * se
nu2 = stationary([[G2[i][j] / -G2[i][i] for j in range(2)] for i in range(2)])
print(f"jump chain of the two-state server, visit shares: {nu2[0]:.4f}, {nu2[1]:.4f}; divided by leaving rates and rescaled: "
      f"{nu2[0] / LAM / (nu2[0] / LAM + nu2[1] / MU):.4f}, {nu2[1] / MU / (nu2[0] / LAM + nu2[1] / MU):.4f}")
CAP, G = 119, gen(119)
pi = stationary(G)
geo = [(1 - RHO) * RHO ** n for n in range(CAP + 1)]
print("figure, road 1, geometric law per 100, n = 0..10: " + ", ".join(f"{100 * x:.2f}" for x in geo[:11]))
print("road 2, generic solve of pi G = 0 on 120 states, per 100: " + ", ".join(f"{100 * x:.2f}" for x in pi[:11]))
assert max(abs(pi[n] - geo[n]) for n in range(CAP + 1)) < 1e-9
q = [-G[i][i] for i in range(CAP + 1)]
nu = stationary([[G[i][j] / q[i] for j in range(CAP + 1)] for i in range(CAP + 1)])
tot = sum(nu[i] / q[i] for i in range(CAP + 1))
print(f"road 3, jump chain: idle share of visits {nu[0]:.4f}, of time after dividing by leaving rates {nu[0] / q[0] / tot:.4f}")
assert abs(nu[0] / q[0] / tot - (1 - RHO)) < 1e-9
L, tail = sum(n * pi[n] for n in range(CAP + 1)), 1 - sum(pi[:10])
print(f"busy {1 - pi[0]:.4f}; mean in system L: formula {RHO / (1 - RHO):.4f}, solve {L:.4f}; waiting (not in service) {L - (1 - pi[0]):.4f}")
print(f"P(X >= 5) {RHO ** 5:.4f}; P(X >= 10): formula {RHO ** 10:.4f}, solve {tail:.4f}; Little: W = L / lam = {L / LAM:.4f} h")
g, n, B, T = SplitMix64(SEED + 1), 0, 100, 1000.0
bb, bl, bt, occ = [], [], [], [[0.0] * 11 for _ in range(B)]
for b in range(B):
    t = sb = sl = st = 0.0
    while True:
        rate = LAM + (MU if n > 0 else 0.0)
        h = g.expo(rate)
        last = h >= T - t
        h = T - t if last else h
        sb, sl, st = sb + (h if n > 0 else 0.0), sl + h * n, st + (h if n >= 10 else 0.0)
        if n <= 10: occ[b][n] += h
        if last: break
        t += h
        n += 1 if n == 0 or g.uniform() < LAM / rate else -1
    bb.append(sb / T); bl.append(sl / T); bt.append(st / T)
def mse(xs):
    m = sum(xs) / len(xs)
    return m, sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
(mb, sb), (ml, sl), (mt, st) = mse(bb), mse(bl), mse(bt)
print(f"road 4, simulated {B * T:.0f} hours ({B} blocks of {T:.0f}): busy {mb:.4f} +- {sb:.4f}, L {ml:.3f} +- {sl:.3f}, P(X >= 10) {mt:.4f} +- {st:.4f}")
print("figure, road 4, simulated share of time per 100, n = 0..10: " + ", ".join(f"{100 * sum(o[k] for o in occ) / (B * T):.2f}" for k in range(11)))
print("road 4, block standard error of each share, per 100, n = 0..10: " + ", ".join(f"{100 * mse([o[k] / T for o in occ])[1]:.2f}" for k in range(11)))
assert abs(mb - RHO) < 4 * sb
assert abs(ml - RHO / (1 - RHO)) < 4 * sl
print("push lam to 4.5, 4.75, 4.9: rho " + ", ".join(f"{a / MU:.2f} gives L {a / MU / (1 - a / MU):.2f}" for a in (4.5, 4.75, 4.9)))
times = [0.0, 0.5, 1.0, 2.0, 4.0, 8.0, 12.0, 16.0, 24.0]
tr = unif(LAM, MU, 450, times, 420)
print("figure, M/M/1 from empty, busy per 100 at hours 0, 0.5, 1, 2, 4, 8, 12, 16, 24: " + ", ".join(f"{100 * (1 - p[0]):.2f}" for p in tr))
print("figure, two-state from idle, busy per 100 at the same hours: " + ", ".join(f"{100 * exact(t):.2f}" for t in times))
print(f"M/M/1 from empty, mean in system at 8 h {sum(k * x for k, x in enumerate(tr[5])):.2f}, at 24 h {sum(k * x for k, x in enumerate(tr[8])):.2f}")
un = unif(5.5, MU, 450, [12.0, 24.0], 450)
print(f"mistake, lam 5.5 > mu: formula L = {5.5 / MU / (1 - 5.5 / MU):.2f}; true mean from empty at 12 h {sum(k * x for k, x in enumerate(un[0])):.2f}, at 24 h {sum(k * x for k, x in enumerate(un[1])):.2f}")
for lam, ref, t in ((LAM, tr[5], 8.0), (LAM, tr[8], 24.0), (5.5, un[0], 12.0), (5.5, un[1], 24.0)):   # road 2 for the transient: Euler on the same 451 states
    p = [1.0] + [0.0] * 450
    for _ in range(round(500 * t)): p = [x + 0.002 * ((p[n - 1] * lam if n else 0.0) + (p[n + 1] * MU if n < 450 else 0.0) - x * ((lam if n < 450 else 0.0) + (MU if n else 0.0))) for n, x in enumerate(p)]
    gap, eu = max(abs(x - y) for x, y in zip(p, ref)), sum(k * x for k, x in enumerate(p))
    print(f"road 2 for the transient, Euler step 0.002 h, arrivals {lam:.2f}, empty to {t:.0f} h: mean in system {eu:.2f}, largest gap to uniformization in any state's chance {gap:.6f}")
    assert gap < 1e-4 and abs(eu - sum(k * x for k, x in enumerate(ref))) < 1e-3
print(f"mistake, I + G read as one-hour chances, idle row: {1 + G2[0][0]:.1f}, {G2[0][1]:.1f}; true one-hour row {1 - exact(1.0):.4f}, {exact(1.0):.4f}")
print(f"mistake, rho as the busy share with no waiting room: {RHO:.4f}; true {LAM / (LAM + MU):.4f}")
r = [24 * sqrt(pi[k] / pi[0]) for k in range(5)]
print("figure, circle radius 24 sqrt(pi_n / pi_0), n = 0..4: " + ", ".join(f"{x:.2f}" for x in r) + "; centres x 32, 102, 172, 242, 312, y 110")
print("ALL CHECKS PASS")
