# Runge-Kutta four -- the check behind the card.  Python standard library only;
# math.exp is the one primitive used.  Skydiver: v' = 9.8 - 0.2 v (m/s, s).
# School rumour: P' = 0.8 P (1 - P/1000), P(0) = 10 pupils, time in days.
import math
def rk4(f, y, h, n, t=0.0, weights=(1, 2, 2, 1), half=0.5):
    for _ in range(n):          # four slopes per step, then one weighted move
        k1 = f(t, y); k2 = f(t + half * h, y + half * h * k1)
        k3 = f(t + half * h, y + half * h * k2); k4 = f(t + h, y + h * k3)
        w = weights; y += h * (w[0]*k1 + w[1]*k2 + w[2]*k3 + w[3]*k4) / sum(w); t += h
    return y
sky = lambda t, v: 9.8 - 0.2 * v
exact = lambda t: 49 * (1 - math.exp(-0.2 * t))          # road 1: the closed form
R = lambda z: 1 + z + z*z/2 + z**3/6 + z**4/24            # road 2: e^z cut after z^4
k1 = sky(0, 0); k2 = sky(1, k1); k3 = sky(1, k2); k4 = sky(2, 2 * k3)
v2 = rk4(sky, 0.0, 2, 1)
print(f"one step, h = 2 s, from v = 0: k1 = {k1:.4f}, k2 = {k2:.4f}, k3 = {k3:.4f}, k4 = {k4:.4f}")
print(f"weighted slope {(k1+2*k2+2*k3+k4)/6:.4f}, v(2) = {v2:.4f}, exact {exact(2):.4f}, error {exact(2)-v2:.4f}")
X = lambda t: 60 + 130 * t; Y = lambda v: 200 - 8.5 * v   # figure scale
pts = [(0, 0), (1, k1), (1, k2), (2, 2 * k3), (2, v2)]
print("figure, start k2 k3 k4 end:", " ".join(f"{X(t):.1f},{Y(v):.1f}" for t, v in pts))
print("figure, exact curve:", " ".join(f"{X(t/4):.1f},{Y(exact(t/4)):.1f}" for t in range(9)))
print(f"skydiver v(10), exact {exact(10):.6f}")
errs = []
for h in (2, 1, 0.5, 0.25):
    v = rk4(sky, 0.0, h, round(10 / h)); errs.append(exact(10) - v)
    print(f"h = {h:<5} RK4 {v:.6f}  error {errs[-1]:.7f}  gap-factor road {49*(1-R(-0.2*h)**round(10/h)):.6f}")
    assert abs(v - 49 * (1 - R(-0.2 * h) ** round(10 / h))) < 1e-9   # road 1 meets road 2
print("error ratio per halving:", " ".join(f"{errs[i]/errs[i+1]:.2f}" for i in range(3)))
eul = lambda h, n: 49 * (1 - (1 - 0.2 * h) ** n); heun = lambda h, n: 49 * (1 - (1 - 0.2*h + 0.02*h*h) ** n)
print(f"20 slope evaluations each: Euler h = 0.5 {eul(0.5,20):.4f} error {eul(0.5,20)-exact(10):.4f}; "
      f"Heun h = 1 {heun(1,10):.4f} error {exact(10)-heun(1,10):.4f}; RK4 h = 2 error {errs[0]:.4f}")
ts = range(0, 11, 2)
print("chart, t:", " ".join(f"{t}" for t in ts))
print("chart, exact:", " ".join(f"{exact(t):.2f}" for t in ts))
print("chart, Euler h = 2:", " ".join(f"{eul(2, t//2):.2f}" for t in ts))
print("chart, RK4 h = 2:", " ".join(f"{rk4(sky, 0.0, 2, t//2):.2f}" for t in ts))
rum = lambda t, p: 0.8 * p * (1 - p / 1000); P10 = 1000 / (1 + 99 * math.exp(-8))
a, b = rk4(rum, 10.0, 0.5, 20), rk4(rum, 10.0, 0.25, 40)
print(f"rumour day 10, exact {P10:.4f}: h = 0.5 {a:.4f} error {P10-a:.4f}; h = 0.25 {b:.4f} error {P10-b:.4f}; ratio {(P10-a)/(P10-b):.2f}")
assert all(15 < errs[i] / errs[i + 1] < 20 for i in range(3)) and 14 < (P10 - a) / (P10 - b) < 18
wrong_w, no_half = rk4(sky, 0.0, 2, 5, weights=(1, 1, 1, 1)), rk4(sky, 0.0, 2, 5, half=1.0)
print(f"mistakes at h = 2: equal weights {wrong_w:.4f}, halves dropped {no_half:.4f}")
b, c, A = (1/6, 1/3, 1/3, 1/6), (0, 0.5, 0.5, 1), {(1, 0): 0.5, (2, 1): 0.5, (3, 2): 1}
Am = lambda u: [sum(A.get((i, j), 0) * u[j] for j in range(4)) for i in range(4)]
dot = lambda u, w: sum(p * q for p, q in zip(u, w))
c2, c3, ac = [x*x for x in c], [x**3 for x in c], Am(c)
sums = [sum(b), dot(b, c), dot(b, c2), dot(b, c3), dot(b, ac), dot(b, [x*y for x, y in zip(c, ac)]), dot(b, Am(c2)), dot(b, Am(ac))]
print("order conditions, one over each sum:", " ".join(f"{1/s:.0f}" for s in sums))
assert all(abs(s * t - 1) < 1e-12 for s, t in zip(sums, (1, 2, 3, 4, 6, 8, 12, 24)))
lo, hi = -3.0, -2.5                          # bisection for the stability edge R(z) = 1
for _ in range(60):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if R(mid) > 1 else (lo, mid)
big = rk4(sky, 0.0, 15, 4)
print(f"stability edge z = {lo:.4f}, so h < {-lo/0.2:.2f} s; h = 15 gives v(60) = {big:.2f}, exact {exact(60):.2f}")
assert abs(big - exact(60)) > 100 and abs(rk4(sky, 0.0, 13, 20) - exact(260)) < 1
print("ALL CHECKS PASS")
