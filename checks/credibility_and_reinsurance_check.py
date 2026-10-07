# Credibility and reinsurance -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Poisson probabilities, the
# integrator and the random numbers are all written out below.
from math import exp, sqrt

def pois(lam, K):                          # Poisson probabilities P(0..K), built by the ratio rule
    p = [exp(-lam)]
    for k in range(1, K + 1): p.append(p[-1] * lam / k)
    return p

class LCG:                                 # 64-bit linear congruential generator, uniform on [0, 1)
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s * 6364136223846793005 + 1442695040888963407) % 2**64
        return (self.s >> 11) / 2.0**53
    def poisson(self, lam):                # inversion: walk up the cumulative probabilities
        u, k, p = self.u(), 0, exp(-lam)
        c = p
        while u > c:
            k += 1; p *= lam / k; c += p
        return k

# ---- credibility: two equally likely fleet types, 1 or 3 claims a year on average ----
TYPES, YEARS, n = (1.0, 3.0), (1, 1, 2), 3
mu = sum(TYPES) / 2                                  # class mean
a = sum((t - mu) ** 2 for t in TYPES) / 2            # variance of hypothetical means
s = mu                                               # expected process variance (Poisson: variance = mean)
Z = n / (n + s / a)                                  # road 1: the formula
xbar = sum(YEARS) / n
cred = Z * xbar + (1 - Z) * mu
def Zof(n, a, s): return n / (n + s / a)

# road 2: enumerate the whole joint law of (type, three yearly counts), counts 0..30
K = 30; P = [pois(t, K) for t in TYPES]
Ex = Exx = Etx = m_cls = m_flt = m_crd = m_bay = 0.0
for i in range(K + 1):
    for j in range(K + 1):
        for k in range(K + 1):
            w = [0.5 * P[t][i] * P[t][j] * P[t][k] for t in (0, 1)]
            xb = (i + j + k) / 3.0
            post = (w[0] * TYPES[0] + w[1] * TYPES[1]) / (w[0] + w[1])
            for t in (0, 1):
                th = TYPES[t]
                Ex += w[t] * xb; Exx += w[t] * xb * xb; Etx += w[t] * th * xb
                m_cls += w[t] * (th - mu) ** 2; m_flt += w[t] * (th - xb) ** 2
                m_crd += w[t] * (th - Z * xb - (1 - Z) * mu) ** 2; m_bay += w[t] * (th - post) ** 2
Z_enum = (Etx - mu * Ex) / (Exx - Ex * Ex)           # least-squares slope from the joint law
lik = [t ** 4 * exp(-3 * t) for t in TYPES]          # likelihood of counts 1, 1, 2 (common factors cancel)
bayes = (lik[0] * TYPES[0] + lik[1] * TYPES[1]) / (lik[0] + lik[1])

# road 3: simulate 100,000 fleets for four years; regress year 4 on the first three
g = LCG(20260928); F = 100000; sx = sy = sxx = sxy = 0.0
for _ in range(F):
    th = TYPES[0] if g.u() < 0.5 else TYPES[1]
    xb = sum(g.poisson(th) for _ in range(3)) / 3.0; y = g.poisson(th)
    sx += xb; sy += y; sxx += xb * xb; sxy += xb * y
Z_sim = (sxy / F - sx / F * sy / F) / (sxx / F - (sx / F) ** 2)

# normal-normal: prior N(2, 1) for the fleet mean, years N(theta, 2); posterior mean by Simpson
def simpson(f, lo, hi, m=4000):
    h = (hi - lo) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(lo + i * h) for i in range(m + 1))
dens = lambda th: exp(-(th - mu) ** 2 / (2 * a) - sum((x - th) ** 2 for x in YEARS) / (2 * s))
nn_post = simpson(lambda th: th * dens(th), -10, 14) / simpson(dens, -10, 14)

# ---- reinsurance: lam claims a year, each $1,000 or $4,000 with equal chance (money in $000) ----
lam, d, D, SEV = cred, 2.0, 3.0, (1.0, 4.0)
def xl_formula(lam, d): return lam * sum(max(y - d, 0.0) for y in SEV) / 2
def sl_formula(lam, D):                    # E(S-D)+ = E S - D + sum over totals below D of (D - k) P(S = k)
    p0 = exp(-lam); below = [p0, p0 * lam / 2, p0 * lam * lam / 8]    # S = 0, 1, 2 (only $1,000 claims fit)
    return lam * 2.5 - D + sum((D - k) * below[k] for k in range(3) if k < D)
def s_law(lam, NMAX=40):                   # exact law of the annual total S, by counts and binomial splits
    pn, law = pois(lam, NMAX), [0.0] * (4 * NMAX + 1)
    for nn in range(NMAX + 1):
        c = 1.0
        for b in range(nn + 1):            # b of the nn claims are $4,000 ones
            law[nn + 3 * b] += pn[nn] * c / 2 ** nn
            c = c * (nn - b) / (b + 1)
    return law
law = s_law(lam)
sl_enum = sum(max(k - D, 0.0) * p for k, p in enumerate(law))
surv = lambda t: sum(p for k, p in enumerate(law) if k > t)
sl_surv = sum(surv(t) for t in range(int(D), len(law)))              # integral of P(S > t) above D, unit steps
xl_surv = lam * sum(sum(0.5 for y in SEV if y > t) for t in range(int(d), 4))    # P(Y > t) above d, unit steps
g = LCG(7); Y = 200000; xs = ss = 0.0
for _ in range(Y):
    sizes = [1.0 if g.u() < 0.5 else 4.0 for _ in range(g.poisson(lam))]
    xs += sum(max(y - d, 0.0) for y in sizes); ss += max(sum(sizes) - D, 0.0)

rows = [("class mean mu", mu), ("VHM a", a), ("EPV s", s), ("k = s/a", s / a), ("1 Z formula", Z),
    ("2 Z from joint law", Z_enum), ("3 Z by simulation", Z_sim), ("fleet mean xbar", xbar),
    ("credibility forecast", cred), ("normal-normal posterior", nn_post), ("two-type Bayes posterior", bayes),
    ("MSE class mean only", m_cls), ("MSE fleet mean only", m_flt), ("MSE credibility", m_crd),
    ("  formula a(1-Z)", a * (1 - Z)), ("MSE two-type Bayes", m_bay),
    ("XL d=2 formula", xl_formula(lam, d)), ("XL d=2 survival sum", xl_surv), ("XL d=2 simulation", xs / Y),
    ("SL D=3 formula", sl_formula(lam, D)), ("SL D=3 exact law", sl_enum), ("SL D=3 survival sum", sl_surv),
    ("SL D=3 simulation", ss / Y), ("P(S=0)", law[0]), ("P(S=1)", law[1]), ("P(S=2)", law[2]), ("E S", lam * 2.5),
    ("layer 1 xs 2 per claim", lam * 0.5),
    ("wrong: Z = n/(n+a/s)", n / (n + a / s)), ("  its forecast", n / (n + a / s) * xbar + (1 - n / (n + a / s)) * mu),
    ("wrong: SL as lam*E(Y-D)+", xl_formula(lam, D)), ("wrong: SL as E S - D", lam * 2.5 - D),
    ("wrong: XL at class mean 2", xl_formula(mu, d)), ("wrong: SL at class mean 2", sl_formula(mu, D)),
    ("try: Z with n = 10", Zof(10, a, s)), ("try: Z with types 1.5, 2.5", Zof(3, 0.25, s)),
    ("try: SL D=5", sum(max(k - 5, 0.0) * p for k, p in enumerate(law)))]
for name, v in rows: print(f"{name:<28} {v:>12.6f}")
print("chart, years n      " + " ".join(f"{m:5d}" for m in range(1, 11)))
print("chart, Z            " + " ".join(f"{Zof(m, a, s):5.2f}" for m in range(1, 11)))
print("chart, retention    " + " ".join(f"{t:5d}" for t in range(0, 9)))
print("chart, SL premium   " + " ".join(f"{sum(max(k - t, 0.0) * p for k, p in enumerate(law)):5.2f}" for t in range(9)))
print("chart, XL premium   " + " ".join(f"{xl_formula(lam, t):5.2f}" for t in range(9)))

assert abs(Z_enum - Z) < 1e-9,                           "joint-law slope must equal the formula's Z"
assert abs(m_crd - a * (1 - Z)) < 1e-9,                  "enumerated error must equal a(1 - Z)"
assert abs(Z_sim - Z) < 0.02,                            "simulated slope near Z"
assert abs(nn_post - cred) < 1e-9,                       "normal-normal posterior equals the credibility forecast"
assert abs(sl_enum - sl_formula(lam, D)) < 1e-12,        "stop-loss: exact law vs formula"
assert abs(sl_surv - sl_enum) < 1e-12,                   "stop-loss: survival sum vs exact law"
assert abs(xl_surv - xl_formula(lam, d)) < 1e-12,        "excess of loss: survival sum vs formula"
assert abs(xs / Y - xl_formula(lam, d)) < 0.02,          "excess of loss: simulation"
assert abs(ss / Y - sl_enum) < 0.03,                     "stop-loss: simulation"
assert m_bay < m_crd,                                    "full Bayes beats the best straight line"
print("ALL CHECKS PASS")
