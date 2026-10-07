# Bootstrapping the discount curve -- the check behind the card.  Standard library
# only; nothing imported that already knows an answer.  Six quotes from one morning,
# two deposits and four par swaps, become six discount factors by three independent
# roads; the finished curve is then made to reprice every quote it was built from,
# out of the cash flows the contracts actually pay.
from math import log

DEPOSITS = ((0.5, 0.0400), (1.0, 0.0420))     # (maturity in years, simple rate)
SWAPS = ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465))   # (years, par rate)
DATES = (0.5, 1.0, 2.0, 3.0, 4.0, 5.0)        # the six pillar dates, in years
PAIRS = tuple(zip((0.0,) + DATES[:-1], DATES))  # the periods between pillars
LOAN = 10_000_000.0                           # a round notional, to price in dollars

def ladder(swaps=SWAPS):                      # road 1: one maturity at a time
    D = {T: 1.0 / (1.0 + T * r) for T, r in DEPOSITS}
    for n, S in swaps:
        B = sum(D[float(j)] for j in range(1, n))      # the earlier coupons, funded
        D[float(n)] = (1.0 - S * B) / (1.0 + S)
    return D

def solve(rows, rhs):                         # Gaussian elimination, partial pivoting
    n = len(rhs)
    M = [rows[i][:] + [rhs[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda i: abs(M[i][c]))
        M[c], M[p] = M[p], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]
            M[i] = [M[i][j] - f * M[c][j] for j in range(n + 1)]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x

def by_elimination():                         # road 2: all six equations at once
    rows, rhs = [], []
    for n, S in reversed(SWAPS):              # longest first: pivoting must do real work
        row = [0.0] * 6
        for j in range(1, n + 1):
            row[DATES.index(float(j))] = S + (1.0 if j == n else 0.0)
        rows.append(row); rhs.append(1.0)
    for T, r in reversed(DEPOSITS):
        row = [0.0] * 6
        row[DATES.index(T)] = 1.0 + T * r
        rows.append(row); rhs.append(1.0)
    return dict(zip(DATES, solve(rows, rhs)))

def legs(D, n, S):                            # what the swap actually pays, leg by leg
    floating = fixed = 0.0
    prev = 1.0                                # one dollar today is worth one dollar
    for j in range(1, n + 1):
        d = D[float(j)]
        floating += (prev / d - 1.0) * d      # this year's forward rate, times this year
        fixed += S * d
        prev = d
    return floating, fixed

def by_bisection():                           # road 3: hunt each pillar numerically
    D = {T: 1.0 / (1.0 + T * r) for T, r in DEPOSITS}
    for n, S in SWAPS:
        lo, hi = 1e-9, 1.0
        for _ in range(200):
            mid = 0.5 * (lo + hi)
            D[float(n)] = mid
            lo, hi = (mid, hi) if legs(D, n, S)[0] - legs(D, n, S)[1] > 0.0 else (lo, mid)
        D[float(n)] = 0.5 * (lo + hi)
    return D

def zero(D, T): return -log(D[T]) / T         # continuously compounded zero rate
def fwd(D, a, b): return (log(D[a] / D[b]) if a else -log(D[b])) / (b - a)
def loan(D, S, n): return LOAN * (S * sum(D[float(j)] for j in range(1, n + 1)) + D[float(n)])

D, E, Z = ladder(), by_elimination(), by_bisection()
gap_e = max(abs(D[T] - E[T]) for T in DATES)
gap_z = max(abs(D[T] - Z[T]) for T in DATES)
print("Six quotes on one morning; accruals 0.5 and 1.0 exactly, one year per swap coupon")
print(f"{'quote':<13}{'rate %':>8}{'T':>6}{'B_n':>11}{'1 - S_n B_n':>13}{'1 + a_n S_n':>13}{'D(T)':>13}")
for T, r in DEPOSITS:
    print(f"{'deposit ' + f'{T:g}y':<13}{100 * r:>8.4f}{T:>6.1f}{0.0:>11.6f}{1.0:>13.6f}"
          f"{1.0 + T * r:>13.6f}{D[T]:>13.8f}")
for n, S in SWAPS:
    B = sum(D[float(j)] for j in range(1, n))
    print(f"{'par swap ' + f'{n}y':<13}{100 * S:>8.4f}{float(n):>6.1f}{B:>11.6f}{1.0 - S * B:>13.6f}"
          f"{1.0 + S:>13.6f}{D[float(n)]:>13.8f}")
print(f"\n{'T':>5}{'D(T)':>13}{'$100 due then':>15}{'zero rate %':>13}{'forward rate %':>16}")
for a, b in PAIRS:
    print(f"{b:>5.1f}{D[b]:>13.8f}{100 * D[b]:>15.2f}{100 * zero(D, b):>13.4f}{100 * fwd(D, a, b):>16.4f}")
print(f"\nroad 2, elimination on the 6 by 6 system, rows fed longest first: largest gap {gap_e:.12f}")
print(f"road 3, bisection against the legs the swaps actually pay: largest gap {gap_z:.12f}")
worst_dep = max(abs((1.0 + T * r) * D[T] - 1.0) for T, r in DEPOSITS)
worst_par = max(abs(legs(D, n, S)[0] / sum(D[float(j)] for j in range(1, n + 1)) - S) for n, S in SWAPS)
worst_val = max(abs(LOAN * (legs(D, n, S)[0] - legs(D, n, S)[1])) for n, S in SWAPS)
print(f"road 4, reprice: deposits come back to within {worst_dep:.12f} of a dollar per dollar lent, "
      f"par rates to within {worst_par:.12f},")
print(f"         and every input swap values at zero: the worst is ${worst_val:.6f} on $10,000,000")
B5 = sum(D[float(j)] for j in range(1, 5))
print(f"\nthe 5-year rung: B_5 = {B5:.6f}, so a positive D(5) needs a 5-year quote between "
      f"{-100.0:.2f}% and {100.0 / B5:.2f}%")
print(f"at {100.0 / B5:.2f}% the rung returns D(5) = {0.0:.2f}; at {-100.0:.2f}% it reads "
      f"0 x D(5) = {1.0 + B5:.6f}, which no number solves")
wrong = {"par rate read as a zero rate": {float(n): 1.0 / (1.0 + S) ** n for n, S in SWAPS},
         "earlier coupons forgotten": {float(n): 1.0 / (1.0 + S) for n, S in SWAPS},
         "simple interest for n years": {float(n): 1.0 / (1.0 + n * S) for n, S in SWAPS}}
print(f"\n{'the 5-year pillar, built this way':<34}{'D(5)':>13}"
      f"{'a $10,000,000 5-year loan at 4.6500% prices at':>48}{'off by':>13}")
print(f"{'bootstrapped, the right answer':<34}{D[5.0]:>13.8f}{loan(D, 0.0465, 5):>48,.2f}"
      f"{loan(D, 0.0465, 5) - LOAN:>13,.2f}")
for name, curve in wrong.items():
    curve.update({T: D[T] for T, _ in DEPOSITS})
    print(f"{name:<34}{curve[5.0]:>13.8f}{loan(curve, 0.0465, 5):>48,.2f}"
          f"{loan(curve, 0.0465, 5) - LOAN:>13,.2f}")
bumped = ladder(tuple((n, S + 0.0001 if n == 3 else S) for n, S in SWAPS))
print("\nthe 3-year quote ticks up one basis point; every other quote on the screen holds still")
print("  pillar zero rates move, in basis points: " +
      ", ".join(f"{T:g}y {10000.0 * (zero(bumped, T) - zero(D, T)):+.4f}" for T in DATES))
print("  forward rates move, in basis points:     " +
      ", ".join(f"{a:g}y-{b:g}y {10000.0 * (fwd(bumped, a, b) - fwd(D, a, b)):+.4f}" for a, b in PAIRS[3:]))
alt4 = D[3.0]                                  # a flat guess where the 4-year quote should be
alt5 = (1.0 - 0.0465 * (D[1.0] + D[2.0] + D[3.0] + alt4)) / 1.0465
print(f"\ndrop the 4-year quote and the 5-year swap holds two unknowns: D(4) = {D[4.0]:.8f} with "
      f"D(5) = {D[5.0]:.8f} reprices it")
print(f"and so does D(4) = {alt4:.8f} with D(5) = {alt5:.8f}")
print(f"the 4y-5y forward rate is {100 * fwd(D, 4.0, 5.0):.4f}% on the first pair, "
      f"{100 * log(alt4 / alt5):.4f}% on the second")
print(f"\n{'chart, T':<26}" + "".join(f"{T:>8.1f}" for T in DATES))
print(f"{'chart, $100 due at T':<26}" + "".join(f"{100 * D[T]:>8.2f}" for T in DATES))
assert gap_e < 1e-12, "the ladder and the 6 by 6 solve must land on the same six numbers"
assert gap_z < 1e-9, "the ladder and the numerical hunt must land on the same six numbers"
assert worst_par < 1e-12, "the curve must hand back every par rate it was built from"
assert worst_val < 1e-6, "every input swap must value at zero on its own curve"
assert all(D[DATES[i]] > D[DATES[i + 1]] for i in range(5)), "discount factors must fall with time"
assert all(fwd(D, a, b) > zero(D, b) for a, b in PAIRS[1:]), "forwards sit above zeros on a rising curve"
assert abs(loan(wrong["par rate read as a zero rate"], 0.0465, 5) - LOAN) > 1000.0, "the mistake costs real money"
print("ALL CHECKS PASS")
