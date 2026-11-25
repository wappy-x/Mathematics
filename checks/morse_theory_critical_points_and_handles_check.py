# Morse theory -- the check behind the card.  Standard library only.
# A swim ring stood on edge: tube-centre circle a = 20 cm, tube radius b = 10 cm, height
# h(u, v) = 30 + (a + b cos v) cos u in cm.  Newton's method finds the critical points; each is
# classified three ways (Hessian signs, lower arcs on a small circle, a second chart).  The counts
# meet Betti numbers from exact ranks, sublevel Euler counts and a mesh count of pits and passes.
from fractions import Fraction
from math import cos, sin, pi, hypot, radians, degrees
A, B, D, TAU = 20.0, 10.0, 1e-4, 2 * pi
def ring(u, v): return 30 + (A + B * cos(v)) * cos(u)
def planet(e):                              # toy planet terrain in metres, chart: polar angle, longitude
    def f(p, t):
        x, y = sin(p) * cos(t), sin(p) * sin(t)
        return 1000 * (x**3 - 3 * x * y * y + e * x)
    return f
def grad(f, u, v): return ((f(u + D, v) - f(u - D, v)) / (2 * D), (f(u, v + D) - f(u, v - D)) / (2 * D))
def hess(f, u, v):
    e, c = 1e-3, f(u, v)
    huv = (f(u + e, v + e) - f(u + e, v - e) - f(u - e, v + e) + f(u - e, v - e)) / (4 * e * e)
    return (f(u + e, v) - 2 * c + f(u - e, v)) / e**2, huv, (f(u, v + e) - 2 * c + f(u, v - e)) / e**2
def index(H):                               # negative eigenvalues of [[H0, H1], [H1, H2]]
    det = H[0] * H[2] - H[1] ** 2
    return None if abs(det) < 1e-3 else 1 if det < 0 else 0 if H[0] + H[2] > 0 else 2
def arcs(f, u, v, r=0.02):                  # separate stretches of a small circle lying below the point
    s = [f(u + r * cos(TAU * k / 72), v + r * sin(TAU * k / 72)) < f(u, v) for k in range(72)]
    return "all" if all(s) else sum(s[k] and not s[k - 1] for k in range(72))
def chart2(f, u, v):                        # the same function read in a bent second chart
    return lambda s, t: f(u + s + 0.4 * t + 0.3 * s * s, v + t - 0.5 * s * t)
def critical(f, starts, ok):
    found = []
    for u, v in starts:
        for _ in range(40):
            (gu, gv), (a, b, c) = grad(f, u, v), hess(f, u, v)
            if abs(a * c - b * b) < 1e-12: break
            u, v = u - (c * gu - b * gv) / (a * c - b * b), v - (a * gv - b * gu) / (a * c - b * b)
        k = (cos(u), sin(u), cos(v), sin(v))
        if hypot(*grad(f, u, v)) < 1e-6 and ok(u, v) and all(max(abs(x - y) for x, y in zip(k, q)) > 1e-5 for q, _ in found):
            found.append((k, (u % TAU, v % TAU)))
    return sorted((p for _, p in found), key=lambda p: f(*p))
def fx(x, d=2): return f"{x if abs(x) >= 0.5 * 10**-d else 0.0:.{d}f}"
def mesh(n, m, sphere):                     # triangles of an n-by-m grid, glued into a torus or a sphere
    def vid(i, j):
        if not sphere: return (i % n) * m + j % m
        return 0 if i == 0 else 1 + (n - 1) * m if i == n else 1 + (i - 1) * m + j % m
    tris = [t for i in range(n) for j in range(m) for t in ((vid(i, j), vid(i + 1, j), vid(i, j + 1)),
            (vid(i + 1, j), vid(i + 1, j + 1), vid(i, j + 1))) if len(set(t)) == 3]
    pos = {vid(i, j): ((pi if sphere else TAU) * i / n, TAU * j / m) for i in range(n + 1) for j in range(m)}
    return tris, pos
def rank(M):                                # exact Gaussian elimination in fractions
    M, r = [[Fraction(x) for x in row] for row in M], 0
    for c in range(len(M[0])):
        p = next((i for i in range(r, len(M)) if M[i][c]), None)
        if p is None: continue
        M[r], M[p] = M[p], M[r]
        for i in range(len(M)):
            if i != r and M[i][c]:
                k = M[i][c] / M[r][c]
                M[i] = [x - k * y for x, y in zip(M[i], M[r])]
        r += 1
    return r
def betti(tris):
    V = sorted({v for t in tris for v in t})
    E = sorted({tuple(sorted(e)) for p, q, r in tris for e in ((p, q), (q, r), (p, r))})
    d1 = [[(v == b) - (v == a) for a, b in E] for v in V]
    T = [tuple(sorted(t)) for t in tris]
    d2 = [[(e == (q, r)) - (e == (p, r)) + (e == (p, q)) for p, q, r in T] for e in E]
    r1, r2 = rank(d1), rank(d2)
    return [len(V) - r1, len(E) - r1 - r2, len(T) - r2], (len(V), len(E), len(T))
def euler_below(tris, val, c):              # V - E + T of the part of the mesh at or below level c
    T = [t for t in tris if max(val[v] for v in t) <= c]
    E = {tuple(sorted(e)) for p, q, r in T for e in ((p, q), (q, r), (p, r))}
    return len({v for t in T for v in t}) - len(E) + len(T)
def mesh_count(tris, val):                  # pits, passes, peaks from sign changes round each vertex
    nxt, kinds = {}, [0, 0, 0]
    for p, q, r in tris:
        for v, x, y in ((p, q, r), (q, r, p), (r, p, q)): nxt.setdefault(v, {})[x] = y
    for v, link in nxt.items():
        cyc = [next(iter(link))]
        while link[cyc[-1]] != cyc[0]: cyc.append(link[cyc[-1]])
        s = [val[w] > val[v] for w in cyc]
        sc = sum(s[k] != s[k - 1] for k in range(len(s)))
        if sc == 0: kinds[0 if s[0] else 2] += 1
        else: kinds[1] += sc // 2 - 1
    return kinds
grid = [(TAU * i / 7 + 0.1, TAU * j / 7 + 0.2) for i in range(7) for j in range(7)]
crit = critical(ring, grid, lambda u, v: True)
counts = [0, 0, 0]
print("swim ring stood on edge: a = 20 cm, b = 10 cm; critical points, lowest first")
for u, v in crit:
    H, K = hess(ring, u, v), hess(chart2(ring, u, v), 0, 0)
    counts[index(H)] += 1
    print(f"u {round(degrees(u)) % 360} deg, v {round(degrees(v)) % 360} deg, height {fx(ring(u, v))} cm; Hessian {fx(H[0])}, "
          f"{fx(H[1])}, {fx(H[2])}; index {index(H)}; lower arcs {arcs(ring, u, v)}; chart 2: {fx(K[0])}, {fx(K[1])}, "
          f"{fx(K[2])}, index {index(K)}")
b_t, vet = betti(mesh(3, 3, False)[0])
print(f"counts by index c = {counts}; Betti numbers b = {b_t} by exact ranks on {vet[0]}-{vet[1]}-{vet[2]} triangles")
print(f"weak: c_k >= b_k {'yes' if all(c >= b for c, b in zip(counts, b_t)) else 'no'}; strong: c1 - c0 = {counts[1] - counts[0]} "
      f">= b1 - b0 = {b_t[1] - b_t[0]}; c0 - c1 + c2 = {counts[0] - counts[1] + counts[2]} = chi = {vet[0] - vet[1] + vet[2]}")
tris, pos = mesh(60, 60, False)
val = {k: ring(*p) for k, p in pos.items()}
chis, mr = [euler_below(tris, val, c) for c in (10, 30, 50, 70)], mesh_count(tris, val)
print(f"sublevel Euler counts below 10, 30, 50, 70 cm on a 60 x 60 mesh: {chis}; mesh pits, passes, peaks {mr}")
terrain = planet(0.3)
peaks = critical(terrain, [(radians(10 + 20 * i), radians(30 * j)) for i in range(9) for j in range(12)],
                 lambda p, t: 0.02 < p < pi - 0.02)
kinds = [index(hess(terrain, *p)) for p in peaks]
pl = [kinds.count(k) for k in (0, 1, 2)]
print(f"toy planet: {pl[0]} pits, {pl[1]} passes, {pl[2]} peaks; {pl[0]} - {pl[1]} + {pl[2]} = {pl[0] - pl[1] + pl[2]}")
print("heights (m): " + ", ".join(fx(terrain(*p), 0) for p in peaks))
for p in peaks[:1] + [p for p in peaks if index(hess(terrain, *p)) == 1][:1]:
    print(f"  polar angle {degrees(p[0]):.2f} deg, longitude {degrees(p[1]):.2f} deg, index {index(hess(terrain, *p))}")
tris_s, pos_s = mesh(48, 96, True)
mc = mesh_count(tris_s, {k: terrain(*p) for k, p in pos_s.items()})
b_s, ve_s = betti(mesh(3, 4, True)[0])
print(f"planet 48 x 96 mesh count {mc}, alternating sum {mc[0] - mc[1] + mc[2]}; sphere Betti {b_s} by exact ranks, chi {ve_s[0] - ve_s[1] + ve_s[2]}")
flat = lambda u, v: 10 + B * sin(v)
print(f"break 1, ring lying flat: Hessian at v = 90 deg {', '.join(fx(x) for x in hess(flat, 0.0, pi / 2))}, "
      f"largest slope on that circle {max(hypot(*grad(flat, TAU * k / 36, pi / 2)) for k in range(36)):.6f}")
tilt = lambda u, v: 30 + (B * sin(v)) * cos(radians(5)) + (A + B * cos(v)) * cos(u) * sin(radians(5))
ct = critical(tilt, grid, lambda u, v: True)
print(f"break 2, ring tilted 5 deg from flat: {len(ct)} critical points, indices {[index(hess(tilt, *p)) for p in ct]}")
monkey = lambda x, y: x**3 - 3 * x * y * y
pm = critical(planet(0.0), [(radians(10 + 20 * i), radians(30 * j)) for i in range(9) for j in range(12)],
              lambda p, t: 0.02 < p < pi - 0.02)
km = [index(hess(planet(0.0), *p)) for p in pm]
print(f"break 3, planet with no nudge: Newton finds {km.count(0)} pits, {km.count(1)} passes, {km.count(2)} peaks, "
      f"sum {km.count(0) - km.count(1) + km.count(2)}; at each pole Hessian {', '.join(fx(x) for x in hess(monkey, 0.0, 0.0))}, "
      f"lower arcs {arcs(monkey, 0.0, 0.0)}")
print(f"break 4, counting without signs: ring {len(crit)} points against chi 0; planet {len(peaks)} against chi 2")
print("figure, 5 px per cm, floor y 340, centre (210, 190), outer r 150, hole r 50, critical points at y "
      + ", ".join(f"{340 - 5 * ring(*p):.0f}" for p in crit))
assert [index(hess(ring, *p)) for p in crit] == [index(hess(chart2(ring, *p), 0, 0)) for p in crit] == [0, 1, 1, 2]
assert [arcs(ring, *p) for p in crit] == [0, 2, 2, "all"]       # second road to the index
assert all(abs(ring(*p) - h) < 1e-6 for p, h in zip(crit, (30 - A - B, 30 - A + B, 30 + A - B, 30 + A + B)))  # 30 -/+ (a -/+ b)
assert counts == b_t == mr == [1, 2, 1] and chis == [1, 0, -1, 0]  # Morse counts against exact ranks, sublevels, mesh
assert pl == mc == [3, 4, 3] and ve_s[0] - ve_s[1] + ve_s[2] == pl[0] - pl[1] + pl[2] and b_s == [1, 0, 1]
assert index(hess(flat, 0.0, pi / 2)) is None and len(ct) == 4 and arcs(monkey, 0.0, 0.0) == 3
print("ALL CHECKS PASS")
