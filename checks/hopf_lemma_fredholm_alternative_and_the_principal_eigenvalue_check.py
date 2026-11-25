# L u = -u'' + 2u' on (0, 1), u(0) = u(1) = 0 (scaled): the principal eigenvalue, Hopf's slopes, Fredholm.
# Roads: closed forms; shooting by RK4 with bisection; a finite-difference grid with inverse iteration;
# Simpson integrals; centred-difference residuals.  Standard library only.
import math
PI, E = math.pi, math.e
phi = lambda x: math.exp(x) * math.sin(PI * x)     # L's first mode
phs = lambda x: math.exp(-x) * math.sin(PI * x)    # the adjoint's first mode

def shoot(lam, A, f=0.0, kicks=None, n=4000):  # -u''+2u'-lam u = f + point sources; u(0)=0, u'(0)=A
    kicks = kicks or {}; h = 1.0 / n; u, p, lo, hi = 0.0, A, math.inf, -math.inf
    rhs = lambda u, p: (p, 2 * p - lam * u - f)
    for i in range(n):
        if i in kicks: p -= kicks[i]   # a source of size a makes the slope drop by a
        k1 = rhs(u, p); k2 = rhs(u + h / 2 * k1[0], p + h / 2 * k1[1])
        k3 = rhs(u + h / 2 * k2[0], p + h / 2 * k2[1]); k4 = rhs(u + h * k3[0], p + h * k3[1])
        u += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); p += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        if i < n - 1: lo, hi = min(lo, u), max(hi, u)   # inside points only
    return u, p, lo, hi

def bisect(g, a, b, it=60):
    for _ in range(it):
        m = (a + b) / 2; a, b = (a, m) if g(a) * g(m) <= 0 else (m, b)
    return (a + b) / 2

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def thomas(lo, di, up, r):
    n = len(di); d, r = di[:], r[:]
    for i in range(1, n):
        m = lo[i] / d[i - 1]; d[i] -= m * up[i - 1]; r[i] -= m * r[i - 1]
    x = [0.0] * n; x[-1] = r[-1] / d[-1]
    for i in range(n - 2, -1, -1): x[i] = (r[i] - up[i] * x[i + 1]) / d[i]
    return x

def grid(N, lam):  # centred differences for -u''+2u'-lam u on the N-1 inside points
    h = 1.0 / N
    return [-1 / h**2 - 1 / h] * (N - 1), [2 / h**2 - lam] * (N - 1), [-1 / h**2 + 1 / h] * (N - 1)

def grid_eig(N):  # inverse iteration: the eigenvalue of smallest size and its vector
    lo, di, up = grid(N, 0.0); v = [1.0] * (N - 1)
    for _ in range(80):
        w = thomas(lo, di, up, v); s = max(abs(t) for t in w); v = [t / s for t in w]
    Av = [di[i] * v[i] + (lo[i] * v[i - 1] if i else 0) + (up[i] * v[i + 1] if i < N - 2 else 0) for i in range(N - 1)]
    return sum(a * b for a, b in zip(v, Av)) / sum(a * a for a in v), v

lam = [k * k * PI * PI + 1 for k in (1, 2, 3)]
sh = [bisect(lambda l: shoot(l, 1.0)[0], a, b) for a, b in ((5, 15), (35, 45), (85, 95))]
print("eigenvalues k^2 pi^2 + 1:  " + "  ".join(f"{t:.6f}" for t in lam))
print("by shooting (RK4, bisect): " + "  ".join(f"{t:.6f}" for t in sh))
for a, b in zip(lam, sh): assert abs(a - b) < 1e-6        # closed form against shooting
fd = {N: grid_eig(N) for N in (50, 100, 200)}
l50, l100, l200 = (fd[N][0] for N in (50, 100, 200))
print(f"grid lambda_1, N = 50/100/200: {l50:.6f} {l100:.6f} {l200:.6f}; order {math.log2((l50 - l100) / (l100 - l200)):.3f}; Richardson {(4 * l200 - l100) / 3:.6f}")
assert abs((4 * l200 - l100) / 3 - lam[0]) < 1e-6 and all(t > 0 for t in fd[200][1])   # grid agrees; its mode is positive
print(f"grid mode at N = 200: smallest entry {min(fd[200][1]):.6f} > 0, sign changes 0")
print(f"drift-free -u'': pi^2 = {PI * PI:.6f}; drift adds b^2/4 = {lam[0] - PI * PI:.6f}")
print(f"population: T = 100 days, threshold {lam[0] / 100:.5f} per day, without drift {PI * PI / 100:.5f} per day; the current adds {(lam[0] - PI * PI) / 100:.4f}")
xp, xs = 1 - math.atan(PI) / PI, math.atan(PI) / PI
xpb = bisect(lambda x: math.sin(PI * x) + PI * math.cos(PI * x), 0.3, 0.9)
print(f"peaks: mode at x = {xp:.4f} (bisection {xpb:.4f}), height {phi(xp):.4f}; adjoint at x = {xs:.4f}, height {phs(xs):.4f}")
assert abs(xp - xpb) < 1e-9
print(f"release at {xs:.4f} km instead of 0.25 km: value {phs(xs):.4f} against {phs(0.25):.4f}, ratio {phs(xs) / phs(0.25):.4f}")
hres = lambda g, l, s, h: max(abs(-(g(x + h) - 2 * g(x) + g(x - h)) / h**2 + s * (g(x + h) - g(x - h)) / h - l * g(x)) for x in [0.1 * i for i in range(1, 10)])
r1, r2 = hres(phi, lam[0], 1, 1e-2), hres(phi, lam[0], 1, 5e-3); r3 = hres(phs, lam[0], -1, 5e-3)
print(f"residual of L phi - lambda_1 phi: h = 0.01 {r1:.6f}, h = 0.005 {r2:.6f}, ratio {r1 / r2:.2f}; of L* phi* - lambda_1 phi*: {r3:.6f}")
assert r1 / r2 > 3.9 and r3 < 1e-3
_, pR, _, _ = shoot(lam[0], PI)
print(f"Hopf slopes: phi'(0) = pi = {PI:.4f}; phi'(1) = -e pi = {-E * PI:.4f}, shooting {pR:.4f}")
print(f"share of losses out the downstream end e/(1 + e) = {E / (1 + E):.4f}")
I1 = simpson(phi, 0, 1)
print(f"births = losses: lambda_1 * int phi = {lam[0] * I1:.6f}, phi'(0) - phi'(1) = pi (1 + e) = {PI * (1 + E):.6f}")
assert abs(pR + E * PI) < 1e-6 and abs(lam[0] * I1 - PI * (1 + E)) < 1e-9
J = simpson(phs, 0, 1); Jc = PI * (1 + 1 / E) / (PI * PI + 1)
print(f"Fredholm test for f = 1: int f phi* = {J:.6f} (closed form {Jc:.6f}), not 0: no steady state")
ends = [shoot(lam[0], A, f=1.0)[0] for A in (0.0, 5.0)]
print(f"shooting f = 1 at lambda_1: u(1) = {ends[0]:.6f} with u'(0) = 0, {ends[1]:.6f} with u'(0) = 5; formula -(e/pi) int phi* = {-E / PI * Jc:.6f}")
assert abs(J - Jc) < 1e-12 and all(abs(t + E / PI * Jc) < 1e-8 for t in ends)
big = []
for N in (50, 100, 200):
    lo, di, up = grid(N, lam[0]); big.append(max(abs(t) for t in thomas(lo, di, up, [1.0] * (N - 1))))
print("grid 'solution' of f = 1 at lambda_1, largest |u|, N = 50/100/200: " + " ".join(f"{t:.1f}" for t in big))
assert big[2] / big[1] > 3.5 and big[1] / big[0] > 3.5    # grows like 1/h^2: no limit
m = phs(0.25) / phs(0.75)   # the amount to remove at x = 0.75
print(f"release 1 at x = 0.25, remove m at x = 0.75: phi*(0.25) = {phs(0.25):.4f}, phi*(0.75) = {phs(0.75):.4f}, m = {m:.4f} = e^0.5 {math.exp(0.5):.4f}")
kb, ku = {1000: 1.0, 3000: -m}, {1000: 1.0, 3000: -1.0}   # a source +1 and a sink at x = 0.75
ub = [shoot(lam[0], A, kicks=kb)[0] for A in (0.0, 1.0)]; uu = shoot(lam[0], 0.0, kicks=ku)[0]
print(f"shooting, balanced: |u(1)| = {abs(ub[0]):.12f} and {abs(ub[1]):.12f} for u'(0) = 0, 1; unbalanced m = 1: u(1) = {uu:.6f}, formula {-E / PI * (phs(0.25) - phs(0.75)):.6f}")
assert abs(m - math.exp(0.5)) < 1e-12 and max(abs(t) for t in ub) < 1e-9 and abs(uu + E / PI * (phs(0.25) - phs(0.75))) < 1e-9
print(f"wrong test with L's own mode: phi(0.25) - m phi(0.75) = {phi(0.25) - m * phi(0.75):.4f}")
for l in (10.0, 10.8, 12.0):   # f = 1 below and above lambda_1: Fredholm says one solution each; only one is positive
    u0, u1 = shoot(l, 0.0, f=1.0)[0], shoot(l, 1.0, f=1.0)[0]; A = -u0 / (u1 - u0); _, _, mn, mx = shoot(l, A, f=1.0)
    w = math.sqrt(l - 1); B = (math.exp(-1) / l - math.cos(w) / l) / math.sin(w)
    uc = lambda x: -1 / l + math.exp(x) * (math.cos(w * x) / l + B * math.sin(w * x))
    cmn, cmx = min(uc(i / 4000) for i in range(1, 4000)), max(uc(i / 4000) for i in range(1, 4000))
    sign, ext, cext = ("positive", mx, cmx) if mn > 0 else ("negative", mn, cmn) if mx < 0 else ("mixed", mn, cmn)  # the other extreme is the grid point next to an end
    print(f"f = 1, r = {l:.1f}: slope u'(0) {A:.4f}; {sign} at every inside point, extreme {ext:.4f}; closed form {cext:.4f}")
    assert abs(mn - cmn) < 1e-6 and abs(mx - cmx) < 1e-6 and (mn > 0) == (l < lam[0]) and (mx < 0) == (l > lam[0])
q = lambda x: x * x; h = 1e-3
print(f"degenerate -x^2 u'' + 2u on u = x^2: residual at 0.5 {abs(-0.25 * (q(0.5 + h) - 2 * q(0.5) + q(0.5 - h)) / h**2 + 2 * q(0.5)):.6f}, slope at 0 {(q(h) - q(0)) / h:.4f} -> 0")
ray = simpson(lambda x: (PI * math.cos(PI * x))**2, 0, 1) / simpson(lambda x: math.sin(PI * x)**2, 0, 1)
print(f"energy ratio of sin(pi x), the drift dropped: {ray:.6f}, below lambda_1 = {lam[0]:.6f}")
assert abs(ray - PI * PI) < 1e-9
print(f"try: drift b = 4: lambda_1 = pi^2 + 4 = {PI * PI + 4:.6f}, best release point atan(pi/2)/pi = {math.atan(PI / 2) / PI:.4f}")
print("chart, x       " + " ".join(f"{i / 10:5.1f}" for i in range(11)))
for name, g in (("sin(pi x)", lambda x: math.sin(PI * x)), ("phi      ", phi), ("phi*     ", phs)):
    print(f"chart, {name}" + " ".join(f"{g(i / 10):5.2f}" for i in range(11)))
print("ALL CHECKS PASS")
