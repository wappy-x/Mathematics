from math import exp, log, sqrt, pi, cos
S, r, q, sig, T = 100.0, 0.05, 0.02, 0.20, 1.0            # the house market
F = S * exp((r - q) * T)                                   # forward, the strip's cut
M64 = (1 << 64) - 1

def N(x):                        # normal CDF from the erf series that converges everywhere
    z = abs(x) / sqrt(2.0)
    if z > 9.0:
        e = 1.0
    else:
        term, total, n = z, z, 0
        while term > 1e-17 * total:
            n += 1
            term *= 2.0 * z * z / (2 * n + 1)
            total += term
        e = 2.0 / sqrt(pi) * exp(-z * z) * total
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)

def bs(K, s, v):                 # Black-Scholes call and put with the house r, q, T
    sd = v * sqrt(T)
    d1 = (log(s / K) + (r - q + 0.5 * v * v) * T) / sd
    d2 = d1 - sd
    return (s * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2),
            K * exp(-r * T) * N(-d2) - s * exp(-q * T) * N(-d1))

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def flat(v):
    return lambda K: v

def strip_pv(volf, s=S, cut=F):  # today's cost of the options: puts below the cut, calls above, 1/K^2 each
    def g(k):                    # in log-strike k = ln(K/cut): Q(K)/K^2 dK = Q(K)/K dk
        K = cut * exp(k)
        c, p = bs(K, s, volf(K))
        return (p if k < 0 else c) / K
    return simpson(g, -3.0, 0.0) + simpson(g, 0.0, 3.0)

def kvar(volf, s=S, cut=F):      # fair strike: 2 e^{rT} / T times the strip
    return 2.0 * exp(r * T) / T * strip_pv(volf, s, cut)

# road 1: the option strip on the flat 20% surface
k1 = kvar(flat(sig))
# road 2: the log contract priced with no options, (2/T) E[-ln(S_T/F)] against the bell curve
dens = lambda z: exp(-0.5 * z * z) / sqrt(2 * pi)
k2 = 2.0 / T * simpson(lambda z: -((-0.5 * sig * sig) * T + sig * sqrt(T) * z) * dens(z), -10.0, 10.0)
# road 3: simulate daily paths; short the log contract, hold 2/(T F_t) futures, compare with realised variance
st = [0x2545F4914F6CDD1D]
def u01():
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & M64
    z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def simulate(paths, volday, days=252):
    dt, rv_all, pl_all = T / days, [], []
    for _ in range(paths):
        rv = pl = 0.0
        for i in range(days):
            v = volday(i)
            y = -0.5 * v * v * dt + v * sqrt(dt) * sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())
            x = y + (r - q) * dt                 # the share's daily log move; y is the forward's
            rv += x * x / T
            pl += 2.0 / T * ((exp(y) - 1.0) - y)  # futures gain minus the log contract's share of the day
        rv_all.append(rv)
        pl_all.append(pl)
    return rv_all, pl_all
def mean_se(a):
    m = sum(a) / len(a)
    return m, sqrt(sum((x - m) ** 2 for x in a) / (len(a) - 1) / len(a))
rv, pl = simulate(4000, lambda i: sig)
rv_m, rv_se = mean_se(rv)
pl_m, pl_se = mean_se(pl)
gap = max(abs(a - b) for a, b in zip(rv, pl))
rv2, pl2 = simulate(1000, lambda i: 0.10 if i < 126 else 0.30)   # a quiet half then a wild half
rv2_m, rv2_se = mean_se(rv2)
k_regime = kvar(flat(sqrt(0.5 * 0.01 + 0.5 * 0.09)))              # options priced off that average variance
gap2 = max(abs(a - b) for a, b in zip(rv2, pl2))
# worked by hand: a two-strike strip, $30 of strike each
c120 = bs(120.0, S, sig)[0]
p90 = bs(90.0, S, sig)[1]
two = 2.0 * exp(r * T) / T * (30.0 / 90.0 ** 2 * p90 + 30.0 / 120.0 ** 2 * c120)
five = 2.0 * exp(r * T) / T * sum(5.0 / K ** 2 * (bs(K, S, sig)[1] if K < F else bs(K, S, sig)[0])
                                  for K in [50.0 + 5.0 * i for i in range(31)])
# what breaks
skew = lambda K: max(0.05, sig - 0.10 * (K - F) / F)
k_skew = kvar(skew)
cut_spot = kvar(flat(sig), S, S)
no_erT = 2.0 / T * strip_pv(flat(sig))
# notionals: $100,000 per vol point, struck at 20 vol points
Nvega, Kvol = 100000.0, 20.0                  # the strike as quoted, in vol points
Nvar = Nvega / (2.0 * Kvol)
# Greeks: vega by re-pricing the strip at 21% and 19%; delta by moving spot; the strip's dollar gamma
vega = exp(-r * T) * Nvar * 1e4 * (kvar(flat(0.21)) - kvar(flat(0.19))) / 2.0
fwd = lambda s: s * exp((r - q) * T)            # a new spot moves the forward, so the cut moves with it
delta = exp(-r * T) * Nvar * 1e4 * (kvar(flat(sig), 101.0, fwd(101.0)) - kvar(flat(sig), 99.0, fwd(99.0))) / 2.0
def dollar_gamma(pv, s, h=0.1):
    return s * s * (pv(s + h) - 2.0 * pv(s) + pv(s - h)) / (h * h)
g_strip = [dollar_gamma(lambda x: 2.0 / T * strip_pv(flat(sig), x, F), s) for s in (60.0, 80.0, 100.0, 120.0, 140.0)]
g_call = [dollar_gamma(lambda x: bs(100.0, x, sig)[0], s) for s in (60.0, 80.0, 100.0, 120.0, 140.0)]
scale = g_strip[2] / g_call[2]

rows = [("forward F", F), ("1 option strip, fair variance", k1), ("  as a vol, percent", 100 * sqrt(k1)),
        ("2 log contract, no options", k2),
        ("3 hedged log P&L, mean of 4000", pl_m), ("  standard error", pl_se),
        ("  realised variance, mean", rv_m), ("  standard error", rv_se), ("  worst path, |P&L - realised|", gap),
        ("  10% then 30%: realised mean", rv2_m), ("  standard error", rv2_se), ("  strip at that average variance", k_regime),
        ("  10% then 30%: worst |P&L - realised|", gap2),
        ("put 90", p90), ("call 120", c120), ("weight 30/90^2", 30.0 / 90 ** 2), ("weight 30/120^2", 30.0 / 120 ** 2),
        ("  put 90 x weight", 30.0 / 90 ** 2 * p90), ("  call 120 x weight", 30.0 / 120 ** 2 * c120),
        ("  sum of the two", 30.0 / 90 ** 2 * p90 + 30.0 / 120 ** 2 * c120), ("2 e^rT / T", 2.0 * exp(r * T) / T), ("two-strike strip", two), ("strikes 50 to 200 every $5", five),
        ("wrong: no e^rT", no_erT), ("wrong: cut at spot 100", cut_spot),
        ("skewed surface: strip", k_skew), ("  ATM vol squared", sig * sig), ("  rule 0.04 (1 + 3 T b^2)", 0.04 * 1.03),
        ("variance notional per var point", Nvar), ("vega by bumping the strip", vega), ("  e^-rT times vega notional", exp(-r * T) * Nvega),
        ("delta by bumping spot", delta if abs(delta) > 5e-7 else 0.0), ("try: sigma = 30%", kvar(flat(0.30))),
        ("try: skew slope 0.20", kvar(lambda K: max(0.05, sig - 0.20 * (K - F) / F))),
        ("  strip dollar gamma, formula 2e^-rT/T", 2.0 * exp(-r * T) / T)]
for name, v in rows:
    print(f"{name:<40} {v:>14.6f}")
print("dollar gamma at spot   " + "".join(f"{s:>9.0f}" for s in (60, 80, 100, 120, 140)))
print("  strip                " + "".join(f"{g:>9.2f}" for g in g_strip))
print("  calls struck 100     " + "".join(f"{scale * g:>9.2f}" for g in g_call))
print("payoff, realised vol   " + "".join(f"{v:>9.0f}" for v in (10, 15, 20, 25, 30)))
print("  variance swap, $000  " + "".join(f"{Nvar * (v * v - Kvol * Kvol) / 1000:>9.2f}" for v in (10, 15, 20, 25, 30)))
print("  vega-linear, $000    " + "".join(f"{Nvega * (v - Kvol) / 1000:>9.2f}" for v in (10, 15, 20, 25, 30)))
print("  at 20.5: var, vega   " + f"{Nvar * (20.5 ** 2 - Kvol ** 2):>12.2f}{Nvega * (20.5 - Kvol):>12.2f}")

assert abs(k1 - sig * sig) < 1e-9, "strip must return the flat surface's variance"
assert abs(k1 - k2) < 1e-9, "strip and log contract are one payoff"
assert abs(pl_m - k1) < 4 * pl_se, "hedged log contract earns the strip on average"
assert abs(rv_m - k1) < 4 * rv_se + 1e-5, "realised variance averages to the strip"
assert gap < 0.002, "hedge tracks realised variance path by path"
assert gap2 < 0.002, "and still does when the volatility changes mid-year"
assert abs(rv2_m - k_regime) < 4 * rv2_se + 1e-5, "strip still reads the average variance when vol is not constant"
assert abs(vega - exp(-r * T) * Nvega) < 0.01, "vega notional is the dollar vega, discounted"
assert abs(delta) < 1e-3, "on a flat surface the fair strike ignores spot"
assert max(g_strip) - min(g_strip) < 1e-4, "the strip's dollar gamma is flat across spot"
assert abs(g_strip[2] - 2.0 * exp(-r * T) / T) < 1e-4, "and equals 2 e^-rT / T"
print("ALL CHECKS PASS")
