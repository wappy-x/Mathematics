# Law of the iterated logarithm -- the check behind the card.  Standard library only.
# A fair +-1 walk S_n.  Roads: every path of 14 steps listed, and a table over
# (position, maximum) for 60 steps, against the reflection formula; exact binomial
# tails against the two exponential bounds and a normal tail by Simpson's rule;
# a simulation of 500 walks of 10^6 steps (SplitMix64, seed 20261123).
from math import exp, log, sqrt

def h(n): return sqrt(2 * n * log(log(n)))          # the envelope sqrt(2 n ln ln n)

N = 10 ** 6
print(f"n = {N}: sqrt(n) = {sqrt(N):.1f}, ln n = {log(N):.4f}, ln ln n = {log(log(N)):.4f}")
print(f"envelope h(n) = sqrt(2 n ln ln n) = {h(N):.1f} = {h(N) / sqrt(N):.4f} sqrt(n)")
print(f"die, sigma^2 = 35/12: envelope sigma h(n) = {sqrt(35 / 12) * h(N):.1f}")
print("sqrt(2 ln ln n) at n = 10^3, 10^6, 10^9, 10^100:",
      " ".join(f"{sqrt(2 * log(log(10.0 ** e))):.4f}" for e in (3, 6, 9, 100)))
assert abs(h(N) - 2291.6) < 0.05

# 1. reflection: P(M_n >= a) = P(S_n >= a) + P(S_n > a), M_n = max(S_1..S_n)
def counts(n):                                      # paths ending at each position
    c = {0: 1}
    for _ in range(n):
        d = {}
        for s, k in c.items():
            for t in (s - 1, s + 1): d[t] = d.get(t, 0) + k
        c = d
    return c
def reflect(c, a): return sum(k for s, k in c.items() if s >= a) + sum(k for s, k in c.items() if s > a)
c14, listed = counts(14), [0] * 16
for p in range(2 ** 14):
    s = m = 0
    for i in range(14): s += 1 if p >> i & 1 else -1; m = max(m, s)
    for a in range(1, m + 1): listed[a] += 1
assert all(listed[a] == reflect(c14, a) for a in range(1, 15))
tab = {(0, 0): 1}                                   # (position, max so far, from 0)
for _ in range(60):
    d = {}
    for (s, m), k in tab.items():
        for t in (s - 1, s + 1): d[(t, max(m, t))] = d.get((t, max(m, t)), 0) + k
    tab = d
c60 = counts(60)
for a in range(1, 61):
    assert sum(k for (s, m), k in tab.items() if m >= a) == reflect(c60, a)
    assert reflect(c60, a) / 2 ** 60 <= 2 * exp(-a * a / 120)    # maximal bound
print("reflection: 14 steps, all 16384 paths listed; 60 steps, table over (S, M): equal")
for a in (10, 20, 30):
    print(f"n=60 a={a}: P(M >= a) = {reflect(c60, a) / 2 ** 60:.6f} <= 2 e^(-a^2/2n) = "
          f"{2 * exp(-a * a / 120):.6f}")

# 2. exact binomial tails for large n, by ratios from the centre
def tail(n, a):                                     # P(S_n >= a), a with the parity of n
    lp = sum(log((n / 2 + i) / i) for i in range(1, n // 2 + 1)) - n * log(2)
    k, p, tot = n // 2, exp(lp), 0.0
    while p > 1e-300 and k <= n:
        if 2 * k - n >= a: tot += p
        p *= (n - k) / (k + 1); k += 1
    return tot
def normal_upper(z, m=2000):                        # 1/2 - integral of the density, Simpson
    f = lambda x: exp(-x * x / 2) / sqrt(2 * 3.141592653589793)
    w = z / m; return 0.5 - w / 3 * (f(0) + f(z) + sum((4 if i % 2 else 2) * f(i * w) for i in range(1, m)))
def binom_lower_ok(n):                              # C(n,k)/2^n >= e^(-n I(j/n)) / sqrt(2n)
    p = 1.0 / 2 ** n
    for k in range(1, n):
        p *= (n - k + 1) / k
        y = (2 * k - n) / n
        I = (1 + y) / 2 * log(1 + y) + (1 - y) / 2 * log(1 - y)
        if p < exp(-n * I) / sqrt(2 * n) * (1 - 1e-12): return False
    return True
assert all(binom_lower_ok(n) for n in range(2, 61))
print("binomial lower bound C(n,k)/2^n >= e^(-n I)/sqrt(2n): holds for n = 2..60, every k")
print("one time n, a = the even number nearest h(n): exact, normal, upper e^(-a^2/2n), lower bound")
for n in (10 ** 4, 10 ** 5, 10 ** 6):
    a = 2 * round(h(n) / 2); x = (a + 2 * sqrt(n)) / n
    ex, nm = tail(n, a), normal_upper((a - 1) / sqrt(n))
    lo = 0.5 * exp(-(a + 2 * sqrt(n)) ** 2 / (2 * n * (1 - x * x)))
    assert lo <= ex <= exp(-a * a / (2 * n))
    assert abs(ex - nm) < 0.02 * ex
    print(f"n=10^{len(str(n)) - 1} a={a}: {ex:.6f} {nm:.6f} {exp(-a * a / (2 * n)):.6f} {lo:.7f}")
a = 2292
pS, pM = tail(N, a), tail(N, a) + tail(N, a + 2)
print(f"n=10^6: P(S_n >= 2292) = {pS:.6f}; P(max to n >= 2292) = {pM:.6f} <= 2/ln n = {2 / log(N):.6f}")
p1000 = tail(N, 1000) + tail(N, 1002); print(f"n=10^6: P(max to n >= 1000) = {p1000:.6f}; normal tail beyond 1.96 = {normal_upper(1.96):.4f}")

# 3. Borel-Cantelli along n_k = 2^k with c = 1.5: term 2 exp(-c^2 h(n_k)^2 / (2 n_(k+1)))
for k in (10, 20, 40):
    t = 2 * exp(-2.25 * h(2 ** k) ** 2 / (2 * 2 ** (k + 1)))
    assert abs(t - 2 * (k * log(2)) ** -1.125) < 1e-12
    print(f"k={k}: bound term {t:.6f} = 2 (k ln 2)^(-1.125)")

# 4. the mistakes
sb = sum(log(n) ** -2.25 for n in range(3, N + 1))
assert sb >= (N - 2) * log(N) ** -2.25                # each term is at least the last
print(f"sqrt n: P(S_n >= 1000) at 10^6 = {tail(N, 1000):.6f}; sqrt(2 n ln n) = {sqrt(2 * N * log(N)):.1f}")
print(f"Kolmogorov's maximal bound n/a^2 at a = h(10^6): {N / h(N) ** 2:.6f}; along 2^k, k=20: {2 ** 20 / h(2 ** 20) ** 2:.6f}")
print(f"every n, c = 1.5: sum of bounds (ln n)^(-2.25), n = 3..10^6: {sb:.1f} >= {(N - 2) * log(N) ** -2.25:.1f}")

# 5. simulation: R(n) = max of S_m / h(m) over 1000 < m <= n, 8 steps per byte
net, pre = [0] * 256, [0] * 256
for b in range(256):
    s, best = 0, -9
    for i in range(8): s += 1 if b >> i & 1 else -1; best = max(best, s)
    net[b], pre[b] = s, best
hb = [h(8 * j + 1) if j >= 125 else 0.0 for j in range(N // 8)]
zb = [1.96 * sqrt(8 * j + 1) for j in range(N // 8)]  # 1.96 sqrt(i) at each byte's first step
MASK, state = (1 << 64) - 1, 20261123
def rand64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
CK, P = (2000, 5000, 10 ** 4, 2 * 10 ** 4, 5 * 10 ** 4, 10 ** 5, 2 * 10 ** 5, 5 * 10 ** 5, N), 500
sumR, hitR, hit9 = [0.0] * len(CK), [0] * len(CK), [0] * len(CK)
end_sq = end_above = max1000 = n196 = 0
for _ in range(P):
    s, mx, r, ci, w, cross = 0, 0, -1e9, 0, 0, False
    for j in range(N // 8):
        if j % 8 == 0: w = rand64()
        b = (w >> (8 * (j % 8))) & 255
        if j >= 125 and (r < 0 or s + pre[b] > r * hb[j] or (not cross and s + pre[b] > zb[j])):
            t = s
            for i in range(8):
                t += 1 if b >> i & 1 else -1
                r = max(r, t / h(8 * j + i + 1)); cross = cross or t > 1.96 * sqrt(8 * j + i + 1)
        mx = max(mx, s + pre[b]); s += net[b]
        if 8 * j + 8 == CK[ci]:
            sumR[ci] += r; hitR[ci] += r >= 1; hit9[ci] += r > 0.9; ci += 1 if ci < len(CK) - 1 else 0
    end_sq += s * s / N; end_above += s >= h(N); max1000 += mx >= 1000; n196 += cross
print(f"simulation, {P} walks of 10^6 steps, SplitMix64 seed 20261123:")
print("n:            " + " ".join(f"{n:>7}" for n in CK))
print("mean R(n):    " + " ".join(f"{v / P:7.4f}" for v in sumR))
print("share R >= 1: " + " ".join(f"{v / P:7.3f}" for v in hitR))
print("share R > 0.9:" + " ".join(f"{v / P:7.3f}" for v in hit9))
print(f"mean S_n^2/n at 10^6 {end_sq / P:.4f} (exact 1); share S_n >= h(n) at 10^6 {end_above / P:.3f}")
print(f"share with max to 10^6 >= 1000: {max1000 / P:.3f} (exact {p1000:.4f})")
print(f"share passing 1.96 sqrt(i) at some 1000 < i <= 10^6: {n196 / P:.3f}")
assert abs(end_sq / P - 1) < 4 * sqrt(2 / P)
assert abs(max1000 / P - p1000) < 4 * sqrt(p1000 * (1 - p1000) / P)
assert abs(end_above / P - pS) < 4 * sqrt(pS * (1 - pS) / P)
assert n196 >= hitR[-1]                       # past i = 1000, h(i) > 1.966 sqrt(i) > 1.96 sqrt(i)
print("ALL CHECKS PASS")
