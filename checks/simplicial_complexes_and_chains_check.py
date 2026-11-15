# Simplicial complexes and chains -- the check behind the card.  Nothing is
# imported.  A simplex is a tuple of vertex numbers in increasing order, and a
# chain is a list of integers, one per simplex.  Road 1 multiplies boundary
# matrices.  Road 2 takes the boundary of every vertex order of each triangle,
# with a sign from counting swaps.  Road 3 tallies the two routes from a
# triangle to each corner.  Then the 42-joint dome, and three mistakes.

def closure(tops):                       # every face of every listed simplex
    out = set()
    for s in tops:
        for mask in range(1, 2 ** len(s)):
            out.add(tuple(v for i, v in enumerate(s) if mask >> i & 1))
    return out

def layer(cx, k):                        # the k-simplices, in sorted order
    return sorted(s for s in cx if len(s) == k + 1)

def bd(s, signed=True):                  # boundary of one simplex: (sign, face) terms
    return [((-1) ** i if signed else 1, s[:i] + s[i + 1:]) for i in range(len(s))]

def matrix(rows, cols, signed=True):     # column j holds the boundary of cols[j]
    m = [[0] * len(cols) for _ in rows]
    for j, s in enumerate(cols):
        for sg, f in bd(s, signed):
            m[rows.index(f)][j] += sg
    return m

def mul(a, b):
    return [[sum(a[i][t] * b[t][j] for t in range(len(b))) for j in range(len(b[0]))]
            for i in range(len(a))]

def apply(m, c):
    return [sum(m[i][j] * c[j] for j in range(len(c))) for i in range(len(m))]

def name(s):
    return "[" + ",".join(str(v) for v in s) + "]"

def fmt(d):                              # a formal sum {simplex: coefficient}
    t = [("+" if c > 0 else "-") + (str(abs(c)) if abs(c) != 1 else "") + name(s)
         for s, c in sorted(d.items()) if c]
    return " ".join(t) if t else "0"

def sort_sign(s):                        # bubble sort; every swap flips the sign
    s, sg = list(s), 1
    for i in range(len(s)):
        for j in range(len(s) - 1 - i):
            if s[j] > s[j + 1]:
                s[j], s[j + 1], sg = s[j + 1], s[j], -sg
    return sg, tuple(s)

def d_sum(chain, signed_sort=True):      # road 2: boundary of a formal sum, any order
    out = {}
    for s, c in chain.items():
        for i in range(len(s)):
            sg, f = sort_sign(s[:i] + s[i + 1:])
            out[f] = out.get(f, 0) + c * (-1) ** i * (sg if signed_sort else 1)
    return {f: c for f, c in out.items() if c}

def orders(s):                           # every ordering of a simplex's vertices
    return [s] if len(s) < 2 else [(v,) + r for v in s for r in orders(tuple(x for x in s if x != v))]

def zero(m):
    return all(x == 0 for row in m for x in row)

def yn(claim):
    return "yes" if claim else "no"

tet = closure([(0, 1, 2, 3)]) - {(0, 1, 2, 3)}           # the hollow tetrahedron
V, E, T = layer(tet, 0), layer(tet, 1), layer(tet, 2)
d1, d2 = matrix(V, E), matrix(E, T)
d1d2 = mul(d1, d2)
print("hollow tetrahedron: vertices", len(V), "edges", len(E), "triangles", len(T))
print("chi = %d - %d + %d = %d" % (len(V), len(E), len(T), len(V) - len(E) + len(T)))
print("edges:", " ".join(name(e) for e in E))
print("triangles:", " ".join(name(t) for t in T))
print("boundary of [0,1,2] =", " ".join(("+" if sg > 0 else "-") + name(f) for sg, f in bd((0, 1, 2))))
print("boundary of that =", fmt(d_sum(d_sum({(0, 1, 2): 1}))))
print("d1, rows = vertices, columns = edges:")
for r in d1: print("  ", r)
print("d2, rows = edges, columns = triangles:")
for r in d2: print("  ", r)
print("d1 times d2:", d1d2)
z = [-1, 1, -1, 1]                       # the shell, oriented as the solid's boundary
solid = matrix(T, [(0, 1, 2, 3)])
print("boundary of solid [0,1,2,3] =", fmt(d_sum({(0, 1, 2, 3): 1})), "->", [r[0] for r in solid])
print("boundary of the whole shell:", apply(d2, z))
hole = [0, 1, -1, 1]                     # panel [0,1,2] lifted out
print("panel [0,1,2] lifted out, boundary of the rest", hole, "is", apply(d2, hole), "=",
      fmt(dict(zip(E, apply(d2, hole)))))
road2 = [(p, d_sum({p: 1}), d_sum({t: 1})) for t in T for p in orders(t)]
same = sum(d == {f: c * sort_sign(p)[0] for f, c in d0.items()} and d_sum(d) == {}
           for p, d, d0 in road2)
print("road 2: vertex orders of the 4 triangles with boundary = sign x sorted one, and boundary twice 0:",
      same, "of", len(road2))
tally = {}
for sg, f in bd((0, 1, 2)):
    for sg2, g in bd(f):
        tally.setdefault(g, []).append(sg * sg2)
print("road 3: routes from [0,1,2] to each corner, with signs:",
      " ".join(name(g) + str(tally[g]) for g in sorted(tally)))
ico = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4),
       (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8),
       (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
mid = {}
def m(a, b):                             # the new joint at the middle of strut a-b
    return mid.setdefault((min(a, b), max(a, b)), 12 + len(mid))
panels = []
for a, b, c in ico:
    x, y, w = m(a, b), m(b, c), m(c, a)
    panels += [tuple(sorted(f)) for f in [(a, x, w), (b, y, x), (c, w, y), (x, y, w)]]
dome = closure(panels)
DV, DE, DT = layer(dome, 0), layer(dome, 1), layer(dome, 2)
dd1, dd2 = matrix(DV, DE), matrix(DE, DT)
twice = all(sum(1 for x in row if x) == 2 for row in dd2)
dome_zero = zero(mul(dd1, dd2))
print("dome: joints", len(DV), "struts", len(DE), "panels", len(DT), "chi",
      len(DV) - len(DE) + len(DT), "| every strut in 2 panels:", yn(twice),
      "| d1 times d2 zero in all", len(DV) * len(DT), "entries:", yn(dome_zero))
u = mul(matrix(V, E, False), matrix(E, T, False))
print("mistake 1, no signs: boundary twice of [0,1,2] =",
      fmt({(v,): u[v][0] for v in range(4)}), "| entries equal to 2:", sum(x == 2 for r in u for x in r))
bad = d_sum({(0, 2, 1): 1}, signed_sort=False)
print("mistake 2, face [2,1] of [0,2,1] sorted with no sign flip: boundary =", fmt(bad),
      "| boundary twice =", fmt(d_sum(bad)))
cut = (0, 1)                             # the edge left off the list
lost = sum(1 for t in T for sg, f in bd(t) if f == cut)
print("mistake 3, edge", name(cut), "left off the list: triangle boundary terms with no row:", lost)
print("figure, joints 0 (70,270) 1 (350,270) 2 (230,340) 3 (210,60); arrows run low label to high")
assert zero(d1d2) and zero(mul(d2, solid))                 # road 1: the matrix products
assert d_sum(d_sum({(0, 1, 2): 1})) == {} and same == 24   # road 2: any vertex order
assert all(sorted(v) == [-1, 1] for v in tally.values())  # road 3: two routes, opposite signs
assert apply(d2, z) == [0] * 6 and z == [r[0] for r in solid]
assert apply(d2, hole) == [r[0] for r in d2]               # the rim is the lifted panel's
assert (len(DV), len(DE), len(DT)) == (42, 120, 80) and twice and dome_zero
assert u[0][0] == 2 and d_sum(bad) == {(1,): -2, (2,): 2} and lost == 2
print("ALL CHECKS PASS")
