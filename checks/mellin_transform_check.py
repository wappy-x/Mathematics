# The Mellin transform -- the check behind the card.  Standard library only.
# Road one: the integral of t^(s-1) f(t) over t, by midpoints.
# Road two: the same number as a two-sided Laplace transform, after t = e^(-x).
# Road three: (s-1)! times the Zipf sum of 1/k^s, with no integral at all.
import math

def mid(g, lo, hi, n):                       # midpoint sum of g from lo to hi, n steps
    h = (hi - lo) / n
    return h * sum(g(lo + (j + 0.5) * h) for j in range(n))
def trap(g, lo, hi, n):                      # trapezoid sum of g from lo to hi, n steps
    h = (hi - lo) / n
    return h * (sum(g(lo + j * h) for j in range(1, n)) + (g(lo) + g(hi)) / 2)
def mellin_t(f, s, top=60.0):                # road one: t from 0 to 60
    return mid(lambda t: t ** (s - 1) * f(t), 0.0, top, 200000)
def mellin_x(f, s, hi=45.0):                 # road two: e^(-sx) f(e^(-x)), x from -5 to 45
    return trap(lambda x: math.exp(-s * x) * f(math.exp(-x)), -5.0, hi, 2000)
def zipf(s, n):                              # 1/k^s for k = 1..n, plus the area beyond n + 1/2
    return sum(k ** -s for k in range(1, n + 1)) + (n + 0.5) ** (1 - s) / (s - 1)
decay = lambda t: math.exp(-t)
bose = lambda t: 1 / math.expm1(t)           # 1/(e^t - 1) = e^(-t) + e^(-2t) + e^(-3t) + ...

for s, ref, name in ((2, 1.0, "1!"), (4, 6.0, "3!"), (2.5, 0.75 * math.sqrt(math.pi), "(3/4) sqrt(pi)")):
    a, b = mellin_t(decay, s), mellin_x(decay, s)
    print(f"gamma as the transform of e^(-t), s = {s}: t-side {a:.6f}, x-side {b:.6f}, {name} = {ref:.6f}")
    assert abs(a - ref) < 1e-7 and abs(b - ref) < 1e-9
st = mellin_t(lambda t: math.exp(-2 * t), 2)
print(f"stretch by k = 2: transform of e^(-2t) at s = 2 is {st:.6f}; Gamma(2)/2^2 = {1 / 4:.6f}")
print("zipf, largest 8000000: " + ", ".join(f"rank {k} {round(8e6 / k)}" for k in (2, 3, 4)))
h1, h2 = sum(1 / k for k in range(1, 1001)), sum(1 / k for k in range(1, 1000001))
print(f"zipf total, exponent 1: {h1:.6f} at 1000 cities, {h2:.6f} at 1000000 cities")
four = sum(1 / k ** 2 for k in range(1, 5))
print(f"zipf total, exponent 2, by hand: 1 + 1/4 + 1/9 + 1/16 = {four:.6f}, tail 1/4.5 = {1 / 4.5:.6f}, sum {zipf(2, 4):.6f}")
for s, closed, cname in ((2, math.pi ** 2 / 6, "pi^2/6"), (4, math.pi ** 4 / 15, "pi^4/15")):
    a, b = mellin_t(bose, s), mellin_x(bose, s)
    g, z = math.factorial(s - 1), zipf(s, 1000)
    print(f"s = {s}: integral of t^(s-1)/(e^t - 1): t-side {a:.6f}, x-side {b:.6f}")
    print(f"s = {s}: Gamma({s}) = {g:.6f} times zeta({s}) = {z:.6f} gives {g * z:.6f}; {cname} = {closed:.6f}")
    assert abs(a - b) < 1e-7                               # the substitution t = e^(-x)
    assert abs(b - g * z) < 1e-9 and abs(b - closed) < 1e-9  # the geometric series, term by term
cut = [(n, mellin_x(bose, 1, math.log(1 / e)), -math.log(-math.expm1(-e))) for n, e in (("0.001", 1e-3), ("0.000001", 1e-6))]
print("s = 1: integral from eps up, " + "; ".join(f"eps = {e}: {v:.6f} (closed {c:.6f})" for e, v, c in cut))
assert abs(st - 0.25) < 1e-7 and all(abs(v - c) < 1e-6 for _, v, c in cut) and cut[1][1] > cut[0][1] + 6
print(f"mistake, t^s for t^(s-1) at s = 2: {mellin_t(bose, 3):.6f}, which is Gamma(3) zeta(3) = {2 * zipf(3, 1000):.6f}")
print(f"mistake, k = 0 kept in the series: integral to 60 = {mellin_t(lambda t: 1 + bose(t), 2):.6f}, "
      f"to 120 = {mellin_t(lambda t: 1 + bose(t), 2, 120.0):.6f}")
px = lambda s: 140 + 40 * s                  # figure: s = 0 at (140, 120), 40 units per 1
print(f"figure, s = 0 at ({px(0):.2f}, 120.00), 40 units per 1, pole s = 1 at ({px(1):.2f}, 120.00), line c = 2 at x = {px(2):.2f}, s = 4 at ({px(4):.2f}, 120.00)")
print("ALL CHECKS PASS")
