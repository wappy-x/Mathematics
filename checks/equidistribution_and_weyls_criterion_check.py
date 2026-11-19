# Equidistribution and Weyl's criterion -- the check behind the card.  Standard library only.
# {x} = x - floor(x) is the fractional part; e(x) = cos 2 pi x + i sin 2 pi x.
# Roads: exact bin counts by integer square roots against floating-point {n root2};
# Weyl sums added term by term against the geometric-series closed form and its bound;
# leading digits read off the integers against the fractional parts of logs.
from math import isqrt, sqrt, pi, sin, cos, log, log10, floor
from bisect import bisect_left, bisect_right

R2 = sqrt(2.0)
def frac(x): return x - floor(x)
def dist(x): return min(frac(x), 1 - frac(x))          # ||x||, distance to the nearest integer
def digits(n, k):                                      # floor(10^k {n root2}), exact
    return isqrt(2 * n * n * 10 ** (2 * k)) - 10 ** k * isqrt(2 * n * n)
def weyl(xs, h):                                       # |(1/N) sum of e(h x_n)|, term by term
    re = im = 0.0
    for x in xs:
        t = 2 * pi * frac(h * x)
        re += cos(t); im += sin(t)
    return sqrt(re * re + im * im) / len(xs)
def closed(N, h, a):                                   # |sin(pi N h a)| / (N |sin(pi h a)|)
    return abs(sin(pi * frac(N * h * a))) / (N * abs(sin(pi * frac(h * a))))
def bars(name, counts):
    for b, c in enumerate(counts):
        print(f"{name} [0.{b}, {'1.0' if b == 9 else '0.' + str(b + 1)})  {'#' * (c // 4):<28} {c}")

print("n, n root2, {n root2}:", "; ".join(f"{n}, {n * R2:.6f}, {frac(n * R2):.6f}" for n in range(1, 6)))
print("road 1 = exact integer count, road 2 = floating point; points in [0, 0.1):")
for N in (10, 100, 1000, 10000, 100000):
    c1 = sum(1 for n in range(1, N + 1) if digits(n, 1) == 0)
    c2 = sum(1 for n in range(1, N + 1) if frac(n * R2) < 0.1)
    assert c1 == c2
    print(f"  N = {N:>6}: count {c1:>5}, fair share {N // 10:>5}, difference {c1 - N // 10:>2}, ratio {c1 / (N / 10):.4f}")

N = 1000
b2, b7 = [0] * 10, [0] * 10
for n in range(1, N + 1):
    b2[digits(n, 1)] += 1
    b7[10 * (99 * n % 70) // 70] += 1                    # 99/70: {99n/70} = (99n mod 70)/70
assert max(abs(c - 100) for c in b2) < 10
bars("root2", b2)
print("99/70 bins, N = 1000:", b7)
gap2 = sum(1 for n in range(1, N + 1) if 1 <= digits(n, 3) <= 13)
gap7 = sum(1 for n in range(1, N + 1) if 70 <= 1000 * (99 * n % 70) < 980)
assert gap7 == 0 and abs(gap2 - 13) <= 6
print(f"points in [0.001, 0.014) for N = 1000: root2 {gap2}, 99/70 {gap7}, fair share 13")

def star(xs):                                          # worst miscount over all [0, t)
    xs = sorted(xs); M = len(xs)
    return max(max(i + 1 - M * x, M * x - i) for i, x in enumerate(xs))
for M in (10, 100, 1000, 10000):
    d = star([frac(n * R2) for n in range(1, M + 1)])
    u = [digits(n, 12) for n in range(1, M + 1)]; su = sorted(u)   # exact floor(10^12 {n root2})
    d2 = max(max(bisect_right(su, v) - M * v / 10**12, M * v / 10**12 - bisect_left(su, v)) for v in u)
    assert abs(d - d2) < 1e-6                          # road 2: exact points, ranks by bisection
    print(f"  worst miscount over all [0, t), N = {M:>5}: {d:.4f} points, share of N {d / M:.6f}")

print("Weyl averages for root2: term by term | closed form | bound 1/(2 N ||h root2||)")
for h in (1, 2, 70):
    print(f"  h = {h:>2}, ||h root2|| = {dist(h * R2):.6f}")
    for M in (100, 1000, 10000):
        w = weyl([n * R2 for n in range(1, M + 1)], h)
        c, bd = closed(M, h, R2), 1 / (2 * M * dist(h * R2))
        assert abs(w - c) < 1e-9 and w <= bd
        print(f"    N = {M:>5}: {w:.6f} | {c:.6f} | {bd:.6f}")
re = im = big = 0.0
for n in range(1, 10001):
    t = 2 * pi * frac(n * R2); re += cos(t); im += sin(t)
    if sqrt(re * re + im * im) > big: big, at = sqrt(re * re + im * im), n
assert big <= 1 / (2 * dist(R2))
print(f"largest |S_N(1)| for N up to 10000: {big:.6f} at N = {at}; bound for every N {1 / (2 * dist(R2)):.6f}")
print(f"by hand: sin(pi ||root2||) = {sin(pi * dist(R2)):.6f}, 1/that = {1 / sin(pi * dist(R2)):.6f}")
pell = [h for h in range(1, 1001) if abs(2 * h * h - round(h * R2) ** 2) == 1]
assert all(abs(2 * h * h - round(h * R2) ** 2) >= 1 for h in range(1, 1001))
worst = min(dist(h * R2) * (2 * R2 * h + 1) for h in range(1, 1001))
assert worst > 1
print(f"|2h^2 - m^2| >= 1 for h up to 1000; it equals 1 at h = {pell}; min ||h root2||(2 root2 h + 1) = {worst:.6f}")

rat = [99 * n % 70 / 70 for n in range(1, N + 1)]
w70, top = weyl(rat, 70), max(weyl(rat, h) for h in range(1, 70))
assert abs(w70 - 1) < 1e-9 and top < 0.02
print(f"99/70 = {99 / 70:.6f}, root2 = {R2:.6f}, gap {99 / 70 - R2:.6f}")
print(f"99/70, N = 1000: Weyl average at h = 70 is {w70:.6f}; largest over h = 1..69 is {top:.6f}")
print("chart, h = 70, N = 20..400 step 20 (bound = smaller of 1 and 1/(2 N ||70 root2||)):")
print("  root2 ", ", ".join(f"{closed(M, 70, R2):.3f}" for M in range(20, 401, 20)))
print("  99/70 ", ", ".join(f"{weyl(rat[:M], 70):.3f}" for M in range(20, 401, 20)))
print("  bound ", ", ".join(f"{min(1, 1 / (2 * M * dist(70 * R2))):.3f}" for M in range(20, 401, 20)))

L2, lim = log10(2), 1 / sqrt(1 + (2 * pi / log(10)) ** 2)
for M in (999, 1999):
    ex = sum(1 for n in range(1, M + 1) if str(n)[0] == "1")
    fl = sum(1 for n in range(1, M + 1) if frac(log10(n)) < L2)
    assert ex == fl
    print(f"log10 n, N = {M:>5}: leading digit 1 share {ex / M:.6f} (equidistributed would give {L2:.6f})")
for M in (1000, 10000, 100000):
    w = weyl([log10(n) for n in range(1, M + 1)], 1)
    assert abs(w - lim) < 0.005
    print(f"log10 n, N = {M:>6}: Weyl average at h = 1 is {w:.6f}; limit 1/sqrt(1 + (2 pi/ln 10)^2) = {lim:.6f}")

ex = [str(2 ** n)[0] for n in range(1, N + 1)]                 # exact powers of 2
f1 = sum(1 for n in range(1, N + 1) if frac(n * L2) < L2)       # leading 1: {n log10 2} < log10 2
f9 = sum(1 for n in range(1, N + 1) if frac(n * L2) >= log10(9))
assert ex.count("1") == f1 and ex.count("9") == f9 and abs(f1 - N * L2) < 3
print(f"2^n, n = 1..1000, leading digit 1: {f1}, predicted {N * L2:.2f}; leading 9: {f9}, predicted {N * log10(10 / 9):.2f}")
print("ALL CHECKS PASS")
