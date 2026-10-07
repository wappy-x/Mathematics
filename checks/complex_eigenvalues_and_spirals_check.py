# Complex eigenvalues and spirals -- the check behind the card.  Standard
# library only.  The shock absorber y' = v, v' = -5y - 2v (y in cm, v in cm/s,
# start y = 10, v = 0) is solved by two roads: the real solutions built from
# w e^(lambda t), and Euler's small steps along the slope, which never call
# exp, cos or sin.  The stepped run's crossings of y = 0 time one turn.
import math

def pair(M):                              # eigenvalues alpha +/- i beta of a 2x2
    tr, det = M[0][0] + M[1][1], M[0][0] * M[1][1] - M[0][1] * M[1][0]
    return tr / 2, math.sqrt(4 * det - tr * tr) / 2, tr, det

A = ((0.0, 1.0), (-5.0, -2.0))
al, be, tr, det = pair(A)
p, q = (1.0, (al - A[0][0]) / A[0][1]), (0.0, be / A[0][1])  # w = p + i q, from row 1
c1, c2 = 10.0, -10.0 * p[1] / q[1]       # start (10, 0) = c1 p + c2 q, as p = (1, .), q = (0, .)

def closed(t):                            # c1 Re(w e^(lambda t)) + c2 Im(w e^(lambda t))
    e, c, s = math.exp(al * t), math.cos(be * t), math.sin(be * t)
    return [e * (c1 * (p[i] * c - q[i] * s) + c2 * (p[i] * s + q[i] * c)) for i in (0, 1)]

def euler(t_end, n):                      # n steps: new state = old + h x (A times state)
    y, v, t, down, h = 10.0, 0.0, 0.0, [], t_end / n
    for _ in range(n):
        ny, nv = y + h * (A[0][0] * y + A[0][1] * v), v + h * (A[1][0] * y + A[1][1] * v)
        if y > 0 >= ny: down.append(t + h * y / (y - ny))   # passing rest, moving down
        y, v, t = ny, nv, t + h
    return (y, v), down
T = 2 * math.pi / be
errs = [math.dist(euler(T, n)[0], closed(T)) for n in (300, 600, 1200)]
fine, down = euler(T, 30000)[0], euler(5.0, 50000)[1]
fd = [(a - b) / 2e-6 for a, b in zip(closed(1.0 + 1e-6), closed(1.0 - 1e-6))]
law = [A[i][0] * closed(1.0)[0] + A[i][1] * closed(1.0)[1] for i in (0, 1)]
px = lambda s: (96 + 22 * s[0], 56 - 12 * s[1])        # 22 px per cm, 12 px per cm/s
pts = [px(closed(k * T / 48)) for k in range(49)]
d = [pts[7][i] - pts[5][i] for i in (0, 1)]
d = [x / math.hypot(*d) for x in d]           # direction of travel at pts[6], unit length
arrow = [(pts[6][0] + 7 * d[0], pts[6][1] + 7 * d[1])] + [(pts[6][0] - 5 * d[0] + 5 * k * d[1], pts[6][1] - 5 * d[1] - 5 * k * d[0]) for k in (1, -1)]
print(f"A: trace {tr:.0f}, det {det:.0f}, discriminant {tr * tr - 4 * det:.0f}; eigenvalues {al:.0f} +/- {be:.0f}i")
print(f"eigenvector w = p + i q: p = ({p[0]:.0f}, {p[1]:.0f}), q = ({q[0]:.0f}, {q[1]:.0f}); start (10, 0) = {c1:.0f} p + {c2:.0f} q")
print(f"coefficients of cos 2t, sin 2t times e^(-t): y {c1 * p[0] + c2 * q[0]:.0f}, {c2 * p[0] - c1 * q[0]:.0f} cm; v {c1 * p[1] + c2 * q[1]:.0f}, {c2 * p[1] - c1 * q[1]:.0f} cm/s")
print(f"rate at start: y' = {A[0][0] * 10:.0f} cm/s, v' = {A[1][0] * 10:.0f} cm/s^2, so the state turns clockwise")
print(f"one turn T = 2 pi / {be:.0f} = {T:.4f} s; shrink per turn e^(alpha T) = {math.exp(al * T):.4f}")
print(f"y(T): closed form {closed(T)[0]:.4f} cm; Euler, 30000 steps: {fine[0]:.4f} cm, ratio to start {fine[0] / 10:.4f}")
print(f"Euler error at T, 300, 600, 1200 steps: {errs[0]:.4f} {errs[1]:.4f} {errs[2]:.4f}; ratios {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"first pass through rest: closed form (pi - atan 2) / 2 = {(math.pi - math.atan(2)) / 2:.4f} s; Euler {down[0]:.4f} s")
print(f"one turn timed from the Euler run: {down[1]:.4f} - {down[0]:.4f} = {down[1] - down[0]:.4f} s")
print(f"law at t = 1: finite difference ({fd[0]:.6f}, {fd[1]:.6f}); A x = ({law[0]:.6f}, {law[1]:.6f})")
a2, b2, _, _ = pair(((0.0, 1.0), (-5.0, 2.0)))
print(f"second case, damping -2: eigenvalues {a2:.0f} +/- {b2:.0f}i; grows by e^(alpha T) = {math.exp(a2 * 2 * math.pi / b2):.2f} per turn")
print(f"mistake, T = 2 pi / |lambda| = 2 pi / sqrt 5 = {2 * math.pi / math.sqrt(al * al + be * be):.2f} s, not {T:.2f} s")
print(f"mistake, a turn taken as 2 pi s: shrink e^(-2 pi) = {math.exp(-2 * math.pi):.4f}, not {math.exp(al * T):.4f}")
print(f"mistake, real part alone: starts at ({c1 * p[0]:.0f}, {c1 * p[1]:.0f}), not (10, 0)")
print(f"hypothesis dropped, complex x' = i x: Re e^(it) = cos t has rate {-math.sin(1):.4f} at t = 1; the law asks {math.cos(1):.4f}i")
print("figure, spiral px:", " ".join(f"{a:.1f},{b:.1f}" for a, b in pts))
print("figure, arrow px:", " ".join(f"{a:.1f},{b:.1f}" for a, b in arrow))
assert abs(fine[0] - closed(T)[0]) < 1e-3 and abs(fine[1] - closed(T)[1]) < 1e-3   # road two meets road one
assert all(1.9 < r < 2.1 for r in (errs[0] / errs[1], errs[1] / errs[2]))         # Euler is order one
assert abs((down[1] - down[0]) - T) < 1e-3                                        # turn timed = 2 pi / beta
assert max(abs(a - b) for a, b in zip(fd, law)) < 1e-6                             # the answer obeys the law
print("ALL CHECKS PASS")
