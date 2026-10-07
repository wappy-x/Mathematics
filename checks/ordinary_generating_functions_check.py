# Generating functions -- the check behind the card.  Nothing is imported.  A
# series is a list of coefficients: the entry at index n is the count hanging on
# x^n.  Two dice are x + x^2 + ... + x^6 twice over; their product is built by
# adding exponents, then checked against a listing of all 36 ordered rolls.
FACES = range(1, 7)                       # the six faces of one die
DIE = [0] + [1] * 6                       # one way to show each of 1 to 6
N = 8                                     # how far the series of ones is written

def poly_mul(a, b):                       # road one: every pair, exponents added
    out = [0] * (len(a) + len(b) - 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            out[i + j] += ai * bj
    return out

def tally_rolls(faces):                   # road two: list the rolls, count totals
    counts = {}
    for u in faces:
        for v in faces:
            counts[u + v] = counts.get(u + v, 0) + 1
    return [counts[t] for t in range(min(counts), max(counts) + 1)]

def splits(n, faces):                     # the ways to split n across two dice
    return [(k, n - k) for k in faces if n - k in faces]

def yn(claim):
    return "yes" if claim else "no"

two = poly_mul(DIE, DIE)                  # the product series, index = the total
totals = two[2:]                          # nothing lands below x^2
listed = tally_rolls(FACES)
ones = [1] * (N + 1)
ones_squared = poly_mul(ones, ones)[: N + 1]
by_formula = [n + 1 for n in range(N + 1)]
inverse = poly_mul([1, -1], ones)         # (1 - x) times the ones, degree by degree
termwise = [u * v for u, v in zip(DIE[1:], DIE[1:])]
zero_to_five = poly_mul([1] * 6, [1] * 6)
added = [2 * c for c in DIE] + [0] * 6
cut = poly_mul([1, -1], [1] * 6)

print(f"one die as a series: the counts on x^1 to x^6 = {DIE[1:]}")
print(f"two dice, series multiplied: totals 2 to 12 -> {totals}")
print(f"the same counts, by listing all 36 ordered rolls: {listed}")
print(f"two roads agree: {yn(totals == listed)}")
print(f"coefficient of x^7 = {two[7]}, from the splits {splits(7, FACES)}")
print(f"the eleven counts sum to {sum(totals)}; 6 faces x 6 faces = {6 * 6}")
print(f"the ones squared, n = 0 to {N}: {ones_squared}")
print(f"the same list, by the count n + 1: {by_formula}")
print(f"(1 - x) times the ones through x^{N}: {inverse}")
print(f"1 stands alone, the only leftover -1 on x^{N + 1}: {yn(inverse == [1] + [0] * N + [-1])}")
print(f"mistake 1, the two face lists multiplied term by term: {termwise}, {len(termwise)} counts summing to {sum(termwise)}, not 36")
print(f"mistake 2, faces numbered 0 to 5: coefficient of x^7 = {zero_to_five[7]}, not 6")
print(f"mistake 3, the two series added, not multiplied: coefficient of x^7 = {added[7]}, all counts summing to {sum(added)}")
print(f"mistake 4, the ones cut off at x^5: (1 - x) times it = {cut}, a leftover -1 on x^6")
assert totals == listed                                    # series algebra vs 36 listed rolls
assert totals == [len(splits(t, FACES)) for t in range(2, 13)] and sum(totals) == 36  # third road
assert ones_squared == by_formula                          # multiplied out vs the closed count
assert inverse == [1] + [0] * N + [-1]                     # the inverse, degree by degree
print("ALL CHECKS PASS")
