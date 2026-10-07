# Least squares -- the check behind the card.  Nothing is imported.  Four used cars:
# ages 1, 2, 3, 4 years and prices $20k, $17k, $13k, $10k.  Two roads to the same
# line: the normal equations A^T A x = A^T b, built and solved here by hand, and the
# slope-from-the-means formula that statistics teaches instead.
AGES, PRICES = [1.0, 2.0, 3.0, 4.0], [20.0, 17.0, 13.0, 10.0]
LATER, MISSES = [21.0, 18.0, 12.0, 9.0], [-0.1, 0.3, -0.3, 0.1]   # second lot; misses by hand

def normal_equations(xs, ys):                     # road 1: A^T A x = A^T b, 2x2
    n, sx, sy = float(len(xs)), sum(xs), sum(ys)
    sxx = sum(x * x for x in xs)                  # ages column dotted with itself
    sxy = sum(x * y for x, y in zip(xs, ys))      # ages column dotted with prices
    det = sxx * n - sx * sx                       # Cramer's rule, written out
    return (sxy * n - sx * sy) / det, (sxx * sy - sx * sxy) / det, [sxx, sx, n, sxy, sy]

def from_means(xs, ys):                           # road 2: the statistics formula
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    top = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    slope = top / sum((x - mx) * (x - mx) for x in xs)
    return slope, my - slope * mx

def squared_miss(xs, ys, m, k):                   # the score any line is judged by
    return sum((y - (m * x + k)) ** 2 for x, y in zip(xs, ys))
def row(name, values): print(f"{name:<36}" + "".join(f"{v:>8.2f}" for v in values))
def one(name, value): print(f"{name:<36}{value:>16}")

m1, k1, s = normal_equations(AGES, PRICES)
m2, k2 = from_means(AGES, PRICES)
fits = [m1 * x + k1 for x in AGES]
left = [y - f for y, f in zip(PRICES, fits)]
dot_age, dot_one = sum(x * r for x, r in zip(AGES, left)), sum(left)
sse = squared_miss(AGES, PRICES, m1, k1)
row("ages, in years", AGES)
row("prices, in $ thousands", PRICES)
row("A^T A, first row", [s[0], s[1]])
row("A^T A, second row", [s[1], s[2]])
row("A^T b", [s[3], s[4]])
print(f"road 1, the normal equations        slope {m1:>8.4f}   intercept {k1:>8.4f}")
print(f"road 2, from the two means          slope {m2:>8.4f}   intercept {k2:>8.4f}")
row("fitted prices, in $ thousands", fits)
row("misses, price minus fitted price", left)
one("total squared miss", f"{sse:.4f}")
one("leftover dot ages column", f"{abs(dot_age):.12f}")
one("leftover dot ones column", f"{abs(dot_one):.12f}")
m0, mf = s[3] / s[0], (PRICES[3] - PRICES[0]) / (AGES[3] - AGES[0])
sse0 = squared_miss(AGES, PRICES, m0, 0.0)        # wrong: no ones column
ssef = squared_miss(AGES, PRICES, mf, PRICES[0] - mf * AGES[0])   # wrong: two cars only
plain_5, sse5 = sum(y - (-5.0 * x + 27.5) for x, y in zip(AGES, PRICES)), \
    squared_miss(AGES, PRICES, -5.0, 27.5)
print(f"wrong, no ones column: slope {m0:.4f}, squared miss {sse0:.4f}")
print(f"wrong, first and last car only: slope {mf:.4f}, squared miss {ssef:.4f}")
print(f"wrong, misses added not squared: fitted line {abs(dot_one):.4f}, "
      f"the -5.0 line {abs(plain_5):.4f}, whose squared miss is {sse5:.4f}")
m3, k3, _ = normal_equations(AGES, LATER)
print(f"second case, prices 21, 18, 12, 9: slope {m3:.4f}, intercept {k3:.4f}, "
      f"squared miss {squared_miss(AGES, LATER, m3, k3):.4f}")
assert s == [30.0, 10.0, 4.0, 133.0, 60.0]
assert abs(m1 + 3.4) < 1e-12 and abs(k1 - 23.5) < 1e-12 and abs(sse - 0.2) < 1e-12 and max(abs(r - t) for r, t in zip(left, MISSES)) < 1e-12
assert abs(m1 - m2) < 1e-12 and abs(k1 - k2) < 1e-12 and abs(dot_age) < 1e-12 and abs(dot_one) < 1e-12
assert sse < ssef < sse5 < sse0 and abs(m3 + 4.2) < 1e-12 and abs(k3 - 25.5) < 1e-12
print("ALL CHECKS PASS")
