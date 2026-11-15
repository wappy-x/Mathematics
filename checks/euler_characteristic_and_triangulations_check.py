# Euler characteristic -- the check behind the card.  Standard library only.
# A surface is a list of triangles, each a sorted triple of vertex numbers.
# Road 1 counts vertices, edges and triangles.  Road 2 adds up 6 minus each
# vertex's degree, which is 6 times chi on a closed surface of triangles.
# Road 3 cuts the dome and the tube up at random and recounts after every cut.
def tri(a, b, c):
    return tuple(sorted((a, b, c)))

def edge_uses(tris):                      # how many triangles touch each edge
    uses = {}
    for t in tris:
        for e in ((t[0], t[1]), (t[0], t[2]), (t[1], t[2])):
            uses[e] = uses.get(e, 0) + 1
    return uses

def counts(tris):
    return len({v for t in tris for v in t}), len(edge_uses(tris)), len(tris)

def chi(tris):
    return counts(tris)[0] - counts(tris)[1] + counts(tris)[2]

def degree_sum(tris):                     # road 2: sum of (6 - degree)
    deg = {}
    for a, b in edge_uses(tris):
        deg[a], deg[b] = deg.get(a, 0) + 1, deg.get(b, 0) + 1
    return sum(6 - d for d in deg.values()), sorted(deg.values())

def rim_loops(tris):                      # edges used once, joined into loops
    rim = [e for e, k in edge_uses(tris).items() if k == 1]
    boss = {v: v for e in rim for v in e}
    def find(x):
        return x if boss[x] == x else find(boss[x])
    for a, b in rim:
        boss[find(a)] = find(b)
    return len({find(v) for v in boss})

def is_surface(tris, closed):             # no repeats; each edge used once or twice
    ok = len(set(tris)) == len(tris) and all(len(set(t)) == 3 for t in tris)
    return ok and all(k == 2 or (k == 1 and not closed) for k in edge_uses(tris).values())

def icosahedron():                        # top 0, rings 1-5 and 6-10, bottom 11
    u, l, out = lambda i: 1 + i % 5, lambda i: 6 + i % 5, []
    for i in range(5):
        out += [tri(0, u(i), u(i + 1)), tri(u(i), u(i + 1), l(i)),
                tri(u(i + 1), l(i), l(i + 1)), tri(11, l(i), l(i + 1))]
    return out

def split4(tris):                         # each triangle into four, at edge midpoints
    mid, out = {}, []
    def m(a, b):
        return mid.setdefault((a, b), 12 + len(mid))
    for a, b, c in tris:
        ab, ac, bc = m(a, b), m(a, c), m(b, c)
        out += [tri(a, ab, ac), tri(b, ab, bc), tri(c, ac, bc), tri(ab, ac, bc)]
    return out

def grid(cols, rows, glue_i, glue_j):     # glue_i: 0 open, 1 straight, 2 half twist
    def name(i, j):
        if i == cols and glue_i:
            i, j = 0, (j if glue_i == 1 else rows - j)
        if j == rows and glue_j:
            j = 0
        return i * (rows + 1) + j
    out = []
    for i in range(cols):
        for j in range(rows):
            a, b, c, d = name(i, j), name(i + 1, j), name(i + 1, j + 1), name(i, j + 1)
            out += [(a, b, c), (a, d, c)]
    ids = sorted({v for t in out for v in t})   # renumber the corners 0, 1, 2, ...
    return [tri(*(ids.index(v) for v in t)) for t in out]

def yn(claim):
    return "yes" if claim else "no"

def show(label, tris):
    return f"{label}: V {counts(tris)[0]}, E {counts(tris)[1]}, F {len(tris)}, chi {chi(tris)}"

state = 2026                              # SplitMix64, written out
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return z ^ (z >> 31)

def cut_up(tris, moves):                  # road 3: random edge and face splits
    tris, new, ok, kinds, start = list(tris), 1 + max(map(max, tris)), True, [0, 0], chi(tris)
    for _ in range(moves):
        k, pick = rand() % len(tris), rand() % 4
        a, b, c = tris[k]
        if pick == 0:                     # a new corner inside triangle k
            tris[k] = tri(a, b, new)
            tris += [tri(a, c, new), tri(b, c, new)]
        else:                             # a new corner on one edge of triangle k
            a, b, c = [(a, b, c), (a, c, b), (b, c, a)][pick - 1]
            k2 = next(j for j, t in enumerate(tris) if j != k and a in t and b in t)
            d = sum(tris[k2]) - a - b
            tris[k], tris[k2] = tri(a, new, c), tri(a, new, d)
            tris += [tri(new, b, c), tri(new, b, d)]
        kinds[pick != 0] += 1
        new += 1
        ok = ok and chi(tris) == start and degree_sum(tris)[0] == 6 * start
    return tris, ok and is_surface(tris, True), kinds

dome, tube, flat, sleeve = split4(icosahedron()), grid(3, 3, 1, 1), grid(3, 3, 0, 0), grid(3, 3, 1, 0)
klein, loop, twist = grid(3, 3, 2, 1), grid(6, 1, 1, 0), grid(6, 1, 2, 0)
cut = tube[0]                             # pretzel: two tubes, one triangle out of each
pretzel = tube[1:] + [tri(*[v if v in cut else v + 100 for v in t]) for t in tube[1:]]
ds, dd = degree_sum(dome)
print(show("icosahedron, before subdividing", icosahedron()))
print(show("dome, geodesic sphere", dome))
print(f"dome degrees: {dd.count(5)} corners of 5 struts, {dd.count(6)} of 6; "
      f"sum of (6 - degree) = {ds} = 6 x {ds // 6}")
print(show("tube, 3 x 3 grid glued both ways", tube) + f"; sum of (6 - degree) = {degree_sum(tube)[0]}")
for label, t in (("flat square", flat), ("glued left to right", sleeve), ("glued top to bottom", tube)):
    print(show("  " + label, t) + f", rim loops {rim_loops(t)}")
print(show("pretzel, two tubes joined", pretzel) + f"; sum of (6 - degree) = {degree_sum(pretzel)[0]}")
print(show("klein bottle, one side flipped", klein))
print(show("paper strip, plain loop", loop) + f", rim loops {rim_loops(loop)}")
print(show("paper strip, half twist", twist) + f", rim loops {rim_loops(twist)}")
closed, rimmed = (dome, tube, pretzel, klein), (flat, sleeve, loop, twist)
all_ok = all(is_surface(t, True) for t in closed) and all(is_surface(t, False) for t in rimmed)
print(f"every model a surface of triangles, each edge on 1 or 2 of them: {yn(all_ok)}")
print(f"random cuts, SplitMix64 seed {state}, 300 on each, chi recounted after every cut:")
(d2, dok, dk), (t2, tok, tk) = cut_up(dome, 300), cut_up(tube, 300)
print(show("  dome", d2) + f"; unchanged every time: {yn(dok)}; edge cuts {dk[1]}, face cuts {dk[0]}")
print(show("  tube", t2) + f"; unchanged every time: {yn(tok)}; edge cuts {tk[1]}, face cuts {tk[0]}")
v, f = counts(dome)[0], len(dome)
print(f"mistake 1, flat square left unglued: {chi(flat)}, not 0")
print(f"mistake 2, struts counted once per panel: {v} - {3 * f} + {f} = {v - 3 * f + f}")
print(f"mistake 3, one dome panel left out: {chi(dome[1:])}, rim loops {rim_loops(dome[1:])}")
print(f"mistake 4, tube from a 2 x 2 grid: {show('counted', grid(2, 2, 1, 1))}; "
      f"a surface of triangles: {yn(is_surface(grid(2, 2, 1, 1), True))}")
print("figure, schematic: 3 x 3 squares, side 80, from (60, 40); left glued to right, bottom to top")
assert [chi(t) for t in closed] == [2, 0, -2, 0]                    # road 1, by counting
assert [degree_sum(t)[0] for t in closed] == [6 * chi(t) for t in closed]  # road 2 agrees
assert counts(dome) == (42, 120, 80) and dd.count(5) == 12 and counts(tube) == (9, 27, 18)
assert chi(flat) == 1 and rim_loops(loop) == 2 and rim_loops(twist) == 1
assert all_ok and dok and tok and not is_surface(grid(2, 2, 1, 1), True)
print("ALL CHECKS PASS")
