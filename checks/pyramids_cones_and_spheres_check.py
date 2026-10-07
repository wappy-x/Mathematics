# Pyramids, cones and spheres -- the check behind the card.  The hopper under
# the tank is a cone, rim radius 1 m, depth 0.75 m; the ball is 2 m across.
# Road one: the formulas.  Road two: thin slabs, a many-sided pyramid and thin
# bands, built from slice areas and Pythagoras alone, never from the formulas.
from math import pi, sqrt

R, H, TANK = 1.0, 0.75, 3.0                  # rim radius, hopper depth, tank height
L = sqrt(R * R + H * H)                      # the slant, by Pythagoras

def slabs(area_at, height, n):               # n flat slabs: one stack inside, one outside
    ends = [area_at(height * j / n) for j in range(n + 1)]
    inside = sum(min(ends[j], ends[j + 1]) for j in range(n)) * height / n
    return inside, sum(max(ends[j], ends[j + 1]) for j in range(n)) * height / n

def polygon_steel(doublings):                # a pyramid on a 6 x 2^k-sided rim polygon
    n, e = 6, R                              # a hexagon's side equals its radius
    for _ in range(doublings):               # halve every side's angle: Pythagoras twice
        n, e = 2 * n, sqrt(2 * R * R - R * sqrt(4 * R * R - e * e))
    return n, n * e * sqrt(H * H + R * R - e * e / 4) / 2   # faces: edge x face height / 2

def bands(n):                                # the ball's outline cut into n chords, spun
    z = [-R + 2 * R * j / n for j in range(n + 1)]     # round; a band is pi x (r1 + r2) x chord
    r = [sqrt(max(0.0, R * R - v * v)) for v in z]
    return sum(pi * (r[j] + r[j + 1]) * sqrt((z[j + 1] - z[j]) ** 2 + (r[j + 1] - r[j]) ** 2) for j in range(n))

cone_v, cone_s, ball_v, ball_s = pi * R * R * H / 3, pi * R * L, 4 * pi * R ** 3 / 3, 4 * pi * R * R
cone_at = lambda z: pi * (R * z / H) ** 2   # slice z above the tip: the rim shrunk by z/H
hemi_at = lambda z: pi * (R * R - z * z)    # slice z above the ball's middle
cone_slabs = [slabs(cone_at, H, n) for n in (10, 100, 1000)]
ball_lo, ball_hi = slabs(hemi_at, R, 1000)
print(f"hopper: rim radius {R:.0f} m, depth {H} m, slant {L:.6f} m; volume {cone_v:.6f} m^3 = {cone_v * 1000:.2f} litres")
print(f"rim area {pi * R * R:.6f} m^2; hopper = {cone_v / (pi * R * R):.6f} m of tank; tank {pi * R * R * TANK:.6f} m^3, "
      f"tank and hopper {pi * R * R * TANK + cone_v:.6f} m^3")
for n, (lo, hi) in zip((10, 100, 1000), cone_slabs):
    print(f"hopper by {n} slabs: inside {lo:.6f}, outside {hi:.6f}")
lo, hi = slabs(lambda z: z * z, 1.0, 100)
print(f"1 m cube, one of three pyramids: 1/3 = {1 / 3:.6f}; 100 slabs {lo:.6f} to {hi:.6f}")
print(f"stretched to 0.75 m tall {0.75 / 3:.6f}; base widened to pi m^2 {pi * 0.75 / 3:.6f}; square side {sqrt(pi):.6f} m")
print(f"hopper steel, pi x r x slant: {cone_s:.6f} m^2; unrolled sector {360 * R / L:.2f} degrees, "
      f"{R / L:.2f} of a {L:.2f} m disc: {R / L * pi * L * L:.6f} m^2")
print("pyramid steel on a rim polygon: " + "; ".join("%d sides %.6f" % polygon_steel(k) for k in (4, 10)))
print(f"ball 2 m across: volume {ball_v:.6f} m^3, skin {ball_s:.6f} m^2; 1000 slabs {2 * ball_lo:.6f} to {2 * ball_hi:.6f}")
print(f"ball skin by 10, 100, 1000 bands: {bands(10):.6f}, {bands(100):.6f}, {bands(1000):.6f}")
print(f"cylinder 2 m tall round the ball: {2 * pi * R ** 3:.6f} m^3, wall {2 * pi * R * (2 * R):.6f} m^2, "
      f"ball / cylinder {ball_v / (2 * pi * R ** 3):.6f}")
print(f"slice 0.6 m above the middle: ball radius {sqrt(R * R - 0.36):.6f}, area {hemi_at(0.6):.6f}; "
      f"cylinder minus cone {pi * R * R - pi * 0.6 ** 2:.6f}; hemisphere {pi * R ** 3 - pi * R ** 3 / 3:.6f}")
print(f"mistakes: no third {pi * R * R * H:.6f}; slant as depth {pi * R * R * L / 3:.6f}; lid counted {cone_s + pi * R * R:.6f}")
print(f"mistakes: third on a 1 m bowl {pi * R ** 3 / 3:.6f}; 4 m ball as double {2 * ball_v:.6f}, truth {4 * pi * 2 ** 3 / 3:.6f}, "
      f"{4 * pi * 2 ** 3 / 3 / ball_v:.6f} times the 2 m ball")
print(f"figure, hopper at 1 m = 50: tank (130, 20) to ({130 + 100 * R:.0f}, {20 + 50 * TANK:.0f}), "
      f"tip ({130 + 50 * R:.0f}, {20 + 50 * TANK + 50 * H:.2f}), wall {50 * L:.2f} long")
dx, dy = 60 * sqrt(0.75), 60 * 0.5          # cube figure: depth drawn half size, 30 degrees up
print(f"figure, cube at 1 m = 120, depth half size at 30 degrees: front (100, 200) to (220, 80), back shift ({dx:.2f}, {-dy:.2f}), "
      f"P ({220 + dx:.2f}, {80 - dy:.2f}), Q (100, 200)")
assert all(lo < cone_v < hi for lo, hi in cone_slabs)          # slabs pinch a third of B x h
assert abs(polygon_steel(10)[1] - cone_s) < 1e-5               # many-sided pyramid against pi r l
assert 2 * ball_lo < ball_v < 2 * ball_hi                      # slabs pinch 4/3 pi r^3
assert 0 < ball_s - bands(1000) < 1e-4                         # bands fall just short of 4 pi r^2
print("ALL CHECKS PASS")
