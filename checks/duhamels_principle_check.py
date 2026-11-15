# Duhamel's principle -- the check behind the card.  Standard library only.
# A 1 m copper rod, 1 cm^2 section, room temperature everywhere.  At t = 5 s a
# 10 W heater band at its middle (x = 0) switches on.  u = rise above room, K.
# Roads: the Duhamel integral by Simpson's rule; its closed form (erfc written
# out); an explicit grid with insulated ends; the residual u_t - kappa u_xx;
# the heat budget; the slope jump at the heater.  Then a string pushed at 5 s.
import math

K, RC, A, P, T0 = 1.11e-4, 3.45e6, 1e-4, 10.0, 5.0   # m^2/s, J/(m^3 K), m^2, W, s
Q = P / (RC * A)                                      # source strength, K m/s

def sci(v):                          # e-notation with the same digits in Rust
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    return f"{m:.3f}e{'-' if e < 0 else '+'}{abs(e):02d}"

def erfc(z):                         # z >= 0: series near 0, continued fraction far out
    if z > 3:
        f = z
        for k in range(60, 0, -1): f = z + (k / 2) / f
        return math.exp(-z * z) / (math.sqrt(math.pi) * f)
    term = s = z; n = 0
    while term > 1e-17 * s:
        n += 1; term *= 2 * z * z / (2 * n + 1); s += term
    return 1 - 2 / math.sqrt(math.pi) * math.exp(-z * z) * s

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def kernel(x, age): return math.exp(-x * x / (4 * K * age)) / math.sqrt(4 * math.pi * K * age)

def duhamel(x, t, n=400, start=T0):  # road 1: add up fresh starts, age a = w^2
    if t <= start: return 0.0
    f = lambda w: Q * 2 * w * kernel(x, w * w) if w > 0 else (Q / math.sqrt(math.pi * K) if x == 0 else 0.0)
    return simpson(f, 0.0, math.sqrt(t - start), n)

def closed(x, t, start=T0):          # road 2: the same integral done by hand
    if t <= start: return 0.0
    tau = t - start; z = abs(x) / (2 * math.sqrt(K * tau))
    return Q * (math.sqrt(tau / (math.pi * K)) * math.exp(-z * z) - abs(x) / (2 * K) * erfc(z))

def grid(dx, t1=65.0, half=0.5):     # road 3: explicit grid, heater in the middle cell
    n = round(2 * half / dx); m = n // 2
    steps = math.ceil((t1 - T0) * 4 * K / dx ** 2); dt = (t1 - T0) / steps; r = K * dt / dx ** 2
    u = [0.0] * (n + 1)
    for _ in range(steps):
        v = [u[i] + r * (u[max(i - 1, 0) if i else 1] - 2 * u[i] + u[i + 1 if i < n else n - 1])
             for i in range(n + 1)]
        v[m] += Q * dt / dx; u = v
    return u[m], u[m + round(0.02 / dx)]

print(f"source strength Q = P/(rho c A) = {Q:.7f} K m/s")
print("chart, heater band, t = 0..65 s by 5 s: " + ", ".join(f"{closed(0, 5.0 * i):.2f}" for i in range(14)))
for t in (15.0, 35.0, 65.0):
    print(f"chart, profile at t = {t:.0f} s, x = -10..10 cm by 2 cm: " + ", ".join(f"{closed(0.02 * i, t):.2f}" for i in range(-5, 6)))
print(f"before switch-on, t = 4 s, x = 0: {duhamel(0, 4.0):.6f} K, {closed(0, 4.0):.6f} K")
print("t s | x m | Duhamel integral K | closed form K")
for t in (15.0, 35.0, 65.0):
    for x in (0.0, 0.02, 0.05):
        d, c = duhamel(x, t), closed(x, t)
        assert abs(d - c) < 1e-9, (t, x)
        print(f"{t:4.0f} | {x:.2f} | {d:.6f} | {c:.6f}")
u10, u40 = closed(0, 15.0), closed(0, 45.0)
assert abs(u40 / u10 - 2) < 1e-12                     # square-root law
print(f"heater band after 10 s and 40 s: {u10:.4f} K, {u40:.4f} K; ratio {u40 / u10:.4f}")

print("grid at t = 65 s | dx cm | u(0) K | u(2 cm) K | error at 0")
errs = []
for dx in (0.02, 0.01, 0.005):
    g0, g2 = grid(dx); e = abs(g0 - closed(0, 65.0)); errs.append(e)
    print(f"grid | {dx * 100:.1f} | {g0:.5f} | {g2:.5f} | {sci(e)}")
orders = [math.log2(errs[i] / errs[i + 1]) for i in range(2)]
assert errs[2] < 0.01 and all(1.7 < p < 2.3 for p in orders)
print("observed order: " + ", ".join(f"{p:.2f}" for p in orders))
img = 2 * closed(1.0, 65.0)
print(f"first omitted term, the two end images at x = 0, t = 65 s: {sci(img)} K")

for h in (1e-3, 5e-4):                                # road 4: residual at x = 2 cm, t = 15 s
    x, t = 0.02, 15.0
    ut = (closed(x, t + h * 10) - closed(x, t - h * 10)) / (20 * h)
    uxx = (closed(x + h, t) - 2 * closed(x, t) + closed(x - h, t)) / h ** 2
    assert abs(ut - K * uxx) < 1e-4 * abs(ut)
    print(f"residual, step {h * 1000:.1f} mm: u_t = {ut:.6f} K/s, kappa u_xx = {K * uxx:.6f} K/s")

half = lambda b: simpson(lambda x: closed(x, 65.0), 0.0, b, 800)  # u is even in x
heat = 2 * RC * A * half(1.0)
past = 2 * RC * A * simpson(lambda x: closed(x, 65.0), 0.5, 1.0, 800)
assert abs(heat - P * 60) < 1e-8 * P * 60              # road 5: the heat budget
print(f"heat on the line at 65 s: {heat:.4f} J; heater gave {P * 60:.1f} J; past the rod ends {sci(past)} J")
for tau in (10.0, 60.0):                               # road 6: slope jump carries the power
    s = (closed(1e-6, T0 + tau) - closed(0.0, T0 + tau)) / 1e-6
    assert abs(s + Q / (2 * K)) < 1e-3 * Q / (2 * K)
    print(f"slope beside the heater, t_on = {tau:.0f} s: {s:.3f} K/m (exact -Q/(2 kappa) = {-Q / (2 * K):.3f}); "
          f"flow out both sides {-2 * K * RC * A * s:.4f} W")
print(f"air cooling, illustrative 10 W/(m^2 K) on a 4 cm rim: {10 * 0.04 * Q * 1800:.2f} J of 600 J, {10 * 0.04 * Q * 1800 / 6:.2f} %")
print(f"conductivity these values imply, kappa rho c = {K * RC:.1f} W/(m K), {100 * (1 - K * RC / 401):.1f} % below 401 W/(m K)")

z = 0.02 / (2 * math.sqrt(K * 10))                     # by hand at t = 15 s
print(f"by hand: rho c A = {RC * A:.1f} J/(K m); sqrt(10/(pi kappa)) = {math.sqrt(10 / (math.pi * K)):.3f} s/m; "
      f"at 2 cm: z = {z:.5f}, e^(-z^2) = {math.exp(-z * z):.5f}, erfc(z) = {erfc(z):.5f}, x/(2 kappa) = {0.02 / (2 * K):.3f} s/m")
t1, t2 = math.sqrt(10 / (math.pi * K)) * math.exp(-z * z), 0.02 / (2 * K) * erfc(z)
print(f"by hand at 2 cm: {t1:.3f} - {t2:.3f} = {t1 - t2:.3f} s/m; times Q: {Q * (t1 - t2):.4f} K")
print("what breaks, at x = 0, t = 15 s:")
print(f"  stream started at 0 s, not 5 s: {closed(0, 15.0, start=0.0):.4f} K, not {u10:.4f}")
wrong = simpson(lambda s: Q * kernel(0, 15.0), T0, 15.0, 10)
print(f"  kernel fed the clock t, not the age t - tau: {wrong:.4f} K")
print(f"  power not divided by rho c A: {P / Q * u10:.1f} K")

F, TS, MU = 0.2, 100.0, 0.01                           # the wave: string, N, N, kg/m
C = math.sqrt(TS / MU)
def tent(x, t): return F / (2 * MU * C) * max(0.0, (t - T0) - abs(x) / C)
def kicks(x, t, n):                                    # each kick: d'Alembert box of height F/(2 mu c)
    ds = (t - T0) / n
    return sum(F / (2 * MU * C) * ds for k in range(n) if abs(x) < C * (t - T0 - (k + 0.5) * ds))
print(f"string: c = {C:.1f} m/s; centre speed F/(2 mu c) = {F / (2 * MU * C):.4f} m/s")
for x in (0.0, 0.1, 0.3):
    a, b = tent(x, 5.004), kicks(x, 5.004, 4000)
    assert abs(a - b) < 1e-3 * a + 1e-9
    print(f"string at t = 5.004 s, x = {x:.1f} m: tent {a * 1000:.4f} mm, sum of 4000 kicks {b * 1000:.4f} mm")
mom = MU * simpson(lambda x: (tent(x, 5.0041) - tent(x, 5.0039)) / 2e-4, -0.5, 0.5, 2000)
assert abs(mom - F * 0.004) < 1e-3 * F * 0.004
print(f"string momentum at 5.004 s: {mom * 1000:.4f} g m/s; impulse F (t - 5) = {F * 4:.4f} g m/s")
off = closed(0, 125.0) - closed(0, 125.0, start=65.0)  # try changing
print(f"try: heater off at 65 s, x = 0 at 125 s: {off:.4f} K; tension 200 N: centre speed {F / (2 * math.sqrt(200 * MU)):.4f} m/s")
print("ALL CHECKS PASS")
