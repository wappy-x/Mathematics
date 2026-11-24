# Cross-ratio and harmonic points -- the check behind the card.  Standard library
# only (math, for the tipped camera).  A level pinhole camera, 1 m above the track,
# focal length 1, sees a sleeper Z m ahead 1/Z focal lengths below the horizon.
from math import atan, tan, radians
GROUND = [4.0, 5.0, 6.0, 7.0]                           # sleepers, metres ahead

def cr(a, b, c, d): return (c - a) * (d - b) / ((c - b) * (d - a))
def solve(a, b, c, k):                                  # the x with cr(a, b, c, x) = k
    den = (c - a) - k * (c - b)
    return None if abs(den) < 1e-12 else ((c - a) * b - k * (c - b) * a) / den
def tipped(z): return tan(atan(1 / z) - radians(10))    # same camera, tipped 10 degrees down
def cross(u, v): return [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]]
def dot(u, v): return sum(x * y for x, y in zip(u, v))
def fit(pairs):                      # road 2: the map z = (p y + q)/(r y + s) through three pairs
    rows = [[y, 1, -z * y, -z] for y, z in pairs]       # p y + q - z (r y + s) = 0, three times
    minor = [[[r[i] for i in range(4) if i != j] for r in rows] for j in range(4)]
    return [(-1) ** j * dot(m[0], cross(m[1], m[2])) for j, m in enumerate(minor)]
def num(x):
    s = f"{x:.6f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s
def nums(v): return ", ".join(num(x) for x in v)
def pt(v): return f"({num(v[0] / v[2])}, {num(v[1] / v[2])})"

photo = [1 / z for z in GROUND]
tilt, t = [tipped(z) for z in GROUND], tan(radians(10))  # t: the tipped camera's map (Step 1)
k = cr(*photo)
top, bot = (photo[2] - photo[0]) * (photo[3] - photo[1]), (photo[2] - photo[1]) * (photo[3] - photo[0])
print(f"ground: sleepers at {nums(GROUND)} m; cross-ratio (6-4)(7-5)/((6-5)(7-4)) = {num(cr(*GROUND))}")
print(f"level photo: heights {nums(photo)} focal lengths below the horizon")
print(f"level photo: top ({num(photo[2] - photo[0])})({num(photo[3] - photo[1])}) = {num(top)} = 1/{num(1 / top)}, "
      f"bottom ({num(photo[2] - photo[1])})({num(photo[3] - photo[0])}) = {num(bot)} = 1/{num(1 / bot)}, cross-ratio {num(k)}")
print(f"photo tipped 10 degrees down: heights {nums(tilt)} from centre; cross-ratio {num(cr(*tilt))}")
print(f"tipped map: t = tan 10 degrees = {num(t)}, (p, q, r, s) = ({nums([-t, 1, 1, t])}), ps - qr = {num(-t * t - 1)}")
for z, y in zip(GROUND, photo): print(f"bar, sleeper {num(z)} m  {'#' * round(100 * y):<25}  {num(y)}")
r1, r3, rt = solve(4, 5, 6, k), 1 / photo[3], solve(4, 5, 6, cr(*tilt))
m = fit(list(zip(photo[:3], GROUND[:3])))
m = [x / m[1] for x in m]
r2 = (m[0] * photo[3] + m[1]) / (m[2] * photo[3] + m[3])
print(f"road 1, photo cross-ratio solved with sleepers 4, 5, 6: fourth sleeper at {num(r1)} m")
print(f"road 2, map through three photo-ground pairs: (p, q, r, s) = ({nums(m)}); sends {num(photo[3])} to {num(r2)} m")
print(f"road 3, the camera's own ray, 1 m drop over Z m: {num(r3)} m; the tipped photo by cross-ratio: {num(rt)} m")
g, h = solve(4, 6, 5, -1), solve(1 / 4, 1 / 6, 1 / 5, -1)
print(f"harmonic, ground: conjugate of 5 against 4 and 6: {'at infinity' if g is None else num(g)}")
print(f"harmonic, photo: conjugate of 0.2 against 0.25 and 0.166667: {num(h)}; harmonic mean 2(0.25)(0.166667)/{num(photo[0] + photo[2])} = {num(2 * photo[0] * photo[2] / (photo[0] + photo[2]))}")
A, B, C, P = [0, 1 / 4, 1], [0, 1 / 6, 1], [0, 1 / 5, 1], [1, 0.1, 1]     # A, B, C on the line u = 0
Q = [(P[0] + C[0]) / 2, (P[1] + C[1]) / 2, 1]                           # Q halfway along PC
R, S = cross(cross(A, Q), cross(P, B)), cross(cross(B, Q), cross(P, A))
D = cross(cross(R, S), cross(A, B))
print(f"figure, A {pt(A)}, B {pt(B)}, C {pt(C)}, P {pt(P)}, Q {pt(Q)}, R {pt(R)}, S {pt(S)}; line RS meets the centre line at D {pt(D)}")
prop = 4 + (photo[0] - photo[3]) / (photo[0] - photo[1])
print(f"mistake, simple ratio AC/BC: ground {num((6 - 4) / (6 - 5))}, photo {num((photo[2] - photo[0]) / (photo[2] - photo[1]))}; "
      f"gap {num(photo[0] - photo[1])} read as 1 m makes gap {num(photo[0] - photo[3])} read as {num(prop - 4)} m, fourth sleeper at {num(prop)} m")
print(f"mistake, order A, C, B, D: cross-ratio {num(cr(4, 6, 5, 7))}; solved, fourth sleeper at {num(solve(4, 5, 6, cr(4, 6, 5, 7)))} m")
print(f"mistake, photo midpoint of 4 and 6: height {num((photo[0] + photo[2]) / 2)}, read as {num(2 / (photo[0] + photo[2]))} m")
assert all(abs((1 - t * z) / (z + t) - y) < 1e-12 for z, y in zip(GROUND, tilt))  # Step 1's map = the camera
assert abs(cr(*GROUND) - k) < 1e-12 and abs(cr(*tilt) - k) < 1e-12     # invariance, two cameras
assert abs(r1 - r3) < 1e-9 and abs(r2 - r3) < 1e-9 and abs(rt - r3) < 1e-9  # three roads to 7 m
assert g is None and abs(D[1] / D[2] - h) < 1e-12 and abs(D[0] / D[2]) < 1e-12  # construction = formula
assert abs(cr(1 / 4, 1 / 6, 1 / 5, D[1] / D[2]) + 1) < 1e-12 and abs(prop - r3) > 0.5
print("ALL CHECKS PASS")
