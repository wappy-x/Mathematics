# Convection-diffusion -- the check behind the card.  10 g of dye is dropped into
# water flowing at c = 1 m/s; the cross-section-averaged dye spreads along the pipe
# with effective diffusivity kappa = 0.01 m^2/s.  Road 1 is the heat kernel moved
# with the flow; road 2 is a random walk of 10,000 dye particles (SplitMix64 and
# Box-Muller, written out); road 3 puts the answer back into the PDE by centred
# differences and integrates it by Simpson's rule.  math gives exp, log, sqrt, cos.
from math import exp, log, log10, sqrt, cos, pi

C, KAP, M, L = 1.0, 0.01, 10.0, 100.0                # m/s, m^2/s, grams, metres to the sensor

def u(x, t, c=C, kap=KAP, k=0.0):                    # g per metre of pipe
    return M * exp(-k * t) / sqrt(4 * pi * kap * t) * exp(-(x - c * t) ** 2 / (4 * kap * t))

re = 1.0 * 0.05 / 1e-6; f = 0.316 * re ** -0.25; ustar = sqrt(f / 8)
print(f"pipe: Re = {re:.0f}, Blasius f = {f:.5f}, u* = {ustar:.4f} m/s, Taylor 10.1 a u* = {10.1 * 0.025 * ustar:.4f} m^2/s")
T = L / C; sig = sqrt(2 * KAP * T); peak = u(C * T, T)
print(f"t = {T:.0f} s: centre {C * T:.0f} m, 4 kappa t = {4 * KAP * T:.2f} m^2, width sqrt(2 kappa t) = {sig:.4f} m")
print(f"road 1, peak M / sqrt(4 pi kappa t) = {M:.0f} / {sqrt(4 * pi * KAP * T):.4f} = {peak:.4f} g/m")
print(f"one width off centre, x = {C * T + sig:.4f} m: {u(C * T + sig, T):.4f} g/m = peak x e^(-1/2)")
print(f"half-peak width 2 sqrt(2 ln 2) sigma = {2 * sqrt(2 * log(2)) * sig:.4f} m")

def simpson(g, a, b, n):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n)))
for n in (400, 800):
    m0 = simpson(lambda x: u(x, T), 80, 120, n)
    m1 = simpson(lambda x: x * u(x, T), 80, 120, n) / m0
    m2 = simpson(lambda x: (x - m1) ** 2 * u(x, T), 80, 120, n) / m0
    print(f"road 3, Simpson n = {n}: mass {m0:.6f} g, mean {m1:.6f} m, variance {m2:.6f} m^2")
assert abs(m0 - M) < 1e-6 and abs(m1 - C * T) < 1e-6 and abs(m2 - 2 * KAP * T) < 1e-6

def res(x, t, h, k=0.0, c=C):                        # u_t + c u_x - kappa u_xx + k u
    g = lambda x, t: u(x, t, c, KAP, k)
    ut = (g(x, t + h) - g(x, t - h)) / (2 * h); ux = (g(x + h, t) - g(x - h, t)) / (2 * h)
    uxx = (g(x + h, t) - 2 * g(x, t) + g(x - h, t)) / h ** 2
    return ut + C * ux - KAP * uxx + k * g(x, t)
r1, r2 = res(101, T, 0.02), res(101, T, 0.01)
print(f"road 3, residual at 101 m, 100 s, in 1e-8 g/m/s: h = 0.02 {r1 * 1e8:+.3f}, h = 0.01 {r2 * 1e8:+.3f}, ratio {r1 / r2:.2f}")
assert abs(r1 / r2 - 4) < 0.1 and abs(r2) < 1e-5
rl = res(101, T, 0.01, k=0.01)
print(f"with a leak k = 0.01 /s: peak {u(C * T, T, k=0.01):.4f} g/m = {peak:.4f} x e^(-1), residual {rl * 1e8:+.3f} x 1e-8")
assert abs(rl) < 1e-5
rw = res(0.1, 1.0, 0.001, c=0.0)
print(f"mistake, heat kernel left at the inlet: residual at 0.1 m, 1 s = {rw:+.2f} g/m/s, not 0")
assert abs(rw) > 1

S = [0x2026_1115]                                    # SplitMix64 state, seed 0x20261115
def rnd():
    S[0] = (S[0] + 0x9E3779B97F4A7C15) & (2 ** 64 - 1); z = S[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
N, STEPS, dt = 10000, 50, T / 50; xs = []
for p in range(N):
    x = 0.0
    for s in range(STEPS):
        z = sqrt(-2 * log(1 - rnd())) * cos(2 * pi * rnd())
        x += C * dt + sqrt(2 * KAP * dt) * z
    xs.append(x)
mean = sum(xs) / N; var = sum((x - mean) ** 2 for x in xs) / (N - 1)
inside = sum(1 for x in xs if abs(x - C * T) < sig) / N
print(f"road 2, {N} walkers x {STEPS} steps: mean {mean:.3f} m, variance {var:.3f} m^2, share within one width {inside:.4f}")
assert abs(mean - C * T) < 4 * sig / sqrt(N) and abs(var - sig ** 2) < 4 * sig ** 2 * sqrt(2 / N)
assert abs(inside - 0.6827) < 4 * sqrt(0.6827 * 0.3173 / N)

tp = (-KAP + sqrt(KAP ** 2 + C ** 2 * L ** 2)) / C ** 2
a, b = 95.0, 105.0; g = (sqrt(5) - 1) / 2
for _ in range(100):
    p, q = b - g * (b - a), a + g * (b - a)
    if u(L, p) > u(L, q): b = q
    else: a = p
print(f"sensor at {L:.0f} m: peak passes at {tp:.6f} s by formula, {(a + b) / 2:.6f} s by search, {u(L, tp):.4f} g/m")
assert abs((a + b) / 2 - tp) < 1e-5
def cross(lo, hi):                                   # bisection for u(L, t) = half the peak
    up = u(L, lo) < u(L, hi)
    for _ in range(80):
        m = (lo + hi) / 2
        if (u(L, m) < u(L, tp) / 2) == up: lo = m
        else: hi = m
    return m
t1, t2 = cross(90, tp), cross(tp, 110)
print(f"sensor above half its peak from {t1:.4f} s to {t2:.4f} s: {t2 - t1:.4f} s")
assert abs((t2 - t1) - 2 * sqrt(2 * log(2)) * sig / C) < 0.01
print(f"Peclet c L / kappa at {L:.0f} m = {C * L / KAP:.0f}, at 0.02 m = {C * 0.02 / KAP:.0f}; drift time {L / C:.0f} s, spreading time L^2/kappa = {L * L / KAP:.0f} s = {L * L / KAP / 86400:.2f} days")
tx = 2 * KAP / C ** 2
print(f"drift c t equals width sqrt(2 kappa t) at t = 2 kappa / c^2 = {tx:.2f} s, both {C * tx:.2f} m")
for ts in ("0.005", "0.02", "1", "25", "100"):
    t = float(ts); print(f"race, t = {ts} s: drift {C * t:.4f} m, width {sqrt(2 * KAP * t):.4f} m, ratio {C * t / sqrt(2 * KAP * t):.2f}")
print(f"mistake, no drift: at {L:.0f} m, {T:.0f} s, log10 u = {log10(M / sqrt(4 * pi * KAP * T)) - L * L / (4 * KAP * T) / log(10):.2f}")
print(f"mistake, molecular diffusivity 1e-9 m^2/s: width {sqrt(2e-9 * T) * 1000:.4f} mm, peak {u(L, T, kap=1e-9):.1f} g/m")
print(f"mistake, variance 4 kappa t: width {sqrt(4 * KAP * T):.4f} m, not {sig:.4f} m")
print(f"mistake, shift x + c t: centre at {-C * T:.0f} m, upstream of the inlet")
print(f"instant reach: 1 m upstream after 1 s, u = {u(-1, 1):.2e} g/m")
print(f"bond reading at r = 4%: drift 0.3(0.05 - 0.04) = {0.3 * 0.01:.3f}, spreading 0.01^2/2 = {0.01 ** 2 / 2:.5f}, leak r = {0.04:.2f}, per year")
for t in (25, 50, 100):
    print(f"chart, moving frame, t = {t} s: " + ", ".join(f"{u(C * t + z / 2, t):.2f}" for z in range(-8, 9)))
print("chart, sensor at 100 m, t = 96..104 s: " + ", ".join(f"{u(L, 96 + i / 2):.2f}" for i in range(17)))
print("ALL CHECKS PASS")
