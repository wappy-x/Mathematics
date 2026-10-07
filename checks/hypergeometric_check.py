# Hypergeometric: drawing without replacement -- the check behind the card.
# Standard library only.  The lottery: 6 balls drawn from 49, a ticket holds 6
# numbers, X = how many of them are drawn.  Three roads to the law of X: count
# with binomial coefficients, enumerate all 13,983,816 draws, and follow the
# draw one ball at a time.  A seeded simulation checks the moments.
from itertools import combinations

N, K, n = 49, 6, 6                      # balls, ticket numbers, balls drawn

def C(a, b):                            # a choose b, by the product rule
    if b < 0 or b > a:
        return 0
    v = 1
    for j in range(1, b + 1):
        v = v * (a - b + j) // j
    return v

def mass(N, K, n):                      # road one: counting
    return [C(K, k) * C(N - K, n - k) / C(N, n) for k in range(n + 1)]

def binom(n, p):                        # the with-replacement law, for contrast
    return [C(n, k) * p ** k * (1 - p) ** (n - k) for k in range(n + 1)]

def mean_var(P):
    m = sum(k * q for k, q in enumerate(P))
    return m, sum(k * k * q for k, q in enumerate(P)) - m * m

total = C(N, n)
counted = [C(K, k) * C(N - K, n - k) for k in range(n + 1)]
enum = [0] * (n + 1)                    # road two: every draw; ticket = balls 0..5
for s in combinations(range(N), n):
    enum[(s[0] < 6) + (s[1] < 6) + (s[2] < 6) + (s[3] < 6) + (s[4] < 6) + (s[5] < 6)] += 1
seq = [0.0] * (n + 1)                   # road three: 64 hit/miss paths, ball by ball
for path in range(1 << n):
    pr, hits = 1.0, 0
    for i in range(n):
        if path >> i & 1:
            pr *= (K - hits) / (N - i); hits += 1
        else:
            pr *= (N - K - (i - hits)) / (N - i)
    seq[hits] += pr
P, B = mass(N, K, n), binom(n, K / N)
print(f"lottery: {n} balls from {N}; a ticket holds {K} numbers; C(49,6) = {total}")
print(f"by hand: 49x48x47x46x45x44 = {49*48*47*46*45*44} ordered draws; / 720 = {49*48*47*46*45*44 // 720}")
print(f"by hand: C(6,3) = {C(6, 3)}, C(43,3) = {C(43, 3)}, product {C(6, 3) * C(43, 3)}")
print("k  counted  enumerated  P(X=k)      ball by ball  about 1 in")
for k in range(n + 1):
    print(f"{k}  {counted[k]:>7}  {enum[k]:>10}  {P[k]:.8f}  {seq[k]:.8f}    {total / counted[k]:.1f}")
print("chart, percent: hypergeometric " + ", ".join(f"{100 * q:.2f}" for q in P))
print("chart, percent: binomial       " + ", ".join(f"{100 * q:.2f}" for q in B))
print(f"at least 3 matches: {sum(P[3:]):.6f}, about 1 in {1 / sum(P[3:]):.1f}")
print(f"jackpot with replacement (binomial): 1 in {1 / B[6]:.1f}, {B[6] / P[6]:.1f} times too likely")
print(f"sample share of the pool: {100 * n / N:.2f} percent")
p = K / N
hm, hv = mean_var(P)
bm, bv = mean_var(B)
fpc = (N - n) / (N - 1)
print(f"mean from the table {hm:.6f}; n K / N = {n * p:.6f}; binomial mean {bm:.6f}")
print(f"variance from the table {hv:.6f}; n p (1-p) (N-n)/(N-1) = {n * p * (1 - p) * fpc:.6f}")
print(f"binomial variance n p (1-p) = {bv:.6f}; correction (N-n)/(N-1) = {fpc:.6f}")
both = K * (K - 1) / (N * (N - 1))
print(f"two named draws both hit: {both:.6f}; p^2 = {p * p:.6f}; covariance {both - p * p:.7f}; {n * (n - 1)} ordered pairs")
print("variance as the draw grows, ticket of 6 (n, without, with replacement):")
for m in range(0, N + 1, 7):
    wv = mean_var(mass(N, K, m))[1]
    fv = m * p * (1 - p) * (N - m) / (N - 1)
    assert abs(wv - fv) < 1e-12        # table road against the correction formula
    print(f"figure, n={m:>2}  {wv:.2f}  {m * p * (1 - p):.2f}")
print("P(X=3) as the pool grows, same shares (6 in 49), 6 drawn:")
for s in (1, 10, 100, 1000):
    print(f"  pool {N * s:>5}: {mass(N * s, K * s, n)[3]:.6f}")
print(f"  binomial:   {B[3]:.6f}")
print(f"smaller game, 6 from 39: jackpot 1 in {1 / mass(39, K, n)[6]:.1f}; correction {(39 - n) / (39 - 1):.6f}")
wrong_at_least_3 = C(K, 3) * C(N - 3, 3) / total
print(f"mistake, ordered over unordered jackpot: 1 in {total / 720:.1f}")
print(f"mistake, choose 3 hits then any 3 balls: {wrong_at_least_3:.6f} for at least 3")

state = 20260928                        # SplitMix64, written out, seed stated
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return z ^ (z >> 31)
R = 200000
s1 = s2 = s3 = s4 = big = 0
for _ in range(R):
    balls, x = list(range(N)), 0
    for i in range(n):                  # partial shuffle: 6 distinct balls
        j = i + rnd() % (N - i)
        balls[i], balls[j] = balls[j], balls[i]
        x += balls[i] < 6
    s1 += x; s2 += x * x; s3 += x ** 3; s4 += x ** 4; big += x >= 3
sm = s1 / R
sv = s2 / R - sm * sm
m4 = (s4 - 4 * sm * s3 + 6 * sm * sm * s2) / R - 3 * sm ** 4   # 4th moment about the mean
se_v = ((m4 - sv * sv) / R) ** 0.5
sp = big / R
se_p = (sp * (1 - sp) / R) ** 0.5
print(f"simulated, {R} draws, seed 20260928: mean {sm:.4f} (se {(sv / R) ** 0.5:.4f})")
print(f"simulated variance {sv:.4f} (se {se_v:.4f}); at least 3 matches {sp:.5f} (se {se_p:.5f})")
assert counted == enum and sum(enum) == total                      # counting = enumeration
assert all(abs(a - b) < 1e-15 for a, b in zip(P, seq))             # counting = ball by ball
assert abs(hv - n * p * (1 - p) * fpc) < 1e-12 and abs(hm - n * p) < 1e-12
assert abs(sv - hv) < 4 * se_v and abs(sv - bv) > 4 * se_v         # sees the correction
assert abs(sp - sum(P[3:])) < 4 * se_p and abs(sm - hm) < 4 * (sv / R) ** 0.5
print("ALL CHECKS PASS")
