# The Riemann problem -- the check behind the card.  Standard library only.
# A one-lane road (illustrative numbers): top speed 25 m/s, jam 150 cars/km,
# flow q = V rho (1 - rho/RJ).  At t = 0 the light at x = 0 turns green: a
# jammed queue behind it, an empty road ahead.  Roads: the fan formula; a
# grid with a Rusanov flux (no Riemann solution inside) at three steps; a car's
# path by RK4 against its closed form; the equation's residual by centred
# differences; shock speeds in exact fractions.
from fractions import Fraction as F
from math import log2

V, RJ = 25.0, 0.15                         # top speed m/s, jam density cars/m
def q(r): return V * r * (1 - r / RJ)      # flow, cars/s
def wave(r): return V * (1 - 2 * r / RJ)   # wave speed u = q'(rho), m/s
def car(r): return V * (1 - r / RJ)        # car speed, m/s
def rho_of(u): return RJ * (1 - u / V) / 2 # back from wave speed to density

def riemann(uL, uR, x, t):                 # Burgers u_t + (u^2/2)_x = 0
    if uL > uR:                            # shock at the average speed
        return uL if x < (uL + uR) / 2 * t else uR
    if x <= uL * t: return uL              # fan: u = x/t between the edges
    if x >= uR * t: return uR
    return x / t
def rho(x, t): return rho_of(riemann(wave(RJ), wave(0.0), x, t))

uL, uR = wave(RJ), wave(0.0)
print(f"wave speeds: queue {uL * 3.6:.1f} km/h, empty road {uR * 3.6:.1f} km/h")
print(f"fan edges at 10 s: {uL * 10:.0f} m and {uR * 10:.0f} m")
r0 = rho(0.0, 30.0)
print(f"at the light: density {r0 * 1000:.1f} cars/km, car speed {car(r0) * 3.6:.1f} km/h, flow {q(r0) * 3600:.1f} cars/h")
through = q(r0) * 60
w = V * 60 / 6000; past = sum(rho((k + 0.5) * w, 60.0) * w for k in range(6000))   # cars past the light
print(f"cars through in 60 s: flow x time {through:.4f}, counted on the road {past:.4f}")
assert abs(r0 - RJ / 2) < 1e-12 and abs(through - past) < 1e-6 and abs(through - V * RJ / 4 * 60) < 1e-9

# one car, 100 m back: closed form x = V t - 2 sqrt(V X0 t) after it starts at X0/V
X0 = 100.0
def path(t): return V * t - 2 * (V * X0 * t) ** 0.5 if t > X0 / V else -X0
def vel(x, t): return car(rho(x, t))
def rk4(s, n=4000):                        # RK4 from the moment the fan reaches it
    x, t = -X0, X0 / V
    if s <= t: return x
    h = (s - t) / n
    for _ in range(n):
        k1 = vel(x, t); k2 = vel(x + h / 2 * k1, t + h / 2)
        k3 = vel(x + h / 2 * k2, t + h / 2); k4 = vel(x + h * k3, t + h)
        x += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4); t += h
    return x
print("car 100 m back:  t s   closed x m   RK4 x m   speed km/h")
for s in (4.0, 9.0, 16.0, 25.0, 36.0):
    xc, xr = path(s), rk4(s)
    print(f"              {s:5.0f}   {xc:9.3f}  {xr if abs(xr) > 5e-4 else 0.0:8.3f}   {car(rho(xc, s)) * 3.6:8.2f}")
    assert abs(xc - xr) < 1e-3
tc = 4 * X0 / V
print(f"it crosses the light at {tc:.1f} s; cars ahead of it: {X0 * RJ:.1f}; flow x time {q(r0) * tc:.1f}")
assert abs(path(tc)) < 1e-9 and abs(q(r0) * tc - X0 * RJ) < 1e-9

# the equation's residual u_t + u u_x at (x, t) = (-100 m, 20 s), centred differences
print("residual u_t + u u_x at -100 m, 20 s, in mm/s^2:", end="")
res = []
for d in (1.0, 0.5, 0.25):
    f = lambda xx, tt: riemann(uL, uR, xx, tt)
    ut = (f(-100, 20 + d) - f(-100, 20 - d)) / (2 * d)
    ux = (f(-100 + d, 20) - f(-100 - d, 20)) / (2 * d)
    res.append(ut + f(-100, 20) * ux); print(f"  step {d} -> {res[-1] * 1000:.4f}", end="")
print()
assert abs(res[0] / res[1] - 4) < 0.01 and abs(res[1] / res[2] - 4) < 0.01

# a grid that knows no Riemann solution: Rusanov flux, cells of h metres, to 60 s
def grid(hx):
    nx = int(4000 / hx); r = [RJ if -2000 + (i + 0.5) * hx < 0 else 0.0 for i in range(nx)]
    dt = 0.5 * hx / V; steps = int(round(60 / dt)); thru = 0.0
    for _ in range(steps):
        e = [r[0]] + r + [r[-1]]
        fl = [(q(e[i]) + q(e[i + 1])) / 2 - max(abs(wave(e[i])), abs(wave(e[i + 1]))) / 2 * (e[i + 1] - e[i]) for i in range(nx + 1)]
        thru += fl[nx // 2] * dt
        r = [r[i] - dt / hx * (fl[i + 1] - fl[i]) for i in range(nx)]
    err = sum(abs(r[i] - rho(-2000 + (i + 0.5) * hx, 60.0)) * hx for i in range(nx))
    return err, thru, sum(r) * hx
errs, thrus = [], []
for hx in (20.0, 10.0, 5.0):
    err, thru, tot = grid(hx); errs.append(err); thrus.append(thru)
    print(f"grid h = {hx:4.1f} m: misplaced cars {err:.4f}, through the light {thru:.4f}, total cars {tot:.4f}")
    assert abs(tot - 2000 * RJ) < 1e-9
print(f"error ratio per halving: {errs[0] / errs[1]:.3f} and {errs[1] / errs[2]:.3f}; observed order {log2(errs[0] / errs[1]):.2f} and {log2(errs[1] / errs[2]):.2f}")
assert errs[2] < errs[1] < errs[0] and errs[1] / errs[2] > 1.4
assert abs(thrus[2] - past) < abs(thrus[1] - past) < abs(thrus[0] - past)

# the other branch: red light, 30 cars/km meets the queue -> a shock
def qk(r): return F(90) * r * (1 - F(r, 150))   # exact, km/h and cars/km
def wk(r): return F(90) * (1 - F(2 * r, 150))
s_rh = (qk(150) - qk(30)) / (150 - 30); s_b = (wk(30) + wk(150)) / 2
print(f"red light: wave speeds {float(wk(30)):.1f} and {float(wk(150)):.1f} km/h; shock {float(s_rh):.1f} km/h (cars), {float(s_b):.1f} km/h (Burgers)")
assert s_rh == s_b == -18
rl, rr = 0.03, RJ                          # the same shock from the float solver
cnt = sum(rho_of(riemann(wave(rl), wave(rr), -2000 + (k + 0.5) * 0.5, 60.0)) * 0.5 for k in range(8000))
inflow = 2000 * (rl + rr) + q(rl) * 60     # cars at t = 0 plus cars driven in
print(f"red light, 60 s: shock at {(wave(rl) + wave(rr)) / 2 * 60:.0f} m; cars on 4 km counted {cnt:.4f}, by inflow {inflow:.4f}")
assert abs(cnt - inflow) < 1e-6

# what breaks
jump = (qk(150) - qk(0)) / 150
print(f"breaks: green-light jump kept: speed {float(jump):.1f} km/h, flow at light {float(qk(150)):.0f} cars/h (right: {q(r0) * 3600:.0f})")
cs = (90 * (1 - F(30, 150)) + 0) / 2
print(f"breaks: shock at the average car speed: {float(cs):.1f} km/h (right: {float(s_rh):.1f})")
a, b = wk(30) / F(18, 5), wk(150) / F(18, 5)    # m/s
wrong = F(2, 3) * (a * a + a * b + b * b) / (a + b)
print(f"breaks: conserve u^2/2 instead of cars: {float(wrong):.1f} m/s = {float(wrong * F(18, 5)):.1f} km/h (right: {float(s_rh):.1f})")
print(f"breaks: fan drawn for the red light: {float((a - b) * 10):.0f} m of road given two densities at 10 s")
assert jump == 0 and cs == 36
assert wrong == F(-95, 3) and (a - b) * 10 == 400

for tt in (20.0, 40.0, 60.0):
    print(f"chart, t = {tt:.0f} s:", " ".join(f"{rho(xx, tt) * 1000:.1f}" for xx in range(-1500, 1501, 500)))
fig = ", ".join(f"({path(s):.1f}, {s:.0f})" for s in (4.0, 9.0, 16.0, 25.0, 40.0))
print(f"figure, fan edges at 40 s: {uL * 40:.0f} m, {uR * 40:.0f} m; car path (x m, t s): {fig}")
print("ALL CHECKS PASS")
