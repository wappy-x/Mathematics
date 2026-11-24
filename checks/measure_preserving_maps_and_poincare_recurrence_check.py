# Measure-preserving maps and Poincare recurrence -- the check behind the card.
# Standard library only.  Exact fractions where the card claims exact values;
# every claim is reached by two roads that share no arithmetic.
from fractions import Fraction as Fr
import math

def doubling_preimage(a, b):        # road one: the formula, two half-length pieces
    return [(a / 2, b / 2), ((a + 1) / 2, (b + 1) / 2)]

def grid_share(step, a, b, bits=20):   # road two: count grid points j / 2^bits
    m = 1 << bits
    return sum(1 for j in range(m) if a <= step(j, m) / m < b) / m

def doubling_grid(j, m):
    return 2 * j % m

def first_return(k, level, cut, steps):   # cell k of width 2^-level; A = cells below cut
    m = 1 << level                          # steps: how far the cell's digits decide
    for n in range(1, steps + 1):
        k = 2 * k % m
        if k < cut:
            return n
    return None                     # not back within the steps the cell decides

a, b = Fr(1, 5), Fr(1, 2)
pieces = doubling_preimage(a, b)
total = sum(hi - lo for lo, hi in pieces)
print("doubling map T(x) = 2x mod 1 on [0, 1), sizes measured by length")
print(f"preimage of [0.2, 0.5): [{float(pieces[0][0])}, {float(pieces[0][1])}) and "
      f"[{float(pieces[1][0])}, {float(pieces[1][1])}); lengths "
      f"{float(pieces[0][1] - pieces[0][0])} + {float(pieces[1][1] - pieces[1][0])} = {float(total)}")
tests = [(Fr(0), Fr(1, 2)), (Fr(1, 5), Fr(1, 2)), (Fr(1, 3), Fr(3, 4)), (Fr(1, 10), Fr(9, 10)), (Fr(2, 7), Fr(5, 7))]
exact_ok = all(sum(h - l for l, h in doubling_preimage(x, y)) == y - x for x, y in tests)
print(f"5 test intervals, exact fractions: preimage length = own length: {'yes' if exact_ok else 'no'}")
g_double = grid_share(doubling_grid, 0.2, 0.5)
print(f"grid of 2^20 points: share that T sends into [0.2, 0.5) = {g_double:.6f}")
image_len = len({doubling_grid(j, 1 << 20) >> 10 for j in range(1 << 19)}) / 1024   # cells of width 2^-10 hit from [0, 0.5)
print(f"forward image of [0, 0.5) under T, by landing cells of width 2^-10: length {image_len:.6f}, twice the length")

alpha = math.sqrt(2) - 1
lo, hi = (0.2 - alpha) % 1, (0.5 - alpha) % 1
print(f"rotation by sqrt 2 - 1 = {alpha:.6f}: preimage of [0.2, 0.5) is [{lo:.6f}, 1) and "
      f"[0, {hi:.6f}); lengths {1 - lo:.6f} + {hi:.6f} = {1 - lo + hi:.6f}")
g_rot = grid_share(lambda j, m: (j + round(alpha * m)) % m, 0.2, 0.5)
print(f"grid of 2^20 points: share that the rotation sends into [0.2, 0.5) = {g_rot:.6f}")

p = 0.3                                     # chance of a 1 on each toss
def chance(word):                           # road one: product of toss chances
    return math.prod(p if s == "1" else 1 - p for s in word)
def preimage_brute(word, n=8):              # road two: add up every string of 8 tosses
    tot = 0.0
    for k in range(1 << n):
        s = format(k, f"0{n}b")
        if s[1:1 + len(word)] == word:      # the shift deletes toss 1
            tot += chance(s)
    return tot
words = [format(k, f"0{L}b") for L in (1, 2, 3) for k in range(1 << L)]
shift_ok = all(abs(preimage_brute(w) - chance(w)) < 1e-12 for w in words)
print(f"coin-toss shift, chance of a 1 = {p}: block 10 has chance {chance('10'):.3f}; "
      f"preimage 010 + 110 = {chance('010'):.3f} + {chance('110'):.3f} = {chance('010') + chance('110'):.3f}")
print(f"all {len(words)} blocks of 1 to 3 tosses, brute force over 2^8 strings: "
      f"preimage chance = own chance: {'yes' if shift_ok else 'no'}")

x, visits = Fr(1, 3), []
for n in range(9):
    if x < Fr(1, 2):
        visits.append(n)
    x = 2 * x % 1
print(f"1/3 -> 2/3 -> 1/3: in A = [0, 0.5) at steps {' '.join(map(str, visits))}")
L = 12
counts = [0] * L
for k in range(1 << (L - 1)):               # the cells of A at level 12
    n = first_return(k, L, 1 << (L - 1), L - 1)
    if n is not None:
        counts[n] += 1
shares = [counts[n] / (1 << (L - 1)) for n in range(1, 7)]
print("first return to A at step n = 1..6, share of A, by cells: " + " ".join(f"{s:.6f}" for s in shares))
print("the same, formula 2^-n: " + " ".join(f"{2.0 ** -n:.6f}" for n in range(1, 7)))
mean_ret = sum(n * c for n, c in enumerate(counts)) / sum(counts)   # cells, steps 1 to 11
print(f"mean first return, by cells {mean_ret:.6f}; formula sum of n 2^-n = {sum(n * 2.0 ** -n for n in range(1, 61)):.6f} = 1/length of A")
print(f"share of A back by step 11, by cells: {sum(counts) / (1 << (L - 1)):.6f}; formula 1 - 2^-11 = {1 - 2.0 ** -11:.6f}")

y, orbit6 = Fr(1, 6), []
for n in range(6):
    orbit6.append(str(y))
    y = 2 * y % 1
start = orbit6[0]
never = all(Fr(s) >= Fr(1, 4) for s in orbit6[1:]) and orbit6[3] == orbit6[5]   # a 2-cycle above 0.25
print(f"A = [0, 0.25): {start} is in A, orbit {' -> '.join(orbit6)}; ever back below 0.25: {'no' if never else 'yes'}")
fib = [0, 1, 1]
while len(fib) < 20:
    fib.append(fib[-1] + fib[-2])
for n in (2, 4, 8, 16):
    lev = n + 2
    stay = sum(1 for k in range(1 << n) if first_return(k, lev, 1 << n, n) is None)
    by_cells, by_fib = stay / (1 << n), fib[n + 1] / 2 ** n
    assert abs(by_cells - by_fib) < 1e-12           # cells against Fibonacci count
    print(f"share of [0, 0.25) not back by step {n}: cells {by_cells:.6f}, Fibonacci {fib[n + 1]}/2^{n} = {by_fib:.6f}")

def dist(n):                                # distance from n * alpha to 0 on the circle
    f = (n * alpha) % 1
    return min(f, 1 - f)
best, records = 1.0, []
for n in range(1, 101):
    if dist(n) < best:
        best = dist(n)
        records.append((n, best))
print("closer than ever before, rotation by sqrt 2 - 1: " + " ".join(f"{n}:{d:.6f}" for n, d in records))
EPS = 0.01
first = next(n for n in range(1, 101) if dist(n) < EPS)
pell, (pp, qq) = [], (1, 1)
while qq <= 100:
    pell.append((qq, 1 / (pp + qq * math.sqrt(2))))     # p^2 - 2 q^2 = +-1
    pp, qq = pp + 2 * qq, pp + qq
print(f"first step back within {EPS} of 0: {first}; {first} x alpha = {first * alpha:.6f}, distance {dist(first):.6f}")
print(f"Pell road: 99^2 - 2 x 70^2 = {99 ** 2 - 2 * 70 ** 2}; distance 1/(99 + 70 sqrt 2) = {1 / (99 + 70 * math.sqrt(2)):.6f}")
print(f"pigeonhole: 101 arcs of width {EPS} around steps 0..100 total {101 * EPS:.2f} > 1, so a return by step 100")

pre_half = grid_share(lambda j, m: j // 2, 0, 0.5)   # grid road: the starts that x -> x/2 sends into [0, 0.5)
back = sum(1 for j in range(500, 1000) if any(Fr(1, 2) <= Fr(j, 1000) / 2 ** n for n in range(1, 21)))
line_back = sum(1 for n in range(1, 1001) if 0 <= 0.5 + n < 1)   # start 0.5, step +1
print(f"mistake 1, forward image: [0, 0.5) lands on a set of length {image_len:.6f}, so 'T doubles length'")
print(f"mistake 2, x -> x/2: preimage of [0, 0.5), by the 2^20 grid, has length {pre_half:.6f} not 0.5; "
      f"of 500 grid starts in [0.5, 1), back within 20 steps: {back}")
print(f"mistake 3, x -> x + 1 on the whole line keeps length; 0.5 back in A = [0, 1) within 1000 steps: {line_back} times")
fx = [round(60 + 280 * v) for v in (0.1, 0.25, 0.6, 0.75)]     # drawing units, origin (60, 360)
fy = [round(360 - 280 * v) for v in (0.2, 0.5)]
print(f"figure, 1 = 280 units, x at 0.1 0.25 0.6 0.75: {' '.join(map(str, fx))}; y at 0.2 0.5: {' '.join(map(str, fy))}")

assert exact_ok and total == b - a and shift_ok                      # formula, exactly
assert abs(g_double - 0.3) < 1e-5 and abs(g_rot - 0.3) < 1e-5        # grid road agrees
assert abs((1 - lo + hi) - 0.3) < 1e-12 and abs(mean_ret - 2) < 0.01
assert all(abs(s - 2.0 ** -n) < 1e-12 for n, s in enumerate(shares, 1))
assert visits == [0, 2, 4, 6, 8] and never
assert first == 70 and [n for n, _ in records] == [q for q, _ in pell]
assert all(abs(d - e) < 1e-9 for (_, d), (_, e) in zip(records, pell))
assert image_len == 1 and pre_half == 1     # both lengths by the grid: the image doubles, x/2 is not kept
print("ALL CHECKS PASS")
