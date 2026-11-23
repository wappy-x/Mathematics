# Birch and Swinnerton-Dyer, the Millennium problem -- the check behind the card.  Standard library only.
# E_n is the curve y^2 = x^3 - n^2 x; n is congruent (a rational right triangle has area n) exactly when
# E_n has rank at least 1.  The card's curve is E_5.  Fractions are exact; L-values are summed here.
from fractions import Fraction as F
from math import gcd, isqrt, sqrt, exp, log, pi

def on(n, x, y): return y * y == x ** 3 - n * n * x
def tri(n, x, y): return ((x * x - n * n) / y, 2 * n * x / y, (x * x + n * n) / y)   # point -> triangle
def dbl(n, x, y):                                                       # tangent rule: 2(x, y)
    m = (3 * x * x - n * n) / (2 * y); x2 = m * m - 2 * x
    return m, x2, m * (x - x2) - y

# Road 1: Fibonacci's number 5, a point, a triangle, and a second point that proves infinite order
a, b, c = F(3, 2), F(20, 3), F(41, 6)
print(f"triangle {a}, {b}, {c}: a^2 + b^2 = {a * a + b * b}, c^2 = {c * c}, area {a * b / 2}")
G = (F(-4), F(6))
print(f"G = (-4, 6) on y^2 = x^3 - 25x: {'yes' if on(5, *G) else 'no'} (36 = -64 + 100)")
t = tri(5, *G)
print(f"triangle from G: {t[0]}, {t[1]}, {t[2]}")
assert a * a + b * b == c * c and a * b / 2 == 5 and on(5, *G) and tuple(abs(v) for v in t) == (a, b, c)
tor = [(F(0), F(0)), (F(5), F(0)), (F(-5), F(0))]
print(f"torsion points O, (0, 0), (5, 0), (-5, 0) on the curve: {'yes' if all(on(5, *T) for T in tor) else 'no'}; 4 in all, no triangle (y = 0)")
assert all(on(5, *T) for T in tor) and not on(5, F(4), F(0))
m, x2, y2 = dbl(5, *G)
t2 = tri(5, x2, y2)
print(f"tangent slope at G {m}; 2G = ({x2}, {y2}); whole numbers: {'yes' if x2.denominator == 1 else 'no'}")
print(f"triangle from 2G: {abs(t2[0])}, {abs(t2[1])}, {abs(t2[2])}; area {abs(t2[0] * t2[1]) / 2}")
assert on(5, x2, y2) and x2.denominator > 1 and t2[0] ** 2 + t2[1] ** 2 == t2[2] ** 2 and abs(t2[0] * t2[1]) / 2 == 5
print("figure,G,-4,6,2G,%.4f,%.4f,-2G,%.4f,%.4f,slope,%.4f" % (x2, y2, x2, -y2, m))

# Road 2: count E_5 mod p by brute force, and by the twist rule a_p(E_n) = (n/p) a_p(E_1)
def leg(v, p):
    v %= p
    return 0 if v == 0 else (1 if pow(v, (p - 1) // 2, p) == 1 else -1)
X = 6000
sv = bytearray([1]) * (X + 1)
for i in range(2, 80):
    if sv[i]: sv[i * i::i] = bytearray(len(sv[i * i::i]))
P = [p for p in range(3, X + 1) if sv[p]]
a1 = {p: -sum(leg(u * u * u - u, p) for u in range(p)) for p in P}
def ap(n, p): return 0 if n % p == 0 else leg(n, p) * a1[p]
rows = []
for p in (3, 7, 11, 13, 17, 19, 23, 29):
    Np = 1 + sum((v * v - u ** 3 + 25 * u) % p == 0 for u in range(p) for v in range(p))
    rows.append(f"{p}:{Np}/{p + 1 - Np}")
    assert p + 1 - Np == ap(5, p) and (p + 1 - Np) ** 2 <= 4 * p
print("E_5 mod p, p:N_p/a_p (brute force = twist rule, Hasse holds):", ", ".join(rows))

# Road 3: the L-function at s = 1 from the a_k: its sign, its value, its slope (two ways)
def coeffs(n, M):
    am = [0, 1] + [0] * (M - 1)
    for k in range(2, M + 1):
        p = next(q for q in [2] + P if k % q == 0)
        e, r = 0, k
        while r % p == 0: r //= p; e += 1
        bad = (2 * n) % p == 0
        pk = [1, 0 if bad else ap(n, p)]
        for _ in range(e - 1): pk.append(pk[-1] * pk[1] - (0 if bad else p) * pk[-2])
        am[k] = pk[e] * am[r]
    return am
def E1(z):                                     # exponential integral: series below 1, continued fraction above
    if z < 1: return -0.5772156649015329 - log(z) - sum((-z) ** k / (k * fac[k]) for k in range(1, 40))
    bb, cc, dd = z + 1, 1e300, 1 / (z + 1); hh = dd
    for i in range(1, 200):
        an = -i * i; bb += 2; dd = 1 / (an * dd + bb); cc = bb + an / cc; hh *= cc * dd
    return hh * exp(-z)
fac = [1]
for k in range(1, 41): fac.append(fac[-1] * k)
def lfun(n):
    N = 32 * n * n if n % 2 else 16 * n * n
    sN = sqrt(N); M = int(6 * sN) + 20; am = coeffs(n, M)
    f = lambda y: sum(am[k] * exp(-2 * pi * k * y) for k in range(1, M + 1))
    t = 1.1 / sN; w = f(1 / (N * t)) / (N * t * t * f(t))           # functional equation gives the sign
    Lp = 2 * sum(am[k] / k * exp(-2 * pi * k / sN) for k in range(1, M + 1))   # the value if w = +1
    dL = 2 * sum(am[k] / k * E1(2 * pi * k / sN) for k in range(1, M + 1))    # the slope if w = -1
    return N, w, Lp, dL, f
def tunnell(n):
    k, q = (n, 2) if n % 2 else (n // 2, 4)
    r = isqrt(k) + 1
    cnt = lambda c: sum(q * u * u + v * v + c * z * z == k for u in range(-r, r + 1) for v in range(-r, r + 1) for z in range(-r, r + 1))
    return cnt(8), cnt(32)
N, w, Lp, dL, f = lfun(5)
A, B = tunnell(5)
print(f"E_5: conductor {N}, sign w = {w:+.9f}; Tunnell counts {A}, {B}, so L(E_5, 1) = 0 exactly")
K, y0 = 3000, 1 / sqrt(N); U = log(8 / y0); h = U / K               # slope again, as an integral, Simpson
quad = 4 * pi * (h / 3) * sum((1 if j in (0, K) else 4 if j % 2 else 2) * f(y0 * exp(j * h)) * j * h * y0 * exp(j * h) for j in range(K + 1))
print(f"L'(E_5, 1) by the E1 series {dL:.12f}, by the integral {quad:.12f}: not 0, analytic rank 1")
assert abs(abs(w) - 1) < 1e-9 and w < 0 and A == 2 * B and abs(dL - quad) < 1e-10 and dL > 0.5

# Road 4: the status of every square-free n up to 100, by the proved theorems; triangles from seeds up to 400
def sfree(k):
    s, d = 1, 2
    while d * d <= k:
        while k % (d * d) == 0: k //= d * d
        if k % d == 0: s *= d; k //= d
        d += 1
    return s * k
sf = [0] + [sfree(k) for k in range(1, 801)]
seeds = {}
for mm in range(2, 401):
    for kk in range(1, mm):
        if (mm - kk) % 2 and gcd(mm, kk) == 1:
            s = 1
            for v in (mm, kk, mm - kk, mm + kk): g = gcd(s, sf[v]); s = s * sf[v] // (g * g)
            seeds.setdefault(s, (mm, kk))
cls = {"rank 0, proved": [], "rank 1, proved": [], "order 2 or more, no general theorem": []}
for n in [k for k in range(1, 101) if sf[k] == k]:
    A, B = tunnell(n)
    if A != 2 * B: cls["rank 0, proved"].append(n); continue
    N, w, Lp, dL, f = lfun(n)
    assert abs(abs(w) - 1) < 1e-9 and ((w < 0) == (n % 8 in (5, 6, 7)))      # sign, two ways
    if w < 0 and abs(dL) > 0.01: cls["rank 1, proved"].append(n)
    else: cls["order 2 or more, no general theorem"].append(n)
count = sum(all(k % (d * d) for d in range(2, 11)) for k in range(1, 101))         # square-free, recounted
print(f"square-free n from 1 to 100: {count}")
for k, v in cls.items(): print(f"{k}: {len(v)} numbers: " + " ".join(map(str, v)))
miss = [n for n in cls["rank 1, proved"] + cls["order 2 or more, no general theorem"] if n not in seeds]
print(f"L(E_n, 1) = 0 but no triangle from seeds up to 400: {len(miss)} numbers: " + " ".join(map(str, miss)))
assert all(n not in seeds for n in cls["rank 0, proved"])                   # no triangle where L(E_n, 1) != 0
assert set(miss) <= set(cls["rank 1, proved"]) and sum(map(len, cls.values())) == count == 61
print(f"seeds for 5: {seeds[5]}, for 41: {seeds[41]}, for 65: {seeds[65]}")

# What breaks
N, w, Lp, dL, f = lfun(157)
print(f"157: seeds up to 400 give a triangle: {'yes' if 157 in seeds else 'no'}; sign {w:+.0f}, L'(E_157, 1) = {dL:.10f}")
assert 157 not in seeds and w < 0 and dL > 0.5
print(f"sign forgotten for n = 5: the w = +1 formula gives {lfun(5)[2]:.10f}, not 0")
print(f"41 = 1 mod 8, sign +1, counts {tunnell(41)}: L(E_41, 1) = 0, yet seeds {seeds[41]} give a triangle")
assert tunnell(41)[0] == 2 * tunnell(41)[1] and lfun(41)[1] > 0
print("ALL CHECKS PASS")
