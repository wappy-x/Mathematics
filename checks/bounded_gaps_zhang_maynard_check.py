# Bounded gaps (Zhang, Maynard) -- the check behind the card.  Standard library only.
# Road 1: a sieve of Eratosthenes counts twin pairs, gaps and tuple hits below a million.
# Road 2: admissible tuples, by brute force and by a greedy sieve, checked residue by residue.
# Road 3: the sieve ratio k*J/I, exactly in fractions, against a closed form and against
# the Bessel-zero formula for the best one-variable weight.  Road 4: real GPY weights.
from fractions import Fraction as Fr
from math import factorial as fa, comb, log
from itertools import combinations
LIM = 1_000_100
s = bytearray([1]) * (LIM + 1); s[0] = s[1] = 0
for i in range(2, int(LIM ** 0.5) + 1):
    if s[i]: s[i * i::i] = bytearray(len(s[i * i::i]))
ps = [p for p in range(2, 1_000_000) if s[p]]
twins = sum(1 for p in ps if p + 2 < 1_000_000 and s[p + 2])
gap, at = max((q - p, p) for p, q in zip(ps, ps[1:]))
print(f"primes below 1,000,000: {len(ps)}; twin pairs: {twins}; widest gap: {gap}, after {at}")
print(f"{at} is prime number {ps.index(at) + 1}; average gap near 1,000,000 = log 1,000,000 = {log(1e6):.4f}")
def hits(H, need): return sum(1 for n in range(1, 1_000_000) if sum(s[n + h] for h in H) >= need)
print(f"n below 1,000,000 with 2+ primes among n, n+2, n+6: {hits([0, 2, 6], 2)}; all 3: {hits([0, 2, 6], 3)}")
print(f"all 3 of n, n+2, n+4 prime: {hits([0, 2, 4], 3)}; both n, n+1 prime: {hits([0, 1], 2)}")
print(f"n below 1,000,000 with 2+ primes in n + (0, 2, 6, 8, 12): {hits([0, 2, 6, 8, 12], 2)}")
def admissible(H):                         # no prime p <= k meets every remainder class mod p
    return all(len({h % p for h in H}) < p for p in range(2, len(H) + 1) if s[p])
def narrowest(k):                          # brute force: smallest width w with an admissible k-tuple
    w = 1
    while not any(admissible((0,) + c + (w,)) for c in combinations(range(1, w), k - 2)): w += 1
    return w
widths = [narrowest(k) for k in range(2, 7)]
print("narrowest admissible k-tuple, k = 2..6, by brute force:", widths)
def greedy(width, k, shift):               # sieve one class mod each prime p <= k from an interval
    S = list(range(shift, shift + width + 1))
    for p in [q for q in range(2, k + 1) if s[q]]:
        cnt = [0] * p
        for x in S: cnt[x % p] += 1
        r = cnt.index(min(cnt)); S = [x for x in S if x % p != r]
    return [x - S[0] for x in S[:k]]
T50, T105 = greedy(246, 50, 1), greedy(600, 105, 21)
print(f"greedy 50-tuple: width {T50[-1]}, admissible {admissible(T50)}; first ten {T50[:10]}")
print(f"greedy 105-tuple: width {T105[-1]}, admissible {admissible(T105)}")
print("inadmissible (0, 2, 4): classes mod 3 met:", len({h % 3 for h in (0, 2, 4)}))
def partitions(n, mx):
    if n == 0: yield []; return
    for p in range(min(n, mx), 0, -1):
        for rest in partitions(n - p, p): yield [p] + rest
def T(k, A, B):        # integral over the k-simplex of (1 - P1)^B * P2^A, exactly
    tot = Fr(0)
    for lam in partitions(A, A):
        if len(lam) > k: continue
        ways = Fr(fa(k), fa(k - len(lam))) * fa(A)
        for x in set(lam): ways /= fa(lam.count(x))
        for x in lam: ways = ways * fa(2 * x) / fa(x)
        tot += ways
    return tot * fa(B) / fa(k + B + 2 * A)
def ratio(k, basis, c):  # k * J / I for F = sum of c * P2^a * (1 - P1)^b
    I = J = Fr(0)
    for (a, b), u in zip(basis, c):
        for (a2, b2), v in zip(basis, c):
            I += u * v * T(k, a + a2, b + b2)
            for x in range(a + 1):
                for y in range(a2 + 1):
                    f = comb(a, x) * comb(a2, y) * Fr(fa(b) * fa(2 * x), fa(b + 2 * x + 1)) * Fr(fa(b2) * fa(2 * y), fa(b2 + 2 * y + 1))
                    J += u * v * f * T(k - 1, a - x + a2 - y, b + 2 * x + b2 + 2 * y + 2)
    return k * J / I
closed = lambda k, b: Fr(2 * k * (2 * b + 1), (b + 1) * (k + 2 * b + 1))
for b in range(4): assert ratio(5, [(0, b)], [1]) == closed(5, b)
print("GPY weight (1 - P1)^b, k = 5, b = 0..3:", ", ".join(f"{float(closed(5, b)):.6f}" for b in range(4)))
print(f"GPY weight 1 - P1 on k = 3 (used below): {closed(3, 1)}")
def bessel(nu, x):     # J_nu(x) by Miller's downward recurrence, normalised by J0 + 2(J2 + J4 + ...) = 1
    m = 2 * ((int(x) + nu + 40) // 2); jp, j, norm, out = 0.0, 1e-30, 0.0, 0.0
    for n in range(m, 0, -1):
        jp, j = j, 2 * n / x * j - jp
        if n - 1 == nu: out = j
        if (n - 1) % 2 == 0: norm += j if n - 1 == 0 else 2 * j
        if abs(j) > 1e200: jp, j, norm, out = jp * 1e-200, j * 1e-200, norm * 1e-200, out * 1e-200
    return out / norm
def first_zero(nu):
    lo = nu + 0.1
    while bessel(nu, lo + 0.1) > 0 and lo < nu + 99: lo += 0.1
    hi = lo + 0.1
    for _ in range(60):
        mid = (lo + hi) / 2
        if bessel(nu, mid) > 0: lo = mid
        else: hi = mid
    return lo
best1 = {k: 4 * k * (k - 1) / first_zero(k - 2) ** 2 for k in (2, 3, 5, 50, 105)}
print(f"first zero of the Bessel function J_3: {first_zero(3):.6f}")
print("best one-variable ratio 4k(k-1)/j^2:", ", ".join(f"k={k}: {v:.6f}" for k, v in best1.items()))
g = ratio(5, [(0, 0), (0, 1), (0, 2), (0, 3)], [1, 4, 4, 5])
B6, C6 = [(0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1)], [1, 11, -39, -22, -9, -81]
M5 = ratio(5, B6, C6)
print(f"k = 5, one-variable g = 1 + 4u + 4u^2 + 5u^3: {float(g):.6f}")
print(f"k = 5, Maynard F with P2 terms: {M5.numerator}/{M5.denominator} = {float(M5):.6f}")
N = 100_000
sqf = [d for d in range(1, 317) if all(d % (p * p) for p in range(2, 18))]
mu = {d: (-1) ** sum(1 for p in range(2, d + 1) if s[p] and d % p == 0) for d in sqf}
for R in (18, 316):
    lam = {d: mu[d] * log(R / d) ** 4 for d in sqf if d <= R}
    W = P = 0.0
    for n in range(N, 2 * N):
        Pn = n * (n + 2) * (n + 6)
        w = sum(v for d, v in lam.items() if Pn % d == 0) ** 2
        W += w; P += w * (s[n] + s[n + 2] + s[n + 6])
    print(f"R = {R}: log R = {log(R):.4f}, log N = {log(N):.4f}, log R / log N = {log(R) / log(N):.4f}")
    print(f"R = {R}: weighted primes per n {P / W:.4f}; predicted (log R / log N) x 3/2 = {log(R) / log(N) * 1.5:.4f}")
    assert abs(P / W - log(R) / log(N) * 1.5) < 0.1
plain = sum(s[n] + s[n + 2] + s[n + 6] for n in range(N, 2 * N)) / N
print(f"unweighted primes per n in (n, n+2, n+6), n from 100,000 to 199,999: {plain:.4f}")
print("record bounds on the smallest gap that recurs forever: 70,000,000 (2013), 600 (2013), 246 (2014)")
print("quoted, not computed here: M_105 > 4 (Maynard); 16 on EH (GPY), 12 on EH, 6 on GEH")
assert len(ps) == 78498 and twins == 8169 and (gap, at) == (114, 492113)
assert widths == [2, 6, 8, 12, 16] and admissible((0, 2, 6, 8, 12)) and not admissible((0, 2, 4))
assert T50[-1] == 246 and len(T50) == 50 and admissible(T50) and T105[-1] == 600 and admissible(T105)
assert hits([0, 2, 4], 3) == 1 and hits([0, 1], 2) == 1 and 0.25 < plain < 0.26
assert M5 > 2 and float(g) <= best1[5] < 2 and abs(float(g) - best1[5]) < 1e-4
assert best1[105] < 4 and all(closed(k, b) < 4 for k in (5, 50, 105) for b in range(30))
assert abs(best1[2] - 8 / 2.404825557695773 ** 2) < 1e-9
print("ALL CHECKS PASS")
