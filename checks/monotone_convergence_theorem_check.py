# The monotone convergence theorem -- the check behind the card.  Standard
# library only; fractions keeps the step-function sums exact.
# River: depth d(x) = 4x(1 - x) metres over a 1 km stretch; integral 2/3.
# Road 1: the staircase through its level sets, lambda(d >= t) = sqrt(1 - t).
# Road 2: the same staircase sampled at M grid midpoints; it never sees a level set.
# Road 3: a different rising sequence, the lowest depth on each of 2^n equal
#         cells, summed exactly and set against the algebra 2/3 - h - 2h^2/3.
# Series on [0, 1/2]: the integrals of x^k added term by term, against ln 2 found
# by Simpson's rule and by the series 2 atanh(1/3).  The code checks finite
# stages; that every rising sequence reaches the limit's integral is the proof's.
from fractions import Fraction as Q
from math import floor, ceil, sqrt

M = 2 ** 16                                            # grid cells for road 2

def d(x): return 4 * x * (1 - x)                      # river depth, metres, x in km
def stair(v, n): return min(n, floor(v * 2 ** n) / 2 ** n)   # round down to marks 2^-n apart, cap n
def grid(fun): return sum(fun((i + 0.5) / M) for i in range(M)) / M

print(f"river, grid of {M} midpoints; n: staircase by levels | staircase on grid | lowest-per-cell exact | 2/3 - h - 2h^2/3 | stair short | cells short")
stairs, cells = [], []
for n in range(1, 11):
    N, h = 2 ** n, Q(1, 2 ** n)
    by_levels = sum(sqrt(1 - k / N) for k in range(1, N + 1)) / N      # sum of 2^-n lambda(d >= k 2^-n)
    on_grid = grid(lambda x: stair(d(x), n))
    low = sum(h * min(Q(4 * j * (N - j), N * N), Q(4 * (j + 1) * (N - j - 1), N * N)) for j in range(N))
    closed = Q(2, 3) - h - 2 * h * h / 3
    assert abs(by_levels - on_grid) <= 2 / M          # one staircase, two roads
    assert low == closed                              # exact sum against the algebra
    assert 0 < 2 / 3 - by_levels <= float(h)          # staircase within 2^-n of d at every point
    assert not stairs or (by_levels > stairs[-1] and low > cells[-1])   # both sequences rise
    stairs.append(by_levels)
    cells.append(low)
    if n == 2:
        print("river, n=2 level-set lengths, lambda(d >= 1/4, 1/2, 3/4, 1):",
              " ".join(f"{sqrt(1 - k / 4):.10f}" for k in range(1, 5)))
    print(f"river, n={n}: {by_levels:.10f} | {on_grid:.10f} | {low:.10f} | {closed:.10f} | "
          f"{2 / 3 - by_levels:.10f} | {Q(2, 3) - low:.10f}")

print(f"river, both limits: 2/3 = {2 / 3:.10f}, from the antiderivative 2x^2 - 4x^3/3 at x = 1")

s_top, c, a, b = 0.95, 0.99, 0.4, 0.6                 # test function s: 0.95 m on [0.4, 0.6] km
assert d(a) >= s_top and d(b) >= s_top                # s sits under d: d >= 0.96 there
print(f"test sets E_n = {{staircase >= c s}}, c = {c}, s = {s_top} on [0.4, 0.6] where d >= {d(a):.2f}, c s = {c * s_top:.4f}")
print("test set, n: lowest mark >= c s | length by formula | on grid | c x integral of s on E_n | staircase integral")
for n in range(1, 7):
    t = ceil(c * s_top * 2 ** n) / 2 ** n              # lowest mark at or above c s = 0.9405
    inside = min(b - a, sqrt(1 - t)) if t <= 1 else 0.0   # {d >= t} is |x - 1/2| <= sqrt(1 - t)/2
    length = 1 - (b - a) + inside
    on_grid = grid(lambda x: 1.0 if stair(d(x), n) >= (c * s_top if a <= x <= b else 0) else 0.0)
    assert abs(length - on_grid) <= 4 / M
    assert c * s_top * inside <= stairs[n - 1]         # integral of f_n >= c times integral of s on E_n
    print(f"test set, n={n}: {t:g} | {length:.10f} | {on_grid:.10f} | {c * s_top * inside:.10f} | {stairs[n - 1]:.10f}")
print(f"test sets, limit: length 1; c x integral of s = {c * s_top * (b - a):.10f}")

zero_part = 1 - sqrt(0.75)                             # where staircase_2 = 0: d < 1/4
lens = []
for n in (2, 10, 100):
    lens.append(grid(lambda x: 1.0 if (1 - 1 / n) * stair(d(x), 2) >= stair(d(x), 2) else 0.0))
    assert abs(lens[-1] - zero_part) <= 4 / M
print(f"c = 1 fails: f_n = (1 - 1/n) staircase_2, length of {{f_n >= staircase_2}}, n = 2, 10, 100: "
      f"{lens[0]:.4f} {lens[1]:.4f} {lens[2]:.4f}; formula 1 - sqrt(3/4) = {zero_part:.4f}")

print("additivity, d + r with r(x) = x/2, exact 2/3 + 1/4 = 11/12: n | staircase of d + r | stair d + stair r")
for n in (2, 4, 6, 8, 10):
    N = 2 ** n
    joint = grid(lambda x: stair(d(x) + x / 2, n))
    apart = stairs[n - 1] + sum(1 - 2 * k / N for k in range(1, N // 2 + 1)) / N   # lambda(r >= t) = 1 - 2t
    assert 0 < 11 / 12 - joint <= 1 / N + 3 / M
    assert 0 < 11 / 12 - apart <= 2 / N
    print(f"additivity, n={n}: {joint:.10f} | {apart:.10f}")
print(f"additivity, 11/12 = {11 / 12:.10f}")

def simpson(fun, lo, hi, m=1000):                      # own integrator, m even
    w = (hi - lo) / m
    return w / 3 * sum(fun(lo + i * w) * (1 if i in (0, m) else (4 if i % 2 else 2)) for i in range(m + 1))

ln2_simpson = simpson(lambda x: 1 / (1 - x), 0.0, 0.5)
ln2_atanh = 2 * sum(Q(1, (2 * j + 1) * 3 ** (2 * j + 1)) for j in range(30))   # ln 2 = 2 atanh(1/3)
assert abs(ln2_simpson - float(ln2_atanh)) < 1e-12
print(f"series, ln 2 by Simpson on 1/(1 - x): {ln2_simpson:.12f}; by 2 atanh(1/3): {float(ln2_atanh):.12f}")
print("series on [0, 1/2], term k integrates to 1/(m 2^m) with m = k + 1: N | sum of first N | ln 2 minus it | bound 1/((N+1) 2^N)")
P = Q(0)
for m in range(1, 31):
    P += Q(1, m * 2 ** m)
    if m in (1, 2, 3, 4, 5, 10, 20, 30):
        gap, bound = float(ln2_atanh - P), 1 / ((m + 1) * 2 ** m)
        assert 0 < gap <= bound                       # the tail of the term-by-term sum
        e3 = lambda v: f"{v:.3e}".replace("e-0", "e-")   # Rust's exponent style
        print(f"series, N={m}: {float(P):.12f} | {e3(gap)} | {e3(bound)}")
five = simpson(lambda x: 1 + x + x * x + x * x * x + x * x * x * x, 0.0, 0.5)
assert abs(five - float(sum(Q(1, m * 2 ** m) for m in range(1, 6)))) < 1e-14
print(f"series, integral of 1 + x + ... + x^4 by Simpson: {five:.12f}; terms",
      " + ".join(str(Q(1, m * 2 ** m)) for m in range(1, 6)), "=", sum(Q(1, m * 2 ** m) for m in range(1, 6)))
H, hs = 0.0, []
for k in range(1, 10001):
    H += 1 / k                                         # integral of x^(k-1) over [0, 1] is 1/k
    if k in (10, 100, 1000, 10000):
        hs.append(H)
assert hs[3] > 9 and hs[3] - hs[2] > 2.3               # still climbing by about ln 10 per decade
print("series on [0, 1): sums of 1/k, N = 10, 100, 1000, 10000: " + " ".join(f"{v:.6f}" for v in hs))

spikes = [grid(lambda x: n if x < 1 / n else 0) for n in (1, 2, 4, 8, 16)]
assert spikes == [1.0] * 5                             # grid count against n x (1/n) = 1
at = [n if 0.3 < 1 / n else 0 for n in (1, 2, 3, 4, 5)]
print(f"spike n on (0, 1/n), n = 1, 2, 4, 8, 16: integrals {' '.join(f'{v:.4f}' for v in spikes)}; "
      f"value at x = 0.3 for n = 1 to 5: {' '.join(str(v) for v in at)}; limit function 0, integral 0")
nw = [(n, w) for n in (1, 10, 100) for w in (1000, 1000000)]
W = [sum(1 for i in range(4 * w) if (i + 0.5) / 4 >= n) / 4 for n, w in nw]   # quarter-unit midpoints
assert W == [w - n for n, w in nw]                     # grid against w - n
print(f"tails, length of [n, infinity) inside [0, w], n = 1, 10, 100, w = 1000 and 10^6: {' '.join(f'{v:g}' for v in W)}")

px = lambda x: 30 + 300 * x                            # figure: 300 px per km, 160 px per metre
edges = [0.5 - sqrt(1 - k / 4) / 2 for k in (1, 2, 3)]
print("figure, staircase_2 step edges x px:", " ".join(f"{px(e):.2f}" for e in edges),
      "|", " ".join(f"{px(1 - e):.2f}" for e in reversed(edges)), "| levels y px 80 120 160 | surface y 40")
print("figure, bed:", " ".join(f"{px(i / 20):.0f},{40 + 160 * d(i / 20):.1f}" for i in range(21)))
print("chart, staircase integrals n=1..8:", " ".join(f"{v:.2f}" for v in stairs[:8]))
print("chart, lowest-per-cell integrals n=1..8:", " ".join(f"{float(v):.2f}" for v in cells[:8]))
print("ALL CHECKS PASS")
