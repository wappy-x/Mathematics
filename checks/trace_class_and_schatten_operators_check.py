# Trace class -- the check behind the card.  Standard library only.
# V is the running total (Vf)(x) = integral of f from 0 to x on L2(0, 1); K f(x) = x * (integral of f).
# Roads: closed forms (singular values, cantilever roots, eigenvalues of K + V^2) against
# truncations (an N-point midpoint grid, a basis cut to M terms); Jacobi rotations for
# eigenvalues, power iteration, Gaussian elimination for a determinant.
import math

def jacobi(A):                            # eigenvalues of a symmetric matrix, largest first
    n, A = len(A), [r[:] for r in A]
    while sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j) > 1e-28:
        for p in range(n - 1):
            for q in range(p + 1, n):
                if A[p][q] == 0.0:
                    continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1 if th >= 0 else -1) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for k in range(n):
                    A[k][p], A[k][q] = c * A[k][p] - s * A[k][q], s * A[k][p] + c * A[k][q]
                for k in range(n):
                    A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return sorted((A[i][i] for i in range(n)), reverse=True)

def mul(A, B):                            # matrix product
    return [[sum(a * b for a, b in zip(r, c)) for c in zip(*B)] for r in A]
gram = lambda A: mul([list(c) for c in zip(*A)], A)   # A^T A: eigenvalues are squared singular values

def vgrid(N):                             # V on N midpoints: weight h below the diagonal, h/2 on it
    return [[1 / N if j < i else (0.5 / N if i == j else 0.0) for j in range(N)] for i in range(N)]

def vapply(f, h):                         # the same V_N, applied by a running sum
    out, run = [], 0.0
    for v in f:
        out.append(h * (run + v / 2)); run += v
    return out

sig = lambda n: 2 / ((2 * n - 1) * math.pi)
print("V: singular values 2/((2n-1)pi): " + ", ".join(f"{sig(n):.6f}" for n in (1, 2, 3)))
pts = [2 ** j for j in range(10)]
print("chart N 1..512, sum of sigma_n to N:   " + ", ".join(f"{sum(sig(n) for n in range(1, N + 1)):.3f}" for N in pts))
print("chart N 1..512, sum of sigma_n^2 to N: " + ", ".join(f"{sum(sig(n) ** 2 for n in range(1, N + 1)):.3f}" for N in pts))
grid = {}
for N in (20, 40, 80):
    V = vgrid(N)
    s = [math.sqrt(max(e, 0.0)) for e in jacobi(gram(V))]
    V2 = mul(V, V)
    s2 = [math.sqrt(max(e, 0.0)) for e in jacobi(gram(V2))]
    frob = sum(a * a for r in V for a in r)
    grid[N] = (s, s2, frob)
    print(f"grid N {N}: V top singular values {s[0]:.6f} {s[1]:.6f} {s[2]:.6f}; sum s^2 {sum(x * x for x in s):.6f},"
          f" kernel squared {frob:.6f}; trace norm sum s {sum(s):.4f}; V^2 trace norm {sum(s2):.6f}")
grow = [sum(grid[N][0]) for N in (20, 40, 80)]
print(f"V trace norm growth per doubling of N: {grow[1] - grow[0]:.4f}, {grow[2] - grow[1]:.4f}; ln2/pi = {math.log(2) / math.pi:.4f};"
      f" V_N's diagonal sum, N eigenvalues h/2: {sum(vgrid(80)[i][i] for i in range(80)):.6f}")

# V^2: singular values 1/beta^2, beta the cantilever roots of cos(b)cosh(b) = -1.
def beta(n):
    lo, hi = (n - 0.5) * math.pi - 1, (n - 0.5) * math.pi + 0.5
    for _ in range(200):
        mid = (lo + hi) / 2
        if (math.cos(mid) + 1 / math.cosh(mid) > 0) == (n % 2 == 1): lo = mid
        else: hi = mid
    return (lo + hi) / 2
b = [beta(n) for n in range(1, 31)]
asy = [((n - 0.5) * math.pi) for n in range(1, 31)]     # past n = 30, beta_n = (n - 1/2) pi to 1e-40
tn2 = 0.5 + sum(1 / x ** 2 - 1 / y ** 2 for x, y in zip(b, asy))
hs2 = 1 / 6 + sum(1 / x ** 4 - 1 / y ** 4 for x, y in zip(b, asy))
rich = 2 * sum(grid[80][1]) - sum(grid[40][1])
print(f"V^2: beta {b[0]:.6f} {b[1]:.6f} {b[2]:.6f}; singular values {1 / b[0] ** 2:.6f} {1 / b[1] ** 2:.6f} {1 / b[2] ** 2:.6f}")
print(f"V^2: HS^2 from roots {hs2:.6f}, kernel (x-y)^2 over the triangle 1/12 = {1 / 12:.6f}")
print(f"V^2: trace norm from roots {tn2:.6f}; grid 40 and 80 extrapolated {rich:.6f}; ||V||_HS^2 = 0.5 bounds it")
print(f"norm ladder V^2: operator {1 / b[0] ** 2:.4f} <= HS {math.sqrt(hs2):.4f} <= trace {tn2:.4f}")

# Traces.  T = K + V^2 has kernel x + (x - y) for y < x, and x above the diagonal.
Q = 4000; h = 1 / Q; xs = [(i + 0.5) * h for i in range(Q)]
Kx = [x * sum(v * h for v in xs) for x in xs]
print(f"trace from kernel diagonal: K {sum(x * h for x in xs):.6f}, V^2 0; K applied to x: {Kx[Q // 2] / xs[Q // 2]:.6f}"
      f" times x; ||K||_1 = 1/sqrt(3) = {1 / math.sqrt(3):.6f}")
sine = lambda n: (4 + 1 if n % 2 else -3) / (n * math.pi) ** 2          # <e_n, T e_n>, e_n = sqrt2 sin
for n in (1, 2, 3, 4):
    e = [math.sqrt(2) * math.sin(n * math.pi * x) for x in xs]
    Te = [k + w for k, w in zip([x * sum(v * h for v in e) for x in xs], vapply(vapply(e, h), h))]
    q = sum(a * c * h for a, c in zip(e, Te))
    print(f"sine basis n {n}: <e_n, T e_n> formula {sine(n):+.6f}, quadrature {q:+.6f}")
    assert abs(q - sine(n)) < 1e-5                                      # closed forms checked
for M in (10, 100, 1000):
    cs = 0.5 + 1 / 6 - sum(1 / (n * math.pi) ** 2 for n in range(1, M + 1))
    vs = sum(4 / (n * math.pi) ** 2 for n in range(1, M + 1, 2))
    print(f"basis cut M {M}: trace of T in sines {sum(sine(n) for n in range(1, M + 1)):.6f}, in cosines {cs:.6f};"
          f" V's diagonal in sines {vs:.6f}")

# Lidskii for T: eigenvalues 1/(L + 2 pi i k)^2 with cosh L = 2.
L = math.log(2 + math.sqrt(3))
lam = lambda k: 1 / complex(L, 2 * math.pi * k) ** 2
print(f"L = ln(2 + sqrt3) = {L:.6f}; eigenvalues: k = 0 {lam(0).real:.6f}; " + "; ".join(
      f"k = +-{k} {lam(k).real:.6f} +- {abs(lam(k).imag):.6f}i" for k in (1, 2)))
for Kc in (1, 10, 100, 1000):
    print(f"Lidskii: sum of eigenvalues |k| <= {Kc}: {sum(lam(k) for k in range(-Kc, Kc + 1)).real:.6f}")
N = 2000; hh = 1 / N; g = [(i + 0.5) * hh for i in range(N)]
f = [1.0] * N
for _ in range(60):
    w = [x * sum(v * hh for v in f) + a for x, a in zip(g, vapply(vapply(f, hh), hh))]
    top = math.sqrt(sum(a * a for a in w)); f = [a / top for a in w]
w = [x * sum(v * hh for v in f) + a for x, a in zip(g, vapply(vapply(f, hh), hh))]
lam0 = sum(a * c for a, c in zip(f, w))
print(f"power iteration on N {N}: top eigenvalue {lam0:.6f}, closed form 1/L^2 = {1 / L ** 2:.6f}")
for N in (50, 100, 200):
    V = vgrid(N); A = mul(V, V)
    M = [[(1.0 if i == j else 0.0) - ((i + 0.5) / N / N + A[i][j]) for j in range(N)] for i in range(N)]
    det = 1.0
    for c in range(N):                     # Gaussian elimination, no pivoting needed here
        det *= M[c][c]
        for r in range(c + 1, N):
            m = M[r][c] / M[c][c]
            M[r] = [a - m * p for a, p in zip(M[r], M[c])]
    print(f"Fredholm determinant det(I - T) on grid N {N}: {det:.6f}; limit 2 - cosh(1) = {2 - math.cosh(1):.6f}")

# Finite rehearsal: A = [[1, -2], [1, 3]], eigenvalues by Durand-Kerner on det(zI - A), built from A's entries.
A = [[1.0, -2.0], [1.0, 3.0]]; tr, dt = A[0][0] + A[1][1], A[0][0] * A[1][1] - A[0][1] * A[1][0]
z = [complex(0.4, 0.9), complex(0.4, 0.9) ** 2]
for _ in range(100): z = [zi - ((zi - A[0][0]) * (zi - A[1][1]) - A[0][1] * A[1][0]) / (zi - z[1 - i]) for i, zi in enumerate(z)]
print(f"2 x 2: eigenvalues {z[0].real:.6f}{z[0].imag:+.6f}i, {z[1].real:.6f}{z[1].imag:+.6f}i; sum {sum(z).real:.6f}, trace {tr:.0f}")

# Density matrix rho = 2 V*V: weights 8/((2n-1)^2 pi^2), sum 1, purity 2/3.
p = [2 * sig(n) ** 2 for n in range(1, 4)]
pg = [2 * x * x for x in grid[80][0]]
print(f"density 2V*V: weights {p[0]:.6f} {p[1]:.6f} {p[2]:.6f}; grid 80 {pg[0]:.6f} {pg[1]:.6f} {pg[2]:.6f};"
      f" grid trace {sum(pg):.6f}, purity {sum(x * x for x in pg):.6f}")

assert abs(grid[80][0][0] - sig(1)) < 1e-4 and abs(grid[80][0][1] - sig(2)) < 1e-3   # grid finds 2/pi, 2/(3pi)
assert all(abs(sum(x * x for x in grid[N][0]) - (0.5 - 1 / (4 * N))) < 1e-9 for N in grid)  # HS = kernel
assert abs(grow[2] - grow[1] - math.log(2) / math.pi) < 2e-3                         # trace norm diverges
assert abs(hs2 - 1 / 12) < 1e-12 and abs(rich - tn2) < 2e-4 and tn2 < 0.5            # V^2 trace class
assert abs(Kx[Q // 2] / xs[Q // 2] - 0.5) < 1e-9
assert abs(sum(sine(n) for n in range(1, 10 ** 5)) - 0.5) < 1e-5                    # basis-free trace
assert abs(sum(lam(k) for k in range(-10 ** 5, 10 ** 5 + 1)) - 0.5) < 1e-5          # Lidskii
assert abs(lam0 - 1 / L ** 2) < 1e-3 and abs(det - (2 - math.cosh(1))) < 2e-3
assert max(abs(zi - complex(tr / 2, s * math.sqrt(dt - tr * tr / 4))) for zi, s in zip(z, (1, -1))) < 1e-12  # quadratic formula
assert abs(sum(z) - tr) < 1e-12 and abs(sum(pg) - 1) < 0.01 and abs(sum(x * x for x in pg) - 2 / 3) < 1e-3
print("ALL CHECKS PASS")
