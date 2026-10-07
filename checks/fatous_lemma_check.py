# Fatou's lemma -- the check behind the card.  Standard library only.
# A spotlight on a 1 m stage: frame n lights the strip [1 - 1/n, 1) at
# brightness n watts per metre, so every frame carries 1 W, yet every seat
# goes dark for good.  Road one counts lit grid cells in whole numbers; road
# two is the formula.  Then the running infimum under house lights that fade
# up, by a closed-form series and by brute force over frames; the smallest
# roof, whose area is a harmonic sum; the flicker under a roof of 2; and the
# shadow that breaks the sign rule.
import math

M = 10_000                                   # grid cells, 0.1 mm each

def lit(n, p, q):                            # is the seat at p/q m lit in frame n?  p/q >= 1 - 1/n
    return p * n >= q * (n - 1)

def light(n, cells, sign=1):                 # watts on the first `cells` grid cells in frame n
    hit = sum(1 for i in range(cells) if lit(n, 2 * i + 1, 2 * M))
    return sign * n * hit / M

def house(n):                                # house lights fading up, W/m, the same at every seat
    return 0.5 * (1 - 1 / n)

print("frame n lights [1 - 1/n, 1) at brightness n W/m")
for n in (1, 2, 4, 10, 100, 1000):
    total, part = light(n, M), light(n, 9 * M // 10)
    print(f"frame {n:>4}: strip from {1 - 1 / n:.4f} m, total {total:.4f} W, on [0, 0.9] m {part:.4f} W")
    assert abs(total - 1) < 1e-12                           # grid count against n x (1/n)
    assert abs(part - max(0.0, 1 - 0.1 * n)) < 1e-12        # grid count against the overlap formula

for p, q in ((1, 2), (9, 10), (99, 100), (999, 1000)):
    last = max(n for n in range(1, 100_001) if lit(n, p, q))   # brute force over 100000 frames
    print(f"seat {p / q:.4f} m: lit in frames 1 to {last}, brightness climbs to {last} W/m, then dark from frame {last + 1} on")
    assert last == q // (q - p)                              # against n <= 1/(1 - x)
    assert all(lit(n, p, q) for n in range(1, last + 1))       # lit in every frame up to the last
dark = light(2 * M + 1, M)                   # every grid seat (at most 0.99995 m) is dark for good from frame 2M + 1 on
print(f"spotlight: integral of lim inf = {dark:.4f} W, lim inf of the integrals = {light(1000, M):.4f} W, lost {light(1000, M) - dark:.4f} W")

# the proof on the stage: f_n = house(n) + spotlight; g_k = inf over n >= k of f_n
def by_series(k):                            # g_k = house(k) left of 1 - 1/k, house(j + 1) on strip j >= k
    tail = math.pi ** 2 / 6 - sum(1 / m ** 2 for m in range(1, k + 1))
    return 0.5 * (1 - 1 / k) ** 2 + 0.5 * tail

J = 1000                                     # strips [1 - 1/j, 1 - 1/(j + 1)), j = 1..J, then a leftover sliver
def by_brute(k):
    s = 0.0
    for j in range(1, J + 1):
        frames = range(k, max(j, k) + 6)     # every frame from k up to a few past the strip's last lit one
        low = min(house(n) + (n if lit(n, j - 1, j) else 0) for n in frames)
        s += low / (j * (j + 1))
    return s + house(k) / (J + 1), s + 0.5 / (J + 1)

print("k, integral of g_k by series, by brute force (bracket), inf of integrals from frame k on")
prev, rows = 0.0, []
for k in range(1, 9):
    a, (lo, hi) = by_series(k), by_brute(k)
    rhs = min(house(n) + 1.0 for n in range(k, k + 4))   # integral of f_n is house(n) + 1 W
    print(f"k = {k}: {a:.4f}, {lo:.4f} to {hi:.4f}, {rhs:.4f}")
    assert lo - 1e-12 <= a <= hi + 1e-12      # two roads to the integral of g_k
    assert prev <= a <= rhs                   # g_k rises, and sits below every later integral
    prev = a
    rows.append(a)
for k in (100, 10_000):
    print(f"k = {k}: integral of g_k {by_series(k):.4f}")
tail3 = sum(1 / m ** 2 for m in range(4, 2_000_001))           # summed directly, not from pi^2/6
print(f"k = 3 by hand: floor {house(3):.4f} W/m on [0, {1 - 1 / 3:.4f}) m, area {house(3) * (1 - 1 / 3):.4f}; "
      f"sum of 1/m^2 from m = 4 is {tail3:.4f}, half of it {0.5 * tail3:.4f}")
assert abs(house(3) * (1 - 1 / 3) + 0.5 * tail3 - by_series(3)) < 1e-6
print(f"with house lights, read at k = 1000000: integral of lim inf = {by_series(10 ** 6):.4f} W, lim inf of the integrals = {1 + house(10 ** 6):.4f} W")
print("chart, integral of g_k to 2 places: " + ", ".join(f"{a:.2f}" for a in rows))
print("chart, inf of integrals to 2 places: " + ", ".join(f"{1 + house(k):.2f}" for k in range(1, 9)))

# the smallest roof over every frame: sup_n f_n = j on strip j
for Jr in (10, 100, 1000, 1_000_000):
    formula = sum(1 / (j + 1) for j in range(1, Jr + 1))
    if Jr <= 1000:
        brute = sum(max(n for n in range(1, j + 6) if lit(n, j - 1, j)) / (j * (j + 1)) for j in range(1, Jr + 1))
        assert abs(brute - formula) < 1e-9
    assert formula >= math.log((Jr + 2) / 2)
    print(f"roof over [0, {1 - 1 / (Jr + 1):.6f}) m: area {formula:.4f} W")

# flicker: odd frames 2 W/m on [0, 0.5), even frames 2 W/m on [0.5, 1); roof G = 2
odd = [2 if i < M // 2 else 0 for i in range(M)]
even = [2 - v for v in odd]
area = lambda row: sum(row) / M
low, high = [min(a, b) for a, b in zip(odd, even)], [max(a, b) for a, b in zip(odd, even)]
chain = (area(low), min(area(odd), area(even)), max(area(odd), area(even)), area(high))
print("flicker: " + " <= ".join(f"{v:.4f}" for v in chain) + f", roof area {area([2] * M):.4f}")
assert chain == (0.0, 1.0, 1.0, 2.0)

# what breaks
print(f"breaks, reverse Fatou with no roof: lim sup of integrals {light(1000, M):.4f} > integral of lim sup {dark:.4f}")
shadow = light(1000, M, -1)
print(f"breaks, shadow of depth n: integral of lim inf {dark:.4f} > lim inf of integrals {shadow:.4f}")
assert dark > shadow
print(f"breaks, equality claimed: {light(1000, M):.4f} W predicted for the limit, {dark:.4f} W there")
print("figure, x = 40 + 280 x, y = 200 - 40 brightness; " + "; ".join(
      f"frame {n}: {40 + 280 * (1 - 1 / n):.1f} to {40 + 280 * 1.0:.1f}, top {200 - 40 * n:.1f}" for n in (1, 2, 4)))
print("ALL CHECKS PASS")
