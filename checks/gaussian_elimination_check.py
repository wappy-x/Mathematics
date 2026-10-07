# Gaussian elimination -- the check behind the card.  Nothing is imported.
# Three days at one cafe: 2c + p + s = 17, c + p = 7, c + 2p + 2s = 22, with c, p, s
# the prices of a coffee, a pastry and a sandwich.  A row is a day: counts, then total.
DAYS = [[2, 1, 1, 17], [1, 1, 0, 7], [1, 2, 2, 22]]
def num(v): return f"{0.0 if v == 0 else v:g}"       # -0.0 and 0.0 both print as 0
def row_text(r): return "[" + ", ".join(num(v) for v in r[:3]) + " | " + num(r[3]) + "]"
def show(tag, R): print(f"{tag:<14}" + "  ".join(row_text(r) for r in R))
def eliminate(rows, talk=False):
    R = [[float(v) for v in r] for r in rows]        # work on a copy
    pivots, row = [], 0
    if talk: show("start", R)
    for col in range(3):
        piv = next((i for i in range(row, 3) if R[i][col] != 0), None)
        if piv is None: continue                     # no pivot in this column
        if piv != row:
            R[row], R[piv] = R[piv], R[row]          # move one: swap
            if talk: show(f"swap R{row + 1} R{piv + 1}", R)
        for i in range(row + 1, 3):                  # move three: take away a multiple
            if R[i][col] == 0: continue
            m = R[i][col] / R[row][col]
            R[i] = [R[i][j] - m * R[row][j] for j in range(4)]
            if talk: show(f"R{i + 1} - ({num(m)}) R{row + 1}", R)
        pivots.append(R[row][col])
        row += 1
    return R, pivots
def back(R):                                         # bottom row first, then up
    s = R[2][3] / R[2][2]
    p = (R[1][3] - R[1][2] * s) / R[1][1]
    c = (R[0][3] - R[0][1] * p - R[0][2] * s) / R[0][0]
    return c, p, s
def hunt(rows):        # second road: every whole-dollar price list from $0 to $12
    return [(a, b, d) for a in range(13) for b in range(13) for d in range(13) if all(r[0] * a + r[1] * b + r[2] * d == r[3] for r in rows)]
print("three days:  2c + p + s = 17,  c + p = 7,  c + 2p + 2s = 22")
R, piv = eliminate(DAYS, talk=True)
c, p, s = back(R)
print(f"pivots {', '.join(num(v) for v in piv)}: three pivots, three unknowns, one answer")
print(f"back from the bottom: s = {num(s)}, p = {num(p)}, c = {num(c)}")
print("prices put back into the three days: " + ", ".join(num(r[0]*c + r[1]*p + r[2]*s) for r in DAYS))
hits = hunt(DAYS)
print(f"whole dollars from $0 to $12 fitting all three days: {len(hits)}, {hits[0]}")
print()
OTHER = [[0, 1, 1, 9], [2, 1, 1, 17], [1, 1, 0, 7]]  # the days recombined: (2 x Wed - Mon) / 3 on top
c2, p2, s2 = back(eliminate(OTHER)[0])
print(f"days recombined, no coffee on top: a swap is forced, c = {num(c2)}, p = {num(p2)}, s = {num(s2)}")
LINE = [[2, 1, 1, 17], [1, 1, 0, 7], [3, 2, 1, 24]]  # day three is day one plus day two
NONE = [[2, 1, 1, 17], [1, 1, 0, 7], [3, 2, 1, 25]]  # the same day, total misread by $1
for tag, rows in (("day three is day one plus day two, 24", LINE), ("the same days, that total misread as 25", NONE)):
    Rd = eliminate(rows)[0]
    print(f"{tag:<40}bottom row {row_text(Rd[2])}, {'no solution' if Rd[2][3] else 'a line of answers'}")
many = hunt(LINE)
print(f"whole dollars fitting the 24 version: {len(many)}, among them {many[4]} and {many[3]}")
print()
BAD = [DAYS[0], [DAYS[1][j] - 0.5 * DAYS[0][j] for j in range(3)] + [DAYS[1][3]], DAYS[2]]
cb, pb, sb = back(eliminate(BAD)[0])
print(f"wrong, total left out of R2 - (0.5) R1: c = {num(cb)}, p = {num(pb)}, s = {num(sb)}")
assert hits == [(4, 3, 6)] and (c, p, s) == (4.0, 3.0, 6.0) and piv == [2.0, 0.5, 3.0]
assert [r[0]*c + r[1]*p + r[2]*s for r in DAYS] == [17, 7, 22]
assert (c2, p2, s2) == (c, p, s) and len(many) == 8
assert eliminate(LINE)[0][2] == [0, 0, 0, 0] and eliminate(NONE)[0][2] == [0, 0, 0, 1]
print("ALL CHECKS PASS")
