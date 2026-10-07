# One-factor Gaussian copula -- the check behind the card.  Standard library only.
# House pool: 100 loans, 5% default chance over five years, recovery 40%, asset correlation 20%.
# Nothing imported knows the answer: the normal CDF is a series written here, the inverse
# is bisection, integrals are Simpson's rule, random numbers come from a hand-written LCG.
from math import sqrt, exp, log, cos, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height

def N(x):                                                       # bell-curve area left of x
    if x < 0.0: return 1.0 - N(-x)
    if x > 9.0: return 1.0
    term, total, k = x, x, 1                                    # x + x^3/3 + x^5/(3*5) + ...
    while term > 1e-17 * total:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def N_inv(p, lo=-10.0, hi=10.0):                                # bisection: N is increasing
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

def simpson(f, a, b, n=4000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

P, RHO, REC, NAMES = 0.05, 0.20, 0.40, 100
a = N_inv(P)                                                    # the default threshold

def q(m, rho=RHO, thr=None):                                    # default chance, economy at m
    thr = a if thr is None else thr
    return N((thr - sqrt(rho) * m) / sqrt(1.0 - rho))

def pair_factor(rho, p1=P, p2=P):                               # road 1: average q1*q2 over M
    t1, t2 = N_inv(p1), N_inv(p2)
    return simpson(lambda m: phi(m) * q(m, rho, t1) * q(m, rho, t2), -9.0, 9.0)

def pair_plackett(rho):                                         # road 2: p^2 + integral of the
    f = lambda r: exp(-a * a / (1.0 + r)) / (2.0 * pi * sqrt(1.0 - r * r))   # corner density
    return P * P + simpson(f, 0.0, rho, 200)

def count_law(rho):                                             # P(S = k), S = defaults in 100
    law = [0.0] * (NAMES + 1)
    h, lo, n = 18.0 / 1000, -9.0, 1000
    for i in range(n + 1):
        m = lo + i * h; w = (1 if i in (0, n) else 4 if i % 2 else 2) * phi(m) * h / 3.0
        qm = q(m, rho)
        pk = (1.0 - qm) ** NAMES
        for k in range(NAMES + 1):
            law[k] += w * pk
            if k < NAMES and qm < 1.0: pk *= (NAMES - k) / (k + 1) * qm / (1.0 - qm)
    return law

J = pair_factor(RHO); J2 = pair_plackett(RHO)
dcorr = (J - P * P) / (P * (1.0 - P))
marg = {r: simpson(lambda m: phi(m) * q(m, r), -9.0, 9.0) for r in (0.2, 0.5)}
law_c, law_i = count_law(RHO), count_law(0.0)

state = 0x2545F4914F6CDD1D                                      # road 3: simulate 20,000 pools
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
POOLS, sr, sn = 20000, sqrt(RHO), sqrt(1.0 - RHO)
d_tot = pair_tot = pair_sq = tail = bad_names = bad_def = 0
for _ in range(POOLS):
    M = gauss()
    d = sum(1 for _ in range(NAMES) if sr * M + sn * gauss() < a)
    x = d * (d - 1) / (NAMES * (NAMES - 1))
    d_tot += d; pair_tot += x; pair_sq += x * x; tail += d >= 10
    if -2.25 < M < -1.75: bad_names += NAMES; bad_def += d
mc_p = d_tot / (POOLS * NAMES); mc_J = pair_tot / POOLS
mc_se = sqrt((pair_sq / POOLS - mc_J * mc_J) / POOLS)          # error bar across pools

print(f"{'threshold a = N^-1(0.05)':<40}{a:>12.6f}")
print(f"{'sqrt(rho), sqrt(1-rho)':<28}{sr:>12.6f}{sn:>12.6f}")
print(f"{'argument at m = -2, m = -3':<28}{(a + 2 * sr) / sn:>12.6f}{(a + 3 * sr) / sn:>12.6f}")
print(f"{'pool loss: expected, 10 names':<28}{P * (1 - REC):>12.6f}{10 * (1 - REC) / NAMES:>12.6f}")
for m in (-3.0, -2.0, -1.0, 0.0, 1.0, 2.0):
    print(f"economy m = {m:+.0f}: name default {q(m):.6f}  expected defaults {NAMES * q(m):6.2f}  pool loss {100 * q(m) * (1 - REC):5.2f}%")
for r in (0.2, 0.5):
    print(f"{'average of q(M) over M, rho = ' + str(r):<40}{marg[r]:>12.6f}")
print(f"{'1 pair default, factor integral':<40}{J:>12.6f}")
print(f"{'2 pair default, correlation route':<40}{J2:>12.6f}")
print(f"{'  if independent, p^2':<40}{P * P:>12.6f}")
print(f"{'  excess J - p^2 = variance of q(M)':<40}{J - P * P:>12.6f}")
print(f"{'default correlation':<40}{dcorr:>12.6f}")
print(f"{'3 simulated: default fraction':<40}{mc_p:>12.6f}")
print(f"{'3 simulated: pair default':<40}{mc_J:>12.6f}")
print(f"{'  its standard error':<40}{mc_se:>12.6f}")
print(f"{'3 simulated: rate when M near -2':<40}{bad_def / bad_names:>12.6f}")
print(f"{'mean defaults per pool, mixture law':<40}{sum(k * v for k, v in enumerate(law_c)):>12.6f}")
print(f"{'P(10 or more defaults), mixture law':<40}{sum(law_c[10:]):>12.6f}")
print(f"{'P(10 or more defaults), independent':<40}{sum(law_i[10:]):>12.6f}")
print(f"{'P(10 or more defaults), simulated':<40}{tail / POOLS:>12.6f}")
for lab, lo, hi in (("0", 0, 1), ("1-4", 1, 5), ("5-9", 5, 10), ("10-19", 10, 20), ("20+", 20, 101)):
    print(f"defaults {lab:<6} independent {100 * sum(law_i[lo:hi]):6.2f}%   one-factor {100 * sum(law_c[lo:hi]):6.2f}%")
# what breaks
wrong_rho = P * P + RHO * P * (1 - P)                           # asset rho used as default rho
no_shrink = N(a / sqrt(1.0 + RHO))                              # sqrt(rho) M + Z, variance 1.2
rho_load = N(a / sqrt(RHO * RHO + 1.0 - RHO))                   # rho M + sqrt(1-rho) Z
no_divide = N(a - sqrt(RHO) * -2.0)                             # q(-2) without / sqrt(1-rho)
print(f"{'wrong: asset rho as default rho':<40}{wrong_rho:>12.6f}")
print(f"{'wrong: no sqrt(1-rho), marginal':<40}{no_shrink:>12.6f}")
print(f"{'wrong: loading rho not sqrt, marginal':<40}{rho_load:>12.6f}")
print(f"{'wrong: q(-2) without dividing':<40}{no_divide:>12.6f}")
print(f"{'try: pair default, rho = 0.5':<40}{pair_factor(0.5):>12.6f}")
print(f"{'try: pair default, p = 5% and 1%':<40}{pair_factor(RHO, P, 0.01):>12.6f}")
print(f"{'try: q(-3), rho = 0.5':<40}{q(-3.0, 0.5):>12.6f}")
chart_m = [-3.0 + 0.5 * i for i in range(13)]
print("chart, economy m      " + " ".join(f"{m:5.1f}" for m in chart_m))
print("chart, q(m) in %      " + " ".join(f"{100 * q(m):5.2f}" for m in chart_m))
rhos = [0.1 * i for i in range(10)]
print("chart, rho            " + " ".join(f"{r:5.1f}" for r in rhos))
print("chart, pair in %      " + " ".join(f"{100 * pair_factor(r):5.2f}" for r in rhos))

assert abs(a - (-1.6448536269514722)) < 1e-12, "threshold vs the published 5% normal quantile"
assert abs(J - J2) < 1e-9, "factor integral and correlation route must agree"
assert abs(marg[0.5] - P) < 1e-10, "averaging q over the economy returns 5% at any rho"
assert abs(mc_J - J) < 4 * mc_se, "simulated pair default within its error bar"
assert abs(mc_p - P) < 0.003, "simulated default fraction near 5%"
assert abs(pair_factor(0.0) - P * P) < 1e-12, "no shared dial: pair default is p^2"
assert abs(sum(law_c) - 1.0) < 1e-9 and abs(sum(k * v for k, v in enumerate(law_c)) - NAMES * P) < 1e-9, "mixture law: total 1, mean 100p"
assert abs(sum(k * (k - 1) * v for k, v in enumerate(law_c)) - NAMES * (NAMES - 1) * J2) < 1e-7, "E[S(S-1)] = 100*99*J"
t_mc = tail / POOLS; assert abs(sum(law_c[10:]) - t_mc) < 4 * sqrt(t_mc * (1 - t_mc) / POOLS), "mixture tail vs simulated tail"
print("ALL CHECKS PASS")
