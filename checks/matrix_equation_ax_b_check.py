# Solving A x = b -- the check behind the card.  Nothing is imported.  The cafe:
# Monday 2 coffees + 1 pastry = $11, Tuesday 1 coffee + 1 pastry = $7, so
# A = [[2, 1], [1, 1]] and b = (11, 7).  Two roads to the same prices, then the
# two look-alike days: totals $22 (a line of answers) and $23 (no answer).

def eliminate(A, b):                           # row two minus (its left entry / row one's) x row one
    (p, q), (r, s) = A                         # every case here has a nonzero top left: no row swap
    f = r / p                                  # the multiple of row one to remove
    s2, t2 = s - f * q, b[1] - f * b[0]        # row two after the subtraction
    if s2 != 0:                                # one unknown left: read it, then back up
        y = t2 / s2
        return "one answer", (b[0] - q * y) / p, y, f, s2, t2
    if t2 != 0:                                # row two now reads 0 = t2
        return "no answer", 0.0, 0.0, f, s2, t2
    return "a line of answers", 0.0, 0.0, f, s2, t2

def times(A, v):                               # A x: the mix of A's columns
    return (A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1])

def columns_test(A):                           # zero when one column is a multiple of the other
    return A[0][0] * A[1][1] - A[0][1] * A[1][0]

A, b = [[2, 1], [1, 1]], (11.0, 7.0)
kind, x, y, f, s2, t2 = eliminate(A, b)
x2 = b[0] - b[1]                               # second road: y = 7 - x put into
y2 = b[1] - x2                                 # 2x + y = 11 leaves x = 11 - 7
ax, ay = times(A, (x, y))
same = [[2, 1], [4, 2]]                        # Tuesday doubled: 4 coffees + 2 pastries
k22, _, _, _, _, _ = eliminate(same, (11.0, 22.0))
k23, _, _, _, _, gap = eliminate(same, (11.0, 23.0))
fits = [(t, 11.0 - 2.0 * t) for t in (0.0, 2.0, 4.0, 5.5)]
free = (same[0][1], -same[0][0])               # one more coffee, two fewer pastries
zz = times(same, free)                         # and neither day's total budges
_, xw, yw, _, _, _ = eliminate(A, (7.0, 11.0))         # the totals in the wrong order

print("A = [[2, 1], [1, 1]] and b = (11, 7), so 2x + y = 11 and x + y = 7")
print(f"elimination: row two minus {f:.2f} x row one leaves {s2:.2f} y = {t2:.2f}")
print(f"read it back up: y = {y:.2f}, then x = (11 - 1 x {y:.2f}) / 2 = {x:.2f}")
print(f"second road, substitution: x = 11 - 7 = {x2:.2f}, then y = 7 - {x2:.2f} = {y2:.2f}")
print(f"so a coffee is ${x:.2f} and a pastry is ${y:.2f}, and that is {kind}")
print(f"multiply back: A x = ({ax:.2f}, {ay:.2f}) and b = (11.00, 7.00)")
print(f"as a column mix: {x:.2f} x (2, 1) + {y:.2f} x (1, 1) = ({ax:.2f}, {ay:.2f})")
for lab, c, m in (("2x + y = 11", 11.0, 2.0), ("x + y = 7", 7.0, 1.0), ("4x + 2y = 23", 23.0 / 2, 2.0)):
    print(f"the line {lab}, y at x = 0, 1, 2, 3, 4, 5: "
          + ", ".join(f"{c - m * k:.2f}" for k in range(6)))
print(f"columns test, zero when dependent: {columns_test(A):.2f} for the cafe, {columns_test(same):.2f} for the doubled Tuesday")
print(f"[[2, 1], [4, 2]] x = (11, 22): {k22}, and four prices that all fit are "
      + " ".join(f"({t:.2f}, {u:.2f})" for t, u in fits))
print(f"the free direction ({free[0]:.2f}, {free[1]:.2f}) adds ({zz[0]:.2f}, {zz[1]:.2f}) to the "
      f"totals, so (4.00, 3.00) plus it, ({4.0 + free[0]:.2f}, {3.0 + free[1]:.2f}), fits too")
print(f"[[2, 1], [4, 2]] x = (11, 23): {k23}, elimination ends at 0 = {gap:.2f}, so every "
      f"price on the line above misses the $23 day by {gap:.2f}")
print(f"mistakes: b divided entry by entry gives ({b[0] / 2:.2f}, {b[1] / 1:.2f}), "
      f"b in the wrong order gives ({xw:.2f}, {yw:.2f})")
assert (round(x, 9), round(y, 9)) == (4.0, 3.0) and columns_test(A) == 1.0   # by hand: 2x1 - 1x1
assert (round(x2, 9), round(y2, 9)) == (4.0, 3.0) and (round(ax, 9), round(ay, 9)) == (11.0, 7.0)
assert columns_test(same) == 0.0 and zz == (0.0, 0.0) and times(same, (5.0, 1.0)) == (11.0, 22.0)
assert (k22, k23, round(gap, 9)) == ("a line of answers", "no answer", 1.0)
print("ALL CHECKS PASS")
