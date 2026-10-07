# Poles, zeros and stability: cruise control with an integrator. Standard library only.
# Road 1: poles from the quadratic formula, modes from partial fractions (residues).
# Road 2: RK4 simulation of the car and controller, with no transfer function in sight.
# Road 3: the poles read back from the simulated wiggle (crossing times, peak ratios).
# BIBO: the area under |g(t)| by Simpson's rule, against the worst bounded command, simulated.
import math

m, b = 1500.0, 60.0      # car mass in kg; drag slope in N per (m/s), linearised near 25 m/s
k, a = 240.0, 0.125      # controller gain in N per (m/s); controller zero at s = -a, a in 1/s

def cexp(z):             # e^z for a complex z, written out
    return complex(math.exp(z.real) * math.cos(z.imag), math.exp(z.real) * math.sin(z.imag))

def roots(d1, d0):       # the two roots of s^2 + d1 s + d0, as complex numbers
    disc = d1 * d1 - 4.0 * d0
    if disc >= 0.0:
        q = math.sqrt(disc)
        return complex((-d1 + q) / 2.0, 0.0), complex((-d1 - q) / 2.0, 0.0)
    q = math.sqrt(-disc)
    return complex(-d1 / 2.0, q / 2.0), complex(-d1 / 2.0, -q / 2.0)

def loop(kk, aa):               # closed loop G(s) = (c1 s + c0) / (s^2 + d1 s + d0)
    return kk / m, kk * aa / m, (b + kk) / m, kk * aa / m

def modes(c1, c0, d1, d0):      # partial fractions: G(s) = r1/(s - p1) + r2/(s - p2)
    p1, p2 = roots(d1, d0)
    return [(p1, (c1 * p1 + c0) / (p1 - p2)), (p2, (c1 * p2 + c0) / (p2 - p1))]

def g_of(t, ms):                # impulse response: sum of r e^(p t)
    return sum((r * cexp(p * t)).real for p, r in ms)

def y_of(t, ms, dc):            # unit step response: G(0) + sum of (r/p) e^(p t)
    return dc + sum((r / p * cexp(p * t)).real for p, r in ms)

def simulate(kk, aa, T, dt, cmd):   # states: v speed change, w summed error
    def f(v, w, rr):
        e = rr - v
        return (-b * v + kk * e + kk * aa * w) / m, e   # m v' = -b v + throttle force
    v = w = 0.0
    out = [0.0]
    for i in range(int(round(T / dt))):
        rr = cmd((i + 0.5) * dt)                # command held over each step
        k1 = f(v, w, rr)
        k2 = f(v + dt / 2 * k1[0], w + dt / 2 * k1[1], rr)
        k3 = f(v + dt / 2 * k2[0], w + dt / 2 * k2[1], rr)
        k4 = f(v + dt * k3[0], w + dt * k3[1], rr)
        v += dt / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        w += dt / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        out.append(v)
    return out

def fc(p):
    return f"{p.real:+.4f} {p.imag:+.4f}j"

print(f"car alone, pole            {-b / m:+.4f} 1/s, time constant {m / b:.1f} s")
print(f"controller, pole {0.0:+.4f} 1/s, zero {-a:+.4f} 1/s, integrator slope {k * a:.1f} N/s per m/s")
print(f"integrator area to 100 s   {k * a * 100:.1f}, to 1000 s {k * a * 1000:.1f}")
for kk in (0.0, 60.0, 240.0, 960.0):
    p1, p2 = roots(*loop(kk, a)[2:])
    print(f"gain k = {kk:5.0f}: poles {fc(p1)}  {fc(p2)}")
c1, c0, d1, d0 = loop(k, a)
ms = modes(c1, c0, d1, d0)
dc = c0 / d0
print(f"G(s) = ({c1:.4f} s + {c0:.4f}) / (s^2 + {d1:.4f} s + {d0:.4f}), G(0) = {dc:.4f}")
p1, p2 = ms[0][0], ms[1][0]
print(f"hand: discriminant {d1 * d1 - 4 * d0:+.4f}, c1 p1 + c0 = {fc(c1 * p1 + c0)}, p1 - p2 = {fc(p1 - p2)}")
for p, r in ms:
    print(f"pole {fc(p)}  residue {fc(r)}  step residue {fc(r / p)}")

dt = 0.01
sim = simulate(k, a, 120.0, dt, lambda t: 1.0)
err = max(abs(sim[i] - y_of(i * dt, ms, dc)) for i in range(len(sim)))
print(f"road 1 vs road 2, largest step-response gap below 1e-12: {'yes' if err < 1e-12 else 'NO'}")
print("chart, t (s)       " + " ".join(f"{5 * i:5d}" for i in range(13)))
print("chart, speed (m/s) " + " ".join(f"{25 + 2 * sim[500 * i]:5.2f}" for i in range(13)))
ipk = max(range(len(sim)), key=lambda i: sim[i])
tpk = (math.pi - math.atan(4.0)) / 0.1
print(f"peak: sim {25 + 2 * sim[ipk]:.4f} m/s at {ipk * dt:.2f} s; formula {25 + 2 * y_of(tpk, ms, dc):.4f} m/s at {tpk:.2f} s")

cross = [(i - 1 + (1 - sim[i - 1]) / (sim[i] - sim[i - 1])) * dt
         for i in range(1, len(sim)) if (sim[i - 1] - 1) * (sim[i] - 1) < 0]
ext = [sim[i] - 1 for i in range(1, len(sim) - 1)
       if (sim[i] - sim[i - 1]) * (sim[i + 1] - sim[i]) < 0]
w_back = math.pi / (cross[1] - cross[0])
s_back = -w_back / math.pi * math.log(abs(ext[0] / ext[1]))
print(f"road 3: crossings {cross[0]:.3f} s, {cross[1]:.3f} s; extremes {ext[0]:+.5f}, {ext[1]:+.5f}")
print(f"road 3: poles read back {s_back:+.4f} {w_back:+.4f}j")

def simpson(f, n=40000, h=0.005):              # Simpson's rule on 0..200 s
    return sum((1 if j in (0, n) else 4 if j % 2 else 2) * f(j * h) for j in range(n + 1)) * h / 3

area = simpson(lambda t: abs(g_of(t, ms)))
T = 200.0
worst = simulate(k, a, T, 0.005, lambda t: 1.0 if g_of(T - t, ms) >= 0 else -1.0)
print(f"BIBO area of |g| {area:.6f}; worst +-1 command, simulated {worst[-1]:.6f}")
print(f"g(0) = {g_of(0.0, ms):.4f} per s; signed area of g {simpson(lambda t: g_of(t, ms)):.6f}")

bc1, bc0, bd1, bd0 = loop(-k, a)               # gain sign flipped: k -> -k
bms = modes(bc1, bc0, bd1, bd0)
print(f"sign error, poles {fc(bms[0][0])}  {fc(bms[1][0])}")
bad = simulate(-k, a, 60.0, dt, lambda t: 1.0)
rate = math.log(bad[6000] / bad[5000]) / 10.0
print(f"sign error, y at 30 s: formula {y_of(30.0, bms, bc0 / bd0):.2f}, sim {bad[3000]:.2f}; growth rate {rate:.4f} 1/s")

zr = modes(-c1, c0, d1, d0)                    # zero moved to s = +a: same poles
yr = [y_of(i * dt, zr, dc) for i in range(6001)]
i0 = min(range(len(yr)), key=lambda i: yr[i])
nz = modes(0.0, c0, d1, d0)                    # no zero at all: same poles
yn = max(y_of(i * dt, nz, dc) for i in range(6001))
print(f"zero at +a: dip {yr[i0]:+.4f} at {i0 * dt:.2f} s ({25 + 2 * yr[i0]:.2f} m/s), peak {max(yr):.4f}")
print(f"no zero: peak {yn:.4f}, 1 + e^-pi {1 + math.exp(-math.pi):.4f}")
cz1, cz2 = roots(*loop(k, -a)[2:])             # the controller's own zero moved to +a: a sits in k a/m too
print(f"controller zero at +a, closed loop: poles {fc(cz1)}  {fc(cz2)}")
print(f"ring period {2 * math.pi / p1.imag:.2f} s, envelope halves every {math.log(2) / -p1.real:.2f} s, "
      f"25 m/s = {25 * 3.6:.1f} km/h, overshoot {100 * (sim[ipk] - 1):.2f} %, no zero {100 * (yn - 1):.2f} %")
px = lambda z: f"({180 + 600 * z.real:.1f},{120 - 600 * z.imag:.1f})"
print(f"figure, 600 px per 1/s: poles {px(ms[0][0])} {px(ms[1][0])}, zero {px(complex(-a, 0))}, flipped {px(bms[0][0])}")
print(f"drag +10 m/s from 25: linear {b * 10:.0f} N, quadratic 1.2 v^2 {1.2 * (35 ** 2 - 25 ** 2):.0f} N")

assert err < 1e-12, "RK4 simulation must match the partial-fraction step response"
assert abs(s_back - ms[0][0].real) < 1e-3 and abs(w_back - ms[0][0].imag) < 1e-3, "poles read back"
assert abs(worst[-1] - area) < 1e-4, "worst bounded command reaches the BIBO area"
assert abs(rate - bms[0][0].real) < 1e-3, "runaway rate equals the right-half-plane pole"
assert abs(yn - (1 + math.exp(-math.pi))) < 1e-6, "no-zero peak against the damping formula"
print("ALL CHECKS PASS")
