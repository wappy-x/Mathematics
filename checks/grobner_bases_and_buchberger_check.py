# Grobner bases and Buchberger's algorithm -- the check behind the card.
# Standard library only.  A polynomial in x and y is a dict {(i, j): c} for the
# term c x^i y^j, with exact Fraction coefficients.  The order is lex, x > y, so
# the leading term has the largest pair (i, j).  Nothing imported knows a basis.
from fractions import Fraction as F
from math import sqrt

def lead(f): return max(f)

def add(f, g, c, m):                          # f + c * x^m0 y^m1 * g
    out = dict(f)
    for (i, j), a in g.items():
        k = (i + m[0], j + m[1])
        out[k] = out.get(k, 0) + c * a
        if out[k] == 0: del out[k]
    return out

def mul(f, g):                                # plain product, term by term
    out = {}
    for m, a in f.items(): out = add(out, g, a, m)
    return out

def divide(f, divs):                          # division by a list: the remainder
    p, r = dict(f), {}
    while p:
        m = lead(p)
        for g in divs:
            n = lead(g)
            if n[0] <= m[0] and n[1] <= m[1]:
                p = add(p, g, -p[m] / g[n], (m[0] - n[0], m[1] - n[1])); break
        else: r[m] = p.pop(m)
    return r

def spoly(f, g):                              # cancel the two leading terms
    a, b = lead(f), lead(g)
    L = (max(a[0], b[0]), max(a[1], b[1]))
    s = add({}, f, 1 / f[a], (L[0] - a[0], L[1] - a[1]))
    return add(s, g, -1 / g[b], (L[0] - b[0], L[1] - b[1]))

def gcd(a, b):
    while b: a, b = b, a % b
    return abs(a)

def tidy(f):                                  # whole coefficients, no common factor
    d, n = 1, 0
    for c in f.values(): d = d * c.denominator // gcd(d, c.denominator)
    for c in f.values(): n = gcd(n, c.numerator * (d // c.denominator))
    s = F(d, n) if f[lead(f)] > 0 else F(-d, n)
    return {m: c * s for m, c in f.items()}

def show(f):
    out = ""
    for (i, j) in sorted(f, reverse=True):
        c = f[(i, j)]; a = abs(c)
        mono = ("x" if i else "") + (f"^{i}" if i > 1 else "") + ("y" if j else "") + (f"^{j}" if j > 1 else "")
        coef = "" if a == 1 and mono else (f"({a})" if a.denominator > 1 and mono else str(a))
        out += ("-" if c < 0 else "") if not out else (" - " if c < 0 else " + ")
        out += coef + mono
    return out or "0"

def buchberger(G, talk):                      # add remainders until every pair gives 0
    G, zero = [tidy(g) for g in G], 0
    pairs = [(i, j) for j in range(len(G)) for i in range(j)]
    while pairs:
        i, j = pairs.pop(0)
        s = spoly(G[i], G[j]); r = divide(s, G)
        if r:
            G.append(tidy(r)); pairs += [(k, len(G) - 1) for k in range(len(G) - 1)]
        else: zero += 1
        if talk: print(f"pair (f{i+1}, f{j+1}): S = {show(s)}; remainder {show(r)}"
                       + (f" -> new f{len(G)} = {show(G[-1])}" if r else ""))
    return G, zero

def P(*terms): return {(i, j): F(c) for c, i, j in terms}     # c x^i y^j, ...
def arm(A): return [P((1, 2, 0), (1, 0, 2), (-9, 0, 0)),     # elbow 3 m from shoulder
                    P((1, 2, 0), (-2 * A, 1, 0), (1, 0, 2), (A * A - 4, 0, 0))]  # 2 m from target

A = F(4)
f1, f2 = arm(A)
print(f"arm: links 3 m and 2 m, shoulder (0, 0), target ({A}, 0); order lex x > y")
print(f"f1 = {show(f1)}   f2 = {show(f2)}")
G, zero = buchberger([f1, f2], True)
s13, s23 = spoly(G[0], G[2]), spoly(G[1], G[2])
print(f"by hand: S(f1, f3) = f1 - ({1 / G[2][(1, 0)]})x f3, then take away {s13[(1, 0)] / G[2][(1, 0)]} f3;"
      f" S(f2, f3) leaves {show(divide(s23, G[:3]))} = ({1 / G[3][(0, 2)]}) f4")
print(f"pairs checked {len(G) * (len(G) - 1) // 2}, new members {len(G) - 2}, remainders 0: {zero}")
crit = all(not divide(spoly(G[i], G[j]), G) for j in range(len(G)) for i in range(j))
print(f"criterion on the final basis: all {len(G) * (len(G) - 1) // 2} S-polynomials divide to 0: {'yes' if crit else 'no'}")
coprime = [(i + 1, j + 1) for j in range(len(G)) for i in range(j)
           if min(lead(G[i])[0], lead(G[j])[0]) == 0 and min(lead(G[i])[1], lead(G[j])[1]) == 0]
print(f"pairs with leading terms sharing no variable (can be skipped; here they also divide to 0): {coprime}")
xb = (9 + A * A - 4) / (2 * A); yy = 9 - xb * xb                # road two: the law of cosines
print(f"law of cosines: elbow x = (9 + {A * A} - 4)/(2*{A}) = {xb}, y^2 = 9 - x^2 = {yy}")
g3, g4 = tidy(P((1, 1, 0), (-xb, 0, 0))), tidy(P((1, 0, 2), (-yy, 0, 0)))
print(f"as polynomials: {show(g3)} and {show(g4)}; same as f3, f4: {'yes' if [g3, g4] == G[2:] else 'no'}")
print(f"tidy basis (Normal forms card): x - {xb}, y^2 - {yy}")
c1 = add(f1, f2, F(-1), (0, 0))                                 # road three: certificates
c2 = add(mul(P((43, 0, 0), (-8, 1, 0)), f1), mul(P((8, 1, 0), (21, 0, 0)), f2), F(1), (0, 0))
print(f"certificates: f1 - f2 = {show(c1)};  (43 - 8x)f1 + (8x + 21)f2 = {show(c2)}")
elbows = [(xb, s) for s in (1, -1)]
print("elbows " + " and ".join(f"({float(x):.6f}, {s * sqrt(yy):.6f})" for x, s in elbows)
      + f" put back exactly: f1 = {xb * xb + yy - 9}, f2 = {(xb - A) ** 2 + yy - 4}")
std = [(i, j) for i in range(3) for j in range(3) if not any(i >= lead(g)[0] and j >= lead(g)[1] for g in G)]
print(f"monomials no leading term divides: {[show(P((1, i, j))) for i, j in std]} -> {len(std)} elbows over the complex numbers")
print(f"figure, shoulder (0, 0) r 3; target ({A}, 0) r 2; line x = {float(xb):.3f}; elbows y = +-{sqrt(yy):.6f}")
r1 = divide(G[2], [f1, f2]); r2 = divide(G[3], G[:3])
print(f"mistake 1, f3 = {show(G[2])} divided by [f1, f2] leaves {show(r1)}; by the basis, {show(divide(G[2], G))}")
print(f"mistake 2, stopping after f3: {show(G[3])} divided by [f1, f2, f3] leaves {show(r2)}")
h, u, v = P((1, 2, 1), (1, 1, 2), (1, 0, 2)), P((1, 1, 1), (-1, 0, 0)), P((1, 0, 2), (-1, 0, 0))
ra, rb = divide(h, [u, v]), divide(h, [v, u])
print(f"mistake 3, {show(h)} divided by [{show(u)}, {show(v)}] leaves {show(ra)}; in the other order, {show(rb)}")
H, _ = buchberger([u, v], False)
orders = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
rs = [show(divide(h, [H[k] for k in o])) for o in orders]
print(f"after Buchberger adds {show(H[2])}: the 6 orders of the 3 divisors leave {sorted(set(rs))}")
print(f"the gap {show(add(rb, ra, F(-1), (0, 0)))} = y(xy - 1) - x(y^2 - 1) = {show(add(mul(P((1, 0, 1)), u), mul(P((1, 1, 0)), v), F(-1), (0, 0)))}")
G6, _ = buchberger(arm(F(6)), False)
y6 = -G6[3][(0, 0)] / G6[3][(0, 2)]
print(f"mistake 4, target 6 m away: new members {show(G6[2])} and {show(G6[3])}, so y^2 = {y6}: no real elbow")
assert [show(g) for g in G[2:]] == ["8x - 21", "64y^2 - 135"]        # the hand computation
assert spoly(G[0], G[2]) == P((F(21, 8), 1, 0), (1, 0, 2), (-9, 0, 0))   # S(f1, f3) by hand
assert crit and [g3, g4] == G[2:] and len(std) == 2                  # criterion, cosines, count
assert c1 == G[2] and c2 == G[3]                                     # members of <f1, f2>
assert xb * xb + yy == 9 and (xb - A) ** 2 + yy == 4                 # elbows on both circles
assert ra != rb and len(set(rs)) == 1 and not divide(add(ra, rb, F(-1), (0, 0)), H)
assert r1 and r2 and not divide(G[3], G) and y6 < 0
print("ALL CHECKS PASS")
