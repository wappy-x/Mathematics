# First fundamental form -- the check behind the card.  Standard library only.
# Roof: the saddle middle of a stadium roof, z = 30 + (u^2 - v^2)/120 metres.
# Walk: straight on the plan from the centre (0, 0) to the corner P = (30, 20).
# Every number on the card is printed here.  No geometry package is used.
from math import sqrt, asinh, acos, degrees, cos, sin, pi

def plan(u, v):            # chart 1: u metres east, v metres north on the plan
    return (u, v, 30.0 + (u * u - v * v) / 120.0)

def rule(p, q):            # chart 2: diagonal seams, u = p + q, v = p - q
    return (p + q, p - q, 30.0 + p * q / 30.0)

def polar(rho, th):        # chart 3: distance and angle from the centre
    return plan(rho * cos(th), rho * sin(th))

def dot(a, b): return sum(x * y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))

def efg(chart, a, b, h=1e-5):
    # E, F, G from the patch alone: tangent arrows by central differences, then dots
    ru = tuple((x - y) / (2 * h) for x, y in zip(chart(a + h, b), chart(a - h, b)))
    rv = tuple((x - y) / (2 * h) for x, y in zip(chart(a, b + h), chart(a, b - h)))
    return dot(ru, ru), dot(ru, rv), dot(rv, rv)

def form(E, F, G, x, y): return E * x[0] * y[0] + F * (x[0] * y[1] + x[1] * y[0]) + G * x[1] * y[1]

def length(chart, path, vel, n=200, fterm=2.0, efg_chart=None):
    # Simpson's rule on ds/dt = sqrt(E u'^2 + 2F u'v' + G v'^2), t from 0 to 1
    def speed(t):
        E, F, G = efg(efg_chart or chart, *path(t))
        a, b = vel
        return sqrt(E * a * a + fterm * F * a * b + G * b * b)
    h = 1.0 / n
    s = speed(0) + speed(1) + sum((4 if k % 2 else 2) * speed(k * h) for k in range(1, n))
    return s * h / 3

def chords(n):             # road 3: a tape laid along n straight pieces in space
    pts = [plan(30.0 * k / n, 20.0 * k / n) for k in range(n + 1)]
    return sum(sqrt(dot(sub(b, a), sub(b, a))) for a, b in zip(pts, pts[1:]))

def angle(E, F, G, x, y):
    return degrees(acos(form(E, F, G, x, y) / sqrt(form(E, F, G, x, x) * form(E, F, G, y, y))))

def tape_angle(h):         # road 3 for the angle: three tape lengths and the law of cosines
    P, A, B = plan(30, 20), plan(30 + h, 20), plan(30, 20 + h)
    a, b, c = (sqrt(dot(sub(X, Y), sub(X, Y))) for X, Y in ((A, P), (B, P), (A, B)))
    return degrees(acos((a * a + b * b - c * c) / (2 * a * b)))

walk1 = lambda t: (30.0 * t, 20.0 * t)       # chart 1: velocity (30, 20)
walk2 = lambda t: (25.0 * t, 5.0 * t)        # chart 2: p = (u+v)/2, q = (u-v)/2
E1, F1, G1 = efg(plan, 30, 20)
E2, F2, G2 = efg(rule, 25, 5)
a, b = 10.0 * sqrt(13.0), 25.0 / 3.0         # ds/dt = sqrt(a^2 + b^2 t^2) on this walk
closed = 0.5 * (sqrt(a * a + b * b) + a * a / b * asinh(b / a))
L1 = length(plan, walk1, (30, 20))
L2 = length(rule, walk2, (25, 5))
flat = sqrt(30.0 ** 2 + 20.0 ** 2)
noF = length(plan, walk1, (30, 20), fterm=0.0)
oneF = length(plan, walk1, (30, 20), fterm=1.0)
mixed = length(plan, walk2, (25, 5), efg_chart=plan)
th1 = angle(E1, F1, G1, (1, 0), (0, 1))
th2 = angle(E2, F2, G2, (0.5, 0.5), (0.5, -0.5))
Ep, Fp, Gp = efg(polar, 0.0, 0.7)

rows = [
    ("E, F, G at P, plan chart", f"{E1:.6f} {F1:.6f} {G1:.6f}"),
    ("hand formula 1+u^2/3600, -uv/3600, 1+v^2/3600", f"{1 + 900 / 3600:.6f} {-600 / 3600:.6f} {1 + 400 / 3600:.6f}"),
    ("E, F, G at P, seam chart", f"{E2:.6f} {F2:.6f} {G2:.6f}"),
    ("  by J^T I J: E+2F+G, E-G, E-2F+G", f"{E1 + 2 * F1 + G1:.6f} {E1 - G1:.6f} {E1 - 2 * F1 + G1:.6f}"),
    ("EG - F^2 at P", f"{E1 * G1 - F1 * F1:.6f}"),
    ("roof height at P, m", f"{plan(30, 20)[2]:.6f}"),
    ("sqrt(E), sqrt(G), sqrt(EG) at P", f"{sqrt(E1):.6f} {sqrt(G1):.6f} {sqrt(E1 * G1):.6f}"),
    ("t^2 terms: 900/4, -1200/6, 400/9", f"{900 / 4:.6f} {-1200 / 6:.6f} {400 / 9:.6f}"),
    ("speed at t = 0, 0.5, 1, m per unit t", " ".join(f"{sqrt(a * a + b * b * t * t):.6f}" for t in (0, 0.5, 1))),
    ("Simpson by hand, 2 slices, m", f"{(a + 4 * sqrt(a * a + b * b / 4) + sqrt(a * a + b * b)) / 6:.6f}"),
    ("plan distance O to P, m", f"{flat:.6f}"),
    ("1 length, plan chart, Simpson", f"{L1:.6f}"),
    ("2 length, seam chart, Simpson", f"{L2:.6f}"),
    ("3 length, closed form", f"{closed:.6f}"),
    ("4 tape in 10 straight pieces", f"{chords(10):.6f}"),
    ("  tape in 100 straight pieces", f"{chords(100):.6f}"),
    ("roof minus plan, m", f"{closed - flat:.6f}"),
    ("speed^2 at t = 1, (m per unit t)^2", f"{form(E1, F1, G1, (30, 20), (30, 20)):.6f}"),
    ("1 angle at P, plan chart, deg", f"{th1:.6f}"),
    ("2 angle at P, seam chart, deg", f"{th2:.6f}"),
    ("  same angle in radians", f"{th1 * pi / 180:.6f}"),
    ("  cos of the angle, F/sqrt(EG)", f"{F1 / sqrt(E1 * G1):.6f}"),
    ("3 tape triangle, 1 m legs, deg", f"{tape_angle(1.0):.6f}"),
    ("  tape triangle, 0.1 m legs, deg", f"{tape_angle(0.1):.6f}"),
    ("wrong: plan angle, deg", f"{90.0:.6f}"),
    ("wrong: drop F, length", f"{noF:.6f}"),
    ("wrong: F once, not 2F, length", f"{oneF:.6f}"),
    ("wrong: plan E,F,G with seam speeds", f"{mixed:.6f}"),
    ("breaks: polar chart at centre, E F G", f"{Ep:.6f} {Fp:.6f} {Gp:.6f}"),
    ("  EG - F^2 there", f"{Ep * Gp - Fp * Fp:.6f}"),
    ("try: walk along seam to (30, 30), m", f"{length(plan, lambda t: (30 * t, 30 * t), (30, 30)):.6f}"),
    ("  plan distance to (30, 30), m", f"{sqrt(1800.0):.6f}"),
    ("try: walk to (30, -20), m", f"{length(plan, lambda t: (30 * t, -20 * t), (30, -20)):.6f}"),
    ("try: angle at centre, deg", f"{angle(*efg(plan, 0, 0), (1, 0), (0, 1)):.6f}"),
    ("try: seams crossing at P, deg", f"{angle(E1, F1, G1, (1, 1), (1, -1)):.6f}"),
]
for name, v in rows:
    print(f"{name:<46} {v}")
stretch = [sqrt(a * a + b * b * (k / 10) ** 2) / a for k in range(11)]
print("figure, plan metres", " ".join(f"{flat * k / 10:.1f}" for k in range(11)))
print("figure, roof m per plan m", " ".join(f"{s:.4f}" for s in stretch))

assert abs(L1 - closed) < 1e-7, "first-form integral must match the closed form"
assert abs(L2 - closed) < 1e-7, "the seam chart must give the same length"
c10, c100 = chords(10), chords(100)
assert 0 < closed - c10 < 0.001 and (closed - c10) / (closed - c100) > 50, "tape error falls 100-fold"
assert abs(E1 - 2 * F1 + G1 - G2) + abs(E1 - G1 - F2) < 1e-6, "chart change rule J^T I J"
assert abs(th1 - th2) < 1e-6, "the angle must not depend on the chart"
assert abs(tape_angle(0.1) - th1) < abs(tape_angle(1.0) - th1) < 0.5, "tape angle closes in"
assert abs(F1 / sqrt(E1 * G1) + 1 / sqrt(50)) < 1e-9, "cos = -1/sqrt(50) by hand"
assert abs(Ep * Gp - Fp * Fp) < 1e-9, "polar chart is not regular at the centre"
print("ALL CHECKS PASS")
