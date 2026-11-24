# Von Neumann's mean ergodic theorem -- the check behind the card.  Standard
# library only.  Three maps of [0, 1) that keep length, one function on each,
# and the time averages A_n f = (f + Uf + ... + U^(n-1) f) / n, with U f = f o T.
# Each limit is reached by roads that share no arithmetic.
from math import cos, sin, pi, sqrt, comb

def inner(u, v):                  # integral of u v over [0, 1), for functions
    return sum(a * b for a, b in zip(u, v)) / len(u)   # stored as equal cells

def norm(v):                      # the L2 length: square root of the integral of v^2
    return sqrt(inner(v, v))

def average(v, n, U):             # road one: apply U again and again, add, divide
    total, w = [0.0] * len(v), v
    for _ in range(n):
        total = [t + a for t, a in zip(total, w)]
        w = U(w)
    return [t / n for t in total]

# ---- 1. rotation by 1/2, f = indicator of [0, 1/4): exact on the four quarters ----
def U_half(v):                    # (f o T)(x) = f(x + 1/2): quarter q reads quarter q + 2
    return [v[(q + 2) % 4] for q in range(4)]
f = [1.0, 0.0, 0.0, 0.0]
cond = [(f[q] + f[(q + 2) % 4]) / 2 for q in range(4)]   # road two: average over {x, x + 1/2}
e1, e2 = [1, 0, 1, 0], [0, 1, 0, 1]                      # road three: drop f onto the invariant
proj = [inner(f, e1) / inner(e1, e1) * a + inner(f, e2) / inner(e2, e2) * b for a, b in zip(e1, e2)]
print("rotation by 1/2, f = indicator of [0, 1/4), values on the quarters [0,1/4) [1/4,1/2) [1/2,3/4) [3/4,1)")
print(f"  f = {f}, Uf = {U_half(f)}")
print(f"  limit as conditional expectation (f + f o T)/2 = {cond}")
print(f"  limit as projection onto the invariant functions = {proj}")
print(f"  integral of f = {sum(f) / 4}; integral of the limit = {sum(cond) / 4}")
for n in [1, 2, 3, 10, 101, 1000]:
    a = average(f, n, U_half)
    err = norm([x - y for x, y in zip(a, cond)])
    print(f"  n = {n:4d}: A_n f = [{', '.join(f'{x:.4f}' for x in a)}], distance to limit {err:.4f}")
rest = [x - y for x, y in zip(f, cond)]
g = [x / 2 for x in f]
cob = [x - y for x, y in zip(g, U_half(g))]
print(f"  f - Pf = {rest} = g - Ug with g = f/2: {"yes" if rest == cob else "no"}; inner products with e1, e2: {inner(rest, e1)}, {inner(rest, e2)}")
assert cond == proj == [0.5, 0.0, 0.5, 0.0]                      # two roads, one projection
assert norm([x - y for x, y in zip(average(f, 1000, U_half), cond)]) < 1e-12
assert abs(norm([x - y for x, y in zip(average(f, 101, U_half), cond)]) - sqrt(0.5) / 202) < 1e-12
assert rest == cob and inner(rest, e1) == 0 == inner(rest, e2)

# ---- 2. rotation by alpha = sqrt 2 - 1, f = cos(2 pi x): sampled on 64 midpoints ----
# Squares of these functions are waves of frequency at most 2, which 64 equal samples
# integrate exactly, so the cell sums are exact integrals, not approximations.
M, alpha = 64, sqrt(2) - 1
xs = [(j + 0.5) / M for j in range(M)]
fc = [cos(2 * pi * x) for x in xs]
def U_alpha_of(func):             # U applied to a known formula: x -> func(x + alpha)
    return [func((x + alpha) % 1.0) for x in xs]
def A_alpha(n):                   # road one: sum cos(2 pi (x + k alpha)) directly
    return [sum(cos(2 * pi * ((x + k * alpha) % 1.0)) for k in range(n)) / n for x in xs]
def closed(n):                    # road two: geometric sum of e^(2 pi i k alpha)
    return abs(sin(pi * n * alpha)) / (sqrt(2) * n * sin(pi * alpha))
s = sin(pi * alpha)
c = 1 / (1 - complex(cos(2 * pi * alpha), sin(2 * pi * alpha)))  # g = Re(c e^(2 pi i x))
gfun = lambda x: (c * complex(cos(2 * pi * x), sin(2 * pi * x))).real
gc = [gfun(x) for x in xs]
cob2 = [a - b for a, b in zip(gc, U_alpha_of(gfun))]
print(f"rotation by alpha = {alpha:.6f}, f = cos(2 pi x); sin(pi alpha) = {s:.4f}")
print(f"  |f| = {norm(fc):.4f}, |Uf| = {norm(U_alpha_of(lambda x: cos(2 * pi * x))):.4f} (U keeps length)")
print(f"  f = g - Ug with |c| = {abs(c):.4f}, |g| = {norm(gc):.4f}: every gap below 1e-12: {
      "yes" if max(abs(a - b) for a, b in zip(fc, cob2)) < 1e-12 else "no"}")
print("  n, |A_n f| summed, |A_n f| closed form, proof bound 2|g|/n, sup bound 1/(n sin pi alpha)")
for n in [1, 10, 100, 1000]:
    a = A_alpha(n)
    print(f"  {n:4d}  {norm(a):.5f}  {closed(n):.5f}  {2 * norm(gc) / n:.5f}  {1 / (n * s):.5f}")
    assert abs(norm(a) - closed(n)) < 1e-9                     # two roads agree
    assert norm(a) <= 2 * norm(gc) / n + 1e-12 and max(map(abs, a)) <= 1 / (n * s) + 1e-12
assert max(abs(a - b) for a, b in zip(fc, cob2)) < 1e-12        # cos is a difference g - Ug
assert abs(abs(c) - 1 / (2 * s)) < 1e-12                        # |c| two ways: complex division, 1/(2 sin pi alpha)

# ---- 3. the house example: doubling map, f = first binary digit ----
def by_enumeration(n):            # road one: run T x = 2x mod 1 on each dyadic midpoint,
    size, tot = 2 ** (n + 1), 0.0 # in whole numbers: x = num / 2^(n+1)
    for j in range(2 ** n):
        num, ones = 2 * j + 1, 0
        for _ in range(n):
            ones += num >= size // 2
            num = 2 * num % size
        tot += (ones / n - 0.5) ** 2
    return sqrt(tot / 2 ** n)
def by_binomial(n):               # road two: digits are fair coins; sum over the count of 1s
    return sqrt(sum(comb(n, k) * (k / n - 0.5) ** 2 for k in range(n + 1)) / 2 ** n)
print("doubling map, f = first binary digit, limit 1/2 (the map is mixing, hence ergodic)")
print(f"  n = 10: distance by enumerating 1024 starts {by_enumeration(10):.4f}, "
      f"by binomial sum {by_binomial(10):.4f}, by 1/(2 sqrt n) {1 / (2 * sqrt(10)):.4f}")
assert abs(by_enumeration(10) - by_binomial(10)) < 1e-12 and abs(by_binomial(10) - 1 / (2 * sqrt(10))) < 1e-12

print("chart, n = 10..100: rotation |A_n f| then doubling distance")
ns = list(range(10, 101, 10))
print("  " + ", ".join(f"{closed(n):.4f}" for n in ns))
print("  " + ", ".join(f"{by_binomial(n):.4f}" for n in ns))
for n in ns:
    assert abs(by_binomial(n) - 1 / (2 * sqrt(n))) < 1e-12

print(f"mistake 1, space average 1/4 as the limit for rotation by 1/2: off by "
      f"{norm([x - 0.25 for x in average(f, 1000, U_half)]):.4f} at n = 1000")
print(f"mistake 2, sums without the 1/n: |S_100 f| = {100 * norm(average(f, 100, U_half)):.2f}, growing with n")
print(f"mistake 3, a 1/n rate for the doubling map: predicts {by_binomial(10) / 10:.4f} at n = 100, "
      f"truth {by_binomial(100):.4f}")
x, ones = 0.0, 0                  # the start 0 is a fixed point of the doubling map
for _ in range(1000):
    ones, x = ones + (x >= 0.5), 2 * x % 1.0
print(f"mistake 4, one start read as almost every start: x = 0 never moves, its average stays {ones / 1000:.4f}")
print("ALL CHECKS PASS")
