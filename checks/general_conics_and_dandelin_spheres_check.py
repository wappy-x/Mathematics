# Every conic -- the check behind the card.  Standard library only.
# Flower bed x^2 + xy + y^2 = 3 (metres); a lamp with a 30-degree half-angle beam, aimed 45 degrees off vertical.
from math import sqrt, sin, cos, tan, atan2, radians as rad, degrees as deg, pi
def turn(A, B, C, t):                         # the x^2, xy, y^2 numbers after turning the axes by t
    c, s = cos(t), sin(t)
    return A*c*c + B*s*c + C*s*s, B*(c*c - s*s) - 2*(A - C)*s*c, A*s*s - B*s*c + C*c*c
def halve(f, lo, hi):                         # road two: find where f changes sign
    for _ in range(200): mid = (lo + hi) / 2; lo, hi = (mid, hi) if (f(mid) > 0) == (f(lo) > 0) else (lo, mid)
    return (lo + hi) / 2
def name(A, B, C, F):                         # A x^2 + B xy + C y^2 + F = 0, centred
    d, (P, _, Q) = B*B - 4*A*C, turn(A, B, C, atan2(B, A - C) / 2)
    kd = "parabola or parallel lines" if d == 0 else "two crossing lines" if F == 0 else "hyperbola" if d > 0 else "ellipse" if -F / P > 0 else "no points"
    return d, kd, P, Q
def scan(A, B, C, F):                         # road five, no B^2 - 4AC: the signs A x^2 + B xy + C y^2 takes over a half-turn
    g = {(v > 1e-9) - (v < -1e-9) for v in (A*cos(f)*cos(f) + B*cos(f)*sin(f) + C*sin(f)*sin(f) for f in (rad(i / 10) for i in range(1800)))}
    return ("two crossing lines" if F == 0 else "hyperbola") if {1, -1} <= g else "parabola or parallel lines" if 0 in g else "ellipse" if g == {(F < 0) - (F > 0)} else "no points"
t = atan2(1, 1 - 1) / 2                       # road one: cot 2t = (A - C)/B
P, B2, Q = turn(1, 1, 1, t); th = halve(lambda u: turn(1, 1, 1, u)[1], 0, pi / 2)
sa, la = sqrt(3 / P), sqrt(3 / Q); c = sqrt(la**2 - sa**2)   # semi-axes; centre to each peg
r = [(sqrt(3 / (1 + cos(rad(i / 10)) * sin(rad(i / 10)))), i / 10) for i in range(1800)]   # road three: polar scan
print(f"bed: B^2 - 4AC = {name(1, 1, 1, -3)[0]} -> {name(1, 1, 1, -3)[1]}; cot 2t = 0, t = {deg(t):.2f} deg; halving on B' = 0: {deg(th):.2f} deg")
print(f"turned: {P:.2f} X^2 + {abs(B2):.2f} XY + {Q:.2f} Y^2 = 3, so X^2/{3 / P:.2f} + Y^2/{3 / Q:.2f} = 1, semi-axes {sa:.3f} and {la:.3f}")
print(f"polar scan, 1800 directions: nearest {min(r)[0]:.3f} at {min(r)[1]:.1f} deg, farthest {max(r)[0]:.3f} at {max(r)[1]:.1f} deg")
print(f"pegs ({-c / sqrt(2):.3f}, {c / sqrt(2):.3f}) and ({c / sqrt(2):.3f}, {-c / sqrt(2):.3f}), c = {c:.3f}, "
      f"string tied to both 2a = {2 * la:.3f}, loop round both 2a + 2c = {2 * la + 2 * c:.3f}, e = {c / la:.4f}, area {pi * sa * la:.2f} m^2")
for co in (eqs := ((1, 1, 1, -3), (0, 1, 0, -1), (2, 4, 5, -6), (1, 2, 1, 0), (1, 0, -1, 0), (1, 1, 1, 3))):
    d, kd, p, q = name(*co)
    print(f"  {co}: B^2 - 4AC = {d}, {kd}, turn {deg(atan2(co[1], co[0] - co[2]) / 2):.2f} deg, X^2 and Y^2 numbers {p:.2f}, {q:.2f}")
inv = [turn(2, 4, 5, rad(a)) for a in (0, 20, 45, 63.43494882, 100)]
print("2x^2 + 4xy + 5y^2 turned 0, 20, 45, 63.43, 100 deg: B'^2 - 4A'C' =", " ".join(f"{b*b - 4*a*cc:.2f}" for a, b, cc in inv),
      "| A' + C' =", " ".join(f"{a + cc:.2f}" for a, b, cc in inv))
k = tan(rad(30)); cs = [(m, round(-4 * (1 - k*k*m*m), 9) + 0) for m in (1, 1 / k, 3)]   # cone x^2 + y^2 = k^2 z^2 cut by the plane z = m x + 1
print("cone slice, plane slope m: " + "; ".join(f"m = {m:.3f}: B^2 - 4AC = {v:.3f}" for m, v in cs))
al, be = rad(30), rad(45)                     # the lamp: beam half-angle, tilt of the beam's axis from vertical
H = 2 * la / (tan(be + al) - tan(be - al)); x1, x2 = H * tan(be - al), H * tan(be + al)   # height that makes the lit patch 2a long
print(f"lamp: height {H:.3f}, lit patch from {x1:.3f} to {x2:.3f}, length {x2 - x1:.3f}, e = cos 45 / cos 30 = {cos(be) / cos(al):.4f}")
ds = [H / (cos(be) + s * sin(al)) for s in (1, -1)]; sph = [(d * sin(be), H - d * cos(be), d * sin(al), d * cos(al)) for d in ds]   # the two Dandelin spheres: centre x, z; radius; touch distance
print("spheres: " + "; ".join(f"centre ({x:.3f}, {z:.3f}), radius {q:.3f}, touches the beam {g:.3f} from the lamp" for x, z, q, g in sph)
      + f"; gap {sph[1][3] - sph[0][3]:.3f}")
u, e1, sums, half, tang = (sin(be), 0, -cos(be)), (cos(be), 0, sin(be)), [], 0, 0   # beam axis; a direction square to it
for i in range(3600):                         # road four: 3600 points on the lit patch's rim, in 3-D
    f = rad(i / 10); w = [cos(al) * u[j] + sin(al) * (cos(f) * e1[j] + (j == 1) * sin(f)) for j in range(3)]
    L = -H / w[2]; Px, Py = L * w[0], L * w[1]
    F1, F2 = sqrt((Px - sph[0][0])**2 + Py**2), sqrt((Px - sph[1][0])**2 + Py**2)
    sums.append(F1 + F2); half = max(half, abs(Py)); tang = max(tang, abs(F1 - (L - sph[0][3])), abs(F2 - (sph[1][3] - L)))
print(f"3600 rim points: PF1 + PF2 from {min(sums):.3f} to {max(sums):.3f}, half-width {half:.3f}")
print("mistakes: turn -45 deg gives {:.2f} X^2 + {:.2f} Y^2; ".format(*turn(1, 1, 1, -t)[::2]) + f"(1.732, 1.732) gives {3 * sqrt(3)**2:.2f}; "
      f"drop xy: circle radius {sqrt(3):.3f}; B^2 - AC = {1 - 1}; r1 + r2 = {sph[0][2] + sph[1][2]:.3f}")
X, Z, gen = lambda x: 30 + 40 * x, lambda z: 90 - 40 * z, [(sin(be + s * al), -cos(be + s * al)) for s in (-1, 1)]
print(f"figure, 1 m = 40 units: lamp ({X(0):.2f}, {Z(H):.2f}), patch ({X(x1):.2f}, 90.00) ({X(x2):.2f}, 90.00), pegs "
      + " ".join(f"({X(x):.2f}, 90.00)" for x, *_ in sph) + ", circles " + " ".join(f"({X(x):.2f}, {Z(z):.2f}) r {40 * q:.2f}" for x, z, q, _ in sph))
print("figure, beam ends and touch points: " + " ".join(f"({X(L * a):.2f}, {Z(H + L * b):.2f})" for a, b in gen for L in (8.6, sph[0][3], sph[1][3])))
assert abs(th - t) < 1e-12 and abs(B2) < 1e-12                  # halving agrees with cot 2t; xy term gone
assert abs(min(r)[0] - sa) + abs(max(r)[0] - la) < 1e-9          # polar scan meets the turned semi-axes
assert all(abs(b*b - 4*a*cc - (4*4 - 4*2*5)) + abs(a + cc - (2 + 5)) < 1e-9 for a, b, cc in inv)   # B^2 - 4AC and A + C unchanged by every turn
assert abs(max(sums) - 2 * la) + abs(min(sums) - 2 * la) + abs(half - sa) < 1e-6 and tang < 1e-9   # cone slice = bed
assert abs(c / la - cos(be) / cos(al)) < 1e-12                   # eccentricity two ways
assert all(name(*co)[1] == scan(*co) for co in eqs)              # B^2 - 4AC names each curve as the sign scan does
assert [(v > 0) - (v < 0) for m, v in cs] == [(m > 1 / k) - (m < 1 / k) for m, v in cs]   # shallower, parallel, steeper than the cone's side
print("ALL CHECKS PASS")
