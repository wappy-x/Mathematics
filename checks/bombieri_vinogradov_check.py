# Bombieri-Vinogradov -- the check behind the card.  Standard library only.  For every modulus q up
# to root x it finds the worst class error E(q) = max over a of |pi(x; q, a) - li(x)/phi(q)| and adds
# them up, at x = 10^4, 10^5 and 10^6.  Class counts come from a sieve read in steps of q and, as a
# second road, from residues of a trial-division prime list; li(x) from its series and Simpson's rule.
import math
X = 10**6
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0          # road 1: sieve of Eratosthenes
for p in range(2, 1001):
    if flag[p]: flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if flag[p]]
small = [p for p in range(2, 1001) if all(p % d for d in range(2, math.isqrt(p) + 1))]
def is_prime_td(n):                                              # road 2: trial division
    for d in small:
        if d * d > n: return True
        if n % d == 0: return False
    return True
td = [n for n in range(2, X + 1) if is_prime_td(n)]
print(f"primes below 10^6: sieve {len(primes)}; trial division {len(td)}")
GAMMA = 0.5772156649015329                                       # Euler's constant, quoted
def li_series(x):                                                # li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    u, term, s, n = math.log(x), 1.0, 0.0, 0
    while True:
        n += 1; term *= u / n; s += term / n
        if term / n < 1e-17 * s: return GAMMA + math.log(u) + s
def simpson(f, a, b, m=20000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m)))
li_b = simpson(lambda u: math.exp(u) / u, math.log(2), math.log(X)) + li_series(2)
print(f"li(10^6): series {li_series(X):.2f}; Simpson from 2 plus li(2) {li_b:.2f}")
def coprime(q): return [a for a in range(1, q + 1) if math.gcd(a, q) == 1]
def counts_sieve(x, q):                                          # pi(x; q, a) for each coprime a, by stepping
    return [flag[a:x + 1:q].count(1) for a in coprime(q)]
def counts_res(ps, q):                                           # the same, by residues of a prime list
    c = {a: 0 for a in coprime(q)}
    for p in ps:
        if p % q in c or q == 1: c[p % q if q > 1 else 1] += 1
    return list(c.values())
check_q = list(range(1, 101)) + [997, 1000]
agree = all(counts_sieve(X, q) == counts_res(td, q) for q in check_q)
print(f"class counts, sieve against trial division: agree on all {len(check_q)} moduli tested: {agree}")
ratios, E6 = [], {}
for e in (4, 5, 6):
    x = 10**e; Q = math.isqrt(x); li = li_series(x); E = {}
    for q in range(1, Q + 1):
        c = counts_sieve(x, q); share = li / len(c)
        E[q] = max(abs(v - share) for v in c)
    S = sum(E.values()); ratios.append(S / (x / math.log(x)))
    wq = max(E, key=lambda q: E[q] * len(coprime(q)) / li)
    print(f"x = 10^{e}: Q = {Q}; S = sum of E(q) = {S:.2f}; x/ln x = {x / math.log(x):.2f}; ratio {ratios[-1]:.4f}; "
          f"mean E(q) {S / Q:.2f}; worst relative miss {100 * E[wq] * len(coprime(wq)) / li:.2f} percent at q = {wq}")
    if e == 6: E6 = E
LI, PI, Q = li_series(X), len(primes), 1000
S = sum(E6.values())
print(f"E(1) = {E6[1]:.2f} = li - pi; E(2) = {E6[2]:.2f}; E(7) = {E6[7]:.2f}; E(1000) = {E6[1000]:.2f}")
c7 = counts_sieve(X, 7); print(f"q = 7: share li/6 = {LI / 6:.2f}; classes hold {min(c7)} to {max(c7)}")
blocks = [(1, 10), (11, 100), (101, 1000)]
print("block sums: " + "; ".join(f"q {a} to {b}: {sum(E6[q] for q in range(a, b + 1)):.2f}" for a, b in blocks))
triv = sum(X / q for q in range(1, Q + 1))
print(f"trivial bound sum of x/q to 1000: {triv:.0f}; S is {100 * S / triv:.2f} percent of it")
print(f"mean E(q) {S / Q:.2f} against sqrt(x) = {math.sqrt(X):.0f} and sqrt(x) ln x = {math.sqrt(X) * math.log(X):.0f}")
print(f"large sieve size N + Q^2 with N = x: Q = 1000 gives {X + 1000**2}; Q = 10000 gives {X + 10000**2}")
sqf = [d for d in range(1, Q + 1, 2) if all(d % (p * p) for p in small if p * p <= d)]
rem = 0.0
for d in sqf:
    cnt = flag[(d - 2) % d if d > 1 else 0:X + 1:d].count(1) if d > 1 else PI
    rem += abs(cnt - LI / len(coprime(d)))
twins = sum(1 for p in primes if p + 2 <= X and flag[p + 2])
print(f"twin pairs below 10^6: {twins}; twin sieve: {len(sqf)} odd squarefree d up to 1000; sum of |pi(x; d, -2) - li(x)/phi(d)| = {rem:.2f}")
big = {}
for q in (1009, 10007, 99991, 999983):
    c = {}
    for p in primes:
        if q % p: c[p % q] = c.get(p % q, 0) + 1
    f = len(coprime(q)); share = LI / f
    lo = min(c.values()) if len(c) == f else 0; hi = max(c.values())
    big[q] = max(hi - share, share - lo) / share
    print(f"q = {q}: phi {f}; share {share:.3f}; classes hold {lo} to {hi}; relative miss {100 * big[q]:.1f} percent")
print(f"q from 500001 to 1000000: each E(q) >= 1/2, so they add at least {X // 4}; "
      f"that is {X / 4 / (X / math.log(X)):.2f} times x/ln x")
S_all = sum(max(abs(flag[a:X + 1:q].count(1) - LI / len(coprime(q))) for a in range(q)) for q in range(1, Q + 1))
S_q = sum(max(abs(v - LI / q) for v in counts_sieve(X, q)) for q in range(1, Q + 1))
print(f"breaks: all classes, not only coprime ones: S = {S_all:.2f}; share li/q in place of li/phi(q): S = {S_q:.2f}")
assert len(primes) == len(td) == 78498 and agree and twins == 8169       # two roads to every class count
assert all(sum(counts_sieve(X, q)) == PI - sum(1 for p in small if q % p == 0) for q in range(1, Q + 1))
assert abs(LI - li_b) < 1e-4 and abs(LI - 78627.55) < 0.001             # li two ways, and the house table
assert abs(E6[1] - (li_b - len(td))) < 1e-4                             # q = 1 against Simpson's li and trial division
res100 = sum(max(abs(v - LI / len(c)) for v in c) for c in (counts_res(td, q) for q in range(1, 101)))
assert abs(sum(E6[q] for q in range(1, 101)) - res100) < 1e-6             # E(q) to 100 by the second road
assert all(r < 1 for r in ratios) and ratios[0] > ratios[1] > ratios[2]  # S below x/ln x, and the ratio falls
assert S < 0.01 * triv and min(big.values()) > 0.2 and big[999983] > 1   # far below trivial; huge q fail
assert S_all > 2 * S and S_q > 2 * S                                     # the broken versions really break
print("ALL CHECKS PASS")
