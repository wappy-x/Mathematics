# Default probability, recovery and expected loss -- the check behind the card.
# Standard library only.  Every number quoted on the card is printed here.
# Roads to the expected loss: (1) the product PD x LGD x EAD, (2) listing every
# outcome with its chance, (3) lending to 400,000 simulated cafes with our own
# random numbers.  The fair rate and every back-solve are found twice: by the
# closed form and by a bisection root finder written below.
from math import exp, sqrt

def el(pd, lgd, ead): return pd * lgd * ead                 # road 1: the product

def el_by_outcomes(outcomes):                                 # road 2: sum of chance x loss
    return sum(chance * loss for chance, loss in outcomes)

class Rng:                                                    # 64-bit linear congruential generator
    def __init__(self, seed): self.x = seed
    def u(self):
        self.x = (6364136223846793005 * self.x + 1442695040888963407) % 2**64
        return (self.x >> 11) / 2.0**53                       # uniform on [0, 1)

def bisect(f, lo, hi, tol=1e-13):                             # root finder: f(lo), f(hi) differ in sign
    flo = f(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi); fm = f(mid)
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
        if hi - lo < tol: break
    return 0.5 * (lo + hi)

# ---- the cafe loan: $10,000 for one year, 5% chance of default, 40 cents back on the dollar ----
EAD, PD, R, r = 10000.0, 0.05, 0.40, 0.05
LGD = 1.0 - R
EL1 = el(PD, LGD, EAD)
EL2 = el_by_outcomes([(1 - PD, 0.0), (PD, EAD * (1 - R))])
rng, n, tot, tot2 = Rng(20260928), 400000, 0.0, 0.0
for _ in range(n):                                            # road 3: recovery varies, 10% to 70%, mean 40%
    loss = EAD * (1.0 - (0.10 + 0.60 * rng.u())) if rng.u() < PD else 0.0
    tot += loss; tot2 += loss * loss
EL3 = tot / n
se = sqrt((tot2 / n - EL3 * EL3) / n)

# ---- fair loan rate: (1 + y)(1 - PD LGD) = 1 + r, recovery on everything owed ----
ell = PD * LGD                                                # expected-loss rate
y_closed = (1 + r) / (1 - ell) - 1
pv = lambda y: ((1 - PD) * EAD * (1 + y) + PD * R * EAD * (1 + y)) / (1 + r) - EAD
y_root = bisect(pv, 0.0, 1.0)
y_zero = 1 / (1 - ell) - 1                                    # the same with a riskless rate of zero

# ---- back-solves: linear, so one answer when the other two are nonzero ----
pd_back = 0.09 / (1 - 0.40)
pd_root = bisect(lambda p: el(p, 0.60, 1.0) - 0.09, 0.0, 1.0)
lgd_back = 300.0 / (PD * EAD)
lgd_root = bisect(lambda g: el(PD, g, EAD) - 300.0, 0.0, 1.0)
ead_back = 300.0 / (PD * LGD)
ead_root = bisect(lambda a: el(PD, LGD, a) - 300.0, 0.0, 1e6)
pd_impossible = 0.09 / (1 - 0.95)                             # 9% loss rate at 95% recovery

# ---- two kinds of year: defaults and recoveries move together ----
states = [(0.8, 0.025, 0.55), (0.2, 0.15, 0.30)]              # (chance of year, PD, recovery)
pd_avg = sum(w * p for w, p, _ in states)
rec_year = sum(w * rc for w, _, rc in states)                 # recovery averaged over years
rec_dflt = sum(w * p * rc for w, p, rc in states) / pd_avg    # recovery averaged over defaults
el_true = el_by_outcomes([(w * p, EAD * (1 - rc)) for w, p, rc in states])
el_naive = el(pd_avg, 1 - rec_year, EAD)

# ---- what breaks ----
wrong_rec = el(PD, R, EAD)                                    # recovery used as the loss
wrong_nopd = el(1.0, LGD, EAD)                                # default treated as certain
short_8 = EAD * 1.08 * (1 - ell) / (1 + r) - EAD              # charge 5% + 3% flat
nw_pd5 = 1 - exp(-0.02 * 5)                                   # Northwind: 2% hazard, 5 years
nw_el = el(nw_pd5, 0.60, 100e6)

rows = [
    ("LGD = 1 - R", LGD), ("EL rate PD x LGD", ell),
    ("1 EL, product", EL1), ("2 EL, list the outcomes", EL2),
    ("3 EL, 400000 simulated cafes", EL3), ("  standard error", se),
    ("loss if default", EAD * LGD), ("recovered if default", EAD * R),
    ("fair rate, closed form", y_closed), ("fair rate, root finder", y_root),
    ("  spread over 5%", y_closed - r), ("  spread, riskless rate 0", y_zero),
    ("PD from 9% at R 40%", pd_back), ("  by root finder", pd_root),
    ("LGD from EL 300", lgd_back), ("  by root finder", lgd_root),
    ("EAD from EL 300", ead_back), ("  by root finder", ead_root),
    ("PD from 9% at R 95%", pd_impossible),
    ("two-state PD", pd_avg), ("  recovery, year-averaged", rec_year),
    ("  recovery, default-weighted", rec_dflt),
    ("  EL, true", el_true), ("  EL, year-averaged recovery", el_naive),
    ("wrong: recovery as the loss", wrong_rec), ("wrong: default certain", wrong_nopd),
    ("wrong: charge 8%, PV shortfall", short_8),
    ("Northwind 5y default chance", nw_pd5), ("Northwind 5y EL, undiscounted", nw_el),
    ("try: PD 10%", el(0.10, LGD, EAD)), ("try: R 0%", el(PD, 1.0, EAD)),
    ("try: fair rate, PD 20%", (1 + r) / (1 - 0.20 * LGD) - 1),
]
for name, v in rows:
    print(f"{name:<32} {v:>16.6f}")

print()
recs = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
print(f"{'chart, recovery %':<22}" + "".join(f"{100 * x:>9.0f}" for x in recs))
for p in (0.05, 0.10, 0.15):
    print(f"{'chart, EL at PD ' + str(round(100 * p)) + '%':<22}" + "".join(f"{el(p, 1 - x, EAD):>9.2f}" for x in recs))

assert abs(EL1 - EL2) < 1e-9, "product vs list of outcomes"
assert abs(EL3 - EL1) < 4 * se, "simulation within four standard errors"
assert abs(y_root - y_closed) < 1e-10, "root finder vs closed-form fair rate"
assert abs(pd_root - 0.15) < 1e-10, "back-solved PD vs the card's 15%"
assert abs(lgd_root - lgd_back) < 1e-10 and abs(ead_root - ead_back) < 1e-6, "LGD, EAD back-solves"
assert abs(el_true - EL1) < 1e-9 and abs(rec_dflt - R) < 1e-12, "two kinds of year give the cafe's EL"
assert el_true - el_naive > 40.0, "year-averaged recovery must understate the loss"
print("ALL CHECKS PASS")
