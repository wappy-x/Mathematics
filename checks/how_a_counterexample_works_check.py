# Counterexamples -- the check behind the card.  Standard library only.
# Three "for every" claims, each refuted by one exact witness, and each witness
# reached by two roads: a search that finds it, and a direct exact check of it.
import math

def smallest_factor(n):                     # trial division, written out
    d = 2
    while d * d <= n:
        if n % d == 0:
            return d
        d += 1 if d == 2 else 2
    return n

def is_prime(n):
    return n >= 2 and smallest_factor(n) == n

def comb(n, k):                             # n choose k, written out
    c = 1
    for i in range(k):
        c = c * (n - i) // (i + 1)
    return c

print("Claim 1 (Fermat, 1640): every 2^(2^m) + 1 is prime")
fermat = [2 ** (2 ** m) + 1 for m in range(6)]
for m, F in enumerate(fermat):
    p = smallest_factor(F)
    print(f"  m={m}  {F:>10}  " + ("prime" if p == F else f"divisible by {p}"))
cands = [p for p in range(65, 642, 64) if is_prime(p)]   # Euler: a factor is 1 + a multiple of 64
print(f"  primes one more than a multiple of 64, up to 641: {cands}")
hits = [p for p in cands if fermat[5] % p == 0]
x, chain = 2, []
for _ in range(5):                                       # square five times: 2^32 mod 641
    x = x * x % 641
    chain.append(x)
print(f"  squaring 2 mod 641: 2^2,2^4,2^8,2^16,2^32 -> {chain}")
print(f"  641 = 5*2^7 + 1 = {5 * 2 ** 7 + 1} = 5^4 + 2^4 = {5 ** 4 + 2 ** 4}")
cof = fermat[5] // 641
print(f"  witness: 2^32 + 1 = 641 x {cof}; cofactor prime: {is_prime(cof)}")
assert [is_prime(F) for F in fermat] == [True] * 5 + [False]
assert hits == [641] and cands.index(641) == 4 and chain[-1] == 640 and 641 * cof == fermat[5]

print("Claim 2 (Goldbach, 1752): every odd composite is a prime + 2 x a square")
N = 6000
sieve = [False, False] + [True] * (N - 1)
for i in range(2, int(N ** 0.5) + 1):
    if sieve[i]:
        for j in range(i * i, N + 1, i):
            sieve[j] = False
def has_form(n):
    k = 1
    while 2 * k * k < n:
        if sieve[n - 2 * k * k]:
            return k
        k += 1
    return 0
odd_comp = [n for n in range(9, N + 1, 2) if not sieve[n]]
fails = [n for n in odd_comp if has_form(n) == 0]
passed = sum(1 for n in odd_comp if n < fails[0])
print(f"  odd composites 9..{N}: {len(odd_comp)}; failures: {fails}")
print(f"  odd composites below {fails[0]} that fit: {passed}, first ones: "
      + ", ".join(f"{n}={n - 2 * has_form(n) ** 2}+2*{has_form(n)}^2" for n in odd_comp[:3]))
rest = [5777 - 2 * k * k for k in range(1, 5777) if 2 * k * k < 5777]  # road 2: no sieve
print(f"  5777 = {smallest_factor(5777)} x {5777 // smallest_factor(5777)}; "
      f"5777 - 2 x (1^2..53^2): {len(rest)} numbers, primes among them: "
      f"{sum(1 for r in rest if is_prime(r))}")
assert fails == [5777, 5993] and not any(is_prime(r) for r in rest)
assert all(not is_prime(n) for n in fails)

print("Claim 3 (Euler, 1769): k-th powers need at least k terms to sum to a k-th power")
w = (27, 84, 110, 133, 144)
for v in w:
    print(f"  {v:>3}^5 = {v ** 5:>11}")
lhs = sum(v ** 5 for v in w[:4])
print(f"  sum of the four = {lhs}; 144^5 = {w[4] ** 5}; equal: {lhs == w[4] ** 5}")
print(f"  mod 30 shortcut: 27+84+110+133 = {sum(w[:4])} = {sum(w[:4]) % 30} mod 30, "
      f"144 = {144 % 30} mod 30")
E = 150                                                  # road 2: meet-in-the-middle search
p5 = [i ** 5 for i in range(E + 1)]
pairs = {}
for a in range(1, E):
    for b in range(a, E):
        pairs.setdefault(p5[a] + p5[b], []).append((a, b))
found = []
for e in range(2, E + 1):
    for c in range(1, e):
        for d in range(c, e):
            r = p5[e] - p5[c] - p5[d]
            if r < 2:
                break
            for a, b in pairs.get(r, []):
                if b <= c:
                    found.append((a, b, c, d, e))
print(f"  search a<=b<=c<=d<e<={E}: solutions {found}")
cand = sum(comb(e + 2, 4) for e in range(2, 144))
print(f"  candidates a<=b<=c<=d<e, e < 144, all failing: {cand} (formula C(146,5) = {comb(146, 5)})")
s = tuple(2 * v for v in w)
print(f"  doubled witness {s}: still equal: {sum(v ** 5 for v in s[:4]) == s[4] ** 5}")
frye, elkies = (95800, 217519, 414560, 422481), (2682440, 15365639, 18796760, 20615673)
for name, q in (("Frye 1988", frye), ("Elkies 1988", elkies)):
    print(f"  k=4, {name}: {q[0]}^4+{q[1]}^4+{q[2]}^4 = {q[3]}^4 is {sum(v ** 4 for v in q[:3]) == q[3] ** 4}")
print(f"  not a witness: 3^3+4^3+5^3 = {3 ** 3 + 4 ** 3 + 5 ** 3} = 6^3, but that is k = 3 terms, not fewer")
assert found == [w] and lhs == w[4] ** 5 == 61917364224 and cand == comb(146, 5)
assert sum(w[:4]) % 30 == w[4] % 30 and sum(v ** 5 for v in s[:4]) == s[4] ** 5
assert all(sum(v ** 4 for v in q[:3]) == q[3] ** 4 for q in (frye, elkies))

print("Trap: a near miss is not a witness (k = 12)")
fl, fr, fa = 1.0, 1.0, 1.0
for _ in range(12):
    fl, fr, fa = fl * 1782.0, fr * 1841.0, fa * 1922.0
gap = (fl + fr - fa) / fa
print(f"  floats: 1782^12+1841^12 ~ {math.floor((fl + fr) / 1e29)} x 10^29, 1922^12 ~ {math.floor(fa / 1e29)} x 10^29")
print(f"  relative gap, parts per 10^12: {math.floor(gap * 1e12 + 0.5)}")
L, R = 1782 ** 12 + 1841 ** 12, 1922 ** 12
print(f"  exact: left is {'odd' if L % 2 else 'even'}, right is {'odd' if R % 2 else 'even'}; equal: {L == R}")
assert L != R and L % 2 == 1 and R % 2 == 0 and 0 < -gap < 1e-9

print("Successes before the first failure (log10, one # per 0.25)")
rows = [("Fermat, cases m=0..4", 5), ("Goldbach, odd composites", passed),
        ("Euler k=5, candidates", cand), ("Polya, n=2.., quoted", 906150257 - 2)]
for name, v in rows:
    lg = math.log10(v)
    print(f"  {name:<26}{'#' * int(lg * 4 + 0.5):<36}{v:>11}  {lg:.2f}")
print("ALL CHECKS PASS")
