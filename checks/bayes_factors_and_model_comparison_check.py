# Bayes factors -- the check behind the card.  Nothing imported holds the answer.
# A new coin shows 7 heads in 10 flips.  M0: the coin is fair, theta = 1/2.
# M1: theta unknown, with a prior on it.  Bayes factor = P(data | M0) / P(data | M1).
# Roads: (1) exact counts and rising products; (2) Simpson's rule over the prior;
# (3) a seeded simulation of both models; (4) for big n, log-factorials two ways
# against Lindley's formula and BIC.
from math import log, exp, sqrt, pi, sin, cos

N, K = 10, 7

def rising(x, k):                            # x (x+1) ... (x+k-1), any real x
    out = 1.0
    for j in range(k):
        out *= x + j
    return out

def comb(n, k):
    out = 1
    for j in range(k):
        out = out * (n - j) // (j + 1)
    return out

def simpson(f, lo, hi, m=2000):
    h = (hi - lo) / m
    return sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(lo + i * h) for i in range(m + 1)) * h / 3

def ev_beta(a, n=N, k=K):                    # road 1: P(k of n | theta ~ Beta(a, a))
    return comb(n, k) * rising(a, k) * rising(a, n - k) / rising(2 * a, n)

def ev_grid(a):                              # road 2: theta = sin^2(phi) makes every a >= 1/2 smooth
    w = lambda p: 2 * (sin(p) * cos(p)) ** (2 * a - 1)
    lik = lambda p: comb(N, K) * sin(p) ** (2 * K) * cos(p) ** (2 * (N - K))
    return simpson(lambda p: w(p) * lik(p), 0, pi / 2) / simpson(w, 0, pi / 2)

L0 = comb(N, K) / 2 ** N
L1 = ev_beta(1)
bf = L0 / L1
print(f"P(7 of 10 | fair) = {comb(N, K)}/{2 ** N} = {L0:.4f}")
print(f"P(7 of 10 | uniform prior) = 1/11 = {L1:.4f}; by grid {ev_grid(1):.4f}")
print("uniform prior, every count 0..10: " + ", ".join(f"{ev_beta(1, N, k):.4f}" for k in range(N + 1)))
print(f"Bayes factor fair : uniform = {comb(N, K) * 11}/{2 ** N} = {bf:.4f}; uniform : fair = {1 / bf:.4f}")
for q in (0.5, 0.9, 0.1):
    o = q / (1 - q) * bf
    print(f"prior P(fair) {q:.1f}: prior odds {q / (1 - q):.4f}, posterior odds {o:.4f}, P(fair | data) {o / (1 + o):.4f}")
tail = sum(comb(N, j) for j in range(K, N + 1))
print(f"two-sided p-value, exact: 2 x {tail}/{2 ** N} = {2 * tail / 2 ** N:.4f}")
th = K / N
Lhat = comb(N, K) * th ** K * (1 - th) ** (N - K)
bic0, bic1 = -2 * log(L0), -2 * log(Lhat) + log(N)
lap = Lhat * sqrt(2 * pi * th * (1 - th) / N)
print(f"best fit theta {th:.1f}: max likelihood {Lhat:.4f}; ratio of maxima {L0 / Lhat:.4f}")
print(f"BIC fair {bic0:.4f}, BIC free {bic1:.4f}; BIC Bayes factor {exp((bic1 - bic0) / 2):.4f}; "
      f"Laplace P(data | uniform) {lap:.4f}")
print("prior Beta(a,a) on theta under M1: a, sd, evidence, grid, Bayes factor fair : M1, posterior mean")
for a in (0.5, 1, 2, 10):
    print(f"  {a:>4}: {1 / (2 * sqrt(2 * a + 1)):.4f}, {ev_beta(a):.4f}, {ev_grid(a):.4f}, "
          f"{L0 / ev_beta(a):.4f}, {(a + K) / (2 * a + N):.4f}")

# road 3: simulation, SplitMix64 seed 20261123
MASK = (1 << 64) - 1
state = 20261123
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
R = 200_000
hit0 = hit1 = 0
for _ in range(R):
    th1 = uniform()
    hit1 += sum(uniform() < th1 for _ in range(N)) == K
    hit0 += sum(uniform() < 0.5 for _ in range(N)) == K
s0, s1 = hit0 / R, hit1 / R
se = lambda q: sqrt(q * (1 - q) / R)
print(f"simulated {R} coins per model, seed 20261123: P(7 of 10) fair {s0:.4f} ({se(s0):.4f}), "
      f"uniform {s1:.4f} ({se(s1):.4f}); Bayes factor {s0 / s1:.4f}")

# road 4: Lindley's paradox -- the same z = 2 at ever larger n
def lf_stirling(n):                          # ln n!, Stirling's series
    if n < 20:
        return sum(log(j) for j in range(2, n + 1))
    return n * log(n) - n + 0.5 * log(2 * pi * n) + 1 / (12 * n) - 1 / (360 * n ** 3)
def lf_sum(n):                               # ln n!, term by term
    return sum(log(j) for j in range(2, n + 1))
def lpmf(n, k, lf):                          # ln P(k of n | fair)
    return lf(n) - lf(k) - lf(n - k) - n * log(2)
def phi_tail(z):                             # P(Z > z) for a standard normal, by Simpson
    return 0.5 - simpson(lambda x: exp(-x * x / 2) / sqrt(2 * pi), 0, z, 400)
def exact_p(n, k):                           # 2 P(X >= k | fair), summed term by term
    t = exp(lpmf(n, k, lf_stirling))
    s, j = 0.0, k
    while j <= n and t > 1e-18 * s:
        s, t, j = s + t, t * (n - j) / (j + 1), j + 1
    return 2 * s
print("n, heads, z, p normal, p exact, BF fair:uniform (Stirling, log-sum), Lindley sqrt(2n/pi)e^(-z^2/2), BIC")
rows = []
for n, k in ((10, 7), (2_500, 1_300), (10_000, 5_100), (1_000_000, 501_000)):
    z = (k - n / 2) / (sqrt(n) / 2)
    b_st = exp(lpmf(n, k, lf_stirling)) * (n + 1)
    b_sum = exp(lpmf(n, k, lf_sum)) * (n + 1)
    lind = sqrt(2 * n / pi) * exp(-z * z / 2)
    t = k / n
    bicbf = exp(lpmf(n, k, lf_stirling) - (lf_stirling(n) - lf_stirling(k) - lf_stirling(n - k)
                + k * log(t) + (n - k) * log(1 - t))) * sqrt(n)
    rows.append((n, b_st, b_sum, lind, bicbf))
    print(f"  {n}, {k}, {z:.4f}, {2 * phi_tail(z):.4f}, {exact_p(n, k):.4f}, {b_st:.4f}, {b_sum:.4f}, "
          f"{lind:.4f}, {bicbf:.4f}")
print(f"  posterior P(fair) at n = 10000, even prior odds: {rows[2][1] / (1 + rows[2][1]):.4f}; "
      f"BIC / exact at n = 1000000: {rows[3][4] / rows[3][1]:.4f}, sqrt(pi/2) = {sqrt(pi / 2):.4f}")
print("n = 10000, 5100 heads; M1 uniform on 0.5 +/- h: h, P(data | M1) x 10^4, Bayes factor fair : M1")
n, k = 10_000, 5_100
bfw = []
for h in (0.5, 0.1, 0.02):
    lc = lf_stirling(n) - lf_stirling(k) - lf_stirling(n - k)
    f = lambda t: exp(lc + k * log(t) + (n - k) * log(1 - t)) if 0 < t < 1 else 0.0
    e = simpson(f, 0.5 - h, 0.5 + h, 4000) / (2 * h)
    bfw.append(rows[2][1] * (1 / (n + 1)) / e)
    print(f"  {h}: {1e4 * e:.4f}, {bfw[-1]:.4f}")
print("scale (Kass and Raftery): 1 to 3 barely worth mentioning, 3 to 20 positive, 20 to 150 strong, over 150 very strong")
print("try: 70 of 100 fair:uniform " + f"{exp(lpmf(100, 70, lf_sum)) * 101:.4f}; 5 of 10 {comb(10, 5) * 11 / 1024:.4f}; "
      f"10 of 10 {11 / 1024:.4f}; Beta(50,50) prior {L0 / ev_beta(50):.4f}")
print("figure, heads 0..10, fair, percent: " + ", ".join(f"{100 * comb(N, j) / 2 ** N:.2f}" for j in range(N + 1)))
print("figure, heads 0..10, uniform, percent: " + ", ".join(f"{100 * ev_beta(1, N, j):.2f}" for j in range(N + 1)))

# asserts: separate roads side by side
assert abs(L1 - 1 / 11) < 1e-12 and abs(ev_grid(1) - L1) < 1e-9
assert all(abs(ev_grid(a) - ev_beta(a)) < 1e-9 for a in (0.5, 2, 10))
assert abs(sum(ev_beta(1, N, j) for j in range(N + 1)) - 1) < 1e-12
assert abs(s0 - L0) < 4 * se(s0) and abs(s1 - L1) < 4 * se(s1)
assert all(abs(r[1] - r[2]) < 1e-6 * r[1] for r in rows)
assert abs(rows[3][3] / rows[3][1] - 1) < 1e-3 and abs(rows[3][4] / rows[3][1] - sqrt(pi / 2)) < 1e-2
assert abs(bfw[0] - rows[2][1]) < 1e-6 * rows[2][1]
assert abs(rows[0][1] - bf) < 1e-9 * bf
assert abs(lap - L1) < 0.1 * L1 and abs(exact_p(N, K) - 2 * tail / 2 ** N) < 1e-12
print("ALL CHECKS PASS")
