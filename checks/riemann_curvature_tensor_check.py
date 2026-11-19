# Riemann curvature tensor of the globe: the check behind the card. Standard library only.
# Five roads to one number, the sectional curvature at London: a closed form by hand,
# a finite-difference tensor in two different charts, a vector carried round London's
# latitude circle, and the shortfall of a circle's circumference against a flat chart.
import math

R = 6371.0                       # Earth's radius in km (the globe is modelled as a sphere)
LAT, LON = 51.5074, -0.1278      # London, degrees north and east
PHI, TH = math.radians(90 - LAT), math.radians(LON)   # polar angle from the North Pole, longitude

def sci(x, d=4):                 # scientific text, the same as Rust's {:.4e}
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"

def fx(x, d):                    # fixed text with no negative zero
    s = f"{x:.{d}f}"
    return s[1:] if s.startswith("-") and float(s) == 0 else s

def shift(x, k, s):
    return [x[i] + (s if i == k else 0.0) for i in range(2)]

def christoffel(metric, x, h):   # G[a][b][c] = Gamma^a_bc, from the metric alone
    g = metric(x); det = g[0][0] * g[1][1] - g[0][1] * g[1][0]
    gi = [[g[1][1] / det, -g[0][1] / det], [-g[1][0] / det, g[0][0] / det]]
    gp = [metric(shift(x, k, h)) for k in range(2)]; gm = [metric(shift(x, k, -h)) for k in range(2)]
    dg = [[[(gp[k][i][j] - gm[k][i][j]) / (2 * h) for j in range(2)] for i in range(2)] for k in range(2)]
    return [[[0.5 * sum(gi[a][l] * (dg[b][c][l] + dg[c][b][l] - dg[l][b][c]) for l in range(2))
              for c in range(2)] for b in range(2)] for a in range(2)]

def curvature(metric, x, h):     # returns (Rm(d1,d2,d2,d1), sectional curvature)
    G = christoffel(metric, x, h)
    Gp = [christoffel(metric, shift(x, k, h), h) for k in range(2)]
    Gm = [christoffel(metric, shift(x, k, -h), h) for k in range(2)]
    dG = [[[[(Gp[k][a][b][c] - Gm[k][a][b][c]) / (2 * h) for c in range(2)] for b in range(2)]
           for a in range(2)] for k in range(2)]
    def Rup(a, b, c, d):         # R^a_bcd = d_c G^a_db - d_d G^a_cb + G^a_ce G^e_db - G^a_de G^e_cb
        return (dG[c][a][d][b] - dG[d][a][c][b]
                + sum(G[a][c][e] * G[e][d][b] - G[a][d][e] * G[e][c][b] for e in range(2)))
    g = metric(x)
    rm = sum(g[0][e] * Rup(e, 1, 0, 1) for e in range(2))
    return rm, rm / (g[0][0] * g[1][1] - g[0][1] ** 2)

sphere = lambda x: [[R * R, 0.0], [0.0, (R * math.sin(x[0])) ** 2]]     # chart A: (phi, theta)
def stereo(x):                                                          # chart B: (u, v) in km
    lam = 2 * R * R / (R * R + x[0] ** 2 + x[1] ** 2)
    return [[lam * lam, 0.0], [0.0, lam * lam]]
polar = lambda x: [[1.0, 0.0], [0.0, x[0] ** 2]]                        # flat chart: (r, theta)

K = 1 / R ** 2
print(f"model: R = {R:.1f} km; London phi = {math.degrees(PHI):.4f} deg, theta = {math.degrees(TH):.4f} deg")
print(f"target 1/R^2 = {sci(K)} per km^2 = {sci(K * 1e-6)} per m^2")

# road 1: closed form, by hand
s, c = math.sin(PHI), math.cos(PHI)
G_tt, G_pt = -s * c, c / s       # Gamma^phi_thth, Gamma^th_phith
dG, quad = -(c * c - s * s), -G_tt * G_pt   # d/dphi of Gamma^phi_thth; minus Gamma^phi_thth Gamma^th_phith
Rup = dG + quad
Rm_A = R * R * Rup; det_A = R ** 4 * s * s
print(f"road 1 by hand: sin phi = {s:.6f}, cos phi = {c:.6f}")
print(f"  Gamma^phi_thth = {G_tt:.6f}, Gamma^th_phith = {G_pt:.6f}")
print(f"  d_phi Gamma = {dG:.6f}, Gamma*Gamma term = {quad:.6f}, Rm^phi_thphth = {Rup:.6f}")
print(f"  Rm_1221 = {sci(Rm_A)} km^2, det g = {sci(det_A)} km^4, sec = {sci(Rm_A / det_A)}")
assert abs(Rup - s * s) < 1e-12
assert abs(Rm_A / det_A - K) < 1e-12 * K

# roads 2 and 3: the tensor from the metric alone, by finite differences, in two charts
rho = R * math.tan(PHI / 2)
ptB = [rho * math.cos(TH), rho * math.sin(TH)]
print(f"chart B point: u = {ptB[0]:.3f} km, v = {ptB[1]:.3f} km")
errs = {}
for name, metric, pt, hs in [("A (phi,theta)", sphere, [PHI, TH], (2e-3, 1e-3)),
                             ("B stereographic", stereo, ptB, (10.0, 5.0))]:
    for h in hs:
        rm, k = curvature(metric, pt, h)
        errs[(name, h)] = abs(k - K) / K
        print(f"road chart {name}, step {h:g}: Rm_1221 = {sci(rm)}, sec*R^2 = {k * R * R:.6f}, rel err {sci(errs[(name, h)], 1)}")
        assert errs[(name, h)] < 1e-5
    ratio = errs[(name, hs[0])] / errs[(name, hs[1])]
    print(f"  halving the step cuts the error by {ratio:.1f}")
    assert 3.0 < ratio < 5.0
rm_B, _ = curvature(stereo, ptB, 5.0)
lam = 2 * R * R / (R * R + rho * rho)
print(f"  chart B by hand: lambda = {lam:.6f}, Rm_1221 = lambda^4/R^2 = {sci(lam ** 4 * K)} per km^2")
assert abs(rm_B - lam ** 4 * K) < 1e-5 * lam ** 4 * K
assert abs(rm_B - Rm_A) > 1e6

# road 4: carry a vector round London's latitude circle (RK4), compare with K times cap area
def carry(n):
    a, b = 1.0, 0.0               # components along unit south, unit east
    f = lambda a, b: (c * b, -c * a)
    for _ in range(n):
        dt = 2 * math.pi / n
        k1 = f(a, b); k2 = f(a + dt / 2 * k1[0], b + dt / 2 * k1[1])
        k3 = f(a + dt / 2 * k2[0], b + dt / 2 * k2[1]); k4 = f(a + dt * k3[0], b + dt * k3[1])
        a += dt / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); b += dt / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return math.atan2(b, a)
area = 2 * math.pi * R * R * (1 - c)
print(f"road 4: cap north of London = {sci(area)} km^2, sec * area = {math.degrees(area * K):.4f} deg")
for n in (24, 48):
    ang = carry(n)
    print(f"  carried with {n} steps: turned {math.degrees(ang):.4f} deg, angle/area = {sci(ang / area)}")
    assert abs(ang - area * K) < 1e-4
paris = 1 - math.cos(math.radians(90 - 48.846))
print(f"  Foucault, Paris: swing plane turns {360 * (1 - paris):.1f} deg per sidereal day, holonomy {360 * paris:.1f} deg")

# road 5: a circle of ground radius r round London, globe against flat chart
for r in (500.0, 250.0):
    C = 2 * math.pi * R * math.sin(r / R)
    est = 3 * (2 * math.pi * r - C) / (math.pi * r ** 3)
    print(f"road 5: r = {r:.0f} km: flat 2 pi r = {2 * math.pi * r:.3f}, globe = {C:.3f}, short by {2 * math.pi * r - C:.3f} km, sec est = {sci(est)}")
    assert abs(est - K) < 1e-3 * K

# the flat chart: Christoffel symbols are not zero, the curvature is
G = christoffel(polar, [1000.0, 0.3], 1.0)
rm_P, k_P = curvature(polar, [1000.0, 0.3], 1.0)
print(f"flat polar chart at r = 1000 km: Gamma^r_thth = {G[0][1][1]:.3f} km, Gamma^th_rth = {G[1][0][1]:.6f} per km, sec*R^2 = {fx(k_P * R * R, 6)}")
assert abs(G[0][1][1] + 1000) < 1e-6
assert abs(k_P) < 1e-6 * K

# how many independent numbers the tensor holds: formula against a count of pairs
for n in (2, 3, 4):
    N = n * (n - 1) // 2; f, cnt = n * n * (n * n - 1) // 12, N * (N + 1) // 2 - n * (n - 1) * (n - 2) * (n - 3) // 24
    print(f"dimension {n}: n^2(n^2-1)/12 = {f}, plane pairs minus Bianchi = {cnt}")
    assert f == cnt

# what breaks
print(f"break: drop the Gamma*Gamma term: sec = {sci(dG * R * R / det_A)} per km^2")
print(f"break: leave the index up: Rm^phi_thphth / det g = {sci(Rup / det_A)} per km^4")
print(f"break: report the component, not sec: {sci(Rm_A)} km^2")
print(f"break: other sign convention for Rm: sec = {sci(-K)} per km^2")
den = (R * R) * (R * R) - (R * R) ** 2      # X = Y = d_phi: |X|^2 |Y|^2 - g(X,Y)^2
print(f"break: X = Y, a plane of zero area: denominator = {den:.1f}, sec undefined")

# try changing
print(f"try: Moon R = 1737.4 km: sec = {sci(1 / 1737.4 ** 2)} per km^2")
s1 = math.sin(math.radians(1.0))
print(f"try: phi = 1 deg: Rm_1221 = {R * R * s1 * s1:.1f} km^2, sec = {sci(R * R * s1 * s1 / (R ** 4 * s1 * s1))}")
print(f"try: triangle of area 1,000,000 km^2: angle excess = {math.degrees(1e6 * K):.3f} deg")
print(f"survey triangle, 100 km sides: area {math.sqrt(3) / 4 * 1e4:.0f} km^2, sec * area = {math.degrees(math.sqrt(3) / 4 * 1e4 * K) * 3600:.1f} arcsec, law of cosines: {math.degrees(3 * math.acos(math.cos(100 / R) / (1 + math.cos(100 / R))) - math.pi) * 3600:.1f} arcsec")
print("ALL CHECKS PASS")
