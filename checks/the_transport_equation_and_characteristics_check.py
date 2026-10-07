# The transport equation u_t + c u_x = 0 -- the check behind the card.  A spill
# of 10 mg/L, width 1 km, rides a river at 2 km/h.  Road 1 is the formula; road 2
# is a grid stepped with no formula (constant speed), or the characteristic ODE
# stepped by RK4 (speed 2 + x/2).  math supplies only exp, log and sqrt.
from math import exp, log, sqrt

def f(a): return 10 * exp(-a * a)                    # the spill, mg/L, at label a km

def upwind(h, nu, T=3.0, lo=-4.0, hi=10.0, xq=5.0):  # road 2: upwind grid, speed 2
    k = nu * h / 2; u = [f(lo + i * h) for i in range(round((hi - lo) / h) + 1)]
    for _ in range(round(T / k)):
        u = [0.0] + [u[i] - nu * (u[i] - u[i - 1]) for i in range(1, len(u))]
    return u[round((xq - lo) / h)], max(abs(v) for v in u)

def rk4(x, t0, t1, n):                               # step X' = 2 + X/2 from t0 to t1
    s = (t1 - t0) / n; c = lambda X: 2 + X / 2
    for _ in range(n):
        k1 = c(x); k2 = c(x + s * k1 / 2); k3 = c(x + s * k2 / 2); k4 = c(x + s * k3)
        x += s * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return x

e = exp(1); exact = f(5 - 2 * 3)
print(f"constant speed 2 km/h, x = 5 km, t = 3 h: formula f(x - ct) = {exact:.4f} mg/L")
errs = []
for h in (0.05, 0.025, 0.0125):
    g = upwind(h, 0.8)[0]; errs.append(g - exact)
    print(f"road 2, upwind grid h = {h} km: {g:.4f} mg/L, grid minus formula {g - exact:+.4f}")
print(f"error ratios as h halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f}")
lab = 14 / e - 4; v = f(lab); back = [rk4(10, 2, 0, n) for n in (5, 10)]
print(f"speed 2 + x/2, x = 10 km, t = 2 h: label (x + 4)/e - 4 = {lab:.4f} km, value {v:.4f} mg/L")
for n, b in zip((5, 10), back):
    print(f"road 2, RK4 back to t = 0 in {n} steps: label {b:.6f} km, error {abs(b - lab):.7f}")
w0 = 2 * sqrt(log(2)); w2 = rk4(w0 / 2, 0, 2, 20) - rk4(-w0 / 2, 0, 2, 20)
print(f"centre at t = 2 h: formula 4(e - 1) = {4 * (e - 1):.4f} km, RK4 {rk4(0, 0, 2, 20):.4f} km")
print(f"half-height width: {w0:.4f} km at t = 0; at t = 2 h, {w0 * e:.4f} km by formula, {w2:.4f} by RK4")
print(f"mistake 1, f(x + ct) at x = 6 km, t = 3 h: {f(12):.4f} mg/L, not {f(0):.4f}")
print(f"mistake 2, speed 2 + x/2 taken as 2, at x = 10 km, t = 2 h: {f(6):.4f} mg/L, not {v:.4f}")
big = upwind(0.05, 1.5)[1]
print(f"mistake 3, river moves 1.5 cells per time step, not 0.8: peak grows to 10^{log(big) / log(10):.1f} mg/L")
labels = [-3 + i / 1000 for i in range(6001)]; sp = [2 + exp(-a * a) for a in labels]   # u_t + u u_x = 0
cross = min(-(labels[i + 1] - labels[i]) / (sp[i + 1] - sp[i]) for i in range(6000) if sp[i + 1] < sp[i])
print(f"nonlinear, speed 2 + e^(-a^2): lines first cross at {cross:.4f} h by search, {sqrt(e / 2):.4f} h by formula")
for t in (0, 1.5, 3):
    print(f"chart, t = {t} h:", ", ".join(f"{f(x - 2 * t):.2f}" for x in range(-2, 9)))
print("figure, x (km) at t = 2 h for a = -2 to 2, speed 2:", " ".join(f"{a + 4:.2f}" for a in (-2, -1, 0, 1, 2))
      + "; speed 2 + x/2, at t = 0.5, 1, 1.5, 2 h:")
print("figure,", "; ".join(" ".join(f"{(a + 4) * exp(t / 2) - 4:.2f}" for t in (0.5, 1, 1.5, 2)) for a in (-2, -1, 0, 1, 2)))
assert 0 < errs[2] < 0.06 and 1.8 < errs[1] / errs[2] < 2.2  # grid meets formula at order 1
assert abs(back[1] - lab) < 1e-5 and abs(w2 - w0 * e) < 1e-5      # RK4 meets the closed-form label
assert abs(cross - sqrt(e / 2)) < 1e-4                            # search meets breaking-time formula
print("ALL CHECKS PASS")
