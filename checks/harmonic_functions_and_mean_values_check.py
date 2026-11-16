# Harmonic functions and mean values -- the check behind the card.  Standard library only.
# A 3 m cube room: the sunny wall (y = 0) at 30 C, the other five faces at 18 C, no heater.
# Road 1: the sine-sinh series.  Road 2: averages over spheres and balls (Gauss-Legendre).
# Road 3: a grid where every node is the average of its six neighbours, at two steps.
from math import pi, sin, cos, exp, sqrt, log

L, COLD, SUN, D = 3.0, 18.0, 30.0, 3            # room side m; wall C; sunny wall C; dimension
ODD = range(1, 140, 2)
MODES = [(m, n, pi * sqrt(m * m + n * n) / L, 16.0 / (pi * pi * m * n)) for m in ODD for n in ODD]

def unit(x, y, z):                               # sunny wall at 1, the rest at 0
    sx = {m: sin(m * pi * x / L) for m in ODD}
    sz = {n: sin(n * pi * z / L) for n in ODD}
    s = 0.0
    for m, n, k, c in MODES:
        e = exp(-k * y)
        if e < 1e-17: continue                   # dropped term below 1e-17 of its size
        s += c * sx[m] * sz[n] * e * (1.0 - exp(-2.0 * k * (L - y))) / (1.0 - exp(-2.0 * k * L))
    return s

def u(x, y, z): return COLD + (SUN - COLD) * unit(x, y, z)

def dudy(x, y, z):                               # the series differentiated term by term
    s = 0.0
    for m, n, k, c in MODES:
        s -= c * sin(m * pi * x / L) * sin(n * pi * z / L) * k * (exp(-k * y) + exp(-k * (2 * L - y))) / (1.0 - exp(-2.0 * k * L))
    return (SUN - COLD) * s

def gauss_legendre(n):                           # nodes and weights on [-1, 1], by Newton's method
    xs, ws = [], []
    for i in range(1, n + 1):
        x = cos(pi * (i - 0.25) / (n + 0.5))
        for _ in range(60):
            p0, p1 = 1.0, x
            for k in range(2, n + 1):
                p0, p1 = p1, ((2 * k - 1) * x * p1 - (k - 1) * p0) / k
            dp = n * (x * p1 - p0) / (x * x - 1.0)
            x -= p1 / dp
        xs.append(x); ws.append(2.0 / ((1.0 - x * x) * dp * dp))
    return xs, ws

GT, GW = gauss_legendre(16)
NP = 32

def sphere_avg(f, c, r):                         # average of f over the sphere of radius r round c
    tot = 0.0
    for t, w in zip(GT, GW):
        st = sqrt(1.0 - t * t)
        for j in range(NP):
            p = 2.0 * pi * j / NP
            tot += w * f(c[0] + r * st * cos(p), c[1] + r * t, c[2] + r * st * sin(p))
    return tot / (2.0 * NP)

GT8, GW8 = gauss_legendre(8)

def ball_avg(f, c, r):                           # shells of radius s weighted by d s^(d-1) / r^d
    return sum(w * 0.5 * D * ((t + 1.0) / 2.0) ** 2 * sphere_avg(f, c, 0.5 * r * (t + 1.0)) for t, w in zip(GT8, GW8))

def grid(N, q):                                  # six-neighbour averaging plus a heater q (K per m^2), swept by SOR
    h = L / N
    g = [[[COLD] * (N + 1) for _ in range(N + 1)] for _ in range(N + 1)]
    for i in range(1, N):
        for k in range(1, N):
            g[i][0][k] = SUN
    om = 2.0 / (1.0 + sin(pi / N))
    while True:
        big = 0.0
        for i in range(1, N):
            for j in range(1, N):
                for k in range(1, N):
                    a = (g[i-1][j][k] + g[i+1][j][k] + g[i][j-1][k] + g[i][j+1][k] + g[i][j][k-1] + g[i][j][k+1] + q * h * h) / 6.0
                    dv = om * (a - g[i][j][k]); g[i][j][k] += dv; big = max(big, abs(dv))
        if big < 1e-12: break
    inner = [g[i][j][k] for i in range(1, N) for j in range(1, N) for k in range(1, N)]
    return g[N // 2][N // 2][N // 2], g[N // 2][round(1.0 / h)][N // 2], max(inner), min(inner)

C, P = (1.5, 1.5, 1.5), (1.5, 1.0, 1.5)          # room centre; 1 m out from the sunny wall
uc, up = u(*C), u(*P)
# what the series drops, at every point it is used (all have y >= 0.5 m): skipped terms, then the first mode past the list
tail_skip = (SUN - COLD) * 16.0 / (pi * pi) * 1e-17 * len(MODES)
tail_141 = (SUN - COLD) * 16.0 / (pi * pi * 141) * exp(-pi * sqrt(141 * 141 + 1) * 0.5 / L)
s_c1, s_p, b_p = sphere_avg(u, C, 1.0), sphere_avg(u, P, 0.5), ball_avg(u, P, 0.5)
g12, g24 = grid(12, 0.0), grid(24, 0.0)
e12, e24 = g12[1] - up, g24[1] - up
order = log(abs(e12) / abs(e24)) / log(2.0)       # observed order of the grid error
# derivatives are averages too: d/dy u(c) = (d/r) * sphere average of u * n_y
grad_series = dudy(*C)
grad_fd = (u(1.5, 1.5 + 1e-3, 1.5) - u(1.5, 1.5 - 1e-3, 1.5)) / 2e-3
grad_mvp = D / 1.0 * sphere_avg(lambda x, y, z: u(x, y, z) * (y - 1.5), C, 1.0)
grad_cap = D / 1.5 * (SUN - COLD) / 2.0          # (d/r) * max |u - 24| with r = 1.5 m
# what breaks
f = 3.0                                          # an even heater, K per m^2 (illustrative)
def heat(x, y, z):                               # same walls, heater f inside: u + v with -Lap v = f, v = 0 on the walls
    s = 0.0                                      # v = f x(L - x)/2 minus a sine-cosh series that cancels it on four faces
    for m, n, k, c in MODES:
        ch = lambda t: (exp(-k * t) + exp(-k * (L - t))) / (1.0 + exp(-k * L))
        s += c * L * L / (pi * pi * m * m) * sin(m * pi * x / L) * (sin(n * pi * z / L) * ch(y) + sin(n * pi * y / L) * ch(z))
    return u(x, y, z) + f * (0.5 * x * (L - x) - s)
heat_c, heat_avg = heat(*C), sphere_avg(heat, C, 1.0)
q12, q24 = grid(12, f), grid(24, f)
q_order = log(abs(q12[0] - heat_c) / abs(q24[0] - heat_c)) / log(2.0)
src = lambda x, y, z: 1.0 / sqrt((x - 1.5) ** 2 + (y - 1.0) ** 2 + (z - 1.5) ** 2)   # point source at P
src_avg = sphere_avg(src, C, 1.0)

rows = [("centre, series (C)", uc), ("centre, symmetry 18 + 12/6 (C)", COLD + (SUN - COLD) / 6),
        ("centre, sphere r = 1 m (C)", s_c1), ("centre, grid h = 0.25 m (C)", g12[0]),
        ("P, series (C)", up), ("P, sphere r = 0.5 m (C)", s_p), ("P, ball r = 0.5 m (C)", b_p),
        ("P, grid h = 0.25 m (C)", g12[1]), ("P, grid h = 0.125 m (C)", g24[1]),
        ("P, grid observed order", order),
        ("hottest grid node inside (C)", g24[2]), ("coldest grid node inside (C)", g24[3]),
        ("du/dx2 at centre, series (K/m)", grad_series), ("du/dx2 at centre, centred diff (K/m)", grad_fd),
        ("du/dx2 at centre, (d/r) avg u n_y (K/m)", grad_mvp), ("|grad u| cap (d/r) max|u-24| (K/m)", grad_cap),
        ("wrong: 2-D rule 18 + 12/4 (C)", COLD + (SUN - COLD) / 4),
        ("wrong: plain wall average at P (C)", (SUN + 5 * COLD) / 6),
        ("break: heater, centre, series (C)", heat_c), ("  heater centre, grid h = 0.25 m (C)", q12[0]),
        ("  heater centre, grid h = 0.125 m (C)", q24[0]), ("  heater centre, grid observed order", q_order),
        ("break: heater, sphere avg r = 1 m (C)", heat_avg), ("  shortfall f r^2/(2d) (K)", f / (2 * D)),
        ("break: source inside, sphere avg (1/m)", src_avg), ("  value at centre 1/0.5 (1/m)", src(*C))]
for name, v in rows:
    print(f"{name:<40} {v:>12.6f}")
print(f"{'series: all skipped terms, at most (K)':<40} {tail_skip:>12.3e}")
print(f"{'series: first omitted mode, y = 0.5 m (K)':<40} {tail_141:>12.3e}")
print("chart, radius (m)          " + " ".join(f"{r:6.2f}" for r in (0.0, 0.25, 0.5, 0.75, 1.0)))
print("chart, no heater (C)       " + " ".join(f"{(uc if r == 0 else sphere_avg(u, C, r)):6.2f}" for r in (0.0, 0.25, 0.5, 0.75, 1.0)))
print("chart, even heater (C)     " + " ".join(f"{(heat_c if r == 0 else sphere_avg(heat, C, r)):6.2f}" for r in (0.0, 0.25, 0.5, 0.75, 1.0)))
print("figure, 120 px/m, slice z = 1.5 m: room (60, 40)-(420, 400); centre (240, 220) r 120; P (240, 280) r 60")

assert abs(uc - 20.0) < 1e-9, "series centre must match the six-face symmetry"
assert abs(s_c1 - uc) < 1e-9 and abs(s_p - up) < 1e-9, "sphere averages equal the centre values"
assert abs(b_p - up) < 1e-9, "ball average equals the centre value"
assert abs(g12[0] - 20.0) < 1e-9, "grid centre is exactly a sixth of the way up"
assert abs(e24) < 0.02 and 1.8 < order < 2.2, "grid converges to the series at second order"
assert SUN > g24[2] and g24[3] > COLD, "inside stays strictly between the wall temperatures"
assert abs(grad_series - grad_fd) < 1e-5 and abs(grad_mvp - grad_series) < 1e-9, "three roads to the slope"
assert abs(grad_series) <= grad_cap, "slope obeys the mean-value derivative bound"
assert abs(q24[0] - heat_c) < 0.02 and 1.8 < q_order < 2.2, "heated grid converges to the heated series"
assert abs((heat_c - heat_avg) - f / (2 * D)) < 1e-9, "heater shortfall is f r^2/(2d)"
assert abs(src_avg - 1.0) < 1e-6, "an enclosed source averages to 1/r, not its centre value"
print("ALL CHECKS PASS")
