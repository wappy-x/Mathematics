# Kummer and Artin-Schreier -- the check behind the card.  Standard library only.
# 1. Hilbert 90 in Q(i)/Q, against a brute-force list of Pythagorean triples.
# 2. Kummer over K = Q(omega): x^3 - 2, and the resolvent that turns the cyclic
#    cubic x^3 - 3x + 1 into a cube root.  3. Artin-Schreier in F_27 over F_3.
from fractions import Fraction as Fr
from math import gcd, isqrt, cos, sin, atan2, pi

def fs(x): return str(Fr(x))
def term(c, v): return v if c == 1 else "-" + v if c == -1 else fs(c) + v
def cs(p, q, v):                                  # p + q v, zero parts dropped
    if q == 0: return fs(p)
    if p == 0: return term(q, v)
    return f"{fs(p)} {'-' if q < 0 else '+'} {term(abs(q), v)}"
def gs(a): return cs(a[0], a[1], "i")
def gm(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])  # Q(i) times
def gc(a): return (a[0], -a[1])                                           # sigma: i -> -i
def gn(a): return a[0] ** 2 + a[1] ** 2                                   # the norm
def gd(a, b): t = gm(a, gc(b)); return (Fr(t[0], gn(b)), Fr(t[1], gn(b)))
def h90(al, th):                                  # beta = theta + alpha sigma(theta)
    t = gm(al, gc(th)); return (th[0] + t[0], th[1] + t[1])
def recipe(al):                                   # theta = 1, or theta = i if that gives 0
    b = h90(al, (1, 0)); return b if b != (0, 0) else h90(al, (0, 1))
def prim(b):                                      # scale a Gaussian rational to a primitive integer
    d = Fr(b[0]).denominator * Fr(b[1]).denominator; m, n = int(b[0] * d), int(b[1] * d)
    g = gcd(m, n); return (m // g, n // g)

print("1. Hilbert 90 in Q(i)/Q")
al = (Fr(3, 5), Fr(4, 5)); be = h90(al, (1, 0))
print(f"alpha = {gs(al)}, norm {fs(gn(al))}; theta = 1 gives beta = 1 + alpha = {gs(be)}")
print(f"beta / sigma(beta) = {gs(gd(be, gc(be)))}; beta scaled to a Gaussian integer: {gs(prim(be))}")
print(f"(2 + i)^2 = {gs(gm((2, 1), (2, 1)))}; norm of 2 + i = {gn((2, 1))}: the triple 3, 4, 5")
pts = [(Fr(p, c), Fr(s * isqrt(c * c - p * p), c)) for c in range(1, 101) for p in range(-c, c + 1)
       for s in (1, -1) if isqrt(c * c - p * p) ** 2 == c * c - p * p and gcd(p, isqrt(c * c - p * p), c) == 1
       and (s == 1 or p * p != c * c)]
ok = all(gd(recipe(a), gc(recipe(a))) == a for a in pts)
search = sorted((a, b, c) for c in range(1, 101) for a in range(1, c) for b in range(a + 1, c)
                if a * a + b * b == c * c and gcd(a, b) == 1)
by_h90 = []
for (a, b, c) in search:
    odd, even = (a, b) if a % 2 else (b, a)
    m, n = prim(recipe((Fr(odd, c), Fr(even, c))))
    by_h90.append(tuple(sorted((m * m - n * n, 2 * m * n))) + (m * m + n * n,))
euclid = sorted(tuple(sorted((m * m - n * n, 2 * m * n))) + (m * m + n * n,) for m in range(2, 11)
                for n in range(1, m) if gcd(m, n) == 1 and (m - n) % 2 and m * m + n * n <= 100)
units = sum(1 for a in pts if a[0].denominator == 1 and a[1].denominator == 1)
print(f"norm-1 points with denominator at most 100, by brute force: {len(pts)} = {len(search)} x 8 + {units}; each is beta/sigma(beta): {ok}")
print(f"primitive triples with hypotenuse at most 100, by search: {len(search)}")
print(f"the same list from Hilbert 90's u + vi: {sorted(by_h90) == search}; from Euclid's u, v: {euclid == search}")
print(f"first four: {search[:4]}")

Z, O, W = (Fr(0), Fr(0)), (Fr(1), Fr(0)), (Fr(0), Fr(1))  # K = Q(omega): p + q omega
def km(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0] - a[1] * b[1])
def ka(a, b): return (a[0] + b[0], a[1] + b[1])
def ws(a): return cs(a[0], a[1], "w")
def lm(x, y, c):                                  # L = K[t] / (t^3 - c0 - c1 t)
    t = [Z] * 5
    for i in range(3):
        for j in range(3): t[i + j] = ka(t[i + j], km(x[i], y[j]))
    for d in (4, 3):
        for k in (0, 1): t[d - 3 + k] = ka(t[d - 3 + k], km(t[d], c[k]))
        t[d] = Z
    return t[:3]
def la(x, y): return [ka(a, b) for a, b in zip(x, y)]
def ks(k, x): return [km(k, a) for a in x]
def sub(x, img, c):                               # apply sigma: t -> img, K fixed
    out, p = [Z, Z, Z], [O, Z, Z]
    for j in range(3): out, p = la(out, ks(x[j], p)), lm(p, img, c)
    return out
def ls(x): return " + ".join(f"({ws(x[j])}){['', ' t', ' t^2'][j]}" for j in range(3) if x[j] != Z) or "0"
def order(x, img, c):
    k, y = 1, sub(x, img, c)
    while y != x and k < 9: k, y = k + 1, sub(y, img, c)
    return k

print("2. Kummer over K = Q(omega), omega^2 = -1 - omega")
c2, t, W2 = [(Fr(2), Fr(0)), Z], [Z, O, Z], km(W, W)
sa, b2 = [Z, W, Z], [Z, Z, O]                     # x^3 - 2: sigma(b) = omega b; beta = b^2
print(f"x^3 - 2: sigma(b) = omega b has order {order(t, sa, c2)}; "
      f"beta = b^2 has beta = omega sigma(beta): {b2 == ks(W, sub(b2, sa, c2))}")
c3, sr = [(Fr(-1), Fr(0)), (Fr(3), Fr(0))], [(Fr(-2), Fr(0)), Z, O]   # t^3 = 3t - 1
s1 = sub(t, sr, c3); s2 = sub(s1, sr, c3)
print(f"x^3 - 3x + 1 = 0 at t: sigma(t) = t^2 - 2, sigma^2(t) = {ls(s2)}; order of sigma {order(t, sr, c3)}")
th = la(la(t, ks(W2, s1)), ks(W, s2)); th3 = lm(lm(th, th, c3), th, c3)
print(f"resolvent b = t + omega^2 sigma(t) + omega sigma^2(t) = {ls(th)}")
print(f"sigma(b) = omega b: {sub(th, sr, c3) == ks(W, th)}; b^3 = {ls(th3)}; equals 27 omega^2: {th3 == [ks((Fr(27), Fr(0)), [W2])[0], Z, Z]}")
r = 2 * cos(2 * pi / 9); rs = [r, r * r - 2, 2 - r - r * r]
wn = [(cos(2 * pi * k / 3), sin(2 * pi * k / 3)) for k in range(3)]
tn = [sum(rs[j] * wn[(-j) % 3][e] for j in range(3)) for e in (0, 1)]
k9 = round(atan2(tn[1], tn[0]) * 9 / (2 * pi)) % 9
print(f"numerically: t = {r:.10f}; |b| = {(tn[0] ** 2 + tn[1] ** 2) ** 0.5:.10f}; b / 3 = zeta_9^{k9}")

print("3. Artin-Schreier over F_3, alpha^3 = alpha + 1")
F = [(a, b, c) for c in range(3) for b in range(3) for a in range(3)]
def fm(x, y):
    t = [0] * 5
    for i in range(3):
        for j in range(3): t[i + j] += x[i] * y[j]
    for d in (4, 3): t[d - 3] += t[d]; t[d - 2] += t[d]; t[d] = 0
    return tuple(v % 3 for v in t[:3])
def fp(x, k):
    out = (1, 0, 0)
    for _ in range(k): out = fm(out, x)
    return out
def fa(x, y, s=1): return tuple((a + s * b) % 3 for a, b in zip(x, y))
def fe(x):                                        # c0 + c1 alpha + c2 alpha^2, written out
    t = [f"{c if c > 1 else ''}{v}" for c, v in [(x[2], "alpha^2"), (x[1], "alpha")] if c] + [str(x[0])] * (x[0] > 0)
    return " + ".join(t) or "0"
def tr(x): return fa(fa(x, fp(x, 3)), fp(x, 9))
A = (0, 1, 0); one = (1, 0, 0)
print(f"x^3 - x - 1 at 0, 1, 2 mod 3: {[(x ** 3 - x - 1) % 3 for x in range(3)]}; Frobenius alpha^3 = {fe(fp(A, 3))}")
roots = [x for x in F if fa(fa(fp(x, 3), x, -1), one, -1) == (0, 0, 0)]
print(f"roots in F_27, trying all 27: {", ".join(fe(x) for x in roots)}; Frobenius order on alpha: {next(k for k in (1, 2, 3) if fp(A, 3 ** k) == A)}")
ap, tz = {fa(fp(x, 3), x, -1) for x in F}, {x for x in F if tr(x) == (0, 0, 0)}
print(f"values of beta^3 - beta: {len(ap)}; trace-zero elements: {len(tz)}; same set: {ap == tz}")
nz = [x for x in F if x != (0, 0, 0)]
n1 = {x for x in nz if fp(x, 13) == one}; q1 = {fm(x, fp(fp(x, 3), 25)) for x in nz}
print(f"norm-1 elements, x^13 = 1: {len(n1)}; values of beta / beta^3: {len(q1)}; same set: {n1 == q1}")
a2, T = (2, 0, 0), fp(A, 2)                       # additive Hilbert 90 for -1, theta = alpha^2
iv = fp(tr(T), 1)[0]                              # Tr(theta) lies in F_3; its inverse is itself
bb = tuple(iv * v % 3 for v in fa(fm(a2, fp(T, 3)), fm(fa(a2, a2), fp(T, 9))))
print(f"additive recipe, Tr(alpha^2) = {tr(T)[0]}: beta = {fe(bb)}; sigma(beta) - beta = {fe(fa(fp(bb, 3), bb, -1))}")

print("4. what breaks")
print(f"alpha = -1 with theta = 1: beta = {gs(h90((-1, 0), (1, 0)))}; theta = i gives {gs(h90((-1, 0), (0, 1)))}")
small = [(x, y) for x in range(-5, 6) for y in range(-5, 6) if (x, y) != (0, 0)]
print(f"norm of 1 + i: {gn((1, 1))}; norms of beta/sigma(beta) over {len(small)} small beta: {", ".join(sorted({fs(gn(gd(b, gc(b)))) for b in small}))}")
real = sum(1 for k in range(3) if abs(sin(2 * pi * k / 3)) < 1e-12)
print(f"x^3 - 2 over Q: real roots {real} of 3, so Q(2^(1/3)) has {real} automorphism")
print(f"cubes in F_27: {len({fp(x, 3) for x in F})} distinct; (x - c)^3 = x^3 - c mod 3 for c = 0, 1, 2: "
      f"{all([(-c) ** 3 % 3, 3 * c * c % 3, -3 * c % 3] == [-c % 3, 0, 0] for c in range(3))}")
asr = [sum(1 for x in range(3) if (x ** 3 - x - a) % 3 == 0) for a in range(3)]
print(f"roots of x^3 - x - a in F_3 for a = 0, 1, 2: {asr}")
assert ok and len(pts) == 132 == 8 * len(search) + units and gs(prim(be)) == "2 + i"        # recipe against brute force
assert sorted(by_h90) == search == euclid and len(search) == 16  # three roads to the triples
assert th3 == [(Fr(-27), Fr(-27)), Z, Z] and 3 * k9 % 9 == 6       # exact resolvent against floats
assert sorted(roots) == sorted([A, fa(A, one), fa(A, (2, 0, 0))]) and ap == tz and n1 == q1
assert fa(fp(bb, 3), bb, -1) == one and asr == [3, 0, 0]
assert sub(th, sr, c3) == ks(W, th) and order(t, sr, c3) == 3 == order(t, sa, c2) and b2 == ks(W, sub(b2, sa, c2))  # Kummer
print("ALL CHECKS PASS")
