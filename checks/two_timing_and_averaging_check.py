# Two-timing and averaging -- the check behind the card.  Only math is imported; RK4 and cycle
# averages are written out.  Road one: the full equations.  Road two: the slow amplitude law.
import math
EPS, R0, GOAL = 0.1, 0.5, 1.9
def rk4(f, p, h):
    k1 = f(p); k2 = f([p[i] + h / 2 * k1[i] for i in (0, 1)])
    k3 = f([p[i] + h / 2 * k2[i] for i in (0, 1)]); k4 = f([p[i] + h * k3[i] for i in (0, 1)])
    return [p[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)]
vdp = lambda p: [p[1], -EPS * (p[0] ** 2 - 1) * p[1] - p[0]]     # x'' + 0.1(x^2 - 1)x' + x = 0
duf = lambda p: [p[1], -p[0] - EPS * p[0] ** 3]                  # x'' + x + 0.1 x^3 = 0
avg = lambda g, n=360: sum(g(2 * math.pi * (k + 0.5) / n) for k in range(n)) / n
h_vdp = lambda r, s: (r * r * math.cos(s) ** 2 - 1) * (-r * math.sin(s))   # h(x, x') on x = r cos s
drift = lambda r: EPS * avg(lambda s: h_vdp(r, s) * math.sin(s))           # r' = eps <h sin s>
law = lambda r: EPS / 2 * r * (1 - r * r / 4)
closed = lambda t: 2 / math.sqrt(1 + (4 / R0 ** 2 - 1) * math.exp(-EPS * t))
t_hit = lambda e=EPS: math.log((4 / R0 ** 2 - 1) / (4 / GOAL ** 2 - 1)) / e
def root(f, lo=1.0, hi=3.0):                        # bisection: where a drift falls to zero
    for _ in range(50): lo, hi = ((lo + hi) / 2, hi) if f((lo + hi) / 2) > 0 else (lo, (lo + hi) / 2)
    return lo
r, t, h = R0, 0.0, 0.01                             # road two: step r' = drift(r) to 1.9
while r < GOAL:
    k1 = drift(r); k2 = drift(r + h / 2 * k1); k3 = drift(r + h / 2 * k2); k4 = drift(r + h * k3)
    r_new = r + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    t, r = t + (h if r_new < GOAL else h * (GOAL - r) / (r_new - r)), r_new
def peaks(f, p, t_end, h):                          # times and heights of the maxima of x
    out, k = [(0.0, p[0])], 0
    while k * h < t_end:
        q = rk4(f, p, h); k += 1
        if p[1] > 0 >= q[1]: out.append(((k - 1 + p[1] / (p[1] - q[1])) * h, max(p[0], q[0])))
        p = q
    return out
def cross(pk, i, v):                                # where the line between peaks hits value v
    (a, x), (b, y) = next((u, w) for u, w in zip(pk, pk[1:]) if w[i] >= v)
    return (x + (y - x) * (v - a) / (b - a)) if i == 0 else a + (b - a) * (v - x) / (y - x)
pk = peaks(vdp, [R0, 0.0], 110, 0.001)              # road one: the full van der Pol law
full, t_full = [cross(pk, 0, t) for t in range(0, 101, 10)], cross(pk, 1, GOAL)
ups = [t for t, _ in peaks(duf, [1.0, 0.0], 62, 0.001)]
w_rk = 2 * math.pi * (len(ups) - 1) / (ups[-1] - ups[0])
c4 = avg(lambda s: math.cos(s) ** 4)                # r phi' = eps <h cos s>, h = r^3 cos^3 s
wrong = root(lambda r: EPS * (-r) * (r * r / 4 - 1 / 2))   # <cos^2 sin^2> taken as 1/2 x 1/2
print(f"averaged drift at r = 0.5: by quadrature {drift(R0):.7f}, by 0.05 r(1 - r^2/4) {law(R0):.7f}")
print(f"drift is zero at r = {root(drift):.4f}: every start settles at amplitude 2")
print(f"closed form: 4/0.5^2 - 1 = {4 / R0 ** 2 - 1:.0f}, 4/1.9^2 - 1 = {4 / GOAL ** 2 - 1:.5f}; r = 1.9 at t = {t_hit():.2f}")
print(f"stepping the averaged law: r = 1.9 at t = {t:.2f}")
print(f"full law by RK4: peak height reaches 1.9 at t = {t_full:.2f}; peak at t = 100: {full[-1]:.4f}")
print(f"t = {t_hit():.2f} is {t_hit() / (2 * math.pi):.2f} swings; at 1 kHz, {t_hit() / (2 * math.pi):.2f} ms")
print(f"naive expansion: amplitude 0.5 + {law(R0):.7f} t, at t = 100: {R0 + 100 * law(R0):.2f}")
print(f"Duffing at amplitude 1: averaging 1 + 0.1 x {c4:.4f} = {1 + EPS * c4:.4f}; RK4 {w_rk:.4f}")
print("chart t:", list(range(0, 101, 10)))
print("chart full law:", " ".join(f"{a:.2f}" for a in full))
print("chart averaged:", " ".join(f"{closed(t):.2f}" for t in range(0, 101, 10)))
print("chart naive:", " ".join(f"{R0 + t * law(R0):.2f}" for t in range(0, 101, 10)))
print(f"mistake 1, <cos^2 sin^2> taken as 1/2 x 1/2: settles at {wrong:.2f}, not 2")
print(f"mistake 2, dropping the 1/2 in r': r = 1.9 at t = {t_hit(2 * EPS):.2f}, not {t_hit():.2f}")
print(f"mistake 3, Duffing shift 3/4 instead of 3/8: frequency {1 + 2 * c4 * EPS:.4f}, not {1 + EPS * c4:.4f}")
assert abs(drift(R0) - law(R0)) < 1e-12 and abs(root(drift) - 2) < 1e-9   # quadrature meets formula
assert abs(t - t_hit()) < 0.01 and abs(t_hit() - 49.33) < 0.005 and abs(closed(t) - GOAL) < 1e-3   # stepping meets closed form
assert abs(t_full - t_hit()) < 0.5 and abs(full[-1] - 2) < 0.01            # full law follows slow law
assert abs(w_rk - (1 + EPS * c4)) < 0.002 and abs(c4 - 3 / 8) < 1e-12      # Duffing: RK4 meets averaging
print("ALL CHECKS PASS")
