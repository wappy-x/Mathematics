# Extreme value theory: fit a generalised Pareto to the losses past a threshold, extrapolate the 99.9% VaR.
from math import sqrt, log, cos, acos, pi

BOOK, VOL, NU, DAYS, K, P = 10_000_000.0, 0.20, 4.0, 2520, 126, 0.999   # $10m of Acme; 20%/yr; t, 4 dof
SD = BOOK * VOL / sqrt(252.0)                     # daily sd of the dollar loss: $125,988
SCALE = SD * sqrt((NU - 2.0) / NU)                # loss = SCALE * T, T a Student t with 4 dof
M64 = (1 << 64) - 1

def tot(xs):                                      # plain left-to-right sum, the same order as Rust
    s = 0.0
    for v in xs: s += v
    return s

class Rng:                                        # splitmix64: the same stream in both languages
    def __init__(self, seed): self.s = seed
    def unif(self):                               # uniform on (0, 1]
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return 1.0 - ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def loss(self):                               # normal / sqrt(chi-square with 4 dof / 4)
        u1 = self.unif(); u2 = self.unif(); u3 = self.unif(); u4 = self.unif()
        z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
        return SCALE * z / sqrt(-2.0 * (log(u3) + log(u4)) / NU)

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + tot((4.0 if i % 2 else 2.0) * f(a + i * h) for i in range(1, n))) * h / 3.0
def bisect(g, lo, hi):                            # g changes sign once on [lo, hi]
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0) == (g(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

# ---- road 1: the true law. t density 0.375 (1 + x^2/4)^-2.5, integrated after x = 1/w ----
t_tail = lambda t: simpson(lambda w: 0.375 * w ** 3 * (w * w + 0.25) ** -2.5, 0.0, 1.0 / t)
t_mean = lambda t: simpson(lambda w: 0.375 * w * w * (w * w + 0.25) ** -2.5, 0.0, 1.0 / t)
def t_quantile(p):                                # closed form for 4 dof
    a = 4.0 * p * (1.0 - p); q = cos(acos(sqrt(a)) / 3.0) / sqrt(a)
    return 2.0 * sqrt(q - 1.0)
q_bis = bisect(lambda t: t_tail(t) - (1.0 - P), 1.0, 100.0)
q_cf = t_quantile(P)
es_int = SCALE * t_mean(q_cf) / (1.0 - P)
es_cf = SCALE * (NU + q_cf * q_cf) / (NU - 1.0) * 0.375 * (1.0 + q_cf * q_cf / 4.0) ** -2.5 / (1.0 - P)
z999 = bisect(lambda x: 0.5 - simpson(lambda s: 0.3989422804014327 * 2.718281828459045 ** (-s * s / 2), 0.0, x) - (1.0 - P), 0.0, 10.0)

# ---- road 2: the generalised Pareto fitted to one decade's exceedances ----
def fit_mle(y):                                   # profile likelihood in th = xi / beta, golden section
    k = len(y)
    xi_of = lambda th: tot(log(1.0 + th * v) for v in y) / k
    prof = lambda th: -k * log(xi_of(th) / th) - k * xi_of(th) - k
    a, b, g = -0.999 / max(y), 50.0 / (tot(y) / k), (sqrt(5.0) - 1.0) / 2.0
    for _ in range(150):
        c, d = b - g * (b - a), a + g * (b - a)
        if prof(c) > prof(d): b = d
        else: a = c
    th = 0.5 * (a + b); xi = xi_of(th)
    return xi, xi / th
def fit_pwm(y):                                   # probability-weighted moments (Hosking and Wallis)
    k = len(y); a0 = tot(y) / k
    a1 = tot((1.0 - (i + 0.65) / k) * v for i, v in enumerate(y)) / k
    return 2.0 - a0 / (a0 - 2.0 * a1), 2.0 * a0 * a1 / (a0 - 2.0 * a1)
def loglik(xi, beta, y): return -len(y) * log(beta) - (1.0 + 1.0 / xi) * tot(log(1.0 + xi * v / beta) for v in y)
def gpd_var(u, xi, beta, frac, p): return u + beta / xi * (((1.0 - p) / frac) ** -xi - 1.0)
def gpd_es(var, u, xi, beta): return (var + beta - xi * u) / (1.0 - xi)
def split(losses, k):                             # sorted losses, threshold, sorted excesses
    s = sorted(losses); n = len(s); u = s[n - k - 1]
    return s, u, [v - u for v in s[n - k:]]
def sample_sd(x): m = tot(x) / len(x); return sqrt(tot((v - m) * (v - m) for v in x) / (len(x) - 1))
HIST = -(-DAYS * 999 // 1000) - 1                 # 0-based rank of the 99.9% historical loss

rng = Rng(20260928)
losses = [rng.loss() for _ in range(DAYS)]
s, u, y = split(losses, K)
xi, beta = fit_mle(y); xp, bp = fit_pwm(y); frac = K / DAYS
v_evt = gpd_var(u, xi, beta, frac, P)
tail = lambda x: frac * (1.0 + xi * (x - u) / beta) ** (-1.0 / xi)
v_bis = bisect(lambda x: tail(x) - (1.0 - P), u, u + 1e8)
es_evt = gpd_es(v_evt, u, xi, beta)
es_evt_int = v_evt + simpson(lambda w: 0.0 if w == 0 else tail(v_evt / w) * v_evt / (w * w), 0.0, 1.0) / (1.0 - P)
sd = sample_sd(losses); v_true = SCALE * q_cf; v_norm = z999 * sd
h1, h2 = 1e-6, 1e-6 * beta
g_xi = (loglik(xi + h1, beta, y) - loglik(xi - h1, beta, y)) / (2 * h1)
g_beta = beta * (loglik(xi, beta + h2, y) - loglik(xi, beta - h2, y)) / (2 * h2)

rows = [("daily sd, the law", SD), ("true tail index xi = 1/nu", 1.0 / NU), ("expected days past VaR in 2520", DAYS * (1.0 - P)),
    ("hand: k/n", frac), ("hand: (1-p)/(k/n)", (1.0 - P) / frac), ("hand: ((1-p)/(k/n))^-xi", ((1.0 - P) / frac) ** -xi),
    ("hand: beta/xi", beta / xi), ("hand: beta - xi u", beta - xi * u), ("daily sd, sample", sd), ("largest loss in the decade", s[-1]), ("threshold u, 127th largest", u),
    ("MLE xi", xi), ("MLE beta", beta), ("PWM xi", xp), ("PWM beta", bp),
    ("MLE score d/dxi", g_xi), ("MLE score beta d/dbeta", g_beta),
    ("true t quantile, bisection", q_bis), ("true t quantile, closed form", q_cf),
    ("normal quantile z, bisection", z999),
    ("VaR true law", v_true), ("VaR normal, sample sd", v_norm), ("VaR historical, 3rd largest", s[HIST]),
    ("VaR EVT, MLE formula", v_evt), ("VaR EVT, MLE by bisection", v_bis), ("VaR EVT, PWM", gpd_var(u, xp, bp, frac, P)),
    ("ES true law, integral", es_int), ("ES true law, closed form", es_cf),
    ("ES EVT, formula", es_evt), ("ES EVT, integral", es_evt_int),
    ("ES normal, sample sd", sd * 0.3989422804014327 * 2.718281828459045 ** (-z999 * z999 / 2) / (1.0 - P)),
    ("wrong: 0.001 used inside the tail", gpd_var(u, xi, beta, 1.0, P)),
    ("wrong: exponential tail, xi = 0", u + tot(y) / K * log(frac / (1.0 - P))),
    ("wrong: 99% historical times 3.09/2.33", s[-(-DAYS * 99 // 100) - 1] * z999 / 2.3263478740408408)]
for k2 in (50, 252):
    _, u2, y2 = split(losses, k2); x2, b2 = fit_mle(y2)
    rows += [(f"try: k = {k2}, xi", x2), (f"try: k = {k2}, VaR EVT", gpd_var(u2, x2, b2, k2 / DAYS, P))]
rows += [("try: 99.99% VaR EVT", gpd_var(u, xi, beta, frac, 0.9999)), ("try: 99.99% VaR true", SCALE * t_quantile(0.9999))]
for name, v in rows: print(f"{name:<40} {v:>14.6f}")
past = [sum(1 for v in losses if v > lim) for lim in (v_true, v_norm, v_evt)]
print(f"days past VaR in the decade: true {past[0]}, normal {past[1]}, EVT {past[2]}")

print("bars, 99.9% VaR ($)" + "".join(f" {v:.2f}" for v in (v_norm, v_evt, gpd_var(u, xp, bp, frac, P), v_true, s[HIST])))
# ---- chart: VaR in $ thousands at five levels ----
LEVELS = (0.99, 0.995, 0.999, 0.9995, 0.9999)
zs = [bisect(lambda x: 0.5 - simpson(lambda s_: 0.3989422804014327 * 2.718281828459045 ** (-s_ * s_ / 2), 0.0, x) - (1.0 - p), 0.0, 10.0) for p in LEVELS]
print("chart, level     " + "".join(f"{p * 100:>10.2f}" for p in LEVELS))
print("chart, true      " + "".join(f"{SCALE * t_quantile(p) / 1000:>10.2f}" for p in LEVELS))
print("chart, EVT       " + "".join(f"{gpd_var(u, xi, beta, frac, p) / 1000:>10.2f}" for p in LEVELS))
print("chart, normal    " + "".join(f"{z * sd / 1000:>10.2f}" for z in zs))

# ---- road 3: 400 independent decades, the card's decade first ----
rng = Rng(20260928); err = [[0.0, 0.0] for _ in range(4)]; M = 400
for m in range(M):
    L = [rng.loss() for _ in range(DAYS)]; s_, u_, y_ = split(L, K)
    x_, b_ = fit_mle(y_); xq, bq = fit_pwm(y_)
    est = (z999 * sample_sd(L), s_[HIST], gpd_var(u_, x_, b_, frac, P), gpd_var(u_, xq, bq, frac, P))
    for j in range(4):
        err[j][0] += est[j] / M; err[j][1] += (est[j] - v_true) * (est[j] - v_true) / M
for j, name in enumerate(("normal", "historical", "EVT MLE", "EVT PWM")):
    print(f"study, {name:<11} mean {err[j][0]:>12.2f}   root mean square error {sqrt(err[j][1]):>11.2f}")

assert abs(q_bis - q_cf) < 1e-9,              "true quantile: Simpson + bisection vs closed form"
assert abs(es_int - es_cf) < 1e-3,            "true ES: integral vs closed form"
assert abs(v_evt - v_bis) < 1e-6,             "EVT VaR: formula vs inverting the fitted tail"
assert abs(es_evt - es_evt_int) < 1e-3,       "EVT ES: mean-excess formula vs integrating the fitted tail"
assert abs(g_xi) < 1e-3,                     "fitted xi is a stationary point of the likelihood"
assert abs(g_beta) < 1e-3,                   "fitted beta is a stationary point of the likelihood"
assert sqrt(err[2][1]) < sqrt(err[1][1]),     "EVT beats the raw historical estimate over 400 decades"
assert abs(z999 - 3.090232306167813) < 1e-9,  "normal 99.9% point vs its tabulated value"
print("ALL CHECKS PASS")
