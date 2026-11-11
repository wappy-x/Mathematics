# Heat engines and Carnot efficiency -- the check behind the card.  Standard
# library only.  Boiler water at 90 C, room at 20 C, a heat pump scoring 4.
# Roads to the limit: (1) the formula 1 - Tc/Th; (2) an ideal-gas Carnot
# cycle simulated leg by leg, its work found by adding up p dV with Simpson's
# rule; (3) entropy bookkeeping, the largest work found by bisection.
from math import log, sqrt

K0 = 273.15                      # kelvin = degrees Celsius + 273.15
R = 8.314462618                  # molar gas constant, J/(mol K), NIST CODATA (exact)
TH, TC = 90.0 + K0, 20.0 + K0    # boiler water and room, in K
QH = 10.0                        # heat taken from the boiler water, kW
COP_REAL = 4.0                   # the heat pump's score: kW of heat per kW of electricity
GAP = 5.0                        # temperature gap across each heat exchanger, K

def carnot_eta(th, tc): return 1.0 - tc / th          # road 1, engine
def carnot_cop(th, tc): return th / (th - tc)         # road 1, heat pump (heating)

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def gas_cycle(th, tc, gamma, n=1.0, v1=0.010, v2=0.020):
    # road 2: one mole of ideal gas, hot isotherm v1->v2, adiabat down to tc,
    # cold isotherm, adiabat back up.  Work on each leg = integral of p dV.
    k = (th / tc) ** (1.0 / (gamma - 1.0))           # adiabat volume stretch
    v3, v4 = v2 * k, v1 * k
    p2, p4 = n * R * th / v2, n * R * tc / v4
    w12 = simpson(lambda v: n * R * th / v, v1, v2)                 # hot isotherm
    w23 = simpson(lambda v: p2 * (v2 / v) ** gamma, v2, v3)         # expand, cools
    w34 = -simpson(lambda v: n * R * tc / v, v4, v3)                # cold isotherm
    w41 = -simpson(lambda v: p4 * (v4 / v) ** gamma, v1, v4)        # squeeze, warms
    t3 = p2 * (v2 / v3) ** gamma * v3 / (n * R)                     # end of adiabat
    return w12, -w34, w12 + w23 + w34 + w41, t3                     # Qh, Qc, W, T3

def best_work(qh, th, tc):
    # road 3: largest W with total entropy change -qh/th + (qh - W)/tc >= 0
    lo, hi = 0.0, qh
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if -qh / th + (qh - mid) / tc >= 0 else (lo, mid)
    return lo

def tank_eta(th, tc, steps):
    # a tank of hot water cooled from th to tc, each slice of heat run through
    # a perfect engine at the tank's current temperature (midpoint rule)
    dt, w = (th - tc) / steps, 0.0
    for i in range(steps):
        w += dt * carnot_eta(th - (i + 0.5) * dt, tc)
    return w / (th - tc)

eta = carnot_eta(TH, TC)
mono = gas_cycle(TH, TC, 5.0 / 3.0)
dia = gas_cycle(TH, TC, 1.4)
w_bis = best_work(QH, TH, TC)
cop = carnot_cop(TH, TC)
cop_gap = carnot_cop(TH + GAP, TC - GAP)
tank_closed = 1.0 - TC * log(TH / TC) / (TH - TC)
tank_sim = tank_eta(TH, TC, 70000)
ca = 1.0 - sqrt(TC / TH)                          # Curzon-Ahlborn, best power
t_max = COP_REAL * TC / (COP_REAL - 1.0)          # hottest delivery a score of 4 allows

def show(label, value, unit=""):
    print(f"{label:<46}{value:>12.4f} {unit}".rstrip())

show("boiler water Th", TH, "K"); show("room Tc", TC, "K"); show("gap Th - Tc", TH - TC, "K")
show("1 Carnot efficiency, formula", eta)
show("2 gas cycle, monatomic: Qh", mono[0], "J"); show("  Qc", mono[1], "J"); show("  W", mono[2], "J")
show("  W / Qh", mono[2] / mono[0]); show("  gas temperature after adiabat", mono[3], "K")
show("2 gas cycle, diatomic: W / Qh", dia[2] / dia[0])
show("3 entropy bisection: best W from 10 kW", w_bis, "kW")
show("  formula: eta x 10 kW", eta * QH, "kW"); show("  heat dumped in room", QH - eta * QH, "kW")
show("heat pump limit Th/(Th - Tc)", cop); show("  same, from the gas cycle Qh / W", mono[0] / mono[2])
show("  fridge limit Tc/(Th - Tc)", TC / (TH - TC))
show("electricity for 10 kW of heat: perfect pump", QH / cop, "kW")
show("  pump scoring 4", QH / COP_REAL, "kW"); show("  electric heater", QH, "kW")
show("pump scoring 4 as share of its limit", COP_REAL / cop)
show("limit with 5 K exchanger gaps, 368.15/80", cop_gap)
show("  pump scoring 4 as share of that", COP_REAL / cop_gap)
show("hottest delivery a score of 4 allows", t_max, "K"); show("  in Celsius", t_max - K0, "C")
show("finite tank 90 -> 20 C, closed form", tank_closed); show("  same, stepped 70000 slices", tank_sim)
show("Curzon-Ahlborn, engine at best power", ca)
show("power station, 600 C steam to 35 C: Tc/Th", (35 + K0) / (600 + K0))
show("  nuclear, 285 C steam to 35 C: Tc/Th", (35 + K0) / (285 + K0))
show("wrong: Celsius efficiency 1 - 20/90", 1.0 - 20.0 / 90.0)
show("wrong: Celsius pump limit 90/70", 90.0 / 70.0)
show("wrong: tank treated as fixed 90 C", eta)
show("try: flow at 70 C, efficiency", carnot_eta(70 + K0, TC)); show("  pump limit", carnot_cop(70 + K0, TC))
show("try: source 5 C outdoors, pump limit", carnot_cop(TH, 5 + K0))
show("  pump scoring 4 as share", COP_REAL / carnot_cop(TH, 5 + K0))
show("try: 10 K exchanger gaps, limit", carnot_cop(TH + 10, TC - 10))
show("try: tank stepped 2 slices", tank_eta(TH, TC, 2))
flows = [40, 50, 60, 70, 80, 90, 100, 110, 120]
print("chart, flow C       " + " ".join(f"{t:6d}" for t in flows))
print("chart, pump limit   " + " ".join(f"{carnot_cop(t + K0, TC):6.2f}" for t in flows))
print("chart, pump score   " + " ".join(f"{COP_REAL:6.2f}" for t in flows))

assert abs(eta - 70.0 / 363.15) < 1e-12                     # formula vs hand arithmetic
assert abs(mono[2] / mono[0] - eta) < 1e-9                  # simulated gas cycle hits the limit
assert abs(mono[0] - R * TH * log(2.0)) < 1e-6              # hot leg vs n R Th ln(V2/V1), 1 mol
assert abs(mono[1] - R * TC * log(2.0)) < 1e-6              # cold leg vs n R Tc ln(V3/V4), 1 mol
assert abs(dia[2] / dia[0] - eta) < 1e-9                    # any gas: same limit
assert abs(mono[3] - TC) < 1e-9                             # adiabat really ends at the room
assert abs(w_bis - eta * QH) < 1e-9                         # entropy road agrees
assert abs(mono[0] / mono[2] - cop) < 1e-9                  # gas cycle reversed = pump limit
assert abs(tank_sim - tank_closed) < 1e-9                   # stepped tank vs closed form
assert tank_closed < eta                                    # a cooling tank allows less
assert COP_REAL < cop_gap < cop                             # real pump sits below both limits
assert abs(carnot_cop(t_max, TC) - COP_REAL) < 1e-9         # hottest delivery for a score of 4
print("ALL CHECKS PASS")
