# The spectrum of a ring -- the check behind the card.  Nothing is imported and
# every number is an exact integer.  The points of Spec R are the prime ideals
# of R.  Roads: trial division against a zero-divisor search; a brute-force
# prime-ideal test on Z/n against prime factors; powering against "in every
# prime"; trial division in F_2[x] against Gauss's counting formula.
def is_prime(n):                              # road one: trial division
    d = 2
    while d * d <= n:
        if n % d == 0:
            return False
        d += 1
    return n > 1
def domain(n):                                # road two: Z/n has no zero divisors
    return n > 1 and all(a * b % n for a in range(1, n) for b in range(1, n))
def V(n):                                     # the closed set V(n): prime factors of n != 0
    out, d, n = [], 2, abs(n)
    while d * d <= n:
        if n % d == 0:
            out.append(d)
            while n % d == 0:
                n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def gcd(a, b):
    while b:
        a, b = b, a % b
    return a
def pts(s):
    return "{" + ", ".join(f"({p})" for p in s) + "}"
def spec_mod(n):                              # every ideal of Z/n, then the brute-force prime test
    ideals = {frozenset(a * r % n for r in range(n)) for a in range(n)}
    primes = [I for I in ideals if len(I) < n and
              all(a in I or b in I for a in range(n) for b in range(n) if a * b % n in I)]
    return len(ideals), sorted(min((x for x in I if x), default=n) for I in primes)
def nilpotent(n):                             # road one: some power is 0 (a^n is enough)
    out = []
    for a in range(n):
        x = 1
        for _ in range(n):
            x = x * a % n
        if x == 0:
            out.append(a)
    return out
def in_every_prime(n):                        # road two: zero at every point of Spec Z/n
    return [a for a in range(n) if all(a % p == 0 for p in V(n))]
def pmod(a, b):                               # remainder in F_2[x]; bit i holds the x^i coefficient
    while a and a.bit_length() >= b.bit_length():
        a ^= b << (a.bit_length() - b.bit_length())
    return a
def irreducible(f):                           # no factor of degree up to half
    return f > 1 and all(pmod(f, g) for g in range(2, f) if 2 * (g.bit_length() - 1) <= f.bit_length() - 1)
def mobius(m):
    f = V(m)
    sq = 1
    for p in f:
        sq *= p
    return 0 if sq != m else (-1) ** len(f)
def show(f):
    t = [("x^" + str(i) if i > 1 else "x" if i == 1 else "1") for i in range(f.bit_length() - 1, -1, -1) if f >> i & 1]
    return " + ".join(t)

print("== Spec Z: the points ==")
sieve = [p for p in range(2, 51) if is_prime(p)]
assert sieve == [n for n in range(2, 51) if domain(n)]           # (n) is prime exactly when Z/n is a domain
assert all(all(any(a * b % p == 1 for b in range(p)) for a in range(1, p)) for p in sieve)  # Z/p is a field
print("closed points (p), p <= 50:", " ".join(map(str, sieve)), f"({len(sieve)} of them)")
bigger = lambda n: [m for m in range(2, 51) if n % m == 0 and m != n]   # (n) inside (m), and (m) is not all of Z
assert all(bigger(p) == [] for p in sieve) and bigger(0)[0] == 2         # maximal: no (m) between (p) and Z
print(f"generic point (0): prime, as Z has no zero divisors; inside ({bigger(0)[0]}), so not maximal")
val = lambda f, p: f % p if p else f                                     # the value of f at (p); at (0) it is f itself
print("60 read at each point:", ", ".join(f"({p}) -> {val(60, p)}" for p in [2, 3, 5, 7, 11, 13, 0]))
print("== the Zariski topology on Spec Z ==")
for a in range(1, 121):
    for b in range(1, 121):
        assert sorted(set(V(a)) | set(V(b))) == V(a * b)            # union of closed sets: multiply
        assert sorted(set(V(a)) & set(V(b))) == V(gcd(a, b))        # overlap: add the ideals, gcd
print("V(60) =", pts(V(60)), " V(12) =", pts(V(12)), " V(10) =", pts(V(10)))
print("V(12) union V(10) = V(120) =", pts(V(120)), " V(12) meet V(10) = V(2) =", pts(V(gcd(12, 10))))
print("open D(6) = all points but", pts([p for p in sieve if val(6, p) == 0]) + "; up to 50 it holds", pts([p for p in sieve + [0] if val(6, p)]))
print("closure of (7) =", pts([p for p in sieve + [0] if val(7, p) == 0]), f" closure of (0) = all {sum(val(0, p) == 0 for p in sieve + [0])} points up to 50")
print("== Spec Z/60: the closed set V(60) as a space of its own ==")
for n in range(2, 41):
    k, gens = spec_mod(n)
    assert gens == V(n) and k == sum(1 for d in range(1, n + 1) if n % d == 0)
k60, g60 = spec_mod(60)
k30, g30 = spec_mod(30)
assert g60 == V(60) == g30
print(f"Z/60: {k60} ideals, {len(g60)} prime: {pts(g60)}")
print(f"Z/30: {k30} ideals, {len(g30)} prime: {pts(g30)}")
for n in range(2, 101):
    assert nilpotent(n) == in_every_prime(n)                      # nilradical = overlap of the primes
print("zero at every point of Spec Z/60:", in_every_prime(60), " nilpotent:", nilpotent(60), " 30^2 =", 30 * 30, "=", 30 * 30 // 60, "x 60")
print("zero at every point of Spec Z/30:", in_every_prime(30), " nilpotent:", nilpotent(30))
print("== Spec F_2[x]: closed points are irreducible polynomials ==")
count = [0] * 9
for f in range(2, 512):
    if irreducible(f):
        count[f.bit_length() - 1] += 1
for d in range(1, 9):
    gauss = sum(mobius(d // e) * 2 ** e for e in range(1, d + 1) if d % e == 0)
    assert gauss % d == 0 and count[d] == gauss // d                # Gauss's formula, a second road
    assert sum(e * count[e] for e in range(1, d + 1) if d % e == 0) == 2 ** d
print("degree 1 to 3:", "; ".join(show(f) for f in range(2, 16) if irreducible(f)))
print("closed points of degree 1..8:", " ".join(map(str, count[1:])), " up to degree 4:", sum(count[1:5]))
assert irreducible(0x11B)
print("x^8 + x^4 + x^3 + x + 1 (the AES byte field) is a point of degree 8:", irreducible(0x11B))
print("== Spec Z[x]: the curve x^2 + 1 above each prime ==")
above = {}
for p in sieve:
    roots = [x for x in range(p) if (x * x + 1) % p == 0]
    above[p] = len(roots) if roots else 1                         # no root: x^2 + 1 stays one point
    if p > 2:
        assert (len(roots) == 2) == (p % 4 == 1)                  # Fermat: two roots exactly when p = 1 mod 4
    if p <= 13:
        print(f"above ({p}): roots of x^2 + 1 mod {p}: {roots}; points: {above[p]}")
print("== the curve y^2 = x^3 - 2 as a scheme over Spec Z ==")
fibre7 = [(x, y) for x in range(7) for y in range(7) if (y * y - x ** 3 + 2) % 7 == 0]
assert len(fibre7) == 6 and (3 % 7, 5 % 7) in fibre7              # (3, 5) reduces into the fibre
print("over (0): holds (3, 5); over (7):", " ".join(f"({x}, {y})" for x, y in fibre7), f"-> {len(fibre7)} points")
print("== what breaks ==")
back = [n for n in range(-50, 51) if n == 0]                             # Z -> Q pulls back Q's one prime (0)
print(f"maximal ideals only: Spec Q -> Spec Z sends (0) to ({back[0]}), inside ({bigger(back[0])[0]}), not maximal: no point to land on")
print(f"every ideal a point: Z/60 gets {k60} points, not {len(g60)}")
print(f"space without the ring: Z/60 and Z/30 both {len(g60)} points; nonzero nilpotents {len(nilpotent(60)) - 1} and {len(nilpotent(30)) - 1}")
least = min(n for n in range(1, 61) if all(n % p == 0 for p in V(60)))
assert least == 30
print(f"ideal of the set V(60): generated by {least}, not 60")
print("== try changing ==")
for n in [360, 64]:
    print(f"Z/{n}: points {pts(V(n))}; nilpotents {len(nilpotent(n))}, the multiples of {nilpotent(n)[1]}")
two = [p for p in sieve if p <= 13 and sum(1 for x in range(p) if (x * x + 2) % p == 0) == 2]
deg9 = sum(1 for f in range(512, 1024) if irreducible(f))
assert deg9 * 9 == 2 ** 9 - count[1] - 3 * count[3]                     # degrees 1, 3, 9 divide 9
print("x^2 + 2 splits into two points above:", pts(two), " degree-9 points of Spec F_2[x]:", deg9)
xs = [40 + 52 * i for i in range(9)]
print("figure, closed points x:", " ".join(f"{p}@{x}" for p, x in zip([2, 3, 5, 7, 11, 13, 17, 19, 23], xs)), "y=100; generic band y=170")
print("ALL CHECKS PASS")
