# Hazard rate and survival probability -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the slice product is a loop, the integral is Simpson's rule written out, the inverse
# is bisection, and the coin flips come from a hand-written random number generator.
from math import exp, log

LAM = 0.02                                          # Northwind's flat hazard, per year
flat = lambda t: LAM
rising = lambda t: 0.01 + 0.004 * t                 # 1% a year now, 3% a year at year 5

def surv(lam, t): return exp(-lam * t)              # road 1: the formula, flat hazard

def slices(hazard, a, b, n):                        # road 2: cut [a, b] into n slices, multiply
    dt, s = (b - a) / n, 1.0
    for i in range(n):
        s *= 1.0 - hazard(a + (i + 0.5) * dt) * dt  # survive this slice
    return s

def simpson(f, a, b, n=2000):                       # area under f from a to b
    h = (b - a) / n
    tot = f(a) + f(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return tot * h / 3.0

def surv_general(hazard, t): return exp(-simpson(hazard, 0.0, t))

def invert(S, T):                                   # flat hazard giving survival S at T, by bisection
    if not (0.0 < S <= 1.0): return None            # S = 0 or outside (0, 1]: no answer
    if S == 1.0: return 0.0
    lo, hi = 0.0, 1.0
    while exp(-hi * T) > S: hi *= 2.0               # widen until the target is bracketed
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if exp(-mid * T) > S: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

class Rng:                                          # 64-bit linear congruential generator
    def __init__(self, seed): self.x = seed
    def u(self):
        self.x = (6364136223846793005 * self.x + 1442695040888963407) % 2**64
        return (self.x >> 11) / 2.0**53

def coin_flips(firms, months, seed):                # road 4: no exp, no log, just monthly flips
    rng, dead_by_year = Rng(seed), [0] * (months // 12 + 1)
    for _ in range(firms):
        for m in range(months):
            if rng.u() < LAM / 12.0:
                dead_by_year[m // 12 + 1] += 1
                break
    return [d / firms for d in dead_by_year]

S1, S2, S3, S5 = surv(LAM, 1), surv(LAM, 2), surv(LAM, 3), surv(LAM, 5)
year3 = S2 - S3
year3_int = simpson(lambda t: LAM * surv(LAM, t), 2.0, 3.0)
year3_cond = 1.0 - S3 / S2
S5_slices = slices(flat, 0.0, 5.0, 100000)
pd5_int = simpson(lambda t: LAM * surv(LAM, t), 0.0, 5.0)
mc = coin_flips(100000, 60, 20260928)
mc5 = sum(mc)
se5 = (mc5 * (1.0 - mc5) / 100000) ** 0.5
lam_85 = invert(0.85, 5.0)
rows = [
    ("S(1)  survive one year", S1), ("S(2)", S2), ("S(3)", S3), ("S(5)  survive five years", S5),
    ("1 default chance by 5, 1 - S(5)", 1.0 - S5),
    ("2 slice product, 100000 slices, S(5)", S5_slices),
    ("3 integral of lambda S(t), 0 to 5", pd5_int),
    ("4 coin flips, 100000 firms, by 5", mc5), ("  one standard error", se5),
    ("year 3 default, S(2) - S(3)", year3), ("year 3 default, integral 2 to 3", year3_int),
    ("year 3 default given alive at 2", year3_cond), ("year 3 default, coin flips", mc[3]),
    ("mean default time 1/lambda", 1.0 / LAM), ("median default time ln2/lambda", log(2.0) / LAM),
    ("carbon-14 rate, ln2/5730", log(2.0) / 5730.0),
    ("S(15)/S(10)  next 5 years at year 10", surv(LAM, 15) / surv(LAM, 10)),
    ("invert S(5) = 0.904837 (bisection)", invert(S5, 5.0)),
    ("invert S(5) = 0.85 (bisection)", lam_85), ("  -ln(0.85)/5", -log(0.85) / 5.0),
    ("invert S(5) = 1", invert(1.0, 5.0)), ("invert S(5) = 1e-12", invert(1e-12, 5.0)),
    ("wrong: 1 - lambda T, 5 years", 1.0 - LAM * 5), ("wrong: 1 - lambda T, 30 years", 1.0 - LAM * 30),
    ("  right: S(30)", surv(LAM, 30)), ("wrong: 0.98^5, default by 5", 1.0 - 0.98 ** 5),
    ("wrong: lambda = (1 - S)/T from 0.85", 0.15 / 5.0),
    ("rising: S(5), exp(-area)", surv_general(rising, 5.0)),
    ("rising: S(5), slice product", slices(rising, 0.0, 5.0, 100000)),
    ("rising: next 5 years at year 5", surv_general(rising, 10.0) / surv_general(rising, 5.0)),
    ("try: flat 4%, S(5)", surv(0.04, 5)), ("try: flat 2%, S(10)", surv(LAM, 10)),
]
for name, v in rows:
    print(f"{name:<38} {v:>12.6f}")
print(f"{'invert S(5) = 0':<38} {'no answer' if invert(0.0, 5.0) is None else 'BUG':>12}")
print("slices  n     S(5) by slice product")
for n in (5, 60, 1825):
    print(f"{n:>12d}  {slices(flat, 0.0, 5.0, n):.6f}")
print("year   flat %   rising %")
for k in range(1, 6):
    f = 100 * (surv(LAM, k - 1) - surv(LAM, k))
    g = 100 * (surv_general(rising, k - 1) - surv_general(rising, k))
    print(f"{k:>4} {f:8.2f} {g:10.2f}")
print("chart, years      " + " ".join(f"{t:6d}" for t in range(0, 55, 5)))
print("chart, exp(-lt)   " + " ".join(f"{surv(LAM, t):6.2f}" for t in range(0, 55, 5)))
print("chart, 1 - lt     " + " ".join(f"{1 - LAM * t:6.2f}" for t in range(0, 55, 5)))
print("chart, flat 0-10  " + " ".join(f"{surv(LAM, t):6.2f}" for t in range(0, 11)))
print("chart, rising     " + " ".join(f"{surv_general(rising, t):6.2f}" for t in range(0, 11)))

assert abs(S5_slices - S5) < 1e-7,                "slice product must converge on exp(-lambda T)"
assert abs(year3_int - year3) < 1e-12,            "integrated density must equal the survival drop"
assert abs(mc5 - (1.0 - S5)) < 4 * se5,           "coin flips within four standard errors"
assert abs(lam_85 - (-log(0.85) / 5.0)) < 1e-14,  "bisection inverse must match -ln S / T"
assert abs(surv_general(rising, 5.0) - slices(rising, 0.0, 5.0, 100000)) < 1e-7, "general case, two roads"
assert abs(pd5_int - (1.0 - S5)) < 1e-12,         "area under lambda S(t) must equal 1 - S(5)"
assert invert(0.0, 5.0) is None and abs(invert(1e-12, 5.0) + log(1e-12) / 5.0) < 1e-12, "inverse boundary cases"
print("ALL CHECKS PASS")
