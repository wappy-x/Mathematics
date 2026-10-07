# Forward rate agreements -- the check behind the card.  Standard library
# only, and nothing is imported that already holds the answer: the root
# finder is a bisection written out below, and one road works in whole-number
# fractions.  Kestrel Dairy borrows 1,000,000 dollars for the second year.
from fractions import Fraction as Q

N, A, K, FIX = 1000000.0, 1.0, 0.06, 0.08   # notional, year fraction, rate locked, the fixing
G1, G2 = 1.05, 1.113                        # what a dollar left one year, and two years, comes back as

def bisect(f, lo, hi, steps=200):           # a root finder, written out here
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0.0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)

def value(strike, d1, d2):                  # receive the fixing, pay the strike: the two-bond form
    return N * (d1 - (1.0 + A * strike) * d2)

def settle(fixing, alpha=A, strike=K, notional=N):    # the market settlement, paid at the start
    end = notional * alpha * (fixing - strike)
    return end, end / (1.0 + alpha * fixing)

def lab(name, text):
    print(f"{name:<46}{text:>16}")

D1, D2 = 1.0 / G1, 1.0 / G2                 # today's price of a dollar at year 1 and at year 2
fwd_curve = (D1 / D2 - 1.0) / A                              # road 1: two discount factors
stake = N * D1                                               # road 2: two dated deposits
borrow = (stake, 0.0, -stake * G2)          # borrow this today for two years, repay at year 2
lend = (-stake, stake * G1, 0.0)            # lend the same sum for one year, drawn at year 1
net = tuple(a + b for a, b in zip(borrow, lend))
fwd_ledger = (-net[2] / net[1] - 1.0) / A
fwd_exact = (Q(1113, 1000) / Q(21, 20) - 1) / Q(1)           # road 3: whole-number fractions
fair = bisect(lambda k: value(k, D1, D2), 0.0, 1.0)          # road 4: the zero-value strike

end_paid, start_paid = settle(FIX)
span = 2.0 * abs(end_paid) + 1.0            # a bracket that holds the root whichever way it points
start_solved = bisect(lambda s: s * (1.0 + A * FIX) - end_paid, -span, span)
grown_back = start_paid * (1.0 + A * FIX)
borrowed = N - start_paid
repaid = borrowed * (1.0 + A * FIX)
mtm_at_fixing = value(K, 1.0, 1.0 / (1.0 + A * FIX))
locked_interest = N * A * K

print(f"Kestrel Dairy borrows {N:.2f} for the second year, starting one year from today")
lab("a dollar left for one year comes back as", f"{G1:.6f}")
lab("a dollar left for two years comes back as", f"{G2:.6f}")
lab("the two quotes as rates, one year and two", f"{G1 - 1:.6f} {G2 - 1:.6f}")
lab("D(1), today's price of a dollar at year 1", f"{D1:.12f}")
lab("D(2), today's price of a dollar at year 2", f"{D2:.12f}")
lab("growth across the second year, D(1)/D(2)", f"{D1 / D2:.12f}")
lab("1 forward rate F from the two discounts", f"{fwd_curve:.12f}")
lab("2 the same F from the two-deposit ledger", f"{fwd_ledger:.12f}")
lab("3 the same F from whole-number fractions", f"{float(fwd_exact):.12f}")
lab("4 the same F from a bisection root finder", f"{fair:.12f}")
print()
print("the replicating ledger, in dollars")
print(f"{'':<28}{'today':>16}{'year 1':>16}{'year 2':>16}")
for name, flows in (("borrow for two years", borrow), ("lend the same for one year", lend), ("net", net)):
    print(f"{name:<28}" + "".join(f"{f:>16.2f}" for f in flows))
print()
lab("the fixing at year 1 comes in at", f"{FIX:.6f}")
lab("interest at the fixing, N x alpha x L", f"{N * A * FIX:.2f}")
lab("interest at the locked rate, N x alpha x K", f"{locked_interest:.2f}")
lab("X, the difference, due at year 2", f"{end_paid:.2f}")
lab("S, the settlement paid at year 1", f"{start_paid:.2f}")
lab("S grown at the fixing to year 2", f"{grown_back:.2f}")
lab("borrowed at year 1, net of the settlement", f"{borrowed:.2f}")
lab("repaid at year 2", f"{repaid:.2f}")
lab("the mark at year 1, two-bond form", f"{mtm_at_fixing:.2f}")
print()
print("the settlement and the hedge, across fixings")
print(f"{'fixing L':>10}{'X at year 2':>16}{'S at year 1':>16}{'repaid at year 2':>20}")
sweep = []
for i in range(9):
    fixing = 0.02 + 0.01 * i
    x, s = settle(fixing)
    total = (N - s) * (1.0 + A * fixing)
    sweep.append(total)
    print(f"{fixing:>10.2f}{x:>16.2f}{s:>16.2f}{total:>20.2f}")
print("the forward moves, the locked 0.06 stays: value today of the agreement")
moves = []
for i in range(5):
    fwd = 0.05 + 0.005 * i
    d2 = D1 / (1.0 + A * fwd)
    moves.append(N * A * d2 * (fwd - K))
    print(f"{fwd:>10.3f}{moves[-1]:>16.2f}")
gap_form = N * A * D2 * (fwd_curve - 0.05)
two_bond = value(0.05, D1, D2)
up, down = settle(0.07)[1], settle(0.05)[1]
print(f"a 0.05 strike: {N * (1.0 + A * fwd_curve):.2f} lent against {N * (1.0 + A * 0.05):.2f} "
      f"borrowed, gap {N * A * (fwd_curve - 0.05):.2f} at year 2, worth today {gap_form:.2f} by the "
      f"gap form and {two_bond:.2f} by the two-bond form")
print(f"value per basis point: on the forward {N * A * D2 * 0.0001:.2f}, "
      f"on the fixed rate {-N * A * D2 * 0.0001:.2f}")
print(f"a point up on the fixing pays {up:.2f}, a point down costs {down:.2f}, "
      f"a gap of {-(up + down):.2f}")
wrong_date = end_paid * (1.0 + A * FIX)
wrong_disc = end_paid / (1.0 + A * K)
wrong_fwd = (G2 - 1.0) - (G1 - 1.0)
alpha9 = 183.0 / 360.0
x9, s9 = settle(FIX, alpha9)
hist_end, hist_start = settle(0.06, 90.0 / 360.0, 0.05)
print(f"wrong: X paid at year 1 grows to {wrong_date:.2f}, over by {wrong_date - end_paid:.2f}")
print(f"wrong: discounted at 0.06 gives {wrong_disc:.2f}, which grows to "
      f"{wrong_disc * (1.0 + A * FIX):.2f}, over by {wrong_disc * (1.0 + A * FIX) - end_paid:.2f}")
print(f"wrong: rates subtracted gives F {wrong_fwd:.6f} and interest {N * A * wrong_fwd:.2f}, "
      f"over by {N * A * wrong_fwd - locked_interest:.2f}")
print(f"3 against 9, alpha {alpha9:.6f}: X {x9:.2f}, S {s9:.2f}, "
      f"year fraction dropped {N * (FIX - K):.2f}")
print(f"Richmond Fed 1x4 example: {N:.2f} at {0.05:.6f} against a {0.06:.6f} fixing over "
      f"{90.0 / 360.0:.6f} of a year: X {hist_end:.2f}, S {hist_start:.2f}")
assert abs(fwd_ledger - fwd_curve) < 1e-12                  # the ledger road meets the curve road
assert fwd_exact == Q(3, 50)                                # and the exact road lands on 6 percent
assert abs(fair - fwd_curve) < 1e-9                         # the root finder finds the same rate
assert max(abs(t - N * (1.0 + A * K)) for t in sweep) < 1e-6    # every fixing repays 1,060,000
assert abs(mtm_at_fixing - start_paid) < 1e-9               # the mark equals the settlement
assert abs(start_solved - start_paid) < 1e-6                # solved for, not divided out
assert abs(gap_form - two_bond) < 1e-9                      # the two value formulas agree
assert round(hist_start * 100) == 246305                    # the Richmond chapter's 2,463.05
assert abs(net[1] - N) < 1e-6 and abs(net[2] + N * (1.0 + A * K)) < 1e-6   # the ledger is that loan
assert abs(moves[4] - value(K, D1, D1 / (1.0 + A * 0.07))) < 1e-9   # both value forms, moved curve
print("ALL CHECKS PASS")
