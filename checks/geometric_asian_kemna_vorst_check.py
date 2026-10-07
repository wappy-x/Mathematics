# The geometric Asian call (Kemna-Vorst) -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is a series written out, the integrals
# are Simpson's rule and brute-force sums, the random numbers are splitmix64 + Box-Muller.
from math import log, sqrt, exp, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height
def N(x):                                                       # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term = total = x; k = 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + phi(x) * total

def bs_call(S, K, r, q, sig, T):                               # the plain Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))

def kv_call(S, K, r, q, sig, T):                               # road 1: Kemna-Vorst substitution
    return bs_call(S, K, r, 0.5 * (r + q) + sig * sig / 12.0, sig / sqrt(3.0), T)

def fixings_call(S, K, r, q, sig, T, n):                       # n equal fixings, the last at T
    m = log(S) + (r - q - 0.5 * sig * sig) * T * (n + 1) / (2 * n)
    v = sig * sig * T * (n + 1) * (2 * n + 1) / (6.0 * n * n)
    d2 = (m - log(K)) / sqrt(v)
    return exp(-r * T) * (exp(m + 0.5 * v) * N(d2 + sqrt(v)) - K * N(d2))

def simpson_price(m, v, payoff, r, T, panels=200000):           # average payoff over ln G ~ normal(m, v)
    a, b = -10.0, 10.0; h = (b - a) / panels
    f = lambda z: payoff(exp(m + sqrt(v) * z)) * phi(z)
    tot = f(a) + f(b)
    for i in range(1, panels):
        tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
nu, sigG, qhat = r - q - 0.5 * sig * sig, sig / sqrt(3.0), 0.5 * (r + q) + sig * sig / 12.0
b = r - qhat
d1 = (log(S / K) + (b + 0.5 * sigG * sigG) * T) / (sigG * sqrt(T)); d2 = d1 - sigG * sqrt(T)
C = kv_call(S, K, r, q, sig, T)

# road 2: the law of ln G by brute force -- covariance min(s, u) summed on a grid, no 1/3 anywhere
def cov_sum(m):
    h = T / m; s = [(i + 0.5) * h for i in range(m)]
    return sum(min(x, y) for x in s for y in s) * h * h / (T * T)
var_c = sig * sig * (4.0 * cov_sum(1200) - cov_sum(600)) / 3.0   # Richardson: error is exactly c/m^2
mean_c = log(S) + nu * sum((i + 0.5) / 1000 * T for i in range(1000)) / 1000
C_simp = simpson_price(mean_c, var_c, lambda G: max(G - K, 0.0), r, T)
P_simp = simpson_price(mean_c, var_c, lambda G: max(K - G, 0.0), r, T)
ts = [T * i / 52 for i in range(1, 53)]                                   # weekly fixings
var_w = sig * sig * sum(min(x, y) for x in ts for y in ts) / 52 ** 2
C_w_simp = simpson_price(log(S) + nu * sum(ts) / 52, var_w, lambda G: max(G - K, 0.0), r, T)
C_w = fixings_call(S, K, r, q, sig, T, 52)

# road 3: simulation.  Exact continuous average: over each week, given both ends, the integral
# of the log price is the trapezoid plus an independent normal with variance sig^2 h^3 / 12.
MASK = (1 << 64) - 1
state = 20260924
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 1) * 2.0 ** -53
paths, steps = 100000, 52
h = T / steps; sh, sb = sig * sqrt(h), sig * sqrt(h ** 3 / 12.0)
disc = exp(-r * T)
acc = {"c": [0.0, 0.0], "w": [0.0, 0.0], "a": [0.0, 0.0]}; am_below_gm = 0
for _ in range(paths):
    x = log(S); integral = 0.0; sum_log = 0.0; sum_price = 0.0
    for _ in range(steps):
        rad = sqrt(-2.0 * log(uniform())); ang = 2.0 * pi * uniform()
        x_new = x + nu * h + sh * rad * cos(ang)
        integral += 0.5 * h * (x + x_new) + sb * rad * sin(ang)
        x = x_new; sum_log += x; sum_price += exp(x)
    gc, gw, aw = exp(integral / T), exp(sum_log / steps), sum_price / steps
    am_below_gm += aw < gw
    for key, avg in (("c", gc), ("w", gw), ("a", aw)):
        pay = disc * max(avg - K, 0.0); acc[key][0] += pay; acc[key][1] += pay * pay
mc = {k: (s1 / paths, sqrt((s2 / paths - (s1 / paths) ** 2) / paths)) for k, (s1, s2) in acc.items()}

# Greeks by bumping the formula, and the delta it predicts
bump = lambda **kw: kv_call(**{**dict(S=S, K=K, r=r, q=q, sig=sig, T=T), **kw})
delta = (bump(S=S + 0.01) - bump(S=S - 0.01)) / 0.02
gamma = (bump(S=S + 0.5) - 2 * C + bump(S=S - 0.5)) / 0.25
vega = (bump(sig=sig + 1e-4) - bump(sig=sig - 1e-4)) / 2e-4 / 100
rho = (bump(r=r + 1e-4) - bump(r=r - 1e-4)) / 2e-4 / 100

rows = [("toy: sqrt(81*121), vs (81+121)/2 = 101", sqrt(81.0 * 121.0)), ("nu = r - q - sigma^2/2", nu),
        ("forward S e^((r-q)T)", S * exp((r - q) * T)), ("sigma_G = sigma / sqrt 3", sigG), ("qhat = (r+q)/2 + sigma^2/12", qhat),
        ("b = r - qhat, carry of the average", b), ("E[G] = S e^(bT)", S * exp(b * T)),
        ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)),
        ("average half S e^-qhatT N(d1)", S * exp(-qhat * T) * N(d1)),
        ("cash half K e^-rT N(d2)", K * exp(-r * T) * N(d2)),
        ("1 Kemna-Vorst formula", C), ("2 var ln G, min(s,u) summed", var_c),
        ("  sigma^2 T / 3", sig * sig * T / 3), ("2 Simpson over that law", C_simp),
        ("3 simulation, 100000 paths", mc["c"][0]), ("  standard error", mc["c"][1]),
        ("4 put by Simpson", P_simp), ("  C - P", C_simp - P_simp),
        ("  e^-rT (E[G] - K)", disc * (S * exp(b * T) - K)),
        ("weekly: formula, 52 fixings", C_w), ("weekly: var ln G, 52x52 sum", var_w),
        ("weekly: Simpson over that law", C_w_simp), ("weekly: simulation", mc["w"][0]),
        ("  standard error", mc["w"][1]), ("arithmetic weekly: simulation", mc["a"][0]),
        ("  paths where AM < GM", am_below_gm), ("vanilla Black-Scholes call", bs_call(S, K, r, q, sig, T))]
rows += [(f"ladder: {n} fixings", fixings_call(S, K, r, q, sig, T, n)) for n in (1, 2, 4, 12, 52, 252, 10000)]
rows += [("delta by bump", delta), ("  e^-qhatT N(d1)", exp(-qhat * T) * N(d1)), ("gamma by bump", gamma),
         ("vega per vol point", vega), ("rho per rate point", rho)]
rows += [("wrong: raw sigma, qhat kept", bs_call(S, K, r, qhat, sig, T)),
         ("wrong: sigma/sqrt3, yield q kept", bs_call(S, K, r, q, sigG, T)),
         ("wrong: no -sigma^2/12 in qhat", bs_call(S, K, r, 0.5 * (r + q), sigG, T)),
         ("wrong: weekly as independent, sigma/sqrt52", bs_call(S, K, r, qhat, sig / sqrt(52), T))]
rows += [("try: sigma = 0.40", kv_call(S, K, r, q, 0.40, T)), ("try: K = 90", kv_call(S, 90.0, r, q, sig, T)),
         ("try: T = 2", kv_call(S, K, r, q, sig, 2.0)), ("try: q = 0", kv_call(S, K, r, 0.0, sig, T))]
for name, v in rows:
    print(f"{name:<42} {v:>12.6f}" if isinstance(v, float) else f"{name:<42} {v:>12}")
grid = [80.0 + 5.0 * i for i in range(9)]
print("chart, G at expiry " + " ".join(f"{g:6.0f}" for g in grid))
print("chart, profit      " + " ".join(f"{max(g - K, 0.0) - C:6.2f}" for g in grid))
fix = (1, 2, 4, 12, 52, 252)
print("chart, fixings     " + " ".join(f"{n:6d}" for n in fix))
print("chart, price       " + " ".join(f"{fixings_call(S, K, r, q, sig, T, n):6.2f}" for n in fix))

assert abs(C_simp - C) < 1e-7, "brute-force law of ln G must reproduce the formula"
assert abs(mc["c"][0] - C) < 3 * mc["c"][1], "exact-average simulation within 3 standard errors"
assert abs(C_w_simp - C_w) < 1e-7, "weekly: covariance sum and Simpson vs the fixings formula"
assert abs(mc["w"][0] - C_w) < 3 * mc["w"][1], "weekly simulation within 3 standard errors"
assert abs((C_simp - P_simp) - disc * (S * exp(b * T) - K)) < 1e-7, "parity with an independently priced put"
assert abs(fixings_call(S, K, r, q, sig, T, 1) - 9.227005508154) < 1e-9, "one fixing is the vanilla"
assert abs(delta - exp(-qhat * T) * N(d1)) < 1e-6, "bumped delta vs e^-qhatT N(d1)"
print("ALL CHECKS PASS")
