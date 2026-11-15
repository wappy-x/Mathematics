# Fokker-Planck with edges -- the check behind the card.  Standard library only.
# Roads: (1) the closed-form bell; (2) the sum of decaying modes (Mehler's series);
# (3) a Crank-Nicolson finite-volume grid with a zero-flux, zero-value or wrong edge;
# (4) eigenvalues by shooting with RK4; plus residuals and the semigroup rule.
# Units: the rate in percentage points ("points"), time in years.
from math import exp, sqrt, pi, log
K, TH, SG, X0 = 0.5, 4.0, 2.0, 6.0         # pull per year, level, noise, start
S2 = SG * SG / (2 * K)                     # long-run variance, points squared
def mu(y): return K * (TH - y)
def kern(t, x, y):                         # road 1: the transition density
    m = TH + (x - TH) * exp(-K * t); v = S2 * (1 - exp(-2 * K * t))
    return exp(-(y - m) ** 2 / (2 * v)) / sqrt(2 * pi * v)
def pinf(y): return exp(-(y - TH) ** 2 / (2 * S2)) / sqrt(2 * pi * S2)
def modes(t, x, y, n):                     # road 2: long-run bell times decaying modes
    a, b = (x - TH) / sqrt(S2), (y - TH) / sqrt(S2)
    ha0, ha1, hb0, hb1, tot, fact = 1.0, a, 1.0, b, 1.0, 1.0
    for k in range(1, n + 2):              # He_k by its recurrence
        fact *= k; term = exp(-k * K * t) * ha1 * hb1 / fact
        if k <= n: tot += term
        ha0, ha1 = ha1, a * ha1 - k * ha0; hb0, hb1 = hb1, b * hb1 - k * hb0
    return pinf(y) * tot, pinf(y) * term   # value, first omitted mode
def Phi(z, n=2000):                        # normal CDF by Simpson's rule
    h = z / n; s = 1 + exp(-z * z / 2)
    for i in range(1, n): s += (4 if i % 2 else 2) * exp(-(i * h) ** 2 / 2)
    return 0.5 + s * h / 3 / sqrt(2 * pi)
def grid(lo, hi, h, dt, edge, times):      # road 3: cells, fluxes, Crank-Nicolson
    n = round((hi - lo) / h); ys = [lo + (i + 0.5) * h for i in range(n)]
    p = [kern(0.1, X0, y) for y in ys]; D = 0.5 * SG * SG / h
    a, b, c = [0.0] * n, [0.0] * n, [0.0] * n
    for i in range(n - 1):                 # current through the face between i and i+1
        m = mu(lo + (i + 1) * h); u, w = (m / 2 + D) / h, (m / 2 - D) / h
        b[i] -= u; c[i] -= w; a[i + 1] += u; b[i + 1] += w
    if edge == "absorb": b[0] -= 2 * D / h # p = 0 on the wall (mirror cell -p)
    if edge == "flat": b[0] += mu(lo) / h  # wrong: p_y = 0, so J = mu p at the wall
    out, t, q = {}, 0.1, dt / 2
    for T in times:
        while t < T - 1e-9:
            r = [p[i] + q * (b[i] * p[i] + (a[i] * p[i - 1] if i else 0)
                 + (c[i] * p[i + 1] if i < n - 1 else 0)) for i in range(n)]
            cc, dd = [0.0] * n, [0.0] * n  # Thomas solve of (I - q A) p = r
            for i in range(n):
                den = 1 - q * b[i] + (q * a[i] * cc[i - 1] if i else 0)
                cc[i] = -q * c[i] / den
                dd[i] = (r[i] + (q * a[i] * dd[i - 1] if i else 0)) / den
            for i in range(n - 2, -1, -1): dd[i] -= cc[i] * dd[i + 1]
            p, t = dd, t + dt
        out[T] = (sum(p) * h, sum(y * v for y, v in zip(ys, p)) * h, ys, p)
    return out
def shoot(nu, f, d, zw=-2.0, zmax=6.0, n=8000):   # road 4: f'' - z f' + nu f = 0
    h, z = (zmax - zw) / n, zw
    F = lambda z, f, d: (d, z * d - nu * f)
    for _ in range(n):
        k1 = F(z, f, d); k2 = F(z + h/2, f + h/2 * k1[0], d + h/2 * k1[1])
        k3 = F(z + h/2, f + h/2 * k2[0], d + h/2 * k2[1]); k4 = F(z + h, f + h * k3[0], d + h * k3[1])
        f += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        d += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]); z += h
    return f
def eigen(lo, hi, f, d):                   # bisect on the sign of the far-out blow-up
    slo = shoot(lo, f, d)
    for _ in range(40):
        mid = (lo + hi) / 2
        if (shoot(mid, f, d) > 0) == (slo > 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2
def tv(t, h=0.01): return 0.5 * h * sum(abs(kern(t, X0, -12 + (i + 0.5) * h) - pinf(-12 + (i + 0.5) * h)) for i in range(3200))
def row(label, v, d=5): print(f"{label:<44}{v:.{d}f}")
m1 = TH + (X0 - TH) * exp(-K); v1 = S2 * (1 - exp(-2 * K))
print("1. One year, no edge (closed form, modes, grid)")
row("fading factor e^(-kappa t)", exp(-K)); row("mean m, points", m1); row("variance v, points^2", v1); row("standard deviation", sqrt(v1))
pk = kern(1, X0, m1); pm, om = modes(1, X0, m1, 30); row("peak density, bell, per point", pk)
row("peak density, 30 modes", pm); row("  first omitted mode", om, 9)
fine = grid(-8, 16, 0.05, 0.01, "reflect", [1.0])[1.0]; crs = grid(-8, 16, 0.1, 0.02, "reflect", [1.0])[1.0]
e1 = max(abs(v - kern(1, X0, y)) for y, v in zip(fine[2], fine[3])); e2 = max(abs(v - kern(1, X0, y)) for y, v in zip(crs[2], crs[3]))
row("grid max error, h = 0.1", e2, 7); row("grid max error, h = 0.05", e1, 7)
for y in (2, 4, 6, 8): row(f"density at {y} points", kern(1, X0, y))
sg = sum(kern(0.5, X0, -8 + (i + 0.5) * 0.01) * kern(0.5, -8 + (i + 0.5) * 0.01, m1) for i in range(2400)) * 0.01
row("half a year twice, at the peak", sg); res = []
for h in (0.1, 0.05):                      # p_t against L* in y and against L in x, at y = 5
    pt = (kern(1 + h, X0, 5) - kern(1 - h, X0, 5)) / (2 * h)
    fw = -(mu(5 + h) * kern(1, X0, 5 + h) - mu(5 - h) * kern(1, X0, 5 - h)) / (2 * h) + SG * SG / 2 * (kern(1, X0, 5 + h) - 2 * kern(1, X0, 5) + kern(1, X0, 5 - h)) / h ** 2
    bw = mu(X0) * (kern(1, X0 + h, 5) - kern(1, X0 - h, 5)) / (2 * h) + SG * SG / 2 * (kern(1, X0 + h, 5) - 2 * kern(1, X0, 5) + kern(1, X0 - h, 5)) / h ** 2
    print(f"{'forward, backward residual, h = ' + str(h):<44}{pt - fw:.7f} {pt - bw:.7f}")
    res.append((pt - fw, pt - bw))
row("zero, in standard deviations from m", -m1 / sqrt(v1), 4); row("free mass below 0 after one year", Phi(-m1 / sqrt(v1)))
print("2. A wall at zero")
belinf = Phi(-2.0); fl_mean = TH + sqrt(S2) * exp(-2) / sqrt(2 * pi) / (1 - belinf)
row("free long-run mass below 0", belinf); row("free long run: height at 4", pinf(4)); row("floor long run: height at 4, exact", pinf(4) / (1 - belinf))
row("floor long run: mean, exact", fl_mean)
times = [0.5, 1.0, 2.0, 4.0, 8.0, 10.0, 12.0, 20.0, 30.0]
R = grid(0, 16, 0.05, 0.01, "reflect", times); A = grid(0, 16, 0.05, 0.01, "absorb", times)
A2 = grid(0, 16, 0.1, 0.02, "absorb", [10.0]); W = grid(0, 16, 0.05, 0.01, "flat", [1.0, 10.0])
i4 = round((4 - 0.025) / 0.05)
row("reflect: mass after 30 years", R[30.0][0], 9); row("reflect: mean after 30 years", R[30.0][1])
row("reflect: height at 4 after 30 years", R[30.0][3][i4] / 2 + R[30.0][3][i4 + 1] / 2)
row("reflect: mean after one year", R[1.0][1])
row("absorb: survival 10 years, h = 0.1", A2[10.0][0]); row("absorb: survival 10 years, h = 0.05", A[10.0][0])
row("absorb: survival after 20 years", A[20.0][0])
print("3. How fast it settles (decay rate per year)")
nuA = eigen(0.0, 1.0, 0.0, 1.0); nuR = eigen(0.5, 1.5, 1.0, 0.0)
gA = log(A[10.0][0] / A[20.0][0]) / 10; gR = log((R[8.0][1] - R[30.0][1]) / (R[12.0][1] - R[30.0][1])) / 4
row("no edge: kappa, exact", K); row("reflect: shooting", K * nuR); row("reflect: grid mean, 8 to 12 years", gR)
row("absorb: shooting", K * nuA); row("absorb: grid survival, 10 to 20 years", gA)
row("reflect minus absorb, shooting", K * (nuR - nuA)); row("half-life of the gap, ln 2 / kappa", log(2) / K, 4)
print("t, mean, sd, distance, leading mode, survival:")
for t in (0.5, 1.0, 2.0, 4.0, 8.0):
    print(f"{t:4.1f} {TH + (X0 - TH) * exp(-K * t):.4f} {sqrt(S2 * (1 - exp(-2 * K * t))):.4f} {tv(t):.5f} {sqrt(2 / pi) / 2 * exp(-K * t):.5f} {A[t][0]:.5f}")
print("4. What breaks")
row("p_y = 0 at the wall: mass after one year", W[1.0][0], 4); row("p_y = 0 at the wall: mass after 10 years", W[10.0][0], 2)
row("absorbing used as a floor: mass, 10 years", A[10.0][0], 4)
row("settling at 2 kappa: distance at 4 years", sqrt(2 / pi) / 2 * exp(-4.0), 5); row("  true distance at 4 years", tv(4.0))
for t in (1.0, 4.0): print(f"chart t={t:.0f}: " + " ".join(f"{kern(t, X0, y):.3f}" for y in range(-2, 11)))
print("chart long run: " + " ".join(f"{pinf(y):.3f}" for y in range(-2, 11)))
assert abs(pm - pk) < 1e-6 and abs(om) < 1e-6        # modes against the bell
assert e1 < 1e-4 and 3 < e2 / e1 < 5                 # grid against the bell, second order
assert abs(sg - pk) < 1e-8                           # semigroup rule: half a year twice
assert all(3.5 < a / b < 4.5 for a, b in zip(*res))  # forward and backward residuals fall as h^2
assert abs(R[30.0][0] - 1) < 1e-9 and abs(R[30.0][1] - fl_mean) < 1e-4   # zero flux keeps mass
assert abs(gA - K * nuA) < 1e-4 and abs(gR - K * nuR) < 2e-3            # grid against shooting
assert abs(nuR - nuA - 1) < 1e-5                     # the derivative identity
assert abs(tv(8.0) / (sqrt(2 / pi) / 2 * exp(-4.0)) - 1) < 1e-3
assert W[10.0][0] > 2 and A[10.0][0] < 0.9           # wrong edges fail visibly
print("ALL CHECKS PASS")
