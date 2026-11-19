# Chebyshev's bounds -- the check behind the card.  Standard library only;
# math.comb is not used, since the middle binomial coefficient is the idea here.
from math import log, sqrt

N = 1_000_000                                # every count below is exact to N
sieve = bytearray([1]) * (N + 1)
sieve[0] = sieve[1] = 0
for i in range(2, int(N ** 0.5) + 1):
    if sieve[i]:
        sieve[i * i::i] = bytearray(len(range(i * i, N + 1, i)))
pi, c = [0] * (N + 1), 0                     # pi[x]: primes up to x, by sieve
for x in range(N + 1):
    c += sieve[x]
    pi[x] = c
primes = [p for p in range(2, N + 1) if sieve[p]]

def legendre(n, p):                          # road 1: v_p(C(2n,n)) by floors
    v, q = 0, p
    while q <= 2 * n:
        t = 2 * n // q - 2 * (n // q)
        assert t in (0, 1)                   # each term is 0 or 1
        v, q = v + t, q * p
    return v

def carries(n, p):                           # road 2: carries in n + n, base p
    v, carry = 0, 0
    while n > 0 or carry:
        carry = 1 if 2 * (n % p) + carry >= p else 0
        v, n = v + carry, n // p
    return v

n = 500
nxt = next(p for p in primes if p > n)
cbig = 1                                     # road 3: C(1000,500) as a whole number
for i in range(1, n + 1):
    cbig = cbig * (n + i) // i
lnC = sum(legendre(n, p) * log(p) for p in primes if p <= 2 * n)
print(f"n = {n}: first prime above n = {nxt}, primes in (n, 2n] = {pi[2*n] - pi[n]}")
digits = int(lnC / log(10)) + 1
assert digits == len(str(cbig))
print(f"C(1000,500): {digits} digits, log = {lnC:.2f}")
print(f"sandwich: {n*log(4) - log(2*n+1):.2f} <= {lnC:.2f} <= {n*log(4):.2f}; 4^500 / C(1000,500) = {4**n / cbig:.1f}")
small = []
for p in primes:
    if p > 2 * n:
        break
    v, w, rest = legendre(n, p), carries(n, p), cbig
    assert v == w                            # floors agree with carries
    k = 0
    while rest % p == 0:
        rest, k = rest // p, k + 1
    assert k == v and p ** v <= 2 * n        # and with the whole number
    if p * p <= 2 * n:
        small.append(f"{p}^{v}")
print("primes up to 31 in C(1000,500):", " ".join(small))
bands = [("(500, 1000]", 500, 1000), ("(333, 500]", 333, 500),
         ("(31, 333]", 31, 333), ("[2, 31]", 1, 31)]
for name, lo, hi in bands:
    ps = [p for p in primes if lo < p <= hi]
    hit = [p for p in ps if legendre(n, p) > 0]
    share = sum(legendre(n, p) * log(p) for p in hit)
    print(f"band {name:<12} {len(hit):>3} of {len(ps):>3} primes divide, log share {share:.2f}")
up = n * log(4) / log(n)
lo = lnC / log(2 * n)
print(f"upper, primes in (500, 1000] < {up:.2f}, so at most {int(up)}; true {pi[1000] - pi[500]}")
print(f"lower, pi(1000) >= {lo:.2f}, so at least {int(lo) + 1}; true {pi[1000]}")
assert pi[1000] - pi[500] <= int(up) and pi[1000] >= int(lo) + 1
L, U = log(2) / 2, 4 * log(2)
print(f"constants: log 2/2 = {L:.4f}, 4 log 2 = {U:.4f}, log 2 = {log(2):.4f}, log 4 = {log(4):.4f}")
print(f"logs: log 500 = {log(500):.4f}, log 1000 = {log(1000):.4f}, sqrt(1000) = {sqrt(1000):.2f}")
print("x  pi(x)  x/log x  ratio  lower  upper")
for e in range(1, 7):
    x = 10 ** e
    m = x / log(x)
    print(f"{x} {pi[x]} {m:.2f} {pi[x]/m:.4f} {L*m:.2f} {U*m:.2f}")
    assert L * m <= pi[x] <= U * m
assert [pi[10**e] for e in range(1, 7)] == [4, 25, 168, 1229, 9592, 78498]   # OEIS A006880
print(f"below 2: floor at x = 1.5 is {L * 1.5 / log(1.5):.2f}, but pi(1.5) = {pi[1]}")
lows = [(log(2) / 2, 2)] + [((pi[q] - 1) * log(q) / q, q) for q in primes[1:]]
lows.append((pi[N] * log(N) / N, N))         # ratio at the left of each jump
highs = [(pi[p] * log(p) / p, p) for p in primes if p >= 3]
lo_r, hi_r = min(lows), max(highs)
A = (log(2)/2 + log(3)/3 + log(5)/5 - log(30)/30)
print(f"Chebyshev 1852 constants: {A:.5f} and {6*A/5:.5f}")
print(f"ratio over [2, {N}]: least {lo_r[0]:.5f} at x = {lo_r[1]}, most {hi_r[0]:.5f} at x = {hi_r[1]}")
assert lo_r[0] >= L - 1e-12 and hi_r[0] <= U
m0 = next(m for m in range(3, 100) if all(log(k) >= 4*log(2) + 2*log(k)/k for k in range(m, N)))
print(f"upper-bound induction step holds from m = {m0}")
assert all(pi[m] <= U * m / log(m) for m in range(2, m0))
f = lambda n: n * log(4) / 3 - log(2 * n + 1) - sqrt(2 * n) * log(2 * n)
df = lambda n: log(4) / 3 - 2 / (2 * n + 1) - (log(2 * n) + 2) / sqrt(2 * n)
n0 = next(k for k in range(5, N) if f(k) > 0 and df(k) > 0)
assert abs(f(n) - (n*log(4) - log(2*n+1) - sqrt(1000)*log(1000) - 1000*log(4)/3)) < 1e-9
print(f"Erdos at n = 500: {sqrt(1000)*log(1000):.2f} + {1000*log(4)/3:.2f} = "
      f"{sqrt(1000)*log(1000) + 1000*log(4)/3:.2f} < {n*log(4) - log(2*n+1):.2f}")
print(f"Erdos inequality forces a prime for every n >= {n0}")
assert all((f(k) > 0) == (k >= n0) for k in range(1, 20000))   # no clash below n0
chain = [2, 3, 5, 7, 13, 23, 43, 83, 163, 317, 631]
assert all(sieve[q] for q in chain) and all(b < 2 * a for a, b in zip(chain, chain[1:]))
print("Landau chain:", " ".join(map(str, chain)), "covers every n below", chain[-1])
assert chain[-1] > n0
assert all(pi[2 * k] > pi[k] for k in range(1, N // 2 + 1))
print(f"sieve: every n from 1 to {N//2} has a prime in (n, 2n]")
gone = [(k, p) for k in range(2, 2001) for p in primes if 2*k/3 < p <= k and legendre(k, p)]
print("primes in (2n/3, n] dividing C(2n,n), n up to 2000:", gone)
assert gone == [(2, 2)]
gap = next(k for k in range(1, N - 30) if pi[k + 30] == pi[k])
print(f"503 lies between 22^2 = {22**2} and 23^2 = {23**2}; x^0.525 at 10^6 = {N**0.525:.2f}")
print("what breaks:")
print(f"  2^n for 4^n: at most {int(n*log(2)/log(n))} primes in (500, 1000], true {pi[1000]-pi[500]}")
print(f"  x/log x as a ceiling at 1000: {1000/log(1000):.2f} < {pi[1000]}")
print(f"  constant log 2 from x = 2: needs {log(2)*2/log(2):.2f} primes, pi(2) = {pi[2]}")
print(f"  window (n, n + 30]: first empty at n = {gap}, between primes {gap} and {primes[pi[gap]]}")
assert int(n * log(2) / log(n)) < pi[1000] - pi[500] and gap == 1327 and sieve[gap]
print("ALL CHECKS PASS")
