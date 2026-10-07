# Eigenvalues and eigenvectors -- the check behind the card.  Nothing is imported.  A fleet of
# 1,000 rental cars moves between two cities: each month 80% of city A's cars stay and 20% drive
# to B, 70% of B's stay and 30% drive to A, so the matrix is [[0.8, 0.3], [0.2, 0.7]].  Road 1:
# the characteristic quadratic, solved by the quadratic formula, each pattern read off a shifted
# row.  Road 2: run the fleet and read both stretch factors off the car counts, with no algebra.
A = [[0.8, 0.3], [0.2, 0.7]]
(a, b), (c, d) = A
trace, det = a + d, a * d - b * c
def times(m, v):                                    # a matrix times a column vector
    return (m[0][0] * v[0] + m[0][1] * v[1], m[1][0] * v[0] + m[1][1] * v[1])
def show(m):                                        # a 2 by 2 matrix, row by row
    return f"[[{m[0][0]:.2f}, {m[0][1]:.2f}], [{m[1][0]:.2f}, {m[1][1]:.2f}]]"
def whole(r, n=1):                                  # smallest whole pair with y / x = r
    while abs(r * n - round(r * n)) > 1e-9: n += 1
    return (n, int(round(r * n)))
disc = trace * trace - 4.0 * det
if disc < 0.0: raise SystemExit("no real eigenvalue: this matrix turns every direction")
half = disc ** 0.5 / 2.0
lam1, lam2 = trace / 2.0 + half, trace / 2.0 - half
vs = [whole((lam - a) / b) for lam in (lam1, lam2)]  # the shifted top row kills these
steady = 1000.0 * vs[0][0] / (vs[0][0] + vs[0][1])
print("fleet rules: each month 80% of city A's cars stay and 20% drive to B, "
      "70% of B's stay and 30% drive to A")
print(f"matrix A = {show(A)}   trace a + d = {trace:.6f}   determinant ad - bc = {det:.6f}")
print(f"characteristic quadratic  lambda^2 - {trace:.6f} lambda + {det:.6f} = 0   "
      f"discriminant {disc:.6f}")
print(f"road 1, the quadratic formula: eigenvalues {lam1:.6f} and {lam2:.6f}   "
      f"sum {lam1 + lam2:.6f} = trace   product {lam1 * lam2:.6f} = determinant")
for lam, v in zip((lam1, lam2), vs):
    shift = [[a - lam, b], [c, d - lam]]
    killed, Av = times(shift, v), times(A, v)
    print(f"lambda = {lam:.6f}:  A - lambda I = {show(shift)}   eigenvector "
          f"({v[0]}, {v[1]})   A times it = ({Av[0]:.6f}, {Av[1]:.6f})")
    assert max(abs(killed[0]), abs(killed[1])) < 1e-12 and \
        abs(Av[0] - lam * v[0]) < 1e-12 and abs(Av[1] - lam * v[1]) < 1e-12
print("road 2, no algebra: 1000 cars start in city A, one month at a time")
split, gaps = (1000.0, 0.0), []
for month in range(61):
    if month <= 12: gaps.append(split[0] - steady)
    if month <= 6:
        print(f"   month {month}   city A {split[0]:>7.2f}   city B {split[1]:>7.2f}"
              f"   above the steady {steady:.2f}: {gaps[month]:>7.2f}")
    split = times(A, split)
settled = times(A, split)[0] / split[0]
print(f"the split settles at ({split[0]:.2f}, {split[1]:.2f}), whose factor is "
      f"{settled:.6f}; each gap halves, factor {gaps[1] / gaps[0]:.6f}; gap after 12 "
      f"months {gaps[12]:.2f} cars")
assert abs(settled - lam1) < 1e-9 and \
    all(abs(gaps[n + 1] - lam2 * gaps[n]) < 1e-9 for n in range(12))
assert abs((a - 2.0) * (d - 2.0) - b * c - (2.0 - lam1) * (2.0 - lam2)) < 1e-12 and \
    abs(lam1 * lam2 - det) < 1e-12 and abs(lam1 - 1.0) < 1e-12 and abs(lam2 - 0.5) < 1e-12
sq = [[a * a + b * c, a * b + b * d], [c * a + d * c, c * b + d * d]]
ch = max(abs(sq[i][j] - trace * A[i][j] + (det if i == j else 0.0)) for i in (0, 1) for j in (0, 1))
bad = times(A, (3.0, -2.0))
print(f"Cayley-Hamilton: A A - {trace:.6f} A + {det:.6f} I is the zero matrix, largest entry {ch:.6f}")
print(f"the four mistakes: root {det / d:.6f}, discriminant "
      f"{trace * trace - 4.0 * (a * d + b * c):.6f}, product {a * d:.6f} not {det:.6f}, "
      f"A (3, -2) = ({bad[0]:.2f}, {bad[1]:.2f})")
assert ch < 1e-12 and abs(bad[0] / 3.0 - bad[1] / -2.0) > 0.1
print("ALL CHECKS PASS")
