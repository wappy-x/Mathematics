# Differential entropy and water-filling -- the check behind the card.  Standard library only.
# A weather station: its daily temperature reading (spread 2 degrees C) and a radio with three
# frequency slots of noise power 1, 2 and 4 sharing a total signal power of 5.
# Roads: closed forms; Simpson's rule (thin slices under the curve); a seeded simulation;
# bin-by-bin sums; bisection for the water level; a grid search over every split of the power.
from math import log, log2, sqrt, exp, pi, e, cos

SIGMA = 2.0                      # spread of the daily reading, degrees C
NOISE = [1.0, 2.0, 4.0]          # noise power in each frequency slot
POWER = 5.0                      # total signal power the radio may spend

def simpson(f, a, b, n):
    hh = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * hh) for i in range(1, n))
    return s * hh / 3

def gauss(x, s): return exp(-x * x / (2 * s * s)) / sqrt(2 * pi * s * s)
def h_gauss(s): return 0.5 * log2(2 * pi * e * s * s)          # the formula
def h_simpson(s):                                              # -integral of f log2 f
    return simpson(lambda x: -gauss(x, s) * log2(gauss(x, s)), -12 * s, 12 * s, 4000)

def splitmix64(st):
    st = (st + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return st, z ^ (z >> 31)
def uniform(st):
    st, z = splitmix64(st)
    return st, ((z >> 11) + 1) / 2.0 ** 53

def h_rounded(s, step):          # entropy in bits of the reading rounded to bins of width step
    tot, k = 0.0, -int(8 * s / step) - 1
    while k * step < 8 * s:
        p = simpson(lambda x: gauss(x, s), k * step, (k + 1) * step, 8)
        if p > 0: tot -= p * log2(p)
        k += 1
    return tot

def capacity(powers, noise):     # bits per use over parallel bell-curve-noise slots
    return sum(0.5 * log2(1 + p / n) for p, n in zip(powers, noise))
def water_level(noise, total):   # bisection: the level nu whose poured power is the total
    lo, hi = 0.0, total + max(noise)
    for _ in range(200):
        mid = (lo + hi) / 2
        if sum(max(0.0, mid - n) for n in noise) < total: lo = mid
        else: hi = mid
    return (lo + hi) / 2
def water_fill(noise, total):
    nu = water_level(noise, total)
    return nu, [max(0.0, nu - n) for n in noise]

out = []
def show(name, v): out.append(f"{name:<44} {v:>12.6f}")

# ---- differential entropy of the reading ----
h_c, h_s = h_gauss(SIGMA), h_simpson(SIGMA)
st, acc, draws = 2026, 0.0, 200000
for _ in range(draws // 2):      # Box-Muller: two uniforms give two bell-curve draws
    st, u1 = uniform(st); st, u2 = uniform(st)
    r = sqrt(-2 * log(u1))
    for z in (r * cos(2 * pi * u2), r * cos(2 * pi * u2 - pi / 2)):
        acc += -log2(gauss(SIGMA * z, SIGMA))
h_mc = acc / draws
show("2 pi e x spread^2", 2 * pi * e * SIGMA ** 2); show("  log2 of it", log2(2 * pi * e * SIGMA ** 2))
show("h, reading in C, formula", h_c); show("  by Simpson", h_s); show("  by 200000 seeded draws", h_mc)
show("h, reading in F (spread 3.6)", h_simpson(3.6)); show("  log2 1.8", log2(1.8)); show("  formula h + log2 1.8", h_c + log2(1.8))
show("h, in tens of degrees (spread 0.2)", h_simpson(0.2)); show("h, uniform on 0 to 0.5", log2(0.5))
for n in (0, 2, 4):
    show(f"rounded to 1/{2 ** n} C: H by bins", h_rounded(SIGMA, 2.0 ** -n)); show(f"  h + {n}", h_c + n)
H01 = h_rounded(SIGMA, 0.1)
show("rounded to 0.1 C: H by bins", H01); show("  h + log2 10", h_c + log2(10))

# ---- the bell curve has the most, for a fixed variance ----
a = SIGMA * sqrt(3); b = SIGMA / sqrt(2)          # uniform on -a..a and Laplace with scale b: variance 4
h_uni, h_lap = log2(2 * a), log2(2 * e * b)
kl_uni = simpson(lambda x: (1 / (2 * a)) * log2((1 / (2 * a)) / gauss(x, SIGMA)), -a, a, 2000)
lap = lambda x: exp(-abs(x) / b) / (2 * b)
kl_lap = 2 * simpson(lambda x: lap(x) * log2(lap(x) / gauss(x, SIGMA)), 0.0, 30 * SIGMA, 20000)
show("uniform, same variance: h", h_uni); show("  gap to bell, h(bell) - h", h_c - h_uni); show("  D(uniform||bell) by Simpson", kl_uni)
show("Laplace, same variance: h", h_lap); show("  gap to bell, h(bell) - h", h_c - h_lap); show("  D(Laplace||bell) by Simpson", kl_lap)

# ---- water-filling ----
nu, pw = water_fill(NOISE, POWER)
c_wf = capacity(pw, NOISE)
best, arg, splits = -1.0, None, 0                   # every split in steps of 0.01
for i in range(501):
    for j in range(501 - i):
        splits += 1; c = capacity([i / 100, j / 100, (500 - i - j) / 100], NOISE)
        if c > best: best, arg = c, (i / 100, j / 100, (500 - i - j) / 100)
slopes = [1 / (2 * log(2) * (p + n)) for p, n in zip(pw, NOISE)]
c_uni = capacity([POWER / 3] * 3, NOISE)
c_one = capacity([POWER, 0, 0], NOISE)
c_snr = capacity([POWER * n / sum(NOISE) for n in NOISE], NOISE)
c_stale = capacity(pw, NOISE[::-1])
show("water level nu, by bisection", nu)
for k in range(3): show(f"  power in slot {k + 1} (noise {NOISE[k]:.0f})", pw[k])
show("capacity, bits per use", c_wf)
show("grid search, splits tried", splits); show("grid search best, steps of 0.01", best)
for k in range(3): show(f"  at power in slot {k + 1}", arg[k])
out.append("equal split, bits in each slot: " + " ".join(f"{capacity([POWER / 3], [n]):.6f}" for n in NOISE))
show("wrong: equal split 5/3 each", c_uni); show("  water-filling gain over it, percent", 100 * (c_wf / c_uni - 1)); show("wrong: all power in slot 1", c_one)
show("wrong: equal S/N, more to noisy slots", c_snr); show("wrong: stale noise map, truth 4, 2, 1", c_stale)
show("  water-filled for 4, 2, 1", capacity(water_fill(NOISE[::-1], POWER)[1], NOISE[::-1]))
show("try: power 12, level", water_level(NOISE, 12.0)); show("  capacity", capacity(water_fill(NOISE, 12.0)[1], NOISE))
show("try: power 1, water-filled", capacity(water_fill(NOISE, 1.0)[1], NOISE)); show("  equal split", capacity([1 / 3] * 3, NOISE))
show("try: slot 3 noise 3, level", water_level([1.0, 2.0, 3.0], POWER))
show("  capacity", capacity(water_fill([1.0, 2.0, 3.0], POWER)[1], [1.0, 2.0, 3.0]))
show("try: spread 4 C, h", h_gauss(4.0))
chart_wf = [capacity(water_fill(NOISE, float(p))[1], NOISE) for p in range(11)]
chart_eq = [capacity([p / 3] * 3, NOISE) for p in range(11)]
print("\n".join(out))
print("chart, water-filled, power 0..10:", " ".join(f"{v:.3f}" for v in chart_wf))
print("chart, equal split,  power 0..10:", " ".join(f"{v:.3f}" for v in chart_eq))
print("slope of each slot at its power:", " ".join(f"{v:.6f}" for v in slopes))
print("figure, y = 200 - 40 v: noise tops", " ".join(f"{200 - 40 * n:.1f}" for n in NOISE), "water", f"{200 - 40 * nu:.1f}")

assert abs(h_c - h_s) < 1e-9                        # formula against the integral
assert abs(h_mc - h_c) < 4 * sqrt(2) / (2 * log(2)) / sqrt(draws)   # within 4 standard errors
assert abs(h_simpson(3.6) - (h_c + log2(1.8))) < 1e-9 and h_simpson(0.2) < 0
assert abs(H01 - (h_c + log2(10))) < 1e-3          # rounded reading: h + log2(1/step)
assert abs((h_c - h_uni) - kl_uni) < 1e-9 and abs((h_c - h_lap) - kl_lap) < 1e-6
assert abs(nu - 4) < 1e-9 and abs(c_wf - (0.5 * log2(4) + 0.5 * log2(2))) < 1e-9
assert abs(best - c_wf) < 1e-12 and arg == (3.0, 2.0, 0.0)   # brute force finds the same split
assert max(c_uni, c_one, c_snr, c_stale) < c_wf
assert all(chart_wf[p] >= chart_eq[p] - 1e-12 for p in range(11))
lam = 1 / (2 * log(2) * nu)                        # Step 5: every used slot's slope is lam, a dry slot's no more
nudge = [(capacity([q + 1e-6 * (k == i) for k, q in enumerate(pw)], NOISE) - c_wf) / 1e-6 for i in range(3)]
assert all(abs(g - s) < 1e-6 and (abs(s - lam) < 1e-9 if p > 0 else s <= lam + 1e-12) for g, s, p in zip(nudge, slopes, pw))
print("ALL CHECKS PASS")
