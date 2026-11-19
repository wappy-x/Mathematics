# The Zariski topology and irreducible pieces -- the check behind the card.
# Nothing is imported; every number is an exact integer.  The field for the
# theorems is the complex numbers.  The finite fields F_13 and F_7 are used
# only to count points by listing them all, as an independent road.

def trim(a):                                  # drop zero coefficients at the top
    while len(a) > 1 and a[-1] == 0:
        a = a[:-1]
    return a

def mul(a, b):                                # one-variable product; a[i] is the x^i coefficient
    out = [0] * (len(a) + len(b) - 1)
    for i, s in enumerate(a):
        for j, t in enumerate(b):
            out[i + j] += s * t
    return trim(out)

def from_roots(roots):                        # (x - r1)(x - r2)...: a finite set as a zero set
    p = [1]
    for r in roots:
        p = mul(p, [-r, 1])
    return p

def igcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)

def primitive(a):                             # divide out the common factor, top coefficient positive
    g = 0
    for c in a:
        g = igcd(g, c)
    a = [c // g for c in a]
    return [-c for c in a] if a[-1] < 0 else a

def poly_gcd(a, b):                           # Euclid with pseudo-remainders: integers only
    while b != [0]:
        r = a[:]
        while len(r) >= len(b) and r != [0]:
            shift, lead = len(r) - len(b), r[-1]
            r = [b[-1] * c for c in r]
            for i, c in enumerate(b):
                r[i + shift] -= lead * c
            r = trim(r)
        a, b = b, (primitive(r) if r != [0] else [0])
    return primitive(a)

def roots(p):                                 # road two: try every whole number from -10 to 10
    return [x for x in range(-10, 11) if sum(c * x ** i for i, c in enumerate(p)) == 0]

def show(p):                                  # leading term first, e.g. x^3 - x
    out = ""
    for i in range(len(p) - 1, -1, -1):
        c = p[i]
        if c == 0:
            continue
        body = ("" if abs(c) == 1 and i > 0 else str(abs(c))) + ("" if i == 0 else "x" if i == 1 else f"x^{i}")
        out += ("-" if c < 0 else "") + body if out == "" else (" - " if c < 0 else " + ") + body
    return out

def rank(m):                                  # elimination without division; counts pivots
    a, r, n = [row[:] for row in m], 0, len(m)
    for col in range(n):
        piv = next((i for i in range(r, n) if a[i][col] != 0), None)
        if piv is None:
            continue
        a[r], a[piv] = a[piv], a[r]
        for i in range(r + 1, n):
            a[i] = [a[r][col] * a[i][j] - a[i][col] * a[r][j] for j in range(n)]
        r += 1
    return r

def det3(m):                                  # road two: the cofactor formula
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def twice_product(l, m):                      # the matrix of 2 l m for linear forms l, m
    return [[l[i] * m[j] + m[i] * l[j] for j in range(3)] for i in range(3)]

def count(p, test, dims):                     # list every point of F_p^dims and count the zeros
    pts = [(a, b, c) for a in range(p) for b in range(p) for c in range(p)] if dims == 3 else \
          [(a, b) for a in range(p) for b in range(p)]
    return sum(1 for q in pts if test(*q) % p == 0)

yn = lambda claim: "yes" if claim else "no"
A, B = [-1, 0, 1], [1, 2]
f, g = from_roots(A), from_roots(B)
fg, h = mul(f, g), poly_gcd(f, g)
print(f"line: V({show(f)}) = {roots(f)}; V({show(g)}) = {roots(g)}")
print(f"union: V({show(fg)}) = {roots(fg)}, the union of the two sets: {yn(roots(fg) == sorted(set(A) | set(B)))}")
print(f"overlap: gcd = {show(h)}, V = {roots(h)}, the shared points: {yn(roots(h) == sorted(set(A) & set(B)))}")
assert roots(fg) == sorted(set(A) | set(B)) and len(roots(fg)) <= len(fg) - 1   # the sets, built separately
assert roots(h) == sorted(set(A) & set(B))

p = 13
both = count(p, lambda x, y, z: x * y, 3)
px, py_, axis = (count(p, t, 3) for t in (lambda x, y, z: x, lambda x, y, z: y, lambda x, y, z: (x != 0) + (y != 0)))
print(f"pair of planes over F_{p}: V(xy) has {both} points; V(x) {px}, V(y) {py_}, corner line V(x, y) {axis}")
print(f"inclusion-exclusion: {px} + {py_} - {axis} = {px + py_ - axis}; adding the corner as a third piece gives {px + py_ + axis}")
on_v = [(x, y, z) for x in range(p) for y in range(p) for z in range(p) if x * y % p == 0]
wx, wy, wxy = (sum(1 for q in on_v if t(*q) % p) for t in (lambda x, y, z: x, lambda x, y, z: y, lambda x, y, z: x * y))
print(f"points of V(xy) where x is not 0: {wx}; where y is not 0: {wy}; where xy is not 0: {wxy}")
(x1, y1, _), (x2, y2, _) = (2, 0, -1), (0, 3, -2)
print(f"witnesses: x at (2, 0, -1) = {x1}, y at (0, 3, -2) = {y2}, xy at them = {x1 * y1} and {x2 * y2}")
assert both == px + py_ - axis == 2 * p * p - p and wx == wy == p * p - p and wxy == 0

cone = lambda x, y, z: x * x + y * y - z * z    # the house cone; each slice's polynomial is read off it
quads = [("pair of planes xy, in (x, y, z)", [[0, 1, 0], [1, 0, 0], [0, 0, 0]], ([1, 0, 0], [0, 1, 0]), 0, lambda x, y, z: x * y),
         ("cone x^2 + y^2 - z^2, in (x, y, z)", [[2, 0, 0], [0, 2, 0], [0, 0, -2]], None, 0, cone)]
for c in range(4):
    quads.append((f"slice x = {c}: y^2 - z^2 + {c * c}, in (y, z, w)", [[2, 0, 0], [0, -2, 0], [0, 0, 2 * c * c]],
                  ([1, -1, 0], [1, 1, 0]) if c == 0 else None, 0, lambda y, z, w, c=c: cone(c * w, y, z)))
quads.append(("slice z = 0: x^2 + y^2, in (x, y, w)", [[2, 0, 0], [0, 2, 0], [0, 0, 0]], ([1, 5, 0], [1, -5, 0]), 13,
              lambda x, y, w: cone(x, y, 0)))
grid = [(a, b, e) for a in range(-2, 3) for b in range(-2, 3) for e in range(-2, 3)]
for name, m, fac, mod, form in quads:
    r, d = rank(m), det3(m)
    assert all(sum(v[i] * m[i][j] * v[j] for i in range(3) for j in range(3)) == 2 * form(*v) for v in grid)  # M is 2Q's matrix
    pieces = "one piece" if r == 3 else "two flat pieces" if r == 2 else "one doubled piece"
    line = f"{name}: rank {r}, det {d}, {pieces}"
    if fac:
        t = twice_product(*fac)
        same = all((t[i][j] - m[i][j]) % mod == 0 if mod else t[i][j] == m[i][j] for i in range(3) for j in range(3))
        line += f"; factors {fac[0]} times {fac[1]} expand back{' mod 13' if mod else ''}: {yn(same)}"
        assert same and r == 2
    print(line)
    assert (r == 3) == (d != 0)
assert [det3(q[1]) for q in quads[2:6]] == [-8 * c * c for c in range(4)]     # the slices' determinants are -8c^2
slices = [count(p, lambda y, z, c=c: y * y - z * z + c * c, 2) for c in range(4)]
print(f"slices x = 0, 1, 2, 3 over F_{p}, points: {slices}; two crossing lines give 2p - 1 = {2 * p - 1}, one curve p - 1 = {p - 1}")
assert slices == [2 * p - 1] + [p - 1] * 3
v13, v7 = count(13, lambda x, y: x * x + y * y, 2), count(7, lambda x, y: x * x + y * y, 2)
print(f"x^2 + y^2 = 0: {v13} points over F_13, where 5^2 = {25 % 13 - 13} mod 13; {v7} point over F_7, where -1 is no square")
sq, lin = count(p, lambda x, y, z: x * x, 3), count(p, lambda x, y, z: x, 3)
print(f"V(x^2) has {sq} points and V(x) has {lin}: one set, two ideals")
assert v13 == 2 * 13 - 1 and v7 == 1 and sq == lin
tops = "; ".join(f"hyperbola c = {c} vertices " + " and ".join(f"(0, {z})" for z in range(4, -5, -1) if cone(c, 0, z) == 0)
                 for c in (1, 2))                 # where the slice x = c meets y = 0, inside the window
print(f"figure, lines z = y and z = -y cross at (0, 0); {tops}; window -4 to 4 in y and z")
print("ALL CHECKS PASS")
