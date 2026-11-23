# Counting solutions and #P -- the check behind the card.  A floor 4 squares by 6 takes 1 x 2
# dominoes; deciding needs one tiling, counting needs all.  Only math.cos and math.pi are imported.
import math
ROWS, COLS = 4, 6

def search(rows, cols):             # road one: cover the first empty square every legal way
    full = [[False] * cols for _ in range(rows)]
    seen = [0, 0]                   # tilings found, squares tried
    def go(i):
        seen[1] += 1
        while i < rows * cols and full[i % rows][i // rows]:
            i += 1                  # squares are read down each column, column by column
        if i == rows * cols:
            seen[0] += 1
            return
        r, c = i % rows, i // rows
        for dr, dc in ((1, 0), (0, 1)):        # an upright domino, then a flat one
            if r + dr < rows and c + dc < cols and not full[r + dr][c + dc]:
                full[r][c] = full[r + dr][c + dc] = True
                go(i + 1)
                full[r][c] = full[r + dr][c + dc] = False
    go(0)
    return seen

def moves(mask, r, nxt, rows, out):  # ways to finish one column whose filled squares are mask
    if r == rows:
        out.append(nxt)
    elif mask >> r & 1:
        moves(mask, r + 1, nxt, rows, out)
    else:
        moves(mask, r + 1, nxt | 1 << r, rows, out)              # flat: pokes into the next column
        if r + 1 < rows and not mask >> (r + 1) & 1:
            moves(mask, r + 2, nxt, rows, out)                   # upright: two squares here

def transfer(rows, cols):            # road two: 2^rows column states, stepped cols times
    v = [1] + [0] * ((1 << rows) - 1)
    for _ in range(cols):
        w = [0] * (1 << rows)
        for mask in range(1 << rows):
            out = []
            moves(mask, 0, 0, rows, out)
            for nxt in out:
                w[nxt] += v[mask]
        v = w
    return v[0], sum(v)              # closed far wall; and the slip that lets dominoes poke out

def det(a):                          # exact determinant by fraction-free elimination (Bareiss)
    a, n, sign, prev = [row[:] for row in a], len(a), 1, 1
    for k in range(n - 1):
        if a[k][k] == 0:
            swap = next((i for i in range(k + 1, n) if a[i][k] != 0), None)
            if swap is None: return 0
            a[k], a[swap], sign = a[swap], a[k], -sign
        for i in range(k + 1, n):
            for j in range(k + 1, n):
                a[i][j] = (a[i][j] * a[k][k] - a[i][k] * a[k][j]) // prev
        prev = a[k][k]
    return sign * a[n - 1][n - 1]

def squares(rows, cols, colour):     # dark squares have colour 0, light squares colour 1
    return [(r, c) for c in range(cols) for r in range(rows) if (r + c) % 2 == colour]

def kasteleyn(rows, cols, signed):   # road three: a row per dark square, a column per light one
    dark, light = squares(rows, cols, 0), squares(rows, cols, 1)
    k = [[0] * len(light) for _ in dark]
    for i, (r, c) in enumerate(dark):
        for j, (s, d) in enumerate(light):
            if abs(r - s) + abs(c - d) == 1:   # neighbours: a domino could cover both
                k[i][j] = (-1) ** c if (signed and r != s) else 1
    return abs(det(k))

def product(rows, cols):             # road four: Kasteleyn's closed product of cosines
    p = 1.0
    for j in range(1, rows // 2 + 1):
        for k in range(1, cols // 2 + 1):
            p *= 4 * math.cos(math.pi * j / (rows + 1)) ** 2 + 4 * math.cos(math.pi * k / (cols + 1)) ** 2
    return p

def match(rows, cols):               # deciding: augmenting paths find one tiling, if any exists
    looks, partner = [0], {}       # partner[light square] = the dark square it is paired with
    def augment(u, used):
        r, c = u
        for v in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
            if not (0 <= v[0] < rows and 0 <= v[1] < cols):
                continue
            looks[0] += 1
            if v not in used:
                used.add(v)
                if v not in partner or augment(partner[v], used):
                    partner[v] = u
                    return True
        return False
    return sum(augment(u, set()) for u in squares(rows, cols, 0)), looks[0]

def verify(rows, cols, tiling):      # the checker V: every square covered exactly once
    cells = [(r, c) for r, c, s, d in tiling] + [(s, d) for r, c, s, d in tiling]
    return (all(abs(r - s) + abs(c - d) == 1 for r, c, s, d in tiling) and len(set(cells))
            == len(cells) == rows * cols and all(0 <= r < rows and 0 <= c < cols for r, c in cells))

def adder(a1, a0, b1, b0):           # the two-bit adder from the circuits card, gate by gate
    xor = lambda x, y: (x | y) & (1 - (x & y))   # AND, OR and NOT only: (x OR y) AND NOT (x AND y)
    t, c0 = xor(a1, b1), a0 & b0                 # t = a1 XOR b1; c0 = the carry out of bit 0
    return 4 * ((a1 & b1) | (t & c0)) + 2 * xor(t, c0) + xor(a0, b0)

(found, tried), (closed, poked) = search(ROWS, COLS), transfer(ROWS, COLS)
signed, unsigned = kasteleyn(ROWS, COLS, True), kasteleyn(ROWS, COLS, False)
prod, (paired, looks), strip = product(ROWS, COLS), match(ROWS, COLS), transfer(2, COLS)[0]
flat = [(r, c, r, c + 1) for r in range(4) for c in (0, 2, 4)]
brick = [t for c in (0, 2, 4) for t in ((0, c, 0, c + 1), (1, c, 2, c), (1, c + 1, 2, c + 1), (3, c, 3, c + 1))]
moved = [(1, 0, 1, 1)] + brick[1:]   # the first domino moved onto squares already covered
by_gates = [sum(1 for x in range(16) if adder(x >> 3 & 1, x >> 2 & 1, x >> 1 & 1, x & 1) == s) for s in range(7)]
by_sums = [sum(1 for a in range(4) for b in range(4) if a + b == s) for s in range(7)]   # every sum 0 to 6
yn = lambda claim: "yes" if claim else "no"
print(f"floor {ROWS} by {COLS}: {ROWS * COLS} squares, {ROWS * COLS // 2} dominoes")
print(f"decide: augmenting paths pair {paired} of {ROWS * COLS // 2} dark squares after {looks} looks")
print(f"count, road 1, every tiling listed: {found} tilings, {tried} squares tried")
print(f"count, road 2, column states stepped: {closed}")
print(f"count, road 3, signed determinant: {signed}")
print(f"count, road 4, product of cosines: {prod:.6f}")
print("growth 4 by m: m, tilings, squares tried by listing, looks to decide")
for m in (2, 4, 6, 8, 10):
    print(f"  {m}, {transfer(4, m)[0]}, {search(4, m)[1]}, {match(4, m)[1]}")
print("square floors: side, tilings by column states, by signed determinant")
for s in (2, 4, 6, 8):
    print(f"  {s}, {transfer(s, s)[0]}, {kasteleyn(s, s, True)}")
print(f"checker V accepts all-flat: {yn(verify(4, 6, flat))}; brick: {yn(verify(4, 6, brick))}; "
      f"brick less one domino: {yn(verify(4, 6, brick[1:]))}; one moved: {yn(verify(4, 6, moved))}")
for name, t in (("all-flat", flat), ("brick", brick)):
    print(f"figure, {name}:", "; ".join(" ".join(str(x) for x in d) for d in t))
print(f"two-bit adder, inputs giving sum 3: {by_gates[3]} by the gates, {by_sums[3]} by a + b = 3")
print(f"mistake 1, each domino flat or upright freely: 2^12 = {2 ** 12}")
print(f"mistake 2, two 2 by 6 strips: {strip} x {strip} = {strip * strip}, missing {closed - strip * strip}")
print(f"mistake 3, determinant with no signs: {unsigned}")
print(f"mistake 4, dominoes left poking out of the far wall: {poked}")
assert found == closed == signed == 281                         # three exact roads agree
assert abs(prod - found) < 1e-6                                 # the closed product agrees
assert paired == ROWS * COLS // 2 and by_gates == by_sums and by_gates[3] == 4  # a tiling; the adder
assert transfer(8, 8)[0] == kasteleyn(8, 8, True) == 12988816   # the chessboard, two roads
assert verify(4, 6, flat) and verify(4, 6, brick) and not verify(4, 6, brick[1:]) and not verify(4, 6, moved)
print("ALL CHECKS PASS")
