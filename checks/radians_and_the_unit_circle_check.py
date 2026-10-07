# The unit circle -- the check behind the card.  Nothing is imported.  A tower
# crane's 30 m jib starts pointing east and swings anticlockwise through 210 deg.
# Road one: reference angle, exact triangle values, quadrant signs.  Road two:
# walk the hook round the circle until the arc is the radius times the radians.
R, PI, H = 30.0, 3.141592653589793, 3 ** 0.5 / 2   # H: height of half an equilateral triangle
EXACT = {0: (1.0, 0.0), 30: (H, 0.5), 45: (0.5 ** 0.5, 0.5 ** 0.5), 60: (0.5, H), 90: (0.0, 1.0)}

def point(deg):                          # road one: sizes from the reference angle,
    a = deg % 360                        # signs from the quadrant
    x, y = EXACT[min(a % 180, 180 - a % 180)]
    return (-x if 90 < a < 270 else x, -y if a > 180 else y)

def walk(theta, r, per=20000):           # road two: the radian, walked out in short steps
    x, y, done, arc = r, 0.0, 0.0, r * abs(theta)
    turn = 1 if theta > 0 else -1        # anticlockwise positive, clockwise negative
    while arc - done > 1e-9:
        s = turn * min(r / per, arc - done)
        u, v = x - y * s / r, y + x * s / r                  # a short step across the jib
        k = r / (u * u + v * v) ** 0.5                       # pulled back to r from the mast
        done += ((u * k - x) ** 2 + (v * k - y) ** 2) ** 0.5  # the arc, walked as chords
        x, y = u * k, v * k
    return x, y

def ratio(a, b):                         # a quotient that refuses to divide by zero
    return "undefined" if b == 0 else f"{a / b + 0.0:.6f}"

def pair(p, d=6):
    return f"({p[0]:.{d}f}, {p[1]:.{d}f})"

t, (x, y) = 210 * PI / 180, point(210)
walks = {d: walk(d * PI / 180, R) for d in [30, 150, 210, 330, -45, -150, 570]}
print(f"jib 30 m, swing 210 deg = 7pi/6 rad = {t:.6f} rad; the hook's arc 30 x {t:.6f} = {R * t:.6f} m")
print(f"road one: reference angle 30 deg, quadrant III, signs (-, -): cos {x:.6f}, sin {y:.6f}")
print(f"road two: {R * t:.6f} m walked round the circle in 1.5 mm steps: hook at {pair(walks[210])} m")
print(f"hook: {-R * x:.2f} m west and {-R * y:.2f} m south of the mast")
print(f"the other four at 210 deg: tan {ratio(y, x)}, sec {ratio(1, x)}, csc {ratio(1, y)}, cot {ratio(x, y)}")
tl = (1 + (y / x) ** 2) ** 0.5           # Pythagoras on the tangent-line triangle
print(f"tangent line x = 1: the jib's line meets it at (1, {y / x:.6f}), {tl:.6f} from the mast, beyond it from the hook")
print("one per quadrant: " + "  ".join(f"{d} deg {pair(point(d), 4)}" for d in [30, 150, 210, 330]))
print(f"second case, 45 deg clockwise = -pi/4 rad: road one {pair(point(-45))}, road two hook at {pair(walks[-45], 2)} m")
print(f"150 deg clockwise and 570 deg anticlockwise end at {pair(walks[-150], 2)} and {pair(walks[570], 2)} m")
for d in (90, 180):
    a, b = point(d)
    print(f"on an axis, {d} deg at ({a:.0f}, {b:.0f}): tan {ratio(b, a)}, sec {ratio(1, a)}, csc {ratio(1, b)}, cot {ratio(a, b)}")
laps = int(210 / (2 * PI)); rest = 210 - laps * 2 * PI
c, s = walk(rest, 1.0)
print(f"mistake 1, the triangle's positive signs kept: hook at {pair((R * H, R / 2), 2)}, the 30 deg spot")
print(f"mistake 2, sine and cosine swapped: hook at {pair((R * y, R * x), 2)}; the 240 deg spot is {pair((R * point(240)[0], R * point(240)[1]), 2)}")
print(f"mistake 3, 210 typed in radian mode: {laps} turns and {rest:.6f} rad = {rest * 180 / PI:.2f} deg more; cos {c:.4f}, sin {s:.4f}")
print(f"figure, plan 1 m = 3.2: mast (180, 120), jib 96, hook ({180 + 96 * x:.2f}, {120 - 96 * y:.2f}),"
      f" arcs end ({180 + 22 * x:.2f}, {120 - 22 * y:.2f}) and ({180 + 45 * x:.2f}, {120 - 45 * y:.2f})")
print(f"figure, tangent line 1 = 90: mast (150, 130), hook ({150 + 90 * x:.2f}, {130 - 90 * y:.2f}),"
      f" meets at (240, {130 - 90 * y / x:.2f}), 30 deg arc end ({150 + 30 * H:.2f}, {130 - 15:.2f})")
for d in [30, 150, 210, 330, -45]:       # two roads agree in all four quadrants
    assert abs(R * point(d)[0] - walks[d][0]) < 1e-6 and abs(R * point(d)[1] - walks[d][1]) < 1e-6
assert all(abs(walks[d][i] - walks[210][i]) < 1e-6 for d in (-150, 570) for i in (0, 1))  # three walks
cf, sf = walk(210, 1.0, 2000)            # 210 radians walked in full: 33 laps and the rest
assert abs(cf - c) < 1e-4 and abs(sf - s) < 1e-4
assert abs(tl - abs(1 / x)) < 1e-12      # the tangent-line hypotenuse is |sec 210|
print("ALL CHECKS PASS")
