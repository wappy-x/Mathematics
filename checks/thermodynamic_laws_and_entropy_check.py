# Thermodynamic laws and entropy -- the check behind the card.  Standard library only.
# A bicycle pump: 300 cm^3 of air at 20 C and 1 atm, outlet shut, squeezed to 75 cm^3.
# Roads: closed forms; an RK4 walk along the stroke; Simpson for the slow stroke;
# a step-by-step entropy sum for the cool-down; the lost-work identity W_fast - W_slow = T0 S_gen.
from math import log, pi

R = 8.314462618                      # gas constant, J/(mol K), CODATA 2018 (exact)
CV = 2.5 * R                         # air as a diatomic ideal gas, J/(mol K)
P1, T1, T0 = 101325.0, 293.15, 293.15  # start pressure Pa, start temperature K, room K
V1, V2, BORE = 300e-6, 75e-6, 0.030  # barrel volumes m^3, barrel bore m
AREA = pi * BORE ** 2 / 4

def out(label, v, d, unit):
    print(f"{label:<42}{v:>12.{d}f} {unit}")

def stroke_rk4(cv, n, steps=2000):   # road 2: dT/dV = -R T/(cv V), dW/dV = -n R T/V, walked in V
    h = (V2 - V1) / steps
    f = lambda v, t: (-R * t / (cv * v), -n * R * t / v)
    v, t, w = V1, T1, 0.0
    for _ in range(steps):
        k1 = f(v, t); k2 = f(v + h / 2, t + h / 2 * k1[0])
        k3 = f(v + h / 2, t + h / 2 * k2[0]); k4 = f(v + h, t + h * k3[0])
        t += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        w += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        v += h
    return t, w

def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))

def fast(cv, ratio):                 # closed form: T V^(gamma-1) stays fixed, W = n cv (T2 - T1)
    n = P1 * V1 / (R * T1)
    t2 = T1 * ratio ** (R / cv)
    return t2, n * cv * (t2 - T1)

n = P1 * V1 / (R * T1)
r = V1 / V2
T2, W_fast = fast(CV, r)
p2 = n * R * T2 / V2
T2_rk, W_rk = stroke_rk4(CV, n)
W_slow = n * R * T0 * log(r)
W_slow_simp = simpson(lambda v: n * R * T0 / v, V2, V1)
Q_cool = n * CV * (T2 - T0)
dS_air = n * CV * log(T0 / T2)
m = 100000                           # road 2 for the entropy: add dQ/T over 100,000 small cooling steps
dS_air_sum = sum(n * CV * (-(T2 - T0) / m) / (T2 - (i + 0.5) * (T2 - T0) / m) for i in range(m))
dS_room = Q_cool / T0
S_gen = dS_air + dS_room
p3 = n * R * T0 / V2

out("air in the barrel", n * 1000, 4, "mmol")
out("barrel length for 300 cm^3, 30 mm bore", V1 / AREA * 100, 2, "cm")
out("barrel area", AREA * 1e6, 2, "mm^2")
out("tyre valve opens above, 7 bar gauge", (P1 + 7e5) / 1000, 1, "kPa")
out("cv, air, per mole", CV, 3, "J/(mol K)")
out("n cv, heat capacity of the air", n * CV * 1000, 2, "mJ/K")
out("4 to the power 0.4", r ** 0.4, 4, "")
out("fast stroke: end temperature", T2, 2, "K")
out("fast stroke: end temperature, RK4", T2_rk, 2, "K")
out("fast stroke: end temperature, Celsius", T2 - 273.15, 2, "C")
out("fast stroke: end pressure", p2 / 1000, 1, "kPa")
out("fast stroke: work on the air", W_fast, 2, "J")
out("fast stroke: work on the air, RK4", W_rk, 2, "J")
out("handle force at the end, fast", (p2 - P1) * AREA, 1, "N")
out("of the work, pushed by the outside air", P1 * (V1 - V2), 2, "J")
out("cool-down at 75 cm^3: heat to the room", Q_cool, 2, "J")
out("cool-down: end pressure", p3 / 1000, 1, "kPa")
out("cool-down: air entropy change", dS_air * 1000, 2, "mJ/K")
out("cool-down: air entropy, summed dQ/T", dS_air_sum * 1000, 2, "mJ/K")
out("cool-down: room entropy change", dS_room * 1000, 2, "mJ/K")
out("cool-down: entropy generated", S_gen * 1000, 2, "mJ/K")
out("slow stroke: work = heat to the room", W_slow, 2, "J")
out("slow stroke: work, Simpson", W_slow_simp, 2, "J")
out("slow stroke: air entropy change", -n * R * log(r) * 1000, 2, "mJ/K")
out("lost work, W_fast - W_slow", W_fast - W_slow, 2, "J")
out("lost work, T0 x S_gen", T0 * S_gen, 2, "J")
print("cool-down, step by step (mJ/K): air, room, total")
bars = []
for t in (T2, 450.0, 400.0, 350.0, 300.0, T0):
    a, b = n * CV * log(t / T2) * 1000, n * CV * (T2 - t) / T0 * 1000
    print(f"  air at {t:6.2f} K {a:>9.2f} {b:>9.2f} {a + b:>9.2f}")
    bars.append(int(36 * (a + b) / (S_gen * 1000) + 0.5))  # bar length, 36 blocks = the total
print("cool-down bars, blocks, 36 for the total:" + "".join(f"{k:4d}" for k in bars))
claim_a = n * CV * log(450.0 / T1) - n * R * log(r)
claim_b = -n * R * log(r) + 35.0 / T0
out("claim: insulated, ends at 450 K, total dS", claim_a * 1000, 2, "mJ/K")
out("claim: 35 J and back to 20 C, total dS", claim_b * 1000, 2, "mJ/K")
out("wrong: Celsius in T V^0.4 rule", (T1 - 273.15) * r ** 0.4, 2, "C")
out("wrong: Boyle for the fast stroke", P1 * r / 1000, 1, "kPa")
out("wrong: Boyle handle force", (P1 * r - P1) * AREA, 1, "N")
out("wrong: air's dS as -Q/T0, total", (-Q_cool / T0 + dS_room) * 1000, 2, "mJ/K")
out("wrong: sign of W flipped, end temperature", T1 - W_fast / (n * CV), 2, "K")
out("two stages of 2:1, cooled between", 2 * fast(CV, 2.0)[1], 2, "J")
out("diesel 18:1 from 20 C", fast(CV, 18.0)[0], 1, "K")
out("try: squeeze to 37.5 cm^3, end temperature", fast(CV, 8.0)[0], 1, "K")
out("try: helium, end temperature", fast(1.5 * R, r)[0], 1, "K")
out("try: helium, end pressure", n * R * fast(1.5 * R, r)[0] / V2 / 1000, 1, "kPa")
out("try: claim of 45 J, total dS", (-n * R * log(r) + 45.0 / T0) * 1000, 2, "mJ/K")
vols = [300, 250, 200, 150, 100, 75]
print("chart, volume cm^3      " + " ".join(f"{v:6d}" for v in vols))
print("chart, fast stroke kPa  " + " ".join(f"{P1 * (V1 / (v * 1e-6)) ** 1.4 / 1000:6.1f}" for v in vols))
print("chart, slow stroke kPa  " + " ".join(f"{P1 * V1 / (v * 1e-6) / 1000:6.1f}" for v in vols))

assert abs(T2_rk - T2) < 1e-6 and abs(W_rk - W_fast) < 1e-6, "RK4 walk must land on the closed form"
assert abs(W_slow_simp - W_slow) < 1e-6, "Simpson must land on n R T ln r"
assert abs(dS_air_sum - dS_air) < 1e-8, "summed dQ/T must land on n cv ln(T0/T2)"
assert abs((W_fast - W_slow) - T0 * S_gen) < 1e-9, "lost work equals T0 times entropy generated"
assert abs(p2 - P1 * r ** 1.4) < 1e-6, "ideal gas law and p V^gamma give the same end pressure"
assert S_gen > 0 and claim_a < 0 and claim_b < 0, "cooling allowed; both claims ruled out"
print("ALL CHECKS PASS")
