# Infinite Galois theory: Gal(algebraic closure of F_2 / F_2) as compatible residues, and Q(sqrt 2, sqrt 3, ...).
from math import gcd
from itertools import product, combinations

def lcm_upto(m):
    L = 1
    for n in range(1, m + 1):
        L = L * n // gcd(L, n)
    return L

def two_part(n):
    t = 1
    while n % (2 * t) == 0:
        t *= 2
    return t

def e_mod(n):  # the symmetry e on GF(2^n): Frob^r with r = 1 mod the 2-part of n, 0 mod the odd part
    t = two_part(n)
    o = n // t
    return next(o * s % n for s in range(t) if o * s % t == 1 % t)

def pmod(a, m):  # remainder of polynomial a by polynomial m, bits as coefficients mod 2
    while a.bit_length() >= m.bit_length():
        a ^= m << (a.bit_length() - m.bit_length())
    return a

def irreducible(n):  # first degree-n polynomial with no factor of degree 1 to n/2
    return next(f for f in range(1 << n | 1, 1 << (n + 1), 2)
                if all(pmod(f, g) for g in range(2, 1 << (n // 2 + 1))))

def mul(a, b, f):
    r = 0
    while b:
        if b & 1:
            r ^= a
        b >>= 1
        a <<= 1
        if a >> (f.bit_length() - 1):
            a ^= f
    return r

def frob(x, k, f):  # x to the power 2^k
    for _ in range(k):
        x = mul(x, x, f)
    return x

def fixed(n, k):  # how many elements of GF(2^n) Frob^k leaves unmoved, by trying every one
    f = irreducible(n)
    return sum(frob(x, k, f) == x for x in range(1 << n))

# Road 1: the inverse limit at level 8 is the clock of lcm(1..8), by brute force over all tuples
M = 8
compat = [t for t in product(*[range(n) for n in range(1, M + 1)])
          if all(t[m - 1] % n == t[n - 1] for m in range(1, M + 1) for n in range(1, m) if m % n == 0)]
from_clock = {tuple(k % n for n in range(1, M + 1)) for k in range(lcm_upto(M))}
assert len(compat) == lcm_upto(M) and set(compat) == from_clock
print(f"tuples (r1..r{M}) with r_n in Z mod n: {len(list(product(*[range(n) for n in range(1, M + 1)])))}; compatible: {len(compat)}; lcm(1..{M}) = {lcm_upto(M)}; each is k mod n for one k: yes")
# Road 2: the symmetry e, residue by residue, and its fixed points counted in fields built here
E = [e_mod(n) for n in range(1, 17)]
assert all(e_mod(m) % n == e_mod(n) for m in range(1, 17) for n in range(1, m) if m % n == 0)
print(f"e on GF(2^n) is Frob^r, n = 1..16, r = {E}; compatible: yes")
fx = [fixed(n, e_mod(n)) for n in range(1, 13)]
assert fx == [2 ** (n // two_part(n)) for n in range(1, 13)]
print("elements of GF(2^n) fixed by e, n = 1..12, counted:", fx)
print("  = 2^(odd part of n): yes, so e fixes exactly the fields GF(2^m) with m odd")
fr = [fixed(n, 1) for n in range(1, 13)]
assert fr == [2] * 12
print("elements fixed by Frob itself, n = 1..12:", fr)
f12 = irreducible(12)
sub16 = [x for x in range(1 << 12) if frob(x, 4, f12) == x]
assert len(sub16) == 16 and all(frob(x, 9, f12) == frob(x, 1, f12) for x in sub16)
diff = sum(frob(x, 9, f12) != frob(x, 1, f12) for x in range(1 << 12))
print(f"GF(2^12) built from {f12:x}; GF(16) inside it has {len(sub16)} elements; Frob^9 = Frob on all of them: yes; on GF(2^12) they differ at {diff} elements")
for m in (2, 4, 6, 8, 10, 12, 16):
    L = lcm_upto(m)
    k = e_mod(L)
    assert all(k % n == e_mod(n) for n in range(1, m + 1))
    print(f"Frob^k agrees with e on GF(2^n) for every n <= {m}: lcm = {L}, smallest k = {k}")
wit = {k: next(n for n in range(1, 5000) if k % n != e_mod(n)) for k in range(-1000, 1001)}
worst = max(wit, key=lambda k: (wit[k], k))
print(f"every integer k with |k| <= 1000 differs from e on some GF(2^n): yes; largest n needed {wit[worst]}, at k = {worst}")
# Road 3: Q(sqrt 2, sqrt 3, ...): Frobenius sign patterns at primes q, evidence for k <= 8 that the degree is 2^k
N = 200000
sieve = bytearray([1]) * N
sieve[0] = sieve[1] = 0
for i in range(2, int(N ** 0.5) + 1):
    if sieve[i]:
        sieve[i * i::i] = bytearray(len(range(i * i, N, i)))
P = [2, 3, 5, 7, 11, 13, 17, 19]
odd = [q for q in range(3, N) if sieve[q]]
pat = {q: tuple(pow(p, (q - 1) // 2, q) == 1 for p in P) for q in odd}
for k in range(1, 9):
    seen, last = set(), 0
    for q in odd:
        if q not in P[:k] and pat[q][:k] not in seen:
            seen.add(pat[q][:k])
            last = q
    assert len(seen) == 2 ** k
    print(f"k = {k}: sign patterns of sqrt 2 .. sqrt {P[k - 1]} at primes q < {N}: {len(seen)} of {2 ** k}; last new one at q = {last}")
Q4 = [q for q in odd if q not in P[:4]]
cnt = {}
for q in Q4:
    cnt[pat[q][:4]] = cnt.get(pat[q][:4], 0) + 1
print(f"k = 4: {len(Q4)} primes q, each of the 16 patterns met between {min(cnt.values())} and {max(cnt.values())} times")
G = list(product([1, -1], repeat=4))
halves = list(combinations(G[1:], 7))
idx2 = [H for H in halves if all(tuple(a * b for a, b in zip(g, h)) in H + (G[0],) for g in H for h in H)]
D = [S for r in range(1, 5) for S in combinations(range(4), r)]
sign = lambda h, S: [1, -1][sum(h[i] == -1 for i in S) % 2]
match = [[S for S in D if all(sign(h, S) == 1 for h in H)] for H in idx2]
assert len(idx2) == 15 and all(len(m) == 1 for m in match) and len({m[0] for m in match}) == 15
ds = []
for m in match:
    d = 1
    for i in m[0]:
        d *= P[i]
    ds.append(d)
print(f"subgroups of index 2 in the 16 sign choices, by testing all {len(halves)} halves: {len(idx2)}; each fixes one sqrt d, d =", sorted(ds))
two8 = {(pow(2, (q - 1) // 2, q) == 1, pow(8, (q - 1) // 2, q) == 1) for q in odd}
assert len(two8) == 2
print(f"mistake, sqrt 2 with sqrt 8: sign patterns met {len(two8)} of 4, so degree 2, not 4")
# Road 4: the house example; the open subgroup fixing the splitting field of x^4 - 2 has index 8
hp = [q for q in odd if q < 10000]
split = [q for q in hp if sum(pow(x, 4, q) == 2 % q for x in range(q)) == 4]
assert abs(len(split) / len(hp) - 1 / 8) < 0.02
print(f"house: odd primes q < 10000: {len(hp)}; x^4 - 2 has 4 roots mod q for {len(split)}; share {len(split) / len(hp):.4f} against 1/8 = 0.1250")
k12 = e_mod(lcm_upto(12))
print(f"mistake, Frob^{k12} taken for e: {k12} mod 13 = {k12 % 13}; on GF(2^13) it fixes {fixed(13, k12 % 13)}, e fixes {fixed(13, e_mod(13))}")
assert fixed(13, k12 % 13) == 2 and fixed(13, e_mod(13)) == 8192
print("ALL CHECKS PASS")
