# The Killing form and roots -- the check behind the card.  Only fractions is
# imported, for exact rational arithmetic.  The algebra is sl(3): traceless 3 by 3
# matrices, the eight gluon directions of the strong force.  The Killing form is
# computed by brute force from 8 by 8 ad matrices and checked against 6 tr(XY)
# and against a sum over roots; roots come from ad(H) and from conjugating by
# a torus element; Cartan's criterion is tested by exact determinants.
from fractions import Fraction as F

def E(i, j): return [[F(int(r == i and c == j)) for c in range(3)] for r in range(3)]
def diag(*d): return [[F(d[r]) if r == c else F(0) for c in range(3)] for r in range(3)]
def mul(a, b): return [[sum(a[r][k] * b[k][c] for k in range(len(b))) for c in range(len(b[0]))] for r in range(len(a))]
def add(a, b, s=1): return [[a[r][c] + s * b[r][c] for c in range(len(a[0]))] for r in range(len(a))]
def br(a, b): return add(mul(a, b), mul(b, a), -1)                  # the bracket [a, b] = ab - ba
def tr(a): return sum(a[i][i] for i in range(len(a)))
def flat(a): return [x for r in a for x in r]
def yn(c): return "yes" if c else "no"

def solve(cols, v):              # coordinates of v in the span of cols, by exact elimination
    n, m = len(cols), len(v)
    rows = [[cols[j][i] for j in range(n)] + [v[i]] for i in range(m)]
    piv, r = [], 0
    for c in range(n):
        p = next((i for i in range(r, m) if rows[i][c] != 0), None)
        if p is None: continue
        rows[r], rows[p] = rows[p], rows[r]
        rows[r] = [x / rows[r][c] for x in rows[r]]
        for i in range(m):
            if i != r and rows[i][c] != 0:
                rows[i] = [x - rows[i][c] * y for x, y in zip(rows[i], rows[r])]
        piv.append(c); r += 1
    assert all(rows[i][n] == 0 for i in range(r, m)), "bracket left the span"
    out = [F(0)] * n
    for i, c in enumerate(piv): out[c] = rows[i][n]
    return out

def ad(x, basis):                # the matrix of ad x = [x, .] in the given basis
    image = [solve([flat(b) for b in basis], flat(br(x, b))) for b in basis]
    return [[image[j][i] for j in range(len(basis))] for i in range(len(basis))]

def killing(x, y, basis): return tr(mul(ad(x, basis), ad(y, basis)))
def gram(basis): return [[killing(a, b, basis) for b in basis] for a in basis]

def reduce(m):                   # row-reduce a copy: (determinant, kernel dimension)
    m, d, r, free = [row[:] for row in m], F(1), 0, 0
    for c in range(len(m[0])):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None: free += 1; d = F(0); continue
        if p != r: m[r], m[p], d = m[p], m[r], -d
        d *= m[r][c]
        for i in range(len(m)):
            if i != r: m[i] = [x - m[i][c] / m[r][c] * y for x, y in zip(m[i], m[r])]
        r += 1
    return d, free

pairs = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)]
name = {p: f"E{p[0]+1}{p[1]+1}" for p in pairs}
H1, H2, S = diag(1, -1, 0), diag(0, 1, -1), diag(1, 1, -2)
sl3 = [E(*p) for p in pairs] + [H1, H2]
G = gram(sl3)
six = all(G[i][j] == 6 * tr(mul(a, b)) for i, a in enumerate(sl3) for j, b in enumerate(sl3))
print("sl(3): dimension", len(sl3), "= 2 diagonal + 6 off-diagonal")
print("B(X,Y) = tr(ad X ad Y) by 8x8 ad matrices equals 6 tr(XY) on all 64 basis pairs:", yn(six))
print("B(H1,H1) =", G[6][6], " B(H2,H2) =", G[7][7], " B(H1,H2) =", G[6][7], " B(E12,E21) =", G[0][2], " B(E12,E12) =", G[0][0])
dG = reduce(G)[0]
print("Cartan's criterion: det of the 8x8 Killing matrix =", dG, "-> semisimple:", yn(dG != 0))
hb = G[6][6] * G[7][7] - G[6][7] ** 2
print("by blocks: three E_ij, E_ji pairs give", G[0][2] * G[2][0] * -1, "each, the H block", hb, ":", F(-36) ** 3, "x", hb, "=", F(-36) ** 3 * hb)
adH = ad(H1, sl3)
print("ad(H) for H = diag(1,-1,0) is diagonal in this basis:", yn(all(adH[i][j] == 0 for i in range(8) for j in range(8) if i != j)))
t, t_inv = diag(2, F(1, 2), 1), diag(F(1, 2), 2, 1)          # the torus element 2^H, determinant 1
for k, p in enumerate(pairs):
    scale = mul(mul(t, E(*p)), t_inv)[p[0]][p[1]]
    print(f"{name[p]}: ad(H) eigenvalue {adH[k][k]}, h{p[0]+1} - h{p[1]+1} = {H1[p[0]][p[0]] - H1[p[1]][p[1]]},"
          f" torus 2^H scales it by {scale} = 2^{adH[k][k]}")
    assert scale == F(2) ** int(adH[k][k]) and adH[k][k] == H1[p[0]][p[0]] - H1[p[1]][p[1]]
print("H1, H2: ad(H) eigenvalues", adH[6][6], adH[7][7], "; so ad(H) has 8 eigenvalues but",
      sum(1 for k in range(8) if adH[k][k] != 0), "roots")
roots_sq = sum(adH[k][k] ** 2 for k in range(6))
print("B(H,H) as a sum of root squares: 4+4+1+1+1+1 =", roots_sq, "; as 6 tr(H^2) = 6 x", tr(mul(H1, H1)), "=", 6 * tr(mul(H1, H1)))
cent = [reduce(ad(h, sl3))[1] for h in (H1, S)]
print("centralizer of regular diag(1,-1,0): dimension", cent[0], "; of singular diag(1,1,-2): dimension", cent[1])
ok = all(br(E(*p), E(p[1], p[0])) == add(E(p[0], p[0]), E(p[1], p[1]), -1)
         and br(add(E(p[0], p[0]), E(p[1], p[1]), -1), E(*p)) == add(E(*p), E(*p)) for p in pairs)
print("each root gives an sl(2): [e,f] = h and [h,e] = 2e for all six:", yn(ok))
ip_aa, ip_ab = 4 / G[6][6], 4 * G[6][7] / (G[6][6] * G[7][7])
print("root lengths by the Killing form: (a,a) =", ip_aa, " (a,b) =", ip_ab, " cos =", ip_ab / ip_aa, "-> 120 degrees")
T3, Y = diag(F(1, 2), F(-1, 2), 0), diag(F(1, 3), F(1, 3), F(-2, 3))
print("gluon colour charges (T3, y):", ", ".join(f"{name[p]} ({T3[p[0]][p[0]]-T3[p[1]][p[1]]}, {Y[p[0]][p[0]]-Y[p[1]][p[1]]})" for p in pairs))
T1 = add(E(0, 1), E(1, 0))
CA = [killing(T1, T1, sl3) / 4, killing(H1, H1, sl3) / 4, killing(S, S, sl3) / 12]   # T1, T3, T8 squared
print("B(T1,T1) =", CA[0], " B(T3,T3) =", CA[1], " B(T8,T8) =", CA[2], "= C_A, the 3 of three colours")
NF = 6                                                                               # quark flavours
print("QCD beta0 = 11 C_A/3 - 2 n_f/3 with n_f =", NF, "flavours:", F(11) * CA[2] / 3 - F(2) * NF / 3)
gl3 = [E(i, j) for i in range(3) for j in range(3)]
b3 = [E(i, j) for i in range(3) for j in range(3) if i <= j]
n3 = [E(i, j) for i in range(3) for j in range(3) if i < j]
print("mistake 1, trace form for the Killing form: tr(H^2) =", tr(mul(H1, H1)), "not", G[6][6])
print("mistake 2, gl(3): det of 9x9 Killing matrix =", reduce(gram(gl3))[0], "; B(I,X) = 0 for all 9 basis X:",
      yn(all(killing(diag(1, 1, 1), x, gl3) == 0 for x in gl3)))
print("mistake 3, upper triangular b: det of 6x6 Killing matrix =", reduce(gram(b3))[0], "; B(b,[b,b]) = 0, solvable:",
      yn(all(killing(x, y, b3) == 0 for x in b3 for y in n3)))
print("mistake 4, splitting by singular diag(1,1,-2): zero part of dimension", cent[1],
      "; it holds [E12,E21] = diag(1,-1,0), not 0:", yn(br(E(0, 1), E(1, 0)) == H1))
assert six and dG == -5038848 == F(-36) ** 3 * hb                                  # brute force against block formula
assert roots_sq == G[6][6] == 6 * tr(mul(H1, H1)) == 12                              # three roads to 12
assert cent == [2, 4] and ok and ip_ab / ip_aa == F(-1, 2) and CA == [3, 3, 3]
assert reduce(gram(gl3))[0] == 0 and reduce(gram(b3))[0] == 0
print("ALL CHECKS PASS")
