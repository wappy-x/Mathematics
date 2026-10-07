# The doubling map -- the check behind the card.  Only math.log is imported.  A place
# on the 1 m strip is an exact fraction p/q, so "double, drop the whole metre" is
# p -> 2p mod q (road one); road two shifts the binary digits.  They must agree.
import math
def digits(p, q, k):                  # road two: first k binary digits of p/q
    out = []
    for _ in range(k):
        out.append(2 * p // q)
        p = 2 * p % q
    return out
def orbit(p, q, n):                   # road one: n exact steps of p -> 2p mod q
    for _ in range(n):
        p = 2 * p % q
    return p

def gcd(a, b): return gcd(b, a % b) if b else a    # Euclid, written out
def returners(n):                     # every fraction p/q, q <= 64, back after n steps
    return {(p // gcd(p, q), q // gcd(p, q)) for q in range(1, 65) for p in range(q) if orbit(p, q, n) == p}

M, d = 2 ** 30, digits(7, 10, 70)
agree = all(digits(orbit(7, 10, n), 10, 40) == d[n:n + 40] for n in range(31))
bp, bq = 7 * (7 * M // 10) + 1, 7 * M        # neighbour: 0.7's first 30 digits, then 1/7's
g0n, g0d = 49 * M - 10 * bp, 70 * M          # gap at the start, exact: 0.7 - neighbour
p30, b30 = orbit(7, 10, 30), orbit(bp, bq, 30)
g30n, g30d = p30 * bq - 10 * b30, 10 * bq    # gap after 30 steps, exact
words = "".join(format(w, "0%db" % L) for L in range(1, 5) for w in range(2 ** L))
cells_digits = {int(words[m:m + 4], 2) for m in range(len(words) - 3)}
cells_exact = {16 * orbit(int(words, 2), 2 ** len(words), m) // 2 ** len(words) for m in range(len(words) - 3)}
x, drop = 0.7, 0
while x != 0.0:
    x, drop = 2 * x % 1.0, drop + 1
ra, rb = 147 * M, 30 * bp                    # rotation by a third, over the denominator 210 M
for _ in range(30):
    ra, rb = (ra + 70 * M) % (210 * M), (rb + 70 * M) % (210 * M)
print("0.7 m in binary: 0." + "".join(map(str, d[:16])) + "...")
print("orbit of 0.7 m, steps 0 to 8:", " ".join(f"{orbit(7, 10, n) / 10:.1f}" for n in range(9)))
print("doubled, before the cut, rounds 1 to 5:", " ".join(f"{2 * orbit(7, 10, n) / 10:.1f}" for n in range(5)))
print("half it lands in (1 = right), steps 0 to 8:", " ".join(str(b) for b in d[:9]))
print("exact fractions and shifted digits agree for 30 steps:", "yes" if agree else "no")
print(f"neighbour: 0.7's first 30 digits, then 1/7's; gap at the start {g0n / g0d * 1e9:.3f} nm")
print(f"digit 31: 0.7 has {d[30]}, the neighbour has {digits(bp, bq, 31)[30]}")
print(f"after 30 steps: 0.7 -> {p30 / 10:.1f}, neighbour -> {b30 / bq:.6f} = 1/7; gap {g30n / g30d:.3f} m")
print(f"flip digit 31 alone: after 30 steps 0.7 -> {p30 / 10:.1f}, flipped -> {orbit(7 * 2 * M - 10, 20 * M, 30) / (20 * M):.1f}; gap {p30 / 10 - orbit(7 * 2 * M - 10, 20 * M, 30) / (20 * M):.1f} m")
print(f"gap multiplied per step: {((g30n / g30d) / (g0n / g0d)) ** (1 / 30):.6f}; Lyapunov exponent ln 2 = {math.log((g30n / g30d) / (g0n / g0d)) / 30:.6f}")
print("period-3 orbit: 1/7 -> 2/7 -> 4/7 ->", f"{orbit(4, 7, 1)}/7, binary 0." + "".join(map(str, digits(1, 7, 9))) + "...;",
      f"the other: 3/7 -> {orbit(3, 7, 1)}/7 -> {orbit(3, 7, 2)}/7 -> {orbit(3, 7, 3)}/7")
print(*(f"points back after {n} steps, brute force over q <= 64: {len(returners(n))}; formula 2^{n} - 1 = {2 ** n - 1}" for n in (3, 4)), sep="\n")
print(f"all words of length 1 to 4 in a row: {len(words)} digits; 1/16 m cells visited: {len(cells_digits)} by digits, {len(cells_exact)} by fractions")
tent = [2]                                   # tent map on sevenths: 2x left of 1/2, 2 - 2x right
while len(tent) < 4: tent.append(2 * tent[-1] if 2 * tent[-1] <= 7 else 14 - 2 * tent[-1])
print("tent map period 3:", " -> ".join(f"{t}/7" for t in tent))
print(f"mistake 1, floating point: 0.7 as a double reaches exactly 0 after {drop} steps")
print(f"mistake 2, no mod 1: 0.7 m doubled 30 times = {7 * M / 10:.1f} m")
print(f"mistake 3, rotation by a third: period 3 everywhere, gap after 30 steps {(ra - rb) % (210 * M) / (210 * M) * 1e9:.3f} nm")
print("figure, 1 m = 180 units, (x, y) of 1/7 2/7 4/7:", *(f"({60 + 180 * k / 7:.2f}, {210 - 180 * k / 7:.2f})" for k in (1, 2, 4)))
assert agree and int("".join(map(str, d[:40])), 2) == 7 * 2 ** 40 // 10   # digits right, roads agree
assert g30n * g0d == M * g0n * g30d and digits(bp, bq, 60)[30:] == digits(1, 7, 30)
assert [len(returners(n)) for n in (3, 4)] == [2 ** 3 - 1, 2 ** 4 - 1]
assert cells_digits == cells_exact == set(range(16))
print("ALL CHECKS PASS")
