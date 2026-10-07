# Realised variance from daily prices -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: random numbers are splitmix64 + Box-Muller written out,
# the share's path is built minute by minute, every estimator is a loop.
from math import log, sqrt, cos, sin, pi, exp
M64 = (1 << 64) - 1

class Rng:                                   # splitmix64 uniforms, Box-Muller bell-curve draws
    def __init__(s, seed): s.x, s.spare = seed, None
    def u(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    def z(s):
        if s.spare is not None:
            v, s.spare = s.spare, None
            return v
        r, t = sqrt(-2.0 * log(s.u())), 2.0 * pi * s.u()
        s.spare = r * sin(t)
        return r * cos(t)

SIG, MU, H, DAYS, M = 0.20, 0.03, 0.001, 21, 390   # true vol, drift, half-spread, days, minutes a day
T = DAYS / 252.0

def month(g):
    # One month of Acme, minute by minute.  Returns log prices every 5 minutes, and each
    # day's open, high, low, close (logs, high and low read from the minute prices).
    dt = 1.0 / (252 * M)
    a, b = (MU - 0.5 * SIG * SIG) * dt, SIG * sqrt(dt)
    x = log(100.0); prints, ohlc = [x], []
    for d in range(DAYS):
        o = hi = lo = x
        for j in range(M):
            x += a + b * g.z(); hi = max(hi, x); lo = min(lo, x)
            if (j + 1) % 5 == 0: prints.append(x)
        ohlc.append((o, hi, lo, x))
    return prints, ohlc

def rv(p, k):                                # annualised: squared log returns every k prints, x 252/N
    return 252.0 / DAYS * sum((p[i] - p[i - k]) ** 2 for i in range(k, len(p), k))
L4, GKW = 4.0 * log(2.0), 2.0 * log(2.0) - 1.0
def parkinson(ohlc): return 252.0 / DAYS * sum((h - l) ** 2 / L4 for o, h, l, c in ohlc)
def garman_klass(ohlc): return 252.0 / DAYS * sum(0.5 * (h - l) ** 2 - GKW * (c - o) ** 2 for o, h, l, c in ohlc)
def noise_formula(n, h): return SIG * SIG + 2.0 * n * h * h / T   # sigma^2 + 2 n h^2, per year

g = Rng(135)
clean, ohlc = month(g)
traded = [x + (H if g.u() < 0.5 else -H) for x in clean]      # each print at the bid or the ask
closes = traded[::78]
rets = [closes[i] - closes[i - 1] for i in range(1, DAYS + 1)]
ssq = sum(r * r for r in rets)
var_cc = 252.0 / DAYS * ssq
print("chart, closes " + " ".join(f"{exp(c):.2f}" for c in closes))
for i in range(3):
    print(f"day {i + 1}  close {exp(closes[i + 1]):8.4f}  log return {rets[i]:+.6f}  squared {rets[i] ** 2:.8f}")
print(f"sum of 21 squared log returns    {ssq:.6f}")
print(f"x 252/21 = realised variance      {var_cc:.6f}")
print(f"realised vol, closes              {100 * sqrt(var_cc):.2f}%")
mean = sum(rets) / DAYS
print(f"textbook: mean removed, N-1       {100 * sqrt(252.0 / (DAYS - 1) * sum((r - mean) ** 2 for r in rets)):.2f}%")
print(f"wrong: x 365 not 252              {100 * sqrt(365.0 / DAYS * ssq):.2f}%")
print(f"wrong: simple returns             {100 * sqrt(252.0 / DAYS * sum((exp(r) - 1) ** 2 for r in rets)):.2f}%")
print(f"wrong: variance read as vol       {100 * var_cc:.2f}%")
print(f"true quadratic variation 21 days  {SIG * SIG * T:.6f}")
print(f"5-min, true prices                {100 * sqrt(rv(clean, 1)):.2f}%   n = {len(clean) - 1}")
print(f"5-min, as traded                  {100 * sqrt(rv(traded, 1)):.2f}%   formula {100 * sqrt(noise_formula(1638, H)):.2f}%")
print(f"bounce adds 2 n h^2 / T           {2.0 * 1638 * H * H / T:.6f}   total {noise_formula(1638, H):.6f}")
print(f"constants  4 ln 2 = {L4:.4f}   2 ln 2 - 1 = {GKW:.4f}")
print(f"one month: Parkinson              {100 * sqrt(parkinson(ohlc)):.2f}%")
print(f"one month: Garman-Klass           {100 * sqrt(garman_klass(ohlc)):.2f}%")
# ---- many months: how much each estimator wobbles around the truth ----
P, KS = 400, (1, 2, 3, 6, 13, 26, 39, 78)
est = {"close-to-close": [], "Parkinson": [], "Garman-Klass": []}
sig_t, sig_c = [0.0] * len(KS), [0.0] * len(KS)          # signature plot: averages over the months
for _ in range(P):
    cl, oh = month(g)
    tr = [x + (H if g.u() < 0.5 else -H) for x in cl]
    for j, k in enumerate(KS):
        sig_t[j] += rv(tr, k) / P; sig_c[j] += rv(cl, k) / P
    est["close-to-close"].append(252.0 / DAYS * sum((c - o) ** 2 for o, h, l, c in oh))
    est["Parkinson"].append(parkinson(oh)); est["Garman-Klass"].append(garman_klass(oh))
stats = {}
for name, xs in est.items():
    m = sum(xs) / P
    sd = sqrt(sum((x - m) ** 2 for x in xs) / (P - 1))
    stats[name] = (m, sd)
cv_c = stats["close-to-close"][1] / stats["close-to-close"][0]   # spread/mean of close-to-close
print(f"{P} months       average    spread/mean   efficiency")
for name, (m, sd) in stats.items():
    print(f"{name:<15} {100 * sqrt(m):7.2f}%   {sd / m:11.4f}   {(cv_c * m / sd) ** 2:10.2f}")
print("signature, 400-month average  minutes  as traded  formula  true prices")
for j, k in enumerate(KS):
    print(f"signature  {5 * k:7d}  {100 * sqrt(sig_t[j]):9.2f}  {100 * sqrt(noise_formula(1638 // k, H)):7.2f}  {100 * sqrt(sig_c[j]):11.2f}")
print(f"theory, close-to-close spread/mean sqrt(2/21) = {sqrt(2.0 / DAYS):.4f}")
print(f"try: half-spread 5 cents, 5-min   {100 * sqrt(noise_formula(1638, 0.0005)):.2f}%")
print(f"try: 1-minute prints, 10 cents    {100 * sqrt(noise_formula(8190, H)):.2f}%")
print(f"try: 252 days, spread/mean        {sqrt(2.0 / 252):.4f}")

mc, sdc = stats["close-to-close"]
assert abs(mc - SIG * SIG) < 3 * sdc / sqrt(P) + 1e-4,         "close-to-close is unbiased for sigma^2"
assert abs(sdc / mc - sqrt(2.0 / DAYS)) < 0.15 * sqrt(2.0 / DAYS), "its wobble matches sqrt(2/N)"
assert abs(sqrt(sig_t[0]) - sqrt(noise_formula(1638, H))) < 0.003, "noise bias: simulation vs formula"
assert abs(sqrt(rv(clean, 1)) - SIG) < 0.01,                     "5-min true prices recover 20%"
for name in ("Parkinson", "Garman-Klass"):
    m, sd = stats[name]
    assert (cv_c * m / sd) ** 2 > 3,                                 "ranges beat closes"
    assert 0.85 * SIG * SIG < m < SIG * SIG,                         "minute ranges read a little low"
print("ALL CHECKS PASS")
