# Quasi-Monte Carlo and sparse grids -- the check behind the card.  Standard
# library only; every point set is built here.  First card 06's basket call, then a
# smooth basket: five assets at $100, each one-year log return spread evenly over
# -30% to +30% (illustrative), wanted the mean of their geometric average.  Roads:
# closed forms; random; van der Corput and Halton; Sobol, plain and shifted; a sparse grid.
import math
C, D5 = 0.06, 5                            # each log return is C * 5 * (2u - 1)
M1, M2 = math.sinh(C) / C, math.sinh(2 * C) / (2 * C)   # mean and mean square of one factor
EXACT = 100 * M1 ** D5                     # closed form: five independent factors
SIGMA = 100 * math.sqrt(M2 ** D5 - M1 ** 10)
def basket(u): return 100 * math.exp(C * sum(2 * x - 1 for x in u))
M64 = (1 << 64) - 1
def splitmix(seed):                        # SplitMix64, written out: random road
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & M64
        z = ((seed ^ (seed >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        yield ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
def radical_inverse(i, p):                 # mirror the base-p digits of i
    x, f = 0.0, 1.0 / p
    while i: x, i, f = x + (i % p) * f, i // p, f / p
    return x
PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]
def halton(i, d): return [radical_inverse(i, p) for p in PRIMES[:d]]
BITS, POLY = 30, [(1, 0, [1]), (2, 1, [1, 3]), (3, 1, [1, 3, 1]), (3, 2, [1, 1, 1])]
V = [[1 << (BITS - k) for k in range(1, BITS + 1)]]   # dimension 1: halves
for s, a, m in POLY:                       # dimensions 2-5: Joe-Kuo's numbers
    for k in range(s, BITS):
        new = m[k - s] ^ (m[k - s] << s)
        for t in range(1, s): new ^= (m[k - t] << t) if (a >> (s - 1 - t)) & 1 else 0
        m.append(new)
    V.append([m[k] << (BITS - 1 - k) for k in range(BITS)])
def sobol(i):                              # XOR the direction numbers i's bits pick
    out = []
    for v in V:
        x, k, j = 0, 0, i
        while j: x, k, j = (x ^ v[k]) if j & 1 else x, k + 1, j >> 1
        out.append(x / 2.0 ** BITS)
    return out
def mean(f, pts): return sum(f(u) for u in pts) / len(pts)
def rule(l):                               # midpoint, then nested trapezoid: 1, 3, 5, 9, 17 points
    if l == 1: return [(0.5, 1.0)]
    n = 2 ** (l - 1)
    return [(j / n, (0.5 if j in (0, n) else 1.0) / n) for j in range(n + 1)]
def levels(total, d):                      # every list of d levels >= 1 summing to total
    if d == 1: yield [total]; return
    for a in range(1, total - d + 2):
        for rest in levels(total - a, d - 1):
            yield [a] + rest
def smolyak(k, d):                         # combination form; weights merged per point
    pts = {}
    for s in range(max(d, k + 1), k + d + 1):
        coef = (-1) ** (k + d - s) * math.comb(d - 1, k + d - s)
        for lv in levels(s, d):
            grid = [((), coef)]
            for l in lv:
                grid = [(x + (p,), w * q) for x, w in grid for p, q in rule(l)]
            for x, w in grid: pts[x] = pts.get(x, 0.0) + w
    return sorted(pts.items())
def new_points(l): return 1 if l == 1 else 2 if l == 2 else 2 ** (l - 2)
def count_by_formula(k, d):                # second road to the sparse-grid size
    return sum(math.prod(new_points(l) for l in lv) for s in range(d, k + d + 1) for lv in levels(s, d))
def sgrid(k, f, d=D5): return sum(w * f(x) for x, w in smolyak(k, d))
N, rnd = 1024, splitmix(2026)              # rnd: the random road
sob, hal = [sobol(i) for i in range(N)], [halton(i, D5) for i in range(N)]   # the two even point sets
CALL = 8 * sum((-1) ** j * math.comb(D5, j) * max(2.5 - j, 0) ** 6 for j in range(6)) / 720   # card 06
def call(u): return 100 * max(0.8 + 0.4 * sum(u) / D5 - 1, 0.0)   # card 06's $100 basket call
grid10 = [[(i // 10 ** a % 10 + 0.5) / 10 for a in range(D5)] for i in range(10 ** D5)]   # card 06's grid, 10 per axis
ec = [mean(call, pts) - CALL for pts in (sob, hal, grid10)] + [sgrid(4, call) - CALL]   # Sobol, Halton, grid, sparse
se_c = math.sqrt(64 * 5 / 24 - CALL ** 2) / math.sqrt(N)        # card 06's sigma over root N
print(f"card 06's call: exact {CALL:.6f}, random SE {se_c:.6f}; Sobol {ec[0]:+.6f}, {se_c / abs(ec[0]):.1f} times smaller;"
      f" Halton {ec[1]:+.6f}; 100000-point grid {ec[2]:+.6f}; 801-point sparse grid {ec[3]:+.6f}")
print(f"basket exact mean {EXACT:.9f}; spread of one draw sigma {SIGMA:.6f}; variance share from single"
      f" coordinates {D5 * M1 ** 8 * (M2 - M1 * M1) * 1e4 / SIGMA ** 2:.4f}")
err_r = mean(basket, [[next(rnd) for _ in range(D5)] for _ in range(N)]) - EXACT
err_h = mean(basket, hal) - EXACT
err_s = mean(basket, sob) - EXACT
err_g = sgrid(4, basket) - EXACT
h17 = sum((0.5 if j in (0, 16) else 1.0) / 16 * math.exp(C * (2 * j / 16 - 1)) for j in range(17))
err_f = 100 * h17 ** D5 - EXACT            # full 17^5 grid, as a product of 1-D sums
se = SIGMA / math.sqrt(N)
print(f"N = {N}, error of each road:  random standard error {se:.6f}, this run {err_r:+.6f}")
print(f"  Halton {err_h:+.6f}   Sobol {err_s:+.6f}   Sobol beats the standard error {se / abs(err_s):.1f} times")
print(f"  random points needed to match Sobol: {SIGMA ** 2 / err_s ** 2:.0f}")
print(f"  sparse grid level 4, {len(smolyak(4, D5))} points"
      f" ({sum(w < 0 for _, w in smolyak(4, D5))} of weight below 0) {err_g:+.6f};"
      f" full 17-per-side grid, {17 ** D5} points {err_f:+.6f}")
print("N       random SE   Halton      Sobol       log10 N  log10 |error|: SE, Halton, Sobol")
rows = [(n, SIGMA / math.sqrt(n), mean(basket, [halton(i, D5) for i in range(n)]) - EXACT,
         mean(basket, [sobol(i) for i in range(n)]) - EXACT) for n in (64, 256, 1024, 4096, 16384)]
for n, *row in rows:
    print(f"{n:<8d}{row[0]:<12.6f}{row[1]:<+12.6f}{row[2]:<+12.6f}{math.log10(n):<9.2f}"
          + "  ".join(f"{math.log10(abs(v)):.2f}" for v in row))
order = [math.log(abs(rows[i][j] / rows[i + 1][j])) / math.log(4) for j in (2, 3) for i in range(4)]
print("observed order per quadrupling, Halton:", " ".join(f"{v:.2f}" for v in order[:4]),
      "| Sobol:", " ".join(f"{v:.2f}" for v in order[4:]))
def dstar(x): return max(max((i + 1) / len(x) - v, v - i / len(x)) for i, v in enumerate(sorted(x)))  # exact, 1-D
print("van der Corput, first 8:", " ".join(f"{radical_inverse(i, 2):g}" for i in range(8)),
      "| Halton base 3:", " ".join(f"{radical_inverse(i, 3):.4f}" for i in range(4)))
vdc, ones, rnd1 = dstar([radical_inverse(i, 2) for i in range(1000)]), bin(1000).count("1"), splitmix(7)
d_r = dstar([next(rnd1) for _ in range(1000)])
print(f"N = 1000: van der Corput D* {vdc:.6f}, bound {ones}/N = {ones / 1000:.6f},"
      f" ratio {vdc * 1000 / ones:.3f}; random D* {d_r:.6f}")
worst = max(dstar([radical_inverse(i, 2) for i in range(n)]) * n / bin(n).count("1") for n in range(1, 1025))
print(f"worst D* / bound over N = 1 to 1024: {worst:.3f}")
def upper_root(d, L):                      # fixed point of L = 2d ln L, upper root; L is ln N
    for _ in range(200): L = 2 * d * math.log(L)
    return L
print("bound shape (ln N)^d / N falls below 1 / sqrt(N) only after log10 N ="
      + "".join(f"  d {d}: {upper_root(d, 4.0 * d * d) / math.log(10):.1f}" for d in (2, 3, 5, 10, 20)))
print("g = product of |4u - 2|, mean 1, N = 1024: d, Halton error, random SE, ratio, single-coordinate share")
for d in (1, 2, 5, 10, 20):
    g = mean(lambda u: math.prod(abs(4 * x - 2) for x in u), [halton(i, d) for i in range(N)])
    gse = math.sqrt(((4 / 3) ** d - 1) / N)
    print(f"  {d:<3d}{g - 1:<+15.6f}{gse:<10.6f}{abs(g - 1) / gse:<10.3f}{d / 3 / ((4 / 3) ** d - 1):.4f}")
print("sparse grid level: points in 5 dims (enumerated, by formula), full grid")
for k in range(6):
    print(f"  {k}  {len(smolyak(k, D5)):>5d}{count_by_formula(k, D5):>6d}{(2 ** k + 1 if k else 1) ** D5:>10d}")
fig = splitmix(11)
print(f"figure, random 0: ({next(fig):.4f},{next(fig):.4f}); Sobol 0-3:", " ".join(f"({a:g},{b:g})"
      for a, b in [sobol(i)[:2] for i in range(4)]), f"| sparse 2-D level 4: {len(smolyak(4, 2))} of 289")
T = 2.5 + math.log(1.02) / (2 * C)          # digital: pays 1 if the average > $102
irwin = 1 - sum((-1) ** j * math.comb(D5, j) * max(T - j, 0) ** D5 for j in range(6)) / 120
digital = lambda u: 1.0 if sum(u) > T else 0.0
dig, dig_s = sgrid(4, digital), mean(digital, sob)
print(f"mistakes: digital exact {irwin:.6f}, sparse grid 801 points {dig:.6f}, Sobol {dig_s:.6f}")
sh = splitmix(99)                          # random shifts: move every Sobol point one random step, wrap round
rq = [mean(basket, [[(x + y) % 1 for x, y in zip(p, dl)] for p in sob]) - EXACT
      for dl in [[next(sh) for _ in range(D5)] for _ in range(10)]]
m_rq = sum(rq) / 10; s_rq = math.sqrt(sum((v - m_rq) ** 2 for v in rq) / 90)   # mean, and its standard error
print(f"Sobol, 10 random shifts: mean error {m_rq:+.6f}, standard error {s_rq:.6f}")
assert all(sorted(int(sobol(i)[j] * N) for i in range(N)) == list(range(N)) for j in range(D5))
assert abs(err_s) < se / 4 and abs(err_r) < 3 * se and abs(err_g) < abs(err_s) / 4 and abs(ec[0]) < min(se_c / 10, abs(ec[2]))
assert abs(m_rq) < 4 * s_rq and s_rq < se / 4                    # shifted Sobol: an honest bar, still narrow
assert all(0.9 < v < 1.1 for v in order[4:])                     # near one over N
assert abs(err_g - err_f) < 0.05 * abs(err_f)                    # 801 points match 1.4 million
assert all(len(smolyak(k, D5)) == count_by_formula(k, D5) for k in range(6))
assert worst <= 1.0 and vdc < d_r / 5                            # D* <= popcount(N) / N
assert abs(dig - irwin) > 0.5 and abs(dig_s - irwin) < 0.01 and abs(ec[3]) > 0.5   # jump, kink: sparse grid fails
print("ALL CHECKS PASS")
