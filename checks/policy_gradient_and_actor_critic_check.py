# Policy gradients and actor-critic -- the check behind the card.  Standard library only.
# Part 1: one state, two actions, softmax at (0, 0); action 1 pays 1, action 2 pays 0.
# Part 2: the 20-level reservoir of the MDP card (release 1, 2 or 3 bands; GBP thousands; maximise;
# discount 0.95).  Exact answers by elimination; random numbers from SplitMix64, seeded.
import math
from functools import reduce
from itertools import product
M64 = (1 << 64) - 1
class SplitMix64:                                  # the card's random numbers, seeded
    def __init__(self, seed): self.x = seed
    def next(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = ((self.x ^ (self.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return (self.next() >> 11) / 9007199254740992.0
def add(xs): return reduce(lambda t, x: t + x, xs, 0.0)   # plain left-to-right sum, as in Rust
def soft(h): m = max(h); e = [math.exp(x - m) for x in h]; z = add(e); return [x / z for x in e]   # softmax
def pick(pi, u):                                   # draw an action from chances pi
    a, c = 0, pi[0]
    while u >= c and a < len(pi) - 1: a += 1; c += pi[a]
    return a
f4 = lambda xs: ",".join(f"{x:.4f}" for x in xs)
# ---- part 1: the two-action example ----
gl = lambda pi, a: [(1.0 if b == a else 0.0) - pi[b] for b in range(2)]   # grad log pi(a)
def pg(th): pi = soft(th); return [add(pi[a] * (1.0 - a) * gl(pi, a)[i] for a in range(2)) for i in range(2)]
pi0, grad = soft([0.0, 0.0]), pg([0.0, 0.0])
fd = [(soft([1e-5, 0.0])[0] - soft([-1e-5, 0.0])[0]) / 2e-5, (soft([0.0, 1e-5])[0] - soft([0.0, -1e-5])[0]) / 2e-5]
print(f"bandit: chances {f4(pi0)}; theorem gradient {f4(grad)}; central difference {f4(fd)}")
for sh, b in ((0, 0.0), (0, 0.5), (10, 0.0)):      # one-play estimates: pay 1 and 0, or 11 and 10
    est = [[(1.0 - a + sh - b) * g + 0.0 for g in gl(pi0, a)] for a in range(2)]
    var = add(pi0[a] * (est[a][0] - grad[0]) ** 2 for a in range(2))
    rng = SplitMix64(11); xs = [est[pick(pi0, rng.unif())][0] for _ in range(10000)]
    m = add(xs) / 10000; v = add((x - m) ** 2 for x in xs) / 9999
    print(f"pay {1 + sh},{sh} baseline {b}: action 1 gives {f4(est[0])}, action 2 gives {f4(est[1])}; "
          f"variance {var:.4f}; 10000 draws: mean {m:.4f}, variance {v:.4f}")
    assert abs(m - grad[0]) < 4 * math.sqrt(var / 10000) + 1e-12 and abs(v - var) < 0.02 * var + 1e-12
th = [0.0, 0.0]                                    # exact gradient ascent, step 0.05, 20 steps
for _ in range(20): th = [x + 0.05 * y for x, y in zip(th, pg(th))]
asc = soft(th)[0]; print(f"exact gradient ascent, 20 steps of 0.05: chance of action 1 {asc:.4f}")
for sh, base in ((0, False), (0, True), (10, False), (10, True)):   # REINFORCE, 2000 runs
    rng, fin = SplitMix64(12), []
    for _ in range(2000):
        th = [0.0, 0.0]
        for _ in range(20):
            pi = soft(th); a = pick(pi, rng.unif()); g = gl(pi, a)
            b = pi[0] + sh if base else 0.0        # baseline: the average payment now
            th = [th[i] + 0.05 * (1.0 - a + sh - b) * g[i] for i in range(2)]
        fin.append(soft(th)[0])
    m = add(fin) / 2000; sd = math.sqrt(add((x - m) ** 2 for x in fin) / 1999)
    print(f"REINFORCE pay {1 + sh},{sh} baseline {base}: chance of action 1 mean {m:.4f}, "
          f"spread {sd:.4f}, runs below 0.5: {sum(x < 0.5 for x in fin)}")
    assert sd > 0.2 if sh and not base else abs(m - asc) < 0.01
# ---- part 2: the reservoir ----
N, G, S0, RAIN, PAY = 20, 0.95, 10, [0.1, 0.2, 0.4, 0.2, 0.1], [0.0, 40.0, 75.0, 90.0]
RMAP = [0, 1, 1, 2, 2, 2, 2, 3, 3, 4]               # a digit 0-9 gives rain with those chances
def step(s, a, w):                                 # release a + 1 bands, rain w: money, next level
    out = min(a + 1, s + w); t = min(N - 1, s + w - out)
    return PAY[out] - (100.0 if t <= 2 else 0.0), t
P = [[[0.0] * N for _ in range(3)] for _ in range(N)]; R = [[0.0] * 3 for _ in range(N)]
for s, a, w in product(range(N), range(3), range(5)): r, t = step(s, a, w); P[s][a][t] += RAIN[w]; R[s][a] += RAIN[w] * r
def solve(A, b):                                   # Gaussian elimination, partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c])); M[c], M[p] = M[p], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]
            for j in range(c, n + 1): M[i][j] -= f * M[c][j]
    x = [0.0] * n
    for i in range(n - 1, -1, -1): x[i] = (M[i][n] - add(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
def Pof(pis): return [[add(pis[s][a] * P[s][a][j] for a in range(3)) for j in range(N)] for s in range(N)]
def value(pis):                                    # exact value of a (random) rule: (I - g P) V = r
    Pp = Pof(pis); I = lambda i, j: 1.0 if i == j else 0.0
    return solve([[I(i, j) - G * Pp[i][j] for j in range(N)] for i in range(N)], [add(pis[s][a] * R[s][a] for a in range(3)) for s in range(N)])
qv = lambda V, s, a: R[s][a] + G * add(P[s][a][j] * V[j] for j in range(N))
V, k, ch = [0.0] * N, 0, 1.0
while ch >= 1e-9:                                  # value iteration from V = 0
    W = [max(qv(V, s, a) for a in range(3)) for s in range(N)]; k, ch, V = k + 1, max(abs(x - y) for x, y in zip(V, W)), W
best = [max(range(3), key=lambda a: qv(V, s, a)) for s in range(N)]
VB = value([[1.0 if a == best[s] else 0.0 for a in range(3)] for s in range(N)]); rule = "".join(str(a + 1) for a in best)
cert = max(qv(VB, s, a) - VB[s] for s in range(N) for a in range(3))
gaps = [sorted(qv(VB, s, a) for a in range(3))[2] - sorted(qv(VB, s, a) for a in range(3))[1] for s in range(N)]
print(f"value iteration: {k} sweeps; rule {rule}; V*(10) {VB[S0]:.2f}; best one-switch gain {cert:.1e}")
print("gap to second-best release, levels 0-19: " + ",".join(f"{x:.2f}" for x in gaps))
assert rule == "11111222223333333333" and cert < 1e-9 and abs(VB[S0] - V[S0]) < 1e-6
U = [[1 / 3] * 3 for _ in range(N)]; VU, Pu = value(U), Pof(U)   # policy gradient theorem at theta = 0
d = solve([[(1.0 if i == j else 0.0) - G * Pu[j][i] for j in range(N)] for i in range(N)], [1.0 * (i == S0) for i in range(N)])
thm = [[d[s] * U[s][a] * (qv(VU, s, a) - VU[s]) for a in range(3)] for s in range(N)]
Jth = lambda s, a, h: value([soft([h if (i, b) == (s, a) else 0.0 for b in range(3)]) for i in range(N)])[S0]
gap = max(abs((Jth(s, a, 1e-4) - Jth(s, a, -1e-4)) / 2e-4 - thm[s][a]) for s in range(N) for a in range(3))
print(f"uniform rule: J = V(10) {VU[S0]:.4f}; d(10) {d[S0]:.4f}; Q(10,.) {f4([qv(VU, S0, a) for a in range(3)])}")
print(f"theorem gradient at level 10: {f4(thm[S0])}; largest gap to central differences over 60: {gap:.1e}")
assert gap < 1e-4
dp = [1.0 / N] * N                                 # semi-gradient TD, straight-line critic, best rule
for _ in range(3000): dp = [add(dp[s] * P[s][best[s]][j] for s in range(N)) for j in range(N)]
X = [[1.0, (s - 10) / 10] for s in range(N)]
nx = [[add(P[s][best[s]][t] * X[t][j] for t in range(N)) for j in range(2)] for s in range(N)]
wtd = solve([[add(dp[s] * X[s][i] * (X[s][j] - G * nx[s][j]) for s in range(N)) for j in range(2)] for i in range(2)],
            [add(dp[s] * R[s][best[s]] * X[s][i] for s in range(N)) for i in range(2)])
wls = solve([[add(dp[s] * X[s][i] * X[s][j] for s in range(N)) for j in range(2)] for i in range(2)],
            [add(dp[s] * X[s][i] * VB[s] for s in range(N)) for i in range(2)])
rms = lambda w: math.sqrt(add(dp[s] * (w[0] + w[1] * X[s][1] - VB[s]) ** 2 for s in range(N)))
rng, s, w = SplitMix64(5), S0, [0.0, 0.0]
for t in range(1000000):
    r, s2 = step(s, best[s], RMAP[rng.next() % 10]); al = 0.05 / (1 + t / 100000)
    dl = r + G * (w[0] + w[1] * X[s2][1]) - (w[0] + w[1] * X[s][1]); w = [w[0] + al * dl, w[1] + al * dl * X[s][1]]; s = s2
print(f"TD line: exact fixed point {wtd[0]:.2f} + {wtd[1]:.2f} x; 1,000,000 months of TD {w[0]:.2f} + {w[1]:.2f} x")
print("TD line at levels 0,5,10,15,19: " + ",".join(f"{wtd[0] + wtd[1] * X[s][1]:.2f}" for s in (0, 5, 10, 15, 19))
      + "; true " + ",".join(f"{VB[s]:.2f}" for s in (0, 5, 10, 15, 19)))
print(f"weighted error: TD line {rms(wtd):.2f}, best line {rms(wls):.2f}, bound {rms(wls) / math.sqrt(1 - G * G):.2f}")
assert abs(w[0] - wtd[0]) < 0.01 * wtd[0] and abs(w[1] - wtd[1]) < 0.1 * wtd[1] and rms(wtd) <= rms(wls) / math.sqrt(1 - G * G)
wo, wn = 1.0, 1.0                                  # deadly triad: values w and 2w, step 0.1
for _ in range(50): wo += 0.1 * (G * 2 * wo - wo); wn += 0.1 * (G * 2 * wn - wn); wn += 0.1 * (0 - 2 * wn) * 2
print(f"triad: after 50 updates off-policy w = {wo:.2f}; on-policy w = {wn:.2e}")
def ac(months, at, seed, line=False, marks=()):   # one-step actor-critic, softmax actor
    rng, th, w, s, hist = SplitMix64(seed), [[0.0] * 3 for _ in range(N)], [0.0] * (2 if line else N), 0, []
    v = (lambda x: w[0] + w[1] * (x - 10) / 10) if line else (lambda x: w[x])
    for t in range(months + 1):
        if t in marks or t == months:
            pis = [soft(h) for h in th]; rl = [max(range(3), key=lambda a: p[a]) for p in pis]
            hist.append((t, value(pis)[S0], sum(x == y for x, y in zip(rl, best)), "".join(str(a + 1) for a in rl)))
        if t == months: return hist, pis
        if t % 50 == 0: s = rng.next() % N         # a fresh 50-month run from a random level
        pi = soft(th[s]); a = pick(pi, rng.unif())
        r, s2 = step(s, a, RMAP[rng.next() % 10])
        dl = r + G * v(s2) - v(s)                  # TD error: the critic's surprise
        for i, c in (((0, 0.01), (1, 0.01 * (s - 10) / 10)) if line else ((s, 0.05),)): w[i] += c * dl
        for b in range(3): th[s][b] += at * dl * ((1.0 if b == a else 0.0) - pi[b])
        s = s2
hist, pis = ac(5000000, 0.0001, 1, marks={0, 50000, 100000, 200000, 500000, 1000000, 2000000})
for t, v10, ok, rl in hist: print(f"actor-critic month {t}: V(10) {v10:.2f}, levels right {ok}/20, rule {rl}")
print(f"actor-critic: smallest top chance {min(max(p) for p in pis):.4f}; level 9 chances {f4(pis[9])}")
s2 = ac(5000000, 0.0001, 2, marks={200000, 1000000, 2000000})[0]; h2, hb, hl = s2[-1], ac(1000000, 0.003, 1)[0][-1], ac(5000000, 0.0001, 1, True)[0][-1]
print(f"seed 2: levels right at 200k, 1M, 2M months {s2[0][2]}, {s2[1][2]}, {s2[2][2]}; at 5M rule {h2[3]}, V(10) {h2[1]:.2f}; step 0.003, 1,000,000 months: rule {hb[3]}, V(10) {hb[1]:.2f}")
print(f"straight-line critic: rule {hl[3]}, levels right {hl[2]}/20, V(10) {hl[1]:.2f}")
assert hist[-1][3] == rule and VB[S0] - hist[-1][1] < 1.0 and h2[3] == rule
assert hb[3] != rule and hl[3] != rule and wo > 50 and wn < 1e-6
print("ALL CHECKS PASS")
