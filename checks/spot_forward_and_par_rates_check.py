# Spot, forward and par rates -- the check behind the card.  Standard library
# only, and nothing imported that already knows an answer: the root finder is
# a bisection written out here, and every power is a loop of multiplications.
# One annual-compounding curve, five maturities.  The forward rate and the par
# rate are each reached by roads that share no arithmetic: algebra on the
# discount factors, a bisection that matches two investments, and a ladder run
# backwards that recovers the spot curve from the par curve alone.
YEARS = [1, 2, 3, 4, 5]
SPOT = [0.04, 0.05, 0.055, 0.058, 0.06]
FACE = 100.0


def grow(rate, n):
    """(1 + rate) multiplied in n times: what one dollar in the bank becomes."""
    out = 1.0
    for _ in range(n):
        out *= 1.0 + rate
    return out


def bisect(f, lo, hi):
    """The root finder, written out: halve the bracket 200 times."""
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0.0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


D = [1.0 / grow(SPOT[t - 1], t) for t in YEARS]                 # D(t)
ann = [sum(D[:n]) for n in YEARS]                               # A_n
fwd = [SPOT[0]] + [D[t - 2] / D[t - 1] - 1.0 for t in YEARS[1:]]  # road 1
par = [(1.0 - D[n - 1]) / ann[n - 1] for n in YEARS]              # road 1


def price(coupon, n, factors):
    """An n-year annual bond, coupon in dollars, priced off given factors."""
    return sum(coupon * factors[t - 1] for t in range(1, n + 1)) + FACE * factors[n - 1]


one_year = FACE * grow(SPOT[0], 1)          # 100 lent for one year
two_year = FACE * grow(SPOT[1], 2)          # 100 lent for two years
rolled = one_year * (1.0 + fwd[1])          # 100 lent for one year, then rolled
f12_bisect = bisect(lambda x: one_year * (1.0 + x) - two_year, -0.5, 0.5)   # road 2
par_bisect = [bisect(lambda c, n=n: price(c, n, D) - FACE, 0.0, 50.0) / FACE
              for n in YEARS]                                               # road 2


def bootstrap(par_rates):
    """Road 3: spot rates out of the par curve alone, shortest maturity first."""
    z = []
    for n, c in zip(YEARS, par_rates):
        cpn = c * FACE
        known = sum(cpn / grow(z[t - 1], t) for t in range(1, n))
        z.append(bisect(lambda x, n=n, cpn=cpn, known=known:
                        known + (cpn + FACE) / grow(x, n) - FACE, -0.5, 1.0))
    return z


spot_back = bootstrap(par)
fwd_back = [spot_back[0]] + [grow(spot_back[t - 1], t) / grow(spot_back[t - 2], t - 1) - 1.0
                             for t in YEARS[1:]]
chain = 1.0
for f in fwd:
    chain /= 1.0 + f                        # the forwards multiplied back into D(5)

g1 = grow(SPOT[0], 1)                       # what one dollar becomes in one year
g2 = grow(SPOT[1], 2)                       # what one dollar becomes in two years
fake = 0.065                                # a forward quoted too high
arb_end = one_year * (1.0 + fake)           # what the rolled 100 dollars would come to
roll_short = FACE * grow(SPOT[0], 2)        # mistake: roll at today's 1-year rate
spot_as_fwd = one_year * (1.0 + SPOT[1])    # mistake: use the 2-year spot for year two
average = 0.5 * (SPOT[0] + SPOT[1])         # mistake: average the two spots
linear = 2.0 * SPOT[1] - SPOT[0]            # the continuous-compounding shortcut
zero_true = FACE * D[4]                     # 5-year zero, priced on the spot curve
zero_par = FACE / grow(par[4], 5)           # mistake: par yield read as a spot rate

print("one curve, annual compounding, five maturities")
print(f"{'year':>4}{'spot %':>11}{'D(t)':>11}{'forward %':>11}{'par %':>11}")
for t in YEARS:
    print(f"{t:>4}{100 * SPOT[t - 1]:>11.4f}{D[t - 1]:>11.6f}"
          f"{100 * fwd[t - 1]:>11.4f}{100 * par[t - 1]:>11.4f}")
print()
print("the two-year question, on 100 dollars")
print(f"  lend for two years at {100 * SPOT[1]:.2f} percent      {two_year:>10.4f}")
print(f"  lend one year at {100 * SPOT[0]:.2f} percent           {one_year:>10.4f}")
print(f"  then roll at the forward {100 * fwd[1]:.4f} percent  {rolled:>10.4f}")
print(f"  forward by bisection, not by algebra    {100 * f12_bisect:>10.4f}")
print(f"  forward from the bootstrapped curve     {100 * fwd_back[1]:>10.4f}")
print(f"  D(1)/D(2) - 1                           {100 * (D[0] / D[1] - 1.0):>10.4f}")
print()
print("by hand, from the two quotes")
print(f"  one dollar for one year               {g1:>10.6f}")
print(f"  one dollar for two years              {g2:>10.6f}")
print(f"  the ratio: year two on its own        {g2 / g1:>10.6f}")
print(f"  annuity A(2) = D(1) + D(2)            {ann[1]:>10.6f}")
print(f"  one dollar less D(2)                  {1.0 - D[1]:>10.6f}")
print()
print("the par rate, two roads")
print(f"{'year':>4}{'formula %':>12}{'bisected %':>12}{'bond price':>12}")
for n in YEARS:
    print(f"{n:>4}{100 * par[n - 1]:>12.4f}{100 * par_bisect[n - 1]:>12.4f}"
          f"{price(par[n - 1] * FACE, n, D):>12.6f}")
print()
print("the ladder backwards: spot rates recovered from the par curve alone")
print("  " + "  ".join(f"{100 * z:.4f}" for z in spot_back))
print(f"  largest gap from the curve we started with: {max(abs(a - b) for a, b in zip(spot_back, SPOT)):.12f}")
print(f"  forwards multiplied back into D(5): {chain:.6f} against {D[4]:.6f}")
print()
print("what breaks")
print(f"  roll at today's 1-year rate twice        {roll_short:>10.4f}  short {two_year - roll_short:.4f}")
print(f"  use the 2-year spot for year two         {spot_as_fwd:>10.4f}  short {two_year - spot_as_fwd:.4f}")
print(f"  average the two spots, as a rate         {100 * average:>10.4f}  against {100 * fwd[1]:.4f}")
print(f"  2 x 2-year minus 1-year, as a rate       {100 * linear:>10.4f}  against {100 * fwd[1]:.4f}")
print(f"  5-year zero on the spot curve            {zero_true:>10.4f}")
print(f"  5-year zero on the par yield             {zero_par:>10.4f}  over by {zero_par - zero_true:.4f}")
print(f"  roll at a forward quoted {100 * fake:.2f} percent  {arb_end:>10.4f}  free {arb_end - two_year:.4f}")
print()
print(f"{'chart, year':<22}" + " ".join(f"{t:6d}" for t in YEARS))
for label, series in (("chart, spot %", SPOT), ("chart, forward %", fwd), ("chart, par %", par)):
    print(f"{label:<22}" + " ".join(f"{100 * v:6.2f}" for v in series))

assert abs(rolled - two_year) < 1e-9, "rolled deposit must land on the two-year deposit"
assert abs(f12_bisect - fwd[1]) < 1e-9, "bisected forward vs the algebra"
assert abs(price(par[4] * FACE, 5, D) - FACE) < 1e-9, "par coupon must price the bond at 100"
assert max(abs(a - b) for a, b in zip(par_bisect, par)) < 1e-9, "bisected par rates vs the algebra"
assert max(abs(a - b) for a, b in zip(spot_back, SPOT)) < 1e-9, "the ladder must recover the curve"
assert abs(chain - D[4]) < 1e-12, "the forwards must multiply back into D(5)"
assert par[4] < SPOT[4], "on a rising curve the par rate sits below the spot rate"
print("ALL CHECKS PASS")
