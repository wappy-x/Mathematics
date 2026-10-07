# The zeta function and the Euler product -- the check behind the card.  Standard library only.
# zeta(s) = sum of n^-s with n^-s = e^(-s ln n).  zeta(2) three ways: 1000 terms plus a tail bracket,
# the product over primes, pi^2/6 from the sine product.  Then 6/pi^2 by counting coprime ticket pairs.
import math

def sieve(m):                                  # the primes up to m, Eratosthenes
    flag = [True] * (m + 1); flag[0] = flag[1] = False
    for p in range(2, math.isqrt(m) + 1):
        if flag[p]: flag[p * p::p] = [False] * len(flag[p * p::p])
    return [p for p in range(m + 1) if flag[p]]
def npow(n, s):                                # n^-s = e^(-s ln n): size n^-(Re s), turn -(Im s) ln n
    r, t = math.exp(-s.real * math.log(n)), -s.imag * math.log(n)
    return complex(r * math.cos(t), r * math.sin(t))
def euler(s, P):                               # product over primes p <= P of 1/(1 - p^-s)
    e = 1 + 0j
    for p in primes:
        if p > P: break
        e /= 1 - npow(p, s)
    return e
def show(w):                                   # 'a + bi', six decimals
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def gcd(a, b): return gcd(b, a % b) if b else a    # Euclid's algorithm

N = P = 1000
primes, z2 = sieve(100000), math.pi ** 2 / 6
S = sum(1 / n ** 2 for n in range(1, N + 1))   # road 1: 1000 terms, tail between 1/(N+1) and 1/N
lo, hi = S + 1 / (N + 1), S + 1 / N
print(f"zeta(2), 1000 terms: sum {S:.8f}, bracket [{lo:.8f}, {hi:.8f}], both ends {lo:.4f} {hi:.4f}")
E2 = euler(2, P).real                          # road 2: 168 primes up to 1000
print(f"Euler product, {sum(p <= P for p in primes)} primes <= 1000: {E2:.8f}, gap to pi^2/6 {abs(E2 - z2):.8f}, bound 1/P {1 / P:.8f}")
sp = math.prod(1 - 0.25 / n ** 2 for n in range(1, 100001))   # road 3: the sine product at x = 1/2
print(f"road 3: pi^2/6 = {z2:.8f}; sine product at x = 1/2, 100000 factors {sp:.6f}, 2/pi {2 / math.pi:.6f}")
s = complex(2, 1)
ser, eul = sum(npow(n, s) for n in range(1, N + 1)), euler(s, P)
print(f"s = 2 + i: 1000 terms {show(ser)}, product {show(eul)}, gap {abs(ser - eul):.6f}; |5^-s| = {abs(npow(5, s)):.6f}")
d1, d2 = [(sum(npow(n, s + h) for n in range(1, N + 1)) - ser) / h for h in (1e-6, 1e-6j)]   # holomorphy
print(f"slope of the 1000-term sum at 2 + i: step along 1 {show(d1)}, step along i {show(d2)}")
C = [0] * (N + 1)                              # C[M] = coprime pairs (a, b) with 1 <= a, b <= M
for M in range(1, N + 1):
    C[M] = C[M - 1] + 2 * sum(1 for a in range(1, M + 1) if gcd(a, M) == 1) - (M == 1)
print(f"tickets 1 to 1000: {C[N]} of {N * N} pairs coprime, share {C[N] / N ** 2:.6f}; 6/pi^2 {1 / z2:.6f}; 1/product {1 / E2:.6f}")
S4 = sum(1 / n ** 2 for n in range(1, 5))
print(f"by hand: 4 terms {S4:.6f}, bracket [{S4 + 1 / 5:.6f}, {S4 + 1 / 4:.6f}]; primes 2, 3, 5: {euler(2, 5).real:.6f}; tickets 1 to 6: {C[6]} of 36")
split = sum(C[N // g] for g in range(1, N + 1))
print(f"split every pair by its gcd g: sum of C(N//g) = {split}")
xs = [10, 100, 1000, 10000, 100000]
rp = [sum(1 / p for p in primes if p <= x) for x in xs]
print("chart, sum of 1/p for p <= x: " + ", ".join(f"{v:.2f}" for v in rp))
print("chart, ln ln x: " + ", ".join(f"{math.log(math.log(x)):.2f}" for x in xs))
print("floor ln ln(x+1) - 1: " + ", ".join(f"{math.log(math.log(x + 1)) - 1:.2f}" for x in xs))
H, E1 = sum(1 / n for n in range(1, P + 1)), math.prod(1 / (1 - 1 / p) for p in primes[:168])
print(f"at s = 1: harmonic sum to 1000 {H:.6f}, product over primes <= 1000 {E1:.6f}")
print(f"mistake, product over all n from 2 to 1000: {math.prod(1 / (1 - 1 / n ** 2) for n in range(2, N + 1)):.6f}")
print(f"figure, 60 per unit, 0 at (60, 150): s = 1 at ({60 + 60}, 150), s = 2 at ({60 + 120}, 150), s = 2 + i at ({60 + 120}, {150 - 60})")
assert lo <= z2 <= hi and abs(E2 - z2) < 1 / P                          # three roads to zeta(2) agree
assert abs(ser - eul) <= 1 / N + 1 / P and abs(d1 - d2) < 1e-4 and abs(sp - 2 / math.pi) <= 0.25 / 100000   # complex s; holomorphy; sine product
assert split == N * N and abs(C[N] / N ** 2 - 1 / z2) < math.log(N) / N  # the count meets 6/pi^2
assert all(v >= math.log(math.log(x + 1)) - 1 for v, x in zip(rp, xs)) and E1 >= H   # sum of 1/p grows
print("ALL CHECKS PASS")
