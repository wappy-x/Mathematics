# Lie bracket and Frobenius theorem -- the check behind the card.  Standard library only.
# A car's state q = (x, y, th): rear-axle middle x along the street, y toward the curb (m),
# heading th (rad, anticlockwise).  A = drive on full left lock, B = drive on full right lock.
from math import sin, cos, atan2, sqrt, pi
r = 5.0                                      # rear-axle turning radius at full lock, m
def A(q): return [cos(q[2]), sin(q[2]), 1 / r]
def B(q): return [cos(q[2]), sin(q[2]), -1 / r]
def arc(q, k, s):                            # exact flow: drive s metres along curvature k
    x, y, th = q
    return [x + (sin(th + k * s) - sin(th)) / k, y - (cos(th + k * s) - cos(th)) / k, th + k * s]
def fA(q, s): return arc(q, 1 / r, s)
def fB(q, s): return arc(q, -1 / r, s)
def sub(u, v): return [a - b for a, b in zip(u, v)]
def bracket(X, Y, q, h=1e-5):                # [X,Y]^i = X^j d_j Y^i - Y^j d_j X^i, central differences
    out, Xq, Yq = [0.0] * len(q), X(q), Y(q)
    for j in range(len(q)):
        qp, qm = list(q), list(q); qp[j] += h; qm[j] -= h
        dY = [(a - b) / (2 * h) for a, b in zip(Y(qp), Y(qm))]
        dX = [(a - b) / (2 * h) for a, b in zip(X(qp), X(qm))]
        out = [o + Xq[j] * a - Yq[j] * b for o, a, b in zip(out, dY, dX)]
    return out
def closed(q): return [-2 / r * sin(q[2]), 2 / r * cos(q[2]), 0.0]   # by hand: (2/r)(-sin th, cos th, 0)
def side(q, v): return -sin(q[2]) * v[0] + cos(q[2]) * v[1]          # sideways speed: the no-skid form
def z(a, n=4): return 0.0 if abs(a) < 0.5 * 10.0 ** -n else a        # no "-0.0000" in print
def fmt(v, n=4): return "(" + ", ".join(f"{z(a, n):.{n}f}" for a in v) + ")"
q0 = [0.0, 0.0, 0.0]

# Overview: parallel parking, two reverse moves of 3.5 m, in both orders
s = 3.5
LR, RL = fB(fA(q0, -s), -s), fA(fB(q0, -s), -s)
print(f"park, left lock then right lock, back {s} m each: end {fmt(LR, 2)}")
print(f"park, right lock then left lock, back {s} m each: end {fmt(RL, 2)}")
print(f"swap gap {LR[1] - RL[1]:.2f} m sideways; bracket estimate s^2 x 2/r = {s * s * 2 / r:.2f} m")

# Road 1 and 2: the bracket by hand and by the coordinate formula
br = bracket(A, B, q0)
print(f"[A,B] at the start: by hand {fmt(closed(q0))}, by formula {fmt(br)}")
print(f"A {fmt(A(q0))}, B {fmt(B(q0))}; first term only {fmt([A(q0)[2] * d for d in [0.0, 1.0, 0.0]])}")
q30 = [0.0, 0.0, pi / 6]
print(f"[A,B] at heading 30 deg: by hand {fmt(closed(q30))}, by formula {fmt(bracket(A, B, q30))}")

# Road 3: swap gap over s^2 as the moves shrink (the chart's points)
gaps = []
for k in range(1, 9):
    s = 0.5 * k
    g = sub(fB(fA(q0, s), s), fA(fB(q0, s), s)); gaps.append(g[1] / s ** 2)
    assert abs(g[1] - 4 * r * (1 - cos(s / r))) < 1e-12 and abs(g[0]) < 1e-12
print("swap gap / s^2, s = 0.5 to 4.0 m: " + ", ".join(f"{v:.4f}" for v in gaps))
print(f"errors from 0.4 at s = 1 and 0.5 m: {0.4 - gaps[1]:.6f}, {0.4 - gaps[0]:.6f}")
print(f"wrong: gap / s, s = 1 and 0.5 m: {gaps[1] * 1.0:.4f}, {gaps[0] * 0.5:.4f}")

# Road 4: the four-move loop: left s, right s, left back s, right back s
def loop(s): return fB(fA(fB(fA(q0, s), s), -s), -s)
for s in (1.0, 0.5):
    e = loop(s)
    print(f"loop of {s} m moves: end {fmt(e)}; y / s^2 = {e[1] / s ** 2:.4f}")

# Road 5: a second chart, polar about a lamp post: (rho, al, th), car at x = 4, y = 3
def cart(p): return [p[0] * cos(p[1]), p[0] * sin(p[1]), p[2]]
def to_polar(F):
    def G(p):
        x, y, _ = cart(p); v = F(cart(p)); rho2 = x * x + y * y
        return [(x * v[0] + y * v[1]) / sqrt(rho2), (x * v[1] - y * v[0]) / rho2, v[2]]
    return G
p = [5.0, atan2(3.0, 4.0), 0.0]
bp = bracket(to_polar(A), to_polar(B), p)
back = [cos(p[1]) * bp[0] - p[0] * sin(p[1]) * bp[1], sin(p[1]) * bp[0] + p[0] * cos(p[1]) * bp[1], bp[2]]
print(f"polar chart at (4, 3): A {fmt(to_polar(A)(p))}, [A,B] {fmt(bp)}, back in x, y {fmt(back)}")

# Road 6: Lie derivative: pull B back along A's flow, then take the rate
def pulled(t, e=1e-6):
    m = fA(q0, t); v = B(m)
    hi, lo = fA([a + e * b for a, b in zip(m, v)], -t), fA([a - e * b for a, b in zip(m, v)], -t)
    return [(a - b) / (2 * e) for a, b in zip(hi, lo)]
t = 1e-3
lie = [(a - b) / (2 * t) for a, b in zip(pulled(t), pulled(-t))]
print(f"Lie derivative L_A B at the start: {fmt(lie)}")

# Frobenius, car: is [A,B] inside the no-skid plane?
det = A(q0)[0] * (B(q0)[1] * br[2] - B(q0)[2] * br[1]) - A(q0)[1] * (B(q0)[0] * br[2] - B(q0)[2] * br[0]) \
    + A(q0)[2] * (B(q0)[0] * br[1] - B(q0)[1] * br[0])
print(f"car: sideways part of A {z(side(q0, A(q0))):.4f}, of B {z(side(q0, B(q0))):.4f}, of [A,B] {side(q0, br):.4f}")
print(f"car: det(A, B, [A,B]) = {det:.4f}; 4/r^2 = {4 / r ** 2:.4f}")
# RK4 against the exact arc for the 3.5 m park
def rk4(F, q, s, n):
    h = s / n
    for _ in range(n):
        k1 = F(q); k2 = F([a + h / 2 * b for a, b in zip(q, k1)]); k3 = F([a + h / 2 * b for a, b in zip(q, k2)])
        k4 = F([a + h * b for a, b in zip(q, k3)])
        q = [a + h / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(q, k1, k2, k3, k4)]
    return q
for n in (10, 20):
    print(f"park by RK4, {n} steps per move: y {rk4(B, rk4(A, q0, -3.5, n), -3.5, n)[1]:.8f}; exact {LR[1]:.8f}")

# Frobenius, roof: planes dz = (y dx + x dy)/20, and the twisted planes dz = y dx/20
U = lambda q: [1.0, 0.0, q[1] / 20]
V = lambda q: [0.0, 1.0, q[0] / 20]
V2 = lambda q: [0.0, 1.0, 0.0]
W = lambda q: [c * (1 + q[0] / 4) for c in V(q)]
om = lambda q, v: v[2] - (q[1] * v[0] + q[0] * v[1]) / 20
om2 = lambda q, v: v[2] - q[1] * v[0] / 20
p0 = [4.0, 2.0, 0.4]
for name, X, Y, w in (("roof [U,V]", U, V, om), ("roof [U,W]", U, W, om), ("twisted [U,V2]", U, V2, om2)):
    b = bracket(X, Y, p0)
    print(f"{name}: {fmt(b)}, out-of-plane part {z(w(p0, b)):.4f}")
gU = lambda q, s: [q[0] + s, q[1], q[2] + q[1] * s / 20]
gV = lambda q, t: [q[0], q[1] + t, q[2] + q[0] * t / 20]
gV2 = lambda q, t: [q[0], q[1] + t, q[2]]
uv, vu = gV(gU(p0, 4.0), 4.0), gU(gV(p0, 4.0), 4.0)
uv2, v2u = gV2(gU(p0, 4.0), 4.0), gU(gV2(p0, 4.0), 4.0)
print(f"roof, U then V: {fmt(uv, 2)}; V then U: {fmt(vu, 2)}; xy/20 there = {uv[0] * uv[1] / 20:.2f}")
print(f"twisted, U then V2: {fmt(uv2, 2)}; V2 then U: {fmt(v2u, 2)}; gap {uv2[2] - v2u[2]:.2f} m")

assert all(abs(a - b) < 1e-8 for a, b in zip(br, closed(q0)))            # formula = hand bracket
assert all(abs(a - b) < 1e-8 for a, b in zip(bracket(A, B, q30), closed(q30)))  # and at 30 deg
assert all(abs(a - b) < 1e-8 for a, b in zip(back, closed(q0)))          # polar chart agrees
assert all(abs(a - b) < 1e-5 for a, b in zip(lie, closed(q0)))           # Lie derivative = bracket
assert abs((0.4 - gaps[1]) / (0.4 - gaps[0]) - 4) < 0.01                 # swap gap -> s^2 [A,B]
assert abs(loop(0.5)[1] / 0.25 - 0.4) < 0.01 and abs(det - 4 / r ** 2) < 1e-8
assert abs(rk4(B, rk4(A, q0, -3.5, 20), -3.5, 20)[1] - LR[1]) < 1e-7     # RK4 = exact arcs
assert abs(om(p0, bracket(U, V, p0))) < 1e-9 and abs(uv[2] - vu[2]) < 1e-12
assert abs((uv2[2] - v2u[2]) - 16 * bracket(U, V2, p0)[2]) < 1e-9        # gap = s t [U,V2]
print("ALL CHECKS PASS")
