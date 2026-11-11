# Waves on strings and drums -- the check behind the card.  Standard library only.
# Road 1: the mode formulas.  Road 2: shooting (RK4 + bisection) on the string's
# shape equation.  Road 3: a time simulation of the square drum, then a written-out
# Fourier scan of one point's motion, to see which frequencies it actually rings at.
from math import pi, sin, cos, sqrt, exp

L, f1 = 0.648, 329.63                  # guitar high E: scale length m, open note Hz
d, rho, E_steel = 0.254e-3, 7850.0, 200e9   # plain steel string: diameter m, kg/m^3, Pa
area = pi * d * d / 4
mu = rho * area                        # mass per metre, kg/m
c = 2 * L * f1                         # wave speed, from f1 = c / (2L)
T = mu * c * c                         # tension, from c = sqrt(T / mu)
print(f"string: {L} m long, open {f1} Hz, steel {d * 1000:.3f} mm thick, {rho:.0f} kg/m^3, {E_steel / 1e9:.0f} GPa")
print(f"string: mass per metre {mu * 1000:.4f} g/m, wave speed {c:.2f} m/s, tension {T:.1f} N")

def shoot(k, free_end=False, steps=400):
    # Road 2: march X'' = -k^2 X from X(0) = 0, X'(0) = 1 with RK4; return X(L) (or X'(L))
    h, x, v = L / steps, 0.0, 1.0
    for _ in range(steps):
        a1, b1 = v, -k * k * x
        a2, b2 = v + h / 2 * b1, -k * k * (x + h / 2 * a1)
        a3, b3 = v + h / 2 * b2, -k * k * (x + h / 2 * a2)
        a4, b4 = v + h * b3, -k * k * (x + h * a3)
        x, v = x + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), v + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    return v if free_end else x

def allowed_k(count, free_end=False):
    # scan k for sign changes of the end value, then bisect each one
    found, k, dk = [], 0.5, 0.5
    prev = shoot(k, free_end)
    while len(found) < count:
        nxt = shoot(k + dk, free_end)
        if prev * nxt < 0:
            lo, hi = k, k + dk
            for _ in range(50):
                mid = (lo + hi) / 2
                if shoot(lo, free_end) * shoot(mid, free_end) <= 0: hi = mid
                else: lo = mid
            found.append((lo + hi) / 2)
        k, prev = k + dk, nxt
    return found

print("string harmonics: n, formula n c/(2L), shooting, nodes inside the string")
for n, k in enumerate(allowed_k(4), start=1):
    fs, fn = c * k / (2 * pi), n * c / (2 * L)
    assert abs(fs - fn) < 1e-6 * fn, (n, fs, fn)
    print(f"  {n}  {fn:8.2f} Hz  {fs:8.2f} Hz  {n - 1}")
print("touch lightly at a point: lowest harmonic with a node there")
for name, frac in (("1/2 (12th fret)", 1 / 2), ("1/3 (7th fret)", 1 / 3), ("1/4 (5th fret)", 1 / 4), ("1/5 (4th fret)", 1 / 5)):
    n = next(m for m in range(1, 20) if abs(sin(m * pi * frac)) < 1e-9)
    print(f"  {name:<16} at {frac * L:.3f} m: harmonic {n}, {n * f1:.2f} Hz")
assert next(m for m in range(1, 20) if abs(sin(m * pi / 3)) < 1e-9) == 3
k400 = 2 * pi * 400 / c                # a frequency not on the list
print(f"try 400 Hz: shape at the bridge sin(kL) = {sin(k400 * L):.4f}, by shooting {k400 * shoot(k400):.4f}, not 0")
xs = [L * i / 10 for i in range(11)]
print("chart, position m       " + " ".join(f"{x:5.3f}" for x in xs))
for n in (1, 2, 3):
    print(f"chart, harmonic {n} shape " + " ".join(f"{round(sin(n * pi * x / L), 2) + 0.0:5.2f}" for x in xs))

# ---- the square drum: side a, wave speed c_d ----
a, cd = 0.30, 100.0
f_mn = lambda m, n: cd / (2 * a) * sqrt(m * m + n * n)
modes = sorted(((f_mn(m, n), m, n) for m in range(1, 5) for n in range(1, 5)))
print(f"square drum, side {a} m, wave speed {cd} m/s: modes up to 650 Hz")
for f, m, n in modes:
    if f < 650: print(f"  ({m},{n})  {f:7.2f} Hz  ratio {f / modes[0][0]:.3f}")
rect = sorted((50 * sqrt((m / 0.3) ** 2 + (n / 0.2) ** 2), m, n) for m in range(1, 4) for n in range(1, 4))
print("try: 0.30 x 0.20 m head, first notes " + ", ".join(f"({m},{n}) {f:.1f} Hz" for f, m, n in rect[:4]))
notes = sorted({round(f, 6) for f, m, n in modes if f < 650})

# Road 3: leapfrog simulation of u_tt = c^2 (u_xx + u_yy), edges clamped, released from rest
N, dt, steps, keep = 30, 5e-5, 4000, 4
dx = a / N
r2 = (cd * dt / dx) ** 2              # (c dt / dx)^2 = 0.25, inside the stability limit 0.5
u = [[0.0] * (N + 1) for _ in range(N + 1)]
for i in range(1, N):
    for j in range(1, N):
        u[i][j] = exp(-((i * dx - 0.09) ** 2 + (j * dx - 0.06) ** 2) / (2 * 0.03 ** 2))
lap = lambda w, i, j: w[i + 1][j] + w[i - 1][j] + w[i][j + 1] + w[i][j - 1] - 4 * w[i][j]
prev = u
u = [[0.0] * (N + 1)] + [[0.0] + [prev[i][j] + 0.5 * r2 * lap(prev, i, j) for j in range(1, N)] + [0.0]
                         for i in range(1, N)] + [[0.0] * (N + 1)]
rec = []
for s in range(1, steps):
    if s % keep == 0: rec.append(u[21][13])                  # the point (0.21 m, 0.13 m)
    nxt = [[0.0] * (N + 1)] + [[0.0] + [2 * u[i][j] - prev[i][j] + r2 * lap(u, i, j) for j in range(1, N)] + [0.0]
                               for i in range(1, N)] + [[0.0] * (N + 1)]
    prev, u = u, nxt
M, ts = len(rec), keep * dt
win = [r * (0.5 - 0.5 * cos(2 * pi * k / (M - 1))) for k, r in enumerate(rec)]   # Hann window
def power(f):
    re = sum(w * cos(2 * pi * f * k * ts) for k, w in enumerate(win))
    im = sum(w * sin(2 * pi * f * k * ts) for k, w in enumerate(win))
    return re * re + im * im
grid = [(f, power(f)) for f in range(100, 651)]
top = max(p for f, p in grid)
peaks = []
for (fa, pa), (fb, pb), (fc, pc) in zip(grid, grid[1:], grid[2:]):
    if pb > pa and pb >= pc and pb > 1e-3 * top:
        peaks.append(max((fb - 1 + 0.01 * q for q in range(201)), key=power))
print(f"simulation: {N} x {N} grid, {steps} steps of {dt * 1e6:.0f} us; peaks heard at (0.21, 0.13) m")
assert len(peaks) == len(notes), (peaks, notes)
for p, f in zip(peaks, notes):
    assert abs(p - f) < 0.01 * f, (p, f)
    print(f"  peak {p:7.1f} Hz   formula {f:7.1f} Hz   off by {100 * (p - f) / f:+.2f}%")

print("figure, 400 px per m, panel 120 px = 0.30 m; node lines: (2,1) x = 60; (1,2) y = 60; "
      "(1,2)+(2,1) from (0,120) to (120,0), y measured up")
# the mix of (1,2) and (2,1) vanishes on the anti-diagonal x + y = a
mix = lambda x, y: sin(pi * x / a) * sin(2 * pi * y / a) + sin(2 * pi * x / a) * sin(pi * y / a)
assert max(abs(mix(t, a - t)) for t in (0.03, 0.11, 0.2)) < 1e-12 and abs(mix(0.1, 0.1)) > 0.5

# ---- what breaks, and outside the range ----
print(f"wrong: drum overtone taken as 2 x f11: {2 * modes[0][0]:.1f} Hz, true next mode {modes[1][0]:.1f} Hz")
print(f"wrong: frequencies add, c/(2a) (1+2): {cd / (2 * a) * 3:.1f} Hz, true (1,2) {f_mn(1, 2):.1f} Hz")
print(f"wrong: dropped the 2, f1 = c/L: {c / L:.2f} Hz")
kf = allowed_k(2, free_end=True)
ff = [c * k / (2 * pi) for k in kf]
assert abs(ff[0] - c / (4 * L)) < 1e-6 * ff[0] and abs(ff[1] / ff[0] - 3) < 1e-6
print(f"wrong: one end free: notes {ff[0]:.2f} Hz, {ff[1]:.2f} Hz (odd multiples only)")
for A in (1e-3, 5e-3):                 # big swing in harmonic 1 stretches the string
    dT = E_steel * area * (pi * A / L) ** 2 / 4    # peak tension rise = EA x mean strain at full swing
    rise = 3 / 8 * f1 * dT / T         # the rise comes and goes twice a cycle: 3/8 of f1 dT/T, not 1/2
    print(f"swing {A * 1000:.0f} mm: peak tension +{dT:.2f} N, pitch +{rise:.2f} Hz, {100 * rise / f1:.2f}%")

# ---- beside it: an electron in a 1 nm box (CODATA 2022) ----
h, me, eV, Lb = 6.62607015e-34, 9.1093837139e-31, 1.602176634e-19, 1e-9
E1 = h * h / (8 * me * Lb * Lb)
print(f"electron, 1 nm box: E1 {E1:.4e} J; levels " + ", ".join(f"{n * n * E1 / eV:.3f}" for n in (1, 2, 3))
      + " eV; ratios 1 : 4 : 9 against the string's 1 : 2 : 3")
print("ALL CHECKS PASS")
