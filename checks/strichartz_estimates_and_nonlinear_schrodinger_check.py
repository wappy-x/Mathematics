# Strichartz estimates and nonlinear Schrodinger -- the check behind the card.  Standard library only.
# Free flow i u_t + u_xx = 0 from f(x) = exp(-x^2); quintic NLS i u_t + u_xx = -|u|^4 u (focusing).
from math import pi, sqrt, exp, atan, atan2, tan, asinh, cos, sin

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def acc(values):                     # plain left-to-right sum, so the Rust twin adds in the same order
    s = 0.0
    for v in values:
        s += v
    return s

def u_free(t, x):                    # closed form (1+4it)^(-1/2) exp(-x^2/(1+4it)), as (re, im)
    a = 1 + 16 * t * t
    mod = a ** -0.25 * exp(-x * x / a)
    ph = 4 * t * x * x / a - 0.5 * atan2(4 * t, 1)
    return mod * cos(ph), mod * sin(ph)

def absu(t, x):
    re, im = u_free(t, x)
    return sqrt(re * re + im * im)

def peak_spectral(t):                # road 2: integral of f-hat(xi) exp(-4 pi^2 i t xi^2), f-hat = sqrt(pi) exp(-pi^2 xi^2)
    g = lambda c: simpson(lambda s: sqrt(pi) * exp(-pi * pi * s * s) * c(4 * pi * pi * t * s * s), -2.2, 2.2, 8000)
    return sqrt(g(cos) ** 2 + g(sin) ** 2)

print("free flow from exp(-x^2): peak |u(t,0)| against the dispersive bound (4|t|)^(-1/2)")
print("     t   peak closed  peak spectral      bound  peak/bound")
for t in (0.25, 0.5, 1.0, 2.0, 4.0, 8.0):
    pc, ps, b = absu(t, 0.0), peak_spectral(t), (4 * t) ** -0.5
    assert abs(pc - ps) < 1e-9, "closed form vs spectral integral"
    assert pc <= b, "dispersive bound"
    print(f"{t:6.2f} {pc:13.6f} {ps:14.6f} {b:10.6f} {pc / b:11.6f}")
t0, x0, h = 0.7, 0.4, 1e-4           # road 3: the closed form solves the equation (finite differences)
ut = [(u_free(t0 + h, x0)[k] - u_free(t0 - h, x0)[k]) / (2 * h) for k in (0, 1)]
uxx = [(u_free(t0, x0 + h)[k] - 2 * u_free(t0, x0)[k] + u_free(t0, x0 - h)[k]) / (h * h) for k in (0, 1)]
resid = sqrt((uxx[0] - ut[1]) ** 2 + (uxx[1] + ut[0]) ** 2)      # i u_t + u_xx, real and imaginary parts
assert resid < 1e-5, "closed form must solve i u_t + u_xx = 0"
print(f"residual of i u_t + u_xx at t = 0.7, x = 0.4: {resid:.10f}")
masses = [simpson(lambda x: absu(t, x) ** 2, -8 * sqrt(1 + 16 * t * t), 8 * sqrt(1 + 16 * t * t), 2000) for t in (0.0, 1.0, 8.0)]
assert max(abs(m - sqrt(pi / 2)) for m in masses) < 1e-9, "mass is conserved"
print("mass at t = 0, 1, 8:", " ".join(f"{m:.6f}" for m in masses), f"  sqrt(pi/2) = {sqrt(pi / 2):.6f}")

def l6_x(t, shift=0.0):               # integral over x of |u|^6, for one bump or two bumps 'shift' apart
    w = 4 * sqrt(1 + 16 * t * t)
    def g(x):
        a, b = u_free(t, x), u_free(t, x - shift)
        re, im = a[0] + (b[0] if shift else 0), a[1] + (b[1] if shift else 0)
        return (re * re + im * im) ** 3
    return simpson(g, -w, w + shift, 240)
T = 50.0
I6_num = 2 * simpson(l6_x, 0.0, T, 4000)
tail_exact = sqrt(pi / 6) * (pi / 2 - atan(4 * T)) / 2
tail_bound = sqrt(pi / 6) / (8 * T)
I6 = pi ** 1.5 / (4 * sqrt(6))
assert tail_exact <= tail_bound and abs(I6_num + tail_exact - I6) < 1e-8, "space-time integral, two roads"
L6, f2 = I6 ** (1 / 6), (pi / 2) ** 0.25
sharp = 12 ** (-1 / 12)
gamma13 = 3 * simpson(lambda y: exp(-y ** 3), 0.0, 8.0, 4000)                   # Gamma(1/3) = 3 int e^(-y^3)
C_hls = pi ** (-1 / 6) * sqrt(3) * gamma13 ** 3 / (2 ** (4 / 3) * pi ** 1.5)    # Lieb, n = 1, kernel |t|^(-1/3)
gamma56 = 6 * simpson(lambda z: z ** 4 * exp(-z ** 6), 0.0, 4.0, 4000)            # Gamma(5/6) = 6 int z^4 e^(-z^6)
assert abs(C_hls - pi ** (-1 / 6) * gamma13 / gamma56) < 1e-9, "Lieb's constant: duplication form against Gamma(5/6)"
K = (4 * pi) ** (-1 / 3) * C_hls
S_proof = sqrt(K)
assert abs(L6 / f2 - sharp) < 1e-9, "the Gaussian meets the sharp constant 12^(-1/12)"
assert sharp < S_proof, "the proof's constant is larger than the sharp one"
rows = [("int |u|^6 numeric, |t| <= 50", I6_num), ("  tail beyond 50, exact", tail_exact),
        ("  tail bound sqrt(pi/6)/(8T)", tail_bound), ("  numeric + tail", I6_num + tail_exact),
        ("  closed form pi^1.5/(4 sqrt 6)", I6), ("||u||_L6 space-time", L6), ("||f||_2", f2),
        ("ratio ||u||_L6 / ||f||_2", L6 / f2), ("sharp constant 12^(-1/12)", sharp),
        ("Gamma(1/3)", gamma13), ("HLS constant, kernel |t|^(-1/3)", C_hls),
        ("K = (4 pi)^(-1/3) C_HLS", K), ("proof's Strichartz constant sqrt K", S_proof)]
I6_two = 2 * simpson(lambda t: l6_x(t, 3.0), 0.0, T, 4000) + 2 ** 6 * tail_exact   # tail: |u| <= sum of two
f2_two = sqrt(2 * sqrt(pi / 2) * (1 + exp(-4.5)))
assert I6_two ** (1 / 6) / f2_two < sharp, "two bumps fall below the Gaussian's ratio"
rows += [("two bumps 3 apart: ratio (tail bounded)", I6_two ** (1 / 6) / f2_two)]
L4 = lambda T: sqrt(pi) / 4 * asinh(4 * T)                                         # int_{|t|<T} int |u|^4
L4_num = 2 * simpson(lambda t: simpson(lambda x: absu(t, x) ** 4, -5 * sqrt(1 + 16 * t * t), 5 * sqrt(1 + 16 * t * t), 400), 0.0, 10.0, 2000)
assert abs(L4_num - L4(10.0)) < 1e-7, "L4 space-time, two roads"
rows += [("wrong pair (4,4): int |u|^4, |t| < 10 numeric", L4_num)] + [(f"  formula, |t| < {T}", L4(T)) for T in (10, 100, 1000, 1000000)]
p4 = lambda t: absu(t, 0.0) ** 4
L4inf = 2 * (simpson(p4, 0.0, 10.0, 4000) + simpson(p4, 10.0, 1e4, 20000))
assert abs(L4inf - pi / 4) < 2 / (16 * 1e4), "endpoint pair (4, inf): int peak^4 dt = pi/4, tail under 1/(8T)"
rows += [("pair (4,inf): int peak^4 dt, |t| < 10^4", L4inf), ("  pi/4", pi / 4)]
eta = (160 * K) ** -0.25                                                            # contraction radius
A = 2.0
T_loc = tan(4 * eta ** 6 / (A ** 6 * sqrt(pi / 6))) / 4
assert abs(10 * K * (2 * eta) ** 4 - 1) < 1e-12 and eta + K * (2 * eta) ** 5 <= 2 * eta, "eta*: Lipschitz factor 10K R^4 = 1 at R = 2 eta, ball kept"
assert abs(A ** 6 * simpson(l6_x, 0.0, T_loc, 40) - eta ** 6) < 1e-9 * eta ** 6, "T_loc: the bell's L6 size on [0, T_loc], integrated, is eta*"
rows += [("contraction threshold eta*", eta), ("small-data amplitude eta*/||u||_L6", eta / L6), ("A = 2: guaranteed time T_loc", T_loc)]
grad2, int6, int4 = A * A * sqrt(pi / 2), A ** 6 * sqrt(pi / 6), A ** 4 * sqrt(pi / 4)
E, V0 = grad2 / 2 - int6 / 6, A * A * sqrt(pi / 2) / 4
Tstar = sqrt(V0 / (-8 * E))
rows += [("A = 2: int |u_x|^2", grad2), ("A = 2: int |u|^6", int6), ("quintic energy E", E), ("variance V(0)", V0),
         ("blow-up before T* = sqrt(V0/(8|E|))", Tstar), ("E < 0 once A > 27^(1/8)", 27 ** 0.125),
         ("cubic: energy E3", grad2 / 2 - int4 / 4), ("cubic: V''(0) = 8 int|u_x|^2 - 2 int|u|^4", 8 * grad2 - 2 * int4)]
for name, v in rows:
    print(f"{name:<46} {v:14.6f}")

# road 3 for the virial law: solve the focusing quintic by finite differences and RK4
N, L = 601, 6.0
dx = 2 * L / (N - 1)
xs = [-L + i * dx for i in range(N)]
re, im = [A * exp(-x * x) for x in xs], [0.0] * N
def rhs(re, im):                     # u_t = i (u_xx + |u|^4 u)
    wr, wi = [0.0] * N, [0.0] * N
    for i in range(1, N - 1):
        m4 = (re[i] * re[i] + im[i] * im[i]) ** 2
        wr[i] = (re[i + 1] - 2 * re[i] + re[i - 1]) / dx ** 2 + m4 * re[i]
        wi[i] = (im[i + 1] - 2 * im[i] + im[i - 1]) / dx ** 2 + m4 * im[i]
    return [-v for v in wi], wr
def stats(re, im):
    m2 = [re[i] ** 2 + im[i] ** 2 for i in range(N)]
    g = acc((re[i + 1] - re[i]) ** 2 + (im[i + 1] - im[i]) ** 2 for i in range(N - 1)) / dx
    return acc(m2) * dx, g / 2 - acc(v ** 3 for v in m2) * dx / 6, acc(xs[i] ** 2 * m2[i] for i in range(N)) * dx
dt, steps = 1e-4, 100
print("focusing quintic, A = 2, grid dx = 0.02, RK4 dt = 0.0001")
print("     t        mass      energy  V numeric  V0 + 8 E t^2")
for k in range(5):
    M, En, V = stats(re, im)
    tk = k * dt * steps
    print(f"{tk:6.2f} {M:11.6f} {En:11.6f} {V:10.6f} {V0 + 8 * E * tk * tk:13.6f}")
    assert abs(V - (V0 + 8 * E * tk * tk)) < 1e-4 and abs(M - 4 * sqrt(pi / 2)) < 1e-6, "virial law and mass"
    for _ in range(steps):
        k1 = rhs(re, im)
        k2 = rhs([re[i] + dt / 2 * k1[0][i] for i in range(N)], [im[i] + dt / 2 * k1[1][i] for i in range(N)])
        k3 = rhs([re[i] + dt / 2 * k2[0][i] for i in range(N)], [im[i] + dt / 2 * k2[1][i] for i in range(N)])
        k4 = rhs([re[i] + dt * k3[0][i] for i in range(N)], [im[i] + dt * k3[1][i] for i in range(N)])
        re = [re[i] + dt / 6 * (k1[0][i] + 2 * k2[0][i] + 2 * k3[0][i] + k4[0][i]) for i in range(N)]
        im = [im[i] + dt / 6 * (k1[1][i] + 2 * k2[1][i] + 2 * k3[1][i] + k4[1][i]) for i in range(N)]
ts = [0.25 * k for k in range(1, 17)]
print("chart t     ", " ".join(f"{t:g}" for t in ts))
print("chart peak  ", " ".join(f"{absu(t, 0.0):.3f}" for t in ts))
print("chart bound ", " ".join(f"{(4 * t) ** -0.5:.3f}" for t in ts))
print("ALL CHECKS PASS")
