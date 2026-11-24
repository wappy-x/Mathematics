# Plane isometries and three reflections -- the check behind the card.  Standard library only.  A move is
# (A, t): p -> A p + t.  Road one names it from A and its fixed points; road two rebuilds it from mirrors.
from math import sqrt, atan2, acos, degrees, dist
def num(v): v = round(v, 6) + 0.0; return str(int(v)) if v == int(v) else f"{v:g}"
def pt(p): return f"({num(p[0])}, {num(p[1])})"
def go(f, p): (a, b), (c, d) = f[0]; return (a * p[0] + b * p[1] + f[1][0], c * p[0] + d * p[1] + f[1][1])
def chain(ms):                       # apply the mirrors in order, first mirror first
    A, t = ((1, 0), (0, 1)), (0, 0)
    for n, c in ms:                  # mirror n . p = c, n a unit normal: p -> p - 2(n . p - c) n
        R = ((1 - 2 * n[0] ** 2, -2 * n[0] * n[1]), (-2 * n[0] * n[1], 1 - 2 * n[1] ** 2))
        A = tuple(tuple(sum(R[i][k] * A[k][j] for k in range(2)) for j in range(2)) for i in range(2))
        t = go((R, (2 * c * n[0], 2 * c * n[1])), t)
    return A, t
def line(n, c):
    s = n[0] if abs(n[0]) > 1e-9 else n[1]; w = lambda k: "" if abs(abs(k / s) - 1) < 1e-9 else num(abs(k / s))
    terms = [("-" if k / s < 0 else "+", w(k) + v) for k, v in ((n[0], "x"), (n[1], "y")) if abs(k) > 1e-9]
    return terms[0][1] + "".join(f" {g} {v}" for g, v in terms[1:]) + f" = {num(c / s)}"
def say(kind, size): return {"rotation": f"rotation by {num(size)} degrees", "translation": f"translation by {num(size)}",
                             "reflection": "reflection", "glide reflection": f"glide reflection, slide {num(size)}"}[kind]
def road1(f):                        # from the matrix and the fixed points
    ((a, b), (c, d)), t = f
    if a * d - b * c > 0 and abs(a - 1) + abs(c) < 1e-9: return "translation", dist(t, (0, 0)), "det +1, no fixed point"
    if a * d - b * c > 0:            # solve (I - A) p = t by Cramer's rule
        D = (1 - a) * (1 - d) - b * c; fix = ((t[0] * (1 - d) + b * t[1]) / D, ((1 - a) * t[1] + c * t[0]) / D); assert dist(go(f, fix), fix) < 1e-9
        return "rotation", degrees(atan2(c, a)), f"det +1, one fixed point {pt(fix)}"
    u = (1 + a, c) if abs(1 + a) + abs(c) > 1e-9 else (b, 1 + d)   # a column of I + A: along the mirror
    s = abs(t[0] * u[0] + t[1] * u[1]) / dist(u, (0, 0))
    return ("reflection", 0, "det -1, a whole line fixed") if s < 1e-9 else ("glide reflection", s, "det -1, no fixed point")
def road2(f):                        # the three-point recipe, then name from mirrors and points only
    ms = []
    for P in ((0, 0), (1, 0), (0, 1)):
        Q, R = go(chain(ms), P), go(f, P)
        if dist(Q, R) < 1e-9: continue
        n = ((R[0] - Q[0]) / dist(Q, R), (R[1] - Q[1]) / dist(Q, R))   # perpendicular bisector of Q and R
        ms.append((n, n[0] * (Q[0] + R[0]) / 2 + n[1] * (Q[1] + R[1]) / 2))
    if len(ms) == 3: return ms, "glide reflection", dist(go(chain(ms * 2), (0, 0)), (0, 0)) / 2   # twice = a slide
    if len(ms) < 2: return ms, ["identity", "reflection"][len(ms)], 0
    (n1, c1), (n2, c2) = ms; dot = n1[0] * n2[0] + n1[1] * n2[1]
    if abs(abs(dot) - 1) < 1e-9: return ms, "translation", 2 * abs(c2 - dot * c1)   # parallel: twice the gap
    return ms, "rotation", 2 * degrees(acos(abs(dot)))                          # crossing: twice the angle
r2, grid = 1 / sqrt(2), [(x / 2 - 2.5, y / 2 - 2.5) for x in range(11) for y in range(11)]
cases = {"quarter turn": [((0, 1), 0), ((r2, -r2), 0)], "slide": [((1, 0), 0), ((1, 0), 1)],
         "mirror": [((r2, -r2), 0)], "glide": [((1, 0), 0), ((1, 0), 1), ((0, 1), 0)]}
for (name, ms), m in zip(cases.items(), (2, 2, 1, 3)):     # m: the fewest mirrors
    f = chain(ms); (a, b), (c, d) = f[0]; k1, s1, why = road1(f); rec, k2, s2 = road2(f)
    print(f"{name}: mirrors {', '.join(line(n, c) for n, c in ms)}; A = [[{num(a)}, {num(b)}], [{num(c)}, {num(d)}]], t = {pt(f[1])}")
    print(f"  matrix road: {why} -> {say(k1, s1)}")
    print(f"  recipe road: {', '.join(line(n, c) for n, c in rec)} -> {say(k2, s2)}")
    assert k1 == k2 and abs(s1 - s2) < 1e-9 and len(rec) == m and max(dist(go(f, p), go(chain(rec), p)) for p in grid) < 1e-9
glide, turn = chain(cases["glide"]), chain(cases["quarter turn"]); (_, c1), (_, c2), ((u1, v1), _), ((u2, v2), _) = cases["slide"] + cases["quarter turn"]   # the spec: (x + 2, -y), (-y, x)
assert max(dist(go(glide, p), (p[0] + 2, -p[1])) + dist(go(turn, p), (-p[1], p[0])) for p in grid) < 1e-12
assert all(abs(dist(go(glide, p), go(glide, q)) - dist(p, q)) < 1e-12 for p in grid for q in grid[::7])
print(f"footprint heel {pt((0, 0.25))} -> {pt(go(glide, (0, 0.25)))}; at 35 cm a unit, one step is {num(2 * 35)} cm")
print(f"mistakes: mirrors swapped send (1, 0) to {pt(go(chain(cases['quarter turn'][::-1]), (1, 0)))}, not "
      f"{pt(go(turn, (1, 0)))}; the glide done twice sends (0, 0) to {pt(go(glide, go(glide, (0, 0))))}")
print(f"mistakes: mirror gap {num(abs(c2 - c1))}, true slide {num(road1(chain(cases['slide']))[1])}; mirror angle "
      f"{num(degrees(acos(abs(u1 * u2 + v1 * v2))))} degrees, true turn {num(road1(turn)[1])} degrees")
print("figure, O X Y after 0 to 3 recipe mirrors, drawn at (45 + 60x, 110 - 60y): " + "; ".join(" ".join(pt(go(
      chain(road2(glide)[0][:k]), p)) for p in ((0, 0), (1, 0), (0, 1))) for k in range(4)))
print("ALL CHECKS PASS")
