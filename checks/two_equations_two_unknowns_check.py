# Two equations, two unknowns -- the check behind the card.  Nothing is imported.
# Friday: 2 adults and 3 children pay $41.  Saturday: 1 adult and 2 children pay
# $24.  x is the adult price, y is the child price, both held in whole cents.
FRI = (2, 3, 4100)                    # adults, children, total in cents
SAT = (1, 2, 2400)
SUN = (4, 6, 7000)                    # a third receipt that cannot be right
GUESS = (1300, 500)                   # a pair that fits Friday and nothing else
a, b, p = FRI
c, d, q = SAT

def m(cents): return f"{cents / 100:.2f}"
def one(name, value): print(f"{name:<58}{value:>8}")
def row(name, cents): print(f"{name:<26}" + "".join(f"{m(v):>7}" for v in cents))

# road one: elimination.  Double Saturday so both receipts carry two adults.
dbl = (2 * c, 2 * d, 2 * q)
y1 = (dbl[2] - p) // (dbl[1] - b)     # the one child left over
x1 = (q - d * y1) // c                # that price back into Saturday
# road two: substitution.  Saturday says x = (q - d*y)/c; put that into Friday.
y2 = (p * c - a * q) // (b * c - a * d)
x2 = (q - d * y2) // c
# road three: the crossing number, then the cross-multiplied pair
cross = a * d - b * c
x3, y3 = (p * d - b * q) // cross, (a * q - c * p) // cross
wy = q - p                            # mistake: only the tickets doubled
wx = q - d * wy

one("Friday, 2 adults and 3 children", m(p))
one("Saturday, 1 adult and 2 children", m(q))
one("elimination -- Saturday doubled, 2 adults and 4 children", m(dbl[2]))
one("minus Friday, leaving one child", m(y1))
one("that price back into Saturday, one adult", m(x1))
one(f"substitution -- child {m(y2)}, adult", m(x2))
one(f"crossing number {cross} -- cross-multiplied child {m(y3)}, adult", m(x3))
one(f"Friday checks, {m(a * x1)} + {m(b * y1)}", m(a * x1 + b * y1))
one(f"Saturday checks, {m(c * x1)} + {m(d * y1)}", m(c * x1 + d * y1))
one("Sunday claims 4 adults and 6 children cost", m(SUN[2]))
one(f"Friday doubled says they cost, crossing number {a * SUN[1] - b * SUN[0]}", m(2 * p))
one(f"had Sunday read {m(2 * p)}, ({m(x1)}, {m(y1)}) fits and so does",
    f"({m(GUESS[0])}, {m(GUESS[1])})")

def at(r, y): return (r[2] - r[1] * 100 * y) // r[0]      # a receipt's line
row("child price, dollars", [100 * y for y in range(11)])
row("adults on Friday's line", [at(FRI, y) for y in range(11)])
row("adults on Saturday's line", [at(SAT, y) for y in range(11)])
row("adults on Sunday's line", [at(SUN, y) for y in range(11)])

one(f"mistake -- only the tickets doubled: child {m(wy)}, adult", m(wx))
one("mistake -- the rearranged adult back into Saturday", f"{m(q)} = {m(q)}")
one(f"mistake -- Friday alone at {m(GUESS[0])} and {m(GUESS[1])}, Saturday",
    m(c * GUESS[0] + d * GUESS[1]))

assert (x1, y1) == (x2, y2) == (x3, y3)                   # three roads, one pair
assert a * 1000 + b * 700 == p and c * 1000 + d * 700 == q and (x1, y1) == (1000, 700)
assert a * GUESS[0] + b * GUESS[1] == p and c * GUESS[0] + d * GUESS[1] == 2300
assert a * SUN[1] - b * SUN[0] == 0 and 2 * p == 8200 and SUN[2] != 8200
print("ALL CHECKS PASS")
