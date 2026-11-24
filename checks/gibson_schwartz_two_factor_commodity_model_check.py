# Gibson-Schwartz: Brent 85, a convenience yield 6% pulled to 3% at speed 1.5 -- the card's check.
# Standard library only.  Every road and every number on the card is computed and printed here.
from math import log, exp, sqrt, cos, sin, pi
S0, Y0, KAPPA, ALPHA, SS, SY, RHO, R = 85.0, 0.06, 1.5, 0.03, 0.30, 0.25, 0.8, 0.05
P = dict(S=S0, y=Y0, k=KAPPA, al=ALPHA, ss=SS, sy=SY, rho=RHO)
def B(T, k): return (1 - exp(-k * T)) / k        # years of today's yield gap still felt by T
def terms(T, S, y, k, al, ss, sy, rho):           # road 1: the closed form, piece by piece
    b = B(T, k); i1 = (T - b) / k                 # i1: integral of B(u) du from 0 to T
    i2 = (T - 2 * b + (1 - exp(-2 * k * T)) / (2 * k)) / k**2   # integral of B(u)^2 du
    return [(R - al) * T, -(y - al) * b, -rho * ss * sy * i1, 0.5 * sy * sy * i2], b, i1, i2
def fut(T, **kw): p = {**P, **kw}; return p["S"] * exp(sum(terms(T, **p)[0]))
def fut_ode(T, n=2000, **kw):
    # road 2: moments of log spot X and yield y, stepped by Runge-Kutta; F = exp(mean X + var X / 2)
    p = {**P, **kw}; k, al, ss, sy, rho = p["k"], p["al"], p["ss"], p["sy"], p["rho"]
    def f(s):                                      # s = mean X, mean y, var X, cov(X, y), var y
        mx, my, vx, c, vy = s
        return [R - my - ss * ss / 2, k * (al - my), ss * ss - 2 * c, rho * ss * sy - k * c - vy, sy * sy - 2 * k * vy]
    s, h = [log(p["S"]), p["y"], 0.0, 0.0, 0.0], T / n
    for _ in range(n):
        k1 = f(s); k2 = f([a + h / 2 * b for a, b in zip(s, k1)])
        k3 = f([a + h / 2 * b for a, b in zip(s, k2)]); k4 = f([a + h * b for a, b in zip(s, k3)])
        s = [a + h / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(s, k1, k2, k3, k4)]
    return exp(s[0] + s[2] / 2)
state = 20261123                                   # road 3: our own random numbers (64-bit LCG)
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def normals():                                     # two independent normals, then correlate them
    r, t = sqrt(-2 * log(uniform())), 2 * pi * uniform()
    return r * cos(t), RHO * r * cos(t) + sqrt(1 - RHO * RHO) * r * sin(t)
def simulate(times, pairs=5000, dt=0.01):          # Euler steps, antithetic pairs: mean, s.e.
    marks, sums = {round(T / dt): T for T in times}, {T: [0.0, 0.0] for T in times}
    for _ in range(pairs):
        xa = xb = log(S0); ya = yb = Y0
        for step in range(1, max(marks) + 1):
            z1, z2 = normals()
            xa, ya = xa + (R - ya - SS * SS / 2) * dt + SS * sqrt(dt) * z1, ya + KAPPA * (ALPHA - ya) * dt + SY * sqrt(dt) * z2
            xb, yb = xb + (R - yb - SS * SS / 2) * dt - SS * sqrt(dt) * z1, yb + KAPPA * (ALPHA - yb) * dt - SY * sqrt(dt) * z2
            if step in marks: v = (exp(xa) + exp(xb)) / 2; sums[marks[step]][0] += v; sums[marks[step]][1] += v * v
    return {T: (a / pairs, sqrt((b / pairs - (a / pairs) ** 2) / pairs)) for T, (a, b) in sums.items()}
def vol_corr(Ta, Tb, k=KAPPA, ss=SS, sy=SY, rho=RHO):   # formula: d ln F = ss dz1 - sy B dz2
    cov = lambda a, b: ss * ss - rho * ss * sy * (a + b) + sy * sy * a * b
    a, b = B(Ta, k), B(Tb, k)
    return sqrt(cov(a, a)), sqrt(cov(b, b)), cov(a, b) / sqrt(cov(a, a) * cov(b, b))
def bumps(T, e=1e-4):                              # second road: slopes of ln F from the ODE road
    dS = (log(fut_ode(T, S=S0 * exp(e))) - log(fut_ode(T, S=S0 * exp(-e)))) / (2 * e)
    return dS, (log(fut_ode(T, y=Y0 + e)) - log(fut_ode(T, y=Y0 - e))) / (2 * e)
def cv(p1, q1, p2, q2): return SS * SS * p1 * p2 + SY * SY * q1 * q2 + RHO * SS * SY * (p1 * q2 + q1 * p2)
TIMES = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0]
sim = simulate(TIMES)
print("inputs: spot 85, yield today 6%, level 3%, kappa 1.5, vols 30% and 25%, rho 0.8, r 5%")
for T in (0.25, 1.0, 3.0):
    (c, g, q, v), b, i1, i2 = terms(T, **P)
    print(f"by hand T = {T:g}: B {b:.4f}  carry {c:+.4f}  yield gap {g:+.4f}  I1 {i1:.4f}  rho term {q:+.4f}"
          f"  I2 {i2:.4f}  yield-var term {v:+.4f}  sum {c + g + q + v:+.4f}  F {fut(T):.4f}")
print("   T   closed form   ODE road   simulation  (s.e.)")
for T in TIMES: print(f"{T:4.2f}  {fut(T):11.4f}  {fut_ode(T):9.4f}  {sim[T][0]:11.4f}  ({sim[T][1]:.4f})")
print("   T   futures vol   by bumps   correlation with 3-month   by bumps")
rows = []
for T in TIMES:
    va, vb, cr = vol_corr(0.25, T)
    (sa, ya), (sb, yb) = bumps(0.25), bumps(T)
    bv, bc = sqrt(cv(sb, yb, sb, yb)), cv(sa, ya, sb, yb) / sqrt(cv(sa, ya, sa, ya) * cv(sb, yb, sb, yb))
    rows.append((vb, bv, cr, bc)); print(f"{T:4.2f}  {100 * vb:10.2f}%  {100 * bv:8.2f}%  {cr:24.4f}  {bc:9.4f}")
print(f"long-run futures vol sqrt(ss^2 - 2 rho ss sy / k + sy^2 / k^2)  {100 * vol_corr(0.25, 60)[1]:.2f}%")
N, dt, xs = 100000, 1 / 252, []                    # third road: daily moves, sample correlation
for _ in range(N):
    z1, z2 = normals()
    S1, y1 = S0 * exp((R - Y0 - SS * SS / 2) * dt + SS * sqrt(dt) * z1), Y0 + KAPPA * (ALPHA - Y0) * dt + SY * sqrt(dt) * z2
    xs.append((log(fut(0.25 - dt, S=S1, y=y1) / fut(0.25)), log(fut(2 - dt, S=S1, y=y1) / fut(2.0))))
ma, mb = sum(a for a, b in xs) / N, sum(b for a, b in xs) / N
c_mc = sum((a - ma) * (b - mb) for a, b in xs) / sqrt(sum((a - ma) ** 2 for a, b in xs) * sum((b - mb) ** 2 for a, b in xs))
c_th = vol_corr(0.25, 2.0)[2]
print(f"3-month vs 2-year correlation: formula {c_th:.4f}  simulated daily moves {c_mc:.4f}  (s.e. {(1 - c_th**2) / sqrt(N):.4f})")
print(f"share of 2-year risk a 3-month hedge cannot remove, sqrt(1 - corr^2)  {100 * sqrt(1 - c_th**2):.1f}%")
one = fut(1.0, S=80.0, y=R - 0.045 + log(80 / 75), k=1.0, al=R - 0.045, ss=0.3, sy=0.3, rho=1.0)
print(f"one-factor case (rho 1, sy = kappa ss), crude 80 toward 75, 1-year {one:.4f}; earlier card 78.3108")
print(f"3-month vs 2-year correlation, rho 1 and sy = kappa ss: {vol_corr(0.25, 2.0, k=1.0, sy=0.3, rho=1.0)[2]:.4f};"
      f"  sy = 0: {vol_corr(0.25, 2.0, sy=0.0)[2]:.4f}")
jump = RHO * SY / SS * log(1.1)                     # yield move that typically comes with a 10% spot rise
KICKS = [("spot alone", dict(S=S0 * 1.1)), ("yield alone", dict(y=Y0 + jump)), ("both", dict(S=S0 * 1.1, y=Y0 + jump))]
def move(T, kw): return 100 * (fut(T, **kw) / fut(T) - 1)   # percent change in the future after a kick
print(f"spot +10% with the typical yield move {100 * jump:+.2f} points; change in each future, kick by kick")
for T in (0.25, 1.0, 3.0): print(f"  T = {T:4.2f}  today {fut(T):.2f}  " + "  ".join(f"{l} {move(T, kw):+.2f}%" for l, kw in KICKS))
grid = [0.5 * i for i in range(11)]; print(f"chart {'T':11s} " + " ".join(f"{T:6.1f}" for T in grid))
for l, kw in [("today", {})] + KICKS[0::2]: print(f"chart {l:11s} " + " ".join(f"{fut(T, **kw):6.2f}" for T in grid))
for l, kw in KICKS: print(f"move  {l:11s} " + " ".join(f"{move(T, kw):6.2f}" for T in grid))
ST, SF = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0], [84.78, 84.50, 84.09, 83.70, 83.42, 82.88, 82.33, 81.86]
def sse(k, y, al, **kw): return sum((log(f) - log(fut(T, k=k, y=y, al=al, **kw))) ** 2 for T, f in zip(ST, SF))
def best(k, **kw):                                 # for fixed kappa, ln F is a straight line in (y, al)
    rows = [(-B(T, k), B(T, k) - T, log(f) - log(fut(T, k=k, y=0.0, al=0.0, **kw))) for T, f in zip(ST, SF)]
    p, q, u = sum(a * a for a, b, c in rows), sum(a * b for a, b, c in rows), sum(b * b for a, b, c in rows)
    g, h = sum(a * c for a, b, c in rows), sum(b * c for a, b, c in rows)
    return (u * g - q * h) / (p * u - q * q), (p * h - q * g) / (p * u - q * q)
lo, hi, gr = 0.2, 6.0, (sqrt(5) - 1) / 2           # fit road 1: golden section on kappa alone
for _ in range(200):
    c, d = hi - gr * (hi - lo), lo + gr * (hi - lo); lo, hi = (lo, d) if sse(c, *best(c)) < sse(d, *best(d)) else (c, hi)
k1 = (lo + hi) / 2; y1, a1 = best(k1)
x, e = [1.0, 0.03, 0.03], 1e-6                     # fit road 2: Gauss-Newton on all three at once
for _ in range(100):
    r = [log(f) - log(fut(T, k=x[0], y=x[1], al=x[2])) for T, f in zip(ST, SF)]
    up = lambda j, s: [x[i] + s * e * (i == j) for i in range(3)]
    J = [[(log(fut(T, k=up(j, 1)[0], y=up(j, 1)[1], al=up(j, 1)[2])) -
           log(fut(T, k=up(j, -1)[0], y=up(j, -1)[1], al=up(j, -1)[2]))) / (2 * e) for j in range(3)] for T in ST]
    M = [[sum(J[i][a] * J[i][b] for i in range(8)) for b in range(3)] + [sum(J[i][a] * r[i] for i in range(8))] for a in range(3)]
    for a, b in ((0, 1), (0, 2), (1, 2)):          # Gaussian elimination on the 3 x 3 normal equations
        m = M[b][a] / M[a][a]; M[b] = [u - m * v for u, v in zip(M[b], M[a])]
    dx = [0.0] * 3
    for a in (2, 1, 0): dx[a] = (M[a][3] - sum(M[a][b] * dx[b] for b in range(a + 1, 3))) / M[a][a]
    step = 1.0                                     # halve the step until the error falls
    while step > 1e-9 and (x[0] + step * dx[0] <= 0 or sse(*[u + step * v for u, v in zip(x, dx)]) > sse(*x)): step /= 2
    x = [u + step * v for u, v in zip(x, dx)]
print(f"fit, golden section: kappa {k1:.4f}  yield today {100 * y1:.3f}%  level {100 * a1:.3f}%  rms log error {sqrt(sse(k1, y1, a1) / 8):.6f}")
print(f"fit, Gauss-Newton:   kappa {x[0]:.4f}  yield today {100 * x[1]:.3f}%  level {100 * x[2]:.3f}%  rms log error {sqrt(sse(*x) / 8):.6f}")
print("fit, rms log error with kappa held at 1.0 / 1.5 / 3.0: " + " / ".join(f"{sqrt(sse(k, *best(k)) / 8):.6f}" for k in (1.0, 1.5, 3.0))
      + "  (" + " / ".join(f"{sqrt(sse(k, *best(k)) / sse(k1, y1, a1)):.2f}" for k in (1.0, 1.5, 3.0)) + " times the best)")
y0, a0 = best(k1, rho=0.0)                         # the same strip and speed, fitted as if rho were 0
print(f"fit with rho 0, kappa {k1:.4f}: yield today {100 * y0:.3f}%  level {100 * a0:.3f}%  rms log error {sqrt(sse(k1, y0, a0, rho=0.0) / 8):.6f}"
      f";  level shift {100 * (a0 - a1):.2f} points, rho ss sy / kappa {100 * RHO * SS * SY / k1:.2f}")
print("strip quotes  " + " ".join(f"{f:6.2f}" for f in SF))
print("fitted curve  " + " ".join(f"{fut(T, k=k1, y=y1, al=a1):6.2f}" for T in ST))
print(f"wrong: drop both variance terms, 3-year      {S0 * exp(sum(terms(3.0, **P)[0][:2])):10.4f}")
print(f"wrong: drop the correlation term, 3-year     {fut(3.0, rho=0.0):10.4f}")
print(f"wrong: carry with yield fixed at 6%, 3-year  {S0 * exp((R - Y0) * 3):10.4f}")
print(f"wrong: carry with yield fixed at 3%, 3-year  {S0 * exp((R - ALPHA) * 3):10.4f}")
print(f"try: rho = 0, 3-month vs 2-year correlation      {vol_corr(0.25, 2.0, rho=0.0)[2]:.4f}")
print(f"try: kappa = 0.5, 3-month vs 2-year correlation  {vol_corr(0.25, 2.0, k=0.5)[2]:.4f}")
print(f"try: kappa = 0.5, 3-year future                  {fut(3.0, k=0.5):.4f}")
print(f"try: yield today 3%, 1-year future               {fut(1.0, y=0.03):.4f}")
for T in TIMES:
    assert abs(fut(T) - fut_ode(T)) < 1e-6, "closed form vs Runge-Kutta moments"
    assert abs(sim[T][0] - fut(T)) < 4 * sim[T][1], "simulation within four standard errors"
for vb, bv, cr, bc in rows: assert abs(vb - bv) < 1e-6 and abs(cr - bc) < 1e-6, "futures vol and correlation vs bumps"
assert abs(c_mc - c_th) < 4 * (1 - c_th**2) / sqrt(N), "correlation vs simulated daily moves"
assert abs(one - 78.3108) < 1e-4, "one-factor special case reproduces the earlier card"
assert abs(k1 - x[0]) < 1e-4, "two fits agree on kappa"
assert abs(y1 - Y0) < 0.002 and abs(a1 - ALPHA) < 0.002 and abs(k1 - KAPPA) < 0.25, "fit recovers the settings the strip was built from"
assert abs(a0 - a1 - RHO * SS * SY / k1) < 1e-9 and abs(sse(k1, y0, a0, rho=0.0) - sse(k1, y1, a1)) < 1e-15, "rho 0: the level absorbs rho ss sy / kappa"
print("ALL CHECKS PASS")
