# Moving shapes with matrices -- the check behind the card.  Standard library
# only.  A 4 cm by 2 cm logo, lower-left corner A at (3, 1) cm, turns 30
# degrees anticlockwise about A.  Road one: 3 x 3 matrices acting on (x, y, 1).
# Road two: each corner's distance and angle from A, angle plus 30, and back.
from math import cos, sin, atan2, hypot, radians

def mul(m, n):                       # 3 x 3 times 3 x 3, or times a column of 3
    if not isinstance(n[0], list):
        return [sum(m[i][k] * n[k] for k in range(3)) for i in range(3)]
    return [[sum(m[i][k] * n[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def shift(a, b): return [[1, 0, a], [0, 1, b], [0, 0, 1]]
def turn(t): return [[cos(t), -sin(t), 0], [sin(t), cos(t), 0], [0, 0, 1]]
def about_a(m): return mul(shift(3, 1), mul(m, shift(-3, -1)))
def area(pts):                       # shoelace: signed area, positive anticlockwise
    return sum(p[0] * q[1] - q[0] * p[1] for p, q in zip(pts, pts[1:] + pts[:1])) / 2
def move(m, pts): return [mul(m, [x, y, 1])[:2] for x, y in pts]
def pt(v): return f"({v[0]:.6f}, {v[1]:.6f})"

p, q, logo, names = 3, 1, [(3, 1), (7, 1), (7, 3), (3, 3)], "ABCD"
H = about_a(turn(radians(30)))
road1 = move(H, logo)
road2 = []
for x, y in logo:                    # polar about A: same distance, angle + 30
    r, ang = hypot(x - p, y - q), atan2(y - q, x - p) + radians(30)
    road2.append([p + r * cos(ang), q + r * sin(ang)])
print(f"cos 30 = {cos(radians(30)):.6f}, sin 30 = {sin(radians(30)):.6f}")
for i in range(2):
    print(f"H row {i + 1}: {H[i][0]:.6f} {H[i][1]:.6f} {H[i][2]:.6f}")
for n, (x, y), a, b in zip(names, logo, road1, road2):
    print(f"{n} ({x}, {y}) -> {pt(a)} by matrix, {pt(b)} by angle")
print("offsets from A after the turn: " + " ".join(f"{n} {pt((a[0] - p, a[1] - q))}" for n, a in zip(names[1:], road1[1:])))
d = lambda u, v: hypot(u[0] - v[0], u[1] - v[1])
print(f"after the turn: sides {d(road1[0], road1[1]):.6f} and {d(road1[0], road1[3]):.6f} cm, area {area(road1):.6f} cm^2")
up = mul(H, [0, 1, 0])
print(f"direction (0, 1, 0) -> ({up[0]:.6f}, {up[1]:.6f}, {abs(up[2]):.0f}): the shift never touches it")
big = move(about_a([[1.5, 0, 0], [0, 1.5, 0], [0, 0, 1]]), logo)
mir = move(about_a([[-1, 0, 0], [0, 1, 0], [0, 0, 1]]), logo)
print(f"scale 1.5 about A: C -> {pt(big[2])}, area {area(big):.6f} cm^2")
print(f"mirror in the line x = 3: B -> {pt(mir[1])}, signed area {area(mir):.6f} cm^2")
print(f"mistake, turn about (0, 0): A -> {pt(move(turn(radians(30)), logo)[0])}")
wrong = mul(shift(-3, -1), mul(turn(radians(30)), shift(3, 1)))
print(f"mistake, shifts in the wrong order: A -> {pt(move(wrong, logo)[0])}")
print(f"mistake, 30 read as radians: B -> {pt(move(about_a(turn(30)), logo)[1])}")
print(f"mistake, sine signs swapped: B -> {pt(move(about_a(turn(radians(-30))), logo)[1])}")
svg = [(30 + 36 * x, 220 - 36 * y) for x, y in road1]
print("figure, 1 cm = 36 units, " + " ".join(f"{n}' ({X:.2f}, {Y:.2f})" for n, (X, Y) in zip(names, svg)))
assert max(abs(a[k] - b[k]) for a, b in zip(road1, road2) for k in range(2)) < 1e-12
assert abs(road1[0][0] - p) < 1e-12 and abs(road1[0][1] - q) < 1e-12   # the pivot stays
assert abs(d(road1[0], road1[1]) - 4) < 1e-12 and abs(area(road1) - 4 * 2) < 1e-12
assert abs(area(big) - (4 * 1.5) * (2 * 1.5)) < 1e-12 and abs(area(mir) + 8) < 1e-12
print("ALL CHECKS PASS")
