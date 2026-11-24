# Birth-and-death processes -- the check behind the card.  Standard library only.
# Switchboard: 3 lines, no waiting room, calls at 4 an hour, each lasting 30 minutes on average.
# Outbreak: each case infects others at 0.3 a day and recovers at 0.2 a day.  Runaway: births at n^2 an hour.
# Roads: detailed balance; a generic solve of pi G = 0; Erlang's recursion; seeded simulations;
# the branching fixed point; Euler steps of the forward equations; an exact series for explosion.
from fractions import Fraction as F
from math import exp, log, sqrt, sinh, pi as PI
LAM, MU, C, MASK = 4, 2, 3, (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def expo(self, rate): return -log(1.0 - self.uniform()) / rate
def gen(birth, death, cap):             # birth-and-death generator on 0..cap: tridiagonal, rows add to 0
    G = [[0.0] * (cap + 1) for _ in range(cap + 1)]
    for n in range(cap + 1):
        if n < cap: G[n][n + 1] = float(birth(n))
        if n > 0: G[n][n - 1] = float(death(n))
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
def stationary(G):                      # pi G = 0 with the last equation swapped for "shares add to 1"
    n = len(G)
    A = [[G[i][j] for i in range(n)] for j in range(n)]
    A[-1] = [1.0] * n
    return solve(A, [0.0] * (n - 1) + [1.0])
def mse(xs):
    m = sum(xs) / len(xs)
    return m, sqrt(sum((x - m) * (x - m) for x in xs) / (len(xs) - 1) / len(xs))
fr = lambda xs: ", ".join(str(x) for x in xs)
G = gen(lambda n: LAM, lambda n: n * MU, C)
print("switchboard G, rows 0..3 lines busy: " + "; ".join(", ".join(f"{x:.0f}" for x in r) for r in G))
def thetas(death, top):                 # theta_n = product of birth rate / death rate along the path 0 -> n
    th = [F(1)]
    for n in range(1, top + 1): th.append(th[-1] * F(LAM, death(n)))
    return th
theta = thetas(lambda n: n * MU, C)
S = sum(theta); pi = [t / S for t in theta]
print(f"road 1, detailed balance: theta = {fr(theta)}, total {S}; pi = {fr(pi)}")
print("figure, pi per 100, n = 0..3: " + ", ".join(f"{100 * float(p):.2f}" for p in pi))
pi2 = stationary(G)
print("road 2, generic solve of pi G = 0: " + ", ".join(f"{x:.6f}" for x in pi2))
assert max(abs(x - float(p)) for x, p in zip(pi2, pi)) < 1e-12
B = [F(1)]
for c in range(1, 8): B.append(F(LAM, MU) * B[-1] / (c + F(LAM, MU) * B[-1]))
print("road 3, Erlang recursion B(c), c = 0..7: " + ", ".join(f"{float(b):.4f}" for b in B))
assert B[C] == pi[C]
print(f"all lines busy: {pi[C]} = {float(pi[C]):.4f}; lost calls per hour {float(LAM * pi[C]):.4f}; "
      f"mean lines busy {float(sum(n * p for n, p in enumerate(pi))):.4f} = a (1 - B) {float(F(LAM, MU) * (1 - B[C])):.4f}")
assert sum(n * p for n, p in enumerate(pi)) == F(LAM, MU) * (1 - B[C])
print(f"fewest lines with B under 1 percent: {min(c for c in range(8) if B[c] < F(1, 100))}")
def board(seed, fixed, hours=100000.0, nb=100):   # simulate calls; a call finding 3 lines busy is lost
    g, t, ends, seen, blk = SplitMix64(seed), 0.0, [], [0] * (C + 1), [[0, 0] for _ in range(nb)]
    while True:
        t += g.expo(LAM)
        if t >= hours: break
        ends = [e for e in ends if e > t]
        k = int(t * nb / hours)
        seen[len(ends)] += 1; blk[k][0] += 1
        if len(ends) == C: blk[k][1] += 1
        else: ends.append(t + (0.5 if fixed else g.expo(MU)))
    m, se = mse([b[1] / b[0] for b in blk])
    return [s / sum(seen) for s in seen], m, se
for seed, fixed, name in ((20261123, False, "exponential"), (20261124, True, "fixed 30-minute")):
    sh, m, se = board(seed, fixed)
    print(f"road 4, {name} calls, 100000 hours: lost share {m:.4f} +- {se:.4f}; lines busy as seen by callers, per 100: "
          + ", ".join(f"{100 * x:.2f}" for x in sh))
    assert abs(m - float(pi[C])) < 4 * se
r = F(LAM, C * MU)                      # M/M/3: the same lines, now with a waiting room; theta_n = theta_3 r^(n-3)
Z = sum(theta[:C]) + theta[C] / (1 - r)
pw, lq = theta[C] / (1 - r) / Z, theta[C] / Z * r / (1 - r) ** 2
print(f"M/M/3 with a waiting room, road 1: pi_0 = {1 / Z}, chance to wait {pw} = {float(pw):.4f}, mean queue {lq} = {float(lq):.4f}, "
      f"mean wait {float((lq + pw) / (C * MU) * 60):.2f} min, mean wait of those who wait {float((lq + pw) / (C * MU) / pw * 60):.2f} min")
Gf = [[float(x) for x in row] for row in gen(lambda n: LAM, lambda n: MU * min(n, C), 120)]
pf = solve([[Gf[i][j] for i in range(121)] for j in range(120)] + [[1.0] * 121], [0.0] * 120 + [1.0])
print(f"M/M/3, road 2, generic solve on 121 states: chance to wait {sum(pf[3:]):.4f}, mean queue {sum((n - 3) * pf[n] for n in range(3, 121)):.4f}")
assert abs(sum(pf[3:]) - float(pw)) < 1e-9 and abs(sum((n - 3) * pf[n] for n in range(3, 121)) - float(lq)) < 1e-9
b, d = 0.3, 0.2                          # the outbreak: per-case rates, per day
q = 0.0
for _ in range(500): q = (d + b * q * q) / (b + d)
print(f"outbreak, extinction from 1 case: road 1 (d/b) = {d / b:.4f}; road 2 branching fixed point {q:.4f}; from 3 cases {(d / b) ** 3:.4f}, {q ** 3:.4f}")
assert abs(q - d / b) < 1e-12
g, R, dead = SplitMix64(20261125), 20000, 0
for _ in range(R):
    n = 1
    while 0 < n < 60: n += 1 if g.uniform() < b / (b + d) else -1
    dead += n == 0
print(f"road 3, {R} simulated outbreaks from 1 case (jump chain, stop at 0 or 60): extinct {dead / R:.4f} +- {sqrt(dead / R * (1 - dead / R) / R):.4f}")
assert abs(dead / R - d / b) < 4 * sqrt(dead / R * (1 - dead / R) / R)
def p0(t, b, d): return b * t / (1 + b * t) if b == d else d * (exp((b - d) * t) - 1) / (b * exp((b - d) * t) - d)
def euler(b, d, t, N=300, h=0.002):     # forward equations p_n' = b(n-1)p_(n-1) + d(n+1)p_(n+1) - (b+d) n p_n
    p = [0.0, 1.0] + [0.0] * (N - 1)
    for _ in range(round(t / h)):
        p = [p[n] + h * ((b * (n - 1) * p[n - 1] if n > 1 else 0.0) + (d * (n + 1) * p[n + 1] if n < N else 0.0)
             - ((b + d) * n * p[n] if n < N else d * n * p[n])) for n in range(N + 1)]
    return p
for bb, dd in ((b, d), (0.25, 0.25)):
    e = euler(bb, dd, 10.0)
    print(f"road 4, Euler steps 0.002 day, b {bb:.2f}, d {dd:.2f}: extinct by day 10 {e[0]:.4f} (formula {p0(10.0, bb, dd):.4f}); "
          f"mean cases {sum(n * x for n, x in enumerate(e)):.4f} (formula e^((b-d)t) = {exp((bb - dd) * 10):.4f})")
    assert abs(e[0] - p0(10.0, bb, dd)) < 2e-3 and abs(sum(n * x for n, x in enumerate(e)) - exp((bb - dd) * 10)) < 1e-2
days = list(range(0, 61, 5))
print("figure, extinct by day 0, 5, ..., 60, per 100, b 0.3 d 0.2: " + ", ".join(f"{100 * p0(t, b, d):.2f}" for t in days))
print("figure, same days, b = d = 0.25: " + ", ".join(f"{100 * p0(t, 0.25, 0.25):.2f}" for t in days))
print(f"critical outbreak: mean stays 1, but extinct by day 100 {p0(100.0, 0.25, 0.25):.4f}, by day 1000 {p0(1000.0, 0.25, 0.25):.4f}")
ET = sum(1.0 / n ** 2 for n in range(1, 10 ** 6))
cdf = lambda t: 1 - sum(2 * (-1) ** (k + 1) * exp(-k * k * t) for k in range(1, 60))
print(f"runaway births at n^2 an hour: road 1, mean time to infinity, sum 1/n^2 = {ET:.4f}, pi^2/6 = {PI ** 2 / 6:.4f}")
assert abs(ET - PI ** 2 / 6) < 1e-5
print(f"road 2, exact series: P(T <= 0.5 h) {cdf(0.5):.4f}, P(T <= 1 h) {cdf(1.0):.4f}, P(T <= 2 h) {cdf(2.0):.4f}; E e^-T = pi / sinh pi = {PI / sinh(PI):.4f}")
g, tail, Ts = SplitMix64(20261126), sum(1.0 / n ** 2 for n in range(201, 10 ** 6)), []
for _ in range(R): Ts.append(sum(g.expo(n * n) for n in range(1, 201)) + tail)
(mT, sT), c1 = mse(Ts), sum(t <= 1.0 for t in Ts) / R
eT = mse([exp(-t) for t in Ts])
print(f"road 3, {R} simulated runs: mean T {mT:.4f} +- {sT:.4f}, P(T <= 1 h) {c1:.4f} +- {sqrt(c1 * (1 - c1) / R):.4f}, E e^-T {eT[0]:.4f} +- {eT[1]:.4f}")
assert abs(mT - PI ** 2 / 6) < 4 * sT and abs(c1 - cdf(1.0)) < 4 * sqrt(c1 * (1 - c1) / R) and abs(eT[0] - PI / sinh(PI)) < 4 * eT[1]
yp = exp(sum(log(n / (n + 1)) for n in range(1, 10 ** 6)))
print(f"Yule births at n an hour: mean hours to reach a million {sum(1.0 / n for n in range(1, 10 ** 6)):.4f}; E e^-T, product n/(n+1), to a million {yp:.6f}")
assert abs(yp - 1e-6) < 1e-10
w = thetas(lambda n: MU, C)
print(f"mistake, one death rate for all lines: B = {w[C] / sum(w)} = {float(w[C] / sum(w)):.4f}; Poisson tail P(N >= 3), mean 2: {1 - 5 * exp(-2):.4f}")
print(f"mistake, extinction from 3 cases read as d/b: {d / b:.4f}; true {(d / b) ** 3:.4f}")
print("ALL CHECKS PASS")
