# Convenience yield implied by the forward -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# Crude at 80, rates 5%, storage 2% a year, one-year market forward at 84.
# The implied convenience yield y is reached three ways that share no step:
# the closed form (one logarithm), bisection on the carry formula (no
# logarithm at all), and a power series on the dollar gap (no library log).
from math import exp, log

def forward(S, r, u, y, T):          # the carry formula, run forwards
    return S * exp((r + u - y) * T)

def y_closed(S, r, u, F, T):         # road 1: the carry formula, run backwards
    return r + u - log(F / S) / T

def y_bisect(S, r, u, F, T):         # road 2: halve an interval; never takes a log
    lo, hi = -1.0, 1.0
    while forward(S, r, u, lo, T) < F: lo *= 2.0      # forward falls as y rises
    while forward(S, r, u, hi, T) > F: hi *= 2.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if forward(S, r, u, mid, T) > F: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def y_series(S, r, u, F, T):         # road 3: the gap as a share of the ceiling,
    C = S * exp((r + u) * T)         # then -ln(1 - x) = x + x^2/2 + x^3/3 + ...
    x = (C - F) / C
    total, term, k = 0.0, x, 1
    while abs(term) > 1e-18:
        total += term / k
        k += 1
        term *= x
    return total / T

S, r, u, F, T = 80.0, 0.05, 0.02, 84.0, 1.0
C = S * exp((r + u) * T)
G = C - F
y1, y2, y3 = y_closed(S, r, u, F, T), y_bisect(S, r, u, F, T), y_series(S, r, u, F, T)

h = 0.01                                            # slope: bump the forward a cent
slope_bump = (y_closed(S, r, u, F + h, T) - y_closed(S, r, u, F - h, T)) / (2 * h)
F1m = forward(S, r, u, y1, 1 / 12)                  # a one-month quote on the same yield
cent_1m = y_closed(S, r, u, F1m - 0.01, 1 / 12) - y1

rows = [
    ("ceiling C = S e^((r+u)T)", C), ("gap G = C - F, delivery day", G),
    ("gap in today's dollars", G * exp(-r * T)), ("ln(F/S)", log(F / S)),
    ("sell 80, bank it: S e^(rT)", S * exp(r * T)), ("storage saved: C - S e^(rT)", C - S * exp(r * T)),
    ("1 closed form y", y1), ("2 bisection, no log", y2), ("3 series on the gap", y3),
    ("  first term only, G/C", G / C), ("forward rebuilt from y", forward(S, r, u, y1, T)),
    ("boundary: F = C gives y", y_closed(S, r, u, C, T)),
    ("boundary: F = S gives y", y_closed(S, r, u, S, T)),
    ("boundary: F = 86.50 gives y", y_closed(S, r, u, 86.50, T)),
    ("boundary: F = 1.00 gives y", y_closed(S, r, u, 1.00, T)),
    ("slope dy/dF by bump", slope_bump), ("  -1/(F T)", -1 / (F * T)),
    ("one-month forward, same y", F1m), ("  y moved by a 1-cent error", cent_1m),
    ("  same cent on the 1-year quote", y_closed(S, r, u, F - 0.01, T) - y1),
    ("wrong: 5% annual as continuous", r - log(1 + r)),
    ("wrong: storage left out", y_closed(S, r, 0.0, F, T)),
    ("wrong: F/S - 1 for ln(F/S)", r + u - (F / S - 1) / T),
    ("wrong: ln(S/F), sign flipped", r + u - log(S / F) / T),
    ("wrong: T = 12 for a year", y_closed(S, r, u, F, 12.0)),
    ("gold: 2000, 5%, fwd 2081.62", y_closed(2000.0, 0.05, 0.0, 2081.62, 1.0)),
    ("try: storage 3%", y_closed(S, r, 0.03, F, T)), ("try: rates 4%", y_closed(S, 0.04, u, F, T)),
    ("try: 6-month forward 82", y_closed(S, r, u, 82.0, 0.5)),
]
for name, v in rows:
    print(f"{name:<32} {v:>12.6f}")

print()
print("inventory state    forward   implied y %")      # illustrative quotes, not market data
states = (("glut", 85.50), ("comfortable", 84.00), ("tight", 81.00), ("squeeze", 78.00))
ys = []
for name, f in states:
    ys.append(y_closed(S, r, u, f, T))
    print(f"{name:<16} {f:9.2f} {100 * ys[-1]:12.2f}")

print()
grid = [76.0 + i for i in range(11)]
curve = [y_closed(S, r, u, f, T) for f in grid]
print("chart, forward  " + " ".join(f"{f:6.0f}" for f in grid))
print("chart, y %      " + " ".join(f"{100 * v:6.2f}" for v in curve))

assert abs(y2 - y1) < 1e-12, "bisection (no log) must land on the closed form"
assert abs(y3 - y1) < 1e-12, "series on the gap must land on the closed form"
assert abs(forward(S, r, u, y1, T) - F) < 1e-9, "the implied yield must rebuild the market forward"
assert abs(slope_bump - (-1 / (F * T))) < 1e-8, "bumped slope vs -1/(F T)"
assert all(a > b for a, b in zip(curve, curve[1:])), "y must fall strictly as the forward rises: one answer per quote"
assert all(a < b for a, b in zip(ys, ys[1:])), "tighter market, lower forward, higher y"
print("ALL CHECKS PASS")
