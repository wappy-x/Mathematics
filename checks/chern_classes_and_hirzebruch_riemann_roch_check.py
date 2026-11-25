# Chern classes and Hirzebruch-Riemann-Roch -- the check behind the card.  Standard library only.
# Classes on P^2 live in Q[H]/(H^3): a list [a0, a1, a2] means a0 + a1 H + a2 H^2, and H^2 = one point.
# Road 1: Hirzebruch-Riemann-Roch, chi = the H^2 coefficient of ch times td.
# Road 2: Cech count: monomials of degree d with all powers >= 0 (h^0) or all <= -1 (h^2).
# Road 3: Riemann-Roch for surfaces, and on the cubic surface an exact rank count of plane cubics.
from fractions import Fraction as Fr
from itertools import combinations

def mul(a, b):                                         # product in Q[H]/(H^3)
    return [sum(a[i] * b[k - i] for i in range(k + 1)) for k in range(3)]

def inv(a):                                            # 1/a as a power series, a[0] = 1
    b = [Fr(1), Fr(0), Fr(0)]
    for k in (1, 2): b[k] = -sum(a[i] * b[k - i] for i in range(1, k + 1))
    return b

def fact(n): return 1 if n < 2 else n * fact(n - 1)
def expH(t): return [Fr(t) ** k / fact(k) for k in range(3)]   # e^(tH), the Chern character of O(t)
def s(x): return str(x)
def pol(a, v):                                         # a0 + a1 v + a2 v^2, fractions in brackets
    out = s(a[0])
    for k, x in ((1, a[1]), (2, a[2])):
        x = Fr(x); co = "" if x == 1 else s(x) if x.denominator == 1 else f"({s(x)})"
        out += f" + {co}{v}" + ("^2" if k == 2 else "")
    return out

# The Todd class of P^2, two ways.  Euler sequence: T + O = O(1) + O(1) + O(1), so the Chern roots are H, H, H.
q = inv([Fr((-1) ** k, fact(k + 1)) for k in range(3)])  # H / (1 - e^(-H)) = 1/((1 - e^(-H))/H)
td = mul(mul(q, q), q)                                 # one factor per Chern root
c = mul(mul([1, 1, 0], [1, 1, 0]), [1, 1, 0])          # c(T) = (1 + H)^3, Whitney's product rule
c1, c2 = c[1], c[2]
td2 = [Fr(1), Fr(c1, 2), Fr(c1 * c1 + c2, 12)]         # 1 + c1/2 + (c1^2 + c2)/12
print("road 1, the Todd class of P^2")
print(f"H/(1 - e^(-H)) = {pol(q, 'H')}; cubed: td = {pol(td, 'H')}")
print(f"c(T) = (1 + H)^3 = {pol(c, 'H')}; 1 + c1/2 + (c1^2 + c2)/12 = {pol(td2, 'H')}")
assert td == td2 == [1, Fr(3, 2), 1]                   # series against the Chern-class formula

def chi_hrr(d): return mul(expH(d), td)[2]
def h0(d): return sum(1 for a in range(d + 1) for b in range(d + 1 - a))          # powers a, b, d - a - b >= 0
def h2(d): return sum(1 for a in range(d, 0) for b in range(d, 0) if d - a - b <= -1)  # all powers <= -1
ds = list(range(-6, 5))
print("road 1 against road 2 against road 3: line bundles O(d) on P^2")
print(f"{'d':<24}" + "".join(f"{d:>5}" for d in ds))
rows = [("chi, Hirzebruch-RR", chi_hrr), ("h^0, monomials", h0), ("h^2, negative monomials", h2),
        ("(d + 1)(d + 2)/2", lambda d: Fr((d + 1) * (d + 2), 2)),
        ("1 + D.(D - K)/2, K = -3H", lambda d: 1 + Fr(d * (d + 3), 2))]
for name, f in rows: print(f"{name:<24}" + "".join(f"{s(f(d)):>5}" for d in ds))
for d in ds: assert chi_hrr(d) == h0(d) + h2(d) == Fr((d + 1) * (d + 2), 2) == 1 + Fr(d * (d + 3), 2)
ch3 = expH(3)
print(f"d = 3: ch = {pol(ch3, 'H')}; H^2 terms {s(ch3[2])} + {s(ch3[1] * td[1])} + {s(td[2])} = {s(chi_hrr(3))} plane cubics")
sym = all(chi_hrr(d) == chi_hrr(-3 - d) for d in ds)
print(f"Serre symmetry chi(O(d)) = chi(O(-3 - d)) for d = -6 to 4: {'yes' if sym else 'no'}")

print("the tangent bundle T of P^2")
chT = [3 * x for x in expH(1)]; chT[0] -= 1             # ch(T) = 3e^H - 1, from the Euler sequence
c2n = Fr(chT[1] ** 2 - 2 * chT[2], 2)                  # ch2 = (c1^2 - 2 c2)/2, solved for c2
w = (0, 1, 2)                                          # the flow (x : y : z) -> (x : e^t y : e^2t z)
supports = [S for r in (1, 2, 3) for S in combinations(range(3), r)]   # which coordinates are nonzero
zeros = [S for S in supports                           # (x, y, z) parallel to (0x, 1y, 2z): all 2 x 2 minors 0
         if all(not (i in S and j in S) or w[i] == w[j] for i, j in combinations(range(3), 2))]
chiT, euler_seq = mul(chT, td)[2], 3 * (h0(1) + h2(1)) - (h0(0) + h2(0))   # Euler sequence, with the Cech counts
pt = lambda S: "(" + " : ".join(("*" if len(S) > 1 else "1") if i in S else "0" for i in range(3)) + ")"   # * = any nonzero value
print(f"ch(T) = {pol(chT, 'H')}; c2 from ch2 = {s(c2n)}; c2 from (1 + H)^3 = {c2}")
print(f"zeros of the vector field ({w[0]}x, {w[1]}y, {w[2]}z): {len(zeros)}, at " + ", ".join(pt(S) for S in zeros))
print(f"chi(T) by HRR = {s(chiT)}; by the Euler sequence and Cech counts 3 x {h0(1) + h2(1)} - {h0(0) + h2(0)} = {s(euler_seq)}; 3 x 3 matrices mod scalars: {9 - 1}")
assert c2n == c2 == len(zeros) == 3 and chiT == euler_seq == 8

print("the cubic surface S: P^2 blown up at 6 points")
cS = mul([Fr(1), 4, 6], inv([Fr(1), 3, 0]))            # c(T_S) = (1 + h)^4 / (1 + 3h), h^2 = 3 points on S
K2_hyp, e_hyp = cS[1] ** 2 * 3, cS[2] * 3
K2_blow, e_blow = 9 - 6, 3 + 6                         # each blow-up: K^2 down 1, Euler number up 1
chiO = Fr(K2_hyp + e_hyp, 12)                          # Noether's formula
chi_antiK = chiO + Fr(2 * K2_hyp, 2)                   # D = -K: D.(D - K)/2 = (-K).(-2K)/2 = K^2
pts = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1), (1, 2, 3), (1, 3, 2)]

def rank(M):                                           # exact rank by Gaussian elimination
    M, r = [[Fr(x) for x in row] for row in M], 0
    for col in range(len(M[0])):
        piv = next((i for i in range(r, len(M)) if M[i][col] != 0), None)
        if piv is None: continue
        M[r], M[piv] = M[piv], M[r]
        for i in range(r + 1, len(M)):
            f = M[i][col] / M[r][col]; M[i] = [a - f * b for a, b in zip(M[i], M[r])]
        r += 1
    return r

def monos(n): return [(a, b, n - a - b) for a in range(n + 1) for b in range(n + 1 - a)]
def ev(p, m): return p[0] ** m[0] * p[1] ** m[1] * p[2] ** m[2]
lines_ok = all(rank([list(p) for p in t]) == 3 for t in combinations(pts, 3))
conic_rank = rank([[ev(p, m) for m in monos(2)] for p in pts])
cubic_rank = rank([[ev(p, m) for m in monos(3)] for p in pts])
print(f"c(T_S) = {pol(cS, 'h')}, h^2 = 3 points: K^2 = {s(K2_hyp)}, Euler number = {s(e_hyp)}; by blow-ups {K2_blow} and {e_blow}")
print(f"Noether chi(O_S) = (K^2 + e)/12 = ({s(K2_hyp)} + {s(e_hyp)})/12 = {s(chiO)}; Riemann-Roch chi(-K) = 1 + K^2 = {s(chi_antiK)}")
print("points " + ", ".join("(%d : %d : %d)" % p for p in pts) + f": no 3 on a line {'yes' if lines_ok else 'no'}; conic rank {conic_rank} of 6")
print(f"plane cubics through them: 10 - rank {cubic_rank} = {10 - cubic_rank} = sections of -K, so S sits in P^3")
assert K2_hyp == K2_blow == 3 and e_hyp == e_blow == 9 and chiO == 1
assert sym and lines_ok and conic_rank == 6 and chi_antiK == 10 - cubic_rank == 4

print("what breaks")
print(f"mistake 1, no Todd class: chi(O(3)) = H^2 term of ch = {s(ch3[2])}, not a whole number")
print(f"mistake 2, td cut to 1 + c1/2: chi(O(3)) = {s(ch3[2] + ch3[1] * td[1])}, short by chi(O) = {s(chi_hrr(0))}")
aff = [sum(1 for a in range(n + 1) for b in range(n + 1 - a)) for n in (3, 6, 9)]   # x^a y^b, a + b <= n
print(f"mistake 3, the open plane A^2, not compact: polynomials of degree <= 3, 6, 9: {aff[0]}, {aff[1]}, {aff[2]}, no limit")
print(f"mistake 4, chi read as h^0 at d = -4: h^0 = {h0(-4)}, but chi = {s(chi_hrr(-4))}, all in h^2")
print(f"mistake 5, c2 taken as c1^2: Euler number {c1 * c1}, not {c2}")
assert ch3[2] == Fr(9, 2) and h0(-4) == 0 and h2(-4) == 3 and aff == [10, 28, 55]
print("ALL CHECKS PASS")
