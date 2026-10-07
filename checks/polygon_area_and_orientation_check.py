# Shoelace formula: the check behind the card. Standard library only.
# The survey polygon, corners A to F in hundreds of metres from a survey peg,
# so one grid square is one hectare. Road one is the shoelace sum of cross
# products. Road two slices the field into thin upright strips and adds their
# heights; it never forms a cross product.
POLY = [(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]      # A B C D E F
NAMES = "ABCDEF"

def cross(p, q): return p[0] * q[1] - p[1] * q[0]
def terms(P): return [cross(P[i], P[(i + 1) % len(P)]) for i in range(len(P))]
def shoelace(P): return sum(terms(P)) / 2
def turn(a, b, c): return cross((b[0] - a[0], b[1] - a[1]), (c[0] - a[0], c[1] - a[1]))

def slices(P, n=9000):             # road two: n strips across x = 2..11
    lo, hi = min(p[0] for p in P), max(p[0] for p in P)
    w, total = (hi - lo) / n, 0.0
    for k in range(n):
        x = lo + (k + 0.5) * w     # the strip's middle line
        ys = []
        for i in range(len(P)):
            (x1, y1), (x2, y2) = P[i], P[(i + 1) % len(P)]
            if (x1 <= x < x2) or (x2 <= x < x1):
                ys.append(y1 + (y2 - y1) * (x - x1) / (x2 - x1))
        ys.sort()                  # boundary crossings, bottom to top
        total += w * sum(ys[j + 1] - ys[j] for j in range(0, len(ys), 2))
    return total

t = terms(POLY)
area, strip = shoelace(POLY), slices(POLY)
back = shoelace(POLY[::-1])
turns = [turn(POLY[i - 1], POLY[i], POLY[(i + 1) % 6]) for i in range(6)]
no_d = POLY[:3] + POLY[4:]                             # cut the notch off at D
notch = slices(no_d) - strip
moved = [(x - 2, y - 1) for x, y in POLY]              # peg moved onto corner A
swapped = [POLY[i] for i in (0, 2, 1, 3, 4, 5)]        # B and C copied in the wrong order
print("corners:", ", ".join(f"{n} ({x}, {y})" for n, (x, y) in zip(NAMES, POLY)))
print("edge products:", ", ".join(f"{p[0] * q[1]} - {p[1] * q[0]}" for p, q in zip(POLY, POLY[1:] + POLY[:1])))
print("figure, 1 unit = 26 svg units: peg (30, 222),", ", ".join(f"{n} ({30 + 26 * x}, {222 - 26 * y})" for n, (x, y) in zip(NAMES, POLY)))
print("edge terms AB BC CD DE EF FA:", ", ".join(str(v) for v in t), "; sum", sum(t))
print(f"road one, shoelace: {area:.1f} ha = {area * 10000:,.0f} m^2")
print(f"road two, 9000 upright strips: {strip:.6f} ha")
print(f"walked backwards, A F E D C B: {back:.1f} ha")
print("turn test at A B C D E F:", ", ".join(str(v) for v in turns))
fan = [turn(POLY[3], POLY[k], POLY[(k + 1) % 6]) / 2 for k in (4, 5, 0, 1)]   # D with EF, FA, AB, BC
print("fan from D, triangles DEF DFA DAB DBC:", ", ".join(f"{v:.1f}" for v in fan), "ha")
print(f"cut the notch at D, by strips: {notch:.6f} ha more; half of -(turn at D): {-turns[3] / 2:.1f}")
print(f"peg moved onto A: terms {', '.join(str(v) for v in terms(moved))}; area {shoelace(moved):.1f} ha")
print(f"what breaks: closing edge FA left out: {sum(t[:-1]) / 2:.1f} ha")
print(f"what breaks: no halving: {sum(t):.1f}")
print(f"what breaks: each term made positive: {sum(abs(v) for v in t) / 2:.1f} ha")
print(f"what breaks: B and C swapped: shoelace {shoelace(swapped):.1f} ha, ground covered {slices(swapped):.2f} ha")
assert abs(area - strip) < 1e-6                        # two roads, one area
assert back == -area and shoelace(moved) == area       # direction flips the sign; the peg does not matter
assert [v < 0 for v in turns] == [False, False, False, True, False, False]
assert abs(notch - (-turns[3] / 2)) < 1e-6             # the right turn's triangle is the notch
