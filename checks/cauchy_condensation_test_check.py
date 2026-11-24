# Cauchy condensation -- the check behind the card.  Standard library only;
# math.log is a primitive.  Every sum is added here one term at a time.
from math import log, exp

a1 = lambda n: 1 / (n * log(n))              # the card's series, from n = 2
a2 = lambda n: 1 / (n * log(n) ** 2)         # the same with (ln n)^2
cond = lambda a, k: 2 ** k * a(2 ** k)       # the condensed term 2^k a(2^k)
KMAX = 20; N = 2 ** KMAX                     # 1048576, about a million terms

S1, S2, at = 0.0, 0.0, {}                    # road one: add every term
for n in range(2, N + 1):
    S1, S2 = S1 + a1(n), S2 + a2(n)
    if n & (n - 1) == 0:
        at[n.bit_length() - 1] = (S1, S2)
for K in range(1, KMAX + 1):                 # road two: the condensed sandwich
    for j, a in ((0, a1), (1, a2)):
        C = sum(cond(a, k) for k in range(1, K + 1))
        assert C / 2 <= at[K][j] <= C        # half the condensed sum <= sum <= condensed sum
    assert abs(cond(a1, K) - 1 / (K * log(2))) < 1e-12  # a harmonic term in K
    assert abs(cond(a2, K) - 1 / (K * log(2)) ** 2) < 1e-12  # a square term in K
half = lambda K: sum(cond(a1, k) for k in range(1, K + 1)) / 2
ks = range(2, KMAX + 1, 2)
f3 = lambda v: " ".join(f"{x:.3f}" for x in v)
print("figure, K (sum runs to 2^K):", " ".join(str(K) for K in ks))
print("figure, half condensed:", f3(half(K) for K in ks))
print("figure, sum of 1/(n ln n):", f3(at[K][0] for K in ks))
print("figure, condensed:", f3(2 * half(K) for K in ks))
lo, hi = log(log(N + 1)) - log(log(2)), a1(2) + log(log(N)) - log(log(2))
assert lo <= S1 <= hi                        # road three: area under 1/(x ln x)
print(f"1/(n ln n) to N={N}: sum {S1:.6f}, integral bounds {lo:.6f} to {hi:.6f}")
print(f"condensed term at k=20: {cond(a1, 20):.6f}; 1/(20 ln 2) = {1 / (20 * log(2)):.6f}")
print(f"ln ln N: at 2^20 {log(log(N)):.6f}, at 10^6 {log(log(10 ** 6)):.6f}; sum to 2^10 "
      f"{at[10][0]:.6f}, gain to 2^20 {S1 - at[10][0]:.6f}, ln 2 = {log(2):.6f}")
print(f"block 4..7: {sum(a1(n) for n in range(4, 8)):.3f}, under c_2 = {cond(a1, 2):.3f}")
c = S1 - log(log(N))                         # the sum runs about ln ln N + c
print(f"sum minus ln ln N: {c:.6f}; estimate: passing 5 takes about 10^{exp(5 - c) / log(10):.0f} terms")
z2 = sum(1 / k ** 2 for k in range(1, 10 ** 6)) + 1 / 10 ** 6  # 1/k^2 summed, tail added
low2, up2 = z2 / log(2) ** 2 / 2, z2 / log(2) ** 2
lo10, hi10 = at[10][1] + 1 / log(2 ** 10 + 1), at[10][1] + 1 / log(2 ** 10)  # the box at 2^10
assert low2 <= lo10 <= S2 + 1 / log(N + 1) and S2 + 1 / log(N) <= hi10 <= up2  # 2^20 box inside it
print(f"1/(n (ln n)^2) to N={N}: sum {S2:.6f}, whole sum between "
      f"{S2 + 1 / log(N + 1):.6f} and {S2 + 1 / log(N):.6f}")
print(f"its condensed series 1/(k^2 (ln 2)^2): half {low2:.6f}, whole {up2:.6f}")
sq = sum(1 / n ** 2 for n in range(2, N + 1))
gq = sum(cond(lambda n: 1 / n ** 2, k) for k in range(1, KMAX + 1))
assert gq / 2 <= sq <= gq and abs(gq - (1 - 2 ** -KMAX)) < 1e-15  # p = 2: 1/2 + 1/4 + ...
print(f"p=2: sum of 1/n^2, n=2..2^20, {sq:.6f}; condensed 1/2 + 1/4 + ... to k=20 {gq:.6f}")
sieve = bytearray([0, 0]) + bytearray([1]) * (10 ** 6 - 1)  # primes below a million, by sieve
for i in range(2, 1001):
    if sieve[i]:
        sieve[i * i::i] = bytearray(len(range(i * i, 10 ** 6 + 1, i)))
P = [i for i in range(10 ** 6 + 1) if sieve[i]]
assert all(P[n - 1] < n * (log(n) + log(log(n))) for n in range(6, len(P) + 1))
print(f"primes below 10^6: {len(P)}, sum of 1/p {sum(1 / p for p in P):.6f}; "
      f"largest {P[-1]}; p_n < n (ln n + ln ln n), n = 6..{len(P)}: yes")
gap = sum(1 / n for n in range(1, N + 1) if n & (n - 1))  # 1/n, powers of 2 set to 0
print(f"mistake 1, not decreasing: sum to 2^20 {gap:.6f}, condensed sum 0")
print(f"mistake 2, 2^k dropped: sum of a(2^k), k=1..20, {sum(a1(2 ** k) for k in range(1, 21)):.6f}")
print(f"mistake 3, condensed value as the sum: {up2:.6f} against {S2 + 1 / log(N):.6f}")
print("ALL CHECKS PASS")
