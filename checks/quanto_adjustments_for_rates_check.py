# Quanto rates: a yen rate paid in dollars at a fixed conversion.  Standard library only.
# Every number quoted on the card is printed here.  The normal density, the Simpson
# integrator and the bisection root finder are written out below.
from math import exp, sqrt, pi

def phi(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)            # bell-curve height at z

N_GRID, LO, HI = 160, -8.0, 8.0                                   # Simpson grid on [-8, 8]
H = (HI - LO) / N_GRID
Z = [LO + i * H for i in range(N_GRID + 1)]
WZ = [(1 if i in (0, N_GRID) else (4 if i % 2 else 2)) * H / 3.0 * phi(z) for i, z in enumerate(Z)]

def dot(a, b):                                                    # plain left-to-right sum of products
    t = 0.0
    for x, y in zip(a, b): t += x * y
    return t
def avg1(f): return dot(WZ, [f(z) for z in Z])                    # E[f(Z)], Z standard normal
def avg2(f, rho):                                                 # E[f(Z1, Z2)], correlation rho
    c, t = sqrt(1.0 - rho * rho), 0.0
    for z1, w1 in zip(Z, WZ):
        t += w1 * dot(WZ, [f(z1, rho * z1 + c * z2) for z2 in Z])
    return t

def lognormal(f0, vol, T, z): return f0 * exp(vol * sqrt(T) * z - 0.5 * vol * vol * T)

# ---- contract A: 3-month yen rate fixing at T = 1, paid in dollars at U = 1.25 ----
F, sF, sG, rho, T, U, delta = 0.03, 0.30, 0.10, 0.40, 1.0, 1.25, 0.25
chi, Nf, Dd = 0.01, 100_000_000, 0.98                             # USD per JPY, JPY notional, dollar bond to U
scale = chi * Nf * delta * Dd                                     # dollars today per unit of rate

def formula(F, sF, sG, rho, T): return F * exp(-rho * sF * sG * T)   # road 1: the quanto drift

def reweighted(F, sF, sG, rho, T):                                # road 2: yen measure, weight 1/G
    h = lambda z1, z2: exp(-sG * sqrt(T) * z2)
    return avg2(lambda a, b: lognormal(F, sF, T, a) * h(a, b), rho) / avg2(h, rho)

def drift_by_root(F, sF, sG, rho, T):                             # road 3: dollar measure, solve for the drift
    G = lambda z2: lognormal(1.0, sG, T, z2)                      # forward FX, driftless in dollars
    def fra(mu):                                                  # dollar value of a yen FRA at market FX
        return avg2(lambda a, b: G(b) * (F * exp(mu * T + sF * sqrt(T) * a - 0.5 * sF * sF * T) - F), rho)
    lo, hi, flo = -0.5, 0.5, fra(-0.5)
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        fm = fra(mid)
        if flo * fm <= 0: hi = mid
        else: lo, flo = mid, fm
    return 0.5 * (lo + hi)

k1, k2 = formula(F, sF, sG, rho, T), reweighted(F, sF, sG, rho, T)
mu = drift_by_root(F, sF, sG, rho, T)
k3 = F * exp(mu * T)
assert abs(k2 - k1) < 1e-12                                      # reweighting agrees with the drift
assert abs(k3 - k1) < 1e-12                                      # root-found drift agrees too

# ---- three states by hand: foreign probabilities, rates, FX in USD per JPY ----
qf, R, X = (0.25, 0.5, 0.25), (0.01, 0.03, 0.05), (0.008, 0.010, 0.012)
w = [1.0 / x for x in X]                                          # dollar-bond weight 1/X_T
wbar = dot(qf, w)
qd = [p * v / wbar for p, v in zip(qf, w)]
f3, k_toy = dot(qf, R), dot(qd, R)
cov = dot(qf, [r * v for r, v in zip(R, w)]) - f3 * wbar
dd_toy = 0.01 * 0.96 * wbar                                       # X_0 * D_f(0,U) * E[weight]
assert abs(k_toy - 137 / 4900) < 1e-15                           # dollar probabilities, exact fraction
assert abs(f3 + cov / wbar - k_toy) < 1e-15                       # covariance form, same answer
assert abs(dd_toy - 0.98) < 1e-15
pv_toy = chi * Nf * delta * dd_toy * (k_toy - 0.03)
assert abs(pv_toy + 500.0) < 1e-9

# ---- contract B: 10-year yen swap rate fixing at T = 1, paid in dollars at T + 1 ----
S0, sS = 0.03, 0.25
def m(s): return s / (1.0 + s) / (1.0 - pow(1.0 + s, -10.0))         # D_f(T,T+1) / A_T on a flat yen curve
def cms(S0, sS, T): return avg1(lambda z: lognormal(S0, sS, T, z) * m(lognormal(S0, sS, T, z))) / avg1(lambda z: m(lognormal(S0, sS, T, z)))
def cms_quanto_2d(S0, sS, sG, rho, T):                           # annuity measure, weight m(S)/G
    wt = lambda a, b: m(lognormal(S0, sS, T, a)) * exp(-sG * sqrt(T) * b)
    return avg2(lambda a, b: lognormal(S0, sS, T, a) * wt(a, b), rho) / avg2(wt, rho)
kc_yen = cms(S0, sS, T)
kc_2d = cms_quanto_2d(S0, sS, sG, rho, T)
kc_shift = cms(S0 * exp(-rho * sS * sG * T), sS, T)               # Girsanov: shift the forward, then convexity
kc_prod = kc_yen * exp(-rho * sS * sG * T)                        # the two corrections multiplied
kc_rho0 = cms_quanto_2d(S0, sS, sG, 0.0, T)
assert abs(kc_2d - kc_shift) < 1e-12                             # 2-D weight = shifted forward
assert abs(kc_rho0 - kc_yen) < 1e-12                              # no correlation, no quanto part
assert 1e-7 < abs(kc_prod - kc_2d) < 1e-5                         # the product rule is close, not exact

# ---- sensitivities of contract A's value at strike 3%: analytic against bumped ----
def value(F=F, sF=sF, sG=sG, rho=rho, T=T): return scale * (formula(F, sF, sG, rho, T) - 0.03)
greeks = [("per 1 bp of yen forward", scale * 1e-4 * exp(-rho * sF * sG * T), (value(F=F + 1e-6) - value(F=F - 1e-6)) / 2e-6 * 1e-4),
          ("per 0.01 of correlation", -scale * 0.01 * sF * sG * T * k1, (value(rho=rho + 1e-6) - value(rho=rho - 1e-6)) / 2e-6 * 0.01),
          ("per 1 vol point of FX", -scale * 0.01 * rho * sF * T * k1, (value(sG=sG + 1e-6) - value(sG=sG - 1e-6)) / 2e-6 * 0.01),
          ("per 1 vol point of rate", -scale * 0.01 * rho * sG * T * k1, (value(sF=sF + 1e-6) - value(sF=sF - 1e-6)) / 2e-6 * 0.01)]
for _, a, b in greeks: assert abs(a - b) < 1e-5

bp = lambda x: 1e4 * x
rows = [("A yen forward F (%)", 100 * F), ("A rho*sF*sG*T", rho * sF * sG * T),
        ("A shrink factor e^-(that)", exp(-rho * sF * sG * T)),
        ("A 1 formula K_q (%)", 100 * k1), ("A 2 reweighted by 1/G (%)", 100 * k2),
        ("A 3 drift found by root", mu), ("A 3 K_q from that drift (%)", 100 * k3),
        ("A adjustment (bp)", bp(k1 - F)), ("A value at 3% strike ($)", scale * (k1 - F)),
        ("A dollars at U per unit rate", chi * Nf * delta),
        ("A dollars at U per 1% of rate", chi * Nf * delta / 100), ("A dollars today per unit rate", scale),
        ("toy weight 1/X, rate 1%", w[0]), ("toy weight 1/X, rate 3%", w[1]), ("toy weight 1/X, rate 5%", w[2]),
        ("toy weight mean E[1/X]", wbar), ("toy D_d(0,U)", dd_toy),
        ("toy dollar prob, rate 1%", qd[0]), ("toy dollar prob, rate 3%", qd[1]), ("toy dollar prob, rate 5%", qd[2]),
        ("toy covariance", cov), ("toy K_q (%)", 100 * k_toy), ("toy adjustment (bp)", bp(k_toy - f3)),
        ("toy value at 3% ($)", pv_toy),
        ("B yen CMS rate (%)", 100 * kc_yen), ("B yen convexity (bp)", bp(kc_yen - S0)),
        ("B 1 quanto CMS, 2-D (%)", 100 * kc_2d), ("B shifted forward (%)", 100 * S0 * exp(-rho * sS * sG * T)),
        ("B 2 shift then CMS (%)", 100 * kc_shift),
        ("B 3 product of the two (%)", 100 * kc_prod), ("B total adjustment (bp)", bp(kc_2d - S0)),
        ("B quanto part (bp)", bp(kc_2d - kc_yen)), ("B product error (bp)", bp(kc_prod - kc_2d)),
        ("wrong: no quanto (%)", 100 * F), ("wrong: sign flipped (%)", 100 * F * exp(rho * sF * sG * T)),
        ("wrong: payment clock U (%)", 100 * formula(F, sF, sG, rho, U)),
        ("try: rho = -0.40 (%)", 100 * formula(F, sF, sG, -rho, T)), ("try: sG = 0.20 (%)", 100 * formula(F, sF, 0.20, rho, T)),
        ("try: B at rho = -0.40 (%)", 100 * cms_quanto_2d(S0, sS, sG, -rho, T))]
for name, v in rows: print(f"{name:<30} {v:>16.10f}")
for name, a, b in greeks: print(f"greek {name:<24} {a:>12.6f} {b:>12.6f}")
print("payoff, yen rate (%)      " + "".join(f"{x:>10.2f}" for x in (1, 2, 3, 4, 5)))
print("payoff, dollars at K_q    " + "".join(f"{chi * Nf * delta * (x / 100 - k1):>10.2f}" for x in (1, 2, 3, 4, 5)))
for r_ in (0.4, 0.0, -0.4):
    print(f"chart rho {r_:+.1f}, K_q (%)  " + "".join(f"{100 * formula(F, sF, sG, r_, t):>6.2f}" for t in range(1, 11)))
print("ALL CHECKS PASS")
