# Vectors -- the check behind the card.  Nothing is imported.  A delivery
# cyclist rides (3 km east, 4 km north), then rides (2, -1).  Two roads to the
# finish: adding the two legs component by component, and walking the whole
# ride one kilometre at a time to see where the bike actually stops.
U, V = (3, 4), (2, -1)                 # the two legs, each a list of two numbers
WEEK, EVENING = (12, 9, 15, 11), (3, 4, 2, 6)   # the same two rules on four numbers

def add(p, q):   return tuple(a + b for a, b in zip(p, q))   # slot by slot
def scale(k, p): return tuple(k * a for a in p)              # every slot times k

def show(name, value): print(f"{name:<46}{str(value):>18}")
def row(name, values): print(f"{name:<46}" + " ".join(f"{v:.2f}" for v in values))

total = add(U, V)                              # road one: add the two lists
east, north = 0, 0                             # road two: walk it, 1 km at a time
for de, dn in [(1, 0)] * 3 + [(0, 1)] * 4 + [(1, 0)] * 2 + [(0, -1)] * 1:
    east, north = east + de, north + dn
walked = (east, north)
zero = scale(0, U)                             # the ride that never happened

show("first leg u", U)
show("second leg v", V)
show("u + v, added component by component", total)
show("where the ride ends, walked one km at a time", walked)
show("2u, the first leg ridden twice", scale(2, U))
show("u + u, the same doubling by adding", add(U, U))
show("the zero vector, never left the shop", zero)
show("u + 0", add(U, zero))
show("u + (-u)", add(U, scale(-1, U)))
path  = [4 * x / 3 if x <= 3 else 4 - (x - 3) / 2 for x in range(6)]   # the two legs
arrow = [total[1] * x / total[0] for x in range(6)]                    # the one arrow
row("path chart, km north at 0,1,2,3,4,5 km east", path)
row("arrow chart, km north at the same six points", arrow)
show("bar chart, east and north of u then of 2u", U + scale(2, U))
show("a week of rides in R^4, WEEK + EVENING", add(WEEK, EVENING))
print(f"the three mistakes come out at {sum(U) + sum(V)}, "
      f"{tuple(a * b for a, b in zip(U, V))} and {(2 * U[0], U[1])}")
assert total == (5, 3) and walked == total          # two roads, one finish
assert scale(2, U) == (6, 8) and add(U, U) == scale(2, U)
assert add(U, zero) == U and add(U, scale(-1, U)) == (0, 0)
assert add(WEEK, EVENING) == (15, 13, 17, 17) and len(add(WEEK, EVENING)) == 4
print("ALL CHECKS PASS")
