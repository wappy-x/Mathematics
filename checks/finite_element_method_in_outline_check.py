# Finite elements in outline -- the check behind the card.  Standard library only.
# A 3 m steel cantilever (the 120 mm I) holds 1 kN at its tip.  Cut it into three
# 1 m beam elements, assemble one stiffness matrix, fix the wall, solve K u = F.
L, NE, P, E, G, RHO = 3.0, 3, 1000.0, 200e9, 9.80665, 7850.0  # m, pieces, N, Pa, m/s^2, kg/m^3
SIGMA_Y = 275e6                                               # S275 yield stress, Pa
h, b, tf, tw = 120.0, 64.0, 6.3, 4.4                          # the 120 mm I, mm
I = (2 * (b * tf**3 / 12 + b * tf * ((h - tf) / 2) ** 2) + tw * (h - 2 * tf) ** 3 / 12) * 1e-12
EI, W = E * I, I / (h / 2 * 1e-3)                             # N m^2, section modulus m^3
w_self = (2 * b * tf + (h - 2 * tf) * tw) * 1e-6 * RHO * G    # own weight, N per m

def k_formula(le):             # element stiffness, unknowns (v1, th1, v2, th2): road 1
    a, l = EI / le**3, le
    return [[12*a, 6*l*a, -12*a, 6*l*a], [6*l*a, 4*l*l*a, -6*l*a, 2*l*l*a],
            [-12*a, -6*l*a, 12*a, -6*l*a], [6*l*a, 2*l*l*a, -6*l*a, 4*l*l*a]]

def curv(s, le):               # second derivatives of the four cubic shape functions
    return [(-6 + 12*s) / le**2, (-4 + 6*s) / le, (6 - 12*s) / le**2, (-2 + 6*s) / le]

def k_energy(le, n=100):       # road 2: k_ij = integral of EI N_i'' N_j'' dx, by Simpson
    k = [[0.0] * 4 for _ in range(4)]
    for m in range(n + 1):
        wt, c = (1 if m in (0, n) else 4 if m % 2 else 2) * le / n / 3, curv(m / n, le)
        for i in range(4):
            for j in range(4):
                k[i][j] += wt * EI * c[i] * c[j]
    return k

def assemble(ne, le, add=True):  # each element adds its 4x4 block at its two nodes
    n = 2 * (ne + 1)
    K, ke = [[0.0] * n for _ in range(n)], k_formula(le)
    for e in range(ne):
        for i in range(4):
            for j in range(4):
                K[2*e+i][2*e+j] = (K[2*e+i][2*e+j] if add else 0.0) + ke[i][j]
    return K

def solve(A, rhs):             # Gaussian elimination with row swaps, then back substitution
    n = len(rhs)
    M = [A[i][:] + [rhs[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            M[r] = [M[r][k] - f * M[c][k] for k in range(n + 1)]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][k] * x[k] for k in range(i + 1, n))) / M[i][i]
    return x

def fem(ne, loads, add=True):  # fix the wall (drop v0, th0), solve for the free 2*ne
    K = assemble(ne, L / ne, add)
    return [0.0, 0.0] + solve([row[2:] for row in K[2:]], loads[2:]), K

def fd_tip(n):                 # finite differences on v'' = P(L - x)/EI, ghost point at the wall
    hh, v = L / n, [0.0, 0.0]
    v[1] = hh * hh * P * L / EI / 2
    for i in range(1, n):
        v.append(2 * v[i] - v[i - 1] + hh * hh * P * (L - i * hh) / EI)
    return v[n]

def exact(x): return P * x * x * (3 * L - x) / (6 * EI)        # closed-form sag, m
def tip_load(ne): return [0.0] * (2 * ne) + [P, 0.0]

print(f"cantilever: {L:.0f} m, 120 mm I, I = {I * 1e8:.2f} cm^4, EI = {EI:.0f} N m^2, tip load {P:.0f} N = {P / G:.1f} kg")
ke, k2 = k_formula(1.0), k_energy(1.0)
print("element k for 1 m, in units of EI/m^3:", " ".join(f"{ke[0][j] / EI:.0f}" for j in range(4)),
      "|", " ".join(f"{ke[1][j] / EI:.0f}" for j in range(4)))
assert max(abs(ke[i][j] - k2[i][j]) for i in range(4) for j in range(4)) < 1e-9 * EI
u, K = fem(NE, tip_load(NE))
print("assembled K, free rows, units EI/m^3:")
for row in K[2:]:
    print("  " + "".join(f"{x / EI:6.0f}" for x in row[2:]))
print(f"u in units of P m^3/EI = {P / EI * 1e3:.4f} mm:", " ".join(f"{x * EI / P:.4f}" for x in u[2:]))
for r in (2, 6):                               # two rows of K u = F, term by term
    print(f"row {r - 1} of K u:", " ".join(f"{K[r][c] * u[c] / P:+.0f}" for c in range(2, len(u)) if K[r][c]),
          f"= {round(sum(K[r][c] * u[c] for c in range(len(u))) / P)} P")
for i in range(1, NE + 1):
    print(f"node {i} at {i * L / NE:.2f} m: sag {u[2*i] * 1e3:6.3f} mm, slope {u[2*i+1]:.6f} rad,"
          f" exact {exact(i * L / NE) * 1e3:6.3f} mm")
tip = u[2 * NE]
d_energy, nn = 0.0, 300                                         # road 3: unit-load integral
for m in range(nn + 1):
    x = m * L / nn
    d_energy += (1 if m in (0, nn) else 4 if m % 2 else 2) * P * (L - x) ** 2 / EI * L / nn / 3
print(f"tip sag: elements {tip * 1e3:.4f} mm, PL^3/3EI {P * L**3 / (3 * EI) * 1e3:.4f} mm,"
      f" energy {d_energy * 1e3:.4f} mm")
assert abs(tip - P * L**3 / (3 * EI)) < 1e-9 and abs(d_energy - tip) < 1e-9
assert max(abs(u[2*i] - exact(i * L / NE)) for i in range(NE + 1)) < 1e-12
fw = [sum(K[r][c] * u[c] for c in range(len(u))) for r in range(2)]
print(f"wall reaction from K u: {-fw[0]:.1f} N up, {-fw[1]:.1f} N m; W = {W * 1e6:.2f} cm^3, stress at wall {-fw[1] / W / 1e6:.2f} MPa")
assert abs(-fw[0] - P) < 1e-6 and abs(-fw[1] - P * L) < 1e-6
for ne in (1, 2, 6):
    print(f"elements: {ne}, tip {fem(ne, tip_load(ne))[0][2 * ne] * 1e3:.4f} mm")
for n in (3, 30, 300):
    print(f"finite differences, {n} steps: tip {fd_tip(n) * 1e3:.4f} mm")
assert abs(fd_tip(300) - tip) / tip < 1e-4 and 0.01 < abs(fd_tip(3) - tip) / tip
def weight_tips(ne):           # own weight w per metre: consistent loads, and nodal forces only
    le, fq = L / ne, [0.0] * (2 * ne + 2)
    fl = fq[:]
    for e in range(ne):
        for i, f in enumerate((w_self * le / 2, w_self * le * le / 12, w_self * le / 2, -w_self * le * le / 12)):
            fq[2 * e + i] += f
        fl[2 * e] += w_self * le / 2
        fl[2 * e + 2] += w_self * le / 2
    return fem(ne, fq)[0][2 * ne], fem(ne, fl)[0][2 * ne]
le, (uw, ul) = L / NE, weight_tips(NE)
uw_exact = w_self * L**4 / (8 * EI)
print(f"own weight {w_self:.2f} N/m: tip {uw * 1e3:.3f} mm (consistent loads), exact wL^4/8EI {uw_exact * 1e3:.3f} mm")
assert abs(uw - uw_exact) < 1e-12
print(f"total tip {(tip + uw) * 1e3:.2f} mm against limit L/180 = {L / 180 * 1e3:.2f} mm")
rigid = [1.0, 0.0] * (NE + 1)
spin = [v for i in range(NE + 1) for v in (i * le, 1.0)]
for name, z in (("lift", rigid), ("spin", spin)):
    print(f"wrong: no supports, K times rigid {name} = {max(abs(sum(r[c] * z[c] for c in range(len(z)))) for r in K):.1f} N")
u_over = fem(NE, tip_load(NE), add=False)[0][2 * NE]
print(f"wrong: assembled by overwriting, not adding: tip {u_over * 1e3:.2f} mm")
print(f"wrong: own weight lumped as nodal forces only: tip {ul * 1e3:.3f} mm against {uw_exact * 1e3:.3f} mm")
print(f"wrong: finite differences on the same 3 pieces: tip {fd_tip(3) * 1e3:.2f} mm")
assert u_over < 0 < tip and abs(ul - uw_exact) > 0.02 * uw_exact
P_y = SIGMA_Y * W / L
print(f"outside the model: yield at P = {P_y:.0f} N; at 10000 N it says {10000 * L**3 / (3 * EI) * 1e3:.1f} mm,"
      f" {10000 * L / W / 1e6:.0f} MPa")
print(f"try: 5000 N tip {5 * tip * 1e3:.2f} mm, {5000 * L / W / 1e6:.0f} MPa;"
      f" L = 4 m tip {P * 64 / (3 * EI) * 1e3:.2f} mm against {4 / 180 * 1e3:.2f} mm;"
      f" 6 elements, own weight lumped {weight_tips(6)[1] * 1e3:.3f} mm")
print("figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps:",
      " ".join(f"{exact(0.25 * k) * 6e3:.1f}" for k in range(13)))
print("ALL CHECKS PASS")
