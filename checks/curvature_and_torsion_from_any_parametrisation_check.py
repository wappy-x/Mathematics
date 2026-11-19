# Curvature and torsion at any speed -- the check behind the card.  Standard library only.
# A ski run bends right round a hill while dropping: a helix of radius a = 40 m that
# drops c = 9 m per radian.  Skier A passes the apex at 10.25 m/s, speeding up.
# Roads: closed form by arc length; the any-speed formulas on three different
# parametrisations; central differences on 20 Hz positions at two step sizes.
import math

def sub(p, q): return tuple(a - b for a, b in zip(p, q))
def scale(k, p): return tuple(k * a for a in p)
def dot(p, q): return sum(a * b for a, b in zip(p, q))
def cross(p, q): return (p[1]*q[2] - p[2]*q[1], p[2]*q[0] - p[0]*q[2], p[0]*q[1] - p[1]*q[0])
def norm(p): return math.sqrt(dot(p, p))
def vec(p, d=4): return "(" + ", ".join(f"{0.0 if abs(a) < 0.5 * 10 ** -d else a:.{d}f}" for a in p) + ")"

def pos(g, th): return (g[0] * math.cos(th), -g[0] * math.sin(th), -g[1] * th)

def derivs(g, th, d1, d2, d3):
    # chain rule: r(t) = r(theta(t)); d1, d2, d3 are theta's first three time derivatives
    R, C = g
    r1 = (-R * math.sin(th), -R * math.cos(th), -C)
    r2 = (-R * math.cos(th), R * math.sin(th), 0.0)
    r3 = (R * math.sin(th), R * math.cos(th), 0.0)
    v = scale(d1, r1)
    acc = tuple(d2 * a + d1 * d1 * b for a, b in zip(r1, r2))
    jerk = tuple(d3 * a + 3 * d1 * d2 * b + d1 ** 3 * e for a, b, e in zip(r1, r2, r3))
    return v, acc, jerk

def kappa_tau(v, acc, jerk):
    w = cross(v, acc)
    return norm(w) / norm(v) ** 3, dot(w, jerk) / dot(w, w)

def skier(g, v0, a, t):                    # angle turned, and its time derivatives
    L = math.hypot(*g)                     # metres of track per radian of turn
    return (v0 * t + a * t * t / 2) / L, (v0 + a * t) / L, a / L, 0.0

def closed(g): return g[0] / (g[0] ** 2 + g[1] ** 2), g[1] / (g[0] ** 2 + g[1] ** 2)

G = (40.0, 9.0)
K0, T0 = closed(G)
print(f"bend: a = 40 m, drop c = 9 m per radian, a^2 + c^2 = {G[0]**2 + G[1]**2:.0f}, L = {math.hypot(*G):.0f} m per radian")
print(f"road 1, closed form: kappa = {K0:.10f} 1/m, tau = {T0:.10f} 1/m, radius {1/K0:.3f} m, tau/kappa = {T0/K0:.3f}")

V0, A0 = 10.25, 0.82
th, d1, d2, d3 = skier(G, V0, A0, 0.0)
print(f"grade {100 * G[1] / G[0]:.1f}%, skier A at the apex: thetadot = {d1:.2f} rad/s, thetaddot = {d2:.2f} rad/s^2, position {vec(pos(G, th))}")
print(f"thetadot^2 = {d1*d1:.4f}, 3 thetadot thetaddot = {3*d1*d2:.3f}, thetadot^3 = {d1**3:.6f}")
print("angle clock at the apex: r_th, r_thth, r_ththth = " + ", ".join(vec(p) for p in derivs(G, 0.0, 1.0, 0.0, 0.0)))
v, acc, jerk = derivs(G, *skier(G, V0, A0, 0.0))
w = cross(v, acc)
print(f"skier A at t = 0 s: rdot = {vec(v)}, rddot = {vec(acc)}, rdddot = {vec(jerk)}")
print(f"rdot x rddot = {vec(w)}, |rdot x rddot| = {norm(w):.4f}, |rdot|^3 = {norm(v)**3:.6f}")
print(f"det = (rdot x rddot).rdddot = {dot(w, jerk):.6f}, |rdot x rddot|^2 = {dot(w, w):.6f}")
k, t = kappa_tau(v, acc, jerk)
print(f"road 2, any-speed formulas: kappa = {k:.10f} 1/m, tau = {t:.10f} 1/m")
assert abs(k - K0) < 1e-12 and abs(t - T0) < 1e-12
k_wrong = norm(acc) / norm(v) ** 2
t_wrong = dot(w, jerk) / norm(w)
swap = [(p[1], p[0], p[2]) for p in (v, acc, jerk)]   # north, east, up

print("road 3, same track, three clocks: label, time s, speed m/s, kappa, tau")
for label, v0, a, ts in [("A", V0, A0, (-4.0, 4.0, 8.0)), ("B steady", 5.125, 0.0, (0.0, 6.0)), ("angle", 41.0, 0.0, (0.5,))]:
    for tt in ts:
        th, d1, d2, d3 = skier(G, v0, a, tt)
        k, t = kappa_tau(*derivs(G, th, d1, d2, d3))
        print(f"  {label}, t = {tt:.1f}, speed {d1 * 41:.3f}, kappa {k:.10f}, tau {t:.10f}")
        assert abs(k - K0) < 1e-12 and abs(t - T0) < 1e-12

# road 4: positions only, 20 Hz samples, central differences at step h = m * 0.05 s
def track(noise, seed=2026):
    s, out = seed, {}
    for n in range(-40, 41):
        p = pos(G, skier(G, V0, A0, n * 0.05)[0])
        jit = []
        for _ in range(3):                 # SplitMix64, uniform in [-noise, noise]
            s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
            z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
            z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
            jit.append(noise * (2 * ((z ^ (z >> 31)) >> 11) / 2 ** 53 - 1))
        out[n] = tuple(a + b for a, b in zip(p, jit))
    return out

def by_steps(P, m):
    h = 0.05 * m
    v = scale(1 / (2 * h), sub(P[m], P[-m]))
    acc = scale(1 / h ** 2, tuple(a - 2 * b + c for a, b, c in zip(P[m], P[0], P[-m])))
    jerk = scale(1 / (2 * h ** 3), tuple(a - 2 * b + 2 * c - d for a, b, c, d in zip(P[2 * m], P[m], P[-m], P[-2 * m])))
    return v, acc, jerk

P = track(0.0)
for n in (-4, -2, 0, 2, 4):
    print(f"road 4, fix at t = {n * 0.05:.1f} s: {vec(P[n], 8)} m")
errs = []
for m in (2, 1):
    d = by_steps(P, m)
    k, t = kappa_tau(*d)
    errs.append((k - K0, t - T0, norm(sub(d[2], jerk))))   # jerk: skier A's, by the chain rule
    wd = cross(d[0], d[1])
    print(f"road 4, h = {0.05*m:.2f} s: rdot = {vec(d[0])}, rddot = {vec(d[1])}, rdddot = {vec(d[2])}")
    print(f"  rdot x rddot = {vec(wd)}, length {norm(wd):.4f}, |rdot|^3 = {norm(d[0])**3:.4f}, det {dot(wd, d[2]):.6f}, length^2 {dot(wd, wd):.6f}")
    print(f"  kappa {k:.10f} (error {k-K0:.10f}), tau {t:.10f} (error {t-T0:.10f}), jerk off by {errs[-1][2]:.6f}")
rk, rt, rj = (errs[0][j] / errs[1][j] for j in range(3))
print(f"halving h divides the errors by {rk:.3f}, {rt:.3f} and {rj:.3f}")
assert 3.5 < rk < 4.5 and 3.5 < rt < 4.5 and abs(errs[1][1]) < 1e-5
assert 3.5 < rj < 4.5 and errs[1][2] < 1e-3            # the jerk from positions meets the chain-rule jerk

print("what breaks:")
print(f"  |rddot|/|rdot|^2 = {k_wrong:.6f} ({100*(k_wrong/K0-1):+.1f}%), |rddot| = {k_wrong * 10.25**2:.5f} m/s^2")
print(f"  det over |rdot x rddot|, not squared = {t_wrong:.6f} ({t_wrong/T0:.2f} times)")
assert k_wrong / K0 - 1 > 0.01 and t_wrong / T0 > 10
k, t = kappa_tau(*swap)
print(f"  axes swapped to north, east, up: kappa {k:.6f}, tau {t:.6f}")
assert abs(k - K0) < 1e-12 and abs(t + T0) < 1e-12
v, acc, jerk = derivs(G, *skier(G, 0.0, A0, 0.0))
print(f"  skier stopped at t = 0: |rdot x rddot| = {norm(cross(v, acc)):.4f}, |rdot|^3 = {norm(v)**3:.4f}, 0/0")
print("chart, 1 cm GPS jitter at 20 Hz: h in s, kappa, tau")
for m in (1, 2, 4, 8, 16):
    k, t = kappa_tau(*by_steps(track(0.01), m))
    print(f"  h = {0.05*m:.2f}: kappa {k:.6f}, tau {t:.6f}")
    if m == 1:
        assert abs(t - T0) > 0.5 * T0
print("try changing:")
for label, g, a in [("flat bend, c = 0", (40.0, 0.0), A0), ("steep spiral, c = 40", (40.0, 40.0), A0),
                    ("skier braking, -0.82 m/s^2", G, -A0)]:
    k, t = kappa_tau(*derivs(g, *skier(g, V0, a, 2.0)))
    print(f"  {label}: kappa {k:.6f}, tau {t:.6f}")
    assert abs(k - closed(g)[0]) < 1e-12 and abs(t - closed(g)[1]) < 1e-12
print("ALL CHECKS PASS")
