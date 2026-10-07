# Term premium and expectations -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Rates are decimals in the code,
# continuously compounded; the printout shows them in percent.
from math import exp, log

def pct(x): return f"{100.0 * x:.4f}"
def row(name, text): print(f"{name:<44} {text}")

def D(t, y): return exp(-y * t)                           # discount factor for t years at zero rate y
def fwd(a, ya, b, yb): return (b * yb - a * ya) / (b - a)  # road 1: the weighted-difference formula

def bisect(g, lo, hi, n=200):                              # root finder: g must change sign on [lo, hi]
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if (g(lo) < 0) == (g(mid) < 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# ---- the example: 2-year zero at 3%, 4-year zero at 4.5%; the forward runs from year 2 to year 4 ----
a, b, ya, yb = 2.0, 4.0, 0.03, 0.045
D2, D4 = D(a, ya), D(b, yb)
F1 = fwd(a, ya, b, yb)
face4 = 1_000_000.0                                        # road 2: lock the rate with two trades
cost4 = face4 * D4                                         # buy $1m face of the 4-year zero
face2 = cost4 / D2                                         # pay for it by selling 2-year zeros
F2 = log(face4 / face2) / (b - a)
growth = lambda f: 100.0 * exp(a * ya) * exp((b - a) * f) - 100.0 * exp(b * yb)
F3 = bisect(growth, -1.0, 1.0)                             # road 3: solve "2 years then F" = "4 years"
curve = [(1.0, 0.025), (2.0, 0.030), (3.0, 0.038), (4.0, 0.045)]
one_year = [fwd(t0, y0, t1, y1) for (t0, y0), (t1, y1) in zip([(0.0, 0.0)] + curve, curve)]
F4 = (one_year[2] + one_year[3]) / 2                       # road 4: average the two one-year forwards

# ---- the expectation: three scenarios for the 2-year rate quoted in year 2 ----
scen = [(0.25, 0.01), (0.50, 0.04), (0.25, 0.07)]
A = sum(p * R for p, R in scen)
TP = F1 - A
hold = []                                                  # road 2 to the premium: holding returns
for p, R in scen:
    long_val = (100.0 / D4) * exp(-(b - a) * R)            # $100 in the 4-year zero, sold in year 2
    roll_val = 100.0 / D2                                  # $100 in the 2-year zero, repaid in year 2
    hold.append((p, R, long_val, roll_val, log(long_val / roll_val)))
TP_hold = sum(p * x for p, _, _, _, x in hold) / (b - a)

def lcg(seed):                                             # own random numbers, 64-bit LCG
    x = seed
    while True:
        x = (x * 6364136223846793005 + 1442695040888963407) % (1 << 64)
        yield (x >> 11) / float(1 << 53)

def mc_premium(F, cases, n, seed=20260928):                # road 3: simulate year 2, average the excess
    u, total = lcg(seed), 0.0
    for _ in range(n):
        v, acc = next(u), 0.0
        for p, R in cases:
            acc += p
            if v < acc: break
        total += (b - a) * (F - R)                         # excess log return of long over roll
    return total / n / (b - a)
TP_mc = mc_premium(F1, scen, 200_000)
F0 = -log(sum(p * exp(-(b - a) * R) for p, R in scen)) / (b - a)   # fair forward with no premium at all
F0_root = bisect(lambda f: sum(p * exp((b - a) * (f - R)) for p, R in scen) - 1.0, -1.0, 1.0)  # zero expected excess

# ---- inversion: 1-year zero at 5%, 2-year zero at 4% ----
y1, y2 = 0.05, 0.04
Finv = log(D(1.0, y1) / D(2.0, y2)) / 1.0
inv_curve = [(1.0, 0.050), (2.0, 0.040), (3.0, 0.036), (4.0, 0.035), (5.0, 0.035)]
inv_fwd = [fwd(t0, y0, t1, y1_) for (t0, y0), (t1, y1_) in zip([(0.0, 0.0)] + inv_curve, inv_curve)]

row("zero rate y(2), y(4)", f"{pct(ya)} {pct(yb)}")
row("discount D(2), D(4)", f"{D2:.6f} {D4:.6f}")
row("D(2)/D(4)", f"{D2 / D4:.6f}")
row("1 forward F(2,4), weighted formula", pct(F1))
row("2 forward, replication: cost of $1m 4y", f"{cost4:.2f}")
row("  2y face sold, paid back in year 2", f"{face2:.2f}")
row("  rate from year 2 to year 4", pct(F2))
row("3 forward, bisection on growth", pct(F3))
row("4 forward, mean of one-year forwards", pct(F4))
row("chart, zero curve y(1..4)", " ".join(pct(y) for _, y in curve))
row("chart, one-year forwards", " ".join(pct(f) for f in one_year))
for p, R, lv, rv, x in hold:
    row(f"scenario R = {pct(R)}, p = {p:.2f}", f"long {lv:.2f} roll {rv:.2f} excess {pct(x)}")
row("expected rate A = E[R]", pct(A))
row("1 term premium F - A", pct(TP))
row("2 premium, expected excess / 2 years", pct(TP_hold))
row("3 premium, simulated, 200000 draws", pct(TP_mc))
row("no-premium forward -ln E[e^-2R] / 2", pct(F0))
row("  convexity gap A - F0", pct(A - F0))
row("inversion y(1), y(2)", f"{pct(y1)} {pct(y2)}")
row("  forward F(1,2)", pct(Finv))
row("  y(2) - y(1)", pct(y2 - y1))
row("  (1/2)(F(1,2) - y(1))", pct(0.5 * (Finv - y1)))
for tp in (0.01, 0.0, -0.01, -0.02):
    row(f"  premium {pct(tp)} -> expected rate", pct(Finv - tp))
row("chart, inverted zero curve y(1..5)", " ".join(pct(y) for _, y in inv_curve))
row("chart, inverted one-year forwards", " ".join(pct(f) for f in inv_fwd))
row("wrong: average the two zero rates", pct((ya + yb) / 2))
row("wrong: divide by b, not b - a", pct((b * yb - a * ya) / b))
row("wrong: read slope y(4) - y(2) as premium", pct(yb - ya))
row("wrong: read F as the forecast, gap", pct(F1 - A))
row("try: y(4) = 5%, forward", pct(fwd(a, ya, b, 0.05)))
row("try: y(4) = 5%, premium", pct(fwd(a, ya, b, 0.05) - A))
wide = [(0.25, 0.0), (0.50, 0.04), (0.25, 0.08)]
row("try: scenarios 0/4/8, expected", pct(sum(p * R for p, R in wide)))
row("try: scenarios 0/4/8, no-premium fwd", pct(-log(sum(p * exp(-2 * R) for p, R in wide)) / 2))
row("try: y(2) = 4.5% in the inversion, F(1,2)", pct(fwd(1.0, y1, 2.0, 0.045)))
row("try: simulated premium, 1000 draws", pct(mc_premium(F1, scen, 1000)))

assert abs(F1 - 0.06) < 1e-12,             "formula vs the card's worked 6%"
assert abs(F2 - F1) < 1e-12,               "replication trades land on the formula"
assert abs(F3 - F1) < 1e-10,               "root finder lands on the formula"
assert abs(F4 - F1) < 1e-12,               "one-year forwards average to the two-year forward"
assert abs(TP_hold - TP) < 1e-12,          "holding-return premium equals F - A"
assert abs(TP_mc - TP) < 5e-4,             "simulated premium within 0.05 pp"
assert abs((y2 - y1) - 0.5 * (Finv - y1)) < 1e-12, "inversion identity from discount factors"
assert abs(F0_root - F0) < 1e-10,          "no-premium forward: closed form vs root finder"
assert F0 < A,                             "with no premium the forward sits below the expectation"
print("ALL CHECKS PASS")
