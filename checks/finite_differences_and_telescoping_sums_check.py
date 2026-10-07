# Finite differences and telescoping sums -- the check behind the card.  Nothing
# is imported.  A supermarket stacks tins in rows of 1, 2, 3, ...: the running
# totals are 1, 3, 6, 10, 15.  Every count is reached twice, once by adding term
# by term and once by a closed form or a telescope collapsed to its two ends.
ROWS, TERMS = 10, 99
def diffs(seq):                            # one pass of jumps: a(n+1) - a(n)
    return [seq[i + 1] - seq[i] for i in range(len(seq) - 1)]
def choose(n, k):                          # n choose k, multiplied out
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out
def gcd(a, b):
    while b: a, b = b, a % b
    return a
def add_fraction(n1, d1, n2, d2):          # exact addition, reduced every step
    n, d = n1 * d2 + n2 * d1, d1 * d2
    g = gcd(n, d)
    return n // g, d // g
def row(name, values):
    print(f"{name:<46}" + " ".join(str(v) for v in values))

totals, running = [], 0                    # road one: add the rows one at a time
for n in range(1, ROWS + 1):
    running += n
    totals.append(running)
first, second = diffs(totals), diffs(diffs(totals))
closed = [n * (n + 1) // 2 for n in range(1, ROWS + 1)]                    # road two
newton = [1 + 2 * choose(n - 1, 1) + choose(n - 1, 2) for n in range(1, ROWS + 1)]
exact, wrong = (0, 1), 0.0                 # road one to the fraction sum: add it up
for k in range(1, TERMS + 1):
    exact = add_fraction(exact[0], exact[1], 1, k * (k + 1))
    wrong += 1 / k + 1 / (k + 1)           # the same split, written with a plus
tele = (TERMS, TERMS + 1)                  # road two: 1 - 1/100, collapsed to two ends
fib = [1, 1]
while len(fib) < 11: fib.append(fib[-1] + fib[-2])
added = sum(fib[:9])
row("tins in rows 1 to 10", range(1, ROWS + 1))
row("running totals, added row by row", totals)
row("first differences", first)
row("second differences", second)
row("the same totals from n(n+1)/2", closed)
row("the same totals from Newton's formula", newton)
print(f"Newton at n = 5: 1 + 2*C(4,1) + C(4,2) = 1 + {2 * choose(4, 1)} + {choose(4, 2)} = {newton[4]}")
print(f"ten rows: {totals[-1]} tins by adding, {closed[-1]} from n(n+1)/2")
print(f"the jumps add to the trip: 2+3+...+{ROWS} = {sum(first)} = {totals[-1]} - {totals[0]}")
row("the first three terms as differences", [f"1/{k}-1/{k + 1}" for k in (1, 2, 3)])
print(f"1/(k(k+1)) added exactly to k = {TERMS}: {exact[0]}/{exact[1]} = {exact[0] / exact[1]:.2f}")
print(f"the same sum, telescoped: 1 - 1/{TERMS + 1} = {tele[0]}/{tele[1]} = {tele[0] / tele[1]:.2f}")
row("Fibonacci F(1) to F(11), the hallway count", fib)
print(f"F(1)+...+F(9) added: {added}; telescoped F(11) - F(2) = {fib[10]} - {fib[1]} = {fib[10] - fib[1]}")
print(f"mistake 1, second difference 1 read as the rule n^2: 5 rows -> {5 ** 2}, not {closed[4]}")
print(f"mistake 2, the collapse stopped at a(n): {ROWS * (ROWS - 1) // 2}, not {totals[-1]}")
print(f"mistake 3, the split written with a plus: {wrong:.2f}, not {exact[0] / exact[1]:.2f}")
assert first == list(range(2, ROWS + 1)) and second == [1] * (ROWS - 2)
assert totals == closed and closed == newton
assert sum(first) == totals[-1] - totals[0] and exact == tele
assert added == fib[10] - fib[1] and fib[10] == 89
print("ALL CHECKS PASS")
