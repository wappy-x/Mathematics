# The credit default swap contract -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Roads: (1) the contract arithmetic,
# (2) a day-by-day ledger that accrues and pays the premium, (3) physical versus cash
# settlement of the payout, (4) 200,000 simulated default times with our own random
# numbers, against the closed-form risky annuity and protection leg.
from datetime import date
from math import exp, log, sqrt

N, s, c = 10_000_000.0, 0.0120, 0.0100            # notional, quoted spread, standard coupon
lam, r, T = 0.02, 0.05, 5.0                        # house hazard, riskless rate, years

# ---- road 1: the arithmetic of the contract ----
idealised = s * N / 4                              # a quarter taken as exactly 1/4 year
dates = [date(2026 + (3 * q + 11) // 12, (3 * q + 11) % 12 + 1, 20) for q in range(21)]
days = [(b - a).days for a, b in zip(dates, dates[1:])]
coupons = [s * N * d / 360 for d in days]          # ACT/360: actual days over 360
event = date(2029, 5, 19)                          # Northwind's credit event
paid_n = sum(1 for d in dates[1:] if d <= event)   # coupons paid before the event
paid = sum(coupons[:paid_n])
accrued = s * N * (event - dates[paid_n]).days / 360

# ---- road 2: a ledger that walks the contract one day at a time ----
ledger, owed, day, coupon_dates = 0.0, 0.0, dates[0], set(dates[1:])
while day < event:
    day = date.fromordinal(day.toordinal() + 1)
    owed += s * N / 360                            # one day of protection bought
    if day in coupon_dates:
        ledger, owed = ledger + owed, 0.0          # quarterly payment date: settle what is owed

# ---- the auction, a toy version, and road 3: two ways to settle ----
quotes = [(40.0, 42.0), (40.5, 42.5), (41.0, 43.0), (39.5, 41.5), (40.0, 42.0)]
imm = sum((b + o) / 2 for b, o in quotes) / len(quotes)      # stage 1: initial midpoint
open_interest = 150e6                                         # bonds offered for sale
bids = [(41.5, 40e6), (41.0, 50e6), (40.0, 80e6), (39.0, 100e6)]
filled, final = 0.0, None
for price, size in sorted(bids, reverse=True):               # stage 2: best bids first
    filled += size
    if filled >= open_interest: final = price; break
R = final / 100
cash_settle = N * (1 - R)
physical = N - N * final / 100          # buyer buys $10m of bonds at the final price, delivers them for par

# ---- road 4: simulated default times against the closed form ----
q = exp(-(r + lam) / 4)
A_closed = 0.25 * q * (1 - q ** 20) / (1 - q)                 # risky annuity, quarterly
prot_closed = (1 - 0.40) * lam / (r + lam) * (1 - exp(-(r + lam) * T))
x, n, sa, saa, sp, spp = 20260928, 200_000, 0.0, 0.0, 0.0, 0.0
disc = [0.25 * exp(-r * i / 4) for i in range(1, 21)]
for _ in range(n):
    x = (6364136223846793005 * x + 1442695040888963407) % 2**64
    tau = -log(((x >> 11) + 0.5) / 2**53) / lam                  # an exponential default time
    a = sum(disc[i] for i in range(20) if tau > (i + 1) / 4)
    p = (1 - 0.40) * exp(-r * tau) if tau <= T else 0.0
    sa, saa, sp, spp = sa + a, saa + a * a, sp + p, spp + p * p
A_mc, prot_mc = sa / n, sp / n
se_a, se_p = sqrt((saa / n - A_mc ** 2) / n), sqrt((spp / n - prot_mc ** 2) / n)
upfront = (s - c) * A_closed * N

rows = [
    ("quarterly premium, 1/4 year", idealised), ("five years, 20 x 1/4", 20 * idealised),
    ("coupon 20 Dec 26-20 Mar 27, days", days[0]), ("  premium", coupons[0]),
    ("coupon to 20 Jun 27, days", days[1]), ("  premium", coupons[1]),
    ("coupon to 20 Sep 27, days", days[2]), ("  premium", coupons[2]),
    ("coupon to 20 Dec 27, days", days[3]), ("  premium", coupons[3]),
    ("first year, ACT/360", sum(coupons[:4])), ("five years, days", sum(days)),
    ("five years, ACT/360", sum(coupons)),
    ("coupons paid before 19 May 29", paid_n), ("  their total", paid),
    ("accrued, days", (event - dates[paid_n]).days), ("  accrued premium", accrued),
    ("ledger: premiums settled", ledger), ("ledger: accrued at event", owed),
    ("auction initial midpoint", imm), ("auction final price", final),
    ("payout, cash settlement", cash_settle), ("payout, physical", physical),
    ("premium received, with accrued", paid + accrued),
    ("buyer's net gain over the trade", cash_settle - paid - accrued),
    ("Lehman 2008: payout at 8.625", N * (1 - 0.08625)),
    ("risky annuity, closed form", A_closed), ("risky annuity, simulated", A_mc),
    ("  standard error", se_a), ("protection leg, closed form", prot_closed),
    ("protection leg, simulated", prot_mc), ("  standard error", se_p),
    ("par spread, quarterly, bp", 1e4 * prot_closed / A_closed),
    ("upfront, 120 bp on 100 coupon", upfront),
    ("per 1 bp: premium per quarter", 1e-4 * N / 4), ("per 1 bp: upfront", 1e-4 * A_closed * N),
    ("per recovery point: payout", -0.01 * N),
    ("wrong: recovery as payout", N * R), ("wrong: spread per quarter", s * N),
    ("wrong: 120 bp read as 12%", 0.12 * N / 4),
    ("try: 500 bp, per quarter", 0.05 * N / 4), ("try: 500 bp coupon, upfront", (s - 0.05) * A_closed * N),
]
for name, v in rows:
    print(f"{name:<36} {v:>18.6f}")
print("chart, recovery %    " + " ".join(f"{10 * k:5d}" for k in range(11)))
print("chart, payout $m     " + " ".join(f"{N * (1 - k / 10) / 1e6:5.0f}" for k in range(11)))

assert abs(ledger - paid) < 1e-6, "day-by-day ledger vs coupons from day counts"
assert abs(owed - accrued) < 1e-6, "ledger's unpaid days vs the accrued formula"
assert sum(days) == 5 * 365 + sum(1 for y in range(2027, 2032) if y % 4 == 0), "calendar vs leap years"
assert abs(A_mc - A_closed) < 4 * se_a, "simulated risky annuity vs closed form"
assert abs(prot_mc - prot_closed) < 4 * se_p, "simulated protection leg vs closed form"
assert abs(A_closed - 4.1819) < 5e-5, "house risky annuity"
clear = max(p for p, _ in bids if sum(z for b, z in bids if b >= p) >= open_interest)
assert final == clear, "auction fill loop vs clearing-price rule"
assert abs(cash_settle - 6_000_000) < 1e-6, "house payout at the auction's 40"
up_sum = sum((s - c) * N * 0.25 * exp(-(r + lam) * i / 4) for i in range(1, 21))
assert abs(upfront - up_sum) < 1e-6, "upfront: geometric closed form vs quarter-by-quarter sum"
assert abs(prot_closed - 0.050625) < 5e-7, "house protection leg"
assert abs(1e4 * prot_closed / A_closed - 121.06) < 5e-3, "house par spread, quarterly"
print("ALL CHECKS PASS")
