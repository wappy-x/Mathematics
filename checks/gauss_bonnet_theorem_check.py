# Gauss-Bonnet -- the check behind the card.  Standard library only.
# A football, a stadium's half dome, a rugby ball and an inner tube: total curvature
# in a chart, against corner angles, mesh angle defects and the count V - E + F.
import math
PI, TAU = math.pi, 2 * math.pi
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def scale(a, k): return (a[0] * k, a[1] * k, a[2] * k)
def unit(a): return scale(a, 1 / math.sqrt(dot(a, a)))
def ang(a, b): return math.acos(max(-1.0, min(1.0, dot(unit(a), unit(b)))))
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def f6(x): return f"{(0.0 if abs(x) < 5e-7 else x):.6f}"
def deg(x): return f6(math.degrees(x))
def KdA(pr, t):                              # surface of revolution, profile (rho, z) and derivatives in t
    r, z, r1, z1, r2, z2 = pr(t)             # chart (t, theta), worked at theta = 0
    rt, rq, rtt, rtq, rqq = (r1, 0, z1), (0, r, 0), (r2, 0, z2), (0, r1, 0), (-r, 0, 0)
    n = cross(rt, rq); s = math.sqrt(dot(n, n))
    if s == 0: return 0.0, 0.0               # a pole of the chart: no area
    n = scale(n, 1 / s)
    E, F, G, L, M, N = dot(rt, rt), dot(rt, rq), dot(rq, rq), dot(rtt, n), dot(rtq, n), dot(rqq, n)
    return (L * N - M * M) / (E * G - F * F), s          # K = (LN - M^2)/(EG - F^2), and sqrt(EG - F^2)
def total(pr, a, b, turn=TAU): return turn * simpson(lambda t: KdA(pr, t)[0] * KdA(pr, t)[1], a, b, 400)

# 1. The football: a truncated icosahedron (edge 1) pumped onto a sphere of radius RB.
RB = 0.11                                    # m: a size-5 ball, circumference 69.12 cm
RC = math.sqrt(1 + 9 * ((1 + math.sqrt(5)) / 2) ** 2) / 2   # corner (0, 1, 3 phi)/2, phi the golden ratio
def face(n):                                 # flat n-sided face: circumradius, apothem, distance from centre
    c = 1 / (2 * math.sin(PI / n))
    return c, c * math.cos(PI / n), math.sqrt(RC * RC - c * c)
def panel_curv(n):                           # chart: flat face point x -> ball point RB x/|x|; add K dA
    c, h, d = face(n)
    def strip(psi):
        def f(s):
            x, xs, xp = (s * h, s * h * math.tan(psi), d), (h, h * math.tan(psi), 0), (0, s * h / math.cos(psi) ** 2, 0)
            L = math.sqrt(dot(x, x))
            ps = scale(sub(scale(xs, L * L), scale(x, dot(x, xs))), RB / L ** 3)
            pp = scale(sub(scale(xp, L * L), scale(x, dot(x, xp))), RB / L ** 3)
            return math.sqrt(dot(cross(ps, pp), cross(ps, pp))) / RB ** 2     # K times sqrt(EG - F^2)
        return simpson(f, 0.0, 1.0, 120)
    return 2 * n * simpson(strip, 0.0, PI / n, 120)
def panel_angle(n):                          # corner angle between two seams, which are great-circle arcs
    c, h, d = face(n)
    p = [unit((c * math.cos(TAU * k / n), c * math.sin(TAU * k / n), d)) for k in (-1, 0, 1)]
    t = lambda w: sub(w, scale(p[1], dot(w, p[1])))      # tangent at p[1] toward w
    return ang(t(p[0]), t(p[2]))
print("ball radius m", f6(RB), "K 1/m^2", f6(K := 1 / RB ** 2), "area m^2", f6(4 * PI * RB * RB), "K x area", f6(K * 4 * PI * RB * RB), "H 1/m", f6(1 / RB))
tot = 0.0
for n, cnt, name in ((5, 12, "pentagon"), (6, 20, "hexagon")):
    a, ci = panel_angle(n), panel_curv(n)
    ex = n * a - (n - 2) * PI
    print(name, "corner deg", deg(a), "excess rad", f6(ex), "deg", deg(ex), "chart integral rad", f6(ci),
          "area cm^2", f6(ci / K * 1e4), "all", cnt, "deg", deg(cnt * ci))
    assert abs(ex - ci) < 1e-8
    tot += cnt * ci
aP, aH = panel_angle(5), panel_angle(6)
print("corner sum deg", deg(aP + 2 * aH))
assert abs(aP + 2 * aH - TAU) < 1e-12
V, E, F = 60, 90, 32
print("32 panels rad", f6(tot), "deg", deg(tot), "V-E+F", V - E + F, "2 pi chi", f6(TAU * (V - E + F)))
print("panels summed: 2 pi F - pi (sides 180) + 2 pi V", f6(TAU * F - PI * (5 * 12 + 6 * 20) + TAU * V))
print("flat-panel ball: defect deg", 360 - 108 - 240, "x 60 corners", 60 * 12, "rad", f6(60 * math.radians(12)), "flat sheet K dA", f6(total(lambda t: (t, 0, 1, 0, 0, 0), 0, 1)))
assert abs(tot - TAU * (V - E + F)) < 1e-8 and abs(60 * math.radians(12) - tot) < 1e-8

# 2. The half dome: sphere radius 60 m, rise 12 m, cut along a great circle through its top.
def half_dome(R, H):
    p0 = math.acos((R - H) / R); b, z0 = R * math.sin(p0), R * math.cos(p0)
    sph = lambda p: (R * math.sin(p), R * math.cos(p), R * math.cos(p), -R * math.sin(p), -R * math.sin(p), -R * math.cos(p))
    kdA = total(sph, 0.0, p0, PI)            # theta over half a turn
    kg_rim = dot((-b, 0.0, 0.0), cross(unit((b, 0.0, z0)), (0.0, b, 0.0))) / b ** 3   # g'' . (n x g') / |g'|^3
    m0, m1, m2 = (R * math.sin(0.3), 0.0, R * math.cos(0.3)), (R * math.cos(0.3), 0.0, -R * math.sin(0.3)), (-R * math.sin(0.3), 0.0, -R * math.cos(0.3))
    kg_mer = dot(m2, cross(unit(m0), m1)) / R ** 3
    corner = ang((z0, 0.0, -b), (0.0, 1.0, 0.0))         # arrive down the cut, leave along the rim
    return p0, b, kdA, kg_rim, kg_rim * PI * b, kg_mer, corner
p0, b, kdA, kgr, rim, kgm, corner = half_dome(R := 60.0, 12.0)
print("half dome: R m", f6(R), "rise m", f6(12.0), "rim radius m", f6(b), "K 1/m^2", f"{1 / R ** 2:.9f}", "integral K dA rad", f6(kdA), "deg", deg(kdA))
print("rim: phi0 deg", deg(p0), "k_g 1/m", f6(kgr), "cot(phi0)/R", f6(1 / (R * math.tan(p0))), "length m", f6(PI * b), "integral k_g ds rad", f6(rim), "deg", deg(rim))
print("cut: k_g", f6(kgm), "length m", f6(2 * R * p0), "turn at each corner deg", deg(corner))
print("total rad", f6(kdA + rim + 2 * corner), "deg", deg(kdA + rim + 2 * corner))
assert abs(kdA + rim + 2 * corner - TAU) < 1e-9
assert abs(kgr - 1 / (R * math.tan(p0))) < 1e-12 and abs(kgm) < 1e-12

# 3. A rugby ball and an inner tube, K from the two fundamental forms.
A, C = 0.095, 0.145                          # rugby ball: half-width, half-length (m)
rug = lambda t: (A * math.sin(t), C * math.cos(t), A * math.cos(t), -C * math.sin(t), -A * math.sin(t), -C * math.cos(t))
TA, TB = 0.30, 0.03                          # inner tube: centre circle and tube radius (m)
tube = lambda v: (TA + TB * math.cos(v), TB * math.sin(v), -TB * math.sin(v), TB * math.cos(v), -TB * math.cos(v), -TB * math.sin(v))
print("rugby ball: half-width m", f6(A), "half-length m", f6(C), "K tip", f6(KdA(rug, 1e-6)[0]), "C^2/A^4", f6(C * C / A ** 4), "K waist", f6(KdA(rug, PI / 2)[0]), "1/C^2", f6(1 / C ** 2))
rt, rc = total(rug, 0, PI), total(rug, 0, PI / 4)
print("rugby ball total rad", f6(rt), "tip cap to ring z", f6(C * math.cos(PI / 4)), "rad", f6(rc), "deg", deg(rc))
print("inner tube: centre circle m", f6(TA), "tube radius m", f6(TB), "K outer", f6(KdA(tube, 0)[0]), "K inner", f6(KdA(tube, PI)[0]), "K top", f6(KdA(tube, PI / 2)[0]))
to, ti = total(tube, -PI / 2, PI / 2), total(tube, PI / 2, 3 * PI / 2)
print("inner tube outer half deg", deg(to), "inner half", deg(ti), "total rad", f6(to + ti), "with |K|", f6(to - ti))
assert abs(rt - 2 * TAU) < 1e-8 and abs(to - 2 * TAU) < 1e-8 and abs(to + ti) < 1e-8

# 4. Meshes of flat triangles pinned to the surface: all curvature sits in the corners as angle defects.
def defects(pts, tris):
    d = [TAU] * len(pts)
    for t in tris:
        for k in range(3):
            o, p, q = pts[t[k]], pts[t[(k + 1) % 3]], pts[t[(k + 2) % 3]]
            d[t[k]] -= ang(sub(p, o), sub(q, o))
    edges = {tuple(sorted((t[k], t[(k + 1) % 3]))) for t in tris for k in range(3)}
    return d, len(pts) - len(edges) + len(tris)
def rugby_mesh(m):                           # m rings from tip to tip, 2m corners round each ring
    w = 2 * m
    P = [(0, 0, C)] + [(A * math.sin(j * PI / m) * math.cos(TAU * k / w), A * math.sin(j * PI / m) * math.sin(TAU * k / w),
                        C * math.cos(j * PI / m)) for j in range(1, m) for k in range(w)] + [(0, 0, -C)]
    ix = lambda j, k: 1 + (j - 1) * w + k % w
    T = [(0, ix(1, k), ix(1, k + 1)) for k in range(w)] + [(len(P) - 1, ix(m - 1, k + 1), ix(m - 1, k)) for k in range(w)]
    T += [t for j in range(1, m - 1) for k in range(w) for t in ((ix(j, k), ix(j + 1, k), ix(j + 1, k + 1)), (ix(j, k), ix(j + 1, k + 1), ix(j, k + 1)))]
    d, chi = defects(P, T)
    cap = d[0] + sum(d[ix(j, k)] for j in range(1, m // 4) for k in range(w)) + sum(d[ix(m // 4, k)] for k in range(w)) / 2
    return sum(d), chi, cap, len(P), len(T)
errs = []
for m in (16, 32):
    s, chi, cap, nv, nf = rugby_mesh(m)
    print(f"rugby mesh {m}: corners {nv} triangles {nf} chi {chi} defects rad", f6(s), "tip cap", f6(cap), "error", f6(cap - rc))
    assert abs(s - TAU * chi) < 1e-9 and chi == 2
    errs.append(cap - rc)
print("error ratio", f6(errs[0] / errs[1]))
assert abs(errs[1]) < abs(errs[0]) / 3
nt, mt = 24, 12                              # inner tube mesh: 24 rings of 12 corners
P = [((TA + TB * math.cos(TAU * j / mt)) * math.cos(TAU * k / nt), (TA + TB * math.cos(TAU * j / mt)) * math.sin(TAU * k / nt),
      TB * math.sin(TAU * j / mt)) for k in range(nt) for j in range(mt)]
q = lambda k, j: (k % nt) * mt + j % mt
d, chi = defects(P, [t for k in range(nt) for j in range(mt) for t in ((q(k, j), q(k + 1, j), q(k + 1, j + 1)), (q(k, j), q(k + 1, j + 1), q(k, j + 1)))])
print("tube mesh 24 x 12: chi", chi, "defects rad", f6(sum(d)), "most, least deg", deg(max(d)), deg(min(d)))
assert abs(sum(d)) < 1e-9 and chi == 0

print("breaks: half dome without k_g rad", f6(kdA + 2 * corner), "deg", deg(kdA + 2 * corner))
print("breaks: flat 180-degree panel sums rad", f6(12 * (5 * math.radians(108) - 3 * PI) + 20 * (6 * math.radians(120) - 4 * PI)))
print("breaks: mean curvature, football m", f6(4 * PI * RB), "Earth km", f6(4 * PI * 6371))
print("try: rugby ball half-length 0.20: K tip", f6(0.2 ** 2 / A ** 4), "total", f6(total(lambda t: (A * math.sin(t), 0.2 * math.cos(t), A * math.cos(t), -0.2 * math.sin(t), -A * math.sin(t), -0.2 * math.cos(t)), 0, PI)))
r18 = half_dome(R, 18.0)
print("try: dome rise 18 m: K dA", f6(r18[2]), "rim", f6(r18[4]), "total", f6(r18[2] + r18[4] + 2 * r18[6]))
print("ALL CHECKS PASS")
