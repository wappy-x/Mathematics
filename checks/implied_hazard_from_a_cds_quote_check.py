# Implied hazard from one CDS quote -- the check behind the card.  Standard
# library only; nothing imported knows the answer.  A festival promoter's
# five-year CDS is quoted at 300 bp, recovery 40%, riskless rate 5% (flat,
# continuous), premiums quarterly in arrears, no accrual on default.
# Three roads to the flat hazard: bisection on legs priced by Simpson's rule,
# Newton on the closed form, and a Monte Carlo that reprices at the answer.
from math import exp, sqrt, log

QUOTE, REC, RATE, T, DT = 0.0300, 0.40, 0.05, 5.0, 0.25

def flat(t): return exp(-RATE * t)                 # discount factor D(t)
def sloped(t): return exp(-(0.02 + 0.01 * t) * t)  # a rising curve, for the uniqueness sweep

def simpson(f, a, b, n=20):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def annuity(lam, D=flat, T=T):                     # risky annuity: premiums of DT at each quarter, if alive
    return sum(DT * D(j * DT) * exp(-lam * j * DT) for j in range(1, round(T / DT) + 1))

def protection(lam, D=flat, T=T, rec=REC):         # (1-R) x integral of lam e^{-lam t} D(t) dt, quarter by quarter
    f = lambda t: lam * exp(-lam * t) * D(t)
    return (1 - rec) * sum(simpson(f, (j - 1) * DT, j * DT) for j in range(1, round(T / DT) + 1))

def par(lam, D=flat, T=T, rec=REC): return protection(lam, D, T, rec) / annuity(lam, D, T)

def g(x): return (exp(x) - 1) / x                  # (e^x - 1)/x, always above 0 and rising
def par_closed(lam, r=RATE, rec=REC):              # the card's formula: maturity has dropped out
    return (1 - rec) * lam * g((r + lam) * DT)

def bisect(quote, lo, hi, halvings, **kw):
    mids = []
    for _ in range(halvings):
        m = (lo + hi) / 2
        mids.append(m)
        if par(m, **kw) > quote: hi = m
        else: lo = m
    return (lo + hi) / 2, mids

def newton(quote, lam, r=RATE, rec=REC):
    path = [lam]
    for _ in range(50):
        x = (r + lam) * DT
        gp = (x * exp(x) - exp(x) + 1) / (x * x)   # slope of g
        step = (par_closed(lam, r, rec) - quote) / ((1 - rec) * (g(x) + lam * DT * gp))
        lam -= step
        path.append(lam)
        if abs(step) < 1e-15: break
    return lam, path

seed = QUOTE / (1 - REC)                            # the credit triangle's guess
lam_b, mids = bisect(QUOTE, 0.0, seed, 60)
lam_n, npath = newton(QUOTE, seed)
fp = [seed]                                         # fixed point, the by-hand road
for _ in range(3): fp.append(QUOTE / ((1 - REC) * g((RATE + fp[-1]) * DT)))

# road 3: simulate default times at the implied hazard; reprice both legs
state, N, NQ = 20260928, 1000000, round(T / DT)
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
cum = [0.0]                                         # PV of the first k premiums, per unit spread
for j in range(1, NQ + 1): cum.append(cum[-1] + DT * flat(j * DT))
sp = sa = szz = spa = saa = 0.0; dead = 0
for _ in range(N):
    tau = -log(uniform()) / lam_b
    p = (1 - REC) * flat(tau) if tau <= T else 0.0
    a = cum[min(int(tau / DT), NQ)]
    sp += p; sa += a; spa += p * a; saa += a * a; szz += p * p
    dead += tau <= T
mp, ma = sp / N, sa / N
s_mc = mp / ma
var_z = (szz - 2 * s_mc * spa + s_mc * s_mc * saa) / N - (mp - s_mc * ma) ** 2
se_mc = sqrt(var_z / N) / ma
pd5 = 1 - exp(-lam_b * T)
se_pd = sqrt(pd5 * (1 - pd5) / N)

print(f"quote {QUOTE*1e4:.0f} bp, recovery {REC:.2f}, r {RATE:.2f}, {T:.0f} years, quarterly")
print(f"seed s/(1-R)                    {seed:.6f}")
print(f"par spread at the seed, bp      {par(seed)*1e4:.4f}")
print("bisection on [0, seed]: step, midpoint, spread bp")
for k in range(12): print(f"  {k+1:>2}  {mids[k]:.6f}  {par(mids[k])*1e4:9.4f}")
print(f"bracket width after 12 halvings {seed/2**12:.7f}")
print(f"road 1 bisection, 60 halvings   {lam_b:.10f}")
print(f"road 2 Newton from the seed     {lam_n:.10f}  in {len(npath)-1} steps")
print("  Newton path   " + "  ".join(f"{x:.8f}" for x in npath[:4]))
print("  fixed point   " + "  ".join(f"{x:.6f}" for x in fp))
print("  its x and g   " + "  ".join(f"{(RATE + l) * DT:.7f} {g((RATE + l) * DT):.7f}" for l in fp[:2]))
print(f"road 3 Monte Carlo spread, bp   {s_mc*1e4:.4f}  (std error {se_mc*1e4:.4f})")
print(f"  MC 5y default fraction        {dead/N:.6f}  (std error {se_pd:.6f})")
print(f"five-year default chance        {pd5:.6f}")
print(f"risky annuity                   {annuity(lam_b):.6f}")
print(f"protection leg per $1           {protection(lam_b):.6f}")
print(f"on $10m: protection PV $        {1e7*protection(lam_b):.2f}")
print(f"house check, 2% hazard: par bp  {par(0.02)*1e4:.4f}  annuity {annuity(0.02):.4f}")
print("maturity drops out: implied hazard at T = 1, 3, 10")
for TT in (1.0, 3.0, 10.0): print(f"  T = {TT:>4.0f}                     {bisect(QUOTE, 0.0, seed, 60, T=TT)[0]:.10f}")
flat_up = all(par(i * 0.005) < par((i + 1) * 0.005) for i in range(200))
slope_up = all(par(i * 0.005, sloped) < par((i + 1) * 0.005, sloped) for i in range(200))
print(f"spread rises on 0..100%: flat {'yes' if flat_up else 'no'}, sloped {'yes' if slope_up else 'no'}")
print(f"sloped curve implied hazard     {bisect(QUOTE, 0.0, seed, 60, D=sloped)[0]:.6f}")
print(f"R = 1: spread at 5% and 50%     {par(0.05, rec=1.0):.6f}  {par(0.5, rec=1.0):.6f}")
print("what breaks:")
print(f"  no recovery, hazard = s       {QUOTE:.6f}  5y default {1-exp(-QUOTE*T):.6f}")
print(f"  triangle seed kept            {seed:.6f}  5y default {1-exp(-seed*T):.6f}")
print(f"  default chance as 5 x hazard  {T*lam_b:.6f}")
print("try: R = 0.25, R = 0.60, 600 bp, r = 0")
print(f"  {newton(QUOTE, QUOTE/0.75, rec=0.25)[0]:.6f}  {newton(QUOTE, QUOTE/0.4, rec=0.60)[0]:.6f}"
      f"  {newton(0.06, 0.1)[0]:.6f}  {newton(QUOTE, seed, r=0.0)[0]:.6f}")
print("chart, hazard %   " + " ".join(f"{i:6d}" for i in range(11)))
print("chart, par bp     " + " ".join(f"{par(i/100)*1e4:6.2f}" for i in range(11)))
print("chart, triangle bp" + " ".join(f"{(1-REC)*i/100*1e4:6.2f}" for i in range(11)))

assert abs(lam_b - lam_n) < 1e-10, "bisection on Simpson legs vs Newton on the closed form"
assert abs(s_mc - QUOTE) < 4 * se_mc, "simulated defaults reprice the quote within 4 standard errors"
assert abs(dead / N - pd5) < 4 * se_pd, "simulated default fraction vs 1 - e^(-lam T)"
assert abs(fp[-1] - lam_n) < 1e-6, "the by-hand fixed point lands on Newton's answer"
assert flat_up, "par spread strictly rising in the hazard, flat curve"
assert slope_up, "par spread strictly rising in the hazard, sloped curve"
print("ALL CHECKS PASS")
