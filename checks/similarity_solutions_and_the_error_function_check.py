# Similarity solutions -- the check behind the card.  Standard library only.  Two 1 m copper
# rods, one at 100 C and one at 20 C, joined end to end at t = 0.  kappa = 1.11e-4 m^2/s.
# Roads: the similarity formula 60 - 40 erf(eta) with erf summed by hand; the reduced ODE
# F'' + 2 eta F' = 0 shot by RK4; a grid on both rods that knows no similarity; the PDE
# residual by centred differences.  Nothing imported knows erf or solves an equation.
from math import exp, sqrt, pi, ceil
K, TH, TC, L = 1.11e-4, 100.0, 20.0, 1.0      # copper diffusivity m^2/s, hot, cold C, rod length m
TJ = (TH + TC) / 2                            # the joint, held by symmetry
def erfc(z):                                  # 1 - erf: continued fraction beyond 3, series below
    if z <= 3: return 1 - erf(z)
    c = z
    for k in range(60, 0, -1): c = z + k / 2 / c
    return exp(-z * z) / sqrt(pi) / c
def erf(z):                                   # Maclaurin series, summed to the last term
    if z > 3: return 1 - erfc(z)
    s, term, n = 0.0, z, 0
    while abs(term) > 1e-17 * max(1.0, abs(s)):
        s += term / (2 * n + 1); n += 1; term *= -z * z / n
    return 2 / sqrt(pi) * s
def eta(x, t): return x / (2 * sqrt(K * t))   # the similarity variable
def T(x, t): return TJ - (TJ - TC) * erf(eta(x, t))   # cold rod, x >= 0 m from the joint

def shoot(slope, h=1e-3, top=6.0):            # road 2: RK4 on F' = G, G' = -2 eta G, F(0) = 60
    f, g, e, out = TJ, slope, 0.0, {0.0: TJ}
    for i in range(round(top / h)):
        k1f, k1g = g, -2 * e * g
        k2f, k2g = g + h / 2 * k1g, -2 * (e + h / 2) * (g + h / 2 * k1g)
        k3f, k3g = g + h / 2 * k2g, -2 * (e + h / 2) * (g + h / 2 * k2g)
        k4f, k4g = g + h * k3g, -2 * (e + h) * (g + h * k3g)
        f += h / 6 * (k1f + 2 * k2f + 2 * k3f + k4f); g += h / 6 * (k1g + 2 * k2g + 2 * k3g + k4g)
        e = (i + 1) * h; out[round(e, 6)] = f
    return out
a, b = shoot(-40.0), shoot(-50.0)             # linear ODE: two shots fix the slope that ends at 20 C
s = -40.0 + (TC - a[6.0]) / (b[6.0] - a[6.0]) * (-10.0)
ode = shoot(s)

def grid(h, times, flux=None):                # road 3: explicit steps on [-1, 1] m, insulated ends
    n = round(2 * L / h); r = 0.4             # r = kappa dt / h^2, inside the limit 1/2
    u = [TH if i < n // 2 else TC if i > n // 2 else TJ for i in range(n + 1)]
    if flux: u = [TC] * (n // 2 + 1)          # or: one rod on [0, 1] m, heated at x = 0
    n1 = ceil(times[0] / (r * h * h / K)); dt = times[0] / n1; r = K * dt / (h * h); out, done = [], 0
    for tt in times:
        for _ in range(round(tt / dt) - done):
            g0 = u[1] + 2 * h * flux / 401 if flux else u[1]     # ghost node: the end condition
            u = [u[0] + r * (g0 - 2 * u[0] + u[1])] + [u[i] + r * (u[i - 1] - 2 * u[i] + u[i + 1])
                 for i in range(1, len(u) - 1)] + [u[-1] + 2 * r * (u[-2] - u[-1])]
        out.append(list(u)); done = round(tt / dt)
    return out
def at(u, h, x, flux=None): return u[round(x / h) + (0 if flux else round(L / h))]

print(f"copper, kappa = {K * 1e4:.2f}e-4 m^2/s; hot rod {TH:.0f} C joined to cold rod {TC:.0f} C; each {L:.0f} m long")
print(f"joint at once and for good: ({TH:.0f} + {TC:.0f})/2 = {TJ:.0f} C; cold rod T = 60 - 40 erf(x / (2 sqrt(kappa t)))")
for t in (15, 60, 240): print(f"t = {t:3d} s: 2 sqrt(kappa t) = {200 * sqrt(K * t):.2f} cm")
e5 = eta(0.05, 60)
print(f"at 5 cm, 60 s: eta = {e5:.4f}, erf(eta) = {erf(e5):.4f}, T = 60 - 40 x {erf(e5):.4f} = {T(0.05, 60):.2f} C")
lo, hi = 0.0, 3.0
for _ in range(60): m = (lo + hi) / 2; lo, hi = (m, hi) if erf(m) < 0.9 else (lo, m)
print(f"heat's reach (rise of 4 C, a tenth of 40): erf(eta) = 0.9 at eta = {lo:.4f}; depth {200 * lo * sqrt(K * 60):.1f} cm at 60 s, {200 * lo * sqrt(K * 240):.1f} cm at 240 s")
gap = max(abs(ode[round(0.1 * i, 6)] - (TJ - (TJ - TC) * erf(0.1 * i))) for i in range(31))
print(f"road 2, RK4 shooting: slope F'(0) = {s:.6f} C, by formula -80/sqrt(pi) = {-80 / sqrt(pi):.6f}; largest gap on 0..3 = {gap:.1e} C")
res = []
for d in (1e-3, 5e-4):                       # residual T_t - kappa T_xx at (5 cm, 60 s); dx = d m, dt = 1000 d s
    tt = (T(0.05, 60 + 1000 * d) - T(0.05, 60 - 1000 * d)) / (2000 * d)
    xx = K * (T(0.05 + d, 60) - 2 * T(0.05, 60) + T(0.05 - d, 60)) / d ** 2
    res.append(tt - xx); print(f"road 4, residual at 5 cm, 60 s, dx = {1000 * d:g} mm: T_t = {tt:.6f}, kappa T_xx = {xx:.6f}, gap {tt - xx:.2e} C/s")
errs = []
for h in (0.01, 0.005, 0.0025):
    u15, u60 = grid(h, [15, 60])
    errs.append(abs(at(u60, h, 0.05) - T(0.05, 60)))
    print(f"road 3, grid h = {1000 * h:g} mm: T(5 cm, 60 s) = {at(u60, h, 0.05):.4f} C, error {errs[-1]:.4f}; joint {at(u60, h, 0):.4f} C")
print(f"error ratios as h halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f} (order 2)")
g = grid(0.0025, [15, 60, 240])
trio = [at(g[0], 0.0025, 0.025), at(g[1], 0.0025, 0.05), at(g[2], 0.0025, 0.10)]
print(f"collapse on the grid: T(2.5 cm, 15 s) = {trio[0]:.4f}, T(5 cm, 60 s) = {trio[1]:.4f}, T(10 cm, 240 s) = {trio[2]:.4f} C")
img = (TJ - TC) * erfc((2 * L - 0.10) / (2 * sqrt(K * 240)))
print(f"first omitted image term (insulated far end) at 10 cm, 240 s: {img:.1e} C")
q, f60, f240 = 1e5, *grid(0.0025, [60, 240], flux=1e5)
ex = lambda t: 2 * q * sqrt(K * t / pi) / 401
print(f"flux start, 100 kW/m^2 into a 20 C rod, k = 401 W/(m K): end rises {f60[0] - TC:.2f} C by 60 s, {f240[0] - TC:.2f} C by 240 s; ratio {(f240[0] - TC) / (f60[0] - TC):.3f}")
print(f"  exact end rise 2 q sqrt(kappa t / pi) / k: {ex(60):.2f} and {ex(240):.2f} C")
es = 14.9 / sqrt(3.95e-6); ec = 401 / sqrt(K)
print(f"copper at 100 C on stainless steel at 20 C: effusivities {ec:.0f} and {es:.0f}; joint {(ec * TH + es * TC) / (ec + es):.1f} C")
far = grid(0.01, [3600])[0]
pair = lambda m, x, t: (TJ - TC) * (erfc(eta(2 * m * L - x, t)) - erfc(eta(2 * m * L + x, t)))  # images at +-2mL
fix = T(1.0, 3600) + pair(1, 1.0, 3600) - pair(2, 1.0, 3600)
print(f"breaks, finite rods at 3600 s, far end of cold rod: half-line formula {T(1.0, 3600):.1f} C, with four images {fix:.2f} C, grid {at(far, 0.01, 1.0):.2f} C; first omitted image pair {pair(3, 1.0, 3600):.1e} C")
print(f"mistake, eta without the 2: T(5 cm, 60 s) = {TJ - (TJ - TC) * erf(2 * e5):.2f} C, not {T(0.05, 60):.2f}")
print(f"mistake, twice the distance in twice the time: T(10 cm, 120 s) = {T(0.10, 120):.2f} C, not {T(0.05, 60):.2f}")
print(f"mistake, erf where erfc belongs, 20 + 40 erf(eta): {TC + (TJ - TC) * erf(e5):.2f} C")
for t in (15, 60, 240): print(f"chart, t = {t} s:", ", ".join(f"{T(0.05 * i, t):.1f}" for i in range(11)))
print(f"try, hot rod at 200 C: joint 110 C, T(5 cm, 60 s) = {110 - 90 * erf(e5):.2f} C")
print(f"try, both rods stainless steel: {T(0.05, 60):.2f} C at 5 cm after {60 * K / 3.95e-6:.0f} s = {K / 3.95e-6:.1f} min")
assert abs(s + 80 / sqrt(pi)) < 1e-6 and gap < 1e-6          # ODE shooting meets the erf formula
assert abs(res[1]) < 1e-5 and abs(res[0]) > 3.5 * abs(res[1])  # formula obeys the PDE, gap shrinks as h^2
assert errs[2] < 5e-3 and 3.5 < errs[1] / errs[2] < 4.5        # grid meets the formula at order 2
assert max(trio) - min(trio) < 1e-2 and abs(trio[1] - T(0.05, 60)) < 1e-2   # grid collapses onto eta
assert abs((f240[0] - TC) / (f60[0] - TC) - 2) < 5e-3          # flux start: rise grows as sqrt(t)
assert abs(f60[0] - TC - ex(60)) < 1e-2                        # flux start meets the exact end rise
assert abs(fix - at(far, 0.01, 1.0)) < 0.01 and at(far, 0.01, 1.0) - T(1.0, 3600) > 5   # images fix the finite rod
print("ALL CHECKS PASS")
