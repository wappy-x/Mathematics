# Triangulating a polygon, and the art gallery theorem: the check behind the card.
# Standard library only. Road one clips ears, colours the corners in 3 colours
# and takes the rarest colour as guards. Road two never colours: it samples each
# gallery on a grid and tests every sight line against every wall.
from math import atan2, pi                                                 # for the angle road only
FIELD = [(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]                 # A to F
COMB = [(0, 0), (14, 0), (13, 7), (12, 1), (10, 1), (9, 7), (8, 1), (6, 1),
        (5, 7), (4, 1), (2, 1), (1, 7)]                                    # 4 prongs
def turn(a, b, c): return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def area(P): return sum(turn((0, 0), P[i - 1], P[i]) for i in range(len(P))) / 2
def in_tri(a, b, c, p): return turn(a, b, p) >= 0 and turn(b, c, p) >= 0 and turn(c, a, p) >= 0
def angles(P): return sum(1 - atan2(turn(P[i - 2], P[i - 1], P[i]), (P[i - 1][0] - P[i - 2][0]) * (P[i][0] - P[i - 1][0])
                           + (P[i - 1][1] - P[i - 2][1]) * (P[i][1] - P[i - 1][1])) / pi for i in range(len(P)))  # in 180s
def clip(P):                       # ear clipping: the triangles, in clipping order
    live, tris = list(range(len(P))), []
    while len(live) > 3:
        for k in range(len(live)):
            a, b, c = live[k - 1], live[k], live[(k + 1) % len(live)]
            if turn(P[a], P[b], P[c]) > 0 and not any(
                    in_tri(P[a], P[b], P[c], P[j]) for j in live if j not in (a, b, c)):
                tris.append((a, b, c)); live.pop(k); break
    return tris + [tuple(live)]
def colour(tris):                  # undo the clipping; each ear's tip takes the missing colour
    col = dict(zip(tris[-1], (1, 2, 3)))
    for a, b, c in reversed(tris[:-1]): col[b] = 6 - col[a] - col[c]
    return col
def crosses(p, q, a, b): return turn(p, q, a) * turn(p, q, b) < 0 and turn(a, b, p) * turn(a, b, q) < 0
def sees(P, g, p): return not any(crosses(g, p, P[i - 1], P[i]) for i in range(len(P)))
def inside(P, p): return sum((a[1] > p[1]) != (b[1] > p[1]) and turn(a, b, p) * (b[1] - a[1]) > 0
                             for a, b in zip(P[-1:] + P[:-1], P)) % 2 == 1
def grid(P): return [p for i in range(160) for j in range(90) if inside(P, p := ((i + 0.37) / 10, (j + 0.61) / 10))]
def gallery(P, names):             # names: one letter per corner
    tris, n, pts, ang = clip(P), len(P), grid(P), angles(P)
    col, tri_area = colour(tris), sum(abs(turn(*(P[v] for v in t))) for t in tris) / 2
    cls = ["".join(names[v] for v in range(n) if col[v] == k) for k in (1, 2, 3)]
    seen = [sum(any(sees(P, P[names.index(g)], p) for g in c) for p in pts) for c in cls]
    print(f"n = {n}: {len(tris)} triangles,", ", ".join("".join(names[v] for v in t) + f" {turn(*(P[v] for v in t)) / 2}" for t in tris))
    print(f"  triangle areas add to {tri_area}; shoelace {area(P)}; inside angles {ang:.1f} x 180 degrees; colours 1, 2, 3: {', '.join(cls)}; rarest {min(map(len, cls))}, n // 3 = {n // 3}")
    print(f"  grid points inside: {len(pts)}; seen by each colour's corners: {seen}")
    assert all(turn(*(P[v] for v in t)) > 0 for t in tris) and abs(tri_area - area(P)) < 1e-9 and abs(ang - len(tris)) < 1e-9  # road three
    assert all(len({col[v] for v in t}) == 3 for t in tris)                # one corner of each colour per triangle
    assert seen == [len(pts)] * 3                     # road two agrees: each colour guards it all
    return pts
(pts, comb), (A, B, C, D, E, F) = (gallery(FIELD, "ABCDEF"), gallery(COMB, "abcdefghijkl")), FIELD
print(f"field: turn at D {turn(C, D, E)}; D alone sees {(nd := sum(sees(FIELD, D, p) for p in pts))} points")
assert nd == len(pts) and all(turn(FIELD[i - 1], FIELD[i], D) >= 0 for i in range(6))   # D on the inner side of every fence
fl = [sorted(COMB[t][0] + (q[0] - COMB[t][0]) * COMB[t][1] / (COMB[t][1] - q[1]) for q in (COMB[t - 1], COMB[(t + 1) % 12])) for t in (11, 8, 5, 2)]  # walls meet the floor
print("comb: floor seen from each tip:", ", ".join(f"{a:.2f} to {b:.2f}" for a, b in fl))
most = max(sum(sees(COMB, COMB[t], p) for t in (11, 8, 5, 2)) for p in comb)
assert most == 1 and all(fl[k][1] < fl[k + 1][0] for k in range(3))     # strips and grid agree: no point sees two tips
print(f"comb: most tips one grid point sees: {most}, so {len(fl)} guards are needed")
s = turn(B, D, E) / (turn(B, D, E) - turn(B, D, F)); Q = (E[0] + s * (F[0] - E[0]), E[1] + s * (F[1] - E[1]))  # line BD meets EF
hid, ex = [p for p in pts if not (sees(FIELD, B, p) or sees(FIELD, C, p))], turn(D, E, Q) / 2
print(f"what breaks: clip reflex D first: triangles cover {abs(turn(C, D, E)) / 2 + area(FIELD[:3] + FIELD[4:])} ha, not {area(FIELD)}")
print(f"what breaks: guards at B and C miss triangle D, E, ({Q[0]:.1f}, {Q[1]:.1f}): {ex:.1f} ha, {100 * ex / area(FIELD):.1f}%; grid {len(hid)} of {len(pts)} points ({100 * len(hid) / len(pts):.1f}%)")
assert hid == [p for p in pts if in_tri(D, E, Q, p)] and abs(len(hid) / len(pts) - ex / area(FIELD)) < 0.01
print(f"what breaks: one guard per triangle: {len(FIELD) - 2} guards, not {len(FIELD) // 3}")
print("figure, field:", ", ".join(f"{n} ({30 + 26 * x}, {222 - 26 * y})" for n, (x, y) in zip("ABCDEF", FIELD)))
print("figure, comb:", ", ".join(f"{n} ({370 + 18 * x}, {222 - 18 * y})" for n, (x, y) in zip("abcdefghijkl", COMB)))
print("ALL CHECKS PASS")
