# Two-point boundary problems: shooting, finite differences and collocation -- the check behind the card.
# Python standard library only. A cable hangs between towers 30 m and 40 m high, 100 m apart (illustrative):
# y'' = sqrt(1 + y'^2) / a with a = H / w = 4000 N / (20 N/m) = 200 m. Every solver is written out.
import math
def sci(x, d=2):                                  # e-notation spelled the way Rust spells it
    m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def dot(u, v):                                    # plain left-to-right sum (Python's sum() compensates)
    t = 0.0
    for p, q in zip(u, v): t += p * q
    return t
def asinh(v): return math.log(v + math.sqrt(v * v + 1))
L, YA, YB, A = 100.0, 30.0, 40.0, 200.0
CAT = (lambda x, y, p: math.sqrt(1 + p * p) / A, lambda x, y, p: 0.0,      # F, dF/dy, dF/dp
       lambda x, y, p: p / (A * math.sqrt(1 + p * p)))
x0 = L / 2 - A * asinh((YB - YA) / (2 * A * math.sinh(L / (2 * A))))      # road 1: the closed form
c0 = YA - A * math.cosh(x0 / A)
def exact(x): return A * math.cosh((x - x0) / A) + c0
s_ex, mid_ex = math.sinh(-x0 / A), exact(L / 2)
print("cable: y'' = sqrt(1 + y'^2)/a, a = 200 m; towers 30 m at x = 0 and 40 m at x = 100 m")
print(f"exact: lowest point at x = {x0:.6f} m, height {A + c0:.6f} m; midspan y(50) = {mid_ex:.9f} m")
print(f"exact: start slope s = {s_ex:.9f}, angle {math.atan(s_ex) * 180 / math.pi:.4f} deg")

def shoot(eq, a, b, ya, yb, s, n, log=None):     # road 2: RK4 on (y, y', dy/ds, dy'/ds), Newton on s
    F, Fy, Fp = eq; h = (b - a) / n
    def rhs(x, u): return [u[1], F(x, u[0], u[1]), u[3], Fy(x, u[0], u[1]) * u[2] + Fp(x, u[0], u[1]) * u[3]]
    for it in range(20):
        u = [ya, s, 0.0, 1.0]
        for i in range(n):
            x = a + i * h; k1 = rhs(x, u)
            k2 = rhs(x + h / 2, [u[j] + h / 2 * k1[j] for j in range(4)])
            k3 = rhs(x + h / 2, [u[j] + h / 2 * k2[j] for j in range(4)])
            k4 = rhs(x + h, [u[j] + h * k3[j] for j in range(4)])
            u = [u[j] + h / 6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j]) for j in range(4)]
            if 2 * (i + 1) == n: mid = u[0]
        g = u[0] - yb; ds = g / u[2]
        if log is not None:
            log.append(g); print(f"  shot {it}: s = {s:.9f}, miss {sci(g, 4)} m, dmiss/ds = {u[2]:.4f} m")
        s -= ds
        if abs(ds) <= 1e-14 * (1 + abs(s)): break
    return s, mid, g, it + 1, u[2]

def thomas(lo, di, up, r):                        # tridiagonal solve: one sweep down, one back
    di, r = di[:], r[:]
    for i in range(1, len(di)):
        m = lo[i] / di[i - 1]; di[i] -= m * up[i - 1]; r[i] -= m * r[i - 1]
    x = r[:]; x[-1] = r[-1] / di[-1]
    for i in range(len(di) - 2, -1, -1): x[i] = (r[i] - up[i] * x[i + 1]) / di[i]
    return x
def fd(eq, a, b, ya, yb, n, onesided=False, noslope=False, log=False):   # road 3: Newton on the grid
    F, Fy, Fp = eq; h = (b - a) / n; y = [ya + (yb - ya) * i / n for i in range(n + 1)]
    for it in range(1, 60):
        lo, di, up, r = [], [], [], []
        for i in range(1, n):
            x = a + i * h
            p = (y[i + 1] - y[i]) / h if onesided else (y[i + 1] - y[i - 1]) / (2 * h)
            fp = 0.0 if noslope else Fp(x, y[i], p)
            r.append(-(y[i - 1] - 2 * y[i] + y[i + 1] - h * h * F(x, y[i], p)))
            lo.append(1 + h * fp / 2); di.append(-2 - h * h * Fy(x, y[i], p)); up.append(1 - h * fp / 2)
        d = thomas(lo, di, up, r)
        for i in range(1, n): y[i] += d[i - 1]
        if log and it == 1:
            print(f"  step 1: each equation misses by {-r[0]:.6f}; Jacobian row: lower {lo[1]:.6f}, diagonal {di[1]:.1f}, upper {up[1]:.6f}")
            print(f"  after step 1: y = {y[1]:.6f} {y[2]:.6f} {y[3]:.6f}")
        if max(abs(v) for v in d) < 1e-12: break
    return y, it

def colloc(eq, a, b, ya, yb, n):                  # road 4: one polynomial, the equation at Chebyshev points
    F, Fy, Fp = eq; t = [math.cos(math.pi * j / n) for j in range(n + 1)]
    x = [a + (b - a) * (1 - tj) / 2 for tj in t]
    w = [(2.0 if j in (0, n) else 1.0) * (1 - 2 * (j % 2)) for j in range(n + 1)]
    D = [[0.0 if i == j else w[i] / w[j] / (t[i] - t[j]) * (-2 / (b - a)) for j in range(n + 1)] for i in range(n + 1)]
    for i in range(n + 1): D[i][i] = -dot(D[i], [1.0] * (n + 1))    # rows of D must kill constants
    D2 = [[dot(D[i], [D[k][j] for k in range(n + 1)]) for j in range(n + 1)] for i in range(n + 1)]
    y = [ya + (yb - ya) * (xi - a) / (b - a) for xi in x]
    for it in range(1, 60):
        p = [dot(D[i], y) for i in range(n + 1)]
        M = [[1.0 if j == i else 0.0 for j in range(n + 1)] for i in range(n + 1)]
        r = [ya - y[0]] + [0.0] * (n - 1) + [yb - y[n]]
        for i in range(1, n):
            M[i] = [D2[i][j] - Fp(x[i], y[i], p[i]) * D[i][j] - (Fy(x[i], y[i], p[i]) if i == j else 0.0) for j in range(n + 1)]
            r[i] = -(dot(D2[i], y) - F(x[i], y[i], p[i]))
        for k in range(n + 1):                    # dense elimination with partial pivoting
            q = max(range(k, n + 1), key=lambda i: abs(M[i][k])); M[k], M[q] = M[q], M[k]; r[k], r[q] = r[q], r[k]
            for i in range(k + 1, n + 1):
                m = M[i][k] / M[k][k]; r[i] -= m * r[k]
                for j in range(k, n + 1): M[i][j] -= m * M[k][j]
        d = [0.0] * (n + 1)
        for i in range(n, -1, -1): d[i] = (r[i] - dot(M[i][i + 1:], d[i + 1:])) / M[i][i]
        y = [y[i] + d[i] for i in range(n + 1)]
        if max(abs(v) for v in d) < 1e-12: break
    return max(abs(y[i] - exact(x[i])) for i in range(n + 1)), it

print("shooting, RK4 with 16 steps, Newton on the start slope from the chord slope 0.1:")
misses = []; s16, m16, g16, sh16, z16 = shoot(CAT, 0, L, YA, YB, 0.1, 16, misses)
print("  |miss_k+1| / |miss_k|^2: " + ", ".join(sci(abs(misses[k + 1]) / (misses[k] * misses[k])) for k in range(3)) + f"; final s = {s16:.12f}, true error {sci(s16 - s_ex)}")
print("finite differences, 4 intervals of 25 m, Newton from the straight line y = " + " ".join(f"{YA + (YB - YA) * i / 4:.1f}" for i in (1, 2, 3)) + ":")
y4, it4 = fd(CAT, 0, L, YA, YB, 4, log=True)
print(f"  after {it4} steps: y = {y4[1]:.6f} {y4[2]:.6f} {y4[3]:.6f}; exact {exact(25):.6f} {exact(50):.6f} {exact(75):.6f}")
print("midspan error, m:  h (m)    shooting    centred FD  one-sided FD")
E = []
for n in (4, 8, 16, 32, 64):
    e = (shoot(CAT, 0, L, YA, YB, 0.1, n)[1] - mid_ex, fd(CAT, 0, L, YA, YB, n)[0][n // 2] - mid_ex,
         fd(CAT, 0, L, YA, YB, n, onesided=True)[0][n // 2] - mid_ex)
    E.append(e); print(f"  {L / n:20.3f}  {sci(e[0]):>10}  {sci(e[1]):>12}  {sci(e[2]):>12}")
order = [math.log2(abs(E[3][j] / E[4][j])) for j in range(3)]
print(f"observed order, last halving: shooting {order[0]:.2f}, centred {order[1]:.2f}, one-sided {order[2]:.2f}")
y64 = fd(CAT, 0, L, YA, YB, 64)[0]; i = min(range(1, 64), key=lambda j: y64[j])   # lowest grid height, then a parabola
d1, d2 = y64[i + 1] - y64[i - 1], y64[i + 1] - 2 * y64[i] + y64[i - 1]; xl, yl = (i - d1 / (2 * d2)) * L / 64, y64[i] - d1 * d1 / (8 * d2)
print(f"lowest point, 64-interval grid and a parabola through its 3 lowest heights: {yl:.6f} m at x = {xl:.4f} m; true errors {sci(yl - A - c0)} m, {sci(xl - x0)} m")
print("collocation, degree n:  max nodal error, Newton steps")
C = {}
for n in (4, 6, 8, 10, 12):
    C[n] = colloc(CAT, 0, L, YA, YB, n); print(f"  n = {n:2d}: {sci(C[n][0]):>9}  {C[n][1]}")
y16, it16 = fd(CAT, 0, L, YA, YB, 16); y16n, it16n = fd(CAT, 0, L, YA, YB, 16, noslope=True)
print(f"cost at 16 intervals: shooting 1 unknown, {sh16} shots of 64 F-calls; FD 15 unknowns, {it16} steps of a {8 * 15 - 7}-flop Thomas sweep")
print(f"cost of collocation n = 8: 9 unknowns, {C[8][1]} steps of a {(4 * 9 ** 3 + 9 * 9 ** 2 - 7 * 9) // 6}-flop dense elimination")
print(f"wrong: FD Jacobian without the slope term: {it16n} Newton steps, not {it16}; answer moves {sci(y16n[8] - y16[8])} m")
print("stiff bed y'' = k^2 y, y(0) = y(1) = 1, 200 steps: k, dmiss/ds (RK4 | sinh k / k), midspan exact | shooting | FD")
B = {}
for k in (10, 20, 30, 40):
    bed = (lambda x, y, p, k=k: k * k * y, lambda x, y, p, k=k: k * k, lambda x, y, p: 0.0)
    sb, mb, gb, nb, zb = shoot(bed, 0, 1, 1, 1, 0.0, 200); yb = fd(bed, 0, 1, 1, 1, 200)[0][100]
    B[k] = (zb, mb, yb, gb, sb); ex = 1 / math.cosh(k / 2)
    print(f"  {k}: {sci(zb, 3)} | {sci(math.sinh(k) / k, 3)}   {sci(ex, 3)} | {sci(mb, 3)} | {sci(yb, 3)}   miss {sci(gb)}")
ulp = 2.0 ** (math.floor(math.log2(abs(B[40][4]))) - 52)
print(f"k = 40: one ulp of s ({sci(ulp)}) moves midspan {sci(ulp * math.sinh(20) / 40)} and far end {sci(ulp * math.sinh(40) / 40)}")
print(f"k = 40 in 10 pieces (multiple shooting): each piece's dmiss/ds is sinh(4)/40 = {math.sinh(4) / 40:.4f}; d(far height)/d(start height) cosh(4) = {math.cosh(4):.2f}")
print("chart, log10 h: " + " ".join(f"{math.log10(L / n):.2f}" for n in (4, 8, 16, 32, 64)))
for j, name in ((0, "shooting"), (1, "centred FD")):
    print(f"chart, log10 |error| {name}: " + " ".join(f"{math.log10(abs(e[j])):.2f}" for e in E))

assert abs(s16 - s_ex) < 1e-9, "shooting slope must match the closed form"
assert abs(misses[3] / (misses[2] * misses[2])) < 0.01, "Newton on the slope must converge quadratically"
assert 3.9 < order[0] < 4.1 and 1.95 < order[1] < 2.05 and 0.9 < order[2] < 1.1, "orders 4, 2 and 1"
assert C[8][0] < 1e-11 < C[4][0], "collocation: geometric convergence against the closed form"
assert abs(E[4][1]) < 4e-5 and abs(y4[2] - mid_ex) < 0.01 and abs(yl - A - c0) < 1e-4 and abs(xl - x0) < 1e-3, "FD within its h^2 error of the closed form"
assert abs(B[40][0] / (math.sinh(40) / 40) - 1) < 1e-3, "variational equation vs sinh(k)/k"
assert abs(B[40][2] * math.cosh(20) - 1) < 0.05 and abs(B[40][1] * math.cosh(20) - 1) > 1, "FD holds, shooting fails"
assert it16 <= 5 < it16n, "exact grid Jacobian: quadratic Newton; without F_p: slower"
print("ALL CHECKS PASS")
