# Darboux's theorem and Moser's trick -- the check behind the card.  Standard library only.
# Part 1, the plane: rain lies 1 + x^2 mm deep at x km from a river, the form w1 = (1 + x^2) dx^dy.
# Darboux coordinates u = x + x^3/3, v = y.  Roads: du/dx by finite differences against 1 + x^2;
# rain in a strip by the midpoint rule against the strip's u-width; Moser's flow, stepped by RK4,
# against Cardano's formula and Newton's method for x + x^3/3 = u.  Part 2: a constant form on R^4
# brought to dq^dp by symplectic Gram-Schmidt, against the shift P1 = p1 + b q2 found by hand.
# Part 3: Lagrangian tests, by w on tangent pairs and by the loop integral of p dq.  Part 4: breaks.
import math
def f6(x): return f"{x + 0.0:.6f}"
def u_of(x, k=2): return x + x ** (k + 1) / (k + 1)
def cardano(u):                              # the real root of x^3 + 3x - 3u = 0
    r = math.sqrt(9 * u * u / 4 + 1)
    return math.cbrt(1.5 * u + r) - math.cbrt(r - 1.5 * u)
def newton(u):
    x = u
    for _ in range(60): x -= (u_of(x) - u) / (1 + x * x)
    return x
def X(t, x, k=2, s=1.0):                     # Moser's field: iota_X w_t = -s alpha, alpha = x^(k+1)/(k+1) dy
    return -s * x ** (k + 1) / ((k + 1) * (1 + t * x ** k))
def moser(a, n, T=1.0, k=2, s=1.0):          # RK4 on dx/dt = X(t, x) from x = a, t = 0 to T
    x, h = a, T / n
    for j in range(n):
        t = j * h
        k1 = X(t, x, k, s); k2 = X(t + h / 2, x + h / 2 * k1, k, s)
        k3 = X(t + h / 2, x + h / 2 * k2, k, s); k4 = X(t + h, x + h * k3, k, s)
        x += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    return x
print("chart, u = x + x^3/3 at x = 0, 0.5, ..., 3 [" + ", ".join(f"{u_of(i / 2):.4f}" for i in range(7)) + "]")
for x in (0.0, 1.0, 2.0, 3.0):
    d = (u_of(x + 1e-5) - u_of(x - 1e-5)) / 2e-5
    print(f"x = {x:.0f} km: rain 1 + x^2 = {f6(1 + x * x)} mm, du/dx by differences {f6(d)}")
    assert abs(d - (1 + x * x)) < 1e-8
for a, b in ((0, 1), (1, 2), (2, 3)):
    mids = [abs(sum(1 + (a + (i + 0.5) / n) ** 2 for i in range(n)) / n - (u_of(b) - u_of(a))) for n in (10, 100)]
    print(f"strip {a}-{b} km out, 1 km along: rain {f6(u_of(b) - u_of(a))} mm km^2 = u-width;"
          f" midpoint error {mids[0]:.1e} (10 cells), {mids[1]:.1e} (100)")
    assert mids[1] < mids[0] / 50 and mids[1] < 1e-4
print("one unit square in (u, v) reaches out to x =", f6(cardano(1.0)), "km; check u(x) =", f6(u_of(cardano(1.0))))
for x in (1.0, 2.0):
    a = u_of(x)
    e1, e2 = abs(moser(a, 40) - x), abs(moser(a, 80) - x)
    print(f"Moser flow from a = {f6(a)}: lands at {f6(moser(a, 80))}; Cardano {f6(cardano(a))}, Newton {f6(newton(a))};"
          f" RK4 error {e1:.1e} (40 steps), {e2:.1e} (80)")
    assert abs(cardano(a) - x) < 1e-12 and abs(newton(a) - x) < 1e-12 and e2 < e1 / 8 and e2 < 1e-4
xm = moser(4 / 3, 200, 0.5)
print("halfway, t = 0.5: x =", f6(xm), "and x + t x^3/3 =", f6(xm + 0.5 * xm ** 3 / 3), "(kept)")
assert abs(xm + 0.5 * xm ** 3 / 3 - 4 / 3) < 1e-10
dxda = (moser(4 / 3 + 1e-5, 200) - moser(4 / 3 - 1e-5, 200)) / 2e-5
print("pullback at a = 4/3: (1 + x^2) dx/da =", f6(2), "x", f6(dxda), "=", f6((1 + moser(4 / 3, 200) ** 2) * dxda), "(w0 = 1 da^dy)")
assert abs((1 + moser(4 / 3, 200) ** 2) * dxda - 1) < 1e-7
def wA(A, u, v): return sum(u[i] * A[i][j] * v[j] for i in range(4) for j in range(4))
def form(entries):                           # antisymmetric 4x4 matrix in the order (q1, q2, p1, p2)
    A = [[0.0] * 4 for _ in range(4)]
    for (i, j), c in entries.items(): A[i][j], A[j][i] = c, -c
    return A
def pf(A): return A[0][1] * A[2][3] - A[0][2] * A[1][3] + A[0][3] * A[1][2]
def gram_schmidt(A):                         # symplectic Gram-Schmidt: returns e1, e2, f1, f2
    rest, es, fs = [[float(i == j) for i in range(4)] for j in range(4)], [], []
    while rest:                              # pair the first arrow with the last one it sees
        e = rest.pop(0)
        f = rest.pop(max(i for i, r in enumerate(rest) if abs(wA(A, e, r)) > 1e-12))
        f = [c / wA(A, e, f) for c in f]
        es.append(e); fs.append(f)
        rest = [[r[i] - wA(A, r, f) * e[i] + wA(A, r, e) * f[i] for i in range(4)] for r in rest]
    return es + fs
def dev(A, P):                               # largest gap between P^T A P and the standard matrix J
    J = form({(0, 2): 1.0, (1, 3): 1.0})
    return max(abs(wA(A, P[i], P[j]) - J[i][j]) for i in range(4) for j in range(4))
B = 2.0
A = form({(0, 2): 1.0, (1, 3): 1.0, (0, 1): B})  # dq1^dp1 + dq2^dp2 + b dq1^dq2
P = gram_schmidt(A)
def vec(v): return "(" + ", ".join(f"{c + 0.0:g}" for c in v) + ")"
print("magnetic form, b = 2: Pfaffian", f6(pf(A)), "| Gram-Schmidt e1, e2, f1, f2 =", ", ".join(vec(v) for v in P))
hand = [[1, 0, 0, 0], [0, 1, -B, 0], [0, 0, 1, 0], [0, 0, 0, 1]]   # z for unit steps of Q1, Q2, P1 = p1 + b q2, P2
ident = [[float(i == j) for i in range(4)] for j in range(4)]
print("largest gap from dq^dp: Gram-Schmidt", f6(dev(A, P)), "| shift P1 = p1 + 2 q2", f6(dev(A, hand)), "| no change", f6(dev(A, ident)))
assert dev(A, P) < 1e-12 and dev(A, hand) < 1e-12 and abs(dev(A, ident) - B) < 1e-12 and P[1] == [0, 1, -B, 0]
W = form({(0, 2): 1.0, (1, 3): 1.0})
E = ident
print("plane of q1, q2: w =", f6(wA(W, E[0], E[1])), "| plane of q1, p1: w =", f6(wA(W, E[0], E[2])))
def graph(beta):                             # the surface q -> (q1, q2, beta1(q), beta2(q))
    return lambda q1, q2: [q1, q2] + list(beta(q1, q2))
def on(g, pts):                              # w on the surface's tangent pair, by central differences
    out = []
    for q1, q2 in pts:
        t1 = [(a - b) / 2e-5 for a, b in zip(g(q1 + 1e-5, q2), g(q1 - 1e-5, q2))]
        t2 = [(a - b) / 2e-5 for a, b in zip(g(q1, q2 + 1e-5), g(q1, q2 - 1e-5))]
        out.append(wA(W, t1, t2))
    return out
def worst(g, pts): return max(abs(w) for w in on(g, pts))
def loop(g, n=400):                          # p dq round the surface g's square 1 <= s, t <= 2, anticlockwise
    c = [(1 + i / n, 1.0) for i in range(n)] + [(2.0, 1 + i / n) for i in range(n)]
    c += [(2 - i / n, 2.0) for i in range(n)] + [(1.0, 2 - i / n) for i in range(n)]
    tot = 0.0
    for (a1, a2), (b1, b2) in zip(c, c[1:] + c[:1]):
        m, ga, gb = g((a1 + b1) / 2, (a2 + b2) / 2), g(a1, a2), g(b1, b2)
        tot += m[2] * (gb[0] - ga[0]) + m[3] * (gb[1] - ga[1])
    return tot
pts = [(1.0, 2.0), (0.5, -1.0), (2.0, 3.0)]
gS, gB = graph(lambda a, b: (2 * a * b, a * a)), graph(lambda a, b: (0.0, a))
print("graph p = grad S, S = q1^2 q2: at q = (1, 2), p =", vec(gS(1.0, 2.0)[2:]), "| largest |w|", f"{worst(gS, pts):.1e}", "| loop of p dq", f6(abs(loop(gS))))
print("graph p = (0, q1), from beta = q1 dq2: w =", ", ".join(f6(w) for w in on(gB, pts)), "| loop of p dq", f6(loop(gB)))
sq = loop(lambda s, t: [s, 0.0, t, 0.0])    # the (q1, p1) plane: the unit square 1 <= q1, p1 <= 2
print("plane of q1, p1, unit square anticlockwise: loop of p dq", f6(sq), "= minus w on it")
assert worst(gS, pts) < 1e-8 and abs(loop(gS)) < 1e-9 and abs(loop(gB) - 1) < 1e-9 and max(abs(w + 1) for w in on(gB, pts)) < 1e-8
assert abs(sq + wA(W, E[0], E[2])) < 1e-12
assert wA(W, E[0], E[1]) == 0.0
print("break, w = x dx^dy: u = x^2/2 gives", f6(0.5 ** 2 / 2), "at x = -0.5 and", f6((-0.5) ** 2 / 2), "at x = 0.5")
def flux(Af, n=10):                          # w over the boundary of the unit cube in (q1, q2, p1)
    tot = 0.0
    for k in range(3):
        a, b = (k + 1) % 3, (k + 2) % 3
        for c, sgn in ((1.0, 1), (0.0, -1)):
            for i in range(n):
                for j in range(n):
                    z = [0.0] * 4; z[k], z[a], z[b] = c, (i + 0.5) / n, (j + 0.5) / n
                    ta, tb = [float(m == a) for m in range(4)], [float(m == b) for m in range(4)]
                    tot += sgn * wA(Af(z), ta, tb) / n / n
    return tot
bad = lambda z: form({(0, 2): 1.0, (1, 3): 1.0, (1, 2): z[0]})   # adds q1 dq2^dp1
print("break, w + q1 dq2^dp1: Pfaffian", f6(pf(bad([0.5] * 4))), "; w through the cube's boundary", f6(flux(bad)), "against", f6(flux(lambda z: W)), "for dq^dp")
assert abs(flux(bad) - 1) < 1e-12 and abs(flux(lambda z: W)) < 1e-12
lo, hi = 0.0, 1.0                            # straight path from dq^dp to dq1^dp1 - dq2^dp2: Pfaffian = 0 where?
for _ in range(60):
    mid = (lo + hi) / 2
    if pf(form({(0, 2): 1.0, (1, 3): 1 - 2 * lo})) * pf(form({(0, 2): 1.0, (1, 3): 1 - 2 * mid})) <= 0: hi = mid
    else: lo = mid
print("break, path without the linear step: w_t degenerate at t =", f6(lo))
assert abs(lo - 0.5) < 1e-9
xw = moser(4 / 3, 200, s=-1.0)
print("break, sign of alpha flipped: flow lands at", f6(xw), "where u =", f6(u_of(xw)), "not 4/3")
print("try: rain 1 + x^4, flow from 1.2 lands at", f6(moser(1.2, 200, k=4)), "| RK4 5 steps error", f"{abs(moser(4 / 3, 5) - 1):.1e}")
A5 = form({(0, 2): 1.0, (1, 3): 1.0, (0, 1): 5.0})
print("try: b = 5, e2 =", vec(gram_schmidt(A5)[1]), "gap", f6(dev(A5, gram_schmidt(A5))),
      "| S = q1^3 + q2^2, largest |w|", f"{worst(graph(lambda a, b: (3 * a * a, 2 * b)), pts):.1e}")
assert abs(moser(1.2, 200, k=4) - 1) < 1e-9 and abs(u_of(xw) - 4 / 3) > 0.5
print("ALL CHECKS PASS")
