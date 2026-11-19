# Levi-Civita connection -- the check behind the card.  Standard library only.
# The globe is a sphere of radius 6371 km.  Its Christoffel symbols at London
# come by three roads: the metric formula with numerical partials, the closed
# form, and the 3-D surface (tangential part of second derivatives).  Then the
# geometric number, how hard a due-east course bends, comes from two charts.
import math

R, LAT = 6371.0, 51.5074                   # km; London's latitude, degrees north
PHI = math.radians(90.0 - LAT)             # polar angle, measured down from the North Pole
H = 1e-4                                   # step for the numerical partials, radians

def clean(x):                              # no "-0.000000" in either language
    return 0.0 if abs(x) < 5e-10 else x

def polar(p):                              # chart 1: (phi, theta) -> g_ij
    return [[R * R, 0.0], [0.0, (R * math.sin(p[0])) ** 2]]

def mercator(p):                           # chart 2: (x, y) = (longitude, Mercator height)
    s = R / math.cosh(p[1])
    return [[s * s, 0.0], [0.0, s * s]]

def christoffel(metric, p, half=0.5, sign=-1.0):
    g = metric(p)
    det = g[0][0] * g[1][1] - g[0][1] * g[1][0]
    gi = [[g[1][1] / det, -g[0][1] / det], [-g[1][0] / det, g[0][0] / det]]
    dg = []                                # dg[l][i][j] = partial_l of g_ij
    for l in range(2):
        up, dn = list(p), list(p)
        up[l] += H
        dn[l] -= H
        gu, gd = metric(up), metric(dn)
        dg.append([[(gu[i][j] - gd[i][j]) / (2 * H) for j in range(2)] for i in range(2)])
    return [[[clean(sum(half * gi[k][l] * (dg[i][j][l] + dg[j][i][l] + sign * dg[l][i][j])
                        for l in range(2))) for j in range(2)] for i in range(2)] for k in range(2)]

def embed(p):                              # the globe in space, km
    u, v = p
    return [R * math.sin(u) * math.cos(v), R * math.sin(u) * math.sin(v), R * math.cos(u)]

def from_outside(p, h=H):                    # road 3: never touches the metric formula
    def d(f, i):
        def df(q):
            up, dn = list(q), list(q)
            up[i] += h
            dn[i] -= h
            return [(a - b) / (2 * h) for a, b in zip(f(up), f(dn))]
        return df
    r = [d(embed, i)(p) for i in range(2)]
    dot = lambda a, b: sum(x * y for x, y in zip(a, b))
    G = [[dot(r[a], r[b]) for b in range(2)] for a in range(2)]
    det = G[0][0] * G[1][1] - G[0][1] ** 2
    out = [[[0.0, 0.0], [0.0, 0.0]], [[0.0, 0.0], [0.0, 0.0]]]
    for i in range(2):
        for j in range(2):
            rij = d(d(embed, i), j)(p)
            b0, b1 = dot(rij, r[0]), dot(rij, r[1])
            out[0][i][j] = clean((G[1][1] * b0 - G[0][1] * b1) / det)
            out[1][i][j] = clean((G[0][0] * b1 - G[0][1] * b0) / det)
    return out

def bend(metric, gam, p, a):   # geodesic curvature along coordinate a; metric diagonal
    g, b = metric(p), 1 - a
    acc = gam[b][a][a] / g[a][a]           # the only sideways part of grad_e e, e = d_a / |d_a|
    return math.sqrt(g[b][b]) * abs(acc), acc

def deg1000(k):                            # turning, degrees per 1000 km flown
    return math.degrees(k * 1000.0)

names = ["phi", "theta"]
gp = christoffel(polar, [PHI, 0.0])
ge = from_outside([PHI, 0.0])
s, c = math.sin(PHI), math.cos(PHI)
closed = [[[0.0, 0.0], [0.0, -s * c]], [[0.0, c / s], [c / s, 0.0]]]
Y = math.asinh(math.tan(math.radians(LAT)))
gm = christoffel(mercator, [0.0, Y])
print(f"London: latitude {LAT:.4f} N, polar angle phi = {90 - LAT:.4f} deg = {PHI:.6f} rad")
print(f"sin phi = {s:.6f}, cos phi = {c:.6f}")
print(f"metric: g_phiphi = {R * R:.0f} km^2, g_thetatheta = {(R * s) ** 2:.0f} km^2")
print(f"partial_phi g_thetatheta = 2 R^2 sin cos = {2 * R * R * s * c:.0f} km^2")
print("Gamma^k_ij, chart (phi, theta): formula | from 3-D | closed form")
worst = 0.0
for k in range(2):
    for i in range(2):
        for j in range(i, 2):
            a, b, e = gp[k][i][j], ge[k][i][j], closed[k][i][j]
            worst = max(worst, abs(a - e), abs(b - e))
            print(f"  Gamma^{names[k]}_{names[i]}{names[j]} = {a:+.6f} | {b:+.6f} | {e:+.6f}")
n = 2
unknowns = sum(1 for k in range(n) for i in range(n) for j in range(n) if i <= j)    # Gamma^k_ij = Gamma^k_ji
equations = sum(1 for l in range(n) for i in range(n) for j in range(n) if i <= j)   # one per rate d_l g_ij
print(f"unknowns after symmetry {unknowns}, equations from keeping lengths {equations}")

def nudged(k, by):                         # the metric one small step along coordinate k
    q = [PHI, 0.0]
    q[k] += by
    return polar(q)

comp = max(abs((nudged(k, H)[i][j] - nudged(k, -H)[i][j]) / (2 * H)      # d_k g_ij, both directions
               - sum(gp[l][k][i] * polar([PHI, 0.0])[l][j] + gp[l][k][j] * polar([PHI, 0.0])[i][l]
                     for l in range(2))) / (R * R) for k in range(2) for i in range(2) for j in range(2))
mn = ["x", "y"]
print(f"Mercator chart at London: y = {Y:.6f}, tanh y = {math.tanh(Y):.6f}")
for k, i, j in [(0, 0, 1), (1, 0, 0), (1, 1, 1), (0, 0, 0)]:
    print(f"  Gamma^{mn[k]}_{mn[i]}{mn[j]} = {gm[k][i][j]:+.6f}")
kp, ap = bend(polar, gp, [PHI, 0.0], 1)
km, am = bend(mercator, gm, [0.0, Y], 0)
kx, _ = bend(polar, ge, [PHI, 0.0], 1)
kc = c / (s * R)
print(f"due-east course at London bends toward the pole: {'yes' if ap < 0 and am > 0 else 'no'}")
print(f"geodesic curvature, per km: polar chart {kp:.8f} | Mercator {km:.8f} | 3-D {kx:.8f} | cot(phi)/R {kc:.8f}")
print(f"turning over 1000 km: {kp * 1000:.5f} rad = {deg1000(kp):.2f} deg")
print("latitude, deg | turning, deg per 1000 km")
for lat in range(0, 90, 10):
    p = math.radians(90 - lat)
    print(f"  {lat:2d} | {deg1000(bend(polar, christoffel(polar, [p, 0.0]), [p, 0.0], 1)[0]):.2f}")
plain = bend(polar, [[[0.0] * 2] * 2] * 2, [PHI, 0.0], 1)[0]
k2 = bend(polar, christoffel(polar, [PHI, 0.0], half=1.0), [PHI, 0.0], 1)
k3 = christoffel(polar, [PHI, 0.0], sign=1.0)
print(f"mistake 1, plain partials, no Gamma: {deg1000(plain):.2f} deg per 1000 km, a straight parallel")
print(f"mistake 2, the 1/2 dropped: {k2[0]:.8f} per km, {deg1000(k2[0]):.2f} deg per 1000 km")
print(f"mistake 3, last sign flipped: Gamma^phi_thetatheta = {k3[0][1][1]:+.6f}, course bends toward the equator")
print(f"mistake 4, components read as shape: Gamma^phi_phiphi = {gp[0][0][0]:+.6f} but Gamma^y_yy = {gm[1][1][1]:+.6f}")
for d in (1.0, 0.1):
    print(f"mistake 5, near the pole: polar angle {d:.1f} deg, Gamma^theta_phitheta = {christoffel(polar, [math.radians(d), 0.0])[1][0][1]:.2f}")
print(f"  at the pole det g = {clean(polar([0.0, 0.0])[0][0] * polar([0.0, 0.0])[1][1]):.1f}: g^ij does not exist")
assert worst < 1e-7                                   # formula and 3-D agree with the closed form
assert abs(kp - kc) < 1e-10                          # polar chart against cot(phi)/R
assert abs(km - kc) < 1e-10                          # Mercator chart: same bending
assert abs(kx - kc) < 1e-10                          # 3-D road: same bending
assert comp < 1e-8                                   # the symbols keep lengths
assert all(gp[k][0][1] == gp[k][1][0] for k in range(2))   # no twist: symmetric
assert abs(k2[0] - 2 * kc) < 1e-10                   # dropping the 1/2 doubles it
assert k3[0][1][1] > 0                               # the flipped sign points it south
print("ALL CHECKS PASS")
