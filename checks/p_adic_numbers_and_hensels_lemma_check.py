# The p-adic numbers and Hensel's lemma -- the check behind the card.  Standard
# library only.  Root 2 in the 7-adics by three roads: road 1 lifts a root one
# power of 7 at a time (Hensel's step); road 2 tries every residue mod 7^k;
# road 3 runs Newton's step on exact fractions (fractions.Fraction) and reads
# each one mod 7^k and as a decimal.  Then the failures, distances and Ostrowski.
from fractions import Fraction as F

P = 7

def v(n, p=P):                       # p-adic valuation: how many times p divides n
    k = 0
    while n % p == 0:
        n //= p
        k += 1
    return k

def inv(a, m):                       # inverse of a mod m, extended Euclid
    r0, r1, s0, s1 = a % m, m, 1, 0
    while r1:
        q = r0 // r1
        r0, r1, s0, s1 = r1, r0 - q * r1, s1, s0 - q * s1
    assert r0 == 1
    return s0 % m

def size(n, p=P):                    # |n|_p written as a fraction
    return "0" if n == 0 else f"1/{p ** v(n, p)}" if v(n, p) else "1"

def roots(c, p, k):                  # road 2: every x mod p^k with x^2 = c mod p^k
    m = p ** k
    return [x for x in range(m) if (x * x - c) % m == 0]

def lift(a, steps, show=False):      # road 1: root mod 7 -> root mod 7^(steps+1)
    out, pk = [a], P
    for k in range(1, steps + 1):
        fa = a * a - 2
        c, d = fa // pk, inv(2 * a, P)
        t = (-c * d) % P
        if show:
            print(f"lift {k}: a = {a}, f(a) = {fa} = 7^{k} * {c}, c mod 7 = {c % P}, "
                  f"f'(a) = {2 * a} = {2 * a % P} mod 7, inverse {d}, t = {t}, new root {a + t * pk} mod {pk * P}")
        a += t * pk
        pk *= P
        out.append(a)
    return out

print("f(x) = x^2 - 2, p = 7; roots mod 7:", roots(2, P, 1), "; nonzero squares mod 7:", sorted({x * x % P for x in range(1, P)}))
up = lift(3, 15, show=False)
lift(3, 3, show=True)
down = lift(4, 7)
print("lifts of 3, one power at a time:", up[:8])
print("lifts of 4, one power at a time:", down)
digits = [(up[15] // P ** i) % P for i in range(16)]
print("7-adic digits of the root above 3, lowest first:", digits)
print("7-adic digits of the root above 4, lowest first:", [(down[7] // P ** i) % P for i in range(8)])
for k in range(1, 7):                # road 2 against road 1
    r = roots(2, P, k)
    print(f"mod 7^{k} = {P ** k}: {len(r)} roots by search, lift of 3 is {up[k - 1]}, lift of 4 is {down[k - 1]}")
    assert r == sorted([up[k - 1], down[k - 1]])
x, newton_v = F(3), []               # road 3: Newton's step on exact fractions
for n in range(5):
    m = P ** (2 ** n)
    res = x.numerator * inv(x.denominator, m) % m
    newton_v.append(v(x.numerator ** 2 - 2 * x.denominator ** 2))
    print(f"Newton x_{n} = {x} = {float(x):.6f}; mod 7^{2 ** n} it is {res}; v_7(x^2 - 2) = {newton_v[-1]}")
    assert res == up[2 ** n - 1] % m
    x = x - (x * x - 2) / (2 * x)
assert abs(float(x) ** 2 - 2) < 1e-12
assert newton_v == [1, 2, 4, 8, 16]
lin = [v(a * a - 2) for a in up[:5]]
print(f"correct 7-adic digits after each step: one power at a time {lin}; Newton {newton_v}")
assert up[:4] == [3, 10, 108, 2166]
assert all((a * a - 2) % P ** (k + 1) == 0 for k, a in enumerate(up))
print(f"7-adic distances: |10 - 3| = {size(7)}, |108 - 10| = {size(98)}, |108 - 3| = {size(105)}; "
      f"|108|_7 = {size(108)}, |1/7|_7 = {P ** (v(7) - v(1))}")
print(f"|f(a)|_7 for 3, 10, 108: {size(7)}, {size(98)}, {size(108 * 108 - 2)}; f(108) = {108 * 108 - 2}")
bad7 = bad_abs = pairs = 0
for x1 in range(-300, 301):          # the strong triangle rule on 600 x 600 pairs
    for y1 in range(-300, 301):
        if x1 and y1 and x1 + y1:
            pairs += 1
            bad7 += v(x1 + y1) < min(v(x1), v(y1))
            bad_abs += abs(x1 + y1) > max(abs(x1), abs(y1))
print(f"strong triangle rule broken, of {pairs:,} pairs: 7-adic {bad7}, ordinary size {bad_abs:,}")
assert bad7 == 0
assert bad_abs > 0
n = 108 * 108 - 2
places = [p for p in range(2, n + 1) if n % p == 0 and all(p % q for q in range(2, int(p ** 0.5) + 1))]
prod = F(n)
for p in places:
    prod *= F(1, p ** v(n, p))
print(f"product formula for {n}: |n| = {n}, primes {places}, p-adic sizes "
      f"{', '.join(size(n, p) for p in places)}, product {prod}")
assert prod == 1
print("mistake 1, no root mod 7 to start: x^2 = 3 mod 7 has roots", roots(3, P, 1))
print("mistake 2, f'(a) divisible by 7: x^2 = 7 has roots", roots(7, P, 1), "mod 7 and", roots(7, P, 2), "mod 49")
c17 = [len(roots(17, 2, k)) for k in range(1, 7)]
print("mistake 3, p = 2 and x^2 = 17: roots mod 2, 4, ..., 64 number", c17)
f1, d1 = v(1 - 17, 2), v(2 * 1, 2)   # the sharper test at a = 1: |f(1)|_2 < |f'(1)|_2^2
print(f"sharper test for x^2 = 17 at a = 1: |f(1)|_2 = 1/{2 ** f1}, |f'(1)|_2^2 = 1/{2 ** (2 * d1)}, "
      f"passes: {'yes' if f1 > 2 * d1 else 'no'}")
gaps = [up[k + 1] - up[k] for k in range(3)]
print(f"mistake 4, ordinary size: gaps {gaps} grow; 7-adic sizes {', '.join(size(g) for g in gaps)} shrink")
assert roots(3, P, 1) == [] and roots(7, P, 2) == []
assert c17 == [1, 2, 4, 4, 4, 4]
assert f1 > 2 * d1                   # yet the sharper lemma puts sqrt 17 in Q_2
h = [3]
for k in range(1, 3):                # house example: x^2 + 5 = 0 has a root mod 7 that lifts
    c = (h[-1] ** 2 + 5) // P ** k
    h.append(h[-1] + (-c * inv(2 * h[-1], P)) % P * P ** k)
print(f"house example, x^2 = -5: lifts of 3 are {h}; a^2 + 5 = {[a * a + 5 for a in h]}")
assert h[-1] in roots(-5, P, 3) and h[1] in roots(-5, P, 2)
print("ALL CHECKS PASS")
