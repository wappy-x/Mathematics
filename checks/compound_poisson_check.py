# Compound Poisson -- the check behind the card.  Only math is imported.
# Insurance claims arrive at 4 an hour; each is $100, $500 or $2,000 with
# chances 0.5, 0.3 and 0.2.  S(t) is the total claimed by hour t.  Roads to its
# mean, variance and moment generating function: the formulas; the exact law of
# S(t), built by conditioning on the count and adding claim laws; the hour cut
# into m slots with at most one claim each; and 20000 simulated hours.
import math

LAM, SIZES, PROBS = 4.0, [100, 500, 2000], [0.5, 0.3, 0.2]
SEED, HOURS, DIAL, BIG = 20260929, 20000, 0.0002, 10000
MASK = (1 << 64) - 1

def claim_moment(k):                     # E[Y^k], the claim law's k-th moment
    return sum(p * a ** k for a, p in zip(SIZES, PROBS))

def m_claim(s):                          # M_Y(s) = E[e^(sY)]
    return sum(p * math.exp(s * a) for a, p in zip(SIZES, PROBS))

def m_total(s, lt):                      # the card's formula: exp(lt (M_Y(s) - 1))
    return math.exp(lt * (m_claim(s) - 1))

def exact_law(lt):                       # P(S = 100 x) for x = 0, 1, 2, ...
    nmax = int(lt + 12 * math.sqrt(lt) + 30)
    top = max(SIZES) // 100               # grid steps of $100 in the largest claim
    size = top * (nmax + 1) + 1
    law, conv = [0.0] * size, [0.0] * size
    conv[0], pn, kept = 1.0, math.exp(-lt), 0.0
    for n in range(nmax + 1):            # conv = law of n claims added up
        for x in range(top * n + 1):
            law[x] += pn * conv[x]
        kept += pn
        new = [0.0] * size
        for x in range(top * n + 1):
            for a, p in zip(SIZES, PROBS):
                new[x + a // 100] += conv[x] * p
        conv, pn = new, pn * lt / (n + 1)
    return law, 1.0 - kept

def summary(law):                        # mean, variance, third central moment
    mean = sum(100 * x * q for x, q in enumerate(law))
    var = sum((100 * x - mean) ** 2 * q for x, q in enumerate(law))
    third = sum((100 * x - mean) ** 3 * q for x, q in enumerate(law))
    return mean, var, third

class SplitMix64:                        # the wing's generator, written out
    def __init__(self, seed):
        self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def claims_until(g, t):                  # one run: exponential gaps, then sizes
    clock, out = 0.0, []
    while True:
        clock += -math.log(1.0 - g.uniform()) / LAM
        if clock > t:
            return out
        u = g.uniform()
        out.append((clock, 100 if u < 0.5 else (500 if u < 0.8 else 2000)))

mu, m2, m3 = claim_moment(1), claim_moment(2), claim_moment(3)
print(f"claims: {LAM:.0f} an hour, sizes {SIZES} with chances {PROBS}")
print(f"claim law: mean {mu:.2f}, E[Y^2] {m2:.2f}, Var(Y) {m2 - mu * mu:.2f}, E[Y^3] {m3:.0f}")
for a, p in zip(SIZES, PROBS):
    print(f"split stream of ${a} claims: rate {LAM * p:.1f} an hour, adds {a * a * LAM * p:.0f} to the variance,"
          f" {100 * a * a * p / m2:.1f} percent of it")
for t in (1, 8):
    lt = LAM * t
    law, lost = exact_law(lt)
    em, ev, e3 = summary(law)
    mgf_exact = sum(q * math.exp(DIAL * 100 * x) for x, q in enumerate(law))
    print(f"t = {t} h  formula  mean {lt * mu:.2f}  var {lt * m2:.2f}  sd {math.sqrt(lt * m2):.2f}"
          f"  third {lt * m3 / 1e9:.4f}e9  M({DIAL}) {m_total(DIAL, lt):.6f}")
    print(f"t = {t} h  exact    mean {em:.2f}  var {ev:.2f}  sd {math.sqrt(ev):.2f}"
          f"  third {e3 / 1e9:.4f}e9  M({DIAL}) {mgf_exact:.6f}")
    print(f"t = {t} h  skewness {lt * m3 / (lt * m2) ** 1.5:.4f}; P(S = 0) {law[0]:.6f} = e^-{lt:.0f};"
          f" chance left out below 1e-12: {'yes' if lost < 1e-12 else 'no'}")
    assert abs(em - lt * mu) < 1e-6 * lt * mu and abs(ev - lt * m2) < 1e-6 * lt * m2
    assert abs(e3 - lt * m3) < 1e-6 * lt * m3              # third cumulant = lt E[Y^3]
    assert abs(mgf_exact / m_total(DIAL, lt) - 1) < 1e-9
    if t == 1:
        law1 = law
print(f"M_Y({DIAL}) = {m_claim(DIAL):.6f}; exponent {LAM:.0f} x {m_claim(DIAL) - 1:.6f} = {LAM * (m_claim(DIAL) - 1):.6f}")
for m in (10, 100, 1000, 10000):         # the hour in m slots, one claim at most each
    p = LAM / m
    var_m = m * (p * m2 - (p * mu) ** 2)
    mgf_m = math.exp(m * math.log(1 + p * (m_claim(DIAL) - 1)))
    print(f"slots m = {m:5d}: var {var_m:.2f} (short by {LAM * m2 - var_m:.2f}),"
          f" M({DIAL}) {mgf_m:.6f} (short by {m_total(DIAL, LAM) - mgf_m:.6f})")
    lnm = lambda s: m * math.log1p(p * (m_claim(s) - 1))    # ln of the slot MGF
    assert abs((lnm(1e-6) + lnm(-1e-6)) / 1e-12 / var_m - 1) < 1e-5   # its curvature at 0 = variance
assert abs(mgf_m / m_total(DIAL, LAM) - 1) < 1e-4
g, totals = SplitMix64(SEED + 1), []
for _ in range(HOURS):
    totals.append(sum(a for _, a in claims_until(g, 1.0)))
n = len(totals)
sm = sum(totals) / n
c2 = sum((x - sm) ** 2 for x in totals) / n
c4 = sum((x - sm) ** 4 for x in totals) / n
sv = c2 * n / (n - 1)
es = [math.exp(DIAL * x) for x in totals]
se_m, sd_e = (sum(es) / n, math.sqrt(sum((e - sum(es) / n) ** 2 for e in es) / (n - 1)))
zeros = sum(1 for x in totals if x == 0) / n
print(f"simulated {HOURS} hours: mean {sm:.2f} +- {math.sqrt(sv / n):.2f}, var {sv:.0f} +- {math.sqrt((c4 - c2 * c2) / n):.0f},"
      f" M({DIAL}) {se_m:.4f} +- {sd_e / math.sqrt(n):.4f}, P(S = 0) {zeros:.4f} +- {math.sqrt(zeros * (1 - zeros) / n):.4f}")
assert abs(sm - LAM * mu) < 4 * math.sqrt(sv / n) and abs(sv - LAM * m2) < 4 * math.sqrt((c4 - c2 * c2) / n)
assert abs(se_m - m_total(DIAL, LAM)) < 4 * sd_e / math.sqrt(n)
assert abs(zeros - math.exp(-LAM)) < 4 * math.sqrt(zeros * (1 - zeros) / n)
bands = [sum(law1[10 * b:10 * b + 10]) for b in range(10)] + [sum(law1[100:])]
simb = [sum(1 for x in totals if min(x // 1000, 10) == b) / n for b in range(11)]
print(f"figure, exact P(S(1) in $1000 band 0..9, then 10000 up), percent: {', '.join(f'{100 * q:.2f}' for q in bands)}")
print(f"figure, simulated, same bands, percent: {', '.join(f'{100 * q:.2f}' for q in simb)}")
print(f"figure, standard error of each simulated band, percent: {', '.join(f'{100 * math.sqrt(q * (1 - q) / n):.2f}' for q in simb)}")
lo, hi = 0.0, 0.003                      # Chernoff: minimise e^(-s x) M_S(s) over s
for _ in range(200):
    a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    if -a * BIG + LAM * (m_claim(a) - 1) < -b * BIG + LAM * (m_claim(b) - 1):
        hi = b
    else:
        lo = a
bound = math.exp(-lo * BIG + LAM * (m_claim(lo) - 1))
print(f"tail: exact P(S(1) >= {BIG}) {bands[10]:.6f}; MGF bound {bound:.6f} at s = {lo:.6f} per dollar")
assert bands[10] <= bound < 1.0
path = claims_until(SplitMix64(SEED), 8.0)
grid = [sum(a for c, a in path if c <= k / 4) for k in range(33)]
print(f"figure, one simulated shift, total every 15 minutes: {', '.join(str(v) for v in grid)}")
print(f"figure, that shift: {len(path)} claims, total {grid[-1]}, largest claim {max(a for _, a in path)}")
calm, _ = exact_law(2.0)
storm, _ = exact_law(6.0)
mix = [0.5 * (calm[x] if x < len(calm) else 0.0) + 0.5 * storm[x] for x in range(len(storm))]
_, mv, _ = summary(mix)
print(f"mistake, variance from claim spread only, lt Var(Y): {LAM * (m2 - mu * mu):.2f},"
      f" sd {math.sqrt(LAM * (m2 - mu * mu)):.2f}, missing {100 * mu * mu / m2:.1f} percent")
print(f"mistake, variance from the count only, Var(N) mu^2: {LAM * mu * mu:.2f}")
print(f"mistake, rate 2 or 6 an hour at random: exact var {mv:.2f}, P(S = 0) {mix[0]:.6f}; formula at rate 4 says {LAM * m2:.2f}")
assert abs(mv - (4 * (m2 - mu * mu) + 8 * mu * mu)) < 1e-6 * mv        # E[N] Var(Y) + Var(N) mu^2: 4 and 8
print("ALL CHECKS PASS")
