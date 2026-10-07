# Method of moments -- the check behind the card.  Standard library only.
# A gamma law fitted to ten insurance claims ($ thousands): by matching moments, then by
# maximum likelihood.  Log-gamma, digamma, trigamma, the integrator, both root finders
# and the random generator (SplitMix64, seed 20260928) are written out here.
from math import log, exp, sqrt, pi

M64 = (1 << 64) - 1
def splitmix64(s):                                   # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def lgam(a):                                         # ln Gamma(a): push a past 7, then Stirling
    r = 0.0
    while a < 7: r -= log(a); a += 1
    return r + (a - 0.5) * log(a) - a + 0.5 * log(2 * pi) + 1 / (12 * a) - 1 / (360 * a**3) + 1 / (1260 * a**5)
def digamma(a):                                      # psi(a), the slope of ln Gamma
    r = 0.0
    while a < 7: r -= 1 / a; a += 1
    return r + log(a) - 1 / (2 * a) - 1 / (12 * a * a) + 1 / (120 * a**4) - 1 / (252 * a**6)
def trigamma(a):                                     # psi'(a), the slope of psi
    r = 0.0
    while a < 7: r += 1 / (a * a); a += 1
    return r + 1 / a + 1 / (2 * a * a) + 1 / (6 * a**3) - 1 / (30 * a**5) + 1 / (42 * a**7)

def mom(xs):                                         # match the mean and the variance
    n = len(xs); m1 = sum(xs) / n; m2 = sum(x * x for x in xs) / n
    v = m2 - m1 * m1
    return m1 * m1 / v, m1 / v
def mle(xs):                                         # road 1: ln a - psi(a) = ln(mean) - mean(ln x), bisection
    n = len(xs); m = sum(xs) / n; c = log(m) - sum(log(x) for x in xs) / n
    lo, hi = log(1e-3), log(1e3)
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        if log(exp(mid)) - digamma(exp(mid)) > c: lo = mid
        else: hi = mid
    a = exp(0.5 * (lo + hi)); return a, a / m
def golden(f, lo, hi):                               # maximise f on [lo, hi] by golden section
    g = (sqrt(5) - 1) / 2
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) > f(b): hi = b
        else: lo = a
    return 0.5 * (lo + hi)
def mle_golden(xs):                                  # road 2: climb the log-likelihood itself, no digamma
    n = len(xs); m = sum(xs) / n; L = sum(log(x) for x in xs) / n
    ll = lambda t: exp(t) * log(exp(t) / m) - lgam(exp(t)) + (exp(t) - 1) * L - exp(t)
    a = exp(golden(ll, log(1e-2), log(1e2))); return a, a / m
def fitted_moment(a, lam, k):                        # integral of x^k times the fitted density, Simpson
    f = lambda x: x**k * exp(a * log(lam) + (a - 1) * log(x) - lam * x - lgam(a)) if x > 0 else 0.0
    N, top = 20000, 80.0; h = top / N
    return h / 3 * sum((1 if i in (0, N) else 4 if i % 2 else 2) * f(i * h) for i in range(N + 1))
def dens(a, lam, x): return exp(a * log(lam) + (a - 1) * log(x) - lam * x - lgam(a))
def tail(a, lam, N=20000, h=150.0 / 20000):          # P(X > 10) for any shape: Simpson on [10, 160]
    return h / 3 * sum((1 if i in (0, N) else 4 if i % 2 else 2) * dens(a, lam, 10 + i * h) for i in range(N + 1))
def mom_avar(a, lam):                                # n x variance of the moment estimates, delta method
    mu = [1.0]
    for k in range(1, 5): mu.append(mu[-1] * (a + k - 1) / lam)      # E[X^k] of the gamma law
    v11, v12, v22 = mu[2] - mu[1]**2, mu[3] - mu[1] * mu[2], mu[4] - mu[2]**2
    m1, m2 = mu[1], mu[2]; d = m2 - m1 * m1
    q = lambda g1, g2: g1 * g1 * v11 + 2 * g1 * g2 * v12 + g2 * g2 * v22
    return q(2 * m1 * m2 / d**2, -m1 * m1 / d**2), q((m2 + m1 * m1) / d**2, -m1 / d**2)
def mle_avar(a, lam):                                # n x variance of the ML estimates, inverse information
    t = trigamma(a); det = a * t - 1
    return a / det, lam * lam * t / det

claims = [0.5, 1.0, 1.0, 2.0, 2.5, 3.0, 3.5, 3.5, 5.0, 8.0]
n = len(claims)
a_m, l_m = mom(claims); a_l, l_l = mle(claims); a_g, l_g = mle_golden(claims)
xbar, sq, lnbar = sum(claims) / n, sum(x * x for x in claims) / n, sum(log(x) for x in claims) / n
print(f"claims, n = {n}, sum {n*xbar:.4f}, mean {xbar:.4f}, sum of squares {n*sq:.4f}, mean of squares {sq:.4f}")
s2 = sum((x - xbar)**2 for x in claims) / (n - 1)
print(f"variance (divide by n) {sq - xbar**2:.4f}, divide by n-1 {s2:.4f}, shape then {xbar**2 / s2:.4f}")
print(f"mean of ln x {lnbar:.4f}, ln(mean) - mean ln x {log(xbar) - lnbar:.4f}, mean of 1/x {sum(1 / x for x in claims) / n:.4f}")
sa, sl = mom_avar(a_m, l_m); ta, tl = mle_avar(a_l, l_l)
print(f"MoM  shape {a_m:.4f} (SE {sqrt(sa/n):.4f})  rate {l_m:.4f} (SE {sqrt(sl/n):.4f})  scale {1/l_m:.4f}")
print(f"MLE  shape {a_l:.4f} (SE {sqrt(ta/n):.4f})  rate {l_l:.4f} (SE {sqrt(tl/n):.4f})  scale {1/l_l:.4f}")
print(f"MLE by golden section on the likelihood: shape {a_g:.4f} rate {l_g:.4f}")
e1, e2 = fitted_moment(a_m, l_m, 1), fitted_moment(a_m, l_m, 2)
print(f"fitted MoM gamma, integrated: E[X] {e1:.4f}  E[X^2] {e2:.4f}")
exp_rate = exp(golden(lambda t: n * t - exp(t) * n * xbar, log(1e-3), log(1e3)))    # exponential log-likelihood
print(f"one parameter: exponential rate by MoM {1/xbar:.4f}, by likelihood {exp_rate:.4f}, SE {1/xbar/sqrt(n):.4f}")
p_hat = golden(lambda t: 520 * log(t) + 480 * log(1 - t), 1e-6, 1 - 1e-6)
print(f"house poll: MoM share {520/1000:.4f}, likelihood {p_hat:.4f}, SE {sqrt(0.52*0.48/1000):.4f}")
print(f"delta method, n x Var(MoM shape) {sa:.4f} vs 2a(a+1) = {2*a_m*(a_m+1):.4f}; psi(1) {digamma(1.0):.4f}, psi'(2) {trigamma(2.0):.4f}")

# ---- what breaks ----
tail_g = exp(-10 * l_m) * (1 + 10 * l_m)                             # P(X > 10) for whole shape 2
print(f"break: P(claim > 10) gamma fit {tail_g:.4f}, exponential fit {exp(-10/3):.4f}, ratio {exp(-10/3) / tail_g:.4f}")
lo_a, hi_a = a_m - sqrt(sa / n), a_m + sqrt(sa / n); print(f"tail by Simpson {tail(a_m, l_m):.4f}; shape -/+ 1 SE, mean held at 3: {tail(lo_a, lo_a / xbar):.4f} to {tail(hi_a, hi_a / xbar):.4f}")
print(f"break: rate read as scale, mean {a_m * l_m:.4f} instead of {a_m / l_m:.4f}")
big = claims + [40.0]
print(f"break: add a 40 claim, MoM shape {mom(big)[0]:.4f}  MLE shape {mle(big)[0]:.4f}")

# ---- simulation: truth shape 2, rate 2/3, R samples of n claims each ----
A, LAM, R, NS, state, tot = 2.0, 2.0 / 3.0, 2000, 200, 20260928, 0.0
est = {"MoM": [], "MLE": []}
for r in range(R):
    xs = []
    for i in range(NS):
        x = 0.0
        for j in range(2):                                           # shape 2 = sum of two exponential gaps
            state, z = splitmix64(state)
            x -= log(((z >> 11) + 0.5) * 2.0**-53) / LAM
        xs.append(x); tot += x
    est["MoM"].append(mom(xs)[0]); est["MLE"].append(mle(xs)[0])
se_draw = sqrt(A) / LAM / sqrt(R * NS)                              # sd of one gamma claim over sqrt(draws)
print(f"sim, all {R * NS} draws: mean {tot / (R * NS):.4f} (SE {se_draw:.4f}), the law's mean {A / LAM:.4f}")
bins = [1.4 + 0.1 * k for k in range(13)]
print(f"sim, {R} samples of {NS}: shape estimate  mean   (SE)     n x variance  theory   % off chart")
for key, th in (("MoM", mom_avar(A, LAM)[0]), ("MLE", mle_avar(A, LAM)[0])):
    e = est[key]; mu = sum(e) / R; var = sum((v - mu)**2 for v in e) / (R - 1)
    off = 100 * sum(not 1.35 <= v < 2.65 for v in e) / R
    print(f"sim, {key}                          {mu:.4f} ({sqrt(var/R):.4f})  {NS*var:8.4f}   {th:.4f}   {off:.2f}")
    est[key + "v"] = NS * var
    print(f"chart, {key} percent per bin " + " ".join(f"{100 * sum(b - 0.05 <= v < b + 0.05 for v in e) / R:.2f}" for b in bins))
print("chart, bin centres         " + " ".join(f"{b:.1f}" for b in bins))
print("chart, claim size           " + " ".join(f"{x:5.1f}" for x in range(1, 12, 2)))
print("chart, claims, % per 1000  " + " ".join(f"{100 * sum(k - 1 <= c < k + 1 for c in claims) / (2 * n):5.2f}" for k in range(1, 12, 2)))
print("chart, MoM gamma, % per 1000 " + " ".join(f"{100 * dens(a_m, l_m, x):5.2f}" for x in range(1, 12, 2)))
print("chart, MLE gamma, % per 1000 " + " ".join(f"{100 * dens(a_l, l_l, x):5.2f}" for x in range(1, 12, 2)))
shapes = [0.5, 1, 2, 3, 5, 10, 20, 50]
print("efficiency, shape           " + " ".join(f"{s:6.1f}" for s in shapes))
print("efficiency, MLE/MoM var, %  " + " ".join(f"{100 * mle_avar(s, 1)[0] / mom_avar(s, 1)[0]:6.2f}" for s in shapes))

assert abs(a_m - 9 / 4.5) < 1e-12, "MoM shape on the claims: hand arithmetic says 9/4.5"
assert abs(e1 - xbar) < 1e-6, "the fitted law's integrated mean must be the sample's mean"
assert abs(e2 - sq) < 1e-6, "the fitted law's integrated E[X^2] must be the sample's mean square"
assert abs(a_l - a_g) < 1e-6, "digamma road and likelihood-climbing road must find the same MLE"
assert abs(sa - 2 * a_m * (a_m + 1)) < 1e-9, "delta method must give the closed form 2a(a+1)"
assert abs(digamma(1.0) + 0.5772156649015329) < 1e-9, "psi(1) is minus Euler's constant"
assert abs(trigamma(2.0) - (pi * pi / 6 - 1)) < 1e-9, "psi'(2) is pi^2/6 - 1"
assert abs(est["MoMv"] / mom_avar(A, LAM)[0] - 1) < 0.15, "simulated MoM spread within a few SE of theory"
assert abs(est["MLEv"] / mle_avar(A, LAM)[0] - 1) < 0.15, "simulated MLE spread within a few SE of theory"
assert est["MLEv"] < est["MoMv"], "MLE must be the tighter estimator at shape 2"
assert abs(tot / (R * NS) - A / LAM) < 4 * se_draw, "the generator must draw from the gamma law with mean 3"
assert abs(exp_rate - 1 / xbar) < 1e-6 and abs(p_hat - 0.52) < 1e-6, "one-dial laws: likelihood equals moments"
assert abs(tail(a_m, l_m) - tail_g) < 1e-9, "Simpson's tail at the fit must match the closed form for whole shape 2"
print("all checks passed")
