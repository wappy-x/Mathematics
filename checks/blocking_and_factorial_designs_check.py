# Blocking and a 2 x 2 factorial: fertiliser and watering -- the check behind the card.
# Standard library only. Roads: contrasts on cell means, least squares by Gaussian
# elimination, every complete randomisation enumerated, a seeded simulation (SplitMix64).
from math import sqrt, log, cos, pi
from itertools import combinations

MASK, state = (1 << 64) - 1, 20260929
def uniform():                                    # SplitMix64 -> a number in [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def normal():                                     # Box-Muller, one draw per call
    u1, u2 = uniform(), uniform()
    return sqrt(-2.0 * log(1.0 - u1)) * cos(2.0 * pi * u2)
def shuffle(a):                                   # Fisher-Yates
    for i in range(len(a) - 1, 0, -1):
        j = int(uniform() * (i + 1)); a[i], a[j] = a[j], a[i]
    return a

NAMES = ["neither", "fert", "water", "both"]     # cells 00, 10, 01, 11: fertiliser digit, water digit
SIGN = {"F": (-1, 1, -1, 1), "W": (-1, -1, 1, 1), "I": (1, -1, -1, 1)}
def effects(m): return {k: sum(s * x for s, x in zip(v, m)) / 2 for k, v in SIGN.items()}
TRUE = (20.0, 24.0, 26.0, 36.0)                   # true mean yield of each cell, kg
STRIP = (-4.0, 0.0, 4.0)                          # top, middle, bottom of the slope, kg
SIGMA = 1.5                                       # plot-to-plot noise, kg
Y = [[17, 19, 22, 34], [19, 24, 27, 35], [23, 31, 29, 39]]   # the season: strip x cell, kg
r, N = len(Y), 4 * len(Y)

# ---- road 1: contrasts on cell means, sums of squares by formula ----
cell = [sum(Y[j][k] for j in range(r)) / r for k in range(4)]
blk = [sum(row) / 4 for row in Y]
grand = sum(blk) / r
eff = effects(cell)
res_ss = sum((Y[j][k] - blk[j] - cell[k] + grand) ** 2 for j in range(r) for k in range(4))
within_ss = sum((Y[j][k] - cell[k]) ** 2 for j in range(r) for k in range(4))
strip_ss = 4 * sum((b - grand) ** 2 for b in blk)
s2_b, s2_u = res_ss / ((r - 1) * 3), within_ss / (4 * (r - 1))
se_b, se_u = sqrt(s2_b / r), sqrt(s2_u / r)

# ---- road 2: least squares on strip indicators and +/-1 columns ----
X, yv = [], []
for j in range(r):
    for k in range(4):
        xf, xw = (1.0 if k in (1, 3) else -1.0), (1.0 if k in (2, 3) else -1.0)
        X.append([1.0] + [1.0 if j == b else 0.0 for b in range(1, r)] + [xf, xw, xf * xw])
        yv.append(float(Y[j][k]))
def solve(A, b):                                  # Gaussian elimination, partial pivoting
    n = len(b); M = [row[:] + [v] for row, v in zip(A, b)]
    for i in range(n):
        p = max(range(i, n), key=lambda t: abs(M[t][i])); M[i], M[p] = M[p], M[i]
        for t in range(i + 1, n):
            f = M[t][i] / M[i][i]; M[t] = [a - f * c for a, c in zip(M[t], M[i])]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (M[i][n] - sum(M[i][t] * x[t] for t in range(i + 1, n))) / M[i][i]
    return x
P = len(X[0])
XtX = [[sum(row[a] * row[b] for row in X) for b in range(P)] for a in range(P)]
beta = solve(XtX, [sum(row[a] * v for row, v in zip(X, yv)) for a in range(P)])
ls_eff = {"F": 2 * beta[-3], "W": 2 * beta[-2], "I": 2 * beta[-1]}
ls_res = sum((v - sum(a * b for a, b in zip(row, beta))) ** 2 for row, v in zip(X, yv))
ls_se = [2 * sqrt(ls_res / 6 * solve(XtX, [float(t == a) for t in range(P)])[a]) for a in range(P - 3, P)]

# ---- road 3: every complete randomisation of the 12 plots, strips ignored ----
base = [b for b in STRIP for _ in range(4)]
Sb2 = sum((b - sum(base) / N) ** 2 for b in base) / (N - 1)
tot = tot2 = cnt = 0
for g0 in combinations(range(N), 3):
    rest = [i for i in range(N) if i not in g0]
    for g1 in combinations(rest, 3):
        rest2 = [i for i in rest if i not in g1]
        for g2 in combinations(rest2, 3):
            g3 = [i for i in rest2 if i not in g2]
            m = [sum(base[i] for i in g) / 3 for g in (g0, g1, g2, g3)]
            fb = (-m[0] + m[1] - m[2] + m[3]) / 2
            tot += fb; tot2 += fb * fb; cnt += 1
enum_mean, enum_var = tot / cnt, tot2 / cnt - (tot / cnt) ** 2

order = [shuffle([0, 1, 2, 3]) for _ in range(r)]  # the field plan: a lottery inside each strip

# ---- road 4: seeded simulation of R seasons, blocked and completely randomised ----
R = 20000
fb_sim, fc_sim, s2_sim = [], [], []
for _ in range(R):
    yb = [[TRUE[k] + STRIP[j] + SIGMA * normal() for k in range(4)] for j in range(r)]
    cb = [sum(yb[j][k] for j in range(r)) / r for k in range(4)]
    bb = [sum(row) / 4 for row in yb]; gb = sum(bb) / r
    fb_sim.append(effects(cb)["F"])
    s2_sim.append(sum((yb[j][k] - bb[j] - cb[k] + gb) ** 2 for j in range(r) for k in range(4)) / 6)
    lab = shuffle([k for k in range(4) for _ in range(r)])
    tc = [0.0] * 4
    for i in range(N): tc[lab[i]] += TRUE[lab[i]] + base[i] + SIGMA * normal()
    fc_sim.append(effects([t / r for t in tc])["F"])
def ms(xs):
    m = sum(xs) / len(xs); return m, sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1))
(mb, sdb), (mc, sdc), (m2, sd2) = ms(fb_sim), ms(fc_sim), ms(s2_sim)
ex_b, ex_c = sqrt(SIGMA ** 2 / r), sqrt((SIGMA ** 2 + Sb2) / r)

print("true effects       " + "  ".join(f"{k} {v:.4f}" for k, v in effects(TRUE).items())
      + f"  strips {STRIP[0]:.1f} {STRIP[1]:.1f} {STRIP[2]:.1f}  sigma {SIGMA:.1f}")
print("cell means, kg     " + "  ".join(f"{n} {c:.4f}" for n, c in zip(NAMES, cell)))
print("strip means, kg    " + "  ".join(f"{c:.4f}" for c in blk) + f"  grand {grand:.4f}")
for k, name in (("F", "fertiliser"), ("W", "watering"), ("I", "interaction")):
    print(f"{name:<12} contrast {eff[k]:8.4f}  least squares {ls_eff[k]:8.4f}  SE {se_b:.4f}")
print(f"fertiliser effect, dry plots {cell[1] - cell[0]:.4f}  watered plots {cell[3] - cell[2]:.4f}")
print(f"additive guess for both {cell[1] + cell[2] - cell[0]:.4f}  observed {cell[3]:.4f}")
print(f"residual SS, formula {res_ss:.4f}  least squares {ls_res:.4f}  df {(r - 1) * 3}")
print(f"blocked analysis    s^2 {s2_b:.4f}  s {sqrt(s2_b):.4f}  SE of an effect {se_b:.4f}")
print(f"strips ignored      s^2 {s2_u:.4f}  s {sqrt(s2_u):.4f}  SE of an effect {se_u:.4f}")
print(f"strip SS {strip_ss:.4f}  within-cell SS {within_ss:.4f}")
print(f"S_b^2, spread of plot baselines {Sb2:.4f}")
print(f"enumerated randomisations {cnt}  mean {enum_mean:.4f}  variance {enum_var:.4f}  S_b^2/r {Sb2 / r:.4f}")
print(f"exact SD of F-hat: blocked {ex_b:.4f}  completely randomised {ex_c:.4f}  variance ratio {ex_c ** 2 / ex_b ** 2:.4f}")
print(f"simulated {R} seasons: blocked mean {mb:.4f} SD {sdb:.4f} (+/- {sdb / sqrt(2 * R):.4f})")
print(f"  completely randomised mean {mc:.4f} SD {sdc:.4f} (+/- {sdc / sqrt(2 * R):.4f})")
print(f"  mean s^2 {m2:.4f} (+/- {sd2 / sqrt(R):.4f})  true sigma^2 {SIGMA ** 2:.4f}")
print(f"one at a time, 12 plots: SE {sqrt(6 * SIGMA ** 2 / N):.4f}  factorial SE {sqrt(4 * SIGMA ** 2 / N):.4f}"
      f"  plots to match {6 * N // 4}")
print("chart, dry then watered, unfertilised " + " ".join(f"{cell[k]:.2f}" for k in (0, 2))
      + ", fertilised " + " ".join(f"{cell[k]:.2f}" for k in (1, 3)))
for j, nm in enumerate(("top", "middle", "bottom")):
    print(f"figure, {nm} strip at y={20 + 70 * j}, plots 70 x 60 at x=70,140,210,280:",
          ", ".join(f"{NAMES[k]} {Y[j][k]}" for k in order[j]))

for k in "FWI":
    assert abs(eff[k] - ls_eff[k]) < 1e-9, f"{k}: contrast vs least squares"
assert abs(res_ss - ls_res) < 1e-9, "residual SS: formula vs least squares"
assert all(abs(se - se_b) < 1e-9 for se in ls_se), "SE of an effect: sqrt(s^2 / r) vs least squares"
assert abs(within_ss - res_ss - strip_ss) < 1e-9, "strips ignored: their SS joins the residual"
assert abs(enum_var - Sb2 / r) < 1e-9, "enumerated variance vs S_b^2 / r"
assert abs(enum_mean) < 1e-9, "over all randomisations the strips add no bias to F-hat"
assert abs(sdb / ex_b - 1) < 0.025, "blocked: simulated SD vs sigma / sqrt(r)"
assert abs(sdc / ex_c - 1) < 0.025, "randomised: simulated SD vs sqrt((sigma^2 + S_b^2) / r)"
for m, sd in ((mb, sdb), (mc, sdc)):
    assert abs(m - effects(TRUE)["F"]) < 4 * sd / sqrt(R), "both designs: F-hat centred on the true effect"
assert abs(m2 - SIGMA ** 2) < 4 * sd2 / sqrt(R), "residual variance with (r-1)*3 df is unbiased"
print("ALL CHECKS PASS")
