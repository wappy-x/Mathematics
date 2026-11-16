# Solitons: a 10 ps pulse in optical fibre, and two KdV humps that pass through each other.
# Roads: the closed-form soliton and its residual; a split-step Crank-Nicolson grid; the
# Zakharov-Shabat eigenvalue problem by RK4 shooting; for KdV, the exact two-soliton formula,
# its residual, and the bound states of its Schrodinger problem by shooting.
from math import cosh, sqrt, log, acosh, floor, log10
from cmath import exp as cexp
B2, GAM, T0 = 20.0, 1.3, 10.0         # |beta2| ps^2/km (anomalous), gamma 1/(W km), T0 ps: illustrative
LD = T0 * T0 / B2                     # dispersion length, km
P0 = B2 / (GAM * T0 * T0)             # soliton peak power, W
def sci(x):                           # e-notation with the same digits in Python and Rust
    e = floor(log10(abs(x))); m = round(x / 10 ** e, 2)
    return f"{m:.2f}e{e:+03d}"
def sech(x): return 1 / cosh(x)
def cn_step(u, h, dz, s):             # Crank-Nicolson for i u_z + (s/2) u_tt = 0, zero at both ends
    n, r = len(u), 1j * s * dz / (4 * h * h)
    d = [u[j] + r * ((u[j-1] if j else 0) - 2 * u[j] + (u[j+1] if j < n - 1 else 0)) for j in range(n)]
    a, b = -r, 1 + 2 * r              # Thomas algorithm, written out
    cp, dp = [a / b] + [0j] * (n - 1), [d[0] / b] + [0j] * (n - 1)
    for j in range(1, n):
        m = b - a * cp[j-1]; cp[j] = a / m; dp[j] = (d[j] - a * dp[j-1]) / m
    for j in range(n - 2, -1, -1): dp[j] -= cp[j] * dp[j+1]
    return dp
def evolve(u, h, dz, steps, s=1, g=1.0):   # Strang splitting: half Kerr phase, dispersion, half Kerr phase
    kerr = lambda u: [v * cexp(0.5j * g * abs(v) ** 2 * dz) for v in u]
    for _ in range(steps): u = kerr(cn_step(kerr(u), h, dz, s))
    return u
def fwhm(xs, p):                      # full width at half maximum, interpolated on the right side
    j0 = max(range(len(p)), key=lambda j: p[j]); half = p[j0] / 2; j = j0
    while p[j+1] > half: j += 1
    return 2 * (xs[j] + (p[j] - half) / (p[j] - p[j+1]) * (xs[j+1] - xs[j]) - xs[j0])
def zs_a(q, h, zeta):                 # Zakharov-Shabat: w1' = q w2, w2' = 2i zeta w2 - conj(q) w1, RK4
    w1, w2 = 1 + 0j, 0j               # q sampled at spacing h; one RK4 step spans 2h
    f = lambda qq, a, b: (qq * b, 2j * zeta * b - qq.conjugate() * a)
    for j in range(0, len(q) - 2, 2):
        H = 2 * h; k1 = f(q[j], w1, w2); k2 = f(q[j+1], w1 + H/2 * k1[0], w2 + H/2 * k1[1])
        k3 = f(q[j+1], w1 + H/2 * k2[0], w2 + H/2 * k2[1]); k4 = f(q[j+2], w1 + H * k3[0], w2 + H * k3[1])
        w1 += H / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]); w2 += H / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return w1
def eigen(q, h, guess):               # secant search for a(zeta) = 0 on the imaginary axis
    z0, z1 = guess, guess + 0.01j; f0, f1 = zs_a(q, h, z0), zs_a(q, h, z1)
    for _ in range(40):
        if abs(z1 - z0) < 1e-12: break
        z0, f0, z1 = z1, f1, z1 - f1 * (z1 - z0) / (f1 - f0); f1 = zs_a(q, h, z1)
    return z1.imag
L, h, dz = 60.0, 0.05, 0.02; xs = [-L + j * h for j in range(2401)]   # tau = t/T0 on [-60, 60]; Z step 0.02
print(f"fibre: |beta2| = {B2:.1f} ps^2/km, gamma = {GAM:.1f} /(W km), T0 = {T0:.1f} ps (illustrative)")
print(f"L_D = T0^2/|beta2| = {LD:.3f} km; soliton peak power P0 = {P0*1e3:.2f} mW; FWHM = {2*acosh(sqrt(2)):.4f} T0 = {2*acosh(sqrt(2))*T0:.3f} ps")
print(f"pulse energy 2 P0 T0 = {2*P0*T0:.4f} pJ; soliton phase turns {1/(2*LD):.3f} rad/km")
print(f"Kerr phase at the peak over 50 km: gamma P0 x 50 km = {GAM*P0*50:.3f} rad; loss of 0.2 dB/km halves power every {10*log10(2)/0.2:.2f} km")
res = []                              # road 1: the closed form in the equation, centred differences
for d in (0.01, 0.005):
    U, t, z = lambda t, z: sech(t) * cexp(0.5j * z), 0.7, 0.3
    uz = (U(t, z + d) - U(t, z - d)) / (2 * d); utt = (U(t + d, z) - 2 * U(t, z) + U(t - d, z)) / (d * d)
    res.append(abs(1j * uz + 0.5 * utt + abs(U(t, z)) ** 2 * U(t, z)))
print(f"NLS residual of sech(tau) e^(i z/2): {sci(res[0])} at step 0.01, {sci(res[1])} at 0.005, ratio {res[0]/res[1]:.2f}")
assert 3.9 < res[0] / res[1] < 4.1, "the closed form solves NLS"
errs = []                             # road 2: the grid, at two steps, against the closed form at 1 L_D
for hh, dd in ((0.1, 0.02), (0.05, 0.01)):
    g = [-20 + j * hh for j in range(int(round(40 / hh)) + 1)]
    u = evolve([complex(sech(x)) for x in g], hh, dd, int(round(1 / dd)))
    errs.append(max(abs(v - sech(x) * cexp(0.5j)) for v, x in zip(u, g)))
print(f"grid error at 5 km: {sci(errs[0])} at step 0.1, {sci(errs[1])} at 0.05, ratio {errs[0]/errs[1]:.2f}")
assert 3.8 < errs[0] / errs[1] < 4.2, "grid converges at second order"
start = [complex(sech(x)) for x in xs]
runs = {"soliton": evolve(start, h, dz, 500), "low power": evolve(start, h, dz, 500, g=0.0),
        "normal dispersion": evolve(start, h, dz, 500, s=-1)}
gau = evolve([complex(cexp(-x * x / 2)) for x in xs], h, dz, 500, g=0.0)
rms = sqrt(sum(x * x * abs(v) ** 2 for x, v in zip(xs, gau)) / sum(abs(v) ** 2 for v in gau))
print(f"check on the grid: Gaussian at low power, 50 km: rms width {rms:.5f} T0, formula {sqrt(101/2):.5f} T0")
assert abs(rms - sqrt(101 / 2)) < 1e-3 * rms, "linear spreading matches the closed form"
print(f"at 50 km (10 L_D), launched as a 17.627 ps sech pulse; grid steps {h*T0:.1f} ps and {dz*LD:.1f} km:")
for k, u in runs.items():
    p = [abs(v) ** 2 for v in u]
    print(f"  {k:17s}: peak {max(p):.4f} of start, FWHM {fwhm(xs, p)*T0:7.3f} ps, energy {h * sum(abs(v) ** 2 for v in u):.6f} (start 2)")
sol = runs["soliton"]
dev = max(abs(abs(v) - sech(x)) for v, x in zip(sol, xs))
print(f"  soliton: largest gap from the launched shape {dev:.5f}")
assert dev < 0.01 and abs(h * sum(abs(v) ** 2 for v in sol) - 2) < 1e-9, "the soliton holds its shape and energy"
eta = eigen(start, h, 0.45j); eta50 = eigen(sol, h, 0.45j)          # road 3: the hidden eigenvalue
print(f"Zakharov-Shabat eigenvalue of the soliton: {eta:.6f} at 0 km, {eta50:.6f} at 50 km; amplitude 2 eta = {2*eta:.6f}")
assert abs(eta - 0.5) < 1e-4 and abs(eta50 - 0.5) < 1e-3, "one bound state, amplitude 1"
for N in (1.2, 0.8):                  # launch at the wrong power: N^2 times P0
    q0 = [complex(N * sech(x)) for x in xs]; q50 = evolve(q0, h, dz, 500)
    e0, e50 = eigen(q0, h, (N - 0.55) * 1j), eigen(q50, h, (N - 0.55) * 1j)
    print(f"N = {N}: launch {N*N*P0*1e3:.2f} mW; eta {e0:.5f} at 0 km, {e50:.5f} at 50 km (N - 1/2 = {N-0.5:.1f})")
    print(f"   settles to peak {4*e0*e0*P0*1e3:.2f} mW, FWHM {2*acosh(sqrt(2))*T0/(2*e0):.3f} ps; keeps {4*e0/(2*N*N)*100:.2f}% of the energy")
    assert abs(e0 - (N - 0.5)) < 1e-4 and abs(e50 - e0) < 1e-3, "eigenvalue fixed, at N - 1/2"
a04 = [zs_a([complex(0.4 * sech(x)) for x in xs], h, 1j * k / 100).real for k in range(1, 201)]
print(f"N = 0.4 ({0.16*P0*1e3:.2f} mW): a(i eta) for eta = 0.01..2 stays between {min(a04):.4f} and {max(a04):.4f}: no bound state, no soliton")
assert min(a04) > 0, "below N = 1/2 nothing binds"
for k, u in runs.items():             # chart points: % of the launch peak at t = -60..60 ps
    print(f"chart 50 km {k}, t=-60..60 ps: " + ", ".join(f"{abs(u[1200 + 20 * m]) ** 2 * 100:.1f}" for m in range(-6, 7)))
two = [eigen([complex(2 * sech(x)) for x in xs], h, g) for g in (0.45j, 1.45j)]
print(f"try: N = 2 ({4*P0*1e3:.2f} mW) has eta = {two[0]:.5f} and {two[1]:.5f}; it breathes with period pi/2 L_D = {3.141592653589793/2*LD:.3f} km")
print(f"try: T0 = 5 ps needs P0 = {B2/(GAM*25)*1e3:.2f} mW, L_D = {25/B2:.3f} km; |beta2| = 40 ps^2/km needs P0 = {40/(GAM*T0*T0)*1e3:.2f} mW")
fw = 2 * acosh(sqrt(2))               # mistake: the FWHM, 17.627 ps, put in place of T0
print(f"FWHM used as T0: launch {P0/fw**2*1e3:.2f} mW, N = {1/fw:.4f}, eta = {1/fw-0.5:.4f}, settles to FWHM {fw*T0/(2*(1/fw-0.5)):.1f} ps")
def kdv2(x, t):                       # scaled KdV w_t + 6 w w_x + w_xxx = 0, two solitons kappa = 1, 2
    num = 3 + 4 * cosh(2 * x - 8 * t) + cosh(4 * x - 64 * t)
    return 12 * num / (3 * cosh(x - 28 * t) + cosh(3 * x - 36 * t)) ** 2
res = []                              # KdV road 1: the formula in the equation
for d in (0.004, 0.002):              # time step d/8: the tall hump changes 8 times faster
    x, t, f, e = 0.3, 0.02, kdv2, d / 8
    ut = (f(x, t + e) - f(x, t - e)) / (2 * e); ux = (f(x + d, t) - f(x - d, t)) / (2 * d)
    uxxx = (f(x + 2 * d, t) - 2 * f(x + d, t) + 2 * f(x - d, t) - f(x - 2 * d, t)) / (2 * d ** 3)
    res.append(abs(ut + 6 * f(x, t) * ux + uxxx))
print(f"KdV residual of the two-soliton formula: {sci(res[0])} at step 0.004, {sci(res[1])} at 0.002, ratio {res[0]/res[1]:.2f}")
assert 3.9 < res[0] / res[1] < 4.1, "the two-soliton formula solves KdV"
def bound(t, k):                      # -psi'' - w psi = -k^2 psi; y = psi e^(-k x); y'' = -2k y' - w y, RK4
    y, v, H = 1.0, 0.0, 0.01
    for j in range(4000):
        x = -20 + 16 * t + j * H; f = lambda x, y, v: (v, -2 * k * v - kdv2(x, t) * y)
        a1 = f(x, y, v); a2 = f(x + H/2, y + H/2 * a1[0], v + H/2 * a1[1])
        a3 = f(x + H/2, y + H/2 * a2[0], v + H/2 * a2[1]); a4 = f(x + H, y + H * a3[0], v + H * a3[1])
        y += H / 6 * (a1[0] + 2 * a2[0] + 2 * a3[0] + a4[0]); v += H / 6 * (a1[1] + 2 * a2[1] + 2 * a3[1] + a4[1])
    return y
def bisect(t, lo, hi):
    for _ in range(40):               # keep the half where w(L) changes sign
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if (bound(t, lo) > 0) == (bound(t, mid) > 0) else (lo, mid)
    return (lo + hi) / 2
for t in (0.0, 0.5):
    k1, k2 = bisect(t, 0.5, 1.5), bisect(t, 1.5, 2.5)
    print(f"KdV t = {t}: kappa = {k1:.6f}, {k2:.6f}; heights 2 kappa^2 = {2*k1*k1:.4f}, {2*k2*k2:.4f}; speeds 4 kappa^2 = {4*k1*k1:.4f}, {4*k2*k2:.4f}")
    assert abs(k1 - 1) < 1e-5 and abs(k2 - 2) < 1e-5, "eigenvalues fixed"
def peak(t, lo, hi, g=(sqrt(5) - 1) / 2):    # golden-section search for a local maximum
    for _ in range(80):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo); lo, hi = (lo, b) if kdv2(a, t) > kdv2(b, t) else (a, hi)
    return (lo + hi) / 2
for t in (-1.0, 1.0):
    xt, xs_ = peak(t, 16 * t - 3, 16 * t + 3), peak(t, 4 * t - 3, 4 * t + 3)
    print(f"KdV t = {t:+.0f}: tall hump {kdv2(xt, t):.4f} at x = {xt:.4f}; short hump {kdv2(xs_, t):.4f} at x = {xs_:.4f}")
shift_t, shift_s = 2 * (peak(1, 13, 19) - 16), 2 * (peak(1, 1, 7) - 4)
print(f"shift through the collision: tall {shift_t:+.4f} (ln 3 / 2 = {log(3)/2:.4f}), short {shift_s:+.4f} (-ln 3 = {-log(3):.4f})")
assert abs(shift_t - log(3) / 2) < 1e-4 and abs(shift_s + log(3)) < 1e-4, "phase shifts"
for t in (-0.5, 0.0, 0.5):
    print(f"chart KdV t = {t:+.1f}, x = -10..10 step 0.5: " + ", ".join(f"{kdv2(-10 + 0.5 * j, t):.2f}" for j in range(41)))
mass = [0.01 * sum(kdv2(-30 + 0.01 * j, t) for j in range(6001)) for t in (0.0, 1.0)]
print(f"KdV mass at t = 0 and 1: {mass[0]:.6f}, {mass[1]:.6f} (4 x (1 + 2) = 12)")
assert abs(mass[0] - 12) < 1e-6 and abs(mass[1] - 12) < 1e-6, "mass conserved"
print("ALL CHECKS PASS")
