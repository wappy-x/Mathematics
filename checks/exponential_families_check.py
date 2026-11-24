# Exponential families -- the check behind the card.  Standard library only.
# Four laws written as h(x) exp(eta*T(x) - A(eta)).  Three roads to each mean
# and variance: A's derivatives in closed form, A built by brute force from its
# definition (a sum or a Simpson integral) and differentiated numerically, and
# the moments summed or integrated straight from the usual formula of the law.
from math import exp, log, sqrt, pi

LF = [0.0]                                   # log factorials, built by adding logs
for k in range(1, 1001):
    LF.append(LF[-1] + log(k))

def simpson(f, a, b, n=20000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def logsumexp(v):
    m = max(v)
    return m + log(sum(exp(x - m) for x in v))

LAM, N, P, MU, SIG, K, B = 12.0, 1000, 0.52, 0.05, 1.2, 3, 12.0
# A(eta) = log of the total of h(x) e^(eta x): the definition, done by brute force
def A_pois(e):  return logsumexp([e * x - LF[x] for x in range(200)])
def A_binom(e): return logsumexp([e * x + LF[N] - LF[x] - LF[N - x] for x in range(N + 1)])
def A_norm(e):  return log(simpson(lambda x: exp(e * x - x * x / (2 * SIG * SIG)) / sqrt(2 * pi * SIG * SIG), -20.0, 20.0))
def A_gamma(e): return log(simpson(lambda x: x ** (K - 1) * exp(e * x) / exp(LF[K - 1]), 0.0, 6.0))

def d1(A, e, h=1e-3): return (A(e + h) - A(e - h)) / (2 * h)
def d2(A, e, h=1e-3): return (A(e + h) - 2 * A(e) + A(e - h)) / (h * h)

def disc_moments(pmf, xs):
    m = sum(x * pmf(x) for x in xs)
    return m, sum((x - m) ** 2 * pmf(x) for x in xs)
def cont_moments(f, a, b):
    m = simpson(lambda x: x * f(x), a, b)
    return m, simpson(lambda x: (x - m) ** 2 * f(x), a, b)

pois = lambda x: exp(-LAM + x * log(LAM) - LF[x])                  # the usual formulas
binom = lambda x: exp(LF[N] - LF[x] - LF[N - x] + x * log(P) + (N - x) * log(1 - P))
norm = lambda x: exp(-(x - MU) ** 2 / (2 * SIG * SIG)) / sqrt(2 * pi * SIG * SIG)
gam = lambda x: B ** K * x ** (K - 1) * exp(-B * x) / exp(LF[K - 1])

laws = [  # name, eta, brute A, closed A'(eta), closed A''(eta), moments from the usual formula
    ("Poisson help desk", log(LAM), A_pois, LAM, LAM, disc_moments(pois, range(200))),
    ("binomial poll", log(P / (1 - P)), A_binom, N * P, N * P * (1 - P), disc_moments(binom, range(N + 1))),
    ("normal return", MU / SIG ** 2, A_norm, MU, SIG ** 2, cont_moments(norm, -20.0, 20.0)),
    ("gamma wait (h)", -B, A_gamma, -K / (-B), K / B ** 2, cont_moments(gam, 0.0, 6.0)),
]
eta = log(LAM)
print("help desk, Poisson with mean 12: eta = log 12".ljust(44) + f"{eta:12.6f}")
print("A(eta) = e^eta".ljust(44) + f"{exp(eta):12.6f}")
print("A(eta) by brute sum of e^(eta x)/x!".ljust(44) + f"{A_pois(eta):12.6f}")
mgf_sum = sum(exp(0.1 * x) * pois(x) for x in range(200))
print("mgf at t=0.1: sum of e^(tx) p(x)".ljust(44) + f"{mgf_sum:12.6f}")
print("mgf at t=0.1: exp(A(eta+t) - A(eta))".ljust(44) + f"{exp(exp(eta + 0.1) - exp(eta)):12.6f}")
print("law                     eta    A' closed  A' numeric  mean summed A'' closed A'' numeric   var summed")
for name, e, A, m, v, (bm, bv) in laws:
    nm, nv = d1(A, e), d2(A, e)
    print(f"{name:<18}{e:9.4f}" + "".join(f"{z:12.4f}" for z in (m, nm, bm, v, nv, bv)))
    assert abs(nm - m) < 1e-4 * max(1, abs(m)) and abs(bm - m) < 1e-6 * max(1, abs(m)), name + " mean"
    assert abs(nv - v) < 1e-4 * max(1, v) and abs(bv - v) < 1e-6 * max(1, v), name + " variance"
print("poll standard error sqrt(A'')/1000".ljust(44) + f"{sqrt(N * P * (1 - P)) / N:12.6f}")
print("gamma wait in minutes: mean, sd".ljust(44) + f"{60 * K / B:12.4f}{60 * sqrt(K) / B:12.4f}")

hours = [11, 14, 9, 12, 15, 10, 13, 12]          # eight observed hours, total 96
other = [6, 18, 12, 12, 20, 4, 12, 12]           # a different week, same total 96
def loglik(data, e): return sum(x * e - exp(e) - LF[x] for x in data)
lo, hi, g = 1.0, 40.0, (sqrt(5) - 1) / 2         # golden-section search on lambda, no calculus
for _ in range(200):
    a, b = hi - g * (hi - lo), lo + g * (hi - lo)
    if loglik(hours, log(a)) < loglik(hours, log(b)): lo = a
    else: hi = b
lam_hat = (lo + hi) / 2
xbar = sum(hours) / len(hours)
curv = (loglik(hours, log(lam_hat) + 1e-3) - 2 * loglik(hours, log(lam_hat)) + loglik(hours, log(lam_hat) - 1e-3)) / 1e-6
print("eight hours " + " ".join(map(str, hours)) + ", total " + str(sum(hours)))
print("MLE of lambda by golden-section search".ljust(44) + f"{lam_hat:12.6f}")
print("sample mean, where A'(eta) = mean of x".ljust(44) + f"{xbar:12.6f}")
print("eta-hat = log of the MLE".ljust(44) + f"{log(lam_hat):12.6f}")
print("curvature of log-lik at eta-hat, numeric".ljust(44) + f"{curv:12.4f}")
print("curvature, -n A''(eta-hat) = -8 x 12".ljust(44) + f"{-len(hours) * xbar:12.4f}")
gaps = [loglik(hours, e) - loglik(other, e) for e in (1.0, 2.0, 2.5, 3.0)]
print("log-lik gap to week 2, eta = 1, 2, 2.5, 3  " + " ".join(f"{z:.6f}" for z in gaps))
assert abs(lam_hat - xbar) < 1e-6, "MLE must match the mean (moment matching)"
assert abs(curv + len(hours) * xbar) < 1e-3, "curvature must be -n A''"
assert all(d2(lambda e: loglik(hours, e), e) < 0 for e in (-2.0, 0.0, 2.0, 4.0)), "log-lik concave"
assert max(gaps) - min(gaps) < 1e-9, "only the total matters: gap must not depend on eta"

a0, b0, counts, spans = 24.0, 2.0, (28, 17), (2.0, 1.0)  # gamma prior; 28 emails in 2 h, 17 in 1 h
a1, b1 = a0 + sum(counts), b0 + sum(spans)
def post(l):  # prior density times both Poisson chances, written in the usual way
    if l <= 0: return 0.0
    w = a0 * log(b0) + (a0 - 1) * log(l) - b0 * l - LF[int(a0) - 1]
    for c, t in zip(counts, spans):
        w += -t * l + c * log(t * l) - LF[c]
    return exp(w)
Z = simpson(post, 0.0, 60.0)
pm = simpson(lambda l: l * post(l), 0.0, 60.0) / Z
psd = sqrt(simpson(lambda l: (l - pm) ** 2 * post(l), 0.0, 60.0) / Z)
print("posterior shape, rate: 24+45, 2+3".ljust(44) + f"{a1:12.4f}{b1:12.4f}")
print("posterior mean: shape/rate".ljust(44) + f"{a1 / b1:12.6f}")
print("posterior mean: brute-force integral".ljust(44) + f"{pm:12.6f}")
print("posterior sd: sqrt(shape)/rate".ljust(44) + f"{sqrt(a1) / b1:12.6f}")
print("posterior sd: brute-force integral".ljust(44) + f"{psd:12.6f}")
assert abs(pm - a1 / b1) < 1e-6 and abs(psd - sqrt(a1) / b1) < 1e-6, "conjugate update"

print("wrong: differentiate A = lambda in lambda".ljust(44) + f"{d1(lambda l: l, LAM):12.6f}")
print("wrong: p = 0.52 put where the log-odds goes".ljust(44) + f"{N * exp(P) / (1 + exp(P)):12.6f}")
print("wrong: gamma with eta = +12".ljust(44) + f"{-K / B:12.6f}")
print("wrong: add the emails, forget the hours".ljust(44) + f"{a1 / b0:12.6f}")
print("try: mean 3: eta, A', A''".ljust(44) + "".join(f"{z:12.6f}" for z in (log(3), d1(A_pois, log(3)), d2(A_pois, log(3)))))
print("try: poll at 50%: eta, A''".ljust(44) + f"{0.0:12.4f}{d2(A_binom, 0.0):12.4f}")
print("try: prior shape 240, rate 20: post. mean".ljust(44) + f"{(240 + 45) / (20 + 3):12.6f}")
print("try: gamma shape 1: mean, variance (h)".ljust(44) + f"{1 / B:12.6f}{1 / B ** 2:12.6f}")
grid = [eta + 0.2 * k for k in range(-4, 5)]
print("chart, eta     " + " ".join(f"{e:6.2f}" for e in grid))
print("chart, A(eta)  " + " ".join(f"{A_pois(e):6.2f}" for e in grid))
print("chart, tangent " + " ".join(f"{LAM + LAM * (e - eta):6.2f}" for e in grid))
print("ALL CHECKS PASS")
