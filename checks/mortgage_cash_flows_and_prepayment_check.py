# Mortgage pool cash flows under prepayment -- the check behind the card.
# Standard library only.  A $1,000,000 pool of identical 30-year loans at 6
# percent, paid monthly.  Three roads to the pool's balance: the month-by-month
# ledger, the closed form (survivors times one loan's schedule), and 20,000
# simulated loans driven by a random-number generator written here.
from math import log, exp

L, N, i = 1_000_000.0, 360, 0.06 / 12
M64 = (1 << 64) - 1

def smm(c):                                    # annual CPR -> monthly fraction s
    return 1.0 - exp(log(1.0 - c) / 12.0)

def annuity(n):                                # a_n(i), added up one discount factor at a time
    v, total = 1.0, 0.0
    for _ in range(n):
        v /= 1.0 + i
        total += v
    return total

A = L / annuity(N)                             # the level payment with no prepayment

def ledger(cpr, frozen=False):                 # road 1: the pool, one month at a time
    b, rows = L, []                            # rows: (interest, scheduled, prepaid, end balance)
    for m in range(1, N + 1):
        interest = i * b
        pay = min(A if frozen else b / annuity(N - m + 1), b + interest)
        sched = pay - interest
        prepaid = smm(cpr(m)) * (b - sched)
        b = b - sched - prepaid
        rows.append((interest, sched, prepaid, b))
        if b < 1e-6:
            break
    return rows

def wal(rows):                                 # weighted average life, in years
    return sum((m + 1) / 12 * (r[1] + r[2]) for m, r in enumerate(rows)) / L

def value(rows, y):                            # today's value of the cash flows at yearly rate y
    return sum((r[0] + r[1] + r[2]) / (1 + y / 12) ** (m + 1) for m, r in enumerate(rows))

def closed(m, c):                              # road 2: L (1-s)^m a_{N-m} / a_N, closed form
    v = 1 / (1 + i)
    return L * (1 - smm(c)) ** m * (1 - v ** (N - m)) / (1 - v ** N)

def closed_path(m, cpr):                       # road 2 with a changing speed: (1-s)^m -> product
    v, surv = 1 / (1 + i), 1.0
    for k in range(1, m + 1):
        surv *= 1 - smm(cpr(k))
    return L * surv * (1 - v ** (N - m)) / (1 - v ** N)

def simulate(c, loans=20000, seed=2026):       # road 3: loans that each prepay whole, or not
    state, us = seed, []
    for _ in range(loans):                     # splitmix64, written out
        state = (state + 0x9E3779B97F4A7C15) & M64
        z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        us.append(((z ^ (z >> 31)) >> 11) / 2.0 ** 53)
    us.sort()
    one, surv, alive, p, bal = 1.0, 1.0, [loans], loans, [1.0]
    for m in range(1, N + 1):                  # one loan's own schedule, per dollar lent
        one = one * (1 + i) - A / L
        surv *= 1 - smm(c)                     # a loan is still in if its draw is below surv
        while p > 0 and us[p - 1] >= surv:
            p -= 1
        alive.append(p); bal.append(max(one, 0.0))
    B = [L * alive[m] / loans * bal[m] for m in range(N + 1)]
    return B, sum(m / 12 * (B[m - 1] - B[m]) for m in range(1, N + 1)) / L

flat = lambda c: (lambda m: c)
rule = lambda M: min(0.30, max(0.02, 0.08 + 4 * (0.06 - M)))       # rate-dependent CPR
psa = lambda m: 0.06 * min(m, 30) / 30                               # 100% PSA ramp
path = lambda m: rule(0.07 if m <= 120 else 0.04)                    # market 7%, then 4% from month 121
runs = {c: ledger(flat(c)) for c in (0.0, 0.04, 0.08, 0.12, 0.20)}
r8, s8 = runs[0.08], smm(0.08)
sim_B, sim_wal = simulate(0.08)

print(f"pool {L:.2f}, {N} months at 0.5% a month; level payment A {A:.6f}")
print(f"8% CPR -> SMM s {s8:.12f}; (1-s)^12 {(1 - s8) ** 12:.12f}; CPR/12 {0.08 / 12:.12f}")
print(f"a_N(i) {annuity(N):.6f}; survivors after 10 years (1-s)^120 {(1 - s8) ** 120:.6f}")
it, sc, pp, b1 = r8[0]
print(f"month 1 at 8% CPR: interest {it:.6f} scheduled {sc:.6f} prepaid {pp:.6f}")
print(f"month 1 at 8% CPR: cash to investors {it + sc + pp:.6f} balance left {b1:.6f}")
print(f"month 2 scheduled payment {r8[1][0] + r8[1][1]:.6f}; (1-s) A {(1 - s8) * A:.6f}")
for yr in (10, 20):
    m = 12 * yr
    print(f"balance year {yr}, 8% CPR: ledger {r8[m - 1][3]:.6f} closed {closed(m, 0.08):.6f} "
          f"20000 loans {sim_B[m]:.6f}")
print(f"WAL 8% CPR: ledger {wal(r8):.6f} years; 20000 loans {sim_wal:.6f} years")
print(f"principal returned at 8% CPR: {sum(r[1] + r[2] for r in r8):.6f}")
print(f"interest paid: 0% CPR {sum(r[0] for r in runs[0.0]):.6f}; 8% CPR {sum(r[0] for r in r8):.6f}")
for c in (0.0, 0.08, 0.12):
    print(f"value at the 6% coupon rate, CPR {c:.0%}: {value(runs[c], 0.06):.6f}")
print("WAL by CPR, years: " + "  ".join(f"{c:.0%} {wal(runs[c]):.2f}" for c in runs))
print(f"try: 100% PSA ramp, WAL {wal(ledger(psa)):.2f} years")
print("rate-dependent CPR: market rate, CPR, WAL, value with rule, value if CPR stayed 8%")
for M in (0.05, 0.06, 0.07):
    rr = ledger(flat(rule(M)))
    print(f"  market {M:.0%}  CPR {rule(M):>3.0%}  WAL {wal(rr):5.2f}  {value(rr, M):11.2f}  {value(r8, M):11.2f}")
rp = ledger(path)
print(f"rate path 7% then 4%: CPR {path(1):.0%} then {path(121):.0%}; balance year 10 {rp[119][3]:.2f} "
      f"closed {closed_path(120, path):.2f}; year 20 {rp[239][3]:.2f}; WAL {wal(rp):.2f}")
cpr12 = ledger(lambda m: 1 - (1 - 0.08 / 12) ** 12)             # mistake 1: s = CPR/12
frozen = ledger(flat(0.08), frozen=True)                          # mistake 2: payment never shrinks
b = L                                                             # mistake 3: s on opening balance
for m in range(1, 121):
    b = b - (b / annuity(N - m + 1) - i * b) - s8 * b
print(f"wrong: s = CPR/12, balance year 10 {cpr12[119][3]:.2f}, WAL {wal(cpr12):.2f}")
print(f"wrong: payment frozen at A, paid off in month {len(frozen)}, WAL {wal(frozen):.2f}")
print(f"wrong: s on opening balance, balance year 10 {b:.2f}")
print("chart, years                 " + " ".join(f"{y:>10d}" for y in range(0, 31, 5)))
for c in (0.0, 0.08, 0.12):
    bs = [L] + [runs[c][12 * y - 1][3] for y in range(5, 31, 5)]
    print(f"chart, balance {c:>4.0%} CPR       " + " ".join(f"{abs(x):10.2f}" for x in bs))
years = (1, 5, 10, 15, 20, 25, 30)
print("chart, year of life          " + " ".join(f"{y:>10d}" for y in years))
for k, name in ((0, "interest"), (1, "scheduled"), (2, "prepaid")):
    tot = [sum(r[k] for r in r8[12 * (y - 1):12 * y]) for y in years]
    print(f"chart, {name:<10} in year 8%  " + " ".join(f"{x:10.2f}" for x in tot))

assert abs((1 - s8) ** 12 - 0.92) < 1e-12, "SMM compounds back to CPR"
assert all(abs(r8[m - 1][3] - closed(m, 0.08)) < 1e-6 for m in range(1, N)), "ledger = closed form"
assert abs(sim_B[120] - closed(120, 0.08)) < 0.02 * L and abs(sim_wal - wal(r8)) < 0.25, "loans"
assert abs(sum(r[1] + r[2] for r in r8) - L) < 1e-6, "every dollar lent comes back once"
assert all(abs(value(runs[c], 0.06) - L) < 1e-6 for c in runs), "at the coupon rate, value = par"
assert all(abs(rp[m - 1][3] - closed_path(m, path)) < 1e-6 for m in range(1, N)), "changing speed"
assert abs(r8[1][0] + r8[1][1] - (1 - s8) * A) < 1e-9, "payment shrinks with the survivors"
print("ALL CHECKS PASS")
