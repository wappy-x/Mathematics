# The spectral theorem -- the check behind the card.  Nothing is imported.  The symmetric
# table [[2, 1], [1, 2]], two stocks that move together, is split into perpendicular axes by
# two roads: the characteristic quadratic, and repeated multiply-and-shrink.
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def mv(a, v): return [dot(a[0], v), dot(a[1], v)]
def tp(a): return [[a[0][0], a[1][0]], [a[0][1], a[1][1]]]
def mul(a, b): return [[dot(r, c) for c in tp(b)] for r in a]
def unit(v): return [x / dot(v, v) ** 0.5 for x in v]
def stretch(a, v): return dot(v, mv(a, v)) / dot(v, v)
def f(v): return "(" + ", ".join("%.6f" % (0.0 if abs(x) < 1e-12 else x) for x in v) + ")"
def near(u, v): return all(abs(x - y) < 1e-9 for x, y in zip(u, v))
def roots(a):                                          # road one: the quadratic
    t = a[0][0] + a[1][1]
    g = ((a[0][0] - a[1][1]) ** 2 + 4 * a[0][1] * a[1][0]) ** 0.5
    return [(t + g) / 2, (t - g) / 2]
A = [[2.0, 1.0], [1.0, 2.0]]
trace, det = A[0][0] + A[1][1], A[0][0] * A[1][1] - A[0][1] * A[1][0]
road_one = roots(A)
q1 = [1.0, 0.25]                                       # road two: multiply, shrink
for _ in range(40): q1 = unit(mv(A, q1))
q2 = [q1[1], -q1[0]]                                   # a quarter turn from q1
big, small = stretch(A, q1), stretch(A, q2)
Q, D = tp([q1, q2]), [[big, 0.0], [0.0, small]]
gram, rebuilt = mul(tp(Q), Q), mul(mul(Q, D), tp(Q))
x, rawq = [4.0, 2.0], [[1.0, 1.0], [1.0, -1.0]]
coords = mv(tp(Q), x)
scaled = mv(D, coords)
bad_unit = mul(mul(tp(rawq), D), rawq)
bad_swap = mul(mul(Q, [[small, 0.0], [0.0, big]]), tp(Q))
curve = [stretch(A, [1.0, s]) for s in (-3.0, -2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0, 3.0)]
sweep = [stretch(A, v) for k in range(-1000, 1001)
         for v in ([1.0, k / 1000], [k / 1000, 1.0])]
F = [[0.8, 0.3], [0.2, 0.7]]                           # second case: not symmetric
fleet = roots(F)
print("A rows %s and %s: symmetric, trace %.6f, determinant %.6f" % (f(A[0]), f(A[1]), trace, det))
print("road one, roots of L*L - 4L + 3 = 0: %.6f and %.6f" % (road_one[0], road_one[1]))
print("road two, 40 rounds of multiply-and-shrink from (1, 0.25): q1 = %s" % f(q1))
print("a quarter turn from it: q2 = %s, and q1 . q2 = %.6f" % (f(q2), dot(q1, q2)))
print("A q1 = %s = %.6f q1; A q2 = %s = %.6f q2" % (f(mv(A, q1)), big, f(mv(A, q2)), small))
print("Q^T Q rows: %s and %s" % (f(gram[0]), f(gram[1])))
print("Q D Q^T rows: %s and %s" % (f(rebuilt[0]), f(rebuilt[1])))
print("mix (4, 2): coordinates %s, then stretched %s" % (f(coords), f(scaled)))
print("A x straight, and through the axes: %s and %s" % (f(mv(A, x)), f(mv(Q, scaled))))
print("stretch along (1, s) for s = -3, -2, -1, -0.5, 0, 0.5, 1, 2, 3:\n  "
      + " ".join("%.6f" % c for c in curve))
print("largest and smallest stretch over %d directions: %.6f and %.6f"
      % (len(sweep), max(sweep), min(sweep)))
print("mistake, raw axes as Q: rows %s and %s" % (f(bad_unit[0]), f(bad_unit[1])))
print("mistake, 3 and 1 swapped in D alone: rows %s and %s" % (f(bad_swap[0]), f(bad_swap[1])))
print("not symmetric, F rows %s and %s: stretch factors %.6f and %.6f"
      % (f(F[0]), f(F[1]), fleet[0], fleet[1]))
print("F(3, 2) = %s, F(1, -1) = %s, and (3, 2) . (1, -1) = %.6f"
      % (f(mv(F, [3.0, 2.0])), f(mv(F, [1.0, -1.0])), dot([3.0, 2.0], [1.0, -1.0])))
assert abs(big - 3.0) < 1e-12 and abs(small - 1.0) < 1e-12 and near(road_one, [big, small])
assert near(gram[0] + gram[1], [1.0, 0.0, 0.0, 1.0]) and near(rebuilt[0] + rebuilt[1], A[0] + A[1])
assert near(mv(A, x), [10.0, 8.0]) and near(mv(Q, scaled), mv(A, x)) \
    and near([max(sweep), min(sweep)], [3.0, 1.0])
assert near(bad_unit[0] + bad_unit[1], [4.0, 2.0, 2.0, 4.0]) and near(fleet, [1.0, 0.5]) \
    and near(bad_swap[0] + bad_swap[1], [2.0, -1.0, -1.0, 2.0])
print("ALL CHECKS PASS")
