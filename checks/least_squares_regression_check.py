# Least squares regression -- the check behind the card.  Standard library only.
# Six house sales: floor area in square metres, price in dollars.  The line is reached
# three ways that share no formula: centred sums, the raw-sum normal equations solved by
# Cramer's rule, and a blind golden-section search of the squared-miss bowl.  Then 2,000
# simulated markets of 50 sales each, from a SplitMix64 generator written out below.
from math import sqrt, log, cos, pi

AREA = [60.0, 70.0, 90.0, 110.0, 130.0, 140.0]
PRICE = [165000.0, 205000.0, 229000.0, 267000.0, 327000.0, 337000.0]

def centred(xs, ys):                 # road 1: slope = S_xy / S_xx, line through the mean point
    n = len(xs); xb = sum(xs) / n; yb = sum(ys) / n
    sxx = sum((x - xb) * (x - xb) for x in xs)
    sxy = sum((x - xb) * (y - yb) for x, y in zip(xs, ys))
    syy = sum((y - yb) * (y - yb) for y in ys)
    b = sxy / sxx
    return xb, yb, sxx, sxy, syy, yb - b * xb, b

def raw(xs, ys):                     # road 2: n a + (sum x) b = sum y ; (sum x) a + (sum x^2) b = sum xy
    n = len(xs); sx = sum(xs); sy = sum(ys)
    sxx = sum(x * x for x in xs); sxy = sum(x * y for x, y in zip(xs, ys))
    det = n * sxx - sx * sx
    return (sy * sxx - sx * sxy) / det, (n * sxy - sx * sy) / det, sxy / sxx

def sse(a, b, xs, ys): return sum((y - a - b * x) * (y - a - b * x) for x, y in zip(xs, ys))

def golden(f, lo, hi, steps=90):     # shrink a bracket around the bottom of a one-dip curve
    g = (sqrt(5.0) - 1.0) / 2.0
    c, d = hi - g * (hi - lo), lo + g * (hi - lo)
    fc, fd = f(c), f(d)
    for _ in range(steps):
        if fc < fd: hi, d, fd = d, c, fc; c = hi - g * (hi - lo); fc = f(c)
        else: lo, c, fc = c, d, fd; d = lo + g * (hi - lo); fd = f(d)
    return (lo + hi) / 2.0

def search(xs, ys):                  # road 3: no formula, only "try a line, score its misses"
    best_a = lambda b: golden(lambda a: sse(a, b, xs, ys), -1e6, 1e6)
    b = golden(lambda b: sse(best_a(b), b, xs, ys), -1e4, 1e4)
    return best_a(b), b

xb, yb, sxx, sxy, syy, a1, b1 = centred(AREA, PRICE)
a2, b2, b_origin = raw(AREA, PRICE)
a3, b3 = search(AREA, PRICE)
fit = [a1 + b1 * x for x in AREA]
res = [y - f for y, f in zip(PRICE, fit)]
sse1 = sse(a1, b1, AREA, PRICE)
r = sxy / sqrt(sxx * syy)
explained = sum((f - yb) * (f - yb) for f in fit)
se_b = sqrt(sse1 / (len(AREA) - 2)) / sqrt(sxx)

print("sale  area  price     d_x   d_y(k)  product(k)  fitted    residual")
for i, (x, y, f, e) in enumerate(zip(AREA, PRICE, fit, res)):
    print(f"{i + 1:>4} {x:5.0f} {y:8.0f} {x - xb:6.0f} {(y - yb) / 1000:7.0f} "
          f"{(x - xb) * (y - yb) / 1000:10.0f} {f:9.0f} {e:9.0f}")
rows = [("mean area (m2)", xb), ("mean price ($)", yb), ("S_xx (m2^2)", sxx),
        ("S_xy ($ m2)", sxy), ("S_yy ($^2)", syy),
        ("Cov(area, price), divide by n", sxy / len(AREA)), ("Var(area), divide by n", sxx / len(AREA)),
        ("1 slope, centred sums", b1), ("  intercept", a1),
        ("2 slope, raw normal equations", b2), ("  intercept", a2),
        ("3 slope, golden search", b3), ("  intercept", a3),
        ("SSE at the fit ($^2)", sse1), ("SSE at the searched line", sse(a3, b3, AREA, PRICE)),
        ("sum of residuals", sum(res)), ("sum of residual x area", sum(e * x for e, x in zip(res, AREA))),
        ("explained, S_xy^2 / S_xx ($^2)", sxy * sxy / sxx),
        ("R^2 = 1 - SSE/S_yy", 1.0 - sse1 / syy), ("R^2 = explained/S_yy", explained / syy),
        ("r, correlation", r), ("r^2", r * r), ("standard error of slope", se_b),
        ("wrong: area on price, inverted", syy / sxy), ("wrong: no intercept", b_origin),
        ("wrong: two end houses only", (PRICE[-1] - PRICE[0]) / (AREA[-1] - AREA[0])),
        ("wrong: flat line, residual sum", sum(y - yb for y in PRICE)), ("  flat line SSE", syy)]
for name, v in rows: print(f"{name:<32} {v:>18.4f}")

# ---- try changing ----
ft2 = [x * 10.7639 for x in AREA]                        # square feet in a square metre
_, _, _, _, syy_f, _, b_f = centred(ft2, PRICE)
big = PRICE[:-1] + [437000.0]
_, _, _, _, _, a_m, b_m = centred(AREA, big)
_, _, _, _, _, a_u, b_u = centred(AREA, [y + 20000.0 for y in PRICE])
print(f"try: square feet, slope {b_f:.2f}  R^2 {1.0 - sse(centred(ft2, PRICE)[5], b_f, ft2, PRICE) / syy_f:.5f}")
print(f"try: last house $437,000, slope {b_m:.2f}  intercept {a_m:.2f}")
print(f"try: every price +$20,000, slope {b_u:.2f}  intercept {a_u:.2f}")

# ---- the figure: x px = 40 + 3 (area - 50), y px = 220 - (price - 150,000) / 1,000 ----
px = lambda x: 40.0 + 3.0 * (x - 50.0)
py = lambda y: 220.0 - (y - 150000.0) / 1000.0
print("figure, points " + " ".join(f"({px(x):.0f},{py(y):.0f})" for x, y in zip(AREA, PRICE)))
print("figure, line   " + " ".join(f"({px(x):.0f},{py(a1 + b1 * x):.1f})" for x in (55.0, 145.0)) +
      " fitted " + " ".join(f"{py(f):.0f}" for f in fit) + f" mean ({px(xb):.0f},{py(yb):.0f})")

# ---- 2,000 simulated markets, 50 sales each: true line 45,000 + 2,100 area, noise sd 25,000 ----
MASK, state = (1 << 64) - 1, 2026092801
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def normal():                         # Box-Muller
    u1 = ((splitmix() >> 11) + 0.5) / 2.0 ** 53
    u2 = ((splitmix() >> 11) + 0.5) / 2.0 ** 53
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
areas = [50.0 + float(splitmix() % 101) for _ in range(50)]
slopes, bins = [], [0] * 8
for m in range(2000):
    prices = [45000.0 + 2100.0 * x + 25000.0 * normal() for x in areas]
    _, _, sx50, _, sy50, a50, b50 = centred(areas, prices)
    if m == 0:
        s50 = sse(a50, b50, areas, prices)
        print(f"market 1: slope {b50:.2f}  intercept {a50:.2f}  R^2 {1.0 - s50 / sy50:.4f}  "
              f"se {sqrt(s50 / 48.0) / sqrt(sx50):.2f}")
    slopes.append(b50)
    bins[min(7, max(0, int((b50 - 1700.0) // 100.0)))] += 1
mean_b = sum(slopes) / len(slopes)
sd_b = sqrt(sum((s - mean_b) * (s - mean_b) for s in slopes) / (len(slopes) - 1))
theory = 25000.0 / sqrt(sx50)
print(f"2000 markets: mean slope {mean_b:.2f}  se of mean {sd_b / sqrt(2000.0):.2f}  "
      f"spread {sd_b:.2f}  theory {theory:.2f}")
print("figure, slope bins 1700..2500 by 100: " + " ".join(str(c) for c in bins))

assert abs(b1 - 2100.0) < 1e-9 and abs(a1 - 45000.0) < 1e-6, "centred road vs the hand table"
assert abs(b2 - b1) < 1e-6 and abs(a2 - a1) < 1e-4, "raw normal equations vs centred sums"
assert abs(b3 - b1) < 1e-3 and abs(a3 - a1) < 0.1, "blind search lands on the formula's line"
assert abs((1.0 - sse1 / syy) - r * r) < 1e-12, "R^2 from misses equals squared correlation"
assert abs(mean_b - 2100.0) < 4.0 * sd_b / sqrt(2000.0), "simulated slopes centre on the true 2,100"
assert abs(sd_b / theory - 1.0) < 0.1, "simulated spread matches sigma / sqrt(S_xx)"
print("ALL CHECKS PASS")
