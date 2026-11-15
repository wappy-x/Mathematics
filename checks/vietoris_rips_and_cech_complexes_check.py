# Vietoris-Rips and Cech complexes -- the check behind the card.  Standard library only.
# Twelve sensor sites (metres), ball radius r: a Rips edge joins sites within 2r.
# Roads: Cech membership by the angle rule plus Helly, against a brute-force smallest
# enclosing circle on every subset; holes by mod-2 ranks, against union-find for the
# pieces and against a flood fill of the real union of discs (the nerve theorem).
from fractions import Fraction as F
from itertools import combinations
P = [(270, 200), (235, 285), (150, 320), (65, 285), (30, 200), (65, 115), (150, 80),
     (235, 115), (330, 278), (102, 315), (0, 120), (200, 10)]
N = len(P)

def d2(a, b):
    return (P[a][0] - P[b][0]) ** 2 + (P[a][1] - P[b][1]) ** 2
def cross(a, b, c):
    return (P[b][0] - P[a][0]) * (P[c][1] - P[a][1]) - (P[b][1] - P[a][1]) * (P[c][0] - P[a][0])

def circum2(a, b, c):                        # circumradius squared, exact
    return F(d2(a, b) * d2(b, c) * d2(a, c), 4 * cross(a, b, c) ** 2)

def tri_ok(t, rr, rule=True):                # road 1: discs of radius r around a, b, c share a point
    s = sorted(d2(*e) for e in combinations(t, 2))
    if rule and s[2] >= s[0] + s[1]:         # right or obtuse: the longest side is a diameter
        return s[2] <= 4 * rr
    return s[2] <= 4 * rr and circum2(*t) <= rr

def centres(s):                              # every candidate centre of a smallest enclosing circle
    for a, b in combinations(s, 2):
        yield (F(P[a][0] + P[b][0], 2), F(P[a][1] + P[b][1], 2))
    for a, b, c in combinations(s, 3):
        D = 2 * cross(a, b, c)
        if D:
            bx, by, cx, cy = P[b][0] - P[a][0], P[b][1] - P[a][1], P[c][0] - P[a][0], P[c][1] - P[a][1]
            yield (P[a][0] + F(cy * d2(a, b) - by * d2(a, c), D), P[a][1] + F(bx * d2(a, c) - cx * d2(a, b), D))

def meb2(s):                                 # road 2: smallest enclosing circle, brute force
    return min(max((x - P[v][0]) ** 2 + (y - P[v][1]) ** 2 for v in s) for x, y in centres(s))

def complexes(rr, rule=True):
    E = [e for e in combinations(range(N), 2) if d2(*e) <= 4 * rr]
    R, C = {0: [(v,) for v in range(N)], 1: E}, {0: [(v,) for v in range(N)], 1: E}
    for k in range(2, N):
        R[k] = [s for s in combinations(range(N), k + 1) if all(e in E for e in combinations(s, 2))]
        C[k] = [s for s in R[k] if all(tri_ok(t, rr, rule) for t in combinations(s, 3))]  # Helly
        if not R[k]:
            break
    return R, C

def betti(K):                                # over Z mod 2: columns as sorted lists, reduced by lowest row
    rank = {}
    for k in range(1, len(K)):
        row, low, rk = {s: i for i, s in enumerate(K[k - 1])}, {}, 0
        for s in K[k]:
            c = sorted(row[s[:i] + s[i + 1:]] for i in range(len(s)))
            while c and c[-1] in low:
                c = sorted(set(c) ^ set(low[c[-1]]))
            if c:
                low[c[-1]], rk = c, rk + 1
        rank[k] = rk
    return [len(K[k]) - rank.get(k, 0) - rank.get(k + 1, 0) for k in range(len(K))]

def pieces(E):                               # union-find on the edges: betti0 without any rank
    root = list(range(N))
    def find(v):
        while root[v] != v:
            v = root[v]
        return v
    for a, b in E:
        root[find(a)] = find(b)
    return len({find(v) for v in range(N)})

def union(rr):                               # flood fill on a 1 m grid: covered pieces, enclosed gaps
    m = int(rr ** 0.5) + 10
    xs, ys = range(min(p[0] for p in P) - m, max(p[0] for p in P) + m + 1), range(min(p[1] for p in P) - m, max(p[1] for p in P) + m + 1)
    cov = {(x, y): any((x - a) ** 2 + (y - b) ** 2 <= rr for a, b in P) for x in xs for y in ys}
    seen, pieces, gaps = set(), 0, []
    for start, val in cov.items():
        if start in seen:
            continue
        stack, size, edge = [start], 0, False
        seen.add(start)
        while stack:
            x, y = stack.pop()
            size += 1
            edge |= x in (xs[0], xs[-1]) or y in (ys[0], ys[-1])
            steps = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([] if val else [(1, 1), (1, -1), (-1, 1), (-1, -1)])
            for dx, dy in steps:
                q = (x + dx, y + dy)
                if q in cov and q not in seen and cov[q] == val:
                    seen.add(q)
                    stack.append(q)
        if val:
            pieces += 1
        elif not edge:
            gaps.append(size)
    return pieces, sorted(gaps)

r = 50
R, C = complexes(r * r)
size = lambda K: [len(K[k]) for k in range(len(K)) if K[k]]
bR, bC = betti(R), betti(C)
print("sites", N, "| ball radius", r, "m | edge if distance <=", 2 * r, "m")
print("edges, length m:", ", ".join(f"{a}-{b} {d2(a, b) ** 0.5:.1f}" for a, b in R[1]))
print("Rips simplices by dimension", size(R), "total", sum(size(R)), "| betti mod 2", bR[:3])
print("Cech simplices by dimension", size(C), "total", sum(size(C)), "| betti mod 2", bC[:3])
print("triangles Rips fills, Cech leaves open", [t for t in R[2] if t not in C[2]])
for t in R[2]:
    print("triangle", t, "sides m", " ".join(f"{d2(*e) ** 0.5:.1f}" for e in combinations(t, 2)), "| squared", *[d2(*e) for e in combinations(t, 2)],
          "| area m^2", f"{abs(cross(*t)) / 2:.1f}", "| circumradius", f"{float(circum2(*t)) ** 0.5:.2f}", "| enclosing radius", f"{float(meb2(t)) ** 0.5:.2f}")
gap = (0, 1, 8)
print("gap triangle: circumradius^2", circum2(*gap), "m^2, so its discs share a point only from r =", f"{float(circum2(*gap)) ** 0.5:.2f}", "m")
for rad, (Rh, Ch) in ((r, (R, C)), (85, complexes(85 * 85))):   # Helly: at 85 m some four sites are pairwise joined
    brute = {s for k in range(2, 5) for s in combinations(range(N), k) if meb2(s) <= rad * rad}
    assert brute == {s for k in (1, 2, 3) for s in Ch.get(k, [])}, "angle rule + Helly disagrees with brute force"
    print("Cech by brute-force enclosing circles on", sum(1 for k in range(2, 5) for _ in combinations(range(N), k)), "subsets at r =", rad,
          "m: same", len(brute), "simplices | sets of four: Rips", len(Rh.get(3, [])), "Cech", len(Ch.get(3, [])))
for name, K, b in (("Rips", R, bR), ("Cech", C, bC)):
    chi = sum((-1) ** k * n for k, n in enumerate(size(K)))
    assert b[0] == pieces(K[1]), "ranks disagree with union-find"
    print("Euler characteristic", name, chi, "= betti0 - betti1 + betti2")
rr2 = F(4 * r * r, 3)                        # Jung: Rips at r sits inside Cech at 2r/sqrt3
assert all(meb2(s) <= rr2 for k in (1, 2) for s in R[k])
print("every Rips simplex lies in Cech at 2r/sqrt3 =", f"{(4 * r * r / 3) ** 0.5:.2f}", "m")
print("r m | Rips sizes, betti0, betti1 | Cech sizes, betti0, betti1 | union pieces, gaps, gap sizes m^2")
for rad in (45, 50, 60, 75):
    Rx, Cx = complexes(rad * rad)
    pieces, gaps = union(rad * rad)
    bx = betti(Cx)
    assert (bx[0], bx[1]) == (pieces, len(gaps)), "nerve theorem: Cech must match the union"
    print(rad, "|", size(Rx), *betti(Rx)[:2], "|", size(Cx), *bx[:2], "|", pieces, len(gaps), gaps)
Rd, _ = complexes(r * r // 4)                # mistake: edge within r, not 2r
print("mistake, edge if distance <= r:", size(Rd), "betti", betti(Rd)[:2])
_, Cc = complexes(r * r, rule=False)         # mistake: circumradius for every triangle
print("mistake, circumradius for every triangle:", size(Cc), "betti", betti(Cc)[:2])
assert betti(Cc)[1] == bC[1] + 1 and (2, 3, 9) not in Cc[2], "the obtuse triangle should be lost"
m, (cx, cy) = (F(P[2][0] + P[3][0], 2), F(P[2][1] + P[3][1], 2)), list(centres((2, 3, 9)))[-1]
assert all((cx - a) ** 2 + (cy - b) ** 2 > circum2(2, 3, 9) for i, (a, b) in enumerate(P) if i not in (2, 3, 9))  # empty circle
print("alpha: midpoint of 2-3 is", f"{float((m[0] - 102) ** 2 + (m[1] - 315) ** 2) ** 0.5:.2f}", "m from site 9; edge 2-3 enters at r =",
      f"{float(circum2(2, 3, 9)) ** 0.5:.2f}", "m | Delaunay ceiling: edges <=", 3 * N - 6, "triangles <=", 2 * N - 5)
print("figure, sites", P, "| gap centre at", "({:.2f}, {:.2f})".format(*map(float, list(centres(gap))[-1])))
print("ALL CHECKS PASS")
