# Basis and dimension -- the check behind the card.  Nothing is imported.  A
# rowing crew on a river; positions in km east and km north of the boathouse.
# Two bases of the same plane: east-north (1, 0) and (0, 1), and the river
# basis (1, 1) downstream and (-1, 1) across.  The buoy sits at (5, 3).
E1, E2 = (1, 0), (0, 1)                  # the standard basis: one east, one north
B1, B2 = (1, 1), (-1, 1)                 # downstream along the river, and across it
SPARE = (1, 0)                           # a spare third vector: spans, but not a basis

def combo(cs, vs):                       # so much of each vector, added up
    return (sum(c * v[0] for c, v in zip(cs, vs)),
            sum(c * v[1] for c, v in zip(cs, vs)))

def cross(u, v):                         # zero exactly when the two are dependent
    return u[0] * v[1] - v[0] * u[1]

def eliminate(t):                        # road one: x - y = east, x + y = north
    x = (t[0] + t[1]) / 2
    return x, t[1] - x

def rule(t, b1, b2):                     # road two: the cross-number rule
    d = cross(b1, b2)
    return cross(t, b2) / d, cross(b1, t) / d

def tup(v): return f"({v[0]:.0f}, {v[1]:.0f})"
def trip(c): return f"({c[0]:.0f}, {c[1]:.0f}, {c[2]:.0f})"
def show(name, value): print(f"{name:<48}{value:>12}")

show("cross-number, river basis then east-north basis",
     f"{cross(B1, B2)} and {cross(E1, E2)}")
for t in ((5, 3), (0, 6)):
    ex, ey = eliminate(t)
    rx, ry = rule(t, B1, B2)
    show(f"point {tup(t)}: east-north coordinates", tup(combo(t, (E1, E2))))
    show(f"point {tup(t)}: river coordinates, by elimination", tup((ex, ey)))
    show(f"point {tup(t)}: river coordinates, by cross-number", tup((rx, ry)))
    show(f"point {tup(t)}: rebuilt from the river basis", tup(combo((ex, ey), (B1, B2))))
wrong_read = combo((5, 3), (B1, B2))     # east-north numbers used as river ones
wrong_order = combo((-1, 4), (B1, B2))   # the two coordinates the wrong way round
show("wrong: (5, 3) read as river coordinates", tup(wrong_read))
show("wrong: the river coordinates in the other order", tup(wrong_order))
show("wrong: cross-number of (1, 1) and (2, 2)", cross((1, 1), (2, 2)))
first, second = (4, -1, 0), (3, 0, 2)
show("with a spare third vector, one answer", trip(first))
show("with a spare third vector, another answer", trip(second))
show("both of those rebuild the buoy",
     tup(combo(first, (B1, B2, SPARE))) + " " + tup(combo(second, (B1, B2, SPARE))))
river = [combo((s, 0), (B1, B2)) for s in range(6)]
route = [combo((s, 0), (B1, B2)) for s in range(5)] + [combo((4, -1), (B1, B2))]
def row(name, vals): print(f"{name:<48}" + " ".join(f"{v:>2}" for v in vals))
row("chart, km east", [p[0] for p in river])
row("chart, the river, km north", [p[1] for p in river])
row("chart, the crew's route, km north", [p[1] for p in route])
show("vectors in each basis, so the dimension", f"{len((B1, B2))} and {len((E1, E2))}")
assert eliminate((5, 3)) == (4, -1) and rule((5, 3), B1, B2) == (4, -1) and combo((4, -1), (B1, B2)) == (5, 3)
assert eliminate((0, 6)) == (3, 3) and rule((0, 6), B1, B2) == (3, 3) and combo((3, 3), (B1, B2)) == (0, 6)
assert cross(B1, B2) == 2 and cross(E1, E2) == 1 and cross((1, 1), (2, 2)) == 0
assert wrong_read == (2, 8) and wrong_order == (-5, 3) and first != second and \
    combo(first, (B1, B2, SPARE)) == combo(second, (B1, B2, SPARE)) == (5, 3)
print("ALL CHECKS PASS")
