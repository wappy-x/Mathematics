# Characteristics -- the check behind the card.  A bunch of cars, density
# rho0(x) = 40 e^(-x^2) cars/km, rides a one-lane road at 50 km/h and slows to
# 30 km/h through a work zone.  Road 1 is the closed form along characteristics;
# road 2 steps the characteristic ODEs by RK4; road 3 puts the answer back into
# the PDE by centred differences and counts the cars.  math gives exp, log, sqrt.
from math import exp, log, sqrt, pi

def rho0(a): return 40 * exp(-a * a)                 # cars/km at t = 0, at label a km
def v(x): return 50.0 if x <= 2 else (50 - 20 * (x - 2) if x <= 3 else 30.0)  # km/h
RAMP = log(5 / 3) / 20                               # hours to cross the ramp, 2 to 3 km

def clock(x):                                        # hours to drive from 2 km to x km
    if x <= 2: return (x - 2) / 50
    return log(50 / v(x)) / 20 if x <= 3 else RAMP + (x - 3) / 30

def unclock(T):                                      # the place reached after T hours
    if T <= 0: return 2 + 50 * T
    return 2 + 2.5 * (1 - exp(-20 * T)) if T <= RAMP else 3 + 30 * (T - RAMP)

def label(x, t): return unclock(clock(x) - t)        # where the car at (x, t) began
def rho(x, t): a = label(x, t); return rho0(a) * v(a) / v(x)   # rho * v rides along

def ride(a, x_end, n):                               # road 2: RK4 in x along the path
    t, r = 0.0, rho0(a); pts = [a] + [b for b in (2, 3) if a < b < x_end] + [x_end]
    for x0, x1 in zip(pts, pts[1:]):
        s = -20.0 if 2 <= x0 < 3 else 0.0; h = (x1 - x0) / n   # slope of v on the piece
        F = lambda x, r: (1 / v(x), -s * r / v(x))   # dt/dx = 1/v, drho/dx = -v' rho / v
        for i in range(n):
            x = x0 + i * h; k1 = F(x, r); k2 = F(x + h / 2, r + h * k1[1] / 2)
            k3 = F(x + h / 2, r + h * k2[1] / 2); k4 = F(x + h, r + h * k3[1])
            t += h * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]) / 6
            r += h * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]) / 6
    return t, r

def shoot(x, t, n):                                  # bisection: the label that arrives on time
    lo, hi = -3.0, x
    for _ in range(60):
        m = (lo + hi) / 2
        if ride(m, x, n)[0] > t: lo = m
        else: hi = m
    return m, ride(m, x, n)[1]

X, T = 4.0, 0.1
a = label(X, T); ans = rho(X, T)
print(f"ramp crossing time ln(5/3)/20 = {RAMP:.6f} h = {60 * RAMP:.4f} min")
print(f"work zone, x = {X:g} km, t = {T:g} h: label a = {a:.4f} km, rho0(a) = {rho0(a):.4f} cars/km")
print(f"trace back: {(X - 3) / 30:.6f} h in the zone, {RAMP:.6f} h on the ramp, {T - (X - 3) / 30 - RAMP:.6f} h before it")
print(f"road 1, closed form rho0(a) * 50/30 = {ans:.4f} cars/km")
for n in (5, 10):
    m, r = shoot(X, T, n)
    print(f"road 2, RK4 {n} steps per piece + bisection: label {m:.6f} km, rho {r:.6f} cars/km")
print(f"flow carried along: {rho0(a) * 50:.2f} cars/h at the start, {ans * 30:.2f} cars/h in the zone")
def res(f, x, t, h):                                 # rho_t + (v rho)_x by centred differences
    return (f(x, t + h) - f(x, t - h)) / (2 * h) + (v(x + h) * f(x + h, t) - v(x - h) * f(x - h, t)) / (2 * h)
wrong = lambda x, t: rho0(label(x, t))               # mistake: value constant along the path
r1, r2 = res(rho, 2.5, 0.05, 0.002), res(rho, 2.5, 0.05, 0.001)
print(f"road 3, residual on the ramp at 2.5 km, 0.05 h: h = 0.002 {r1:+.6f}, h = 0.001 {r2:+.6f}, ratio {r1 / r2:.2f}")
print(f"same residual for rho0(label), the zero-R mistake: {res(wrong, 2.5, 0.05, 0.001):+.2f} cars/km/h")
cars = lambda t: 0.002 * sum(rho(-6 + 0.002 * i, t) for i in range(9001))
print(f"cars on the road: 40 sqrt(pi) = {40 * sqrt(pi):.4f}; summed at t = 0: {cars(0):.4f}, at t = 0.1 h: {cars(0.1):.4f}")
w0 = 2 * sqrt(log(2))
wl = unclock(clock(-w0 / 2) + T); wr = unclock(clock(w0 / 2) + T)
xm = unclock(clock(0) + T)                           # the bunch's middle, label 0, at T
print(f"half-height width: {w0:.4f} km at t = 0, {wr - wl:.4f} km at t = 0.1 h; middle at {xm:.4f} km, peak {rho(xm, T):.4f} cars/km")
print(f"mistake 1, R dropped: rho0(a) = {wrong(X, T):.4f} cars/km, not {ans:.4f}")
print(f"mistake 2, zone ignored, shift at 50 km/h: rho0(4 - 5) = {rho0(X - 50 * T):.4f} cars/km, not {ans:.4f}")
J = lambda P, Q, dx, dt: P * dt - Q * dx             # data curve against the characteristic
print(f"J = P t0' - Q x0': start line {J(50, 1, 1, 0):.0f}, counter at 0 km {J(50, 1, 0, 1):.0f}, probe car {J(50, 1, 50, 1):.0f}")
g = lambda t: rho0(-50 * t)                          # what the counter at 0 km records
print(f"counter read back, x = 1 km, t = 0.03 h: g(t - x/50) = {g(0.03 - 1 / 50):.4f}, rho0(x - 50t) = {rho0(1 - 50 * 0.03):.4f} cars/km")
A, B = rho0(1 - 50 * 0), 40.0                        # two solutions with the probe's data
print(f"mistake 3, probe reads 40 cars/km: 40 e^(-(x-50t)^2) gives {A:.4f} at 1 km, 0 h; constant 40 gives {B:.4f}")
c = lambda r: 60 - 0.8 * r                           # quasilinear: speed of a density value
print(f"at 40 cars/km: car speed 60(1 - 40/150) = {60 * (1 - 40 / 150):.4f} km/h, the density value moves at c = {c(40):.4f} km/h")
print(f"trap, car speed used for c: after 0.02 h the 40 cars/km value sits at {c(40) * 0.02:.4f} km, not "
      f"{60 * (1 - 40 / 150) * 0.02:.4f} km, {(60 * (1 - 40 / 150) - c(40)) * 0.02:.4f} km too far ahead")
def qlabel(x, t):                                    # bisection on a + c(rho0(a)) t = x
    lo, hi = x - 60 * t, x - 28 * t
    for _ in range(60):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if m + c(rho0(m)) * t < x else (lo, m)
    return m
q = lambda x, t: rho0(qlabel(x, t)); qa = qlabel(1.0, 0.02)
print(f"quasilinear, x = 1 km, t = 0.02 h: label {qa:.4f} km, rho {q(1.0, 0.02):.4f} cars/km, speed c {c(q(1.0, 0.02)):.4f} km/h")
qr = lambda h: (q(1, 0.02 + h) - q(1, 0.02 - h)) / (2 * h) + c(q(1, 0.02)) * (q(1 + h, 0.02) - q(1 - h, 0.02)) / (2 * h)
print(f"residual rho_t + c(rho) rho_x: h = 0.002 {qr(0.002):+.6f}, h = 0.001 {qr(0.001):+.6f}")
L = [-3 + i / 1000 for i in range(6001)]; C = [c(rho0(a)) for a in L]
tc = min((L[i + 1] - L[i]) / (C[i] - C[i + 1]) for i in range(6000) if C[i] > C[i + 1])
tf = 1 / (0.8 * 40 * sqrt(2) * exp(-0.5))
print(f"first crossing: {tc:.6f} h by search, 1/(0.8 * 40 sqrt(2) e^(-1/2)) = {tf:.6f} h = {60 * tf:.4f} min")
tm = 0.06                                            # a time after the first crossing, h
arrive = lambda a: a + c(rho0(a)) * tm - 1.8         # zero where label a reaches 1.8 km
hits = [i for i in range(6000) if arrive(L[i]) * arrive(L[i + 1]) < 0]
def root(lo, hi):                                    # bisection inside one sign-change bracket
    for _ in range(60):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if arrive(lo) * arrive(m) > 0 else (lo, m)
    return (lo + hi) / 2
print(f"mistake 4, at x = 1.8 km, t = {tm} h: {len(hits)} labels arrive, densities", ", ".join(f"{rho0(root(L[i], L[i + 1])):.2f}" for i in hits))
for t in (0, 0.1):
    print(f"chart, t = {t} h:", ", ".join(f"{rho(-2 + k / 2, t):.2f}" for k in range(17)))
print("figure, label a: t entering ramp, t entering zone, x at 0.15 h (h, h, km):", "; ".join(
    f"{b}: {0 - clock(b):.4f} {RAMP - clock(b):.4f} {unclock(clock(b) + 0.15):.4f}" for b in range(-2, 3)))
assert abs(shoot(X, T, 10)[1] - ans) < 1e-4 and abs(shoot(X, T, 10)[0] - a) < 1e-4   # RK4 meets closed form
assert abs(r2) < 1 and 3.5 < r1 / r2 < 4.5 and abs(res(wrong, 2.5, 0.05, 0.001)) > 100  # residual
assert abs(cars(0.1) - 40 * sqrt(pi)) < 1e-3 and abs(wr - wl - 0.6 * w0) < 1e-9          # cars conserved
assert abs(g(0.03 - 1 / 50) - rho(1, 0.03)) < 1e-9                                   # counter data suffice
assert abs(tc - tf) < 1e-5 and abs(qr(0.001)) < 1 and len(hits) == 3             # quasilinear
print("ALL CHECKS PASS")
