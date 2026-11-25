# Neutral geometry: Legendre's halving and Saccheri's quadrilateral.  math gives
# cosh, sinh, tanh, acos, atan, acosh, log2 and degrees, nothing more.  Hyperbolic
# points sit on the surface t^2 - x^2 - y^2 = 1 (the hyperboloid), curvature -1.
import math
H = lambda p, q: p[0] * q[0] - p[1] * q[1] - p[2] * q[2]     # the hyperboloid's dot

def ang(p, q, r):                       # angle at p between the lines to q and to r
    u = [a - H(p, q) * b for a, b in zip(q, p)]
    v = [a - H(p, r) * b for a, b in zip(r, p)]
    return math.degrees(math.acos(-H(u, v) / math.sqrt(H(u, u) * H(v, v))))

def pt(d, th):                          # the point d from the origin, heading th
    return (math.cosh(d), math.sinh(d) * math.cos(th), math.sinh(d) * math.sin(th))

s, small, n, steps = 181.0, 60.0, 0, ["60"]       # road 1: Legendre's bookkeeping
while small >= s - 180:
    small, n = small / 2, n + 1
    steps.append(f"{small:g}")
print(f"suppose angles 60, 60, 61 sum to {s:g}: halve the 60 deg angle {n} times")
print("smallest angle after each halving: " + " -> ".join(steps))
print(f"other two then sum to at least {s - small} > 180: impossible")
print(f"stop at 5 halvings: smallest {60 / 32:g}, others {s - 60 / 32:g}, no clash")
assert n == math.floor(math.log2(60 / (s - 180))) + 1 and small == 60 / 2 ** n   # count and value match logs
tri, sums, halved = [pt(0, 0), pt(0.3, 0), pt(0.3, math.pi / 3)], [], []
for step in range(7):                               # road 2: a real hyperbolic triangle
    A, B, C = tri
    sums.append(ang(A, B, C) + ang(B, C, A) + ang(C, A, B)); halved.append(ang(A, B, C))
    m = [x + y for x, y in zip(B, C)]
    D = [x / math.sqrt(H(m, m)) for x in m]         # the midpoint of BC
    E = [2 * H(A, D) * x - y for x, y in zip(D, A)]  # A's mirror image through D
    tri = [A, E, C] if ang(A, E, C) <= ang(E, A, C) else [E, A, C]
ch, sh = math.cosh(0.3), math.sinh(0.3)             # hyperbolic law of cosines
cos_a = ch * ch - sh * sh / 2
law_B = math.degrees(math.acos((cos_a * ch - ch) / (math.sqrt(cos_a ** 2 - 1) * sh)))
print(f"hyperbolic triangle, sides 0.3 and 0.3 at 60 deg: angles 60, {law_B:.4f}, {law_B:.4f}")
print("Legendre steps, the angle being halved: " + ", ".join(f"{x:.4f}" for x in halved))
print(f"angle sum at all 7 stages: {min(sums):.6f} to {max(sums):.6f}, short by {180 - sums[0]:.6f}")
assert abs(sums[0] - (60 + 2 * law_B)) < 1e-9       # coordinates agree with the law
assert max(sums) - min(sums) < 1e-6 and sums[0] < 180      # the sum never moves
assert all(halved[i + 1] <= halved[i] / 2 + 1e-9 for i in range(6))
a, b = 3.0, 4.0                                     # Saccheri: legs 3, base 4
A, B = pt(b / 2, math.pi), pt(b / 2, 0)
D, C = [(math.cosh(a) * P[0], math.cosh(a) * P[1], math.sinh(a)) for P in (A, B)]
tops = ang(D, A, C), ang(C, B, D)
formula = math.degrees(math.atan(1 / (math.sinh(a) * math.tanh(b / 2))))
top = math.acosh(H(D, C))
print(f"Saccheri base {b:g}, legs {a:g}: base corners {ang(A, B, D):.4f}, {ang(B, C, A):.4f}")
print(f"formula pieces: sinh {a:g} = {math.sinh(a):.4f}, tanh {b / 2:g} = {math.tanh(b / 2):.4f}")
print(f"top corners by coordinates {tops[0]:.4f}, {tops[1]:.4f}; by formula {formula:.4f}")
u, v = (0.0, -a), (b, 0.0)                          # flat: from the top-left corner
flat = math.degrees(math.acos((u[0] * v[0] + u[1] * v[1]) / (a * b)))
print(f"flat top corners {flat:g}; top side flat {b:g}, hyperbolic {top:.4f}")
assert abs(tops[0] - tops[1]) < 1e-9 and abs(tops[0] - formula) < 1e-9
assert tops[0] < 90 and top > b                     # neutral: at most 90, top >= base
small_top = math.degrees(math.atan(1 / (math.sinh(a / 1000) * math.tanh(b / 2000))))
print(f"same shape shrunk 1000 times: top corners {small_top:.5f}")
print("sphere, octant triangle: 90 + 90 + 90 = 270, two angles alone reach 180")
P = lambda Q: (round(170 + 150 * Q[1] / (1 + Q[0]), 1), round(170 - 150 * Q[2] / (1 + Q[0]), 1))
print(f"figure, disc radius 150 at (170, 170): A {P(A)}, B {P(B)}, C {P(C)}, D {P(D)}")
print("ALL CHECKS PASS")
