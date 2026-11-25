# Hasse-Minkowski and the Hilbert symbol -- the check behind the card.  Standard
# library only.  Road 1: the Hilbert symbol by its formula.  Road 2: brute-force
# search for primitive solutions mod p^N, which Hensel's lemma lifts.  Road 3:
# Legendre's box builds rational solutions; direct searches confirm yes and no.
from math import gcd, isqrt

def split(n, p):                     # n = p^k * u with p not dividing u
    k = 0
    while n % p == 0:
        n //= p
        k += 1
    return k, n

def leg(u, p):                       # Legendre symbol by Euler's criterion
    r = pow(u % p, (p - 1) // 2, p)
    return -1 if r == p - 1 else r

def hs(a, b, p, odd_rule=False):     # road 1: (a, b)_p; p = 0 is the real place
    if p == 0:
        return -1 if a < 0 and b < 0 else 1
    al, u = split(a, p)
    be, v = split(b, p)
    if p == 2 and not odd_rule:
        e = lambda w: (w - 1) // 2 % 2
        w = lambda w: (w * w - 1) // 8 % 2
        return (-1) ** ((e(u) * e(v) + al * w(v) + be * w(u)) % 2)
    return (-1) ** (al * be * (p - 1) // 2 % 2) * leg(u, p) ** be * leg(v, p) ** al

def bf(a, b, p):                     # road 2: z^2 = a x^2 + b y^2, primitive, mod p^N
    m = p ** (5 if p == 2 else 3)
    sq = {z * z % m for z in range(m)}
    usq = {z * z % m for z in range(m) if z % p}
    for x in range(m):
        for y in range(m):
            t = (a * x * x + b * y * y) % m
            if t in (sq if x % p or y % p else usq):
                return 1
    return -1

def primes(n): return [p for p in range(2, n + 1) if all(p % q for q in range(2, isqrt(p) + 1))]

def places(a, b):                    # the real place and every prime dividing 2ab
    return [0] + [p for p in primes(abs(2 * a * b)) if (2 * a * b) % p == 0]

def local_yes(a, b): return all(hs(a, b, p) == 1 for p in places(a, b))

def prodp(a, b):                     # product of (a, b)_v over every place v
    out = 1
    for p in places(a, b):
        out *= hs(a, b, p)
    return out

for n in (3, 5):                     # the examples: x^2 + y^2 = n z^2 is x^2 = n z^2 - y^2
    s = {p: hs(n, -1, p) for p in [0, 2, 3, 5, 7]}
    print(f"({n}, -1) at " + ", ".join(f"{p or 'inf'}: {s[p]:+d}" for p in s) + f"; product over all places {prodp(n, -1):+d}")
    assert prodp(n, -1) == 1
assert [hs(3, -1, p) for p in (0, 2, 3)] == [1, -1, -1] and local_yes(5, -1)
SF = [-7, -6, -5, -3, -2, -1, 1, 2, 3, 5, 6, 7]
agree = sum(hs(a, b, p) == bf(a, b, p) for a in SF for b in SF for p in (2, 3, 5, 7))
print(f"formula against brute-force search, squarefree a, b from -7 to 7, p = 2, 3, 5, 7: {agree} of {4 * len(SF) ** 2} agree")
assert agree == 4 * len(SF) ** 2
bad = sum(prodp(a, b) != 1 for a in range(-30, 31) for b in range(-30, 31) if a and b)
print(f"product formula over all 3,600 pairs a, b from -30 to 30: {bad} failures")
assert bad == 0
P = [p for p in primes(100) if p > 2]
rec = sum(leg(q, p) * leg(p, q) == hs(p, q, 2) for p in P for q in P if p != q)
print(f"odd primes p != q below 100: (q/p)(p/q) = (p, q)_2 in {rec} of {len(P) * (len(P) - 1)} pairs")
assert rec == len(P) * (len(P) - 1)

def prim(n, m):                      # primitive x^2 + y^2 = n z^2 mod m, n multiple of p
    return sum((x * x + y * y - n * z * z) % m == 0 and gcd(gcd(x, y), gcd(z, m)) == 1
               for x in range(m) for y in range(m) for z in range(m))
print(f"x^2 + y^2 = 3z^2: primitive solutions mod 3: {prim(3, 3)}, mod 9: {prim(3, 9)}")
assert prim(3, 3) > 0 and prim(3, 9) == 0

def legendre(a, b, c):               # road 3: a x^2 + b y^2 = c z^2, a, b, c > 0
    r = [next(t for t in range(m) if (k * t * t - j) % m == 0) for k, j, m in
         ((b, c, a), (c, a, b), (a, -b, c))]
    X, Y, Z = isqrt(b * c), isqrt(a * c), isqrt(a * b)
    box = [(x, y, z) for x in range(-X, X + 1) for y in range(-Y, Y + 1) for z in range(Z + 1)
           if (x, y, z) != (0, 0, 0) and (y - r[0] * z) % a == 0 and (z - r[1] * x) % b == 0
           and (x - r[2] * y) % c == 0]
    vals = sorted({a * x * x + b * y * y - c * z * z for x, y, z in box})
    x, y, z = next(v for v in box if a * v[0] ** 2 + b * v[1] ** 2 - c * v[2] ** 2 in (0, a * b * c))
    q = a * x * x + b * y * y - c * z * z
    print(f"Legendre {a}x^2 + {b}y^2 = {c}z^2: roots {r}, box {X} x {Y} x {Z}, {len(box)} vectors, "
          f"values of Q {vals}; first ({x}, {y}, {z}), Q = {q}")
    if q:                            # Q = abc: the identity turns it into a zero
        x, y, z = x * z + b * y, y * z - a * x, z * z + a * b
    g = gcd(gcd(x, y), z)
    x, y, z = abs(x // g), abs(y // g), abs(z // g)
    assert a * x * x + b * y * y == c * z * z and z > 0
    print(f"  solution ({x}, {y}, {z}): {a * x * x} + {b * y * y} = {c * z * z}")
legendre(1, 1, 5)
legendre(11, 13, 2)
yes = [n for n in range(1, 51) if local_yes(n, -1)]
srch = [n for n in range(1, 51) if any(isqrt(n * z * z - x * x) ** 2 == n * z * z - x * x
        for z in range(1, 30) for x in range(isqrt(n) * z + 1))]
r2 = [n for n in range(1, 51) if any(isqrt(n - x * x) ** 2 == n - x * x for x in range(isqrt(n) + 1))]
print(f"x^2 + y^2 = n z^2, n = 1 to 50: {len(yes)} pass every local test: {yes}")
print(f"  same list by search with z below 30: {yes == srch}; by n = a^2 + b^2 in whole numbers: {yes == r2}")
assert yes == srch == r2
house = [p for p in primes(200) if local_yes(p, -5)]
whole = [p for p in primes(200) if any(isqrt(p - 5 * y * y) ** 2 == p - 5 * y * y for y in range(isqrt(p // 5) + 1))]
print(f"house: primes below 200 with x^2 + 5y^2 = p z^2 locally solvable: {house}")
print(f"  {len(house)} primes, equal to whole-number x^2 + 5y^2 = p: {house == whole}; residues mod 20 {sorted({p % 20 for p in house})}")
assert house == whole and {p % 20 for p in house if p != 5} == {1, 9}
f = lambda x, y, z: 3 * x ** 3 + 4 * y ** 3 + 5 * z ** 3
for p in (2, 3, 5):                  # Selmer: a point mod p^(2v+1) where d/dt has v_p = v
    for i in range(3):
        v = split(3 * (3, 4, 5)[i], p)[0]
        m = p ** (2 * v + 1)
        w = next((t for t in ((x, y, z) for x in range(m) for y in range(m) for z in range(m))
                  if t[i] % p and f(*t) % m == 0), None)
        if w:
            print(f"Selmer at {p}: ({w[0]}, {w[1]}, {w[2]}) gives {f(*w)}, divisible by {p}^{2 * v + 1}; "
                  f"unit {'xyz'[i]}, slope {3 * (3, 4, 5)[i]}{'xyz'[i]}^2 has v_{p} = {v}: lifts")
            break
    assert w
cnt = {p: sum(f(x, y, z) % p == 0 for x in range(p) for y in range(p) for z in range(p)) - 1
       for p in primes(200) if p > 5}
print(f"Selmer mod p, 7 <= p < 200: fewest nonzero solutions {min(cnt.values())}, at p = {min(cnt, key=cnt.get)}; "
      f"real point (1, 1, {-(7 / 5) ** (1 / 3):.6f})")
assert min(cnt.values()) > 0
B, hits = 60, 0
for x in range(-B, B + 1):           # 5 z^3 = -(3x^3 + 4y^3): is it 5 times a cube?
    for y in range(-B, B + 1):
        t = -(3 * x ** 3 + 4 * y ** 3)
        r = round(abs(t / 5) ** (1 / 3)) * (1 if t >= 0 else -1)
        hits += (x, y) != (0, 0) and any(5 * z ** 3 == t for z in (r - 1, r, r + 1))
print(f"Selmer over Q: nonzero solutions with |x|, |y| <= {B}: {hits}")
assert hits == 0
wrong = hs(3, -1, 2, odd_rule=True)  # the odd-prime formula used at p = 2
print(f"mistake, odd-prime rule at 2: (3, -1)_2 comes out {wrong:+d}, product over places "
      f"{hs(3, -1, 0) * wrong * hs(3, -1, 3):+d}; true (3, -1)_2 = {hs(3, -1, 2):+d}")
assert hs(3, -1, 0) * wrong * hs(3, -1, 3) == -1
print(f"mistake, skip 2 and inf for x^2 + y^2 + z^2 = 0: odd primes say yes; (-1, -1) at 2: {hs(-1, -1, 2):+d}, "
      f"at inf: {hs(-1, -1, 0):+d}")
assert hs(-1, -1, 2) == hs(-1, -1, 0) == -1 and all(hs(-1, -1, p) == 1 for p in P)
print("ALL CHECKS PASS")
