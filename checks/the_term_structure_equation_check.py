# A short-rate model and the term structure equation -- the check behind the card.
# Standard library only.  Nothing imported knows the answer: the random numbers,
# the integrator and the equation solver are all written here.
from math import exp, log, sqrt, cos, pi

a, theta, sigma, r0, T = 0.3, 0.05, 0.01, 0.04, 5.0   # pricing-world rate model; $100 due in 5 years
lam = 0.15                                             # market price of risk
theta_P = theta - lam * sigma / a                      # real-world long-run level, 4.5%

def simpson(f, lo, hi, n=2000):
    h = (hi - lo) / n
    return (f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))) * h / 3

def gauss_road(r, tau, th, sg=sigma):
    # Road 1: the integrated rate I is normal, so E[e^-I] = e^(-m + v/2); m and v by Simpson
    m = simpson(lambda s: th + (r - th) * exp(-a * s), 0.0, tau)
    v = simpson(lambda s: (sg * (1 - exp(-a * (tau - s))) / a) ** 2, 0.0, tau)
    return m, v, exp(-m + v / 2)

def closed(r, tau, th=theta):
    # Road 4: the formula the Vasicek card derives, used here only as a cross-check
    B = (1 - exp(-a * tau)) / a
    return exp((th - sigma ** 2 / (2 * a * a)) * (B - tau) - sigma ** 2 * B * B / (4 * a) - B * r)

state = 20260928
def u01():                                             # splitmix64 random numbers, 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def mc_road(pairs=4000, steps=500):
    # Road 2: step the rate exactly, add up the rate along the path, average the discount factor
    dt = T / steps; e = exp(-a * dt); sd = sigma * sqrt((1 - e * e) / (2 * a))
    tot = tot2 = 0.0
    for _ in range(pairs):
        ra = rb = r0; ia = ib = 0.0
        for _ in range(steps):
            z = sqrt(-2 * log(1 - u01())) * cos(2 * pi * u01())
            na = theta + (ra - theta) * e + sd * z; nb = theta + (rb - theta) * e - sd * z
            ia += 0.5 * dt * (ra + na); ib += 0.5 * dt * (rb + nb); ra, rb = na, nb
        d = 0.5 * (exp(-ia) + exp(-ib)); tot += d; tot2 += d * d
    mean = tot / pairs
    return mean, sqrt((tot2 / pairs - mean * mean) / pairs)

def pde_road(lo=-0.08, hi=0.18, dr=0.001, dt=0.0005):
    # Road 3: march p_t + a(theta - r) p_r + sigma^2/2 p_rr - r p = 0 back from p = 1 at maturity
    n = int(round((hi - lo) / dr)); rs = [lo + i * dr for i in range(n + 1)]; p = [1.0] * (n + 1)
    for _ in range(int(round(T / dt))):
        q = p[:]
        for i in range(1, n):
            pr = (p[i + 1] - p[i - 1]) / (2 * dr); prr = (p[i + 1] - 2 * p[i] + p[i - 1]) / dr ** 2
            q[i] = p[i] + dt * (a * (theta - rs[i]) * pr + 0.5 * sigma ** 2 * prr - rs[i] * p[i])
        q[0] = 2 * q[1] - q[2]; q[n] = 2 * q[n - 1] - q[n - 2]; p = q
    return lambda r: p[int(round((r - lo) / dr))]

m, v, P_g = gauss_road(r0, T, theta)
P_mc, se = mc_road()
pde = pde_road(); P_pde = pde(r0)
P_cf = closed(r0, T)
def row(name, x, f="14.4f"): print(f"{name:<34}{x:>{f}}")
row("e^-aT, share of the gap left", exp(-a * T), "14.6f"); row("B = (1 - e^-aT)/a", (1 - exp(-a * T)) / a, "14.6f")
row("(1 - e^-2aT)/(2a)", (1 - exp(-2 * a * T)) / (2 * a), "14.6f")
row("bracket T - 2B + that", T - 2 * (1 - exp(-a * T)) / a + (1 - exp(-2 * a * T)) / (2 * a), "14.6f")
row("mean of integrated rate m", m, "14.6f"); row("variance of integrated rate v", v, "14.8f")
row("exponent -m + v/2", -m + v / 2, "14.6f")
row("1 Gaussian moments, $100 bond", 100 * P_g); row("2 Monte Carlo, 8000 paths", 100 * P_mc)
row("  its standard error", 100 * se); row("3 equation marched back", 100 * P_pde)
row("4 Vasicek closed form", 100 * P_cf); row("5-year yield, percent", -100 * log(P_g) / T)

def parts(tau, drift_level):
    # finite-difference slopes of the closed form: time, rate, curvature
    h = 1e-4; p = closed(r0, tau)
    pt = -(closed(r0, tau + h) - closed(r0, tau - h)) / (2 * h)       # time left shrinks as t grows
    pr = (closed(r0 + h, tau) - closed(r0 - h, tau)) / (2 * h)
    prr = (closed(r0 + h, tau) - 2 * p + closed(r0 - h, tau)) / h ** 2
    return p, pt, a * (drift_level - r0) * pr, 0.5 * sigma ** 2 * prr, pr
p, pt, drift_term, curve_term, pr = parts(T, theta)
row("term: p_t", 100 * pt, "14.6f"); row("term: a(theta - r) p_r", 100 * drift_term, "14.6f")
row("term: sigma^2/2 p_rr", 100 * curve_term, "14.6f"); row("term: -r p", -100 * r0 * p, "14.6f")
resid = pt + drift_term + curve_term - r0 * p
print(f"{'residual of the equation below 1e-9':<34}{'yes' if abs(resid) < 1e-9 else 'NO':>14}")

row("real-world long-run level", theta_P, "14.6f")
lams = []
for tau in (2.0, 5.0, 10.0):
    p, pt, dP, cP, pr = parts(tau, theta_P)
    mu, vol = (pt + dP + cP) / p, -sigma * pr / p                    # real-world drift and volatility
    lams.append((mu - r0) / vol)
    print(f"bond {tau:>4.0f}y  return {mu:.6f}  vol {vol:.6f}  lambda {lams[-1]:.6f}")

P_real = gauss_road(r0, T, theta_P)[2]
row("wrong: real-world drift", 100 * P_real); row("wrong: rate frozen at 4%", 100 * exp(-r0 * T))
row("wrong: e^-m, variance dropped", 100 * exp(-m))
row("wrong: no pull toward 5%", 100 * exp(-r0 * T + sigma ** 2 * T ** 3 / 6))
row("try: sigma = 0.02", 100 * gauss_road(r0, T, theta, 0.02)[2])
row("try: r = 0.08", 100 * gauss_road(0.08, T, theta)[2])
row("try: 30 years", 100 * gauss_road(r0, 30.0, theta)[2])
p, pt, dP, cP, pr = parts(5.0, theta + lam * sigma / a)             # lam = -0.15: level 5.5%
row("try: lam = -0.15, real level", theta + lam * sigma / a, "14.6f")
row("try: lam = -0.15, 5y lambda", ((pt + dP + cP) / p - r0) / (-sigma * pr / p), "14.6f")

print("chart, maturity (years)     " + " ".join(f"{t:>5d}" for t in range(1, 11)))
print("chart, yield pricing world  " + " ".join(f"{-100 * log(gauss_road(r0, t, theta)[2]) / t:5.2f}" for t in range(1, 11)))
print("chart, yield real-world     " + " ".join(f"{-100 * log(gauss_road(r0, t, theta_P)[2]) / t:5.2f}" for t in range(1, 11)))
print("chart, rate today (%)       " + " ".join(f"{j:>5d}" for j in range(0, 9)))
print("chart, 5y bond from the PDE " + " ".join(f"{100 * pde(j / 100):5.2f}" for j in range(0, 9)))

assert abs(P_mc - P_g) < 4 * se,           "Monte Carlo average must land on the Gaussian road"
assert abs(P_pde - P_g) < 5e-6,             "the marched equation must land on the Gaussian road"
assert abs(P_g - P_cf) < 1e-10,            "Simpson moments must reproduce the closed form"
assert abs(resid) < 1e-9,                  "the closed form must satisfy the equation"
assert max(abs(x - lam) for x in lams) < 1e-5, "every maturity must show the same market price of risk"
print("ALL CHECKS PASS")
