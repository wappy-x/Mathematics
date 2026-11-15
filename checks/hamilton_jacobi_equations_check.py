# Hamilton-Jacobi equations -- the check behind the card.  Imports only math's sin, cos, sqrt, pi.
# A 40 t truck crosses a 100 km route over rolling hills; u(x, t) = least fuel (L) to be at km x at time t (h).
# Roads: the closed form, characteristics (Hamilton's equations) by RK4, a dynamic-programming grid,
# the Hopf-Lax minimum by search, and the residual u_t + H(u_x, x) by centred differences.
from math import sin, cos, sqrt, pi
K, R, W, D, T = 2.5e-5, 0.14, 0.027, 100.0, 1.25   # drag L h^2/km^3, rolling L/km, climb L/m, km, h
AMP, LAM = 30.0, 50.0                               # hills: 30 m up and down every 50 km, plus 0.4 m/km
h = lambda x: 200 + 0.4 * x + AMP * sin(2 * pi * x / LAM)         # elevation, m
dh = lambda x: 0.4 + AMP * 2 * pi / LAM * cos(2 * pi * x / LAM)   # grade, m per km
d2h = lambda x: -AMP * (2 * pi / LAM) ** 2 * sin(2 * pi * x / LAM)
b = lambda x: R + W * dh(x)                         # fuel per km that does not depend on speed, L/km
B = lambda x: R * x + W * (h(x) - h(0))             # its total from km 0 to km x, L
C = 2 / (3 * sqrt(3 * K))
L0 = lambda v: K * abs(v) ** 3                      # drag fuel per hour at speed v, L/h
H0 = lambda q: C * abs(q) ** 1.5                    # its slope transform
dH0 = lambda q: (1 if q >= 0 else -1) * sqrt(abs(q) / (3 * K))   # = speed chosen at price q
H = lambda x, p: H0(p - b(x))                       # the Hamiltonian with hills
exact = lambda x, t: K * x ** 3 / t ** 2 + B(x)     # road 1: straight line in (x, t), hills added
def tern(f, lo, hi):                                # minimiser of a one-dip function, by ternary search
    for _ in range(200):
        a, c = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, c) if f(a) < f(c) else (a, hi)
    return lo
def chars(p0, n=500):                               # road 2: x' = H_p, p' = -H_x, u' = p H_p - H, by RK4
    def f(s):
        x, p, u = s; v = dH0(p - b(x)); return (v, v * W * d2h(x), p * v - H(x, p))
    s, dt, vs = (0.0, p0, 0.0), T / n, []
    for _ in range(n):
        k1 = f(s); k2 = f([a + dt / 2 * k for a, k in zip(s, k1)]); k3 = f([a + dt / 2 * k for a, k in zip(s, k2)])
        k4 = f([a + dt * k for a, k in zip(s, k3)]); s = [a + dt / 6 * (q + 2 * r + 2 * w + z) for a, q, r, w, z in zip(s, k1, k2, k3, k4)]
        vs.append(dH0(s[1] - b(s[0])))
    return s, min(vs), max(vs)
lo, hi = b(0), b(0) + 2.0                           # shoot: find the starting price that lands on km 100
for _ in range(60):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if chars(mid)[0][0] < D else (lo, mid)
(xc, pc, uc), vmin, vmax = chars(lo)
def dp(n, M=100):                                   # road 3: best path through a 1 km x (T/n) h grid
    dt, big = T / n, 1e18; u = [0.0] + [big] * M
    for _ in range(n):
        u = [min(u[y] + K * abs(x - y) ** 3 / dt ** 2 + B(x) - B(y) for y in range(M + 1) if u[y] < big) for x in range(M + 1)]
    return u[M]
u_dp, u_dp7 = dp(25), dp(7)
ex = exact(D, T)
v_leg = tern(lambda v: -(0.48 * v - L0(v)), 0.0, 300.0)            # Legendre: H0(0.48) as a maximum
y_star = tern(lambda y: K * y ** 3 / 0.5 ** 2 + 0.75 * L0((D - y) / 0.75), 0.0, D)   # Hopf-Lax replan at 0.5 h
hl = K * y_star ** 3 / 0.25 + 0.75 * L0((D - y_star) / 0.75)
res = []
for e in (0.002, 0.001):
    ut = (exact(D, T + e) - exact(D, T - e)) / (2 * e); ux = (exact(D + e, T) - exact(D - e, T)) / (2 * e)
    res.append(abs(ut + H(D, ux)))
print(f"route: {D:.0f} km in {T:.2f} h, so {D / T:.0f} km/h; drag {K * (D / T) ** 2:.2f} L/km, rolling {R:.2f} L/km")
print(f"inputs: k = {K:.6f} L h^2/km^3, climb {W:.3f} L/m, hills h = 200 + 0.4 x + {AMP:.0f} sin(2 pi x / {LAM:.0f}) m")
print(f"by hand: 3 k v^2 = {3 * K * (D / T) ** 2:.2f} L/km, k v^3 = {K * (D / T) ** 3:.2f} L/h, 0.48 x 80 = {0.48 * D / T:.2f}; grade wave {AMP * 2 * pi / LAM:.4f} m/km, b(0) = {b(0):.5f} L/km")
print(f"climb: net {h(D) - h(0):.0f} m, costing {W * (h(D) - h(0)):.2f} L; grade from {dh(LAM / 2):.2f} to {dh(0):.2f} m/km")
print(f"speed-free fuel per km b(x): {min(b(x / 10) for x in range(1001)):.4f} to {max(b(x / 10) for x in range(1001)):.4f} L/km")
print(f"closed form: drag {K * D ** 3 / T ** 2:.2f} + rolling {R * D:.2f} + climb {W * (h(D) - h(0)):.2f} = {ex:.2f} L")
print(f"fixed fuel B(100) = {B(D):.2f} L; average {ex / D:.2f} L/km; 1.0 h deadline costs {exact(D, 1.0) - ex:.2f} L more; at 1.5 h drag {K * D ** 3 / 1.5 ** 2:.2f} L")
print(f"slopes at km 100: u_x = p = {b(D) + 3 * K * (D / T) ** 2:.5f} L/km, u_t = {-2 * K * D ** 3 / T ** 3:.2f} L/h")
print(f"price p on the 80 km/h path at km 0, 25, 50: {b(0) + 0.48:.5f} {b(25) + 0.48:.5f} {b(50) + 0.48:.5f} L/km")
print(f"Legendre: H0(0.48) = max of 0.48 v - L0(v) = {0.48 * v_leg - L0(v_leg):.2f} L/h at v = {v_leg:.2f} km/h")
print(f"characteristics: start price {lo:.5f} L/km, ends at km {xc:.4f}, fuel {uc:.4f} L, end price {pc:.5f}")
print(f"characteristics: speed stays between {vmin:.4f} and {vmax:.4f} km/h; H along it {H(xc, pc):.4f} L/h")
print(f"grid, 25 steps of {T / 25:.2f} h: {u_dp:.4f} L; 7 steps of {T / 7:.4f} h: {u_dp7:.4f} L")
print(f"Hopf-Lax replan at 0.5 h: best place {y_star:.2f} km, drag fuel {K * y_star ** 3 / 0.25:.2f} + {0.75 * L0((D - y_star) / 0.75):.2f} = {hl:.2f} L")
print(f"residual |u_t + H(u_x, x)| at step 0.002, 0.001 h or km: {1e6 * res[0]:.3f} {1e6 * res[1]:.3f} x 1e-6")
up = sum(1 for i in range(100000) if dh((i + 0.5) / 1000) > 0) / 1000   # km of climbing, by midpoint count
t_up = up / 70; v_dn = (D - up) / (T - t_up); slow = K * (70 ** 2 * up + v_dn ** 2 * (D - up))
print(f"mistake 1, fuel per km taken as per hour: drag {T * K * (D / T) ** 2:.2f} L")
print(f"mistake 2, 70 km/h on the {up:.2f} km of climbs, {v_dn:.2f} km/h elsewhere: drag {slow:.2f} L, total {slow + B(D):.2f} L")
two = lambda x, t: min(K * x ** 3 / t ** 2, K * (D - x) ** 3 / t ** 2)    # depots at km 0 and km 100, drag only
print(f"mistake 3, two depots, km 70: west characteristics {K * 70 ** 3 / T ** 2:.3f} L, Hopf-Lax minimum {two(70, T):.3f} L")
print(f"mistake 4, hill grade frozen at km 0: {K * D ** 3 / T ** 2 + b(0) * D:.2f} L")
print(f"kink at km 50: value {two(50, T):.3f} L, slope {3 * K * 50 ** 2 / T ** 2:.3f} then {-3 * K * 50 ** 2 / T ** 2:.3f} L/km")
bmin60 = R + W * (0.4 - 60 * 2 * pi / LAM)
print(f"try: deadline 1.5 h {exact(D, 1.5):.2f} L; replan at 0.75 h, best place {tern(lambda y: K * y ** 3 / 0.75 ** 2 + 0.5 * L0((D - y) / 0.5), 0.0, D):.2f} km; 60 m hills, lowest b {bmin60:.4f} L/km")
a_coast = (0.4 + (R + K * (D / T) ** 2) / W) / (2 * pi / LAM)   # hill height at which 80 km/h first coasts
print(f"try: on 60 m hills 80 km/h still burns {K * (D / T) ** 2 + bmin60:.4f} L/km on the steepest descent; L < 0 only below {sqrt(-bmin60 / K):.2f} km/h; coasting from {a_coast:.1f} m hills")
print("chart, deadline h  " + " ".join(f"{1 + i / 8:6.3f}" for i in range(9)))
print("chart, fuel L      " + " ".join(f"{exact(D, 1 + i / 8):6.2f}" for i in range(9)))
print("chart, km          " + " ".join(f"{10 * i:6d}" for i in range(11)))
print("chart, two depots  " + " ".join(f"{two(10 * i, T):6.3f}" for i in range(11)))
print("chart, west only   " + " ".join(f"{K * (10 * i) ** 3 / T ** 2:6.3f}" for i in range(11)))
assert abs(uc - ex) < 1e-6 and abs(xc - D) < 1e-6           # characteristics land on the closed form
assert abs(u_dp - ex) < 1e-6 < u_dp7 - ex                    # grid minimum over all paths agrees; misaligned grid is above
assert abs(hl - K * D ** 3 / T ** 2) < 1e-6 and abs(y_star - 40) < 1e-4   # Hopf-Lax replan = whole-trip drag
assert res[1] < res[0] / 3 and res[1] < 1e-4                # residual shrinks like step^2
assert abs(0.48 * v_leg - L0(v_leg) - H0(0.48)) < 1e-9 and vmax - vmin < 1e-6
assert slow > K * D ** 3 / T ** 2 and two(70, T) < K * 70 ** 3 / T ** 2
print("ALL CHECKS PASS")
