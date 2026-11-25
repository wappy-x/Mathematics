# Mean curvature flow -- the check behind the card.  Standard library only.
# Each shape moves down the gradient of its own size: a polygon down the gradient of its
# length, a profile spun round the z-axis down the gradient of its surface area.  A vertex
# moves by minus that gradient over its share of the size, the discrete kappa N or 2H n.
from math import pi, sqrt, cos, sin, asin
def f(x): return f"{x:.4f}"
def curve(P):                           # closed polygon, counterclockwise
    n = len(P); E = []
    for i in range(n):
        dx = P[(i + 1) % n][0] - P[i][0]; dy = P[(i + 1) % n][1] - P[i][1]
        E.append((dx, dy, sqrt(dx * dx + dy * dy)))
    V = []; L = 0.0; A = 0.0; lmin = E[0][2]; convex = True; k2 = 0.0
    for i in range(n):
        a = E[i - 1]; b = E[i]; m = (a[2] + b[2]) / 2       # the vertex's share of the length
        vx = (b[0] / b[2] - a[0] / a[2]) / m; vy = (b[1] / b[2] - a[1] / a[2]) / m
        V.append((vx, vy)); k2 += (vx * vx + vy * vy) * m  # adds kappa^2 ds
        L += b[2]; lmin = min(lmin, b[2]); convex = convex and a[0] * b[1] - a[1] * b[0] > 0
        A += (P[i][0] * P[(i + 1) % n][1] - P[(i + 1) % n][0] * P[i][1]) / 2
    return V, A, 0.2 * lmin * lmin, (L, convex, k2)
def surface(P):                         # profile (z, r) from pole to pole, spun round the z-axis
    n = len(P) - 1; E = []; A = 0.0; lmin = 1e9
    for i in range(n):
        dz = P[i + 1][0] - P[i][0]; dr = P[i + 1][1] - P[i][1]; l = sqrt(dz * dz + dr * dr)
        E.append((dz / l, dr / l, l, pi * (P[i][1] + P[i + 1][1]))); A += E[i][3] * l; lmin = min(lmin, l)
    V = []; rneck = P[n // 2][1]; rmax = 0.0
    for i in range(n + 1):
        gz = 0.0; gr = 0.0; m = 0.0                         # gradient of area, share of area
        if i > 0:
            e = E[i - 1]; gz += e[3] * e[0]; gr += e[3] * e[1] + pi * e[2]
            m += pi * (1.5 * P[i][1] + 0.5 * P[i - 1][1]) * e[2] / 2  # half-band next to the vertex
        if i < n:
            e = E[i]; gz -= e[3] * e[0]; gr += pi * e[2] - e[3] * e[1]
            m += pi * (1.5 * P[i][1] + 0.5 * P[i + 1][1]) * e[2] / 2
        V.append((-gz / m, 0.0 if i == 0 or i == n else -gr / m)); rmax = max(rmax, P[i][1])
    return V, A, 0.1 * min(lmin * lmin, rneck * rneck), (rneck, rmax)
def edges(P, closed):
    Q = P + [P[0]] if closed else P
    return [sqrt((b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1])) for a, b in zip(Q, Q[1:])]
def even(P, closed):                   # re-space the vertices evenly along the shape
    Q = P + [P[0]] if closed else P; s = [0.0]
    for l in edges(P, closed): s.append(s[-1] + l)
    n = len(P) if closed else len(P) - 1; out = []; j = 0
    for k in range(len(P)):
        g = s[-1] * k / n
        while j < len(Q) - 2 and s[j + 1] < g: j += 1
        w = (g - s[j]) / (s[j + 1] - s[j]); out.append((Q[j][0] + w * (Q[j + 1][0] - Q[j][0]), Q[j][1] + w * (Q[j + 1][1] - Q[j][1])))
    if not closed: out[-1] = P[-1]
    return out
def lmin(P, closed): return min(edges(P, closed))
def lmean(P, closed):
    s = 0.0
    for l in edges(P, closed): s += l
    return s / len(edges(P, closed))
def flow(P, law, marks, stop):          # explicit steps; returns readings at marks, stop time
    t = 0.0; steps = 0; V, A, dt, x = law(P); A0 = A; seen = {}; marks = list(marks)
    while True:
        if marks and t >= marks[0] - 1e-12: seen[marks.pop(0)] = (A, x)
        h = min(dt, marks[0] - t) if marks else dt
        Q = [(p[0] + h * v[0], p[1] + h * v[1]) for p, v in zip(P, V)]
        steps += 1
        if steps % 10 == 0 and lmin(Q, law is curve) < 0.6 * lmean(Q, law is curve): Q = even(Q, law is curve)
        V2, A2, dt2, x2 = law(Q)
        if stop(A0, A2, x2, t + h):
            return seen, t, h, A, A2, x, x2
        P, V, A, dt, x, t = Q, V2, A2, dt2, x2, t + h
def at_one_percent(P, law, marks=()):   # time the size falls to 1% of its start; first convex time
    cv = []
    seen, t, h, A, A2, x, x2 = flow(P, law, marks, lambda A0, A2, x, t:
                                    (law is surface or not x[1] or cv or cv.append(t)) and A2 < 0.01 * A0)
    target = 0.01 * law(P)[1]
    return t + h * (A - target) / (A - A2), seen, cv
ring = lambda n: [(10 * cos(2 * pi * k / n), 10 * sin(2 * pi * k / n)) for k in range(n)]
ball = lambda n: [(10 * cos(pi * k / n), 10 * sin(pi * k / n)) for k in range(n + 1)]
def peanut(n):
    return [(10 * (1 + 0.5 * cos(2 * a)) * cos(a), 10 * (1 + 0.5 * cos(2 * a)) * sin(a))
            for a in [2 * pi * k / n for k in range(n)]]
print("closed forms, radius 10 cm: sphere r^2 = 100 - 4t, circle r^2 = 100 - 2t")
print("chart sphere", ", ".join(f"{sqrt(max(0.0, 100 - 4 * t)):.2f}" for t in range(0, 51, 5)))
print("chart circle", ", ".join(f"{sqrt(100 - 2 * t):.2f}" for t in range(0, 51, 5)))
print("sphere area", f(400 * pi), "cm^2, rate -16 pi =", f(-16 * pi), "-> gone at", f(400 * pi / (16 * pi)))
print("circle area", f(100 * pi), "cm^2, rate -2 pi =", f(-2 * pi), "-> gone at", f(100 * pi / (2 * pi)))
print("closed form at t=16: sphere", f(sqrt(100 - 64)), "circle", f(sqrt(100 - 32)))
print("circle length rate -2pi/r at r=10:", f(-2 * pi / 10), " sphere speed 2/r:", f(0.2))
res = {}
for name, law, mk, n1, exact in (("sphere", surface, ball, 40, 24.75), ("circle", curve, ring, 64, 49.5)):
    for n in (n1, 2 * n1):
        t1, seen, cv = at_one_percent(mk(n), law, (16.0,))
        r16 = seen[16.0][1][1] if law is surface else sqrt(seen[16.0][0] / pi)
        res[name, n] = t1
        print(f"{name} N={n}: 1% of size left at t = {f(t1)} (exact {f(exact)}); radius at t=16: {f(r16)}")
    assert abs(res[name, 2 * n1] - exact) < abs(res[name, n1] - exact) + 1e-9 and abs(res[name, 2 * n1] - exact) < 0.05
P = peanut(200); A_exact = 112.5 * pi
print("peanut area", f(A_exact), "exact,", f(curve(P)[1]), "polygon; gone at A/2pi =", f(A_exact / (2 * pi)))
def smooth(n):                          # the smooth peanut by Simpson's rule in the polar angle: L, int kappa^2 ds
    L = 0.0; k2 = 0.0
    for k in range(n + 1):
        a = 2 * pi * k / n; r = 10 + 5 * cos(2 * a); r1 = -10 * sin(2 * a); r2 = -20 * cos(2 * a)
        w = (1 if k in (0, n) else 4 if k % 2 else 2) * 2 * pi / (3 * n); v = sqrt(r * r + r1 * r1)
        q = r * r + 2 * r1 * r1 - r * r2; L += w * v; k2 += w * q * q / (v * v * v * v * v)
    return L, k2
Ls, k2s = smooth(2000); gap = []
for n in (100, 200):
    V, A, dt, (L, cv, k2) = curve(peanut(n)); gap.append(abs(k2 - k2s))
    print(f"peanut N={n} start: length {f(L)}; length lost per unit time: speed kappa {f(k2)}, even speed of equal size {f(2 * pi * sqrt(k2 / L))}")
    assert k2 > 2 * pi * sqrt(k2 / L) * 1.05 and not cv
print(f"smooth peanut start: length {f(Ls)}; length lost per unit time: speed kappa {f(k2s)}, even speed of equal size {f(2 * pi * sqrt(k2s / Ls))}")
assert gap[1] < gap[0] < 0.1 and abs(L - Ls) < 0.05
for n in (100, 200):
    marks = (0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 55.0)
    t1, seen, cv = at_one_percent(peanut(n), curve, marks)
    ratio = [s[1][0] * s[1][0] / (4 * pi * s[0]) for s in (seen[m] for m in marks)]
    print(f"peanut N={n}: area at t=20 {f(seen[20.0][0])} (law {f(curve(peanut(n))[1] - 40 * pi)}), 1% at t = {f(t1)} (law {f(0.99 * A_exact / (2 * pi))})")
    print(f"  chart L^2/(4 pi A):", ", ".join(f"{r:.3f}" for r in ratio), "; convex from t =", f(cv[0]))
    assert abs(seen[20.0][0] - (curve(peanut(n))[1] - 40 * pi)) < 0.5 and abs(t1 - 0.99 * A_exact / (2 * pi)) < 0.3
    assert ratio[0] > 1.3 and ratio[-1] < 1.01 and not seen[0.0][1][1] and 0 < cv[0] < 50
def dumbbell(h):                        # two 10 cm bulbs, centres 24 cm apart, a 3 cm neck
    tj = pi - asin(0.3); m = round(10 * tj / h); zj = 12 - 10 * cos(asin(0.3)); q = 2 * round(zj / h)
    right = [(12 + 10 * cos(tj * k / m), 10 * sin(tj * k / m)) for k in range(m + 1)]
    neck = [(zj - 2 * zj * k / q, 3.0) for k in range(1, q)]
    return right + neck + [(-z, r) for z, r in reversed(right)]
tp = {}
for h in (0.5, 0.25):
    seen, t, hh, A, A2, x, x2 = flow(dumbbell(h), surface, (0.0, 1.0, 2.0, 3.0, 4.0), lambda A0, A2, x, t: x[0] < 0.3)
    tp[h] = t + hh * (x[0] - 0.3) / (x[0] - x2[0])
    print(f"dumbbell h={h}: neck/bulb radius at t=0..4:", "; ".join(f"{f(s[1][0])}/{f(s[1][1])}" for s in seen.values()))
    print(f"  neck 0.3 cm at t = {f(tp[h])}; bulbs then {f(x2[1])} cm, a lone sphere {f(sqrt(100 - 4 * tp[h]))}")
    assert 4.5 < tp[h] < 25 and abs(x2[1] - sqrt(100 - 4 * tp[h])) < 0.1
assert abs(tp[0.5] - tp[0.25]) < 0.1
print("lone sphere r=10 at t=0..4:", ", ".join(f(sqrt(100 - 4 * t)) for t in (0, 1, 2, 3, 4)))
print("lone cylinder r=3 at t=0..4:", ", ".join(f(sqrt(9 - 2 * t)) for t in (0, 1, 2, 3, 4)), "; gone at", f(4.5))
print("wrong: speed H = average, sphere gone at", f(100 / 2), "not 25")
print("wrong: surface speed 2/r on a circle, gone at", f(100 / 4), "not 50")
print("Ricci flow, sphere radius 10: R^2 = 100 - 2t, gone at", f(100 / 2), "; circle and cylinder: Ric = 0, never move;", "this flow: cylinder r=10 gone at", f(100 / 2))
print("try: sphere radius 5 gone at", f(25 / 4), "; 3-sphere radius 10 gone at", f(100 / 6), "; circle area 300 gone at", f(300 / (2 * pi)))
print("ALL CHECKS PASS")
