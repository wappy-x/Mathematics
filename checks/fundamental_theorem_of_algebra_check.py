# The fundamental theorem of algebra -- the check behind the card.  Nothing is
# imported.  A complex number a + bi is the integer pair (a, b), and i times i =
# -1 is the only new rule.  Two independent roads to every root: road one puts it
# into the polynomial, road two multiplies the brackets (x - root) back out.
I = (0, 1)
def add(p, q): return (p[0] + q[0], p[1] + q[1])
def mul(p, q): return (p[0] * q[0] - p[1] * q[1], p[0] * q[1] + p[1] * q[0])
def metres(h): return f"{h // 100}.{h % 100:02d}"      # hundredths of a metre
def value_at(coeffs, z):                   # road one: the polynomial at z
    out, power = (0, 0), (1, 0)            # coefficients, constant term first
    for c in coeffs:
        out, power = add(out, mul((c, 0), power)), mul(power, z)
    return out
def from_roots(lead, roots):               # road two: lead*(x - r1)(x - r2)...
    coeffs = [(lead, 0)]
    for r in roots:
        nxt = [(0, 0)] * (len(coeffs) + 1)
        for j, c in enumerate(coeffs):
            nxt[j] = add(nxt[j], mul(c, (-r[0], -r[1])))
            nxt[j + 1] = add(nxt[j + 1], c)
        coeffs = nxt
    return coeffs
def show(z):                               # the pair (a, b) written as a + bi
    a, b = z
    if b == 0: return str(a)
    tail = "i" if abs(b) == 1 else f"{abs(b)}i"
    return f"{a} + {tail}" if b > 0 else f"{a} - {tail}"
# the football: height 20t - 5t^2 metres at t = k/10 seconds, and the polynomial
# 5t^2 - 20t + 25 on the same grid, both in hundredths, so nothing is rounded
heights = [200 * k - 5 * k * k for k in range(41)]
floors = [5 * (k * k - 40 * k + 500) for k in range(41)]
max_h, min_p, real_hits = max(heights), min(floors), sum(1 for v in floors if v == 0)
EXAMPLES = [(5, [25, -20, 5], [(2, 1), (2, -1)], "5t^2 - 20t + 25"),
            (1, [-6, 11, -6, 1], [(1, 0), (2, 0), (3, 0)], "x^3 - 6x^2 + 11x - 6"),
            (1, [1, -2, 1], [(1, 0), (1, 0)], "x^2 - 2x + 1")]
r1, r2 = EXAMPLES[0][2]                    # the ball's two roots, 2 + i and 2 - i
gap = add(r1, (-r2[0], -r2[1]))            # r1 - r2, which is 2i
disc, alt = (-20) ** 2 - 4 * 5 * 25, 25 * mul(gap, gap)[0]   # two roads to it
print(f"i times i, as the pair (real part, i part): {mul(I, I)}")
print("height 20t - 5t^2 in metres, t = 0 to 4 seconds in half-seconds:")
print("  " + "".join(f"{metres(heights[k]):>7}" for k in range(0, 41, 5)))
print(f"the highest height on a tenth-second grid is {metres(max_h)} m, leaving the 25 m target {metres(2500 - max_h)} m out of reach")
print(f"5t^2 - 20t + 25 over {len(floors)} grid times: lowest value {metres(min_p)}, real roots found {real_hits}")
print(f"its discriminant: {disc} from b^2 - 4ac, {alt} from 25 x (root gap)^2; 10 x 10 = {10 * 10}, so the square root of {disc} is 10i")
for lead, coeffs, roots, label in EXAMPLES:
    road_one = ", ".join(str(value_at(coeffs, r)) for r in roots)
    road_two = ", ".join(str(c[0]) for c in from_roots(lead, roots))
    print(f"{label} = 0, degree {len(coeffs) - 1}, roots " + ", ".join(show(r) for r in roots))
    print(f"  road one, the polynomial at each root: {road_one}")
    print(f"  road two, brackets multiplied back, constant first: {road_two}")
    assert (all(value_at(coeffs, r) == (0, 0) for r in roots)
            and from_roots(lead, roots) == [(c, 0) for c in coeffs])
bad = value_at(EXAMPLES[0][1], (1, 0))[0]   # t = 1, from misreading the root
wrong = (from_roots(1, [r1, r2])[0][0], bad, 25 - bad)
print(f"mistakes: leading 5 dropped leaves constant {wrong[0]} not 25; times 1 "
      f"and 3 give {wrong[1]} not 0, a height of {wrong[2]} m not 25 m")
assert mul(I, I) == (-1, 0)
assert max_h == 2000 and max_h + min_p == 2500 and disc == alt
assert real_hits == 0 and wrong == (5, 10, 15)
print("ALL CHECKS PASS")
