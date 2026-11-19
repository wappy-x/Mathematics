# Volume form and Laplace-Beltrami on a dome panel. Standard library only.
# Roads: closed form, two charts (phi, theta) and (x, y), a triangle mesh with cotangent weights,
# and a Legendre series for the slowest cooling rate. Every number on the card is printed here.
import math
R, P0, KAPPA, T0 = 1.0, math.pi / 3, 1.0e-4, 40.0  # sphere radius m, cap angle, m^2/s, degC
A_GEO = R * P0                                       # distance from top to edge along the panel, m
def f6(x): return f"{x:.6f}"

def lb(metric, f, x, y, h=1e-4):
    # Laplace-Beltrami from the metric: (1/sqrt det g) d_i( sqrt det g  g^ij  d_j f ), by central differences
    def flux(x, y):
        E, F, G = metric(x, y); det = E * G - F * F; s = math.sqrt(det)
        fx = (f(x + h, y) - f(x - h, y)) / (2 * h); fy = (f(x, y + h) - f(x, y - h)) / (2 * h)
        return s * (G * fx - F * fy) / det, s * (-F * fx + E * fy) / det, s
    d1 = (flux(x + h, y)[0] - flux(x - h, y)[0]) / (2 * h); d2 = (flux(x, y + h)[1] - flux(x, y - h)[1]) / (2 * h)
    return (d1 + d2) / flux(x, y)[2]
def flat(f, x, y, h=1e-4):  # the flat-plane Laplacian f_xx + f_yy in the same chart: the mistake
    return (f(x + h, y) + f(x - h, y) + f(x, y + h) + f(x, y - h) - 4 * f(x, y)) / (h * h)
polar = lambda p, t: (R * R, 0.0, (R * math.sin(p)) ** 2)           # chart 1: (phi, theta)
def graph(x, y):                                                       # chart 2: (x, y), z = sqrt(R^2 - x^2 - y^2)
    q = R * R - x * x - y * y; return (1 + x * x / q, x * y / q, 1 + y * y / q)
z_polar = lambda p, t: R * math.cos(p)
z_graph = lambda x, y: math.sqrt(R * R - x * x - y * y)

def mesh(n):  # rings of 1, 6, 12, ... points at equal steps of phi, joined into triangles
    pts, rings, tris = [], [], []
    for k in range(n + 1):
        m = max(1, 6 * k); ph = k * P0 / n; rings.append(list(range(len(pts), len(pts) + m)))
        for j in range(m):
            th = 2 * math.pi * j / m
            pts.append((R * math.sin(ph) * math.cos(th), R * math.sin(ph) * math.sin(th), R * math.cos(ph)))
    for k in range(1, n + 1):
        A, B = rings[k - 1], rings[k]; a, b = len(A), len(B); i = j = 0
        while j < b if k == 1 else (i < a or j < b):
            if k > 1 and i < a and (j == b or (i + 1) * b < (j + 1) * a):
                tris.append((A[i], A[(i + 1) % a], B[j % b])); i += 1
            else:
                tris.append((A[i % a], B[j], B[(j + 1) % b])); j += 1
    return pts, rings, tris
def sub(p, q): return [p[i] - q[i] for i in range(3)]
def dot(p, q): return sum(p[i] * q[i] for i in range(3))
def cross(p, q): return [p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0]]
def cot_laplacian(pts, tris):  # edge weight (cot a + cot b)/2; each vertex owns a third of each triangle
    W, M = {}, [0.0] * len(pts)
    for t in tris:
        c = cross(sub(pts[t[1]], pts[t[0]]), sub(pts[t[2]], pts[t[0]])); ar = 0.5 * math.sqrt(dot(c, c))
        for s in range(3):
            p, q, r = t[s], t[(s + 1) % 3], t[(s + 2) % 3]
            u, v = sub(pts[p], pts[r]), sub(pts[q], pts[r]); cr = cross(u, v)
            e = (min(p, q), max(p, q)); W[e] = W.get(e, 0.0) + dot(u, v) / math.sqrt(dot(cr, cr)) / 2
            M[r] += ar / 3
    nb = [[] for _ in pts]
    for (p, q), w in W.items(): nb[p].append((q, w)); nb[q].append((p, w))
    return nb, M
def mesh_lambda(nb, M, inside):  # smallest lambda of L u = lambda M u, edge at 0: inverse iteration + CG
    def L(u): return [sum(w * (u[i] - u[j]) for j, w in nb[i]) if inside[i] else 0.0 for i in range(len(u))]
    u = [1.0 if s else 0.0 for s in inside]
    for _ in range(40):
        b = [M[i] * u[i] if inside[i] else 0.0 for i in range(len(u))]
        x = [0.0] * len(u); r = b[:]; p = r[:]; rr = sum(v * v for v in r)
        for _ in range(2000):
            Ap = L(p); al = rr / sum(p[i] * Ap[i] for i in range(len(p)))
            x = [x[i] + al * p[i] for i in range(len(x))]; r = [r[i] - al * Ap[i] for i in range(len(r))]
            r2 = sum(v * v for v in r)
            if r2 < 1e-26: break
            p = [r[i] + r2 / rr * p[i] for i in range(len(p))]; rr = r2
        s = math.sqrt(sum(M[i] * x[i] * x[i] for i in range(len(x)))); u = [v / s for v in x]
    Lu = L(u); return sum(u[i] * Lu[i] for i in range(len(u)))  # u is M-normalised

def legendre(nu, x):  # P_nu(x) as the series 2F1(-nu, nu+1; 1; (1-x)/2)
    z, term, tot = (1 - x) / 2, 1.0, 1.0
    for k in range(400): term *= (k - nu) * (k + nu + 1) / ((k + 1) ** 2) * z; tot += term
    return tot
def cap_lambda(radius, angle):  # first zero in nu of P_nu(cos angle); lambda = nu(nu+1)/radius^2
    nu = 0.0
    while legendre(nu + 0.05, math.cos(angle)) > 0: nu += 0.05
    lo, hi = nu, nu + 0.05
    for _ in range(60):
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if legendre(mid, math.cos(angle)) > 0 else (lo, mid)
    return lo * (lo + 1) / radius ** 2
def j0(x): return sum((-1) ** k * (x / 2) ** (2 * k) / math.factorial(k) ** 2 for k in range(40))
lo, hi = 2.0, 3.0
for _ in range(60): mid = (lo + hi) / 2; lo, hi = (mid, hi) if j0(mid) > 0 else (lo, mid)
J01 = lo

print("panel: R =", f6(R), "m, cap angle phi0 =", f6(P0), "rad = 60 deg, edge distance a =", f6(A_GEO), "m")
area_exact = 2 * math.pi * R * R * (1 - math.cos(P0)); N = 2000; rho = R * math.sin(P0)
area_polar = sum(2 * math.pi * R * R * math.sin((i + 0.5) * P0 / N) * P0 / N for i in range(N))
area_graph = sum(2 * math.pi * r * R / math.sqrt(R * R - r * r) * rho / N for r in [(i + 0.5) * rho / N for i in range(N)])
print("1 - cos phi0 =", f6(1 - math.cos(P0)), "; area closed form 2 pi R^2 (1 - cos phi0) =", f6(area_exact), "m^2")
print("area chart (phi, theta), sum of sqrt det g =", f6(area_polar))
print("area chart (x, y), sum of sqrt det g =", f6(area_graph))
print("flat disc radius a: area =", f6(math.pi * A_GEO ** 2), "edge =", f6(2 * math.pi * A_GEO), "m; cap edge =", f6(2 * math.pi * rho), "m")
print("sqrt det g at phi = 30 deg, chart (phi, theta) =", f6(math.sqrt(polar(math.pi / 6, 0)[0] * polar(math.pi / 6, 0)[2])))
ex = -2 * math.cos(math.pi / 6) / R; lbp = lb(polar, z_polar, math.pi / 6, 0.0); lbg = lb(graph, z_graph, 0.5, 0.0)
print("at phi = 30 deg: z =", f6(z_polar(math.pi / 6, 0)), "m, z_phi =", f6(-R * math.sin(math.pi / 6)), "m, cot(phi) =", f6(1 / math.tan(math.pi / 6)))
print("Delta_g z exact -2 z / R^2 =", f6(ex), "per m")
print("Delta_g z chart (phi, theta) =", f6(lbp), " chart (x, y) =", f6(lbg))
P, H = math.pi / 6, 1e-4; bend = (z_polar(P + H, 0) - 2 * z_polar(P, 0) + z_polar(P - H, 0)) / (H * H) / R ** 2
spread = (1 / math.tan(P)) * (z_polar(P + H, 0) - z_polar(P - H, 0)) / (2 * H) / R ** 2
print("bend term z_phiphi / R^2 =", f6(bend), " spread term cot(phi) z_phi / R^2 =", f6(spread))
res = {}
for n in (8, 16):
    pts, rings, tris = mesh(n); nb, M = cot_laplacian(pts, tris); v = rings[n // 2][0]
    lz = -sum(w * (pts[v][2] - pts[j][2]) for j, w in nb[v]) / M[v]
    inside = [True] * len(pts)
    for i in rings[n]: inside[i] = False
    res[n] = (sum(M), lz, mesh_lambda(nb, M, inside))
    print(f"mesh n = {n}: {len(pts)} points {len(tris)} triangles; area {f6(res[n][0])} err {f6(area_exact - res[n][0])};",
          f"Delta_g z {f6(lz)} err {f6(lz - ex)}")
lam = cap_lambda(R, P0); lam_flat = (J01 / A_GEO) ** 2
for n in (8, 16): print(f"mesh n = {n}: lambda1 = {f6(res[n][2])} per m^2, err {f6(res[n][2] - lam)}")
print("lambda1 cap, Legendre series =", f6(lam), "per m^2; flat disc (j01/a)^2 =", f6(lam_flat), "with j01 =", f6(J01))
half = lambda l, k=KAPPA: math.log(2) / (k * l) / 60
print("cap / flat disc: area ratio", f6(area_exact / (math.pi * A_GEO ** 2)), "; lambda1 ratio flat / cap", f6(lam_flat / lam))
print("ln 2 =", f6(math.log(2)), "; kappa lambda1 =", f"{KAPPA * lam:.10f}", "per s; half-life", f"{half(lam) * 60:.2f}", "s")
print("half-life of the slowest pattern, kappa = 1e-4 m^2/s: cap", f"{half(lam):.2f}", "min, flat disc", f"{half(lam_flat):.2f}", "min")
print("chart minutes 0..60: cap", " ".join(f"{T0 * math.exp(-KAPPA * lam * 600 * k):.2f}" for k in range(7)))
print("chart minutes 0..60: flat", " ".join(f"{T0 * math.exp(-KAPPA * lam_flat * 600 * k):.2f}" for k in range(7)))
print("break: area with sqrt det g dropped, chart (phi, theta) =", f6(2 * math.pi * R * R * P0), "m^2")
fp, fg = flat(z_polar, math.pi / 6, 0.0) / R ** 2, flat(z_graph, 0.5, 0.0)
print("break: flat Laplacian of z, chart (phi, theta) / R^2 =", f6(fp), " chart (x, y) =", f6(fg))
hgt = math.tan(math.pi / 6)  # edge (-1,0,0)-(1,0,0), apexes (0, +-hgt, 0): both angles facing it are 120 deg
w_obt = dict(cot_laplacian([(-1.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, hgt, 0.0), (0.0, -hgt, 0.0)], [(0, 1, 2), (1, 0, 3)])[0][0])[1]
print("break: edge weight with two 120 deg opposite angles =", f6(w_obt))
lam_h, lam_10 = cap_lambda(R, math.pi / 2), cap_lambda(10.0, A_GEO / 10.0)
print("try: hemisphere lambda1 =", f6(lam_h), "; R = 10 m, same a: lambda1 =", f6(lam_10), "; steel kappa 1.2e-5: half-life", f"{half(lam, 1.2e-5):.2f}", "min")
assert abs(area_polar - area_exact) < 1e-6 and abs(area_graph - area_exact) < 1e-5     # two charts, one area
assert abs(lbp - ex) < 1e-5 and abs(lbg - ex) < 1e-5 and abs(bend + spread - ex) < 1e-5 # two charts, one Delta_g z
assert abs(res[16][1] - ex) < abs(res[8][1] - ex) / 3 < 0.02                           # mesh converges, order 2
assert abs(res[16][0] - area_exact) < abs(res[8][0] - area_exact) / 3
assert abs(res[16][2] - lam) < abs(res[8][2] - lam) / 3 < 0.05                         # mesh lambda -> series lambda
assert abs(lam_h - 2 / R ** 2) < 1e-9 and lam < lam_10 < lam_flat                      # z itself on a hemisphere
assert abs(fp - ex) > 0.5 and abs(fg - fp) > 1 and abs(w_obt + 1 / math.sqrt(3)) < 1e-9  # the mistakes are wrong
print("ALL CHECKS PASS")
