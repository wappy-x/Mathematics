# Gamma-Poisson -- the check behind the card.  Standard library only (math); no
# statistics or random module.  Prior Gamma(shape 24, rate 2 hours); record: 28
# emails in 2 hours, then 17 in 1 hour.  Road 1: the conjugate update and the
# negative binomial.  Road 2: prior times likelihood on a grid (Simpson), no gamma
# algebra.  Road 3: seeded simulated desks, kept only if 3 hours brought 45 emails.
import math

ALPHA, BETA = 24, 2.0                     # prior shape and prior rate (hours)
RECORD = [(2.0, 28), (1.0, 17)]           # (exposure in hours, emails seen)
STAFF = 20                                # one person clears 20 emails an hour

def update(a, b, record):                 # counts add to the shape, hours to the rate
    return a + sum(y for t, y in record), b + sum(t for t, y in record)

def negbin(A, B, t, top):                 # predictive masses for a window of t hours
    p = B / (B + t)
    q = [p ** A]
    for k in range(top):
        q.append(q[-1] * (A + k) / (k + 1) * (1 - p))
    return q

def poisson(mu, top):                     # p0 = e^-mu, then times mu/(k+1)
    p = [math.exp(-mu)]
    for k in range(top):
        p.append(p[-1] * mu / (k + 1))
    return p

def lfact(n): return sum(math.log(j) for j in range(2, n + 1))
def gamma_cdf(x, a, b): return 1 - sum(poisson(b * x, a - 1))   # whole a: at least a events by time x
def bisect(cdf, c):                       # the x with cdf(x) = c, halving 0 to 40 fifty times
    lo, hi = 0.0, 40.0
    for _ in range(50): mid = (lo + hi) / 2; lo, hi = (lo, mid) if cdf(mid) >= c else (mid, hi)
    return (lo + hi) / 2

def gamma_pdf(x, a, b):                   # whole-number shape a: Gamma(a) = (a-1)!
    return math.exp(a * math.log(b) + (a - 1) * math.log(x) - b * x - lfact(a - 1))

def simpson(f, lo, hi, n=4000):
    h = (hi - lo) / n
    s = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return s * h / 3

def row(label, v): print(f"{label:<44}{v:>12.6f}")

# ---- road 1: the formula ----
A, B = update(ALPHA, BETA, RECORD); K, H = A - ALPHA, B - BETA   # all emails, all hours
mean, sd = A / B, math.sqrt(A) / B
q = negbin(A, B, 1.0, 200)
tail = 1 - sum(q[:STAFF + 1])
plug = poisson(mean, 200)
print(f"posterior Gamma(shape {A}, rate {B:.0f} hours)")
row("prior mean, emails per hour", ALPHA / BETA); row("prior sd", math.sqrt(ALPHA) / BETA)
row("record rate K / H", K / H)
row("prior weight beta / B", BETA / B); row("record weight H / B", H / B)
row("1 posterior mean A / B", mean)
row("1 posterior sd sqrt(A) / B", sd)
ci = [bisect(lambda x: gamma_cdf(x, A, B), c) for c in (0.025, 0.975)]
row("1 rate 95% interval, lower end", ci[0]); row("  upper end", ci[1])
row("1 next hour P(N = 14)", q[14])
row("1 next hour variance tA/B + t^2 A/B^2", A / B + A / B ** 2); row("  of which t^2 A/B^2", A / B ** 2)
row("  plug-in Poisson(13.8) variance", mean)
pt = 1 - sum(plug[:STAFF + 1])
print(f"1 next hour P(N > 20) {tail:.6f} (1 hour in {1 / tail:.1f}); plug-in {pt:.6f} (1 in {1 / pt:.1f})")
m0, m2 = update(ALPHA, BETA, RECORD[:1]), update(*update(ALPHA, BETA, RECORD[1:]), RECORD[:1])
print(f"sequential: after morning {m0[0]}/{m0[1]:.0f}, then {update(*m0, RECORD[1:])[0]}; other order {m2[0]}/{m2[1]:.0f}")

# ---- road 2: prior times likelihood on a grid, windows kept separate ----
def unnorm(lam):
    s = (ALPHA - 1) * math.log(lam) - BETA * lam
    for t, y in RECORD:
        s += y * math.log(t * lam) - t * lam - lfact(y)
    return math.exp(s)
LO, HI = 1e-9, 40.0
Z = simpson(unnorm, LO, HI)
g_mean = simpson(lambda x: x * unnorm(x), LO, HI) / Z
g_var = simpson(lambda x: x * x * unnorm(x), LO, HI) / Z - g_mean ** 2
g_q = [simpson(lambda x, k=k: math.exp(-x + k * math.log(x) - lfact(k)) * unnorm(x), LO, HI) / Z
       for k in range(STAFF + 1)]
row("2 grid posterior mean", g_mean); row("2 grid posterior sd", math.sqrt(g_var))
g_ci = [bisect(lambda x: simpson(unnorm, LO, x) / Z, c) for c in (0.025, 0.975)]
row("2 grid rate 95% interval, lower end", g_ci[0]); row("  upper end", g_ci[1])
row("2 grid P(N = 14)", g_q[14]); row("2 grid P(N > 20)", 1 - sum(g_q))
pmf_mean = sum(k * x for k, x in enumerate(q))
pmf_var = sum(k * k * x for k, x in enumerate(q)) - pmf_mean ** 2
row("  masses 0..200 sum", sum(q)); row("  variance read off the masses", pmf_var)

# ---- road 3: simulated desks (SplitMix64, seed 20260929) ----
state = 20260929
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def count(mu):                            # multiply uniforms until below e^-mu
    lim, prod, n = math.exp(-mu), u01(), 0
    while prod > lim:
        prod *= u01(); n += 1
    return n
WORLDS, kept = 200000, []
for _ in range(WORLDS):
    prod = 1.0
    for _ in range(ALPHA):                # 24 exponential waits of rate 2 add to a Gamma(24, 2)
        prod *= u01()
    lam = -math.log(prod) / BETA
    if count(H * lam) == K:               # H hours of this desk; keep it if K emails came
        kept.append((lam, count(lam)))
n = len(kept); s_mean = sum(l for l, _ in kept) / n
s_sd = math.sqrt(sum((l - s_mean) ** 2 for l, _ in kept) / (n - 1))
s_tail = sum(1 for _, c in kept if c > STAFF) / n
print(f"3 simulated desks {WORLDS}, kept {n}")
row("3 sim posterior mean", s_mean); row("  standard error", s_sd / math.sqrt(n))
row("3 sim posterior sd", s_sd)
row("3 sim next hour P(N > 20)", s_tail); row("  standard error", math.sqrt(s_tail * (1 - s_tail) / n))

# ---- what breaks, and try changing ----
row("wrong: count windows, not hours: mean", A / (BETA + len(RECORD))); row("wrong: rate 2 read as scale 2: mean", A / (0.5 + H))
row("wrong: morning entered twice: mean", (A + 28) / (B + 2)); row("  its sd", math.sqrt(A + 28) / (B + 2))
row("try: prior Gamma(2.4, 0.2): mean", (2.4 + 45) / 3.2)
row("try: six hours, 90 emails: mean", (24 + 90) / 8.0); row("try: six hours, 90 emails: sd", math.sqrt(114) / 8.0)
row("try: half-hour window: mean", 0.5 * A / B); row("try: half-hour window: variance", 0.5 * A / B + 0.25 * A / B ** 2)
row("try: a fourth hour with no email: mean", A / (B + 1))

# ---- chart points ----
xs = range(6, 23)
print("chart, rate      " + " ".join(f"{x:>6d}" for x in xs))
print("chart, prior     " + " ".join(f"{gamma_pdf(x, ALPHA, BETA):6.4f}" for x in xs))
print("chart, posterior " + " ".join(f"{gamma_pdf(x, A, B):6.4f}" for x in xs))
print("chart, count     " + " ".join(f"{k:>6d}" for k in range(4, 27)))
print("chart, predict   " + " ".join(f"{q[k]:6.4f}" for k in range(4, 27)))
print("chart, plug-in   " + " ".join(f"{plug[k]:6.4f}" for k in range(4, 27)))

assert abs(g_mean - mean) < 1e-9, "grid posterior mean vs A/B"
assert max(abs(g_q[k] - q[k]) for k in range(STAFF + 1)) < 1e-9, "grid predictive vs negative binomial"
assert abs(pmf_var - (A / B + A / B ** 2)) < 1e-9, "variance from the masses vs the formula"
assert max(abs(g_ci[i] - ci[i]) for i in (0, 1)) < 1e-8, "grid interval vs the gamma's Poisson sum"
assert abs(s_mean - mean) < 4 * s_sd / math.sqrt(n), "simulated posterior mean within 4 se"
assert abs(s_tail - tail) < 4 * math.sqrt(s_tail * (1 - s_tail) / n), "simulated tail within 4 se"
print("ALL CHECKS PASS")
