# Poincare conjecture, solved -- the check behind the card.  Standard library only.
# Nothing here proves the theorem.  It checks the card's instances: one loop on the
# 3-sphere shrinks two ways, Euler counts, the 120-element group that fools homology,
# and the toy surgery clock.  Every number on the card is printed here.
from itertools import combinations, permutations, product
from math import cos, sin, pi, sqrt

print("status ledger")
for date, event in [("1900", "Poincare's homology version (false)"), ("1904", "Poincare asks about loops"),
                    ("1960", "dimensions 5 and up, announced (Smale)"), ("1982", "dimension 4, topological (Freedman)"),
                    ("1982", "Ricci flow introduced (Hamilton)"),
                    ("1982", "geometrisation conjecture, 8 geometries (Thurston)"), ("2000", "Clay names 7 problems, $1,000,000 each"),
                    ("2002-11-11", "Perelman preprint 1 (entropy)"), ("2003-03-10", "Perelman preprint 2 (surgery)"),
                    ("2003-07-17", "Perelman preprint 3 (finite extinction)"), ("2006-05-25", "Kleiner-Lott notes, first arXiv version"),
                    ("2006-07-25", "Morgan-Tian book posted"), ("2006", "Fields Medal, declined"),
                    ("2007-08", "Morgan-Tian book published"), ("2008-11-06", "Kleiner-Lott refereed paper"),
                    ("2010-03-18", "Clay Millennium Prize awarded; money later declined")]:
    print(f"  {date:<11}{event}")
print(f"years, question to first preprint  {2002 - 1904}\nyears, question to prize           {2010 - 1904}")

# 1. The loop gamma(s) = (cos 2 pi s, sin 2 pi s, 0, 0) on the unit 3-sphere.
N, q = (0.0, 0.0, 0.0, 1.0), (0.0, 0.0, 0.0, -1.0)
def gamma(s): return (cos(2*pi*s), sin(2*pi*s), 0.0, 0.0)
def norm(v): return sqrt(sum(x*x for x in v))
def road1(s, t):   # straight line toward N, then pushed back onto the sphere
    v = tuple((1-t)*a + t*b for a, b in zip(gamma(s), N)); n = norm(v)
    return tuple(x/n for x in v), n
def road2(s, t):   # stereographic projection from q, shrink in R^3, map back
    g = gamma(s); y = [(1-t)*x/(1+g[3]) for x in g[:3]]; r2 = sum(c*c for c in y)
    return tuple([2*c/(1+r2) for c in y] + [(1-r2)/(1+r2)])
S, T = 400, 100
L = sum(norm([a-b for a, b in zip(gamma((k+1)/S), gamma(k/S))]) for k in range(S))
minmix, offsphere, end_gap = 9.0, 0.0, 0.0
for i in range(S+1):
    for j in range(T+1):
        p1, n = road1(i/S, j/T); p2 = road2(i/S, j/T); minmix = min(minmix, n)
        offsphere = max(offsphere, abs(norm(p1)-1), abs(norm(p2)-1))
    end_gap = max(end_gap, norm([a-b for a, b in zip(road1(i/S, 1)[0], N)]),
                  norm([a-b for a, b in zip(road2(i/S, 1), N)]))
print(f"loop length, 400 chords      {L:.6f}   (2 pi = {2*pi:.6f})")
print(f"loop distance to q           {norm([a-b for a, b in zip(gamma(0.3), q)]):.6f}")
print(f"road 1 smallest mix length   {minmix:.6f}   (sqrt 1/2 = {sqrt(0.5):.6f})")
print("road 1 at s=0, t=1/2         (%.6f, %.6f, %.6f, %.6f)" % road1(0, 0.5)[0])
print("road 2 at s=0, t=1/2         (%.6f, %.6f, %.6f, %.6f)" % road2(0, 0.5))
print(f"both roads stay on S^3       {offsphere < 1e-12}  (grid 401 x 101)")
print(f"both roads end at N          {end_gap < 1e-12}")
assert abs(L - 2*pi) < 1e-4, "chords must approach the circle"
assert abs(minmix - sqrt(0.5)) < 1e-12, "grid minimum must match the hand value"
assert offsphere < 1e-12, "a road left the sphere"
assert end_gap < 1e-12, "a road missed N"

# 2. Euler characteristic by counting cells, and the edge-path group.
def faces(simplex, proper):
    k = len(simplex); top = k-1 if proper else k
    return [c for d in range(1, top+1) for c in combinations(simplex, d)]
def chi(cells): return sum((-1)**(len(c)-1) for c in cells)
S1, S2, S3 = faces(range(3), True), faces(range(4), True), faces(range(5), True)
B3, S4 = faces(range(4), False), faces(range(6), True)
octa = [c for c in faces(range(6), True) if len(c) < 4 and all(a//2 != b//2 for a, b in combinations(c, 2))]   # octahedron: +-e1, +-e2, +-e3
torus = [(x, y, z, m) for x in range(3) for y in range(3) for z in range(3) for m in range(8)]
chi_t = sum((-1)**bin(c[3]).count("1") for c in torus)
chi_22 = sum((-1)**(len(a)+len(b)) for a in S2 for b in S2)
for name, v in [("circle", chi(S1)), ("2-sphere", chi(S2)), ("2-sphere, octahedron", chi(octa)), ("solid ball", chi(B3)),
                ("3-sphere", chi(S3)), ("3-torus, 3x3x3 cubes", chi_t),
                ("4-sphere", chi(S4)), ("S^2 x S^2", chi_22)]:
    print(f"chi  {name:<22}{v:>3}")
print("3-sphere cells by dimension ", [sum(len(c) == d for c in S3) for d in range(1, 5)])
assert chi(S2) == chi(octa) == 2, "two triangulations of the 2-sphere disagree"
assert (chi(B3), chi(S4), chi_22) == (1, 1 + 1, 1 + 2 + 1), "Betti sums: ball 1; S^4 1+1; S^2 x S^2 1+2+1"
assert chi_t == chi(S3) == 0, "closed 3-manifolds have chi 0"
def edge_path(cells):
    gens = {c for c in cells if len(c) == 2 and 0 not in c}; total = len(gens)
    tris = [c for c in cells if len(c) == 3]; changed = True
    while changed:
        changed = False
        for a, b, c in tris:
            alive = [e for e in [(a, b), (b, c), (a, c)] if e in gens]
            if len(alive) == 1: gens.discard(alive[0]); changed = True
    return total, len(gens)
for name, cells in [("3-sphere", S3), ("circle", S1)]: print(f"edge-path {name:<9} generators %d, left after relations %d" % edge_path(cells))
assert edge_path(S3) == (6, 0), "the 3-sphere's loops must all die"

# 3. Unit quaternions: the binary icosahedral group, 120 elements.
def mul(a, b):
    return (a[0]*b[0]-a[1]*b[1]-a[2]*b[2]-a[3]*b[3], a[0]*b[1]+a[1]*b[0]+a[2]*b[3]-a[3]*b[2],
            a[0]*b[2]-a[1]*b[3]+a[2]*b[0]+a[3]*b[1], a[0]*b[3]+a[1]*b[2]-a[2]*b[1]+a[3]*b[0])
def inv(a): return (a[0], -a[1], -a[2], -a[3])
def key(a): return tuple(int(round(x*1e6)) for x in a)
def close(gens):
    one = (1.0, 0.0, 0.0, 0.0); seen = {key(one): one}; todo = [one]
    while todo:
        x = todo.pop()
        for g in gens:
            y = mul(x, g)
            if key(y) not in seen: seen[key(y)] = y; todo.append(y)
    return seen
phi = (1 + sqrt(5))/2; signs = list(product((1, -1), repeat=4))
listed = [tuple(float(i == k)*sg for i in range(4)) for k in range(4) for sg in (1, -1)]
listed += [tuple(x/2 for x in sg) for sg in signs]
even = [p for p in permutations(range(4))
        if sum(p[i] > p[j] for i in range(4) for j in range(i+1, 4)) % 2 == 0]
base = (0.0, 1.0, 1/phi, phi)
listed += [tuple(sg[i]*base[p[i]]/2 for i in range(4)) for p in even for sg in signs]
listed = {key(x): x for x in listed}
G = close([(0.5, 0.5, 0.5, 0.5), (phi/2, 1/(2*phi), 0.5, 0.0)])
closed = all(key(mul(a, b)) in listed for a in listed.values() for b in listed.values())
print(f"2I listed {len(listed)}, generated from two {len(G)}, same set {set(G) == set(listed)}, "
      f"closed {closed}")
def order(a):
    n, x = 1, a
    while key(x) != key((1.0, 0, 0, 0)): x = mul(x, a); n += 1
    return n
hist = {}
for a in G.values(): hist[order(a)] = hist.get(order(a), 0) + 1
print("2I element orders            ", dict(sorted(hist.items())))
def comm(grp):
    els = list(grp.values())
    cs = {key(mul(mul(a, b), mul(inv(a), inv(b)))): mul(mul(a, b), mul(inv(a), inv(b)))
          for a in els for b in els}
    return close(list(cs.values()))
w = 2*pi/5
for name, grp in [("Poincare sphere, 2I", G), ("RP^3, {+1,-1}", close([(-1.0, 0, 0, 0)])),
                  ("lens L(5,1)", close([(cos(w), sin(w), 0.0, 0.0)]))]:
    c = len(comm(grp))
    print(f"{name:<20} loop classes {len(grp):>3}, commutators {c:>3}, homology sees {len(grp)//c}")
assert set(G) == set(listed), "two roads to 2I disagree"
assert closed, "the listed set is not a group"
assert len(comm(G)) == 120, "2I must be perfect"

# 4. Toy surgery clock (rates from the Ricci flow card): thin neck rho^2 falls at 2,
#    round 3-sphere R^2 falls at 4.  Neck rho = 0.5 cm, two balls R = 2 cm.
rho = 0.5; pinch, extinct = rho**2/2, 2.0**2/4
print(f"neck pinches at tau          {pinch:.6f}\nball radius then             {sqrt(4 - 4*pinch):.6f} cm")
print(f"after 1 surgery, extinct at  {extinct:.6f}")
def life(x, rate, t=0.0):          # second road: step x^2 down at this rate, in steps of 1e-6, until x is gone
    while x > 1e-3: x, t = x - rate*1e-6/(2*x), t + 1e-6
    return t
assert abs(life(rho, 2) - pinch) < 1e-4 and abs(life(sqrt(4 - 4*pinch), 4, pinch) - extinct) < 1e-4, "clock vs stepping"
print("ALL CHECKS PASS")
