# Gauss composition and genus theory for positive binary quadratic forms (a, b, c) = a x^2 + b x y + c y^2.
# Road A composes forms by Dirichlet's united forms; road B multiplies the matching ideals as lattices.
from math import gcd

def red(f, trail=None):            # reduce: -a < b <= a <= c, b >= 0 when a = c (Reduced forms card)
    a, b, c = f
    while not (-a < b <= a <= c):
        k = (a - b) // (2 * a); a, b, c = a, b + 2 * a * k, a * k * k + b * k + c
        if trail is not None and k: trail.append((a, b, c))
        if c < a:
            a, b, c = c, -b, a
            if trail is not None: trail.append((a, b, c))
    return (a, -b, c) if a == c and b < 0 else (a, b, c)
def forms(D):                      # the reduced primitive forms of discriminant D < 0
    return [(a, b, (b * b - D) // (4 * a)) for a in range(1, int((-D / 3) ** 0.5) + 1) for b in range(-a + 1, a + 1)
            if (b * b - D) % (4 * a) == 0 and red((a, b, (b * b - D) // (4 * a))) == (a, b, (b * b - D) // (4 * a))
            and gcd(gcd(a, b), (b * b - D) // (4 * a)) == 1]
def val(f, x, y): return f[0] * x * x + f[1] * x * y + f[2] * y * y
def egcd(a, b):
    if b == 0: return (1, 0)
    u, v = egcd(b, a % b); return (v, u - a // b * v)
def move(g, m):                    # an equivalent form whose first number shares no factor with m
    x, y = next((x, y) for y in range(20) for x in range(20) if gcd(x, y) == 1 and gcd(val(g, x, y), m) == 1)
    s, r = egcd(x, y); r = -r      # x s - y r = 1, so (X, Y) -> (x X + r Y, y X + s Y) can be undone
    return (val(g, x, y), 2 * g[0] * x * r + g[1] * (x * s + y * r) + 2 * g[2] * y * s, val(g, r, s))
def unite(f, g):                   # road A: Dirichlet composition, after making gcd(a1, a2, (b1 + b2)/2) = 1
    if gcd(gcd(f[0], g[0]), (f[1] + g[1]) // 2) > 1: g = move(g, f[0])
    (a1, b1, c1), (a2, b2, c2) = f, g; D = b1 * b1 - 4 * a1 * c1; A = a1 * a2
    B = next(B for B in range(b1 % (2 * a1), 2 * A, 2 * a1) if (B - b2) % (2 * a2) == 0 and (B * B - D) % (4 * A) == 0)
    return g, B, (A, B, (B * B - D) // (4 * A))
def comp(f, g): return red(unite(f, g)[2])
# Road B: the order of discriminant D is Z[t], t^2 = D/4 or t^2 = t + (D - 1)/4; x + y t is the pair (x, y).
def emul(D, u, v):
    r = D % 4; s = (D - r) // 4; t = u[1] * v[1]
    return (u[0] * v[0] + t * s, u[0] * v[1] + u[1] * v[0] + t * r)
def hnf(vs):                       # the lattice spanned by integer vectors, as (A, K, C): basis A and K + C t
    vs = [v for v in vs if v != (0, 0)]
    while len([v for v in vs if v[1]]) > 1:
        vs.sort(key=lambda v: (v[1] == 0, abs(v[1]))); p = vs[0]
        vs = [p] + [(v[0] - v[1] // p[1] * p[0], v[1] - v[1] // p[1] * p[1]) for v in vs[1:]]
    p = [v for v in vs if v[1]][0]; p = (-p[0], -p[1]) if p[1] < 0 else p
    A = 0
    for v in vs:
        if v[1] == 0: A = gcd(A, v[0])
    return (A, p[0] % A, p[1])
def to_ideal(D, f): return hnf([(f[0], 0), ((-f[1] - D % 4) // 2, 1)])   # [a, (-b + sqrt D)/2]
def imul(D, I, J): return hnf([emul(D, u, v) for u in ((I[0], 0), (I[1], I[2])) for v in ((J[0], 0), (J[1], J[2]))])
def to_form(D, I):                 # N(A x - beta y) / N(I), with beta = K + C t
    A, K, C = I; tr = D % 4; nb = K * K + K * C * tr + C * C * (tr - D) // 4
    assert A % C == 0 and (2 * K + C * tr) % C == 0 and nb % (A * C) == 0
    return red((A // C, -(2 * K + C * tr) // C, nb // (A * C)))
def compB(D, f, g): return to_form(D, imul(D, to_ideal(D, f), to_ideal(D, g)))
def mu(D):                         # Gauss's count: the number of genera is 2^(mu - 1)
    n = -D if D % 4 == 1 else -D // 4; m = n
    r = len([p for p in range(3, m + 1, 2) if m % p == 0 and all(p % q for q in range(3, int(p ** 0.5) + 1, 2))])
    if D % 4 == 1: return r
    return r + (0 if n % 4 == 3 else 2 if n % 8 == 0 else 1)
def residues(D, f): return frozenset(val(f, x, y) % -D for x in range(-D) for y in range(-D) if gcd(val(f, x, y), D) == 1)
def genera(D): return len(forms(D)) // len({comp(f, f) for f in forms(D)})
def yn(t): return "yes" if t else "no"

D = -20; F = forms(D); f0, f1 = F
print("D = -20: reduced forms", F, "; ideal of (2, 2, 3) as (A, K, C):", to_ideal(D, f1), "= (2, 1 + sqrt-5); back to a form:", to_form(D, to_ideal(D, f1)))
g, B, u = unite(f1, f1); tr = []; r = red(u, tr)
print("compose (2, 2, 3) with itself: gcd(2, 2, 2) =", gcd(gcd(2, 2), 2), "; second form moved to", g, "; B =", B, "; composite", u, "; reduction", tr, "->", r)
I2 = imul(D, to_ideal(D, f1), to_ideal(D, f1))
print("ideal road: (2, 1 + sqrt-5)^2 =", I2, "= (2) as a lattice, form", to_form(D, I2), "; united forms (2, 10, 15) and (3, 10, 10):", red((2, 10, 15)), red((3, 10, 10)))
assert r == f0 == to_form(D, I2) and I2 == hnf([(2, 0), emul(D, (2, 0), (0, 1))]) and to_form(D, to_ideal(D, f1)) == f1
rng = range(-6, 7)
ok1 = all(val(f1, x, y) * val(f1, z, w) == (2 * x * z + x * w + y * z - 2 * y * w) ** 2 + 5 * (x * w + y * z + y * w) ** 2 for x in rng for y in rng for z in rng for w in rng)
ok2 = all(val((2, 10, 15), x, y) * val((3, 10, 10), z, w) == val((6, 10, 5), x * z - 5 * y * w, 2 * x * w + 3 * y * z + 10 * y * w) for x in rng for y in rng for z in rng for w in rng)
x, y, z, w = 0, 1, 1, 1
print(f"product identities on all 13^4 inputs: {yn(ok1)}, {yn(ok2)}; 3 x 7 = f(0, 1) f(1, 1) = ({2*x*z + x*w + y*z - 2*y*w})^2 + 5 ({x*w + y*z + y*w})^2 = {val(f1, x, y) * val(f1, z, w)}")
assert ok1 and ok2
for D in (-20, -56, -84):
    F = forms(D); tab = [[F.index(comp(f, g)) for g in F] for f in F]
    assert all(comp(f, g) == compB(D, f, g) for f in F for g in F)
    print(f"D = {D}: classes {F}; composition table by index (roads A and B agree): {tab}")
N = 10000; isp = [1] * (N + 1); isp[0] = isp[1] = 0
for i in range(2, 101):
    if isp[i]: isp[i * i::i] = [0] * len(isp[i * i::i])
P = [p for p in range(N + 1) if isp[p]]
def reps(f): return {v for x in range(-120, 121) for y in range(121) if 0 < (v := val(f, x, y)) <= N}
R = {f: reps(f) for f in forms(-20) + forms(-56)}
c19 = [p for p in P if p in R[(1, 0, 5)]]; c37 = [p for p in P if p in R[(2, 2, 3)]]
print("primes below 10,000:", len(P), "; x^2 + 5y^2:", len(c19), "; 2x^2 + 2xy + 3y^2:", len(c37), "; first", c19[:4], c37[:5], "; 3^2 + 5 x 2^2 =", val((1, 0, 5), 3, 2))
assert c19 == [p for p in P if p == 5 or p % 20 in (1, 9)] and c37 == [p for p in P if p == 2 or p % 20 in (3, 7)]
for D in (-20, -56):
    print(f"D = {D}: values prime to {-D}, mod {-D}, of each class:", [sorted(residues(D, f)) for f in forms(D)])
H = residues(-56, (1, 0, 14)); pg = [p for p in P if p % 56 in H]
a14 = [p for p in pg if p in R[(1, 0, 14)]]; b27 = [p for p in pg if p in R[(2, 0, 7)]]; c35 = [p for p in P if p in R[(3, 2, 5)]]
print("D = -56, primes below 10,000 in the principal genus:", len(pg), "; x^2 + 14y^2:", len(a14), "; 2x^2 + 7y^2:", len(b27), "; 3x^2 + 2xy + 5y^2:", len(c35))
print("same residue, different forms: 3^2 + 14 x 1^2 =", val((1, 0, 14), 3, 1), "and 2 x 6^2 + 7 x 1^2 =", val((2, 0, 7), 6, 1), "; both", 79 % 56, "mod 56; first of each", a14[:5], b27[:5])
def kr(p): return pow(-14 % p, (p - 1) // 2, p) == 1
assert sorted(a14 + b27) == pg and not set(a14) & set(b27) and pg == [p for p in P if p > 7 and kr(p) and pow(p, 3, 7) == 1]
quart = [p for p in P if p > 7 and kr(p) and any(((t * t + 1) ** 2 - 8) % p == 0 for t in range(p))]
print("Cox's test, (-14/p) = 1 and (t^2 + 1)^2 = 8 mod p solvable, picks", len(quart), "primes; equal to the x^2 + 14y^2 list:", yn(quart == a14))
assert quart == a14
print("D, h, genera by squares (Gauss), by Gauss's count 2^(mu - 1), by residue sets, classes per genus, squares = principal genus")
for D in (-15, -20, -23, -56, -84, -96, -260, -420):
    F = forms(D); rs = [residues(D, f) for f in F]; sq = {comp(f, f) for f in F}
    g1, g2, g3 = genera(D), 2 ** (mu(D) - 1), len(set(rs))
    print(D, len(F), g1, g2, g3, len(F) // g1, yn(sq == {f for f, s in zip(F, rs) if s == rs[0]}))
    assert g1 == g2 == g3 and sq == {f for f, s in zip(F, rs) if s == rs[0]}
ido = []
for n in range(1, 2001):
    g1 = genera(-4 * n); assert g1 == 2 ** (mu(-4 * n) - 1)
    if g1 == len(forms(-4 * n)): ido.append(n)
print("n up to 2,000 with one class in each genus of -4n (Euler's convenient numbers):", len(ido), "; largest", ido[-1], "; first", ido[:12])
assert len(ido) == 65 and ido[-1] == 1848
a, b = 2, 2; print("what breaks: multiply the first numbers without uniting: (4, 2, c) needs c =", (b * b + 20) / (4 * a * a))
print("what breaks: every square principal, as at -20? at -56", (3, 2, 5), "composed with itself is", comp((3, 2, 5), (3, 2, 5)))
print("what breaks: 79 is", 79 % 56, "mod 56, like 23; is it x^2 + 14y^2?", yn(79 in R[(1, 0, 14)]), "; Gauss's count with 2^mu at -20:", 2 ** mu(-20), "genera, truth", genera(-20))
print("ALL CHECKS PASS")
