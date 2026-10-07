# Correlated paths -- the check behind the card.  Nothing is imported that
# already holds an answer: the factor, the normal draws, the standard
# deviations and the correlations are written out here.  Three shares, Borex
# at $80, Acme at $100 and Cobalt at $120, each 20% volatility, every pair of
# shocks correlated 0.5, watched at 0.25, 0.5 and 1 year.
from math import cos, exp, log, pi, sin, sqrt

RHO, SIG, RATE, PATHS, SEED = 0.5, 0.20, 0.05, 6000, 20260914
SPOTS, INCOME = (80.0, 100.0, 120.0), (0.01, 0.02, 0.03)
TIMES, STEPS, RHOS = (0.25, 0.5, 1.0), (0.25, 0.25, 0.5), (-0.25, 0.0, 0.5, 0.75)
DIALS = (-0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0)
PAIRS = ((0, 1), (0, 2), (1, 2))

def equi(rho):                              # one correlation for every pair of shares
    return [[1.0 if i == j else rho for j in range(3)] for i in range(3)]
def dot(x, y): return sum(p * q for p, q in zip(x, y))
def gram(m): return [[dot(r, s) for s in m] for r in m]   # row lengths squared down the diagonal, row dot products off it
def worst(m, t): return max(abs(m[i][j] - t[i][j]) for i in range(len(m)) for j in range(len(m[0])))
def quad(a, x): return sum(x[i] * a[i][j] * x[j] for i in range(3) for j in range(3))   # the variance of a portfolio x
def chol(a):                                # the factor, one column at a time
    n, low = len(a), [[0.0] * len(a) for _ in a]
    for j in range(n):
        pivot = a[j][j] - sum(low[j][k] ** 2 for k in range(j))
        if pivot <= 0.0:
            return None, pivot              # no factor with a positive diagonal exists
        low[j][j] = sqrt(pivot)
        for i in range(j + 1, n):
            low[i][j] = (a[i][j] - sum(low[i][k] * low[j][k] for k in range(j))) / low[j][j]
    return low, 0.0
def spread(col):                            # standard deviation of one column of numbers
    mean = sum(col) / len(col)
    return sqrt(sum((v - mean) ** 2 for v in col) / len(col))
def link(xs, ys):                           # sample correlation of two columns
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    top = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    return top / sqrt(sum((x - mx) ** 2 for x in xs) * sum((y - my) ** 2 for y in ys))
def draws(count, seed):                     # uniforms from a counter, paired into normals
    out, state = [], seed
    while len(out) < count:
        state = (1664525 * state + 1013904223) % 4294967296
        u = (state + 0.5) / 4294967296
        state = (1664525 * state + 1013904223) % 4294967296
        v = (state + 0.5) / 4294967296
        radius, angle = sqrt(-2.0 * log(u)), 2.0 * pi * v
        out += [radius * cos(angle), radius * sin(angle)]
    return out
def walk(mixer, normals):                   # every path: mix, accumulate, then price
    shock = [[[0.0] * PATHS for _ in range(3)] for _ in range(3)]      # [date][share][path]
    ret, gap, ledger = [[0.0] * PATHS for _ in range(3)], 0.0, 0
    for p in range(PATHS):
        w, stock = [0.0, 0.0, 0.0], list(SPOTS)
        for k in range(3):
            z = normals[9 * p + 3 * k:9 * p + 3 * k + 3]
            for i in range(3):
                dw = sqrt(STEPS[k]) * dot(mixer[i], z)
                w[i] += dw
                drift = RATE - INCOME[i] - 0.5 * SIG * SIG
                stock[i] *= exp(drift * STEPS[k] + SIG * dw)             # road one: step by step
                direct = SPOTS[i] * exp(drift * TIMES[k] + SIG * w[i])   # road two: one exponential
                gap, ledger = max(gap, abs(stock[i] / direct - 1.0)), ledger + 1
                shock[k][i][p] = w[i]
        for i in range(3):
            ret[i][p] = stock[i] / SPOTS[i] - 1.0
    return shock, ret, gap, ledger
def row(label, values): print(f"{label:<47}" + "".join(f"{v:>12.6f}" for v in values))
def tiny(label, value): print(f"{label:<47}{value:>16.12f}")
def chart(label, values): print(f"{label:<47}" + "".join(f"{v:>8.2f}" for v in values))

low, _ = chol(equi(RHO))
hand = [[1.0, 0.0, 0.0], [0.5, sqrt(3.0) / 2.0, 0.0], [0.5, 1.0 / (2.0 * sqrt(3.0)), sqrt(2.0 / 3.0)]]
one = [[sqrt(RHO)] + [sqrt(1.0 - RHO) if j == i else 0.0 for j in range(3)] for i in range(3)]
side = [[low[j][i] for j in range(3)] for i in range(3)]          # the factor laid on its side
bad = [[1.0, 0.9, 0.9], [0.9, 1.0, -0.9], [0.9, -0.9, 1.0]]       # correlations that cannot happen
bad_low, bad_pivot = chol(bad)
entries, off_grid = 0, 0.0
for rho in RHOS:                            # the clock, by exact coefficient algebra
    matrix, (lo, _) = equi(rho), chol(equi(rho))
    coef = [[sqrt(STEPS[k]) * lo[i][j] if k <= a else 0.0 for k in range(3) for j in range(3)]
            for a in range(3) for i in range(3)]
    for a in range(3):
        for b in range(3):
            for i in range(3):
                for j in range(3):
                    want = matrix[i][j] * min(TIMES[a], TIMES[b])
                    off_grid = max(off_grid, abs(dot(coef[3 * a + i], coef[3 * b + j]) - want))
                    entries += 1
shock, ret, gap, ledger = walk(low, draws(9 * PATHS, SEED))
basket = [(shock[2][0][p] + shock[2][1][p] + shock[2][2][p]) / 3.0 for p in range(PATHS)]
model = (exp(RHO * SIG * SIG) - 1.0) / (exp(SIG * SIG) - 1.0)
fat = (exp(RHO * 0.36) - 1.0) / (exp(0.36) - 1.0)
theory = [100.0 * SIG * sqrt((1.0 + 2.0 * d) / 3.0) for d in DIALS]
raw, sideways, mixgap = gram(equi(RHO)), gram(side), worst(one, [r + [0.0] for r in low])

row("correlation asked for, every pair", [RHO])
for i in range(3):
    row(f"L row {i + 1}", low[i])
row("length of each L row", [sqrt(dot(low[i], low[i])) for i in range(3)])
tiny("hand-written factor, worst entry off L", worst(low, hand))
tiny("L L^T rebuilt, worst entry off R", worst(gram(low), equi(RHO)))
row("one-factor mixer row 1", one[0])
tiny("one-factor mixer, worst entry off R", worst(gram(one), equi(RHO)))
tiny("the two mixers differ, worst entry", mixgap)
print(f"grid covariance entries checked                 {entries}")
tiny("grid covariance, worst gap off rho x min(ta,tb)", off_grid)
print(f"paths {PATHS}, normal draws {9 * PATHS}, seed {SEED}")
print(f"stock ledger comparisons                       {ledger}")
tiny("stepwise price vs one exponential, worst gap", gap)
row("sample sd of Borex shock at 0.25, 0.5, 1 year", [spread(shock[k][0]) for k in range(3)])
row("sqrt of the time elapsed, same three dates", [sqrt(t) for t in TIMES])
row("sample sd of each shock at 1 year", [spread(shock[2][i]) for i in range(3)])
row("sample shock correlation, pairs 1-2, 1-3, 2-3", [link(shock[2][i], shock[2][j]) for i, j in PAIRS])
row("sample percent-return correlation, same pairs", [link(ret[i], ret[j]) for i, j in PAIRS])
row("model percent-return correlation at 1 year", [model])
tiny("the same value written 1/(1 + e^0.02), gap", abs(model - 1.0 / (1.0 + exp(RHO * SIG * SIG))))
row("model percent-return correlation at 60% vol", [fat])
row("three-share average sd at 1 year, percent", [100.0 * SIG * spread(basket), theory[4]])
chart("chart, correlation dial", DIALS)
chart("chart, three-share average sd, percent", theory)
chart("chart, one share alone, percent", [100.0 * SIG] * 7)
row("wrong: R as the mixer: variance, sd, corr 1-2", [raw[0][0], sqrt(raw[0][0]), raw[0][1] / raw[0][0]])
row("wrong: L on its side: three variances", [sideways[i][i] for i in range(3)])
row("wrong: L on its side: correlation 1-2", [sideways[0][1] / sqrt(sideways[0][0] * sideways[1][1])])
print(f"wrong: impossible dial has no factor           {'yes' if bad_low is None else 'no'}")
row("wrong: impossible dial: third pivot, (1,-1,-1)", [bad_pivot, quad(bad, (1.0, -1.0, -1.0))])

assert worst(low, hand) < 1e-15, "the recurrence must land on the hand-written factor"
assert worst(gram(low), equi(RHO)) < 1e-15, "L L^T must rebuild R"
assert worst(gram(one), equi(RHO)) < 1e-15, "the one-factor mixer must rebuild R as well"
assert mixgap > 0.1, "two mixers rebuild one R: only the triangular one with a positive diagonal is unique"
assert off_grid < 1e-12, "grid covariance must equal rho times the earlier date"
assert bad_low is None, "the impossible dial must break the factor"
assert quad(bad, (1.0, -1.0, -1.0)) < 0.0, "and hold a portfolio of negative variance"
assert gap < 1e-12, "stepping the price must match one exponential"
assert all(abs(spread(shock[k][0]) - sqrt(TIMES[k])) < 0.05 for k in range(3)), "spread grows as sqrt of time"
assert all(abs(link(shock[2][i], shock[2][j]) - RHO) < 0.03 for i, j in PAIRS), "sample shocks near the dial"
assert all(abs(link(ret[i], ret[j]) - model) < 0.03 for i, j in PAIRS), "sample returns near the model"
assert abs(model - 1.0 / (1.0 + exp(RHO * SIG * SIG))) < 1e-12, "two roads to the model correlation"
assert abs(100.0 * SIG * spread(basket) - theory[4]) < 1.0, "average-share spread, sample against theory"
print("ALL CHECKS PASS")
