# Ricci and scalar curvature: contract the curvature tensor, then compare a small ball with the flat answer.
from math import sin, cos, cosh, sqrt, pi

R = 30.0   # the dome's radius of curvature, m
r = 5.0    # patch radius, measured along the roof from the top, m

def sphere_chart(p):   # polar angle phi from the top, longitude theta
    return [[R * R, 0.0], [0.0, (R * sin(p[0])) ** 2]]

def graph_chart(p):    # x, y in metres on the floor plan, roof height sqrt(R^2 - x^2 - y^2)
    w = R * R - p[0] ** 2 - p[1] ** 2
    return [[1 + p[0] ** 2 / w, p[0] * p[1] / w], [p[0] * p[1] / w, 1 + p[1] ** 2 / w]]

def saddle_chart(p):   # half-plane chart of the hyperbolic plane, curvature -1/R^2
    return [[R * R / p[1] ** 2, 0.0], [0.0, R * R / p[1] ** 2]]

def stack_chart(p):    # dome directions phi, theta plus one flat direction t (m)
    return [[R * R, 0.0, 0.0], [0.0, (R * sin(p[0])) ** 2, 0.0], [0.0, 0.0, 1.0]]

def inverse(g):        # 2x2 or 3x3 inverse by cofactors
    if len(g) == 2:
        d = g[0][0] * g[1][1] - g[0][1] * g[1][0]
        return [[g[1][1] / d, -g[0][1] / d], [-g[1][0] / d, g[0][0] / d]]
    c = [[g[(j + 1) % 3][(i + 1) % 3] * g[(j + 2) % 3][(i + 2) % 3]
          - g[(j + 1) % 3][(i + 2) % 3] * g[(j + 2) % 3][(i + 1) % 3] for j in range(3)] for i in range(3)]
    d = sum(g[0][k] * c[k][0] for k in range(3))
    return [[c[i][j] / d for j in range(3)] for i in range(3)]

def shift(p, i, s):
    q = list(p); q[i] += s; return q

def christoffel(chart, p, h):  # G[l][j][k] = 1/2 g^lm (d_j g_mk + d_k g_mj - d_m g_jk)
    n = len(p); gi = inverse(chart(p))
    dg = [[[(chart(shift(p, m, h))[i][j] - chart(shift(p, m, -h))[i][j]) / (2 * h)
            for j in range(n)] for i in range(n)] for m in range(n)]
    return [[[0.5 * sum(gi[l][m] * (dg[j][m][k] + dg[k][m][j] - dg[m][j][k]) for m in range(n))
              for k in range(n)] for j in range(n)] for l in range(n)]

def ricci(chart, p, h):  # Rm(l, i, j, k) = Rm^l_kij, component l of Rm(d_i, d_j) d_k; Ric_jk = Rm^i_jik, S = g^jk Ric_jk
    n = len(p); G = christoffel(chart, p, h)
    dG = [[[[(a - b) / (2 * h) for a, b in zip(ra, rb)] for ra, rb in zip(A, B)]
           for A, B in zip(christoffel(chart, shift(p, i, h), h), christoffel(chart, shift(p, i, -h), h))]
          for i in range(n)]
    def Rm(l, i, j, k):
        return (dG[i][l][j][k] - dG[j][l][i][k]
                + sum(G[l][i][m] * G[m][j][k] - G[l][j][m] * G[m][i][k] for m in range(n)))
    Ric = [[sum(Rm(i, i, k, j) for i in range(n)) for k in range(n)] for j in range(n)]
    gi = inverse(chart(p))
    return Ric, sum(gi[j][k] * Ric[j][k] for j in range(n) for k in range(n))

def clean(v):
    return 0.0 if abs(v) < 5e-12 else v

def show(label, v, d=6):
    print(f"{label:<40}{clean(v):>16.{d}f}")

# ---- road 1: contract in two charts of the dome, at a point 15 m from the top ----
phi0, th0 = 0.5, 0.3
x0, y0 = R * sin(phi0) * cos(th0), R * sin(phi0) * sin(th0)
RicA, SA = ricci(sphere_chart, [phi0, th0], 1e-4)
RicB, SB = ricci(graph_chart, [x0, y0], 1e-2)
gB = graph_chart([x0, y0])
show("by hand: Rm^phi_thphth = sin^2 phi", sin(phi0) ** 2); show("sphere chart Ric_phiphi", RicA[0][0])
show("sphere chart Ric_thetatheta", RicA[1][1]); show("sphere chart Ric_phitheta", RicA[0][1])
show("graph chart Ric_xx, 1/m^2", RicB[0][0], 8); show("graph chart Ric_xy, 1/m^2", RicB[0][1], 8)
show("graph chart g_xx * K, 1/m^2", gB[0][0] / R ** 2, 8)
show("S, sphere chart, 1/m^2", SA, 8); show("S, graph chart, 1/m^2", SB, 8)
show("S = 2K = 2/R^2, 1/m^2", 2 / R ** 2, 8)
_, SH = ricci(saddle_chart, [0.0, 40.0], 1e-2)
show("S, saddle (hyperbolic) chart, 1/m^2", SH, 8)

# ---- the dome patch: flat answer, exact area, curvature prediction ----
def cap(s):  # area within distance s of the top, closed form
    return 2 * pi * R * R * (1 - cos(s / R))
def cap_by_chart(s, N=200):  # integrate sqrt(det g) over the graph chart's disc; round, so 2 pi times Simpson in radius
    rho, tot = R * sin(s / R), 0.0
    for i in range(N + 1):
        q = rho * i / N; g = graph_chart([q * cos(0.7), q * sin(0.7)])
        tot += (1 if i in (0, N) else 4 if i % 2 else 2) * sqrt(g[0][0] * g[1][1] - g[0][1] ** 2) * q
    return 2 * pi * rho / N / 3 * tot
flat, exact, chart_area = pi * r * r, cap(r), cap_by_chart(r)
pred = flat * (1 - SB * r * r / 24)
show("fraction missing, S r^2 / 24", 2 / R ** 2 * r * r / 24, 8)
show("flat disc pi r^2, m^2", flat, 4); show("exact cap area, m^2", exact, 4)
show("chart integral area, m^2", chart_area, 4); show("Ricci prediction, m^2", pred, 4)
show("missing area, exact, m^2", flat - exact, 4); show("missing area, predicted, m^2", flat - pred, 4)
show("prediction error, m^2", pred - exact, 6)
Kest = 12 * (flat - exact) / (pi * r ** 4)
show("radius read back from the area, m", 1 / sqrt(Kest), 4)
show("Earth, 1000 km disc, missing km^2", pi * 1000 ** 2 - 2 * pi * 6371 ** 2 * (1 - cos(1000 / 6371)), 1)

# ---- road 2: three dimensions, the dome stacked along a flat direction t ----
Ric3, S3 = ricci(stack_chart, [phi0, th0, 0.0], 1e-4)
def ric_dir(v):
    return sum(Ric3[j][k] * v[j] * v[k] for j in range(3) for k in range(3))
show("3D Ric, along the dome, 1/m^2", ric_dir([1 / R, 0, 0]), 8)
show("3D Ric, along t, 1/m^2", ric_dir([0, 0, 1]), 8)
show("3D Ric, tilted 45 degrees, 1/m^2", ric_dir([1 / (R * sqrt(2)), 0, 1 / sqrt(2)]), 8)
avg = 0.0  # Simpson in z = cos(angle from t) over [-1, 1], 8 midpoints around: exact for this quadratic
for a in range(21):
    z = -1 + a / 10
    for b in range(8):
        v = 2 * pi * (b + 0.5) / 8
        e = [sqrt(1 - z * z) * cos(v), sqrt(1 - z * z) * sin(v), z]   # unit direction, orthonormal frame
        avg += (1 if a in (0, 20) else 4 if a % 2 else 2) / 30 / 2 / 8 * ric_dir([e[0] / R, e[1] / (R * sin(phi0)), e[2]])
show("average Ric over all directions", avg, 8); show("S / 3, 1/m^2", S3 / 3, 8)
def ball3(s, N=400):  # Simpson over t of the dome cap at radius sqrt(s^2 - t^2)
    hh = 2 * s / N
    return hh / 3 * sum(cap(sqrt(max(0.0, s * s - (-s + i * hh) ** 2))) * (1 if i in (0, N) else 4 if i % 2 else 2)
                        for i in range(N + 1))
flat3, ex3 = 4 / 3 * pi * r ** 3, ball3(r)
show("3D flat ball, m^3", flat3, 3); show("3D exact ball, m^3", ex3, 3)
show("3D Ricci prediction, m^3", flat3 * (1 - S3 * r * r / 30), 3)

print("parts of Rm and of Ric, n = 2, 3, 4: " + "  ".join(f"{n * n * (n * n - 1) // 12}/{n * (n + 1) // 2}" for n in (2, 3, 4)))
# ---- what breaks ----
show("wrong: divide by 6, not 24, m^2", flat * (1 - SB * r * r / 6), 4)
show("wrong: S taken as K, m^2", flat * (1 - (SB / 2) * r * r / 24), 4)
show("wrong: sign flipped, m^2", flat * (1 + SB * r * r / 24), 4)
big = pi * R; show("whole sphere, r = pi R, m", big, 2)
show("whole sphere, exact, m^2", cap(big), 2); show("whole sphere, prediction, m^2", pi * big ** 2 * (1 - SB * big ** 2 / 24), 2)
show("try: saddle disc, exact, m^2", 2 * pi * R * R * (cosh(r / R) - 1), 4)
show("try: R = 15 m, exact, m^2", 2 * pi * 225 * (1 - cos(r / 15)), 4)

# ---- chart: area / flat area against patch radius ----
rs = [10.0 * i for i in range(1, 10)]
print("chart r  " + " ".join(f"{s:6.0f}" for s in rs))
print("exact    " + " ".join(f"{cap(s) / (pi * s * s):6.3f}" for s in rs))
print("predict  " + " ".join(f"{1 - SB * s * s / 24:6.3f}" for s in rs))

assert abs(SA - 2 / R ** 2) < 1e-9, "sphere chart S against 2/R^2"
assert abs(SB - SA) < 1e-9, "S agrees in two charts"
assert abs(SH + 2 / R ** 2) < 1e-8, "saddle has S = -2/R^2"
assert abs(chart_area - exact) < 1e-6, "chart integral against closed form"
assert abs((exact - pred) - flat * (r / R) ** 4 / 360) < 1e-6, "prediction misses only the next term"
assert abs(avg - S3 / 3) < 1e-12, "direction average of Ric is S/n"
assert abs(ex3 - flat3 * (1 - S3 * r * r / 30)) < 0.01, "3D ball against S r^2 / 30"
assert abs(RicB[0][0] - gB[0][0] / R ** 2) < 1e-9, "on a surface Ric = K g"
assert abs(RicA[1][1] - sin(phi0) ** 2) < 1e-6, "Ric_thetatheta against the hand contraction"
print("ALL CHECKS PASS")
