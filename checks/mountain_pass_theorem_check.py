# Mountain pass check: -u'' = u^3 on (0, pi), u(0) = u(pi) = 0, energy J(u) = 1/2 int u'^2 - 1/4 int u^4.
# Standard library only.  Three roads to the pass level c: shooting by RK4, the AGM closed form, a grid minimax.
import math
PI = math.pi

def simpson(f, h):  # composite Simpson on an even number of intervals, plain loops
    n = len(f) - 1; s = f[0] + f[n]
    for i in range(1, n, 2): s += 4.0 * f[i]
    for i in range(2, n, 2): s += 2.0 * f[i]
    return s * h / 3.0

def shoot(s, n=2000):  # RK4 for u' = p, p' = -u^3 from u = 0, p = s; returns grid values of u and p
    h = PI / n; u, p = 0.0, s; us, ps = [u], [p]
    for _ in range(n):
        k1u, k1p = p, -u * u * u
        a = u + 0.5 * h * k1u; k2u, k2p = p + 0.5 * h * k1p, -a * a * a
        a = u + 0.5 * h * k2u; k3u, k3p = p + 0.5 * h * k2p, -a * a * a
        a = u + h * k3u; k4u, k4p = p + h * k3p, -a * a * a
        u += h * (k1u + 2.0 * k2u + 2.0 * k3u + k4u) / 6.0
        p += h * (k1p + 2.0 * k2p + 2.0 * k3p + k4p) / 6.0
        us.append(u); ps.append(p)
    return us, ps

def tri_solve(r, h):  # (-w[i-1] + 2 w[i] - w[i+1]) / h^2 = r[i], w = 0 beyond both ends (Thomas)
    n = len(r); c = [0.0] * n; d = [0.0] * n; c[0] = -0.5; d[0] = r[0] * h * h / 2.0
    for i in range(1, n):
        m = 2.0 + c[i - 1]; c[i] = -1.0 / m; d[i] = (r[i] * h * h + d[i - 1]) / m
    w = [0.0] * n; w[n - 1] = d[n - 1]
    for i in range(n - 2, -1, -1): w[i] = d[i] - c[i] * w[i + 1]
    return w

def ground(n, iters=120):  # grid minimax: minimise A^2/(4B) over shapes by v <- L^-1(v^3), rescaled
    h = PI / (n + 1); v = [math.sin((i + 1) * h) for i in range(n)]; m = 1.0
    for _ in range(iters):
        w = tri_solve([x * x * x for x in v], h); m = max(w); v = [x / m for x in w]
    va = [0.0] + v + [0.0]; A = 0.0; B = 0.0
    for i in range(n + 1): A += (va[i + 1] - va[i]) ** 2 / h
    for x in v: B += h * x ** 4
    return A * A / (4.0 * B), 1.0 / math.sqrt(m), v, h

# ---- the ray t sin x: J = pi t^2/4 - 3 pi t^4/32 ----
ray = lambda t: PI * t * t / 4.0 - 3.0 * PI * t ** 4 / 32.0
ts = 2.0 / math.sqrt(3.0); n = 2000; hx = PI / n; xs = [i * hx for i in range(n + 1)]
jq = simpson([0.5 * (ts * math.cos(x)) ** 2 - 0.25 * (ts * math.sin(x)) ** 4 for x in xs], hx)
print(f"ray t sin x: peak at t = {ts:.6f}, J = {ray(ts):.6f} (pi/6 = {PI / 6:.6f}), by Simpson {jq:.6f}")
print(f"ray t sin x: J back to 0 at t = {math.sqrt(8.0 / 3.0):.6f}; J(2 sin x) = {ray(2.0):.6f}; J(3 sin x) = {ray(3.0):.6f}")
assert abs(jq - PI / 6) < 1e-9 and abs(ray(ts) - jq) < 1e-9; assert ray(2.0) < 0

# ---- the ring of mountains: J >= r^2/2 - (pi/16) r^4 >= 1/pi on |u'| = r = 2/sqrt(pi) ----
rho = 2.0 / math.sqrt(PI); alpha = 1.0 / PI
print(f"ring: radius |u'| = {rho:.6f}, guaranteed height 1/pi = {alpha:.6f}")

# ---- road 1: shooting.  bisect on the starting slope s until u(pi) = 0 ----
lo, hi = 0.5, 1.5
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if shoot(mid)[0][-1] > 0.0 else (lo, mid)
s = 0.5 * (lo + hi); us, ps = shoot(s)
amp = max(us); A1 = simpson([p * p for p in ps], hx); B1 = simpson([u ** 4 for u in us], hx)
J1 = 0.5 * A1 - 0.25 * B1
print(f"road 1 shooting: slope u'(0) = {s:.9f}, height u(pi/2) = {amp:.9f}, J = {J1:.9f}")
print(f"  int u'^2 = {A1:.9f}, int u^4 = {B1:.9f} (equal for a solution)")

# ---- road 2: closed form through the arithmetic-geometric mean M = AGM(1, sqrt 2) ----
a, g = 1.0, math.sqrt(2.0)
for _ in range(8): a, g = 0.5 * (a + g), math.sqrt(a * g)
M = a; c2 = PI / (3.0 * M ** 4)
print(f"road 2 AGM: M = {M:.9f}, slope sqrt2/M^2 = {math.sqrt(2.0) / M ** 2:.9f}, height sqrt2/M = {math.sqrt(2.0) / M:.9f}, c = pi/(3M^4) = {c2:.9f}")
assert abs(J1 - c2) < 1e-9 and abs(amp - math.sqrt(2.0) / M) < 1e-7 and abs(s - math.sqrt(2.0) / M ** 2) < 1e-9
assert abs(A1 - B1) < 1e-8 and alpha < c2 < PI / 6
print(f"by hand: pi/4 = {PI / 4:.6f}, 3pi/32 = {3 * PI / 32:.6f}, |2 cos x| = {2 * math.sqrt(PI / 2):.6f}, agm step 1: {(1 + math.sqrt(2.0)) / 2:.6f}, {math.sqrt(math.sqrt(2.0)):.6f}, 3g^4 = {3 * M ** 4:.6f}")
print(f"by hand: c is {100 * (1 - c2 / (PI / 6)):.2f}% below pi/6 and {100 * (c2 / alpha - 1):.1f}% above 1/pi; f(4, 1) = {16 + (1 - 4) ** 3:.0f}; 2* = 2d/(d-2) = {2 * 3 / (3 - 2):.0f} at d = 3, {2 * 4 / (4 - 2):.0f} at d = 4")

# ---- road 3: grid minimax of A^2/(4B), at three steps ----
errs = []
for nn in (50, 100, 200):
    ch, ah, _, h = ground(nn); errs.append(ch - c2)
    print(f"road 3 grid: h = {h:.6f}, c_h = {ch:.9f}, height {ah:.6f}, error {ch - c2:.3e}")
order = math.log(errs[0] / errs[1]) / math.log(2.0); order2 = math.log(errs[1] / errs[2]) / math.log(2.0)
print(f"  observed order {order:.3f}, then {order2:.3f}")
assert abs(errs[2]) < 3e-5 and 1.9 < order2 < 2.1

# ---- the shape on the sphere |u'| = rho: J = rho^2/2 - rho^4 B/(4A^2) for three test shapes ----
for name, A, B in (("sin x", PI / 2, 3 * PI / 8), ("sin 2x", 2 * PI, 3 * PI / 8), ("u*", A1, B1)):
    j = rho ** 2 / 2 - rho ** 4 * B / (4 * A * A)
    print(f"on the ring: {name:6s} J = {j:.6f}"); assert j >= alpha
print(f"lower bound r^2/2 - (pi/16) r^4 at r = rho: {rho ** 2 / 2 - PI / 16 * rho ** 4:.6f}")

# ---- the solution is a saddle: down along its own ray, up across it ----
for t in (0.9, 1.1): print(f"J({t} u*) = {A1 * (t * t / 2 - t ** 4 / 4):.6f}  (below c)")
for e in (0.1, -0.1):
    jj = simpson([0.5 * (ps[i] + 3 * e * math.cos(3 * xs[i])) ** 2 - 0.25 * (us[i] + e * math.sin(3 * xs[i])) ** 4 for i in range(n + 1)], hx)
    print(f"J(u* {e:+.1f} sin 3x) = {jj:.6f}  (above c)"); assert jj > J1
assert A1 * (0.81 / 2 - 0.6561 / 4) < J1 and A1 * (1.21 / 2 - 1.4641 / 4) < J1

# ---- the chart: J against the stretch r = |u'| along both rays, and the lower bound ----
rs = [0.2 * k for k in range(11)]
print("chart sin x:", ", ".join(f"{r * r / 2 - r ** 4 * 3 / (8 * PI):.3f}" for r in rs))
print("chart u*   :", ", ".join(f"{r * r / 2 - r ** 4 / (4 * A1):.3f}" for r in rs))
print("chart bound:", ", ".join(f"{r * r / 2 - PI / 16 * r ** 4:.3f}" for r in rs))

# ---- what breaks ----
print(f"drop the growth, -u'' = u/2: J(2 sin x) = {PI * 4 / 8:.6f} > 0, no far valley")
jl = PI * 0.01 / 4 - PI * 0.01 / 2 - 3 * PI * 1e-4 / 32
print(f"drop the ring, -u'' = 2u + u^3: J(0.1 sin x) = {jl:.6e} < 0 next to u = 0"); assert jl < 0
for sm in (0.1, 0.01, 0.001):  # f = x^2 + (1-x)^3 y^2: only critical point is the origin
    x = 1 + sm; y = math.sqrt(2 * x / (3 * sm * sm)); f = x * x + (1 - x) ** 3 * y * y
    gr = math.hypot(2 * x - 3 * (1 - x) ** 2 * y * y, 2 * (1 - x) ** 3 * y)
    print(f"drop Palais-Smale: s = {sm}, point ({x:.3f}, {y:.3f}), f = {f:.6f}, |grad f| = {gr:.3e}")
assert gr < 1e-4 and abs(f - 1) < 1e-2 and y > 800

# ---- how it moves: u_t = u_xx + u^3 from fac times the grid solution (N = 50, dt = 0.001), up to t = 2 ----
_, ah, v, h = ground(50); dt = 0.001
def flow(fac, steps=2000):
    u = [fac * ah * x for x in v]; line = []; k = 0
    while k < steps and max(u) <= 10.0:
        if k % 250 == 0: line.append(f"{max(u):.4f}")
        ua = [0.0] + u + [0.0]
        u = [u[i] + dt * ((ua[i] - 2 * ua[i + 1] + ua[i + 2]) / (h * h) + u[i] ** 3) for i in range(len(u))]
        k += 1
    return line, k * dt, max(u)
for fac in (0.9, 1.1):
    line, te, pk = flow(fac)
    print(f"heat flow from {fac} u*, peak every 0.25: {', '.join(line)}; ends t = {te:.3f}, peak {pk:.4f}")
    assert (pk < 0.3) if fac < 1 else (te < 2.0)

# ---- try changing ----
for fac in (0.99, 1.01):
    _, te, pk = flow(fac, 4000); print(f"try: heat flow from {fac} u* ends t = {te:.3f}, peak {pk:.4f}")
w = [math.sin(x) - 0.05 * math.sin(3 * x) for x in xs]; wp = [math.cos(x) - 0.15 * math.cos(3 * x) for x in xs]
A3 = simpson([q * q for q in wp], hx); B3 = simpson([q ** 4 for q in w], hx)
print(f"try: ray of sin x - 0.05 sin 3x peaks at {A3 * A3 / (4 * B3):.6f}"); assert A3 * A3 / (4 * B3) >= J1
print(f"try: solutions with 1 and 2 interior zeros have J = 16c = {16 * c2:.6f} and 81c = {81 * c2:.6f}")
lo, hi = 0.5, 1.5
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if shoot(mid, 20)[0][-1] > 0.0 else (lo, mid)
u20, p20 = shoot(0.5 * (lo + hi), 20)
print(f"try: shooting with 20 RK4 steps: J = {simpson([0.5 * p * p - 0.25 * u ** 4 for u, p in zip(u20, p20)], PI / 20):.9f}")
print("ALL CHECKS PASS")
