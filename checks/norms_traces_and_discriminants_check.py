# Norm, trace and discriminant -- the check behind the card.  Standard library
# only.  Road 1 multiplies an element's matrix exactly (fractions.Fraction);
# road 2 plugs it into every complex embedding (math.cos, sin, sqrt; rounded
# to 5 places); road 3 uses the closed formulas a^2 + 5b^2, 2a and the
# polynomial discriminant.  A brute-force search in Z[sqrt-5] backs the norm test.
from fractions import Fraction as F
from math import cos, sin, sqrt, pi

def companion(p):                    # theta times theta^c, for theta^n = sum p[r] theta^r
    n = len(p)
    return [[F(1) if r == c + 1 else F(0) for c in range(n - 1)] + [F(p[r])] for r in range(n)]

def matmul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]

def mat_of(x, p):                    # road 1: the matrix of "multiply by x" on 1, theta, theta^2
    n, C = len(p), companion(p)
    M, P = [[F(0)] * n for _ in range(n)], [[F(int(i == j)) for j in range(n)] for i in range(n)]
    for c in x:
        M = [[M[i][j] + F(c) * P[i][j] for j in range(n)] for i in range(n)]
        P = matmul(C, P)
    return M

def det(M):                          # Laplace expansion: works for fractions and complex numbers
    if len(M) == 1:
        return M[0][0]
    return sum((-1) ** j * M[0][j] * det([row[:j] + row[j + 1:] for row in M[1:]]) for j in range(len(M)))

def mul(x, y, p):
    M = mat_of(x, p)
    return [sum(M[i][k] * F(y[k]) for k in range(len(p))) for i in range(len(p))]

def norm(x, p):  return det(mat_of(x, p))
def trace(x, p): return sum(mat_of(x, p)[i][i] for i in range(len(p)))
def gram(basis, p): return [[trace(mul(u, v, p), p) for v in basis] for u in basis]
def disc(basis, p): return det(gram(basis, p))
def embed(x, root): return sum(F(c).numerator / F(c).denominator * root ** i for i, c in enumerate(x))

def disc_embed(basis, roots):        # road 2: square of det[sigma_k(w_j)]
    return det([[embed(w, r) for w in basis] for r in roots]) ** 2

def prod(zs):
    out = 1
    for z in zs:
        out = out * z
    return out

def fr(v): return round(v + 0.0, 5) + 0.0
def fc(z): return f"{fr(z.real):.5f} {'-' if fr(z.imag) < 0 else '+'} {abs(fr(z.imag)):.5f}i"
def fl(v): return f"{fr(v):.5f}"
def vec(x): return "[" + ", ".join(str(F(c)) for c in x) + "]"
def yn(c): return "yes" if c else "no"

M5, C2, P5 = [-5, 0], [2, 0, 0], [5, 0]                   # theta^2 = -5, theta^3 = 2, theta^2 = 5
r5 = [complex(0, sqrt(5)), complex(0, -sqrt(5))]
c = 2 ** (1 / 3)
r2 = [complex(c * cos(2 * pi * k / 3), c * sin(2 * pi * k / 3)) for k in range(3)]
alpha = [1, 1]
conj = [embed(alpha, r) for r in r5]
N_mat, T_mat = norm(alpha, M5), trace(alpha, M5)
N_cnj, T_cnj = prod(conj), sum(conj)
N_frm, T_frm = 1 ** 2 + 5 * 1 ** 2, 2 * 1
sq = mul(alpha, alpha, M5)
minpoly_at = [sq[i] - T_mat * alpha[i] + (N_mat if i == 0 else 0) for i in range(2)]
print("field Q(sqrt-5), theta^2 = -5; alpha = 1 + sqrt-5, written [1, 1] on the basis 1, sqrt-5")
print(f"conjugates of alpha: {fc(conj[0])} and {fc(conj[1])}")
print(f"N(alpha): product of conjugates {fc(N_cnj)}; matrix determinant {N_mat}; a^2 + 5b^2 = {N_frm}")
print(f"Tr(alpha): sum of conjugates {fc(T_cnj)}; matrix trace {T_mat}; 2a = {T_frm}")
print("matrix of multiply-by-alpha: [" + ", ".join(vec(row) for row in mat_of(alpha, M5)) + "]")
print(f"alpha squared {vec(sq)}; alpha^2 - {T_mat} alpha + {N_mat} = {vec(minpoly_at)}")
named = [("2", [2, 0]), ("3", [3, 0]), ("1 + sqrt-5", [1, 1]), ("1 - sqrt-5", [1, -1])]
print("norms of " + ", ".join(s for s, _ in named) + ": " + ", ".join(str(norm(x, M5)) for _, x in named))
box = [(a, b) for a in range(-10, 11) for b in range(-10, 11)]          # every element with N <= 100
values = sorted({a * a + 5 * b * b for a, b in box if a * a + 5 * b * b <= 30})
counts = [sum(1 for a, b in box if a * a + 5 * b * b == n) for n in (1, 2, 3, 4, 6, 9)]
print(f"norm values up to 30: {values}")
print(f"elements of norm 1, 2, 3, 4, 6, 9: {', '.join(map(str, counts))}")
small = [(a, b) for a in range(-6, 7) for b in range(-6, 7)]
good = all(((a*c - 5*b*d) ** 2 + 5 * (a*d + b*c) ** 2) == (a*a + 5*b*b) * (c*c + 5*d*d)
           for a, b in small for c, d in small)
print(f"N(xy) = N(x)N(y) on all {len(small) ** 2} pairs with |a|, |b| <= 6: {yn(good)}")

def divides(y, x):                   # y | x in Z[sqrt-5]: x times conj(y) over N(y) is whole
    n, (a, b), (p, q) = y[0] ** 2 + 5 * y[1] ** 2, x, y
    return n != 0 and (a * p + 5 * b * q) % n == 0 and (b * p - a * q) % n == 0

proper = [sum(1 for y in box if 1 < y[0] ** 2 + 5 * y[1] ** 2 < norm(x, M5) and divides(y, x)) for _, x in named]
print("proper divisors found by search: " + "; ".join(f"of {s}: {k}" for (s, _), k in zip(named, proper)))
print(f"2 divides 1 + sqrt-5: {yn(divides((2, 0), (1, 1)))}; 3 divides 1 + sqrt-5: {yn(divides((3, 0), (1, 1)))}")
beta, cof = [1, 1, 0], [1, -1, 1]
conj3 = [embed(beta, r) for r in r2]
print("field Q(cbrt 2), theta^3 = 2; beta = 1 + cbrt2, written [1, 1, 0]")
print("conjugates of beta: " + "; ".join(fc(z) for z in conj3))
print(f"N(beta): product {fc(prod(conj3))}; determinant {norm(beta, C2)}; -f(-1) = {-((-1) ** 3 - 2)}")
print(f"Tr(beta): sum {fc(sum(conj3))}; trace {trace(beta, C2)}")
print(f"(1 + cbrt2)(1 - cbrt2 + cbrt4) = {vec(mul(beta, cof, C2))}")
fields = [("Q(sqrt-5), basis 1, sqrt-5", [[1, 0], [0, 1]], M5, r5, 0 ** 2 - 4 * 5),
          ("Q(cbrt 2), basis 1, cbrt2, cbrt4", [[1, 0, 0], [0, 1, 0], [0, 0, 1]], C2, r2, -4 * 0 ** 3 - 27 * 2 ** 2),
          ("Q(sqrt 5), basis 1, (1 + sqrt5)/2", [[1, 0], [F(1, 2), F(1, 2)]], P5, [sqrt(5), -sqrt(5)], 0 ** 2 + 4 * 5)]
ds = []
for name, basis, p, roots, polyd in fields:
    d, de = disc(basis, p), disc_embed(basis, roots)
    ds.append((d, de, polyd))
    print(f"d_K for {name}: Tr(w_i w_j) = [{', '.join(vec(r) for r in gram(basis, p))}]")
    print(f"    its determinant {d}; embeddings squared {fc(complex(de))}; polynomial formula {polyd}")
primes = [[q for q in range(2, abs(int(d)) + 1) if d % q == 0 and all(q % s for s in range(2, q))] for d, _, _ in ds]
print(f"primes dividing -20: {primes[0]}; -108: {primes[1]}; 5: {primes[2]}")
wrong5 = disc([[1, 0], [0, 1]], P5)
quot = [F(v, 6) for v in mul([1, 1], [1, 1], M5)]                    # (1 + s)/(1 - s) = (1 + s)^2 / 6
half = det([[embed(w, r) for w in [[1, 0], [0, 1]]] for r in r5])
print(f"mistake 1, the Gaussian norm a^2 + b^2 on 1 + sqrt-5: {1 + 1}, not {N_mat}")
print(f"mistake 2, beta times its complex conjugate only: {fl((conj3[1] * conj3[2]).real)}, not a whole number")
print(f"mistake 3, Z[sqrt5] taken for the ring of integers: {wrong5}, not {ds[2][0]}; ratio {wrong5 / ds[2][0]}")
print(f"mistake 4, N(1 - sqrt-5) = 6 divides 6, yet (1 + sqrt-5)/(1 - sqrt-5) = {vec(quot)}, not whole")
print(f"mistake 5, the embedding determinant not squared: {fc(half)}")
on = [sum(1 for a, b in box if a * a + 5 * b * b == n) for n in (2, 3, 4, 6, 9)]
print(f"figure, 50 px per unit, rows at b*sqrt5 = {fl(sqrt(5))}; radii {fl(sqrt(2))}, {fl(sqrt(3))}, 2, "
      f"{fl(sqrt(6))}, 3; lattice points on them {on}")
assert N_mat == N_frm == round(N_cnj.real) == 6 and T_mat == T_frm == round(T_cnj.real) == 2
assert minpoly_at == [0, 0] and norm(beta, C2) == round(prod(conj3).real) == -((-1) ** 3 - 2) == 3
assert mul(beta, cof, C2) == [3, 0, 0] and good and values[:5] == [0, 1, 4, 5, 6]
assert counts == [2, 0, 0, 2, 4, 6] and proper == [0, 0, 0, 0] and not divides((2, 0), (1, 1)) and divides((1, 1), (-4, 2))
assert all(d == round(de.real) for d, de, _ in ds) and [pd for _, _, pd in ds] == [-20, -108, 20] and [d for d, _, _ in ds] == [-20, -108, 5]
assert wrong5 == 4 * ds[2][0] and quot == [F(-2, 3), F(1, 3)] and abs(half.real) < 1e-9
print("ALL CHECKS PASS")
