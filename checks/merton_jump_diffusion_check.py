# Merton jump-diffusion -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is Marsaglia's series
# written out, the root finder is bisection, the integral is Simpson's rule,
# uniforms come from the house recurrence and normals from Box-Muller.
from math import cos, exp, log, pi, sqrt

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0    # the house market
LAM, MUJ, DEL = 0.5, -0.10, 0.15            # jump rate, log-size mean, spread
SEED, PATHS, MOD = 20260924, 1000000, 1 << 32
STRIKES = (70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0)

def n_cdf(x):                               # area left of x, Marsaglia's series
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        t, i = s, i + 2.0
        b *= x * x / i
        s = t + b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def phi(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)      # bell-curve height
def bs(k, r, q, sig, t, put=False):         # Black-Scholes, spot S, yield q
    vt = sig * sqrt(t)
    d1 = (log(S / k) + (r - q + 0.5 * sig * sig) * t) / vt
    if put: return k * exp(-r * t) * n_cdf(vt - d1) - S * exp(-q * t) * n_cdf(-d1)
    return S * exp(-q * t) * n_cdf(d1) - k * exp(-r * t) * n_cdf(d1 - vt)
def kbar(mu): return exp(mu + 0.5 * DEL * DEL) - 1.0       # k = E[Y] - 1
def poisson_sum(f, lam, t, terms=60):       # sum over n of P(n jumps) f(n)
    w, total = exp(-lam * t), 0.0
    for n in range(terms):
        if n: w *= lam * t / n
        total += w * f(n)
    return total
def merton(k=K, lam=LAM, mu=MUJ, t=T, terms=60, put=False, comp=1.0, widen=1.0, shift=1.0, kj=None):
    kj = kbar(mu) if kj is None else kj                   # road 1: the series
    return poisson_sum(lambda n: bs(k, R, Q + comp * lam * kj - shift * n * log(1.0 + kj) / t,
                                    sqrt(SIG * SIG + widen * n * DEL * DEL / t), t, put), lam, t, terms)
def merton76(lam_w, t=T):                   # road 2: Merton's own arrangement
    kj = kbar(MUJ)
    return poisson_sum(lambda n: bs(K, R - LAM * kj + n * log(1.0 + kj) / t, Q,
                                    sqrt(SIG * SIG + n * DEL * DEL / t), t), lam_w, t)
def branch(n, lam):                         # centre and spread of ln(S_T / S)
    return (R - Q - lam * kbar(MUJ) - 0.5 * SIG * SIG) * T + n * MUJ, sqrt(SIG * SIG * T + n * DEL * DEL)
def payoff_average(n):                      # road 3: the n-jump payoff, Simpson slices
    m, sd = branch(n, LAM)
    a = (log(K / S) - m) / sd                             # start at the strike's kink
    h, f = (12.0 - a) / 4000, lambda z: (S * exp(m + sd * z) - K) * phi(z)
    return h / 3.0 * sum((1.0 if i in (0, 4000) else 4.0 if i % 2 else 2.0) * f(a + i * h) for i in range(4001))
def ending(x, lam, cdf):                    # in %: chance per $1 at x, or below x
    def one(n):
        m, sd = branch(n, lam)
        return n_cdf((log(x / S) - m) / sd) if cdf else phi((log(x / S) - m) / sd) / (sd * x)
    return 100.0 * poisson_sum(one, lam, T, 30)
def implied(price, k, t):                   # bisection: Black-Scholes rises with vol
    lo, hi = 1e-4, 3.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if bs(k, R, Q, mid, t) < price else (lo, mid)
    return 0.5 * (lo + hi)
def uniform(state):                         # the house recurrence
    state = (1664525 * state + 1013904223) % MOD
    return state, (state + 0.5) / MOD
def normal(state):                          # Box-Muller, cosine half only
    state, u = uniform(state)
    state, v = uniform(state)
    return state, sqrt(-2.0 * log(u)) * cos(2.0 * pi * v)
def simulate():                             # road 4: real jump counts and sizes
    state, disc, e0 = SEED, exp(-R * T), exp(-LAM * T)
    drift = (R - Q - LAM * kbar(MUJ) - 0.5 * SIG * SIG) * T
    tot, bk = [0.0] * 4, [[0.0] * 3 for _ in range(3)]
    for _ in range(PATHS):
        n, prod = -1, 1.0
        while prod > e0:                                  # Knuth's Poisson count
            state, u = uniform(state)
            prod, n = prod * u, n + 1
        state, z = normal(state)
        x = drift + SIG * sqrt(T) * z
        for _ in range(n):
            state, zj = normal(state)
            x += MUJ + DEL * zj                           # one jump's log size
        pay, st = disc * max(S * exp(x) - K, 0.0), disc * S * exp(x)
        tot = [a + b for a, b in zip(tot, (pay, pay * pay, st, st * st))]
        if n < 3: bk[n] = [a + b for a, b in zip(bk[n], (1.0, pay, pay * pay))]
    ms = lambda a, b, c: (a / c, sqrt((b / c - (a / c) * (a / c)) / c))
    return ms(tot[0], tot[1], PATHS), ms(tot[2], tot[3], PATHS), [ms(b[1], b[2], b[0]) + (b[0],) for b in bk]
kj, fwd = kbar(MUJ), S * exp((R - Q) * T)
c1, c2, c3 = merton(), merton76(LAM * (1.0 + kj)), exp(-R * T) * poisson_sum(payoff_average, LAM, T, 30)
(mc, se), (fw, fse), bk = simulate()
put, allin = merton(put=True), sqrt(SIG * SIG + LAM * (MUJ * MUJ + DEL * DEL))
branch_row = lambda n: (Q + LAM * kj - n * log(1.0 + kj) / T, sqrt(SIG * SIG + n * DEL * DEL / T))
print("house market: S 100, K 100, r 5%, q 2%, sigma 20%, T 1 year; jumps 0.5 a year, mean -0.10, spread 0.15")
for name, v in (("typical jump multiplier e^mu_J", exp(MUJ)), ("k = e^(mu_J + delta^2/2) - 1", kj),
                ("lambda k, compensator per year", LAM * kj), ("ln(1 + k)", log(1.0 + kj)),
                ("forward S e^(r - q)T", fwd), ("average S_T without the compensator", fwd * exp(LAM * kj * T))):
    print(f"{name:<44}{v:>12.6f}")
print("  n    weight   sigma_n        q_n    BS price  contribution")
for n in range(6):
    w, (qn, sn) = poisson_sum(lambda j: float(j == n), LAM, T, n + 1), branch_row(n)
    print(f"{n:>3}  {w:.6f}  {sn:.6f}  {qn:>9.6f}  {bs(K, R, qn, sn, T):>10.6f}  {w * bs(K, R, qn, sn, T):>12.6f}")
for n in range(3):
    print(f"paths with {n} jumps: {bk[n][2]:>7.0f}  simulated {bk[n][0]:9.6f} +- {bk[n][1]:.6f}  "
          f"branch {bs(K, R, *branch_row(n), T):9.6f}")
for name, v in (("six terms, n = 0 to 5", merton(terms=6)), ("left after six terms", c1 - merton(terms=6)),
                ("chance of more than five jumps", 1.0 - poisson_sum(lambda n: 1.0, LAM, T, 6)),
                ("road 1  series, 60 terms", c1), ("road 2  Merton 1976 arrangement", c2),
                ("road 3  Simpson average over the jumps", c3), (f"road 4  simulation, {PATHS} paths", mc),
                ("        standard error", se), ("compensator: simulated average e^-rT S_T", fw),
                ("             S e^-qT", S * exp(-Q * T)), ("             standard error", fse),
                ("put by the same series", put), ("C - P", c1 - put),
                ("S e^-qT - K e^-rT", S * exp(-Q * T) - K * exp(-R * T)), ("lambda = 0 series", merton(lam=0.0)),
                ("jumps add: road 1 minus lambda = 0", c1 - merton(lam=0.0)),
                ("wrong: no compensator", merton(comp=0.0)), ("wrong: sigma not widened", merton(widen=0.0)),
                ("wrong: centre not shifted", merton(shift=0.0)), ("wrong: k = e^mu_J - 1", merton(kj=exp(MUJ) - 1.0)),
                ("wrong: plain lambda weights, 1976 rates", merton76(LAM)),
                (f"wrong: one vol, {allin * 100:.2f}%", bs(K, R, Q, allin, T)),
                ("wrong: no-jump branch only", merton(terms=1))):
    print(f"{name:<44}{v:>12.6f}")
iv = lambda k, t=T, mu=MUJ: implied(merton(k, mu=mu, t=t), k, t)      # one strike's implied vol
iv1, iv3 = [iv(k) for k in STRIKES], [iv(k, 0.25) for k in STRIKES]
print("strike             " + "".join(f"{k:>8.0f}" for k in STRIKES))
print("1 year, Merton call" + "".join(f"{merton(k):>8.3f}" for k in STRIKES))
print("1 year, one vol    " + "".join(f"{bs(k, R, Q, allin, T):>8.3f}" for k in STRIKES))
print("1 year, implied %  " + "".join(f"{v * 100:>8.2f}" for v in iv1))
print("3 months, implied %" + "".join(f"{v * 100:>8.2f}" for v in iv3))
grid = [40.0 + 10.0 * i for i in range(13)]
print("chart, price  " + " ".join(f"{x:>5.0f}" for x in grid))
print("chart, Merton " + " ".join(f"{ending(x, LAM, False):>5.2f}" for x in grid))
print("chart, 20% BS " + " ".join(f"{ending(x, 0.0, False):>5.2f}" for x in grid))
print(f"chance of ending below 70, %: Merton {ending(70.0, LAM, True):.2f}, lognormal {ending(70.0, 0.0, True):.2f}")
print(f"try: lambda = 1 {merton(lam=1.0):.6f}; two terms {merton(terms=2):.6f}; "
      f"mu_J = +0.10, implied % at 80 and 120: {iv(80.0, mu=0.1) * 100:.2f}, {iv(120.0, mu=0.1) * 100:.2f}")
assert max(abs(c2 - c1), abs(merton76(LAM * (1.0 + kj), 0.25) - merton(t=0.25))) < 1e-10, "the same sum, regrouped"
assert abs(c3 - c1) < 1e-7, "brute-force average lands on the series"
assert abs(mc - c1) < 3.0 * se < abs(mc - merton76(LAM)), "simulation backs the series, not the mix"
assert abs(fw - S * exp(-Q * T)) < 3.0 * fse, "compensated drift puts the average on the forward"
assert abs((c1 - put) - (S * exp(-Q * T) - K * exp(-R * T))) < 1e-10, "put-call parity"
assert abs(merton(lam=0.0) - 9.227005508154) < 1e-9, "no jumps: the call card's house price"
assert abs(bs(K, R, Q, iv1[3], T) - c1) < 1e-8, "the at-the-money implied vol reprices the call"
assert iv1[0] > iv1[3] > iv1[6] and iv3[1] - iv3[3] > iv1[1] - iv1[3], "a skew, steeper when short"
print("ALL CHECKS PASS")
