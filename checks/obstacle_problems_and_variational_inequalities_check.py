# The obstacle problem: a rubber sheet on a 20 cm hoop, pressed over a stone ball.
# Unknown u(r): sheet height in cm at distance r cm from the centre. Standard library only.
from math import sqrt, log, pi, sin

R, RHO, H, T = 20.0, 10.0, 2.0, 50.0   # hoop radius cm, stone radius cm, top height cm, tension N/m
C = RHO - H                             # the stone's centre sits 8 cm below the hoop plane

def psi(r):   # obstacle: the stone's upper surface; beyond its equator, its equator height
    return sqrt(RHO * RHO - r * r) - C if r < RHO else -C
def dpsi(r):  # slope of the stone
    return -r / sqrt(RHO * RHO - r * r)
def press(r): # -Laplacian of the stone surface, per cm: the contact pressure divided by T
    s = sqrt(RHO * RHO - r * r)
    return RHO * RHO / (s * s * s) + 1.0 / s

def z(x):     # print a rounding-level residual as 0
    return 0.0 if abs(x) < 5e-7 else x

def simpson(f, x0, x1, n=2000):
    h = (x1 - x0) / n
    s = f(x0) + f(x1)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(x0 + i * h)
    return s * h / 3.0

def bisect(f, lo, hi):
    for _ in range(200):
        m = 0.5 * (lo + hi)
        if (f(lo) < 0.0) == (f(m) < 0.0): lo = m
        else: hi = m
    return 0.5 * (lo + hi)

# Road 1: smooth fit. Outside contact u = A log(r/R); match the stone's height and slope at r = a.
fit = lambda a: a * dpsi(a) * log(a / R) - psi(a)
a = bisect(fit, 1.0, 6.0)
A = a * dpsi(a)
u = lambda r: psi(r) if r <= a else A * log(r / R) + 0.0
du = lambda r: dpsi(r) if r <= a else A / r
print(f"smooth fit: F(1) = {fit(1.0):.4f}, F(6) = {fit(6.0):.4f} cm; root a = {a:.4f} cm")
print(f"contact radius a = {a:.4f} cm ({a:.2f} cm), A = {A:.4f} cm, height at edge {psi(a):.4f} cm, slope at edge {dpsi(a):.4f}")
print(f"by hand: top {H:.0f} cm, a^2 = {a * a:.4f}, s = {sqrt(RHO * RHO - a * a):.4f} cm, log(a/R) = {log(a / R):.4f}, log(10/R) = {log(10 / R):.4f}, A^2 = {A * A:.4f} cm^2")
for r in [0.0, 1.0, 2.0, a, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0]:
    print(f"r = {r:7.4f} cm: sheet {u(r):7.4f} cm, stone {psi(r):7.4f} cm, gap {u(r) - psi(r):7.4f} cm")
gaps = [u(a + (R - a) * k / 1000) - psi(a + (R - a) * k / 1000) for k in range(1, 1001)]
assert min(gaps) > 0.0 and abs(u(a) - psi(a)) < 1e-12

# Energy E = (1/2) integral |grad u|^2 dA = pi * integral u'^2 r dr, in cm^2
e_in = pi * simpson(lambda r: dpsi(r) * dpsi(r) * r, 0.0, a)
e_out = pi * simpson(lambda r: (A / r) * (A / r) * r, a, R)
e_out_exact = pi * A * A * log(R / a)
E = e_in + e_out
print(f"energy: contact {e_in:.4f}, free part {e_out:.4f} (exact {e_out_exact:.4f}), total {E:.4f} cm^2")
print(f"stored energy T E = {T * E * 1e-4 * 1e3:.2f} mJ")
assert abs(e_out - e_out_exact) < 1e-9

# The equation, by centred differences of u'' + u'/r: equals the stone's Laplacian on contact, 0 off it
lap = lambda r, h: (u(r + h) - 2 * u(r) + u(r - h)) / (h * h) + (u(r + h) - u(r - h)) / (2 * h * r)
for h in [0.1, 0.05]:
    print(f"step {h} cm: -Laplacian of sheet at r = 1.5 cm {-lap(1.5, h):.6f} (stone {press(1.5):.6f}), at r = 10 cm {abs(lap(10.0, h)):.6f} per cm")
assert abs(-lap(1.5, 0.05) - press(1.5)) < 1e-4 and abs(lap(10.0, 0.05)) < 1e-4
print(f"contact pressure T x (-Laplacian): top {T * press(0.0) * 100:.1f} Pa, edge {T * press(a) * 100:.1f} Pa")

# Force balance: the stone's push equals the hoop's pull (N)
f_press = T * simpson(lambda r: press(r) * 2 * pi * r, 0.0, a) / 100
f_rim = T * 2 * pi * R * abs(du(R)) / 100
print(f"stone's push: pressure integral {f_press:.4f} N, hoop flux {f_rim:.4f} N ({f_rim:.2f} N)")
assert abs(f_press - f_rim) < 1e-6

# Road 2: the variational inequality, tested on rival sheets v. I = integral grad u . grad (v - u) dA
def split(f):   # integrate piece by piece, across the kinks at r = a and r = 6 cm
    return simpson(f, 0.0, a) + simpson(f, a, 6.0) + simpson(f, 6.0, R)
bump = lambda r: 1 - r * r / (R * R)                                  # lift, zero on the hoop
far = lambda r: sin(pi * (r - 6) / (R - 6)) * sin(pi * (r - 6) / (R - 6)) if r > 6 else 0.0            # wiggle where the sheet is free
dbump = lambda r: -2 * r / (R * R)
dfar = lambda r: pi / (R - 6) * sin(2 * pi * (r - 6) / (R - 6)) if r > 6 else 0.0
tests = [("lift 0.5 cm", 0.5, bump, dbump), ("press 0.5 cm", -0.5, bump, dbump),
         ("wiggle +0.3 cm", 0.3, far, dfar), ("wiggle -0.3 cm", -0.3, far, dfar)]
for name, t, f, df in tests:
    I = 2 * pi * t * split(lambda r: du(r) * df(r) * r)
    I_p = 2 * pi * t * simpson(lambda r: press(r) * f(r) * r, 0.0, a)   # same thing, by parts
    Ev = pi * split(lambda r: (du(r) + t * df(r)) * (du(r) + t * df(r)) * r)
    ok = min(u(r) + t * f(r) - psi(r) for r in [R * k / 2000 for k in range(2001)]) >= -1e-12
    dE = pi * t * t * split(lambda r: df(r) * df(r) * r)
    print(f"{name}: admissible {ok}, I = {z(I):.4f} (by parts {z(I_p):.4f}), E(v) - E(u) = {Ev - E:.4f} = I + E(v - u) = {z(I):.4f} + {dE:.4f} cm^2")
    assert abs(I - I_p) < 1e-6 and abs(Ev - (E + I + dE)) < 1e-9
    assert (I >= -1e-9) == ok

# Wrong edges: sheet on the stone out to b, then A_b log(r/R), matching height only
print("guessed edge b: energy cm^2, deepest cut into the stone mm, slope jump, ring force N/m (negative = pull)")
jumps = []
b0 = sqrt(RHO * RHO - C * C)   # the clipped guess max(stone, 0) leaves the stone here
for b in [1.0, 2.0, 2.5, a, 3.0, 4.0, 5.0, b0]:
    B = psi(b) / log(b / R)
    Eb = pi * simpson(lambda r: dpsi(r) * dpsi(r) * r, 0.0, b) + pi * B * B * log(R / b)
    cut = max(psi(r) - B * log(r / R) for r in [b + (RHO - b) * k / 1000 for k in range(1, 1000)])
    jump = B / b - dpsi(b)
    jumps.append(jump)
    print(f"b = {b:.4f}: energy {Eb:.4f}, cut {z(max(cut, 0.0)) * 10:.4f}, jump {z(jump):.4f}, ring {z(-T * jump):.2f}")
    assert (cut > 1e-9) == (b < a - 1e-9)
    if b >= a: assert Eb >= E - 1e-9
assert jumps[0] < 0 < jumps[-1] and abs(jumps[3]) < 1e-9

# Road 3: projected SOR on a radial grid, minimising the grid energy with u_i >= psi_i
def psor(N):
    h = R / N
    r = [i * h for i in range(N + 1)]
    ob = [psi(x) for x in r]
    v = [max(o, 0.0) for o in ob]
    v[N] = 0.0
    w = 2.0 / (1.0 + sin(pi / N))
    for sweep in range(1, 100001):
        big = 0.0
        for i in range(N):
            lo, hi = (0.0 if i == 0 else r[i] - h / 2), r[i] + h / 2
            gs = v[1] if i == 0 else (lo * v[i - 1] + hi * v[i + 1]) / (lo + hi)
            new = max(ob[i], v[i] + w * (gs - v[i]))
            big = max(big, abs(new - v[i]))
            v[i] = new
        if big < 1e-13: break
    k = max(i for i in range(N) if v[i] - ob[i] < 1e-12)
    eh = 0.0
    for i in range(N): eh += pi * (r[i] + h / 2) * (v[i + 1] - v[i]) * (v[i + 1] - v[i]) / h
    return v[N // 2], r[k], r[k + 1], eh, sweep
errs = []
for N in [50, 100, 200]:
    um, rk, rk1, eh, sw = psor(N)
    errs.append(eh - E)
    print(f"grid N = {N}, step {R / N:.2f} cm: energy {eh:.4f} cm^2 (error {eh - E:.4f}), sheet at {R / 2:.0f} cm {um:.6f} (error {um - u(R / 2):.6f}), last point on the stone {rk:.2f} cm, first free point {rk1:.2f} cm, {sw} sweeps")
    assert abs(rk - a) <= R / N and abs(um - u(R / 2)) < 1e-3
print(f"observed order, energy: {log(errs[0] / errs[1]) / log(2):.2f}, {log(errs[1] / errs[2]) / log(2):.2f}")
assert abs(errs[2]) < abs(errs[1]) < abs(errs[0])

# A hypothesis that fails: a needle. Hold the sheet at 2 cm on a tip of radius d; energy pi H^2 / log(R/d)
for name, d in [("1 mm", 0.1), ("1 micrometre", 1e-4), ("1e-13 cm, a proton", 1e-13)]:
    print(f"needle tip radius {name}: energy {pi * H * H / log(R / d):.4f} cm^2")
print(f"figure, hoop +-{R:.0f} cm, stone centre (0, {-C:.0f}) radius {RHO:.0f} cm, contact edge +-{a:.4f} cm at height {psi(a):.4f} cm, sheet at 10 cm {u(10.0):.4f} cm")
print("ALL CHECKS PASS")
