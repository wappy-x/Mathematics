# Geometric invariant theory in outline -- the check behind the card.  Standard
# library only.  Quotients by group actions, decided exactly: the sign group on
# the plane, the scalars giving P^2, a torus whose fibre over 0 holds orbits that
# are not closed, an additive group that breaks the rule, and four points on a
# line, whose quotient coordinate j is reached by three roads and counted mod 37.
from fractions import Fraction as F

def fr(v): return str(v.numerator) if v.denominator == 1 else f"{v.numerator}/{v.denominator}"
def ls(vals): return "[" + ", ".join(fr(v) for v in vals) + "]"
def yn(claim): return "yes" if claim else "no"

def orbits(points, moves):                  # orbits under a full list of group elements
    seen, out = set(), []
    for pt in points:
        if pt not in seen:
            orb = {m(pt) for m in moves}
            seen |= orb
            out.append(tuple(sorted(orb)))
    return sorted(out)
def classes(points, key):                   # points grouped by the value of key
    out = {}
    for pt in points:
        out.setdefault(key(pt), []).append(pt)
    return sorted(tuple(sorted(c)) for c in out.values())

p = 7
plane = [(x, y) for x in range(p) for y in range(p)]
signs = orbits(plane, [lambda v: v, lambda v: (-v[0] % p, -v[1] % p)])
sign_cls = classes(plane, lambda v: (v[0] * v[0] % p, v[0] * v[1] % p, v[1] * v[1] % p))
print(f"signs on F_7^2: {len(signs)} orbits, {len(sign_cls)} classes of equal (x^2, xy, y^2); same split: {yn(signs == sign_cls)}")
cone7 = {(u, v, w) for u in range(p) for v in range(p) for w in range(p) if (v * v - u * w) % p == 0}
print(f"cone v^2 = uw over F_7: {len(cone7)} points; values of (x^2, xy, y^2) on F_7^2: {len(sign_cls)} of them")
inv_deg = [sum(1 for a in range(d + 1) if d % 2 == 0) for d in range(9)]      # monomials x^a y^(d-a), d even
cone_deg = [0 if d % 2 else sum(1 for i in range(d // 2 + 1) for e in (0, 1) for k in range(d // 2 + 1)
                                if i + e + k == d // 2) for d in range(9)]     # u^i v^e w^k, v^2 replaced
print(f"invariants of degree 0 to 8: {inv_deg}; cone uw = v^2 by degree: {cone_deg}")
units5 = [lambda v, t=t: tuple(t * c % 5 for c in v) for t in range(1, 5)]
space = [(a, b, c) for a in range(5) for b in range(5) for c in range(5) if (a, b, c) != (0, 0, 0)]
lines5 = orbits(space, units5)
print(f"scalars on F_5^3 minus 0: {len(lines5)} orbits; P^2 over F_5 by charts: 25 + 5 + 1 = {25 + 5 + 1}")
print(f"degrees 0 to 4 whose monomials in x, y, z are fixed by t = 2: {[d for d in range(5) if F(2) ** d == 1]}")
torus = orbits(plane, [lambda v, t=t: (t * v[0] % p, pow(t, p - 2, p) * v[1] % p) for t in range(1, p)])
fibre0 = sorted(len(o) for o in torus if o[0][0] * o[0][1] % p == 0)
print(f"torus (tx, y/t) on F_7^2: {len(torus)} orbits, {len({v[0] * v[1] % p for v in plane})} values of xy; "
      f"orbit sizes over xy = 0: {fibre0}")
print(f"monomials x^a y^b, a + b <= 4, fixed by t = 2: {[(a, b) for a in range(5) for b in range(5 - a) if F(2) ** (a - b) == 1]}")
add_orbs = orbits(plane, [lambda v, s=s: (v[0], (v[1] + s * v[0]) % p) for s in range(p)])
print(f"additive group (x, y + sx) on F_7^2: {len(add_orbs)} orbits, all closed; the invariant x takes {p} values")

def cross(z1, z2, z3, z4):                  # send z1, z2, z3 to 0, infinity, 1: lambda is where z4 lands
    return (z4 - z1) * (z3 - z2) / ((z4 - z2) * (z3 - z1))
def jl(lam):                                # j as a function of the cross-ratio
    return 256 * (lam * lam - lam + 1) ** 3 / (lam * lam * (lam - 1) ** 2)
def quartic(roots):                         # coefficients of prod (x - r y), from x^4 down to y^4
    c = [F(1)]
    for r in roots:
        c = [(c[i] if i < len(c) else 0) - (r * c[i - 1] if i else 0) for i in range(len(c) + 1)]
    return c
def IJ(c):                                  # I, J of a0 x^4 + 4a1 x^3y + 6a2 x^2y^2 + 4a3 xy^3 + a4 y^4
    a, b, cc, d, e = c[0], c[1] / 4, c[2] / 6, c[3] / 4, c[4]
    return a * e - 4 * b * d + 3 * cc * cc, a * cc * e + 2 * b * cc * d - a * d * d - b * b * e - cc ** 3
def j_ij(c):
    i, j = IJ(c)
    return 1728 * i ** 3 / (i ** 3 - 27 * j * j)
def j_legendre(lam):                        # y^2 = x(x - 1)(x - lam), moved to short Weierstrass form
    pp, qq = -(1 + lam), lam
    a, b = qq - pp * pp / 3, -pp * qq / 3 + 2 * pp ** 3 / 27
    return 1728 * 4 * a ** 3 / (4 * a ** 3 + 27 * b * b)

def act(c, g):                              # substitute x -> g0 x + g1 y, y -> g2 x + g3 y
    out = [F(0)] * 5
    for k, ck in enumerate(c):
        term = [F(1)]
        for lin in [(g[0], g[1])] * (4 - k) + [(g[2], g[3])] * k:
            term = [(term[i] if i < len(term) else 0) * lin[0] + (term[i - 1] * lin[1] if i else 0)
                    for i in range(len(term) + 1)]
        out = [o + ck * t for o, t in zip(out, term)]
    return out

posts = [F(0), F(10), F(20), F(30)]
photo = [600 * z / (z + 20) for z in posts]
lam = cross(*posts)
perms = [(a, b, c, d) for a in range(4) for b in range(4) for c in range(4) for d in range(4) if len({a, b, c, d}) == 4]
six = sorted({cross(*[posts[i] for i in q]) for q in perms})
print(f"posts at {ls(posts)} m; photo at {ls(photo)} px")
print(f"cross-ratio of the posts {fr(lam)}, of the photo {fr(cross(*photo))}")
print(f"24 orderings give {len(six)} values: {ls(six)}")
print(f"j of the six: {ls(sorted({jl(v) for v in six}))}")
top = lam * lam - lam + 1
print(f"by hand at 3/4: lambda^2 - lambda + 1 = {fr(top)}, cubed {fr(top ** 3)}, times 256 = {fr(256 * top ** 3)}; "
      f"lambda^2 (lambda - 1)^2 = {fr(lam * lam * (lam - 1) ** 2)}")
print(f"j by the formula {fr(jl(lam))}; by I and J of the posts {fr(j_ij(quartic(posts)))}, "
      f"of the photo {fr(j_ij(quartic(photo)))}; by the Legendre curve {fr(j_legendre(lam))}")
g = (2, 1, 1, 1)
I0, J0 = IJ(quartic(posts))
I1, J1 = IJ(act(quartic(posts), g))
print(f"posts quartic: coefficients {ls(quartic(posts))}; a0..a4 = {ls([v / k for v, k in zip(quartic(posts), (1, 4, 6, 4, 1))])}")
print(f"posts quartic: I = {fr(I0)}, J = {fr(J0)}; after x -> 2x + y, y -> x + y: I = {fr(I1)}, J = {fr(J1)}")
h = F(-1)
print(f"harmonic lambda = -1, 2, 1/2: j = {ls([jl(F(v)) for v in (-1, 2, F(1, 2))])}; at -1: 256 x {fr((h * h - h + 1) ** 3 / (h * h * (h - 1) ** 2))}; "
      f"xy(x - y)(x + y) has J = {fr(IJ([F(0), F(1), F(0), F(-1), F(0)])[1])}, j = {fr(j_ij([F(0), F(1), F(0), F(-1), F(0)]))}")
hv = [cross(*[[F(-3), F(0), F(1), F(3)][i] for i in o]) for o in perms]      # a harmonic set: lambda = -1 in some order
print(f"harmonic set -3, 0, 1, 3: {len(hv)} orderings give {ls(sorted(set(hv)))}, orderings per value {[hv.count(v) for v in sorted(set(hv))]}")
q = 37
six_maps = [lambda l: l, lambda l: pow(l, q - 2, q), lambda l: (1 - l) % q, lambda l: pow(1 - l, q - 2, q),
            lambda l: l * pow(l - 1, q - 2, q) % q, lambda l: (l - 1) * pow(l, q - 2, q) % q]
jmod = lambda l: 256 * pow(l * l - l + 1, 3, q) * pow(l * l * (l - 1) ** 2, q - 2, q) % q
lam_orbs = orbits(list(range(2, q)), six_maps)
j_cls = classes(list(range(2, q)), jmod)
print(f"mod {q}: {len(lam_orbs)} orbits of the six moves on lambda = 2..{q - 1}, {len(j_cls)} values of j; "
      f"same split: {yn(lam_orbs == j_cls)}; orbit sizes {sorted(len(o) for o in lam_orbs)}")
w3 = next(x for x in range(2, q) if pow(x, 3, q) == 1); eq = [0, 1, w3, w3 * w3 % q]   # 0 and the three cube roots of 1
ev = [(eq[d] - eq[a]) * (eq[c] - eq[b]) * pow((eq[d] - eq[b]) * (eq[c] - eq[a]), q - 2, q) % q for a, b, c, d in perms]
print(f"mod {q}: equianharmonic set {eq}: values {sorted(set(ev))}, orderings per value {[ev.count(v) for v in sorted(set(ev))]}, j = {sorted({jmod(v) for v in ev})}")
for name, c in [("x y^3, triple root", [0, 0, 0, 1, 0]), ("x^2 y^2, two double roots", [0, 0, 1, 0, 0]),
                ("x^2 y^2 - x^3 y, one double root", [0, -1, 1, 0, 0])]:
    i, j = IJ([F(v) for v in c])
    wts = [4 - 2 * k for k in range(5) if c[k]]
    print(f"{name}: I = {fr(i)}, J = {fr(j)}, I^3 - 27J^2 = {fr(i ** 3 - 27 * j * j)}; torus weights {wts}")
t = F(1, 10)
print(f"x^2 y^2 - x^3 y moved by x -> tx, y -> y/t at t = 1/10: x^3 y coefficient {fr(-t * t)}, x^2 y^2 coefficient 1")
print(f"mistake 1, Spec of the scalars' invariants: 1 point, not the {len(lines5)} points of P^2 over F_5")
print(f"mistake 2, every torus orbit a point: {len(torus)} points, not {p}")
print(f"mistake 3, lambda as the coordinate of unordered points: {len(six)} values for one photo, not 1")
print(f"mistake 4, a non-reductive group: {len(add_orbs)} closed orbits, {p} values of the invariant")
print("figure, square -3 to 3 at 60 px per unit; (1, 1) at (270, 150); (1, -1) at (270, 270); origin at (210, 210)")
assert signs == sign_cls and len(signs) == (p * p - 1) // 2 + 1                       # finite group: classes = orbits
assert inv_deg == cone_deg                                                           # two counts of invariants
assert len(lines5) == 31 and len(torus) == p + 2 and fibre0 == [1, p - 1, p - 1]     # orbit counts
assert len(add_orbs) == 2 * p - 1 and all(len({a * b % p for a, b in o}) == 1 for o in torus)  # xy is invariant
assert lam == cross(*photo) == F(3, 4) and len(six) == 6                             # camera keeps lambda
assert jl(lam) == j_ij(quartic(posts)) == j_ij(quartic(photo)) == j_legendre(lam)    # three roads to j
assert len({jl(v) for v in six}) == 1 and (I0, J0) == (I1, J1)                       # j forgets the order
assert jl(F(-1)) == 1728 == j_legendre(F(-1))
assert sorted(set(hv)) == [-1, F(1, 2), 2] and [hv.count(v) for v in set(hv)] == [8, 8, 8]       # harmonic: 3 values
assert [ev.count(v) for v in set(ev)] == [12, 12] and {jmod(v) for v in ev} == {0}                # equianharmonic: 2 values
assert len(cone7) == p * p and {(x * x % p, x * y % p, y * y % p) for x, y in plane} < cone7       # the plane reaches 25 of 49
assert lam_orbs == j_cls                                                             # fibres of j are orbits
print("ALL CHECKS PASS")
