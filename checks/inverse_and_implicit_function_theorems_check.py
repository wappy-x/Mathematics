# Inverse and implicit function theorems -- the check behind the card.  Nothing
# is imported.  One mole of gas: p in kPa, V in litres, T in kelvin, and
# F(p, V, T) = pV - nRT = 0.  Road 1 is the theorems' formula; road 2 solves
# F = 0 for V by halving and takes shrinking difference quotients.
n, R, P, T = 1.0, 8.314, 100.0, 300.0     # R in kPa L per (mol K); the known state
A, B = 364.0, 0.04267                      # van der Waals constants for carbon dioxide
def ideal(p, V, t): return p * V - n * R * t
def vdw(p, V, t): return (p + A * n * n / (V * V)) * (V - n * B) - n * R * t
def solve(F, p, t, lo=0.05, hi=500.0):     # F < 0 below the root, > 0 above it
    for _ in range(200):
        mid = (lo + hi) / 2
        if F(p, mid, t) < 0: lo = mid
        else: hi = mid
    return (lo + hi) / 2
V = solve(ideal, P, T)
Fp, FV, FT = V, P, -n * R                  # the three partials of pV - nRT
dVdT, dVdp = -FT / FV, -Fp / FV            # road 1: implicit function theorem
s, c = -n * R * T / (V * V), n * R / V     # Jacobian of (V, T) -> (p, T): [[s, c], [0, 1]]
inv_row = (1 / s, -c / s)                  # top row of its inverse matrix
print(f"state: n = {n:.0f} mol, p = {P:.0f} kPa, T = {T:.0f} K; V by halving {V:.6f} L; |F| = {abs(ideal(P, V, T)):.9f}")
print(f"partials: dF/dp = {Fp:.6f}, dF/dV = {FV:.6f}, dF/dT = {FT:.6f}")
print(f"road 1, implicit: dV/dT = {dVdT:.6f} L per K, dV/dp = {dVdp:.6f} L per kPa")
print(f"inverse theorem: Jacobian [[{s:.6f}, {c:.6f}], [0, 1]], det {s:.6f}; inverse top row {inv_row[0]:.6f}, {inv_row[1]:.6f}")
errs = []
for k in (1.0, 0.1, 0.01, 0.001):          # road 2: shrinking pressure steps
    q = (solve(ideal, P + k, T) - V) / k
    errs.append(q - dVdp)
    print(f"road 2, pressure step {k} kPa: quotient {q:.6f}, error {q - dVdp:.6f}")
qT = (solve(ideal, P, T + 1e-3) - solve(ideal, P, T - 1e-3)) / 2e-3
print(f"road 2, temperature: central quotient {qT:.6f} L per K")
lo, hi = 0.0, 10.0                         # largest pressure step within 0.001
for _ in range(60):
    mid = (lo + hi) / 2
    if (solve(ideal, P + mid, T) - V) / mid - dVdp < 0.001: lo = mid
    else: hi = mid
print(f"tolerance: every pressure step under {lo:.5f} kPa lands within 0.001 of {dVdp:.6f}")
lin, exact = 3 * dVdT + 2 * dVdp, solve(ideal, P + 2, T + 3) - V
print(f"3 K warmer and 2 kPa more: predicted change {lin:.6f} L, solved change {exact:.6f} L")
ps = [80, 90, 100, 110, 120]
print("chart, V on the 300 K isotherm:", ", ".join(f"{solve(ideal, p, T):.2f}" for p in ps))
print("chart, tangent line at 100 kPa:", ", ".join(f"{V + dVdp * (p - P):.2f}" for p in ps))
W = solve(vdw, P, T)                       # second case: no tidy formula for V
WV = P - A * n * n / (W * W) + 2 * A * B * n ** 3 / W ** 3
wq = (solve(vdw, P, T + 1e-3) - solve(vdw, P, T - 1e-3)) / 2e-3
print(f"CO2 (a = {A:.0f}, b = {B}) at the same state: V {W:.6f} L; dF/dV {WV:.6f}; dV/dT implicit {n * R / WV:.6f}, quotient {wq:.6f}")
Vc, Tc, pc = 3 * B, 8 * A / (27 * R * B), A / (27 * B * B)
Fc = pc - A / Vc ** 2 + 2 * A * B / Vc ** 3
Vs = solve(vdw, pc, Tc, 0.05, 1.0)
qc = [(solve(vdw, pc + k, Tc, 0.05, 1.0) - Vs) / k for k in (1.0, 0.001)]
print(f"CO2 critical point: V {Vc:.5f} L (halving: {Vs:.5f}), T {Tc:.2f} K, p {pc:.1f} kPa; |dF/dV| {abs(Fc):.9f}")
print(f"critical quotients for pressure steps 1 and 0.001 kPa: {qc[0]:.6f}, {qc[1]:.6f}")
print(f"mistake 1, minus dropped: dV/dT = {FT / FV:.6f}; mistake 2, ratio upside down: {-FV / FT:.6f}")
print(f"mistake 3, p = 0 and T = 0: F at V = 1, 10, 100 is {ideal(0, 1, 0):.0f}, {ideal(0, 10, 0):.0f}, "
      f"{ideal(0, 100, 0):.0f}; at T = 1 K it is {ideal(0, 1, 1):.3f} for every V")
assert abs(errs[-1]) < 1e-5 and 9 < errs[1] / errs[2] < 11        # quotients close on road 1
assert abs(inv_row[1] - qT) < 1e-8 and abs(dVdT - qT) < 1e-8      # both theorems vs solver
assert abs(n * R / WV - wq) < 1e-8                                 # CO2: formula vs solver
assert qc[1] / qc[0] > 50                                          # no finite rate at dF/dV = 0
print("ALL CHECKS PASS")
