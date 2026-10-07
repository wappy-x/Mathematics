# Prisms and cylinders -- the check behind the card.  The tank is a cylinder
# 2 m across (radius 1 m) and 3 m tall.  Road one: base area times height.
# Two more roads never touch pi: count cubes of water, and squeeze the tank
# between prisms on many-sided bases whose sides come from Pythagoras alone.
from math import pi, sqrt

R, H = 1.0, 3.0                                 # radius and height, in metres
base, rim = pi * R * R, 2 * pi * R              # circle area and circumference
vol, side = base * H, rim * H                   # base x height; perimeter x height
L = vol * 1000                                  # 1000 litre cubes to the cubic metre
print(f"tank: {2 * R:.0f} m across, radius {R:.0f} m, {H:.0f} m tall")
print(f"base area {base:.6f} m^2; volume {vol:.6f} m^3, x 1000 = {L:.2f} litres")
print(f"each cm of depth: {base * 10:.4f} litres, x {H * 100:.0f} cm = {L:.2f}; each 1 m slice: {base * 1000:.2f}")
print(f"circumference {rim:.6f} m; side {side:.6f}, with floor {side + base:.6f}, closed {side + 2 * base:.6f} m^2")
D, k, z = 2 * R, round(20 * R), round(10 * H)   # the square box the tank fits in; litre cubes
print(f"square box {D:.0f} x {D:.0f} x {H:.0f} m: {k} x {k} = {k * k} litre cubes a layer, x {z} layers = {k * k * z} litres")
print(f"box skin: perimeter {4 * D:.0f} m x {H:.0f} m = {4 * D * H:.0f} m^2 of walls, + 2 x {D * D:.0f} m^2 of ends = "
      f"{4 * D * H + 2 * D * D:.0f} m^2; tank / box = {vol / (D * D * H):.6f}")

def cubes(n):                                   # cubes of edge 1/n m: wholly inside, touching
    m, inside, touching = round(R * n), 0, 0
    for i in range(-m, m):                      # one layer, cell corners i..i+1, j..j+1
        for j in range(-m, m):
            far = max(i * i, (i + 1) ** 2) + max(j * j, (j + 1) ** 2)
            near = min(i * i, (i + 1) ** 2) + min(j * j, (j + 1) ** 2)
            inside += far <= m * m              # farthest corner inside the circle
            touching += near < m * m            # nearest corner inside the circle
    return inside * round(H * n), touching * round(H * n)   # one layer, times the layers

(lo1, hi1), (lo2, hi2) = cubes(10), cubes(100)
print(f"litre cubes (10 cm): {lo1} wholly inside, {hi1} touching the tank")
print(f"millilitre cubes (1 cm): {lo2} to {hi2}, so {lo2 / 1000:.2f} to {hi2 / 1000:.2f} litres")

rows, s, n = [], sqrt(2) * R, 4                 # a square inside the circle
while n <= 4096:
    a = sqrt(R * R - s * s / 4)                 # centre to the middle of a side
    rows.append((n, n * s * a / 2 * H * 1000, n * s * R * R / (2 * a) * H * 1000,
                 n * s * H, n * s * R / a * H))  # inside and outside prisms
    s, n = sqrt(R * s * s / (2 * (R + a))), 2 * n  # double the sides, by Pythagoras
for n, vin, vout, sin_, sout in rows:
    if n in (4, 16, 256, 4096):
        print(f"prisms, {n} sides: {vin:.2f} to {vout:.2f} litres; side {sin_:.6f} to {sout:.6f} m^2")

print(f"mistake, diameter as radius: {pi * (2 * R) ** 2 * H * 1000:.2f} litres")
print(f"mistake, circumference as base area: {rim * H * 1000:.2f} litres")
print(f"mistake, 100 litres to the cubic metre: {vol * 100:.2f} litres")
print(f"mistake, paint for the side only: {side:.2f} of {side + 2 * base:.2f} m^2")
print(f"figure, tank at 1 m = 55: walls x {125 - 55 * R:.0f} and {125 + 55 * R:.0f}, rim y 32, "
      f"slices y {32 + 55:.0f} and {32 + 110:.0f}, floor y {32 + 55 * H:.0f}, ends {55 * R / 4:.2f} deep")
print(f"figure, net at 1 m = 30: side 30 to {30 + 30 * rim:.2f} by 75 to {75 + 30 * H:.0f} "
      f"({rim:.2f} m by {H:.0f} m, {side:.2f} m^2); ends centred x {30 + 15 * rim:.2f}, "
      f"y {75 - 30 * R:.0f} and {75 + 30 * H + 30 * R:.0f}, radius {30 * R:.0f} ({base:.2f} m^2 each)")
assert lo1 < L < hi1 and lo2 / 1000 < L < hi2 / 1000 and (hi2 - lo2) / 1000 < (hi1 - lo1) / 5
assert all(r[1] < L < r[2] for r in rows) and rows[-1][2] - rows[-1][1] < 1e-6 * L
assert all(r[3] < side < r[4] for r in rows) and rows[-1][4] - rows[-1][3] < 1e-6 * side
print("ALL CHECKS PASS")
