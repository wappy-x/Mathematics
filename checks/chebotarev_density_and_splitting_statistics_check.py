# Chebotarev density -- the check behind the card.  Standard library only.
# Field 1: Q(sqrt-5), from x^2 + 5, group of order 2.  Field 2: the splitting
# field of x^3 - 2, group S3 of order 6.  Every prime is sieved here, every
# Frobenius found two or three ways, and the shares compared with |C|/|G|.
N = 1_000_000
sieve = bytearray([1]) * (N + 1)
sieve[0] = sieve[1] = 0
for i in range(2, int(N ** 0.5) + 1):
    if sieve[i]:
        sieve[i * i::i] = bytearray(len(range(i * i, N + 1, i)))
primes = [p for p in range(N + 1) if sieve[p]]

def reps(form):                          # every value of a form up to N
    out, lim = set(), int(N ** 0.5) + 2
    for x in range(-lim, lim + 1):
        for y in range(0, lim + 1):
            v = form(x, y)
            if 0 < v <= N:
                out.add(v)
    return out

def first_rep(form, v):                  # smallest (x, y), y first, with form(x, y) = v
    return next((x, y) for y in range(v + 1) for x in range(v + 1) if form(x, y) == v)

def pct(a, b):
    return f"{100 * a / b:6.2f}%"

def yn(claim):
    return "yes" if claim else "no"

def bar(a, b):
    return "#" * round(60 * a / b)

# Road 1: Frobenius on sqrt-5 is multiplication by (-5)^((p-1)/2) mod p.
def frob_sign(p):
    return 1 if pow(-5 % p, (p - 1) // 2, p) == 1 else -1

SPLIT20 = {1, 3, 7, 9}                   # Road 2: reciprocity's answer mod 20
odd = [p for p in primes if p not in (2, 5)]
agree = all((frob_sign(p) == 1) == (p % 20 in SPLIT20) for p in odd)
brute = all((frob_sign(p) == 1) == any((x * x + 5) % p == 0 for x in range(p))
            for p in odd if p < 10_000)  # Road 3: hunt a square root of -5
small = [p for p in primes if p < 50]
print("field Q(sqrt-5): polynomial x^2 + 5, discriminant -20, group of order 2")
print("p=3: (-5)^1 mod 3 =", pow(-5 % 3, 1, 3), "| p=11: (-5)^5 mod 11 =", pow(-5 % 11, 5, 11))
sp = [p for p in small if p in odd and frob_sign(p) == 1]
ine = [p for p in small if p in odd and frob_sign(p) == -1]
print("primes below 50: ramified 2 5 | split", len(sp), ":", *sp, "| inert", len(ine), ":", *ine)
print("house: (1 + sqrt-5)(1 - sqrt-5) = 1 + 5 =", 1 + 5, "= 2 x 3")
print("Euler test = residue mod 20, every prime to 1,000,000:", yn(agree),
      "| = square-root hunt, p < 10,000:", yn(brute))
print("x          pi(x)    split    inert  split share  split - inert")
rows = {}
for x in (100, 1_000, 10_000, 100_000, 1_000_000):
    u = [p for p in odd if p <= x]
    s = sum(1 for p in u if frob_sign(p) == 1)
    rows[x] = (len(u) + 2, s, len(u) - s)
    print(f"{x:<9,} {len(u) + 2:7,} {s:8,} {len(u) - s:8,}     {pct(s, len(u))}  {2 * s - len(u):+6,}")
pi_N, split_N, _ = rows[N]
fates = [("split, principal    1 9 mod 20", {1, 9}),
         ("split, not principal 3 7 mod 20", {3, 7}),
         ("inert, splits in Q(i) 13 17", {13, 17}),
         ("inert, splits in Q(sqrt5) 11 19", {11, 19})]
counts = [sum(1 for p in odd if p % 20 in cl) for _, cl in fates]
print(f"the four fates to 1,000,000 among {len(odd):,} unramified primes; each predicted 25.00%")
for (name, _), c in zip(fates, counts):
    print(f"{name:<32}{c:7,} {pct(c, len(odd))} {bar(c, len(odd))}")
norm1 = reps(lambda x, y: x * x + 5 * y * y)
norm2 = reps(lambda x, y: 2 * x * x + 2 * x * y + 3 * y * y)
print("29 = x^2 + 5y^2 at", first_rep(lambda x, y: x * x + 5 * y * y, 29),
      "| 41 at", first_rep(lambda x, y: x * x + 5 * y * y, 41),
      "| 3 = 2x^2 + 2xy + 3y^2 at", first_rep(lambda x, y: 2 * x * x + 2 * x * y + 3 * y * y, 3),
      "| 7 at", first_rep(lambda x, y: 2 * x * x + 2 * x * y + 3 * y * y, 7))
f1 = all((p in norm1) == (p % 20 in {1, 9}) for p in odd)
f2 = all((p in norm2) == (p % 20 in {3, 7}) for p in odd)
print("p = x^2 + 5y^2 exactly when p = 1, 9 mod 20:", yn(f1),
      "| p = 2x^2 + 2xy + 3y^2 exactly when p = 3, 7 mod 20:", yn(f2))

# Field 2: x^3 - 2.  Roots mod p by the cube test (Road 1) and by brute force.
def roots_test(p):
    if p % 3 == 2:
        return 1
    return 3 if pow(2, (p - 1) // 3, p) == 1 else 0

big = [p for p in primes if p > 3]
cube_ok = all(roots_test(p) == sum(1 for x in range(p) if (x ** 3 - 2) % p == 0)
              for p in big if p < 10_000)
print("x^3 - 2: discriminant -108, group S3 of 6 symmetries, classes of size 1, 3, 2")
print("roots of x^3 - 2 mod 5, 7, 31:", *[[x for x in range(p) if (x ** 3 - 2) % p == 0]
      for p in (5, 7, 31)], "| 31 = x^2 + 27y^2 at", first_rep(lambda x, y: x * x + 27 * y * y, 31))
print("cube test = brute-force root count, every prime 5 to 10,000:", yn(cube_ok))
print("x          primes  1+1+1 (3 roots)  2+1 (1 root)   3 (0 roots)")
for x in (1_000, 10_000, 100_000, 1_000_000):
    u = [p for p in big if p <= x]
    c = [sum(1 for p in u if roots_test(p) == r) for r in (3, 1, 0)]
    print(f"{x:<9,} {len(u):7,} {c[0]:7,} {pct(c[0], len(u))} {c[1]:6,} {pct(c[1], len(u))}"
          f" {c[2]:6,} {pct(c[2], len(u))}")
s3 = c
print("S3 predicts                1/6 = 16.67%      1/2 = 50.00%  1/3 = 33.33%")
for name, k, d in (("1+1+1, identity", s3[0], 6), ("2+1, three swaps", s3[1], 2),
                   ("3, two 3-cycles", s3[2], 3)):
    print(f"{name:<17}{pct(k, len(u))} {bar(k, len(u))}")
form27 = reps(lambda x, y: x * x + 27 * y * y)
gauss = all((roots_test(p) == 3) == (p in form27) for p in big if p % 3 == 1)
print("for p = 1 mod 3: 2 is a cube mod p exactly when p = x^2 + 27y^2, to 1,000,000:", yn(gauss))

print("mistake 1, Q(cbrt 2) taken as Galois: predicts 33.33% split completely, count", pct(s3[0], len(u)))
print("mistake 2, every pattern equally likely: predicts 33.33% each, count",
      pct(s3[0], len(u)), pct(s3[1], len(u)), pct(s3[2], len(u)))
r3 = [x for x in range(3) if (x ** 3 - 2) % 3 == 0]
cubed = all(((x + 1) ** 3 - (x ** 3 - 2)) % 3 == 0 for x in range(3))
print(f"mistake 3, ramified p = 3: roots {r3}, one root, looks like 2+1;"
      f" but x^3 - 2 = (x + 1)^3 mod 3: {yn(cubed)}, a triple root")
print("mistake 4, 'splits' read as 'p = x^2 + 5y^2': predicts 50.00%, count",
      pct(counts[0], len(odd)))
assert agree and brute and f1 and f2 and cube_ok and gauss          # roads agree
assert pi_N == 78_498                                              # sieve vs known pi(10^6)
assert split_N == counts[0] + counts[1]                             # Euler count = mod-20 count
assert abs(split_N / (pi_N - 2) - 0.5) < 1.5 / (pi_N - 2) ** 0.5     # density 1/2, 3 std errors
assert all(abs(c / len(odd) - 0.25) < 0.01 for c in counts)          # four quarters
assert all(abs(k / len(u) - f) < 0.01 for k, f in zip(s3, (1 / 6, 1 / 2, 1 / 3)))
assert abs(s3[0] / len(u) - 1 / 3) > 0.1                           # mistake 1 really misses
assert r3 == [2]                                                    # mistake 3: one root mod 3
assert cubed                                                        # yet a triple root
print("ALL CHECKS PASS")
