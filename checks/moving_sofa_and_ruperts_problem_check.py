# Moving sofa and Rupert's problem: the check behind the card. Standard library only.
import math
from fractions import Fraction as Fr
INF, PI = float("inf"), math.pi
# Part 1. A path x(t) carries the hallway's inner corner as the hallway turns by t.
def cut(S, a, b, lo, hi):  # keep x in S with lo <= a*x + b <= hi
    if abs(a) < 1e-15:
        return S if lo <= b <= hi else []
    u, v = sorted(((lo - b) / a, (hi - b) / a))
    return [(max(p, u), min(q, v)) for p, q in S if max(p, u) < min(q, v)]
def merge(S):
    m = []
    for iv in sorted(S):
        if m and iv[0] <= m[-1][1]: m[-1] = (m[-1][0], max(m[-1][1], iv[1]))
        else: m.append(iv)
    return m
def area_from_motion(path, n):  # n hallway angles, n rows of the sofa
    pre = [(math.cos(t), math.sin(t)) + path(t) for t in (PI / 2 * k / n for k in range(n + 1))]
    total = 0.0
    for j in range(n):
        y, S = (j + 0.5) / n, [(-INF, 1.0)]
        for i, (c, s, x1, x2) in enumerate(pre):  # q1 = c*x + k1 and q2 = -s*x + k2
            k1, k2 = -c * x1 + s * (y - x2), s * x1 + c * (y - x2)
            arm_v = cut(cut(S, -s, k2, -INF, 1.0), c, k1, 0.0, 1.0)
            arm_h = [] if i == n else cut(cut(S, c, k1, -INF, 1.0), -s, k2, 0.0, 1.0)
            S = merge(arm_h + arm_v)
        total += sum(q - p for p, q in S) / n
    return total
def extrapolate(path, label):
    a1, a2 = area_from_motion(path, 800), area_from_motion(path, 1600)
    print(f"{label}: n=800 {a1:.6f}  n=1600 {a2:.6f}  extrapolated {2 * a2 - a1:.5f}")
    return 2 * a2 - a1
f = lambda r: PI / 2 + 2 * r - PI / 2 * r * r  # Hammersley's family, hole radius r
print("Part 1. Sofas in a hallway of width 1")
for name, r in [("semicircle", 0.0), ("half-size hole", 0.5), ("Hammersley 2/pi", 2 / PI), ("full-width hole", 1.0)]:
    print(f"r = {r:.6f} ({name}): area {f(r):.6f}")
best = max(range(10001), key=lambda k: f(k / 10000)) / 10000
print(f"best r by search over 10,001 steps: {best:.4f}, area {f(best):.6f}")
assert abs(best - 2 / PI) < 1e-4 and abs(f(best) - (PI / 2 + 2 / PI)) < 1e-8
semi = extrapolate(lambda t: (0.0, 0.0), "semicircle from its motion")
ham = extrapolate(lambda t: (2 / PI * (math.cos(2 * t) - 1), 2 / PI * math.sin(2 * t)), "Hammersley from its motion")
assert abs(semi - PI / 2) < 1e-4 and abs(ham - f(2 / PI)) < 1e-4
def gerver_eqs(v):  # Gerver's four equations (1992), as written by Romik (2018)
    A, B, p, t = v
    return [A * (math.cos(t) - math.cos(p)) - 2 * B * math.sin(p) + (t - p - 1) * math.cos(t) - math.sin(t) + math.cos(p) + math.sin(p),
            A * (3 * math.sin(t) + math.sin(p)) - 2 * B * math.cos(p) + 3 * (t - p - 1) * math.sin(t) + 3 * math.cos(t) - math.sin(p) + math.cos(p),
            A * math.cos(p) - (math.sin(p) + 0.5 - 0.5 * math.cos(p) + B * math.sin(p)),
            (A + PI / 2 - p - t) - (B - 0.5 * (t - p) * (1 + A) - 0.25 * (t - p) ** 2)]
v = [0.1, 1.4, 0.04, 0.7]
for _ in range(30):  # Newton's method with a finite-difference Jacobian
    F0 = gerver_eqs(v)
    J = [[(gerver_eqs([v[k] + (1e-7 if k == j else 0) for k in range(4)])[i] - F0[i]) / 1e-7 for j in range(4)] + [-F0[i]] for i in range(4)]
    for c in range(4):  # Gaussian elimination with partial pivoting
        p = max(range(c, 4), key=lambda r: abs(J[r][c])); J[c], J[p] = J[p], J[c]
        for r in range(c + 1, 4):
            m = J[r][c] / J[c][c]; J[r] = [J[r][k] - m * J[c][k] for k in range(5)]
    d = [0.0] * 4
    for c in range(3, -1, -1): d[c] = (J[c][4] - sum(J[c][k] * d[k] for k in range(c + 1, 4))) / J[c][c]
    v = [v[k] + d[k] for k in range(4)]
A, B, phi, th = v
print(f"Gerver's equations by Newton: A {A:.10f}  B {B:.10f}  phi {phi:.10f}  theta {th:.10f}")
assert abs(phi - 0.039177364790083641) < 1e-12 and abs(th - 0.681301509382724894) < 1e-12  # Romik's table
a1, kap = 1.210322422072688751, [(-0.210322422072688751, 0.25), (-0.919179292771593322, 0.472406619750805465),
    (-0.613763229430251668, 0.889626479003221860), (-0.308347166088910014, 0.472406619750805465), (-1.017204036787814585, 0.25)]
b1, b2, c1, c2, d1, d2 = -0.527624598026784624, 0.920258385160637622, 0.626045522848465867, -0.944750803946430751, 1.313022761424232933, -0.525382670414554437
def turn(t, u, w, k): return (math.cos(t) * u - math.sin(t) * w + k[0], math.sin(t) * u + math.cos(t) * w + k[1])
phases = [lambda t: turn(t, a1 * math.cos(t) - 0.25 * math.sin(t) - 1, 0.25 * math.cos(t) + a1 * math.sin(t) - 0.5, kap[0]),
          lambda t: turn(t, -t * t / 4 + b1 * t + b2, t / 2 - b1 - 1, kap[1]),
          lambda t: turn(t, c1 - t, c2 + t, kap[2]),
          lambda t: turn(t, -t / 2 + d1 - 1, -t * t / 4 + d1 * t + d2, kap[3]),
          lambda t: turn(t, a1 * math.cos(t) + 0.25 * math.sin(t) - 0.5, -0.25 * math.cos(t) + a1 * math.sin(t) - 1, kap[4])]
cuts = [phi, th, PI / 2 - th, PI / 2 - phi]
gap = max(math.dist(phases[i](cuts[i]), phases[i + 1](cuts[i])) for i in range(4))
assert gap < 1e-12 and math.dist(phases[0](0.0), (0, 0)) < 1e-12  # the five pieces join up
gerver = extrapolate(lambda t: phases[sum(t >= c for c in cuts)](t), "Gerver from its motion")
print(f"Gerver published 2.21953166; gain over Hammersley {gerver - ham:.4f}; upper bound 2 sqrt 2 = {2 * math.sqrt(2):.6f}")
assert abs(gerver - 2.21953166) < 1e-4 and gerver > ham + 0.01
# Part 2. The cube's shadow along u has edge normals u x e_i; test the square on each.
def cross(u, e): return (u[1] * e[2] - u[2] * e[1], u[2] * e[0] - u[0] * e[2], u[0] * e[1] - u[1] * e[0])
dot = lambda p, q: sum(x * y for x, y in zip(p, q))
E = [(1, 0, 0), (0, 1, 0), (0, 0, 1)]
P = [(Fr(3, 4), 0, 0), (0, Fr(3, 4), 0), (Fr(1, 4), 1, 1), (1, Fr(1, 4), 1)]  # Nieuwland's square
sides = [tuple(P[(i + 1) % 4][k] - P[i][k] for k in range(3)) for i in range(4)]
assert all(sum(c in (0, 1) for c in p) == 2 for p in P) and all(dot(s, s) == Fr(9, 8) for s in sides) and all(dot(sides[i], sides[(i + 1) % 4]) == 0 for i in range(4))
U, Av, Bv = (2, 2, -1), (-1, 1, 0), (1, 1, 4)  # normal, and the square's two directions (lengths sqrt2, 3 sqrt2)
ratios = [Fr(sum(abs(x) for x in cross(U, e)), 3 * abs(dot(cross(U, e), Av)) + abs(dot(cross(U, e), Bv))) for e in E]
s2 = 18 * min(ratios) ** 2
print("Part 2. A cube through a cube")
print(f"Nieuwland's square: corners on cube edges, sides^2 = 9/8, right angles; edge ratios {[str(r) for r in ratios]}; s^2 = {s2}")
def face_on(u, al):  # largest square side, square turned by al in the shadow plane
    n = math.sqrt(dot(u, u)); u = [x / n for x in u]
    a0 = cross(u, (0, 0, 1) if abs(u[2]) < 0.9 else (1, 0, 0)); n = math.sqrt(dot(a0, a0)); a0 = [x / n for x in a0]; b0 = cross(u, a0)
    a = [math.cos(al) * p + math.sin(al) * q for p, q in zip(a0, b0)]; b = [-math.sin(al) * p + math.cos(al) * q for p, q in zip(a0, b0)]
    return min(sum(map(abs, w)) / (abs(dot(w, a)) + abs(dot(w, b))) for w in (cross(u, e) for e in E))
diag = max(face_on((1, 1, 1), PI / 2 * k / 20000) for k in range(20000))
print(f"along the main diagonal: best side {diag:.6f}; sqrt 6 - sqrt 2 = {math.sqrt(6) - math.sqrt(2):.6f}")
assert abs(diag - (math.sqrt(6) - math.sqrt(2))) < 1e-6
sph = lambda th, ph: (math.cos(th) * math.sin(ph), math.sin(th) * math.sin(ph), math.cos(ph))
g = [(face_on(sph(PI / 2 * i / 24, PI * j / 24), PI / 2 * k / 24), PI / 2 * i / 24, PI * j / 24, PI / 2 * k / 24) for i in range(25) for j in range(1, 24) for k in range(24)]
s, th1, ph1, al1 = max(g); step = PI / 48
while step > 1e-9:  # pattern search from the best grid point
    moves = [(th1 + step, ph1, al1), (th1 - step, ph1, al1), (th1, ph1 + step, al1), (th1, ph1 - step, al1), (th1, ph1, al1 + step), (th1, ph1, al1 - step)]
    cand = max((face_on(sph(p, q), r), p, q, r) for p, q, r in moves)
    if cand[0] > s: s, th1, ph1, al1 = cand
    else: step /= 2
print(f"search over all directions and turns: best side {s:.6f}; exact 3 sqrt 2 / 4 = {3 * math.sqrt(2) / 4:.6f}")
assert s2 == Fr(9, 8) and abs(s - math.sqrt(float(s2))) < 1e-6
# Random search (Steininger and Yurkevich 2023): is one turned shadow strictly inside another?
class SplitMix64:
    def __init__(self, seed): self.x = seed
    def unit(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) % 2**64; z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
        return ((z ^ (z >> 31)) >> 11) / 2**53
def shadow(V, th, ph):  # the projection M(theta, phi) of the 2025 paper, then the convex hull
    pts = sorted({(-math.sin(th) * x + math.cos(th) * y, -math.cos(th) * math.cos(ph) * x - math.sin(th) * math.cos(ph) * y + math.sin(ph) * z) for x, y, z in V})
    def half(seq):  # Andrew's monotone chain: keep only left turns
        h = []
        for p in seq:
            while len(h) >= 2 and (h[-1][0] - h[-2][0]) * (p[1] - h[-2][1]) - (h[-1][1] - h[-2][1]) * (p[0] - h[-2][0]) <= 0: h.pop()
            h.append(p)
        return h[:-1]
    return half(pts) + half(pts[::-1])
def passes(V, rng):
    t1, p1, t2, p2, al = (rng.unit() * m for m in (2 * PI, PI, 2 * PI, PI, 2 * PI))
    inner = [(math.cos(al) * x - math.sin(al) * y, math.sin(al) * x + math.cos(al) * y) for x, y in shadow(V, t1, p1)]
    H = shadow(V, t2, p2)
    return all((b[0] - a[0]) * (q[1] - a[1]) - (b[1] - a[1]) * (q[0] - a[0]) > 1e-12 for a, b in zip(H, H[1:] + H[:1]) for q in inner)
cube = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
C = [tuple(v / 259375205 for v in (152024884, 0, 210152163)), (0.6632738028, 0.6106948881, 0.3980949609), (0.8193990033, 0.5298215096, 0.1230614493)]
nop = [(sg * (math.cos(2 * PI * k / 15) * x - math.sin(2 * PI * k / 15) * y), sg * (math.sin(2 * PI * k / 15) * x + math.cos(2 * PI * k / 15) * y), sg * z) for x, y, z in C for k in range(15) for sg in (1, -1)]
assert sum(round(v * 259375205) ** 2 for v in C[0]) == 259375205 ** 2 and all(0.98 < math.dist(c, (0, 0, 0)) < 0.99 for c in C[1:])
assert len({tuple(round(c, 9) for c in p) for p in nop}) == 90
print(f"Noperthedron: 90 distinct vertices; |C1| = 1 exactly; |C2| {math.dist(C[1], (0, 0, 0)):.6f}  |C3| {math.dist(C[2], (0, 0, 0)):.6f}")
for name, V in [("cube", cube), ("Noperthedron", nop)]:
    rng = SplitMix64(2025); hits = [i for i in range(1, 20001) if passes(V, rng)]
    print(f"random tries, {name}: {len(hits)} passages in 20,000; first at try {hits[0] if hits else 'none'}")
    assert (len(hits) > 0) == (name == "cube")
print(f"figure, hole radius {2 / PI:.4f}, outer width {2 + 4 / PI:.4f}, quarter-disc centres x = -{2 / PI:.4f} and {2 / PI:.4f}")
print("ALL CHECKS PASS")
