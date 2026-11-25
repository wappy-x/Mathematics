# Haar measure -- the check behind the card.  Standard library only; math.log
# appears once, as a cross-check labelled 'library'.  Groups: the positive
# reals under multiplication, the ax + b group and GL2(R).  Every size is
# found by a closed form and again by brute force (grids, covers, sampling).
import math

def ln(x):                                   # ln x = 2 atanh((x-1)/(x+1)), summed
    z = (x - 1) / (x + 1)
    s, p = 0.0, z
    for k in range(1, 800, 2):
        s, p = s + p / k, p * z * z
    return 2 * s

def mid(f, a, b, n):                         # midpoint rule with n cells
    h = (b - a) / n
    return h * sum(f(a + (i + 0.5) * h) for i in range(n))

def cover(a, b, eps):                        # Haar's count: slid copies of [1, 1+eps)
    n, x = 0, a
    while x < b:
        x, n = x * (1 + eps), n + 1
    return n

LN2, LN10 = ln(2.0), ln(10.0)
print(f"ln 2 = {LN2:.12f} (library {math.log(2):.12f}); log10 2 = {LN2 / LN10:.6f}")
print("positive reals, ordinary length dx  vs  fair size dx/x")
for a, b in [(1, 2), (2, 4), (4, 8), (5, 10)]:
    print(f"  [{a}, {b}]: dx {b - a}, dx/x closed form {ln(b / a):.6f}, "
          f"midpoint 100 cells {mid(lambda x: 1 / x, a, b, 100):.6f}, 1000 cells {mid(lambda x: 1 / x, a, b, 1000):.9f}")
for eps in [0.01, 0.001, 0.0001]:
    c12, c510, c110 = cover(1, 2, eps), cover(5, 10, eps), cover(1, 10, eps)
    print(f"  cover by [g, g(1+{eps})): [1,2] needs {c12}, [5,10] needs {c510}, [1,10] needs {c110}; ratio {c510 / c110:.6f}")
digits = [0] * 10                            # leading digits of 2^1 .. 2^1000, exact
p = 1
for k in range(1, 1001):
    p *= 2
    digits[int(str(p)[0])] += 1
frac_road = sum(1 for k in range(1, 1001) if (k * LN2 / LN10) % 1 < LN2 / LN10)
print(f"Benford: 2^1..2^1000 starting with 1: {digits[1]} by digits, {frac_road} by k log10 2 mod 1; Haar share {LN2 / LN10:.5f}")

def grid(dens, inside, a0, a1, b0, b1, n, m):   # brute force: count cells of a box
    ha, hb, tot = (a1 - a0) / n, (b1 - b0) / m, 0.0
    for i in range(n):
        a = a0 + (i + 0.5) * ha
        cnt = sum(1 for j in range(m) if inside(a, b0 + (j + 0.5) * hb))
        tot += dens(a) * cnt * hb * ha
    return tot

inE = lambda a, b: 1 <= a <= 2 and 0 <= b <= 1           # E = [1,2] x [0,1]; g = (2, 3)
in_gE = lambda a, b: inE(a / 2, (b - 3) / 2)             # g*(a,b) = (2a, 2b + 3)
in_Eg = lambda a, b: inE(a / 2, b - 1.5 * a)             # (a,b)*g = (2a, 3a + b)
left, right = (lambda a: 1 / (a * a)), (lambda a: 1 / a)
closed = {"E": (0.5, LN2), "gE": (0.5, 2 * LN2), "Eg": (0.25, LN2)}
boxes = {"E": (inE, 1, 2, 0, 1), "gE": (in_gE, 2, 4, 3, 5), "Eg": (in_Eg, 2, 4, 3, 7)}
print("ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)")
brute = {}
for name, (ins, a0, a1, b0, b1) in boxes.items():
    L = grid(left, ins, a0, a1, b0, b1, 200, 1000)
    R = grid(right, ins, a0, a1, b0, b1, 200, 1000)
    brute[name] = (L, R)
    print(f"  {name:2}: left da db/a^2 = {closed[name][0]:.6f} (grid {L:.5f}),"
          f" right da db/a = {closed[name][1]:.6f} (grid {R:.5f})")
delta = brute["Eg"][0] / brute["E"][0]
print(f"  modular function at g: left size of Eg over E = {delta:.4f}; 1/a = {1 / 2:.4f}")

class Mix:                                   # SplitMix64, seed stated, written out
    def __init__(s, seed): s.x = seed
    def u(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & (2**64 - 1)
        z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53

def inBox(X):                                # E: entries within 0.1 of the identity
    return abs(X[0] - 1) <= 0.1 and abs(X[1]) <= 0.1 and abs(X[2]) <= 0.1 and abs(X[3] - 1) <= 0.1

def sample(inside, lo, hi, n, rng):          # Monte Carlo of dX/|det X|^2 and of dX
    vol, s, s2, hits = 1.0, 0.0, 0.0, 0
    for k in range(4): vol *= hi[k] - lo[k]
    for _ in range(n):
        Y = [lo[k] + (hi[k] - lo[k]) * rng.u() for k in range(4)]
        if inside(Y):
            d = Y[0] * Y[3] - Y[1] * Y[2]
            w = 1 / (d * d)
            s, s2, hits = s + w, s2 + w * w, hits + 1
    mean, msq = s / n, s2 / n
    return vol * mean, vol * math.sqrt((msq - mean * mean) / n), vol * hits / n

# A = [[2, 1], [0, 1]], det 2.  X is stored as [x11, x12, x21, x22].
in_AE = lambda Y: inBox([(Y[0] - Y[2]) / 2, (Y[1] - Y[3]) / 2, Y[2], Y[3]])
in_EA = lambda Y: inBox([Y[0] / 2, Y[1] - Y[0] / 2, Y[2] / 2, Y[3] - Y[2] / 2])
def nu_grid(g):                              # 4-D midpoint grid on E, g cells a side
    h, tot = 0.2 / g, 0.0
    for i in range(g ** 4):
        q = [((i // g ** k) % g + 0.5) * h - 0.1 for k in range(4)]
        d = (1 + q[0]) * (1 + q[3]) - q[1] * q[2]
        tot += h * h * h * h / (d * d)
    return tot

nu16, nuE_grid = nu_grid(16), nu_grid(32)                # second cut-off: 32^4 cells
rng = Mix(2026)
runs = {"E": sample(inBox, [0.9, -0.1, -0.1, 0.9], [1.1, 0.1, 0.1, 1.1], 100000, rng),
        "AE": sample(in_AE, [1.7, 0.7, -0.1, 0.9], [2.3, 1.3, 0.1, 1.1], 100000, rng),
        "EA": sample(in_EA, [1.8, 0.8, -0.2, 0.8], [2.2, 1.2, 0.2, 1.2], 100000, rng)}
print(f"GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume {0.2 * 0.2 * 0.2 * 0.2:.4f}")
print(f"  E : dX/|det X|^2 by midpoint grid, 16^4 cells {nu16:.7f}, 32^4 cells {nuE_grid:.7f}")
for name, (nu, se, vol) in runs.items():
    print(f"  {name:2}: dX/|det X|^2 = {nu:.7f} +- {se:.7f} (100000 samples), plain dX = {vol:.7f}")
print(f"  plain dX ratio AE/E = {runs['AE'][2] / runs['E'][2]:.3f}; |det A|^2 = 4")
print(f"clock Z/12: each hour {1 / 12:.6f}; circle d(theta)/2pi: a 30-degree arc {30 / 360:.6f}")
print(f"l2, not locally compact: |e1 - e2| = {math.sqrt(2):.6f}, so balls of radius {math.sqrt(2) / 2:.6f} "
      f"round every e_k are disjoint inside one ball of radius {1 + math.sqrt(2) / 2:.6f}")
assert abs(LN2 - math.log(2)) < 1e-12 and abs(LN10 - math.log(10)) < 1e-12
assert all(abs(mid(lambda x: 1 / x, a, b, 1000) - LN2) < 1e-6 for a, b in [(1, 2), (5, 10)])
assert cover(1, 2, 1e-4) == cover(5, 10, 1e-4) and abs(cover(5, 10, 1e-4) / cover(1, 10, 1e-4) - LN2 / LN10) < 1e-4
assert digits[1] == frac_road == 301
for name in closed:                                       # grid against closed form
    assert abs(brute[name][0] - closed[name][0]) < 0.01 * closed[name][0]
    assert abs(brute[name][1] - closed[name][1]) < 0.01 * closed[name][1]
assert abs(delta - 0.5) < 0.01
assert abs(runs["E"][0] - nuE_grid) < 4 * runs["E"][1]
for name in ["AE", "EA"]:                                 # invariance, within 4 standard errors
    assert abs(runs[name][0] - nuE_grid) < 4 * runs[name][1]
assert abs(runs["AE"][2] / runs["E"][2] - 4) < 0.05
print("ALL CHECKS PASS")
