# Order of a method -- the check behind the card.  Standard library only.
# The skydiver: v' = 9.8 - 0.2 v, v(0) = 0, exact v = 49 (1 - e^(-0.2 t)).
# Road one steps the rate law in a loop; road two uses each method's closed form.
from math import exp, log

G, K, T = 9.8, 0.2, 10.0                       # m/s^2, 1/s, s

def exact(t): return G / K * (1 - exp(-K * t))
def rate(t, v): return G - K * v
def euler(f, t, v, h): return v + h * f(t, v)
def rk4(f, t, v, h):
    k1 = f(t, v); k2 = f(t + h / 2, v + h / 2 * k1)
    k3 = f(t + h / 2, v + h / 2 * k2); k4 = f(t + h, v + h * k3)
    return v + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
def run(step, f, h):                            # road one: N steps from rest
    v = 0.0
    for n in range(round(T / h)): v = step(f, n * h, v, h)
    return v
def closed(factor, h): return G / K * (1 - factor ** round(T / h))   # road two
def r4(z): return 1 + z + z * z / 2 + z ** 3 / 6 + z ** 4 / 24
def order(e): return [log(e[i] / e[i + 1], 2) for i in range(len(e) - 1)]

HS, vT, M = [2.0, 1.0, 0.5], exact(T), K * G    # M = size of v'' at t = 0
print(f"skydiver v' = 9.8 - 0.2v from rest; terminal {G / K:.1f} m/s; exact v(10) = {vT:.4f} m/s")
loc = []
for h in (1.0, 0.5):
    loc.append(euler(rate, 0, 0.0, h) - exact(h))
    print(f"one step h = {h}: Euler {h * G:.4f}, exact {exact(h):.4f}, local error "
          f"{loc[-1]:.4f}, Taylor h^2/2 x 1.96 = {h * h / 2 * M:.4f}")
print(f"local error ratio h = 1 over h = 0.5: {loc[0] / loc[1]:.2f}")
ee, er, pred = [], [], []
for h in HS:
    ee.append(run(euler, rate, h) - vT); er.append(abs(run(rk4, rate, h) - vT))
    pred.append(T / 2 * M * exp(-K * T) * h)
    print(f"Euler h = {h}: v(10) = {run(euler, rate, h):.4f}, closed form "
          f"{closed(1 - K * h, h):.4f}, error {ee[-1]:.4f}, predicted {pred[-1]:.4f}")
for h, e in zip(HS, er):
    print(f"RK4 h = {h}: v(10) = {run(rk4, rate, h):.7f}, closed form "
          f"{closed(r4(-K * h), h):.7f}, error {e:.7f}")
po, pr = order(ee), order(er)
print(f"order estimates, Euler: {po[0]:.2f}, {po[1]:.2f}; RK4: {pr[0]:.2f}, {pr[1]:.2f}")
print(f"error ratios per halving, RK4: {er[0] / er[1]:.1f}, {er[1] / er[2]:.1f}")
print(f"general bound (M/2L)(e^(LT) - 1) = {M / (2 * K) * (exp(K * T) - 1):.2f} per unit h")
print(f"chart, Euler error / h: {ee[2] / HS[2]:.2f}, {ee[1] / HS[1]:.2f}, "
      f"{ee[0] / HS[0]:.2f}; prediction / h: {pred[0] / HS[0]:.2f}")
print(f"mistake 1, local order 2 read as global: h = 1 guessed {ee[0] / 4:.4f}, actual {ee[1]:.4f}")
big = [abs(run(euler, rate, h) - vT) for h in (10.0, 5.0)]
print(f"mistake 2, h = 10 and 5: errors {big[0]:.4f}, {big[1]:.4f}, order estimate {order(big)[0]:.2f}")
TO, K2 = 4.3, 0.98                              # parachute opens at 4.3 s
def chute(t, v): return G - (K if t < TO else K2) * v
v2 = G / K2 + (exact(TO) - G / K2) * exp(-K2 * (T - TO))
ec = [abs(run(rk4, chute, h) - v2) for h in HS]
print(f"mistake 3, parachute at 4.3 s, exact v(10) = {v2:.4f}: RK4 errors "
      f"{ec[0]:.4f}, {ec[1]:.4f}, {ec[2]:.4f}; estimates {order(ec)[0]:.2f}, {order(ec)[1]:.2f}")
for h in HS: assert abs(run(euler, rate, h) - closed(1 - K * h, h)) + abs(run(rk4, rate, h)
                     - closed(r4(-K * h), h)) < 1e-9 * vT              # two roads agree
assert all(h * h / 2 * M * exp(-K * h) < e < h * h / 2 * M for h, e in zip((1, .5), loc))
assert all(0.9 < p < 1.1 for p in po) and all(3.9 < p < 4.4 for p in pr)  # orders 1, 4
assert all(abs(e / p - 1) < 0.07 for e, p in zip(ee, pred))
print("ALL CHECKS PASS")
