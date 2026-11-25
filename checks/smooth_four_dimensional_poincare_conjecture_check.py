# The smooth Poincare conjecture in dimension four -- the check behind the card.  Standard library only.
# Nothing here proves or refutes the conjecture.  It prints the status by dimension and checks the
# card's instances: 28 smooth 7-spheres by two roads, the E8 form that dimension 4 cannot smooth,
# and the dimension count behind the Whitney trick.  Every number on the card is printed here.
from fractions import Fraction as F
from math import comb, factorial

print("Poincare conjecture by dimension, status as of 2026-11-24")
print("  n  topological   smooth        smooth homotopy n-spheres")
for row in [("1", "true", "true", "1"), ("2", "true", "true", "1"), ("3", "true (2003)", "true (2003)", "1"),
            ("4", "true (1982)", "OPEN", "unknown, at least 1"), ("5", "true (1961)", "true (1963)", "1"),
            ("6", "true (1961)", "true (1963)", "1"), ("7", "true (1961)", "false (1956)", "28"),
            ("8", "true (1961)", "false (1963)", "2")]:
    print("  %-2s %-13s %-13s %s" % row)
print("ledger")
for date, event in [("1952", "Rokhlin: smooth spin 4-manifolds, signature divisible by 16"),
                    ("1956", "Milnor: a 7-sphere that is not smoothly standard"),
                    ("1961", "Smale: h-cobordism, smooth dimensions 5 and up"),
                    ("1962", "Stallings: R^n has one smooth structure for n >= 5"),
                    ("1962", "Gluck: the twist of S^4 along a 2-sphere"), ("1963", "Kervaire-Milnor: 28 smooth 7-spheres"),
                    ("1966", "Newman (1967 Connell): topological manifolds, n >= 5"),
                    ("1976", "Cappell-Shaneson: candidate homotopy 4-spheres"),
                    ("1982", "Freedman: dimension 4, topological"), ("1983", "Donaldson: smooth definite forms are diagonal"),
                    ("1987", "Taubes: uncountably many smooth R^4"), ("1987", "Donaldson: smooth h-cobordism fails in dim 4"),
                    ("2003", "Perelman: dimension 3"), ("2010", "Akbulut: Cappell-Shaneson spheres are standard"),
                    ("2010", "Freedman-Gompf-Morrison-Walker: computer test, no verdict"),
                    ("2022-09-17", "Akbulut: outline of a proof of smooth dimension 4, revised to 2024-07-30; claimed, not accepted"),
                    ("2026-11-24", "smooth dimension 4: open")]:
    print(f"  {date:<11}{event}")

# 1. Bernoulli numbers from the recurrence sum_{j<=m} C(m+1, j) B_j = 0.
B = [F(1)]
for m in range(1, 11):
    B.append(-sum(comb(m + 1, j) * B[j] for j in range(m)) / (m + 1))
print("Bernoulli B2, B4, B6, B8, B10:", ", ".join(str(B[i]) for i in range(2, 11, 2)))

# 2. Road 1 to 28: Kervaire-Milnor's order of bP(4k), the spheres that bound parallelizable manifolds.
def bP(k):
    return 2**(2*k - 2) * (2**(2*k - 1) - 1) * (4 * abs(B[2*k]) / k).numerator
quoted = {7: 28, 11: 992, 15: 16256}            # orders of Theta_n in Kervaire-Milnor's 1963 table
for k in range(1, 5):
    n = 4*k - 1
    note = f"table: {quoted[n]}" if n in quoted else "but the 3-sphere has 1 smooth structure" if k == 1 else "beyond the quoted table"
    print(f"  k={k}  n={n:<3} bP = {2**(2*k-2)} x {2**(2*k-1)-1} x {(4*abs(B[2*k])/k).numerator} = {bP(k):<6} {note}")
assert bP(2) == quoted[7] and bP(3) == quoted[11], "the formula must match the quoted table"
assert quoted[15] % bP(4) == 0, "bP(16) is a subgroup of Theta_15"

# 3. Road 2 to 28: the L and A-hat genera of a closed 8-manifold, from power series in z = x^2.
N = 3
def mul(a, b): return [sum(a[i] * b[j - i] for i in range(j + 1)) for j in range(N)]
def inv(a):
    out = [1 / a[0]]
    for j in range(1, N): out.append(-sum(a[i] * out[j - i] for i in range(1, j + 1)) / a[0])
    return out
def log1(a):                      # log of a series that starts with 1
    u, out, pw = [F(0)] + a[1:], [F(0)] * N, [F(1)] + [F(0)] * (N - 1)
    for m in range(1, N):
        pw = mul(pw, u); out = [o + (-1)**(m + 1) * p / m for o, p in zip(out, pw)]
    return out
cosh = [F(1, factorial(2*i)) for i in range(N)]                # cosh x
sinhx = [F(1, factorial(2*i + 1)) for i in range(N)]           # sinh(x) / x
sinh_half = [F(1, 4**i * factorial(2*i + 1)) for i in range(N)]  # sinh(x/2) / (x/2)
genus = {}
for name, Q in [("L", mul(cosh, inv(sinhx))), ("A-hat", inv(sinh_half))]:
    c = log1(Q)                   # p1 = s1, p2 = (s1^2 - s2)/2 in power sums s_m of z
    genus[name] = (c[1], -2 * c[2], c[2] + c[1]**2 / 2)
    print(f"{name:<6} genus: dim 4 = ({c[1]}) p1;  dim 8 = ({genus[name][1]}) p2 + ({genus[name][2]}) p1^2")
for k in (1, 2):                  # second road to the top coefficients: Hirzebruch's Bernoulli forms
    Lk = F(2**(2*k) * (2**(2*k - 1) - 1)) * abs(B[2*k]) / factorial(2*k)
    Ak = -abs(B[2*k]) / (2 * factorial(2*k))
    assert (Lk, Ak) == (genus["L"][k - 1], genus["A-hat"][k - 1]), "series against Bernoulli"
step = 1 / abs(genus["A-hat"][1])  # p1 = 0 and A-hat a whole number force p2 into steps of this
sig = genus["L"][1] * step
print(f"8-manifold with p1 = 0: p2 in steps of {step}, signature in steps of {sig}; {sig} / 8 = {sig / 8}")
assert sig / 8 == bP(2), "two roads to 28 must agree"

# 4. The E8 form: simple roots in coordinates, their dot products, determinant two ways, signature.
h = F(1, 2)
roots = [[h, -h, -h, -h, -h, -h, -h, h], [F(1), F(1)] + [F(0)] * 6]
roots += [[F(0)] * i + [F(-1), F(1)] + [F(0)] * (6 - i) for i in range(6)]
G = [[sum(x * y for x, y in zip(a, b)) for b in roots] for a in roots]
A, piv = [row[:] for row in G], []
for i in range(8):
    piv.append(A[i][i])
    for r in range(i + 1, 8):
        f = A[r][i] / A[i][i]; A[r] = [x - f * y for x, y in zip(A[r], A[i])]
det = 1
for p in piv: det *= p
def bareiss(M):                   # second road: a determinant in whole numbers only
    M, prev = [[int(x) for x in row] for row in M], 1
    for i in range(7):
        for r in range(i + 1, 8):
            for c in range(i + 1, 8): M[r][c] = (M[r][c] * M[i][i] - M[r][i] * M[i][c]) // prev
        prev = M[i][i]
    return M[7][7]
sigma = sum(p > 0 for p in piv) - sum(p < 0 for p in piv)
print("E8 diagonal", [int(G[i][i]) for i in range(8)], " pivots", ", ".join(str(p) for p in piv))
print(f"E8 determinant {det} (whole-number road {bareiss(G)}), signature {sigma}, even {all(G[i][i] % 2 == 0 for i in range(8))}")
assert det == bareiss(G) == 1 and sigma == 8, "E8 must have determinant 1 and signature 8"
e8, diag = {}, {}                 # every vector of square <= 2 lies in these boxes
for m in range(3**8):
    v = [(m // 3**i) % 3 - 1 for i in range(8)]; s = sum(x*x for x in v)
    diag[s] = diag.get(s, 0) + 1
    if sum(v) % 2 == 0: e8[s] = e8.get(s, 0) + 1
e8[2] += sum(1 for m in range(2**8) if bin(m).count("1") % 2 == 0)   # all entries +-1/2
print(f"square 1: E8 {e8.get(1, 0)}, diagonal form {diag[1]};  square 2: E8 {e8[2]} = {4 * comb(8, 2)} + {2**7}")
assert e8.get(1, 0) == 0 and diag[1] == 2 * 8, "a diagonal form has 16 square-1 vectors, E8 none"
assert e8[2] == 4 * comb(8, 2) + 2**7, "E8 has 112 + 128 = 240 vectors of square 2"
print(f"Rokhlin test: smooth needs signature divisible by 16; E8 gives {sigma} mod 16 = {sigma % 16}")
print("Milnor's 7-spheres: k copies of the E8 plumbing, signature 8k, standard when 224 divides 8k:",
      [k for k in range(1, 60) if (8 * k) % 224 == 0])

# 5. Whitney trick: a 2-disc in general position in a level of dimension d crosses itself in dimension 2+2-d.
print("Whitney disc self-crossing dimension 2+2-d:", ", ".join(f"d={d}: {4 - d}" for d in range(4, 8)))
print("ALL CHECKS PASS")
