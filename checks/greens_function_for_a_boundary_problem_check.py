# Green's function for -y'' = f with zero ends -- the check behind the card.
# A canvas shelf 1 m long; sag y in m; load f = weight per metre / tension.
# Road 1: the tent G(x, s) built from Step 3's corner conditions, summed against the load.
# Road 2: a finite-difference grid solving -y'' = f directly, never using G.
def build(s, jump):      # A s - B (1 - s) = 0 and -A - B = jump, by Cramer's rule
    det = s * -1 - (-(1 - s)) * -1
    return (0 * -1 - (-(1 - s)) * jump) / det, (s * jump - 0 * -1) / det
def G(x, s, jump=-1.0):  # the tent for a unit load at s: A x left of s, B (1 - x) right of it
    A, B = build(s, jump)
    return A * x if x <= s else B * (1 - x)
def green_sum(x, f, top=1.0, m=2000):      # midpoint rule for the sum of G(x, s) f(s)
    h = top / m
    return sum(G(x, (j + 0.5) * h) * f((j + 0.5) * h) for j in range(m)) * h

def grid_solve(n, rhs):  # (-y[i-1] + 2 y[i] - y[i+1]) / h^2 = rhs[i], zero ends, Thomas
    h, cp, dp, y = 1.0 / n, [0.0] * n, [0.0] * n, [0.0] * (n + 1)
    for i in range(1, n):
        den = 2.0 + cp[i - 1]
        cp[i], dp[i] = -1.0 / den, (rhs[i] * h * h + dp[i - 1]) / den
    for i in range(n - 1, 0, -1): y[i] = dp[i] - cp[i] * y[i + 1]
    return y

def bag_grid(n, at):  # the bag as load P / h on the one node at `at`
    return grid_solve(n, [P * n if i == round(at * n) else 0.0 for i in range(n + 1)])

T, W, q = 10 * 9.81, 5 * 9.81, 10 * 9.81 / 1.0   # tension = weight of 10 kg; bag 5 kg; books 10 kg/m
P, xs, fmt = W / T, [i / 10 for i in range(11)], lambda v: " ".join(f"{a:.4f}" for a in v)
A, B = build(0.3, -1.0)
books_g, books_d = [green_sum(x, lambda s: q / T) for x in xs], grid_solve(10, [q / T] * 11)
bag_g, bag_d = [P * G(x, 0.3) for x in xs], bag_grid(10, 0.3)
left, right = (bag_d[3] - bag_d[2]) / 0.1, (bag_d[4] - bag_d[3]) / 0.1
print(f"shelf: tension {T:.2f} N, bag {W:.2f} N, P = {P:.4f}; books {q:.2f} N/m, f = {q / T:.4f} per m")
print(f"construction at s = 0.3: A = {A:.4f}, B = {B:.4f}, peak G(0.3, 0.3) = {A * 0.3:.4f}")
print("x                     " + "    ".join(f"{x:.1f}" for x in xs))
print("books, Green sum      " + fmt(books_g))
print("books, grid h = 0.1   " + fmt(books_d))
print("bag, 0.5 G(x, 0.3)    " + fmt(bag_g))
print("bag, grid h = 0.1     " + fmt(bag_d))
print(f"peak sag under the bag {bag_d[3]:.4f} m at x = 0.3; books at the middle {books_d[5]:.4f} m")
print(f"slopes beside the bag, grid: left {left:.4f}, right {right:.4f}, jump {right - left:.4f}")
print(f"reciprocity, grid: bag at 0.3 sags x = 0.7 by {bag_d[7]:.4f}; bag at 0.7 sags x = 0.3 by "
      f"{bag_grid(10, 0.7)[3]:.4f}")
for n in (10, 20):
    eb = max(abs(v - (i / n) * (1 - i / n) / 2) for i, v in enumerate(grid_solve(n, [1.0] * (n + 1))))
    ep = max(abs(v - P * G(i / n, 0.3)) for i, v in enumerate(bag_grid(n, 0.3)))
    print(f"grid h = {1 / n:.2f}: every node within 1e-15 of the kernel, books and bag: "
          f"{'yes' if max(eb, ep) < 1e-15 else 'no'}")
print(f"mistake 1, no slope jump (left piece everywhere): far end at {P * A * 1.0:.4f} m, not 0")
print(f"mistake 2, loads on the left only: books at the middle "
      f"{green_sum(0.5, lambda s: 1.0, top=0.5):.4f} m, not {books_g[5]:.4f}")
print(f"mistake 3, jump of +1: bag at x = 0.3 gives {P * G(0.3, 0.3, 1.0):.4f} m, the shelf lifted")
print(f"mistake 4, sliding ends y'(0) = y'(1) = 0: y'(1) - y'(0) = {-sum(0.1 for _ in range(10)):.4f}, needs 0")
print(f"figure, 280 px/m across, 800 px/m down, depth x {800 / 280:.2f}; bag tent px: " + " ".join(f"({40 + 280 * x:.0f},{60 + 800 * v:.0f})" for x, v in
      [(0, bag_d[0]), (0.3, bag_d[3]), (1, bag_d[10])]))
print("figure, books px y at x = 0 to 1: " + " ".join(f"{60 + 800 * v:.0f}" for v in books_d))
assert max(abs(g - d) for g, d in zip(books_g, books_d)) < 1e-12      # road 1 = road 2, books
assert max(abs(g - d) for g, d in zip(bag_g, bag_d)) < 1e-12          # road 1 = road 2, bag
assert abs((right - left) - (-P)) < 1e-9                              # grid kink = derived jump
assert abs(bag_d[7] - bag_grid(10, 0.7)[3]) < 1e-12                   # reciprocity on the grid
print("ALL CHECKS PASS")
