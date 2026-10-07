# Normal modes -- the check behind the card.  Standard library only.  Two 1 kg
# carts, three springs of 1 N/m: x'' = -K x, K = [[2, -1], [-1, 2]]; cart 1 starts
# 10 cm out, cart 2 in place, both still.  Road one: eigenvalues and modes of K,
# then the mode sum.  Road two: plain Euler steps, with periods timed from them.
import math
def modes(a, b, d):                    # K = [[a, b], [b, d]]: roots of l^2 - (a + d) l + ad - b^2
    r = math.sqrt((a + d) ** 2 - 4 * (a * d - b * b))
    return [(l, (1.0, (l - a) / b)) for l in ((a + d - r) / 2, (a + d + r) / 2)]
def exact(K, x0, t):                   # the mode sum, started from rest at x0
    x = [0.0, 0.0]
    for l, v in modes(*K):
        c = (x0[0] * v[0] + x0[1] * v[1]) / (v[0] ** 2 + v[1] ** 2)
        x = [x[i] + c * v[i] * math.cos(math.sqrt(l) * t) for i in range(2)]
    return x
def euler(K, x0, t_end, h, watch=None):   # x' = v, v' = -K x, one small step at a time
    (a, b, d), (x1, x2), v1, v2 = K, x0, 0.0, 0.0
    for n in range(round(t_end / h)):
        x1, x2, v1, v2 = x1 + h * v1, x2 + h * v2, v1 - h * (a * x1 + b * x2), v2 - h * (b * x1 + d * x2)
        if watch: watch((n + 1) * h, x1, x2)
    return x1, x2, v1, v2
def energy(K, s):                      # mJ, with x in cm and v in cm/s
    x1, x2, v1, v2 = s
    return 0.05 * (v1 * v1 + v2 * v2 + K[0] * x1 * x1 + 2 * K[1] * x1 * x2 + K[2] * x2 * x2)
K, X0, H = (2.0, -1.0, 2.0), (10.0, 0.0), 1e-4
(l1, u), (l2, w) = modes(*K)
res = max(abs(K[0] * v[0] + K[1] * v[1] - l * v[0]) + abs(K[1] * v[0] + K[2] * v[1] - l * v[1]) for l, v in modes(*K))
cross, last = ([], []), [10.0, 10.0]   # zero crossings of x1 + x2 and of x1 - x2
def watch(t, x1, x2):
    for j, val in enumerate((x1 + x2, x1 - x2)):
        if val * last[j] < 0: cross[j].append(t - H * val / (val - last[j]))
        last[j] = val
euler(K, X0, 20, H, watch)
per = [2 * (c[-1] - c[0]) / (len(c) - 1) for c in cross]
errs = [abs(euler(K, X0, 10, h)[0] - exact(K, X0, 10)[0]) for h in (0.01, 0.005, 0.0025)]
ts, fine = [i / 2 for i in range(25)], euler(K, X0, 10, 1e-5)
W = (1.05, -0.05, 1.05)                # weak middle spring, 0.05 N/m: the carts trade the motion
dw = math.sqrt(modes(*W)[1][0]) - math.sqrt(modes(*W)[0][0]); T = math.pi / dw
peak = [0.0, 0.0]
def watch_w(t, x1, x2):
    if abs(t - T) < math.pi: peak[0], peak[1] = max(peak[0], abs(x1)), max(peak[1], abs(x2))
euler(W, X0, T + math.pi, 1e-5, watch_w)
print(f"trace {K[0] + K[2]:.0f}, determinant {K[0] * K[2] - K[1] ** 2:.0f}: eigenvalues {l1:.0f} and {l2:.0f}, modes {u} and {w}")
print(f"largest |K v - lambda v| {res:.12f}; modes' dot product {u[0] * w[0] + u[1] * w[1]:.0f}; frequencies {math.sqrt(l1):.3f} and {math.sqrt(l2):.3f} rad/s; periods {2 * math.pi / math.sqrt(l1):.3f} and {2 * math.pi / math.sqrt(l2):.3f} s")
print(f"start (10, 0) cm = 5 x (1, 1) + 5 x (1, -1); energy {energy(K, (*X0, 0, 0)):.2f} mJ = {0.5 * l1 * 50 * 0.1:.2f} slow + {0.5 * l2 * 50 * 0.1:.2f} fast")
print("t (s)  ", " ".join(f"{t:g}" for t in ts))
for i in range(2): print(f"x{i + 1} (cm)", " ".join(f"{exact(K, X0, t)[i]:.2f}" for t in ts))
print(f"t = 10 s: mode sum x1 {exact(K, X0, 10)[0]:.3f}, x2 {exact(K, X0, 10)[1]:.3f} cm; Euler h = 0.00001 x1 {fine[0]:.3f}, x2 {fine[1]:.3f} cm")
print("Euler error in x1 at t = 10, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.4f}" for e in errs), f"ratios {errs[0] / errs[1]:.2f} {errs[1] / errs[2]:.2f}")
print(f"periods timed from Euler's zero crossings: x1 + x2 {per[0]:.3f} s, x1 - x2 {per[1]:.3f} s")
print(f"weak middle spring: eigenvalues {modes(*W)[0][0]:.2f} and {modes(*W)[1][0]:.2f}, frequencies {math.sqrt(modes(*W)[0][0]):.3f} and {math.sqrt(modes(*W)[1][0]):.4f} rad/s; cart 1 hands over at pi/{dw:.4f} = {T:.2f} s")
print(f"within pi s of {T:.2f} s: largest |x1| {peak[0]:.2f} cm (envelope says <= {10 * math.sin(dw * math.pi / 2):.2f}), largest |x2| {peak[1]:.2f} cm")
print(f"mistake, eigenvalue as frequency: fast period 2 pi/3 = {2 * math.pi / 3:.3f} s, not {2 * math.pi / math.sqrt(3):.3f}")
print(f"mistake, share without dividing by |v|^2: {X0[0] * u[0] + X0[1] * u[1]:.0f} x (1, 1) + {X0[0] * w[0] + X0[1] * w[1]:.0f} x (1, -1) starts x1 at {X0[0] * u[0] + X0[1] * u[1] + X0[0] * w[0] + X0[1] * w[1]:.0f} cm")
print(f"mistake, wall springs dropped: frequencies {math.sqrt(modes(1.0, -1.0, 1.0)[0][0]):.3f} and {math.sqrt(modes(1.0, -1.0, 1.0)[1][0]):.3f} rad/s")
print(f"mistake, Euler with h = 0.1 to t = 20: energy {energy(K, euler(K, X0, 20, 0.1)):.0f} mJ, not 10")
assert res < 1e-12 and abs(per[0] - 2 * math.pi) < 1e-3 and abs(per[1] - 2 * math.pi / math.sqrt(3)) < 1e-3
assert abs(fine[0] - exact(K, X0, 10)[0]) < 2e-3 and abs(fine[1] - exact(K, X0, 10)[1]) < 2e-3
assert all(1.8 < errs[i] / errs[i + 1] < 2.3 for i in range(2))      # error halves with h: order one
assert peak[1] > 9.5 and peak[0] <= 10 * math.sin(dw * math.pi / 2) + 0.02
print("ALL CHECKS PASS")
