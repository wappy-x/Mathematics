# Radon, Helly and Caratheodory in the plane, from one engine: weights on four points
# that add to 0 and balance to (0, 0).  Nothing imported.  Each fact meets a brute force.
def turn(a, b, c):                       # twice the signed area of triangle a, b, c
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
def dep(p):                              # the dependence on four points, by turns
    return [turn(p[1], p[2], p[3]), -turn(p[0], p[2], p[3]), turn(p[0], p[1], p[3]), -turn(p[0], p[1], p[2])]
def in_tri(x, a, b, c):                  # on or inside triangle a, b, c
    s = [turn(a, b, x), turn(b, c, x), turn(c, a, x)]; return min(s) >= -1e-9 or max(s) <= 1e-9
def cross(a, b, c, d):                   # segments ab and cd meet
    return turn(a, b, c) * turn(a, b, d) <= 0 and turn(c, d, a) * turn(c, d, b) <= 0
def show(p, g):                          # a split, written with the group holding p[0] first
    h = [i for i in range(4) if i not in g]; g, h = (g, h) if 0 in g else (h, g)
    return " ".join(str(p[i]) for i in g) + " | " + " ".join(str(p[i]) for i in h)
def radon(p):                            # road one: split by the signs of the dependence
    lam = dep(p); pos = [i for i in range(4) if lam[i] > 0]; s = sum(lam[i] for i in pos)
    return lam, show(p, pos), tuple(sum(lam[i] * p[i][k] for i in pos) / s for k in (0, 1))
def splits(p):                           # road two: try all 7 splits, test the hulls
    meets = lambda g, h: cross(*[p[i] for i in g + h]) if len(g) == 2 else in_tri(p[h[0]], *[p[i] for i in g])
    return [show(p, g) for g in [[1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2], [0, 1], [0, 2], [0, 3]] if meets(g, [i for i in range(4) if i not in g])]
f = lambda v: f"({v[0]:.3f}, {v[1]:.3f})"
P, Q, I = [(0, 0), (4, 0), (0, 4), (1, 1)], [(0, 0), (4, 0), (0, 4), (3, 3)], [(0, 5), (2, 7), (4, 9), (3, 6)]
(lam, split, r), (lq, sq, rq), V = radon(P), radon(Q), P[:3]
print(f"dependence on {P}: weights {lam}; sum {sum(lam)}, balance {tuple(sum(l * q[k] for l, q in zip(lam, P)) for k in (0, 1))}")
print(f"road one, by signs: {split}; Radon point {f(r)}\nroad two, all 7 splits, hulls meeting: {'; '.join(splits(P))}")
print(f"(1, 1) moved to (3, 3): weights {lq}; by signs {sq}, point {f(rq)}; brute force {'; '.join(splits(Q))}")
print(f"three points only, a corner on the line through the other two: {sum(turn(V[i - 2], V[i - 1], V[i]) == 0 for i in range(3))} of 3")
pairs = sum(max(a[0], b[0]) <= min(a[1], b[1]) for i, a in enumerate(I) for b in I[i + 1:])
lo, hi = max(a for a, b in I), min(b for a, b in I); scan = [k / 4 for k in range(37) if all(a <= k / 4 <= b for a, b in I)]
print(f"Helly on a line: {I}; pairs meeting {pairs} of 6; common part [{lo}, {hi}]; quarter-hour scan {scan[0]} to {scan[-1]}")
print(f"[0, 5] cut to [0, 3]: largest left end {lo}, smallest right end {min(3, hi)}: nothing common")
H = [((0, 0), (4, 0)), ((4, 0), (4, 4)), ((4, 4), (0, 4)), ((0, 4), (0, 0))]  # half-planes: left of each side of a square
pk = [next(g for g in [(x, y) for x in range(-2, 7) for y in range(-2, 7)] if turn(*H[j], g) < 0 and all(turn(*H[i], g) > 0 for i in range(4) if i != j)) for j in range(4)]; rh = radon(pk)[2]
print(f"Helly in the plane: 4 half-planes, inner sides of a 4 by 4 square; a grid point in each three, outside the fourth: {pk}; Radon point {f(rh)} in all four: {all(turn(*h, rh) >= 0 for h in H)}")
on = [sum(turn(V[i], V[i - 1], c) == 0 and min(V[i][0], V[i - 1][0]) <= c[0] <= max(V[i][0], V[i - 1][0]) for i in range(3)) for c in V]
print(f"the triangle's three sides: pairs meeting {sum(cross(V[i], V[i - 1], V[j], V[j - 1]) for i in range(3) for j in range(i))} of 3; sides through each corner {on}")
N, S, w, drops, bad = "ABCDEF", [(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)], [1 / 6] * 6, [], None
x = tuple(sum(wi * s[k] for wi, s in zip(w, S)) for k in (0, 1))
print(f"Caratheodory: x = average of the 6 survey corners = {f(x)}; in the notch C D E: {in_tri(x, S[2], S[3], S[4])}")
while len(live := [i for i in range(6) if w[i] > 1e-12]) > 3:
    q = live[:4]; lam = dep([S[i] for i in q])
    t, j = min((w[i] / l, i) for i, l in zip(q, lam) if l > 0)
    if bad is None: bad = min(w[i] - max(w[i] / l for i, l in zip(q, lam) if l > 0) * l for i, l in zip(q, lam))
    for i, l in zip(q, lam): w[i] -= t * l
    w[j] = 0.0; drops.append(f"drop {N[j]}: weights {lam} on {''.join(N[i] for i in q)}, step {t:.4f}; now " + " ".join(f"{N[i]} {w[i]:.4f}" for i in range(6)))
a, b, c = live
bary = [turn(x, S[b], S[c]), turn(S[a], x, S[c]), turn(S[a], S[b], x)]
mix = [w[a] * S[a][k] + w[b] * S[b][k] + w[c] * S[c][k] for k in (0, 1)]
holds = [N[i] + N[j] + N[k] for i in range(6) for j in range(i + 1, 6) for k in range(j + 1, 6) if in_tri(x, S[i], S[j], S[k])]
print("\n".join(drops) + f"\nleaves {N[a]}{N[b]}{N[c]}, weights {w[a]:.4f}, {w[b]:.4f}, {w[c]:.4f}; mix {f(mix)}")
print(f"road two, weights as turn ratios: {', '.join(f'{v / sum(bary):.4f}' for v in bary)}\nbrute force, corner triangles holding x: {len(holds)} of 20: {' '.join(holds)}")
print(f"mistake, trimming by the largest ratio: smallest weight {bad:.4f}")
print("figure, left 40 per unit from (40, 200): " + " ".join(f"({40 + 40 * p[0]}, {200 - 40 * p[1]})" for p in P) + "; right 22 per unit from (250, 215): "
      + " ".join(f"{n} ({250 + 22 * p[0]}, {215 - 22 * p[1]})" for n, p in zip(N, S)) + f" x ({250 + 22 * x[0]:.1f}, {215 - 22 * x[1]:.1f})")
assert splits(P) == [split] and splits(Q) == [sq]                      # signs agree with brute force
assert turn(Q[0], Q[3], rq) == 0 and turn(Q[1], Q[2], rq) == 0          # (2, 2) is on both lines
assert pairs == 6 and [scan[0], scan[-1]] == [lo, hi]                  # formula agrees with the scan
assert all(turn(*h, rh) >= 0 for h in H)                               # Helly by Radon: in all four
assert N[a] + N[b] + N[c] in holds and all(abs(u / sum(bary) - v) < 1e-9 for u, v in zip(bary, [w[a], w[b], w[c]]))
assert abs(mix[0] - x[0]) < 1e-9 and abs(mix[1] - x[1]) < 1e-9 and bad < 0
print("ALL CHECKS PASS")
