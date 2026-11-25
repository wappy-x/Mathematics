# Bochner's theorem -- the check behind the card.  Standard library only.
# The Bochner formula is checked at London in two charts of the globe, then integrated
# over the whole globe and over a band, and Betti numbers are counted by exact rank.
from math import sin, cos, tan, atan, sqrt, pi, radians, log

R = 6371.0                       # globe radius, km
A, B = 6378.137, 6356.7523142    # WGS 84 equatorial and polar radii, km

sphere = lambda r: lambda p: [[r * r, 0.0], [0.0, (r * sin(p[0])) ** 2]]      # polar angle phi, longitude theta
def graph(p):     # x, y in km on the equator plane, northern half
    w = R * R - p[0] ** 2 - p[1] ** 2
    return [[1 + p[0] ** 2 / w, p[0] * p[1] / w], [p[0] * p[1] / w, 1 + p[1] ** 2 / w]]
flat = lambda p: [[1.0, 0.0], [0.0, 1.0]]                                          # wrap-around map, km
wgs = lambda p: [[(A * sin(p[0])) ** 2 + (B * cos(p[0])) ** 2, 0.0], [0.0, (A * cos(p[0])) ** 2]]  # parametric latitude

det = lambda g: g[0][0] * g[1][1] - g[0][1] * g[1][0]
inv = lambda g: [[g[1][1] / det(g), -g[0][1] / det(g)], [-g[1][0] / det(g), g[0][0] / det(g)]]
def dif(f, p, i, h):             # central difference of f in coordinate i
    a, b = list(p), list(p); a[i] += h; b[i] -= h
    return (f(a) - f(b)) / (2 * h)
def gam(ch, p, h):               # Christoffel symbols G[l][j][k] from the metric alone
    gi = inv(ch(p)); dg = [[[dif(lambda q: ch(q)[a][b], p, m, h) for b in range(2)] for a in range(2)] for m in range(2)]
    return [[[0.5 * sum(gi[l][m] * (dg[j][m][k] + dg[k][m][j] - dg[m][j][k]) for m in range(2))
              for k in range(2)] for j in range(2)] for l in range(2)]
def ric(ch, p, h):               # Ric_jk = Rm^i_jik, curvature from the Christoffel symbols
    G = gam(ch, p, h)
    dG = [[[[dif(lambda q: gam(ch, q, h)[l][j][k], p, i, h) for k in range(2)] for j in range(2)] for l in range(2)]
          for i in range(2)]
    def Rm(l, k, i, j):
        return dG[i][l][j][k] - dG[j][l][i][k] + sum(G[l][i][m] * G[m][j][k] - G[l][j][m] * G[m][i][k] for m in range(2))
    return [[sum(Rm(i, j, i, k) for i in range(2)) for k in range(2)] for j in range(2)]
def nab(ch, w, p, h):            # covariant derivative (nabla_i w)_j = d_i w_j - G^k_ij w_k
    G, wp = gam(ch, p, h), w(p)
    return [[dif(lambda q: w(q)[j], p, i, h) - sum(G[k][i][j] * wp[k] for k in range(2)) for j in range(2)] for i in range(2)]
def div(ch, w, p, h):            # divergence of the wind w-sharp: (1/sqrt det g) d_i (sqrt det g g^ij w_j)
    flux = lambda q, i: sqrt(det(ch(q))) * sum(inv(ch(q))[i][j] * w(q)[j] for j in range(2))
    return sum(dif(lambda q: flux(q, i), p, i, h) for i in range(2)) / sqrt(det(ch(p)))
def lap(ch, f, p, h):            # Laplace-Beltrami = divergence of the gradient
    return div(ch, lambda q: [dif(f, q, 0, h), dif(f, q, 1, h)], p, h)
def sq1(ch, w, p):               # |w|^2 = g^ij w_i w_j
    gi, v = inv(ch(p)), w(p); return sum(gi[i][j] * v[i] * v[j] for i in range(2) for j in range(2))
def bochner(ch, w, p, h):        # |w|^2, |nabla w|^2, Ric(w, w), (1/2) Laplacian |w|^2, curl, divergence
    gi, N, Rc, v = inv(ch(p)), nab(ch, w, p, h), ric(ch, p, h), w(p)
    n2 = sum(gi[i][a] * gi[j][b] * N[i][j] * N[a][b] for i in range(2) for j in range(2) for a in range(2) for b in range(2))
    rw = sum(gi[j][a] * gi[k][b] * Rc[j][k] * v[a] * v[b] for j in range(2) for k in range(2) for a in range(2) for b in range(2))
    return sq1(ch, w, p), n2, rw, 0.5 * lap(ch, lambda q: sq1(ch, w, q), p, h), N[0][1] - N[1][0], div(ch, w, p, h)
def show(label, *vs):              # tiny rounding noise prints as 0
    print(f"{label:<46}" + "".join(f"{(v if abs(v) >= 5e-7 else 0.0):>12.6f}" for v in vs))

# ---- road 1: the Bochner formula at London for the harmonic wind d(theta), two charts ----
ph, th = radians(90 - 51.5074), radians(-0.1278)
sA = bochner(sphere(R), lambda p: [0.0, 1.0], [ph, th], 1e-4)
sB = bochner(graph, lambda p: [-p[1] / (p[0] ** 2 + p[1] ** 2), p[0] / (p[0] ** 2 + p[1] ** 2)],
             [R * sin(ph) * cos(th), R * sin(ph) * sin(th)], 1.0)
s, c = sin(ph), cos(ph); exact = [1 / s ** 2, 2 * c * c / s ** 4, 1 / s ** 2, 1 / s ** 2 + 2 * c * c / s ** 4]
show("London: polar angle (deg), R sin(phi) (km)", 90 - 51.5074, R * s)
for k, lab in enumerate(["R^2 |w|^2", "R^4 |nabla w|^2", "R^4 Ric(w, w)", "R^4 half Laplacian |w|^2"]):
    show(lab + ": sphere, graph, exact", sA[k] * R ** (2 if k == 0 else 4), sB[k] * R ** (2 if k == 0 else 4), exact[k])
show("R^4 (|nabla w|^2 + Ric): sphere, graph", (sA[1] + sA[2]) * R ** 4, (sB[1] + sB[2]) * R ** 4)
show("R^2 curl, R^2 divergence: graph chart", sB[4] * R * R, sB[5] * R * R)
hd = nab(sphere(R), lambda q: [-R * sin(q[0]), 0.0], [ph, th], 1e-4)[1][1] / R   # w = df, f = height: sign-sensitive entry
show("London, w = df: nabla_theta w_theta / R, exact", hd, -s * s * c)

# ---- road 2: the whole globe, closed form w = d(height), height = r cos(phi) ----
def globe(r, N):                 # midpoint rule in phi; nothing depends on theta
    tot = [0.0, 0.0, 0.0]
    for i in range(N):
        p = [pi * (i + 0.5) / N, 0.3]; wt = 2 * pi * r * r * sin(p[0]) * pi / N
        b = bochner(sphere(r), lambda q: [-r * sin(q[0]), 0.0], p, 1e-4)
        tot = [tot[0] + wt * lap(sphere(r), lambda q: r * cos(q[0]), p, 1e-4) ** 2, tot[1] + wt * b[1], tot[2] + wt * b[2]]
    return tot
G, G2 = globe(R, 1200), globe(R, 600)
show("globe: int (delta w)^2, |nabla w|^2, Ric", *G)
show("  same with half the steps", *G2)
show("  closed forms 16 pi/3, 8 pi/3, 8 pi/3", 16 * pi / 3, 8 * pi / 3, 8 * pi / 3)
show("  Moon, r = 1737.4 km", *globe(1737.4, 1200))

# ---- road 3: globe minus its poles, the band between two polar circles, w = d(theta) ----
def band(deg, N=1200):           # R^2 times the integrals of each side, and the edge flux in closed form
    a, tot = radians(deg), [0.0, 0.0, 0.0]
    for i in range(N):
        p = [a + (pi - 2 * a) * (i + 0.5) / N, 0.3]; wt = 2 * pi * R * R * sin(p[0]) * (pi - 2 * a) / N
        b = bochner(sphere(R), lambda q: [0.0, 1.0], p, 1e-4)
        tot = [tot[0] + wt * b[3], tot[1] + wt * b[1], tot[2] + wt * b[2]]
    f, rc = 4 * pi * cos(a) / sin(a) ** 2, 4 * pi * log(1 / tan(a / 2))   # edge flux; int Ric = 4 pi ln cot(a/2)
    return [t * R * R for t in tot] + [f, f - rc, rc]        # int |nabla w|^2 = 4 pi (cos a / sin^2 a - ln cot(a/2))
bands = [band(23.44), band(10.0)]
for deg, bd in zip((23.44, 10.0), bands): show(f"band from {deg:5.2f} deg: lhs, nabla, Ric, flux", *bd[:4]); show("  closed forms of nabla, Ric", *bd[4:])

# ---- WGS 84: Gaussian curvature K = Ric_22 / g_22 at every whole degree of latitude ----
def Kc(b):                       # closed form: (1 - e^2 sin^2 lat)^2 / (A^2 (1 - e^2)), lat = geodetic latitude
    e2 = 1 - B * B / (A * A); s2 = sin(atan(A / B * tan(b))) ** 2; return (1 - e2 * s2) ** 2 / (A * A * (1 - e2))
Ks = [ric(wgs, [radians(d), 0.0], 1e-4)[1][1] / wgs([radians(d), 0.0])[1][1] for d in range(-89, 90)]
show("WGS 84 K x 1e8 (1/km^2): min, max", min(Ks) * 1e8, max(Ks) * 1e8)
show("  closed form at 89 deg, equator, pole", Kc(radians(89)) * 1e8, Kc(0.0) * 1e8, B * B / A ** 4 * 1e8)
show("flat 40000 x 20000 km map, w = dx: three", *bochner(flat, lambda p: [1.0, 0.0], [40000.0 * 0.3, 20000.0 * 0.7], 1.0)[:3])

# ---- road 4: Betti number b1 counted by exact rank on triangulated surfaces ----
def rank(M):                     # fraction-free (Bareiss) elimination: whole numbers, exact
    M, r, prev = [row[:] for row in M], 0, 1
    for c in range(len(M[0])):
        p = next((i for i in range(r, len(M)) if M[i][c] != 0), None)
        if p is None: continue
        M[r], M[p] = M[p], M[r]
        for i in range(r + 1, len(M)):
            for j in range(c + 1, len(M[0])):
                num = M[r][c] * M[i][j] - M[i][c] * M[r][j]; assert num % prev == 0; M[i][j] = num // prev
            M[i][c] = 0
        prev, r = M[r][c], r + 1
    return r
def grid(n, m, wrap):            # n by m squares, each cut into two triangles; wrap north-south or not
    rows = m if wrap else m + 1; v = lambda i, j: i % n + n * (j % rows)
    return [t for i in range(n) for j in range(m) for t in ([v(i, j), v(i + 1, j), v(i + 1, j + 1)], [v(i, j), v(i + 1, j + 1), v(i, j + 1)])]
def betti(tri, n):               # V, E, F, b1 = E - rank d0 - rank d1, nullity of the edge Laplacian, L1 times the east cochain
    V = 1 + max(max(t) for t in tri); E = sorted({tuple(sorted((t[a], t[b]))) for t in tri for a, b in ((0, 1), (1, 2), (0, 2))})
    d0 = [[(k == b) - (k == a) for k in range(V)] for a, b in E]
    d1 = [[sum(sg * (e == tuple(sorted(pr))) * (1 if pr[0] < pr[1] else -1) for pr, sg in (((t[0], t[1]), 1), ((t[1], t[2]), 1), ((t[0], t[2]), -1)))
           for e in E] for t in tri]
    L1 = [[sum(d0[i][k] * d0[j][k] for k in range(V)) + sum(d1[t][i] * d1[t][j] for t in range(len(tri))) for j in range(len(E))] for i in range(len(E))]
    east = [((b % n) - (a % n) + 1) % n - 1 for a, b in E]               # x-step of each edge on an n-wide grid
    return V, len(E), len(tri), len(E) - rank(d0) - rank(d1), len(E) - rank(L1), [sum(L1[i][j] * east[j] for j in range(len(E))) for i in range(len(E))]
octa = [[0, i, i % 4 + 1] for i in range(1, 5)] + [[5, i % 4 + 1, i] for i in range(1, 5)]
o, t3, cy = betti(octa, 3), betti(grid(3, 3, True), 3), betti(grid(3, 1, False), 3)
for name, x in (("octahedron", o), ("3x3 torus", t3), ("3x1 band", cy)):
    print(f"{name} V E F {x[0]} {x[1]} {x[2]}: b1 by ranks {x[3]}, harmonic 1-cochains {x[4]}")
print(f"east cochain on the torus has L1 x = 0: {'yes' if not any(t3[5]) else 'no'}")

# ---- the wind that circles the pole with no swirl and no source: 10 m/s at the equator ----
print("wind m/s at latitude " + " ".join(f"{L}:{10 * R / (R * sin(radians(90 - L))):.1f}" for L in (0, 10, 20, 30, 40, 50, 60, 70, 80, 85, 88)))

assert all(abs(sA[k] * R ** (2 if k == 0 else 4) - exact[k]) < 1e-5 for k in range(4)) and abs(hd + s * s * c) < 1e-6, "sphere chart against exact"
assert all(abs((sB[k] - sA[k]) / sA[k]) < 1e-6 for k in range(4)), "two charts agree"
assert abs(sB[3] - sB[1] - sB[2]) < 1e-6 * sB[3], "Bochner formula pointwise"
assert abs(G[0] - 16 * pi / 3) < 1e-4 > abs(G[1] - 8 * pi / 3), "globe integrals against 16 pi / 3 and 8 pi / 3"
assert abs(G[0] - G[1] - G[2]) < 1e-4, "integrated Weitzenbock identity"
assert abs(G2[0] - G[0]) > 2 * abs(G[0] - 16 * pi / 3), "halving the steps cuts the error about fourfold"
assert all(abs(bd[0] - bd[3]) < 1e-4 * bd[3] and abs(bd[0] - bd[1] - bd[2]) < 1e-4 * bd[3] and abs(bd[1] - bd[4]) < 1e-4 * bd[3] and abs(bd[2] - bd[5]) < 1e-4 * bd[3] for bd in bands), "band: lhs is the edge flux; each side against its closed form"
assert all(abs(k - Kc(radians(d))) < 1e-6 * k for k, d in zip(Ks, range(-89, 90))) and min(Ks) > B * B / A ** 4, "WGS 84 K, closed form, positive"
assert (o[3], o[4], t3[3], t3[4], cy[3], cy[4], any(t3[5])) == (0, 0, 2, 2, 1, 1, False), "b1 by two counts; east is harmonic"
print("ALL CHECKS PASS")
