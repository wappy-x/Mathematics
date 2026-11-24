# Stress in 3D -- the check behind the card.  Standard library only.
# One point in the web of a steel footbridge girder, in plane stress:
# sigma_x = 80 MPa, sigma_y = -40 MPa, tau_xy = 30 MPa.  The principal stresses
# and the largest shear, reached three independent ways, then Hooke's law in 3D.
import math
SX, SY, TXY = 80.0, -40.0, 30.0                # MPa
E, NU, SIGMA_Y = 200e3, 0.3, 275.0             # MPa, no unit, MPa (grade S275 yield)
G = E / (2 * (1 + NU))                         # shear modulus, MPa
DEG = 180 / math.pi

def tensor(sx, sy, txy, sz=0.0, txz=0.0, tyz=0.0):
    return [[sx, txy, txz], [txy, sy, tyz], [txz, tyz, sz]]

def matmul(A, B):
    C = [[0.0] * 3 for _ in range(3)]
    for i in range(3):
        for j in range(3):
            for k in range(3):
                C[i][j] += A[i][k] * B[k][j]
    return C

def transpose(A): return [[A[j][i] for j in range(3)] for i in range(3)]

def rotate(T, th):                             # the same stress, read on axes turned by th about z
    c, s = math.cos(th), math.sin(th)
    Q = [[c, s, 0.0], [-s, c, 0.0], [0.0, 0.0, 1.0]]   # rows: the new x', y', z axes
    return matmul(matmul(Q, T), transpose(Q))

def invariants(T):                             # trace, sum of 2x2 minors, determinant
    i1 = T[0][0] + T[1][1] + T[2][2]
    i2 = (T[0][0] * T[1][1] + T[1][1] * T[2][2] + T[2][2] * T[0][0]
          - T[0][1] ** 2 - T[1][2] ** 2 - T[0][2] ** 2)
    i3 = (T[0][0] * (T[1][1] * T[2][2] - T[1][2] ** 2) - T[0][1] * (T[0][1] * T[2][2] - T[1][2] * T[0][2])
          + T[0][2] * (T[0][1] * T[1][2] - T[1][1] * T[0][2]))
    return i1, i2, i3

def jacobi(T, sweeps=30):                      # road 3: eigenvalues of a symmetric 3x3,
    A = [row[:] for row in T]                  # by plane rotations that clear one off-diagonal each
    V = [[1.0 if i == j else 0.0 for j in range(3)] for i in range(3)]
    for _ in range(sweeps):
        for p, q in ((0, 1), (0, 2), (1, 2)):
            if abs(A[p][q]) < 1e-15:
                continue
            phi = 0.5 * math.atan2(2 * A[p][q], A[q][q] - A[p][p])
            J = [[1.0 if i == j else 0.0 for j in range(3)] for i in range(3)]
            J[p][p], J[q][q], J[p][q], J[q][p] = math.cos(phi), math.cos(phi), math.sin(phi), -math.sin(phi)
            A, V = matmul(matmul(transpose(J), A), J), matmul(V, J)
    order = sorted(range(3), key=lambda k: -A[k][k])
    return [A[k][k] for k in order], [[V[i][k] for i in range(3)] for k in order]

def mohr(sx, sy, txy):                         # road 1: centre, radius, principal stresses, angle
    C, R = (sx + sy) / 2, math.hypot((sx - sy) / 2, txy)
    return C, R, C + R, C - R, 0.5 * math.atan2(2 * txy, sx - sy)

def hooke(T):                                  # generalised Hooke's law, strains (gamma = engineering shear)
    sx, sy, sz = T[0][0], T[1][1], T[2][2]
    return ((sx - NU * (sy + sz)) / E, (sy - NU * (sz + sx)) / E, (sz - NU * (sx + sy)) / E, T[0][1] / G, T[1][2] / G, T[0][2] / G)

S = tensor(SX, SY, TXY)
C, R, s1, s2, thp = mohr(SX, SY, TXY)
z = lambda v: 0.0 if abs(v) < 1e-9 else v     # print a rounding speck as 0.00, not -0.00
fmt = lambda T: "[" + ", ".join("[" + ", ".join(f"{z(v):.2f}" for v in r) + "]" for r in T) + "]"
print(f"web point: sigma_x = {SX:.2f} MPa, sigma_y = {SY:.2f} MPa, tau_xy = {TXY:.2f} MPa, sigma_z = 0 (plane stress)")
print(f"stress tensor, MPa: {fmt(S)}")
print(f"road 1, Mohr's circle: centre {C:.2f} MPa, radius sqrt({(SX - SY) / 2:.2f}^2 + {TXY:.2f}^2) = {R:.4f} MPa")
print(f"road 1: C + R = {s1:.2f} MPa, C - R = {s2:.2f} MPa, theta_p = {thp * DEG:.2f} deg = {thp:.4f} rad,"
      f" tan 2theta_p = {math.tan(2 * thp):.2f}")
best_hi, best_lo, t_hi, t_lo, worst = (-1e9, 0), (1e9, 0), (-1e9, 0), (1e9, 0), 0.0
for k in range(18000):                         # road 2: turn the axes in 0.01 deg steps, 0 to 180 deg
    th = k * 0.01 / DEG
    T = rotate(S, th)
    best_hi, best_lo = max(best_hi, (T[0][0], k)), min(best_lo, (T[0][0], k))
    t_hi, t_lo = max(t_hi, (T[0][1], k)), min(t_lo, (T[0][1], k))
    worst = max(worst, abs(math.hypot(T[0][0] - C, T[0][1]) - R))   # Mohr: every turn lands on the circle
print(f"road 2, axes turned in 0.01 deg steps: largest normal {best_hi[0]:.2f} MPa at {best_hi[1] / 100:.2f} deg,"
      f" smallest {best_lo[0]:.2f} MPa at {best_lo[1] / 100:.2f} deg")
print(f"road 2: shear peaks {t_lo[0]:.2f} MPa at {t_lo[1] / 100:.2f} deg and {t_hi[0]:.2f} MPa at {t_hi[1] / 100:.2f} deg;"
      f" normal there {rotate(S, thp + math.pi / 4)[0][0]:.2f} MPa")
print(f"road 2: every turned point on the circle, worst miss under 1e-9 MPa: {'yes' if worst < 1e-9 else 'no'}")
lam, vec = jacobi(S)
print(f"road 3, Jacobi on the 3x3 tensor: eigenvalues {lam[0]:.2f}, {lam[1]:.2f}, {lam[2]:.2f} MPa;"
      f" sigma_1 axis ({vec[0][0]:.4f}, {vec[0][1]:.4f}, {vec[0][2]:.4f}) at {math.atan2(vec[0][1], vec[0][0]) * DEG:.2f} deg")
assert abs(best_hi[0] - s1) < 1e-6 and abs(best_lo[0] - s2) < 1e-6 and best_hi[1] == round(thp * DEG * 100)
assert abs(lam[0] - s1) < 1e-9 and abs(lam[2] - s2) < 1e-9 and abs(lam[1]) < 1e-9
assert abs(t_hi[0] - R) < 1e-6 and worst < 1e-9
tau_max = (lam[0] - lam[2]) / 2
print(f"largest shear in 3D, (sigma_max - sigma_min) / 2 = {tau_max:.2f} MPa, on planes 45 deg from the principal axes")
Tp = rotate(S, thp)
print(f"tensor on the principal axes, MPa: {fmt(Tp)}")
inv0, inv1 = invariants(S), invariants(rotate(S, 0.7))
print("invariants I1, I2, I3 before turning: " + ", ".join(f"{z(v):.2f}" for v in inv0)
      + "; after turning 0.7 rad: " + ", ".join(f"{z(v):.2f}" for v in inv1))
assert max(abs(a - b) for a, b in zip(inv0, inv1)) < 1e-9 and abs(Tp[0][1]) < 1e-9
cubic = [x ** 3 - inv0[0] * x ** 2 + inv0[1] * x - inv0[2] for x in lam]
print(f"eigenvalues solve lambda^3 - I1 lambda^2 + I2 lambda - I3 = 0 to 1e-6: {'yes' if max(map(abs, cubic)) < 1e-6 else 'no'}")
assert max(map(abs, cubic)) < 1e-6
ex, ey, ez, gxy, gyz, gxz = hooke(S)
print(f"Hooke: E = {E / 1e3:.0f} GPa, nu = {NU:.2f}, G = E / (2(1 + nu)) = {G / 1e3:.2f} GPa")
print(f"strains, microstrain: eps_x = {ex * 1e6:.2f}, eps_y = {ey * 1e6:.2f}, eps_z = {ez * 1e6:.2f}, gamma_xy = {gxy * 1e6:.2f},"
      f" gamma_yz = {gyz * 1e6:.2f}, gamma_xz = {gxz * 1e6:.2f}")
Ce, Re, e1, e2, the = mohr(ex * 1e6, ey * 1e6, gxy * 1e6 / 2)
print(f"strain circle, microstrain: centre {Ce:.2f}, half-difference {(ex - ey) * 1e6 / 2:.2f}, gamma_xy/2 {gxy * 1e6 / 2:.2f}, radius {Re:.2f}")
print(f"principal strains {e1:.2f} and {e2:.2f} microstrain at {the * DEG:.2f} deg: the same axes as the stresses")
lame = E * NU / ((1 + NU) * (1 - 2 * NU))
back = [lame * (ex + ey + ez) + 2 * G * e for e in (ex, ey, ez)] + [G * gxy]
print("back from strain to stress, inverse Hooke: " + ", ".join(f"{z(v):.2f}" for v in back) + " MPa")
assert abs(the - thp) < 1e-12 and max(abs(a - b) for a, b in zip(back, (SX, SY, 0.0, TXY))) < 1e-9
print("chart, theta deg  " + " ".join(f"{15 * k:7d}" for k in range(13)))
print("chart, sigma_x'   " + " ".join(f"{rotate(S, 15 * k / DEG)[0][0]:7.2f}" for k in range(13)))
print("chart, tau_x'y'   " + " ".join(f"{rotate(S, 15 * k / DEG)[0][1]:7.2f}" for k in range(13)))
W = rotate(S, 2 * thp)
print(f"wrong: biggest entry read as sigma_1 = {max(SX, SY):.2f} MPa (true {s1:.2f}), tau_xy as largest shear"
      f" {TXY:.2f} MPa (true {tau_max:.2f})")
print(f"wrong: axes turned by 2theta_p = {2 * thp * DEG:.2f} deg: sigma_x' = {W[0][0]:.2f} MPa, tau = {W[0][1]:.2f} MPa")
_, Rs, a1, a2, _ = mohr(80.0, 40.0, 30.0)
print(f"wrong: sigma_y = +40 MPa, in-plane shear {Rs:.2f} MPa, but principal {a1:.2f}, {a2:.2f}, 0.00 give"
      f" {a1 / 2:.2f} MPa out of plane")
print(f"wrong: one-way Hooke, eps_x = sigma_x / E = {SX / E * 1e6:.2f} microstrain (true {ex * 1e6:.2f}, {100 * (1 - SX / E / ex):.0f}% low),"
      f" eps_y {SY / E * 1e6:.2f} (true {ey * 1e6:.2f}), eps_z {S[2][2] / E * 1e6:.2f} (true {ez * 1e6:.2f})")
assert abs(W[0][0] - SX) < 1e-9 and a1 / 2 > Rs and SX / E < ex
s4 = mohr(4 * SX, 4 * SY, 4 * TXY)[2]
vm1 = math.sqrt(((lam[0] - lam[1]) ** 2 + (lam[1] - lam[2]) ** 2 + (lam[2] - lam[0]) ** 2) / 2)   # von Mises, card 11
assert abs(vm1 - math.sqrt(SX ** 2 - SX * SY + SY ** 2 + 3 * TXY ** 2)) < 1e-9
print(f"outside the model: load x4, stresses {4 * SX:.2f}, {4 * SY:.2f}, {4 * TXY:.2f} MPa: sigma_1 = {s4:.2f} MPa, but von Mises"
      f" {4 * vm1:.2f} MPa > {SIGMA_Y:.0f} MPa yield")
print(f"outside the model: first yield at x{SIGMA_Y / vm1:.2f} the load (Tresca x{SIGMA_Y / (2 * tau_max):.2f}); past that neither"
      f" the scaled stresses nor Hooke's eps_x = {4 * ex * 1e6:.2f} microstrain are real")
_, _, b1, b2, bth = mohr(SX, SX, TXY)
l3, _ = jacobi(tensor(SX, SY, TXY, txz=20.0))
print(f"try: tau_xy = 0 gives {SX:.2f}, {SY:.2f} MPa, largest shear {(SX - SY) / 2:.2f} MPa; sigma_y = 80 gives"
      f" {b1:.2f}, {b2:.2f} MPa at {bth * DEG:.2f} deg, largest shear {b1 / 2:.2f} MPa")
print(f"try: tau_xz = 20 MPa gives " + ", ".join(f"{v:.2f}" for v in l3) + f" MPa, largest shear {(l3[0] - l3[2]) / 2:.2f} MPa;"
      f" nu = 0 gives eps_x = {SX / E * 1e6:.2f} microstrain")
px = lambda s: 240 + 3 * s                     # figure: 3 px per MPa, tau drawn positive downward
py = lambda t: 250 + 3 * t
print(f"figure, 3 px/MPa: centre ({px(C):.1f}, {py(0):.1f}), radius {3 * R:.1f}, X ({px(SX):.1f}, {py(TXY):.1f}),"
      f" Y ({px(SY):.1f}, {py(-TXY):.1f})")
print(f"figure: sigma_1 ({px(s1):.1f}, 250.0), sigma_3 ({px(s2):.1f}, 250.0), origin = sigma_2 ({px(0):.1f}, 250.0), top ({px(C):.1f},"
      f" {py(-R):.1f}), bottom ({px(C):.1f}, {py(R):.1f}), small circles radius {3 * s1 / 2:.1f} and {-3 * s2 / 2:.1f}")
print("ALL CHECKS PASS")
