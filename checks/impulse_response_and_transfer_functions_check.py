# Transfer functions -- the check behind the card.  Standard library only.
# The plant is a car on cruise control: m dv/dt = u - b v, with the drag
# c v^2 linearised about 25 m/s.  Its transfer function is G(s) = 1/(m s + b).
# Roads: the formula; an RK4 simulation of the equation; a numerical Laplace
# transform (Simpson) of the impulse response; residues at the poles.
import math

M, C, V0 = 1000.0, 0.5, 25.0                # mass kg, drag N s^2/m^2, cruise m/s
B = 2 * C * V0                               # linearised drag, N s/m
TAU, DT = M / B, 0.01                        # time constant s, RK4 step s
J, TE = 500.0, 0.5                           # the shove N s, engine lag s

def G(s):                                    # the transfer function, (m/s)/N
    return 1.0 / (M * s + B)

def h(t):                                    # impulse response: residue at s = -b/m
    return math.exp(-B * t / M) / M

def run(f, x, t0, n):                        # RK4 on dx/dt = f(t, x); keeps every state
    out = [x]
    for i in range(n):
        t = t0 + i * DT
        k1 = f(t, x)
        k2 = f(t + DT / 2, [a + DT / 2 * k for a, k in zip(x, k1)])
        k3 = f(t + DT / 2, [a + DT / 2 * k for a, k in zip(x, k2)])
        k4 = f(t + DT, [a + DT * k for a, k in zip(x, k3)])
        x = [a + DT / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(x, k1, k2, k3, k4)]
        out.append(x)
    return out

def car(u):                                  # the linear car pushed by the force u(t)
    return lambda t, x: [(u(t) - B * x[0]) / M]

def steps(t):
    return round(t / DT)

def push(force, width, t_end):               # constant force for width s, then coast
    on = run(car(lambda t: force), [0.0], 0.0, steps(width))
    off = run(car(lambda t: 0.0), on[-1], width, steps(t_end - width))
    return [x[0] for x in on + off[1:]]

def simpson(ys, dx):                         # composite Simpson's rule, odd point count
    return dx / 3 * (ys[0] + ys[-1] + 4 * sum(ys[1:-1:2]) + 2 * sum(ys[2:-1:2]))

def laplace_of_h(s, t_end=1000.0, dx=0.05):  # integral of h(t) e^(-s t) dt, numerically
    n = round(t_end / dx)
    return simpson([h(k * dx) * math.exp(-s * k * dx) for k in range(n + 1)], dx)

def drive_ratio(s, t_end=800.0):             # feed u = e^(s t) from rest; output / input
    v = run(car(lambda t: math.exp(s * t)), [0.0], 0.0, steps(t_end))[-1][0]
    return v / math.exp(s * t_end)

print(f"car: m = {M:.0f} kg, c = {C} N s^2/m^2, cruising at v0 = {V0:.0f} m/s")
print(f"linearised drag b = 2 c v0 = {B:.0f} N s/m; cruise force c v0^2 = {C * V0 * V0:.1f} N")
print(f"G(s) = 1/({M:.0f} s + {B:.0f}) (m/s)/N; pole s = {-B / M:.3f} 1/s; time constant {TAU:.0f} s")
print("G(s) three ways, (m/s)/N: formula | transform of h, Simpson to 1000 s | e^(st) drive, RK4 to 800 s")
rows = []
for s in (0.0, 0.025, 0.05, 0.1):
    rows.append((G(s), laplace_of_h(s), drive_ratio(s)))
    print(f"s = {s:.3f} 1/s: {rows[-1][0]:.7f} | {rows[-1][1]:.7f} | {rows[-1][2]:.7f}")
print(f"impulse response h(t) = (1/m) e^(-t/{TAU:.0f} s); h(0+) = {h(0.0):.3f} (m/s) per N s")
short, slow = push(1000.0, 0.5, 120.0), push(12.5, 40.0, 120.0)
print(f"{J:.0f} N s shove, speed gained (m/s): t | ideal impulse | 1000 N for 0.5 s | 12.5 N for 40 s")
times = list(range(0, 121, 10))
for t in times:
    print(f"t = {t:3d} s: {J * h(t):.3f} | {short[steps(t)]:.3f} | {slow[steps(t)]:.3f}")
print("figure, chart ideal:", " ".join(f"{J * h(t):.2f}" for t in times))
print("figure, chart 40 s push:", " ".join(f"{slow[steps(t)]:.2f}" for t in times))
step = [x[0] for x in run(car(lambda t: 100.0), [0.0], 0.0, steps(160.0))]
print("100 N extra thrust, speed gained (m/s): t | partial fractions | RK4 | convolution h*u")
stepped = []
for t in (20, 40, 80, 160):
    pf = 100.0 / B * (1.0 - math.exp(-t / TAU))
    conv = simpson([100.0 * h(k * 0.05) for k in range(round(t / 0.05) + 1)], 0.05)
    stepped.append((pf, step[steps(t)], conv))
    print(f"t = {t:3d} s: {pf:.4f} | {step[steps(t)]:.4f} | {conv:.4f}")
p1, p2 = -B / M, -1.0 / TE                   # engine lag 1/(TE s + 1) in series
r1, r2 = 1.0 / ((TE * p1 + 1.0) * M), 1.0 / (TE * (M * p2 + B))
lag = lambda r: (lambda t, x: [(r(t) - x[0]) / TE, (x[0] - B * x[1]) / M])
g2 = G(0.05) / (TE * 0.05 + 1.0)
d2 = run(lag(lambda t: math.exp(0.05 * t)), [0.0, 0.0], 0.0, steps(800.0))[-1][1] / math.exp(40.0)
print(f"engine lag {TE} s in series: G_total(0.05) = {g2:.7f} by product, {d2:.7f} by e^(st) drive")
print(f"residues: h2(t) = {r1:.8f} e^({p1:.3f} t) + ({r2:.8f}) e^({p2:.0f} t); h2(0+) = {abs(r1 + r2):.6f}")
kick = run(lag(lambda t: 0.0), [J / TE, 0.0], 0.0, steps(40.0))
for t in (1, 10, 40):
    print(f"{J:.0f} N s through the engine, t = {t:2d} s: residues {J * (r1 * math.exp(p1 * t) + r2 * math.exp(p2 * t)):.5f} m/s | RK4 {kick[steps(t)][1]:.5f} m/s")
print(f"mistake 1, shove spread over 40 s: peak {max(slow):.3f} m/s, not {J * h(0.0):.3f} m/s")
warm = [x[0] for x in run(car(lambda t: 100.0), [1.0], 0.0, steps(800.0))]
vs = simpson([v * math.exp(-0.05 * k * DT) for k, v in enumerate(warm)], DT)
print(f"mistake 2, car already 1 m/s fast: V/U at s = 0.05 is {vs / (100.0 / 0.05):.4f}, not G = {G(0.05):.4f}")
print(f"mistake 3, mass dropped, G = 1/(s + {B / M:.3f}): steady gain {1.0 / (B / M):.0f} (m/s)/N, not {G(0.0):.2f}")
far = []
for df in (100.0, 1000.0):
    sq = lambda t, x: [(C * V0 * V0 + df - C * x[0] * x[0]) / M]
    far.append((df / B, math.sqrt(V0 * V0 + df / C) - V0, run(sq, [V0], 0.0, steps(600.0))[-1][0] - V0))
    print(f"{'mistake 4, ' if df > 500 else 'in range, '}{df:.0f} N step: linear +{far[-1][0]:.3f} m/s, "
          f"drag-squared car +{far[-1][1]:.3f} m/s (RK4 at 600 s: +{far[-1][2]:.3f})")
for g, lap, drv in rows:                     # transform of h, and the e^(st) drive, both give G
    assert abs(lap - g) < 1e-6 * g and abs(drv - g) < 1e-6 * g
assert all(abs(short[steps(t)] - J * h(t)) < 0.01 * J * h(t) for t in times[1:])
assert abs(max(slow) - 12.5 / B * (1.0 - math.exp(-40.0 / TAU))) < 1e-6   # 40 s push peak, closed form
assert all(abs(rk - pf) < 1e-6 and abs(cv - pf) < 1e-6 for pf, rk, cv in stepped)
assert abs(d2 - g2) < 1e-6 * g2
assert all(abs(kick[steps(t)][1] - J * (r1 * math.exp(p1 * t) + r2 * math.exp(p2 * t))) < 1e-6 for t in (1, 10, 40))
assert all(abs(rk - exact) < 1e-6 for _, exact, rk in far) and abs(vs - (2000.0 + M * 1.0) * G(0.05)) < 1e-4
print("ALL CHECKS PASS")
