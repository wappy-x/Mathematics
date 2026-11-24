# The subgradient method -- the check behind the card.  Standard library only.
# A depot goes on a straight road with shops at km 1, 2 and 6.  f(x) is the total
# distance in km from a depot at km x to the three shops; it is minimised from km 10.
# Roads: the method under three step rules; the zero-subgradient certificate; a scan
# of the whole road; the one-step inequality at every step; the proved bounds.
import math
SHOPS = [1.0, 2.0, 6.0]
X0, XSTAR, FSTAR = 10.0, 2.0, 5.0        # start; the median and its value, certified below
R, G = abs(X0 - XSTAR), float(len(SHOPS))  # distance to the optimum; largest |subgradient|

def sq(v): return v * v
def f(x): return sum(abs(x - s) for s in SHOPS)
# Slope just right of x.  A shop within 1e-9 km counts as reached: exact moves of 1/3 km
# land on km 6, and rounding must not leave the point a hair short, on the wrong side.
def sub(x): return float(sum(1 if x >= s - 1e-9 else -1 for s in SHOPS))

def run(step, K, x=X0, fstar=FSTAR):          # fstar: the value f(x*) the check uses
    """K steps of x <- x - a_k g_k.  Returns points x_0..x_K, step sizes, one-step checks kept."""
    xs, al, kept = [x], [], 0
    for k in range(K):
        g = sub(x)
        a = step(k, x, g)
        nx = x - a * g
        lhs = sq(nx - XSTAR)                                   # one-step inequality, Step 1
        rhs = sq(x - XSTAR) - 2 * a * (f(x) - fstar) + a * a * g * g
        kept += lhs <= rhs + 1e-9
        xs.append(nx); al.append(a); x = nx
    return xs, al, kept

def best_gap(xs, K): return min(f(x) for x in xs[:K]) - FSTAR     # best of x_0 .. x_{K-1}
def bound(al): return (R * R + G * G * sum(a * a for a in al)) / (2 * sum(al))
def rises(xs): return sum(f(b) > f(a) + 1e-9 for a, b in zip(xs, xs[1:]))
def fixed(a): return lambda k, x, g: a
def polyak(fs): return lambda k, x, g: (f(x) - fs) / (g * g) if g else 0.0
def row(label, vals, d=4): print(f"{label:<46}" + " ".join(f"{v:.{d}f}" for v in vals))

h = 1e-6
left, right = (f(XSTAR) - f(XSTAR - h)) / h, (f(XSTAR + h) - f(XSTAR)) / h
row("start km 10: f, subgradient", [f(X0), sub(X0)])
row("km 2: f, slope left, slope right", [f(XSTAR), left, right])
grid = [i / 1000 for i in range(0, 12001)]
xb = min(grid, key=f)
row("scan of 12001 points, 0 to 12 km: best x, f", [xb, f(xb)])
assert abs(left + 1) < 1e-6 and abs(right - 1) < 1e-6 and left <= 0 <= right   # 0 in [-1, 1]
assert abs(xb - XSTAR) < 1e-12 and abs(f(xb) - FSTAR) < 1e-12                 # scan meets certificate

K = math.ceil(sq(R * G / 1.0))                                  # steps for a gap of 1 km
A = R / (G * math.sqrt(K))
row("R, G, R*G", [R, G, R * G])
print(f"{'steps for a guaranteed gap of 1 km, step a':<46}{K} {A:.4f}")
xs, al, kept = run(fixed(A), K)
row("fixed step: x_0 .. x_3", xs[:4])
lhs0 = sq(xs[1] - XSTAR)
rhs0 = sq(X0 - XSTAR) - 2 * A * (f(X0) - FSTAR) + A * A * G * G
row("step 0: |x_1 - x*|^2, one-step bound", [lhs0, rhs0])
k6 = next(k for k, x in enumerate(xs) if abs(x - 6.0) < 1e-9)
first = next(k for k, x in enumerate(xs) if abs(x - XSTAR) < 1e-9)
print(f"{'one-step inequality kept, of 576 steps':<46}{kept}")
print(f"{'first step within 1e-9 km of km 6, of km 2':<46}{k6} {first}")
print(f"{'steps on which f rose, of 576':<46}{rises(xs)}")
row("f(x_k), k = 40 .. 60", [f(x) for x in xs[40:61]])
row("best f so far, k = 40 .. 60", [min(f(x) for x in xs[:k + 1]) for k in range(40, 61)])
row("576 steps: best gap, proved bound", [best_gap(xs, K), bound(al)])
assert kept == K and rises(xs) > 0 and best_gap(xs, K) <= bound(al) + 1e-12
assert abs(bound(al) - R * G / math.sqrt(K)) < 1e-9                # bound(al) is RG/sqrt(K)
assert k6 == 12 and first == 12 + 1 + 33     # by hand: 12 moves of 1/3 km, 1 at km 6, 33 of 1/9
assert rises(xs) == (K - first) // 2 and best_gap(xs, K) < 1e-9 < f(xs[K - 1]) - FSTAR

gaps, bnds = [], []
for k2 in (16, 36, 144):
    x2, a2, kp = run(fixed(R / (G * math.sqrt(k2))), k2)
    gaps.append(best_gap(x2, k2)); bnds.append(bound(a2))
    assert kp == k2 and gaps[-1] <= bnds[-1]
row("K = 16, 36, 144: guarantee RG/sqrt(K)", bnds)
row("K = 16, 36, 144: best gap found", gaps)

xd, ad, kd = run(lambda k, x, g: 1 / math.sqrt(k + 1), 576)
row("a_k = 1/sqrt(k+1): best gap at 10, 100, 576", [best_gap(xd, n) for n in (10, 100, 576)])
row("  proved bound at 10, 100, 576", [bound(ad[:n]) for n in (10, 100, 576)])
row("  last point's gap at 576", [f(xd[576]) - FSTAR])
print(f"{'  steps on which f rose, of 576':<46}{rises(xd)}")
assert kd == 576 and all(best_gap(xd, n) <= bound(ad[:n]) for n in (10, 100, 576))
assert f(xd[576]) - FSTAR > best_gap(xd, 576) + 0.04            # the last point is not the best

xp, ap, kp = run(polyak(FSTAR), 2)
row("Polyak: x_0, x_1, x_2", xp)
row("Polyak: f at those points", [f(x) for x in xp])
row("Polyak: step sizes a_0, a_1", ap)
row("Polyak: |x_1 - x*|^2, promised at most", [sq(xp[1] - XSTAR), R * R - sq(f(X0) - FSTAR) / (G * G)])
assert abs(xp[2] - XSTAR) < 1e-12 and kp == 2
assert sq(xp[1] - XSTAR) <= R * R - sq(f(X0) - FSTAR) / (G * G)
row("many-variable lower bound RG/(2(1 + sqrt K))", [R * G / (2 * (1 + math.sqrt(576)))])

print("what breaks:")
xc, _, _ = run(fixed(0.7), 5000)
row("  fixed step 0.7: best gap at 50, 5000", [best_gap(xc, 50), best_gap(xc, 5000)])
row("  fixed step 0.7: x_7 .. x_10", xc[7:11])
Rs = 0.5
xr, ar, _ = run(fixed(Rs / (G * math.sqrt(K))), K)
row("  R guessed 0.5: step, x_576, gap, promised", [ar[0], xr[K], best_gap(xr, K), Rs * G / math.sqrt(K)])
x0g, _, _ = run(polyak(0.0), 100, fstar=0.0)
row("  Polyak, guess f(x*) = 0: x_0 .. x_4", x0g[:5])
row("  Polyak, guess f(x*) = 0: best gap at 100", [best_gap(x0g, 100)])
x4g, _, _ = run(polyak(4.0), 4, fstar=4.0)
row("  Polyak, guess f(x*) = 4: x_0 .. x_4", x4g)
x6, _, _ = run(polyak(6.0), 100, fstar=6.0)
row("  Polyak, guess f(x*) = 6: x_0 .. x_3, gap", x6[:4] + [best_gap(x6, 100)])
assert best_gap(xc, 5000) > 0.29 and best_gap(xr, K) > Rs * G / math.sqrt(K)
assert abs(xr[K] - 239 / 72) < 1e-9  # by hand: 192 moves of 1/48 km, 1 at km 6, 383 of 1/144
assert best_gap(x0g, 100) > 0.99 and abs(x6[-1] - 3.0) < 1e-12 and abs(x4g[4] - 1.0) < 1e-9
print("ALL CHECKS PASS")
