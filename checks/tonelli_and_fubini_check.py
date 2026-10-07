# Tonelli and Fubini -- the check behind the card.  Standard library only.
# A dart lands uniformly on the 1 m x 1 m board [0, 1] x [0, 1]; D is its
# distance from the centre (0.5, 0.5).  E[D] five ways: y first with an exact
# inner integral, x first with numerical inner integrals, a grid of small
# squares summed by rows and by columns, the closed form, and thrown darts.
# Then f = (x^2 - y^2)/(x^2 + y^2)^2, whose two orders disagree; a
# non-negative double series summed both ways; and the +1/-1 table.
import math

def simpson(g, a, b, n):                      # n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def dist(x, y):
    return math.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2)

def slice_y(x):                               # integral of D over y in [0, 1], by antiderivative
    a = abs(x - 0.5)
    r = math.sqrt(a * a + 0.25)
    return 0.5 * r + (a * a * math.log((0.5 + r) / a) if a > 0 else 0.0)

def arctan_series(t):                         # |t| < 1
    s, p, k = 0.0, t, 0
    while abs(p) > 1e-18:
        s += p / (2 * k + 1)
        p *= -t * t
        k += 1
    return s

M64 = (1 << 64) - 1
def splitmix(s):                              # SplitMix64: returns (new state, 64 random bits)
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def row(v):
    return ", ".join(f"{t:.2f}" for t in v)

PI = 16 * arctan_series(1 / 5) - 4 * arctan_series(1 / 239)     # Machin's formula
print(f"pi by Machin's series: {PI:.11f}")

# 1. the dartboard, E[D] by several roads
r2, l2 = math.sqrt(2), math.log(1 + math.sqrt(2))
closed = (r2 + l2) / 6
y_first = simpson(slice_y, 0.0, 1.0, 2000)
x_first = simpson(lambda y: simpson(lambda x: dist(x, y), 0.0, 1.0, 400), 0.0, 1.0, 400)
m = 600
cell = [[dist((i + 0.5) / m, (j + 0.5) / m) for j in range(m)] for i in range(m)]
rows_first = sum(sum(cell[i][j] for j in range(m)) for i in range(m)) / m ** 2
cols_first = sum(sum(cell[i][j] for i in range(m)) for j in range(m)) / m ** 2
state, n_darts, s1, s2 = 2026, 100000, 0.0, 0.0
for _ in range(n_darts):
    state, u = splitmix(state)
    state, v = splitmix(state)
    d = dist((u >> 11) / 2 ** 53, (v >> 11) / 2 ** 53)
    s1, s2 = s1 + d, s2 + d * d
mc = s1 / n_darts
se = math.sqrt((s2 / n_darts - mc * mc) / n_darts)
print(f"dart, closed form (sqrt 2 + ln(1 + sqrt 2))/6: {closed:.6f}")
print(f"dart, y first (exact inner, Simpson outer): {y_first:.6f}")
print(f"dart, x first (Simpson inner and outer): {x_first:.6f}")
print(f"dart, grid of {m} x {m} squares: rows first {rows_first:.6f}, columns first {cols_first:.6f}")
print(f"dart, {n_darts} thrown darts, SplitMix64 seed 2026: mean {mc:.4f}, standard error {se:.4f}")
assert abs(y_first - closed) < 1e-8
assert abs(x_first - closed) < 1e-5
assert abs(rows_first - closed) < 1e-5
assert abs(mc - closed) < 4 * se
print("slice averages at x = 0, 0.1, ..., 1: " + row(slice_y(k / 10) for k in range(11)))
print(f"by hand, slice at x = 0: 0.5 sqrt(0.5) = {0.5 * math.sqrt(0.5):.4f}, 0.25 ln(1 + sqrt 2) = {0.25 * l2:.4f},"
      f" sum {slice_y(0):.4f}; slice at x = 0.5: {slice_y(0.5):.4f}")
print(f"by hand, sqrt 2 = {r2:.6f}, ln(1 + sqrt 2) = {l2:.6f}, sum {r2 + l2:.6f}, divided by 6 = {closed:.6f}")
print(f"figure, board 0 to 1 m, centre (0.5, 0.5), dart (0.8, 0.3) at D = {dist(0.8, 0.3):.4f},"
      f" strips x 0.2 to 0.25 and y 0.7 to 0.75")

# 2. f = (x^2 - y^2)/(x^2 + y^2)^2 on (0, 1] x (0, 1]: the two orders disagree
f = lambda x, y: (x * x - y * y) / (x * x + y * y) ** 2
A = lambda x: 1 / (1 + x * x)                 # y-integral of f: [y/(x^2 + y^2)] from 0 to 1
iy, ix = simpson(lambda y: f(0.5, y), 0.0, 1.0, 2000), simpson(lambda x: f(x, 0.5), 0.0, 1.0, 2000)
print(f"f, inner y-integral at x = 0.5: Simpson {iy:.6f}, antiderivative 1/(1 + x^2) = {A(0.5):.6f}")
print(f"f, inner x-integral at y = 0.5: Simpson {ix:.6f}, antiderivative -1/(1 + y^2) = {-A(0.5):.6f}")
assert abs(iy - A(0.5)) < 1e-9
assert abs(ix + A(0.5)) < 1e-9
yx = simpson(A, 0.0, 1.0, 2000)
xy = simpson(lambda y: -1 / (1 + y * y), 0.0, 1.0, 2000)
print(f"f, y first then x: {yx:.6f} (pi/4 = {PI / 4:.6f}); x first then y: {xy:.6f} (-pi/4 = {-PI / 4:.6f})")
assert abs(yx - PI / 4) < 1e-10
assert abs(xy + PI / 4) < 1e-10
print("chart, y-first inner integral 1/(1 + x^2): " + row(A(k / 10) for k in range(11)))
print("chart, x-first inner integral -1/(1 + y^2): " + row(-A(k / 10) for k in range(11)))
ry = simpson(lambda x: 2 / (x * x + 4), 0.0, 1.0, 2000)
rx = -simpson(lambda y: 1 / (1 + y * y), 0.0, 2.0, 2000)
print(f"f on [0, 1] x [0, 2]: y first {ry:.6f}, x first {rx:.6f}, gap {ry - rx:.6f} (pi/2 = {PI / 2:.6f})")
assert abs((ry - rx) - PI / 2) < 1e-10
for e in (0.1, 0.01, 0.001):                  # |f| over [e, 1]^2, exact inner integral, outer in t = ln x
    g = lambda x: 1 / x - e / (x * x + e * e) - 1 / (1 + x * x)
    num = simpson(lambda t: g(math.exp(t)) * math.exp(t), math.log(e), 0.0, 4000)
    form = math.log(1 / e) - (PI / 2 - arctan_series(e)) + arctan_series(e)
    sq = simpson(lambda t: (1 / (1 + math.exp(2 * t)) - e / (math.exp(2 * t) + e * e)) * math.exp(t),
                 math.log(e), 0.0, 4000)
    print(f"|f| on [e, 1]^2, e = {e}: Simpson {num:.6f}, formula ln(1/e) - arctan(1/e) + arctan(e)"
          f" = {form:.6f}; f itself, size of total {abs(sq):.6f}")
    gx = sum(simpson(lambda y: abs(f(0.5, y)), a, b, 2000) for a, b in ((e, 0.5), (0.5, 1.0)))
    assert abs(gx - g(0.5)) < 1e-6              # the exact inner integral of |f| matches |f| itself
    assert abs(num - form) < 1e-6
    assert abs(sq) < 1e-6

# 3. double series: the +1/-1 table b(i, j) = [j = i] - [j = i + 1]
band = lambda i, j: (j == i) - (j == i + 1)
N = 10
rows = [sum(band(i, j) for j in range(1, i + 2)) for i in range(1, N + 1)]   # row i lives on j = i, i + 1
cols = [sum(band(i, j) for i in range(1, j + 1)) for j in range(1, N + 1)]   # column j lives on i = j - 1, j
square, wide = [sum(band(i, j) for i in range(1, N + 1) for j in range(1, c + 1)) for c in (N, N + 1)]   # N x N and N x (N + 1) corners
print(f"table, complete rows {rows[:4]}...: rows first {sum(rows)}; complete columns {cols[:4]}...: columns first"
      f" {sum(cols)}; absolute entries in the first {N} rows {sum(abs(band(i, j)) for i in range(1, N + 1) for j in range(1, N + 2))}")
print(f"table, finite {N} x {N} corner: total {square} in either order; {N} x {N + 1} corner, more columns than rows: total {wide}")
assert sum(rows) == 0
assert sum(cols) == 1
assert (square, wide) == (1, 0)

# 4. Tonelli on counting measure: sum over n >= 2 of (zeta(n) - 1), rows versus columns
def zeta_minus_1(n, M=1000):                  # direct sum to M plus Euler-Maclaurin tail
    return sum(k ** -n for k in range(2, M + 1)) + M ** (1 - n) / (n - 1) - M ** -n / 2 + n * M ** (-n - 1) / 12
z = [zeta_minus_1(n) for n in range(2, 61)]
print(f"zeta(2) - 1: series {z[0]:.6f}, pi^2/6 - 1 = {PI * PI / 6 - 1:.6f}; zeta(3) - 1 = {z[1]:.6f}")
assert abs(z[0] - (PI * PI / 6 - 1)) < 1e-12
print(f"rows first, sum over n = 2..60 of zeta(n) - 1: {sum(z):.9f}")
col2 = sum(2.0 ** -n for n in range(2, 61))
cols_z = sum(1 / (k * (k - 1)) for k in range(2, 1001))
print(f"columns first, column k totals 1/(k(k - 1)); column 2 by its series {col2:.6f};"
      f" columns 2..1000: {cols_z:.6f} = 1 - 1/1000")
assert abs(sum(z) - 1) < 1e-12
assert abs(cols_z - (1 - 1 / 1000)) < 1e-12
diag = [(t, t) for t in ((i + 0.5) / 1000 for i in range(1000))]   # the diagonal at 1000 points
v_d = sum(sum(1 for u, v in diag if u == x) for x, _ in diag) / 1000   # length on x: count each vertical section, times width
h_d = sum(max(u for u, v in diag if v == y) - min(u for u, v in diag if v == y) for _, y in diag)   # counting on y: add each horizontal section's length
print(f"breaks, not sigma-finite: diagonal of [0, 1]^2 at 1000 points, length on x and counting on y; the orders give {v_d:g} and {h_d:g}")
print("ALL CHECKS PASS")
