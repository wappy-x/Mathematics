# Sheaves in outline -- the check behind the card.  Standard library only.
# The space is the projective line P^1, covered by two charts: U0 with
# coordinate t, and U1 with coordinate s, overlapping where s = 1/t.  A section
# over U0 is a polynomial f(t), over U1 a polynomial g(s); both restrict to the
# overlap as Laurent polynomials in t (powers of t from -12 to 12, as a list).
# The twist d sets the gluing rule f(t) = t^d g(1/t); d = 0 is the sheaf O.
# flip=False glues by s = t instead: the wrong rule, for "What breaks".
from fractions import Fraction

LO, HI = -12, 12

def from_u0(f):                            # restrict f(t) to the overlap
    out = [0] * (HI - LO + 1)
    for i, c in enumerate(f):
        out[i - LO] += c
    return out

def from_u1(g, d, flip=True):              # restrict g(s), s = 1/t, times t^d
    out = [0] * (HI - LO + 1)
    for j, c in enumerate(g):
        out[(d - j if flip else d + j) - LO] += c
    return out

def rank(rows):                            # Gaussian elimination over Q, exact
    rows, r = [row[:] for row in rows], 0
    for col in range(len(rows[0])):
        piv = next((i for i in range(r, len(rows)) if rows[i][col] != 0), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(len(rows)):
            if i != r and rows[i][col] != 0:
                k = rows[i][col] / rows[r][col]
                rows[i] = [x - k * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r

def glue_road(n, d, flip=True):            # road one: rank of (f, g) -> f - t^d g(1/t)
    cols = []
    for i in range(n + 1):
        cols.append(from_u0([1 if k == i else 0 for k in range(i + 1)]))
    for j in range(n + 1):
        cols.append([-x for x in from_u1([1 if k == j else 0 for k in range(j + 1)], d, flip)])
    used = [e for e in range(HI - LO + 1) if any(c[e] for c in cols)]
    window = range(used[0], used[-1] + 1)  # every power of t between the extremes
    rows = [[Fraction(c[e]) for c in cols] for e in window]
    rk = rank(rows)
    return 2 * (n + 1) - rk, len(window) - rk   # (glued sections, terms never reached)

def polys(p, n):                           # every polynomial of degree <= n over F_p
    for code in range(p ** (n + 1)):
        yield [code // p ** k % p for k in range(n + 1)]

def brute_road(p, n, d):                   # road two: test every pair, mod p
    hits = 0
    for f in polys(p, n):
        left = [x % p for x in from_u0(f)]
        for g in polys(p, n):
            if left == [x % p for x in from_u1(g, d)]:
                hits += 1
    return hits

def components(intervals):                 # open intervals: count connected pieces
    pieces, end = 0, None
    for a, b in sorted(intervals):
        if end is None or a >= end:
            pieces += 1
        end = b if end is None else max(end, b)
    return pieces

def yn(claim):
    return "yes" if claim else "no"

N, P, BN = 6, 5, 2
print("P^1 = U0 (coordinate t) and U1 (coordinate s), overlap s = 1/t")
f = lambda t: 3 + 2 * t                    # a section over U0
g = lambda s: (3 * s + 2) / s              # the same function, written in s
for t in (2, 10, 100, 1000):
    print(f"t = {t}: f = 3 + 2t = {f(t)}; s = 1/{t}: (3s + 2)/s = {g(Fraction(1, t))}")
print("at s = 0, the point at infinity: (3s + 2)/s has denominator 0, so 3 + 2t is not global")
print(f"constant 3 on U0 glues with constant 3 on U1: {yn(from_u0([3]) == from_u1([3], 0))}")
q2 = [1, 4, 1]                             # twist 2: f = 1 + 4t + t^2, g = 1 + 4s + s^2
print(f"twist 2: 1 + 4t + t^2 glues with 1 + 4s + s^2: {yn(from_u0(q2) == from_u1(q2, 2))}")
table = {}
for d in range(-2, 4):
    k, left = glue_road(N, d)
    table[d] = (k, left)
    print(f"twist d = {d:2}: glued sections up to degree {N}: {k}; "
          f"Laurent terms never reached: {left}; formula max(d + 1, 0) = {max(d + 1, 0)}")
counts = {}
for d in range(-2, 3):
    counts[d] = brute_road(P, BN, d)
    print(f"over F_{P}, degree <= {BN}, twist {d:2}: {counts[d]} of {P ** (2 * BN + 2)} pairs glue")
only_u0 = N + 1
same_t, _ = glue_road(N, 0, flip=False)
print(f"mistake 1, chart U0 alone: {only_u0} independent sections up to degree {N}, one more per degree")
print(f"mistake 2, overlap never checked: {2 * (N + 1)} free coefficients up to degree {N}; "
      f"{P ** (2 * BN + 2)} pairs over F_{P}")
print(f"mistake 3, charts glued by s = t: {same_t} glued sections up to degree {N}")
print(f"mistake 4, 3 + 2t read as global: f(1000) = {f(1000)}, and no value at s = 0")
print(f"sections up to degree {N}: chart U0 {N + 1}; overlap, powers -{N} to {N}: {2 * N + 1}")
line = {(1, x) for x in range(P)} | {(0, 1)}                  # (1 : t) and infinity
pairs = {(a, b) for a in range(P) for b in range(P) if (a, b) != (0, 0)}
scaled = {min((a * c % P, b * c % P) for c in range(1, P)) for a, b in pairs}
u0 = [t for a, t in line if a == 1]                           # the points (1 : t) of U0 over F_5
same = all(pow(t, P, P) == t for t in u0)
print(f"points of P^1 over F_{P}: {len(line)}; t^{P} and t agree at each of the {len(u0)} points of U0 over F_{P}: {yn(same)}")
pieces = components([(0, 1), (2, 3)])
one = rank([[Fraction(1)] for _ in range(pieces)])            # one constant c restricts to (c, c): rank 1
print(f"constants on (0, 1) and (2, 3): {one} free value; sections that glue: {pieces}")
assert all(counts[d] == P ** table[d][0] for d in counts)          # rank against brute force
assert all(table[d][0] == max(d + 1, 0) for d in table)            # rank against the formula
assert table[-2][1] == 1 and table[0][1] == 0                     # the gap at t^-1 only
assert same_t == N + 1 and pieces == 2 and one == 1 and same and len(scaled) == len(line) == P + 1
assert all(g(Fraction(1, t)) == f(t) for t in (2, 10, 100, 1000))  # two charts, one function
assert from_u0([3]) == from_u1([3], 0) and from_u0(q2) == from_u1(q2, 2)  # the glued examples
print("ALL CHECKS PASS")
