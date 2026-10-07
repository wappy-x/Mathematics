# Convolution and sums -- the check behind the card.  Standard library only.
# The dart: x and y independent, each uniform on [0, 1] metres; S = x + y.
# Roads to P(S < 0.5) = 1/8: the triangle density integrated exactly, the
# corner area of the square, grids of cells convolved exactly, and simulated
# darts.  Then the numerical convolution of the two densities, two discrete
# rulers, a continuous plus a discrete reading, the algebra, and what breaks.
from fractions import Fraction as Fr
from math import sqrt

def h_exact(s):                                   # the triangle: s on [0, 1], 2 - s on [1, 2]
    return max(Fr(0), 1 - abs(s - 1))

def trapezoid(f, a, b, pieces):                   # exact when f is a straight line on each piece
    w = (b - a) / pieces
    return sum((f(a + i * w) + f(a + (i + 1) * w)) * w / 2 for i in range(pieces))

def shoelace(pts):                                # area of a polygon from its corners
    n = len(pts)
    return abs(sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))) / 2

def slide(p, q):                                  # (p * q)(k) = sum over a of p(a) q(k - a)
    ks = range(min(p) + min(q), max(p) + max(q) + 1)
    return {k: sum(p[a] * q.get(k - a, 0) for a in p) for k in ks}

def push(p, q):                                   # law of a + b under the product law: add over pairs
    out = {}
    for a in p:
        for b in q:
            out[a + b] = out.get(a + b, 0) + p[a] * q[b]
    return out

def splitmix(seed):                               # SplitMix64: uniform draws in [0, 1)
    s, M = seed, (1 << 64) - 1
    while True:
        s = (s + 0x9E3779B97F4A7C15) & M
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        yield ((z ^ (z >> 31)) >> 11) / 2 ** 53

def fmt(v):
    return ", ".join(f"{float(x):.2f}" for x in v)

# road 1 and road 2: the triangle density against the corner of the square
half = Fr(1, 2)
r1 = trapezoid(h_exact, Fr(0), half, 5)
r2 = shoelace([(Fr(0), Fr(0)), (half, Fr(0)), (Fr(0), half)])
print(f"P(S < 0.5): integral of the triangle density = {r1}; corner area of the square = {r2}")
assert r1 == r2
lo, hi = trapezoid(h_exact, Fr(0), Fr(1), 4), trapezoid(h_exact, Fr(3, 2), Fr(2), 5)
tot = trapezoid(h_exact, Fr(0), Fr(2), 8)
print(f"P(S <= 1) = {lo}; P(S > 1.5) = {hi}; P(0.5 <= S <= 1.5) = {1 - r1 - hi}; total {tot}; peak h(1) = {h_exact(Fr(1))}")
assert tot == 1

# road 3: cut the board into n x n cells, read each dart at its cell's midpoint,
# and convolve the two discrete cell laws exactly
for n in (10, 100, 1000):
    cells = {a: 1 for a in range(n)}              # counts; each cell has chance 1/n
    c = slide(cells, cells)
    hits = sum(v for k, v in c.items() if 2 * (k + 1) < n)   # (a + b + 1)/n < 1/2
    gap = Fr(1, 8) - Fr(hits, n * n)
    print(f"grid of {n} x {n} cells: P(S < 0.5) = {hits}/{n * n} = {hits / n ** 2:.5f}; gap to 1/8 = {float(gap):.5f}")
    assert gap == Fr(1, 4 * n)
    if n == 10:
        dens = [Fr(c[k], n) for k in range(2 * n - 1)]      # chance c/n^2 spread over width 1/n
        print(f"tenths grid, density at s = 0.1, 0.2, ..., 1.9: {fmt(dens)}")
        assert all(dens[k] == h_exact(Fr(k + 1, n)) for k in range(2 * n - 1))

# the convolution integral itself, by a midpoint sum, f = g = 1 on [0, 1)
m = 1000
def h_num(s):
    return sum(1 for i in range(m) if 0 <= s - (i + 0.5) / m < 1) / m
hn = [h_num(j / 5) for j in range(11)]
print(f"midpoint convolution, m = {m}, at s = 0, 0.2, ..., 2: {', '.join(f'{v:.4f}' for v in hn)}")
assert all(abs(v - float(h_exact(Fr(j, 5)))) <= 1 / m for j, v in enumerate(hn))
print(f"chart, independent: {fmt(h_exact(Fr(j, 5)) for j in range(11))}")
print(f"chart, y = x: {fmt(half * (0 <= Fr(j, 10) <= 1) for j in range(11))}")

# two discrete laws: x read in tenths, y read in fifths (units: tenths of a metre)
p = {a: Fr(1, 10) for a in range(10)}
q = {b: Fr(1, 5) for b in range(0, 10, 2)}
pq = slide(p, q)
print(f"tenths + fifths, chance x 50 at 0, 1, ..., 17 tenths: {', '.join(str(v * 50) for v in pq.values())}")
assert pq == push(p, q)
assert pq == slide(q, p)
assert slide(slide(p, q), p) == slide(p, slide(q, p))
print("slide formula = sum over pairs: yes; p * q = q * p: yes; (p * q) * p = p * (q * p): yes")

# a continuous law plus a discrete one: x uniform, y in fifths
mixed = sum(q[b] * min(max(half - Fr(b, 10), 0), 1) for b in q)
print(f"x uniform + y in fifths: P(S < 0.5) = 0.2 x (0.5 + 0.3 + 0.1) = {mixed} = {float(mixed):.2f}")

# road 4: simulated darts; and what breaks when x and y are tied together
N, g = 200000, splitmix(20260929)
ind = same = anti = mix = mx = 0
for _ in range(N):
    x, y = next(g), next(g)
    ind += x + y < 0.5
    same += x + x < 0.5
    anti += x + (1 - x) < 0.5
    mix += 10 * x < 5 - 2 * int(5 * y)
    mx += max(x, y) < 0.5
se = sqrt(0.125 * 0.875 / N)
print(f"{N} simulated darts, seed 20260929: P(S < 0.5) = {ind / N:.4f} (1/8 = 0.1250, standard error {se:.4f})")
assert abs(ind / N - 0.125) < 4 * se
print(f"simulated, x uniform + y in fifths: {mix / N:.4f} (exact 0.18)")
assert abs(mix / N - float(mixed)) < 4 * sqrt(0.18 * 0.82 / N)
print(f"breaks, y = 1 - x: {anti / N:.4f} (the sum is always 1)")
print(f"breaks, y = x: {same / N:.4f} (exact 0.25)")
assert abs(same / N - 0.25) < 4 * sqrt(0.25 * 0.75 / N)
print(f"breaks, product of CDFs F(0.5) x F(0.5) = {half * half} is P(max < 0.5), simulated {mx / N:.4f}")

# the picture: metre (x, y) -> SVG (60 + 200x, 220 - 200y)
def pt(x, y):
    return f"{int(60 + 200 * x)},{int(220 - 200 * y)}"
print(f"figure, square {pt(0, 1)} to {pt(1, 0)}; corner x + y < 0.5: {pt(0, 0)} {pt(half, 0)} {pt(0, half)};"
      f" x + y = 1: {pt(0, 1)} {pt(1, 0)}; x + y = 1.5: {pt(half, 1)} {pt(1, half)}")
print("ALL CHECKS PASS")
