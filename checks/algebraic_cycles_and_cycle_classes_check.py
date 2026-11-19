# Algebraic cycles and cycle classes: the check behind the card.  Standard library only.
# X: x^4 - y^4 - z^4 + w^4 = 0, a smooth quartic surface over C.  The plane P: x - y - z + w = 0
# cuts X in a line L (x = y, z = w), a line M (x = z, y = w) and a conic C.  The cycle is W = C + L.
from fractions import Fraction as Fr
import math, cmath

def pmul(p, q):                   # polynomials as {exponent tuple: coefficient}
    r = {}
    for a, c in p.items():
        for b, d in q.items():
            k = tuple(i + j for i, j in zip(a, b)); r[k] = r.get(k, 0) + c * d
    return {k: v for k, v in r.items() if v}
def padd(*ps):
    r = {}
    for p in ps:
        for k, v in p.items(): r[k] = r.get(k, 0) + v
    return {k: v for k, v in r.items() if v}
def ppow(p, n): return pmul(ppow(p, n - 1), p) if n else {(0, 0, 0): 1}
x, y, z = {(1, 0, 0): 1}, {(0, 1, 0): 1}, {(0, 0, 1): 1}
neg = lambda p: {k: -v for k, v in p.items()}
w = padd(neg(x), y, z)                                   # on P, w = -x + y + z
F_on_P = padd(ppow(x, 4), neg(ppow(y, 4)), neg(ppow(z, 4)), ppow(w, 4))
Q = {(2, 0, 0): 1, (0, 2, 0): 2, (0, 0, 2): 2, (1, 1, 0): -1, (1, 0, 1): -1, (0, 1, 1): 3}
split = pmul(pmul(padd(x, neg(y)), padd(x, neg(z))), {k: 2 * v for k, v in Q.items()})
print("road 1, exact algebra on the plane section, over C")
print(f"F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): {'yes' if split == F_on_P else 'no'}")
S = [[Fr(1), Fr(-1, 2), Fr(-1, 2)], [Fr(-1, 2), Fr(2), Fr(3, 2)], [Fr(-1, 2), Fr(3, 2), Fr(2)]]
det = (S[0][0] * (S[1][1] * S[2][2] - S[1][2] * S[2][1]) - S[0][1] * (S[1][0] * S[2][2] - S[1][2] * S[2][0])
       + S[0][2] * (S[1][0] * S[2][1] - S[1][1] * S[2][0]))
print(f"conic matrix determinant {det}, leading minors 1, {S[0][0] * S[1][1] - S[0][1] ** 2}: smooth, no real points")

def meet(a, b, c):                # points of the binary quadratic a s^2 + b s t + c t^2 on P^1: over C, over R
    disc = b * b - 4 * a * c
    return (2 if disc != 0 else 1), (2 if disc > 0 else 1 if disc == 0 else 0), disc
def q_on(u, v):                   # q restricted to the line s u + t v of the plane, as (a, b, c)
    qf = lambda p: sum(S[i][j] * p[i] * p[j] for i in range(3) for j in range(3))
    bil = sum(S[i][j] * u[i] * v[j] for i in range(3) for j in range(3))
    return qf(u), 2 * bil, qf(v)
rows = [("C . L", (1, 1, 0), (0, 0, 1)), ("C . M", (1, 0, 1), (0, 1, 0)), ("C . h (plane x = 0)", (0, 1, 0), (0, 0, 1))]
num = {}
for name, u, v in rows:
    nC, nR, disc = meet(*q_on(u, v))
    num[name] = (nC, nR); print(f"{name}: discriminant {disc}; {nC} points over C, {nR} over R")
def rank(m):                      # rank of a matrix, by exact elimination over Q
    m = [list(map(Fr, r)) for r in m]; rk = 0
    for c in range(len(m[0])):
        piv = next((i for i in range(rk, len(m)) if m[i][c] != 0), None)
        if piv is None: continue
        m[rk], m[piv] = m[piv], m[rk]
        for i in range(len(m)):
            if i != rk and m[i][c] != 0: m[i] = [x - m[i][c] / m[rk][c] * y for x, y in zip(m[i], m[rk])]
        rk += 1
    return rk
lin = [[1, -1, 0, 0], [0, 0, 1, -1], [1, 0, -1, 0], [0, 1, 0, -1]]   # L: x = y, z = w; M: x = z, y = w
pt = (1, 1, 1, 1)
print(f"L . M: (1 : 1 : 1 : 1) on both: {'yes' if all(sum(a * b for a, b in zip(r, pt)) == 0 for r in lin) else 'no'}; "
      f"q there = {sum(S[i][j] for i in range(3) for j in range(3))}, so C misses it")
CL, CM, CH = num["C . L"][0], num["C . M"][0], num["C . h (plane x = 0)"][0]
LM, LH, MH = [int(rank(r) == 3) for r in (lin, lin[:2] + [[1, 0, 0, 0]], lin[2:] + [[1, 0, 0, 0]])]  # 3 independent planes: 1 point
CC, LL, MM = CH - CL - CM, LH - CL - LM, MH - CM - LM    # h = C + L + M, paired with C, L and M
G = [[CC, CL, CM], [CL, LL, LM], [CM, LM, MM]]
hh = CH + LH + MH
print(f"self-intersections from h = C + L + M: C.C = {CC}, L.L = {LL}, M.M = {MM}; adjunction 2g - 2 = -2")
ft = [-1, 0, 0, 0, 1]; dft = [(4 - k) * c for k, c in enumerate(ft[:-1])]   # X on x = y = 0 at w = 1 (w = 0 forces z = 0): 1 - t^4; dft = ft'
npts = 4 - (7 - rank([[0] * i + ft + [0] * (2 - i) for i in range(3)] + [[0] * i + dft + [0] * (3 - i) for i in range(4)]))  # 4 - deg gcd(ft, ft')
print(f"h.h = {CH} + {LH} + {MH} = {hh}; line x = y = 0 meets X where z^4 = w^4: {npts} points")
eu = 4 ** 3 - 4 * 4 ** 2 + 6 * 4                         # Euler number of a smooth quartic surface (quoted formula)
print(f"Euler number {eu}, so H^2 has rank {eu - 2}; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension {eu - 4}")
def pair(a, b): return sum(a[i] * G[i][j] * b[j] for i in range(3) for j in range(3))
def cycle(n, m):                                       # n C + m L
    W = (n, m, 0); return pair(W, (1, 1, 1)), pair(W, W), pair(W, (0, 0, 1))
for n, m in [(1, 1), (3, -2)]:
    d, s, wm = cycle(n, m); print(f"W = {n} C {'+' if m > 0 else '-'} {abs(m)} L: degree W.h = {d}, W.W = {s}, W.M = {wm}")
print(f"[C + L] = h - [M]: pairs with C, L, M as {[pair((1, 1, 0), e) for e in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]} "
      f"and h - M as {[CH - CM, LH - LM, MH - MM]}")

print("road 2, the class read by integrating forms (Simpson's rule)")
om = cmath.exp(2j * math.pi / 3)
p0 = (om, om, 1)                                       # a point of C, where C meets L
def Bf(u, v): return sum(float(S[i][j]) * u[i] * v[j] for i in range(3) for j in range(3))
def curve_C(t):                   # second point of C on the line from p0 towards d = (1, t, 0)
    d, dd = (1, t, 0), (0, 1, 0)
    qd, b = Bf(d, d), Bf(p0, d)
    qd1, b1 = 2 * Bf(d, dd), Bf(p0, dd)
    ph = [qd * p0[i] - 2 * b * d[i] for i in range(3)]
    dph = [qd1 * p0[i] - 2 * b1 * d[i] - 2 * b * dd[i] for i in range(3)]
    return ph + [ph[1] + ph[2] - ph[0]], dph + [dph[1] + dph[2] - dph[0]]
curve_L = lambda t: ([1, 1, t, t], [0, 0, 1, 1])
def fs_area(curve, n=400):        # integral of the hyperplane form h over the curve; a line gives 1
    def dens(t):
        ph, dph = curve(t)
        a = sum(abs(c) ** 2 for c in ph); b = sum(abs(c) ** 2 for c in dph)
        cr = sum(complex(c).conjugate() * e for c, e in zip(ph, dph))
        return (a * b - abs(cr) ** 2) / (math.pi * a * a)
    tot = 0.0
    for i in range(n + 1):        # t = tan(alpha) e^(i theta): Simpson in alpha, trapezium in theta
        al = (math.pi / 2) * i / n; wa = 1 if i in (0, n) else (4 if i % 2 else 2)
        if i == n: continue
        r = math.tan(al); jac = r / math.cos(al) ** 2
        ring = sum(dens(r * cmath.exp(2j * math.pi * k / n)) for k in range(n)) * (2 * math.pi / n)
        tot += wa * ring * jac
    return tot * (math.pi / 2) / n / 3
aC, aL = fs_area(curve_C), fs_area(curve_L)
print(f"integral of h over C {aC:.6f}, over L {aL:.6f}, over W = C + L {aC + aL:.6f}")

print("road 3, the type test")
def gs(c):                        # a Gaussian number with rational parts, printed exactly
    re, im = Fr(c.real), Fr(c.imag)
    if im == 0: return str(re)
    t = "i" if im == 1 else "-i" if im == -1 else f"{im}i"
    return t if re == 0 else f"{re} {'+' if im > 0 else '-'} {t.lstrip('-')}"
def sigma(u, v): return (u[0] * v[1] - u[1] * v[0]) / -4  # dx dy / (dF/dz) at (1, 1, 1), chart w = 1
u, v = (1, 1, 0), (1, 0, 1)                            # tangent to L and to M; together, X's real points
iu, iv = tuple(1j * c for c in u), tuple(1j * c for c in v)
print(f"sigma on L's tangent (u, iu): {gs(sigma(u, iu))}; on M's (v, iv): {gs(sigma(v, iv))}; on the real plane (u, v): {gs(sigma(u, v))}")
def plk(a, b): return tuple(a[i] * b[j] - a[j] * b[i] for i in range(4) for j in range(i + 1, 4))
def dz12(p): return complex(p[1] - p[4], p[2] + p[3])  # dz1 dz2 on the class; basis (1,0), (i,0), (0,1), (0,i)
tor = [("E x 0", (1, 0, 0, 0), (0, 1, 0, 0)), ("0 x E", (0, 0, 1, 0), (0, 0, 0, 1)), ("diagonal", (1, 0, 1, 0), (0, 1, 0, 1)),
       ("graph of i", (1, 0, 0, 1), (0, 1, -1, 0)), ("real torus (1,0), (0,i)", (1, 0, 0, 0), (0, 0, 0, 1))]
cls = []
for name, a, b in tor:
    p = plk(a, b); cls.append(p); print(f"E x E, {name}: class {p}, dz1 dz2 gives {gs(dz12(p))}")
tests = [[0, 1, 0, 0, -1, 0], [0, 0, 1, 1, 0, 0]]     # p13 - p24 = 0, p14 + p23 = 0: the type (1, 1) classes
print(f"rank of the four curve classes {rank(cls[:4])}; rank of all type (1,1) classes 6 - {rank(tests)} = {6 - rank(tests)}")
wC = CH - num["C . L"][1] - num["C . M"][1]
print(f"mistake 1, C . L and C . M over R: {num['C . L'][1]} and {num['C . M'][1]}, so C.C = {CH} - 0 - 0 = {wC}")
print(f"mistake 2, L.L = +1 as in the plane: L.h = {CL + 1 + LM}, but L meets a plane in {LH} point")
print(f"mistake 3, the real torus as a cycle: dz1 dz2 gives {gs(dz12(cls[4]))}, not 0")
assert split == F_on_P and det == Fr(3, 2)                         # the section really is L + M + C
assert (CL, CM, CH) == (2, 2, 2) and num["C . L"][1] == 0         # counts over C against over R
assert (CC, LL, MM) == (-2, -2, -2) and hh == npts                  # linearity against adjunction and a line's points
assert cycle(1, 1)[1] == hh - 2 * MH + MM == 0 and cycle(1, 1)[0] == round(aC + aL) == 3  # [W] = h - [M]
assert abs(aC - CH) < 1e-6 and abs(aL - LH) < 1e-6                  # analysis against counting
assert all(sum(a * b for a, b in zip(r, s + (0,))) == 0 for r, s in zip(lin, (u, u, v, v)))   # u lies along L, v along M
assert sigma(u, iu) == 0 and sigma(v, iv) == 0 and sigma(u, v) != 0
assert all(dz12(p) == 0 for p in cls[:4]) and dz12(cls[4]) != 0
assert rank(cls[:4]) == 6 - rank(tests) == 4
print("ALL CHECKS PASS")
