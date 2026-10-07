# Volatility swap and jump bias -- the check behind the card.  Standard library only.
# Part 1, Heston anchor: the fair vol strike E[sqrt(vbar)] by three roads -- the convexity
# formula, the exact Laplace-transform integral, a Monte Carlo of variance paths.
# Part 2, Merton jumps: the option-strip variance strike against the true expected realised
# variance -- closed forms, a numerical strip of option prices, a Monte Carlo of daily returns.
from math import exp, log, sqrt, pi, cos, sin, expm1

def N(x):                                    # normal CDF: 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, s, n = x, x, 1
    while abs(term) > 1e-17 * abs(s):
        term *= x * x / (2 * n + 1); s += term; n += 1
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3.0 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
class Rng:                                   # 64-bit LCG; uniforms from the top 53 bits; Box-Muller pairs
    def __init__(s, seed): s.x, s.spare = seed, None
    def u(s):
        s.x = (6364136223846793005 * s.x + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return ((s.x >> 11) + 0.5) / 9007199254740992.0
    def z(s):
        if s.spare is not None: z, s.spare = s.spare, None; return z
        rad = sqrt(-2.0 * log(s.u())); ang = 2.0 * pi * s.u()
        s.spare = rad * sin(ang); return rad * cos(ang)

def mean_se(tot, tot2, n): return tot / n, sqrt((tot2 / n - (tot / n) ** 2) / n)

# ---------------- Part 1: the vol swap under the Heston anchor ----------------
T, V0, TH, KA, XI = 1.0, 0.04, 0.04, 2.0, 0.3
def var_vbar(th, ka, xi):                    # variance of the average variance, when v0 = theta
    e1, e2 = exp(-ka * T), exp(-2 * ka * T)
    return th * xi**2 / ka**2 * (T - (1 - e2) / (2 * ka) - (1 - e1) / ka + e1 * (1 - e1) / ka) / T**2
def convexity(m, var): return sqrt(m) - var / (8.0 * m ** 1.5)
def log_laplace(s, v0, th, ka, xi):          # ln E[exp(-s vbar)]: the CIR bond-price formula
    c = s / T; g = sqrt(ka * ka + 2 * xi * xi * c); em = exp(-g * T)
    den = (g + ka) * (1 - em) + 2 * g * em
    lnA = 2 * ka * th / xi**2 * (log(2 * g) + 0.5 * (ka - g) * T - log(den))
    return lnA - 2 * c * (1 - em) / den * v0
def vol_strike(v0, th, ka, xi):              # E sqrt(X) = (1/sqrt pi) * integral of (1 - L(e^2y)) e^-y dy
    f = lambda y: -expm1(log_laplace(exp(2 * y), v0, th, ka, xi)) * exp(-y)
    return simpson(f, -20.0, 25.0, 6000) / sqrt(pi)
def heston_mc(paths, steps, seed):           # full-truncation Euler; vbar = time-average of v
    g, dt, a = Rng(seed), T / steps, [0.0] * 4
    for _ in range(paths):
        v, acc = V0, 0.0
        for _ in range(steps):
            vp = max(v, 0.0); acc += vp * dt
            v += KA * (TH - vp) * dt + XI * sqrt(vp * dt) * g.z()
        x = acc / T; a[0] += sqrt(x); a[1] += x; a[2] += x * x
    return (*mean_se(a[0], a[1], paths), a[1] / paths, a[2] / paths - (a[1] / paths) ** 2)

kvar, var_x = V0, var_vbar(TH, KA, XI)
k_conv, k_exact = convexity(kvar, var_x), vol_strike(V0, TH, KA, XI)
mc_vol, mc_se, mc_mean, mc_var = heston_mc(50000, 100, 20260927)
two_pt = 0.5 * (sqrt(0.02) + sqrt(0.06))
print("PART 1  vol swap, Heston v0 = theta = 0.04, kappa 2, xi 0.3, one year")
for lab, v in (("two-point: root of 0.02", sqrt(0.02)), ("two-point: root of 0.06", sqrt(0.06)), ("two-point: mean of roots", two_pt),
               ("variance strike E[vbar]", kvar), ("  as a vol, %", 100 * sqrt(kvar)),
               ("Var(vbar), formula", var_x), ("sd(vbar), formula", sqrt(var_x)),
               ("1 convexity formula, %", 100 * k_conv), ("2 Laplace integral, %", 100 * k_exact),
               ("3 Monte Carlo, %", 100 * mc_vol), ("  standard error, %", 100 * mc_se),
               ("  MC mean of vbar", mc_mean), ("  MC Var(vbar)", mc_var),
               ("gap sqrt(Kvar) - Kvol, vol pts", 100 * (sqrt(kvar) - k_exact)),
               ("wrong: no pull, xi^2 th T / 3, %", 100 * convexity(kvar, XI**2 * TH * T / 3))):
    print(f"{lab:<34} {v:>12.6f}")
print("chart, xi     " + "".join(f"{x:>7.2f}" for x in (0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)))
gx = [(100 * (0.2 - vol_strike(V0, TH, KA, x)), 100 * (0.2 - convexity(kvar, var_vbar(TH, KA, x))))
      for x in (0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7)]
print("chart, exact  " + "".join(f"{e:>7.2f}" for e, _ in gx))
print("chart, approx " + "".join(f"{c:>7.2f}" for _, c in gx))
for lab, args in (("level: v0 = theta = 0.0484, %", (0.0484, 0.0484, KA, XI)), ("pull: kappa = 1, %", (V0, TH, 1.0, XI)),
                  ("pull: kappa = 4, %", (V0, TH, 4.0, XI)), ("start: v0 = 0.09, %", (0.09, TH, KA, XI))):
    print(f"{lab:<34} {100 * vol_strike(*args):>12.6f}")
print("payoff, realised vol %  " + "".join(f"{s:>7.1f}" for s in (10, 15, 20, 25, 30)))
print("payoff, vol swap        " + "".join(f"{s - 20:>7.2f}" for s in (10, 15, 20, 25, 30)))
print("payoff, var swap        " + "".join(f"{(s * s - 400) / 40:>7.2f}" for s in (10, 15, 20, 25, 30)))

# ---------------- Part 2: the strip under Merton jumps ----------------
S, r, q, SIG, LAM, MU, DEL = 100.0, 0.05, 0.02, 0.20, 0.5, -0.10, 0.15
F = S * exp((r - q) * T)
def bs(K, sig, qq, call):                    # Black-Scholes on Acme with volatility sig, yield qq
    d1 = (log(S / K) + (r - qq + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    if call: return S * exp(-qq * T) * N(d1) - K * exp(-r * T) * N(d2)
    return K * exp(-r * T) * N(-d2) - S * exp(-qq * T) * N(-d1)
def merton(K, call):                         # Poisson-weighted Black-Scholes branches
    k, w, tot = exp(MU + 0.5 * DEL * DEL) - 1, exp(-LAM * T), 0.0
    for n in range(25):
        tot += w * bs(K, sqrt(SIG * SIG + n * DEL * DEL / T), q + LAM * k - n * log(1 + k) / T, call)
        w *= LAM * T / (n + 1)
    return tot
def strip(price):                            # (2/T) e^rT [int_0^F P/K^2 dK + int_F^inf C/K^2 dK], K = e^x
    lf = log(F)
    puts = simpson(lambda x: price(exp(x), False) * exp(-x), lf - 4.0, lf, 800)
    calls = simpson(lambda x: price(exp(x), True) * exp(-x), lf, lf + 4.0, 800)
    return 2.0 / T * exp(r * T) * (puts + calls)
def closed(mu, de):                          # (strip strike, true expected realised variance)
    return SIG**2 + 2 * LAM * (exp(mu + 0.5 * de * de) - 1 - mu), SIG**2 + LAM * (mu * mu + de * de)
def merton_mc(paths, days, seed):            # daily log returns; realised variance and log-contract payoff
    g, dt, a, k = Rng(seed), T / days, [0.0] * 6, exp(MU + 0.5 * DEL * DEL) - 1
    drift, p0 = (-LAM * k - 0.5 * SIG * SIG) * dt, exp(-LAM * dt)
    for _ in range(paths):
        lx, rv, gap = 0.0, 0.0, 0.0
        for _ in range(days):
            u = drift + SIG * sqrt(dt) * g.z()
            un, n, p, cum = g.u(), 0, p0, p0
            while un > cum: n += 1; p *= LAM * dt / n; cum += p
            for _ in range(n): u += MU + DEL * g.z()
            lx += u; rv += (u + (r - q) * dt) ** 2; gap += 2 * expm1(u) - 2 * u - u * u
        pay = 2 * (expm1(lx) - lx)
        for i, val in enumerate((rv, rv * rv, pay, pay * pay, gap, gap * gap)): a[i] += val
    return [mean_se(a[i], a[i + 1], paths) for i in (0, 2, 4)]

ks_bs, ks_m = strip(lambda K, c: bs(K, SIG, q, c)), strip(merton)
kc_strip, kc_true = closed(MU, DEL)
m3, m4 = LAM * (MU**3 + 3 * MU * DEL**2) / 3, LAM * (MU**4 + 6 * MU**2 * DEL**2 + 3 * DEL**4) / 12
(rv, rv_se), (lp, lp_se), (hg, hg_se) = merton_mc(40000, 252, 7)
print("PART 2  jump bias, Merton lambda 0.5, mu_J -0.10, delta 0.15, sigma 0.20")
for lab, v in (("strip, no jumps (house)", ks_bs), ("1 strip strike, closed form", kc_strip),
               ("2 strip strike, numerical strip", ks_m), ("3 MC log-contract payoff", lp),
               ("  standard error", lp_se), ("true E[realised var], closed", kc_true),
               ("  MC daily realised variance", rv), ("  standard error", rv_se),
               ("jump bias strip - true", kc_strip - kc_true), ("  MC hedged gap", hg), ("  standard error", hg_se),
               ("  third-moment term", m3), ("  plus fourth-moment term", m3 + m4),
               ("strip strike as a vol, %", 100 * sqrt(kc_strip)), ("true as a vol, %", 100 * sqrt(kc_true))):
    print(f"{lab:<34} {v:>12.6f}")
mus = (-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3)
print("chart, mu_J   " + "".join(f"{m:>7.2f}" for m in mus))
print("chart, exact  " + "".join(f"{100 * (sqrt(closed(m, DEL)[0]) - sqrt(closed(m, DEL)[1])):>7.2f}" for m in mus))
print("chart, 3rd    " + "".join(f"{100 * (sqrt(closed(m, DEL)[1] + LAM * (m**3 + 3 * m * DEL**2) / 3) - sqrt(closed(m, DEL)[1])):>7.2f}" for m in mus))

assert abs(k_exact - mc_vol) < 4 * mc_se,            "exact Laplace road vs Monte Carlo"
assert abs(k_exact - k_conv) < 0.001,                "convexity formula within 0.1 vol point at xi = 0.3"
assert abs(mc_var - var_x) < 0.05 * var_x,           "simulated Var(vbar) vs the closed formula"
assert k_exact < sqrt(mc_mean),                      "Jensen: vol strike below root of the variance strike"
assert abs(ks_bs - SIG**2) < 1e-6,                   "no-jump strip returns sigma^2"
assert abs(ks_m - kc_strip) < 1e-6,                  "numerical strip vs closed-form strip strike"
assert abs(hg - (kc_strip - kc_true)) < 4 * hg_se + 2e-4, "hedged Monte Carlo gap vs closed-form jump bias"
assert abs(rv - kc_true) < 4 * rv_se + 2e-4 and abs(lp - kc_strip) < 4 * lp_se, "MC realised variance and log contract"
print("ALL CHECKS PASS")
