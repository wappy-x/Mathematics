# The canonical bundle and adjunction -- the check behind the card.  Standard library only.
# Road 1: the top form of projective space, moved between charts by an exact Jacobian.
# Road 2: adjunction arithmetic.  Road 3: Riemann-Hurwitz, branch points counted from an
# exact discriminant modulo a prime.  Road 4: points of the Hermitian curve over GF(16).
from fractions import Fraction as Fr
P = 1000000007                                    # the prime for road 3

class Dual:                                       # a + b e with e^2 = 0: exact first derivatives
    def __init__(s, a, b=0): s.a, s.b = Fr(a), Fr(b)
    def __truediv__(s, o): return Dual(s.a / o.a, (s.b * o.a - s.a * o.b) / (o.a * o.a))

def detp(m):                                       # determinant mod P, by Gaussian elimination
    m, n, d = [r[:] for r in m], len(m), 1
    for c in range(n):
        p = next((r for r in range(c, n) if m[r][c] % P != 0), None)
        if p is None: return 0
        if p != c: m[c], m[p], d = m[p], m[c], -d
        d, inv = d * m[c][c] % P, pow(m[c][c], P - 2, P)
        for r in range(c + 1, n):
            f = m[r][c] * inv % P
            m[r] = [(m[r][k] - f * m[c][k]) % P for k in range(n)]
    return d % P

def jacobian(n, b):                               # chart x1 = 1 -> chart x0 = 1, at b = (b0, b2.., bn)
    cols = []
    for j in range(n):
        v = [Dual(b[k], 1 if k == j else 0) for k in range(n)]
        a = [Dual(1) / v[0]] + [v[k] / v[0] for k in range(1, n)]   # a1 = 1/b0, ak = bk/b0
        cols.append([t.b for t in a])
    m = [[cols[j][i] for j in range(n)] for i in range(n)]
    out = Fr(1)                                   # exact determinant over fractions
    for c in range(n):
        p = next(r for r in range(c, n) if m[r][c] != 0)
        if p != c: m[c], m[p], out = m[p], m[c], -out
        out *= m[c][c]
        for r in range(c + 1, n):
            f = m[r][c] / m[c][c]
            m[r] = [m[r][k] - f * m[c][k] for k in range(n)]
    return out

def disc(F, d, x0):                               # Res_y(F, F_y) at x = x0, mod P, by Sylvester
    a = [sum(c * pow(x0, i, P) for (i, j), c in F.items() if j == k) % P for k in range(d, -1, -1)]
    b = [(d - k) * a[k] % P for k in range(d)]
    N = 2 * d - 1
    return detp([[0] * k + a + [0] * (N - d - 1 - k) for k in range(d - 1)] +
               [[0] * k + b + [0] * (N - d - k) for k in range(d)])

def interpolate(ys):                              # Newton form through x = 0, 1, 2, ..., mod P
    c, n = ys[:], len(ys)
    for j in range(1, n):
        for i in range(n - 1, j - 1, -1):
            c[i] = (c[i] - c[i - 1]) * pow(j, P - 2, P) % P
    poly = [0]
    for i in range(n - 1, -1, -1):                # poly = poly * (x - i) + c[i], low terms first
        poly = [((poly[k - 1] if k else 0) - i * (poly[k] if k < len(poly) else 0) + (c[i] if k == 0 else 0)) % P
                for k in range(len(poly) + 1)]
    while len(poly) > 1 and poly[-1] == 0: poly.pop()
    return poly

def euclid(a, b):                                 # Euclid mod P, low terms first: (gcd, resultant)
    out = 1
    while any(b):
        m, n, a, inv = len(a) - 1, len(b) - 1, a[:], pow(b[-1], P - 2, P)
        while len(a) >= len(b):
            f, s = a[-1] * inv % P, len(a) - len(b)
            a = [(a[k] - f * b[k - s]) % P if k >= s else a[k] for k in range(len(a))][:-1]
        while len(a) > 1 and a[-1] == 0: a.pop()
        out = out * (pow(b[0], m, P) if n == 0 else (-1) ** (m * n) * pow(b[-1], m - len(a) + 1, P)) % P
        a, b = b, a
    return a, (out if len(a) == 1 else 0)

def branch(F, d):                                 # returns deg D, repeated-root degree, simple roots
    xs, Fy = range(d * (d - 1) + 2), {(i, j - 1): j * c for (i, j), c in F.items() if j}
    col = lambda G, x, n: [sum(c * pow(x, i, P) for (i, j), c in G.items() if j == k) % P for k in range(n)]
    ys = [disc(F, d, x) for x in xs]
    assert ys == [euclid(col(F, x, d + 1), col(Fy, x, d))[1] for x in xs]   # Sylvester against Euclid
    D = interpolate(ys)
    g = euclid(D, [k * D[k] % P for k in range(1, len(D))])[0]
    return len(D) - 1, len(g) - 1, len(D) - 1 - 2 * (len(g) - 1)

print("road 1, the top form of P^n moved from chart x1 = 1 to chart x0 = 1")
for n in range(1, 5):
    rest = [5, 7, 11][:n - 1]
    j2, j3 = jacobian(n, [2] + rest), jacobian(n, [3] + rest)
    e = next(e for e in range(10) if j2 * 2 ** e == j3 * 3 ** e)
    print(f"P^{n}: Jacobian at b0 = 2, 3: {j2}, {j3}; equals {j2 * 2 ** e}/b0^{e}: pole of order {e}, K = O({-e})")
    assert e == n + 1 and j2 * 2 ** e == -1
print(f"P^2 at (t, s) = (2, 3): dx ^ dy = {jacobian(2, [2, 3])} dt ^ ds")
print("road 2, adjunction on a plane curve of degree d: K_C = O(d - 3) on C")
genus = {}
for d in range(1, 6):
    degK = d * (d - 3)
    genus[d] = degK // 2 + 1
    mono = sum(1 for i in range(d - 2) for j in range(d - 2 - i))   # x^i y^j, i + j <= d - 3
    print(f"d = {d}: deg K_C = {d}({d} - 3) = {degK} = 2g - 2, g = {genus[d]}; differentials h dx/F_y: {mono}")
    assert degK % 2 == 0 and genus[d] == (d - 1) * (d - 2) // 2 == mono
print("road 3, Riemann-Hurwitz: project to x, count simple roots of the discriminant mod 1000000007")
curves = [(d, {(d, 0): 1, (0, d): 1, (1, 1): 1, (1, 0): 1, (0, 0): 1}, f"x^{d} + y^{d} + xy + x + 1") for d in range(2, 6)]
curves.append((4, {(4, 0): 1, (2, 0): -1, (0, 4): 1, (0, 3): 1, (0, 2): 1, (0, 0): -1}, "x^4 - x^2 + y^4 + y^3 + y^2 - 1"))
for d, F, name in curves:
    deg, rep, b = branch(F, d)
    g = 1 - d + b // 2                            # 2 - 2g = 2d - b
    print(f"{name}: discriminant degree {deg}, repeated {rep}, branch points {b}; 2 - 2g = {2 * d} - {b}, g = {g}")
    assert deg == b == d * (d - 1) and g == genus[d]
print("road 4, the Hermitian curve x^5 = y^4 + y over GF(16), a smooth quintic")
def mul(a, b):                                    # GF(16) as bit-polynomials mod t^4 + t + 1
    r = 0
    for _ in range(4):
        if b & 1: r ^= a
        b, a = b >> 1, (a << 1) ^ (0b10011 if a & 8 else 0)
    return r
def pw(a, k):
    r = 1
    for _ in range(k): r = mul(r, a)
    return r
N = 1 + sum(1 for x in range(16) for y in range(16) if pw(x, 5) == pw(y, 4) ^ y)
print(f"points: {N - 1} affine + 1 at infinity = {N}; Hasse-Weil N <= 17 + 8g gives g >= {(N - 17) // 8}; adjunction g = {genus[5]}")
assert N == 65 and (N - 17) // 8 == genus[5]
print("surfaces of degree e in P^3: K = O(e - 4); a line L has L.L = 2g - 2 - K.L = -2 - (e - 4)")
for e in range(1, 6):
    LL, HH = -2 - (e - 4), e                      # H.H = e: a line meets the surface e times
    print(f"e = {e}: K = O({e - 4}), L.L = {LL}; plane section H.H = {HH}, K.H = {(e - 4) * e}, sum {HH + (e - 4) * e} = 2g - 2 for g = {genus[e]}")
    assert HH + (e - 4) * e == 2 * genus[e] - 2
print("quintic threefold in P^4: K = O(5 - 4 - 1) = O(0)")
print("what breaks")
d = 4                                             # the smooth quartic, true genus 3
print(f"mistake 1, K of P^2 taken as O(-2): g = 1 + d(d - 2)/2 = {1 + 3 * 1 / 2:.1f} for d = 3, {1 + d * (d - 2) // 2} for d = 4")
print(f"mistake 2, twist O(C) dropped: deg K_C = -3d = {-3 * d} for d = 4, g = {-3 * d // 2 + 1}")
print(f"mistake 3, twist with the wrong sign: deg K_C = d(-3 - d) = {d * (-3 - d)} for d = 4, g = {d * (-3 - d) // 2 + 1}")
nodal = {(3, 0): 1, (0, 3): 1, (2, 0): 1, (0, 2): -4}
deg, rep, b = branch(nodal, 3)
t = Fr(1); xt = (4 * t * t - 1) / (1 + t ** 3)
print(f"mistake 4, nodal cubic x^3 + y^3 + x^2 - 4y^2: adjunction says 1; discriminant degree {deg}, repeated {rep}, "
      f"branch points {b}, g = {1 - 3 + b // 2}; t = 1 gives ({xt}, {xt * t}), F = {xt ** 3 + (xt * t) ** 3 + xt ** 2 - 4 * (xt * t) ** 2}")
assert (deg, rep, b) == (6, 1, 4) and xt ** 3 + (xt * t) ** 3 + xt ** 2 - 4 * (xt * t) ** 2 == 0
print("ALL CHECKS PASS")
