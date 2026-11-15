# Lax-Milgram on a loaded cable: the check behind the card. Standard library only.
# Sag u (m) of a 1 m cable: tension T (N), spring bed k (N/m^2), load q (N/m), drift b.
# Form a(u,v) = int(T u'v' + b u'v + k u v), load l(v) = int(q v), norm |v|_V = |v'|_L2.
from math import pi, sqrt, sin, cos, cosh, sinh, tanh, exp, log10

T, K, Q = 500.0, 2000.0, 40.0                   # illustrative cable numbers

def thomas(sub, dia, sup, rhs):                 # tridiagonal solve, written out
    n = len(rhs); c = [0.0] * n; d = [0.0] * n
    c[0] = sup / dia; d[0] = rhs[0] / dia
    for i in range(1, n):
        m = dia - sub * c[i - 1]
        c[i] = sup / m; d[i] = (rhs[i] - sub * d[i - 1]) / m
    x = [0.0] * n; x[-1] = d[-1]
    for i in range(n - 2, -1, -1):
        x[i] = d[i] - c[i] * x[i + 1]
    return x

def matrix(N, t, k, b):                         # rows of a(phi_j, phi_i) for hat functions
    h = 1.0 / N
    return (-t / h + k * h / 6 - b / 2, 2 * t / h + 4 * k * h / 6, -t / h + k * h / 6 + b / 2)

def apply(row, x):
    s, d, p = row; n = len(x)
    return [s * (x[i - 1] if i else 0) + d * x[i] + p * (x[i + 1] if i < n - 1 else 0) for i in range(n)]

def vnorm(x, N):                                # |v|_V^2 = x^T Kstiff x, Kstiff = (1/h) tridiag(-1,2,-1)
    return sqrt(sum(a * b for a, b in zip(x, apply((-N, 2.0 * N, -N), x))))

def galerkin(N, t=T, k=K, b=0.0):
    s, d, p = matrix(N, t, k, b)
    return thomas(s, d, p, [Q / N] * (N - 1))

def ratio(N, j, t, k):                     # a(s_j,s_j)/|s_j|_V^2 for the sine mode s_j
    h, c = 1.0 / N, cos(j * pi / N)
    return t + k * h * h * (2 + c) / (6 * (1 - c))

def exact(x, b=0.0):                            # closed form of -T u'' + b u' + K u = Q, u(0)=u(1)=0
    r1 = (b + sqrt(b * b + 4 * T * K)) / (2 * T); r2 = (b - sqrt(b * b + 4 * T * K)) / (2 * T)
    A = (-Q / K) * (1 - exp(r2)) / (exp(r1) - exp(r2)); B = -Q / K - A
    return Q / K + A * exp(r1 * x) + B * exp(r2 * x)

mu = sqrt(K / T)
c, C = T, T + K / pi ** 2                       # coercivity and bound in the V norm
lnorm = Q / sqrt(12)                            # |l| = |Riesz representer g|_V, g = (Q/2) x (1 - x)
mid = (Q / K) * (1 - 1 / cosh(mu / 2))
un_closed = (Q / K) * mu * sqrt(sinh(mu) / (2 * mu) - 0.5) / cosh(mu / 2)
n = 2000; hh = 1.0 / n                          # Simpson on the closed form: |u|_V and a(u,u)
du = lambda x: -(Q / K) * mu * sinh(mu * (x - 0.5)) / cosh(mu / 2)
u = lambda x: (Q / K) * (1 - cosh(mu * (x - 0.5)) / cosh(mu / 2))
simp = lambda f: hh / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(i * hh) for i in range(n + 1))
un_simp = sqrt(simp(lambda x: du(x) ** 2))
a_uu = simp(lambda x: T * du(x) ** 2 + K * u(x) ** 2)
l_u = Q * (Q / K) * (1 - (2 / mu) * tanh(mu / 2))
print(f"form constants: c = {c:.3f} N, C = {C:.3f} N, |l| = {lnorm:.6f}")
print(f"size of sag |u|_V: closed {un_closed:.6f}, Simpson {un_simp:.6f}, Lax-Milgram bound |l|/c {lnorm / c:.6f}")
print(f"middle sag: exact {100 * mid:.6f} cm, guaranteed below {100 * 0.5 * lnorm / c:.6f} cm")
print(f"energy balance: a(u,u) = {a_uu:.9f} J, l(u) = {l_u:.9f} J, least energy {-0.5 * l_u:.9f} J")
r4 = matrix(4, T, K, 0.0); x4 = galerkin(4)
print(f"N = 4 matrix: diagonal {r4[1]:.6f}, beside it {r4[0]:.6f}, load per node {Q / 4:.6f} N")
print(f"N = 4 nodes (cm): {100 * x4[0]:.6f} {100 * x4[1]:.6f} {100 * x4[2]:.6f}")
print("  N   c_N (N)     C_N (N)    middle sag cm  error cm    energy J")
errs = []
for N in (4, 8, 16, 32, 64):
    x = galerkin(N); e = mid - x[N // 2 - 1]; errs.append(abs(e))
    print(f"{N:3d} {ratio(N, N - 1, T, K):10.4f} {ratio(N, 1, T, K):10.4f} {100 * x[N // 2 - 1]:12.6f} {100 * e:10.6f} {-0.5 * sum(x) * Q / N:12.9f}")
res = 0.0                                       # sine modes really are the extremes: residual of A s - ratio K s
for N in (4, 16):
    for j in range(1, N):
        s = [sin(j * pi * i / N) for i in range(1, N)]
        As = apply(matrix(N, T, K, 0.0), s); Ks = apply((-N, 2.0 * N, -N), s)
        res = max(res, max(abs(p - ratio(N, j, T, K) * q) for p, q in zip(As, Ks)))
print(f"every sine mode, N = 4 and 16: |A s_j - ratio_j K s_j| below 1e-9: {res < 1e-9}")
bd = 1000.0                                     # drift: a stops being symmetric
Cb = C + bd / pi
xb = galerkin(64, b=bd); rho = c / Cb ** 2      # Step 5's recipe: x <- x - rho K^-1 (A x - F)
row = matrix(64, T, K, bd); F = [Q / 64] * 63; y = [0.0] * 63; e0 = vnorm(xb, 64)
for it in range(1, 400):
    r = [p - f for p, f in zip(apply(row, y), F)]
    z = thomas(-64.0, 128.0, -64.0, r); y = [p - rho * q for p, q in zip(y, z)]
    if vnorm([p - q for p, q in zip(y, xb)], 64) < 1e-10 * e0: break
xAx = lambda r, v: sum(p * q for p, q in zip(v, apply(r, v)))  # drift's share of x^T A x, solver's own matrices
share = (xAx(row, xb) - xAx(matrix(64, T, K, 0.0), xb)) / xAx(matrix(64, T, K, 0.0), xb)
print(f"drift b = {bd:.0f}: C = {Cb:.3f} N, c still {c:.3f} N, drift's share of x^T A x below 1e-9: {abs(share) < 1e-9}")
print(f"drift middle sag (cm): closed {100 * exact(0.5, bd):.6f}, N = 64 {100 * xb[31]:.6f}, iteration {100 * y[31]:.6f}")
print(f"drift sag at 0.25 m (cm): closed {100 * exact(0.25, bd):.6f}, N = 64 {100 * xb[15]:.6f}")
print(f"iteration: {it} steps to 1e-10, factor per step at most {sqrt(1 - (c / Cb) ** 2):.6f}")
print("what breaks, N = 4 / 16 / 64:")
out = [ratio(N, 1, T, -pi * pi * T) for N in (4, 16, 64)]
mids = [100 * galerkin(N, T, -pi * pi * T)[N // 2 - 1] for N in (4, 16, 64)]
print("  springs push out: c_N " + " ".join(f"{v:.4f}" for v in out) + "; middle cm " + " ".join(f"{v:.3f}" for v in mids))
z0 = [ratio(N, N - 1, 0.0, K) for N in (4, 16, 64)]
zn = [vnorm(galerkin(N, 0.0, K), N) for N in (4, 16, 64)]
print("  no tension: c_N " + " ".join(f"{v:.4f}" for v in z0) + "; |u_N|_V " + " ".join(f"{v:.4f}" for v in zn))
l2 = [T * 6 * (1 - cos((N - 1) * pi / N)) * N * N / (2 + cos((N - 1) * pi / N)) + K for N in (4, 16, 64)]
print("  L2 norm: bound C_N " + " ".join(f"{v:.1f}" for v in l2))
cn = [ratio(N, N - 1, T, K) for N in (4, 16, 64)]
print("chart, log10 N " + " ".join(f"{log10(N):.3f}" for N in (4, 16, 64)) + "; log10 c_N " + " / ".join(" ".join(f"{log10(v):.4f}" for v in L) for L in (cn, out, z0)))
print("chart, x (m)  " + " ".join(f"{i / 8:.3f}" for i in range(9)))
print("chart, exact  " + " ".join(f"{100 * u(i / 8):.3f}" for i in range(9)))
nod = [0.0] + x4 + [0.0]
print("chart, N = 4  " + " ".join(f"{100 * (nod[i // 2] if i % 2 == 0 else (nod[i // 2] + nod[i // 2 + 1]) / 2):.3f}" for i in range(9)))
assert abs(un_simp - un_closed) < 1e-9 and un_closed <= lnorm / c and mid < 0.5 * lnorm / c, "two roads, under the bounds"
assert abs(a_uu - l_u) < 1e-9, "energy balance a(u,u) = l(u)"
assert abs(sqrt(simp(lambda x: (Q / 2 * (1 - 2 * x)) ** 2)) - lnorm) < 1e-9, "|l| = size of the Riesz representer g"
assert errs[-1] < 1e-6 and 3.9 < errs[-2] / errs[-1] < 4.1, "Galerkin middle sag converges at order 2"
assert all(T < ratio(N, N - 1, T, K) < ratio(N, 1, T, K) < C for N in (4, 64)) and C - ratio(64, 1, T, K) < 0.1, "c <= c_N <= C_N <= C, gap closing"
assert res < 1e-9, "sine modes are exact extremes"
assert abs(share) < 1e-9, "drift adds nothing to a(v,v) in the solver's own matrix"
assert abs(xb[31] - exact(0.5, bd)) < 1e-6 and abs(xb[15] - exact(0.25, bd)) < 1e-6, "drift: closed form against solve, middle and 0.25 m"
assert abs(y[31] - xb[31]) < 1e-12 and it < 399, "drift: the iteration reaches the solve before 400 steps"
assert out[2] < 0.01 * out[0] and zn[2] > 3 * zn[0], "both failures: c_N heads to 0"
print("ALL CHECKS PASS")
