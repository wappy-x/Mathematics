# Null sets and almost everywhere -- the check behind the card.  Standard
# library only.  A dart lands uniformly on a board of radius 1 m, so the
# chance of a region is its area divided by pi.  Four roads: exact chances
# against a simulated dart, a countable cover by list against its closed form,
# pi by a series against a grid count, and a completion built two ways.
from fractions import Fraction

MASK = (1 << 64) - 1

def splitmix64(state):                   # small generator, identical in Rust
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

def gcd(a, b):
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a

def arctan_inv(n):                       # arctan(1/n) by its alternating series
    total, term, k, sign = 0.0, 1.0 / n, 1, 1
    while term > 1e-18:
        total += sign * term / k
        term, k, sign = term / (n * n), k + 2, -sign
    return total

# road one to pi: Machin's series.  road two: count grid cells inside a circle.
pi_series = 16 * arctan_inv(5) - 4 * arctan_inv(239)
R, x, cells = 1_000_000, 1_000_000, 0
for y in range(R):                       # cells in one quarter, row by row
    while x * x + y * y >= R * R:
        x -= 1
    cells += x + 1
pi_upper = 4 * cells / (R * R)           # cells with a corner inside: cover the disc
pi_lower = 4 * (cells - 2 * R) / (R * R) # cells wholly inside: fit in the disc
print(f"board area by Machin's series: {pi_series:.6f} m^2")
print(f"board area by 1-micron cells: between {pi_lower:.6f} and {pi_upper:.6f} m^2")

# a simulated dart: uniform in the 2 m square, kept only if it hits the board
N, radii = 200_000, [0.5, 0.2, 0.1, 0.05, 0.02, 0.01]
state, darts = 20260929, []
while len(darts) < N:
    state, a = splitmix64(state)
    state, b = splitmix64(state)
    px, py = 2 * (a >> 11) / 2**53 - 1, 2 * (b >> 11) / 2**53 - 1
    if px * px + py * py <= 1:
        darts.append(px * px + py * py)
exact_centre = [r * r for r in radii]                    # area pi r^2 over pi
exact_rim = [1 - (1 - r) * (1 - r) for r in radii]      # annulus over pi
print(f"darts thrown {N}, seed 20260929")
print("r, P(within r of centre) exact, simulated, P(within r of rim) exact, simulated")
worst = 0.0
for r, c, m in zip(radii, exact_centre, exact_rim):
    sc = sum(1 for d in darts if d < r * r) / N
    sm = sum(1 for d in darts if d > (1 - r) * (1 - r)) / N
    for e, s in ((c, sc), (m, sm)):
        worst = max(worst, abs(s - e) / (e * (1 - e) / N) ** 0.5)
    print(f"{r:.2f}, {c:.4f}, {sc:.4f}, {m:.4f}, {sm:.4f}")
print(f"largest gap, in standard errors: {worst:.2f}")
print(f"darts landing exactly on the centre: {sum(1 for d in darts if d == 0)} of {N}")

# rational points on the board, listed by denominator: a countable list
eps, listed, seen, grid_count = Fraction(1, 1000), [], set(), 0
print("eps = 0.001; denominator up to D, rational points listed K, cover area total")
for D in range(1, 7):                    # points p1/D, p2/D on the board
    for p1 in range(-D, D + 1):
        for p2 in range(-D, D + 1):
            if p1 * p1 + p2 * p2 <= D * D:
                pt = (Fraction(p1, D), Fraction(p2, D))           # road one: reduce
                if pt not in seen:
                    seen.add(pt)
                    listed.append(pt)
                if gcd(gcd(p1, p2), D) == 1:                     # road two: gcd test
                    grid_count += 1
    K = len(listed)
    by_list = sum(eps / 2**k for k in range(1, K + 1))          # square k: eps/2^k
    closed = eps * (1 - Fraction(1, 2**K))
    assert by_list == closed and K == grid_count
    print(f"D={D}, K={K}, cover {float(by_list):.10f} m^2, chance at most {float(by_list) / pi_series:.10f}")

# uncountable but null: the diameter, covered by n squares of side 2/n
print("diameter covered by n squares of side 2/n: n, total area 4/n, chance at most")
for n in (10, 100, 1000):
    print(f"n={n}, {4 / n:.4f} m^2, {4 / n / pi_series:.6f}")

# the scorer's record: centre dot, rim line, inner, outer (bits 1, 2, 4, 8)
names = ["centre", "rim", "inner", "outer"]
F = {0: Fraction(0), 3: Fraction(0), 12: Fraction(1), 15: Fraction(1)}
nulls = [A for A, p in F.items() if p == 0]
pairs = {(A | M, F[A]) for A in F for Nn in nulls for M in range(16) if M & ~Nn == 0}
road1 = dict(pairs)                      # well defined: one value per set
road2 = {E: F[A] for E in range(16) for A in F for B in F
         if A & ~E == 0 and E & ~B == 0 and (B & ~A) in F and F[B & ~A] == 0}
closed_up = all((15 ^ E) in road1 and (E | G) in road1 for E in road1 for G in road1)
label = lambda E: "{" + ", ".join(names[i] for i in range(4) if E >> i & 1) + "}"
print(f"scorer's sigma-algebra: {len(F)} sets; its completion: {len(road1)} sets of 16")
for E in sorted(road1):
    print(f"  {label(E)}: {road1[E]}")
print(f"completion closed under complement and union: {'yes' if closed_up else 'no'}")
print(f"not in the completion: {label(4)}, {label(8)}, {label(5)}")

# the usual mistake: every simulated coordinate is a fraction over 2^53
on_rational = 0
for i in range(1000):
    v = 2 * (splitmix64(i)[1] >> 11) / 2**53 - 1
    on_rational += Fraction(v).denominator <= 2**53      # a whole number over 2^53
print(f"simulated coordinates that are rational: {on_rational} of 1000")
print("figure, board r=100px at (120,120); centre discs 50, 20, 10 px; rim band 90-100 px")

assert pi_lower < pi_series < pi_upper                   # two roads to the area
assert worst < 4.0                                       # simulation within 4 SE
assert road1 == road2 and len(pairs) == len(road1) == 8 and closed_up  # one value each
