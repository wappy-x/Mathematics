# Nodes and cusps -- the check behind the card.
# Standard library only.  Fraction keeps every coefficient exact.  A curve is F(x, y) = 0,
# stored as {(i, j): coefficient of x^i y^j}.  At a point P the card reads the multiplicity m
# (the lowest degree left after moving P to the origin), the tangent cone (those lowest terms)
# and the type.  Three roads to m and the tangents: the Taylor shift, the partial derivatives,
# and the order of contact with lines.  A fourth road counts real arcs on a small circle.
from fractions import Fraction as Q
from math import comb, factorial, cos, sin, pi

def P(*terms): return {(i, j): Q(c) for c, i, j in terms}       # (c, i, j) is c x^i y^j
def mono(i, j): return ("x" if i == 1 else f"x^{i}" if i else "") + ("y" if j == 1 else f"y^{j}" if j else "")
def show(F):
    out = ""
    for (i, j) in sorted(F, key=lambda k: (-k[0] - k[1], -k[0])):
        c, m = F[(i, j)], mono(i, j)
        s = (str(abs(c)) if abs(c) != 1 or not m else "") + m
        out += (" - " if c < 0 else " + ") + s if out else ("-" if c < 0 else "") + s
    return out or "0"
def shift(F, a, b):                               # F(x + a, y + b), by the binomial theorem
    G = {}
    for (i, j), c in F.items():
        for r in range(i + 1):
            for s in range(j + 1):
                G[(r, s)] = G.get((r, s), 0) + c * comb(i, r) * a ** (i - r) * comb(j, s) * b ** (j - s)
    return {k: v for k, v in G.items() if v}
def lowest(G):
    m = min(i + j for i, j in G)
    return m, {k: v for k, v in G.items() if sum(k) == m}
def part(G, k): return {key: v for key, v in G.items() if sum(key) == k}
def d(F, v): return {(i - 1 + v, j - v): c * (j if v else i) for (i, j), c in F.items() if (j if v else i)}
def ev(F, a, b): return sum(c * a ** i * b ** j for (i, j), c in F.items())
def by_partials(F, a, b):                         # first k with a k-th partial nonzero at P
    for k in range(9):
        T = {}
        for i in range(k + 1):
            D = F
            for v in [0] * i + [1] * (k - i): D = d(D, v)
            val = ev(D, a, b) / (factorial(i) * factorial(k - i))
            if val: T[(i, k - i)] = val
        if T: return k, T
def pmul(p, q):
    r = [Q(0)] * (len(p) + len(q) - 1)
    for i, x in enumerate(p):
        for j, y in enumerate(q): r[i + j] += x * y
    return r
def ppow(p, n):
    r = [Q(1)]
    for _ in range(n): r = pmul(r, p)
    return r
def contact(F, a, b, u, v):                       # order of s in F(a + u s, b + v s)
    out = {}
    for (i, j), c in F.items():
        for k, t in enumerate(pmul(ppow([a, u], i), ppow([b, v], j))): out[k] = out.get(k, 0) + c * t
    return min(k for k, t in out.items() if t)
def arcs(F, a, b, r=0.05, n=7200):                # sign changes of F on a circle round P, halved
    f = lambda x, y: sum(float(c) * x ** i * y ** j for (i, j), c in F.items())
    s = [f(a + r * cos(2 * pi * (k + 0.5) / n), b + r * sin(2 * pi * (k + 0.5) / n)) > 0 for k in range(n)]
    return sum(s[k] != s[k - 1] for k in range(n)) // 2
def kind(m, G):
    if m == 1: return "smooth point"
    if m > 2: return f"point of multiplicity {m}"
    A, B, C = (G.get(k, 0) for k in ((2, 0), (1, 1), (0, 2)))
    D = B * B - 4 * A * C
    if D > 0: return f"D = {D}: node, two real tangents"
    if D < 0: return f"D = {D}: node, tangents complex, a lone real dot"
    u, v = (-B, 2 * A) if A else (1, 0)           # the one tangent direction
    return f"D = 0, F_3 on the tangent = {ev(part(G, 3), u, v)}: " + ("ordinary cusp" if ev(part(G, 3), u, v) else "not a cusp: higher terms decide")

DIRS = [(1, Q(t), f"slope {Q(t)}") for t in (-2, -1, Q(-1, 2), 0, Q(1, 2), 1, 2)] + [(0, 1, "vertical")]
curves = [("cusp y^2 = x^3", P((1, 0, 2), (-1, 3, 0)), (0, 0), "ordinary cusp"),
          ("node y^2 = x^2(x + 1)", P((1, 0, 2), (-1, 3, 0), (-1, 2, 0)), (0, 0), "two real tangents"),
          ("same node curve", P((1, 0, 2), (-1, 3, 0), (-1, 2, 0)), (-1, 0), "smooth point"),
          ("neighbour y^2 = x^3 + x^2 - 4/27", P((1, 0, 2), (-1, 3, 0), (-1, 2, 0), (Q(4, 27), 0, 0)), (Q(-2, 3), 0), "a lone real dot"),
          ("tacnode y^2 = x^4", P((1, 0, 2), (-1, 4, 0)), (0, 0), "higher terms decide"),
          ("y^2 = x^5", P((1, 0, 2), (-1, 5, 0)), (0, 0), "higher terms decide"),
          ("three-leaf (x^2 + y^2)^2 = xy(x - y)", P((1, 4, 0), (2, 2, 2), (1, 0, 4), (-1, 2, 1), (1, 1, 2)), (0, 0), "multiplicity 3")]
res = {}
print("field: C for the algebra, exact rationals; real points for arcs and pictures")
for name, F, (a, b), want in curves:
    a, b = Q(a), Q(b)
    G = shift(F, a, b); m, L = lowest(G); m2, T = by_partials(F, a, b); kd = kind(m, G)
    orders = [(contact(F, a, b, u, v), lab, ev(L, u, v) == 0) for u, v, lab in DIRS]
    m3 = min(o for o, _, _ in orders); tang = [lab for o, lab, _ in orders if o > m]
    n_arcs = arcs(F, float(a), float(b))
    print(f"{name}, P = ({a}, {b}): moved to P, F = {show(G)}")
    print(f"  m = {m} by shift, {m2} by partials, {m3} by lines; tangent cone {show(L)}; {kd}")
    print(f"  tangent lines found: {', '.join(tang) or 'none real'}; real arcs through P: {n_arcs}")
    assert m == m2 == m3 and T == L and tang == [lab for _, lab, z in orders if z] and kd.endswith(want)
    res[name] = (m, tang, n_arcs, orders)

t = [Q(k) for k in range(8)]; nd = lambda t: (t * t - 1, t ** 3 - t); cu = lambda t: (t * t, t ** 3); lo = lambda t: (t * t + 1, t ** 3 + t)  # degree 6: 8 points
F_n, F_c, F_l = curves[1][1], curves[0][1], shift(curves[3][1], Q(-2, 3), Q(0))   # F_l: the neighbour moved to its lone dot
assert all(ev(F_n, *nd(s)) == 0 and ev(F_c, *cu(s)) == 0 and ev(F_l, *lo(s)) == 0 for s in t)
o2 = contact(F_n, Q(0), Q(0), 1, Q(2)); x2, y2 = nd(Q(2))
print(f"Bezout: y = 2x meets the node cubic at (0, 0) to order {o2}, and once more at ({x2}, {y2}), where F = {ev(F_n, x2, y2)}; {o2} + 1 = 3, the degree")
vel = [(2 * t, 3 * t * t - 1) for t in (-1, 1)]
print(f"node (t^2 - 1, t^3 - t): t = -1 and t = 1 both give ({nd(Q(-1))[0]}, {nd(Q(1))[1]}); velocities (2t, 3t^2 - 1) = "
      f"{vel[0]}, {vel[1]}: slopes {Q(vel[0][1], vel[0][0])}, {Q(vel[1][1], vel[1][0])}")
print(f"cusp (t^2, t^3): t = 0 gives {cu(0)}, velocity (2t, 3t^2) = {(2 * 0, 3 * 0)}; acceleration (2, 6t) = {(2, 6 * 0)}, slope 0")
gi = lambda p, q: (p[0] * q[0] - p[1] * q[1], p[0] * q[1] + p[1] * q[0])   # complex product
i1 = (0, 1); i2 = gi(i1, i1); i3 = gi(i2, i1)
assert (i2[0] + 1, i2[1]) == (0, 0) and (i3[0] + i1[0], i3[1] + i1[1]) == (0, 0)
print(f"lone dot y^2 = x^3 - x^2 by (t^2 + 1, t^3 + t): real t keeps x >= 1; t = i gives ({i2[0] + 1}, {i3[1] + i1[1]})")
G3 = {k: (v + 1) % 3 - 1 for k, v in shift(P((1, 0, 2), (-1, 3, 0), (2, 0, 0)), Q(2), Q(0)).items() if v % 3}  # mod 3
print(f"mod 3: y^2 = x^3 - 2 moved to (2, 0) is {show(G3)}; {kind(2, G3)}")
s = [Q(1)]                                        # sqrt(1 + x) by s^2 = 1 + x, term by term
for n in range(1, 7): s.append((Q(n == 1) - sum(s[k] * s[n - k] for k in range(1, n))) / 2)
binom = [Q(1)]
for n in range(1, 7): binom.append(binom[-1] * (Q(1, 2) - n + 1) / n)
y = {(k + 1, 0): c for k, c in enumerate(s)}; sq = {}
for (i, _), c in y.items():
    for (j, _), e in y.items(): sq[(i + j, 0)] = sq.get((i + j, 0), 0) + c * e
left = {k: v for k, v in sq.items() if v and k[0] <= 7}
ser = " ".join(("" if k == 1 else "- " if c < 0 else "+ ") + (f"{abs(c)} " if abs(c) != 1 else "") + mono(k, 0) for (k, _), c in sorted(y.items()))
print(f"node branches y = +-x sqrt(1 + x) = +-({ser} ...); recurrence = binomial: {'yes' if s == binom else 'no'}")
print(f"  (branch)^2 up to x^7 = {show(left)}, which is x^2(x + 1)")
assert s == binom and left == {(3, 0): 1, (2, 0): 1}

fam = lambda c: -c * (4 + 27 * c)                 # discriminant of x^3 + x^2 + c
crit = sorted(-x ** 3 - x ** 2 for x in (Q(0), Q(-2, 3)))  # F_x = 0 forces 3x^2 + 2x = 0
def roots(c, lo=-2.0, h=1e-4):                    # real roots of x^3 + x^2 + c by sign changes
    g = [(lo + k * h) * (lo + k * h) * (lo + k * h) + (lo + k * h) * (lo + k * h) + c for k in range(40001)]
    return sum((g[k] > 0) != (g[k - 1] > 0) for k in range(1, 40001))
print(f"family y^2 = x^3 + x^2 + c: singular only at c = {', '.join(map(str, crit))} (from F_y = F_x = F = 0); discriminant -c(4 + 27c) zero there: {'yes' if all(fam(c) == 0 for c in crit) else 'no'}")
for c in (Q(1, 100), Q(-1, 100)):
    k = roots(float(c))
    print(f"  c = {c}: discriminant {fam(c)}, {k} real root(s) of x^3 + x^2 + c, so {'one smooth piece' if k == 1 else 'an oval and a tail'}")
    assert (k == 3) == (fam(c) > 0) and fam(c) != 0
grad = [(ev(d(F, 0), 0, 0), ev(d(F, 1), 0, 0)) for _, F, _, _ in curves[:2] + [curves[4]]]
print(f"mistake 1, gradient only: cusp, node, tacnode all give gradient {', '.join(f'({g[0]}, {g[1]})' for g in grad)}: singular, type unknown")
print(f"mistake 2, lowest terms only: y^2 = x^3, x^4, x^5 all start y^2; real arcs {res['cusp y^2 = x^3'][2]}, {res['tacnode y^2 = x^4'][2]}, {res['y^2 = x^5'][2]}")
print(f"mistake 3, real slopes only: the lone dot has m = {res['neighbour y^2 = x^3 + x^2 - 4/27'][0]} but {len(res['neighbour y^2 = x^3 + x^2 - 4/27'][1])} real tangents; y^2 + x^2 = (y - ix)(y + ix)")
o_smooth = contact(curves[2][1], Q(-1), Q(0), 0, 1); o_node = contact(F_n, Q(0), Q(0), 1, Q(1))
print(f"mistake 4, one line only: x = -1 meets the smooth point (-1, 0) to order {o_smooth}; y = x meets the node to order {o_node}")
assert grad == [(0, 0)] * 3 and o_smooth == 2 and o_node == 3 and res['tacnode y^2 = x^4'][2] == 2 and all(fam(e) == 0 for e in crit) and o2 == 2 and ev(F_n, x2, y2) == 0 and G3 == {(3, 0): -1, (0, 2): 1}
k = 60                                            # figure: 60 units per unit length
px = lambda cx, x, y: f"({cx + k * x:.2f}, {170 - k * y:.2f})"
print(f"figure, {k} units per unit: node origin {px(100, 0, 0)}, (-1, 0) at {px(100, -1, 0)}; cusp origin {px(300, 0, 0)}, "
      f"(1, 1) at {px(300, 1, 1)}; lone dot {px(500, 0, 0)}, branch start (1, 0) at {px(500, 1, 0)}")
print("ALL CHECKS PASS")
