# Approximate identities -- the check behind the card.  Standard library only;
# math gives sin, cos, exp, sqrt and pi.  A thermocouple moves from 20 C air into
# stirred 60 C tea at t = 0 s; it reads 1,000 times a second with 0.5 C of noise.
# A centred moving average of width eps is convolution with the box K_eps(s) = 1/eps
# on |s| < eps/2.  Roads: the box's closed form, the moving average of the readings
# (midpoint sum), and Simpson's rule on the convolution integral.
from math import sin, cos, exp, sqrt, pi

def f(t):    return 20.0 if t < 0 else 60.0 + 2.0 * sin(2 * pi * t)    # true temperature, C
def fl(t):   return 20.0 if t <= 0 else f(t)                       # f with its left limit at the jump
def F(t):    return 20.0 * t if t < 0 else 60.0 * t - cos(2 * pi * t) / pi + 1 / pi
def box(x, e):  return (F(x + e / 2) - F(x - e / 2)) / e     # road 1: closed form
def sinc(u): return sin(pi * u) / (pi * u)
def total(xs):                      # plain left-to-right sum, as in the Rust twin
    s = 0.0
    for x in xs: s += x
    return s

def simpson(g, a, b, n):
    h = (b - a) / n
    s = g(a) + g(b) + total((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def conv(K, lo, hi, x, n=2000):     # road 3: integral of K(s) f(x - s), split at the jump s = x
    if not lo < x < hi:
        return simpson(lambda s: K(s) * f(x - s), lo, hi, n)
    return simpson(lambda s: K(s) * f(x - s), lo, x, n) + simpson(lambda s: K(s) * fl(x - s), x, hi, n)

def midpoint(x, e, rate=1000):      # road 2: average of the clean readings inside the window
    n = round(e * rate)
    k0 = round((x - e / 2) * rate)
    return total(f((k0 + k + 0.5) / rate) for k in range(n)) / n

def l1_gap(e):                      # integral of |box average - f| over the record -1..2 s
    pts, ff = [-1, -e / 2, 0, e / 2, 2], [fl, fl, f, f]   # left of 0, the left limit 20 C
    return total(simpson(lambda x: abs(box(x, e) - ff[i](x)), pts[i], pts[i + 1], 4000) for i in range(4))

state = 2026
def uniform():                      # SplitMix64, seed 2026
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def noise():  return 0.5 * (total(uniform() for _ in range(12)) - 6.0)   # sd exactly 0.5 C

E = 0.1
print("signal: 20 C before 0 s, 60 + 2 sin(2 pi t) C after; box width eps = 0.1 s")
b1, b2 = box(0.25, E), midpoint(0.25, E)
b3 = conv(lambda s: 1 / E, -E / 2, E / 2, 0.25)
bias_est = -2 * (2 * pi) ** 2 * E * E / 24              # f'' * eps^2 / 24 at the peak
print(f"t=0.25 s: true 62.000000  closed {b1:.6f}  100 readings {b2:.6f}  simpson {b3:.6f}")
print(f"t=0.25 s: gap {b1 - 62:.6f}  curvature estimate f''*eps^2/24 {bias_est:.6f}")
assert abs(b1 - b2) < 1e-4 and abs(b1 - b3) < 1e-9
assert abs((b1 - 62) - bias_est) < 0.001
j1, j2 = box(0, E), midpoint(0, E)
print(f"t=0 s jump: left 20  right 60  closed {j1:.6f}  100 readings {j2:.6f}  formula 40+(1-cos(pi eps))/(pi eps) {40 + (1 - cos(pi * E)) / (pi * E):.6f}")
assert abs(j1 - j2) < 1e-4 and abs(j1 - 40 - (1 - cos(pi * E)) / (pi * E)) < 1e-9

print("eps sweep: eps s | gap at 0.25 s | average at 0 s | worst gap | L1 gap on record C*s | L1/eps")
for e in [0.2, 0.1, 0.05, 0.025, 0.0125]:
    L = l1_gap(e)
    worst = box(0, e) - 20                               # just left of the jump
    grid = max(abs(box(x / 1e4, e) - f(x / 1e4)) for x in range(-10000, 20001, 7))
    print(f"  {e:.4f} | {box(0.25, e) - 62:.6f} | {box(0, e):.6f} | {worst:.6f} | {L:.6f} | {L / e:.4f}")
    assert grid <= worst + 1e-9 and worst > 20             # the worst gap never falls below 20 C
    assert abs(L - (10 * e + 8 / pi * (1 - sinc(e)))) < 1e-6   # jump part J*eps/4 plus the swing part

print("noise: one reading sd 0.5 C; mean of n readings sd 0.5/sqrt(n)")
for e in [0.025, 0.05, 0.1, 0.2, 0.4]:
    n = round(e * 1000)
    print(f"  eps {e:.3f} s: n {n:3d}  noise sd {0.5 / sqrt(n):.4f}  bias at peak {2 * (1 - sinc(e)):.4f}")
means = [total(noise() for _ in range(100)) / 100 for _ in range(2000)]
m = total(means) / 2000
sd = sqrt(total((x - m) ** 2 for x in means) / 1999)
print(f"simulated: 2000 windows of 100 readings, sd of the window mean {sd:.4f} (theory 0.0500)")
assert abs(sd - 0.05) < 4 * 0.05 / sqrt(2 * 1999)
noisy = [f((k + 0.5) / 1000) + noise() for k in range(200, 300)]
print(f"one noisy run: reading at 0.2495 s {noisy[49]:.4f}  moving average at 0.25 s {total(noisy) / 100:.4f}")
errs = sorted(abs(noisy[k] - f((k + 200.5) / 1000)) for k in range(100))
print(f"  its 100 readings: median error {(errs[49] + errs[50]) / 2:.4f}  largest {errs[99]:.4f}  average's error {abs(total(noisy) / 100 - 62):.4f}")
print(f"faster stirring, 5 Hz swing: peak 62 reads {60 + 2 * sinc(0.5):.6f}")

print("what breaks, at t = 0.25 s, eps = 0.1 s unless said")
print(f"  weights add to 0.9: {0.9 * b1:.6f}  limit {0.9 * 62:.6f}")
tr = conv(lambda s: 1 / E, 0, E, 0.25)
print(f"  trailing window (past 0.1 s only): {tr:.6f}  gap {tr - 62:.6f}  at the jump {(F(0) - F(-E)) / E:.6f}")
assert abs(tr - (60 + (cos(0.3 * pi) - cos(0.5 * pi)) / (0.1 * pi))) < 1e-9
leak = 0.9 * 62 + 0.1 * (F(0.75) - F(-0.25))
print(f"  10% of weight on a fixed 1 s average: limit {leak:.6f}")

# density of smooth signals: the bump eta(u) = exp(-1/(1-u^2))/Z, half-width eps
raw = lambda u: exp(-1 / (1 - u * u)) if abs(u) < 1 else 0.0
Z = simpson(raw, -1, 1, 4000)
m1 = simpson(lambda u: abs(u) * raw(u), -1, 1, 4000) / Z
assert abs(Z - simpson(raw, -1, 1, 2000)) < 1e-9
print(f"bump: Z {Z:.6f}  mean distance m1 {m1:.6f}")
for e in [0.05, 0.01]:
    sm = lambda x: conv(lambda s: raw(s / e) / (Z * e), -e, e, x, 200)
    gap = simpson(lambda x: abs(sm(x) - fl(x)), -e, 0, 200) + simpson(lambda x: abs(sm(x) - f(x)), 0, e, 200)
    print(f"  eps {e:.2f} s: L1 gap near the jump {gap:.6f} C*s  predicted 40*m1*eps {40 * m1 * e:.6f}")
    assert abs(gap - 40 * m1 * e) < 0.001 * 40 * m1 * e   # the window around the jump

ts = [round(-0.15 + 0.05 * i, 2) for i in range(14)]
print("chart t:", " ".join(f"{t:.2f}" for t in ts))
print("chart f:", " ".join(f"{f(t):.2f}" for t in ts))
print("chart box 0.1:", " ".join(f"{box(t, 0.1):.2f}" for t in ts))
print("chart box 0.02:", " ".join(f"{box(t, 0.02):.2f}" for t in ts))
print("ALL CHECKS PASS")
