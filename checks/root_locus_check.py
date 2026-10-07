# Root locus: a room thermostat whose gain runs from 0 to 20. Standard library only.
# Roads: (1) the sketching rules in closed form; (2) a Durand-Kerner root finder swept with bisection;
# (3) RK4 simulation read back as ring period and swing ratio; (4) Evans's angle and magnitude conditions.
import math, cmath

T1, T2, T3 = 2.0, 4.0, 10.0          # time constants in min: pipe, radiator, room air
G0 = 10.0                            # room rise per kW of heat, degC per kW (loss 100 W per degC)
P = [-1 / T1, -1 / T2, -1 / T3]      # open-loop poles, 1/min
A3, A2, A1 = T1 * T2 * T3, T1 * T2 + T1 * T3 + T2 * T3, T1 + T2 + T3   # D(s) = 80 s^3 + 68 s^2 + 16 s + 1

def D(s):                            # (T1 s + 1)(T2 s + 1)(T3 s + 1), the characteristic part
    return ((A3 * s + A2) * s + A1) * s + 1.0

def roots(K):                        # roots of D(s) + K = 0 by Durand-Kerner: real pole first, then the pair
    c = [A2 / A3, A1 / A3, (1.0 + K) / A3]
    r = [complex(0.4, 0.9) ** i for i in range(3)]
    for _ in range(300):
        new = []
        for i in range(3):
            den = complex(1.0, 0.0)
            for j in range(3):
                if j != i:
                    den *= r[i] - r[j]
            new.append(r[i] - (((r[i] + c[0]) * r[i] + c[1]) * r[i] + c[2]) / den)
        r = new
    r.sort(key=lambda z: z.real)
    return [complex(r[0].real, 0.0)] + sorted(r[1:], key=lambda z: z.imag)

def bisect(f, lo, hi, n=100):        # f changes sign from negative at lo to positive at hi
    for _ in range(n):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return (lo + hi) / 2
def angle_sum(s):                    # angles from each open-loop pole to the point s, in degrees
    return sum(math.degrees(cmath.phase(s - p)) for p in P)

def simulate(K, T, dt=0.01, delay=False):   # room's response to a 1 degC setpoint step
    kc, nd = K / G0, int(round(T1 / dt))    # thermostat gain in kW per degC; delay in steps
    x, err, out = [0.0, 0.0, 0.0], [], [0.0]
    def f(x, u):                     # delay=True: the pipe is a pure 2-min delay, not a lag
        return [(G0 * u - x[0]) / T1, ((G0 * u if delay else x[0]) - x[1]) / T2, (x[1] - x[2]) / T3]
    for i in range(int(round(T / dt))):
        err.append(1.0 - x[2])
        if delay:
            u0 = kc * err[i - nd] if i >= nd else 0.0
            u1 = kc * err[i + 1 - nd] if i + 1 >= nd else 0.0
            us = [u0, (u0 + u1) / 2, (u0 + u1) / 2, u1]
        def u(k, xs):
            return us[k] if delay else kc * (1.0 - xs[2])
        k1 = f(x, u(0, x))
        y = [x[j] + dt / 2 * k1[j] for j in range(3)]; k2 = f(y, u(1, y))
        y = [x[j] + dt / 2 * k2[j] for j in range(3)]; k3 = f(y, u(2, y))
        y = [x[j] + dt * k3[j] for j in range(3)];     k4 = f(y, u(3, y))
        x = [x[j] + dt / 6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j]) for j in range(3)]
        out.append(x[2])
    return out

def swings(y, dt, K, t0=30.0):       # period and ratio of successive like peaks, after t0 min
    fin, pk = K / (1 + K), []
    for i in range(int(t0 / dt), len(y) - 1):
        if y[i] - y[i - 1] > 0 >= y[i + 1] - y[i]:   # a maximum; refine by a parabola
            a, b, c = y[i - 1], y[i], y[i + 1]
            h = (a - c) / (2 * (a - 2 * b + c))
            pk.append(((i + h) * dt, b - (a - c) * h / 4 - fin))
    return pk[1][0] - pk[0][0], pk[1][1] / pk[0][1]

fc = lambda z: f"{round(z.real, 6) + 0.0:+.4f} {round(z.imag, 6) + 0.0:+.4f}j"
print(f"room: {G0:.1f} degC per kW (heat loss {1000 / G0:.0f} W per degC); lags {T1:.0f}, {T2:.0f}, {T3:.0f} min; thermostat k_c = K / {G0:.0f} kW per degC")
print(f"open-loop poles {P[0]:+.4f} {P[1]:+.4f} {P[2]:+.4f} 1/min; D(s) = {A3:.0f} s^3 + {A2:.0f} s^2 + {A1:.0f} s + 1")
sig_a = sum(P) / 3
print(f"rule, asymptotes: centroid {sig_a:+.4f} 1/min, angles 60, 180, 300 deg")
sb = (-2 * A2 + math.sqrt(4 * A2 * A2 - 12 * A3 * A1)) / (6 * A3)       # D'(s) = 0 on (-0.25, -0.1)
gs = (math.sqrt(5) - 1) / 2                                            # road 2: golden-section peak of -D
lo, hi = P[1], P[2]
for _ in range(100):
    m1, m2 = hi - gs * (hi - lo), lo + gs * (hi - lo)
    lo, hi = (m1, hi) if -D(m1) < -D(m2) else (lo, m2)
print(f"breakaway: D'(s) = 0 at {sb:+.6f}, K = {-D(sb):.6f}; golden section {lo:+.6f}, K = {-D(lo):.6f}")
print(f"breakaway: third pole {sum(P) - 2 * sb:+.4f} 1/min; other root of D' {(-2 * A2 - math.sqrt(4 * A2 * A2 - 12 * A3 * A1)) / (6 * A3):+.4f} (off the locus: K there {-D(-0.4):+.4f})")
for K in (0.0, 1.0, 2.0, 4.0, 8.0, 16.0, 20.0):
    r = roots(K)
    print(f"gain K = {K:5.2f}: poles {fc(r[0])}  {fc(r[2])}  {fc(r[1])}  sum {sum(r).real:+.4f}")
w_c, K_c = math.sqrt(A1 / A3), A2 * A1 / A3 - 1.0
K_b = bisect(lambda K: roots(K)[2].real, 10.0, 20.0)
print(f"crossing, rules: omega = {w_c:.4f} rad/min, K = {K_c:.4f}, period {2 * math.pi / w_c:.2f} min")
print(f"crossing, root finder: K = {K_b:.4f}, omega = {roots(K_b)[2].imag:.4f} rad/min")
print(f"crossing, Evans: angle sum at j omega {angle_sum(complex(0, w_c)):.4f} deg, K = |D| = {abs(D(complex(0, w_c))):.4f}")
print("crossing: angles from the poles " + " + ".join(f"{math.degrees(cmath.phase(complex(0, w_c) - p)):.2f}" for p in P) + f" deg; thermostat {K_c / G0:.2f} kW per degC")
print(f"crossing: omega {w_c / 60:.6f} rad/s = {w_c / (2 * math.pi):.4f} cycles per min; misread as cycles per min, period {1 / w_c:.2f} min")
sz, p3 = A1 / (2 * A2), A1 / A2 - A2 / A3                              # pair -sz +- j sz sqrt3: zeta 0.5
K_z = -A3 * 4 * sz * sz * p3 - 1.0
K_zb, K_z7 = (bisect(lambda K: z + roots(K)[2].real / abs(roots(K)[2]), 0.2, 12.0) for z in (0.5, 0.7))
ray = lambda r: r * cmath.exp(1j * math.radians(120))
r_e = bisect(lambda r: angle_sum(ray(r)) - 180.0, 0.05, 0.5)
print(f"zeta 0.5, rules: pair {fc(complex(-sz, sz * math.sqrt(3)))}, third {p3:+.4f}, K = {K_z:.4f}")
print(f"zeta 0.5, root finder: K = {K_zb:.4f}; Evans on the 60 deg ray: K = |D| = {abs(D(ray(r_e))):.4f}")
print(f"zeta 0.5: thermostat {K_z / G0:.4f} kW per degC; omega_n {2 * sz:.4f} rad/min; settles at {K_z / (1 + K_z):.4f} degC per degC")
print(f"try, zeta 0.7: root finder K = {K_z7:.4f}; settles at {K_z7 / (1 + K_z7):.4f} degC per degC, {20 + K_z7 / (1 + K_z7):.2f} degC")
dt, rz = 0.01, roots(K_z)
ms = [(p, K_z / (A3 * p * math.prod(p - q for q in rz if q != p))) for p in rz]
yz = simulate(K_z, 120.0)
gap = max(abs(yz[i] - (K_z / (1 + K_z) + sum((rr * cmath.exp(p * i * dt)).real for p, rr in ms)))
          for i in range(len(yz)))
print(f"step response, residues vs RK4: largest gap below 1e-9 degC: {'yes' if gap < 1e-9 else 'NO'}")
ipk, fin = max(range(len(yz)), key=lambda i: yz[i]), K_z / (1 + K_z)
print(f"zeta 0.5 step: peak {20 + yz[ipk]:.4f} degC at {ipk * dt:.2f} min, overshoot {100 * (yz[ipk] / fin - 1):.2f} %, "
      f"pair alone {100 * math.exp(-math.pi / math.sqrt(3)):.2f} %")
y12 = simulate(12.6, 120.0)
print("chart, t (min)      " + " ".join(f"{10 * i:5d}" for i in range(13)))
print("chart, K = 1.72     " + " ".join(f"{20 + yz[1000 * i]:5.2f}" for i in range(13)))
print("chart, K = 12.6     " + " ".join(f"{20 + y12[1000 * i]:5.2f}" for i in range(13)))
print("chart, K            " + " ".join(f"{K:5d}" for K in range(2, 21, 2)))
print("chart, swing ratio  " + " ".join(f"{math.exp(2 * math.pi * roots(K)[2].real / roots(K)[2].imag):5.2f}" for K in range(2, 21, 2)))
sim = {}
for K in (4.0, 12.6, 20.0):
    per, rat = swings(simulate(K, 150.0), dt, K)
    q = roots(K)[2]
    sim[K] = (per, rat, 2 * math.pi / q.imag, math.exp(2 * math.pi * q.real / q.imag))
    print(f"K = {K:4.1f}: simulated period {per:.3f} min, swing ratio {rat:.4f}; poles say {sim[K][2]:.3f} min, {sim[K][3]:.4f}")
wd = bisect(lambda w: math.atan(T2 * w) + math.atan(T3 * w) + T1 * w - math.pi, 0.01, 1.0)
K_d = math.sqrt((1 + (T2 * wd) ** 2) * (1 + (T3 * wd) ** 2))
rd = [swings(simulate(K, 200.0, delay=True), dt, K)[1] for K in (K_d - 0.3, K_d + 0.3, 10.0)]
print(f"pipe as a 2-min delay: crossing omega {wd:.4f} rad/min, K = {K_d:.4f}")
q = roots(10.0)[2]
print(f"pipe as a delay, simulated swing ratio: K = {K_d - 0.3:.2f} {rd[0]:.4f}, K = {K_d + 0.3:.2f} {rd[1]:.4f}, K = 10 {rd[2]:.4f}; "
      f"lag model K = 10 {math.exp(2 * math.pi * q.real / q.imag):.4f}")
px = lambda z: f"({300 + 200 * z.real:.1f},{120 - 200 * z.imag:.1f})"
print("figure, 200 px per 1/min, upper branch: " + " ".join(px(roots(K)[2]) for K in (0.2, 0.5, 1, 2, 4, 8, 12.6, 20)))
print(f"figure, real branch to {px(roots(20.0)[0])}; breakaway {px(complex(sb, 0))}; centroid {px(complex(sig_a, 0))}; "
      f"zeta point {px(ray(r_e))}; crossing {px(complex(0, w_c))}")

assert abs(K_b - K_c) < 1e-9, "root finder's crossing gain matches the rules"
assert abs(lo - sb) < 1e-6, "golden-section peak matches the breakaway from D'(s) = 0"
assert abs(angle_sum(complex(0, w_c)) - 180.0) < 1e-9, "Evans angle condition holds at the crossing"
assert abs(K_zb - K_z) < 1e-9, "root finder matches the rules on the zeta 0.5 gain"
assert abs(abs(D(ray(r_e))) - K_z) < 1e-9, "Evans's ray search matches the rules on the zeta 0.5 gain"
assert gap < 1e-9, "RK4 simulation matches the residue sum"
assert all(abs(sim[K][0] - sim[K][2]) < 1e-3 and abs(sim[K][1] - sim[K][3]) < 1e-3 for K in sim), "simulated rings match the poles"
assert rd[0] < 1.0 < rd[1], "simulated delay loop decays 0.3 below the frequency road's gain and grows 0.3 above"
print("ALL CHECKS PASS")
