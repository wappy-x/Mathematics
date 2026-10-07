# The eigenvalue method -- the check behind the card.  Standard library only.
# Two rooms, heating off, outside 0 C, time in hours: T1' = -2 T1 + T2,
# T2' = T1 - 2 T2, start (30, 10).  Road one: eigenvalues, eigenvectors, modes
# fitted to the start.  Road two: Euler steps on the coupled rates.
import math
def eigen(a):              # roots of L^2 - trace L + det = 0, and a direction for each
    tr, det = a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]
    lams = [(tr + math.sqrt(tr * tr - 4 * det)) / 2, (tr - math.sqrt(tr * tr - 4 * det)) / 2]
    return lams, [(a[0][1], lam - a[0][0]) for lam in lams]   # from row 1 of (A - L I) v = 0
def fit(vs, x0):           # c1 v1 + c2 v2 = x0, solved by Cramer's rule
    (p, q), (r, s) = vs
    return [(x0[0] * s - r * x0[1]) / (p * s - r * q), (p * x0[1] - q * x0[0]) / (p * s - r * q)]
def modes(lams, vs, cs, t):
    return [sum(c * math.exp(l * t) * v[i] for l, v, c in zip(lams, vs, cs)) for i in range(2)]
def rate(a, x):
    return [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]]
def euler(a, x, t_end, h):  # new state = old state + h x rate, repeated
    for _ in range(round(t_end / h)):
        x = [x[i] + h * rate(a, x)[i] for i in range(2)]
    return x
def peak(a, x, h):          # step until room 2 stops warming
    t = 0.0
    while rate(a, x)[1] > 0:
        x, t = euler(a, x, h, h), t + h
    return t, x[1]

A, B, J, X0 = [[-2, 1], [1, -2]], [[-3, 1], [2, -4]], [[-1, 1], [0, -1]], [30.0, 10.0]
vec = lambda v, d=0: f"({v[0]:.{d}f}, {v[1]:.{d}f})"
lams, vs = eigen(A); cs = fit(vs, X0)
T = lambda t: modes(lams, vs, cs, t)
ts, fig = [k / 4 for k in range(13)], [0, 0.1, 0.2, 0.3, 0.5, 0.75, 1, 1.5, 2, 3]
errs = [abs(euler(A, X0, 1, h)[0] - T(1)[0]) for h in (0.01, 0.005, 0.0025)]
eu1, pk = euler(A, X0, 1, 1e-4), peak(A, X0, 1e-5)
print(f"eigenvalues {lams[0]:.0f}, {lams[1]:.0f} per hour; eigenvectors {vec(vs[0])}, {vec(vs[1])}")
print(f"A times them: {vec(rate(A, vs[0]))}, {vec(rate(A, vs[1]))}; weights c1 = {cs[0]:.0f}, c2 = {cs[1]:.0f}")
print("t (h)  ", " ".join(f"{t:.2f}" for t in ts))
print("T1 (C) ", " ".join(f"{T(t)[0]:.2f}" for t in ts))
print("T2 (C) ", " ".join(f"{T(t)[1]:.2f}" for t in ts))
print(f"at 1 h: slow piece {cs[0] * math.exp(lams[0]):.4f}, fast piece {cs[1] * math.exp(lams[1]):.4f}; modes {vec(T(1), 4)}; Euler h = 0.0001 {vec(eu1, 4)}")
print("Euler error in T1 at 1 h, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.5f}" for e in errs), f"; ratios {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"average {cs[0]:.0f} e^-t, half-life {math.log(2):.3f} h; difference {2 * cs[1]:.0f} e^-3t, half-life {math.log(2) / 3:.3f} h")
print(f"rooms within 1 C of each other at ln 20 / 3 = {math.log(20) / 3:.3f} h; average within 1 C of outside at ln 20 = {math.log(20):.3f} h")
print(f"room 2 peak: formula t = ln 1.5 / 2 = {math.log(1.5) / 2:.4f} h, {T(math.log(1.5) / 2)[1]:.3f} C; Euler {pk[0]:.4f} h, {pk[1]:.3f} C")
print("figure, path at 9 px per C, origin (50, 170):", " ".join(f"{50 + 9 * T(t)[0]:.1f},{170 - 9 * T(t)[1]:.1f}" for t in fig))
lb, vb = eigen(B); cb = fit(vb, X0)       # second case: room 2 half the size
print(f"half-size room: eigenvalues {lb[0]:.0f}, {lb[1]:.0f}; eigenvectors {vec(vb[0])}, {vec(vb[1])}; weights {cb[0]:.3f}, {cb[1]:.3f}")
print(f"half-size room at 1 h: modes {vec(modes(lb, vb, cb, 1), 4)}; Euler {vec(euler(B, X0, 1, 1e-4), 4)}")
wrong = [X0[0] + X0[1], X0[0] - X0[1]]                          # P times the start, not P inverse
print(f"mistake, P for its inverse: weights {vec(wrong)} rebuild the start as {vec([wrong[0] + wrong[1], wrong[0] - wrong[1]])}")
print(f"mistake, rates swapped: T1(1) = {cs[0] * math.exp(-3) + cs[1] * math.exp(-1):.4f}, not {T(1)[0]:.4f}")
dots = [(X0[0] * v[0] + X0[1] * v[1]) / (v[0] ** 2 + v[1] ** 2) for v in vb]
print(f"mistake, dot products on the half-size room: weights {vec(dots)} rebuild {vec([dots[0] + dots[1], dots[0] * vb[0][1] + dots[1] * vb[1][1]])}")
lj, vj = eigen(J)
print(f"mistake, J: eigenvalues {lj[0]:.0f}, {lj[1]:.0f}, one direction {vec(vj[0])}; Euler T1(1) = {euler(J, X0, 1, 1e-5)[0]:.4f}, (30 + 10t) e^-t = {40 / math.e:.4f}")
for lam, v in zip(lams, vs):
    assert max(abs(rate(A, v)[i] - lam * v[i]) for i in range(2)) < 1e-12   # row 2 agrees too
assert max(abs(eu1[i] - T(1)[i]) for i in range(2)) < 1e-3 and abs(pk[0] - math.log(1.5) / 2) < 1e-4
assert all(1.8 < r < 2.2 for r in (errs[0] / errs[1], errs[1] / errs[2]))  # Euler is order one
assert max(abs(euler(B, X0, 1, 1e-4)[i] - modes(lb, vb, cb, 1)[i]) for i in range(2)) < 1e-3
print("ALL CHECKS PASS")
