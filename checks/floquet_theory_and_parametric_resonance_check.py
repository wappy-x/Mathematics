# Floquet theory -- the check behind the card.  Standard library only.
# Hill's equation x'' + (d + 0.1 cos t) x = 0, a swing pumped at twice its natural frequency.
# Two roads to the monodromy matrix M over one period 2 pi: RK4, and exact frozen-coefficient steps.
import math, cmath, functools
T, EPS, I = 2 * math.pi, 0.1, [[1.0, 0.0], [0.0, 1.0]]
def add(Y, K, c): return [[Y[i][j] + c * K[i][j] for j in range(2)] for i in range(2)]
def mul(X, Y): return [[X[i][0] * Y[0][j] + X[i][1] * Y[1][j] for j in range(2)] for i in range(2)]
def rk4(d, t1, n=4000, e=EPS):     # columns: starts (1, 0) and (0, 1); rows x and x'
    h, t, Y = t1 / n, 0.0, I
    f = lambda t, Y: [Y[1], [-(d + e * math.cos(t)) * y for y in Y[0]]]
    for _ in range(n):
        k1 = f(t, Y); k2 = f(t + h / 2, add(Y, k1, h / 2))
        k3 = f(t + h / 2, add(Y, k2, h / 2)); k4 = f(t + h, add(Y, k3, h))
        Y = add(add(add(add(Y, k1, h / 6), k2, h / 3), k3, h / 3), k4, h / 6); t += h
    return Y
def frozen(d, n=20000):             # coefficient held at its mid-step value: exact cos/sin step
    h, M = T / n, I
    for k in range(n):
        w = cmath.sqrt(d + EPS * math.cos((k + 0.5) * h))
        c, s = cmath.cos(w * h).real, (cmath.sin(w * h) / w).real
        M = mul([[c, s], [-(w * w).real * s, c]], M)
    return M
def expm(B, t, terms=60):           # I + Bt + (Bt)^2/2! + ...
    S, term = I, I
    for k in range(1, terms): term = [[v * t / k for v in r] for r in mul(term, B)]; S = add(S, term, 1.0)
    return S
tr, det = lambda M: M[0][0] + M[1][1], lambda M: M[0][0] * M[1][1] - M[0][1] * M[1][0]
fm = lambda M: "[[" + "], [".join(", ".join(f"{round(v, 4) + 0.0:.4f}" for v in r) for r in M) + "]]"
gap = lambda X, Y: max(abs(X[i][j] - Y[i][j]) for i in range(2) for j in range(2))
M1, M2, M3 = rk4(0.25, T), rk4(0.5, T), rk4(1.0, T)
for d, M in ((0.25, M1), (0.5, M2)):
    print(f"delta {d}: M = {fm(M)}, trace {tr(M):.4f}, frozen-step trace {tr(frozen(d)):.4f}, det {det(M):.6f}")
mu1 = (tr(M1) - math.sqrt(tr(M1) ** 2 - 4)) / 2; mu2 = 1 / mu1; mu3 = (tr(M3) + math.sqrt(tr(M3) ** 2 - 4)) / 2
print(f"delta 0.25 multipliers {mu1:.4f} and {mu2:.4f}, sum {mu1 + mu2:.4f}; growth exponent {math.log(-mu1) / T:.4f} per unit time")
ten, direct = functools.reduce(mul, [M1] * 10), rk4(0.25, 10 * T, 40000)
print(f"x after 10 periods from x = 1 at rest: M^10 {ten[0][0]:.3f}, RK4 straight through {direct[0][0]:.3f}, "
      f"(mu1^10 + mu2^10)/2 = {(mu1 ** 10 + mu2 ** 10) / 2:.3f}")
th = math.acos(tr(M2) / 2); B = [[v * th / (math.sin(th) * T) for v in r] for r in add(M2, I, -math.cos(th))]   # log M / T
print(f"delta 0.5 multipliers cos {th:.4f} +- i sin {th:.4f}, size 1; B = {fm(B)}; e^(B 2pi) = {fm(expm(B, T))}")
Pa, Pb = mul(rk4(0.5, 1.0, 1000), expm(B, -1.0)), mul(rk4(0.5, 1 + T, 5000), expm(B, -1 - T))
print(f"P(1) = {fm(Pa)}, P(1 + 2pi) = {fm(Pb)}")
grows = lambda d, e: abs(tr(rk4(d, T, 1000, e))) > 2
def edge(lo, hi, e):                # bisection on |trace M| = 2
    for _ in range(30): lo, hi = ((lo + hi) / 2, hi) if grows((lo + hi) / 2, e) == grows(lo, e) else (lo, (lo + hi) / 2)
    return (lo + hi) / 2
tongue = [(e, edge(0.05, 0.25, e), edge(0.25, 0.45, e)) for e in (0.05, 0.1, 0.15, 0.2, 0.25, 0.3)]   # stability chart
print("tongue edges, pump", "; ".join(f"{e:.2f}: {lo:.4f} to {hi:.4f}" for e, lo, hi in tongue))
print("first-order guess 1/4 -+ pump/2:", "; ".join(f"{0.25 - e / 2:.4f} to {0.25 + e / 2:.4f}" for e, lo, hi in tongue))
ds = [0.1 + 0.025 * k for k in range(17)]
print("chart delta", " ".join(f"{d:.3f}" for d in ds))
print("chart trace", " ".join(f"{tr(rk4(d, T, 1000)):.2f}" for d in ds))
fr = max(cmath.sqrt(-(0.25 + EPS * math.cos(k * T / 100))).real for k in range(100))
print(f"mistake 1, e^(averaged A * 2pi): trace {tr(expm([[0.0, 1.0], [-0.25, 0.0]], T)):.4f}; mistake 2, frozen stiffness {0.25 - EPS:.2f} to {0.25 + EPS:.2f}, largest frozen real part {fr:.4f}")
print(f"mistake 3, growth over 10 periods read as |trace|^10 = {abs(tr(M1)) ** 10:.1f}, not |mu|^10 = {abs(mu1) ** 10:.1f}")
print(f"pump at the natural frequency, delta 1: trace {tr(M3):.6f}, growth {mu3:.4f} per period, {mu3 ** 10:.2f} over 10")
assert gap(M1, frozen(0.25)) < 1e-6 and gap(M2, frozen(0.5)) < 1e-6 and abs(det(M1) - 1) < 1e-9 and abs(tr(frozen(1.0)) - tr(M3)) < 1e-7
assert abs(tr(M1) + 2.0986) < 1e-4 and abs(tr(M2) + 0.5753) < 1e-4 and all(abs(lo - 0.25 + e / 2) < e * e / 4 and abs(hi - 0.25 - e / 2) < e * e / 4 for e, lo, hi in tongue)
assert abs(ten[0][0] - direct[0][0]) < 1e-6 * abs(direct[0][0]) and abs((mu1 ** 10 + mu2 ** 10) / 2 - direct[0][0]) < 1e-6 and abs(mu1) > 1
assert gap(expm(B, T), M2) < 1e-9 and gap(Pa, Pb) < 1e-8             # Floquet form P(t) e^(Bt)
print("ALL CHECKS PASS")
