# Vasicek model -- the check behind the card.  Standard library only.
# Short rate r pulled toward level th at speed a, with volatility s:
#   dr = a (th - r) dt + s dW.   House example: a = 0.3, th = 5%, s = 1%, r0 = 4%.
# The 5-year zero is priced four ways that share no code: the closed form,
# the Gaussian integral of the rate, the bond equation solved as two ODEs by
# Runge-Kutta, and simulated rate paths.  The normal CDF and the random
# numbers are written here.
from math import exp, log, sqrt, cos, pi

A_, TH, S_, R0, T = 0.3, 0.05, 0.01, 0.04, 5.0

def closed(r0, t, a=A_, th=TH, s=S_):                 # road 1: P = exp(lnA - B r0)
    b = (1 - exp(-a * t)) / a
    ln_a = (th - s * s / (2 * a * a)) * (b - t) - s * s * b * b / (4 * a)
    return exp(ln_a - b * r0)

def integral_moments(r0, t, a=A_, th=TH, s=S_):       # mean and variance of the area under r
    b = (1 - exp(-a * t)) / a
    return th * t + (r0 - th) * b, s * s / (a * a) * (t - b - a * b * b / 2)

def by_moments(r0, t):                                # road 2: E[exp(-I)] for a normal I
    m, v = integral_moments(r0, t)
    return exp(-m + v / 2)

def by_ode(r0, t, n=1000):                            # road 3: B' = 1 - aB, lnA' = -a th B + s^2 B^2 / 2
    f = lambda y: (1 - A_ * y[0], -A_ * TH * y[0] + S_ * S_ * y[0] * y[0] / 2)
    y, h = (0.0, 0.0), t / n
    for _ in range(n):
        k1 = f(y); k2 = f((y[0] + h / 2 * k1[0], y[1] + h / 2 * k1[1]))
        k3 = f((y[0] + h / 2 * k2[0], y[1] + h / 2 * k2[1])); k4 = f((y[0] + h * k3[0], y[1] + h * k3[1]))
        y = (y[0] + h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]), y[1] + h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]))
    return exp(y[1] - y[0] * r0), y[0]

M64 = (1 << 64) - 1
state = 20260928
def uniform():                                        # splitmix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 9007199254740992.0

def normal():                                         # Box-Muller, cosine half
    u1, u2 = uniform(), uniform()
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2)

def by_paths(r0, t, pairs=4000, steps=250):           # road 4: simulate, discount, average
    dt = t / steps
    decay, sd = exp(-A_ * dt), S_ * sqrt((1 - exp(-2 * A_ * dt)) / (2 * A_))
    vals = []
    for _ in range(pairs):
        rp = rm = r0; ip = im = 0.0
        for _ in range(steps):
            z = normal()
            np_ = TH + (rp - TH) * decay + sd * z; nm = TH + (rm - TH) * decay - sd * z
            ip += (rp + np_) / 2 * dt; im += (rm + nm) / 2 * dt; rp, rm = np_, nm
        vals.append((exp(-ip) + exp(-im)) / 2)
    mean = sum(vals) / pairs
    se = sqrt(sum((x - mean) ** 2 for x in vals) / (pairs - 1) / pairs)
    return mean, se

def ncdf(x, n=2000):                                  # bell-curve area left of x, Simpson
    h = x / n
    g = lambda u: exp(-u * u / 2) / sqrt(2 * pi)
    tot = g(0) + g(x) + sum((4 if i % 2 else 2) * g(i * h) for i in range(1, n))
    return 0.5 + tot * h / 3

def rate_at(t, r0=R0, s=S_):                          # mean and sd of r_t
    return TH + (r0 - TH) * exp(-A_ * t), s * sqrt((1 - exp(-2 * A_ * t)) / (2 * A_))

def yld(r0, t, s=S_): return 100 * (-log(closed(r0, t, s=s)) / t) if t > 0 else 100 * r0

p1 = closed(R0, T); p2 = by_moments(R0, T); p3, b_ode = by_ode(R0, T); p4, se = by_paths(R0, T)
b = (1 - exp(-A_ * T)) / A_
m, v = integral_moments(R0, T)
h = 1e-4
dur_bump = -(closed(R0 + h, T) - closed(R0 - h, T)) / (2 * h) / p1
mu5, sd5 = rate_at(T); mu5b, sd5b = rate_at(T, s=0.02)
neg_1 = ncdf(-mu5 / sd5); neg_2 = ncdf(-mu5b / sd5b)
draws = 200000
neg_count = sum(1 for _ in range(draws) if mu5b + sd5b * normal() < 0)

rows = [
    ("e^(-aT)", exp(-A_ * T)), ("B(5), rate sensitivity in years", b), ("B(5) from the ODE", b_ode),
    ("level part (th - s^2/2a^2)(B - T)", (TH - S_ * S_ / (2 * A_ * A_)) * (b - T)),
    ("spread part s^2 B^2 / 4a", S_ * S_ * b * b / (4 * A_)),
    ("A(5)", log(p1) + b * R0), ("-B(5) r0", -b * R0), ("log of price", log(p1)),
    ("mean of area under r, 0 to 5", m), ("variance of that area", v),
    ("1 closed form P(0,5)", p1), ("2 Gaussian integral", p2), ("3 Runge-Kutta ODE", p3),
    ("4 paths, 4000 antithetic pairs", p4), ("  standard error", se),
    ("5-year yield, percent", yld(R0, T)), ("long yield, percent", 100 * (TH - S_ * S_ / (2 * A_ * A_))),
    ("5-year yield move per point of r0", b / T), ("bumped rate sensitivity", dur_bump),
    ("expected r at 5y, percent", 100 * mu5), ("sd of r at 5y, percent", 100 * sd5),
    ("P(r5 < 0), s = 1%, percent", 100 * neg_1), ("P(r5 < 0), s = 2%, percent", 100 * neg_2),
    ("  simulated, 200000 draws, percent", 100 * neg_count / draws),
    ("3-month zero at r0 = -0.5%", closed(-0.005, 0.25)),
    ("wrong: flat at today's 4%", exp(-R0 * T)), ("wrong: flat at the 5% level", exp(-TH * T)),
    ("wrong: expected path, no convexity", exp(-m)), ("wrong: convexity sign flipped", exp(-m - v / 2)),
    ("wrong: no reversion, a -> 0", exp(-R0 * T + S_ * S_ * T ** 3 / 6)),
    ("30-year zero", closed(R0, 30.0)), ("  30-year, no convexity", exp(-integral_moments(R0, 30.0)[0])),
    ("try: a = 0.03", closed(R0, T, a=0.03)), ("try: s = 3%", closed(R0, T, s=0.03)),
    ("try: r0 = 8%", closed(0.08, T)), ("try: r0 = 0%", closed(0.0, T)),
]
for name, val in rows:
    print(f"{name:<36} {val:>12.6f}")
print()
print("5-year zero by today's rate, percent: price")
for r in (-1, 0, 2, 4, 6, 8):
    print(f"  r0 = {r:>2}%   {closed(r / 100, T):.4f}")
print()
mats = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
print("yield curve, percent" + "".join(f"{t:>6}" for t in mats))
for r in (2, 4, 8):
    print(f"  r0 = {r}%, s = 1%    " + "".join(f"{yld(r / 100, t):6.2f}" for t in mats))
humps = (0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20)
print("hump, maturities   " + "".join(f"{t:>6}" for t in humps))
print("  r0 = 4.5%, s = 3%" + "".join(f"{yld(0.045, t, s=0.03):6.2f}" for t in humps))

assert abs(p1 - p2) < 1e-12, "closed form vs Gaussian integral"
assert abs(p1 - p3) < 1e-10, "closed form vs Runge-Kutta on the bond equation"
assert abs(p4 - p1) < 4 * se, "simulated paths within four standard errors"
assert abs(dur_bump - b_ode) < 1e-6, "bumped sensitivity vs B from the ODE"
assert abs(neg_count / draws - neg_2) < 0.002, "simulated negative-rate share vs normal CDF"
print("ALL CHECKS PASS")
