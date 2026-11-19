# Domains, principal ideals and unique factorisation -- the check behind the card.
# Standard library only; Fraction is exact arithmetic, nothing more.  Three rings:
# the integers (Euclid on 1071 and 462), polynomials in x over Q (Euclid on f and
# g), and polynomials in x and y, where <x, y> has no single generator yet
# x^2y - y^3 still factors one way.  Two-letter searches run over F_3 (mod 3).
from fractions import Fraction as Q
from itertools import product

def yn(c): return "yes" if c else "no"

# ---- the integers: Euclid, then the same generator by brute force ----
print("integers: Euclid on 1071 and 462")
a, b = 1071, 462
while b:
    print(f"{a} = {a // b} x {b} + {a % b}"); a, b = b, a % b
gi, si, ti, r1, s1, t1 = 1071, 1, 0, 462, 0, 1          # extended Euclid
while r1:
    k = gi // r1; gi, si, ti, r1, s1, t1 = r1, s1, t1, gi - k * r1, si - k * s1, ti - k * t1
print(f"gcd {gi} = {ti} x 462 - {-si} x 1071")
combos = [i * 1071 + j * 462 for i in range(-30, 31) for j in range(-30, 31)]
least = min(c for c in combos if c > 0)
print(f"road 2: smallest positive a x 1071 + b x 462 with |a|, |b| <= 30: {least}")
print(f"every such combination a multiple of {least}: {yn(all(c % least == 0 for c in combos))} ({len(combos)} checked)")

# ---- polynomials in x over Q, coefficients highest power first ----
def trim(p):
    while len(p) > 1 and p[0] == 0: p = p[1:]
    return p
def sub(p, q):
    n = max(len(p), len(q)); p = [Q(0)] * (n - len(p)) + p; q = [Q(0)] * (n - len(q)) + q
    return trim([u - v for u, v in zip(p, q)])
def mul(p, q):
    out = [Q(0)] * (len(p) + len(q) - 1)
    for i, u in enumerate(p):
        for j, v in enumerate(q): out[i + j] += u * v
    return trim(out)
def divmod_(f, g):
    quo, r = [Q(0)] * max(1, len(f) - len(g) + 1), f
    while r != [0] and len(r) >= len(g):
        c, d = r[0] / g[0], len(r) - len(g)
        quo[len(quo) - 1 - d] = c; r = sub(r, mul([c] + [Q(0)] * d, g))
    return trim(quo), r
def show(p):
    s, n = "", len(p) - 1
    for i, c in enumerate(p):
        if c == 0: continue
        d, a = n - i, abs(c)
        cs = "" if a == 1 and d else (f"({a})" if a.denominator > 1 and d else str(a))
        t = cs + ("" if d == 0 else "x" if d == 1 else f"x^{d}")
        s += (("-" if c < 0 else "") + t) if not s else (" - " if c < 0 else " + ") + t
    return s or "0"
P = lambda *cs: [Q(c) for c in cs]
f, g = P(1, -6, 11, -6), P(1, 0, -1)
print(f"polynomials in x over Q: f = {show(f)}, g = {show(g)}")
q1, rem1 = divmod_(f, g); q2, rem2 = divmod_(g, P(1, -1))
print(f"f = ({show(q1)}) g + ({show(rem1)})")
print(f"g = ({show(q2)})(x - 1) + {show(rem2)}")
r0, s0, t0, r1, s1, t1 = f, P(1), P(0), g, P(0), P(1)    # extended Euclid again
while r1 != [0]:
    k, rr = divmod_(r0, r1)
    r0, s0, t0, r1, s1, t1 = r1, s1, t1, rr, sub(s0, mul(k, s1)), sub(t0, mul(k, t1))
lead = r0[0]; h, u, v = [c / lead for c in r0], [c / lead for c in s0], [c / lead for c in t0]
print(f"monic gcd: {show(h)}")
print(f"{show(h)} = u f + v g with u = {show(u)}, v = {show(v)}")
ev = lambda p, x: sum(c * x ** (len(p) - 1 - i) for i, c in enumerate(p))
rf = [x for x in range(-6, 7) if ev(f, x) == 0]; rg = [x for x in range(-1, 2) if ev(g, x) == 0]
print(f"road 2: rational roots of f {rf}, of g {rg}, shared {[x for x in rf if x in rg]}")

# ---- polynomials in x and y: dicts {(power of x, power of y): coefficient} ----
def tidy(out, m):                                     # reduce mod m (0: not at all), drop zeros
    return {key: (c % m if m else c) for key, c in out.items() if (c % m if m else c)}
def mul2(p, q, m=0):
    out = {}
    for (i, j), c in p.items():
        for (k, l), e in q.items(): out[(i + k, j + l)] = out.get((i + k, j + l), 0) + c * e
    return tidy(out, m)
def add2(p, q, m=0):
    out = dict(p)
    for key, c in q.items(): out[key] = out.get(key, 0) + c
    return tidy(out, m)
ev2 = lambda p, x, y: sum(c * x ** i * y ** j for (i, j), c in p.items())
def show2(p):
    s = ""
    for (i, j) in sorted(p, reverse=True):              # lex order, x > y
        c = p[(i, j)]; mono = ("x" if i else "") + (f"^{i}" if i > 1 else "") + ("y" if j else "") + (f"^{j}" if j > 1 else "")
        t = (str(abs(c)) if abs(c) != 1 or not mono else "") + mono
        s += (("-" if c < 0 else "") + t) if not s else (" - " if c < 0 else " + ") + t
    return s or "0"
def polys(deg):                                       # every polynomial over F_3 of degree <= deg
    monos = [(i, j) for i in range(deg + 1) for j in range(deg + 1 - i)]
    return [{m: c for m, c in zip(monos, cs) if c} for cs in product(range(3), repeat=len(monos))]
X, Y, ONE = {(1, 0): 1}, {(0, 1): 1}, {(0, 0): 1}
L1 = polys(1)
divides = lambda h, t, qs: any(mul2(h, q, 3) == t for q in qs)
common = [show2(h) for h in L1 if h and divides(h, X, L1) and divides(h, Y, L1)]
print("polynomials in x and y over F_3: the ideal <x, y>")
print(f"polynomials of degree <= 1 dividing both x and y: {common}")
cs2 = [add2(mul2(a, X), mul2(b, Y), 3) for a in L1 for b in L1]
print(f"combinations a x + b y, a and b of degree <= 1: {len(cs2)}, zero at (0, 0): {sum(ev2(p, 0, 0) == 0 for p in cs2)}")
F = {(2, 1): 1, (0, 3): -1}
fac = mul2(mul2(Y, {(1, 0): 1, (0, 1): -1}), {(1, 0): 1, (0, 1): 1})
print(f"unique factorisation in k[x, y]: {show2(F)} = y(x - y)(x + y), expanded: {show2(fac)}: {yn(fac == F)}")
F3, L2 = tidy(F, 3), polys(2)
linear = [show2(h) for h in L1 if h and (0, 0) not in h and h[max(h)] == 1 and divides(h, F3, L2)]
print(f"road 2: monic degree-1 divisors over F_3: {linear} (x - y is x + 2y mod 3)")
zeros = sum(ev2(F, x, y) % 3 == 0 for x in range(3) for y in range(3))
print(f"road 3: zeros of {show2(F)} on the 9 points of F_3^2: {zeros} = 3 lines x 3 points - 2 repeats of (0, 0)")

# ---- what breaks ----
print(f"mistake 1, Z mod 12 has zero divisors: 3 x 4 = {3 * 4 % 12}; 4 = 2 x 2 = 4 x 4 = 2 x 8: "
      f"{yn(2 * 2 % 12 == 4 * 4 % 12 == 2 * 8 % 12 == 4)}")
nm = lambda a, b: a * a + 5 * b * b
small = sorted({nm(a, b) for a in range(-3, 4) for b in range(-3, 4)} & {2, 3})
print(f"mistake 2, Z[sqrt-5]: norms 2 -> {nm(2, 0)}, 3 -> {nm(3, 0)}, 1 + sqrt-5 -> {nm(1, 1)}, "
      f"1 - sqrt-5 -> {nm(1, -1)}; {nm(2, 0)} x {nm(3, 0)} = {nm(2, 0) * nm(3, 0)} = {nm(1, 1)} x {nm(1, -1)}")
print(f"  elements of norm 2 or 3 (|a|, |b| <= 3): {small}, so {'all four are irreducible' if not small else 'irreducible not proved'}")
print(f"mistake 3, least-degree member x taken as generator of <x, y>: y a multiple of x: {yn(divides(X, Y, L1))}")
print(f"mistake 4, gcd(x, y) = 1 read as 1 = a x + b y: combinations equal to 1 found: {sum(p == ONE for p in cs2)}")
assert gi == least == 21 and all(c % 21 == 0 for c in combos)    # Euclid against brute force
assert ti * 462 + si * 1071 == 21                                 # Bezout, substituted back
assert show(h) == "x - 1" and [x for x in rf if x in rg] == [1]   # gcd against shared roots
assert sub(sub(h, mul(u, f)), mul(v, g)) == [0]                   # u f + v g, multiplied out
assert sorted(common) == ["1", "2"]                               # only units divide x and y
assert sum(p == ONE for p in cs2) == 0 and not divides(X, Y, L1)  # 1 and y out of reach
assert fac == F and sorted(linear) == ["x + 2y", "x + y", "y"] and zeros == 7  # three roads agree
assert small == []                                                # no element of norm 2 or 3
assert nm(2, 0) * nm(3, 0) == nm(1, 1) * nm(1, -1)                # the norm multiplies both ways
print("ALL CHECKS PASS")
