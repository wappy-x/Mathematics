# A random hazard (Cox process): Northwind's five-year survival four ways, the Jensen gap, the par spread.
# Standard library only. Random numbers, ODE stepper and integrator are written here.
from math import exp, log, sqrt, cos, sin, pi
K, TH, SIG, L0, T = 0.5, 0.02, 0.10, 0.02, 5.0   # pull speed, long-run hazard, noise, today's hazard, years
R, REC, DELTA = 0.05, 0.40, 0.25                 # riskless rate, recovery, quarterly premiums

def cir_AB(t, k=K, th=TH, s=SIG, two=2.0, power=True):   # road 1: the CIR bond formula, hazard for rate
    g = sqrt(k * k + two * s * s)
    e = exp(g * t); den = (g + k) * (e - 1.0) + 2.0 * g
    base = 2.0 * g * exp((g + k) * t / 2.0) / den
    return (base ** (2.0 * k * th / (s * s)) if power else base), 2.0 * (e - 1.0) / den, g
def Q(t, l0=L0, **kw):
    if t == 0.0: return 1.0
    A, B, _ = cir_AB(t, **kw)
    return A * exp(-B * l0)
def riccati_Q(t, n=1000):                        # road 2: B' = 1 - kB - s^2 B^2/2, (ln A)' = -k th B, stepped
    f = lambda b: 1.0 - K * b - 0.5 * SIG * SIG * b * b
    h, b, lnA = t / n, 0.0, 0.0
    for _ in range(n):
        k1 = f(b); k2 = f(b + h * k1 / 2); k3 = f(b + h * k2 / 2); k4 = f(b + h * k3)
        lnA -= K * TH * h * (b + 2 * (b + h * k1 / 2) + 2 * (b + h * k2 / 2) + (b + h * k3)) / 6
        b += h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return exp(lnA - b * L0)
def simpson(f, a, b, n=2000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3
class Rng:                                       # splitmix64 + Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    def pair(self):
        a, b = 1.0 - self.u(), self.u()
        rad = sqrt(-2.0 * log(a))
        return rad * cos(2 * pi * b), rad * sin(2 * pi * b)
def path(zs, sign, dt):                          # one hazard path from the SDE; returns area, hazards
    l, area, ls = L0, 0.0, [L0]
    for z in zs:
        nl = max(l + K * (TH - l) * dt + SIG * sqrt(l) * sign * z * sqrt(dt), 0.0)
        area += 0.5 * (l + nl) * dt; l = nl; ls.append(l)
    return area, ls
def simulate(pairs=50000, steps=100, seed=20260928):     # roads 3 and 4
    rng, dt = Rng(seed), T / steps
    avg, alive, l1, frz = [], 0, [], []
    for _ in range(pairs):
        zs = []
        for _ in range(steps // 2): zs.extend(rng.pair())
        es = (-log(1.0 - rng.u()), -log(1.0 - rng.u()))  # each twin's own exponential clock
        pv = 0.0
        for sign, E in zip((1.0, -1.0), es):             # antithetic twin: same draws, flipped
            area, ls = path(zs, sign, dt)
            pv += 0.5 * exp(-area); alive += area < E     # road 3 averages e^-area; road 4 counts
            l1.append(ls[steps // 5]); frz.append(exp(-T * ls[-1]))
        avg.append(pv)
    return avg, alive / (2 * pairs), l1, frz
def tot(xs):
    s = 0.0
    for x in xs: s += x
    return s
def mean_se(xs):
    m = tot(xs) / len(xs)
    return m, sqrt(tot([(x - m) ** 2 for x in xs]) / (len(xs) - 1) / len(xs))
def par_bp(q, lam=None):                         # par spread: Simpson legs, or the flat closed form
    if lam is not None:
        c = R + lam; x = exp(-c * DELTA)
        return (1 - REC) * lam * (1 - exp(-c * T)) / c / (DELTA * x * (1 - x ** 20) / (1 - x)) * 1e4
    ann = tot([DELTA * exp(-R * DELTA * j) * q(DELTA * j) for j in range(1, 21)])
    prot = (1 - REC) * (1 - exp(-R * T) * q(T) - R * simpson(lambda t: exp(-R * t) * q(t), 0.0, T))
    return prot / ann * 1e4
mean_l = lambda s: TH + (L0 - TH) * exp(-K * s)
var_l = lambda s: L0 * SIG**2 / K * (exp(-K * s) - exp(-2 * K * s)) + TH * SIG**2 / (2 * K) * (1 - exp(-K * s))**2
A5, B5, G = cir_AB(T)
e5 = exp(G * T); den5 = (G + K) * (e5 - 1.0) + 2.0 * G; base5 = 2.0 * G * exp((G + K) * T / 2.0) / den5
Q1, Q2, flat = Q(T), riccati_Q(T), exp(-0.02 * T)
avg, Q4, l1, frz = simulate(); Q3, se3 = mean_se(avg); se4 = sqrt(Q4 * (1 - Q4) / 100000)
EL = simpson(mean_l, 0.0, T)
VL = 2 * simpson(lambda s: var_l(s) * (1 - exp(-K * (T - s))) / K, 0.0, T)
m1 = tot(l1) / len(l1); sd1 = sqrt(tot([(x - m1) ** 2 for x in l1]) / (len(l1) - 1))
cT = SIG**2 * (1 - exp(-K * T)) / (4 * K)                 # frozen-hazard mistake: E[exp(-T lam_T)]
frozen = (1 + 2 * T * cT) ** (-2 * K * TH / SIG**2) * exp(-T * L0 * exp(-K * T) / (1 + 2 * T * cT))
s_flat, s_cf, s_cox = par_bp(lambda t: exp(-0.02 * t)), par_bp(None, 0.02), par_bp(Q)
rows = [("gamma", G), ("e^(gamma T)", e5), ("denominator (g+k)(e^gT - 1) + 2g", den5), ("B(5)", B5),
    ("bracket inside A", base5), ("A(5)", A5), ("e^(-B(5) lambda0)", exp(-B5 * L0)), ("Feller ratio nu = 2 k theta / sigma^2", 2 * K * TH / SIG**2),
    ("shock size at 2%, sigma sqrt(lambda0)", SIG * sqrt(L0)),
    ("1 closed form Q(5)", Q1), ("2 Riccati stepped Q(5)", Q2), ("3 simulated mean of e^-area", Q3),
    ("  standard error", se3), ("4 simulated share never defaulting", Q4), ("  standard error", se4),
    ("flat 2% survival e^-0.1", flat), ("E[area] by Simpson", EL), ("Var[area] by Simpson", VL),
    ("Jensen gap Q - e^-E[area]", Q1 - exp(-EL)), ("  half Var times e^-E[area]", 0.5 * VL * exp(-EL)),
    ("  ln Q + E - Var/2 (the rest)", log(Q1) + EL - 0.5 * VL),
    ("sd of hazard at 1 year, formula", sqrt(var_l(1.0))), ("sd of hazard at 1 year, simulated", sd1),
    ("par spread bp, flat 2%, Simpson", s_flat), ("par spread bp, flat 2%, closed form", s_cf),
    ("par spread bp, random hazard", s_cox), ("  difference bp", s_cox - s_flat),
    ("wrong: power nu dropped", Q(T, power=False)), ("wrong: sigma^2 not 2 sigma^2 in gamma", Q(T, two=1.0)),
    ("wrong: hazard frozen at year 5, formula", frozen), ("  simulated", tot(frz) / len(frz)),
    ("try: kappa = 2", Q(T, k=2.0)), ("try: sigma = 0.20, Feller ratio 0.5", Q(T, s=0.2))]
for name, v in rows: print(f"{name:<40} {v:>12.6f}")
print("gap by maturity, bp of survival, 1..10 years:")
print(" ".join(f"{(Q(float(t)) - exp(-0.02 * t)) * 1e4:.2f}" for t in range(1, 11)))
print("sigma, Feller ratio, five-year survival gain over flat (bp):")
for s in (0.05, 0.10, 0.15, 0.20): print(f"  {s:.2f}  {2 * K * TH / s**2:5.2f}  {(Q(T, s=s) - flat) * 1e4:6.2f}")
print("start hazard %, par spread bp random, par spread bp flat:")
for i in range(6):
    l0 = i / 100.0
    print(f"  {i}  {par_bp(lambda t: Q(t, l0=l0)):7.2f}  {par_bp(None, l0) if l0 > 0 else 0.0:7.2f}")
print("three hazard paths, % a year, every half year 0..5:")
rng = Rng(7)
for _ in range(3):
    zs = []
    for _ in range(50): zs.extend(rng.pair())
    print(" ".join(f"{100 * x:.2f}" for x in path(zs, 1.0, 0.05)[1][::10]))
assert abs(Q1 - 0.9056646181) < 1e-9, "closed form vs the card's worked number"
assert abs(Q2 - Q1) < 1e-10, "stepped Riccati equations must land on the closed form"
assert abs(Q3 - Q1) < 4 * se3 and abs(Q4 - Q1) < 4 * se4, "both simulations within four standard errors"
assert Q1 > exp(-EL) and abs(Q1 - exp(-EL) - 0.5 * VL * exp(-EL)) < 3e-5, "Jensen: above, by about half the variance"
assert abs(s_flat - s_cf) < 1e-6, "Simpson legs vs the flat closed form"
assert abs(frozen - tot(frz) / len(frz)) < 2e-4, "frozen-hazard formula vs the simulated paths"
print("ALL CHECKS PASS")
