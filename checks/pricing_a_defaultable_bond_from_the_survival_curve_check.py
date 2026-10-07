# A risky bond from the hazard curve -- the check behind the card.  Standard library only.
# Northwind's five-year bond: face 100, 6% annual coupon, riskless rate 5% continuously
# compounded, hazard 2% a year, recovery 40% of face paid at default.  Nothing imported
# knows the answer: the integrator, root finder and random numbers are written below.
from math import exp, log, sqrt

F, CPN, T, R, RATE, LAM = 100.0, 6.0, 5, 0.40, 0.05, 0.02
FLAT = [(1e9, LAM)]                                      # hazard curve: (end of piece, rate)
BOOT = [(1.0, 0.019826), (3.0, 0.040440), (1e9, 0.056837)]   # bootstrapped from 120/200/250 bp

def cum_hazard(curve, t):                                # area under the hazard from 0 to t
    area, start = 0.0, 0.0
    for end, lam in curve:
        area += lam * (min(t, end) - start)
        if t <= end: return area
        start = end
def hazard(curve, t): return next(lam for end, lam in curve if t < end)
def Q(curve, t): return exp(-cum_hazard(curve, t))       # survival to t
def D(t): return exp(-RATE * t)                          # riskless discount factor

def simpson(f, a, b, n=200):                             # area under f from a to b, n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
def flows(disc): return sum(CPN * disc(t) for t in range(1, T + 1)) + F * disc(T)
def closed_form(lam, rec=R):                             # road 1: flat curves, recovery of face
    k = RATE + lam
    return flows(lambda t: exp(-k * t)), rec * F * lam * (1 - exp(-k * T)) / k

def dated_sum(curve, rec=R):                             # road 2: any curve, dated sum + quadrature
    promised = flows(lambda t: D(t) * Q(curve, t))
    recovery = sum(simpson(lambda t: rec * F * hazard(curve, t) * Q(curve, t) * D(t), a, a + 1)
                   for a in range(T))
    return promised + recovery

def riskless_minus_loss(curve):                          # road 2b: riskless price less expected loss
    def still_owed(t, a):                                # value at t of what is still promised, in year a+1
        return sum(CPN * exp(-RATE * (u - t)) for u in range(a + 1, T + 1)) + F * exp(-RATE * (T - t))
    loss = sum(simpson(lambda t: hazard(curve, t) * Q(curve, t) * D(t) * (still_owed(t, a) - R * F), a, a + 1)
               for a in range(T))
    return flows(D) - loss

M64 = (1 << 64) - 1
class SplitMix:                                          # the splitmix64 generator, written out
    def __init__(self, seed): self.s = seed
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53

def default_time(curve, u):                              # spend the hazard budget -ln u piece by piece
    budget, start = -log(u), 0.0
    for end, lam in curve:
        if budget <= lam * (end - start): return start + budget / lam
        budget -= lam * (end - start); start = end

def rmv_value(t):                                        # pre-default value at t under recovery of market value
    k = RATE + LAM * (1 - R)
    return sum(CPN * exp(-k * (u - t)) for u in range(1, T + 1) if u > t) + F * exp(-k * (T - t))

def simulate(curve, n, seed):                            # road 3: draw default dates, count the cash
    rng, tot, tot2, early, dif, dif2 = SplitMix(seed), 0.0, 0.0, 0, 0.0, 0.0
    for _ in range(n):
        tau = default_time(curve, rng.uniform())
        v = sum(CPN * D(t) for t in range(1, T + 1) if t < tau)
        if tau > T: v += F * D(T)
        else:                                            # x: extra cash if recovery is R x value, not R x face
            early += 1; v += D(tau) * R * F
            x = D(tau) * R * (rmv_value(tau) - F); dif += x; dif2 += x * x
        tot += v; tot2 += v * v
    mean, dm = tot / n, dif / n                          # same draws price both rules, so their gap is sharp
    return mean, sqrt((tot2 / n - mean * mean) / n), early / n, dm, sqrt((dif2 / n - dm * dm) / n)

def bisect(f, lo, hi):                                   # root finder: halve the bracket 200 times
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def cont_yield(price): return bisect(lambda y: flows(lambda t: exp(-y * t)) - price, 0.0, 1.0)

N = 100_000
coup, rec = closed_form(LAM)
p1 = coup + rec
p2, p2b = dated_sum(FLAT), riskless_minus_loss(FLAT)
p3, se3, dflt, gap, se_gap = simulate(FLAT, N, 2026)
rf = flows(D)
p_rmv = flows(lambda t: exp(-(RATE + LAM * (1 - R)) * t))
s_rmv = p3 + gap                                         # RMV priced on the same default dates
y_rf, y1, y_rmv = cont_yield(rf), cont_yield(p1), cont_yield(p_rmv)
k = RATE + LAM
dP_dlam = (-sum(CPN * t * exp(-k * t) for t in range(1, T + 1)) - T * F * exp(-k * T)
           + R * F * ((1 - exp(-k * T)) / k + LAM * (T * exp(-k * T) / k - (1 - exp(-k * T)) / k ** 2)))
bump_lam = (sum(closed_form(LAM + 1e-5)) - sum(closed_form(LAM - 1e-5))) / 2e-5
dP_dR = F * LAM * (1 - exp(-k * T)) / k
bump_R = (dated_sum(FLAT, R + 0.01) - dated_sum(FLAT, R - 0.01)) / 0.02
b2 = dated_sum(BOOT); y_b = cont_yield(b2)
b3, seb3, bdflt, _, _ = simulate(BOOT, N, 44)

face_rf, face_1 = F * D(T), F * exp(-k * T)
rows = [("riskless coupons", rf - face_rf), ("riskless face", face_rf), ("riskless price", rf),
        ("road 1 coupons, survival-weighted", coup - face_1), ("road 1 face, survival-weighted", face_1),
        ("road 1 recovery leg", rec), ("road 1 price, closed form", p1), ("road 2 price, dated sum + Simpson", p2),
        ("road 2b riskless less expected loss", p2b), ("  expected discounted loss", rf - p2b),
        ("road 3 price, 100,000 default dates", p3), ("  standard error", se3),
        ("  share defaulting by year 5", dflt), ("  formula: 1 - Q(5)", 1 - Q(FLAT, 5)),
        ("price at yield 0, the cash added up", flows(lambda t: 1.0)), ("yield, riskless (cont.)", y_rf),
        ("yield, face recovery (cont.)", y1), ("spread, face recovery (bp)", 1e4 * (y1 - y_rf)),
        ("RMV price, rate r + lam(1-R)", p_rmv),
        ("RMV simulated, R x value at default", s_rmv), ("  RMV less face, simulated", gap),
        ("  RMV less face, formula", p_rmv - p1), ("  standard error of the gap", se_gap), ("RMV yield (cont.)", y_rmv),
        ("RMV spread (bp)", 1e4 * (y_rmv - y_rf)), ("dP/dlam, formula", dP_dlam), ("dP/dlam, bump", bump_lam),
        ("  per 1 bp of hazard", dP_dlam * 1e-4), ("dP/dR, formula", dP_dR), ("dP/dR, bump", bump_R),
        ("  per 10 points of recovery", dP_dR * 0.1), ("boot curve price, road 2", b2),
        ("boot curve price, road 3", b3), ("  standard error", seb3), ("  share defaulting by year 5", bdflt),
        ("boot curve spread (bp)", 1e4 * (y_b - y_rf)), ("wrong: no default at all", rf), ("wrong: no recovery", coup),
        ("wrong: recovery paid at year 5", coup + R * F * (1 - Q(FLAT, T)) * D(T)),
        ("wrong: 60% recovery for 40%", sum(closed_form(LAM, 0.60)))]
for name, v in rows: print(f"{name:<38} {v:>12.6f}")
print("weights D(t), years 1..5      " + " ".join(f"{D(t):.6f}" for t in range(1, T + 1)))
print("weights D(t)Q(t), years 1..5  " + " ".join(f"{D(t) * Q(FLAT, t):.6f}" for t in range(1, T + 1)))
print(f"bars, $ riskless {rf - face_rf:.2f} {face_rf:.2f}  risky {coup - face_1:.2f} {face_1:.2f} {rec:.2f}")
hz = [0.01 * i for i in range(11)]
print("chart, hazard %      " + " ".join(f"{100 * h:6.0f}" for h in hz))
print("chart, price RFV     " + " ".join(f"{sum(closed_form(h)):6.2f}" for h in hz))
print("chart, price RMV     " + " ".join(f"{flows(lambda t: exp(-(RATE + h * (1 - R)) * t)):6.2f}" for h in hz))
rc = [0.1 * i for i in range(9)]
print("chart, recovery %    " + " ".join(f"{100 * x:6.0f}" for x in rc))
print("chart, spread RFV bp " + " ".join(f"{1e4 * (cont_yield(sum(closed_form(LAM, x))) - y_rf):6.2f}" for x in rc))
print("chart, spread RMV bp " + " ".join(f"{1e4 * LAM * (1 - x):6.2f}" for x in rc))

assert abs(p2 - p1) < 1e-8, "dated sum with quadrature must land on the closed form"
assert abs(p2b - p1) < 1e-6, "riskless-less-loss road must land on the closed form"
assert abs(p3 - p1) < 3 * se3, "simulation within three standard errors"
assert abs(gap - (p_rmv - p1)) < 3 * se_gap, "RMV: simulated gap between the rules vs the adjusted rate"
assert abs(y_rmv - (RATE + LAM * (1 - R))) < 1e-9, "RMV yield is r + lam(1 - R)"
assert abs(bump_lam - dP_dlam) < 1e-5, "hazard sensitivity: formula vs bump"
assert abs(b3 - b2) < 3 * seb3, "stepped curve: simulation vs dated sum"
print("ALL CHECKS PASS")
