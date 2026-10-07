# Impulses and the delta function -- the check behind the card.  Only math is
# imported, for exp, sin, cos and atan.  The car body hits a pothole at t = 1 s:
# y'' + 2y' + 5y = delta(t - 1), at rest before it.  Road one is the transform
# answer y = u(t - 1) 0.5 e^(-(t-1)) sin 2(t - 1).  Road two never uses a delta:
# it pushes with a pulse of area 1, strength 1/eps for eps seconds, stepped by RK4.
from math import exp, sin, cos, atan
A, S, H = 1.0, 2.0, 0.0005

def ideal(t):                                   # road one: the transform's answer
    return 0.0 if t < A else 0.5 * exp(-(t - A)) * sin(2 * (t - A))

def pulse_run(eps, area=1.0, t_end=6.0):        # road two: RK4, force held per step
    y, v, ys, vs = 0.0, 0.0, [], []
    for n in range(round(t_end / H) + 1):
        ys.append(y); vs.append(v)
        f = area / eps if A <= (n + 0.5) * H < A + eps else 0.0
        rate = lambda y, v: (v, f - 2 * v - 5 * y)
        k1 = rate(y, v)
        k2 = rate(y + H / 2 * k1[0], v + H / 2 * k1[1])
        k3 = rate(y + H / 2 * k2[0], v + H / 2 * k2[1])
        k4 = rate(y + H * k3[0], v + H * k3[1])
        y += H / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += H / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return ys, vs

for eps in (0.5, 0.1, 0.01):                    # the pulse's transform, two ways
    n = 1000; d = eps / n
    mid = sum(exp(-S * (A + (k + 0.5) * d)) / eps * d for k in range(n))
    exact = exp(-S * A) * (1 - exp(-S * eps)) / (S * eps)
    print(f"pulse eps = {eps}: transform at s = 2 midpoint {mid:.6f}, formula {exact:.6f}")
    assert abs(mid - exact) < 1e-8
print(f"limit e^(-as) at a = 1, s = 2: {exp(-S * A):.6f}")
lap = sum(exp(-S * (A + (k + 0.5) * 0.001)) * ideal(A + (k + 0.5) * 0.001) * 0.001 for k in range(20000))
print(f"transform of y at s = 2: midpoint sum {lap:.8f}, e^(-2)/13 = {exp(-2) / 13:.8f}")
assert abs(lap - exp(-2) / 13) < 1e-7
errs = []
for eps in (0.2, 0.1, 0.05):
    ys, vs = pulse_run(eps)
    errs.append(max(abs(ys[n] - ideal(n * H)) for n in range(len(ys))))
    v_after = vs[round((A + eps) / H)]
    print(f"RK4 pulse eps = {eps}: worst height error {errs[-1]:.6f} cm, velocity at pulse end {v_after:.6f} cm/s")
    assert errs[-1] < eps and abs(v_after - 1) < 1.5 * eps
print(f"error ratios as eps halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f} (order 1 in eps)")
assert all(1.7 < errs[i] / errs[i + 1] < 2.3 for i in range(2))
tp = A + atan(2) / 2
grid_peak = max(ideal(A + k * 1e-5) for k in range(200000))
print(f"ideal: velocity 0 before, {0.5 * (2 * cos(0) - sin(0)):.6f} after; peak {ideal(tp):.6f} cm at t = {tp:.6f} (grid max {grid_peak:.6f})")
wide = pulse_run(0.5)[0]
print("figure, t    " + " ".join(f"{0.25 * k:5.2f}" for k in range(17)))
print("figure, ideal" + " ".join(f"{10 * ideal(0.25 * k):5.2f}" for k in range(17)) + " mm")
print("figure, 0.5 s" + " ".join(f"{10 * wide[round(0.25 * k / H)]:5.2f}" for k in range(17)) + " mm")
flat = max(pulse_run(0.01, area=0.01)[0])
print(f"mistake 1, strength 1 for 0.01 s: area 0.01, peak {flat:.6f} cm instead of {ideal(tp):.6f}")
print(f"mistake 2, delay dropped: y(1.5) = {0.5 * exp(-1.5) * sin(3):.6f} cm instead of {ideal(1.5):.6f}")
print(f"mistake 3, switch u(t - 1) dropped: y(0.5) = {0.5 * exp(0.5) * sin(-1):.6f} cm instead of {ideal(0.5):.6f}")
print("ALL CHECKS PASS")
