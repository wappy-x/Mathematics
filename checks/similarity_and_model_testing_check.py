# Similarity and model testing -- the check behind the card.  Standard library
# only.  A quarter-scale cycling helmet sits in a wind tunnel.  Which tunnel
# speed, or which tunnel pressure, makes its drag predict the full-size
# helmet's drag, and which dimensionless groups cannot be matched together?
import math

R, GAMMA = 287.05, 1.4        # air: gas constant J/(kg K), ratio of specific heats
BETA, SUTH = 1.458e-6, 110.4  # Sutherland's law: kg/(m s K^0.5) and K
T, P0 = 293.15, 101325.0      # 20 C and sea-level pressure, Pa (US Std Atmosphere 1976)
MU = BETA * T ** 1.5 / (T + SUTH)    # viscosity, Pa s; does not depend on pressure
C = math.sqrt(GAMMA * R * T)         # speed of sound, m/s; does not depend on pressure
DP, UP, LAM = 0.22, 12.5, 0.25       # helmet width m, rider speed m/s, model scale
DM = LAM * DP

def rho(p):                          # ideal-gas density, kg/m^3
    return p / (R * T)

def reynolds(p, u, d):
    return rho(p) * u * d / MU

def cd(re):                          # stand-in drag law: White's smooth-sphere fit, Re <= 2e5
    return 24 / re + 6 / (1 + math.sqrt(re)) + 0.4

def drag(p, u, d):                   # newtons: dynamic pressure x frontal area x C_D
    return 0.5 * rho(p) * u * u * (math.pi * d * d / 4) * cd(reynolds(p, u, d))

def predict(fm, pm, um):             # similarity: equal C_D, so scale by rho U^2 D^2
    return fm * (rho(P0) * UP ** 2 * DP ** 2) / (rho(pm) * um ** 2 * DM ** 2)

def bisect(f, lo, hi):               # root finder, written out: f(lo) < 0 < f(hi)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)

def pct(a, b):
    return 100 * (a - b) / b

re_p, ma_p, f_p = reynolds(P0, UP, DP), UP / C, drag(P0, UP, DP)
print(f"inputs: R {R} J/(kg K), gamma {GAMMA}, beta {BETA * 1e6:.3f}e-6, S {SUTH} K, T {T} K, "
      f"p {P0:.0f} Pa, U {UP} m/s = {UP * 3.6:.1f} km/h")
print(f"air at {T - 273.15:.0f} C, 1 atm: rho {rho(P0):.4f} kg/m^3, mu {MU * 1e6:.3f} uPa s, "
      f"nu {MU / rho(P0) * 1e6:.3f} mm^2/s, c {C:.2f} m/s")
print(f"card 06's value for the same air, mu 1.82e-5 Pa s, is {pct(1.82e-5, MU):+.1f} % from Sutherland's")
print(f"full size: D {DP:.3f} m, U {UP:.1f} m/s, Re {re_p:.0f}, Ma {ma_p:.4f}, "
      f"C_D {cd(re_p):.4f}, drag {f_p:.4f} N, power {f_p * UP:.2f} W")
print(f"by hand: sqrt(Re) {math.sqrt(re_p):.2f}, 24/Re {24 / re_p:.5f}, 6/(1 + sqrt(Re)) "
      f"{6 / (1 + math.sqrt(re_p)):.5f}, q {0.5 * rho(P0) * UP ** 2:.2f} Pa, A {math.pi * DP ** 2 / 4:.5f} m^2")
print(f"model: D {DM:.3f} m, scale 1/{1 / LAM:.0f}")
# Case 1: atmospheric tunnel at the rider's own speed.
f1 = drag(P0, UP, DM)
print(f"case 1, 1 atm, {UP:.1f} m/s: Re {reynolds(P0, UP, DM):.0f}, Ma {UP / C:.4f}, "
      f"model drag {f1:.4f} N, predicts {predict(f1, P0, UP):.4f} N, "
      f"error {pct(predict(f1, P0, UP), f_p):+.2f} %, {(predict(f1, P0, UP) - f_p) * UP:.2f} W")
# Case 2: atmospheric tunnel, speed chosen to match Re.  Two roads to that speed.
u2_formula = UP * DP / DM
u2_root = bisect(lambda u: reynolds(P0, u, DM) - re_p, 1.0, 200.0)
f2 = drag(P0, u2_formula, DM)
print(f"case 2, 1 atm, Re matched: speed by formula {u2_formula:.6f} m/s, "
      f"by root finder {u2_root:.6f} m/s")
print(f"case 2: Re {reynolds(P0, u2_formula, DM):.0f}, Ma {u2_formula / C:.4f}, "
      f"model drag {f2:.4f} N, predicts {predict(f2, P0, u2_formula):.4f} N, "
      f"size of error {abs(pct(predict(f2, P0, u2_formula), f_p)):.9f} %")
# Case 3: pressurised tunnel at the rider's speed, so Ma matches; pressure matches Re.
p3_formula = P0 * DP / DM
p3_root = bisect(lambda p: reynolds(p, UP, DM) - re_p, P0, 20 * P0)
f3 = drag(p3_formula, UP, DM)
print(f"case 3, Ma matched at {UP:.1f} m/s: pressure by formula {p3_formula / P0:.6f} atm, "
      f"by root finder {p3_root / P0:.6f} atm")
print(f"case 3: Re {reynolds(p3_formula, UP, DM):.0f}, Ma {UP / C:.4f}, "
      f"model drag {f3:.4f} N, predicts {predict(f3, p3_formula, UP):.4f} N, "
      f"size of error {abs(pct(predict(f3, p3_formula, UP), f_p)):.9f} %")
# The clash: in one fixed air, Re wants U_m = U_p / LAM, Ma wants U_m = U_p.
print(f"same air: Re needs {UP / LAM:.1f} m/s, Ma needs {UP:.1f} m/s; both only at scale 1")
print(f"density change, about Ma^2/2: full size {ma_p ** 2 / 2 * 100:.2f} %, "
      f"Re-matched model {(u2_formula / C) ** 2 / 2 * 100:.2f} %, at Ma 0.3 {0.3 ** 2 / 2 * 100:.2f} %")
lam_min_formula = UP / (0.3 * C)
lam_min_scan = next(k / 10000 for k in range(1, 10001) if UP / (k / 10000) / C <= 0.3)
print(f"smallest scale keeping Ma <= 0.3 with Re matched at 1 atm: formula {lam_min_formula:.4f} "
      f"(1/{1 / lam_min_formula:.2f}), scan {lam_min_scan:.4f}")
print(f"outside the range: a 1/10 model needs {UP * 10:.0f} m/s, Ma {UP * 10 / C:.4f}; "
      f"a 20 m/s descent has Re {reynolds(P0, 20.0, DP):.0f}, past the fit's 200000")
print(f"fit's edge: the model's Re reaches 200000 at {200000 * MU / (rho(P0) * DM):.1f} m/s")
# Unit-change road: feet, pounds, minutes.  The numbers move; Re, Ma and C_D do not.
FT, LB, MIN = 0.3048, 0.45359237, 60.0
rho_i = rho(P0) / (LB / FT ** 3)
u_i, d_i, mu_i, c_i = UP / (FT / MIN), DP / FT, MU / (LB / (FT * MIN)), C / (FT / MIN)
f_i = f_p / (LB * FT / MIN ** 2)
re_i = rho_i * u_i * d_i / mu_i
cd_i = f_i / (0.5 * rho_i * u_i ** 2 * math.pi * d_i ** 2 / 4)
print(f"in ft, lb, min: U {u_i:.1f} ft/min, drag {f_i:.1f} lb ft/min^2, Re {re_i:.0f}, "
      f"Ma {u_i / c_i:.4f}, C_D {cd_i:.4f}")
# What breaks: three wrong recipes, each from the Re-matched or naive model.
print(f"mistake 1, force scaled by area alone: {f2 / LAM ** 2:.4f} N, error {pct(f2 / LAM ** 2, f_p):+.1f} %")
u_bad = UP * LAM
f_bad = drag(P0, u_bad, DM)
print(f"mistake 2, speed scaled the wrong way, {u_bad:.3f} m/s: Re {reynolds(P0, u_bad, DM):.0f}, "
      f"predicts {predict(f_bad, P0, u_bad):.4f} N, error {pct(predict(f_bad, P0, u_bad), f_p):+.2f} %")
print(f"mistake 3, 4 atm and 50 m/s together: Re {reynolds(p3_formula, u2_formula, DM):.0f}, "
      f"Re ratio {reynolds(p3_formula, u2_formula, DM) / re_p:.2f}")
# Figure points: the model's prediction against tunnel speed, and the two ratios.
print("figure, tunnel speed m/s -> predicted full-size drag N (truth " + f"{f_p:.3f})")
print("  " + ", ".join(f"{u}:{predict(drag(P0, u, DM), P0, u):.3f}" for u in range(10, 65, 5)))
print("figure, tunnel speed m/s -> Re_m/Re_p and Ma_m/Ma_p at 1 atm")
print("  " + ", ".join(f"{u}:{reynolds(P0, u, DM) / re_p:.2f}/{u / C / ma_p:.2f}" for u in range(10, 70, 10)))
assert abs(u2_root - u2_formula) < 1e-9 and abs(p3_root - p3_formula) < 1e-6   # two roads, two answers
assert abs(predict(f2, P0, u2_formula) - f_p) < 1e-12 * f_p                      # matched Re: model = truth
assert abs(predict(f3, p3_formula, UP) - f_p) < 1e-12 * f_p                      # complete similarity
assert abs(re_i - re_p) < 1e-6 * re_p and abs(cd_i - cd(re_p)) < 1e-9           # unit-free means unit-free
assert pct(predict(f1, P0, UP), f_p) > 1.0                                       # unmatched Re misleads
assert abs(lam_min_scan - lam_min_formula) < 1e-4                                # scan meets formula
print("ALL CHECKS PASS")
