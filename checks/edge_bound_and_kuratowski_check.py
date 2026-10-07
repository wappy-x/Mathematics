# Why some graphs cannot be drawn flat -- the check behind the card.  Nothing is imported.  Road
# one is the Euler ceiling: a flat drawing of a simple graph on three dots or more holds at most
# 3V - 6 lines, and at most 2V - 4 when no three dots form a ring of three.  Road two never counts
# lines: it tries every cyclic order of lines round every dot, walks each order to count regions,
# and a flat drawing is one whose regions reach E - V + 2.
def complete(n): return [(u, v) for u in range(n) for v in range(u + 1, n)]
def utilities(a, b): return [(u, a + v) for u in range(a) for v in range(b)]
def adj(n, edges): return {u: [b if a == u else a for a, b in edges if u in (a, b)] for u in range(n)}
def degrees(n, edges): return sorted(len(vs) for vs in adj(n, edges).values())
def perms(xs): return [[x] + p for i, x in enumerate(xs) for p in perms(xs[:i] + xs[i + 1:])] or [[]]
def ring_free(n, es): return not any(w in adj(n, es)[v] for u, v in es for w in adj(n, es)[u])
RING = [(i, (i + 1) % 5) for i in range(5)]                                 # a pentagon of five dots
PET = RING + [(5 + i, 5 + (i + 2) % 5) for i in range(5)] + [(i, 5 + i) for i in range(5)]
ICO = (RING + [(5 + i, 5 + (i + 1) % 5) for i in range(5)] + [(10, i) for i in range(5)]
       + [(11, 5 + i) for i in range(5)] + [(i, 5 + i) for i in range(5)] + [(i, 5 + (i + 1) % 5) for i in range(5)])

def trace(rot):                              # one closed walk of the orders is one region
    used, faces = set(), []
    for start in sorted((u, v) for u in rot for v in rot[u]):
        if start in used: continue
        (u, v), sides = start, 0
        while (u, v) != start or sides == 0:
            used.add((u, v)); sides += 1; u, v = v, rot[v][rot[v].index(u) - 1]
        faces.append(sides)
    return sorted(faces)
def hunt(n, edges):                          # road two: every cyclic order round every dot
    choices = [[[ns[0]] + p for p in perms(ns[1:])] for ns in adj(n, edges).values()]
    total, best = 1, []
    for c in choices: total *= len(c)
    for k in range(total):
        rot, m = {}, k
        for u, c in enumerate(choices): rot[u], m = c[m % len(c)], m // len(c)
        if len(f := trace(rot)) > len(best): best = f
    return total, best
GRAPHS = [("K(3,3), the utilities", 6, utilities(3, 3)), ("K(5)", 5, complete(5)),
          ("K(5) minus one line", 5, [e for e in complete(5) if e != (3, 4)]), ("Petersen", 10, PET)]
print(f"{'graph':<22}{'V':>3}{'E':>4}{'3V-6':>6}{'2V-4':>6}{'over?':>7}{'orders':>8}{'best F':>8}{'target':>8}{'flat?':>7}")
rows = []
for name, n, edges in GRAPHS:
    e, c3, c4, free = len(edges), 3 * n - 6, 2 * n - 4, ring_free(n, edges)
    total, best = hunt(n, edges)
    rows.append((n, e, e > c3 or (free and e > c4), total, best, e - n + 2))
    cells = [n, e, c3, c4 if free else "-", "yes" if rows[-1][2] else "no", total, len(best), e - n + 2, "yes" if len(best) == e - n + 2 else "no"]
    print(f"{name:<22}" + "".join(f"{c:>{w}}" for c, w in zip(cells, (3, 4, 6, 6, 7, 8, 8, 8, 7))))
hv, he, flat, pet = 6, 9, rows[2], rows[3]
print(f"the three houses: dots {hv}, pipes wanted {he}, regions if it could be drawn {he - hv + 2}, pipe-sides {2 * he}, sides the regions need {4 * (he - hv + 2)}")
print(f"no ring of three, so the ceiling is 2 x {hv} - 4 = {2 * hv - 4}: {he} pipes is one too many")
print(f"the drawing found for K(5) minus one line: {len(flat[4])} regions, sides {' '.join(map(str, flat[4]))}, adding to 2E = {sum(flat[4])}")
print("a dot of small degree: the degrees add to 2E, so a flat drawing averages under 6")
print(f"  K(5) minus one line: V = {flat[0]}, E = {flat[1]}, average degree {2 * flat[1] / flat[0]:.2f}, degrees {degrees(5, GRAPHS[2][2])}")
print(f"  icosahedron: V = 12, E = {len(ICO)} = 3V - 6 = {3 * 12 - 6}, average degree {2 * len(ICO) / 12:.2f}, every degree {min(degrees(12, ICO))}, regions {len(ICO) - 12 + 2}")
print(f"mistake 1, the ring-of-three ceiling on the utilities: {he} <= {3 * hv - 6} says it fits, and the right ceiling is {2 * hv - 4}")
print(f"mistake 2, the ceiling read as permission: Petersen {pet[1]} <= {3 * 10 - 6} and <= {2 * 10 - 4}, yet {pet[3]} orders reach only {len(pet[4])} regions, not {pet[5]}")
print(f"mistake 3, the ceiling on two dots and one line: 1 > 3 x 2 - 6 = {3 * 2 - 6} calls one line impossible")
assert [len(r[4]) for r in rows] == [3, 5, 6, 5] and [r[3] for r in rows] == [64, 7776, 864, 1024]
assert [r[2] for r in rows] == [True, True, False, False]     # counting is silent on Petersen
assert [len(r[4]) == r[5] for r in rows] == [False, False, True, False]
assert sum(flat[4]) == 2 * flat[1] and min(flat[4]) >= 3 and degrees(12, ICO) == [5] * 12
print("ALL CHECKS PASS")
