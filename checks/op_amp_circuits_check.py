# Op-amp circuits -- the check behind the card.  Standard library only.
# The radio's audio stage.  One op-amp part: open-loop gain A0 = 100,000 at DC and
# a 1 MHz gain-bandwidth product, so one internal pole at fa = 10 Hz; rails +/-12 V.
# Roads: (1) closed forms; (2) Kirchhoff's current law at the inverting input, with
# the op-amp as a gain block A(jw), solved as two complex equations (no feedback
# formula used); (3) an RK4 simulation in time of the op-amp's pole, wired up.
import math
A0, FT, RAIL = 100_000.0, 1.0e6, 12.0
FA = FT / A0                                  # open-loop corner frequency, Hz
WA = 2 * math.pi * FA                         # the same corner in rad/s
RF, R1 = 90e3, 10e3                           # the audio stage's two resistors, ohms
RD, CD = 75e3, 1e-9                           # de-emphasis: 75 kohm and 1 nF, so 75 us
INF = float("inf")

def opamp(f, a0=A0):                          # open-loop gain at f hertz
    return a0 / (1 + 1j * f / FA)

def par(z1, z2):                              # two impedances side by side
    return 1 / (1 / z1 + 1 / z2)

def node_solve(z1, zf, a, noninv):            # road 2, for 1 V in.  Unknowns v-, vout:
    va, vp = (0, 1) if noninv else (1, 0)     #   KCL: (v- - va)/z1 + (v- - vout)/zf = 0
    a11, a12, b1 = 1 / z1 + 1 / zf, -1 / zf, va / z1    # op-amp: a v- + vout = a v+
    return (a11 * a * vp - a * b1) / (a11 - a12 * a)    # Cramer's rule

def zcap(f):                                  # capacitor's impedance at f hertz
    return 1 / (2j * math.pi * f * CD)

def rk4(deriv, y, h, n, record=None):         # road 3: classic fourth-order Runge-Kutta
    t = 0.0
    for _ in range(n):
        k1 = deriv(t, y)
        k2 = deriv(t + h / 2, [a + h / 2 * b for a, b in zip(y, k1)])
        k3 = deriv(t + h / 2, [a + h / 2 * b for a, b in zip(y, k2)])
        k4 = deriv(t + h, [a + h * b for a, b in zip(y, k3)])
        y = [a + h / 6 * (p + 2 * q + 2 * r + s) for a, p, q, r, s in zip(y, k1, k2, k3, k4)]
        t += h
        if record is not None: record.append((t, y[0]))
    return y

def noninv_deriv(f, beta, sign=1.0):          # vout' = wa (A0 (v+ - v-) - vout), v- = beta vout
    return lambda t, y: [WA * (A0 * sign * (math.sin(2 * math.pi * f * t) - beta * y[0]) - y[0])]

def inv_c_deriv(vin, gf):                     # inverting, C (and conductance gf) in feedback
    def d(t, y):                              # y = [vout, u], u = vout - v- across C
        vn = y[0] - y[1]
        return [WA * (-A0 * vn - y[0]), -((vin(t) - vn) / RD + gf * y[1]) / CD]
    return d

def sine_amp(deriv, f, n_state, cycles=6):   # settled swing, by projection
    per = math.ceil(1 / f / 1e-7)             # time step at most 0.1 us
    rec, h = [], 1 / f / per
    rk4(deriv, [0.0] * n_state, h, cycles * per, rec)
    last = rec[-per:]
    s = sum(v * math.sin(2 * math.pi * f * t) for t, v in last) * 2 / per
    c = sum(v * math.cos(2 * math.pi * f * t) for t, v in last) * 2 / per
    return math.hypot(s, c), math.degrees(math.atan2(c, s))

def db(x): return 20 * math.log10(x)

beta = R1 / (R1 + RF)
g_ideal, g_fin = 1 + RF / R1, A0 / (1 + A0 * beta)
g_half = (A0 / 2) / (1 + A0 / 2 * beta)
g_node = node_solve(R1, RF, A0, True).real
inv_ideal, inv_fin = -RF / R1, -RF / R1 * A0 * beta / (1 + A0 * beta)
inv_node = node_solve(R1, RF, A0, False).real
f_cl = FA * (1 + A0 * beta)
lo, hi = 1e3, 1e7                             # road 2's -3 dB point, found by bisection
for _ in range(100):
    mid = math.sqrt(lo * hi)
    lo, hi = (mid, hi) if abs(node_solve(R1, RF, opamp(mid), True)) > g_fin / math.sqrt(2) else (lo, mid)
amp_cl, ph_cl = sine_amp(noninv_deriv(f_cl, beta), f_cl, 1)
print("op-amp: A0 = %.0f, gain-bandwidth %.0f Hz, open-loop corner fa = %.1f Hz" % (A0, FT, FA))
print("NON-INVERTING, Rf = 90 kohm, R1 = 10 kohm: feedback fraction beta = %.4f" % beta)
print("  ideal gain 1 + Rf/R1                     = %.4f" % g_ideal)
print("  finite A0: A0/(1 + A0 beta)               = %.6f" % g_fin)
print("  Kirchhoff, op-amp as a gain block          = %.6f" % g_node)
print("  loop gain A0 beta = %.0f, i.e. %.1f dB; voltage between inputs at 1 V out = %.1f uV"
      % (A0 * beta, db(A0 * beta), 1e6 / A0))
print("  A0 halved to %.0f: gain %.6f, change %.4f %% for a 50 %% change in A0"
      % (A0 / 2, g_half, 100 * (g_fin - g_half) / g_fin))
print("  closed-loop bandwidth fa (1 + A0 beta) = %.0f Hz; f_T x beta = %.0f Hz" % (f_cl, FT * beta))
print("  Kirchhoff -3 dB point, by bisection      = %.0f Hz" % lo)
print("  RK4 sine at %.0f Hz: settled swing %.4f V per V in, phase %.2f deg" % (f_cl, amp_cl, ph_cl))
print("  closed form there: %.4f V per V, -45.00 deg" % (g_fin / math.sqrt(2)))
print("  at 20 kHz, top of the audio band: gain %.4f, %.2f dB down"
      % (abs(node_solve(R1, RF, opamp(2e4), True)), db(g_fin / abs(node_solve(R1, RF, opamp(2e4), True)))))
print("INVERTING, same two resistors: ideal -Rf/R1 = %.4f, finite A0 = %.6f, Kirchhoff = %.6f"
      % (inv_ideal, inv_fin, inv_node))
print("  input resistance %.0f kohm; bandwidth set by 1/beta = 10, not 9: %.0f Hz" % (R1 / 1e3, f_cl))
fc = 1 / (2 * math.pi * RD * CD)
print("DE-EMPHASIS FILTER, Rin = Rf = 75 kohm, C = 1 nF: time constant %.0f us, corner %.2f Hz" % (RD * CD * 1e6, fc))
rows = []
for f in (1e3, fc, 1e4):
    ideal = 1 / math.sqrt(1 + (f / fc) ** 2)
    node = abs(node_solve(RD, par(RD, zcap(f)), opamp(f), False))
    sim, _ = sine_amp(inv_c_deriv(lambda t, f=f: math.sin(2 * math.pi * f * t), 1 / RD), f, 2, math.ceil(1.5e-3 * f) + 1)
    rows.append((ideal, node, sim))
    print("  %8.2f Hz: closed form %.4f (%.2f dB), Kirchhoff %.4f, RK4 %.4f" % (f, ideal, db(ideal), node, sim))
integ_10k = 1 / (2 * math.pi * 1e4 * RD * CD)
print("  above the corner it integrates: 1/(w RC) at 10 kHz = %.4f" % integ_10k)
print("INTEGRATOR, Rf removed, R = 75 kohm, C = 1 nF, 0.1 V held at the input")
slope = -0.1 / (RD * CD)
v_1ms = rk4(inv_c_deriv(lambda t: 0.1, 0.0), [0.0, 0.0], 2e-8, 50_000)[0]
k = 1 + 1 / (RD * CD * 2 * math.pi * FT)    # finite gain: the ramp is k times slower,
v_fin = slope / k * (1e-3 - 1 / (2 * math.pi * FT * k))   # and starts 1/(w_T k) late
print("  ramp -vin/(RC) = %.1f V/s; ideal output at 1 ms %.4f V" % (slope, slope * 1e-3))
print("  with the op-amp's finite gain: closed form %.4f V, RK4 %.4f V, %.2f %% short"
      % (v_fin, v_1ms, 100 * (1 - v_1ms / (slope * 1e-3))))
print("  reaches the -12 V rail after %.1f ms" % (RAIL / -slope * 1e3))
print("  a 1 mV input offset alone: drifts %.2f V/s, rail after %.2f s; with Rf back: %.1f mV"
      % (1e-3 / (RD * CD), RAIL / (1e-3 / (RD * CD)), 1e-3 * (1 + RD / RD) * 1e3))
p = WA * (A0 * beta - 1)                      # inputs swapped: the pole moves to +p
rec = []
rk4(lambda t, y: [WA * (A0 * beta * y[0] - y[0])], [1e-6], 1e-9, 40_000, rec)
t_rail = next(t for t, v in rec if v >= RAIL)
print("WHAT BREAKS")
print("  inputs swapped: formula -A/(1 - A beta) = %.4f, but pole at +%.0f rad/s" % (-A0 / (1 - A0 * beta), p))
print("    1 uV of noise reaches the +12 V rail: closed form %.2f us, RK4 %.2f us"
      % (math.log(RAIL / 1e-6) / p * 1e6, t_rail * 1e6))
print("  gain read as Rf/R1: %.4f instead of %.4f" % (RF / R1, g_ideal))
print("  inverting bandwidth from f_T / 9: %.0f Hz instead of %.0f Hz" % (FT / 9, f_cl))
print("  2 V peak into the gain-10 stage: wants %.1f V, rails clip it at %.1f V" % (2 * g_ideal, RAIL))
print("figure, schematic: Rf = %.0f kohm, R1 = %.0f kohm, gain %.0f" % (RF / 1e3, R1 / 1e3, g_ideal))
print("chart, Bode, f in Hz | open-loop dB | closed-loop dB")
for e in range(8):
    f = 10.0 ** e
    print("  %10.0f | %7.2f | %6.2f" % (f, round(db(abs(opamp(f))), 2) + 0.0, db(abs(node_solve(R1, RF, opamp(f), True)))))
assert abs(g_node - g_fin) < 1e-9 and abs(inv_node - inv_fin) < 1e-9        # road 2 = road 1
assert abs(lo - f_cl) < 1.0                                                   # -3 dB point
assert abs(amp_cl - g_fin / math.sqrt(2)) < 2e-3 and abs(ph_cl + 45) < 0.1    # road 3 = road 1
assert all(abs(i - n) < 2e-3 and abs(n - s) < 1e-4 for i, n, s in rows)       # filter, 3 roads
assert abs(v_1ms - v_fin) < 2e-4 and abs(v_1ms - slope * 1e-3) > 1e-3        # integrator ramp
assert abs(t_rail - math.log(RAIL / 1e-6) / p) < 2e-9                         # runaway time
assert 0 < g_fin - g_half < 2e-3
print("ALL CHECKS PASS")
