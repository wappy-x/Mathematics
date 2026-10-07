# The Riemann integral -- the check behind the card.  Nothing is imported.
# A tank fills at f(t) = 3 + 2t litres per minute from t = 0 to t = 10 minutes.
# Road one: lower and upper sums, slice by slice.  Road two: the closed form
# 130 -/+ 100/n, from 0 + 1 + ... + (n - 1) = n(n - 1)/2.  Road three: geometry,
# a 3-by-10 rectangle under a triangle of base 10 and height 20.
def rate(t):
    return 3 + 2 * t

def valve(t):                             # second case: the valve opens wider at t = 4
    return 3 if t < 4 else 8

def sums(f, cuts):                        # a monotone rate is lowest and highest at slice ends
    lo = hi = 0.0
    for s, u in zip(cuts, cuts[1:]):
        lo += min(f(s), f(u)) * (u - s)
        hi += max(f(s), f(u)) * (u - s)
    return lo, hi

def even(n, a=0, b=10):
    return [a + (b - a) * k / n for k in range(n + 1)]

def gap(f, n):
    lo, hi = sums(f, even(n))
    return hi - lo

def row(xs, d):
    return ", ".join(f"{x:.{d}f}" for x in xs)

geometry = 3 * 10 + 10 * 20 / 2
print(f"tank: rate 3 + 2t litres per minute, {rate(0):.0f} at t = 0, {rate(10):.0f} at t = 10; "
      f"geometry 3 x 10 + 10 x 20 / 2 = {geometry:.1f}")
for n in (5, 10, 100, 1000):
    lo, hi = sums(rate, even(n))
    print(f"n = {n}, width {10 / n:g}: lower {lo:.1f}, upper {hi:.1f}, gap {hi - lo:.1f}")
    assert abs(lo - (130 - 100 / n)) < 1e-9 and abs(hi - (130 + 100 / n)) < 1e-9  # road 1 = road 2
    assert lo <= geometry <= hi and abs((hi - lo) * n - 200) < 1e-6         # road 3 trapped, gap 200/n
print(f"n = 5, rate at each cut: {row([rate(t) for t in even(5)], 0)}")
ns = [1, 2, 4, 5, 10, 20, 50, 100]
print(f"chart n: {row(ns, 0)}; lower: {row([sums(rate, even(n))[0] for n in ns], 0)}")
print(f"chart upper: {row([sums(rate, even(n))[1] for n in ns], 0)}")
c, r = sums(rate, [0, 5, 10]), sums(rate, [0, 2, 5, 10])
print(f"refine: cuts 0, 5, 10 give lower {c[0]:.1f}, upper {c[1]:.1f}; a cut at 2 gives {r[0]:.1f}, {r[1]:.1f}")
assert c[0] <= r[0] <= geometry <= r[1] <= c[1]                        # extra cut tightens
n1 = next(n for n in range(1, 10**4) if gap(rate, n) <= 1 + 1e-9)   # road one, searched
n2 = next(n for n in range(19900, 20100) if gap(rate, n) <= 0.01 + 1e-9)
print(f"gap at most 1 litre first at n = {n1}, width {10 / n1:g}; at most 0.01 litres needs n = {n2}")
for n in (7, 100):
    lo, hi = sums(valve, even(n))
    print(f"valve, exact 3 x 4 + 8 x 6 = 60, n = {n}: lower {lo:.3f}, upper {hi:.3f}, gap {hi - lo:.3f}")
    assert lo - 1e-9 <= 3 * 4 + 8 * 6 <= hi and abs((hi - lo) * n - 50) < 1e-6  # gap (8 - 3) x 10 / n
xs = [40 + 28 * t for t in even(5)]
print(f"figure, 28 px per minute, 8 px per litre/min; slice edges x = {row(xs, 0)}")
print(f"figure, lower tops y = {row([215 - 8 * rate(t) for t in even(5)[:-1]], 0)}; "
      f"upper tops y = {row([215 - 8 * rate(t) for t in even(5)[1:]], 0)}")
print(f"mistake 1, lower sum at n = 10 taken as the total: {sums(rate, even(10))[0]:.1f}")
print(f"mistake 2, 20 slice rates added without widths: {sum(rate(t) for t in even(20)[1:]):.1f}")
inside = all(k / n < k / n + 2 ** 0.5 / (4 * n) < (k + 1) / n for n in (4, 100, 10000) for k in range(n))
print(f"mistake 3, fraction rule on [0, 1]: a sqrt(2) tag inside every slice: {'yes' if inside else 'no'}; "
      f"lower 0, upper 1 at n = 4, 100, 10000")
print("ALL CHECKS PASS")
