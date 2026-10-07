# Random walks on a graph -- the check behind the card.  Only math is imported.
# A six-page website where every link works both ways.  A surfer clicks one of
# the current page's links, each equally likely.  Where does the surfer spend
# time, how fast does the starting page stop mattering, and what is PageRank?
import math
MASK = (1 << 64) - 1
NAMES = ["Home", "About", "Blog", "Shop", "Contact", "FAQ"]
EDGES = [(0, 1), (0, 2), (0, 3), (0, 4), (2, 3), (2, 5), (3, 4), (3, 5)]
class Rng:                                        # SplitMix64, written out
    def __init__(self, seed):
        self.s = seed
    def below(self, k):                           # a whole number 0 .. k-1, equally likely
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return int(((z ^ (z >> 31)) >> 11) / 2.0 ** 53 * k)
step_matrix = lambda out: [[out[i].count(j) / len(out[i]) for j in range(6)] for i in range(6)]
advance = lambda p, P: [sum(p[i] * P[i][j] for i in range(6)) for j in range(6)]   # one click
tv = lambda p, q: 0.5 * sum(abs(a - b) for a, b in zip(p, q))   # total variation distance
def solve(M, b):                                  # Gaussian elimination with row swaps
    n, A = len(b), [M[i][:] + [b[i]] for i in range(len(b))]
    for c in range(n):
        r = max(range(c, n), key=lambda k: abs(A[k][c]))
        A[c], A[r] = A[r], A[c]
        for k in range(c + 1, n):
            A[k] = [x - A[k][c] / A[c][c] * y for x, y in zip(A[k], A[c])]
    x = [0.0] * n
    for c in range(n - 1, -1, -1):
        x[c] = (A[c][n] - sum(A[c][j] * x[j] for j in range(c + 1, n))) / A[c][c]
    return x
def stationary(P):                                # road two: pi P = pi, entries add to 1
    return solve([[P[j][i] - (i == j) for j in range(6)] for i in range(5)] + [[1.0] * 6], [0.0] * 5 + [1.0])
def jacobi(S):                                    # every eigenvalue of a symmetric matrix
    A = [row[:] for row in S]
    for _ in range(30):
        for p in range(5):
            for q in range(p + 1, 6):
                if abs(A[p][q]) < 1e-15:
                    continue
                th = 0.5 * math.atan2(2 * A[p][q], A[q][q] - A[p][p])
                c, s = math.cos(th), math.sin(th)
                for k in range(6):                # rotate columns p and q, then rows
                    A[k][p], A[k][q] = c * A[k][p] - s * A[k][q], s * A[k][p] + c * A[k][q]
                for k in range(6):
                    A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return sorted((A[i][i] for i in range(6)), reverse=True)
f4 = lambda xs: " ".join(f"{x:.4f}" for x in xs)
out = [[b for a, b in EDGES if a == i] + [a for a, b in EDGES if b == i] for i in range(6)]
P, deg, m = step_matrix(out), [len(o) for o in out], len(EDGES)
pi_deg = [d / (2 * m) for d in deg]               # road one: degree over twice the links
pi_sol = stationary(P)
print(f"pages {' '.join(NAMES)}; links m = {m}, 2m = {2 * m}")
print("degrees", " ".join(str(d) for d in deg))
print("pi by degree / 2m ", f4(pi_deg))
print("pi by solving     ", f4(pi_sol))
print("flow along a link, each way, pi(i)/deg(i):", f4(pi_deg[i] / deg[i] for i in range(6)))
dist, d_all, d_about = [[float(i == j) for j in range(6)] for i in range(6)], [], []
V, tv_exact = [[int(i == j) for j in range(6)] for i in range(6)], []   # road two: 12^t P^t, whole numbers
for t in range(13):                               # every start page at once, 0 to 12 clicks
    if 1 <= t <= 3:
        print(f"from About, t = {t}:", f4(dist[1]), f"TV {tv(dist[1], pi_deg):.4f}")
    d_all.append(max(tv(row, pi_deg) for row in dist))
    d_about.append(tv(dist[1], pi_deg))
    tv_exact.append(max(sum(abs(2 * m * v[j] - deg[j] * 12 ** t) for j in range(6)) for v in V) / (4 * m * 12 ** t))
    dist = [advance(row, P) for row in dist]
    V = [[sum(v[i] * (12 // deg[i]) for i in range(6) if j in out[i]) for j in range(6)] for v in V]
t_mix = next(t for t in range(13) if d_all[t] <= 0.25)
print("TV from About, t = 0..12:  ", f4(d_about))
print("worst start TV, t = 0..12: ", f4(d_all))
print(f"mixing time t_mix(1/4) = {t_mix} clicks")
S = [[P[i][j] * math.sqrt(deg[i] / deg[j]) for j in range(6)] for i in range(6)]
eig = jacobi(S)
lam = max(abs(e) for e in eig[1:])
v, x = [math.sqrt(q) for q in pi_deg], [1.0, -2.0, 3.0, -1.0, 0.5, 2.0]
for _ in range(3000):                             # road two: power iteration, top direction removed
    x = [sum(S[i][j] * x[j] for j in range(6)) for i in range(6)]
    dot = sum(a * b for a, b in zip(v, x))
    x = [a - dot * b for a, b in zip(x, v)]
    nx = math.sqrt(sum(a * a for a in x))
    x = [a / nx for a in x]
lam_pow = math.sqrt(sum(sum(S[i][j] * x[j] for j in range(6)) ** 2 for i in range(6)))
sq_eig, sq_edges = sum(e * e for e in eig), sum(2 / (deg[a] * deg[b]) for a, b in EDGES)
print("eigenvalues of P:", f4(eig))
print(f"lambda* by Jacobi {lam:.4f}, by power iteration {lam_pow:.4f}")
print(f"sum of squared eigenvalues {sq_eig:.4f}; sum over links of 2/(deg deg) {sq_edges:.4f}")
bound = [0.5 * math.sqrt(1 / pi_deg[1] - 1) * lam ** t for t in range(13)]
print("bound from About, t = 0..12:", f4(bound))
print("figure, TV from About", " ".join(f"{x:.2f}" for x in d_about) + "\nfigure, bound        ", " ".join(f"{x:.2f}" for x in bound))
rng, N, CLICKS, count = Rng(2026), 20000, 40, [0] * 6   # road three: simulated surfers
for _ in range(N):
    page = 1
    for _ in range(CLICKS):
        page = out[page][rng.below(deg[page])]
    count[page] += 1
freq = [c / N for c in count]
se = [math.sqrt(f * (1 - f) / N) for f in freq]
print(f"{N} surfers, {CLICKS} clicks from About:", f4(freq))
print("  standard errors:                  ", f4(se))
page, steps, trips = 1, 0, []
while len(trips) < N:                             # return trips to About, on one long walk
    page, steps = out[page][rng.below(deg[page])], steps + 1
    if page == 1:
        trips.append(steps)
        steps = 0
mt = sum(trips) / N
st = math.sqrt(sum((a - mt) ** 2 for a in trips) / (N - 1) / N)
print(f"mean return time to About {mt:.2f} clicks (se {st:.2f}); 1/pi = {1 / pi_deg[1]:.2f}")
D, r = 0.85, [1 / 6] * 6                          # PageRank on the same site
for _ in range(200):
    r = [(1 - D) / 6 + D * y for y in advance(r, P)]
r_sol = solve([[float(i == j) - D * P[j][i] for j in range(6)] for i in range(6)], [(1 - D) / 6] * 6)
print("PageRank d = 0.85, iterated", f4(r))
print("PageRank d = 0.85, solved  ", f4(r_sol))
one_way = out[:5] + [[0]]                         # FAQ links to Home only; every other link kept
P1, pw = step_matrix(one_way), [1 / 6] * 6
pi_one, hit = stationary(P1), solve([[float(i == j) - P[i][j] * (j != 5) for j in range(6)] for i in range(6)], [1.0] * 6)
for _ in range(500): pw = advance(pw, P1)         # road two: 500 clicks from the even spread
indeg = [sum(o.count(j) for o in one_way) for j in range(6)]
print("one-way site, true pi:     ", f4(pi_one))
print(f"one-way site, in-degree/{sum(indeg)}:", f4(k / sum(indeg) for k in indeg))
ring = step_matrix([[(k - 1) % 6, (k + 1) % 6] for k in range(6)])
lazy = [[0.5 * ring[i][j] + 0.5 * (i == j) for j in range(6)] for i in range(6)]
a, b, flat = [1.0, 0, 0, 0, 0, 0], [1.0, 0, 0, 0, 0, 0], [1 / 6] * 6
for t in range(60):
    a, b = advance(a, ring), advance(b, lazy)
print(f"ring of six, TV after 60 clicks {tv(a, flat):.4f}, after 61 {tv(advance(a, ring), flat):.4f}; lazy walk after 60 {tv(b, flat):.4f}")
assert max(abs(x - y) for x, y in zip(pi_deg, pi_sol)) < 1e-12        # formula vs solving
assert all(abs(f - q) < 4 * s for f, q, s in zip(freq, pi_deg, se))    # simulation vs formula
assert abs(mt - 2 * m / deg[1]) < 4 * st                               # return time vs 2m/deg
assert abs(lam - lam_pow) < 1e-9                                       # two roads to lambda*
assert abs(sq_eig - sq_edges) < 1e-9                                   # Jacobi vs a link count
assert all(d <= bound[t] + 1e-12 for t, d in enumerate(d_about))        # the spectral bound holds
assert all(abs(d - e) + abs(a - e) < 1e-12 for d, a, e in zip(d_all, d_about, tv_exact))   # distances, two roads; About worst
assert t_mix == next(t for t, e in enumerate(tv_exact) if e <= 0.25)    # mixing time, two roads
assert max(abs(x - y) for x, y in zip(r, r_sol)) < 1e-12               # PageRank, two roads
assert max(abs(x - y) for x, y in zip(pi_one, pw)) < 1e-12             # one-way shares, two roads
assert abs(pi_one[5] * (1 + hit[0]) - 1) < 1e-12   # road three, Kac: FAQ clicks to Home, then hit[0] clicks back on the two-way site
assert abs(min(jacobi(ring)) + 1) < 1e-9                               # the ring's eigenvalue -1
assert abs(tv(a, flat) - 0.5) + abs(tv(advance(a, ring), flat) - 0.5) < 1e-12   # parity: all on one half, which holds 1/2
print("ALL CHECKS PASS")
