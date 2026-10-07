# Double integrals -- the check behind the card.  Nothing is imported.
# Rain depth f(x, y) = 6 + 3y + xy mm on the catchment 0 <= y <= x/2, 0 <= x <= 4 (km).
# Roads: hand antiderivatives both orders; nested midpoint sums (vertical = north strips,
# horizontal = east strips); a grid of cells with no slicing; the lower/upper bracket.
def depth(x, y):
    return 6 + 3 * y + x * y
def mid(g, a, b, n):                           # midpoint sum of g on [a, b], n pieces
    h = (b - a) / n
    return sum(g(a + (k + 0.5) * h) for k in range(n)) * h
def vertical(f, n):                            # x from 0 to 4, then y from 0 to x/2
    return mid(lambda x: mid(lambda y: f(x, y), 0, x / 2, n), 0, 4, n)

def horizontal(f, n):                          # y from 0 to 2, then x from 2y to 4
    return mid(lambda y: mid(lambda x: f(x, y), 2 * y, 4, n), 0, 2, n)

def grid(f, n):                                # cells 4/n by 2/n; cells on the edge count half
    w, h = 4 / n, 2 / n
    return sum(f((i + 0.5) * w, (j + 0.5) * h) * w * h * (1 if j < i else 0.5)
               for i in range(n) for j in range(i + 1))

def bracket(f, n):                             # depth rises east and north: extremes at cell corners
    w, h, lo, hi = 4 / n, 2 / n, 0.0, 0.0
    for i in range(n):
        for j in range(i + 1):                  # an edge cell's lowest value is 0, outside the edge
            hi += f((i + 1) * w, (j + 1) * h) * w * h
            lo += f(i * w, j * h) * w * h if j < i else 0.0
    return lo, hi

inner_v = lambda x: 3 * x + 3 * x**2 / 8 + x**3 / 8       # hand: north strip at x, y from 0 to x/2
inner_h = lambda y: 24 + 8 * y - 6 * y**2 - 2 * y**3       # hand: east strip at y, x from 2y to 4
v_exact = 3 * 4**2 / 2 + 3 * 4**3 / 24 + 4**4 / 32        # integral of inner_v from 0 to 4
h_exact = 24 * 2 + 8 * 2**2 / 2 - 6 * 2**3 / 3 - 2 * 2**4 / 4   # integral of inner_h from 0 to 2
print(f"corners: depth {depth(0, 0):.0f}, {depth(4, 0):.0f}, {depth(4, 2):.0f} mm; area {4 * 2 / 2:.0f} km^2")
print(f"vertical slice at x = 2: {inner_v(2):.3f}; midpoint {mid(lambda y: depth(2, y), 0, 1, 64):.3f}")
print(f"horizontal slice at y = 1: {inner_h(1):.3f}; midpoint {mid(lambda x: depth(x, 1), 2, 4, 64):.3f}")
print(f"exact: vertical order {v_exact:.4f}, horizontal order {h_exact:.4f} mm km^2")
assert all(abs(inner_v(2 * t) - mid(lambda y: depth(2 * t, y), 0, t, 8)) < 1e-9 and    # hand strips match
           abs(inner_h(t) - mid(lambda x: depth(x, t), 2 * t, 4, 8)) < 1e-9 for t in (0.3, 1, 1.7))
for n in (4, 16, 64):
    v, hz, g = vertical(depth, n), horizontal(depth, n), grid(depth, n)
    print(f"n = {n}: vertical {v:.4f}, horizontal {hz:.4f}, grid {g:.4f}; "
          f"errors {v - v_exact:+.4f}, {hz - v_exact:+.4f}, {g - v_exact:+.4f}")
    assert abs(v - v_exact) < 10 / n**2 and abs(hz - h_exact) < 10 / n**2 and abs(g - v_exact) < 10 / n**2
lo, hi = bracket(depth, 336)
print(f"bracket n = 336: lower {lo:.4f}, upper {hi:.4f}, gap {hi - lo:.4f}; bound (22 x 8 + 20 x 8)/n = {(22 * 8 + 20 * 8) / 336:.4f}")
assert lo <= v_exact <= hi and hi - lo <= (22 * 8 + 20 * 8) / 336         # the tolerance game, played
print(f"volume: {v_exact:.0f} mm km^2 = {v_exact * 1000:.0f} m^3 = {v_exact:.0f} million litres")
rect = mid(lambda x: mid(lambda y: depth(x, y), 0, 2, 64), 0, 4, 64)
wrong = mid(lambda y: mid(lambda x: depth(x, y), 0, 2 * y, 64), 0, 2, 64)
print(f"mistake, rectangle limits 0..4 and 0..2: {rect:.2f}; wrong side of the edge: {wrong:.2f}")
print(f"mistake, n = 4 grid depths added without the cell area: {grid(depth, 4) / 0.5:.2f}")
spike = lambda x, y: (x * x - y * y) / (x * x + y * y) ** 2      # unbounded at the corner
dy_first = mid(lambda x: 1 / (1 + x * x), 0, 1, 1000)     # inner y-integral = 1/(1 + x^2)
dx_first = mid(lambda y: -1 / (1 + y * y), 0, 1, 1000)    # inner x-integral = -1/(1 + y^2)
print(f"spike at x = 0.5: inner closed form {1 / 1.25:.6f}, midpoint {mid(lambda y: spike(0.5, y), 0, 1, 4000):.6f}")
assert abs(mid(lambda y: spike(0.5, y), 0, 1, 4000) - 1 / 1.25) < 1e-6
print(f"spike on the unit square: dy first {dy_first:.6f}, dx first {dx_first:.6f}")
print("figure, 70 px per km; corners (40,200), (320,200), (320,60); vertical strip x = "
      f"{40 + 70 * 2.4:.0f} to {40 + 70 * 2.6:.0f}, top y = {200 - 70 * 1.25:.1f}; horizontal strip y = {200 - 70 * 0.6:.0f} to {200 - 70 * 0.4:.0f}, x = {40 + 70 * 1:.0f} to 320")
print("ALL CHECKS PASS")
