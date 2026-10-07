# Expected utility and risk aversion -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  The normal density, Simpson's rule,
# the bisection root finder and the random numbers are all written out below.
from math import log, exp, sqrt, pi

W0, DEP, UP, DN = 10000.0, 10400.0, 12300.0, 9300.0   # savings, deposit, the fund's two outcomes
MEAN = 0.5 * UP + 0.5 * DN                            # expected wealth in the fund
VAR = 0.5 * (UP - MEAN) ** 2 + 0.5 * (DN - MEAN) ** 2 # its variance, dollars squared

def u(w, g):                      # power utility with relative risk aversion g; log at g = 1
    return log(w) if g == 1 else w ** (1 - g) / (1 - g)
def u_inv(y, g):
    return exp(y) if g == 1 else (y * (1 - g)) ** (1 / (1 - g))
def ce_coin(g):                   # road 1: exact expected utility of the coin-toss fund, then invert
    return u_inv(0.5 * u(UP, g) + 0.5 * u(DN, g), g)
def vnm_p(w, g):                  # the chance of 12,300 (else 9,300) the saver rates equal to a sure w
    return (u(w, g) - u(DN, g)) / (u(UP, g) - u(DN, g))

def ce_monte_carlo(g, n=200000):  # road 2: simulate n years with a home-made xorshift generator
    s, total = 88172645463325252, 0.0
    for _ in range(n):
        s ^= (s << 13) & 0xFFFFFFFFFFFFFFFF; s ^= s >> 7; s ^= (s << 17) & 0xFFFFFFFFFFFFFFFF
        total += u(UP if (s >> 11) / 2.0 ** 53 < 0.5 else DN, g)
    return u_inv(total / n, g)

def bisect(f, lo, hi):            # root of f between lo and hi, f changing sign
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# ---- a smoother fund: lognormal, same 8% mean and 15% spread ----
S2 = log(1.0 + (0.15 / 1.08) ** 2)          # variance of the log return
M = log(1.08) - 0.5 * S2                    # mean of the log return
def ce_lognormal_formula(g): return W0 * exp(M + 0.5 * (1 - g) * S2)
def ce_lognormal_simpson(g, n=2000):        # second road: integrate u over the bell curve
    a, b = -10.0, 10.0; h = (b - a) / n; tot = 0.0
    for i in range(n + 1):
        z = a + i * h
        wgt = 1 if i in (0, n) else (4 if i % 2 else 2)
        tot += wgt * u(W0 * exp(M + sqrt(S2) * z), g) * exp(-0.5 * z * z) / sqrt(2 * pi)
    return u_inv(tot * h / 3, g)

# ---- the headline comparison ----
print(f"{'deposit, sure wealth':<40}{DEP:>14.2f}")
print(f"{'fund, expected wealth':<40}{MEAN:>14.2f}")
print(f"{'fund, spread of wealth (dollars)':<40}{sqrt(VAR):>14.2f}")
print(f"{'fund, variance (dollars squared)':<40}{VAR:>14.2f}")
print(f"{'spread / expected wealth':<40}{sqrt(VAR) / MEAN:>14.4f}")
print(f"{'E[ln W], fund':<40}{0.5 * log(UP) + 0.5 * log(DN):>14.6f}")
print(f"{'ln W, deposit':<40}{log(DEP):>14.6f}")
for g in (1, 5):
    print(f"gamma = {g}")
    print(f"{'  certainty equivalent, exact':<40}{ce_coin(g):>14.2f}")
    print(f"{'  certainty equivalent, simulated':<40}{ce_monte_carlo(g):>14.2f}")
    print(f"{'  vNM chance matching the deposit':<40}{vnm_p(DEP, g):>14.4f}")
    print(f"{'  takes':<40}{'fund' if ce_coin(g) > DEP else 'deposit':>14}")
print(f"{'log saver, CE minus deposit':<40}{ce_coin(1) - DEP:>14.2f}")

# ---- Arrow-Pratt: -u''/u' by finite differences, two differently scaled utilities ----
w, h = MEAN, 1.0
def ap_numeric(f):
    d1 = (f(w + h) - f(w - h)) / (2 * h); d2 = (f(w + h) - 2 * f(w) + f(w - h)) / h ** 2
    return -d2 / d1, d2
A_log, d2_log = ap_numeric(log)
A_pts, d2_pts = ap_numeric(lambda x: 100 * log(x / 10000) + 7)
print(f"{'A(10800), log, by differences':<40}{A_log:>14.9f}")
print(f"{'A(10800), 100 ln(w/10000)+7':<40}{A_pts:>14.9f}")
print(f"{'A(10800) = 1/w':<40}{1 / w:>14.9f}")
print(f"{'second derivative x 1e9, log':<40}{d2_log * 1e9:>14.4f}")
print(f"{'same, 100 ln(w/10000)+7':<40}{d2_pts * 1e9:>14.4f}")

# ---- Pratt's small-risk rule against the exact premium ----
pratt = 0.5 * (1 / MEAN) * VAR
print(f"{'premium, log, exact':<40}{MEAN - ce_coin(1):>14.2f}")
print(f"{'premium, log, Pratt 0.5 A var':<40}{pratt:>14.2f}")
print(f"{'Pratt error, log':<40}{MEAN - ce_coin(1) - pratt:>14.2f}")
rich = 100000.0                               # same +-1,500 bet on 100,000 of wealth
ce_rich = exp(0.5 * log(rich + 2300) + 0.5 * log(rich - 700))
print(f"{'premium, same bet on 100,000, exact':<40}{rich + 800 - ce_rich:>14.2f}")
g_star = bisect(lambda g: ce_coin(g) - DEP, 1.5, 10.0)
print(f"{'break-even gamma, coin fund, exact':<40}{g_star:>14.4f}")
print(f"{'break-even gamma, Pratt rule':<40}{(MEAN - DEP) / pratt:>14.4f}")

# ---- the lognormal fund, formula and brute force ----
gl_formula = 1 + 2 * (M - log(1.04)) / S2
gl_simpson = bisect(lambda g: ce_lognormal_simpson(g) - DEP, 1.5, 10.0)
print(f"{'lognormal, log-return mean, variance':<26}{M:>14.4f}{S2:>14.4f}")
print(f"{'lognormal CE, log, formula':<40}{ce_lognormal_formula(1):>14.2f}")
print(f"{'lognormal CE, log, Simpson':<40}{ce_lognormal_simpson(1):>14.2f}")
print(f"{'lognormal break-even gamma, formula':<40}{gl_formula:>14.4f}")
print(f"{'lognormal break-even gamma, Simpson':<40}{gl_simpson:>14.4f}")

# ---- what breaks ----
print(f"{'wrong: rank by expected wealth':<40}{MEAN:>14.2f}")
print(f"{'wrong: u(E W) in place of E u(W)':<40}{u_inv(u(MEAN, 1), 1):>14.2f}")
print(f"{'wrong: spread not squared, premium':<40}{0.5 * (0.15 / 1.08) * MEAN:>14.2f}")
print(f"{'wrong: gamma used as A, premium':<40}{0.5 * 1.0 * VAR:>14.2f}")

# ---- chart points ----
print("chart, certainty equivalent for gamma 0 to 5, then 6 to 10")
print("".join(f"{ce_coin(g):>10.2f}" for g in range(0, 6)))
print("".join(f"{ce_coin(g):>10.2f}" for g in range(6, 11)))
xs = [DN + 500.0 * i for i in range(7)]
chord = [100 * log(DN / W0) + (x - DN) / (UP - DN) * 100 * (log(UP / W0) - log(DN / W0)) for x in xs]
print(f"{'chart, wealth':<14}" + "".join(f"{x:>8.0f}" for x in xs))
print(f"{'  100 ln(w/1e4)':<14}" + "".join(f"{100 * log(x / W0):>8.2f}" for x in xs))
print(f"{'  chord':<14}" + "".join(f"{c:>8.2f}" for c in chord))

assert abs(ce_coin(1) - sqrt(UP * DN)) < 1e-6, "log CE must be the geometric mean"
assert abs(ce_coin(2) - 2 / (1 / UP + 1 / DN)) < 1e-6, "gamma 2 CE must be the harmonic mean"
assert abs(ce_monte_carlo(1) - ce_coin(1)) < 10.0, "simulation within $10 of the exact CE"
assert abs(A_log - 1 / w) < 1e-9, "-u''/u' by differences vs 1/w"
assert abs(A_pts - 1 / w) < 1e-9, "-u''/u' ignores rescaling and shifting"
assert abs(pratt - (MEAN - ce_coin(1))) < 1.0, "Pratt's rule within $1 on this bet"
assert abs(ce_lognormal_simpson(1) - ce_lognormal_formula(1)) < 1e-6, "lognormal CE two roads"
assert abs(gl_simpson - gl_formula) < 1e-6, "break-even gamma two roads"
assert abs(ce_lognormal_simpson(0) - MEAN) < 1e-6, "lognormal fund really has mean 10,800"
assert (vnm_p(DEP, 1) < 0.5) == (ce_coin(1) > DEP), "calibration and CE agree, log saver"
assert (vnm_p(DEP, 5) < 0.5) == (ce_coin(5) > DEP), "calibration and CE agree, gamma 5"
assert ce_coin(1) > DEP > ce_coin(5) and vnm_p(DEP, 1) < 0.5 < vnm_p(DEP, 5), "log: fund; gamma 5: deposit"
assert ce_coin(3.9) > DEP > ce_coin(4.0) and abs(g_star - 3.9454) < 5e-5, "crossing between 3.9 and 4"
assert abs(ap_numeric(lambda x: u(x, 5))[0] * w - 5) < 1e-5, "power utility: w A(w) = gamma"
