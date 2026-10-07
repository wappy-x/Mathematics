# Annuities and loans -- the check behind the card.  Nothing is imported.  A
# 200,000 mortgage over 25 years, quoted at 5 percent a year and charged as
# 5/12 of a percent on the balance each month.  The level payment is reached
# three independent ways, the balance after a chosen month three ways, and the
# same factor prices the shelf's 1,000 five-year 6 percent bond at 5 percent.
LOAN, RATE, YEARS, PER = 200000.0, 0.05, 25, 12
N, I = YEARS * PER, RATE / PER            # 300 payments; monthly rate 0.05/12

def a_closed(i, n):                       # road 1: the closed form on the card
    return (1.0 - (1.0 + i) ** (-n)) / i

def a_added(i, n):                        # road 2: add the n discount factors
    total, d = 0.0, 1.0
    for _ in range(n):
        d = d / (1.0 + i)
        total = total + d
    return total

def schedule(payment, i, n, loan):        # road 3: the ledger, month by month
    bal, interest, rows = loan, 0.0, []
    for k in range(1, n + 1):
        charge = bal * i                  # interest on what is still owed
        bal = bal + charge - payment      # then the payment lands
        interest = interest + charge
        rows.append((k, charge, payment - charge, bal))
    return bal, interest, rows

def payment_bisect(i, n, loan):           # road 3: hunt the payment ending at zero
    lo, hi = 0.0, loan
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if schedule(mid, i, n, loan)[0] > 0.0:
            lo = mid                      # too small: debt left over
        else:
            hi = mid                      # too big: overshot into credit
    return 0.5 * (lo + hi)

def one(name, value):
    print(f"{name:<44}{value:>14.6f}")

fac_closed, fac_added = a_closed(I, N), a_added(I, N)
A = LOAN / fac_closed
A_bisect = payment_bisect(I, N, LOAN)
end_balance, interest_total, rows = schedule(A, I, N, LOAN)
K = 100
bal_ledger = rows[K - 1][3]
bal_ahead = A * a_closed(I, N - K)                        # the payments still due
s_k = ((1.0 + I) ** K - 1.0) / I                          # 1 a month for 100 months, grown
bal_behind = LOAN * (1.0 + I) ** K - A * s_k
perp = LOAN * I                                           # payment that never clears
tail_gap = A * (a_added(I, 20000) - fac_added)            # the payments past the 300th, added
tail_form = (A / I) * (1.0 + I) ** (-N)
ROUNDED = round(A * 100.0) / 100.0                        # the payment as a lender quotes it
short = schedule(ROUNDED, I, N, LOAN)[0]                  # what the trimmed cents leave owing
short_form = (A - ROUNDED) * ((1.0 + I) ** N - 1.0) / I   # the same shortfall, grown forward
FACE, COUPON, YLD, NY = 1000.0, 0.06, 0.05, 5             # the shelf's house bond
bond_factor = FACE * COUPON * a_closed(YLD, NY) + FACE * (1.0 + YLD) ** (-NY)
bond_terms = FACE * (1.0 + YLD) ** (-NY)
for k in range(1, NY + 1):
    bond_terms = bond_terms + FACE * COUPON * (1.0 + YLD) ** (-k)
wrong_annual = LOAN * RATE / (1.0 - (1.0 + RATE) ** (-YEARS)) / PER
wrong_flat = (LOAN + LOAN * RATE * YEARS) / N
wrong_due = A / (1.0 + I)

print(f"loan {LOAN:.2f}, {N} monthly payments, quoted {RATE * 100:.3f} percent a year")
one("monthly rate in percent, 5/12 of one", I * 100.0)
one("discount factor for month 300, (1+i)^-300", (1.0 + I) ** (-N))
one("annuity factor a(300), closed form", fac_closed)
one("annuity factor a(300), 300 terms added", fac_added)
one("payment, loan / factor", A)
one("payment, bisection on the final balance", A_bisect)
one("balance after the 300th payment", end_balance)
one("total handed over, 300 payments", N * A)
one("total interest, 300 payments - loan", N * A - LOAN)
one("total interest, summed from the ledger", interest_total)

print()
print("month   payment   interest  principal    balance")
for k in (1, 2, 3, 100, 200, 299, 300):
    m, charge, principal, bal = rows[k - 1]
    print(f"{m:>5}{A:>10.2f}{charge:>11.2f}{principal:>11.2f}{bal:>11.2f}")

print()
one("balance after month 100, from the ledger", bal_ledger)
one("balance after month 100, payments still due", bal_ahead)
one("balance after month 100, grown less repaid", bal_behind)
one("accumulation factor s(100), 1 a month grown", s_k)

print()
one("perpetuity payment, loan x monthly rate", perp)
one("value past month 300, later payments added", tail_gap)
one("value past month 300, (A/i)(1+i)^-300", tail_form)

print()
one("left owing after 300 payments of 1169.18", short)
one("last payment when the rest are rounded cents", ROUNDED + short)

print()
one("bond 1000 5y 6pc at 5pc, 60 x a(5) + face", bond_factor)
one("bond 1000 5y 6pc at 5pc, six terms added", bond_terms)

print()
one("wrong: yearly rate, yearly payment, then /12", wrong_annual)
one("wrong: 5pc flat for 25 years, split 300 ways", wrong_flat)
one("wrong: paying at the start of each month", wrong_due)
one("wrong: interest only, principal never falls", perp)

print()
years = [0, 5, 10, 15, 20, 25]
months = [1, 60, 120, 180, 240, 300]
print(f"{'chart, years elapsed':<28}" + " ".join(f"{y:>9d}" for y in years))
print(f"{'chart, balance owed':<28}" + " ".join(
    f"{A * a_closed(I, N - y * PER):>9.2f}" for y in years))
print(f"{'chart, loan in equal chunks':<28}" + " ".join(
    f"{LOAN * (1 - y / YEARS):>9.2f}" for y in years))
print(f"{'chart, payment number':<28}" + " ".join(f"{m:>9d}" for m in months))
print(f"{'chart, interest part':<28}" + " ".join(f"{rows[m - 1][1]:>9.2f}" for m in months))
print(f"{'chart, principal part':<28}" + " ".join(f"{rows[m - 1][2]:>9.2f}" for m in months))

assert abs(A - A_bisect) < 1e-6                    # closed form vs the ledger's own answer
assert abs(fac_closed - fac_added) < 1e-9          # closed form vs 300 added terms
assert abs(bal_ahead - bal_ledger) < 1e-6 and abs(bal_behind - bal_ledger) < 1e-6
assert abs(bond_factor - bond_terms) < 1e-9        # one factor vs six discounted terms
assert abs(interest_total - (N * A - LOAN)) < 1e-6
assert abs(tail_gap - tail_form) < 1e-6            # the tail, added vs the closed form
assert abs(short - short_form) < 1e-6              # rounding shortfall, ledger vs grown
assert abs(end_balance) < 1e-6                     # the loan really does clear
print("ALL CHECKS PASS")
