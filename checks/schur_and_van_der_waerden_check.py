# Schur and van der Waerden -- the check behind the card.  Nothing is imported.  Cells count from 0; col[i] is
# cell i's colour; a "triple" lists cells that must not all share one colour.  Road one tries every colouring;
# road two grows colourings one cell at a time, keeping those that dodge.
def every(m, r):                                   # all colourings of m cells with r colours
    out = [[]]
    for _ in range(m): out = [c + [k] for c in out for k in range(r)]
    return out
def mono(col, triples): return sum(len({col[c] for c in t}) == 1 for t in triples)
def brute(m, r, triples): return [sum(mono(c, [t for t in triples if max(t) < n]) == 0 for c in every(n, r)) for n in range(1, m + 1)]
def grow(m, r, triples):                           # road two: dodging colourings of cells 0..n-1, for each n
    by, counts = [[sorted(t) for t in triples if max(t) == i] for i in range(m)], [0] * m
    def go(col):
        for k in range(r if len(col) < m else 0):
            if not any(all(col[c] == k for c in t[:-1]) for t in by[len(col)]):
                counts[len(col)] += 1; go(col + [k])
    go([]); return counts
def schur(m, strict=False): return [(x - 1, y - 1, x + y - 1) for x in range(1, m) for y in range(x + strict, m + 1 - x)]
def ap(m): return [(a, a + d, a + 2 * d) for a in range(m) for d in range(1, m) if a + 2 * d < m]
def lines(n, geo):                                 # lines of the 3 x ... x 3 board; "+" runs 0,1,2 and "-" runs 2,1,0
    opts, out = [0, 1, 2, "+"] + ["-"] * geo, []
    for code in range(len(opts) ** n):
        p = [opts[code // len(opts) ** i % len(opts)] for i in range(n)]
        moving = [o for o in p if o in ("+", "-")]
        if moving and moving[0] == "+":            # a line and its reverse are counted once
            out.append(tuple(sum(3 ** i * (j if o == "+" else 2 - j if o == "-" else o) for i, o in enumerate(p)) for j in range(3)))
    return out
def last(counts): return max(n + 1 for n in range(len(counts)) if counts[n])
col4, cv = [0, 1, 1, 0], [0, 0, 1, 1, 0, 0, 1, 1]  # red is 0: Schur's 1, 4 red; van der Waerden's 1, 2, 5, 6 red
print(f"Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: {mono(col4, schur(4))}")
s_b, s_g = brute(5, 2, schur(5)), grow(5, 2, schur(5))
print(f"2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: {s_b}")
print(f"the same, grown one number at a time: {s_g}")
def triangle(col):                                 # road three: points 0..5, the side i-j coloured by |i - j|
    return [(j - i, k - j, k - i) for i in range(6) for j in range(i + 1, 6) for k in range(j + 1, 6) if col[j - i - 1] == col[k - j - 1] == col[k - i - 1]]
tri = sum(len(t := triangle(c)) > 0 and all(mono(c, [(x - 1, y - 1, z - 1)]) for x, y, z in t) for c in every(5, 2))
print(f"Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: {tri} of 32")
for k, name in ((0, "red"), (1, "blue")):
    x, y, z = triangle(col4 + [k])[0]; print(f"add 5 as {name}: the triangle gives {x} + {y} = {z}, all {name}")
s3 = grow(14, 3, schur(14))
print(f"three colours: longest dodge 1..{last(s3)}; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = {17 - 2}")
print(f"van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: {mono(cv, ap(8))}")
w_b, w_g = brute(9, 2, ap(9)), grow(9, 2, ap(9))
print(f"2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: {w_b}")
print(f"the same, grown one number at a time: {w_g}; so W(3; 2) = {w_b.index(0) + 1}")
g2, c2, g3, c3 = lines(2, 1), lines(2, 0), lines(3, 1), lines(3, 0)
draws = sum(mono(c, g2) == 0 for c in every(9, 2) if sum(c) == 5)
print(f"noughts and crosses: lines {len(g2)}, Hales-Jewett lines {len(c2)} = 4^2 - 3^2; drawn full boards (5 X, 4 O): {draws}")
cube_g, cube_c = grow(27, 2, g3)[-1], grow(27, 2, c3)[-1]
print(f"3 x 3 x 3 cube: lines {len(g3)} = (5^3 - 3^3)/2, 2-colourings dodging them all: {cube_g}")
print(f"cube: Hales-Jewett lines {len(c3)} = 4^3 - 3^3, 2-colourings dodging them all: {cube_c}")
sums = [[sum(c // 3 ** i % 3 for i in range(3)) for c in t] for t in c3]
ok = sum(s[1] - s[0] == s[2] - s[1] > 0 for s in sums)
print(f"Hales-Jewett lines whose digit sums form a 3-term progression: {ok} of {len(c3)}; line (j, 1, j): {sums[c3.index((3, 13, 23))]}")
weak = grow(10, 2, schur(10, True))
print(f"mistake, demanding x different from y: longest dodge 1..{last(weak)}")
assert s_b == s_g and s_b[4] == 0 and s_b[3] == 2 and tri == 32           # Schur on 1..5: three roads agree
assert w_b == w_g and w_b[8] == 0 and w_b[7] == 6 and mono(cv, ap(8)) == 0  # W(3; 2) = 9: two roads agree
assert last(s3) == 13 and len(c2) == 4**2 - 3**2 and len(g3) == (5**3 - 3**3) // 2 and cube_g == 0
assert draws == 16 and cube_c > 0 and ok == len(c3) and last(weak) == 8
print("ALL CHECKS PASS")
