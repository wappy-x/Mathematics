import cmath, math
from itertools import permutations

PI, TURN = math.pi, 2 * math.pi

def p(ph, th):  # point on the unit globe: ph down from the North Pole, th east
    return (math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph))

def chern_by_integral(density, n):  # midpoint rule for (1/2pi) times the integral of F
    s, dph, dth = 0.0, PI / n, TURN / (2 * n)
    for i in range(n):
        for j in range(2 * n):
            s += density((i + 0.5) * dph, (j + 0.5) * dth) * dph * dth
    return s / TURN

def chern_by_lattice(state, n):  # overlaps round each grid square: no connection, no gauge
    s, dph, dth = 0.0, PI / n, TURN / (2 * n)
    for i in range(n):
        for j in range(2 * n):
            c = [state(a * dph, b * dth) for a, b in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))]
            loop = 1
            for k in range(4):
                loop *= sum(x.conjugate() * y for x, y in zip(c[k], c[(k + 1) % 4]))
            s += cmath.phase(loop)
    return s / TURN + 0.0

def winding(angle, m=720):  # whole turns made by an angle carried once round the equator
    tot, prev = 0.0, angle(0.0)
    for k in range(1, m + 1):
        cur = angle(TURN * k / m)
        tot += (cur - prev + PI) % TURN - PI
        prev = cur
    return tot / TURN

spin_half = lambda ph, th: (complex(math.cos(ph / 2)), cmath.exp(1j * th) * math.sin(ph / 2))

def level_frame(ph, th):  # (e_phi + i e_theta)/sqrt 2: a level frame as one complex vector
    ep = (math.cos(ph) * math.cos(th), math.cos(ph) * math.sin(th), -math.sin(ph))
    et = (-math.sin(th), math.cos(th), 0.0)
    return tuple(complex(a, b) / math.sqrt(2) for a, b in zip(ep, et))

def stereo_frame(w):  # d/d(Re w) of the inverse stereographic chart from the South Pole
    d = 1 + abs(w) ** 2
    return (2 / d - 4 * w.real ** 2 / d ** 2, -4 * w.real * w.imag / d ** 2, -4 * w.real / d ** 2)

def clutch_tangent(th):  # angle from the north-chart frame to the south-chart frame on the equator
    q = p(PI / 2, th)
    a, b = stereo_frame(complex(q[0], q[1])), stereo_frame(complex(q[0], -q[1]))
    b = (b[0], -b[1], -b[2])  # the south chart is the north chart after (x, y, z) -> (x, -y, -z)
    cr = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    return math.atan2(sum(u * v for u, v in zip(cr, q)), sum(u * v for u, v in zip(a, b)))

def b_form(ph, th):  # global 1-form b = z(x dy - y dx) + x(y dz - z dy), times 1/2; parts (b_ph, b_th)
    x, y, z = p(ph, th)
    vs = ((math.cos(ph) * math.cos(th), math.cos(ph) * math.sin(th), -math.sin(ph)),
          (-math.sin(ph) * math.sin(th), math.sin(ph) * math.cos(th), 0.0))
    return [0.5 * (z * (x * v[1] - y * v[0]) + x * (y * v[2] - z * v[1])) for v in vs]

def deformed(ph, th, h=1e-5):  # F density of the monopole connection plus b: F + db
    db = (b_form(ph + h, th)[1] - b_form(ph - h, th)[1] - b_form(ph, th + h)[0] + b_form(ph, th - h)[0]) / (2 * h)
    return 0.5 * math.sin(ph) + db

sign = lambda s: -1 if sum(1 for i in range(len(s)) for j in range(i) if s[j] > s[i]) % 2 else 1

def top_form(R, pf):  # e1234 coefficient of Pf(Omega) (pf True) or of tr(Omega ^ Omega)
    tot = 0.0
    for a, b, c, d in permutations(range(4)):
        if pf:
            t = sum(sign(s) * R[s[0]][s[1]][a][b] * R[s[2]][s[3]][c][d] for s in permutations(range(4))) / 8
        else:
            t = sum(R[i][j][a][b] * R[j][i][c][d] for i in range(4) for j in range(4))
        tot += sign((a, b, c, d)) * t / 4
    return tot + 0.0

pf4 = lambda m: m[0][1] * m[2][3] - m[0][2] * m[1][3] + m[0][3] * m[1][2]

print("part 1: the monopole (Hopf) line bundle over the globe")
F = lambda ph, th: 0.5 * math.sin(ph)
c20, c40 = chern_by_integral(F, 20), chern_by_integral(F, 40)
print(f"c1 by integrating F/2pi: 20 x 40 grid {c20:.9f}; 40 x 80 grid {c40:.9f}")
print(f"error ratio, coarse over fine: {(c20 - 1) / (c40 - 1):.4f}")
cap, south = 0.5 * (1 - math.cos(math.radians(40))), 0.5 * (1 + math.cos(math.radians(40)))
print(f"north gauge round 50N: {cap:.6f} turn; south gauge: {south:.6f} turn; sum {cap + south:.6f}")
c_wind, c_lat = winding(lambda th: th), chern_by_lattice(spin_half, 6)
print(f"c1 from the clutching angle at the equator: {c_wind:.6f}; from spin-half overlaps, 6 x 12 grid: {c_lat:.12f}")
box = (math.cos(math.radians(30)) - math.cos(math.radians(40))) * PI / 6
print(f"survey box: area {box * 6371 ** 2:.0f} km2, rim {6371 * (PI / 9 + PI / 6 * (0.5 + math.sin(math.radians(40)))):.0f} km; camera turn {math.degrees(box):.4f} deg; spin-half phase {math.degrees(box / 2):.4f} deg")
print("part 2: the tangent bundle (the camera's level frames)")
e_wind, e_lat = winding(clutch_tangent), chern_by_lattice(level_frame, 6)
e_int = chern_by_integral(lambda ph, th: math.sin(ph), 40)
print(f"Euler number from the clutching between stereographic frames: {e_wind:.6f}; from level-frame overlaps, 6 x 12 grid: {e_lat:.12f}")
print(f"Euler number from K dA / 2pi, 40 x 80 grid: {e_int:.9f}")
print("part 3: a different connection on the monopole bundle")
mid = (math.radians(35), math.radians(-15))
print(f"F density at 55N 15W: old {F(*mid):.6f}, new {deformed(*mid):.6f}")
d20, d40 = chern_by_integral(deformed, 20), chern_by_integral(deformed, 40)
print(f"c1 of the new connection: 20 x 40 grid {d20:.9f}; 40 x 80 grid {d40:.9f}")
print("part 4: invariant polynomials")
X = [[0.3j, 0.2 + 0.1j], [-0.2 + 0.1j, -0.7j]]
g = [[0.6, 0.8j], [0.8j, 0.6]]  # unitary, so g^-1 is its conjugate transpose
gi = [[g[j][i].conjugate() for j in range(2)] for i in range(2)]
mul = lambda A, B: [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
Y = mul(gi, mul(X, g))
cs = []
for nm, M in (("F", X), ("g^-1 F g", Y)):
    cs.append(((1j * (M[0][0] + M[1][1]) / TURN).real, (-(M[0][0] * M[1][1] - M[0][1] * M[1][0]) / TURN ** 2).real))
    print(f"{nm}: c1 part {cs[-1][0]:.6f}, c2 part {cs[-1][1]:.6f}, top-left entry {M[0][0].imag:.6f}i")
W = [[0, 1, 2, 3], [-1, 0, 4, 5], [-2, -4, 0, 6], [-3, -5, -6, 0]]
Wr = [[(-1 if (i == 0) != (j == 0) else 1) * W[i][j] for j in range(4)] for i in range(4)]
print(f"Pfaffian {pf4(W)}, after a reflection {pf4(Wr)}; Pfaffian squared {pf4(W) ** 2}")
print("part 5: the round 4-sphere, radius 1")
dl = lambda a, b: 1.0 if a == b else 0.0
R = [[[[dl(a, c) * dl(b, d) - dl(a, d) * dl(b, c) for d in range(4)] for c in range(4)] for b in range(4)] for a in range(4)]
pf_c, tr_c = top_form(R, True), top_form(R, False)
vol = {n: TURN * math.prod(sum(math.sin((i + 0.5) * PI / n) ** k for i in range(n)) * PI / n for k in (1, 2, 3)) for n in (20, 40)}
rm2 = sum(R[a][b][c][d] ** 2 for a in range(4) for b in range(4) for c in range(4) for d in range(4))
ric = [[sum(R[c][a][c][b] for c in range(4)) for b in range(4)] for a in range(4)]
ric2, sc = sum(ric[a][b] ** 2 for a in range(4) for b in range(4)), sum(ric[a][a] for a in range(4))
chi_pf, chi_gbc = pf_c * vol[40] / TURN ** 2, (rm2 - 4 * ric2 + sc ** 2) * vol[40] / (32 * PI ** 2)
chi_cells = sum((-1) ** k * math.comb(6, k + 1) for k in range(5))
print(f"Pfaffian of curvature: {pf_c:.6f} e1234; trace of Omega^Omega: {tr_c:.6f} e1234")
print(f"volume: 20 grid {vol[20]:.9f}; 40 grid {vol[40]:.9f}; exact 8pi^2/3 {8 * PI ** 2 / 3:.9f}")
print(f"|Rm|^2 {rm2:.0f}, |Ric|^2 {ric2:.0f}, S^2 {sc ** 2:.0f}; p1 from the trace: {-tr_c * vol[40] / (8 * PI ** 2) + 0.0:.6f}")
print(f"chi: from the Pfaffian {chi_pf:.6f}; from 4D Gauss-Bonnet-Chern {chi_gbc:.6f}; from cells {chi_cells}")
print("part 6: real line bundles over the circle")
mob = (1, -1)  # transition signs on the two overlaps of two arcs covering the circle
for nm, t in (("band", (1, 1)), ("Mobius", mob), ("Mobius squared", tuple(a * a for a in mob))):
    hol = t[0] * t[1]
    print(f"{nm}: section returns {hol:+d}, w1 = {(1 - hol) // 2}, curvature 0, two-sided copies {2 if hol == 1 else 1}")
print("what breaks")
print(f"north gauge alone round 89.9S: {0.5 * (1 - math.cos(math.radians(179.9))):.6f} turn hidden at the pole")
print(f"F without the 1/2pi: {c40 * TURN:.6f}; level frames on a 1 x 2 grid: {chern_by_lattice(level_frame, 1):.6f}")
assert abs(c40 - 1) < 1e-3 and abs(c20 - 1) > abs(c40 - 1)
assert round(c_wind) == round(c_lat) == 1 and abs(c_lat - 1) < 1e-9
assert round(e_wind) == round(e_lat) == 2 and abs(e_int - 2) < 1e-3
assert abs(d40 - 1) < 1e-3 and abs(deformed(*mid) - F(*mid) * (1 + sum(w * u * u for w, u in zip((1, -2, 1), p(*mid))))) < 1e-6
assert abs(cs[0][0] - cs[1][0]) < 1e-12 and abs(cs[0][1] - cs[1][1]) < 1e-12 and abs(X[0][0] - Y[0][0]) > 0.1
assert pf4(W) ** 2 == sum(sign(s) * math.prod(W[i][s[i]] for i in range(4)) for s in permutations(range(4)))
assert abs(pf_c - 3) < 1e-12 and abs(chi_pf - 2) < 1e-3 and abs(chi_gbc - chi_cells) < 1e-3 and max(abs(ric2 - 36), abs(sc - 12)) < 1e-12
print("ALL CHECKS PASS")
