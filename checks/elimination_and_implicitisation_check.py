# Elimination and implicitisation -- the check behind the card.  Standard
# library only: Buchberger's algorithm, row reduction and the scan are written
# out here.  A polynomial is a dict {exponent tuple: Fraction}; comparing the
# tuples is the lex order, first variable biggest.  The folium is
# x = 3t/(1 + t^3), y = 3t^2/(1 + t^3), and its equation is found three ways.
from fractions import Fraction as Q
from math import prod, sqrt

def P(*terms): return {tuple(e): Q(c) for c, *e in terms}   # P((coef, exps...), ...)
def shift(p, c, m): return {tuple(a + b for a, b in zip(e, m)): c * v for e, v in p.items()}
def add(p, q):
    r = dict(p)
    for e, v in q.items():
        r[e] = r.get(e, 0) + v
        if r[e] == 0: del r[e]
    return r
def divides(a, b): return all(x <= y for x, y in zip(a, b))
def gap(a, b): return tuple(x - y for x, y in zip(a, b))

def reduce(p, G):                      # divide p by G; return the remainder
    r, p = {}, dict(p)
    while p:
        e = max(p)
        g = next((g for g in G if divides(max(g), e)), None)
        if g is None: r[e] = p.pop(e)
        else: p = add(p, shift(g, -p[e] / g[max(g)], gap(e, max(g))))
    return r

def groebner(F):                       # Buchberger, then the reduced basis
    G = [dict(f) for f in F]
    pairs = [(i, j) for j in range(len(G)) for i in range(j)]
    while pairs:
        f, g = (G[k] for k in pairs.pop(0))
        L = tuple(map(max, max(f), max(g)))
        s = add(shift(f, 1 / f[max(f)], gap(L, max(f))), shift(g, -1 / g[max(g)], gap(L, max(g))))
        r = reduce(s, G)
        if r:
            pairs += [(k, len(G)) for k in range(len(G))]
            G.append(r)
    G = [g for k, g in enumerate(G) if not any(divides(max(h), max(g)) and
         (max(h) != max(g) or m < k) for m, h in enumerate(G) if m != k)]
    G = [reduce(g, [h for h in G if h is not g]) for g in G]
    return sorted(({e: v / g[max(g)] for e, v in g.items()} for g in G), key=max, reverse=True)

def show(p, names):
    out = ""
    for e in sorted(p, reverse=True):
        c, m = p[e], "*".join(n + (f"^{k}" if k > 1 else "") for n, k in zip(names, e) if k)
        body = (m if abs(c) == 1 else f"{abs(c)}*{m}") if m else f"{abs(c)}"
        out += ("-" if c < 0 else "") + body if not out else (" - " if c < 0 else " + ") + body
    return out or "0"

def free_of(G, k): return [g for g in G if all(e[k] == 0 for e in g)]
def nullspace(rows):                   # row-reduce; return the null vectors
    M, piv, r = [row[:] for row in rows], [], 0
    for c in range(len(M[0])):
        k = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if k is None: continue
        M[r], M[k] = [v / M[k][c] for v in M[k]], M[r]
        for i in range(len(M)):
            if i != r and M[i][c] != 0: M[i] = [a - M[i][c] * b for a, b in zip(M[i], M[r])]
        piv.append(c); r += 1
    free = [c for c in range(len(M[0])) if c not in piv]
    return [[Q(c == f) - (M[piv.index(c)][f] if c in piv else 0) for c in range(len(M[0]))] for f in free]

def ev(p, pt): return sum(c * prod(v ** k for v, k in zip(pt, e)) for e, c in p.items())
def lead_coef(g):                      # the coefficient of the top power of the first variable
    n = max(e[0] for e in g)
    return {(0,) + e[1:]: c for e, c in g.items() if e[0] == n}
def point(t): return 3 * t / (1 + t * t * t), 3 * t * t / (1 + t * t * t)
def F(x, y): return x ** 3 + y ** 3 - 3 * x * y
yn = lambda b: "yes" if b else "no"

# ---- road 1: lex basis with t > x > y; keep what is free of t ----
fol = [P((1, 3, 1, 0), (1, 0, 1, 0), (-3, 1, 0, 0)), P((1, 3, 0, 1), (1, 0, 0, 1), (-3, 2, 0, 0))]
G = groebner(fol)
print("lex basis, t > x > y, of (1 + t^3)x - 3t and (1 + t^3)y - 3t^2:")
for g in G: print("  " + show(g, "txy"))
cubic = free_of(G, 0)
print(f"basis polynomials free of t: {len(cubic)}, namely {show(cubic[0], 'txy')}")
lift = [{(0,) + e: c for e, c in f.items()} for f in fol]
GW = groebner(lift + [P((1, 1, 3, 0, 0), (1, 1, 0, 0, 0), (-1, 0, 0, 0, 0))])
cubic_w = free_of(free_of(GW, 0), 1)
print(f"with w and (1 + t^3)w = 1 added, free of w and t: {show(cubic_w[0], 'wtxy')}")
# ---- road 2: the lowest-degree curve through 12 points of the folium ----
ts = [Q(p, q) for p, q in [(0, 1), (1, 1), (2, 1), (-2, 1), (3, 1), (1, 2), (-1, 2),
                           (1, 3), (2, 3), (3, 2), (-3, 1), (-1, 3)]]
for deg in (2, 3):
    mons = [(a, b) for a in range(deg, -1, -1) for b in range(deg - a, -1, -1)]
    ns = nullspace([[x ** a * y ** b for a, b in mons] for x, y in map(point, ts)])
    print(f"curves of degree <= {deg} through the {len(ts)} points: {len(ns)}")
v = ns[0]; fit = {(0, a, b): c / v[0] for (a, b), c in zip(mons, v) if c}
print(f"the one of degree 3: {show(fit, 'txy')}")
# ---- road 3: put points back in exactly ----
back = [F(*point(Q(t, 2))) for t in range(-7, 8) if t != -2]
print(f"F(x(t), y(t)) at 14 values of t from -7/2 to 7/2: all zero: {yn(back == [0] * 14)}; off the curve, F(1, 1) = {F(Q(1), Q(1))}")
for t in (1, 2):
    x, y = point(Q(t))
    print(f"t = {t}: 3t = {3 * t}, 3t^2 = {3 * t * t}, D = 1 + t^3 = {1 + t ** 3}, (x, y) = ({x}, {y}), x^3 + y^3 = {x ** 3 + y ** 3}, 3xy = {3 * x * y},"
          f" t back from t*x - y = 0: {y / x}")
witht = [g for g in G if any(e[0] for e in g)]
lcs = [lead_coef(g) for g in witht]
print(f"leading coefficients in t: {', '.join(show(c, 'txy') for c in lcs)}; at the node (0, 0): "
      f"{', '.join(str(ev(c, (0, 0, 0))) for c in lcs)}")
at_node = [{e: c for e, c in g.items() if e[1] == e[2] == 0} for g in witht]
print(f"the basis at x = y = 0: {', '.join(show(g, 'txy') for g in at_node)}; so t = 0, and"
      f" (t, x, y) = (0, 0, 0) satisfies all four: {yn(all(ev(g, (0, 0, 0)) == 0 for g in G))}")
# ---- solving: the top of the loop, where F = 0 and dF/dx = 0 ----
GT = groebner([P((1, 3, 0), (1, 0, 3), (-3, 1, 1)), P((1, 2, 0), (-1, 0, 1))])
print("lex basis, x > y, of F and (dF/dx)/3 = x^2 - y:")
for g in GT: print("  " + show(g, "xy"))
ytop = 4 ** (1 / 3); xtop = ytop * ytop / 2
print(f"eliminant y^2*(y^3 - 4): real roots 0 and {ytop:.6f}; extend: x = y^2/2 = {xtop:.6f}")
best = max((point(i / 100000)[1], i / 100000) for i in range(400001))
print(f"scan of y(t), t = 0 to 4 in steps of 0.00001: highest y {best[0]:.6f} at t = {best[1]:.5f}, where x = {point(best[1])[0]:.5f}")
# ---- what breaks ----
Gbad = groebner([P((1, 1, 0, 3), (1, 1, 0, 0), (-3, 0, 0, 1)), P((1, 0, 1, 3), (1, 0, 1, 0), (-3, 0, 0, 2))])
print(f"mistake 1, lex x > y > t: basis polynomials free of t: {len(free_of(Gbad, 2))}")
Gnod = groebner([P((1, 0, 1, 0), (-3, 1, 0, 0)), P((1, 0, 0, 1), (-3, 2, 0, 0))])
x, y = point(Q(2))
print(f"mistake 2, denominator dropped: {show(free_of(Gnod, 0)[0], 'txy')}; "
      f"at (2/3, 4/3) it gives {x * x - 3 * y}")
print(f"mistake 3, root y = 0 taken as a top: x = 0, (dF/dy)/3 = y^2 - x = "
      f"{ev(P((1, 0, 2), (-1, 1, 0)), (0, 0, 0))} there too: both slopes vanish, a node")
Ghyp = groebner([P((1, 1, 1), (-1, 0, 0))])
print(f"mistake 4, x*y - 1 with x > y: free of x: {len(free_of(Ghyp, 0))}; leading coefficient "
      f"{show(lead_coef(Ghyp[0]), 'xy')} is {ev(lead_coef(Ghyp[0]), (0, 0))} at y = 0, so 0*x - 1 = 0 has no x")
# ---- the house example: elbow (a, b), links 3 m and 2 m, hand at (4, 0) ----
GA = groebner([P((1, 2, 0), (1, 0, 2), (-9, 0, 0)), P((1, 2, 0), (-8, 1, 0), (1, 0, 2), (12, 0, 0))])
print(f"arm, lex a > b: {show(GA[0], 'ab')} and {show(GA[1], 'ab')}; b = +-{sqrt(-GA[1].get((0, 0), 0)):.6f} m")
x, y = map(float, point(Q(2)))
print(f"figure, node (0, 0), t=1 (1.5, 1.5), t=2 ({x:.4f}, {y:.4f}), top ({xtop:.4f}, {ytop:.4f})")
want = P((1, 0, 3, 0), (-3, 0, 1, 1), (1, 0, 0, 3))
assert cubic == [want] and fit == want and cubic_w[0] == {(0,) + e: c for e, c in want.items()}
assert back == [0] * 14 and F(*point(Q(2))) == 0 and all(ev(g, (0, 0, 0)) == 0 for g in G)
assert free_of(GT, 0) == [P((1, 0, 5), (-4, 0, 2))] and abs(best[0] - ytop) < 1e-9
assert abs(best[1] - 2 ** (1 / 3)) < 1e-5 and len(free_of(Gbad, 2)) == 0
assert GA == [P((1, 1, 0), (Q(-21, 8), 0, 0)), P((1, 0, 2), (Q(-135, 64), 0, 0))]
assert G == [P((1, 2, 0, 1), (-3, 1, 0, 0), (1, 0, 1, 0)), P((1, 1, 1, 0), (-1, 0, 0, 1)), P((1, 1, 0, 2), (1, 0, 2, 0), (-3, 0, 0, 1)), want]
print("ALL CHECKS PASS")
