# The delta and the derivative of a switch -- the check behind the card.
# Standard library only: math supplies exp and log, nothing more.  Time is in
# milliseconds.  A switch puts 12 V on a lamp at t = 0, with a 100 uF capacitor
# across it.  The step's derivative is read on one smooth probe by three roads:
# the delta's rule 12*phi(0); the derivative moved onto the probe, integrated by
# Simpson's rule; and real switches that ramp up over eps ms, eps shrinking.
import math

V, C = 12.0, 100e-6                  # volts; farads
CEN, W = 2.0, 4.0                    # probe centre and half-width, ms: alive on (-2, 6)

def phi(t):                          # the probe: a smooth bump, zero outside (-2, 6)
    u = (t - CEN) / W
    return math.exp(-1.0 / (1.0 - u * u)) if abs(u) < 1.0 else 0.0

def dphi(t):                         # its slope, per ms, by the chain rule
    u = (t - CEN) / W
    return phi(t) * (-2.0 * u / (1.0 - u * u) ** 2) / W if abs(u) < 1.0 else 0.0

def simpson(f, a, b, n=4000):        # Simpson's rule, written out; n is even
    h = (b - a) / n
    s = f(a) + f(b)
    for k in range(1, n):
        s += (4.0 if k % 2 == 1 else 2.0) * f(a + k * h)
    return s * h / 3.0

def gap_integral(lo, hi):            # integral of phi(t)/t over (-2, -lo) and (hi, 6)
    right = simpson(lambda x: phi(math.exp(x)), math.log(hi), math.log(6.0))
    left = simpson(lambda x: phi(-math.exp(x)), math.log(lo), math.log(2.0))
    return right - left              # t = e^x on the right, t = -e^x on the left

def log_weight(s):                   # ln|t| phi'(t) after t = s*s, on each side
    if s == 0.0:
        return 0.0
    return 4.0 * s * math.log(s) * (dphi(s * s) + dphi(-s * s))

# ---- road 1 and road 2: the delta's rule, and the derivative moved onto the probe
road1 = V * phi(0.0)
road2 = -simpson(lambda t: V * dphi(t), 0.0, 6.0)
print("switch 12 V at t = 0 ms; capacitor 100 uF; probe centre 2 ms, half-width 4 ms")
print(f"probe phi(0) = {phi(0.0):.6f}, slope phi'(0) = {dphi(0.0):.6f} per ms")
print(f"road 1, the delta's rule 12*phi(0): {road1:.6f}")
print(f"road 2, minus the integral of 12*phi' over t > 0: {road2:.6f}")

# ---- road 3: a real switch ramps from 0 to 12 V over eps ms
print("road 3, ramp switch of rise time eps: peak current, charge, reading, error/eps")
ratios = []
for eps in [1.0, 0.1, 0.01, 0.001]:
    slope = V / eps                                  # V per ms while the ramp rises
    current = C * slope * 1000.0                     # amps: C dV/dt with dt in seconds
    charge = simpson(lambda t: current, 0.0, eps)     # amps times ms is millicoulombs
    reading = simpson(lambda t: slope * phi(t), 0.0, eps)
    ratios.append((reading - road1) / eps)
    print(f"  eps {eps:g} ms: {current:.1f} A, {charge:.3f} mC, "
          f"{reading:.6f}, {ratios[-1]:.6f}")
half_slope = V * dphi(0.0) / 2.0
print(f"  error/eps tends to 12*phi'(0)/2 = {half_slope:.6f}")

# ---- the finite rehearsal: the step as a list of N samples on (-4, 8) ms
print("finite rehearsal, N samples: spike height V/ms, reading, by parts, error")
for n in [12, 120, 1200, 12000]:
    h = 12.0 / n
    ts = [-4.0 + (k + 0.5) * h for k in range(n)]
    step = [V if t >= 0.0 else 0.0 for t in ts]
    diff = [0.0] + [(step[k] - step[k - 1]) / h for k in range(1, n)]
    reading = sum(diff[k] * phi(ts[k]) * h for k in range(n))
    by_parts = -sum(step[k] * (phi(ts[k + 1]) - phi(ts[k])) for k in range(n - 1))
    assert abs(reading - by_parts) < 1e-12               # summation by parts, exact
    print(f"  N {n}: {max(diff):.1f}, {reading:.6f}, {by_parts:.6f}, "
          f"{reading - road1:.6f}")

# ---- the jump rule: on at 0 ms, off at 5 ms
jump_rule = V * phi(0.0) - V * phi(5.0)
moved = -simpson(lambda t: V * dphi(t), 0.0, 5.0)
print(f"jump rule, on at 0 and off at 5 ms: 12*phi(0) - 12*phi(5) = {jump_rule:.6f}; "
      f"moved onto the probe = {moved:.6f}")

# ---- the principal value of 1/t: the derivative of ln|t|
print("principal value of 1/t on the probe, gap (-eps, eps) cut out:")
gaps = []
for eps in [0.1, 0.01, 0.001]:
    gaps.append(gap_integral(eps, eps))
    print(f"  eps {eps:g}: {gaps[-1]:.6f}")
log_road = -simpson(log_weight, 0.0, math.sqrt(6.0))
print(f"  minus the integral of ln|t| phi'(t): {log_road:.6f}")
lopsided = gap_integral(0.001, 0.002)
ln2_shift = phi(0.0) * math.log(2.0)

# ---- what breaks
print(f"mistake 1, classical derivative, zero off the switch: reading 0, charge 0 mC, not {road1:.6f}")
print(f"mistake 2, minus sign dropped: {-road2:.6f}")
print(f"mistake 3, lopsided gap (-0.001, 0.002): {lopsided:.6f}, off by phi(0) ln 2 = {ln2_shift:.6f}")
squares = [simpson(lambda t: (V / e) ** 2, 0.0, e) for e in [1.0, 0.1, 0.01, 0.001]]
print("mistake 4, squaring the ramp's slope, integral of (12/eps)^2: "
      + ", ".join(f"{q:.0f}" for q in squares))

# ---- chart: capacitor current for rise times 2, 1 and 0.5 ms
xs = [-0.5 + 0.25 * k for k in range(13)]
for eps in [2.0, 1.0, 0.5]:
    row = [C * V / eps * 1000.0 if 0.0 <= x < eps else 0.0 for x in xs]
    print(f"chart eps {eps:g}: " + ", ".join(f"{y:.2f}" for y in row))

assert abs(road1 - road2) < 1e-9                         # rule against moved derivative
assert abs(ratios[-1] - half_slope) < 1e-3               # ramp error falls like eps
assert abs(jump_rule - moved) < 1e-9                     # two jumps, two deltas
assert abs(gaps[-1] - log_road) < 3 * 0.001 * dphi(0.0)  # PV: gap against log road
assert abs((gaps[-1] - lopsided) - ln2_shift) < 1e-3     # lopsided gap is off by ln 2
print("ALL CHECKS PASS")
