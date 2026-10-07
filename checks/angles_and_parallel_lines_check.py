# Angles and parallel lines: the check behind the card. Standard library only.
# A 5 m ladder leans on a wall at 70 degrees to level ground. Road one is the
# card's arithmetic. Road two puts the ladder on a grid (metres, y up) and
# measures every angle with a protractor written here from the grid alone.
THETA, L = 70, 5.0

def atan(t):                        # size of the angle of slope t (0..1), arbitrary unit
    for _ in range(30):             # halve it: the bisector of (1, 0) and (1, t) is their
        t = t / (1 + (1 + t * t) ** 0.5)          # unit vectors added, slope t / (1 + |(1, t)|)
    return t * 2 ** 30              # a sliver's slope is proportional to its size

def deg(t):                         # calibrated by the square's diagonal: 45 degrees
    return 45 * atan(t) / atan(1)

def angle(u, v):                    # protractor: angle between two directions, 0..180
    c = u[0] * v[0] + u[1] * v[1]                 # dot product
    s = abs(u[0] * v[1] - u[1] * v[0])            # determinant, made positive
    if c >= s: return deg(s / c)
    if c > -s: return 90 - deg(c / s)
    return 180 - deg(s / -c)

def slope_for(target):              # bisection: rise per unit run giving `target` degrees
    lo, hi = 0.0, 100.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if angle((1, 0), (1, mid)) < target else (lo, mid)
    return lo
def sub(p, q): return (p[0] - q[0], p[1] - q[1])
def kind(a): return "acute" if a < 90 else "right" if a == 90 else "obtuse" if a < 180 else "straight" if a == 180 else "reflex"

k = slope_for(THETA)                              # road two: place the ladder
d = L / (1 + k * k) ** 0.5; h = k * d
O, F, T, G = (0, 0), (d, 0), (0, h), (4, h)        # wall base, foot, top, a gutter point
E = (d + 0.4 * d / L, -0.4 * h / L)               # the ladder's line 0.4 m past the foot
rows = [("foot, far side (straight line)", 180 - THETA, angle(sub((9, 0), F), sub(T, F))),
        ("foot, across (vertical)", THETA, angle(sub((9, 0), F), sub(E, F))),
        ("top, gutter to ladder (alternate)", THETA, angle(sub(G, T), sub(F, T))),
        ("top, above the line (corresponding)", THETA, angle(sub(T, G), sub(T, F))),
        ("top, gutter side (co-interior)", 180 - THETA, angle(sub(T, G), sub(F, T))),
        ("top, ladder to wall", 90 - THETA, angle(sub(O, T), sub(F, T)))]
round_foot = angle(sub(O, F), sub(T, F)) + rows[0][2] + rows[1][2] + angle(sub(O, F), sub(E, F))
m = slope_for(2); tilted = angle((4, 4 * m), sub(F, T))    # gutter rising 2 degrees
assert all(abs(grid - synth) < 1e-9 for _, synth, grid in rows)
assert abs(round_foot - 360) < 1e-9
assert abs(tilted - (THETA + 2)) < 1e-9
equi = angle((1, 0), (1, 3 ** 0.5))                   # equilateral corner, true 60
assert abs(equi - 60) < 1e-9
print("turn: full 360, straight 180, right 90; divisors of 360:", sum(360 % n == 0 for n in range(1, 361)), "of 100:", sum(100 % n == 0 for n in range(1, 101)))
print(f"ladder {THETA} degrees = 7/36 of a turn = {THETA / 360:.3f} turn")
print(f"ladder 5 m: foot {d:.3f} m from wall, top {h:.3f} m up, foot/length {d / L:.3f}")
print(f"figure, 1 m = 40 units: top (90, {215 - 40 * h:.2f}), foot ({90 + 40 * d:.2f}, 215), extension 0.4 m ({90 + 40 * E[0]:.2f}, {215 - 40 * E[1]:.2f})")
for name, synth, grid in rows: print(f"{name}: synthetic {synth}, grid {grid:.3f}")
print(f"four angles round the foot, grid: {round_foot:.3f}")
print(f"protractor test, square diagonal: {angle((1, 0), (1, 1)):.3f}, equilateral corner: {equi:.3f}")
print("types:", ", ".join(f"{a} {kind(a)}" for a in (20, 70, 90, 110, 180, 360 - THETA)))
print(f"quarter-length rule: {angle((-1, 0), (-1, 15 ** 0.5)):.3f} degrees")
print(f"what breaks: wall angle copied from ground: {THETA}, true {90 - THETA}")
print(f"what breaks: gutter rising 2 degrees: copied angle {tilted:.3f}, not {THETA}")
print(f"what breaks: co-interior taken as equal: {THETA}, true {180 - THETA}")
print("ALL CHECKS PASS")
