# Moduli spaces in outline -- the check behind the card.  Standard library only.
# The j-line: exact j of four curves, against the j of four lattice shapes by a
# q-series and by a direct lattice sum; every j reached by one family; a twist
# with equal j but a different point count.  The Grassmannian G(2, 4): lines in
# 3-space counted over F_5 as subspaces and as points of the Plucker quadric,
# and the two lines meeting four given lines, by substitution and by search.
from fractions import Fraction as Fr
import math

def j_ab(a, b):                                    # j of y^2 = x^3 + ax + b, exact
    a, b = Fr(a), Fr(b)
    return 1728 * 4 * a**3 / (4 * a**3 + 27 * b**2)

def family(j):                                     # a curve with j-invariant j
    return 3 * j * (1728 - j), 2 * j * (1728 - j)**2

def count(p, a, b):                                # points mod p, O included
    return 1 + sum((y * y - x**3 - a * x - b) % p == 0 for x in range(p) for y in range(p))

def cmul(z, w): return (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])
def cadd(z, w): return (z[0] + w[0], z[1] + w[1])
def cdiv(z, w):
    d = w[0] * w[0] + w[1] * w[1]
    return ((z[0] * w[0] + z[1] * w[1]) / d, (z[1] * w[0] - z[0] * w[1]) / d)
def j_from(e4, e6, k):                             # k e4^3 / (e4^3 - e6^2), complex
    c = cmul(e4, cmul(e4, e4))
    return cdiv(cmul((k, 0.0), c), cadd(c, cmul((-1.0, 0.0), cmul(e6, e6))))

def j_qseries(t, terms=30):                        # road 1: Eisenstein q-series
    r = math.exp(-2 * math.pi * t[1])
    q = (r * math.cos(2 * math.pi * t[0]), r * math.sin(2 * math.pi * t[0]))
    e4, e6, qn = (1.0, 0.0), (1.0, 0.0), (1.0, 0.0)
    for n in range(1, terms):
        qn = cmul(qn, q)
        s3 = sum(d**3 for d in range(1, n + 1) if n % d == 0)
        s5 = sum(d**5 for d in range(1, n + 1) if n % d == 0)
        e4 = cadd(e4, (240.0 * s3 * qn[0], 240.0 * s3 * qn[1]))
        e6 = cadd(e6, (-504.0 * s5 * qn[0], -504.0 * s5 * qn[1]))
    return j_from(e4, e6, 1728.0)

def j_lattice(t, R=400):                           # road 2: sum over lattice points
    g4, g6, top = (0.0, 0.0), (0.0, 0.0), int(R / t[1]) + 1
    for m in range(-R, R + 1):
        for n in range(-top, top + 1):
            w = (m + n * t[0], n * t[1])
            if (m == 0 and n == 0) or w[0] * w[0] + w[1] * w[1] > R * R:
                continue
            w2 = cmul(w, w); w4 = cmul(w2, w2)
            g4 = cadd(g4, cdiv((1.0, 0.0), w4)); g6 = cadd(g6, cdiv((1.0, 0.0), cmul(w4, w2)))
    g2, g3 = (60 * g4[0], 60 * g4[1]), (140 * g6[0], 140 * g6[1])
    return j_from(g2, (math.sqrt(27) * g3[0], math.sqrt(27) * g3[1]), 1728.0)

IDX = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
def plucker(u, v, p=0):                            # six 2 x 2 minors, mod p if p
    out = [u[i] * v[k] - u[k] * v[i] for i, k in IDX]
    return [x % p for x in out] if p else out
def meet(P, Q):                                    # zero exactly when the lines meet
    return P[0]*Q[5] - P[1]*Q[4] + P[2]*Q[3] + P[3]*Q[2] - P[4]*Q[1] + P[5]*Q[0]
def quad(P): return P[0] * P[5] - P[1] * P[4] + P[2] * P[3]
def normal(P, p):                                  # scale so the first nonzero is 1
    lead = next(x for x in P if x)
    inv = pow(lead, p - 2, p)
    return tuple(x * inv % p for x in P)

curves = [("x^3 - 2", 0, -2, (-0.5, math.sqrt(3) / 2), "rho"), ("x^3 - x", -1, 0, (0.0, 1.0), "i"),
          ("x^3 - 30x + 56", -30, 56, (0.0, math.sqrt(2)), "i sqrt2"),
          ("x^3 - 11x + 14", -11, 14, (0.0, 2.0), "2i"), ("x^3 - 11x + 14", -11, 14, (0.0, 0.5), "i/2")]
for name, a, b, t, tn in curves:
    jq, jl = j_qseries(t), j_lattice(t)
    print(f"y^2 = {name}: j = {j_ab(a, b)}; tau = {tn}: q-series {jq[0]:.6f}, lattice sum {jl[0]:.2f}")
    assert abs(jq[0] - j_ab(a, b)) < 1e-6 * (1 + abs(j_ab(a, b))) and abs(jq[1]) < 1e-6
    assert abs(jl[0] - j_ab(a, b)) < 2e-6 * (1 + abs(j_ab(a, b)))
q = math.exp(-4 * math.pi)
print(f"by hand: 4a^3 = 4 x {(-11)**3} = {4 * (-11)**3}; 27b^2 = 27 x {14**2} = {27 * 14**2}; sum {4 * (-11)**3 + 27 * 14**2}")
print(f"tau = 2i: q = e^(-4 pi) = {q * 1e6:.10f} x 10^-6; 1/q = {1 / q:.2f}; 1/q + 744 + 196884 q = {1 / q + 744 + 196884 * q:.3f}")
print(f"1728 = 12^3 = {12**3}; 8000 = 20^3 = {20**3}; 287496 = 66^3 = {66**3}")
for j in [Fr(1), Fr(8000), Fr(287496), Fr(-3375), Fr(6912, 31)]:
    a, b = family(j)
    assert j_ab(a, b) == j                         # every j is reached
print(f"family at j = 8000: a = {family(8000)[0]}, b = {family(8000)[1]}; j back = {j_ab(*family(8000))}")
print(f"rescale to x^3 - 30x + 56: u^4 = {Fr(family(8000)[0], -30)}, u^6 = {Fr(family(8000)[1], 56)}, u^2 = 2240, 2240^3 = {2240**3}")
fam = [(t, Fr(6912 * t, 4 * t + 27), j_ab(t, t)) for t in (1, 2, 5)]
print("family y^2 = x^3 + tx + t: " + "; ".join(f"t = {t}: 6912t/(4t+27) = {f}, direct {d}" for t, f, d in fam))
assert all(f == d for _, f, d in fam)
print(f"family at t = 0: the cusp y^2 = x^3, 4t^3 + 27t^2 = {4 * 0**3 + 27 * 0**2}, yet 6912t/(4t+27) = {Fr(6912 * 0, 4 * 0 + 27)}")
c1, c2 = count(11, -30, 56), count(11, -30, -56)
print(f"twist: x^3 - 30x + 56 and x^3 - 30x - 56 both j = {j_ab(-30, -56)}; points mod 11: {c1} and {c2}, sum {c1 + c2} = 2 x 11 + 2")
assert c1 != c2 and c1 + c2 == 24
p = 5
vecs = [(a, b, c, d) for a in range(p) for b in range(p) for c in range(p) for d in range(p)]
subspaces = {normal(plucker(u, v, p), p) for u in vecs for v in vecs if any(plucker(u, v, p))}
pts = [P for P in (normal(list(v6), p) for v6 in __import__("itertools").product(range(p), repeat=6) if any(v6)) if quad(P) % p == 0]
pts = sorted(set(pts))
print(f"G(2, 4) over F_5: planes in F_5^4 = {len(subspaces)}; points on the Plucker quadric = {len(pts)}; (p^2 + 1)(p^2 + p + 1) = {(p*p + 1) * (p*p + p + 1)}")
print(f"all of P^5 over F_5, relation dropped = {(p**6 - 1) // (p - 1)}")
assert len(subspaces) == len(pts) == 806 and set(pts) == subspaces
L = [((0, 0, 0, 1), (1, 0, 0, 1)), ((0, 0, 1, 1), (0, 1, 1, 1)), ((-1, -1, 0, 1), (2, 1, 1, 1)), ((-1, 0, 2, 1), (0, 1, -1, 1))]
PL = [plucker(u, v) for u, v in L]
A, B = plucker((1, 0, 0, 1), (0, 0, 1, 1)), plucker((0, 0, 0, 1), (0, -1, 1, 1))
skew = [meet(PL[i], PL[k]) for i in range(4) for k in range(i + 1, 4)]
print(f"four lines, Plucker: {PL}; pairwise meet values {skew}, none 0, so no two meet")
assert all(skew)
A2 = plucker((2, 0, -1, 1), (-1, 0, 2, 1))
print(f"line A through (2,0,-1), (-1,0,2) instead: {A2} = {Fr(A2[1], A[1])} x A")
assert all(x * A2[1] == y * A[1] for x, y in zip(A, A2))
print(f"line A through (1,0,0), (0,0,1): {A}; relation {quad(A)}; meets L1..L4: {[meet(A, P) for P in PL]}")
print(f"line B through (0,0,0), (0,-1,1): {B}; relation {quad(B)}; meets L1..L4: {[meet(B, P) for P in PL]}")
assert quad(A) == quad(B) == 0 and all(meet(X, P) == 0 for X in (A, B) for P in PL)
col = [A[1], A[3], 0, -A[5]]                       # column 3 of the table: p13, p23, p33 = 0, p43 = -p34
print(f"line A, column 3 (p13, p23, p33, p43) = {tuple(col)}: the point (1, 0, 0)")
assert any(col) and all(meet(A, plucker(col, e)) == 0 for e in [(1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)])
found = [P for P in pts if all(meet(P, [x % p for x in Q]) % p == 0 for Q in PL)]
print(f"search over all 806 lines mod 5 meeting all four: {len(found)}; A, B mod 5 = {[normal([x % p for x in X], p) for X in (A, B)]}")
assert sorted(found) == sorted(normal([x % p for x in X], p) for X in (A, B))
print(f"mistake, node y^2 = x^3 - 3x + 2: 4a^3 + 27b^2 = {4 * (-3)**3 + 27 * 2**2}, so j has no value")
print(f"figure, rho (-0.5, {math.sqrt(3) / 2:.6f}); i (0, 1); i sqrt2 (0, {math.sqrt(2):.6f}); 2i (0, 2); i/2 (0, 0.5)")
print("ALL CHECKS PASS")
