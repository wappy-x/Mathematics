# Relaxation and rounding -- the check behind the card.  Standard library only.
# Part 1: a ward rota.  Each nurse works 5 days in a row, then has 2 off.
# Part 2: two weekend teams, split by a semidefinite relaxation and a random plane.
import math, itertools
DAYS = "Mon Tue Wed Thu Fri Sat Sun".split()
NEED = [12, 11, 11, 10, 12, 8, 7]                             # nurses needed each day
PAT = [DAYS[j] + "-" + DAYS[(j + 4) % 7] for j in range(7)]   # pattern j starts on day j
A = [[1 if (i - j) % 7 < 5 else 0 for j in range(7)] for i in range(7)]  # day i, pattern j
cover = lambda x: [sum(A[i][j] * x[j] for j in range(7)) for i in range(7)]
short = lambda x: [DAYS[i] for i in range(7) if cover(x)[i] < NEED[i] - 1e-9]

def solve(M, b):                                  # Gaussian elimination; None if singular
    M = [r[:] + [c] for r, c in zip(M, b)]; n = len(M)
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        if abs(M[p][c]) < 1e-12: return None
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c: M[r] = [a - M[r][c] / M[c][c] * e for a, e in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def corners(rows, rhs, fits, score):              # every point where 7 of 14 limits are tight
    best, seen = None, 0
    for S in itertools.combinations(range(14), 7):
        x = solve([rows[s] for s in S], [rhs[s] for s in S])
        if x is not None and fits(x):
            seen += 1
            if best is None or score(x) < score(best) - 1e-9: best = x
    return best, seen

I = [[1 if i == j else 0 for j in range(7)] for i in range(7)]
x, nx = corners(A + I, NEED + [0] * 7,            # road 1: fewest nurses, fractions allowed
    lambda x: min(x) > -1e-9 and not short(x), lambda x: sum(x))
AT = [list(r) for r in zip(*A)]
y, ny = corners(AT + I, [1] * 7 + [0] * 7,        # road 2: dual prices, most demand per nurse
    lambda y: min(y) > -1e-9 and all(sum(r[i] * y[i] for i in range(7)) < 1 + 1e-9 for r in AT),
    lambda y: -sum(n * p for n, p in zip(NEED, y)))
LP, DUAL = sum(x), sum(n * p for n, p in zip(NEED, y))
print("days:", " ".join(DAYS)); print("need:", " ".join(map(str, NEED)))
print(f"nurse-days needed {sum(NEED)}; divided by 5 days a nurse: {sum(NEED) / 5:.2f}")
print(f"LP rota, best of {nx} bases in {math.comb(14, 7)} tries: " + ", ".join(f"{p} {v:.2f}" for p, v in zip(PAT, x)))
print(f"LP total {LP:.4f} = {round(3 * LP)}/3; dual prices, best of {ny} bases: " + ", ".join(f"{d} {v:.2f}" for d, v in zip(DAYS, y)))
print(f"dual total {DUAL:.4f}; floor on whole rotas: {math.ceil(LP - 1e-9)}")
assert abs(LP - DUAL) < 1e-9 and abs(LP - 43 / 3) < 1e-9          # two roads, one floor

up = [math.ceil(v - 1e-9) for v in x]; frac = sum(1 for v in x if abs(v - round(v)) > 1e-9)
near = [round(v) for v in x]
trim = up[:]
for j in range(7):                                # take nurses off while every day stays covered
    while trim[j] > 0 and not short([t - (k == j) for k, t in enumerate(trim)]): trim[j] -= 1
print(f"round up: {up} = {sum(up)} nurses; bound LP + {frac} fractional = {LP + frac:.2f}")
print(f"round to nearest: {near} = {sum(near)} nurses; short on {' '.join(short(near))}")
print(f"payroll cap of 15: round up hires {sum(up)}, {sum(up) - 15} over; the trimmed rota fits")
print(f"round up then trim: {trim} = {sum(trim)} nurses; short on {short(trim) or 'none'}")
assert not short(up) and sum(up) <= LP + frac and short(near) and not short(trim)

def rotas(total, k=7):                            # every way to share total nurses over k patterns
    if k == 1: yield (total,); return
    for v in range(total + 1):
        for rest in rotas(total - v, k - 1): yield (v,) + rest
r14 = list(rotas(14)); r15 = [r for r in rotas(15) if not short(r)]
print(f"brute force: {len(r14)} rotas of 14, {sum(not short(r) for r in r14)} cover; "
      f"{len(r15)} rotas of 15 cover")
assert not any(not short(r) for r in r14) and len(r15) > 0 and sum(trim) == 15  # OPT = 15

base = [math.floor(v + 1e-9) for v in x]; fr = [j for j in range(7) if x[j] - base[j] > 1e-9]
p = x[fr[0]] - base[fr[0]]
print(f"random rounding: base {sum(base)}, patterns {' '.join(PAT[j] for j in fr)} each up with chance {p:.4f}")
for t in (1, 2, 3, 4):                            # t independent rounds; up if any round says up
    q, cov, staff = 1 - (1 - p) ** t, 0.0, 0.0
    for bits in itertools.product((0, 1), repeat=len(fr)):
        z = base[:]; pr = 1.0
        for b, j in zip(bits, fr): z[j] += b; pr *= q if b else 1 - q
        staff += pr * sum(z); cov += pr * (not short(z))
    print(f"  rounds {t}: expected nurses {staff:.4f}, all days covered {cov:.4f}, "
          f"union bound on failure {6 * math.exp(-t):.4f}")
    assert 1 - cov <= 6 * math.exp(-t) and staff <= sum(base) + t * (LP - sum(base)) + 1e-9
    if t == 1: one = (staff, cov)
s = 20261119                                      # SplitMix64, written out, for the simulations
def rnd():
    global s; s = (s + 0x9E3779B97F4A7C15) % 2**64; z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2**53
N = 100000; hit = tot = 0
for _ in range(N):
    z = [b + (rnd() < p) if j in fr else b for j, b in enumerate(base)]; hit += not short(z); tot += sum(z)
print(f"  simulated, {N} draws of 1 round, seed 20261119: mean nurses {tot / N:.4f}, all covered {hit / N:.4f}")
assert abs(tot / N - one[0]) < 4 * math.sqrt(4 * p * (1 - p) / N) and abs(hit / N - one[1]) < 4 * math.sqrt(one[1] * (1 - one[1]) / N)

dot = lambda u, v: sum(a * b for a, b in zip(u, v))
alpha, tha = min((2 * th / (math.pi * (1 - math.cos(th))), th) for th in (k * math.pi / 200000 for k in range(1, 200001)))
def relax(E, n):                                  # brute-force best split, relaxation, dual check
    cut = lambda side: sum(side[a] != side[b] for a, b in E)
    cuts = [cut([(m >> i) & 1 for i in range(n)]) for m in range(2 ** n)]
    V = [[math.cos(1.0 * i + 0.7 * t * (i + 1)) for t in range(n)] for i in range(n)]
    for _ in range(3000):                         # each vector turns to point away from its partners
        for i in range(n):
            g = [-sum(V[b if a == i else a][k] for a, b in E if i in (a, b)) for k in range(n)]
            V[i] = [c / math.sqrt(dot(g, g)) for c in g]
    X = [[dot(u, v) for v in V] for u in V]
    u = [sum((1 - X[a][b]) / 4 for a, b in E if i in (a, b)) for i in range(n)]  # dual prices
    M = [[u[i] - sum(i in e for e in E) / 4 + 1e-9 if i == j else ((i, j) in E or (j, i) in E) / 4
          for j in range(n)] for i in range(n)]
    Lc = [[0.0] * n for _ in range(n)]; psd = True    # Cholesky of Diag(u) - L/4: works iff PSD
    for i in range(n):
        for j in range(i + 1):
            v = M[i][j] - sum(Lc[i][k] * Lc[j][k] for k in range(j))
            if i == j: psd = psd and v > 0; Lc[i][i] = math.sqrt(max(v, 1e-300))
            else: Lc[i][j] = v / Lc[j][j]
    sdp = sum((1 - X[a][b]) / 2 for a, b in E)
    expct = sum(math.acos(max(-1, min(1, X[a][b]))) / math.pi for a, b in E)
    assert psd and max(cuts) <= sdp + 1e-9 and expct >= alpha * sdp - 1e-9
    return V, X, cuts, sdp, expct, cut
E = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]  # stand-in pairs
V, X, cuts, SDP, expct, cut = relax(E, 6); best = max(cuts)
print(f"teams: {len(E)} pairs, best split {best} (brute force over {2 ** 6} splits, {cuts.count(best)} reach it)")
print(f"relaxation {SDP:.6f}, certified: Diag(u) - L/4 is PSD, for dual prices u built to sum to it")
for name, (a, b) in (("ring neighbours", (0, 1)), ("hub to ring", (5, 0))):
    th = math.acos(X[a][b])
    print(f"  {name}: angle {math.degrees(th):.2f} deg, cos {X[a][b]:.4f}, split chance {th / math.pi:.4f}, "
          f"share {(1 - X[a][b]) / 2:.4f}, ratio {th / math.pi / ((1 - X[a][b]) / 2):.4f}")
print(f"expected split {expct:.6f} >= alpha x relaxation {alpha * SDP:.6f}; alpha {alpha:.6f} at {math.degrees(tha):.2f} deg")
print(f"ratio to relaxation {expct / SDP:.6f}, to best split {expct / best:.6f}")
assert abs(alpha - 0.878567) < 1e-6 and best == 7
_, _, cr, s5, e5, _ = relax(E[:5], 5)
print(f"ring of five only: best {max(cr)}, relaxation {s5:.6f}, expected split {e5:.6f}")
assert max(cr) == 4 and abs(s5 - 2.5 * (1 - math.cos(0.8 * math.pi))) < 1e-6   # vectors 144 deg apart
hist = [0] * (len(E) + 1)
for _ in range(N):                                # road 2: random planes through the origin
    gv = [math.sqrt(-2 * math.log(1 - rnd())) * math.cos(2 * math.pi * rnd()) for _ in range(6)]
    hist[cut([dot(v, gv) > 0 for v in V])] += 1
sim = sum(k * h for k, h in enumerate(hist)) / N
print(f"simulated, {N} planes: mean split {sim:.4f}; " + ", ".join(f"{k}: {h}" for k, h in enumerate(hist) if h))
assert abs(sim - expct) < 4 * math.sqrt(sum(h * (k - sim) ** 2 for k, h in enumerate(hist)) / N / N)
for deg in range(0, 181, 15):
    th = math.radians(deg)
    print(f"chart, {deg:3d} deg: split chance {th / math.pi:.4f}, relaxation share {(1 - math.cos(th)) / 2:.4f}")
print("ALL CHECKS PASS")
