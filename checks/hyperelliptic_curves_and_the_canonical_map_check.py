# Hyperelliptic curves and the canonical map -- the check behind the card.  Standard library only.
# Polynomials are integer lists, lowest power first.  Roads to the genus: pole orders of differentials
# and branch points from an exact discriminant.  Point counts mod 13 and 13^2 are a consistency check.
from math import sqrt
def disc_formula(n):                 # discriminant of x^n + x + 1, the trinomial formula
    return (-1) ** (n * (n - 1) // 2) * (n ** n + (-1) ** (n - 1) * (n - 1) ** (n - 1))
def det(M):                          # Bareiss elimination: exact integer determinant
    M = [r[:] for r in M]; n = len(M); sign, prev = 1, 1
    for k in range(n - 1):
        if M[k][k] == 0:
            s = next((i for i in range(k + 1, n) if M[i][k] != 0), None)
            if s is None: return 0
            M[k], M[s] = M[s], M[k]; sign = -sign
        for i in range(k + 1, n):
            for j in range(k + 1, n): M[i][j] = (M[i][j] * M[k][k] - M[i][k] * M[k][j]) // prev
        prev = M[k][k]
    return sign * M[n - 1][n - 1]
def disc_sylvester(f):               # (-1)^(n(n-1)/2) Res(f, f') for monic f, by the Sylvester matrix
    n = len(f) - 1; d = [i * f[i] for i in range(1, n + 1)]; S = []
    for r in range(n - 1): S.append([0] * r + f[::-1] + [0] * (n - 2 - r))
    for r in range(n): S.append([0] * r + d[::-1] + [0] * (n - 1 - r))
    return (-1) ** (n * (n - 1) // 2) * det(S)
def orders_at_infinity(n):           # (points at infinity, ord x, ord y, ord dx) on y^2 = f, deg f = n
    return (1, -2, -n, -3) if n % 2 else (2, -1, -n // 2, -2)
def holomorphic(n):                  # the i with x^i dx/y finite at infinity (it is finite elsewhere)
    pts, ox, oy, odx = orders_at_infinity(n)
    return [i for i in range(n) if i * ox + odx - oy >= 0]
print("y^2 = x^n + x + 1: discriminant two ways, branch points, genus two ways")
for n in range(3, 9):
    f = [1, 1] + [0] * (n - 2) + [1]
    D1, D2 = disc_formula(n), disc_sylvester(f)
    assert D1 == D2 and D1 != 0                      # squarefree, so the affine curve is smooth
    branch = n + n % 2                               # n roots, plus infinity when n is odd
    g_rh = (branch - 2) // 2                         # Riemann-Hurwitz for a 2-to-1 map to the line
    hol = holomorphic(n); pts, ox, oy, odx = orders_at_infinity(n)
    degK = pts * (odx - oy)                          # zeros of dx/y, all at infinity
    assert len(hol) == g_rh and degK == 2 * g_rh - 2
    print(f"n = {n}: disc {D1}, branch points {branch}, genus {g_rh}, differentials x^i dx/y for i in {hol}, deg K {degK}")
print("genus-2 curve y^2 = x^5 + x + 1 = (x^2 + x + 1)(x^3 - x^2 + 1)")
mul = lambda a, b: [sum(a[i] * b[k - i] for i in range(len(a)) if 0 <= k - i < len(b)) for k in range(len(a) + len(b) - 1)]
assert mul([1, 1, 1], [1, 0, -1, 1]) == [1, 1, 0, 0, 0, 1]
pts, ox, oy, odx = orders_at_infinity(5)
for i in range(3): print(f"  order at infinity of x^{i} dx/y: {i * ox + odx - oy}")
print(f"  div(dx/y) = 2*inf, div(x dx/y) = (0, 1) + (0, -1): degrees 2 and 2 = 2g - 2")
def chi(a, p):                       # Euler's criterion: +1 square, -1 non-square, 0 zero
    a %= p
    return 0 if a == 0 else (1 if pow(a, (p - 1) // 2, p) == 1 else -1)
p = 13
ev = lambda f, x: sum(c * x ** i for i, c in enumerate(f))
def hyper_points(f):                 # affine points of y^2 = f over F_p, plus one point at infinity
    P = [(x, y) for x in range(p) for y in range(p) if (y * y - ev(f, x)) % p == 0]
    assert len(P) == sum(1 + chi(ev(f, x), p) for x in range(p))   # enumeration against Euler
    return P
def canonical_image(P, g):           # (1 : x : ... : x^(g-1)), infinity goes to (0 : ... : 0 : 1)
    return {tuple(x ** k % p for k in range(g)) for x, y in P} | {tuple([0] * (g - 1) + [1])}
def mirror_rank(P, g):               # rank of the conditions "a_0 + a_1 x + ... vanishes at P and P'"
    ranks = []
    for (x1, y1) in P:
        for (x2, y2) in P:
            if (x1, y1) < (x2, y2):
                rows = [[x1 ** k % p for k in range(g)], [x2 ** k % p for k in range(g)]]
                full = any((rows[0][a] * rows[1][b] - rows[0][b] * rows[1][a]) % p for a in range(g) for b in range(a + 1, g))
                ranks.append(((x1, y1), (x2, y2), 2 if full else 1))
    return ranks
f2 = [1, 1, 0, 0, 0, 1]
P2 = hyper_points(f2); N1 = len(P2) + 1; img2 = canonical_image(P2, 2)
roots2 = [x for x in range(p) if ev(f2, x) % p == 0]
bad2 = [r for r in mirror_rank(P2, 2) if r[2] == 1]
assert len(bad2) == (N1 - 1 - len(roots2)) // 2 and all(a[0] == b[0] for a, b, _ in bad2)
assert 2 * len(img2) - len(roots2) - 1 == N1      # two-to-one except at the branch points
print(f"mod {p}: {N1} points, roots of f at x = {roots2}, canonical image {len(img2)} of {p + 1} points of the line")
print(f"  pairs not separated: {len(bad2)}, every one a mirror pair (x, y), (x, -y); l(K - P - P') = 1 = g - 1")
nr = next(a for a in range(2, p) if chi(a, p) == -1)   # F_169 = F_13 with a square root r of nr
m2 = lambda a, b: ((a[0] * b[0] + nr * a[1] * b[1]) % p, (a[0] * b[1] + a[1] * b[0]) % p)
def pw(a, e):
    r = (1, 0)
    while e:
        if e & 1: r = m2(r, a)
        a, e = m2(a, a), e >> 1
    return r
N2 = 1
for a in range(p):
    for b in range(p):
        v = pw((a, b), 5); v = ((v[0] + a + 1) % p, (v[1] + b) % p)
        N2 += 1 if v == (0, 0) else (2 if pw(v, (p * p - 1) // 2) == (1, 0) else 0)
s1, s2 = p + 1 - N1, p * p + 1 - N2; e2 = (s1 * s1 - s2) // 2
assert (s1 * s1 - s2) % 2 == 0
D = s1 * s1 - 4 * (e2 - 2 * p); b1, b2 = (s1 + sqrt(D)) / 2, (s1 - sqrt(D)) / 2
assert D > 0 and max(abs(b1), abs(b2)) <= 2 * sqrt(p)  # four Frobenius roots of size sqrt(13): fits genus 2
g1_N2 = p * p + 1 - (s1 * s1 - 2 * p)
assert g1_N2 != N2
print(f"mod {p}^2: {N2} points; L(T) = 1 + {-s1}T + {e2}T^2 + {-p * s1}T^3 + {p * p}T^4")
print(f"  alpha + {p}/alpha = {b1:.6f} and {b2:.6f}, both within 2 sqrt({p}) = {2 * sqrt(p):.6f}")
print(f"  a genus-1 curve with {N1} points mod {p} would have {g1_N2} points mod {p}^2")
def rem(a, u):                       # remainder of a on division by the monic u, mod p
    while len(a) >= len(u): s = len(a) - len(u); a = [(c - a[-1] * u[i - s]) % p if i >= s else c for i, c in enumerate(a[:-1])]
    return a
pairs = sum(not any(rem([(c - w) % p for c, w in zip(f2, mul(v, v) + [0] * 6)], u)) for d in range(3)
            for u in ([k // p ** i % p for i in range(d)] + [1] for k in range(p ** d)) for v in ([m // p ** i % p for i in range(d)] for m in range(p ** d)))
L1 = 1 - s1 + e2 - p * s1 + p * p
assert pairs == L1                   # Mumford pairs (u, v): u monic, deg v < deg u <= 2, u divides f - v^2
print(f"  divisor classes of degree 0 mod {p} (the Jacobian group): L(1) = {L1}; reduced pairs (u, v) by search: {pairs}")
print("Fermat curves x^d + y^d = z^d: genus formula against differentials x^i y^j dx/y^(d-1)")
H = {d: [(i, j) for i in range(d) for j in range(d) if -i - j - 2 + (d - 1) >= 0] for d in range(3, 7)}   # ord at the d points at infinity
for d, hol in H.items():
    assert len(hol) == (d - 1) * (d - 2) // 2
    print(f"  d = {d}: genus {(d - 1) * (d - 2) // 2}, differentials {len(hol)}, deg K {d * (-2 + (d - 1))}")
Q = [(x, y, 1) for x in range(p) for y in range(p) if (x ** 4 + y ** 4 - 1) % p == 0]
Q += [(1, y, 0) for y in range(p) if (1 + y ** 4) % p == 0]
nz = lambda u: tuple(c * pow(next(a for a in u if a), p - 2, p) % p for c in u)   # first nonzero entry scaled to 1
img4 = {nz([x ** i * y ** j * z ** (1 - i - j) % p for i, j in H[4]]) for x, y, z in Q}   # x^i y^j dx/y^3, homogenised
assert len(img4) == len(Q)                           # one image per point: nothing folds
print(f"x^4 + y^4 = z^4 mod {p}: {len(Q)} points {sorted(Q)}")
print(f"  canonical map from the differentials x^i y^j dx/y^3, (i, j) in {H[4]}: {len(img4)} images, all {len(Q) * (len(Q) - 1) // 2} pairs separated")
f7 = [1, 1, 0, 0, 0, 0, 0, 1]
assert disc_sylvester(f7) % p != 0
P7 = hyper_points(f7); img7 = canonical_image(P7, 3); bad7 = [r for r in mirror_rank(P7, 3) if r[2] == 1]
assert all((u[0] * u[2] - u[1] * u[1]) % p == 0 for u in img7)   # the image lies on the conic u0 u2 = u1^2
print(f"y^2 = x^7 + x + 1 mod {p}: {len(P7) + 1} points, canonical image {len(img7)} points on the conic u0 u2 = u1^2")
print(f"  mirror pairs not separated: {len(bad7)}, l(K - P - P') = 2 = g - 1: hyperelliptic, not a plane quartic")
print("what breaks")
proj = [(1, 0, 2, 3)] + [(-c, i, 0, 5 - i) for i, c in enumerate(f2) if c]   # y^2 z^3 - x^5 - x z^4 - z^5 as (c, a, b, e)
mult = min(a + e for c, a, b, e in proj)              # set y = 1: lowest degree in x and z at (0 : 1 : 0)
print(f"  plane genus formula on degree 5: {(5 - 1) * (5 - 2) // 2}; y^2 z^3 = x^5 + x z^4 + z^5 at (0 : 1 : 0) has multiplicity {mult}")
print(f"  counting x^2 dx/y too: {len(holomorphic(5)) + 1} differentials, order at infinity {2 * ox + odx - oy}")
nodal = [0, 0, 1, 1]                                 # y^2 = x^2 (x + 1): x = 0 is a double root
assert disc_sylvester(nodal) == 0
odd = [r for r in range(-3, 4) if ev(nodal, r) == 0 and ev([0, 2, 3], r) != 0]   # simple roots only
assert all((t * (t * t - 1)) ** 2 == ev(nodal, t * t - 1) for t in range(-5, 6))   # smooth model x = t^2 - 1, y = t(t^2 - 1)
print(f"  nodal cubic: disc 0, branch points {len(odd) + 1}, genus {(len(odd) + 1 - 2) // 2}; dx/y = 2 dt/(t^2 - 1), poles at t = 1 and -1")
lo, hi = -1.0, 0.0                                   # real branch point: root of x^3 - x^2 + 1, by bisection
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if mid * mid * mid - mid * mid + 1 < 0 else (lo, mid)
assert abs(lo * lo * lo * lo * lo + lo + 1) < 1e-12
y1, y12 = sqrt(3.0), sqrt(1.2 * 1.2 * 1.2 * 1.2 * 1.2 + 2.2)
print(f"figure,branch,{lo:.6f},0,mirror,0,1,0,-1,x=1,{y1:.6f},x=1.2,{y12:.6f}")
print("ALL CHECKS PASS")
