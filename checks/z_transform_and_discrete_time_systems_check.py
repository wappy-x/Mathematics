# The z-transform -- the check behind the card.  Standard library only.
# A soldering-iron tip on a digital thermostat that updates every T = 0.1 s.
#   tip:        y[n+1] = a y[n] + b u[n]     y: tip temperature change (degC), u: heater power change (W)
#   thermostat: u[n]   = K (r - y[n-1])      it acts on the reading taken one tick earlier
#   transform:  H(z) = b K z / (z^2 - a z + b K)
# Step response by three roads: the loop itself; partial fractions over the poles;
# the inverse transform as a contour integral.  Stability by roots, by Jury's test, by running it.
import math, cmath

T, Cth, Rth, P_idle, P_max = 0.1, 2.5, 20.0, 16.5, 80.0   # s, J/degC, degC/W, W, W
a, b = 1 - T / (Rth * Cth), T / Cth                       # share kept per tick; degC per W per tick
K, r0 = 12.5, 5.0                                         # W/degC; setpoint raised 5 degC

def loop(K, r, ticks, b=b, d=0.0, lo=-math.inf, hi=math.inf, a=a):   # the firmware
    y, u = [0.0, 0.0], []                                 # y[-1], y[0]: at rest
    for n in range(ticks):
        u.append(min(hi, max(lo, K * (r - y[-2]))))       # reading from one tick back
        y.append(a * y[-1] + b * u[-1] - b * d)           # d: heat drawn by a joint, W
    return y[1:], u

def poles(K, b=b, a=a):                                   # roots of z^2 - a z + b K
    q = cmath.sqrt(a * a - 4 * b * K)
    return (a + q) / 2, (a - q) / 2

def jury(K, b=b):                                         # z^2 + c1 z + c0, no roots needed
    c1, c0 = -a, b * K
    return abs(c0) < 1 and 1 + c1 + c0 > 0 and 1 - c1 + c0 > 0

def Y(z, K=K, r=r0):                                      # transform of the step response
    return b * K * r * z * z / ((z - 1) * (z * z - a * z + b * K))

def residues(n, K=K, r=r0):                               # partial fractions, read back in time
    p1, p2 = poles(K)
    g = b * K * r
    return (g / ((1 - p1) * (1 - p2)) + g * p1 ** (n + 1) / ((p1 - 1) * (p1 - p2))
            + g * p2 ** (n + 1) / ((p2 - 1) * (p2 - p1))).real

clean = lambda v: 0.0 if abs(v) < 1e-9 else v              # no "-0.00000" from rounding noise

def contour(n, rho=1.2, M=256):                           # (1/2 pi j) closed integral of Y z^(n-1) dz
    s = 0j
    for k in range(M):
        z = rho * cmath.exp(2j * math.pi * k / M)
        s += Y(z) * z ** n
    return (s / M).real

print(f"tip: T = {T:.1f} s, C = {Cth:.1f} J/degC, R = {Rth:.1f} degC/W; a = {a:.6f}, b = {b:.6f} degC per W per tick")
ae, be = math.exp(-T / (Rth * Cth)), Rth * (1 - math.exp(-T / (Rth * Cth)))   # heater held flat over each tick
print(f"exact one-tick factors (card 09): a = {ae:.6f}, b = {be:.6f}")
y, u = loop(K, r0, 400)
p1, p2 = poles(K)
print(f"K = {K:.1f} W/degC: b K = {b * K:.3f}; poles {p1.real:.5f} +- {abs(p1.imag):.5f}j, |p| = {abs(p1):.5f}, angle {math.degrees(cmath.phase(p1)):.2f} deg")
print(f"power for the 5 degC step: first tick {u[0]:.1f} W extra, total {u[0] + P_idle:.1f} W of {P_max:.0f} W; min extra {min(u):.2f} W")
gap = max(max(abs(y[n] - residues(n)), abs(y[n] - contour(n))) for n in range(41))
print(f"three roads, ticks 0-40 (contour |z| = 1.2, 256 points): largest gap {'below 1e-9' if gap < 1e-9 else gap} degC")
for n in (0, 1, 2, 3, 4, 5, 10, 20):
    print(f"n = {n:2d}  t = {n * T:.1f} s  loop {y[n]:8.5f}  partial fractions {clean(residues(n)):8.5f}  contour {clean(contour(n)):8.5f} degC")
print("chart, y[n] n=0..20 (degC) " + " ".join(f"{v:.2f}" for v in y[:21]))
H1 = b * K / (1 - a + b * K)
pk = max(range(60), key=lambda n: y[n])
settle = max(n for n in range(200) if abs(y[n] - H1 * r0) > 0.02 * H1 * r0) + 1
print(f"final value: H(1) = {H1:.6f}, H(1) r = {H1 * r0:.5f} degC (loop at n = 399: {y[399]:.5f}); droop {r0 - H1 * r0:.5f} degC")
print(f"peak {y[pk]:.4f} degC at n = {pk} (t = {pk * T:.1f} s), overshoot {100 * (y[pk] / (H1 * r0) - 1):.1f} %, {y[pk] - H1 * r0:.5f} degC past")
print(f"2 % settling: loop n = {settle} ({settle * T:.1f} s); envelope ln(0.02)/ln|p| = {math.log(0.02) / math.log(abs(p1)):.2f} ticks")
ye, _ = loop(K, r0, 400, b=be, a=ae); pe = max(range(60), key=lambda n: ye[n])
print(f"exact factors, same loop: |p| = {abs(poles(K, be, ae)[0]):.5f}, peak {ye[pe]:.5f} degC at n = {pe}, overshoot {100 * (ye[pe] / ye[399] - 1):.1f} %, final {ye[399]:.5f} degC, limit 1/b = {1 / be:.3f} W/degC")
z0 = 2.0
fwd = sum(y[n] * z0 ** -n for n in range(400))
print(f"definition at z = 2: sum of y[n] 2^-n = {fwd:.9f}; closed form Y(2) = {Y(z0).real:.9f}")
per = 2 * math.pi / cmath.phase(p1)
print(f"ringing period 2 pi/angle = {per:.3f} ticks = {per * T:.4f} s, {1 / (per * T):.4f} Hz")
s1 = cmath.log(p1) / T
print(f"z = e^(sT): closed-loop s = {s1.real:.4f} +- {abs(s1.imag):.4f}j rad/s; plant pole ln(a)/T = {math.log(a) / T:.6f} 1/s vs -1/(RC) = {-1 / (Rth * Cth):.6f}")

# ---- stability against the unit circle ----
for k in (0.0, 5.0, 12.5, 20.0, 24.0, 25.0, 26.0, 30.0):
    m = max(abs(p) for p in poles(k))
    yk, _ = loop(k, r0, 3000)
    dev = max(abs(v - (b * k / (1 - a + b * k)) * r0) for v in yk[2900:])
    print(f"K = {k:4.1f}  max|p| = {m:.5f}  roots say {'stable' if m < 1 - 1e-12 else 'not stable'}  Jury says {'stable' if jury(k) else 'not stable'}  swing after 290 s {'below 1e-9' if dev < 1e-9 else f'{dev:.2f}' if dev < 1e3 else f'10^{math.log10(dev):.2f}'} degC")
lo_k, hi_k = 0.0, 100.0
for _ in range(100):                                      # bisection on the roots' size, max|p| < 1
    mid = (lo_k + hi_k) / 2
    lo_k, hi_k = (mid, hi_k) if max(abs(p) for p in poles(mid)) < 1 else (lo_k, mid)
print(f"stability limit: bisection on max|p| = 1 {lo_k:.6f} W/degC; Jury's b K < 1 gives 1/b = {1 / b:.6f} W/degC; gain margin {1 / b / K:.2f}")
for k in (25.0, 30.0):
    q = poles(k)[0]
    print(f"K = {k:.1f}: poles {q.real:.5f} +- {abs(q.imag):.5f}j, angle {math.degrees(cmath.phase(q)):.2f} deg, period {2 * math.pi / cmath.phase(q) * T:.4f} s")
for sc in (1.2, 2.0):                                     # smaller tip: b grows and a shrinks
    print(f"tip heat capacity / {sc:.1f}: b = {b * sc:.3f}, max|p| = {max(abs(p) for p in poles(K, b * sc, 1 - T * sc / (Rth * Cth))):.5f}")
print("figure, centre (170,120), unit circle radius 90 px; zero at (170,120)")
for k in (12.5, 25.0, 30.0):
    q = poles(k)[0]
    print(f"figure, K = {k:.1f}: poles at ({170 + 90 * q.real:.1f},{120 - 90 * q.imag:.1f}) and ({170 + 90 * q.real:.1f},{120 + 90 * q.imag:.1f})")

# ---- the unit circle is frequency: z = e^(j 2 pi f T) ----
Hz = lambda f: b * K * cmath.exp(2j * math.pi * f * T) / (cmath.exp(4j * math.pi * f * T) - a * cmath.exp(2j * math.pi * f * T) + b * K)
for f in (0.0, 0.5, 1.0, 1.25, 2.0, 5.0):
    print(f"|H| at {f:4.2f} Hz = {abs(Hz(f)):.4f}")
fpk = max((i * 0.001 for i in range(5001)), key=lambda f: abs(Hz(f)))
print(f"peak gain {abs(Hz(fpk)):.4f} at {fpk:.3f} Hz; z = -1 is f_s/2 = {1 / (2 * T):.1f} Hz")
yv = [0.0, 0.0]
for n in range(1200):                                     # setpoint wobbling 1 degC at 1 Hz
    yv.append(a * yv[-1] + b * K * (math.sin(2 * math.pi * 1.0 * n * T) - yv[-2]))
tail = yv[201:1201]                                       # y[200]..y[1199], 100 whole periods
cs = sum(v * math.cos(2 * math.pi * (n + 200) * T) for n, v in enumerate(tail)) * 2 / 1000
sn = sum(v * math.sin(2 * math.pi * (n + 200) * T) for n, v in enumerate(tail)) * 2 / 1000
print(f"1 Hz wobble of 1 degC, run through the loop: tip swings {math.hypot(cs, sn):.4f} degC ({360 * 1.0 * T:.1f} deg per tick)")
print(f"no sensor delay: one pole a - b K = {a - b * K:.3f}; limit K = (1 + a)/b = {(1 + a) / b:.2f} W/degC")

# ---- what breaks ----
print(f"s-plane rule on z-poles: Re p = {p1.real:.3f} > 0 calls the K = 12.5 loop unstable; |p| = {abs(p1):.5f} < 1, it settles")
yl, ul = loop(K, 20.0, 200)
yc, uc = loop(K, 20.0, 200, lo=-P_idle, hi=P_max - P_idle)
print(f"20 degC step: linear asks {ul[0]:.0f} W extra, peak {max(yl):.3f} degC; heater clamped to +{P_max - P_idle:.1f} W/-{P_idle:.1f} W peaks {max(yc):.3f} degC at n = {yc.index(max(yc))}")
yd, _ = loop(K, 0.0, 400, d=20.0)
print(f"joint drawing 20 W: loop settles at {yd[399]:.4f} degC; formula -b d/(1 - a + b K) = {-b * 20 / (1 - a + b * K):.4f} degC; bare tip would sag R d = {Rth * 20:.0f} degC")
anti = sum(-(0.5 / a) ** m for m in range(1, 400))
print(f"anti-causal twin: same z/(z-a), ROC |z| < {a:.3f}: anti-causal sum at z = 0.5 is {anti:.6f} = {0.5 / (0.5 - a):.6f}")

assert gap < 1e-9                                         # loop vs pole formula vs contour integral
assert abs(fwd - Y(z0).real) < 1e-9                       # summed definition vs closed-form transform
assert abs(y[399] - H1 * r0) < 1e-9                       # long run vs z -> 1
assert abs(lo_k - 1 / b) < 1e-9                           # bisection on the roots vs Jury's b K < 1
assert all(jury(k) == (max(abs(p) for p in poles(k)) < 1 - 1e-12) for k in (0, 5, 12.5, 24, 26, 30))
assert abs(yd[399] + b * 20 / (1 - a + b * K)) < 1e-9     # disturbance run vs formula
assert abs(math.hypot(cs, sn) - abs(Hz(1.0))) < 1e-6      # simulated wobble vs H on the unit circle
assert abs(anti - 0.5 / (0.5 - a)) < 1e-9                 # anti-causal sum vs the same fraction
print("ALL CHECKS PASS")
