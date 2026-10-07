# The dot product -- the check behind the card.  Nothing is imported.  A weekly
# shop: quantities (2, 3, 1) at prices (3, 2, 4); a cyclist's leg (3, 4); the
# direction (4, -3) at right angles to it; (6, 8), the same way twice as long.
# Two roads to the bill, Pythagoras on the tips, Cauchy-Schwarz on twelve arrows.
SHOP_Q, SHOP_P = (2, 3, 1), (3, 2, 4)
LEG, PERP, TWICE = (3, 4), (4, -3), (6, 8)
ROUND = [(5, 0), (4, 3), (3, 4), (0, 5), (-3, 4), (-4, 3),
         (-5, 0), (-4, -3), (-3, -4), (0, -5), (3, -4), (4, -3)]

def dot(a, b):                # road one: multiply matching entries, add them up
    total = 0
    for x, y in zip(a, b):
        total += x * y
    return total

def squares(w):               # one list's own squares added up, nothing paired
    total = 0
    for t in w:
        total += t * t
    return total

def dot_from_lengths(a, b):   # road two: three squared lengths, no paired products
    both = [x + y for x, y in zip(a, b)]
    return (squares(both) - squares(a) - squares(b)) / 2

def length(w): return squares(w) ** 0.5

def show(w): return "(" + ", ".join(str(t) for t in w) + ")"

def one(name, value): print(f"{name:<46}{value:>6}")

for a, b in ((SHOP_Q, SHOP_P), (LEG, LEG), (LEG, PERP), (LEG, TWICE)):
    print(f"line by line, {show(a)} . {show(b)}: "
          + ", ".join(f"{x} x {y} = {x * y}" for x, y in zip(a, b)))
one("(2, 3, 1) . (3, 2, 4), the bill in dollars", dot(SHOP_Q, SHOP_P))
one("the same bill, from squared lengths only", f"{dot_from_lengths(SHOP_Q, SHOP_P):.0f}")
one("(3, 4) . (3, 4)", dot(LEG, LEG))
one("the leg's length, the square root of 25", f"{length(LEG):.1f}")
one("(3, 4) . (4, -3)", dot(LEG, PERP))
one("(3, 4) . (6, 8)", dot(LEG, TWICE))
one("the alignment score, 50 / (5 x 10)",
    f"{dot(LEG, TWICE) / (length(LEG) * length(TWICE)):.2f}")
gap = tuple(x - y for x, y in zip(LEG, PERP))
print(f"the tips of (3, 4) and (4, -3) are {show(gap)} apart, squared length "
      f"{squares(gap)} = {squares(LEG)} + {squares(PERP)}")
add_them = sum(x + y for x, y in zip(SHOP_Q, SHOP_P))
all_pairs = sum(SHOP_Q) * sum(SHOP_P)
back_to_front = dot(SHOP_Q, tuple(reversed(SHOP_P)))
print(f"the four mistakes come out at {add_them}, {all_pairs}, "
      f"{back_to_front} and {squares(LEG)}")
scores = [dot(LEG, d) / (length(LEG) * length(d)) for d in ROUND]
print("alignment scores with (3, 4), for twelve directions each of length 5:")
print("  " + "".join(f"{show(d).replace(', ', ','):>8}" for d in ROUND))
print("  " + "".join(f"{s:>8.2f}" for s in scores))
assert dot(SHOP_Q, SHOP_P) == 16 and dot_from_lengths(SHOP_Q, SHOP_P) == 16.0
assert (add_them, all_pairs, back_to_front) == (15, 54, 17)
assert squares(LEG) == 25 and dot(LEG, PERP) == 0 and squares(gap) == squares(LEG) + squares(PERP)
assert scores[2] == 1.0 and scores[8] == -1.0 and all(-1.0 <= s <= 1.0 for s in scores)
assert all(dot(LEG, d) ** 2 <= squares(LEG) * squares(d) for d in ROUND)   # Cauchy-Schwarz
print("ALL CHECKS PASS")
