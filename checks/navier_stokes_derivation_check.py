# Navier-Stokes derivation -- the check behind the card.  Standard library only.
# Part A: Poiseuille flow in the 5 cm pipe solves the derived equations, and the
# integral balances over a 1 m slug of pipe close.  Part B: a Taylor-Green eddy
# 5 cm across, where the pressure is recovered from the velocity alone, by a
# line integral of the momentum equation and by a grid Poisson solve.
from math import pi, sin, cos, log, sqrt

RHO, MU = 998.207, 1.0016e-3          # water at 20 C: kg/m^3, Pa s
V, D = 1.0, 0.05                       # mean speed m/s, bore m
R = D / 2
NU = MU / RHO

def u_pipe(r): return 2 * V * (1 - (r / R) ** 2)   # Poiseuille profile, m/s
G = 8 * MU * V / R ** 2                              # pressure drop per metre, Pa/m

# ---- road 1: the equation's residual by centred differences, Cartesian x, y ----
def resid(x, y, h):
    f = lambda a, b: u_pipe(sqrt(a * a + b * b))
    lap = (f(x + h, y) + f(x - h, y) + f(x, y + h) + f(x, y - h) - 4 * f(x, y)) / h ** 2
    return G + MU * lap                # -dp/dz + mu * Laplacian(u_z); convection is zero
res1, res2 = resid(0.01, 0.005, 1e-3), resid(0.01, 0.005, 5e-4)

# ---- road 2: integral balances over a 1 m slug, by summing 2000 thin rings ----
n = 2000
rings = [((i + 0.5) * R / n, R / n) for i in range(n)]
Q = sum(u_pipe(r) * 2 * pi * r * dr for r, dr in rings)
mom = sum(RHO * u_pipe(r) ** 2 * 2 * pi * r * dr for r, dr in rings)
h = 1e-6
tau_w = -MU * (u_pipe(R + h) - u_pipe(R - h)) / (2 * h)   # wall shear from the profile's slope
F_p, F_w = G * pi * R ** 2 * 1.0, tau_w * 2 * pi * R * 1.0
Re = V * D / NU
f_bl = 0.3164 * Re ** -0.25                                 # Blasius smooth-pipe friction factor
G_turb = f_bl * RHO * V ** 2 / (2 * D)

print(f"nu (mm^2/s)                      {NU * 1e6:12.6f}")
print(f"Re = V D / nu                    {Re:12.1f}")
print(f"u_max on the axis (m/s)          {u_pipe(0):12.4f}")
print(f"G = 8 mu V / R^2 (Pa/m)          {G:12.4f}")
print(f"residual, h = 1 mm (N/m^3)       {res1:12.2e}")
print(f"residual, h = 0.5 mm (N/m^3)     {res2:12.2e}")
print(f"Q by rings (L/s)                 {Q * 1000:12.6f}")
print(f"Q = pi R^2 V (L/s)               {pi * R * R * V * 1000:12.6f}")
print(f"mass through each end (kg/s)     {RHO * Q:12.6f}")
print(f"momentum flux by rings (N)       {mom:12.6f}")
print(f"momentum flux 4/3 rho V^2 A (N)  {4 / 3 * RHO * V * V * pi * R * R:12.6f}")
print(f"wall shear tau_w (Pa)            {tau_w:12.6f}")
print(f"pressure force on slug (N)       {F_p:12.6f}")
print(f"wall friction on slug (N)        {F_w:12.6f}")
print(f"Blasius f                        {f_bl:12.6f}")
print(f"turbulent drop (Pa/m)            {G_turb:12.4f}")
print(f"turbulent / laminar              {G_turb / G:12.4f}")
print(f"wrong: mu = 0 (Pa/m)             {8 * 0.0 * V / R ** 2:12.4f}")
print(f"wrong: 1 m/s as centre (Pa/m)    {4 * MU * V / R ** 2:12.4f}")
print(f"try: V = 2 m/s (Pa/m), Re        {16 * MU / R ** 2:12.4f} {2 * Re:10.1f}")
print(f"try: D = 10 cm (Pa/m)            {8 * MU * V / 0.05 ** 2:12.4f}")
print("chart, r (mm)  " + " ".join(f"{-25 + 5 * i:5d}" for i in range(11)))
print("chart, u (m/s) " + " ".join(f"{u_pipe((-25 + 5 * i) / 1000):5.2f}" for i in range(11)))

# ---- Part B: Taylor-Green eddy, one eddy 5 cm across, 1 m/s ----
U, k = 1.0, pi / D
def vel(x, y): return U * sin(k * x) * cos(k * y), -U * cos(k * x) * sin(k * y)
def p_exact(x, y): return RHO * U * U / 4 * (cos(2 * k * x) + cos(2 * k * y))
e = 1e-5
def grads(x, y):                       # du/dx, du/dy, dv/dx, dv/dy by centred differences
    (a, _), (b, _) = vel(x + e, y), vel(x - e, y)
    (_, c), (_, d) = vel(x + e, y), vel(x - e, y)
    (a2, c2), (b2, d2) = vel(x, y + e), vel(x, y - e)
    return (a - b) / (2 * e), (a2 - b2) / (2 * e), (c - d) / (2 * e), (c2 - d2) / (2 * e)
def dpdx_dpdy(x, y):                   # momentum equation: grad p = -rho (u . grad) u
    u, v = vel(x, y); ux, uy, vx, vy = grads(x, y)
    return -RHO * (u * ux + v * uy), -RHO * (u * vx + v * vy)
def simpson(f, a, b, m=200):
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * (b - a) / m) for i in range(1, m))
    return s * (b - a) / (3 * m)
dp_line = simpson(lambda x: dpdx_dpdy(x, 0.0)[0], 0, R) + simpson(lambda y: dpdx_dpdy(R, y)[1], 0, R)

def poisson(N, sign=1.0):              # periodic box 2D x 2D, -Lap p = rho * sum d_i u_j d_j u_i
    L = 2 * D; hh = L / N; X = [i * hh for i in range(N)]
    S = [[0.0] * N for _ in range(N)]
    for i in range(N):                 # velocity gradients of the eddy, written out by hand
        for j in range(N):
            cx, sx, cy, sy = cos(k * X[i]), sin(k * X[i]), cos(k * X[j]), sin(k * X[j])
            ux, uy, vx, vy = U * k * cx * cy, -U * k * sx * sy, U * k * sx * sy, -U * k * cx * cy
            S[i][j] = sign * RHO * (ux * ux + 2 * uy * vx + vy * vy)
    P = [[0.0] * N for _ in range(N)]
    w = 2 / (1 + sin(2 * pi / N))
    for sweep in range(5000):
        big = 0.0
        for i in range(N):
            for j in range(N):
                nb = P[(i + 1) % N][j] + P[(i - 1) % N][j] + P[i][(j + 1) % N] + P[i][(j - 1) % N]
                new = (nb + hh * hh * S[i][j]) / 4
                d = w * (new - P[i][j]); P[i][j] += d; big = max(big, abs(d))
        if big < 1e-11: break
    mean = sum(map(sum, P)) / N ** 2
    err = max(abs(P[i][j] - mean - p_exact(X[i], X[j])) for i in range(N) for j in range(N))
    return P[N // 4][N // 4] - mean, err

pc16, err16 = poisson(16)
pc32, err32 = poisson(32)
pc64, err64 = poisson(64)
pc_wrong, _ = poisson(32, -1.0)
divrate = abs(sum(grads(0.0, 0.0)[a] ** 2 for a in (0, 3)) + 2 * grads(0.0, 0.0)[1] * grads(0.0, 0.0)[2])

print(f"TG p at eddy centre, exact (Pa)  {p_exact(R, R):12.4f}")
print(f"TG p at corner, exact (Pa)       {p_exact(0, 0):12.4f}")
print(f"TG centre - corner, exact (Pa)   {p_exact(R, R) - p_exact(0, 0):12.4f}")
print(f"TG centre - corner, line (Pa)    {dp_line:12.4f}")
print(f"TG centre, Poisson N=16 (Pa)     {pc16:12.4f}")
print(f"TG centre, Poisson N=32 (Pa)     {pc32:12.4f}")
print(f"TG centre, Poisson N=64 (Pa)     {pc64:12.4f}")
print(f"TG max error N=16, 32, 64 (Pa)   {err16:12.4f} {err32:10.4f} {err64:10.4f}")
print(f"TG observed order 16-32, 32-64   {log(err16 / err32) / log(2):12.4f} {log(err32 / err64) / log(2):10.4f}")
print(f"wrong: Poisson sign flipped (Pa) {pc_wrong:12.4f}")
print(f"no pressure: d(div u)/dt (1/s^2) {divrate:12.1f}")
print(f"no pressure: div u at 1 ms (1/s) {divrate * 1e-3:12.4f}")

assert abs(Re - 49830.6) < 0.1, "Reynolds number of the house pipe"
assert abs(res1) < 1e-6 * G and abs(res2) < 1e-5 * G, "Poiseuille solves the equation"
assert abs(Q - pi * R * R * V) < 1e-9, "ring sum against the closed-form flow rate"
assert abs(mom - 4 / 3 * RHO * V * V * pi * R * R) < 1e-6, "momentum flux by rings vs formula"
assert abs(F_p - F_w) < 1e-9, "pressure force balances wall friction on the slug"
assert abs(dp_line - (p_exact(R, R) - p_exact(0, 0))) < 1e-4, "pressure from momentum"
assert abs(pc32 - p_exact(R, R)) < 0.02 * RHO, "Poisson pressure at the eddy centre"
assert 1.9 < log(err32 / err64) / log(2) < 2.1, "second-order grid"
assert abs(divrate - 2 * U * U * k * k) < 0.1, "divergence growth without pressure"
print("ALL CHECKS PASS")
