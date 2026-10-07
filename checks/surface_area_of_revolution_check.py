# Surface area of revolution -- the check behind the card.  Standard library
# only; math.sqrt and math.sin are the only primitives used.  The glass's bowl
# is the lower 6 cm of a ball of radius 4 cm: at height x above the bottom its
# radius is f(x) = sqrt(8x - x^2).  Road one: the formula, S = 2 pi R h.
# Road two: bands swept by chords, with no derivative anywhere.
import math

sides, s = 6, 1.0                           # Archimedes: a hexagon in a unit circle,
for _ in range(26):                         # its side count doubled 26 times
    s, sides = s / math.sqrt(2 + math.sqrt(4 - s * s)), sides * 2
PI = sides * s / 2                          # half the polygon's perimeter
R, H = 4.0, 6.0                             # ball radius and bowl height, cm

def f(x):
    return math.sqrt(max(8 * x - x * x, 0.0))

def bands(g, a, b, n, slant=True):          # n frustums, each pi (r1 + r2) times its width
    total, w = 0.0, (b - a) / n
    for k in range(n):
        x0, x1 = a + k * w, a + (k + 1) * w
        run = math.sqrt(w * w + (g(x1) - g(x0)) ** 2) if slant else w
        total += PI * (g(x0) + g(x1)) * run
    return total

def dq(g, x, h=1e-5):                       # a shrinking difference quotient for g'
    return (g(x + h) - g(x - h)) / (2 * h)

exact, ball = 2 * PI * R * H, 2 * PI * R * (2 * R)
print(f"pi, from a {sides}-sided polygon: {PI:.12f}")
print(f"bowl: R = {R:g} cm, h = {H:g} cm, rim radius {f(H):.6f} cm")
factors = []
for x in (1, 3, 5):
    k = math.sqrt(1 + dq(f, x) ** 2)
    factors.append(f(x) * k)
    print(f"x = {x}: radius {f(x):.6f}, slope {dq(f, x):.6f}, slant factor {k:.6f}, product {factors[-1]:.6f}")
print(f"road one, 2 pi R h: bowl {exact:.6f}, whole ball {ball:.6f}")
errs = []
for n in (6, 60, 600, 6000):
    errs.append(exact - bands(f, 0, H, n))
    print(f"road two, {n:4d} bands: {exact - errs[-1]:.6f}, short by {errs[-1]:.6f}")
ball2 = bands(f, 0, 2 * R, 6000)
print(f"road two, whole ball, 6000 bands: {ball2:.6f}")
print(f"one band, x 1 to 2: radii {f(1):.4f} and {f(2):.4f}, slant {math.sqrt(1 + (f(2) - f(1)) ** 2):.4f}, "
      f"area {bands(f, 1, 2, 1):.4f}, exact {2 * PI * R:.4f}")
print(f"pole: start 0.01 cm up, lose {2 * PI * R * 0.01:.6f}; to lose under 0.01, start below {0.01 / (2 * PI * R):.6f}")
print(f"silver 0.002 cm thick at 10.49 g per cm^3: {exact * 0.002:.6f} cm^3, {exact * 0.002 * 10.49:.4f} g")
print(f"figure, 25 per cm: centre (150, 120), band ({150 + 25 * f(1):.2f}, 195) to "
      f"({150 + 25 * f(2):.2f}, 170), rim ({150 - 25 * f(H):.2f} to {150 + 25 * f(H):.2f}, 70)")
w = H / 6000
disc = sum(PI * f((k + 0.5) * w) ** 2 * w for k in range(6000))
print(f"mistake, width not slant: {bands(f, 0, H, 60000, slant=False):.2f}")
print(f"mistake, disc formula pi f^2 (a volume, cm^3): {disc:.2f}")
print(f"mistake, crinkled within 0.01 cm: {bands(lambda x: f(x) + 0.01 * math.sin(100 * x), 0, H, 60000):.2f}")
print(f"mistake, signed radius x - 3 on 0 to 6: {round(bands(lambda x: x - 3, 0, 6, 6), 2) + 0.0:.2f}, true {bands(lambda x: abs(x - 3), 0, 6, 6):.2f}")
assert abs(exact - bands(f, 0, H, 6000)) < 1e-3               # road two meets road one
assert all(a > b > 0 for a, b in zip(errs, errs[1:]))          # and closes in from below
assert abs(ball2 - 4 * PI * R * R) < 1e-3                       # the sphere, 4 pi R^2
assert all(abs(p - R) < 1e-6 for p in factors)                  # radius x slant factor = R
print("ALL CHECKS PASS")
