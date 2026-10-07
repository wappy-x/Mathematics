# The butterfly and the implied density -- the check behind the card.  Standard library only.
# The normal CDF is Marsaglia's series written out, the random numbers are xorshift64*,
# the density is read off prices by second differences.  Nothing imported knows the answer.
from math import log, sqrt, exp, cos, pi

def N(x):                                      # bell-curve area left of x, summed as a series
    if x < -10.0: return 0.0
    if x > 10.0: return 1.0
    s, t, b, q, i = x, 0.0, x, x * x, 1.0
    while s != t:
        i += 2.0; b *= q / i; t = s; s = t + b
    return 0.5 + s * exp(-0.5 * q - 0.91893853320467274178)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height at x

S, r, q, sig, T = 100.0, 0.05, 0.02, 0.20, 1.0
F = S * exp((r - q) * T)                       # the forward price
D = exp(-r * T)                                # discount factor D(T)

def call(K, v=sig, s0=S):                      # Black-Scholes call with dividend yield
    d1 = (log(s0 / K) + (r - q + 0.5 * v * v) * T) / (v * sqrt(T))
    return s0 * exp(-q * T) * N(d1) - K * D * N(d1 - v * sqrt(T))

def d2(K): return (log(S / K) + (r - q - 0.5 * sig * sig) * T) / (sig * sqrt(T))
def dens(K): return phi(d2(K)) / (K * sig * sqrt(T))    # lognormal density of S_T at K
def fly(K, h, c=call): return c(K - h) - 2.0 * c(K) + c(K + h)   # long K-h, short 2 K, long K+h

K = 100.0
ckk = D * dens(K)                              # road 1: closed-form second strike-derivative
gam = exp(-q * T) * phi(d2(K) + sig * sqrt(T)) / (S * sig * sqrt(T))   # road 3: spot gamma
gam_bump = (call(K, s0=S + 0.01) - 2.0 * call(K) + call(K, s0=S - 0.01)) / 1e-4
rows = [("house call C(100)", call(K)), ("call at K = 99", call(99.0)), ("call at K = 101", call(101.0)),
        ("discount e^-rT", D), ("K sig rt T", K * sig * sqrt(T)), ("d2 at K = 100", d2(K)), ("phi(d2)", phi(d2(K))),
        ("1 closed form e^-rT phi(d2)/(K sig rt T)", ckk), ("  density f(100) = e^rT x that", dens(K)),
        ("3 spot gamma formula at S = K", gam), ("  spot gamma by bumping S", gam_bump)]
errs = []
for h in (8.0, 4.0, 2.0, 1.0, 0.5):            # road 2: butterflies of shrinking width
    b = fly(K, h) / (h * h)
    errs.append(b - ckk)
    rows.append((f"2 butterfly/h^2, h = {h:g}", b))
rows.append(("  error ratio h = 2 over h = 1", errs[2] / errs[3]))
rows.append(("  error ratio h = 1 over h = 0.5", errs[3] / errs[4]))
dig = -(call(K + 0.01) - call(K - 0.01)) / 0.02
rows += [("minus dC/dK: cash digital", dig), ("  e^-rT N(d2)", D * N(d2(K)))]

st = 88172645463325252                         # road 4: simulate S_T, count the $1 bin at 100
def unif():
    global st
    st ^= st >> 12; st ^= (st << 25) & 0xFFFFFFFFFFFFFFFF; st ^= st >> 27
    return (((st * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) * 2.0 ** -53 + 2.0 ** -54
n, hits, drift, vol = 1_000_000, 0, log(S) + (r - q - 0.5 * sig * sig) * T, sig * sqrt(T)
for _ in range(n // 2):
    rad, ang = sqrt(-2.0 * log(unif())), 2.0 * pi * unif()
    for z in (rad * cos(ang), rad * cos(ang - 0.5 * pi)):
        if 99.5 <= exp(drift + vol * z) < 100.5: hits += 1
mc = D * hits / n
se = D * sqrt(hits / n * (1.0 - hits / n) / n)
rows += [("4 simulated share in [99.5, 100.5) x e^-rT", mc), ("  its standard error", se)]

bF, b10 = fly(K, 10.0), fly(K, 10.0) / 100.0
rows += [("butterfly 90/100/110 price", bF), ("  largest payoff, at 100", 10.0),
         ("wrong: no e^rT, density read as", ckk), ("wrong: h = 10 used as it stands", b10 / D),
         ("wrong: divided by h, not h^2", bF / 10.0 / D),
         ("wrong: spot gamma read at K = 120", exp(-q * T) * phi(d2(120.0) + sig * sqrt(T)) / (S * sig * sqrt(T))),
         ("  right: e^-rT f(120)", D * dens(120.0))]
bad = fly(K, 1.0, lambda k: call(k) + (0.03 if k == 100.0 else 0.0))
rows += [("wrong: C(100) marked 3 cents high", bad / D)]
def fb(s0=S, v=sig): return call(90.0, v, s0) - 2.0 * call(100.0, v, s0) + call(110.0, v, s0)
rows += [("fly delta, bump S by 1 cent", (fb(S + 0.01) - fb(S - 0.01)) / 0.02),
         ("fly gamma, bump S by 1 cent", (fb(S + 0.01) - 2.0 * fb() + fb(S - 0.01)) / 1e-4),
         ("fly vega, per vol point", (fb(v=sig + 1e-4) - fb(v=sig - 1e-4)) / 2e-4 / 100.0)]

H = 0.5                                        # whole density from a strike grid, flat and smiling
Ks = [H * i for i in range(1, 1201)]
def smile(k): x = log(k / F); return sig - 0.05 * x + 0.30 * x * x / (1.0 + 4.0 * x * x)
def grid(vol):
    C = [call(k, vol(k)) for k in Ks]
    return [(Ks[i], (C[i - 1] - 2.0 * C[i] + C[i + 1]) / (H * H) / D) for i in range(1, len(Ks) - 1)]
gf, gs = grid(lambda k: sig), grid(smile)
for name, g in (("flat", gf), ("smile", gs)):
    rows += [(f"{name}: total probability", sum(f for _, f in g) * H),
             (f"{name}: mean, compare forward", sum(k * f for k, f in g) * H),
             (f"{name}: grid strikes with density < 0", sum(1 for _, f in g if f < -1e-9)),
             (f"{name}: P(S_T < 70)", sum(f for k, f in g if k < 70.0) * H),
             (f"{name}: P(S_T > 150)", sum(f for k, f in g if k > 150.0) * H)]
rows += [("forward F = S e^(r-q)T", F)] + [(f"smile vol at K = {k:g}", smile(k)) for k in (60.0, 100.0, 160.0)]
worst = max(abs(f - dens(k)) for k, f in gf)
rows.append(("flat grid vs lognormal, worst gap", worst))
for name, v in rows:
    print(f"{name:<44} {v:>12.6f}")
xs = [50.0 + 10.0 * i for i in range(12)]
print("chart, strike           " + "".join(f"{x:>6.0f}" for x in xs))
for name, g in (("chart, flat % per $    ", dict(gf)), ("chart, smile % per $   ", dict(gs))):
    print(name + "".join(f"{100.0 * g[x]:>6.2f}" for x in xs))
pay = [max(0.0, 10.0 - abs(x - 100.0)) for x in range(80, 125, 5)]
print("chart, butterfly payoff " + "".join(f"{p:>6.2f}" for p in pay))
print("chart, payoff less price" + "".join(f"{p - bF:>6.2f}" for p in pay))

assert abs(fly(K, 1.0) - ckk) < 1e-5, "a $1 butterfly lands on the closed-form curvature"
assert 3.9 < errs[3] / errs[4] < 4.1, "halving h cuts the error by four"
assert abs(gam - ckk) < 1e-12, "spot gamma formula equals strike curvature at S = K"
assert abs(gam_bump - ckk) < 1e-6, "bumped spot gamma lands on it too"
assert abs(mc - ckk) < 4.0 * se, "simulated bin count agrees with the formula"
assert abs(dig - 0.494581) < 1e-6, "first difference is the shelf's cash digital"
assert worst < 1e-5, "density read off flat prices matches the lognormal formula at every strike"
assert min(f for _, f in gs) > -1e-9, "the smile's density stays non-negative: no butterfly arbitrage"
tail = lambda g, lo, hi: sum(f for k, f in g if k < lo or k > hi) * H
assert tail(gs, 70.0, 150.0) > 1.3 * tail(gf, 70.0, 150.0), "the smile fattens the tails"
assert bad < 0.0, "three cents on one quote turns the density negative"
for g in (gf, gs):
    assert abs(sum(f for _, f in g) * H - 1.0) < 1e-9, "total probability is 1"
    assert abs(sum(k * f for k, f in g) * H - F) < 1e-6, "the mean is the forward"
print("ALL CHECKS PASS")
