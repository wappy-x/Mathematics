# Intersection numbers on the plane blown up at one point -- the check behind the card.  Standard library only.
# Road 1: count meeting points of real curves on the blow-up X, inside P^2 x P^1 over F_7 and F_11.
# Road 2: the winding of the gluing rule of O(E) along E, the degree of E's normal line bundle.
# Road 3: Riemann-Roch against a count of plane forms that vanish to a given order at p.
import math
from itertools import product

def p2(q):  # one representative per point of P^2 over F_q
    return [(1, y, z) for y in range(q) for z in range(q)] + [(0, 1, z) for z in range(q)] + [(0, 0, 1)]

def p1(q):
    return [(1, v) for v in range(q)] + [(0, 1)]

def blowup(q):  # X = {((x : y : z), (u : v)) : xv = yu}, the plane blown up at p = (0 : 0 : 1)
    return [(P, D) for P in p2(q) for D in p1(q) if (P[0] * D[1] - P[1] * D[0]) % q == 0]

curves = {  # each curve on X as an equation in (x, y, z) and (u, v)
    "E": lambda P, D, q: P[0] % q == 0 and P[1] % q == 0,              # all directions at p
    "H1": lambda P, D, q: P[2] % q == 0,                                 # the line z = 0, missing p
    "H2": lambda P, D, q: (P[0] + P[1] - P[2]) % q == 0,                 # the line z = x + y, missing p
    "H3": lambda P, D, q: (P[0] - 3 * P[2]) % q == 0,                    # the line x = 3z, missing p
    "L1": lambda P, D, q: D[1] % q == 0,                                 # strict transform of y = 0
    "L2": lambda P, D, q: (D[1] - D[0]) % q == 0,                        # strict transform of y = x
    "C": lambda P, D, q: ((D[1] ** 2 - D[0] ** 2) * P[2] - P[0] * D[0] ** 2) % q == 0,  # nodal cubic y^2 z = x^3 + x^2 z
}

def meet(a, b, q, X):
    return sum(1 for P, D in X if curves[a](P, D, q) and curves[b](P, D, q))

def dot(A, B, M):  # intersection pairing of classes written in a basis with Gram matrix M
    return sum(A[i] * M[i][j] * B[j] for i in range(len(A)) for j in range(len(B)))

counts = {}
for q in (7, 11):
    X = blowup(q)
    pairs = [("H1", "H2"), ("H1", "E"), ("L1", "E"), ("L1", "L2"), ("C", "E"), ("C", "L1"), ("C", "H3")]
    counts[q] = {a + "." + b: meet(a, b, q, X) for a, b in pairs}
    print(f"over F_{q}: X has {len(X)} points = ({q} + 1)^2; meeting points " +
          ", ".join(f"{k} {v}" for k, v in counts[q].items()))
    assert len(X) == (q + 1) ** 2 == len(p2(q)) - 1 + len(p1(q))
assert counts[7] == counts[11]
c = counts[7]
HH, HE = c["H1.H2"], c["H1.E"]
E2_from_one_line = HE - c["L1.E"]                  # (H - E).E = 1 gives H.E - E^2 = 1
E2_from_two_lines = c["L1.L2"] - HH + 2 * HE       # (H - E)^2 = 0 gives H^2 - 2 H.E + E^2 = 0
print(f"road 1: H^2 = {HH}, H.E = {HE}; (H - E).E = {c['L1.E']} gives E^2 = {E2_from_one_line}; "
      f"(H - E)^2 = {c['L1.L2']} gives E^2 = {E2_from_two_lines}")
M = [[HH, HE], [HE, E2_from_one_line]]             # Gram matrix in the basis H, E
H, E = (1, 0), (0, 1)
cubic = (3, -2)                                    # the nodal cubic: 3H minus E twice, for its double point at p
pred = [dot(cubic, E, M), dot(cubic, (1, -1), M), dot(cubic, H, M)]
print(f"Gram matrix in the basis H, E: {M}, signature (1, 1)")
print(f"nodal cubic 3H - 2E: predicted .E, .(H - E), .H = {pred}; counted {[c['C.E'], c['C.L1'], c['C.H3']]}")
assert E2_from_one_line == E2_from_two_lines == -1 and pred == [c["C.E"], c["C.L1"], c["C.H3"]]

# road 2: O(E) has local equations x (chart y = t x) and y (chart x = s y); on E they glue by x/y = 1/t
N, wind = 360, 0.0
for k in range(N):
    a0, a1 = 2 * math.pi * k / N, 2 * math.pi * (k + 1) / N
    g0, g1 = 1 / complex(math.cos(a0), math.sin(a0)), 1 / complex(math.cos(a1), math.sin(a1))
    wind += math.atan2((g1 / g0).imag, (g1 / g0).real)
deg = round(wind / (2 * math.pi))
print(f"road 2: gluing rule 1/t once round |t| = 1 winds {wind / (2 * math.pi):.6f} times, so deg O(E)|E = E^2 = {deg}")
assert abs(wind / (2 * math.pi) - deg) < 1e-9 and deg == M[1][1]

K = (-3, 1)                                        # K_X = pullback of K_P2 = -3H, plus E
K2, euler = dot(K, K, M), 3 - 1 + 2                # e(X): the plane's 3, minus the point, plus the sphere E
print(f"K = -3H + E: K^2 = 9 - 1 = {K2}; e(X) = 3 - 1 + 2 = {euler}; Noether K^2 + e = {K2 + euler} = 12 x chi(O_X), chi(O_X) = 1")
assert K2 + euler == 12

def genus(C, M, K):
    two_g_minus_2 = dot(C, C, M) + dot(K, C, M)
    return two_g_minus_2, (two_g_minus_2 + 2) / 2

print("adjunction 2g - 2 = C^2 + K.C:")
for name, C in [("E", (0, 1)), ("line H", (1, 0)), ("line through p, H - E", (1, -1)),
                ("conic through p, 2H - E", (2, -1)), ("nodal cubic, 3H - 2E", (3, -2)), ("cubic missing p, 3H", (3, 0))]:
    t, g = genus(C, M, K)
    print(f"  {name}: C^2 = {dot(C, C, M)}, K.C = {dot(K, C, M)}, 2g - 2 = {t}, g = {g:g}")
    assert g == int(g) and g >= 0
assert genus((0, 1), M, K)[1] == genus((3, -2), M, K)[1] == 0 and genus((3, 0), M, K)[1] == 1

# road 3: sections of aH - bE are degree-a forms vanishing to order b at p: monomials x^i y^j z^k with i + j >= b
tested = 0
for a in range(0, 7):
    for b in range(0, a + 2):
        forms = sum(1 for i in range(a + 1) for j in range(a + 1 - i) if i + j >= b)
        D = (a, -b)
        rr = 1 + (dot(D, D, M) - dot(K, D, M)) // 2
        assert forms == rr and (dot(D, D, M) - dot(K, D, M)) % 2 == 0
        tested += 1
print(f"road 3: forms vanishing to order b at p = 1 + (D^2 - K.D)/2 for all {tested} classes aH - bE, 0 <= a <= 6, b <= a + 1;"
      f" conics through p: {1 + (dot((2, -1), (2, -1), M) - dot(K, (2, -1), M)) // 2}")

A = (3, -1)                                        # an ample class: positive on every curve
box = [(x, y) for x in range(-6, 7) for y in range(-6, 7) if (x, y) != (0, 0)]
perp = [D for D in box if dot(A, D, M) == 0]
print(f"Hodge index: A = {A[0]}H {'-' if A[1] < 0 else '+'} {'' if abs(A[1]) == 1 else abs(A[1])}E, A^2 = {dot(A, A, M)}; classes in the box with A.D = 0: {perp}, squares {[dot(D, D, M) for D in perp]}")
assert dot(A, A, M) > 0 and all(dot(D, D, M) < 0 for D in perp)
assert all(dot(A, D, M) ** 2 >= dot(A, A, M) * dot(D, D, M) for D in box)

M6 = [[1 if i == j == 0 else -1 if i == j else 0 for j in range(7)] for i in range(7)]   # six points blown up
K6 = (-3, 1, 1, 1, 1, 1, 1)
ex = [C for C in product(range(0, 4), *[range(-2, 3)] * 6) if dot(C, C, M6) == -1 and dot(K6, C, M6) == -1]
print(f"six points (the cubic surface): K^2 = {dot(K6, K6, M6)}, classes with C^2 = -1 and K.C = -1: {len(ex)}")
assert dot(K6, K6, M6) == 3 and len(ex) == 27

M2, K2b = [[1, 0, 0], [0, -1, 0], [0, 0, -1]], (-3, 1, 1)   # blow up p, then a point of E
C = (0, 1, -1)                                     # strict transform of the first E: E1 - E2
KP2 = dot((-3,), (-3,), [[1]])                    # K of the plane is -3H, with H^2 = 1
print(f"contract E: K^2 goes from {K2} to {K2 + 1}, and K^2 of P^2 = (-3)^2 = {KP2}")
assert dot(C, C, M2) == -2 and dot(K2b, C, M2) == 0 and K2 + 1 == KP2
Mbad = [[1, 0], [0, 1]]
print(f"mistake 1, E^2 = +1 like a line: (H - E).E = {dot((1, -1), E, Mbad)}, a negative count; Noether {dot(K, K, Mbad) + euler}, not 12")
t2 = dot(E, E, M) + dot((-3, 0), E, M)
print(f"mistake 2, K = -3H (no E): 2g - 2 for E = {t2}, so g = {(t2 + 2) / 2}")
print(f"mistake 3, a line through p kept as H: two of them meet {HH} time by H^2, counted after the blow-up {c['L1.L2']}")
print(f"mistake 4, blow up a point of E too and contract E1 - E2: square {dot(C, C, M2)}, K.C = {dot(K2b, C, M2)}, g = {genus(C, M2, K2b)[1]:g}, "
      "but Castelnuovo needs -1; the result is a cone point")
print("figure, p (160, 150); lines through p at slopes t = -1, 0, 1 end at (70, 60)-(250, 240), (70, 150)-(250, 150), "
      "(70, 240)-(250, 60); E at y = 150; fibres H - E at x = " + ", ".join(str(490 + 70 * t) for t in (-1, 0, 1)))
print("ALL CHECKS PASS")
