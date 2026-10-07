# Market-risk capital: 99% VaR against 97.5% expected shortfall, and the Basel
# liquidity-horizon rule.  Standard library only: the normal CDF, the t density,
# the quantiles, the tail integrals and the random numbers are all written here.
from math import sqrt, exp, log, cos, pi, atan

A_OLD, A_NEW, SD, N_MC = 0.99, 0.975, 3.0, 200_000   # confidences; 10-day loss sd in $m
def gamma_half(k):                     # Gamma(k/2) for a whole number k, by recurrence
    return sqrt(pi) if k == 1 else 1.0 if k == 2 else (k / 2 - 1) * gamma_half(k - 2)
def dens(x, nu):                       # nu = 0 is the bell curve; otherwise Student t
    if nu == 0:
        return exp(-x * x / 2) / sqrt(2 * pi)
    c = gamma_half(nu + 1) / (sqrt(nu * pi) * gamma_half(nu))
    return c * (1 + x * x / nu) ** (-(nu + 1) / 2)
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3
def cdf(x, nu):
    if nu == 0:                        # Marsaglia: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
        if x > 9:
            return 1.0
        s = t = x
        for k in range(1, 200):
            t *= x * x / (2 * k + 1)
            s += t
        return 0.5 + dens(x, 0) * s
    return 0.5 + simpson(lambda u: dens(u, nu), 0.0, x)
def quantile(p, nu):                   # bisection: the loss line with chance p below it
    lo, hi = 0.0, 50.0
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if cdf(mid, nu) < p else (lo, mid)
    return (lo + hi) / 2
def unit(nu):                          # rescales a standard t to standard deviation 1
    return 1.0 if nu == 0 else sqrt((nu - 2) / nu)
def var_es(nu, a):                     # road 1: closed forms, per $1 of standard deviation
    q = quantile(a, nu)
    tail = dens(q, 0) if nu == 0 else dens(q, nu) * (nu + q * q) / (nu - 1)
    return q * unit(nu), tail / (1 - a) * unit(nu)
def es_integral(nu, a):                # road 2: average loss beyond the line, x = q/u
    q = quantile(a, nu)
    g = lambda u: 0.0 if u == 0 else dens(q / u, nu) / u ** 3
    return q * q * simpson(g, 0.0, 1.0) / (1 - a) * unit(nu)
state = 20260928                       # road 3: Monte Carlo from a 64-bit LCG
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
def normal():                          # Box-Muller
    u1, u2 = unif(), unif()
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2)
def mc_var_es(losses):                 # the 99% line, and the mean of the worst 2.5%
    s, n, tail = sorted(losses), len(losses), 0.0
    for x in s[n - n * 25 // 1000:]: tail += x
    return s[n * 99 // 100 - 1], tail / (n * 25 // 1000)
def row(label, *vals):
    print(f"{label:<40}" + "".join(f"{v:>11.3f}" for v in vals))

z99, k99 = var_es(0, A_OLD)
k975 = var_es(0, A_NEW)[1]
lo, hi = 0.95, 0.99                    # the confidence where normal ES meets 99% VaR
for _ in range(50):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if var_es(0, mid)[1] < z99 else (lo, mid)
print("standard normal, per $1 of standard deviation")
print(f"  VaR99 = z(0.99)                         {z99:.6f}")
print(f"  ES97.5 = phi(z(0.975)) / 0.025          {k975:.6f}")
print(f"  z(0.975), phi(z(0.975))                 {quantile(A_NEW, 0):.6f}  {dens(quantile(A_NEW, 0), 0):.6f}")
print(f"  ES99                                    {k99:.6f}")
print(f"  ES97.5 / VaR99                          {k975 / z99:.6f}")
print(f"  confidence where ES equals VaR99        {lo:.6f}")
norm_mc, t3_mc = [SD * normal() for _ in range(N_MC)], []
for _ in range(N_MC):
    z = normal()
    chi = normal() ** 2 + normal() ** 2 + normal() ** 2
    t3_mc.append(SD * unit(3) * z / sqrt(chi / 3))
nv, ne = z99 * SD, k975 * SD
tv, te = var_es(3, A_OLD)[0] * SD, var_es(3, A_NEW)[1] * SD
q3 = quantile(A_OLD, 3)                # t3 has a closed-form CDF: check the quantile
f3 = 0.5 + ((q3 / sqrt(3)) / (1 + q3 * q3 / 3) + atan(q3 / sqrt(3))) / pi
beyond = SD * unit(3) * dens(q3, 3) * (3 + q3 * q3) / 2 / (1 - A_NEW)
line = mc_var_es(t3_mc)[0]
stretched = [2 * x if x > line else x for x in t3_mc]
print(f"\nbooks, $100m trading book, 10-day loss sd $3m    VaR99     ES97.5")
row("normal book, formula", nv, ne)
row("normal book, tail integral", nv, es_integral(0, A_NEW) * SD)
row("normal book, Monte Carlo 200,000", *mc_var_es(norm_mc))
row("fat-tailed t3 book, formula", tv, te)
row("fat-tailed t3 book, tail integral", tv, es_integral(3, A_NEW) * SD)
row("fat-tailed t3 book, Monte Carlo 200,000", *mc_var_es(t3_mc))
row("t3, losses past VaR99 doubled, formula", tv, te + beyond)
row("t3, losses past VaR99 doubled, MC", *mc_var_es(stretched))
print(f"  t3 CDF at its VaR99 line, closed form   {f3:.9f}")
print(f"  t3 standard lines z(0.99), z(0.975)     {q3:.6f}  {quantile(A_NEW, 3):.6f}")
print("\nchart, percent by which ES97.5 exceeds VaR99, by tail weight")
ratios = {}
for nu in (3, 4, 5, 6, 8, 10, 20, 30, 0):
    ratios[nu] = var_es(nu, A_NEW)[1] / var_es(nu, A_OLD)[0]
    print(f"  chart, {'normal' if nu == 0 else 't' + str(nu):<8}{100 * (ratios[nu] - 1):>10.2f}")

# Liquidity horizons: three independent factors, 10-day sd in $m, horizon in days
factors = [("large-cap equity", 2.0, 10), ("IG corporate credit", 2.0, 40), ("HY corporate credit", 1.0, 60)]
LH, T = [10, 20, 40, 60, 120], 10
def es_subset(j):                      # ES_T(P, j): only factors with horizon >= LH_j move
    return k975 * sqrt(sum(s * s for _, s, h in factors if h >= LH[j]))
parts = [es_subset(0) ** 2] + [es_subset(j) ** 2 * (LH[j] - LH[j - 1]) / T for j in range(1, 5)]
cascade = sqrt(sum(parts))
per_factor = k975 * sqrt(sum(s * s * h / T for _, s, h in factors))
lh_mc = []
for _ in range(N_MC):
    x = 0.0
    for _, s, h in factors:
        x += s * sqrt(h / T) * normal()
    lh_mc.append(x)
print("\nliquidity horizons, normal book, $m")
for j in range(5):
    print(f"  squared piece j={j + 1}, LH {LH[j]:>3}, ES_T(P,j) {es_subset(j):6.3f}   {parts[j]:8.3f}")
row("liquidity-adjusted ES, Basel cascade", cascade)
row("liquidity-adjusted ES, factor by factor", per_factor)
row("liquidity-adjusted ES, Monte Carlo", mc_var_es(lh_mc)[1])
row("  squared total over ES97.5 per $1 squared", (cascade / k975) ** 2)
row("wrong: normal formula on the t3 book", ne)
row("wrong: ES at 99% on the normal book", k99 * SD)
row("wrong: no liquidity horizons", es_subset(0))
row("wrong: whole book at 120 days", es_subset(0) * sqrt(12))
row("wrong: pieces added, not squared", sum(sqrt(p) for p in parts))
factors[2] = ("HY corporate credit", 1.0, 120)
row("try: HY credit at 120 days", k975 * sqrt(sum(s * s * h / T for _, s, h in factors)))

assert abs(es_integral(0, A_NEW) * SD - ne) < 1e-6 and abs(es_integral(3, A_NEW) * SD - te) < 1e-6
assert abs(f3 - A_OLD) < 1e-9,                            "t3 quantile against the closed-form CDF"
assert abs(mc_var_es(norm_mc)[1] / ne - 1) < 0.02 and abs(mc_var_es(t3_mc)[1] / te - 1) < 0.05
assert abs(cascade - per_factor) < 1e-9,                  "Basel cascade against factor-by-factor horizons"
assert abs(mc_var_es(lh_mc)[1] / cascade - 1) < 0.02,     "simulated horizons against the formula"
assert abs(2 * simpson(lambda u: 0.0 if u == 1 else (u / (1 - u)) ** 2 * dens(u / (1 - u), 3) / (1 - u) ** 2, 0.0, 1.0)
           * unit(3) ** 2 - 1) < 1e-3,                     "t3 book: variance integral gives sd 1 per $1"
assert ratios[0] < 1.01 and ratios[3] > 1.1,              "normal ratio near 1, t3 ratio well above"
print("ALL CHECKS PASS")
