# Crank-Nicolson and the theta family -- the check behind the card.  Standard
# library only.  A steel bar 1 m long at 100 C, both ends plunged into ice
# water (0 C) at t = 0; heat obeys u_t = alpha u_xx.  Grid: h = 0.02 m, 49 inner
# nodes.  Road 1: theta steps solved by a written-out Thomas sweep.  Road 2: the
# grid's own sine modes, each multiplied by its factor g per step (no solves).
# Road 3: the true bar, as a Fourier series.  All agree as the analysis says.
from math import sin, exp, pi, log10
ALPHA, N, T = 1e-5, 50, 3600.0          # m^2/s (illustrative), cells, one hour in s
h, n = 1 / N, N - 1
x = [(j + 1) * h for j in range(n)]
def sci(v): m, e = f"{v:.3e}".split("e"); return f"{m}e{int(e)}"
def thomas(a, b, c, d):                 # constant bands a, b, c; right side d
    cp, dp = [c / b], [d[0] / b]
    for i in range(1, len(d)):
        p = b - a * cp[-1]; cp.append(c / p); dp.append((d[i] - a * dp[-1]) / p)
    y = [dp[-1]]
    for i in range(len(d) - 2, -1, -1): y.insert(0, dp[i] - cp[i] * y[0])
    return y, cp, dp
def step(u, dt, th):                    # one theta step; ends held at 0 C
    r = ALPHA * dt / h ** 2
    w = [0.0] + u + [0.0]
    rhs = [u[j] + (1 - th) * r * (w[j] - 2 * w[j + 1] + w[j + 2]) for j in range(n)]
    return rhs if th == 0 else thomas(-th * r, 1 + 2 * th * r, -th * r, rhs)[0]
def run(dt, th, damp=False, u=None):    # damp: first step as two backward-Euler half-steps
    u, k = ([100.0] * n if u is None else u), 0
    out = [u]
    if damp: u = step(step(u, dt / 2, 1.0), dt / 2, 1.0); out.append(u); k = 1
    for _ in range(round(T / dt) - k): u = step(u, dt, th); out.append(u)
    return out
def s2(k): return sin(k * pi * h / 2) ** 2
def lam(k): return 4 * ALPHA / h ** 2 * s2(k)          # decay rate of grid mode k, per s
def g(k, r, th): return (1 - (1 - th) * 4 * r * s2(k)) / (1 + th * 4 * r * s2(k))
b = [2 / N * sum(100.0 * sin(k * pi * xj) for xj in x) for k in range(1, N)]
def modes(f): return [sum(b[k - 1] * f(k) * sin(k * pi * xj) for k in range(1, N)) for xj in x]
def maxerr(u, v): return max(abs(p - q) for p, q in zip(u, v))
def centre(m):                          # the grid's exact-in-time centre with m cells: each sine mode decayed exactly
    return sum(2 / m * sum(100.0 * sin(k * pi * j / m) for j in range(1, m)) * sin(k * pi / 2)
               * exp(-4 * ALPHA * m * m * sin(k * pi / m / 2) ** 2 * T) for k in range(1, m))
dt = 200.0; r = ALPHA * dt / h ** 2
print(f"explicit limit h^2/(2 alpha) = {h * h / 2 / ALPHA:.1f} s; chosen step {dt:.0f} s; r = {r:.6f}")
grid = modes(lambda k: exp(-lam(k) * T))
true = 400 / pi * sum(sin(k * pi / 2) / k * exp(-ALPHA * (k * pi) ** 2 * T) for k in range(1, 2001, 2))
print(f"centre at 1 h: true bar {true:.6f}, grid exact in time {grid[24]:.6f}, space error {sci(grid[24] - true)}")
sp = [centre(m) - true for m in (50, 100, 200)]
print(f"space error at the centre, h = 0.02, 0.01, 0.005 m: {', '.join(sci(v) for v in sp)}; ratios {sp[0] / sp[1]:.2f}, {sp[1] / sp[2]:.2f}")
assert abs(sp[0] - (grid[24] - true)) < 1e-9 and all(3.9 < sp[i] / sp[i + 1] < 4.1 for i in range(2))   # series: grids close in at order 2
# one Crank-Nicolson step by hand, from 100 C everywhere
rhs = [100 + r / 2 * (w0 - 200 + w2) for w0, w2 in zip([0.0] + [100.0] * (n - 1), [100.0] * (n - 1) + [0.0])]
u1, cp, dp = thomas(-r / 2, 1 + r, -r / 2, rhs)
print(f"CN row: {-r / 2:.6f}, {1 + r:.6f}, {-r / 2:.6f}; right side node 1 {rhs[0]:.6f}, node 2 {rhs[1]:.6f}")
print(f"sweep: c'1 {cp[0]:.6f}, d'1 {dp[0]:.6f}; node 2 {u1[1]:.6f}; node 1 = d'1 - c'1 x node 2 = {u1[0]:.6f}")
print(f"settled pivot 3 + sqrt(2.75) = {3 + 2.75 ** 0.5:.6f}; sweep pivot 24 {(-r / 2) / cp[23]:.6f}")
# road 2: measured factors against the formula, mode 1 and mode 49
for k in (1, 49):
    um = [sin(k * pi * xj) for xj in x]
    meas = [step(um, dt, th)[0] / um[0] for th in (0.0, 0.5, 1.0)]
    form = [g(k, r, th) for th in (0.0, 0.5, 1.0)]
    print(f"mode {k}: 4r sin^2 {4 * r * s2(k):.6f}; g explicit {meas[0]:.6f}, CN {meas[1]:.6f}, "
          f"backward {meas[2]:.6f}; exact e^(-lambda dt) {(f'{exp(-lam(k) * dt):.6f}' if k == 1 else sci(exp(-lam(k) * dt)))}")
    assert maxerr(meas, form) < 1e-12
z = -lam(1) * dt
print(f"mode 1: CN g - e^z = {sci(g(1, r, 0.5) - exp(z))}, Taylor z^3/12 = {sci(z ** 3 / 12)}")
assert abs((g(1, r, 0.5) - exp(z)) / (z ** 3 / 12) - 1) < 0.03          # second order: error z^3/12, next term 1 + z
print("CN g as r grows, sharpest mode: " + ", ".join(f"r={rr} {g(49, rr, 0.5):.6f}" for rr in (1, 5, 50, 5000)))
print("backward g as r grows: " + ", ".join(f"r={rr} {g(49, rr, 1.0):.6f}" for rr in (1, 5, 50, 5000)))
# road 1 against road 2: stepped Thomas runs equal the mode formula
cn, cnd, be = run(dt, 0.5), run(dt, 0.5, True), run(dt, 1.0)
assert maxerr(cn[-1], modes(lambda k: g(k, r, 0.5) ** 18)) < 1e-9
assert maxerr(cnd[-1], modes(lambda k: g(k, r / 2, 1.0) ** 2 * g(k, r, 0.5) ** 17)) < 1e-9
ex = [modes(lambda k: exp(-lam(k) * dt * i)) for i in range(7)]
print("figure, t s: " + ", ".join(f"{dt * i:.0f}" for i in range(7)))
for name, v in (("CN", cn), ("CN damped", cnd), ("exact", ex)):
    print(f"figure, node 1, {name}: " + ", ".join(f"{v[i][0]:.1f}" for i in range(7)))
assert cn[1][0] < 0 < min(min(v) for v in cnd)          # CN dips below ice; damped run does not
print(f"start-up, two backward half-steps: mode 49 x {g(49, r / 2, 1.0) ** 2:.6f}, mode 1 x {g(1, r / 2, 1.0) ** 2:.6f}")
print(f"centre at 1 h, dt 200: CN {cn[-1][24]:.6f}, CN damped {cnd[-1][24]:.6f}, backward {be[-1][24]:.6f}; "
      f"damped minus true bar {sci(cnd[-1][24] - true)} = space {sci(grid[24] - true)} + time {sci(cnd[-1][24] - grid[24])}")
# order: max error against the grid's exact-in-time answer, as dt halves
dts = [400.0, 200.0, 100.0, 50.0, 25.0]
tab = {nm: [maxerr(run(d, th, dm)[-1], grid) for d in dts] for nm, th, dm in
       (("CN", 0.5, False), ("CN damped", 0.5, True), ("backward", 1.0, False), ("theta 0.6", 0.6, False))}
for nm, e in tab.items():
    print(f"max error, dt 400..25, {nm}: " + ", ".join(sci(v) for v in e)
          + "; ratios " + ", ".join(f"{e[i] / e[i + 1]:.2f}" for i in range(4)))
    print(f"figure, log10 error, {nm}: " + ", ".join(f"{log10(v):.2f}" for v in e))
print("figure, log10 dt: " + ", ".join(f"{log10(d):.2f}" for d in dts))
assert all(3.9 < tab["CN damped"][i] / tab["CN damped"][i + 1] < 4.1 for i in range(1, 4))
assert all(1.9 < tab["backward"][i] / tab["backward"][i + 1] < 2.1 for i in range(1, 4))
exp20 = run(20.0, 0.0)[-1]
print(f"explicit at 20 s (r = 0.5): centre {exp20[24]:.6f}, max error {sci(maxerr(exp20, grid))}")
# what breaks: steps too long for theta below one half
for th in (0.0, 0.4):
    big = max(abs(v) for v in run(dt, th)[-1])
    print(f"theta {th:.2f} at r = 5: limit r <= {1 / (2 - 4 * th):.2f}; sharpest g {g(49, r, th):.6f}; largest |u| at 1 h {sci(big)}")
    assert big > 100 and abs(g(49, r, th)) > 1       # hotter than the start: impossible
fl = 8 * n - 7
print(f"flops: Thomas {fl}, right side {5 * n}; CN 18 steps {18 * (fl + 5 * n)}, damped {2 * fl + 17 * (fl + 5 * n)}, "
      f"explicit 180 steps {180 * 5 * n}")
print("ALL CHECKS PASS")
