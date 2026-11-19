# Fermat's last theorem: the descent for n = 4, and Kummer's regular primes.  Standard
# library only.  Search is evidence; the descent is the proof, so the code checks the
# descent's parametrisation two ways and computes the regular primes two ways.
from math import gcd, isqrt

def sq(n):                                 # is n a perfect square?
    return n >= 0 and isqrt(n) ** 2 == n

def root4(n):                              # largest w with w^4 <= n
    return isqrt(isqrt(n))

def icbrt(n):                              # largest c with c^3 <= n
    c = round(n ** (1 / 3))
    while c ** 3 > n: c -= 1
    while (c + 1) ** 3 <= n: c += 1
    return c

def case_for(n):                           # 4 if 4 divides n, else the smallest odd prime factor
    if n % 4 == 0: return 4
    m = n
    while m % 2 == 0: m //= 2
    return next(d for d in range(3, m + 1) if m % d == 0)

def near_miss(a, b):                       # the descent run backwards from seeds a > b
    x, s, r = a * a - b * b, 2 * a * b, a * a + b * b
    return (x, 2 * r * s, r * r + s * s)   # x^4 + Y^2 = z^2

def irregular_by_bernoulli(p):             # B_0..B_{p-3} mod p by the recurrence
    B, row, hits = [1], [1, 1], []         # row holds C(n+1, k) mod p
    for n in range(1, p - 2):
        row = [1] + [(row[k - 1] + row[k]) % p for k in range(1, len(row))] + [1]
        s = sum(row[k] * B[k] for k in range(n)) % p
        B.append(-s * pow(n + 1, p - 2, p) % p)
        if n % 2 == 0 and B[n] == 0: hits.append(n)
    return hits

def irregular_by_power_sums(p):            # p | B_m  iff  1^m + ... + (p-1)^m = 0 mod p^2
    q, hits = p * p, []
    sq_j = [j * j % q for j in range(p)]
    cur = sq_j[:]
    for m in range(2, p - 2, 2):
        if sum(cur[1:]) % q == 0: hits.append(m)
        cur = [c * s % q for c, s in zip(cur, sq_j)]
    return hits

print("exponent -> case that covers it:", " ".join(f"{n}->{case_for(n)}" for n in range(3, 13)))
N = 1000
fourth = sum(1 for x in range(1, N + 1) for y in range(x, N + 1) if sq(x**4 + y**4))
cubes = sum(1 for x in range(1, N + 1) for y in range(x, N + 1) if icbrt(x**3 + y**3) ** 3 == x**3 + y**3)
trip = sum(1 for z in range(1, N + 1) for x in range(1, z) if x % 2 == 1 and
           sq(z * z - x * x) and z * z - x * x > 0 and gcd(x, z) == 1)
print(f"pairs 1 <= x <= y <= {N} tested: {N * (N + 1) // 2}")
print(f"x^4 + y^4 a perfect square: {fourth}")
print(f"x^3 + y^3 a perfect cube: {cubes}")
print(f"contrast, primitive x^2 + y^2 = z^2 with z <= {N}: {trip}")
Z = 10000
road_a = sorted((x, isqrt(z * z - x**4), z) for x in range(1, 100, 2) for z in range(x * x + 1, Z + 1)
                if sq(z * z - x**4) and gcd(x, z) == 1)
road_b = sorted(near_miss(a, b) for a in range(2, 100) for b in range(1, a)
                if (a - b) % 2 == 1 and gcd(a, b) == 1 and near_miss(a, b)[2] <= Z)
print(f"near misses x^4 + Y^2 = z^2, x odd, primitive, z <= {Z}: search {len(road_a)}, seeds {len(road_b)}")
print("first three:", ", ".join(f"{x}^4 + {Y}^2 = {z}^2" for x, Y, z in road_a[:3]))
pieces = [(a, b, a * a + b * b) for a in range(2, 100) for b in range(1, a)
          if (a - b) % 2 == 1 and gcd(a, b) == 1 and near_miss(a, b)[2] <= Z]
coprime = all(gcd(a, b) == gcd(a, c) == gcd(b, c) == 1 for a, b, c in pieces)
match = all(near_miss(a, b)[1] == 4 * a * b * c for a, b, c in pieces)
print(f"Y = 4 a b (a^2 + b^2) in all: {'yes' if match else 'no'}; pieces pairwise coprime: {'yes' if coprime else 'no'}")
print(f"Y a square in any: {'yes' if any(sq(Y) for _, Y, _ in road_a) else 'no'}; "
      f"all three pieces squares in any: {'yes' if any(sq(a) and sq(b) and sq(c) for a, b, c in pieces) else 'no'}")
x, Y, z = near_miss(4, 1)
print(f"trace from u, v = 2, 1: a, b = 4, 1; x = {x}, s = 8, r = 17, Y = 2 r s = {Y}, z = {z}")
print(f"{x}^4 + {Y}^2 = {x**4} + {Y**2} = {z**2} = {z}^2; Y = 4 x 4 x 1 x 17, a square: {'yes' if sq(Y) else 'no'}")
print(f"2^4 + 1^4 = {2**4 + 1}, a square: {'yes' if sq(17) else 'no'}; would-be w^4 = 17^2 = {17**2} < z = {z}")
ladder, b = [10**38], 10**38
while b >= 2:
    b = root4(b - 1); ladder.append(b)
print("descent ladder, bound on z:", " -> ".join(str(v) for v in ladder), "(z >= 2 is needed)")
print(f"9^3 + 10^3 = {9**3 + 10**3} = 12^3 + {9**3 + 10**3 - 12**3} = (9 + 10)(81 - 90 + 100) = 19 x {81 - 90 + 100}")
pts = sorted({(a, e) for e in range(1, 31) for a in range(-1000, 1001)
              if gcd(a, e) == 1 and sq(a**3 - a * e**4)})
print("points on y^2 = x^3 - x, x = a/e^2 with |a| <= 1000, e <= 30: x =",
      ", ".join(f"{a}/{e * e}" for a, e in pts), "and y = 0 each")
P = 200
primes = [p for p in range(3, P) if all(p % d for d in range(2, isqrt(p) + 1))]
irr_b = [(p, irregular_by_bernoulli(p)) for p in primes]
irr_s = [(p, irregular_by_power_sums(p)) for p in primes]
bad = [(p, h) for p, h in irr_b if h]
print(f"odd primes below {P}: {len(primes)}; irregular: {len(bad)}; regular: {len(primes) - len(bad)}")
print("irregular p with index 2k, p | B_2k (Bernoulli road):", ", ".join(f"{p} at {h}" for p, h in bad))
print(f"power-sum road agrees: {'yes' if irr_s == irr_b else 'no'}")
below100 = [p for p, h in bad if p < 100]
print(f"below 100: {len([p for p in primes if p < 100])} odd primes, irregular {below100}")
h23, irr23 = 3, any(p == 23 for p, _ in bad)          # h23 quoted from a published table
print(f"quoted: class number of Q(zeta_23) = {h23}, so unique factorisation fails; "
      f"23 divides it: {'yes' if h23 % 23 == 0 else 'no'}; 23 irregular by Bernoulli: {'yes' if irr23 else 'no'}")
e4 = (2682440, 15365639, 18796760, 20615673)
print(f"Euler's pattern fails: 2682440^4 + 15365639^4 + 18796760^4 - 20615673^4 = "
      f"{e4[0]**4 + e4[1]**4 + e4[2]**4 - e4[3]**4}")
print(f"what breaks: 2 x 8 = {2 * 8}, a square, gcd(2, 8) = {gcd(2, 8)}, 2 square: {'yes' if sq(2) else 'no'}")
assert fourth == 0 and cubes == 0                       # the theorem's prediction, searched
assert road_a == road_b and len(road_a) > 0             # descent parametrisation, two roads
assert z**2 - x**4 == Y**2 and not sq(Y) and Y == 4 * 4 * 1 * 17
assert ladder[-1] <= 1 and len(ladder) == 5             # four rungs to nothing
assert irr_s == irr_b                                   # regularity, two roads
assert [p for p, _ in bad] == [37, 59, 67, 101, 103, 131, 149, 157]   # quoted table
assert (h23 % 23 == 0) == irr23                         # table and Bernoulli road agree
assert pts == [(-1, 1), (0, 1), (1, 1)]
print("ALL CHECKS PASS")
