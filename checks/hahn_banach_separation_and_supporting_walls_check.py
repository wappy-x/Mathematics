# Separation: a wall between a budget set and a cheaper bundle.  Standard library only.
# Every number on the card is printed here.  The worst-case price, the gauge, the polar
# and the bipolar are built by hand; Fractions keep the exact answers exact.
from fractions import Fraction as F
import math

def f4(x): return f"{float(x):.4f}"
def bill(q, x): return sum(a * b for a, b in zip(q, x))
def worst_price(x, qbar, w):  # road 1: high price where you buy, low where you sell
    return [qb + (wb if t >= 0 else -wb) for qb, wb, t in zip(qbar, w, x)]
def gauge(x, qbar, w, m, cap):  # s(x): the smallest t > 0 with x / t in the budget set
    return max(F(0), bill(worst_price(x, qbar, w), x) / m, max(abs(t) for t in x) / cap)

# ---- two hours, night then evening: pounds per MWh; MWh per hour, negative = sold back ----
QBAR, W, M, CAP, X0 = [F(50), F(150)], [F(10), F(30)], F(500), F(12), [F(11), F(-1)]
QS = worst_price(X0, QBAR, W)
fore, high, worst = bill(QBAR, X0), bill([a + b for a, b in zip(QBAR, W)], X0), bill(QS, X0)
grid = max(bill([QBAR[0] - W[0] + W[0] * i / 10, QBAR[1] - W[1] + W[1] * j / 10], X0)
           for i in range(21) for j in range(21))  # road 2: try 441 price lists in the band
assert worst == grid == 540 and fore == 400 and high == 480
s0 = gauge(X0, QBAR, W, M, CAP)
lo, hi = 0.5, 4.0  # road 3: bisection on the scale t, membership tested by the price grid
for _ in range(60):
    t = (lo + hi) / 2
    xs = [float(v) / t for v in X0]
    ok = max(bill([40 + i, 120 + 3 * j], xs) for i in range(21) for j in range(21)) <= 500
    (hi, lo) = (t, lo) if ok and max(abs(v) for v in xs) <= 12 else (hi, t)
assert s0 == F(27, 25) and abs(hi - 1.08) < 1e-12
sup = [v / s0 for v in X0]
assert bill(QS, sup) == M and max(abs(v) for v in sup) <= CAP
r = min(M / max(a + b for a, b in zip(QBAR, W)), CAP)
phi = [q / M for q in QS]
assert abs(float(bill(phi, X0)) - hi) < 1e-12  # the wall meets the bisection gauge at x0
print(f"forecast bill {f4(fore)}, all-high bill {f4(high)}, worst bill {f4(worst)} (grid of 441: {f4(grid)})")
print(f"worst price list ({f4(QS[0])}, {f4(QS[1])}); over budget by {f4(worst - M)}")
print(f"gauge s(x0) = {f4(s0)} (bisection {hi:.4f}); supporting point ({f4(sup[0])}, {f4(sup[1])})")
print(f"phi = ({f4(phi[0])}, {f4(phi[1])}) per MWh; phi(x0) = {f4(bill(phi, X0))}; ball radius {f4(r)}; "
      f"norm {f4(max(map(abs, phi)))} <= 1/r = {f4(1 / r)}")
state, bad = 2026, 0
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return (z ^ (z >> 31)) / 2**64
for _ in range(2000):  # Hahn-Banach's promise: phi never exceeds the gauge
    x = [F(int(40000 * splitmix()) - 20000, 1000) for _ in range(2)]
    bad += bill(phi, x) > gauge(x, QBAR, W, M, CAP)
assert bad == 0
print(f"phi <= s at 2000 random schedules (SplitMix64 seed 2026): {bad} failures")

# ---- convexity: two plans, their halfway mix, and 121 walls that try to split them ----
pair = [(F(10), F(0)), (F(0), F(4))]
mix = tuple((u + v) / 2 for u, v in zip(*pair))
tried = [(F(i), F(j)) for i in range(-5, 6) for j in range(-5, 6)]
split = sum(bill(q, mix) > max(bill(q, p) for p in pair) or bill(q, mix) < min(bill(q, p) for p in pair)
            for q in tried)
print(f"convexity: plans ({f4(pair[0][0])}, {f4(pair[0][1])}) and ({f4(pair[1][0])}, {f4(pair[1][1])}), "
      f"halfway mix ({f4(mix[0])}, {f4(mix[1])}); of {len(tried)} walls, {split} put the mix beyond both plans")
assert mix == (5, 2) and split == 0

# ---- the bipolar: walls a.x <= 1 -> corners -> polar -> walls again ----
def corners(walls):
    pts = set()
    for i, (a, b) in enumerate(walls):
        for c, d in walls[i + 1:]:
            det = a * d - b * c
            if det != 0:
                p = ((d - b) / det, (a - c) / det)
                if all(u * p[0] + v * p[1] <= 1 for u, v in walls): pts.add(p)
    return sorted(pts, key=lambda p: math.atan2(p[1], p[0]))
def hull(pts):
    pts, out = sorted(set(pts)), []
    for seq in (pts, pts[::-1]):
        part = []
        for p in seq:
            while len(part) > 1 and (part[-1][0] - part[-2][0]) * (p[1] - part[-2][1]) - (part[-1][1] - part[-2][1]) * (p[0] - part[-2][0]) <= 0:
                part.pop()
            part.append(p)
        out += part[:-1]
    return sorted(out, key=lambda p: math.atan2(p[1], p[0]))
walls = [(a / M, b / M) for a in (F(40), F(60)) for b in (F(120), F(180))] + [(1 / CAP, F(0)), (-1 / CAP, F(0)), (F(0), 1 / CAP), (F(0), -1 / CAP)]
C, polar = corners(walls), hull(walls)  # the polar as the hull of the 8 walls
polar2 = corners(C)  # road two: every functional that scores the corners of C at most 1
assert len(C) == 6 and len(polar) == 6 and polar2 == polar and corners(polar2) == C
print("budget set corners: " + ", ".join(f"({f4(a)}, {f4(b)})" for a, b in C))
print(f"8 walls, {len(polar)} of them corners of the polar; the polar built from the {len(C)} corners has "
      f"{len(polar2)}, the same; their walls give back the same {len(C)} corners")

# ---- a week: 168 hourly prices (illustrative), band 20 per cent, budget 10000 pounds ----
day = [50] * 6 + [90] * 10 + [150] * 4 + [70] * 4
qw = [F(day[h % 24] - (10 if h >= 120 else 0)) for h in range(168)]
ww = [q / 5 for q in qw]
xw = [F(3) if h % 24 < 5 else F(-5, 4) if 16 <= h % 24 < 20 else F(1) for h in range(168)]
for n, mb in ((24, None), (168, F(10000))):
    q, w, x = qw[:n], ww[:n], xw[:n]
    vals = bill(q, x), bill([a + b for a, b in zip(q, w)], x), bill(worst_price(x, q, w), x)
    line = f"N = {n}: forecast {f4(vals[0])}, all-high {f4(vals[1])}, worst {f4(vals[2])}"
    if mb:
        sw = gauge(x, q, w, mb, CAP)
        line += f"; budget {f4(mb)}, gauge {f4(sw)}, scale to {f4(100 / sw)} per cent"
        assert vals == (8110, 9732, 11792) and sum(t < 0 for t in x) == 28
    print(line)
print(f"hours priced at the low end in the week: {sum(t < 0 for t in xw)}")

# ---- infinite hours: what the finite rehearsal hides ----
direct = sum(1 / t**2 for t in range(10**6, 0, -1)) + 1 / (10**6 + 0.5)
for n in (24, 168, 1000, 10000):
    tail = math.pi**2 / 6 - sum(1 / t**2 for t in range(1, n + 1))
    tail2 = direct - sum(1 / t**2 for t in range(1, n + 1))
    assert abs(tail - tail2) < 1e-9 and abs(n * tail - 1) < 1 / n
    print(f"dense set, N = {n}: best margin {tail:.6f} MWh, N x margin {n * tail:.4f}")
for n in (24, 168, 1000):
    best = max(100 * (1 - 1 / t) for t in range(1, n + 1))
    assert abs(best - 100 * (1 - 1 / n)) < 1e-12
    print(f"sup price 100 never reached, N = {n}: best 1 MWh placement {best:.4f}")
print("curve v >= 1/u against v <= 0, gap at u = 1, 10, 100, 1000: "
      + ", ".join(f"{1 / x:.4f}" for x in (1, 10, 100, 1000)))

# ---- try changing ----
for label, w, m, x in (("band 30 per cent", [F(15), F(45)], M, X0), ("sell 3 MWh", W, M, [F(11), F(-3)]),
                       ("budget 550", W, F(550), X0), ("buy 13 MWh", W, M, [F(13), F(-1)])):
    print(f"try {label}: worst bill {f4(bill(worst_price(x, QBAR, w), x))}, gauge {f4(gauge(x, QBAR, w, m, CAP))}")

px = lambda a, b: f"{220 + 15 * float(a):.2f} {220 - 15 * float(b):.2f}"
print("figure, " + ", ".join(px(a, b) for a, b in C) + f", x0 {px(*X0)}, support {px(*sup)}, "
      f"wall {px(4, F(500 - 240, 120))} {px(13, F(500 - 780, 120))}, all-high {px(4, F(500 - 240, 180))} {px(13, F(500 - 780, 180))}")
print("ALL CHECKS PASS")
