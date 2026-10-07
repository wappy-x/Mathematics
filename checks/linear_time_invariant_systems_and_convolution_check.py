# Linear and time-invariant systems and convolution -- the check behind the card.
# Standard library only; only math.exp is imported.  The car is a black box:
# 1500 dv/dt = 25 (17.25 + u) - 0.6 CdA v^2 - 150, stepped with RK4.
# Road one convolves the measured pulse response with the throttle history;
# road two runs the box itself; road three is the linearised car's closed form.
from math import exp

M, KF, HALF_RHO, FR, V0 = 1500.0, 25.0, 0.5 * 1.2, 150.0, 25.0  # kg, N/%, kg/m^3, N, m/s
DRAG = HALF_RHO * 0.75                    # drag area 0.75 m^2: 0.45 N per (m/s)^2
TH0 = (DRAG * V0 * V0 + FR) / KF          # cruise throttle, %
B = 2 * DRAG * V0                         # slope of the drag curve at 25 m/s, N s/m
TAU, K = M / B, KF / B                    # time constant in s; steady gain in (m/s) per %
A = exp(-1.0 / TAU)                       # share of a speed bump left after one second

def clean(t): return 0.75                       # drag area in clean air, m^2
def draft(t): return 0.75 if t < 50 else 0.60   # tucked behind a lorry from t = 50 s

def car(u, area=clean, mass=M, sub=10):
    """Throttle deviation u[n] in %, held through second n -> speed deviation y[n] in m/s at t = n s."""
    v, dt, y = V0, 1.0 / sub, [0.0]
    for n, un in enumerate(u):
        F = KF * (TH0 + un) - FR
        f = lambda t, v: (F - HALF_RHO * area(t) * v * v) / mass
        for j in range(sub):
            t = n + j * dt
            k1 = f(t, v); k2 = f(t + dt / 2, v + dt / 2 * k1)
            k3 = f(t + dt / 2, v + dt / 2 * k2); k4 = f(t + dt, v + dt * k3)
            v += dt / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        y.append(v - V0)
    return y

def conv(h, u):                           # y[n] = sum over k of h[k] u[n - k]
    return [sum(h[k] * u[n - k] for k in range(n + 1) if n - k < len(u)) for n in range(len(u) + 1)]

def linear(u, a=A, gain=K):               # the linearised car, solved exactly second by second
    y = [0.0]
    for un in u: y.append(a * y[-1] + gain * (1 - a) * un)
    return y

def block(level, start, length, n): return [level if start <= i < start + length else 0.0 for i in range(n)]
def plus(p, q): return [a + b for a, b in zip(p, q)]
def minus(p, q): return [a - b for a, b in zip(p, q)]

N = 300
h = car([1.0] + [0.0] * (N - 1))          # measured: +1 % for one second, then cruise throttle
hcf = [0.0] + [K * (1 - A) * A ** (k - 1) for k in range(1, N + 1)]
print(f"car: mass {M:.0f} kg, drive {KF:.0f} N per %, air {2 * HALF_RHO:.1f} kg/m^3, drag area 0.75 m^2 "
      f"(0.60 m^2 behind the lorry), rolling {FR:.0f} N; drag {DRAG:.2f} N/(m/s)^2, {DRAG * V0 * V0:.2f} N at {V0:.0f} m/s")
print(f"model: cruise throttle {TH0:.2f} %, drag slope {B:.1f} N s/m, tau {TAU:.3f} s, "
      f"K {K:.4f} (m/s)/%, a {A:.6f}")

# ---- the four tests, run on the box ----
zero = car([0.0] * 120)
s1, s2 = car(block(5.0, 0, 10, 20)), car(block(10.0, 0, 10, 20))
b1, b2 = car(block(5.0, 10, 10, 30)), car(block(5.0, 0, 10, 30))
both = car(plus(block(5.0, 0, 10, 30), block(5.0, 10, 10, 30)))
late = car(block(10.0, 40, 10, 80)); early = car(block(10.0, 0, 10, 80))
shift_gap = max(abs(late[n + 40] - early[n]) for n in range(41))
base = car([0.0] * 140, draft)
g0 = minus(car(block(1.0, 0, 1, 140), draft), base)
g1 = minus(car(block(1.0, 100, 1, 140), draft), base)
print(f"test 1, zero in: largest speed deviation {max(abs(x) for x in zero):.9f} m/s")
print(f"test 2, scaling at 10 s: 5 % gives {s1[10]:.4f} m/s, 10 % gives {s2[10]:.4f} m/s, ratio {s2[10] / s1[10]:.4f}")
print(f"test 3, adding at 20 s: together {both[20]:.4f} m/s, separately {b1[20] + b2[20]:.4f} m/s")
print(f"test 4, shifting by 40 s, clean air: largest gap {shift_gap:.9f} m/s")
print(f"test 4, shifting by 100 s, lorry from 50 s: 30 s after the pulse {1000 * g0[30]:.2f} mm/s "
      f"early, {1000 * g1[130]:.2f} mm/s late")

# ---- the pulse response, measured and from the formula ----
print(f"h[1], h[2], h[3] measured: {h[1]:.6f} {h[2]:.6f} {h[3]:.6f} m/s; formula K(1-a)a^(k-1): "
      f"{hcf[1]:.6f} {hcf[2]:.6f} {hcf[3]:.6f}")
ks1 = [1] + list(range(20, N + 1, 20))    # chart 1 starts at 1 s, the end of the push; h[0] = 0
print("chart1, k in s:   " + " ".join(f"{k:5d}" for k in ks1))
print("chart1, h mm/s:   " + " ".join(f"{1000 * h[k]:5.2f}" for k in ks1))
herr = max(abs(h[k] - hcf[k]) / hcf[k] for k in range(1, N + 1))
print(f"pulse response, measured vs formula: largest relative gap {100 * herr:.3f} %")
print(f"running sum of h to 300 s (the step response) {sum(h):.4f} m/s per %; K = {K:.4f}")

# ---- worked by hand: throttle +10, +10, -5 % for three seconds ----
hand = [10.0, 10.0, -5.0]
print(f"hand: products h[1]u[2], h[2]u[1], h[3]u[0] = {h[1] * hand[2]:.6f} {h[2] * hand[1]:.6f} {h[3] * hand[0]:.6f} m/s")
print(f"hand: y[3] = h[3]*10 + h[2]*10 + h[1]*(-5) = {conv(h, hand)[3]:.6f} m/s; "
      f"box {car(hand)[3]:.6f}; linear model {linear(hand)[3]:.6f}")

# ---- the overtaking manoeuvre: +10 % for 15 s, -5 % for 15 s, then cruise ----
u = [10.0] * 15 + [-5.0] * 15 + [0.0] * 90
yc, yb, yl, yh = conv(h, u), car(u), linear(u), conv(hcf, u)
print("chart2, t s:     " + " ".join(f"{n:5d}" for n in range(0, 121, 5)))
for name, ys in (("convolution", yc), ("box", yb), ("linear", yl)):
    print(f"chart2, {name + ':':<12}" + " ".join(f"{ys[n]:5.2f}" for n in range(0, 121, 5)))
gap = max(abs(a - b) for a, b in zip(yc, yb))
exact = max(abs(a - b) for a, b in zip(yh, yl))
print(f"overtaking: largest gap convolution vs box {gap:.4f} m/s; formula-h convolution vs linear model {exact:.9f}")

# ---- what breaks ----
big = [40.0] * 120
bl, bb = linear(big), car(big)
print("chart3, t s:     " + " ".join(f"{n:5d}" for n in range(0, 121, 10)))
print("chart3, linear:  " + " ".join(f"{bl[n]:5.2f}" for n in range(0, 121, 10)))
print("chart3, box:     " + " ".join(f"{bb[n]:5.2f}" for n in range(0, 121, 10)))
gw = conv(h, [10.0] * 30)[30]; bw = minus(car(block(10.0, 100, 30, 130), draft), base[:131])[130]
print(f"breaks 1, +40 % for 120 s: linear {bl[120]:.2f} m/s, box {bb[120]:.2f} m/s, gap {bl[120] - bb[120]:.2f} m/s")
print(f"breaks 2, clean-air h used behind the lorry, +10 % for 30 s: predicted {gw:.4f} m/s, "
      f"box {bw:.4f} m/s, box in clean air {car([10.0] * 30)[30]:.4f} m/s")
step = car([1.0] * 120)
print(f"breaks 3, step response used as h: overtaking at 15 s {conv(step, u)[15]:.4f} m/s, not {yc[15]:.4f}")
noflip = sum(h[k] * u[k] for k in range(31))
print(f"breaks 4, no flip at 30 s: {noflip:.4f} m/s, not {yc[30]:.4f}")

# ---- try changing ----
for scale in (0.5, 2.0):
    us = [scale * x for x in u]
    print(f"try, overtaking x {scale:.1f}: largest gap convolution vs box {max(abs(a - b) for a, b in zip(conv(h, us), car(us))):.4f} m/s")
print(f"try, car of 2000 kg: speed at 15 s {car(u, mass=2000.0)[15]:.4f} m/s")

assert abs(s2[10] / s1[10] - 2.0) < 0.01                           # scaling nearly holds near cruise
assert abs(both[20] - (b1[20] + b2[20])) < 0.01                   # adding nearly holds near cruise
assert shift_gap < 1e-9                                            # the clean-air car only shifts
assert abs(g1[130] - g0[30]) > 2e-4                                # the drafting car changes its answer
assert herr < 0.01                                                 # measured pulse response = linear formula
assert gap < 0.05                                                  # convolution = the box itself, near cruise
assert exact < 1e-9                                                # convolution = exact linear solution
assert bl[120] - bb[120] > 5.0                                     # far from cruise, linearity fails
print("ALL CHECKS PASS")
