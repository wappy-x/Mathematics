# Birch-Swinnerton-Dyer and the congruent number problem -- the check behind the card.
# Standard library only.  Fraction is exact fractions; every point count, L-value, period and
# Tunnell count is computed here.  E_n is the curve y^2 = x^3 - n^2 x; E_6 belongs to area 6.
from fractions import Fraction as F
from math import gcd, isqrt, sqrt, exp, log, pi, sin

def sq(r): return r >= 0 and isqrt(r.numerator) ** 2 == r.numerator and isqrt(r.denominator) ** 2 == r.denominator
def root(r): return F(isqrt(r.numerator), isqrt(r.denominator))
def on(n, x, y): return y * y == x ** 3 - n * n * x

# Road 1: the 3-4-5 triangle gives three squares spaced 6 apart, and so a point on E_6
a, b, c, n = 3, 4, 5, 6
x = F(c * c, 4)
print(f"triangle {a}, {b}, {c}: area {a * b // 2}; x - 6, x, x + 6 = {x - 6}, {x}, {x + 6}")
print(f"roots: {root(x - 6)}, {root(x)}, {root(x + 6)}; product {(x - 6) * x * (x + 6)} = y^2")
y = root((x - 6) * x * (x + 6))
print(f"point P = ({x}, {y}) on y^2 = x^3 - 36x: {'yes' if on(6, x, y) else 'no'}; not whole, so infinite order")
assert (x, y) == (F(25, 4), F(35, 8)) and on(6, x, y) and y.denominator > 1
m = (3 * x * x - 36) / (2 * y); x2 = m * m - 2 * x; y2 = m * (x - x2) - y      # tangent at P
h, s, d = root(x2), root(x2 + 6), root(x2 - 6)                       # read a triangle back
print(f"2P = ({x2}, {y2}); triangle back: legs {s - d}, {s + d}, long side {2 * h}, area {(s - d) * (s + d) / 2}")
assert on(6, x2, y2) and (s - d) ** 2 + (s + d) ** 2 == (2 * h) ** 2 and (s - d) * (s + d) / 2 == 6

# Road 2: count points mod p by brute force, and by the twist rule a_p(E_n) = (n/p) a_p(E_1)
def leg(v, p):
    v %= p
    return 0 if v == 0 else (1 if pow(v, (p - 1) // 2, p) == 1 else -1)
X = 10000
sieve = bytearray([1]) * (X + 1)
for i in range(2, 101):
    if sieve[i]: sieve[i * i::i] = bytearray(len(sieve[i * i::i]))
P = [p for p in range(3, X + 1) if sieve[p]]
a1 = {p: -sum(leg(t * t * t - t, p) for t in range(p)) for p in P}   # a_p of y^2 = x^3 - x
def ap(n, p): return 0 if n % p == 0 else leg(n, p) * a1[p]
rows = []
for p in (5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
    Np = 1 + sum((v * v - u ** 3 + 36 * u) % p == 0 for u in range(p) for v in range(p))
    rows.append(f"{p}:{Np}/{p + 1 - Np}")
    assert p + 1 - Np == ap(6, p) and (p + 1 - Np) ** 2 <= 4 * p and (p % 4 == 1 or Np == p + 1)
print("E_6 mod p, p:N_p/a_p (brute force = twist rule; Hasse |a_p| <= 2 sqrt p holds):", ", ".join(rows))

# Road 3: the Euler product prod N_p/p that Birch and Swinnerton-Dyer watched grow
for n in (1, 6, 34):
    prod, out, marks = 1.0, [], [100, 300, 1000, 3000, 10000]
    for p in P:
        if n % p == 0: continue
        while marks and p > marks[0]: out.append(f"{prod:.2f}"); marks.pop(0)
        prod *= (p + 1 - ap(n, p)) / p
    print(f"chart n = {n}: prod N_p/p for p up to 100, 300, 1000, 3000, 10000:", ", ".join(out + [f"{prod:.2f}"]))
    if n == 1: end1 = prod                                       # E_1's product at 10000

# Road 4: the L-function at s = 1 from a_m, with its sign found from the functional equation
def coeffs(n, M):
    am = [0, 1] + [0] * (M - 1)
    for k in range(2, M + 1):
        p = next(q for q in [2] + P if k % q == 0)
        e, r = 0, k
        while r % p == 0: r //= p; e += 1
        pk = [1, 0 if (2 * n) % p == 0 else ap(n, p)]
        for _ in range(e - 1): pk.append(pk[-1] * pk[1] - (0 if (2 * n) % p == 0 else p) * pk[-2])
        am[k] = pk[e] * am[r]
    return am
def E1(z):                                   # exponential integral: series below 1, continued fraction above
    if z < 1: return -0.5772156649015329 - log(z) - sum((-z) ** k / (k * fact(k)) for k in range(1, 40))
    bb, cc, dd = z + 1, 1e300, 1 / (z + 1); hh = dd
    for i in range(1, 200):
        an = -i * i; bb += 2; dd = 1 / (an * dd + bb); cc = bb + an / cc; hh *= cc * dd
    return hh * exp(-z)
def fact(k): return 1 if k < 2 else k * fact(k - 1)
def lvals(n, M=2000):
    N = 32 * n * n if n % 2 else 16 * n * n
    am = coeffs(n, M)
    f = lambda t: sum(am[k] * exp(-2 * pi * k * t) for k in range(1, M + 1))
    t = 1.2 / sqrt(N); w = f(1 / (N * t)) / (N * t * t * f(t))
    L = 2 * sum(am[k] / k * exp(-2 * pi * k / sqrt(N)) for k in range(1, M + 1))
    dL = 2 * sum(am[k] / k * E1(2 * pi * k / sqrt(N)) for k in range(1, M + 1))
    return N, w, (L if w > 0 else 0.0), (dL if w < 0 else 0.0), L
def agm(u, v):
    for _ in range(30): u, v = (u + v) / 2, sqrt(u * v)
    return u
om = pi / agm(1, sqrt(2)); K = 2000                               # period of E_1, two ways
om2 = 2 * (pi / 2 / K / 3) * sum((1 if j in (0, K) else 4 if j % 2 else 2) / sqrt(1 + sin(j * pi / 2 / K) ** 2) for j in range(K + 1))
print(f"period of y^2 = x^3 - x: by AGM {om:.12f}, by Simpson {om2:.12f}; doubled over sqrt 6, for E_6: {2 * om / sqrt(6):.12f}")
assert abs(om - om2) < 1e-12
L1 = lvals(1)[2]                                     # rank 0: Goldfeld's limit, if the product converges at s = 1
print(f"n = 1: sqrt 2 / L(E_1, 1) = {sqrt(2) / L1:.4f}, 1 / L(E_1, 1) = {1 / L1:.4f}; chart ends at {end1:.2f}")
assert abs(end1 - sqrt(2) / L1) < abs(end1 - 1 / L1)

# Road 5: Tunnell's counts of whole solutions; the test says 'congruent' when the first is twice the second
def tunnell(n):
    k, q = (n, 2) if n % 2 else (n // 2, 4)
    r = isqrt(k) + 1
    cnt = lambda c: sum(q * u * u + v * v + c * z * z == k for u in range(-r, r + 1) for v in range(-r, r + 1) for z in range(-r, r + 1))
    return cnt(8), cnt(32)
sf = list(range(1201))                                            # square-free parts
for dd in range(2, 35):
    for k in range(dd * dd, 1201, dd * dd):
        while sf[k] % (dd * dd) == 0: sf[k] //= dd * dd
seeds = {}
for mm in range(2, 401):
    for kk in range(1, mm):
        if (mm - kk) % 2 and gcd(mm, kk) == 1:
            seeds.setdefault(sf[mm] * sf[kk] * sf[mm - kk] * sf[mm + kk], (mm, kk))
print("n | n mod 8 | counts | sign | L(E_n, 1) | scaled L | verdict | witness")
for n in [k for k in range(1, 24) if all(k % (j * j) for j in range(2, 7))]:
    A, B = tunnell(n)
    N, w, L, dL, _ = lvals(n)
    scaled = (16 if n % 2 else 8) * sqrt(n) * L / om
    wit = f"seeds {seeds[n]}" if n in seeds else ("23 triangle below" if n == 23 else "-")
    print(f"{n:2d} | {n % 8} | {A}, {B} | {'+' if w > 0 else '-'} | {L:.10f} | {scaled:.6f} | "
          f"{'congruent' if A == 2 * B else 'not congruent'} | {wit}")
    assert abs(abs(w) - 1) < 1e-9 and abs(scaled - (A - 2 * B) ** 2) < 1e-6   # L matches Tunnell
    assert (A == 2 * B) == (w < 0) == (n in seeds or n == 23)                # three roads agree
a23, b23, c23, D = 80155 * 3485, 41496 * 20748, 905141617, 72306780       # sides over D
print(f"23 triangle: {80155}/{20748}, {41496}/{3485}, {c23}/{D}; Pythagoras {'yes' if a23 ** 2 + b23 ** 2 == c23 ** 2 else 'no'}; "
      f"area {F(80155 * 41496, 2 * 20748 * 3485)}")
assert a23 ** 2 + b23 ** 2 == c23 ** 2 and 80155 * 41496 == 46 * 20748 * 3485
N, w, L, dL, _ = lvals(6)
print(f"E_6: conductor {N}, sign {w:+.9f}, L(E_6, 1) = 0 forced, L'(E_6, 1) = {dL:.10f}: analytic rank 1")
assert w < 0 and dL > 0.5
per, reg = 2.140901028075231, 0.888625874839619          # quoted from the LMFDB table, curve 576.c3
strong = per * reg * 16 / 4 ** 2                               # period x regulator x Tamagawa 16 / torsion 4 squared
print(f"strong form, table's period {per}, regulator {reg}, Tamagawa factor 16, analytic Sha 1, torsion 4: {strong:.10f}")
assert abs(strong - dL) < 1e-9 and abs(2 * om / sqrt(6) - per) < 1e-12        # the quoted period, recomputed

# What breaks
N, w, L, _, wrong = lvals(6)
print(f"sign forgotten for n = 6: the + formula gives {wrong:.10f}, not 0")
N, w, L, _, _ = lvals(34)
print(f"n = 34 is 2 mod 8, yet sign {w:+.0f}, L(E_34, 1) = {abs(L):.10f}, counts {tunnell(34)}, point (-16, 120) on E_34: "
      f"{'yes' if on(34, F(-16), F(120)) else 'no'}")
print(f"n = 24, not square-free: counts {tunnell(24)} say 'not congruent', yet 6, 8, 10 has area 24")
assert abs(L) < 1e-9 and w > 0 and tunnell(24) == (8, 0) and abs(wrong - 1.2893431325) < 1e-9
print("ALL CHECKS PASS")
