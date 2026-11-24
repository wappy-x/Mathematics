# The Henon map -- the check behind the card.  Standard library only.  The rule (x, y) ->
# (1 - a x^2 + y, b x) at a = 1.4, b = 0.3: fixed points, area, stretch and dimension, two roads each.
from math import sqrt, log, floor
A, B, M = 1.4, 0.3, 10 ** 7
step = lambda x, y: (1 - A * x * x + y, B * x)
def newton(x, y):                     # road two: solve step(x, y) = (x, y) by Newton
    for _ in range(40):
        f, g, p = 1 - A * x * x + y - x, B * x - y, -2 * A * x - 1
        x, y = x + (f + g) / (-p - B), y + (B * f - p * g) / (-p - B)
    return x, y
shoelace = lambda p: sum(p[i - 1][0] * p[i][1] - p[i][0] * p[i - 1][1] for i in range(len(p))) / 2
def slope(cs):                        # least-squares slope of ln(count) against ln(1/side)
    xs, ys = [k * log(2) for k in range(7, 13)], [log(c) for c in cs]
    mx, my = sum(xs) / 6, sum(ys) / 6
    return sum((u - mx) * (v - my) for u, v in zip(xs, ys)) / sum((u - mx) * (u - mx) for u in xs)
fx = [(-(1 - B) + s * sqrt((1 - B) * (1 - B) + 4 * A)) / (2 * A) for s in (1, -1)]   # road one: formula
nw = [newton(0.5, 0.0), newton(-1.0, 0.0)]
orb = [(0.0, 0.0)]                                  # the orbit from (0, 0); pts drops 1000 steps
for _ in range(10 ** 7 + 1001): orb.append(step(*orb[-1]))
pts = orb[1001:]
eig = [(-A * u + sqrt(A * A * u * u + B), -A * u - sqrt(A * A * u * u + B)) for u in fx]
print(f"Henon map, a = {A}, b = {B}; from (0, 0): {' '.join(f'({u:.4f}, {v:.4f})' for u, v in orb[1:5])}")
print(f"fixed points, formula: (1 - b)^2 + 4a = {(1 - B) * (1 - B) + 4 * A:.2f}, root {sqrt((1 - B) * (1 - B) + 4 * A):.6f}; x = {fx[0]:.6f}, {fx[1]:.6f}; y = b x = {B * fx[0]:.6f}, {B * fx[1]:.6f}")
print(f"fixed points, Newton: ({nw[0][0]:.6f}, {nw[0][1]:.6f}), ({nw[1][0]:.6f}, {nw[1][1]:.6f})")
print(f"eigenvalues: {eig[0][0]:.6f} and {eig[0][1]:.6f}; {eig[1][0]:.6f} and {eig[1][1]:.6f}")
t = [-1.5 + 3 * i / 4000 for i in range(4000)]
sq = [(u, -1.5) for u in t] + [(1.5, u) for u in t] + [(-u, 1.5) for u in t] + [(-1.5, -u) for u in t]
im1 = [step(*p) for p in sq]
ar = [shoelace(sq), shoelace(im1), shoelace([step(*p) for p in im1])]
print(f"signed area of the square [-1.5, 1.5]^2, then 1 and 2 steps: {ar[0]:.6f} {ar[1]:.6f} {ar[2]:.6f};"
      f" times -b, b^2: {ar[0] * -B:.6f} {ar[0] * B * B:.6f}")
vx, vy, d0, s_tan, s_two, s_eig, px, py = 1.0, 0.0, 1e-8, 0.0, 0.0, 0.0, pts[0][0] + 1e-8, pts[0][1]
for (x, y), (nx, ny) in zip(pts[:M], pts[1:M + 1]):
    vx, vy = -2 * A * x * vx + vy, B * vx              # road one: carry an arrow by the Jacobian
    nv = sqrt(vx * vx + vy * vy)
    s_tan, vx, vy = s_tan + log(nv), vx / nv, vy / nv
    s_eig += log(abs(A * x) + sqrt(A * A * x * x + B))
    px, py = step(px, py)                              # road two: a shadow run 1e-8 away
    dd = sqrt((px - nx) * (px - nx) + (py - ny) * (py - ny))
    s_two, px, py = s_two + log(dd / d0), nx + (px - nx) * d0 / dd, ny + (py - ny) * d0 / dd
l1, l2 = s_tan / M, log(B) - s_tan / M
print(f"largest Lyapunov exponent, steps 1001 to {M + 1000}, carried arrow: {l1:.4f}; shadow run: {s_two / M:.4f}")
print(f"second exponent ln 0.3 - {l1:.4f} = {l2:.4f}; Kaplan-Yorke 1 + {l1:.4f}/{-l2:.4f} = {1 - l1 / l2:.4f}")
count = lambda n: [len({(floor(x * 2 ** k), floor(y * 2 ** k)) for x, y in pts[:n]}) for k in range(7, 13)]
many, few = count(10 ** 7), count(10 ** 5)
print(f"boxes of side 1/128 to 1/4096 hit by 10^7 points: {many}; slope {slope(many):.4f}")
print(f"mistakes, exponent from one fixed point: ln {-eig[0][1]:.6f} = {log(-eig[0][1]):.4f};"
      f" from each step's biggest eigenvalue: {s_eig / M:.4f}")
print(f"mistake, only 10^5 points: {few}; slope {slope(few):.4f}")
path = [(2.0, 0.0)]
while abs(path[-1][0]) < 1e6: path.append(step(*path[-1]))
print(f"mistake, start (2, 0): x runs {', '.join(f'{p[0]:.1f}' for p in path)}")
fig = [f"({210 + 150 * u:.1f}, {110 - 150 * B * u:.1f})" for u in fx]
print(f"figure, 150 px per unit, origin at (210, 110), orbit points 1001 to 6000, fixed points at {fig[0]} and {fig[1]}")
assert all(abs(fx[i] - nw[i][0]) < 1e-9 and abs(B * fx[i] - nw[i][1]) < 1e-9 for i in range(2))
assert all(abs(e[0]) > 1 > abs(e[1]) or abs(e[1]) > 1 > abs(e[0]) for e in eig)    # saddles, and
assert all(abs((-2 * A * u - m) * -m - B) < 1e-12 for u, e in zip(fx, eig) for m in e)  # det(J - mu I) = 0
assert abs(ar[0] - 9) < 1e-9 and abs(ar[1] + B * ar[0]) < 1e-5 and abs(ar[2] - B * B * ar[0]) < 1e-5
assert abs(l1 - s_two / M) < 0.002 and abs(slope(many) - (1 - l1 / l2)) < 0.01
print("ALL CHECKS PASS")
