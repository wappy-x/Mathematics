# Random projection card check: 30 songs with 10,000 features squashed to 100 by a
# matrix of normal draws. Roads: the real projection, the exact chi-square law of one
# squared length, Chernoff's bound above it, and a seeded simulation. Standard library.
from math import sqrt, log, cos, pi, exp, ceil
from operator import mul

MASK = (1 << 64) - 1
class SplitMix64:  # small seeded generator, explained on wing 09's simulation cards
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def unif(self): return ((self.next() >> 11) + 0.5) / 9007199254740992.0
    def normal(self):  # Box-Muller: two uniforms make one standard normal draw
        u1 = self.unif(); u2 = self.unif()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def dot(a, b): return sum(map(mul, a, b))
def sqdist(a, b): return sum((x - y) * (x - y) for x, y in zip(a, b))

def chi2_cdf(x, k):  # Pr[sum of k squared normals <= x], k even: a Poisson sum
    term, total = exp(-x / 2.0), 0.0
    for j in range(k // 2):
        total += term
        term *= (x / 2.0) / (j + 1)
    return 1.0 - total

def tail_exact(eps, k): return chi2_cdf(k * (1 - eps), k) + 1.0 - chi2_cdf(k * (1 + eps), k)
def tail_chernoff(eps, k):
    return ((1 + eps) * exp(-eps)) ** (k / 2) + ((1 - eps) * exp(eps)) ** (k / 2)

D, K, N, G = 10000, 100, 30, ("folk", "rock", "dance")
rng = SplitMix64(2026)
centres = [[rng.normal() for _ in range(D)] for _ in G]
songs = [[c + rng.normal() for c in centres[s // 10]] for s in range(N)]
genre = [s // 10 for s in range(N)]
pairs = [(a, b) for a in range(N) for b in range(a + 1, N)]
true2 = {p: sqdist(songs[p[0]], songs[p[1]]) for p in pairs}
diff01 = [x - y for x, y in zip(songs[0], songs[1])]
proj = [[0.0] * K for _ in range(N)]; pdiff = [0.0] * K
col7000 = []; first101 = []
for i in range(K):
    row = [rng.normal() for _ in range(D)]
    for s in range(N): proj[s][i] = dot(row, songs[s]) / sqrt(K)
    pdiff[i] = dot(row, diff01) / sqrt(K)
    col7000.append(row[6999]); first101.append(row[:101])
print(f"songs {N} in 3 genres, features d = {D}, kept k = {K}, pairs {len(pairs)}, seed 2026")
lin = max(abs(proj[0][i] - proj[1][i] - pdiff[i]) for i in range(K))
print(f"linearity: f(u) - f(v) against f(u - v), largest gap below 1e-9: {lin < 1e-9}")
assert lin < 1e-9
ratio = {p: sqdist(proj[p[0]], proj[p[1]]) / true2[p] for p in pairs}
for a, b in [(0, 1), (0, 10), (10, 20)]:
    t, q = sqrt(true2[(a, b)]), sqrt(sqdist(proj[a], proj[b]))
    print(f"song {a+1} ({G[genre[a]]}) to song {b+1} ({G[genre[b]]}): distance {t:.2f}, "
          f"projected {q:.2f}, squared ratio {q*q/(t*t):.4f}")
ys = list(ratio.values()); m = sum(ys) / len(ys)
sd = sqrt(sum((y - m) ** 2 for y in ys) / (len(ys) - 1))
print(f"squared ratio over {len(ys)} pairs: mean {m:.4f} sd {sd:.4f} min {min(ys):.4f} max {max(ys):.4f}")
print(f"distance ratio over {len(ys)} pairs: min {sqrt(min(ys)):.4f} max {sqrt(max(ys)):.4f}")
print(f"theory: mean 1, sd sqrt(2/k) = {sqrt(2 / K):.4f}")
groups = {}
for (a, b), y in ratio.items(): groups.setdefault((genre[a], genre[b]), []).append(y)
print("mean squared ratio by genre pair: " + ", ".join(f"{G[g]}-{G[h]} {sum(v) / len(v):.4f}" for (g, h), v in sorted(groups.items())))
assert abs(m - 1) < 0.05 and abs(sd - sqrt(2 / K)) < 0.25 * sqrt(2 / K)
edges = [0.0] + [0.6 + 0.1 * j for j in range(10)] + [99.0]
for lo, hi in zip(edges, edges[1:]):
    obs = sum(1 for y in ys if lo <= y < hi)
    exp_n = len(ys) * (chi2_cdf(K * hi, K) - chi2_cdf(K * lo, K))
    print(f"bin {lo:.1f}-{min(hi, 9):.1f}: {'#' * ((obs + 2) // 4):25} observed {obs:3d} expected {exp_n:6.1f}")
sim, T = SplitMix64(7), 20000
simy = [sum(sim.normal() ** 2 for _ in range(K)) / K for _ in range(T)]
for eps in (0.2, 0.5):
    ex, ch = tail_exact(eps, K), tail_chernoff(eps, K)
    obs = sum(1 for y in ys if abs(y - 1) > eps) / len(ys)
    sf = sum(1 for y in simy if abs(y - 1) > eps) / T
    print(f"outside 1 +/- {eps}: pairs {obs:.4f}, exact {ex:.6f}, Chernoff bound {ch:.6f}, "
          f"simulated {T} {sf:.5f}")
    assert ex <= ch, "the bound must sit above the exact tail"
    assert abs(sf - ex) <= 4 * sqrt(ex * (1 - ex) / T) + 1e-4
    lw, lf = chi2_cdf(K * (1 - eps), K), sum(1 for y in simy if y < 1 - eps) / T  # lower side alone
    assert abs(lf - lw) <= 4 * sqrt(lw * (1 - lw) / T) + 1e-4
lo_e, hi_e = 0.01, 0.99  # smallest eps whose union bound over 435 pairs is <= 0.1
for _ in range(60):
    mid = (lo_e + hi_e) / 2
    if len(pairs) * tail_chernoff(mid, K) <= 0.1: hi_e = mid
    else: lo_e = mid
worst = max(abs(y - 1) for y in ys)
ub, lb = 1.5 * exp(-0.5), 0.5 * exp(0.5)
print(f"hand, eps 0.5: upper base {ub:.6f}, to the 50th {ub ** 50:.6f}; lower base {lb:.6f}, to the 50th "
      f"{lb ** 50:.6f}; {len(pairs)} pairs x {tail_chernoff(0.5, K):.6f} = {len(pairs) * tail_chernoff(0.5, K):.4f}")
L, c5 = log(30 * 29 / 0.1), 0.5 ** 2 / 2 - 0.5 ** 3 / 3
print(f"hand, n = 30: ln(870/0.1) = {L:.4f}, c(0.5) = {c5:.6f}, k = {ceil(2 * L / c5)}")
print(f"union bound, k = {K}, {len(pairs)} pairs, failure 0.1: eps {hi_e:.4f}; run's worst {worst:.4f}")
assert worst <= hi_e

def nearest(vecs, s):
    return min((t for t in range(N) if t != s), key=lambda t: sqdist(vecs[s], vecs[t]))
p4 = [[proj[s][i] * sqrt(K) / 2.0 for i in range(4)] for s in range(N)]
nn0 = [nearest(songs, s) for s in range(N)]
print(f"before: nearest song in own genre {sum(1 for s in range(N) if genre[nn0[s]] == genre[s])}/{N}")
for name, vecs in (("k = 100", proj), ("k = 4", p4)):
    nn = [nearest(vecs, s) for s in range(N)]
    same_g = sum(1 for s in range(N) if genre[nn[s]] == genre[s])
    same_s = sum(1 for s in range(N) if nn[s] == nn0[s])
    print(f"{name}: nearest song in own genre {same_g}/{N}, same nearest song as before {same_s}/{N}")
    if name == "k = 100": assert same_g == N
r4 = [sqdist(p4[a], p4[b]) / true2[(a, b)] for a, b in pairs]
print(f"k = 4: squared ratio min {min(r4):.4f} max {max(r4):.4f}")
print(f"no 1/sqrt(k) scale: mean squared ratio {m * K:.2f}")
e = [0.0] * D; e[6999] = 10.0  # two versions of one song, 10 apart in feature 7000 only
keep100 = sqrt(sum((sqrt(D / K) * x) ** 2 for x in e[:K]))
jump = sqrt(sum((10.0 * c / sqrt(K)) ** 2 for c in col7000))
print(f"pair 10 apart in feature 7000 only: first 100 features keep {keep100:.2f}, random keeps {jump:.2f}")
for n in (30, 1000, 10**6):  # counted multiply-adds for every pair's distance
    direct, viaproj = n * (n - 1) // 2 * D, n * K * D + n * (n - 1) // 2 * K
    print(f"cost, n = {n}: all pairs directly {direct}, project then compare {viaproj}")
print("dims needed, failure 0.1: n eps=0.5 eps=0.2")
for e10 in range(1, 10):
    n = 10.0 ** e10
    ks = [ceil(2 * log(n * (n - 1) / 0.1) / (e * e / 2 - e ** 3 / 3)) for e in (0.5, 0.2)]
    print(f"n=1e{e10} {ks[0]} {ks[1]}")
A = [r[:100] for r in first101]; bvec = [-r[100] for r in first101]
for c in range(100):  # Gaussian elimination: a pair chosen after seeing the matrix
    piv = max(range(c, 100), key=lambda r: abs(A[r][c]))
    A[c], A[piv] = A[piv], A[c]; bvec[c], bvec[piv] = bvec[piv], bvec[c]
    for r in range(c + 1, 100):
        f = A[r][c] / A[c][c]
        for j in range(c, 100): A[r][j] -= f * A[c][j]
        bvec[r] -= f * bvec[c]
z = [0.0] * 101; z[100] = 1.0
for c in range(99, -1, -1):
    z[c] = (bvec[c] - sum(A[c][j] * z[j] for j in range(c + 1, 100))) / A[c][c]
fz = sqrt(sum(dot(first101[i], z) ** 2 for i in range(K)) / K)
nz = sqrt(sum(v * v for v in z))
print(f"pair chosen after the matrix: distance {nz:.2f}, projected below 1e-9: {fz < 1e-9}")
assert fz < 1e-9
print("ALL CHECKS PASS")
