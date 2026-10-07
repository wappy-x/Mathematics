# Smile-adjusted delta -- the check behind the card.  Standard library only.
# The normal CDF is a series written out here, the random numbers come from a
# splitmix64 generator written out here, and the regression is two sums.
from math import log, sqrt, exp, pi, cos

S0, K, r, q, T = 100.0, 100.0, 0.05, 0.02, 1.0
SIG0, BETA = 0.20, 0.0004          # at-the-money vol; skew falls 0.0004 (0.04 points) per $ of strike

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def N(x):                           # 0.5 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    term, total, n = x, x, 1
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 2; term *= x * x / n; total += term
    return 0.5 + phi(x) * total

def d1(S, sig): return (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def call(S, sig):
    a = d1(S, sig)
    return S * exp(-q * T) * N(a) - K * exp(-r * T) * N(a - sig * sqrt(T))
def delta(S, sig): return exp(-q * T) * N(d1(S, sig))
def vega(S, sig): return S * exp(-q * T) * phi(d1(S, sig)) * sqrt(T)
def gamma(S, sig): return exp(-q * T) * phi(d1(S, sig)) / (S * sig * sqrt(T))
def vanna(S, sig): return -exp(-q * T) * phi(d1(S, sig)) * (d1(S, sig) - sig * sqrt(T)) / sig

rules = {                            # the vol the K = 100 option is marked at, when Acme is at S
    "sticky strike": lambda S: SIG0 - BETA * (K - S0),
    "sticky moneyness": lambda S: SIG0 - BETA * S0 * (K / S - 1.0),
    "local-vol rule": lambda S: SIG0 - BETA * (K + S - 2.0 * S0),
}
slopes = {"sticky strike": 0.0, "sticky moneyness": BETA, "local-vol rule": -BETA}   # d sigma / dS, by hand
dl, vg, gm, vn = delta(S0, SIG0), vega(S0, SIG0), gamma(S0, SIG0), vanna(S0, SIG0)
print(f"{'d1':<34}{d1(S0, SIG0):12.6f}")
print(f"{'N(d1)':<34}{N(d1(S0, SIG0)):12.6f}")
print(f"{'phi(d1), bell-curve height':<34}{phi(d1(S0, SIG0)):12.6f}")
print(f"{'BS delta e^-qT N(d1)':<34}{dl:12.6f}")
print(f"{'vega, per 1.00 of vol':<34}{vg:12.6f}")
print(f"{'vega x 0.0004':<34}{vg * BETA:12.6f}")
out = {}
for name, rule in rules.items():                 # road 1: chain rule.  road 2: bump spot, remark, reprice
    formula = dl + vg * slopes[name]
    h = 0.01
    bumped = (call(S0 + h, rule(S0 + h)) - call(S0 - h, rule(S0 - h))) / (2 * h)
    out[name] = (formula, bumped)
    print(f"{name + ', formula':<34}{formula:12.6f}")
    print(f"{name + ', bump and reprice':<34}{bumped:12.6f}")

# strict sticky delta: the vol is a fixed function G of the option's own BS delta
dDdK = -exp(-q * T) * phi(d1(S0, SIG0)) / (K * SIG0 * sqrt(T))   # how delta changes with strike
Gp = -BETA / dDdK                                                  # skew slope, re-expressed per unit of delta
sigS = Gp * gm / (1.0 - Gp * vn)
def solve_vol(S):                                                  # sigma = G(delta(S, sigma)), by iteration
    sig = SIG0
    for _ in range(60): sig = SIG0 + Gp * (delta(S, sig) - dl)
    return sig
strict_bump = (call(S0 + 0.01, solve_vol(S0 + 0.01)) - call(S0 - 0.01, solve_vol(S0 - 0.01))) / 0.02
print(f"{'gamma':<34}{gm:12.6f}")
print(f"{'vanna':<34}{vn:12.6f}")
print(f"{'G prime, vol per unit of delta':<34}{Gp:12.6f}")
print(f"{'1 - G prime x vanna':<34}{1.0 - Gp * vn:12.6f}")
print(f"{'strict sticky delta, formula':<34}{dl + vg * sigS:12.6f}")
print(f"{'strict sticky delta, bump':<34}{strict_bump:12.6f}")

# minimum-variance delta: simulate one day of joint spot and vol moves, reprice fully, regress
state = 20260919
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0
def normal_pair():
    u1, u2 = uniform(), uniform()
    rad = sqrt(-2.0 * log(u1))
    return rad * cos(2.0 * pi * u2), rad * cos(2.0 * pi * u2 - 0.5 * pi)
B, ETA, DT, PAIRS = -BETA, 0.0005, 1.0 / 252.0, 20000
dS, dV, dsig = [], [], []
C0 = call(S0, SIG0)
for _ in range(PAIRS):
    z1, z2 = normal_pair()
    for sgn in (1.0, -1.0):                                          # antithetic pair
        ds = sgn * S0 * SIG0 * sqrt(DT) * z1
        dv = B * ds + sgn * ETA * z2
        dS.append(ds); dsig.append(dv); dV.append(call(S0 + ds, SIG0 + dv) - C0)
n = len(dS)
def cov(a, b):
    ma, mb = sum(a) / n, sum(b) / n
    return sum((x - ma) * (y - mb) for x, y in zip(a, b)) / n
vS, vs = cov(dS, dS), cov(dsig, dsig)
h_star = cov(dV, dS) / vS
b_hat = cov(dsig, dS) / vS
rho = cov(dsig, dS) / sqrt(vS * vs)
def resid_sd(h): return sqrt(cov([v - h * s for v, s in zip(dV, dS)], [v - h * s for v, s in zip(dV, dS)]))
print(f"{'simulated days':<34}{n:12d}")
print(f"{'daily spot move sd, $':<34}{sqrt(vS):12.6f}")
print(f"{'spot-vol correlation':<34}{rho:12.6f}")
print(f"{'vol-on-spot slope, fitted':<34}{b_hat:12.6f}")
print(f"{'min-variance delta, regression':<34}{h_star:12.6f}")
print(f"{'min-variance delta, BS + vega x b':<34}{dl + vg * b_hat:12.6f}")
sd_bs, sd_mv = resid_sd(dl), resid_sd(h_star)
print(f"{'daily P&L sd per 10,000, BS delta':<34}{10000 * sd_bs:12.2f}")
print(f"{'daily P&L sd per 10,000, MV delta':<34}{10000 * sd_mv:12.2f}")
cut = sqrt(sd_bs ** 2 - sd_mv ** 2)                                  # the part of the P&L the MV hedge removes
cut_pred = vg * abs(B) * sqrt(vS)                                     # vega x |b| x sd of the spot move
print(f"{'removed sd per 10,000, measured':<34}{10000 * cut:12.2f}")
print(f"{'removed sd per 10,000, vega b sd':<34}{10000 * cut_pred:12.2f}")
print("chart, hedge ratio   " + " ".join(f"{0.55 + 0.01 * i:6.2f}" for i in range(8)))
print("chart, sd per 10,000 " + " ".join(f"{10000 * resid_sd(0.55 + 0.01 * i):6.2f}" for i in range(8)))
print("smile today, strike   " + "".join(f"{k:7.0f}" for k in (90.0, 95.0, 100.0, 105.0, 110.0)))
print("smile today, vol %    " + "".join(f"{100 * (SIG0 - BETA * (k - S0)):7.2f}" for k in (90.0, 95.0, 100.0, 105.0, 110.0)))
print("chart, Acme price     " + "".join(f"{s:7.0f}" for s in (90.0, 95.0, 100.0, 105.0, 110.0)))
for name, tag in (("sticky strike", "strike"), ("sticky moneyness", "moneyness"), ("local-vol rule", "local-vol")):
    print(f"chart, vol % {tag:<9}" + "".join(f"{100 * rules[name](s):7.2f}" for s in (90.0, 95.0, 100.0, 105.0, 110.0)))

# what breaks, and try changing
print(f"{'wrong: shift of -vega x 0.0004':<34}{dl - vg * BETA:12.6f}")
print(f"{'wrong: vega per 1.00 x -0.04':<34}{dl + vg * (-0.04):12.6f}")
print(f"{'shares per 10,000 calls, gap':<34}{10000 * vg * BETA:12.2f}")
print(f"{'put: BS delta':<34}{dl - exp(-q * T):12.6f}")
print(f"{'put: local-vol rule':<34}{dl - exp(-q * T) - vg * BETA:12.6f}")
pts = ((92.15, 0.24), (100.0, 0.20), (119.93, 0.18))                 # the shelf's house smile
(x0, y0), (x1, y1), (x2, y2) = pts
house = (y0 * (x1 - x2) / ((x0 - x1) * (x0 - x2)) + y1 * (2 * x1 - x0 - x2) / ((x1 - x0) * (x1 - x2))
         + y2 * (x1 - x0) / ((x2 - x0) * (x2 - x1)))                # slope at 100 of the parabola through them
print(f"{'house smile slope at 100, per $':<34}{house:12.6f}")
print(f"{'house smile, local-vol rule':<34}{dl + vg * house:12.6f}")

for name, (formula, bumped) in out.items():
    assert abs(formula - bumped) < 1e-6, name                     # chain rule vs full reprice, each rule
assert abs((dl + vg * sigS) - strict_bump) < 1e-6                  # implicit rule vs solve-and-reprice
assert abs(h_star - (dl + vg * B)) < 1e-3                          # regression vs chain rule with the true b
assert abs(cut / cut_pred - 1.0) < 0.03                            # risk removed vs vega x b x sd(dS)
print("ALL CHECKS PASS")
