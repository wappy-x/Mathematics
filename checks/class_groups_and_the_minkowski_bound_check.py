# Class groups and the Minkowski bound, in the imaginary quadratic fields Q(sqrt m), m < 0.
# A number x + y*w is the pair (x, y), with w = sqrt(m), or w = (1 + sqrt(m))/2 when m = 1 mod 4.
# An ideal is (a, b, c): the whole numbers x*a + y*(b + c*w), a lattice in Hermite normal form.
from math import gcd, isqrt, pi

def wsq(m): return (m, 0) if m % 4 != 1 else ((m - 1) // 4, 1)   # w*w = s + r*w
def disc(m): return m if m % 4 == 1 else 4 * m
def mul(m, u, v):
    s, r = wsq(m); t = u[1] * v[1]
    return (u[0] * v[0] + t * s, u[0] * v[1] + u[1] * v[0] + t * r)
def norm(m, u):
    x, y = u
    return x * x - m * y * y if m % 4 != 1 else x * x + x * y + (1 - m) // 4 * y * y
def conj(m, u): return (u[0], -u[1]) if m % 4 != 1 else (u[0] + u[1], -u[1])

def hnf(vs):                       # the lattice spanned by integer vectors, as (a, b, c)
    vs = [v for v in vs if v != (0, 0)]
    while len([v for v in vs if v[1]]) > 1:
        vs.sort(key=lambda v: (v[1] == 0, abs(v[1])))
        p = vs[0]
        vs = [p] + [(v[0] - v[1] // p[1] * p[0], v[1] - v[1] // p[1] * p[1]) for v in vs[1:]]
    p = [v for v in vs if v[1]][0]
    if p[1] < 0: p = (-p[0], -p[1])
    a = gcd(*[v[0] for v in vs if v[1] == 0])
    return (a, p[0] % a, p[1])
def basis(I): return [(I[0], 0), (I[1], I[2])]
def ideal(m, gens): return hnf(gens + [mul(m, g, (0, 1)) for g in gens])
def imul(m, I, J): return hnf([mul(m, u, v) for u in basis(I) for v in basis(J)])
def iconj(m, I): return hnf([conj(m, u) for u in basis(I)])
def has(I, u): return u[1] % I[2] == 0 and (u[0] - u[1] // I[2] * I[1]) % I[0] == 0
def gen(m, I):                     # a generator if the ideal is principal: an element whose norm is N(I)
    N = I[0] * I[2]; Y = 2 * isqrt(N // -m) + 2; X = isqrt(N) + Y
    for y in range(-Y, Y + 1):
        for x in range(-X, X + 1):
            if norm(m, (x, y)) == N and has(I, (x, y)): return max((x, y), (-x, -y))
def same_class(m, I, J): return gen(m, imul(m, I, iconj(m, J))) is not None
def ideals_upto(m, B):             # every ideal of norm <= B: lattices closed under multiplying by w
    return [I for N in range(1, B + 1) for c in range(1, N + 1) if N % c == 0 for I in [(N // c, b, c) for b in range(N // c)]
            if has(I, (0, I[0])) and has(I, mul(m, (I[1], I[2]), (0, 1)))]
def class_group(m, gens):          # multiply out the generators until no new class appears
    reps = [(1, 0, 1)]
    for R in reps:
        for G in gens:
            P = imul(m, R, G)
            if not any(same_class(m, P, S) for S in reps): reps.append(P)
    return reps
def order(m, I):
    k, P = 1, I
    while gen(m, P) is None: k, P = k + 1, imul(m, P, I)
    return k
def forms(d):                      # road 2: Gauss's reduced forms a x^2 + b x y + c y^2, b^2 - 4ac = d
    out = []; a = 1
    while 3 * a * a <= -d:
        for b in range(-a + 1, a + 1):
            if (b * b - d) % (4 * a) == 0:
                c = (b * b - d) // (4 * a)
                if c >= a and not (b < 0 and a == c) and gcd(gcd(a, b), c) == 1: out.append((a, b, c))
        a += 1
    return out
def kron(d, n):                    # the Kronecker symbol (d/n), n > 0
    r = 1
    while n % 2 == 0:
        n //= 2
        if d % 2 == 0: return 0
        r *= 1 if d % 8 in (1, 7) else -1
    a = d % n
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5): r = -r
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3: r = -r
        a %= n
    return r if n == 1 else 0
def h_formula(d):                  # road 3: h = -(w_K / 2|d|) * sum of kron(d, a) * a for 0 < a < |d|
    w = 6 if d == -3 else 4 if d == -4 else 2
    S = sum(kron(d, a) * a for a in range(1, -d)); return S, -w * S // (2 * -d)
def mink(m): return 2 / pi * (-disc(m)) ** 0.5
def yn(b): return "yes" if b else "no"

m = -5; M = mink(m)
print(f"Q(sqrt -5): d_K = {disc(m)}, degree 2, r1 = 0, r2 = 1, Minkowski bound M_K = (2/pi) sqrt 20 = {M:.6f}")
small = ideals_upto(m, int(M)); print("ideals of norm <= M_K, as (a, b, c):", small)
p = ideal(m, [(2, 0), (1, 1)]); q = ideal(m, [(3, 0), (1, 1)]); q2 = ideal(m, [(3, 0), (1, -1)])
sols = [(x, y) for x in range(-2, 3) for y in range(-1, 2) if x * x + 5 * y * y == 2]
print("p2 = (2, 1 + sqrt-5) =", p, "; solutions of x^2 + 5y^2 = 2:", len(sols), "; p2^2 = (2):", yn(imul(m, p, p) == ideal(m, [(2, 0)])))
cl = class_group(m, small[1:]); fm = forms(-20); S, hf = h_formula(-20)
print("road 1, Minkowski search: h =", len(cl), "; road 2, reduced forms", fm, "h =", len(fm), "; road 3, formula: sum =", S, "h =", hf)
assert sols == [] and len(cl) == len(fm) == hf == 2
I2, I3 = ideal(m, [(2, 0)]), ideal(m, [(3, 0)]); A, B = ideal(m, [(1, 1)]), ideal(m, [(1, -1)])
fact = [I2 == imul(m, p, p), I3 == imul(m, q, q2), A == imul(m, p, q), B == imul(m, p, q2)]
print("6 = 2 x 3 = (1 + sqrt-5)(1 - sqrt-5); (2) = p2 p2, (3) = p3 p3bar, (1 + sqrt-5) = p2 p3, (1 - sqrt-5) = p2 p3bar:", yn(all(fact)))
print("generators: p2, p3, p3bar", *[gen(m, J) or "none" for J in (p, q, q2)], "; p2 p3, p2 p3bar, p3 p3bar", *[gen(m, imul(m, J, K)) for J, K in ((p, q), (p, q2), (q, q2))])
assert all(fact) and gen(m, p) is None and gen(m, q) is None and gen(m, imul(m, q, q2)) == (3, 0)
def pairs(n):                      # factorisations n = u * v into two non-units of Z[sqrt-5], up to sign and order
    out = set()
    for x in range(-n, n + 1):
        for y in range(-n, n + 1):
            N = norm(m, (x, y)); t = mul(m, (n, 0), conj(m, (x, y)))
            if 1 < N < n * n and t[0] % N == 0 and t[1] % N == 0:
                out.add(frozenset(max(u, (-u[0], -u[1])) for u in ((x, y), (t[0] // N, t[1] // N))))
    return sorted(sorted(f) for f in out)
def groupings(J):                  # ways to split four prime ideals into two pairs with principal products
    return {frozenset((imul(m, J[a], J[b]), imul(m, J[c], J[d]))) for a, b, c, d in ((0, 1, 2, 3), (0, 2, 1, 3), (0, 3, 1, 2))
            if gen(m, imul(m, J[a], J[b])) and gen(m, imul(m, J[c], J[d]))}
r = ideal(m, [(7, 0), (3, 1)]); r2 = ideal(m, [(7, 0), (3, -1)])
for n, J in ((6, [p, p, q, q2]), (21, [q, q2, r, r2])):
    print(f"{n}: factorisations found by search {pairs(n)}; pairings of its prime ideals {len(groupings(J))}")
    assert len(pairs(n)) == len(groupings(J))
print("no element has norm 2, 3 or 7:", yn(all(x * x + 5 * y * y not in (2, 3, 7) for x in range(3) for y in range(2))))
allI = ideals_upto(m, 60); npr = [J for J in allI if gen(m, J) is None]
cnt = sum(kron(-20, e) for n in range(1, 61) for e in range(1, n + 1) if n % e == 0)
print(f"ideals of norm <= 60: {len(allI)} (divisor sum of kron(-20, e): {cnt}); not principal {len(npr)}; each of those times p2 principal:",
      yn(all(gen(m, imul(m, J, p)) for J in npr)))
assert len(allI) == cnt and all(gen(m, imul(m, J, p)) for J in npr)
print("m, d_K, M_K, ideals searched, h by search, h by forms, h by formula, orders of the classes")
for m in (-1, -2, -3, -5, -6, -14, -21, -23, -163):
    d = disc(m); g = ideals_upto(m, int(mink(m))); cl = class_group(m, g[1:])
    od = sorted(order(m, J) for J in cl)
    print(m, d, f"{mink(m):.4f}", len(g), len(cl), len(forms(d)), h_formula(d)[1], od)
    assert len(cl) == len(forms(d)) == h_formula(d)[1]
fund = [d for d in range(-3, -1001, -1) if (d % 4 == 1 and all(d % (k * k) for k in range(3, isqrt(-d) + 1, 2)))
        or (d % 4 == 0 and (d // 4) % 4 in (2, 3) and all((d // 4) % (k * k) for k in range(2, isqrt(-d) + 1)))]
one = [d for d in fund if len(forms(d)) == 1]
print(f"fundamental discriminants from -3 to -1000: {len(fund)}; class number 1: {one}")
assert one == [-3, -4, -7, -8, -11, -19, -43, -67, -163]
ps = [n for n in range(2, 200) if all(n % k for k in range(2, isqrt(n) + 1))]
f1 = [n for n in ps if any(x * x + 5 * y * y == n for x in range(15) for y in range(7))]
f2 = [n for n in ps if any(2 * x * x + 2 * x * y + 3 * y * y == n for x in range(-10, 11) for y in range(-10, 11))]
print("primes below 200 of the form x^2 + 5y^2:", f1); print("of the form 2x^2 + 2xy + 3y^2:", f2)
assert f1 == [n for n in ps if n == 5 or n % 20 in (1, 9)] and f2 == [n for n in ps if n == 2 or n % 20 in (3, 7)]
m = -14; g = ideals_upto(m, 2)
print("what breaks: Q(sqrt -14) searched only to norm 2:", len(class_group(m, g[1:])), "classes; to the bound", f"{mink(m):.4f}:", len(class_group(m, ideals_upto(m, 4)[1:])))
m = -23; print("what breaks: Q(sqrt -23), ideals of norm <= M_K counted as classes:", len(ideals_upto(m, 3)), "; true h", len(forms(-23)))
print("what breaks: Z[sqrt -11] taken for the ring of integers: forms of discriminant -44 give", len(forms(-44)), "; true h", len(forms(-11)))
o14, o21 = [sorted(order(k, J) for J in class_group(k, ideals_upto(k, b)[1:])) for k, b in ((-14, 4), (-21, 5))]
print("what breaks: h = 4 for both, class orders -14", o14, "-21", o21); assert o14 == [1, 2, 4, 4] and o21 == [1, 2, 2, 2]
cov = 2 * 5 ** 0.5; rad = (4 * cov / pi) ** 0.5
print(f"figure, rows {5 ** 0.5:.6f} apart, p2 covolume {cov:.6f}, disc radius {rad:.6f}, radius squared {rad * rad:.6f} = M_K N(p2), |1 + sqrt-5| = {6 ** 0.5:.6f}, |2| = 2")
print("ALL CHECKS PASS")
