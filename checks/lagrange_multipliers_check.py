# Lagrange multipliers -- the check behind the card.  Standard library only.
# Fence a rectangle, x by y metres, with P metres of fence: a*x + b*y = P.
# Four sides: a = b = 2.  Beside a river (no fence on one long side): a = 1, b = 2.
# Road one solves the Lagrange equations y = lam*a, x = lam*b, a*x + b*y = P.
# Road two walks along the fence and searches for the biggest area.
def det(m):
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))

def lagrange(a, b, P):                  # Cramer's rule on the 3 x 3 system
    m, rhs = [[0, 1, -a], [1, 0, -b], [a, b, 0]], [0, 0, P]
    d = det(m)
    col = lambda j: [[rhs[i] if k == j else m[i][k] for k in range(3)] for i in range(3)]
    return [det(col(j)) / d for j in range(3)]

def search(a, b, P):                    # golden-section search along the fence
    area = lambda x: x * (P - a * x) / b
    lo, hi, r = 0.0, P / a, (5 ** 0.5 - 1) / 2
    for _ in range(200):
        p, q = hi - r * (hi - lo), lo + r * (hi - lo)
        if area(p) < area(q): lo = p
        else: hi = q
    x = (lo + hi) / 2
    return x, area(x)

def price(a, b, P, h=1e-3):             # slope of the best area as the fence grows
    return (search(a, b, P + h)[1] - search(a, b, P - h)[1]) / (2 * h)

for name, a, b in (("four sides", 2, 2), ("river", 1, 2)):
    x, y, lam = lagrange(a, b, 40)
    sx, sa = search(a, b, 40)
    pr = price(a, b, 40)
    print(f"{name}: Lagrange x = {x:.6f}, y = {y:.6f}, lambda = {lam:.6f}, area = {x * y:.6f}")
    print(f"{name}: search along the fence x = {sx:.6f}, area = {sa:.6f}; price slope = {pr:.6f}")
    print(f"{name}: 41 m of fence gives area {search(a, b, 41)[1]:.4f}, gain {search(a, b, 41)[1] - sa:.4f}")
    assert abs(sx - x) < 1e-6 and abs(sa - x * y) < 1e-6      # two roads, one best point
    assert abs(pr - lam) < 1e-6                                # the multiplier is the price
xs = list(range(0, 21, 2))
print("area along the four-side fence, x = 0, 2, ..., 20:", " ".join(str(x * (20 - x)) for x in xs))
pts = [k / 7 for k in range(141)]                    # 0 to 20 m in steps of 1/7
assert all(abs((100 - x * (20 - x)) - (x - 10) ** 2) < 1e-12 for x in pts)
print(f"square identity 100 - x(20 - x) = (x - 10)^2 holds at {len(pts)} points on the fence")
for x, y in ((10, 10), (15, 5)):
    print(f"at ({x}, {y}): grad A = ({y}, {x}), grad g = (2, 2), area {x * y}, rate as x grows along the fence = {y - x}")
x0, y0 = 0, 0                            # grad A = (y, x) = (0, 0) has one solution
print(f"mistake 1, grad A = 0 with no fence: ({x0}, {y0}), area {x0 * y0}")
x2 = y2 = 2 * 6                          # y = 2*lam, x = 2*lam with lam = 6, fence ignored
print(f"mistake 2, no fence equation: lambda = 6 gives {x2} by {y2}, fence {2 * x2 + 2 * y2}, area {x2 * y2}")
s = 2 * (2 * 10 + 2 * 10 - 40)
print(f"mistake 3, fence squared: its gradient at (10, 10) = ({s * 2}, {s * 2}), grad A = (10, 10)")
print(f"mistake 4, river priced at 5: predicts gain 5, true gain {search(1, 2, 41)[1] - 200:.4f}")
px = lambda x, y: (40 + 9 * x, 215 - 9 * y)
print("figure, 9 px per m, origin (40, 215): fence ends", px(0, 20), px(20, 0),
      "touch", px(10, 10), "crossings", px(5, 15), px(15, 5))
print("ALL CHECKS PASS")
