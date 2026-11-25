# Gauss, Codazzi and Ricci equations: the check behind the card. Standard library only.
# Curvature of a submanifold = ambient curvature + bending from the second fundamental form II.
# Roads: II from an embedding by finite differences, the metric alone, closed forms, two splits.
import math
from functools import reduce

def sci(x, d=4):                 # scientific text, the same as Rust's {:.4e}
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def fx(x, d):                    # fixed text with no negative zero
    s = f"{x:.{d}f}"
    return s[1:] if s.startswith("-") and float(s) == 0 else s
dot = lambda a, b: reduce(lambda t, pq: t + pq[0] * pq[1], zip(a, b), 0.0)   # plain left-to-right sum

def solve(A, b):                 # Gaussian elimination for a small square system
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for i in range(n):
        for k in range(i + 1, n):
            M[k] = [M[k][j] - M[k][i] / M[i][i] * M[i][j] for j in range(n + 1)]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (M[i][n] - dot(M[i][i + 1:n], x[i + 1:])) / M[i][i]
    return x

def forms(emb, x, h):            # metric g_ij and II_ij (normal vectors) by central differences
    n = len(x)
    P = lambda *s: emb([x[i] + sum(h * c for k, c in s if k == i) for i in range(n)])
    p0 = P()
    r = [[(a - b) / (2 * h) for a, b in zip(P((i, 1)), P((i, -1)))] for i in range(n)]
    g = [[dot(r[i], r[j]) for j in range(n)] for i in range(n)]
    def perp(w):                 # the part of w at right angles to every tangent arrow
        c = solve(g, [dot(w, r[i]) for i in range(n)])
        return [w[m] - dot(c, [r[i][m] for i in range(n)]) for m in range(len(w))]
    def d2(i, j):
        if i == j:
            return [(a - 2 * c + b) / h ** 2 for a, b, c in zip(P((i, 1)), P((i, -1)), p0)]
        q = [P((i, s), (j, t)) for s, t in ((1, 1), (1, -1), (-1, 1), (-1, -1))]
        return [(q[0][m] - q[1][m] - q[2][m] + q[3][m]) / (4 * h * h) for m in range(len(p0))]
    return g, [[perp(d2(i, j)) for j in range(n)] for i in range(n)], perp

def gauss_sec(g, II, i, j, amb=0.0):  # Gauss equation for the plane of coordinate arrows i, j
    area2 = g[i][i] * g[j][j] - g[i][j] ** 2
    return amb + (dot(II[i][i], II[j][j]) - dot(II[i][j], II[i][j])) / area2

R = 6371.0                                            # the globe as a sphere of radius 6371 km
PHI = math.radians(90 - 51.5074)                      # London: polar angle from the North Pole
sphere = lambda x: [R * math.sin(x[0]) * math.cos(x[1]), R * math.sin(x[0]) * math.sin(x[1]), R * math.cos(x[0])]
print(f"globe: R = {R:.1f} km, London phi = {math.degrees(PHI):.4f} deg, 1/R = {sci(1 / R)} per km, target K = 1/R^2 = {sci(1 / R ** 2)} per km^2")
for h in (4e-2, 2e-3, 1e-3):
    g, II, _ = forms(sphere, [PHI, 0.3], h)
    K = gauss_sec(g, II, 0, 1)
    print(f"  step {h:g}: II/g = {sci(math.sqrt(dot(II[0][0], II[0][0])) / g[0][0])}, {sci(math.sqrt(dot(II[1][1], II[1][1])) / g[1][1])} per km; K = 0 + bending = {sci(K)}, rel err {sci(abs(K * R * R - 1), 1)}")
    assert abs(K * R * R - 1) < h * h                 # second order: the error falls as the step squared

# the real globe: the GRS80 ellipsoid at London, where II is no longer a multiple of g
A, FL = 6378.137, 1 / 298.257222101; E2 = FL * (2 - FL)
rho_e = lambda p: A / math.sqrt(1 - E2 * math.cos(p) ** 2)                  # east-west radius
rho_m = lambda p: A * (1 - E2) / (1 - E2 * math.cos(p) ** 2) ** 1.5         # north-south radius
ell = lambda x: [rho_e(x[0]) * math.sin(x[0]) * math.cos(x[1]), rho_e(x[0]) * math.sin(x[0]) * math.sin(x[1]),
                 rho_e(x[0]) * (1 - E2) * math.cos(x[0])]
Kc = 1 / (rho_m(PHI) * rho_e(PHI))
print(f"GRS80 (a = {A:.3f} km, 1/f = {1 / FL:.9f}) at London: rho_m = {rho_m(PHI):.3f} km, rho_e = {rho_e(PHI):.3f} km, K = 1/(rho_m rho_e) = {sci(Kc)} per km^2")
g, II, _ = forms(ell, [PHI, 0.3], 1e-3)
k1, k2 = math.sqrt(dot(II[0][0], II[0][0])) / g[0][0], math.sqrt(dot(II[1][1], II[1][1])) / g[1][1]
Ke = gauss_sec(g, II, 0, 1)
print(f"  outside road: kappa_1 = {sci(k1)}, kappa_2 = {sci(k2)} per km, |II_12| = {fx(math.sqrt(dot(II[0][1], II[0][1])), 6)}, K = {sci(Ke)}")
assert abs(k1 * rho_m(PHI) - 1) < 1e-6 and abs(Ke / Kc - 1) < 1e-6
Eg, Gg = lambda p: rho_m(p) ** 2, lambda p: (rho_e(p) * math.sin(p)) ** 2   # the metric: E and G
def K_inside(p, h):              # Gauss's formula for F = 0 and nothing depending on theta
    f = lambda q: (Gg(q + h) - Gg(q - h)) / (2 * h) / math.sqrt(Eg(q) * Gg(q))
    return -(f(p + h) - f(p - h)) / (2 * h) / (2 * math.sqrt(Eg(p) * Gg(p)))
errs = [abs(K_inside(PHI, h) / Kc - 1) for h in (2e-3, 1e-3)]
print(f"  inside road, metric alone: K = {sci(K_inside(PHI, 1e-3))}; rel err {sci(errs[0], 1)} then {sci(errs[1], 1)}")
assert errs[1] < 1e-5 and 3 < errs[0] / errs[1] < 5
print(f"  sphere of 6371 km is off by {100 * (1 / R ** 2 / Kc - 1):.3f} percent at London")
def codazzi(L, N, p, h=1e-4):    # N_phi - (G_phi / 2)(L/E + N/G): zero for every real surface
    Gp = (Gg(p + h) - Gg(p - h)) / (2 * h)
    return (N(p + h) - N(p - h)) / (2 * h) - Gp / 2 * (L(p) / Eg(p) + N(p) / Gg(p))
c_ok = codazzi(rho_m, lambda p: Gg(p) / rho_e(p), PHI)         # true II: L = rho_m, N = G / rho_e
c_bad = codazzi(lambda p: Eg(p) / rho_e(p), lambda p: Gg(p) / rho_m(p), PHI)
print(f"  Codazzi residual: true II {fx(c_ok, 6)} km; radii swapped {c_bad:.6f} km")
assert abs(c_ok) < 1e-5 and abs(c_bad) > 1.0

# the Clifford torus: flat, inside the round unit 3-sphere, inside 4-space
s3 = lambda x: [math.cos(x[0]) * math.cos(x[1]), math.cos(x[0]) * math.sin(x[1]), math.sin(x[0]) * math.cos(x[2]), math.sin(x[0]) * math.sin(x[2])]
g3, II3, _ = forms(s3, [math.pi / 4, 0.3, 1.1], 1e-4)
secs = [gauss_sec(g3, II3, i, j) for i, j in ((0, 1), (0, 2), (1, 2))]
print("unit 3-sphere in 4-space (n = 3): sec of the three coordinate planes = " + ", ".join(f"{s:.6f}" for s in secs))
assert all(abs(s - 1) < 1e-5 for s in secs)
tor = lambda x: [math.cos(x[0]) / math.sqrt(2), math.sin(x[0]) / math.sqrt(2), math.cos(x[1]) / math.sqrt(2), math.sin(x[1]) / math.sqrt(2)]
pt = [0.3, 1.1]; p = tor(pt)
g, II, _ = forms(tor, pt, 1e-4)
K4 = gauss_sec(g, II, 0, 1)
Hv = [(II[0][0][m] / g[0][0] + II[1][1][m] / g[1][1]) / 2 for m in range(4)]
print(f"Clifford torus: E = {g[0][0]:.6f}, F = {fx(g[0][1], 6)}, G = {g[1][1]:.6f}; area = 4 pi^2 E = {4 * math.pi ** 2 * g[0][0]:.4f}")
print(f"  split 1, in flat 4-space (k = 2): <II_11, II_22> = {fx(dot(II[0][0], II[1][1]), 6)}, |II(e1,e1)|^2 = {dot(II[0][0], II[0][0]) / g[0][0] ** 2:.6f}, K = 0 + {fx(K4, 6)}")
print(f"    mean curvature vector H = {fx(Hv[0], 6)}, {fx(Hv[1], 6)}, {fx(Hv[2], 6)}, {fx(Hv[3], 6)}; point = {p[0]:.6f}, {p[1]:.6f}, {p[2]:.6f}, {p[3]:.6f}")
assert abs(K4) < 1e-6 and all(abs(Hv[m] + p[m]) < 1e-6 for m in range(4))
nu = [math.cos(pt[0]) / math.sqrt(2), math.sin(pt[0]) / math.sqrt(2), -math.cos(pt[1]) / math.sqrt(2), -math.sin(pt[1]) / math.sqrt(2)]
hp = [[dot(II[i][j], p) / math.sqrt(g[i][i] * g[j][j]) for j in range(2)] for i in range(2)]   # part along the 3-sphere's normal p
hS = [[dot(II[i][j], nu) / math.sqrt(g[i][i] * g[j][j]) for j in range(2)] for i in range(2)]  # part along nu: II inside the 3-sphere
amb = hp[0][0] * hp[1][1] - hp[0][1] ** 2; KS = amb + hS[0][0] * hS[1][1] - hS[0][1] ** 2       # Gauss for the 3-sphere in 4-space
print(f"  split 2, in the unit 3-sphere (k = 1): II along p = {hp[0][0]:.6f}, {hp[1][1]:.6f}, so ambient = ({hp[0][0]:.6f})({hp[1][1]:.6f}) = {amb:.6f}")
print(f"    II along nu = principal curvatures {hS[0][0]:.6f}, {hS[1][1]:.6f}, mean {fx((hS[0][0] + hS[1][1]) / 2, 6)} (minimal); K = {amb:.6f} + ({hS[0][0]:.6f})({hS[1][1]:.6f}) = {fx(KS, 6)}")
assert abs(hp[0][0] + 1) < 1e-6 and abs(hp[1][1] + 1) < 1e-6 and abs(amb - secs[0]) < 1e-5 and abs(hS[0][0] + 1) < 1e-6 and abs(hS[1][1] - 1) < 1e-6 and abs(KS - K4) < 1e-6

# Ricci equation, flat 4-space: <R_perp(du,dv) nu1, nu2> = <[A1, A2] du, dv>
def frame(emb, x):               # orthonormal normal frame by Gram-Schmidt on e1, e3
    perp = forms(emb, x, 1e-5)[2]
    a = perp([1, 0, 0, 0]); a = [t / math.sqrt(dot(a, a)) for t in a]
    b = perp([0, 0, 1, 0]); b = [t - dot(b, a) * s for t, s in zip(b, a)]
    return a, [t / math.sqrt(dot(b, b)) for t in b]
def ricci(emb, x, h=1e-3):
    def om(y, i):                # omega_i = <d_i nu1, nu2>, the normal plane's turning rate
        yp, ym = y[:], y[:]; yp[i] += h; ym[i] -= h
        return dot([(a - b) / (2 * h) for a, b in zip(frame(emb, yp)[0], frame(emb, ym)[0])], frame(emb, y)[1])
    sh = lambda i, s: [x[k] + (s * h if k == i else 0) for k in range(2)]
    Rp = (om(sh(0, 1), 1) - om(sh(0, -1), 1) - om(sh(1, 1), 0) + om(sh(1, -1), 0)) / (2 * h)
    g, II, _ = forms(emb, x, 1e-3)
    n1, n2 = frame(emb, x)
    As = [[solve(g, [dot(II[0][j], n), dot(II[1][j], n)]) for j in range(2)] for n in (n1, n2)]
    Am = [[[A[j][i] for j in range(2)] for i in range(2)] for A in As]      # column j = A applied to d_j
    C = [[dot(Am[0][i], [Am[1][k][j] for k in range(2)]) - dot(Am[1][i], [Am[0][k][j] for k in range(2)]) for j in range(2)] for i in range(2)]
    area = math.sqrt(g[0][0] * g[1][1] - g[0][1] ** 2)       # per unit area, so it is chart-free
    return Rp / area, dot([C[k][0] for k in range(2)], [g[k][1] for k in range(2)]) / area, gauss_sec(g, II, 0, 1), g, II
par = lambda y: [y[0], y[1], (y[0] ** 2 - y[1] ** 2) / 2, y[0] * y[1]]     # the complex curve w = z^2/2
for name, emb, x in (("Clifford torus", tor, pt), ("w = z^2/2 at z = 0.4 + 0.3i", par, [0.4, 0.3])):
    Rp, cm, K, gp, IIp = ricci(emb, x)
    print(f"Ricci equation, {name}: normal curvature = {fx(Rp, 6)}, from [A1,A2] = {fx(cm, 6)}; K = {fx(K, 6)}")
    assert abs(Rp - cm) < 1e-4
print(f"  closed form for w = z^2/2: K = -2/(1+|z|^2)^3 = {-2 / 1.25 ** 3:.6f}")
assert abs(K + 2 / 1.25 ** 3) < 1e-5 and abs(Rp - K) < 1e-4

# what breaks
print(f"break: ambient term only: globe K = 0, Clifford torus in the 3-sphere K = {amb:.6f}")
print(f"break: bending term only, Clifford torus in the 3-sphere: K = {hS[0][0] * hS[1][1]:.6f}")
print(f"break: drop |II_12|^2, w = z^2/2 at 0.4 + 0.3i: K = {dot(IIp[0][0], IIp[1][1]) / (gp[0][0] * gp[1][1] - gp[0][1] ** 2):.6f}")
print(f"break: sphere's II on the ellipsoid's metric: Gauss says {sci(1 / R ** 2)}, metric says {sci(Kc)}")
print(f"try: Moon, R = 1737.4 km: 1/R = {sci(1 / 1737.4)} per km, K = {sci(1 / 1737.4 ** 2)} per km^2; GRS80: North Pole K = {sci(1 / rho_m(0) ** 2)}, equator K = {sci(1 / (rho_m(math.pi / 2) * rho_e(math.pi / 2)))}")
print("ALL CHECKS PASS")
