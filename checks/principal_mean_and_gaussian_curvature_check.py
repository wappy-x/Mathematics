# Principal, mean and Gaussian curvature -- the check behind the card.
# Standard library only.  A stadium roof: a saddle z = 30 + (x^2 - y^2)/120
# over the middle and a dome (a sphere of radius 60 m) over the east end.
# The unit normal n points up, to the sky; a bending rate is positive where the
# roof bends toward n (up, like a bowl).  Roads to the two bending rates:
# (1) the formulas K = det II / det I and H = half the trace of W = I^-1 II,
# (2) a symmetric 2-by-2 matrix in a roof-perpendicular frame, turned by one
# Jacobi rotation, (3) a sweep of 3600 directions measuring each curve on the
# roof from raw 3D points, (4) a second chart, (5) K from the spread of n.
from math import sqrt, sin, cos, atan2, asin, acos, pi, degrees, radians

A, R = 60.0, 60.0                                  # saddle radius a; dome sphere radius (m)
def saddle(x, y): return (x, y, 30 + (x * x - y * y) / (2 * A))
def seam(s, t): return saddle(s + t, s - t)        # second saddle chart: along the seams
def dome_plan(x, y): return (x, y, -10.5 + sqrt(R * R - (x - 30) ** 2 - y * y))
def dome_sphere(p, t): return (30 + R * sin(p) * cos(t), R * sin(p) * sin(t), -10.5 + R * cos(p))
def vault(x, s): return (x, 20 * sin(s / 20), 20 * cos(s / 20))   # copper rolled to radius 20 m
def sheet(x, s): return (x, s, 0.0)                                # the same copper laid flat

def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def comb(cs, vs): return tuple(sum(c * v[k] for c, v in zip(cs, vs)) for k in range(3))
def unit_up(f, u, v, h):                           # the unit normal, turned to point up
    ru = comb((0.5 / h, -0.5 / h), (f(u + h, v), f(u - h, v)))
    rv = comb((0.5 / h, -0.5 / h), (f(u, v + h), f(u, v - h)))
    n = cross(ru, rv); s = sqrt(dot(n, n)) * (1 if n[2] > 0 else -1)
    return ru, rv, (n[0] / s, n[1] / s, n[2] / s)

def forms(f, u, v, h):                             # E, F, G, L, M, N by central differences
    ru, rv, n = unit_up(f, u, v, h)
    ruu = comb((1 / h / h, -2 / h / h, 1 / h / h), (f(u + h, v), f(u, v), f(u - h, v)))
    rvv = comb((1 / h / h, -2 / h / h, 1 / h / h), (f(u, v + h), f(u, v), f(u, v - h)))
    q = 0.25 / h / h
    ruv = comb((q, -q, -q, q), (f(u + h, v + h), f(u + h, v - h), f(u - h, v + h), f(u - h, v - h)))
    return dot(ru, ru), dot(ru, rv), dot(rv, rv), dot(ruu, n), dot(ruv, n), dot(rvv, n)

def curv(E, F, G, L, M, N):                        # road 1: K, H, kappa_1, kappa_2
    K = (L * N - M * M) / (E * G - F * F)
    H = (E * N - 2 * F * M + G * L) / (2 * (E * G - F * F))
    d = sqrt(max(H * H - K, 0.0))
    return K, H, H + d, H - d

def frame(E, F, G):                                # roof-perpendicular unit steps, as (du, dv)
    w = sqrt(G - F * F / E)
    return (1 / sqrt(E), 0.0), (-F / E / w, 1 / w)
def II(L, M, N, a, b): return L * a[0] * b[0] + M * (a[0] * b[1] + a[1] * b[0]) + N * a[1] * b[1]
def jacobi(E, F, G, L, M, N):                      # road 2: one rotation diagonalises S
    e1, e2 = frame(E, F, G)
    s11, s12, s22 = II(L, M, N, e1, e1), II(L, M, N, e1, e2), II(L, M, N, e2, e2)
    th = 0.5 * atan2(2 * s12, s11 - s22)
    c, s = cos(th), sin(th)
    return s11 * c * c + 2 * s12 * s * c + s22 * s * s, s11 * s * s - 2 * s12 * s * c + s22 * c * c, th, s12

def kn_raw(f, u, v, th, h):                        # road 3: bend of a roof curve from 3D points
    E, F, G = forms(f, u, v, h)[:3]
    e1, e2 = frame(E, F, G)
    a, b = cos(th) * e1[0] + sin(th) * e2[0], cos(th) * e1[1] + sin(th) * e2[1]
    n = unit_up(f, u, v, h)[2]
    g1 = comb((0.5 / h, -0.5 / h), (f(u + a * h, v + b * h), f(u - a * h, v - b * h)))
    g2 = comb((1 / h / h, -2 / h / h, 1 / h / h), (f(u + a * h, v + b * h), f(u, v), f(u - a * h, v - b * h)))
    return dot(g2, n) / dot(g1, g1), (a, b)

def gauss_map_K(f, u, v, h):                       # road 5: area spread of n over area of roof
    ru, rv, n = unit_up(f, u, v, h)
    nu = comb((0.5 / h, -0.5 / h), (unit_up(f, u + h, v, h)[2], unit_up(f, u - h, v, h)[2]))
    nv = comb((0.5 / h, -0.5 / h), (unit_up(f, u, v + h, h)[2], unit_up(f, u, v - h, h)[2]))
    return dot(cross(nu, nv), n) / dot(cross(ru, rv), n)

def f9(v): return f"{v:.9f}"
def f12(v): return f"{v:.12f}"
def show(label, val): print(f"{label:<44} {val}")

P = (30.0, 20.0)                                   # the north-east lamp fixing
p, q = P[0] / A, -P[1] / A                         # its two slopes
E, F, G = 1 + p * p, p * q, 1 + q * q
L, M, N = (1 / A) / sqrt(1 + p * p + q * q), 0.0, (-1 / A) / sqrt(1 + p * p + q * q)
K, H, k1, k2 = curv(E, F, G, L, M, N)
for name, val in (("P slopes east, north", f"{p:.6f} {q:.6f}"), ("P E, F, G", f"{E:.6f} {F:.6f} {G:.6f}"),
                  ("P EG - F^2, its root", f"{E * G - F * F:.6f} {sqrt(E * G - F * F):.6f}"), ("P L, M, N (1/m)", f"{f9(L)} {f9(M)} {f9(N)}"),
                  ("P K (1/m^2), road 1", f12(K)), ("P H (1/m), road 1", f9(H)), ("P root of H^2 - K (1/m)", f9(sqrt(H * H - K))),
                  ("P kappa_1, kappa_2 (1/m), road 1", f"{f9(k1)} {f9(k2)}"),
                  ("P signed radii 1/kappa (m)", f"{1 / k1:.3f} {1 / k2:.3f}")):
    show(name, val)
j1, j2, th, s12 = jacobi(E, F, G, L, M, N)
e1, e2 = frame(E, F, G)
s11, s22 = II(L, M, N, e1, e1), II(L, M, N, e2, e2)
show("P frame e1, e2 as plan steps (dx, dy)", f"{e1[0]:.6f} {e1[1]:.6f} {e2[0]:.6f} {e2[1]:.6f}")
show("P frame matrix S: s11, s22, s12 (1/m)", f"{f9(s11)} {f9(s22)} {f9(s12)}")
show("P tan 2 theta_1 = 2 s12 / (s11 - s22)", f"{2 * s12 / (s11 - s22):.6f}")
show("P kappa_1, kappa_2, road 2 Jacobi", f"{f9(j1)} {f9(j2)}")
W = tuple(x / (E * G - F * F) for x in (G * L - F * M, G * M - F * N, E * M - F * L, E * N - F * M))   # W = I^-1 II
show("P W row by row (1/m)", " ".join(f9(w) for w in W))
show("P trace W = 2H, det W = K", f"{f9(W[0] + W[3])} {f12(W[0] * W[3] - W[1] * W[2])}")
v1, v2 = (k1 - W[3], W[2]), (k2 - W[3], W[2])     # eigenvectors of W in (dx, dy), from its second row
show("P v1, v2: eigenvectors of W (dx, dy)", f"{f9(v1[0])} {f9(v1[1])} {f9(v2[0])} {f9(v2[1])}")
hd = [degrees(atan2(v[1], v[0])) % 180 for v in (v1, v2)]
show("P plan headings of v1, v2; angle between", f"{hd[0]:.4f} {hd[1]:.4f} {hd[1] - hd[0]:.4f}")
roof = degrees(atan2(II(E, F, G, v1, e2), II(E, F, G, v1, e1)))   # II's formula fed E, F, G is the first form
show("P kappa_1 roof deg from east: Jacobi, v1", f"{degrees(th):.4f} {roof:.4f}")
sweep = [(kn_raw(saddle, P[0], P[1], pi * i / 3600, 1.0)[0], i / 20) for i in range(3600)]
hi, lo = max(sweep), min(sweep)
show("P sweep max, min (1/m), road 3", f"{f9(hi[0])} {f9(lo[0])}")
show("P sweep at roof deg", f"{hi[1]:.2f} {lo[1]:.2f}")
euler = max(abs(k - (k1 * cos(radians(d) - th) ** 2 + k2 * sin(radians(d) - th) ** 2)) for k, d in sweep)
show("P worst gap to Euler's formula (1/m)", f12(euler))
s_seam = curv(*forms(seam, 25.0, 5.0, 1.0))
show("P K, kappa_1, kappa_2, road 4 seam chart", f"{f12(s_seam[0])} {f9(s_seam[2])} {f9(s_seam[3])}")
gK2, gK = (gauss_map_K(saddle, P[0], P[1], h) for h in (0.02, 0.01))
show("P K by road 5, step 0.02 | 0.01 m", f"{f12(gK2)} | {f12(gK)}")
show("P |I(v1, v2)|, roof dot of the two", f12(abs(II(E, F, G, v1, v2))))
show("P east and north lines, roof angle (deg)", f"{degrees(acos(F / sqrt(E * G))):.4f}")
O = curv(*forms(saddle, 0.0, 0.0, 1.0))
show("O K, H, kappa_1, kappa_2", f"{f12(O[0])} {f9(O[1])} {f9(O[2])} {f9(O[3])}")
D1c, D1 = (curv(*forms(dome_plan, 42.0, 16.0, h)) for h in (0.02, 0.01))
D2c, D2 = (curv(*forms(dome_sphere, asin(1 / 3), atan2(16, 12), h)) for h in (0.0004, 0.0002))
show("D plan K, H, step 0.02 | 0.01 m", f"{f12(D1c[0])} {f9(D1c[1])} | {f12(D1[0])} {f9(D1[1])}")
show("D sphere K, H, step 0.0004 | 0.0002 rad", f"{f12(D2c[0])} {f9(D2c[1])} | {f12(D2[0])} {f9(D2[1])}")
djc, dj = (jacobi(*forms(dome_plan, 42.0, 16.0, h)) for h in (0.02, 0.01))
show("D kappa_1 - kappa_2, step 0.02 | 0.01 m", f"{f12(djc[0] - djc[1])} | {f12(dj[0] - dj[1])}")
cyl, flat = forms(vault, 0.0, 0.0, 0.01), forms(sheet, 0.0, 0.0, 0.01)
show("vault E, F, G | sheet E, F, G", " ".join(f"{x:.6f}" for x in cyl[:3] + flat[:3]))
show("vault K, H | sheet K, H", f"{f12(curv(*cyl)[0])} {f9(curv(*cyl)[1])} {f12(curv(*flat)[0])} {f9(curv(*flat)[1])}")
show("vault H, step 0.02 | 0.01 m", f"{f9(curv(*forms(vault, 0.0, 0.0, 0.02))[1])} | {f9(curv(*cyl)[1])}")
show("wrong: eigenvalues of II alone; product", f"{f9(L)} {f9(N)} {f12(L * N)}")
show("wrong: height Hessian K, H", f"{f12(-1 / A / A)} {f9(0.0)}")
show("wrong: east, north as principal; K, H", f"{f9(L / E)} {f9(N / G)} {f12(L / E * N / G)} {f9((L / E + N / G) / 2)}")
show("flip n: K, H", f"{f12(curv(E, F, G, -L, -M, -N)[0])} {f9(curv(E, F, G, -L, -M, -N)[1])}")
for name, f, u, v, h in (("O", saddle, 0.0, 0.0, 1.0), ("P", saddle, P[0], P[1], 1.0), ("D", dome_plan, 42.0, 16.0, 0.01)):
    print("chart, " + name + " kappa_n (1/km) every 15 roof deg:", " ".join(f"{1000 * kn_raw(f, u, v, radians(15 * i), h)[0]:.2f}" for i in range(13)))

assert abs(j1 - k1) < 1e-12 and abs(j2 - k2) < 1e-12          # road 2 against road 1
assert abs(hi[0] - k1) < 1e-8 and abs(lo[0] - k2) < 1e-8 and euler < 1e-9   # road 3
assert abs(s_seam[0] - K) < 1e-12 and abs(s_seam[2] - k1) < 1e-9 and abs(s_seam[3] - k2) < 1e-9
assert abs(gK - K) < 1e-9                                       # road 5: Gauss map against det II / det I
assert abs(II(E, F, G, v1, v2)) < 1e-15 and abs(roof - degrees(th)) < 1e-9 and abs(W[0] * W[3] - W[1] * W[2] - K) < 1e-15
assert abs(gK - K) < abs(gK2 - K) / 3 and abs(dj[0] - dj[1]) < abs(djc[0] - djc[1]) / 3   # stepped errors shrink
assert abs(D1[0] - 1 / R / R) < 1e-8 and abs(D2[0] - 1 / R / R) < 1e-8 and abs(D1[1] + 1 / R) < 1e-6 and abs(D2[1] + 1 / R) < 1e-6
assert abs(dj[0] - dj[1]) < 1e-6 and abs(L * N - K) > 1e-5      # dome umbilic; II alone is wrong
assert abs(curv(*cyl)[1] + 1 / 40) < 1e-6 and abs(curv(*cyl)[0]) < 1e-9 and abs(cyl[0] - flat[0]) + abs(cyl[2] - flat[2]) < 1e-6
print("ALL CHECKS PASS")
