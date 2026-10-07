# Triple product and volume -- the check behind the card.  Nothing is imported.
# A crate knocked out of square, measured in decimetres, so 1 dm^3 = 1 litre.  Its
# capacity is found three ways: cross then dot, a 3 by 3 determinant, and a count of
# small cubes.  Then sets of four corners are tested for lying in one plane, two ways.
a, b, c = (20.0, 0.0, 0.0), (5.0, 15.0, 0.0), (4.0, 3.0, 12.0)

def add(u, v): return tuple(x + y for x, y in zip(u, v))
def sub(u, v): return tuple(x - y for x, y in zip(u, v))
def dot(u, v): return sum(x * y for x, y in zip(u, v))
def cross(u, v): return (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
def triple(u, v, w): return dot(cross(u, v), w)       # road 1: floor arrow, then height
def det(m):                                           # road 2: cofactor expansion, top row
    if len(m) == 1: return m[0][0]
    return sum((-1) ** j * m[0][j] * det([r[:j] + r[j + 1:] for r in m[1:]]) for j in range(len(m)))
def inside(p):                                        # road 3: undo c, then b, then read a
    t = p[2] / c[2]; s = (p[1] - t * c[1]) / b[1]; r = (p[0] - t * c[0] - s * b[0]) / a[0]
    return 0 <= r <= 1 and 0 <= s <= 1 and 0 <= t <= 1
def show(v): return "(" + ", ".join(f"{x:.1f}" for x in v) + ")"
def length(v): return dot(v, v) ** 0.5

V, D = triple(a, b, c), det([list(a), list(b), list(c)])
h = 0.25                                              # cube edge in dm; the box spans 29 x 18 x 12
n = sum(inside(((i + .5) * h, (j + .5) * h, (k + .5) * h)) for i in range(116) for j in range(72) for k in range(48))
def step(P, Q, R, S):                                 # plane road: reach S along two edges; what is left
    u, v, d = sub(Q, P), sub(R, P), sub(S, P); k = u[0] * v[1] - u[1] * v[0]
    s, t = (d[0] * v[1] - d[1] * v[0]) / k, (u[0] * d[1] - u[1] * d[0]) / k
    return k, d[2] - (s * u[2] + t * v[2])            # floor shadow of the base, height left over
O, P, Q, R = (0.0, 0.0, 0.0), c, add(c, a), add(c, b)  # corner at the floor, three lid corners
cases = (("flat lid", P, Q, R, add(Q, b)), ("sagging lid", P, Q, R, (29.0, 18.0, 11.5)),
         ("bent front", O, a, c, (24.0, 2.5, 12.0)))

print(f"edges in dm: a {show(a)}, b {show(b)}, c {show(c)}")
print(f"floor arrow a x b = {show(cross(a, b))}, floor area {length(cross(a, b)):.1f} dm^2")
print(f"road 1, (a x b) . c = {V:.1f} litres")
print(f"road 2, determinant with rows a, b, c = {D:.1f} litres")
print(f"road 3, {n} cubes of 1/64 litre inside = {n * h ** 3:.2f} litres")
print(f"a . (b x c) = {dot(a, cross(b, c)):.1f}; (b x a) . c = {triple(b, a, c):.1f}")
print(f"height straight up: {V:.1f} / {length(cross(a, b)):.1f} = {V / length(cross(a, b)):.1f} dm")
print(f"mistake 1, edge lengths multiplied: {length(a):.0f} x {length(b):.6f} x {length(c):.0f}"
      f" = {length(a) * length(b) * length(c):.2f}")
print(f"mistake 2, floor area x slanted edge: {length(cross(a, b)) * length(c):.1f}")
for name, p, q, r, S in cases:
    T, (k, z) = triple(sub(q, p), sub(r, p), sub(S, p)), step(p, q, r, S)
    print(f"{name} S {show(S)}: triple {T:.1f}; shadow {k:.1f} x leftover {z:.2f} = {k * z:.1f};"
          f" gap {T / length(cross(sub(q, p), sub(r, p))):.3f} dm")
print(f"mistake 3, corner positions Q, R, S of the flat lid as edges: {triple(Q, R, cases[0][4]):.1f}")
f = [(60 + 7 * (p[0] + p[1] * 3 ** 0.5 / 4), 205 - 7 * (p[2] + p[1] / 4)) for p in
     ((0, 0, 0), a, b, c, add(a, b), add(a, c), add(b, c), add(add(a, b), c), (4, 3, 0))]
G = ((1.0, 2.0, 3.0), (2.0, -1.0, 1.0), (0.0, 3.0, 1.0))  # a second box, every top-row term live
print(f"second box, rows {show(G[0])} {show(G[1])} {show(G[2])}: triple {triple(*G):.1f},"
      f" determinant {det([list(g) for g in G]):.1f}")
print(f"try changing: c (0, 0, 12) {triple(a, b, (0, 0, 12)):.1f}; c (4, 3, 6) {triple(a, b, (4, 3, 6)):.1f};"
      f" corner at 11.0: triple {triple(a, b, (25, 15, -1.0)):.1f}, gap {triple(a, b, (25, 15, -1.0)) / 300:.2f} dm")
print("figure, " + " ".join(f"{x:.2f},{y:.2f}" for x, y in f))
assert D == V and det([list(g) for g in G]) == triple(*G)  # two expansions, one number
assert abs(n * h ** 3 - V) < 0.01 * V                  # the cube count lands within 1%
assert triple(b, a, c) == -V                           # swapping two edges flips the sign
assert all(abs(triple(sub(q, p), sub(r, p), sub(S, p)) - step(p, q, r, S)[0] * step(p, q, r, S)[1]) < 1e-9
           for _, p, q, r, S in cases)                  # box volume = shadow x leftover height
print("ALL CHECKS PASS")
