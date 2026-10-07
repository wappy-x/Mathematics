# Brownian paths: scaling by root t, continuous everywhere, smooth nowhere.  Std lib only.
# A pollen grain's position W_t in micrometres (um), t in seconds, spread 1 um^2 per s.
# Roads: formulas; exact coin-flip walk; seeded simulation (SplitMix64 20260930, Box-Muller).
from math import sqrt, log, cos, sin, pi, exp

M64 = (1 << 64) - 1
state = 20260930
spare = None

def uniform():                          # SplitMix64 -> a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0**53

def normal():                           # Box-Muller, both values of each pair used
    global spare
    if spare is not None:
        z, spare = spare, None
        return z
    r, th = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    spare = r * sin(th)
    return r * cos(th)

def phi_simpson(x):                     # normal CDF, Simpson's rule on the density
    n, h = 2000, x / 2000
    s = sum((4 if i % 2 else 2) * exp(-(i * h) * (i * h) / 2) for i in range(1, n))
    return 0.5 + (s + 1.0 + exp(-x * x / 2)) * h / 3 / sqrt(2 * pi)

def phi_series(x):                      # normal CDF, Taylor series of the integral
    term, total, n = x, x, 0
    while abs(term) > 1e-17:
        n += 1
        term *= -x * x / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

def g(t):                               # a smooth curve, for contrast, in um
    return 2.0 * sin(pi * t / 8.0)

def mean_se(xs):
    m = sum(xs) / len(xs)
    v = sum((x - m) * (x - m) for x in xs) / (len(xs) - 1)
    return m, sqrt(v / len(xs))

print("grain: W_t in um, t in s, spread 1 um^2 per second; SplitMix64 seed 20260930")
print(f"Phi(1) by Simpson {phi_simpson(1.0):.9f}, by series {phi_series(1.0):.9f}")
assert abs(phi_simpson(1.0) - phi_series(1.0)) < 1e-9, "the two normal CDFs disagree"
print("E|W_t| = sqrt(2t/pi), t = 1, 4, 16 s: " + " ".join(f"{sqrt(2 * t / pi):.4f}" for t in (1, 4, 16)))
print(f"K sqrt(h) for K = 10 um/s, h = 1/4096 s: {10 * sqrt(1 / 4096):.5f}")

# ---- one path over 16 s, refined by midpoints: level k = sampled every 2^-k s ----
w = [0.0]
for i in range(16):
    w.append(w[-1] + normal())
for k in range(1, 13):
    sd, new = sqrt(1.0 / 2 ** (k - 1)) / 2.0, [w[0]]
    for a, b in zip(w, w[1:]):
        new += [(a + b) / 2.0 + sd * normal(), b]
    w = new                             # earlier points never move: the same path, finer
FINE = 4096                             # points per second at level 12

print("level  step(s)  max|step|  mean|slope| +- se   formula   smooth")
lv_rows, mean_slopes = [], []
for k in range(0, 13, 2):
    st, dt = FINE // 2 ** k, 1.0 / 2 ** k
    pts = w[::st]
    slopes = [abs(b - a) / dt for a, b in zip(pts, pts[1:])]
    m, se = mean_se(slopes)
    big = max(abs(b - a) for a, b in zip(pts, pts[1:]))
    sm = sum(abs(g((i + 1) * dt) - g(i * dt)) for i in range(len(slopes))) / dt / len(slopes)
    f = sqrt(2.0 / (pi * dt))
    mean_slopes.append((m, f))
    print(f"{k:5d} {dt:9.6f} {big:9.4f} {m:10.4f} +- {se:6.4f} {f:9.4f} {sm:8.4f}")
    assert abs(m - f) < 4 * se, "mean |slope| off the root-t prediction"
    frac = sum(1 for s in slopes if s > 10.0) / len(slopes)
    p = max(0.0, 2.0 * (1.0 - phi_simpson(10.0 * sqrt(dt))))
    fse = sqrt(frac * (1 - frac) / len(slopes))
    assert abs(frac - p) < 4 * fse + 1.0 / len(slopes), "slope tail off the formula"
    i8, ih = 8 * FINE, 8 * FINE + st
    lv_rows.append((k, frac, fse, p, (w[ih] - w[i8]) / dt, (w[ih] - w[i8]) / sqrt(dt),
                    (g(8 + dt) - g(8)) / dt))
print("level  frac|slope|>10 +- se  formula   chord(8)  chord*sqrt(h)  smooth chord")
for k, frac, fse, p, ch, rch, sch in lv_rows:
    print(f"{k:5d} {frac:10.4f} +- {fse:6.4f} {p:9.4f} {ch:10.4f} {rch:10.4f} {sch:12.4f}")
assert abs(lv_rows[-1][6] + pi / 4) < 1e-6, "smooth chord must settle on its slope -pi/4"

# ---- the scaling law tested on simulated paths: V_t = W(4t)/2 ----
M, STEPS = 20000, 32                    # 32 steps of 1/8 s cover 4 s
w2s, w4s = [], []
for _ in range(M):
    x = 0.0
    for j in range(1, STEPS + 1):
        x += sqrt(1.0 / 8.0) * normal()
        if j == 16:
            w2s.append(x)
    w4s.append(x)
v_half, v_one = [x / 2 for x in w2s], [x / 2 for x in w4s]
print(f"-- scaling, V_t = W(4t)/2, {M} paths on a 1/8 s grid --")
rows = [("Var V_1", [x * x for x in v_one], 1.0),
        ("Cov V_0.5 V_1", [a * b for a, b in zip(v_half, v_one)], 0.5),
        ("P(|V_1| <= 1)", [1.0 if abs(x) <= 1 else 0.0 for x in v_one], 2 * phi_series(1.0) - 1),
        ("E|V_1|", [abs(x) for x in v_one], sqrt(2 / pi)),
        ("wrong: Var W(4t)/4", [(x / 4) * (x / 4) for x in w4s], 0.25),
        ("wrong: Var W(4t)", [x * x for x in w4s], 4.0)]
for label, xs, f in rows:
    m, se = mean_se(xs)
    print(f"{label:<20} sim {m:7.4f} +- {se:6.4f}   formula {f:7.4f}")
    assert abs(m - f) < 4 * se, label

# ---- coin-flip walk, exact over every path: E|S_m| / sqrt(m) ----
vals = []
for mm in (1, 4, 16, 64, 256):
    pmf, tot = 0.5 ** mm, 0.0
    for kk in range(mm + 1):
        tot += pmf * abs(2 * kk - mm)
        pmf *= (mm - kk) / (kk + 1)
    vals.append(tot / sqrt(mm))
print("walk E|S_m|/sqrt(m), m = 1 4 16 64 256: " + " ".join(f"{v:.6f}" for v in vals)
      + f"; limit {sqrt(2 / pi):.6f}")
assert abs(vals[-1] - sqrt(2 / pi)) < 0.002, "walk does not approach the Brownian value"

# ---- the proof's bound, one second, K = 1 um/s ----
print("proof: n P(|Z| <= 7/sqrt n)^3 and 343/sqrt n, n = 2^12 2^16 2^20 2^24:")
for e in (12, 16, 20, 24):
    n = 2.0 ** e
    exact, bound = n * (2 * phi_series(7 / sqrt(n)) - 1) ** 3, 343 / sqrt(n)
    print(f"  2^{e}: {exact:.4f}  {bound:.4f}")
    assert exact <= bound, "the proof's bound fails"

# ---- chart points ----
print("chart, time (s)      " + " ".join(f"{0.5 * i:.1f}" for i in range(33)))
print("chart, whole path    " + " ".join(f"{w[i * FINE // 2]:.2f}" for i in range(33)))
print("chart, zoomed path   " + " ".join(f"{4 * (w[8 * FINE + i * FINE // 32] - w[8 * FINE]):.2f}" for i in range(33)))
print("chart, zoomed smooth " + " ".join(f"{4 * (g(8 + i / 32) - g(8)):.2f}" for i in range(33)))
print("chart, mean slope    " + " ".join(f"{m:.2f}" for m, f in mean_slopes))
print("chart, formula       " + " ".join(f"{f:.2f}" for m, f in mean_slopes))
print("ALL CHECKS PASS")
