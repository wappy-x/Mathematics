# Steady-state error and system type -- the check behind the card.  Standard library only.
# A room (200 min lag) heated by a radiator through a slow pipe (10 min lag), with a thermostat.
# Roads: the final-value formula; a heat balance at rest; an RK4 simulation.  The frequency
# response near zero checks the s -> 0 limit.  Time in minutes, temperature in degC, power in W.
U, KC, TR, TP = 100.0, 1900.0, 200.0, 10.0   # heat loss W/K, thermostat gain W/K, lags (min)
TI, QMAX = 30.0, 3000.0                      # integral time (min), radiator limit (W)

def sim(ti, t_end, th, q, i, out, r0=20.0, slope=0.0, front=None, qmax=None, dt=0.05):
    """RK4 on room temperature th, radiator output q, integral of error i.  Returns history."""
    def f(t, x):
        to = out if front is None or t < front[0] else front[1]
        e = r0 + slope * t - x[0]
        qc = KC * (e + (x[2] / ti if ti else 0.0))
        if qmax is not None: qc = min(max(qc, 0.0), qmax)
        return [(x[1] / U - (x[0] - to)) / TR, (qc - x[1]) / TP, e if ti else 0.0]
    x, hist = [th, q, i], [(0.0, th, r0)]
    for k in range(int(round(t_end / dt))):
        t = k * dt
        k1 = f(t, x)
        k2 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k1)])
        k3 = f(t + dt / 2, [a + dt / 2 * b for a, b in zip(x, k2)])
        k4 = f(t + dt, [a + dt * b for a, b in zip(x, k3)])
        x = [a + dt / 6 * (b + 2 * c + 2 * d + g) for a, b, c, d, g in zip(x, k1, k2, k3, k4)]
        hist.append(((k + 1) * dt, x[0], r0 + slope * (k + 1) * dt))
    return x, hist

def loop(w, ti):
    """L(jw): thermostat (with or without integral) times radiator pipe times room."""
    s = 1j * w
    ctrl = KC * (1 + 1 / (ti * s)) if ti else KC
    return ctrl / U / ((TR * s + 1) * (TP * s + 1))

def row(name, v, unit=""):
    print(f"{name:<44} {v:>11.6f} {unit}")

# ---- road 1: the formula, from the loop's constants ----
A = 20.0 - 0.0                      # the step the loop must hold: setpoint 20 degC above a 0 degC outdoors
K0 = KC / U                         # position constant L(0), type 0
KV = KC / U / TI                    # velocity constant lim s L(s), type 1, per minute
a = 2.0 / 60.0                      # ramp slope: 2 degC per hour, in degC per minute
row("type 0 position constant K0 = L(0)", K0, "dimensionless")
row("type 1 velocity constant Kv", KV, "1/min")
row("formula  P  step error A/(1+K0)", A / (1 + K0), "degC")
row("formula  PI ramp error a/Kv", a / KV, "degC")
row("formula  PI ramp lag in time 1/Kv", 1 / KV, "min")
# ---- road 2: heat balance at rest: thermostat power = heat lost through the walls ----
e_bal = U * A / (U + KC)            # KC*e = U*(20 - e - 0), solved for e
row("balance  P  step error", e_bal, "degC")
row("balance  P  power held at rest", KC * e_bal, "W")
row("balance  PI power held at rest", U * 20.0, "W")
# ---- road 3: simulation.  Integral switched off at 20 degC: the room sags to its P rest ----
x0, _ = sim(0, 360, 20.0, 2000.0, 0.0, 0.0)
row("sim      P  from 20 degC, error at 360 min", 20 - x0[0], "degC")
# P at its 19 degC rest, PI switched on at t = 0; cold front to -3 degC at 160 min
xP, hP = sim(0, 480, 19.0, 1900.0, 0.0, 0.0, front=(160, -3.0))
xI, hI = sim(TI, 480, 19.0, 1900.0, 0.0, 0.0, front=(160, -3.0))
for (t, p, r), (_, q, _) in list(zip(hP, hI))[::800]:
    print(f"chart, t {t:3.0f} min, P {p:5.2f}, PI {q:5.2f}, setpoint {r:5.2f}")
row("sim      P  error at 480 min, after the front", 20 - xP[0], "degC")
row("formula  P  error after the front 23/(1+K0)", 23.0 / (1 + K0), "degC")
row("sim      PI error at 480 min", 20 - xI[0], "degC")
row("sim      PI lowest room after the front", min(h[1] for h in hI[3200:]), "degC")
row("sim      PI radiator power at 480 min", xI[1], "W")
# ---- the s -> 0 limit, checked on the frequency response: E = S R with S = 1/(1+L) ----
w = 1e-5
row("freq     P  step error A*|S(jw)|", A * abs(1 / (1 + loop(w, 0))), "degC")
row("freq     PI step error A*|S(jw)|", A * abs(1 / (1 + loop(w, TI))), "degC")
row("freq     PI ramp error a*|S(jw)|/w", a * abs(1 / (1 + loop(w, TI))) / w, "degC")
# ---- ramp: night setback 14 degC rising to 22 degC at 2 degC/h; both loops start at rest ----
xR, _ = sim(TI, 240, 14.0, 1400.0, 1400.0 / KC * TI, 0.0, r0=14.0, slope=a)
xRp, _ = sim(0, 240, 14.0 - 14.0 / 20, 1400.0 * 19 / 20, 0.0, 0.0, r0=14.0, slope=a)
row("sim      PI ramp error at 240 min", 22.0 - xR[0], "degC")
row("sim      P  ramp error at 240 min", 22.0 - xRp[0], "degC")
row("formula  P  error if 22 degC were held", 22.0 / (1 + K0), "degC")
# ---- what breaks ----
ti_edge = K0 * TR * TP / ((1 + K0) * (TR + TP))   # cubic a2*a1 > a3*a0 (Routh) solved for Ti
row("stability edge for Ti", ti_edge, "min")
def worst(ti):          # largest error in each 120-minute window after the integral is switched on
    _, h = sim(ti, 360, 19.0, 1900.0, 0.0, 0.0)
    return [max(abs(20 - p[1]) for p in h[k - 2400:k]) for k in (2400, 4800, 7200)]
pU, pS = worst(5.0), worst(15.0)
for k, p, q in zip((120, 240, 360), pU, pS):
    row(f"sim      worst error to {k} min, Ti = 5 / 15 min", p, f"/ {q:.6f} degC")
pLo, pHi = worst(0.9 * ti_edge), worst(1.1 * ti_edge)
row("sim      worst error to 360 min, Ti = 0.9 / 1.1 edge", pLo[2], f"/ {pHi[2]:.6f} degC")
xS, _ = sim(TI, 1500, 20.0, 2000.0, 2000.0 / KC * TI, -15.0, qmax=QMAX)
row("sim      -15 degC, 3000 W cap, error at 1500 min", 20 - xS[0], "degC")
row("balance  -15 degC, power needed at 20 degC", U * 35.0, "W")
row("balance  -15 degC, 3000 W cap, error", 20 - (-15.0 + QMAX / U), "degC")
row("sim      -15 degC, integral term asks for", KC * xS[2] / TI, "W")
row("wrong: FVT on the unstable loop, Ti = 5 min", A * abs(1 / (1 + loop(w, 5.0))), "degC")
# ---- try changing ----
row("try: P, draughty room U = 150 W/K", 150 * A / (150 + KC), "degC")
row("try: P, thermostat gain 3900 W/K", U * A / (U + 3900.0), "degC")
row("try: PI ramp error, Ti = 15 min", a * 15.0 / K0, "degC")

assert abs(e_bal - (20 - x0[0])) < 1e-3                    # heat balance vs simulation
assert abs(A / (1 + K0) - A * abs(1 / (1 + loop(w, 0)))) < 1e-4   # formula vs the s -> 0 limit of S
assert abs(20 - xP[0] - 23.0 / (1 + K0)) < 1e-4            # cold front, P: formula vs simulation
assert abs(20 - xI[0]) < 1e-4                              # the integrator removes the offset
assert abs((22.0 - xR[0]) - a / KV) < 2e-4                 # ramp lag: formula vs simulation
assert abs(a * abs(1 / (1 + loop(w, TI))) / w - a / KV) < 1e-4    # ramp: the s -> 0 limit vs formula
assert pU[2] > 10 * pU[0] and pS[2] < pS[0] / 10           # simulated: Ti = 5 min grows, 15 min dies
assert pLo[2] > pLo[0] and pHi[2] < pHi[0]                 # Routh edge: just below it grows, just above it dies
assert abs((20 - xS[0]) - (20 - (-15.0 + QMAX / U))) < 1e-2   # saturated: heat balance vs simulation
print("all checks passed")
