# The reference distributions -- the check behind the card.  Nothing imported holds the answer.
# Ten bags from a filling machine labelled 500 g, spread unknown; seven bags from a second machine.
# Roads: closed forms (a normal series, finite sums for chi-square, t and F); Simpson's rule on the
# densities; a seeded simulation that weighs whole samples and never uses a chi-square, t or F formula.
from math import exp, log, sqrt, pi, atan, sin, cos

A = [507, 498, 505, 500, 503, 502, 501, 497, 505, 502]   # machine one, grams
B = [503, 498, 501, 498, 502, 499, 499]                  # machine two, grams
LABEL, SIGMA = 500.0, 3.0                                # the label; a spread to test against

def summary(xs):                             # size, mean, sample variance with n - 1
    m = sum(xs) / len(xs)
    return len(xs), m, sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
def phi(x):                                  # the standard normal density
    return exp(-x * x / 2) / sqrt(2 * pi)
def Phi(x):                                  # 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    term = s = x
    for j in range(1, 200):
        term *= x * x / (2 * j + 1)
        s += term
    return 0.5 + phi(x) * s
def gam(h2):                                 # Gamma(h2 / 2), for a whole number h2 >= 1
    g, h = (sqrt(pi), 0.5) if h2 % 2 else (1.0, 1.0)
    while h < h2 / 2:
        g, h = g * h, h + 1
    return g
def chi_d(x, k):                             # chi-square density: Gamma(k/2, rate 1/2)
    return x ** (k / 2 - 1) * exp(-x / 2) / (2 ** (k / 2) * gam(k))
def t_d(t, v):
    return gam(v + 1) / (sqrt(v * pi) * gam(v)) * (1 + t * t / v) ** (-(v + 1) / 2)
def f_d(x, v1, v2):                          # F density, with c = v1 / v2
    return gam(v1 + v2) / (gam(v1) * gam(v2)) * (v1 / v2) ** (v1 / 2) * x ** (v1 / 2 - 1) * (1 + v1 * x / v2) ** (-(v1 + v2) / 2)
def chi_tail(x, k):                          # P(V > x): Poisson sum (even k), normal road (odd k)
    if k % 2 == 0:
        term = s = 1.0
        for j in range(1, k // 2):
            term *= x / 2 / j
            s += term
        return exp(-x / 2) * s
    term, s = sqrt(x), 0.0
    for r in range(1, (k - 1) // 2 + 1):
        s += term
        term *= x / (2 * r + 1)
    return 2 * (1 - Phi(sqrt(x))) + 2 * phi(sqrt(x)) * s
def t_tail2(t, v):                           # P(|T| > t), odd v, through the angle atan(t / sqrt v)
    th = atan(t / sqrt(v))
    c, w, s = cos(th), 1.0, 0.0
    for j in range((v - 1) // 2):
        s += w * c ** (2 * j + 1)
        w *= (2 * j + 2) / (2 * j + 3)
    return 1 - 2 / pi * (th + sin(th) * s)
def beta_cdf(y, a, b):                       # needs a whole number a or b
    if b != int(b):
        return 1 - beta_cdf(1 - y, b, a)
    term = s = 1.0
    for j in range(1, int(b)):
        term *= (a + j - 1) / j * (1 - y)
        s += term
    return y ** a * s
def f_tail(x, v1, v2):                       # P(F > x), through the beta variable cF / (1 + cF)
    return 1 - beta_cdf(v1 * x / (v2 + v1 * x), v1 / 2, v2 / 2)
def simpson(g, lo, hi, n=4000):
    h = (hi - lo) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(lo + i * h) for i in range(n + 1))
def bisect(g, target, lo, hi):               # g decreasing
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) > target else (lo, mid)
    return (lo + hi) / 2
MASK, state = (1 << 64) - 1, 20260928        # SplitMix64, seed 20260928
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def normals(k):                              # Box-Muller, two at a time
    out = []
    while len(out) < k:
        r, a = sqrt(-2 * log(uniform())), 2 * pi * uniform()
        out += [r * cos(a), r * sin(a)]
    return out[:k]

n, m, s2 = summary(A)
nb, mb, s2b = summary(B)
se = sqrt(s2 / n)
t_obs, q_obs, f_obs = (m - LABEL) / se, (n - 1) * s2 / SIGMA ** 2, s2 / s2b
print(f"machine one: n {n}, mean {m:.3f}, squared residuals {s2 * (n - 1):.1f}, S^2 {s2:.3f}, S {sqrt(s2):.3f}, S/sqrt(n) {se:.3f}")
print(f"machine two: n {nb}, mean {mb:.3f}, squared residuals {s2b * (nb - 1):.1f}, S^2 {s2b:.3f}")
print(f"observed: t {t_obs:.3f} on 9; V = 9 S^2/3^2 {q_obs:.3f} on 9; F = S1^2/S2^2 {f_obs:.3f} on (9, 6)")
p_t, p_q, p_f = t_tail2(t_obs, 9), chi_tail(q_obs, 9), f_tail(f_obs, 9, 6)
s_t = 1 - 2 * simpson(lambda x: t_d(x, 9), 0.0, t_obs)
s_q = 1 - simpson(lambda x: chi_d(x, 9), 0.0, q_obs)
s_f = 1 - simpson(lambda x: f_d(x, 9, 6), 0.0, f_obs)
print(f"P(|T| > 2) on 9: closed form {p_t:.4f}; Simpson {s_t:.4f}; normal instead {2 * (1 - Phi(2.0)):.4f}")
print(f"P(V > 10) on 9: closed form {p_q:.4f}; Simpson {s_q:.4f}. P(F > 2.5) on (9, 6): beta sum {p_f:.4f}; Simpson {s_f:.4f}")
print(f"Gamma(1/2) {gam(1):.6f}; Gamma(9/2) {gam(9):.6f}; area under t on 9 {2 * simpson(lambda x: t_d(x, 9), 0.0, 60.0):.6f}")
q_t = bisect(lambda x: t_tail2(x, 9), 0.05, 0.0, 20.0)
q_lo, q_hi = bisect(lambda x: chi_tail(x, 9), 0.975, 0.0, 60.0), bisect(lambda x: chi_tail(x, 9), 0.025, 0.0, 60.0)
q_95, f_95 = bisect(lambda x: chi_tail(x, 9), 0.05, 0.0, 60.0), bisect(lambda x: f_tail(x, 9, 6), 0.05, 0.0, 60.0)
print(f"cutoffs: t on 9, 2.5% each side {q_t:.3f}; normal {bisect(lambda x: 2 * (1 - Phi(x)), 0.05, 0.0, 10.0):.3f}")
print(f"cutoffs: chi-square 9, middle 95% {q_lo:.3f} to {q_hi:.3f}, top 5% {q_95:.3f}; F (9, 6) top 5% {f_95:.3f}")
print(f"P(|T| > 1.96): t on 9 {t_tail2(1.96, 9):.4f}; t on 1 (Cauchy) P(|T| > 2) {t_tail2(2.0, 1):.4f}")
N = 100_000
c_t = c_z = c_q = c_f = c_sk = c_st = 0
sq = sq2 = st2 = st4 = sf = sf2 = 0.0
for _ in range(N):
    _, ma, va = summary([LABEL + SIGMA * z for z in normals(10)])
    _, _, vb = summary([LABEL + SIGMA * z for z in normals(7)])
    _, me, ve = summary([LABEL - SIGMA - SIGMA * log(uniform()) for _ in range(10)])
    t, q, f = (ma - LABEL) / sqrt(va / 10), 9 * va / SIGMA ** 2, va / vb
    c_t, c_z, c_q, c_f = c_t + (abs(t) > 2), c_z + (abs(t) > 1.96), c_q + (q > 10), c_f + (f > 2.5)
    c_sk, c_st = c_sk + (9 * ve / SIGMA ** 2 > q_95), c_st + (abs((me - LABEL) / sqrt(ve / 10)) > q_t)
    sq, sq2, st2, st4, sf, sf2 = sq + q, sq2 + q * q, st2 + t * t, st4 + t ** 4, sf + f, sf2 + f * f
est = lambda c: (c / N, sqrt(c / N * (1 - c / N) / N))   # a share and its standard error
(r_t, e_t), (r_z, e_z), (r_q, e_q), (r_f, e_f), (r_sk, e_sk), (r_st, e_st) = map(est, (c_t, c_z, c_q, c_f, c_sk, c_st))
mq, vq = sq / N, sq2 / N - (sq / N) ** 2
mt2, et2, mf, ef = st2 / N, sqrt((st4 / N - (st2 / N) ** 2) / N), sf / N, sqrt((sf2 / N - (sf / N) ** 2) / N)
print(f"simulated {N} rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)")
print(f"  P(|T| > 2) {r_t:.4f} ({e_t:.4f}); P(V > 10) {r_q:.4f} ({e_q:.4f}); P(F > 2.5) {r_f:.4f} ({e_f:.4f})")
print(f"  V: mean {mq:.3f} ({sqrt(vq / N):.3f}), variance {vq:.3f}; T: mean square {mt2:.4f} ({et2:.4f}), formula 9/7 = {9 / 7:.4f}; F: mean {mf:.4f} ({ef:.4f}), formula 6/4 = {6 / 4:.4f}")
print(f"mistake, cutoff 1.96 with an estimated spread: true label rejected {r_z:.4f} ({e_z:.4f}), closed form {t_tail2(1.96, 9):.4f}")
print(f"mistake, 10 degrees of freedom for 9: P(V > 10) {chi_tail(10.0, 10):.4f}, not {p_q:.4f}")
print(f"mistake, F read on (6, 9) for (9, 6): P(F > 2.5) {f_tail(2.5, 6, 9):.4f}, not {p_f:.4f}")
print(f"mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects {r_sk:.4f} ({e_sk:.4f}); 5% t test {r_st:.4f} ({e_st:.4f})")
xs = [0.5 * i for i in range(-8, 9)]
print("figure, t: " + ", ".join(f"{x:.1f}" for x in xs))
print("figure, normal: " + ", ".join(f"{phi(x):.2f}" for x in xs))
print("figure, t on 9: " + ", ".join(f"{t_d(x, 9):.2f}" for x in xs))
print("figure, t on 2: " + ", ".join(f"{t_d(x, 2):.2f}" for x in xs))
vs = [2.0 * i for i in range(13)]
print("figure, v: " + ", ".join(f"{v:.0f}" for v in vs))
for k in (3, 9):
    print(f"figure, chi-square {k}: " + ", ".join(f"{chi_d(v, k):.2f}" for v in vs))
assert abs(p_t - s_t) < 1e-9 and abs(p_q - s_q) < 1e-9 and abs(p_f - s_f) < 1e-9   # closed forms against Simpson
assert abs(chi_tail(10.0, 10) - (1 - simpson(lambda x: chi_d(x, 10), 0.0, 10.0))) < 1e-9 and abs(f_tail(2.5, 6, 9) - (1 - simpson(lambda x: f_d(x, 6, 9), 0.0, 2.5))) < 1e-9
assert abs(r_t - p_t) < 4 * e_t and abs(r_q - p_q) < 4 * e_q and abs(r_f - p_f) < 4 * e_f
assert abs(mq - 9) < 4 * sqrt(vq / N) and abs(vq - 18) < 0.42   # nine squares: mean 9, variance 18 (SE 0.104)
assert abs(r_z - t_tail2(1.96, 9)) < 4 * e_z and abs(mt2 - 9 / 7) < 4 * et2 and abs(mf - 1.5) < 4 * ef and r_sk - 0.05 > 4 * e_sk and r_st - 0.05 > 4 * e_st
print("ALL CHECKS PASS")
