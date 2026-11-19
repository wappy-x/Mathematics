# Hodge decomposition: the square-lattice torus, complex tori, the quartic surface, the quintic threefold
import math
from fractions import Fraction as Fr
from itertools import combinations, product

def fr(x):  # a fraction, printed in lowest terms
    return str(x.numerator) if x.denominator == 1 else f"{x.numerator}/{x.denominator}"
def cx(z):  # an exact complex number (re, im), printed as re + im i
    return f"{fr(Fr(z[0]))} {'-' if z[1] < 0 else '+'} {fr(abs(Fr(z[1])))} i"
def gmul(u, v):  # product of two Gaussian integers (re, im)
    return (u[0] * v[0] - u[1] * v[1], u[0] * v[1] + u[1] * v[0])
def gsub(u, v):
    return (u[0] - v[0], u[1] - v[1])
def gdiv(n, d):  # n / d as an exact complex fraction
    m = d[0] ** 2 + d[1] ** 2
    return (Fr(n[0] * d[0] + n[1] * d[1], m), Fr(n[1] * d[0] - n[0] * d[1], m))

# 1. The torus C / (Z + Zi). Periods round the loops a (0 to 1) and b (0 to i)
dz, dzb = [(1, 0), (0, 1)], [(1, 0), (0, -1)]  # [period on a, period on b]
print(f"periods of dz: a {cx(dz[0])}, b {cx(dz[1])}; of dz-bar: a {cx(dzb[0])}, b {cx(dzb[1])}")
det = gsub(gmul(dz[0], dzb[1]), gmul(dzb[0], dz[1]))
print(f"period determinant = {cx(det)}")
assert det != (0, 0)  # dz and dz-bar are independent classes, so h10 + h01 = 2 = b1
# Road 1: Cramer's rule on the periods (A, B) of the closed real form 3 dx + 5 dy
A, B = (3, 0), (5, 0)
c1 = gdiv(gsub(gmul(A, dzb[1]), gmul(dzb[0], B)), det)
c2 = gdiv(gsub(gmul(dz[0], B), gmul(A, dz[1])), det)
print(f"{A[0]} dx + {B[0]} dy = ({cx(c1)}) dz + ({cx(c2)}) dz-bar")
# Road 2: substitute dx = (dz + dz-bar)/2 and dy = (dz - dz-bar)/(2i), then collect the dz and dz-bar parts
dxc, dyc = [(Fr(1, 2), Fr(0))] * 2, [gdiv((1, 0), (0, 2)), gdiv((-1, 0), (0, 2))]
s1, s2 = [(A[0] * dxc[j][0] + B[0] * dyc[j][0], A[0] * dxc[j][1] + B[0] * dyc[j][1]) for j in (0, 1)]
assert (c1, c2) == (s1, s2)
assert c2 == (c1[0], -c1[1])  # Hodge symmetry: the (0,1) part is the conjugate of the (1,0) part
# Road 3: integrate c1 dz + c2 dz-bar along wiggly loops in the classes of a and b
def integral(velocity, n=4000):  # midpoint rule over t in [0, 1], in real arithmetic
    re = im = 0.0
    for k in range(n):
        vx, vy = velocity((k + 0.5) / n)  # dz reads vx + i vy, dz-bar reads vx - i vy
        re += (float(c1[0] + c2[0]) * vx - float(c1[1] - c2[1]) * vy) / n
        im += (float(c1[1] + c2[1]) * vx + float(c1[0] - c2[0]) * vy) / n
    return re, im
w = 0.2 * 2 * math.pi  # a(t) = t + 0.2 i sin(2 pi t), b(t) = i t + 0.2 sin(2 pi t)
ia = integral(lambda t: (1.0, w * math.cos(2 * math.pi * t)))
ib = integral(lambda t: (w * math.cos(2 * math.pi * t), 1.0))
print(f"wiggly loop a gives {ia[0]:.9f} {ia[1]:+.9f} i; wiggly loop b gives {ib[0]:.9f} {ib[1]:+.9f} i")
assert abs(ia[0] - A[0]) + abs(ia[1]) < 1e-9 and abs(ib[0] - B[0]) + abs(ib[1]) < 1e-9  # the loops return the periods

# 2. Complex n-torus: count wedges of dz's and dz-bars by type, against binomials
for n in (1, 2):
    syms = [("dz", i) for i in range(n)] + [("dzb", i) for i in range(n)]
    h = {}
    for k in range(2 * n + 1):
        for S in combinations(syms, k):
            p = sum(1 for s in S if s[0] == "dz")
            h[(p, k - p)] = h.get((p, k - p), 0) + 1
    for k in range(2 * n + 1):
        ps = range(max(0, k - n), min(k, n) + 1)
        row = [h[(p, k - p)] for p in ps]
        assert sum(row) == math.comb(2 * n, k) and row == row[::-1]
        assert row == [math.comb(n, p) * math.comb(n, k - p) for p in ps]
        print(f"torus dim {n}, k = {k}: b{k} = {math.comb(2 * n, k)} = " + " + ".join(map(str, row)))
    if n == 1:
        hol_only = h[(1, 0)]

# 3. Hypersurfaces in projective space, two roads
def jac_ring(nv, d, deg):  # monomials of degree deg with exponents <= d - 2 (Fermat Jacobian ring)
    return sum(1 for e in product(range(d - 1), repeat=nv) if sum(e) == deg)
def euler(n, d):  # topological Euler characteristic of a smooth degree-d hypersurface of dimension n
    return d * sum(math.comb(n + 2, n - j) * (-d) ** j for j in range(n + 1))
R = [jac_ring(4, 4, 4 * q) for q in range(3)]  # quartic surface: n = 2, d = 4
h20, h11, h02 = R[0], R[1] + 1, R[2]
print(f"quartic, Jacobian ring: h20 = {R[0]}, primitive h11 = {R[1]}, h02 = {R[2]}; with the hyperplane class h11 = {h11}")
chi = euler(2, 4)
b2, pg = chi - 2, math.comb(4 - 1, 3)
noether = Fr((4 - 4) ** 2 * 4 + chi, 12)  # (K^2 + Euler characteristic)/12, with K = (d - 4) h
print(f"quartic, topology: Euler characteristic {chi}, b2 = {b2}, p_g = {pg}, Noether (K^2 + 24)/12 = {fr(noether)}")
assert (h20, h02) == (pg, pg) and h11 == b2 - 2 * pg and noether == 1 + pg
print(f"quartic diamond rows: 1 | 0 0 | {h20} {h11} {h02} | 0 0 | 1")
Q = [jac_ring(5, 5, 5 * q) for q in range(4)]  # quintic threefold: n = 3, d = 5
chi3 = euler(3, 5)
b3 = 4 - chi3  # Euler characteristic = 1 - 0 + 1 - b3 + 1 - 0 + 1
print(f"quintic, Jacobian ring: h30, h21, h12, h03 = {Q[0]}, {Q[1]}, {Q[2]}, {Q[3]}")
print(f"quintic, topology: Euler characteristic {chi3}, b3 = {b3}")
assert sum(Q) == b3 and Q == Q[::-1]

# 4. What breaks
s1p, s3p = [1, 1], [1, 0, 0, 1]  # Poincare polynomials 1 + t and 1 + t^3
hopf = [sum(s1p[i] * s3p[k - i] for i in range(2) if 0 <= k - i < 4) for k in range(5)]
print(f"Hopf surface S1 x S3, Betti numbers {hopf}: b1 = {hopf[1]} is odd, so h10 = h01 is impossible")
assert hopf[1] % 2 == 1
print(f"mistakes: torus with holomorphic forms only, b1 = {hol_only}; quartic h11 read as b2 = {b2}; no hyperplane class, h11 = {R[1]}")
pts = [("0", (0, 0)), ("1", (1, 0)), ("i", (0, 1)), ("1+i", (1, 1))]
print("figure, 150 px per unit, " + ", ".join(f"{m} at ({60 + 150 * z[0]},{360 - 150 * z[1]})" for m, z in pts))
print("ALL CHECKS PASS")
