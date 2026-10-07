# Parametric curves -- the check behind the card.  Standard library only.
# A bicycle wheel of radius R = 0.35 m rolls along a flat road; its valve sits
# b = 0.30 m from the hub.  Road one: the formula x = R th - b sin th,
# y = R - b cos th.  Road two: turn the wheel in 100000 small clicks and add up.
import math
R, b, TURN, N = 0.35, 0.30, 2 * math.pi, 100000
def valve(th, r=b):                       # road one: hub (R th, R) plus the spoke
    return R * th - r * math.sin(th), R - r * math.cos(th)
def eliminated(y):                        # x from y alone, first half turn only
    u = min(1.0, max(-1.0, (R - y) / b))
    return R * math.acos(u) - b * math.sqrt(1 - u * u)
def chord(p, q):                          # straight-line distance, Pythagoras
    return math.sqrt((q[0] - p[0]) ** 2 + (q[1] - p[1]) ** 2)
fmt = lambda p: f"({p[0]:.4f}, {p[1]:.4f})"
c, s = math.cos(TURN / N), math.sin(TURN / N)
hx, ox, oy, clicked = 0.0, 0.0, -b, [(0.0, R - b)]
for k in range(1, N + 1):                 # road two: one click at a time
    hx += R * TURN / N                    # the hub rolls on by one click of tyre
    ox, oy = ox * c + oy * s, -ox * s + oy * c   # the spoke turns one click clockwise
    if k % (N // 4) == 0:
        clicked.append((hx + ox, R + oy))
quarters = [valve(k * TURN / 4) for k in range(5)]
spoke = [(-b * math.sin(k * TURN / 360), R - b * math.cos(k * TURN / 360)) for k in range(361)]
far = max(chord(spoke[0], q) for q in spoke)   # hub left out: spoke only
th = math.acos(-0.5)
gap = max(abs(eliminated(valve(k * math.pi / 12)[1]) - valve(k * math.pi / 12)[0]) for k in range(1, 12))
pts = [valve(k * TURN / N, R) for k in range(N + 1)]
arch = sum(chord(pts[k], pts[k + 1]) for k in range(N))
ratio = lambda t, r: chord(valve(t - 0.005, r), valve(t + 0.005, r)) / (R * 0.01)
print(f"one turn rolls {R * TURN:.4f} m, taking {R * TURN / 3.5:.4f} s at 3.5 m/s")
print("quarter turns by the formula:", " ".join(fmt(p) for p in quarters))
print("quarter turns by 100000 clicks:", " ".join(fmt(p) for p in clicked))
print("quarter-turn angles, rad:", " ".join(f"{k * TURN / 4:.4f}" for k in range(5)), "| hub x, m:", " ".join(f"{R * k * TURN / 4:.4f}" for k in range(5)))
print(f"valve lowest {R - b:.4f} m, highest {quarters[2][1]:.4f} m")
print(f"eliminated: y = 0.5000 gives x = {R * th:.4f} - {b * math.sqrt(0.75):.4f} = {eliminated(0.5):.4f}; formula at theta {th:.4f} gives {fmt(valve(th))}")
print(f"eliminated and formula agree to 1e-9 at 11 points of the first half turn: {'yes' if gap < 1e-9 else 'no'}")
print(f"tread pebble (b = R): arch by {N} slices {arch:.4f} m, 8R = {8 * R:.4f} m, top {valve(math.pi, R)[1]:.4f} m")
print(f"over a 0.01 rad click: valve at top moves {ratio(math.pi, b):.4f} x the hub, height / R = {(R + b) / R:.4f}")
print(f"valve at bottom moves {ratio(0, b):.4f} x the hub, height / R = {(R - b) / R:.4f}; pebble at bottom {ratio(0, R):.4f}")
print(f"mistake, sine sign flipped: quarter-turn x {R * TURN / 4 + b:.4f} m, not {quarters[1][0]:.4f} m")
print(f"mistake, hub left out: valve stays within {far:.4f} m of the start, never reaching {R * TURN:.4f} m")
print(f"mistake, degrees for theta: hub after a quarter turn {90 * R:.4f} m, not {R * TURN / 4:.4f} m")
print(f"mistake, eliminated past half a turn: y = 0.3500 gives x = {eliminated(0.35):.4f} m, not {quarters[3][0]:.4f} m")
X, Y = lambda x: 24 + 140 * x, lambda y: 200 - 140 * y
v = quarters[1]
print(f"figure, 1 m = 140 units, road at y = 200: hub ({X(R * TURN / 4):.2f}, {Y(R):.2f}), valve ({X(v[0]):.2f}, {Y(v[1]):.2f}), turn ends x = {X(R * TURN):.2f}")
for name, r in (("valve", b), ("pebble", R)):
    print(f"figure, {name}:", " ".join(f"{X(p[0]):.1f},{Y(p[1]):.1f}" for p in (valve(k * TURN / 24, r) for k in range(25))))
assert max(chord(p, q) for p, q in zip(quarters, clicked)) < 1e-9     # two roads, one path
assert gap < 1e-9                                                     # the eliminated form holds
assert abs(arch - 8 * R) < 1e-6                                       # slices against Wren's 8R
assert abs(ratio(math.pi, b) - (R + b) / R) < 1e-4 and abs(ratio(0, b) - (R - b) / R) < 1e-4
print("ALL CHECKS PASS")
