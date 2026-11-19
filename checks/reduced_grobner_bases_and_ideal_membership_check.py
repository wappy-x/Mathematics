# Normal forms and ideal membership -- the check behind the card.  Standard library
# only; fractions does exact rational arithmetic and nothing more.  Polynomials in x, y
# over the rationals are dicts {(i, j): coefficient of x^i y^j}; order lex, x > y unless
# said.  Division, S-polynomials, Buchberger and reduction are all written out here.
from fractions import Fraction as F

XY = lambda m: m                 # lex, x > y: compare the x power first
YX = lambda m: (m[1], m[0])      # lex, y > x: compare the y power first

def P(*terms):                   # P((c, i, j), ...) builds c x^i y^j + ...
    p = {}
    for c, i, j in terms:
        p[(i, j)] = p.get((i, j), 0) + F(c)
    return {m: c for m, c in p.items() if c != 0}

def add(p, q, s=1):              # p + s q
    r = dict(p)
    for m, c in q.items():
        r[m] = r.get(m, 0) + s * c
    return {m: c for m, c in r.items() if c != 0}

def mul(p, q):
    r = {}
    for (a, b), c in p.items():
        for (d, e), k in q.items():
            r[(a + d, b + e)] = r.get((a + d, b + e), 0) + c * k
    return {m: c for m, c in r.items() if c != 0}

def lt(p, o): return max(p, key=o)
def divides(m, n): return m[0] <= n[0] and m[1] <= n[1]

def nf(f, G, o=XY):              # divide f by the list G; return the remainder r
    p, r = dict(f), {}
    while p:
        m = lt(p, o)
        for g in G:
            n = lt(g, o)
            if divides(n, m):
                p = add(p, mul({(m[0] - n[0], m[1] - n[1]): p[m] / g[n]}, g), -1)
                break
        else:
            r[m] = p.pop(m)
    return r

def spoly(f, g, o):              # cancel the two leading terms against each other
    a, b = lt(f, o), lt(g, o)
    L = (max(a[0], b[0]), max(a[1], b[1]))
    return add(mul({(L[0] - a[0], L[1] - a[1]): 1 / f[a]}, f),
               mul({(L[0] - b[0], L[1] - b[1]): 1 / g[b]}, g), -1)

def buchberger(F_, o=XY):        # add remainders of S-polynomials until all reduce to 0
    G = [dict(f) for f in F_]
    pairs = [(i, j) for j in range(len(G)) for i in range(j)]
    while pairs:
        i, j = pairs.pop(0)
        r = nf(spoly(G[i], G[j], o), G, o)
        if r:
            pairs += [(k, len(G)) for k in range(len(G))]
            G.append(r)
    return G

def reduce_basis(G, o=XY):       # the unique tidy form: drop, make monic, clean the tails
    keep = [g for i, g in enumerate(G)
            if not any(divides(lt(h, o), lt(g, o)) and (lt(h, o) != lt(g, o) or j < i)
                       for j, h in enumerate(G) if j != i)]
    keep = [{m: c / g[lt(g, o)] for m, c in g.items()} for g in keep]
    out = []
    for i, g in enumerate(keep):
        head = lt(g, o)
        tail = nf({m: c for m, c in g.items() if m != head}, keep[:i] + keep[i + 1:], o)
        out.append(add({head: F(1)}, tail))
    return sorted(out, key=lambda g: o(lt(g, o)), reverse=True)

def fmt(p, o=XY):
    if not p: return "0"
    s = ""
    for k, m in enumerate(sorted(p, key=o, reverse=True)):
        c = p[m]
        mono = ("x" if m[0] else "") + (f"^{m[0]}" if m[0] > 1 else "") + \
               ("y" if m[1] else "") + (f"^{m[1]}" if m[1] > 1 else "")
        a = abs(c)
        cs = "" if (a == 1 and mono) else (str(a) if a.denominator == 1 or not mono else f"({a})")
        s += ("-" if c < 0 else "") if k == 0 else (" - " if c < 0 else " + ")
        s += cs + mono
    return s

def ev(p, pt): return sum(c * F(pt[0]) ** i * F(pt[1]) ** j for (i, j), c in p.items())
def L(G, o=XY): return "[" + ", ".join(fmt(g, o) for g in G) + "]"
def yn(b): return "yes" if b else "no"

f1 = P((1, 2, 0), (1, 0, 2), (-25, 0, 0))                          # beacon A (0, 0), 5 m
f2 = P((1, 2, 0), (1, 0, 2), (-8, 1, 0), (-8, 0, 1), (-17, 0, 0))  # beacon B (4, 4), 7 m
f3 = P((1, 2, 0), (1, 0, 2), (6, 1, 0), (6, 0, 1), (-31, 0, 0))    # beacon C (-3, -3), 7 m
lane = P((1, 1, 0), (1, 0, 1), (-1, 0, 0))                         # x + y - 1
pts = [(4, -3), (-3, 4)]
print("figure, beacon A (0, 0) r 5; beacon B (4, 4) r 7; beacon C (-3, -3) r 7; fixes (4, -3) (-3, 4); lane x + y = 1")
print("system 1: f1 =", fmt(f1), "; f2 =", fmt(f2))
raw1 = buchberger([f1, f2]);  G = reduce_basis(raw1)
print("Buchberger output, system 1:", L(raw1))
print("reduced basis, lex x > y:", L(G))
std = [(i, j) for i in range(4) for j in range(4) if not any(divides(lt(g, XY), (i, j)) for g in G)]
print("standard monomials (no leading term divides them):", ", ".join(fmt({m: F(1)}) for m in sorted(std)), "->", len(std), "; fixes:", len(pts))
tests = [("x + y - 1", lane), ("xy + 12", P((1, 1, 1), (12, 0, 0))), ("x - y - 7", P((1, 1, 0), (-1, 0, 1), (-7, 0, 0))), ("x^2", P((1, 2, 0)))]
for name, p in tests:
    r = nf(p, G)
    print(f"NF({name}) = {fmt(r)}; member: {yn(not r)}; values at fixes {[str(ev(p, q)) for q in pts]}, remainder there {[str(ev(r, q)) for q in pts]}")
    assert all(ev(p, q) == ev(r, q) for q in pts)                  # remainder agrees at every fix
cert1 = add(mul(P((F(1, 8), 0, 0)), f1), mul(P((F(-1, 8), 0, 0)), f2))
c = P((F(1, 16), 1, 0), (F(1, 16), 0, 1), (F(1, 16), 0, 0))         # (x + y + 1)/16
cert2 = add(mul(c, add(f1, f2, -1)), mul(P((F(-1, 2), 0, 0)), f1))
print("certificate (1/8)f1 - (1/8)f2 =", fmt(cert1))
print("certificate ((x + y + 1)/16)(f1 - f2) - (1/2)f1 =", fmt(cert2))
print("NF(x^2) by the raw Buchberger list =", fmt(nf(tests[3][1], raw1)), "; by the reduced basis =", fmt(nf(tests[3][1], G)))
H = [P((2, 1, 0), (2, 0, 2), (-26, 0, 0)), P((2, 0, 2), (-2, 0, 1), (-24, 0, 0)), P((1, 1, 1), (12, 0, 0))]
print("messy basis H:", L(H), "; tail y^2 - 13 reduced by y^2 - y - 12:", fmt(nf(P((1, 0, 2), (-13, 0, 0)), [G[1]])), "; tidied:", L(reduce_basis(H)))
raw2 = buchberger([f1, f3]);  G2 = reduce_basis(raw2)
print("system 2: f1 =", fmt(f1), "; f3 =", fmt(f3))
print("Buchberger output, system 2:", L(raw2))
print("reduced basis, system 2:", L(G2), "; same as system 1:", yn(G2 == G))
both = all(not nf(g, G) for g in [f1, f3]) and all(not nf(g, G2) for g in [f1, f2])
print("each system's equations reduce to 0 by the other's basis:", yn(both))
arm = reduce_basis(buchberger([P((1, 2, 0), (1, 0, 2), (-9, 0, 0)), P((1, 2, 0), (-8, 1, 0), (1, 0, 2), (12, 0, 0))]))
print("house arm, elbow (x, y), links 3 m and 2 m, hand at (4, 0) m: reduced basis", L(arm), "; NF(8x - 21) =", fmt(nf(P((8, 1, 0), (-21, 0, 0)), arm)))
print("mistake 1, divide x + y - 1 by [f1, f2] as given: remainder", fmt(nf(lane, [f1, f2])))
print("mistake 2, compare the raw Buchberger lists: equal:", yn(raw1 == raw2), f"({len(raw1)} and {len(raw2)} polynomials)")
Gy = reduce_basis(buchberger([f1, f2], YX), YX)
print("mistake 3, reduced basis in lex y > x:", L(Gy, YX), "; equal to the x > y basis:", yn(Gy == G))
GJ = reduce_basis(buchberger([f1, mul(lane, lane)]))
print("mistake 4, doubled system [f1, (x + y - 1)^2], reduced basis:", L(GJ))
print("  x + y - 1 at the fixes:", [str(ev(lane, q)) for q in pts], "; NF =", fmt(nf(lane, GJ)))
assert G == [lane, P((1, 0, 2), (-1, 0, 1), (-12, 0, 0))]          # x + y - 1, y^2 - y - 12
assert cert1 == lane and cert2 == tests[1][1]                      # certificates expand back
assert len(std) == len(pts)                                        # count matches the points
assert all(ev(f, q) == 0 for f in (f1, f2, f3) for q in pts)       # fixes lie on all three circles
assert nf(tests[1][1], G) == {} and nf(tests[2][1], G) != {}       # member and non-member
assert G2 == G and both and nf(tests[3][1], raw1) == nf(tests[3][1], G) and reduce_basis(H) == G
assert nf(lane, [f1, f2]) == lane and nf(lane, GJ) != {}           # the two traps
assert raw1 == [f1, f2, P((8, 1, 0), (8, 0, 1), (-8, 0, 0)), H[1]] and raw2 == [f1, f3, P((-6, 1, 0), (-6, 0, 1), (6, 0, 0)), H[1]]
assert arm == [P((1, 1, 0), (F(-21, 8), 0, 0)), P((1, 0, 2), (F(-135, 64), 0, 0))] and nf(P((8, 1, 0), (-21, 0, 0)), arm) == {}
print("ALL CHECKS PASS")
