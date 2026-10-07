# Limit cycles and van der Pol -- the check behind the card.  Only math is imported; RK4 is
# written out.  Road one: the polar model against its closed form.  Road two: van der Pol
# settled from two starts, then its loop found again by a return map and bisection.
import math
S = 0.12                                   # seconds of heartbeat per model time unit
def rk4(f, p, h):
    k1 = f(p); k2 = f([p[i] + h / 2 * k1[i] for i in (0, 1)])
    k3 = f([p[i] + h / 2 * k2[i] for i in (0, 1)]); k4 = f([p[i] + h * k3[i] for i in (0, 1)])
    return [p[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)]
polar = lambda p: [p[0] * (1 - p[0] ** 2 - p[1] ** 2) - p[1], p[1] * (1 - p[0] ** 2 - p[1] ** 2) + p[0]]
vdp = lambda mu: lambda p: [p[1], mu * (1 - p[0] ** 2) * p[1] - p[0]]   # x' = v, v' = mu(1-x^2)v - x
def run(f, p, t, h=0.001):                 # step from p for time t, keeping the path
    path = [p]
    for _ in range(round(t / h)): path.append(rk4(f, path[-1], h))
    return path
def lap(f, p, mu=1.0, h=0.001):            # step until v turns from + to -; return x there,
    t, div = 0.0, 0.0                      # the time taken, and the integral of mu(1 - x^2)
    while True:
        q = rk4(f, p, h); t += h
        if p[1] > 0 >= q[1]:               # Newton on the last part-step lands v on 0
            s = 0.0
            for _ in range(4): s -= rk4(f, p, s)[1] / f(rk4(f, p, s))[1]
            r = rk4(f, p, s)
            return r[0], t - h + s, div + s * mu * (1 - (p[0] ** 2 + r[0] ** 2) / 2)
        div += h * mu * (1 - (p[0] ** 2 + q[0] ** 2) / 2); p = q

closed = lambda r0, t: 1 / math.sqrt(1 + (1 / r0 ** 2 - 1) * math.exp(-2 * t))
err = [abs(math.hypot(*run(polar, [0.1, 0.0], 5, h)[-1]) - closed(0.1, 5)) for h in (0.1, 0.05)]
print(f"polar model at t = 5, from r0 = 0.1: 99 x e^-10 = 99 x {math.exp(-10):.3e} = {99 * math.exp(-10):.6f}, r = {closed(0.1, 5):.5f}; from r0 = 2: r = {closed(2, 5):.6f}")
print(f"RK4 error at h = 0.1 and 0.05: {err[0]:.2e}, {err[1]:.2e}; ratio {err[0] / err[1]:.1f} (fourth order: 16)")
d = 1e-6; J = [[vdp(1.0)([d * (j == 0), d * (j == 1)])[i] / d for j in (0, 1)] for i in (0, 1)]
tr, det = J[0][0] + J[1][1], J[0][0] * J[1][1] - J[0][1] * J[1][0]
print(f"van der Pol origin: trace {tr:.3f}, det {det:.3f}, eigenvalues {tr / 2:.3f} +/- {math.sqrt(det - tr * tr / 4):.3f}i")
paths, got = {}, []
for s in (0.1, 4.0):
    paths[s] = run(vdp(1.0), [s, 0.0], 60)
    got.append(lap(vdp(1.0), [lap(vdp(1.0), paths[s][-1])[0], 0.0]))
    print(f"start ({s}, 0), after t = 60: amplitude {got[-1][0]:.4f}, period {got[-1][1]:.4f}")
lo, hi = 1.0, 3.0                          # road two: the x the return map sends to itself
for _ in range(40):
    lo, hi = ((lo + hi) / 2, hi) if lap(vdp(1.0), [(lo + hi) / 2, 0.0])[0] > (lo + hi) / 2 else (lo, (lo + hi) / 2)
a, T, div = lap(vdp(1.0), [lo, 0.0])
slope = (lap(vdp(1.0), [a + 1e-3, 0.0])[0] - lap(vdp(1.0), [a - 1e-3, 0.0])[0]) / 2e-3
print(f"return map fixed point by bisection: amplitude {a:.4f}, period {T:.4f}; x {S} s = {T * S:.3f} s, {60 / (T * S):.1f} beats/min")
print(f"pull per lap: exp(integral) = {math.exp(div):.3e}, return-map slope = {slope:.3e}; polar exp(-4 pi) = {math.exp(-4 * math.pi):.2e}")
amp0 = [lap(vdp(0.0), run(vdp(0.0), [s, 0.0], 60)[-1], mu=0.0)[0] for s in (0.1, 4.0)]
lin = run(lambda p: [p[1], p[1] - p[0]], [0.1, 0.0], 20)
print(f"mistake 1, mu = 0: amplitudes stay {amp0[0]:.4f} and {amp0[1]:.4f}; every circle is a loop")
print(f"mistake 2, linearised law from (0.1, 0): largest |x| by t = 20 is {max(abs(p[0]) for p in lin):.0f}, not 2")
print(f"mistake 3, period taken as 2 pi = {2 * math.pi:.4f}: {100 * (1 - 2 * math.pi / T):.1f}% short, {60 / (2 * math.pi * S):.1f} beats/min")
X = lambda x: 120 + 34 * x; Y = lambda v: 120 - 34 * v
print(f"figure, 34 px per unit; origin ({X(0):.0f}, {Y(0):.0f}); x = 4 at {X(4):.0f}; x = {a:.4f} at {X(a):.1f}")
for s, n, k in ((0.1, 16, 400), (4.0, 7, 250)):
    print(f"figure, start {s}:", " ".join(f"{X(p[0]):.1f},{Y(p[1]):.1f}" for p in paths[s][:n * 1000 + 1:k]))
print("figure, loop:", " ".join(f"{X(p[0]):.1f},{Y(p[1]):.1f}" for p in run(vdp(1.0), [a, 0.0], T, T / 24000)[:-1:1000]))
assert err[1] < 1e-6 and 12 < err[0] / err[1] < 20                   # RK4 meets the closed form at order 4
assert all(abs(g[0] - a) < 1e-4 and abs(g[1] - T) < 1e-3 for g in got)  # settling agrees with bisection
assert abs(math.exp(div) / slope - 1) < 1e-3 and slope < 1            # two measures of the pull agree
assert abs(tr - 1) < 1e-6 and abs(det - 1) < 1e-6 and abs(amp0[1] - 4) < 1e-4
print("ALL CHECKS PASS")
