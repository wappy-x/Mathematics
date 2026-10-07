# The quanto adjustment -- the check behind the card.  Standard library only.
# A euro share paid in dollars at a fixed rate.  Roads to its forward:
# 1 the formula; 2 a 2-D Simpson integral in the euro world; 3 a Monte Carlo
# of the pair in the euro world; 4 a Monte Carlo of the pair in the dollar world,
# testing the product rule.  Random numbers: splitmix64 + Box-Muller, written here.
from math import exp, log, sqrt, pi, cos, sin

S, Xbar, X0 = 100.0, 1.10, 1.10          # share (EUR), fixed rate and spot (USD per EUR)
rd, rf, q, T = 0.05, 0.03, 0.01, 1.0     # dollar rate, euro rate, dividend yield, years
sS, sX, rho = 0.20, 0.10, 0.30           # share vol, FX vol, correlation

def quanto_fwd(rho, T=1.0):              # road 1: the formula
    return S * exp((rf - q - rho * sS * sX) * T)

def euro_fwd(T=1.0):
    return S * exp((rf - q) * T)

def euro_world_integral(rho, X0, n=160):
    # Road 2.  Euro world: the share drifts at rf - q, a dollar (Y = 1/X euros)
    # drifts at rf - rd.  Dollar-world mean of S_T = E[S_T Y_T] / E[Y_T].
    a, h = -8.0, 16.0 / n
    num = den = 0.0
    for i in range(n + 1):
        z1 = a + i * h
        wi = 1 if i in (0, n) else (4 if i % 2 else 2)
        ST = S * exp((rf - q - 0.5 * sS * sS) * T + sS * sqrt(T) * z1)
        for j in range(n + 1):
            z2 = a + j * h
            wj = 1 if j in (0, n) else (4 if j % 2 else 2)
            wx = rho * z1 + sqrt(1 - rho * rho) * z2
            YT = (1 / X0) * exp((rf - rd - 0.5 * sX * sX) * T - sX * sqrt(T) * wx)
            w = wi * wj * exp(-0.5 * (z1 * z1 + z2 * z2))
            num += w * ST * YT
            den += w * YT
    return num / den

M = (1 << 64) - 1
state = 20260927
def uniform():                           # splitmix64, top 53 bits, never 0
    global state
    state = (state + 0x9E3779B97F4A7C15) & M
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    z ^= z >> 31
    return ((z >> 11) + 1) / 9007199254740992.0

n = 200000
sy = sy1 = sy2 = sxy = 0.0               # euro-world sums
sa = sa2 = su = su2 = sxx = 0.0          # dollar-world sums
mu = rf - q - rho * sS * sX
for _ in range(n):
    r_ = sqrt(-2.0 * log(uniform())); t_ = 2.0 * pi * uniform()
    z1, z2 = r_ * cos(t_), r_ * sin(t_)
    wx = rho * z1 + sqrt(1 - rho * rho) * z2
    # road 3: euro world, no adjusted drift anywhere
    ST = S * exp((rf - q - 0.5 * sS * sS) * T + sS * sqrt(T) * z1)
    YT = (1 / X0) * exp((rf - rd - 0.5 * sX * sX) * T - sX * sqrt(T) * wx)
    sy += ST * YT; sy1 += YT; sy2 += ST * YT * ST * YT; sxy += YT * YT; sxx += ST * YT * YT
    # road 4: dollar world, share at the adjusted drift, rate at rd - rf
    XT = X0 * exp((rd - rf - 0.5 * sX * sX) * T + sX * sqrt(T) * wx)
    Sa = S * exp((mu - 0.5 * sS * sS) * T + sS * sqrt(T) * z1)
    Su = S * exp((rf - q - 0.5 * sS * sS) * T + sS * sqrt(T) * z1)
    sa += Sa * XT; sa2 += Sa * XT * Sa * XT; su += Su * XT; su2 += Su * XT * Su * XT
F_mc = sy / sy1
var_r = (sy2 - 2 * F_mc * sxx + F_mc * F_mc * sxy) / n    # variance of S Y - F Y
se_F = sqrt(var_r / n) / (sy1 / n)
dA, dU = sa / n, su / n
se_A, se_U = sqrt((sa2 / n - dA * dA) / n), sqrt((su2 / n - dU * dU) / n)
fair = S * X0 * exp((rd - q) * T)

# two-state story: euro-world odds 1/2 each; dollar-world odds proportional to (1/2) / X_T
up, dn, xs, xw = 120.0, 84.0, 1.21, 0.99
w_s = (0.5 / xs) / (0.5 / xs + 0.5 / xw)
together = w_s * up + (1 - w_s) * dn     # share high when the euro is strong
opposite = (1 - w_s) * up + w_s * dn     # share high when the euro is weak

FQ, FE = quanto_fwd(rho), euro_fwd()
FI = euro_world_integral(rho, X0)
FI_130 = euro_world_integral(rho, 1.30)
rows = [
    ("adjustment rho sS sX", rho * sS * sX), ("quanto drift rf - q - rho sS sX", mu),
    ("euro carry rf - q", rf - q), ("rate drift rd - rf", rd - rf), ("adjustment at rho = 1", sS * sX),
    ("1 formula: quanto forward", FQ), ("2 euro-world integral", FI),
    ("3 euro-world Monte Carlo", F_mc), ("  its standard error", se_F),
    ("euro forward S e^(rf-q)T", FE), ("gap, euro forward - quanto", FE - FQ),
    ("gap as ln(FE / FQ)", log(FE / FQ)),
    ("4 dollar share E[S X], adjusted", dA), ("  its standard error", se_A),
    ("  required S X0 e^(rd-q)T", fair),
    ("  dollar share E[S X], unadjusted", dU), ("  unadjusted, exact", fair * exp(rho * sS * sX * T)),
    ("  growth required, ln(fair / S X0)", log(fair / (S * X0)) / T), ("  growth unadjusted, exact", log(fair * exp(rho * sS * sX * T) / (S * X0)) / T),
    ("one day: 1.01 x 1.01", 1.01 * 1.01), ("one day: 1.01 x 0.99", 1.01 * 0.99),
    ("story: dollar weight, strong euro", w_s), ("story: euro-world mean", 0.5 * up + 0.5 * dn),
    ("story: together, dollar mean", together), ("story: opposite, dollar mean", opposite),
    ("story: ln(102 / together)", log(102.0 / together)),
    ("rho = -0.30: quanto forward", quanto_fwd(-0.30)), ("rho = 0: quanto forward", quanto_fwd(0.0)),
    ("wrong: domestic rate for the share", S * exp((rd - q - rho * sS * sX) * T)),
    ("contract struck at FE, USD value", Xbar * exp(-rd * T) * (FQ - FE)),
    ("try: spot 1.30, integral", FI_130),
]
for name, v in rows:
    print(f"{name:<36} {v:>12.6f}")
print("chart, rho      " + " ".join(f"{-1 + 0.25 * k:6.2f}" for k in range(9)))
print("chart, forward  " + " ".join(f"{quanto_fwd(-1 + 0.25 * k):6.2f}" for k in range(9)))
for Tm in (1, 2, 5, 10):
    print(f"bars, T = {Tm:>2}: euro {euro_fwd(Tm):7.2f}  quanto {quanto_fwd(rho, Tm):7.2f}  gap {euro_fwd(Tm) - quanto_fwd(rho, Tm):5.2f}")

assert abs(FI - FQ) < 1e-8,               "euro-world integral must land on the formula"
assert abs(FI_130 - FQ) < 1e-8,           "today's spot rate must not matter"
assert abs(F_mc - FQ) < 4 * se_F,         "euro-world Monte Carlo within 4 standard errors"
assert abs(dA - fair) < 4 * se_A,         "adjusted drift makes the dollar share fair"
assert abs(dU - fair) > 4 * se_U,         "unadjusted drift leaves a detectable free lunch"
assert (together < 0.5 * up + 0.5 * dn) == (quanto_fwd(1.0) < FE),  "story and model agree: moving together lowers it"
assert (opposite > 0.5 * up + 0.5 * dn) == (quanto_fwd(-1.0) > FE), "story and model agree: moving apart raises it"
print("ALL CHECKS PASS")
