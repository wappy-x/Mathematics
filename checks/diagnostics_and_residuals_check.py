# Diagnostics and residuals -- the check behind the card.  Standard library only.
# Nine house sales, one of them a mansion: which sale is steering the line?
# Road 1: the leverage formulas.  Road 2: brute force -- nudge a price, or delete a sale,
# and refit.  Road 3: a seeded simulation of 50 sales whose spread grows with size.
from math import sqrt, log, cos, pi

AREA = [80, 100, 110, 120, 140, 150, 170, 190, 600]            # floor area, square metres
PRICE = [350, 390, 450, 440, 530, 540, 610, 650, 1400]         # sale price, $ thousands
N, P, M = len(AREA), 2, len(AREA) - 1                          # P: intercept and slope; M: the mansion

def fit(x, y):                                                  # least squares line: intercept, slope
    mx, my = sum(x) / len(x), sum(y) / len(y)
    sxx = sum((a - mx) ** 2 for a in x)
    b = sum((a - mx) * (c - my) for a, c in zip(x, y)) / sxx
    return my - b * mx, b

def resid(x, y, a, b): return [c - (a + b * v) for v, c in zip(x, y)]

def drop(v, i): return v[:i] + v[i + 1:]

a, b = fit(AREA, PRICE)
e = resid(AREA, PRICE, a, b)
s = sqrt(sum(r * r for r in e) / (N - P))                       # typical size of a residual
mx = sum(AREA) / N
sxx = sum((v - mx) ** 2 for v in AREA)
h = [1 / N + (v - mx) ** 2 / sxx for v in AREA]                 # road 1: leverage by formula
h_nudge = []                                                    # road 2: lift one price by 1, refit
for i in range(N):
    y2 = PRICE[:]; y2[i] += 1.0
    a2, b2 = fit(AREA, y2)
    h_nudge.append((a2 + b2 * AREA[i]) - (a + b * AREA[i]))
r = [e[i] / (s * sqrt(1 - h[i])) for i in range(N)]            # studentized, internal
t_f, t_r, d_f, d_r, del_f, del_r = [], [], [], [], [], []
for i in range(N):
    s_i2 = ((N - P) * s * s - e[i] ** 2 / (1 - h[i])) / (N - P - 1)
    t_f.append(e[i] / (sqrt(s_i2) * sqrt(1 - h[i])))             # road 1: external, by formula
    d_f.append(r[i] ** 2 * h[i] / (P * (1 - h[i])))              # road 1: Cook's distance
    del_f.append(e[i] / (1 - h[i]))                              # road 1: deletion residual
    ai, bi = fit(drop(AREA, i), drop(PRICE, i))                  # road 2: delete the sale, refit
    ei = resid(drop(AREA, i), drop(PRICE, i), ai, bi)
    si = sqrt(sum(q * q for q in ei) / (N - 1 - P))
    del_r.append(PRICE[i] - (ai + bi * AREA[i]))                  # the sale, priced by the other eight
    mi = sum(drop(AREA, i)) / (N - 1)
    sxx_i = sum((v - mi) ** 2 for v in drop(AREA, i))
    t_r.append(del_r[i] / (si * sqrt(1 + 1 / (N - 1) + (AREA[i] - mi) ** 2 / sxx_i)))   # its own error bar
    d_r.append(sum((a + b * v - ai - bi * v) ** 2 for v in AREA) / (P * s * s))

print("house   area  price  fitted  resid  leverage  lev by nudge")
for i in range(N):
    name = "mansion" if i == M else f"{i + 1:>7}"
    print(f"{name}{AREA[i]:>6}{PRICE[i]:>7}{a + b * AREA[i]:>8.1f}{e[i]:>7.1f}{h[i]:>10.3f}{h_nudge[i]:>14.3f}")
print("house   studentized  external  ext by refit   Cook's D  D by refit")
for i in range(N):
    name = "mansion" if i == M else f"{i + 1:>7}"
    print(f"{name}{r[i]:>13.2f}{t_f[i]:>10.2f}{t_r[i]:>14.2f}{d_f[i]:>11.3f}{d_r[i]:>12.3f}")
a0, b0 = fit(AREA[:M], PRICE[:M])
e0 = resid(AREA[:M], PRICE[:M], a0, b0)
s0 = sqrt(sum(q * q for q in e0) / (M - P))
sxx0 = sum((v - sum(AREA[:M]) / M) ** 2 for v in AREA[:M])
print(f"fit with the mansion:    intercept {a:.2f}, slope {b:.4f} (SE {s / sqrt(sxx):.4f}), "
      f"i.e. ${b * 1000:.0f} per m2; s = {s:.2f}")
print(f"fit without the mansion: intercept {a0:.2f}, slope {b0:.4f} (SE {s0 / sqrt(sxx0):.4f}), "
      f"i.e. ${b0 * 1000:.0f} per m2; s = {s0:.2f}")
print(f"mansion by hand: 1/N {1 / N:.4f}; area - mean {AREA[M] - mx:.2f}; squared {(AREA[M] - mx) ** 2:.1f}; "
      f"over Sxx {(AREA[M] - mx) ** 2 / sxx:.4f}; leverage {h[M]:.4f}")
print(f"mansion by hand: 1 - h {1 - h[M]:.4f}; root {sqrt(1 - h[M]):.3f} (house 1: {sqrt(1 - h[0]):.3f}); "
      f"s x root {s * sqrt(1 - h[M]):.2f}; r squared {r[M] ** 2:.2f}")
zero = abs(sum(e)) < 1e-9 and abs(sum(v * q for v, q in zip(AREA, e))) < 1e-9
print(f"mean area {mx:.2f}; Sxx {sxx:.2f}; residuals and area x residual both sum to 0: "
      f"{'yes' if zero else 'no'}; sum of leverages {sum(h):.4f}")
print(f"flag lines: leverage above 2P/N = {2 * P / N:.3f}; Cook's D above 1")
print(f"mansion's deletion residual: formula {del_f[M]:.1f}, refit {del_r[M]:.1f}; "
      f"line without it predicts {a0 + b0 * 600:.1f} for 600 m2")
rank = sorted(range(N), key=lambda i: -abs(e[i])).index(M) + 1
print(f"mistake, raw residual: mansion's |residual| {abs(e[M]):.1f} ranks {rank} of {N} by size")
print(f"mistake, one line for all: a 150 m2 house priced {a + b * 150:.1f} with the mansion, {a0 + b0 * 150:.1f} without")
print(f"mistake, extrapolating: 600 m2 predicted {a0 + b0 * 600:.1f}, sold {PRICE[M]}")
sx = lambda v: 40 + 0.45 * v                                    # figure 1: price against area
sy = lambda p: 210 - 0.09 * p
print("figure, houses " + " ".join(f"({sx(v):.1f},{sy(p):.1f})" for v, p in zip(AREA, PRICE)))
print(f"figure, line with mansion ({sx(60):.1f},{sy(a + b * 60):.1f}) ({sx(620):.1f},{sy(a + b * 620):.1f}); "
      f"without ({sx(60):.1f},{sy(a0 + b0 * 60):.1f}) ({sx(620):.1f},{sy(a0 + b0 * 620):.1f})")
fx = lambda f: 40 + 0.25 * (f - 300)                            # figure 2: residual against fitted
fy = lambda q: 120 - 2.0 * q
print("figure, residual plot " + " ".join(f"({fx(a + b * v):.1f},{fy(q):.1f})" for v, q in zip(AREA, e)))

MASK, state = (1 << 64) - 1, 20260928                           # road 3: SplitMix64, seed 20260928
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def unif(): return ((splitmix() >> 11) + 0.5) / 2.0 ** 53
def normal(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())

SALES, REPS = 50, 4000
xs = [60 + 180 * unif() for _ in range(SALES)]                  # 50 floor areas, fixed for every run
xm = sum(xs) / SALES
print(f"simulation: {SALES} sales, areas 60 to 240 m2, true price 120 + 2.8 x area, {REPS} runs, seed 20260928; "
      f"spread 40, or 40 x (area/150)^2")
sxx50 = sum((v - xm) ** 2 for v in xs)
for label, sd in (("even spread", lambda v: 40.0), ("funnel", lambda v: 40.0 * (v / 150) ** 2)):
    exact = sqrt(sum((v - xm) ** 2 * sd(v) ** 2 for v in xs)) / sxx50
    slopes, ses, hits, small, big = [], [], 0, 0.0, 0.0
    for rep in range(REPS):
        ys = [120 + 2.8 * v + sd(v) * normal() for v in xs]
        a5, b5 = fit(xs, ys)
        e5 = resid(xs, ys, a5, b5)
        se = sqrt(sum(q * q for q in e5) / (SALES - P) / sxx50)   # the textbook standard error
        slopes.append(b5); ses.append(se); hits += abs(b5 - 2.8) <= 2 * se
        small += sum(abs(q) for v, q in zip(xs, e5) if v < 120) / REPS
        big += sum(abs(q) for v, q in zip(xs, e5) if v >= 180) / REPS
    sim = sqrt(sum((q - sum(slopes) / REPS) ** 2 for q in slopes) / (REPS - 1))
    cover = hits / REPS
    nsm, nbg = sum(v < 120 for v in xs), sum(v >= 180 for v in xs)
    print(f"{label}: slope mean {sum(slopes) / REPS:.4f}; true SD exact {exact:.4f}, simulated {sim:.4f} "
          f"(+/- {sim / sqrt(2 * (REPS - 1)):.4f}); textbook SE {sum(ses) / REPS:.4f}")
    print(f"{label}: b +/- 2 SE covers 2.8 in {cover:.4f} (+/- {sqrt(cover * (1 - cover) / REPS):.4f}); "
          f"mean |resid| below 120 m2 {small / nsm:.1f}, 180 m2 and up {big / nbg:.1f}")
    assert abs(sim - exact) < 4 * sim / sqrt(2 * (REPS - 1))   # simulation agrees with the exact spread
    if label == "funnel": assert cover < 0.93 and sum(ses) / REPS < 0.9 * exact
assert all(abs(h[i] - h_nudge[i]) < 1e-9 for i in range(N))    # leverage: formula = nudge-and-refit
assert abs(sum(h) - P) < 1e-12                                  # leverages add up to the line's 2 numbers
assert all(abs(d_f[i] - d_r[i]) < 1e-9 * (1 + d_r[i]) for i in range(N))   # Cook's D: formula = deletion
assert all(abs(t_f[i] - t_r[i]) < 1e-9 and abs(del_f[i] - del_r[i]) < 1e-9 for i in range(N))
print("ALL CHECKS PASS")
