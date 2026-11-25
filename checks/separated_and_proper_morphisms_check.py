# Separated, finite and proper -- the check behind the card.  Nothing is
# imported.  Field Q for limits; F_7 and F_49 for counts.  A rational function
# of t is a pair (num, den) of integer coefficient lists, lowest power first.
# A punctured-disc curve is a list of such functions; its limit as t -> 0 is
# found by rescaling by the least order, against chart by chart, against a
# float evaluation near t = 0.  Point counts are by brute force.
def gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)

def pmul(a, b):
    out = [0] * (len(a) + len(b) - 1)
    for i, c in enumerate(a):
        for j, d in enumerate(b):
            out[i + j] += c * d
    return out

def order(p):                                  # how many times t divides p; None for p = 0
    return next((i for i, c in enumerate(p) if c), None)

def val(f):                                    # the valuation v(f): order of top minus order of bottom
    return None if order(f[0]) is None else order(f[0]) - order(f[1])

def at0(f):                                    # the value at t = 0 of f with v(f) >= 0, as (num, den)
    if val(f) is None or val(f) > 0:
        return (0, 1)
    a, b = f[0][order(f[0])], f[1][order(f[1])]
    g = gcd(a, b) * (1 if b > 0 else -1)
    return (a // g, b // g)

def normal(v):                                 # a projective point in lowest terms, last nonzero entry > 0
    g = 0
    for c in v:
        g = gcd(g, c)
    s = 1 if [c for c in v if c][-1] > 0 else -1
    return tuple(s * c // g for c in v)

def rescale(curve):                            # road 1: clear bottoms, divide by t^m, m the least order
    polys = []
    for i, (n, _) in enumerate(curve):
        for j, (_, d) in enumerate(curve):
            n = n if i == j else pmul(n, d)
        polys.append(n)
    m = min(order(p) for p in polys if order(p) is not None)
    return normal([p[m] if len(p) > m else 0 for p in polys])

def chart_limits(curve):                       # road 2: in chart i divide by coordinate i; keep it if every ratio has v >= 0
    found = set()
    for i, (ni, di) in enumerate(curve):
        if order(ni) is None:
            continue
        ratios = [(pmul(n, di), pmul(d, ni)) for n, d in curve]
        if all(val(r) is None or val(r) >= 0 for r in ratios):
            vals = [at0(r) for r in ratios]
            den = 1
            for _, b in vals:
                den = den * b // gcd(den, b)
            found.add(normal([a * (den // b) for a, b in vals]))
    return found

def by_float(curve, r, t=1e-6):                # road 3: evaluate near 0, divide by the largest entry, compare with r
    ev = lambda p: sum(c * t ** k for k, c in enumerate(p))
    v = [ev(n) / ev(d) for n, d in curve]
    big, rbig = max(v, key=abs), max(r, key=abs)
    return all(abs(a / big - b / rbig) < 1e-4 for a, b in zip(v, r))

def show(pt):
    return "(" + " : ".join(str(c) for c in pt) + ")"

T, ONE = [0, 1], [1]
glue = lambda chart, a: (chart, a) if a[0] == 0 else a   # doubled line: (A, a) and (B, a) are one point unless a = 0
curves = {"x = 1/t": (ONE, T), "x = t": (T, ONE), "x = 1 + 2t": ([1, 2], ONE)}
print("punctured-disc curves t -> x(t), t != 0; limit points as t -> 0 (field Q)")
counts = {}
for name, x in curves.items():
    curve = [x, (ONE, ONE)]                    # in P^1 the point x is (x : 1); the point at infinity is (1 : 0)
    p1, r = chart_limits(curve), rescale(curve)
    a1 = [at0(x)] if val(x) is None or val(x) >= 0 else []   # A^1 = Spec k[x]: a limit needs x in R
    dbl = {glue(chart, a) for chart in "AB" for a in a1}     # doubled line: each chart is a copy of A^1, then glue
    counts[name] = (len(a1), len(p1), len(dbl))
    assert p1 == {r} and by_float(curve, r)    # three roads to the P^1 limit
    print(f"  {name:11}: limits in A^1 {len(a1)}; in P^1 {len(p1)}, {show(r)}; in the doubled line {len(dbl)}")
assert counts == {"x = 1/t": (0, 1, 0), "x = t": (1, 1, 2), "x = 1 + 2t": (1, 1, 1)}
vs = [val(f) for f in [([0, 0, 1], ONE), ([3, 1], ONE), (ONE, T), (ONE, [0, 0, 1])]]
print(f"valuations: v(t^2) = {vs[0]}, v(3 + t) = {vs[1]}, v(1/t) = {vs[2]}, v(1/t^2) = {vs[3]}; (1/t : 1) has m = {min(vs[2], 0)}")
assert vs == [2, 0, -1, -2]
print("x = 1/t near 0: t = 1/10, 1/100, 1/1000 gives x = " + ", ".join(str(10 ** k) for k in (1, 2, 3))
      + "; in P^1, (x : 1) = (1 : t) = " + ", ".join(f"(1 : 1/{10 ** k})" for k in (1, 2, 3)))

plane = {"line y = 2x + 1, x = 1/t": [(ONE, T), ([2, 1], T), (ONE, ONE)],
         "line y = 2x + 5, x = 1/t": [(ONE, T), ([2, 5], T), (ONE, ONE)],
         "parabola y = x^2, x = 1/t": [(ONE, T), (ONE, [0, 0, 1]), (ONE, ONE)],
         "x = 3 + t, y = t/(1 - t)": [([3, 1], ONE), (T, [1, -1]), (ONE, ONE)]}
for name, curve in plane.items():
    r, c, close = rescale(curve), chart_limits(curve), by_float(curve, rescale(curve))
    print(f"P^2, {name}: rescaled {show(r)}; charts {len(c)} point(s), {show(next(iter(c)))}; float near 0 agrees: {'yes' if close else 'no'}")
    assert c == {r} and close                  # three roads to one limit
assert rescale(plane["line y = 2x + 1, x = 1/t"]) == rescale(plane["line y = 2x + 5, x = 1/t"])   # parallel lines meet

p = 7                                          # the diagonal in chart (A, B): x in A and y in B name one point
diag_AA = sum(1 for x in range(p) for y in range(p) if glue("A", (x, 1)) == glue("A", (y, 1)))
diag_AB = sum(1 for x in range(p) for y in range(p) if glue("A", (x, 1)) == glue("B", (y, 1)))
print(f"doubled line, diagonal over F_{p}: chart (A, A) {diag_AA} of the {p} points on x = y; "
      f"chart (A, B) {diag_AB} of {p}, missing (0_A, 0_B)")
hyper = {x for x in range(p) for y in range(p) if (x * y - 1) % p == 0}
P1 = [(1, 0)] + [(a, 1) for a in range(p)]     # the 8 points (y0 : y1) of P^1 over F_7, y = y0/y1
closure = [(x, q) for x in range(p) for q in P1 if (x * q[0] - q[1]) % p == 0]   # xy = 1 as x y0 = y1
shadow = {x for x, _ in closure}
over0 = [q for x, q in closure if x == 0]
print(f"hyperbola xy = 1 over F_{p}: shadow on the x-line {len(hyper)} of {p} points, x = 0 missing")
print(f"its closure in A^1 x P^1: {len(closure)} points, shadow {len(shadow)} of {p}; over x = 0 the point y = {show(over0[0])}")
assert len(hyper) == p - 1 and 0 not in hyper and len(shadow) == p and over0 == [(1, 0)]   # brute force against p - 1 and p
print(f"mistake 1: A^1 -> a point is closed (shadow 1 of 1), yet its base change has shadow {len(hyper)} of {p}")
print(f"mistake 2: P^1 tested in the chart x only: x = 1/t finds {counts['x = 1/t'][0]} limits, not {counts['x = 1/t'][1]}")
fib = [sum(1 for x in range(1, p) if x == a) for a in range(p)]   # the punctured line inside the line
print(f"mistake 3: punctured line -> line, fibres over F_{p} {fib}: all at most 1, image {sum(fib)} of {p}, origin missing")
assert (diag_AA, diag_AB) == (p, p - 1) and fib == [0] + [1] * (p - 1)    # brute force against p, p - 1 and the hole at 0
print(f"mistake 4: doubled line, x = t has {counts['x = t'][2]} limits; separated needs at most 1")

f = [2, -1, 3, 0, 0, 1]                        # x^5 + 3x^2 - x + 2, lowest power first
g, h = f[0::2], f[1::2]                        # f(x) = g(x^2) + x h(x^2)
grid = range(-4, 5)
same = all(sum(c * x ** k for k, c in enumerate(f)) ==
           sum(c * x ** (2 * k) for k, c in enumerate(g)) + x * sum(c * x ** (2 * k) for k, c in enumerate(h)) for x in grid)
print(f"x -> u = x^2: f = x^5 + 3x^2 - x + 2 = g(x^2) + x h(x^2), g(u) = 3u + 2, h(u) = u^2 - 1; agrees at x = -4..4: {'yes' if same else 'no'}")
assert g == [2, 3, 0] and h == [-1, 0, 1] and same
sq7 = [sum(1 for x in range(p) if (x * x - a) % p == 0) for a in range(p)]
euler = [1 + (1 if pow(a, (p - 1) // 2, p) == 1 else -1 if a else 0) for a in range(p)]
F49 = [(a, b) for a in range(p) for b in range(p)]                 # a + b i with i^2 = -1, p = 3 mod 4
sq49 = [sum(1 for a, b in F49 if ((a * a - b * b - c) % p, (2 * a * b) % p) == (0, 0)) for c in range(p)]
print(f"fibres of x -> x^2 over u = 0..{p - 1}: points over F_{p} {sq7}, Euler's test {euler}; over F_{p * p} {sq49}")
print("fibre ring k[x]/<x^2 - u> has basis 1, x: dimension 2 for every u; at u = 0 the one point counts twice")
assert sq7 == euler and sq49 == [1] + [2] * (p - 1)               # brute force against Euler, and F_49 roots
print("ALL CHECKS PASS")
