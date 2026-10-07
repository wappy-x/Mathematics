# Forced systems -- the check behind the card.  Standard library only.
# Two rooms, C above outdoors, t in hours: x' = Ax + b, heater b = (15, 0).
# Road one: modes, xeq + e^(At)(x0 - xeq).  Road two: e^(At) x0 + integral of
# e^(A(t-s)) b, Simpson's rule, e^(Aw) by power series.  Road three: Euler.
import math
A, INS, B = [[-2.0, 1.0], [1.0, -2.0]], [[-1.0, 1.0], [1.0, -1.0]], [15.0, 0.0]
def mv(M, v): return [M[0][0] * v[0] + M[0][1] * v[1], M[1][0] * v[0] + M[1][1] * v[1]]
def modes(t, v):                          # e^(At) v by the eigenvectors (1, 1) and (1, -1)
    p, m = (v[0] + v[1]) / 2 * math.exp(-t), (v[0] - v[1]) / 2 * math.exp(-3 * t)
    return [p + m, p - m]
def series(M, w, v):                      # e^(Mw) v = v + Mwv + (Mw)^2 v / 2! + ...
    out, term = v[:], v[:]
    for k in range(1, 40):
        term = [c * w / k for c in mv(M, term)]
        out = [o + c for o, c in zip(out, term)]
    return out
def pushed(M, t, s1, s2, n=200):          # input from s1 to s2, each moment carried to t
    h, tot = (s2 - s1) / n, [0.0, 0.0]
    for i in range(n + 1):
        wt = h / 3 * (1 if i in (0, n) else 4 if i % 2 else 2)
        tot = [a + wt * c for a, c in zip(tot, series(M, t - s1 - i * h, B))]
    return tot
det = A[0][0] * A[1][1] - A[0][1] * A[1][0]  # Cramer's rule for A xeq = -b
XEQ = [-(A[1][1] * B[0] - A[0][1] * B[1]) / det, -(A[0][0] * B[1] - A[1][0] * B[0]) / det]
def closed(t, x0):
    d = modes(t, [x0[0] - XEQ[0], x0[1] - XEQ[1]])
    return [XEQ[0] + d[0], XEQ[1] + d[1]]
def road2(t, x0): return [a + c for a, c in zip(series(A, t, x0), pushed(A, t, 0, t))]
def euler(t, h, x):
    for _ in range(round(t / h)):
        x = [a + h * (r + c) for a, r, c in zip(x, mv(A, x), B)]
    return x
def f(v): return "(" + ", ".join(f"{c:.4f}" for c in v) + ")"
cold, house = [0.0, 0.0], [30.0, 10.0]
c2, h2, errs = closed(2, cold), closed(2, house), [abs(euler(2, h, cold)[0] - closed(2, cold)[0]) for h in (0.01, 0.005, 0.0025)]
slices = [pushed(A, 2, s, s + 0.5)[0] for s in (0, 0.5, 1, 1.5)]
fd = [(a - b) / 0.002 for a, b in zip(closed(1.001, cold), closed(0.999, cold))]
print(f"det A = {det:.0f}; settles at xeq = -A^(-1) b = {f(XEQ)}")
print("t (h)     ", ", ".join(f"{k / 2:.1f}" for k in range(9)))
print("room 1 (C)", ", ".join(f"{closed(k / 2, cold)[0]:.2f}" for k in range(9)))
print("room 2 (C)", ", ".join(f"{closed(k / 2, cold)[1]:.2f}" for k in range(9)))
g = [(XEQ[0] + XEQ[1]) / 2, (XEQ[0] - XEQ[1]) / 2]
print(f"cold gap = -{g[0]:.1f}(1, 1) - {g[1]:.1f}(1, -1); e^(-2) = {math.exp(-2):.5f}, e^(-6) = {math.exp(-6):.5f}; {g[0]:.1f}e^(-2) = {g[0] * math.exp(-2):.5f}, {g[1]:.1f}e^(-6) = {g[1] * math.exp(-6):.5f}")
print(f"cold start, t = 2: modes {f(c2)}; integral {f(road2(2, cold))}; Euler {f(euler(2, 0.0025, cold))}")
print(f"house start (30, 10), t = 2: free decay {f(modes(2, house))}; total {f(h2)}; integral {f(road2(2, house))}")
print("half-hour slices of heat, carried to t = 2, room 1:", " ".join(f"{v:.4f}" for v in slices), f"sum {sum(slices):.4f}; each slice puts in {B[0] / 2:.1f}")
print("Euler error, room 1 at t = 2, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.5f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"rate at t = 1: finite difference {f(fd)}; law Ax + b {f([r + c for r, c in zip(mv(A, closed(1, cold)), B)])}")
print(f"mistake, heat added unpropagated: room 1 = {B[0] * 2:.2f}")
print(f"mistake, all heat aged from t = 0: room 1 = {2 * modes(2, B)[0]:.4f}")
print(f"mistake, settled state only: room 1 = {XEQ[0]:.2f} at every t, even t = 0")
ins = pushed(INS, 2, 0, 2)
r = [a + c for a, c in zip(mv(INS, ins), B)]
print(f"insulated walls, det = {INS[0][0] * INS[1][1] - INS[0][1] * INS[1][0]:.0f}: room 1 at t = 2 = {ins[0]:.4f}; formula 15 + 3.75(1 - e^(-4)) = {15 + 3.75 * (1 - math.exp(-4)):.4f}; average climbs {(r[0] + r[1]) / 2:.1f} per hour")
assert max(abs(a - b) for a, b in zip(road2(2, house), h2)) < 1e-7   # road two meets road one
assert 1.9 < errs[0] / errs[1] < 2.1 and 1.9 < errs[1] / errs[2] < 2.1   # road three, order one
assert max(abs(a - b) for a, b in zip(fd, [r + c for r, c in zip(mv(A, closed(1, cold)), B)])) < 1e-5
assert abs(ins[0] - (15 + 3.75 * (1 - math.exp(-4)))) < 1e-6          # insulated: no settling
print("ALL CHECKS PASS")
