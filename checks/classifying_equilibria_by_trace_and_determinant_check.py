# Trace and determinant -- the check behind the card.  Only math is imported.  Four
# systems x' = Ax are classified twice: road one reads trace and determinant off the
# chart; road two steps the motion with Euler's rule from eight starts and watches it.
from math import sqrt, exp, cos, sin, pi
CASES = [("rooms", [[-2, 1], [1, -2]]), ("absorber", [[0, 1], [-5, -2]]),
         ("spring", [[0, 1], [-1, 0]]), ("saddle", [[1, 0], [0, -1]])]
STARTS = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
def eig(t, d):                           # roots of L^2 - tL + d = 0
    q = t * t - 4 * d
    if q >= 0: return (t + sqrt(q)) / 2, (t - sqrt(q)) / 2, 0.0
    return t / 2, t / 2, sqrt(-q) / 2
def chart(t, d):                         # road one: where (trace, det) sits
    if d < 0: return "saddle", "unstable"
    if t == 0: return "centre", "stable, not asymptotically stable"
    shape = "spiral" if t * t - 4 * d < 0 else "node"
    return ("stable " if t < 0 else "unstable ") + shape, ("asymptotically stable" if t < 0 else "unstable")
def euler(a, x, y, h, n):                # n small steps along the slope
    for _ in range(n):
        x, y = x + h * (a[0][0] * x + a[0][1] * y), y + h * (a[1][0] * x + a[1][1] * y)
    return x, y
def motion(a, h=0.001, n=6000):          # road two: eight starts, 6 time units
    ratios = [sqrt(sum(v * v for v in euler(a, x, y, h, n))) / sqrt(x * x + y * y) for x, y in STARTS]
    shrink, grow = sum(r < 0.5 for r in ratios), sum(r > 2 for r in ratios)
    x, y, turns = 1.0, 0.0, 0
    for _ in range(n):                   # count sign changes of x from (1, 0)
        nx, y = euler(a, x, y, h, 1)
        turns, x = turns + ((nx > 0) != (x > 0)), nx
    if shrink and grow: label = "saddle"
    elif shrink == 8 or grow == 8: label = ("stable " if shrink else "unstable ") + ("spiral" if turns >= 2 else "node")
    else: label = "centre"
    return shrink, grow, 8 - shrink - grow, turns, label
def px(t, d): return f"({180 + 30 * t:.0f}, {180 - 24 * d:.0f})"   # figure: 30 px per unit of trace, 24 per unit of det
figure = []
for name, a in CASES:
    t, d = a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]
    l1, l2, im = eig(t, d)
    for lam in (complex(l1, im), complex(l2, -im)):          # det(A - L I) = 0, from the entries
        assert abs((a[0][0] - lam) * (a[1][1] - lam) - a[0][1] * a[1][0]) < 1e-12
    ev = f"{l1:.4f} +/- {im:.4f}i" if im else f"{l1:.4f} and {l2:.4f}"
    kind, stab = chart(t, d)
    s, g, st, turns, label = motion(a)
    print(f"{name} {a}: trace {t}, det {d}, trace^2 - 4det {t * t - 4 * d}, eigenvalues {ev} -> chart: {kind}, {stab}")
    print(f"  motion, 8 starts over 6 time units: shrink {s}, grow {g}, stay {st}, sign changes {turns} -> {label}")
    assert kind == label                                       # two roads, one verdict
    figure.append(f"{name} {px(t, d)}")
closed = 20 * exp(-1) + 10 * exp(-3)
errs = [abs(euler(CASES[0][1], 30.0, 10.0, h, n)[0] - closed) for h, n in ((0.01, 100), (0.001, 1000))]
print(f"rooms, room 1 after 1 h from (30, 10): closed form {closed:.4f} C; Euler error {errs[0]:.4f} at h = 0.01, {errs[1]:.4f} at h = 0.001")
print(f"periods: absorber 2pi/2 = {pi:.4f} s, shrinking by e^-pi = {exp(-pi):.4f} each turn; spring 2pi/1 = {2 * pi:.4f} s")
print("chart spring x(t):", ", ".join(f"{cos(k / 2):.2f}" for k in range(13)))
print("chart absorber x(t):", ", ".join(f"{exp(-k / 2) * (cos(k) + 0.5 * sin(k)):.2f}" for k in range(13)))
print(f"figure, {', '.join(figure)}, parabola ends {px(-5, 6.25)} and {px(5, 6.25)}, control {px(0, -6.25)}")
r, (b1, b2, _) = sqrt(sum(v * v for v in euler(CASES[2][1], 1.0, 0.0, 0.1, 600))), eig(4, 3)
print(f"mistake 1, trace -1 read as stable: [[1, 0], [0, -2]] has det -2, a saddle; from (1, 1) x reaches e^6 = {exp(6):.2f} after 6 units")
print(f"mistake 2, Euler at h = 0.1 on the spring for 60 s: radius {r:.2f} (1.01^300 = {1.01 ** 300:.2f}); the true radius stays 1")
print(f"hypothesis dropped, det 0: [[-1, 0], [0, 0]] reads {chart(-1, 0)[0]}, yet (0, 1) goes to {euler([[-1, 0], [0, 0]], 0.0, 1.0, 0.001, 6000)}: never returns")
print(f"mistake 3, sign slip L^2 + trace L + det on the rooms: eigenvalues {b1:.4f} and {b2:.4f}, a false unstable node")
assert 8 < errs[0] / errs[1] < 12 and errs[1] < 0.01          # Euler closes on the closed form at first order
assert abs(r - 1.01 ** 300) < 1e-9 * r                         # stepping agrees with (1 + h^2)^(n/2)
print("ALL CHECKS PASS")
