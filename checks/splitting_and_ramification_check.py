# Splitting and ramification -- the check behind the card.  Nothing is imported.
# Field Q(sqrt-5), ring of integers Z[sqrt-5], f(x) = x^2 + 5, d_K = -20.  Every
# prime is classified three ways: road 1 counts the roots of f mod p by trying
# every residue; road 2 counts nilpotents and units in the residue ring
# O_K/pO_K, never touching f's roots; road 3 is Euler's criterion for -5 and the
# rule mod 20 that reciprocity gives.  The cubic Q(cbrt 2) shows patterns past 2.
def primes_below(n):                     # sieve of Eratosthenes, written out here
    s = [True] * n
    s[0] = s[1] = False
    for i in range(2, int(n ** 0.5) + 1):
        if s[i]:
            s[i * i::i] = [False] * len(s[i * i::i])
    return [i for i in range(n) if s[i]]

def powmod(a, k, m):                     # square-and-multiply
    out, a = 1, a % m
    while k:
        if k & 1:
            out = out * a % m
        a, k = a * a % m, k >> 1
    return out

def roots(coeffs, p):                    # road 1: residues r with f(r) = 0 mod p
    return [r for r in range(p) if sum(c * r ** i for i, c in enumerate(coeffs)) % p == 0]

def by_roots(p, f=(5, 0, 1)):            # quadratic f: 2 roots split, 1 ramifies, 0 inert
    return {2: "split", 1: "ramified", 0: "inert"}[len(roots(f, p))]

def residue_ring(p):                     # road 2: a + b sqrt-5 with a, b taken mod p
    nil = sum(1 for a in range(p) for b in range(p)          # nonzero, square 0: the nilpotents
              if (a or b) and (a * a - 5 * b * b) % p == 0 and 2 * a * b % p == 0)
    units = sum(1 for a in range(p) for b in range(p) if (a * a + 5 * b * b) % p)
    kind = "ramified" if nil else ("split" if units == (p - 1) ** 2 else "inert")
    return nil, units, kind

def by_euler(p):                         # road 3a: p | d_K ramifies, else is -5 a square?
    if 20 % p == 0:
        return "ramified"
    return "split" if powmod(-5, (p - 1) // 2, p) == 1 else "inert"

def by_mod20(p):                         # road 3b: reciprocity's answer, a rule mod 20
    return "ramified" if 20 % p == 0 else ("split" if p % 20 in (1, 3, 7, 9) else "inert")

def mul(x, y):                           # (a + b sqrt-5)(c + d sqrt-5) in Z[sqrt-5]
    return (x[0] * y[0] - 5 * x[1] * y[1], x[0] * y[1] + x[1] * y[0])

def is_norm(p):                          # is p = a^2 + 5b^2 for whole a, b?
    return any(int((p - 5 * b * b) ** 0.5) ** 2 == p - 5 * b * b
               for b in range(int((p / 5) ** 0.5) + 1))

EF = {"split": "e = 1, f = 1 twice", "inert": "e = 1, f = 2", "ramified": "e = 2, f = 1"}
print("field Q(sqrt-5): f(x) = x^2 + 5, ring of integers Z[sqrt-5], d_K = 0^2 - 4*5 =", 0 - 4 * 5)
for p in (2, 3, 5, 7, 11, 29):
    nil, units, kind = residue_ring(p)
    print(f"p = {p}: roots of x^2 + 5 mod p {roots((5, 0, 1), p)}; nilpotents {nil}, "
          f"units {units} of {p * p}; {by_roots(p)} ({EF[by_roots(p)]})")
small = primes_below(200)
road2_ok = all(residue_ring(p)[2] == by_roots(p) for p in small)
print(f"road 2 agrees with road 1 for all {len(small)} primes below 200: {'yes' if road2_ok else 'no'}")
prod29 = mul((3, 2), (3, -2))
r29 = roots((5, 0, 1), 29)
print(f"29: (3 + 2 sqrt-5)(3 - 2 sqrt-5) = {prod29[0]} + {prod29[1]} sqrt-5; norm 3^2 + 5*2^2 = {9 + 5 * 4}")
print(f"square roots of -5 mod 29: {r29}; 13^2 = {13 * 13} = 5*29 + {13 * 13 - 5 * 29}, and {13 * 13 - 5 * 29} = -5 mod 29")
print(f"3 + 2*{r29[0]} = {3 + 2 * r29[0]}, so 3 + 2 sqrt-5 lies in (29, sqrt-5 - {r29[0]})")
print(f"5: (sqrt-5)^2 = {mul((0, 1), (0, 1))[0]}, so (5) = (sqrt-5)^2, one prime, e = 2")
t, u = (2, 0), (1, 1)                            # the generators 2 and 1 + sqrt-5
sq2 = [mul(t, t), mul(t, u), mul(u, u)]          # the square's generators: all products of two
even = all(a % 2 == 0 and b % 2 == 0 for a, b in sq2)
two = (sq2[1][0] - sq2[2][0] - sq2[0][0], sq2[1][1] - sq2[2][1] - sq2[0][1])
print(f"2: (2, 1 + sqrt-5)^2 holds {sq2}, all multiples of 2: {'yes' if even else 'no'}; "
      f"(2 + 2 sqrt-5) - (-4 + 2 sqrt-5) - 4 = {two[0]} + {two[1]} sqrt-5, so it is (2)")
print(f"3 = a^2 + 5b^2 has a solution: {'yes' if is_norm(3) else 'no'}; yet x^2 + 5 = (x - 1)(x - 2) mod 3, "
      f"so (3) = (3, sqrt-5 - 1)(3, sqrt-5 - 2)")
r3 = roots((5, 0, 1), 3)
print(f"6 = 2*3 = (1 + sqrt-5)(1 - sqrt-5), norm {1 + 5}: 1 + sqrt-5 lies in (3, sqrt-5 - {r3[1]}) as "
      f"1 + {r3[1]} = {1 + r3[1]}; 1 - sqrt-5 in (3, sqrt-5 - {r3[0]}) as 1 - {r3[0]} = {1 - r3[0]}")
big = primes_below(10000)
agree = all(by_roots(p) == by_euler(p) == by_mod20(p) for p in big)
print(f"roads 1 and 3 agree on all {len(big)} primes below 10,000: {'yes' if agree else 'no'}")
table = {}
for n in (100, 1000, 10000):
    kinds = [by_euler(p) for p in big if p < n]
    table[n] = [len(kinds)] + [kinds.count(k) for k in ("split", "inert", "ramified")]
    s, i = table[n][1], table[n][2]
    print(f"primes below {n}: {table[n][0]}; split {s}, inert {i}, ramified {table[n][3]}; "
          f"split share of unramified {s / (s + i):.4f}")
ram = [p for p in big if by_roots(p) == "ramified"]
dk_primes = [q for q in primes_below(21) if 20 % q == 0]
print(f"ramified primes below 10,000: {ram}; primes dividing d_K = -20: {dk_primes}")
q1000 = primes_below(1000)
spl = [p for p in q1000 if by_euler(p) == "split"]
nonprin = [p for p in spl if not is_norm(p)]
print(f"split primes below 1000 equal to a^2 + 5b^2: {len(spl) - len(nonprin)}; split but not: "
      f"{len(nonprin)}, first {nonprin[:6]}")
rule = all(is_norm(p) == (p % 20 in (1, 9)) for p in spl)
print(f"a^2 + 5b^2 exactly when p = 1 or 9 mod 20, among split primes below 1000: {'yes' if rule else 'no'}")
gauss = [f"{p} {({2: 'split', 1: 'ramified', 0: 'inert'})[len(roots((1, 0, 1), p))]}" for p in (2, 3, 5, 7, 13)]
print(f"Gaussian integers, x^2 + 1, d = -4: {', '.join(gauss)}")

def cubic(p):                            # x^3 - 2 mod p, read off its roots
    rs = roots((-2, 0, 0, 1), p)
    if any(3 * r * r % p == 0 for r in rs):          # also a root of f' = 3x^2: repeated
        return "ramified, e = 3"
    return {3: "split completely, f = 1, 1, 1", 1: "f = 1, 2", 0: "inert, f = 3"}[len(rs)]

print("cubic Q(cbrt 2): f(x) = x^3 - 2, d_K = -4*0^3 - 27*2^2 =", -27 * 4)
for p in (2, 3, 5, 7, 31):
    print(f"p = {p}: roots of x^3 - 2 mod p {roots((-2, 0, 0, 1), p)}; {cubic(p)}")
pat = [cubic(p).split(",")[0] for p in q1000 if cubic(p)[0] != "r"]
counts3 = [pat.count(k) for k in ("split completely", "f = 1", "inert")]
print(f"unramified primes below 1000: {len(pat)}; split completely {counts3[0]}, f = 1, 2 {counts3[1]}, "
      f"inert {counts3[2]}")
rep = [p for p in q1000 if cubic(p)[0] == "r"]
d108 = [q for q in primes_below(109) if 108 % q == 0]
print(f"shares {counts3[0] / len(pat):.4f}, {counts3[1] / len(pat):.4f}, {counts3[2] / len(pat):.4f}; "
      f"Chebotarev's 1/6, 1/2, 1/3 = {1 / 6:.4f}, {1 / 2:.4f}, {1 / 3:.4f}")
print(f"primes below 1000 where x^3 - 2 has a repeated root: {rep}; primes dividing 108: {d108}")
w1 = (roots((-5, 0, 1), 2), roots((-1, -1, 1), 2))
print(f"mistake 1, Z[sqrt5] for Q(sqrt5): x^2 - 5 mod 2 has roots {w1[0]}, a double root, so 2 looks "
      f"ramified; x^2 - x - 1 has roots {w1[1]}, so 2 is inert; d_K = 5, not 20")
print(f"mistake 2, no element of norm p read as inert: {len(nonprin)} split primes below 1000 misread, "
      f"first {nonprin[:3]}")
w3 = [p for p in q1000 if 20 % p and (powmod(5, (p - 1) // 2, p) == 1) != (by_euler(p) == "split")]
print(f"mistake 3, testing 5 instead of -5: {len(w3)} of {len(q1000) - 2} primes below 1000 misread, first {w3[:3]}")
print(f"mistake 4, ramified primes read off -5 instead of d_K = -20: {[q for q in (2, 3, 5) if 5 % q == 0]}, "
      f"missing 2")
assert road2_ok and agree and ram == dk_primes == [2, 5]                       # three roads, one answer
assert r29 == [13, 16] and (3 + 2 * r29[0]) % 29 == 0                         # roots of x^2 + 5 mod 29
assert prod29 == (29, 0) and even and two == (2, 0)          # ring products: (29) and (2, 1 + sqrt-5)^2 = (2)
assert table[1000] == [168, 81, 85, 2] and table[10000] == [1229, 614, 613, 2]
assert rule and len(nonprin) == 45 and not is_norm(3) and r3 == [1, 2] and (1 + r3[1]) % 3 == 0 == (1 - r3[0]) % 3
assert rep == d108 == [2, 3] and counts3 == [24, 86, 56] and w1 == ([1], []) and len(w3) == 87
print("ALL CHECKS PASS")
