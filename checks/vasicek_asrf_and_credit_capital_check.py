# The Basel credit formula (IRB risk weight from one-factor Vasicek) -- the check behind the card.
# Standard library only: N(x) from math.erf, its inverse by bisection, hand-written random numbers.
# Three roads to the 78% mortgage risk weight: the formula, the Basel Committee's own published
# table (CRE99), and a simulation of a whole loan book over two million economies.
from math import erf, exp, log, sqrt, cos, pi

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))            # bell-curve area left of x
def Ninv(u):                                                  # its inverse, by bisection
    lo, hi = -40.0, 40.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if N(mid) < u: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

Z999 = Ninv(0.999)                                            # the 1-in-1000 bad economy
def q_stress(pd, r, z=Z999):                                  # default rate in that economy
    return N((Ninv(pd) + sqrt(r) * z) / sqrt(1.0 - r))
def b_slope(pd): return (0.11852 - 0.05478 * log(pd)) ** 2
def mat_adj(pd, m): return (1.0 + (m - 2.5) * b_slope(pd)) / (1.0 - 1.5 * b_slope(pd))
def K(pd, lgd, r, m=None, z=Z999):                            # capital per dollar lent
    k = lgd * (q_stress(pd, r, z) - pd)
    return k if m is None else k * mat_adj(pd, m)
def RW(*a, **kw): return 100.0 * 12.5 * K(*a, **kw)          # risk weight, percent
def r_corp(pd):                                               # 24% for the safest, 12% for the riskiest
    w = (1.0 - exp(-50.0 * pd)) / (1.0 - exp(-50.0))
    return 0.12 * w + 0.24 * (1.0 - w)
def r_other(pd):                                              # other retail: 16% down to 3%
    w = (1.0 - exp(-35.0 * pd)) / (1.0 - exp(-35.0))
    return 0.03 * w + 0.16 * (1.0 - w)
def r_sme(pd, sales): return r_corp(pd) - 0.04 * (1.0 - (min(max(sales, 5.0), 50.0) - 5.0) / 45.0)

PD, LGD, EAD, R_MORT = 0.02, 0.40, 200000.0, 0.15            # the home loan on the card
c = Ninv(PD)
q = q_stress(PD, R_MORT)
k = K(PD, LGD, R_MORT)
rw = RW(PD, LGD, R_MORT)
rows = [("threshold N^-1(PD)", c, 6), ("bad economy N^-1(0.999)", Z999, 6),
        ("shared weight sqrt(R)", sqrt(R_MORT), 6), ("private weight sqrt(1-R)", sqrt(1 - R_MORT), 6),
        ("stress argument", (c + sqrt(R_MORT) * Z999) / sqrt(1 - R_MORT), 6),
        ("bad-year default rate q", q, 6), ("expected loss rate PD*LGD", PD * LGD, 6),
        ("bad-year loss rate LGD*q", LGD * q, 6), ("K, capital per dollar", k, 6),
        ("1 risk weight by formula %", rw, 4), ("RWA on the $200,000 loan", EAD * rw / 100, 2),
        ("capital at 8% $", 0.08 * EAD * rw / 100, 2), ("expected loss $", EAD * PD * LGD, 2),
        ("loss if the family defaults $", EAD * LGD, 2)]

# ---- road 2: the Basel Committee's published illustrative risk weights, CRE99 Table 1, PD 2% ----
table = [("mortgage, LGD 25%", 48.85, RW(PD, 0.25, R_MORT)), ("mortgage, LGD 45%", 87.94, RW(PD, 0.45, R_MORT)),
         ("corporate, LGD 40%, M 2.5", 102.09, RW(PD, 0.40, r_corp(PD), 2.5)),
         ("SME sales 5m, LGD 40%, M 2.5", 78.71, RW(PD, 0.40, r_sme(PD, 5.0), 2.5)),
         ("other retail, LGD 45%", 57.99, RW(PD, 0.45, r_other(PD))), ("QRRE, LGD 85%", 54.63, RW(PD, 0.85, 0.04))]
interp = 0.25 * 48.85 + 0.75 * 87.94                          # LGD 40% sits 3/4 of the way from 25% to 45%
rows += [("2 risk weight from the table %", interp, 4)]

# ---- road 3: simulate the economy for the house bank's $1bn book, loss by loss, no quantile formula ----
MORT, CORP = 600e6, 400e6                                     # mortgages as above; one-year corporate loans
r_c = r_corp(PD)
state = 0x2545F4914F6CDD1D
def unif():
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) / 9007199254740992.0 + 1e-17
DRAWS = 2000000
mort_rate, book = [], []
for _ in range(DRAWS):
    m = sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())    # this year's economy
    qm = N((c - sqrt(R_MORT) * m) / sqrt(1 - R_MORT))
    qc = N((c - sqrt(r_c) * m) / sqrt(1 - r_c))
    mort_rate.append(qm)
    book.append(LGD * (MORT * qm + CORP * qc))
mort_rate.sort(); book.sort()
idx = int(0.999 * DRAWS)
sim_rw = 100.0 * 12.5 * LGD * (mort_rate[idx] - PD)
sim_cap = book[idx] - LGD * PD * (MORT + CORP)
loan_cap = MORT * K(PD, LGD, R_MORT) + CORP * K(PD, LGD, r_c)
rows += [("3 simulated risk weight %", sim_rw, 4),
         ("$1bn book: mortgages alone, capital", MORT * k, 2), ("$1bn book: capital, loan by loan", loan_cap, 2),
         ("$1bn book: capital, simulated", sim_cap, 2), ("  simulated / loan by loan - 1", sim_cap / loan_cap - 1, 6), ("$1bn book: RWA, loan by loan", 12.5 * loan_cap, 2)]

# ---- the prescribed inputs, one at a time ----
rows += [("maturity slope b(2%)", b_slope(PD), 6), 
         ("maturity adj M = 2.5", mat_adj(PD, 2.5), 6), ("maturity adj M = 5", mat_adj(PD, 5.0), 6),
         ("corporate weight w at 2%", (1 - exp(-50 * PD)) / (1 - exp(-50)), 6), ("corporate correlation at 2%", r_c, 6), ("bars: QRRE, R 4%", RW(PD, LGD, 0.04), 2),
         ("bars: other retail", RW(PD, LGD, r_other(PD)), 2), ("bars: SME, M 2.5", RW(PD, LGD, r_sme(PD, 5.0), 2.5), 2),
         ("bars: mortgage, R 15%", rw, 2), ("bars: corporate, M 1", RW(PD, LGD, r_c, 1.0), 2),
         ("bars: corporate, M 2.5", RW(PD, LGD, r_c, 2.5), 2), ("bars: large bank, M 2.5", RW(PD, LGD, 1.25 * r_c, 2.5), 2)]
for a in (0.99, 0.995, 0.999, 0.9997):
    rows += [(f"conf {100 * a:g}%: risk weight", RW(PD, LGD, R_MORT, z=Ninv(a)), 2)]
rows += [("wrong: expected loss left in %", 100 * 12.5 * LGD * q, 2),
         ("wrong: M 2.5 adjustment on a mortgage %", RW(PD, LGD, R_MORT, 2.5), 2),
         ("wrong: N^-1(0.001), capital $", EAD * K(PD, LGD, R_MORT, z=-Z999), 2),
         ("try: LGD 20% %", RW(PD, 0.20, R_MORT), 2), ("try: PD 0.5% %", RW(0.005, LGD, R_MORT), 2),
         ("try: PD 10% %", RW(0.10, LGD, R_MORT), 2), ("try: R 25% %", RW(PD, LGD, 0.25), 2)]
for name, v, d in rows:
    print(f"{name:<40} {v:>16.{d}f}")
print("CRE99 Table 1, PD 2%                    published    formula")
for name, pub, mine in table:
    print(f"  {name:<36} {pub:>9.2f} {mine:>10.4f}")
pds = (0.001, 0.0025, 0.005, 0.01, 0.02, 0.03, 0.05, 0.10, 0.20)
print("chart, PD %        " + " ".join(f"{100 * p:6.2f}" for p in pds))
print("chart, mortgage    " + " ".join(f"{RW(p, LGD, R_MORT):6.2f}" for p in pds))
print("chart, corporate   " + " ".join(f"{RW(p, LGD, r_corp(p), 2.5):6.2f}" for p in pds))

for name, pub, mine in table:
    assert abs(mine - pub) < 0.006, "formula must reproduce the Basel Committee's published weight: " + name
assert abs(interp - rw) < 0.01,              "table road vs formula road"
assert abs(sim_rw - rw) < 1.5,                "simulated 99.9% mortgage weight within noise of the formula"
assert abs(sim_cap / loan_cap - 1.0) < 0.02,  "book capital from the simulated loss equals the loan-by-loan sum"
print("ALL CHECKS PASS")
