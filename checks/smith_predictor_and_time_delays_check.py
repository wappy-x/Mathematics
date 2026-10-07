# Time delays and the Smith predictor -- the check behind the card.  Standard library only.
# A shower mixer: the mixer outlet follows the controller with a 2 s lag; the water then
# spends 4 s in the pipe before the skin.  Roads: closed forms; a time-domain simulation with
# the delay held as a buffer of past samples; the frequency response with complex arithmetic.
import math, cmath
TAU, TH, DT = 2.0, 4.0, 0.005          # mixer lag (s), pipe delay (s), simulation step (s)
VOL, R0, STEP, FLUSH = 8.0 / 60 * 4.0, 30.0, 8.0, 3.0   # pipe volume (L), start (degC), step (K), flush (K)

def sim(kp, smith, th=TH, t_end=60.0, flush_at=None):
    """Skin temperature above 30 degC; PI with Ti = TAU, optional Smith predictor (model delay TH)."""
    a, n, nm = math.exp(-DT / TAU), round(th / DT), round(TH / DT)
    pipe, mpipe, m, mm, integ, out = [0.0] * n, [0.0] * nm, 0.0, 0.0, 0.0, []
    for k in range(round(t_end / DT)):
        y = pipe[k % n]                                   # water that left the mixer th seconds ago
        e = STEP - y - ((mm - mpipe[k % nm]) if smith else 0.0)
        u = kp * (e + integ / TAU)
        integ += e * DT
        d = FLUSH if flush_at is not None and k * DT >= flush_at else 0.0
        pipe[k % n], mpipe[k % nm] = m + d, mm
        m, mm = a * m + (1 - a) * u, a * mm + (1 - a) * u   # exact update of a 2 s lag, input held
        out.append(y)
    return out

def grows(kp, smith=False, th=TH):
    """True if the oscillation at 208-240 s is larger than at 112-144 s."""
    y = sim(kp, smith, th, 240.0)
    late, early = (max(abs(v - STEP) for v in y[round(s / DT):round((s + 32) / DT)]) for s in (208, 112))
    return late > early

def bisect(f, lo, hi, n=50):
    for _ in range(n):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if f(mid) else (mid, hi)
    return (lo + hi) / 2

def delay(w, pade=0):
    """e^(-jw TH), or its first- or second-order Pade stand-in."""
    x = 1j * w * TH
    return {0: cmath.exp(-x), 1: (1 - x / 2) / (1 + x / 2), 2: (1 - x / 2 + x * x / 12) / (1 + x / 2 + x * x / 12)}[pade]

def loop(w, kp):
    """L(jw) = PI * mixer * delay, with Ti = TAU so L = kp e^(-jw TH) / (jw TAU)."""
    s = 1j * w
    return kp * (1 + 1 / (TAU * s)) / (TAU * s + 1) * delay(w)

def row(name, v, unit=""):
    print(f"{name:<50} {v:>11.6f} {unit}")

# ---- the pipe: delay = volume / flow ----
row("pipe volume, 8 L/min for 4 s", VOL, "L")
for lpm in (8.0, 6.0, 5.0):
    row(f"pipe delay at {lpm:.0f} L/min", VOL / (lpm / 60.0), "s")
# ---- phase cost of the delay at crossover; Ti = TAU makes |L| = kp/(w TAU), so w_c = kp/TAU ----
KF = 2.0                                              # delay-free design: closed loop time constant 1 s
row("fast design Kp = 2: crossover w_c = Kp/tau", KF / TAU, f"rad/s; closed loop lag {TAU / KF:.3f} s")
row("phase eaten by delay at w_c, w_c*theta", math.degrees(KF / TAU * TH), "deg")
row("phase margin, fast design, 4 s delay", 90.0 - math.degrees(KF / TAU * TH), "deg")
KD = (math.pi / 2 - math.pi / 3) * TAU / TH           # detuned: w_c*theta = 30 deg leaves 60 deg
row("detuned Kp for 60 deg margin", KD, "")
wc = bisect(lambda w: abs(loop(w, KD)) < 1, 1e-3, 10.0)
row("freq     detuned crossover from |L| = 1", wc, "rad/s")
row("freq     detuned phase margin 180 + arg L", 180 + math.degrees(cmath.phase(loop(wc, KD))), "deg")
# ---- ultimate gain: three roads, then two Pade stand-ins ----
ku = math.pi * TAU / (2 * TH)
row("formula  ultimate gain pi*tau/(2*theta)", ku, "")
w180 = bisect(lambda w: loop(w, 1.0).imag > 0, 0.05, 0.6)   # first frequency where L(jw) is real, negative
row("freq     ultimate gain 1/|L(jw180)|", 1 / abs(loop(w180, 1.0)), "")
row("freq     ultimate period 2*pi/w180", 2 * math.pi / w180, "s")
ku_sim = bisect(grows, 0.5, 1.2, 22)
row("sim      ultimate gain, growth test", ku_sim, "")
y = sim(ku, False, TH, 200.0)
ups = [k * DT for k in range(round(100 / DT), len(y)) if y[k - 1] < STEP <= y[k]]
row("sim      period at the ultimate gain", (ups[-1] - ups[0]) / (len(ups) - 1), "s")
row("pade 1   Routh edge 2*tau/theta", 2 * TAU / TH, "")
routh2 = lambda k: (TAU * TH / 2 + k * TH ** 2 / 12) * (TAU - k * TH / 2) < (TAU * TH ** 2 / 12) * k
row("pade 2   edge, algebra / Routh on the cubic", TAU * (math.sqrt(21) - 3) / TH, f"/ {bisect(routh2, 0.1, 2.0):.6f}")
# ---- phase of the delay against its Pade stand-ins (chart) ----
for i in range(6):
    w = i * 0.2
    ph = [math.degrees(-w * TH)] + [math.degrees(cmath.phase(delay(w, p))) for p in (1, 2)]
    ph = [ph[0] + 0.0] + [(v - 360 if v > 1e-9 else v) + 0.0 for v in ph[1:]]   # unwrap: stand-ins only lag
    print(f"chart phase, w {w:5.3f} rad/s, exact {ph[0]:8.2f}, pade1 {ph[1]:8.2f}, pade2 {ph[2]:8.2f} deg")
# ---- step 30 -> 38 degC, flush (+3 K) at 27 s: detuned PI against Smith predictor at Kp = 2 ----
yd, ys = sim(KD, False, flush_at=27.0), sim(KF, True, flush_at=27.0)
for t in range(0, 46, 3):
    print(f"chart step, t {t:2d} s, detuned PI {R0 + yd[round(t / DT)]:6.2f}, Smith {R0 + ys[round(t / DT)]:6.2f} degC")
settle = lambda y, tol, end: max(k for k in range(round(end / DT)) if abs(y[k] - STEP) > tol) * DT + DT
row("formula  Smith 2% settling theta + ln(50)*tau/Kp", TH + math.log(50) * TAU / KF, "s")
row("sim      Smith 2% settling (0.16 K band)", settle(ys, 0.16, 27.0), "s")
row("sim      detuned PI 2% settling", settle(yd, 0.16, 27.0), "s")
row("sim      detuned PI peak", R0 + max(yd[:round(27 / DT)]), "degC")
row("sim      flush peak, Smith / detuned", R0 + max(ys), f"/ {R0 + max(yd):.2f} degC")
row("formula  Smith flush full theta / 2theta / back", TH, f"/ {2 * TH:.6f} / {2 * TH + math.log(15) * TAU / KF:.6f} s after")
full = [k * DT - 27.0 for k in range(round(27 / DT), len(ys)) if abs(ys[k] - STEP - FLUSH) < 1e-3]
row("sim      Smith flush full size (1 mK), from / to", full[0], f"/ {full[-1]:.6f} s after")
row("sim      Smith back within 0.2 K", settle(ys, 0.2, 60.0) - 27.0, "s after")
row("sim      detuned PI back within 0.2 K", settle(yd, 0.2, 60.0) - 27.0, "s after")
# ---- model error: the pipe's true delay is not the 4 s the predictor assumes ----
def edge(sign):            # frequency road: 1 + T(jw)(e^(-jw D) - 1) = 0 needs |1 - 1/T| = 1
    best, w, step = None, 0.001, 0.001
    g = lambda w: abs(1 - (1 + 1j * w * TAU / KF) * cmath.exp(1j * w * TH)) - 1
    while w < 20:
        if g(w) * g(w + step) < 0:
            r = bisect(lambda v: (g(v) > 0) != (g(w) > 0), w, w + step); assert abs(g(r)) < 1e-9   # rising or falling crossing
            d = (-cmath.phase(1 - (1 + 1j * r * TAU / KF) * cmath.exp(1j * r * TH))) % (2 * math.pi) / r
            d = d if sign > 0 else d - 2 * math.pi / r
            best = d if best is None or abs(d) < abs(best) else best
        w += step
    return TH + best
row("freq     Smith stable for true delay from / to", edge(-1), f"/ {edge(+1):.6f} s")
def sedge(a, b):           # bisect a delay, in samples of DT, between a and b to where the growth test changes
    ga = grows(KF, True, a * DT)
    while b - a > 1:
        a, b = ((a + b) // 2, b) if grows(KF, True, (a + b) // 2 * DT) == ga else (a, (a + b) // 2)
    return a, b
(lo, _), (_, hi2) = sedge(840, 1400), sedge(400, 800)   # 4.2 s stable, 7 s not; 2 s unstable, 4 s stable
row("sim      Smith stable for true delay from / to", hi2 * DT, f"/ {lo * DT:.6f} s")
def ratio(y):              # largest swing in 208-240 s over the largest in 176-208 s
    return max(abs(v - STEP) for v in y[round(208 / DT):]) / max(abs(v - STEP) for v in y[round(176 / DT):round(208 / DT)])
sw = {lpm: ratio(sim(KF, True, VOL / (lpm / 60.0), 240.0)) for lpm in (6.0, 5.0)}
for lpm in (6.0, 5.0):
    row(f"sim      Smith at {lpm:.0f} L/min, swing ratio per 32 s", sw[lpm], "")
row("formula  detuned PI tolerates delay up to", math.pi * TAU / (2 * KD), "s")
sw09 = ratio(sim(0.9, False, TH, 240.0))
row("sim      Kp = 0.9 no predictor, swing ratio per 32 s", sw09, "")

assert abs(ku_sim - ku) < 3e-3                         # simulation edge vs closed form
assert abs(1 / abs(loop(w180, 1.0)) - ku) < 1e-6        # frequency road vs closed form
assert abs(bisect(routh2, 0.1, 2.0) - TAU * (math.sqrt(21) - 3) / TH) < 1e-6   # Routh vs algebra
assert abs(settle(ys, 0.16, 27.0) - (TH + math.log(50) * TAU / KF)) < 0.05      # Smith: sim vs formula
assert abs(settle(ys, 0.2, 60.0) - 27.0 - (2 * TH + math.log(15) * TAU / KF)) < 0.05   # flush: sim vs formula
assert abs(lo * DT - edge(+1)) < 0.02       # model-error edge: sim vs frequency road
assert abs(hi2 * DT - edge(-1)) < 0.01      # ... and the lower edge
assert abs(180 + math.degrees(cmath.phase(loop(wc, KD))) - 60.0) < 1e-6        # margin: complex vs formula
assert abs(full[0] - TH) < 0.01 and abs(full[-1] - 2 * TH) < 0.01                # flush felt theta to 2*theta
assert sw[6.0] < 1 < sw[5.0] and sw09 > 1   # 5.33 s inside the edge, 6.40 s and Pade-1's Kp = 0.9 outside
print("all checks passed")
