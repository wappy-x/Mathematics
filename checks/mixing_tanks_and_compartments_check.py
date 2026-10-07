# Mixing tanks -- the check behind the card.  Standard library only.
# A 200 L brewing tank holds 4 kg of sugar.  Syrup at 0.05 kg/L flows in at
# 5 L/min and the stirred mix drains at 5 L/min, so S' = 0.25 - S/40.
# Road one: the integrating-factor answer.  Road two: Euler steps on the rate
# law itself.  Second case: a drug dripped into 40 L of body water.
import math

V, Q, C_IN, S0 = 200.0, 5.0, 0.05, 4.0            # L, L/min, kg/L, kg
TAU, S_INF = V / Q, V * C_IN                      # 40 min, 10 kg

def exact(t):                                     # S = 10 - 6 e^(-t/40)
    return S_INF + (S0 - S_INF) * math.exp(-t / TAU)

def euler(rate, y, t_end, h):                     # small steps along the slope
    t = 0.0
    for _ in range(round(t_end / h)):
        y, t = y + h * rate(t, y), t + h
    return y

def crossing(rate, y, level, h):                  # step until y reaches level
    t = 0.0
    while y < level:
        y, t = y + h * rate(t, y), t + h
    return t

tank = lambda t, s: Q * C_IN - Q * s / V          # kg/min in minus kg/min out
drug = lambda t, a: 20.0 - 5.0 * a / 40.0         # mg/h dripped in minus mg/h cleared
grow = lambda t, s: Q * C_IN - 4.0 * s / (V + t)  # drain cut to 4 L/min: tank fills
errs = [abs(euler(tank, S0, 60, h) - exact(60)) for h in (1, 0.5, 0.25)]
drug_12 = 160 * (1 - math.exp(-12 / 8))           # A = 160 (1 - e^(-t/8)) mg
grow_60 = 0.05 * 260 - 6 * (200 / 260) ** 4       # integrating factor (200 + t)^4
fixed_60 = 12.5 - 8.5 * math.exp(-60 / 50)        # wrong: volume held at 200 L
print(f"in {Q * C_IN:.2f} kg/min; out S/{TAU:.0f} kg/min, {Q * S0 / V:.2f} at t = 0 ({S0 / V:.2f} kg/L); net {tank(0, S0):.2f} kg/min")
print(f"S = {S_INF:.0f} - {S_INF - S0:.0f} e^(-t/{TAU:.0f}); settles at {S_INF:.2f} kg = {C_IN} kg/L x {V:.0f} L")
print("t (min)", " ".join(f"{t}" for t in range(0, 241, 20)))
print("S (kg) ", " ".join(f"{exact(t):.2f}" for t in range(0, 241, 20)))
print(f"S(40) = {exact(40):.4f} kg; S(60) = {exact(60):.4f} kg, {exact(60) / V:.4f} kg/L")
print(f"Euler h = 0.01 to t = 60: {euler(tank, S0, 60, 0.01):.4f} kg")
print("Euler error at t = 60, h = 1, 0.5, 0.25:", " ".join(f"{e:.4f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"S = 7 kg: formula 40 ln 2 = {TAU * math.log(2):.2f} min; Euler {crossing(tank, S0, 7, 0.001):.2f} min")
print(f"S = 9.70 kg: formula 40 ln 20 = {TAU * math.log(20):.2f} min; Euler {crossing(tank, S0, 9.7, 0.001):.2f} min")
print(f"drug: 20 mg/h into 40 L, cleared 5 L/h; settles at {20 / (5 / 40):.0f} mg = {20 / 5:.2f} mg/L; half-life 8 ln 2 = {8 * math.log(2):.2f} h")
print(f"drug at 12 h: formula {drug_12:.2f} mg; Euler {euler(drug, 0.0, 12, 0.001):.2f} mg; {drug_12 / 40:.2f} mg/L")
print(f"drug at 95% (152 mg): formula 8 ln 20 = {8 * math.log(20):.2f} h; Euler {crossing(drug, 0.0, 152, 0.0001):.2f} h")
print(f"drain 4 L/min, S(60): formula {grow_60:.2f} kg; Euler {euler(grow, S0, 60, 0.001):.2f} kg; in {V + 60:.0f} L")
print(f"mistake, volume held at 200 L with 4 L/min out: S(60) = {fixed_60:.2f} kg")
print(f"mistake, outflow 5S not 5S/200: settles at {euler(lambda t, s: 0.25 - 5 * s, S0, 60, 0.01):.2f} kg")
print(f"mistake, drain at the feed's 0.05 kg/L: S(60) = {euler(lambda t, s: 0.25 - 5 * 0.05, S0, 60, 0.01):.2f} kg")
print(f"mistake, start from a clean tank: S(60) = {S_INF * (1 - math.exp(-60 / TAU)):.2f} kg")
assert abs(euler(tank, S0, 60, 0.01) - exact(60)) < 1e-3         # road two meets road one
assert 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2  # error halves: order one
assert abs(euler(drug, 0.0, 12, 0.001) - drug_12) < 1e-2        # the drug, both roads
assert abs(euler(grow, S0, 60, 0.001) - grow_60) < 1e-3         # unequal flows, both roads
print("ALL CHECKS PASS")
