# Free energies and Maxwell relations -- the check behind the card.  Standard
# library only.  Water boiling at 1 atm, then a sealed heating loop at 1.5 bar gauge.
# Roads: closed forms; bisection on the Gibbs gap; Legendre's minimum found by
# golden-section search; finite differences on explicit state functions; and the
# IAPWS-IF97 saturation curve as a measured-water reference.
from math import log, sqrt

R = 8.314462618        # molar gas constant, J/(mol K), NIST CODATA 2018 (exact)
K0 = 273.15            # kelvin = degrees Celsius + 273.15
P0 = 101325.0          # one atmosphere, Pa
DH = 40650.0           # heat to boil one mole at 1 atm (enthalpy of boiling), J/mol
DS = 108.9             # entropy of boiling, J/(mol K), as tabulated (four figures)
TB = 373.15            # measured boiling point at 1 atm, K
P_LOOP = P0 + 150000.0 # sealed loop: 1.5 bar on the gauge, absolute Pa
CV = 3.0 * R           # steam as a rigid ideal gas: 3R per mole at fixed volume
CP = CV + R            # ... and 4R at fixed pressure
VL = 18.80e-6          # liquid water at 100 C, m^3/mol (958.4 kg/m^3)

def if97_psat(t):      # IAPWS-IF97 region 4: saturation pressure of real water, Pa
    n = [0.11670521452767e4, -0.72421316703206e6, -0.17073846940092e2,
         0.12020824702470e5, -0.32325550322333e7, 0.14915108613530e2,
         -0.48232657361591e4, 0.40511340542057e6, -0.23855557567849, 0.65017534844798e3]
    th = t + n[8] / (t - n[9])
    a, b, c = th*th + n[0]*th + n[1], n[2]*th*th + n[3]*th + n[4], n[5]*th*th + n[6]*th + n[7]
    return (2.0 * c / (-b + sqrt(b*b - 4.0*a*c))) ** 4 * 1e6

def bisect(f, lo, hi):  # root of f between lo and hi, f(lo) and f(hi) of opposite sign
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if (f(mid) > 0) == (f(lo) > 0) else (lo, mid)
    return 0.5 * (lo + hi)

def gap(t, p, ds=DH / TB):  # G(vapour) - G(liquid) per mole, J/mol; vapour ideal
    return DH - t * ds + R * t * log(p / P0)

# ---- 1. boiling at 1 atm: the lower Gibbs energy wins ----
for tc in (90.0, 100.0, 110.0):
    print(f"gap at 1 atm, {tc:.0f} C: {DH - (tc + K0) * DS:+.1f} J/mol")
t_cross = DH / DS
t_cross_bis = bisect(lambda t: gap(t, P0, DS), 300.0, 450.0)
print(f"crossing with DS = 108.9: {t_cross:.2f} K; entropy that puts it at 373.15 K: {DH / TB:.3f} J/(mol K)")

# ---- 2. Legendre: G(T, p) = min over V of F(T, V) + p V, one mole of steam ----
V0 = R * TB / P0
def helm(t, v):         # F = U - T S, with U = CV T and S = CV ln(T/TB) + R ln(V/V0)
    return CV * t - t * (CV * log(t / TB) + R * log(v / V0))
def legendre_g(t, p):   # golden-section search for the minimising volume
    lo, hi, g = 1e-4, 1.0, (sqrt(5.0) - 1.0) / 2.0
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        lo, hi = (lo, b) if helm(t, a) + p * a < helm(t, b) + p * b else (a, hi)
    v = 0.5 * (lo + hi)
    return helm(t, v) + p * v, v
g0, v_atm = legendre_g(TB, P0)
g1, v_loop = legendre_g(TB, P_LOOP)
print(f"Legendre minimum: V at 1 atm = {v_atm * 1e3:.3f} L, at the loop = {v_loop * 1e3:.3f} L")
print(f"G(loop) - G(1 atm), vapour: search {g1 - g0:.2f} J/mol, R T ln(p/p0) {R * TB * log(P_LOOP / P0):.2f} J/mol")
print(f"G(loop) - G(1 atm), liquid: v dp = {VL * (P_LOOP - P0):.2f} J/mol")

# ---- 3. the four Maxwell relations for the steam, by finite differences ----
def T_SV(s, v): return TB * ((v / V0) ** (-R / CV)) * 2.718281828459045 ** (s / CV)
def T_Sp(s, p): return TB * ((p / P0) ** (R / CP)) * 2.718281828459045 ** (s / CP)
def S_TV(t, v): return CV * log(t / TB) + R * log(v / V0)
def S_Tp(t, p): return CP * log(t / TB) - R * log(p / P0)
def d(f, x, h): return (f(x + h) - f(x - h)) / (2.0 * h)
hs, hv, hp, ht = 1e-4, 1e-8, 1e-2, 1e-4
rel = [("(dT/dV)_S = -(dp/dS)_V, K/m^3", d(lambda v: T_SV(0.0, v), V0, hv),
        -d(lambda s: R * T_SV(s, V0) / V0, 0.0, hs), -R * TB / (CV * V0)),
       ("(dT/dp)_S = (dV/dS)_p, K/Pa", d(lambda p: T_Sp(0.0, p), P0, hp),
        d(lambda s: R * T_Sp(s, P0) / P0, 0.0, hs), R * TB / (CP * P0)),
       ("(dS/dV)_T = (dp/dT)_V, Pa/K", d(lambda v: S_TV(TB, v), V0, hv),
        d(lambda t: R * t / V0, TB, ht), R / V0),
       ("-(dS/dp)_T = (dV/dT)_p, m^3/K", -d(lambda p: S_Tp(TB, p), P0, hp),
        d(lambda t: R * t / P0, TB, ht), R / P0)]
for name, left, right, exact in rel:
    print(f"{name}: {left:.6e} | {right:.6e} | formula {exact:.6e}")
    assert abs(left - exact) < 1e-6 * abs(exact) and abs(right - exact) < 1e-6 * abs(exact)

# ---- 4. Clapeyron slope at 1 atm, three ways ----
cc = DH * P0 / (R * TB * TB)                         # Clausius-Clapeyron
clap = (DH / TB) / (R * TB / P0 - VL)                # Clapeyron, liquid volume kept
dp = 10.0                                            # slope of the gap = 0 curve
t_up, t_dn = (bisect(lambda t: gap(t, P0 + s * dp), 300.0, 450.0) for s in (1, -1))
curve = 2.0 * dp / (t_up - t_dn)
real = (if97_psat(TB + 0.01) - if97_psat(TB - 0.01)) / 0.02
print(f"dp/dT: Clausius-Clapeyron {cc:.1f} Pa/K, Clapeyron {clap:.1f}, gap curve {curve:.1f}, IF97 {real:.1f}")
print(f"IF97 boiling point at 1 atm: {bisect(lambda t: if97_psat(t) - P0, 360.0, 380.0) - K0:.3f} C; "
      f"volume gained on boiling, from IF97 slope: {(DH / TB) / real * 1e3:.3f} L/mol (ideal gas {V0 * 1e3:.3f})")

# ---- 5. the sealed loop at 1.5 bar gauge ----
t_closed = 1.0 / (1.0 / TB - R * log(P_LOOP / P0) / DH)
t_bis = bisect(lambda t: gap(t, P_LOOP), 300.0, 450.0)
t_if97 = bisect(lambda t: if97_psat(t) - P_LOOP, 373.0, 450.0)
t_lin = TB + (P_LOOP - P0) / cc
print(f"loop boils at: formula {t_closed - K0:.2f} C, Gibbs bisection {t_bis - K0:.2f} C, IF97 {t_if97 - K0:.2f} C")
print(f"margin over 90 C flow: {t_closed - K0 - 90.0:.1f} K sealed, {TB - K0 - 90.0:.1f} K open at 1 atm")

print(f"hand: ln(p/p0) = {log(P_LOOP / P0):.5f}; R ln(p/p0)/DH = {R * log(P_LOOP / P0) / DH:.4e} 1/K; "
      f"1/TB = {1.0 / TB:.4e} 1/K; T = {t_closed:.2f} K; DH p0 = {DH * P0:.4e}; R TB^2 = {R * TB * TB:.0f}")

# ---- 6. the integrated formula against real water, inside and outside the range ----
def p_cc(t): return P0 * 2.718281828459045 ** (-DH / R * (1.0 / t - 1.0 / TB))
def err(tc): return 100.0 * (p_cc(tc + K0) / if97_psat(tc + K0) - 1.0)   # pressure error, %
worst = max(range(100, 151), key=lambda tc: abs(err(tc)))
print(f"integrated formula, worst error from 100 to 150 C: {err(worst):+.2f}% at {worst} C")
for tc in (150.0, 200.0, 300.0):
    print(f"p_sat at {tc:.0f} C: formula {p_cc(tc + K0) / 1e3:.1f} kPa, IF97 {if97_psat(tc + K0) / 1e3:.1f} kPa, "
          f"error {err(tc):+.1f}%")

# ---- 7. chart points: the Gibbs gap from 80 C to 140 C ----
temps = [80.0 + 10.0 * i for i in range(7)]
print("chart, C       " + "".join(f"{tc:8.0f}" for tc in temps))
print("chart, 1 atm   " + "".join(f"{gap(tc + K0, P0):8.0f}" for tc in temps))
print("chart, loop    " + "".join(f"{gap(tc + K0, P_LOOP):8.0f}" for tc in temps))

# ---- 8. what breaks, and try changing ----
s_vp = d(lambda v: S_Tp(v * P0 / R, P0), V0, hv)     # (dS/dV) holding p, not T
print(f"held fixed: (dS/dV)_T = {R / V0:.2f} Pa/K, (dS/dV)_p = {s_vp:.2f} Pa/K")
def boil(p): return 1.0 / (1.0 / TB - R * log(p / P0) / DH) - K0, bisect(lambda t: if97_psat(t) - p, 300.0, 500.0) - K0
for name, p in (("loop at 3 bar gauge", P0 + 3e5), ("cooker at 1 bar gauge", P0 + 1e5), ("1600 m up, 84 kPa", 84000.0)):
    print("try, %s: formula %.2f C, IF97 %.2f C" % ((name,) + boil(p)))
print(f"try, IF97 vapour pressure rise per K at 15 C: {100 * (if97_psat(288.16) - if97_psat(288.14)) / 0.02 / if97_psat(288.15):.2f}%")
bad_c = DH * P0 / (R * 100.0 * 100.0)
print(f"break: Celsius in the slope {bad_c / 1e3:.1f} kPa/K; enthalpy alone at 140 C {DH:+.0f} J/mol "
      f"(Gibbs {gap(140.0 + K0, P0):+.0f}); straight-line loop {t_lin - K0:.1f} C")
print(f"derived: ideal slope {100 * (1 - cc / real):.1f}% low; crossing {t_cross - TB:.2f} K off; loop {t_closed - TB:.2f} K "
      f"above 1 atm, {t_closed - t_if97:.2f} K above IF97; Celsius slope x{bad_c / cc:.1f}; "
      f"(dS/dV) ratio {s_vp * V0 / R:.2f}; G rise ratio {(g1 - g0) / (VL * (P_LOOP - P0)):.0f}")

assert abs(t_cross_bis - t_cross) < 1e-9                      # bisection = DH/DS
assert abs((g1 - g0) - R * TB * log(P_LOOP / P0)) < 1e-6      # Legendre search = closed form
assert abs(v_atm - V0) < 1e-9 and abs(v_loop - R * TB / P_LOOP) < 1e-9
assert abs(curve - cc) < 1e-3 * cc                            # gap = 0 curve slope = formula
assert abs(t_bis - t_closed) < 1e-9                           # bisection = integrated formula
assert abs(if97_psat(300.0) / 1e6 - 0.353658941e-2) < 1e-11   # IF97 published test values
assert abs(if97_psat(500.0) / 1e6 - 0.263889776e1) < 1e-8
assert abs(t_closed - t_if97) < 0.5 and 0.01 < (real - cc) / real < 0.03 and abs(err(worst)) < 1.0
assert t_lin - t_if97 > 10.0                                  # the straight line overshoots
assert abs(s_vp - CP / V0) < 1e-6 * s_vp                      # at fixed p: c_p / V
print("ALL CHECKS PASS")
