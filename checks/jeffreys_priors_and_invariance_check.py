# Jeffreys priors -- the check behind the card.  Standard library: math only.
# Fisher information is found by brute force (finite-difference score, squared,
# averaged over outcomes), in three ways of writing the coin's chance.  Each
# posterior is found twice: by the conjugate formula, and by a grid integral on
# the scale where the information is constant.  The coin also gets a simulation.
from math import sqrt, log, exp, sin, asin, pi, lgamma

def midpoint(f, a, b, m=20000):                 # area under f from a to b
    h = (b - a) / m
    return h * sum(f(a + (i + 0.5) * h) for i in range(m))

def info(loglik, t, outcomes, d=1e-5):          # average squared score at t
    return sum(p * ((loglik(t + d, x) - loglik(t - d, x)) / (2 * d)) ** 2 for x, p in outcomes)

def flip_ll(th, x): return x * log(th) + (1 - x) * log(1 - th)
def coin_info(th, to_theta, at):               # parameter written as at -> theta
    return info(lambda a, x: flip_ll(to_theta(a), x), at, [(1, th), (0, 1 - th)])
sq = lambda a: sqrt(a)                          # psi = theta^2, back to theta
lo = lambda a: 1 / (1 + exp(-a))                # log-odds phi, back to theta

print("Fisher information per flip, by brute force, and Jeffreys mapped back to theta")
for th in (0.1, 0.3, 0.5, 0.7, 0.9):
    i_th = coin_info(th, lambda a: a, th)
    j_psi = sqrt(coin_info(th, sq, th * th)) * 2 * th                     # times |dpsi/dtheta|
    j_phi = sqrt(coin_info(th, lo, log(th / (1 - th)))) / (th * (1 - th))  # times |dphi/dtheta|
    exact = 1 / sqrt(th * (1 - th))
    print(f"theta {th:.1f}: I {i_th:.4f} (formula {1 / (th * (1 - th)):.4f}); sqrt I {exact:.4f}; "
          f"via theta^2 {j_psi:.4f}; via log-odds {j_phi:.4f}; flat-in-theta^2 gives {2 * th:.4f}")
    assert abs(i_th * th * (1 - th) - 1) < 1e-6 and abs(j_psi / exact - 1) < 1e-6 and abs(j_phi / exact - 1) < 1e-6

xs = [0.05 + 0.1 * i for i in range(10)]
print("figure, Jeffreys prior density: " + ", ".join(f"{1 / (pi * sqrt(x * (1 - x))):.2f}" for x in xs))
print("figure, flat-in-theta^2 prior density: " + ", ".join(f"{2 * x:.2f}" for x in xs))

# The coin on the even-information scale u, theta = sin^2 u: there Jeffreys is flat.
N, S = 10, 7
lik = lambda th: th ** S * (1 - th) ** (N - S)
def coin_post(w, g):                            # posterior average of g(theta), prior weight w(u)
    top = midpoint(lambda u: g(sin(u) ** 2) * w(u) * lik(sin(u) ** 2), 0, pi / 2)
    return top / midpoint(lambda u: w(u) * lik(sin(u) ** 2), 0, pi / 2)
priors = [("Jeffreys Beta(1/2,1/2)", 0.5, 0.5, lambda u: 1.0),
          ("flat in theta Beta(1,1)", 1, 1, lambda u: sin(2 * u)),
          ("flat in theta^2 Beta(2,1)", 2, 1, lambda u: 2 * sin(u) ** 2 * sin(2 * u)),
          ("I not its root Beta(0,0)", 0, 0, lambda u: 4 / sin(2 * u))]
print(f"coin, {S} heads in {N}: prior, posterior, mean by formula and by grid, P(theta > 0.5)")
means = {}
for name, a, b, w in priors:
    form = (a + S) / (a + b + N)
    grid = coin_post(w, lambda t: t)
    means[a] = form
    print(f"  {name}: Beta({a + S:g},{b + N - S:g}) mean {form:.4f} grid {grid:.4f} "
          f"P {coin_post(w, lambda t: 1.0 if t > 0.5 else 0.0):.4f}")
    assert abs(form - grid) < 1e-6
A, B = 7.5, 3.5
sd = sqrt(A * B / ((A + B) ** 2 * (A + B + 1)))
print(f"Jeffreys posterior sd {sd:.4f}; flat prior posterior sd {sqrt(32 / (144 * 13)):.4f}")
# Invariance: Jeffreys built directly on the log-odds scale, information by brute force.
wphi = lambda f: sqrt(coin_info(lo(f), lo, f))
top = midpoint(lambda f: (1.0 if f > 0 else 0.0) * wphi(f) * lik(lo(f)), -30, 30, 6000)
p_phi = top / midpoint(lambda f: wphi(f) * lik(lo(f)), -30, 30, 6000)
p_th = coin_post(lambda u: 1.0, lambda t: 1.0 if t > 0.5 else 0.0)
print(f"P(theta > 0.5) under Jeffreys built on theta {p_th:.4f}, built on log-odds {p_phi:.4f}")
assert abs(p_phi - p_th) < 1e-4
print(f"prior P(theta < 0.5): flat in theta {0.5:.4f}, flat in theta^2 {0.25:.4f}, Jeffreys "
      f"{midpoint(lambda u: 1.0, 0, pi / 4) / (pi / 2):.4f}")
print(f"Jeffreys prior P(theta < 0.1 or > 0.9) {2 * midpoint(lambda u: 1.0, 0, asin(sqrt(0.1))) / (pi / 2):.4f}; flat 0.2000")
# Wrong likelihood: flip until the 7th head (negative binomial) gives Beta(7, 3.5).
ths = (0.1, 0.5, 0.9)                           # its information, by brute force over f tails before the 7th head
inb = [info(lambda t, f: 7 * log(t) + f * log(1 - t), th, [(f, exp(lgamma(f + 7) - lgamma(7) - lgamma(f + 1) + 7 * log(th) + f * log(1 - th))) for f in range(3000)]) for th in ths]
fnb = [7 / (th * th * (1 - th)) for th in ths]
print(f"flip-until-7th-head information by brute force at theta 0.1, 0.5, 0.9: {inb[0]:.4f}, {inb[1]:.4f}, {inb[2]:.4f}; "
      f"formula 7/(theta^2(1-theta)) {fnb[0]:.4f}, {fnb[1]:.4f}, {fnb[2]:.4f}")
assert all(abs(i / f - 1) < 1e-6 for i, f in zip(inb, fnb))
print(f"Jeffreys for flip-until-7th-head: Beta(7,3.5) mean {7 / 10.5:.4f}; grid "
      f"{coin_post(lambda u: 1 / sin(u) ** 2 / (1 - sin(u) ** 2) ** 0.5 * sin(2 * u), lambda t: t):.4f}")
# Simulation: theta from Jeffreys by theta = sin^2(pi U / 2), ten flips, keep 7 heads.
MASK, state = (1 << 64) - 1, 20261123
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
kept, total = 0, 0.0
for _ in range(200000):
    th = sin(pi * rnd() / 2) ** 2
    if sum(1 for _ in range(N) if rnd() < th) == S:
        kept, total = kept + 1, total + th
print(f"simulation: 200000 coins, {kept} showed 7 heads, mean chance {total / kept:.4f}")
assert abs(total / kept - means[0.5]) < 4 * sd / sqrt(kept)

# Poisson rate: 45 emails in 3 hours.  Even-information scale v = sqrt(lambda).
K, H = 45, 3
print(f"Poisson rate: I(15) by brute force {info(lambda l, k: k * log(l) - l - lgamma(k + 1), 15.0, [(k, exp(k * log(15) - 15 - lgamma(k + 1))) for k in range(200)]):.4f}, formula {1 / 15:.4f}")
def rate_post(w, k, g):
    f = lambda v: w(v) * exp(k * log(v * v) - H * v * v - (k * log(k / H) - k if k else 0))
    return midpoint(lambda v: g(v * v) * f(v), 1e-9, 12) / midpoint(f, 1e-9, 12)
for name, a, w in [("Jeffreys lambda^(-1/2)", 0.5, lambda v: 1.0), ("flat in lambda", 1, lambda v: 2 * v),
                   ("flat in log lambda", 0, lambda v: 2 / v)]:
    g = rate_post(w, K, lambda l: l)
    print(f"  {name}: Gamma({K + a:g},{H}) mean {(K + a) / H:.4f} grid {g:.4f}")
    assert abs(g - (K + a) / H) < 1e-6
print(f"Jeffreys sd {sqrt(K + 0.5) / H:.4f}; zero emails in 3 hours: Jeffreys mean {0.5 / H:.4f} grid {rate_post(lambda v: 1.0, 0, lambda l: l):.4f}")
for eps in (1e-2, 1e-4, 1e-6):   # flat in log lambda, zero emails: area from sqrt(lambda) = eps up
    print(f"  flat in log lambda, zero emails, area above sqrt(lambda) = {eps:g}: "
          f"{midpoint(lambda t: 2 * exp(-H * exp(2 * t)), log(eps), log(12)):.4f}")

# Normal spread, mean known 0: fill errors 1, -3, 2, -1, 1 ml.  Scale t = log sigma.
X = [1, -3, 2, -1, 1]
n, Q = len(X), sum(x * x for x in X)
nll = lambda s, x: -log(s) - x * x / (2 * s * s)
i2 = midpoint(lambda x: exp(-x * x / 8) / sqrt(8 * pi) * ((nll(2 + 1e-5, x) - nll(2 - 1e-5, x)) / 2e-5) ** 2, -40, 40)
print(f"normal spread, n {n}, sum of squares {Q}: I(2) by brute force {i2:.4f}, formula 2/sigma^2 {2 / 4:.4f}")
def spread_post(w, g):
    f = lambda t: w(t) * exp(-n * t - Q / (2 * exp(2 * t)) + n * log(sqrt(Q / n)) + n / 2)
    return midpoint(lambda t: g(exp(t)) * f(t), -6, 20) / midpoint(f, -6, 20)
print(f"plain estimate sqrt(Q/n) {sqrt(Q / n):.4f} ml")
for name, a, w in [("Jeffreys 1/sigma", n / 2, lambda t: 1.0), ("flat in sigma", (n - 1) / 2, lambda t: exp(t)),
                   ("flat in sigma^2", (n - 2) / 2, lambda t: exp(2 * t))]:
    es = sqrt(Q / 2) * exp(lgamma(a - 0.5) - lgamma(a))
    gs, gv = spread_post(w, lambda s: s), spread_post(w, lambda s: s * s)
    print(f"  {name}: 1/sigma^2 ~ Gamma({a:g},{Q / 2:g}); E sigma {es:.4f} grid {gs:.4f}; "
          f"E sigma^2 {Q / 2 / (a - 1):.4f} grid {gv:.4f}")
    assert abs(es - gs) < 1e-5 and abs(Q / 2 / (a - 1) - gv) < 1e-4
assert abs(i2 - 0.5) < 1e-6
iu = [coin_info(th, lambda a: sin(a) ** 2, asin(sqrt(th))) for th in (0.1, 0.5, 0.9)]
iv = info(lambda v, k: k * log(v * v) - v * v - lgamma(k + 1), sqrt(15), [(k, exp(k * log(15) - 15 - lgamma(k + 1))) for k in range(200)])
it = midpoint(lambda x: exp(-x * x / 8) / sqrt(8 * pi) * ((nll(exp(log(2) + 1e-5), x) - nll(exp(log(2) - 1e-5), x)) / 2e-5) ** 2, -40, 40)
print(f"information on the even scales: u = asin(sqrt(theta)) at theta 0.1, 0.5, 0.9: {iu[0]:.4f}, {iu[1]:.4f}, {iu[2]:.4f}; "
      f"v = sqrt(lambda) at 15: {iv:.4f}; log sigma at 2: {it:.4f}")
print(f"try: 10 heads in 10, Jeffreys mean {10.5 / 11:.4f}, flat {11 / 12:.4f}; 70 in 100, Jeffreys {70.5 / 101:.4f}, flat {71 / 102:.4f}")
assert all(abs(x - 4) < 1e-5 for x in iu) and abs(iv - 4) < 1e-5 and abs(it - 2) < 1e-5
print("ALL CHECKS PASS")
