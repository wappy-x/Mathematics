# Seasonal gas curve -- the check behind the card.  Standard library only.
# A 12-month Henry Hub strip (USD/MMBtu, illustrative) is fitted to a level times
# a yearly cosine shape by two roads, then the summer-to-winter storage bound is
# found by a formula and by pricing the trade's cash flows and searching.
from math import log, exp, cos, sin, atan2, pi, sqrt

MONTHS = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
STRIP = [2.70, 2.55, 2.50, 2.50, 2.55, 2.62, 2.75, 3.05, 3.35, 3.50, 3.40, 3.05]
r, c, FS, FW = 0.05, 0.60, 2.50, 3.50        # rate, all-in storage cost, July and January forwards
TS, TW = 3 / 12, 9 / 12                       # delivery times in years from 1 April
TAU = TW - TS
y = [log(f) for f in STRIP]
th = [2 * pi * m / 12 for m in range(12)]

# Road 1 to the shape: over 12 evenly spaced months cos and sin are orthogonal, so each
# coefficient is an average (a discrete Fourier sum).
a1 = sum(y) / 12
A1 = 2 / 12 * sum(v * cos(t) for v, t in zip(y, th))
B1 = 2 / 12 * sum(v * sin(t) for v, t in zip(y, th))

# Road 2: ordinary least squares, normal equations solved by Gaussian elimination.
def solve(M, v):
    n = len(v); M = [row[:] + [v[i]] for i, row in enumerate(M)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k])); M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            f = M[i][k] / M[k][k]
            M[i] = [M[i][j] - f * M[k][j] for j in range(n + 1)]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x
X = [[1.0, cos(t), sin(t)] for t in th]
XtX = [[sum(row[i] * row[j] for row in X) for j in range(3)] for i in range(3)]
Xty = [sum(row[i] * v for row, v in zip(X, y)) for i in range(3)]
a2, A2, B2 = solve(XtX, Xty)

L = exp(a1)
beta = sqrt(A1 * A1 + B1 * B1)                   # the hypotenuse of A and B
t0 = (atan2(B1, A1) / (2 * pi)) % 1.0            # peak time, years from 1 April
fit = [L * exp(beta * cos(2 * pi * (m / 12 - t0))) for m in range(12)]

# The storage bound.  Road 1: the formula.
cap1 = c + FS * (exp(r * TAU) - 1)
# Road 2: value today of "buy July, store, sell January" from its cash flows alone,
# then bisection for the January price at which the trade is worth exactly zero.
def trade_pv(fs, fw, cost, ts, tw):
    return -fs * exp(-r * ts) + (fw - cost) * exp(-r * tw)
lo, hi = FS, FS + 5.0
for _ in range(200):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if trade_pv(FS, mid, c, TS, TW) < 0 else (lo, mid)
cap2 = 0.5 * (lo + hi) - FS

profit_jan = FW - FS * exp(r * TAU) - c          # locked in, paid in January
profit_pv = trade_pv(FS, FW, c, TS, TW)          # the same trade valued today
fw_low = FS + 0.30
loss_low = fw_low - FS * exp(r * TAU) - c
phantom = FS * exp(r * TAU) + c - fw_low         # the reverse trade, if gas could be borrowed

# Road 3: every storage cycle on the whole strip, inject in month i, withdraw in month j,
# the season's space leased for the flat 0.60; the search must find July -> January.
best = max(((trade_pv(STRIP[i], STRIP[j], c, i / 12, j / 12), i, j)
            for i in range(12) for j in range(i + 1, 12)))

fitted_spread = fit[9] - fit[3]
level_up = 1.2 * FW - 1.2 * FS - (c + 1.2 * FS * (exp(r * TAU) - 1))

print(f"{'fit road 1  a, A, B':<30} {a1:10.6f} {A1:10.6f} {B1:10.6f}")
print(f"{'fit road 2  a, A, B':<30} {a2:10.6f} {A2:10.6f} {B2:10.6f}")
print(f"{'level L = e^a':<30} {L:10.4f}")
print(f"{'amplitude beta':<30} {beta:10.4f}")
print(f"{'peak t0, years from 1 Apr':<30} {t0:10.4f}  = month {12 * t0:.2f}")
print(f"{'winter/summer shape ratio':<30} {exp(2 * beta):10.4f}")
print("month   strip    fit   miss")
for m in range(12):
    print(f"{MONTHS[m]:<5} {STRIP[m]:7.2f} {fit[m]:6.2f} {STRIP[m] - fit[m]:+6.2f}")
print(f"{'largest miss':<30} {max(abs(s - f) for s, f in zip(STRIP, fit)):10.4f}")
print(f"{'fitted Jul -> Jan spread':<30} {fitted_spread:10.4f}")
print(f"{'quoted spreads, high and low':<30} {FW - FS:10.4f} {fw_low - FS:10.4f}")
print(f"{'growth e^(r tau), July -> Jan':<30} {exp(r * TAU):10.4f}")
print(f"{'July 2.50 grown to January':<30} {FS * exp(r * TAU):10.4f}")
print(f"{'interest on July gas':<30} {FS * (exp(r * TAU) - 1):10.4f}")
print(f"{'cap road 1  formula':<30} {cap1:10.4f}")
print(f"{'cap road 2  cash flows+search':<30} {cap2:10.4f}")
print(f"{'January break-even price':<30} {FS + cap1:10.4f}")
print(f"{'spread 1.00: profit in Jan':<30} {profit_jan:10.4f}")
print(f"{'spread 1.00: value today':<30} {profit_pv:10.4f}")
print(f"{'  x 1,000,000 MMBtu, in Jan':<30} {profit_jan * 1e6:10.0f}")
print(f"{'spread 0.30: storage trade':<30} {loss_low:10.4f}")
print(f"{'best cycle on the strip':<30} {MONTHS[best[1]]} -> {MONTHS[best[2]]}  {best[0]:.4f}")
print(f"{'wrong: no interest, cap':<30} {c:10.4f}")
print(f"{'wrong: storage fee only, cap':<30} {0.50 + FS * (exp(r * TAU) - 1):10.4f}")
print(f"{'wrong: reverse trade on 0.30':<30} {phantom:10.4f}")
print(f"{'try: level x 1.2, spread, cap':<30} {1.2 * (FW - FS):10.4f} {c + 1.2 * FS * (exp(r * TAU) - 1):10.4f}")
print(f"{'try: level x 1.2, profit Jan':<30} {level_up:10.4f}")
print(f"{'try: r = 10%, cap':<30} {c + FS * (exp(0.10 * TAU) - 1):10.4f}")
print(f"{'try: c = 1.10, spread 1.00 P&L':<30} {FW - FS * exp(r * TAU) - 1.10:10.4f}")
print("chart, Jan price  " + " ".join(f"{2.8 + 0.1 * k:5.2f}" for k in range(9)))
print("chart, trade P&L  " + " ".join(f"{2.8 + 0.1 * k - FS - cap1:5.2f}" for k in range(9)))
print("chart, take-it    " + " ".join(f"{max(2.8 + 0.1 * k - FS - cap1, 0.0):5.2f}" for k in range(9)))

assert max(abs(u - v) for u, v in zip((a1, A1, B1), (a2, A2, B2))) < 1e-12, "two fits agree"
assert abs(cap1 - cap2) < 1e-9, "formula cap equals the searched break-even"
assert abs(profit_pv * exp(r * TW) - profit_jan) < 1e-12, "today's value grows to the January profit"
assert (best[1], best[2]) == (3, 9), "the best cycle on the strip is the summer-to-winter one"
assert max(abs(exp(a1 + A1 * cos(t) + B1 * sin(t)) - f) for t, f in zip(th, fit)) < 1e-12, "legs form equals level-and-peak form"
assert fw_low - FS < cap2 < FW - FS, "0.30 sits under the searched cap, 1.00 over it"
print("ALL CHECKS PASS")
