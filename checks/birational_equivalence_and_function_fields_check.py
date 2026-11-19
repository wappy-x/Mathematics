# Birational equivalence and function fields -- the check behind the card.
# Standard library only.  Fraction keeps every value exact.  The circle C: x^2 + y^2 = 1
# and the line with coordinate t are matched by projection from the point (-1, 0):
# phi(x, y) = y/(x + 1) and psi(t) = ((1 - t^2)/(1 + t^2), 2t/(1 + t^2)).
# Three roads: points put back exactly; the pullbacks composed as fractions of
# polynomial functions, reduced by y^2 = 1 - x^2; and the match counted over F_p.
from fractions import Fraction as Q
from math import sqrt

PX, PY, PD = (1, 0, -1), (0, 2, 0), (1, 0, 1)                # psi's two tops and its bottom: coefficients of 1, t, t^2
def cv(c, t): return c[0] + c[1] * t + c[2] * t * t
def psi(t): return (cv(PX, t) / cv(PD, t), cv(PY, t) / cv(PD, t))
def phi(x, y): return y / (x + 1)
def on_c(x, y): return x * x + y * y == 1
def pt(*a): return "(" + ", ".join(str(c) for c in a) + ")"
def yn(c): return "yes" if c else "no"
def cone_phi(x, y, z): return (y / (x + z), z)               # cone x^2 + y^2 = z^2 to the (s, z) plane
def cone_psi(s, z): return tuple(z * c for c in psi(s)) + (z,)

# ---- polynomials in x, y as {(i, j): coefficient}; normal form uses y^2 = 1 - x^2 ----
def add(a, b):
    out = dict(a)
    for k, c in b.items(): out[k] = out.get(k, 0) + c
    return {k: c for k, c in out.items() if c != 0}
def scale(a, c): return {k: v * c for k, v in a.items() if v * c != 0}
def mul(a, b):
    out = {}
    for (i, j), c in a.items():
        for (k, l), d in b.items(): out = add(out, {(i + k, j + l): c * d})
    return out
def nf(a):                                     # every element of k[C] is a(x) + b(x) y
    out = {}
    for (i, j), c in a.items():
        term = {(i, j % 2): Q(c)}
        for _ in range(j // 2): term = mul(term, {(0, 0): Q(1), (2, 0): Q(-1)})
        out = add(out, term)
    return out
def show(a, names=("x", "y")):
    if not a: return "0"
    s = ""
    for (i, j) in sorted(a, reverse=True):
        c = a[(i, j)]
        mono = "*".join(n + (f"^{e}" if e > 1 else "") for n, e in zip(names, (i, j)) if e)
        body = (str(abs(c)) if abs(c) != 1 or not mono else "") + ("*" if abs(c) != 1 and mono else "") + mono
        s += (" - " if c < 0 else " + ") + body if s else ("-" if c < 0 else "") + body
    return s
X, Y, ONE = {(1, 0): Q(1)}, {(0, 1): Q(1)}, {(0, 0): Q(1)}
def P(*terms): return {k: Q(c) for k, c in terms}

print("field Q; circle C: x^2 + y^2 = 1; line: coordinate t; projection from (-1, 0)")
print("road 1: points, put back exactly")
for t in (Q(1, 2), Q(2, 3), Q(3, 4), Q(1, 4), Q(2), Q(-1, 3), Q(0)):
    x, y = psi(t)
    m, n = t.denominator, t.numerator
    trip = (m * m - n * n, 2 * m * n, m * m + n * n)
    print(f"  t = {t}: psi(t) = {pt(x, y)}, on C: {yn(on_c(x, y))}, phi back: {phi(x, y)}"
          + (f"; triple {pt(*trip)}" if 0 < t < 1 else ""))
    assert on_c(x, y) and phi(x, y) == t
    assert trip[0] ** 2 + trip[1] ** 2 == trip[2] ** 2
for x, y in ((Q(5, 13), Q(-12, 13)), (Q(-7, 25), Q(24, 25)), (Q(1), Q(0)), (Q(0), Q(-1))):
    t = phi(x, y)
    print(f"  circle point {pt(x, y)}: phi = {t}, psi back: {pt(*psi(t))}")
    assert psi(t) == (x, y)

print("road 2: fractions in k(C), cross-multiplied and reduced by y^2 = 1 - x^2")
a, b = Y, add(X, ONE)                           # t = a/b = y/(x + 1)
same = nf(add(mul(Y, Y), scale(mul(P(((0, 0), 1), ((1, 0), -1)), b), -1)))
print(f"  y/(x + 1) = (1 - x)/y: y*y - (1 - x)(x + 1) reduces to {show(same)}")
print("  " + "; ".join(f"at ({u}, {w}): y/(x + 1) = {w}/{u + 1}, (1 - x)/y = {1 - u}/{w}" for u, w in ((1, 0), (-1, 0)))
      + ": phi is defined at (1, 0), not at (-1, 0)")
yb = 0.01; xb = -sqrt(1 - yb * yb)                            # the circle point just above (-1, 0)
print(f"  near (-1, 0): at y = 1/100, x = {xb:.5f}, the height t = (1 - x)/y = {(1 - xb) / yb:.3f}: t runs off")
assert same == {} and abs(yb / (xb + 1) - (1 - xb) / yb) < 1e-6 and (1 - xb) / yb > 199
hs = lambda c: add(add(scale(mul(b, b), c[0]), scale(mul(a, b), c[1])), scale(mul(a, a), c[2]))   # psi's c at t = a/b, times b^2
den = nf(hs(PD))
for name, num, target in (("x", hs(PX), X), ("y", hs(PY), Y)):
    num = nf(num)
    diff = nf(add(num, scale(mul(target, den), -1)))
    print(f"  phi*(psi*({name})) = ({show(num)})/({show(den)}); minus {name}, cross-multiplied: {show(diff)}")
    assert diff == {}
tp = lambda c: {(k, 0): Q(v) for k, v in enumerate(c) if v}  # psi's coefficients as a polynomial in t
lin = lambda L: add(add(scale(tp(PD), L.get((0, 0), 0)), scale(tp(PX), L.get((1, 0), 0))), scale(tp(PY), L.get((0, 1), 0)))
tn, td = lin(a), lin(b)                            # phi = a/b with x, y = psi(t); top and bottom times 1 + t^2
diff_t = add(tn, scale(mul(P(((1, 0), 1)), td), -1))
print(f"  psi*(phi*(t)) = ({show(tn, 't_')})/({show(td, 't_')}); minus t, cross-multiplied: {show(diff_t)}")
assert diff_t == {}

count = {}
print("road 3: count over F_p (circle minus (-1, 0) against line minus t^2 = -1)")
for p in (3, 5, 7, 11, 13, 17):
    inv = lambda v: pow(v % p, p - 2, p)
    circ = [(x, y) for x in range(p) for y in range(p) if (x * x + y * y - 1) % p == 0]
    bad_t = [t for t in range(p) if (t * t + 1) % p == 0]
    good_c = [(x, y) for x, y in circ if (x + 1) % p]
    image = sorted({y * inv(x + 1) % p for x, y in good_c})
    back = all(((1 - t * t) * inv(1 + t * t) % p, 2 * t * inv(1 + t * t) % p) in good_c for t in image)
    print(f"  p = {p:2d}: circle {len(circ):2d}, minus 1 = {len(good_c):2d}; line {p:2d}, minus {bad_t} = "
          f"{p - len(bad_t):2d}; phi one-to-one onto the rest: {yn(len(image) == len(good_c) and back)}")
    assert len(image) == len(good_c) == p - len(bad_t) and back
    count[p] = len(circ)
    assert set(image).isdisjoint(bad_t)

c5 = [(x, y) for x in range(5) for y in range(5) if (x * x + y * y - 1) % 5 == 0]
print(f"  F_5 unit on C, (x + 2y)(x - 2y) = x^2 + y^2 = 1: values of x + 2y at "
      + ", ".join(pt(*c) for c in c5) + ": " + ", ".join(str((x + 2 * y) % 5) for x, y in c5))
assert all((x + 2 * y) * (x - 2 * y) % 5 == 1 for x, y in c5)
for v in ((Q(3), Q(4), Q(5)), (Q(5), Q(12), Q(13))):
    w = cone_phi(*v)
    print(f"cone x^2 + y^2 = z^2: {pt(*v)} -> (s, z) = {pt(*w)} -> {pt(*cone_psi(*w))}")
    assert cone_psi(*w) == v

print("what breaks")
print(f"  no bad sets: over F_7 circle {count[7]} points, line 7; over F_5 circle {count[5]}, line 5: "
      "no one-to-one match")
assert count[7] != 7 and count[5] != 5
ys = [y for y in (Q(k, 5) for k in range(-5, 6)) if on_c(Q(3, 5), y)]
print(f"  map to x only: x = 3/5, y^2 = {1 - Q(9, 25)}: {len(ys)} points, y = " + " and ".join(map(str, ys)))
assert len(ys) == 2
v = [(x, y) for x in range(7) for y in range(7) if x * y % 7 == 0]
print(f"  reducible xy = 0 over F_7: {len(v)} points; x*y nonzero at {sum(x * y % 7 != 0 for x, y in v)}, "
      f"x nonzero at {sum(x != 0 for x, y in v)}, y nonzero at {sum(y != 0 for x, y in v)}: zero divisors, no field")
sols = [(u, v, w) for u in range(9) for v in range(9) for w in range(9)
        if (u * u + v * v - 3 * w * w) % 9 == 0 and (u % 3 or v % 3 or w % 3)]
ok1 = [(u, v, w) for u in range(9) for v in range(9) for w in range(9)
       if (u * u + v * v - w * w) % 9 == 0 and (u % 3 or v % 3 or w % 3)]
print(f"  x^2 + y^2 = 3 over Q: primitive X^2 + Y^2 = 3Z^2 mod 9: {len(sols)}; for x^2 + y^2 = 1: {len(ok1)}")
assert sols == [] and len(ok1) > 0

S = 100                                                    # figure: 100 units per unit, origin (160, 240)
sv = lambda x, y: f"({160 + S * x:.2f}, {240 - S * y:.2f})"
print("figure, N " + sv(-1, 0) + "; " + "; ".join(
    f"t = {t}: point {sv(*psi(t))}, line {sv(0, t)}" for t in (Q(1, 2), Q(2), Q(-1, 3))))
print("ALL CHECKS PASS")
