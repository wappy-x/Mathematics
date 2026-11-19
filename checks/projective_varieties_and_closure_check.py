# Projective varieties and closure -- the check behind the card.
# Standard library only.  Fraction keeps every step exact.  A 50 mm lens obeys
# Newton's equation x y = 1 (distances from the two focal points, in focal lengths).
# Homogenise to x y = z^2, find its points at infinity three ways, dehomogenise into
# every chart and back, then count over F_p and test the homogenised system.
from fractions import Fraction as Q

def deg(m): return sum(m)
def clean(P): return {m: c for m, c in P.items() if c != 0}
def add(P, R): return clean({m: P.get(m, 0) + R.get(m, 0) for m in set(P) | set(R)})
def mul(P, R):
    out = {}
    for m, c in P.items():
        for n, e in R.items():
            k = tuple(a + b for a, b in zip(m, n)); out[k] = out.get(k, 0) + c * e
    return clean(out)
def sc(c, P): return clean({m: c * v for m, v in P.items()})
def dehom(P, i):                                  # set coordinate i equal to 1
    out = {}
    for m, c in P.items():
        k = tuple(0 if j == i else e for j, e in enumerate(m)); out[k] = out.get(k, 0) + c
    return clean(out)
def rehom(P, i):                                  # pad coordinate i up to the top degree
    d = max(deg(m) for m in P)
    return {tuple(d - deg(m) + e if j == i else e for j, e in enumerate(m)): c for m, c in P.items()}
def ev(P, v):
    tot = Q(0)
    for m, c in P.items():
        t = Q(c)
        for a, e in zip(v, m): t *= Q(a) ** e
        tot += t
    return tot
def show(P):
    s = ""
    for m, c in sorted(P.items(), key=lambda t: [-e for e in t[0]]):
        mono = "".join(n + ("" if e == 1 else f"^{e}") for n, e in zip("xyz", m) if e)
        a = abs(Q(c)); num = "" if a == 1 and mono else (f"{a} " if a.denominator > 1 and mono else str(a))
        s += ("-" if c < 0 else "") + num + mono if not s else (" - " if c < 0 else " + ") + num + mono
    return s
def modp(q, p): return q.numerator * pow(q.denominator, p - 2, p) % p
def yn(c): return "yes" if c else "no"
def pt(v): return "(" + " : ".join(str(c) for c in v) + ")"
def pr(a, b): return f"({a}, {b})"
def norm(v, p=0):                                 # scale so the first nonzero entry is 1
    i = next(k for k, c in enumerate(v) if (c % p if p else c))
    if p: inv = pow(v[i], p - 2, p); return tuple(c * inv % p for c in v)
    return tuple(Q(c) / v[i] for c in v)

X, Y, Z, ONE = {(1, 0, 0): 1}, {(0, 1, 0): 1}, {(0, 0, 1): 1}, {(0, 0, 0): 1}
f = add(mul(X, Y), sc(-1, ONE))                   # x y - 1
F = rehom(f, 2)
print("lens of focal length 50 mm; x, y = object and image distances from the focal points, in focal lengths")
print(f"Newton's equation f = {show(f)} = 0; object at 100 mm: x = 2, image y = {Q(1, 2)} (25 mm); f = {ev(f, (2, Q(1, 2), 1))}")
tests = [(2, 3, 1), (5, -1, 2), (Q(1, 2), 7, -3), (4, 4, 4), (-2, 9, 5)]
subst = all(ev(F, v) == Q(v[2]) ** 2 * ev(f, (Q(v[0]) / v[2], Q(v[1]) / v[2], 1)) for v in tests)
print(f"homogenise (degree 2): F = {show(F)}; z^2 f(x/z, y/z) agrees at {len(tests)} test points: {yn(subst)}")
ch = [dehom(F, i) for i in (2, 0, 1)]
back = [rehom(g, i) for g, i in zip(ch, (2, 0, 1))]
print(f"dehomogenise F: chart z = 1: {show(ch[0])}; chart x = 1: {show(ch[1])}; chart y = 1: {show(ch[2])}")
print(f"rehomogenise each chart: {', '.join(show(b) for b in back)}; all equal F: {yn(all(b == F for b in back))}")
top = {m: c for m, c in f.items() if deg(m) == 2}
grid = [(a, b) for a in range(-3, 4) for b in range(-3, 4) if (a, b) != (0, 0)]
def online(line):                                 # F along a line is al a^2 + be ab + ga b^2: its real points
    al, ga = ev(F, line(1, 0)), ev(F, line(0, 1)); be = ev(F, line(1, 1)) - al - ga; dc = be * be - 4 * al * ga
    return dc, (dc > 0) + (dc >= 0), sorted({norm(line(a, b)) for a, b in grid if ev(F, line(a, b)) == 0}, reverse=True)
LINES = (("z = 0", lambda a, b: (a, b, 0)), ("x = 0", lambda a, b: (0, a, b)), ("x + y = 0", lambda a, b: (a, -a, b)))
dz, _, inf = online(LINES[0][1])                  # by the discriminant's sign (2, 1 or 0), and by a search
print(f"points at infinity: F(x, y, 0) = {show(top)} = 0, discriminant {dz}, gives {', '.join(pt(v) for v in inf)}")
far = [(Q(10) ** k, Q(10) ** -k) for k in (1, 2, 3)]
print("far object, chart x = 1 address (y/x, z/x): " + "; ".join(f"x = {a}: {pr(b / a, 1 / a)}" for a, b in far))
print("object near the front focus, chart y = 1 address (x/y, z/y): " + "; ".join(f"x = {b}: {pr(b / a, 1 / a)}" for a, b in far))
par = lambda s, t: (s * s, t * t, s * t)          # (s : t) -> (s^2 : t^2 : st)
pin = [norm(par(*st)) for st in ((1, 0), (0, 1), (2, 1))]
print(f"parametrisation (s^2 : t^2 : st): (1 : 0) -> {pt(pin[0])}, (0 : 1) -> {pt(pin[1])}, (2 : 1) -> {pt(par(2, 1))} = {pr(Q(4, 2), Q(1, 2))}")
obj = (Q(1, 4), Q(1, 2))
print(f"the 100 mm object in chart x = 1: {pr(*obj)}; on y = z^2: {yn(ev(ch[1], (1, *obj)) == 0)}")
img = (5 - 4, 5 + 4, 3)                           # (x : y : z) -> (z - y : z + y : x)
print(f"house cone x^2 + y^2 = z^2 to this conic, (x : y : z) -> (z - y : z + y : x): (3 : 4 : 5) -> {pt(img)} = "
      f"{pr(Q(1, 3), Q(9, 3))}; xy = z^2: {yn(ev(F, img) == 0)}")
cnt = []
for name, line in LINES:
    dc, nr, real = online(line); cnt.append((nr, len(real)))
    print(f"line at infinity {name}: discriminant {dc}, real points on F {nr}; search finds {len(real)}{''.join(', ' + pt(v) for v in real)}")
e, isq = (Q(1, 2),) * 3, 0 * 0 - 1 * 1           # chart x + y = 1, u = x - y: u^2 + 4 z^2 = 1
print(f"  chart x + y = 1, u = x - y: ellipse u^2 + 4z^2 = 1; (1 : 1 : 1) is u = {e[0] - e[1]}, z = {e[2]}: "
      f"{yn((e[0] - e[1]) ** 2 + 4 * e[2] ** 2 == 1)}; over C, F(1, -1, i) = F(1, -1, -i) = -1 - i^2 = {-1 - isq}")
asy = {m: c for m, c in F.items() if m[1] == 0}
print(f"asymptote y = 0: F becomes {show(asy)}, a double root z = 0 at (1 : 0 : 0): tangent at infinity")
xz = add(mul(X, X), {(0, 0, 2): 1})                # x^2 + 1 padded; over R x^2 + 1 is never 0
print(f"over R, x^2 + 1 has no affine zero, yet its padding {show(xz)} vanishes at (0 : 1 : 0): {yn(ev(xz, (0, 1, 0)) == 0)}")
print("over F_p: affine xy = 1 / closure xy = z^2 / at infinity / parametrisation / house cone")
for p in (5, 7, 11, 13):
    trip = [(a, b, c) for a in range(p) for b in range(p) for c in range(p) if (a, b, c) != (0, 0, 0)]
    clo = {norm(v, p) for v in trip if (v[0] * v[1] - v[2] ** 2) % p == 0}
    aff = sum(1 for a in range(p) for b in range(p) if (a * b - 1) % p == 0)
    pp = {norm(par(s, t), p) for s, t in [(1, t) for t in range(p)] + [(0, 1)]}
    cone = {norm(v, p) for v in trip if (v[0] ** 2 + v[1] ** 2 - v[2] ** 2) % p == 0}
    atinf = sum(1 for v in clo if v[2] == 0)
    print(f"p = {p}: {aff} {len(clo)} {atinf} {len(pp)} {len(cone)}")
    assert len(clo) == aff + 2 == len(pp) == len(cone) == p + 1 and pp == clo and atinf == 2
    if p == 7: trip7 = trip
g1, g2 = f, add(Y, sc(-2, ONE))                   # the system x y = 1, y = 2
gb = [add(X, sc(Q(-1, 2), ONE)), g2]              # grevlex x > y basis of <g1, g2>
c1 = add(g1, sc(-1, mul(X, g2))) == sc(2, gb[0])
c2 = add(mul(sc(Q(1, 2), Y), sc(2, gb[0])), sc(Q(1, 2), g2)) == g1
each, base = [rehom(g1, 2), rehom(g2, 2)], [rehom(g, 2) for g in gb]
box = [(a, b, c) for a in range(-4, 5) for b in range(-4, 5) for c in range(-4, 5) if (a, b, c) != (0, 0, 0)]
common = lambda S: sorted({norm(v) for v in box if all(ev(P, v) == 0 for P in S)}, reverse=True)
cnt7 = lambda S: len({norm(v, 7) for v in trip7 if all(modp(ev(P, v), 7) == 0 for P in S)})
print(f"system {{{show(g1)}, {show(g2)}}}: affine solution {pr(Q(1, 2), 2)}")
print(f"  homogenise each equation {{{', '.join(map(show, each))}}}: {', '.join(pt(v) for v in common(each))}")
print(f"  grevlex (x > y) Groebner basis {{{', '.join(map(show, gb))}}}; both certificates hold: {yn(c1 and c2)}")
print(f"  homogenised basis {{{', '.join(map(show, base))}}}: {', '.join(pt(v) for v in common(base))}")
print(f"  over F_7: homogenised equations {cnt7(each)} points, homogenised basis {cnt7(base)}")
print(f"mistake 1, closure of the system from its homogenised equations: {cnt7(each)} points, not {cnt7(base)}")
print(f"mistake 2, line y = 2 met in the affine plane only: {len([v for v in common(each) if v[2] != 0])}, not {len(common(each))}")
print(f"mistake 3, z = 0 set before homogenising: f(x, y) has no z, so {show(f)} = 0 becomes -1 = 0: 0 points, not {len(inf)}")
G = mul(X, F); G2 = rehom(dehom(G, 0), 0)
n7 = lambda P: len({norm(v, 7) for v in trip7 if modp(ev(P, v), 7) == 0})
print(f"mistake 4, {show(G)} through chart x = 1 and back: {show(G2)}; over F_7 {n7(G2)} points, not {n7(G)}")
h2 = add(mul(X, X), sc(-1, Y))                    # a second system: x y = 1 and y = x^2, three solutions
lx = [add(X, sc(-1, mul(Y, Y))), add(mul(Y, mul(Y, Y)), sc(-1, ONE))]   # its lex (x > y) basis: x - y^2, y^3 - 1
c3 = (lx[0] == add(mul(Y, h2), sc(-1, mul(X, f))) and lx[1] == add(sc(-1, mul(Y, lx[0])), f)
      and f == add(mul(Y, lx[0]), lx[1]) and h2 == add(mul(lx[0], add(X, mul(Y, Y))), mul(Y, lx[1])))
aff3 = sum(1 for a in range(7) for b in range(7) if (a * b - 1) % 7 == 0 and (b - a * a) % 7 == 0)
lxh, grh = [rehom(g, 2) for g in lx], [rehom(g, 2) for g in (h2, f, lx[0])]   # grh: a graded basis, padded
at100 = all(ev(P, (1, 0, 0)) == 0 for P in lxh)
print(f"mistake 5, {{{show(f)}, {show(h2)}}} has {aff3} solutions over F_7; certificates for its lex (x > y) basis "
      f"{{{', '.join(map(show, lx))}}} hold: {yn(c3)}")
print(f"  padded lex basis {{{', '.join(map(show, lxh))}}}: {cnt7(lxh)} points over F_7, zero at (1 : 0 : 0): {yn(at100)}; "
      f"padded graded basis {{{', '.join(map(show, grh))}}}: {cnt7(grh)}; {show(grh[0])} at (1 : 0 : 0) = {ev(grh[0], (1, 0, 0))}")
k, cx, cy, kr, rx, ry = 40, 160, 170, 80, 480, 300
print(f"figure, left 40 and right 80 units per focal length: object {pr(cx + k * 2, cy - k * Q(1, 2))}, vertices "
      f"{pr(cx + k, cy - k)} {pr(cx - k, cy + k)}; right object {pr(rx + kr * obj[1], ry - kr * obj[0])}, (1 : 0 : 0) at {pr(rx, ry)}")
assert subst and all(b == F for b in back) and inf == [(1, 0, 0), (0, 1, 0)] and pin[:2] == inf
assert c1 and c2 and common(each) == [(1, 4, 2), (1, 0, 0)] and common(base) == [(1, 4, 2)]
assert ev(F, img) == 0 and n7(G) == 15 and n7(G2) == 8 and ev(ch[1], (1, *obj)) == 0
assert cnt == [(2, 2), (1, 1), (0, 0)] and dz == 1                 # discriminant and search agree on each line
assert c3 and cnt7(lxh) == aff3 + 1 == 4 and cnt7(grh) == aff3 and at100 and ev(grh[0], (1, 0, 0)) == 1
print("ALL CHECKS PASS")
