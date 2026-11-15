# Entropy conditions -- the check behind the card.  Standard library only.
# A one-lane road, Greenshields flux q(rho) = V rho (1 - rho/RM).  A light at
# x = 0 turns green at t = 0: a jammed queue behind it, an empty road ahead.
# Roads: the Lax test, the entropy inequality, the Cole-Hopf formula for the
# viscous road, a finite-difference grid for the viscous road, and its residual.
import math
from fractions import Fraction as Fr

V, RM, T = 25.0, 0.15, 60.0          # top speed m/s, jam density cars/m, time s
def q(r): return V * r * (1 - r / RM)              # flux, cars per second
def dq(r): return V * (1 - 2 * r / RM)             # wave speed q'(rho), m/s
def yn(b): return "yes" if b else "no"
def pf(d): return "passes" if d <= 0 else "fails"
def sci(v):                          # e-notation with the same digits in Rust
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    return f"{m:.3f}e{'-' if e < 0 else '+'}{abs(e):02d}"
def fan(x, t): return min(RM, max(0.0, RM / 2 * (1 - x / (V * t))))

def log_phi(z):                      # log of the normal CDF, written out
    if z < -3:                       # continued fraction for the far left tail
        x = -z; f = x
        for k in range(30 + int(300 / x), 0, -1): f = x + k / f
        return -x * x / 2 - 0.5 * math.log(2 * math.pi) - math.log(f)
    if z > 3: return math.log1p(-math.exp(log_phi(-z)))
    term = s = z; n = 0              # power series in the middle
    while abs(term) > 1e-17 * abs(s):
        n += 1; term *= z * z / (2 * n + 1); s += term
    return math.log(0.5 + s * math.exp(-z * z / 2) / math.sqrt(2 * math.pi))

def visc(x, t, eps):                 # exact viscous density, by Cole-Hopf
    sg = math.sqrt(2 * eps * t)
    d = -V * x / eps + log_phi((x - V * t) / sg) - log_phi(-(x + V * t) / sg)
    return 0.0 if d > 700 else RM / (1 + math.exp(d))

def grid(eps, dx, t0=50.0, t1=T, half=2000.0):     # second road: explicit grid
    n = int(2 * half / dx); xs = [-half + i * dx for i in range(n + 1)]
    r = [visc(x, t0, eps) for x in xs]
    steps = round((t1 - t0) * 4 * eps / dx ** 2); dt = (t1 - t0) / steps
    a, b = dt / (2 * dx), eps * dt / dx ** 2
    for _ in range(steps):
        f = [q(v) for v in r]
        r = [r[0]] + [r[i] - a * (f[i + 1] - f[i - 1])
                      + b * (r[i + 1] - 2 * r[i] + r[i - 1]) for i in range(1, n)] + [r[n]]
    return max(abs(r[i] - visc(xs[i], t1, eps)) for i in range(n + 1)) * 1000

def jump(rl, rr):                    # speed, Lax test, entropy production
    s = (q(rr) - q(rl)) / (rr - rl)
    psi = lambda r: V * (r * r / 2 - 2 * r ** 3 / (3 * RM))   # eta = rho^2/2
    return s, dq(rl) > s > dq(rr), (psi(rr) - psi(rl)) - s * (rr * rr - rl * rl) / 2

K, H = 1000.0, 3600.0                # cars/m to cars/km; cars/s to cars/h
print("GREEN LIGHT: queue at 150 cars/km behind x = 0, empty road ahead")
sA, laxA, dA = jump(RM, 0.0)
print(f"rival A, the jump stays put: q left {q(RM) * H:.0f}, q right {q(0.0) * H:.0f} cars/h, "
      f"speed {sA + 0.0:.1f} m/s")
print(f"  wave speeds: left {dq(RM):.0f} m/s, right {dq(0.0):.0f} m/s; Lax test passes: {yn(laxA)}")
print(f"  entropy production {dA:.5f} (must be <= 0): {pf(dA)}")
h = 0.01; past_fan = sum(fan((i + 0.5) * h, T) for i in range(int(V * T / h))) * h
print(f"rival B, the fan: density at the light {fan(0.0, T) * K:.1f} cars/km, "
      f"flow {q(RM / 2) * H:.0f} cars/h")
print(f"  at t = 60 s: fan edges at x = {-V * T:.0f} m and {V * T:.0f} m, "
      f"density at x = 750 m {fan(750.0, T) * K:.1f} cars/km")
print(f"  cars past the light in 60 s: flow x time {q(RM / 2) * T:.2f}, "
      f"area under the fan {past_fan:.2f}, rival A {0.0:.2f}")
print(f"  start wave: the car at x = -300 m has {300 * RM:.0f} cars ahead and starts at "
      f"{300 / V:.1f} s; jam spacing {1 / RM:.2f} m")
print(f"  top speed {V:.0f} m/s = {V * 3.6:.0f} km/h; L1 gap rival A to fan {2 * past_fan:.2f} cars")

print("RED LIGHT: arrivals at 30 cars/km run into a queue at 150 cars/km")
def qx(r): return 25 * r * (1 - r / Fr(15, 100))       # the flux in exact rationals
s_exact = (qx(Fr(15, 100)) - qx(Fr(3, 100))) / (Fr(15, 100) - Fr(3, 100))
sR, laxR, dR = jump(0.03, RM)
print(f"  arrivals flow {q(0.03) * H:.0f} cars/h; shock speed {sR:.4f} m/s "
      f"= {sR * 3.6:.1f} km/h, exact {s_exact}")
print(f"  wave speeds: behind {dq(0.03):.0f} m/s, ahead {dq(RM):.0f} m/s; Lax test passes: {yn(laxR)}")
print(f"  entropy production {dR:.5f} (must be <= 0): {pf(dR)}")
car = lambda r: V * (1 - r / RM)
print(f"  mistake, car speeds in the test: {car(0.03):.0f} > {sR:.0f} > {car(RM):.0f} holds: "
      f"{yn(car(0.03) > sR > car(RM))}")
for eps in (20.0, 2.0, 0.2):
    w = 4 * eps / (dq(0.03) - dq(RM))
    print(f"  viscous shock, eps = {eps:>4.1f} m^2/s: thickness 4 eps/40 = {w:.3f} m")

print("VANISHING VISCOSITY at t = 60 s (Cole-Hopf, exact for each eps)")
print("  eps m^2/s | cars/km at 750 m | cars/km at 1500 m | L1 gap to fan, cars | cars past light")
gaps, past = [], []
for eps in (200.0, 20.0, 2.0, 0.2):
    dx = 0.5; xs = [(i + 0.5) * dx for i in range(4000)]           # symmetric: x > 0
    gaps.append(2 * sum(abs(visc(x, T, eps) - fan(x, T)) for x in xs) * dx)
    past.append(sum(visc(x, T, eps) for x in xs) * dx)
    print(f"  {eps:>9.1f} | {visc(750.0, T, eps) * K:>16.3f} | {visc(1500.0, T, eps) * K:>17.3f} |"
          f" {gaps[-1]:>19.4f} | {past[-1]:>15.4f}")
print(f"  gap shrinks by {gaps[0] / gaps[1]:.2f}, {gaps[1] / gaps[2]:.2f}, "
      f"{gaps[2] / gaps[3]:.2f} per tenfold cut in eps")
print(f"  mistake, stop at eps = 200: {past[0]:.2f} cars cross, {gaps[0]:.2f} cars misplaced")
e2, e1 = grid(50.0, 2.0), grid(50.0, 1.0)
print(f"  grid road, eps = 50, 50 s to 60 s: max error {sci(e2)} cars/km at dx = 2 m, "
      f"{sci(e1)} at dx = 1 m, order {math.log2(e2 / e1):.2f}")
res = []
for hh in (1.0, 0.5):                # residual rho_t + q_x - eps rho_xx at (750 m, 60 s)
    f = lambda x, t: visc(x, t, 20.0)
    rt = (f(750, T + hh) - f(750, T - hh)) / (2 * hh)
    qd = (q(f(750 + hh, T)) - q(f(750 - hh, T))) / (2 * hh)
    rxx = (f(750 + hh, T) - 2 * f(750, T) + f(750 - hh, T)) / hh ** 2
    res.append(rt + qd - 20.0 * rxx)
print(f"  residual of the Cole-Hopf answer, eps = 20: {sci(res[0])} at step 1, {sci(res[1])} at step 0.5")
k = 2 * math.pi / 1.0                # a ripple 1 m long; eps = -1 m^2/s, t = 1 s
grow = 1.0 * k * k * 1.0 / math.log(10)     # log10 of e^(|eps| k^2 t)
print(f"mistake, eps = -1 m^2/s: a 1 m ripple grows by 10^{grow:.2f} in one second")
pts = range(-2000, 2001, 250)
print("chart x m:   " + ", ".join(str(x) for x in pts))
print("chart A:     " + ", ".join(f"{(RM if x < 0 else 0.0) * K:.1f}" for x in pts))
print("chart fan:   " + ", ".join(f"{fan(x, T) * K:.1f}" for x in pts))
print("chart eps200:" + ", ".join(f"{visc(x, T, 200.0) * K:.1f}" for x in pts))
print(f"figure, x from {-2000} to {2000} m, t from 0 to {T:.0f} s, fan edges ({-V * T:.0f}, {T:.0f})"
      f" and ({V * T:.0f}, {T:.0f}), rival A jump x = 0")

assert sA == 0.0 and not laxA and dA > 0 and laxR and dR < 0      # Lax and entropy agree
assert Fr(sR).limit_denominator(1000) == s_exact == -5
assert abs(past_fan - q(RM / 2) * T) < 1e-6 and abs(q(RM / 2) * T - 56.25) < 1e-12
assert gaps[0] > gaps[1] > gaps[2] > gaps[3] and gaps[3] < 0.05   # viscous -> fan
assert abs(past[3] - 56.25) < 0.05 and abs(visc(0.0, T, 2.0) - fan(0.0, T)) < 1e-12
assert e1 < 0.1 and 3.5 < e2 / e1 < 4.5 and abs(res[1]) < abs(res[0]) < 1e-5
print("ALL CHECKS PASS")
