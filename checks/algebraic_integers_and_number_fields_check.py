# Algebraic integers in Q(sqrt d): a number a + b*sqrt(d) is stored as the pair (a, b) of fractions.
from fractions import Fraction as F
from itertools import product
from math import gcd

def mul(x, y, d):
    return (x[0] * y[0] + d * x[1] * y[1], x[0] * y[1] + x[1] * y[0])

def show(cs):
    """A polynomial, highest power first, written out: [1, -2, 6] -> x^2 - 2x + 6."""
    out, n = "", len(cs) - 1
    for i, c in enumerate(cs):
        c, e = F(c), n - i
        if c == 0:
            continue
        mono = "" if e == 0 else "x" if e == 1 else f"x^{e}"
        num = "" if e > 0 and abs(c) == 1 else f"({abs(c)})" if e > 0 and c.denominator > 1 else str(abs(c))
        out += ("-" if c < 0 else "") + num + mono if not out else (" - " if c < 0 else " + ") + num + mono
    return out

def root_of(coeffs, x, d):
    """Road 2's tool: evaluate a polynomial (highest power first) at x exactly, by Horner's rule."""
    acc = (F(0), F(0))
    for c in coeffs:
        acc = mul(acc, x, d)
        acc = (acc[0] + c, acc[1])
    return acc == (0, 0)

def minpoly(a, b, d):
    """Road 1: the monic minimal polynomial over Q, from (x - a)^2 = d b^2."""
    if b == 0:
        return [F(1), -a]
    return [F(1), -2 * a, a * a - d * b * b]

def road1(a, b, d):
    return all(c.denominator == 1 for c in minpoly(a, b, d))

def search(x, d, deg, h):
    """Road 2: every monic integer polynomial of degree 1..deg, coefficients -h..h, with x as a root."""
    found = []
    for n in range(1, deg + 1):
        for cs in product(range(-h, h + 1), repeat=n):
            if root_of([1, *cs], x, d):
                found.append([1, *cs])
    return found

D = -5
r5, half = (F(0), F(1)), (F(0), F(1, 2))
print("the field Q(sqrt -5): generator sqrt(-5), basis 1, sqrt(-5)")
for name, (a, b) in [("sqrt(-5)", r5), ("sqrt(-5)/2", half), ("1 + sqrt(-5)", (F(1), F(1)))]:
    m = minpoly(a, b, D)
    print(f"{name}: minimal polynomial {show(m)}, degree {len(m) - 1}, algebraic integer {road1(a, b, D)}")
assert road1(*r5, D) and not road1(*half, D)
p = (F(1), F(0))
pw = []
for k in range(5):
    pw.append(p)
    p = mul(p, r5, D)
print("powers of sqrt(-5) as (a, b):", ", ".join(f"({a}, {b})" for a, b in pw))
assert pw[2] == (-5, 0) and pw[3] == (0, -5), "sqrt(-5)^2 = -5 keeps every power in degree 2"

# Road 2: brute-force search, degree up to 4, coefficients -H..H
H = 6
f5, fh = search(r5, D, 4, H), search(half, D, 4, H)
print(f"monic integer polys, degree <= 4, coefficients -{H}..{H}: {len(f5)} have root sqrt(-5), {len(fh)} have root sqrt(-5)/2")
print("  the shortest one for sqrt(-5):", show(min(f5, key=len)))
small = range(-(H // 5), H // 5 + 1)   # 5*c0 and 5*c1 must stay within -H..H
predicted = len(small) ** 2 + len(small) + 1   # (x^2+5)(x^2+c1*x+c0), (x^2+5)(x+c0), x^2+5
print(f"  predicted from multiples of x^2 + 5: 1 + {len(small)} + {len(small) ** 2} = {predicted}")
assert len(f5) == predicted and fh == [], "every hit is a multiple of x^2 + 5; the half has none"
sq = mul(half, half, D)
hits = search(sq, D, 3, 6)
print(f"(sqrt(-5)/2)^2 = {sq[0]}; monic integer polys, degree <= 3, coefficients -6..6, with that root: {len(hits)}")
assert sq == (F(-5, 4), 0) and hits == []

# The grid: a, b in quarters from -2 to 2, so 289 numbers a + b*sqrt(d)
grid = [F(k, 4) for k in range(-8, 9)]
polys = [[1, c] for c in range(-2, 3)] + [[1, p_, q] for p_ in range(-4, 5) for q in range(-24, 25)]
for d in (-5, 5):
    r1 = [(a, b) for a in grid for b in grid if road1(a, b, d)]
    r2 = [(a, b) for a in grid for b in grid if any(root_of(c, (a, b), d) for c in polys)]
    coords = [(a, b) for a in grid for b in grid if a.denominator == 1 and b.denominator == 1]
    print(f"d = {d}: grid {len(grid)} x {len(grid)} = {len(grid) ** 2}, road 1 (minimal polynomial) {len(r1)}, "
          f"road 2 (search) {len(r2)}, whole a and b {len(coords)}, extra {len(r1) - len(coords)}")
    assert r1 == r2
    assert (len(r1) == len(coords)) == (d == -5), "Z[sqrt -5] is everything for d = -5, not for d = 5"
phi = (F(1, 2), F(1, 2))
print(f"golden ratio (1 + sqrt 5)/2: minimal polynomial {show(minpoly(*phi, 5))}, algebraic integer {road1(*phi, 5)}")

# The house example: 6 two ways, and no proper split of 2, 3 or 1 + sqrt(-5) in a box
print("2 x 3 =", mul((F(2), F(0)), (F(3), F(0)), D)[0], "; (1 + sqrt-5)(1 - sqrt-5) =", mul((F(1), F(1)), (F(1), F(-1)), D)[0])
box = [(F(a), F(b)) for a in range(-6, 7) for b in range(-6, 7)]
for name, t in [("2", (F(2), F(0))), ("3", (F(3), F(0))), ("1 + sqrt(-5)", (F(1), F(1)))]:
    pairs = [(x, y) for x in box for y in box if mul(x, y, D) == t]
    trivial = all(x in [(1, 0), (-1, 0)] or y in [(1, 0), (-1, 0)] for x, y in pairs)
    print(f"factor pairs of {name} with |a|, |b| <= 6: {len(pairs)}, every one uses 1 or -1: {trivial}")
    assert len(pairs) == 4 and trivial

# What breaks
def cleared(a, b, d):   # the minimal polynomial times the lcm of its denominators: integer, not monic
    m = minpoly(a, b, d)
    k = 1
    for c in m:
        k = k * c.denominator // gcd(k, c.denominator)
    return [c * k for c in m]
nonmonic = sum(1 for a in grid for b in grid
               if all(c.denominator == 1 for c in cleared(a, b, D)) and root_of(cleared(a, b, D), (a, b), D))
print("accept any integer polynomial, monic or not: grid numbers passing", nonmonic)
wrong = [F(1), F(-1, 2), F(5), F(-5, 2)]         # (x^2 + 5)(x - 1/2)
print(f"sqrt(-5) is a root of {show(wrong)}: {root_of(wrong, r5, D)}; judged by it, not an integer")
assert root_of(wrong, r5, D) and not all(c.denominator == 1 for c in wrong)
x4 = [1, 0, 0, 0, -25]
print("degree read off x^4 - 25:", len(x4) - 1, "; true degree", len(minpoly(*r5, D)) - 1)
assert root_of(x4, r5, D) and nonmonic == len(grid) ** 2

# The ring property at work: phi^n + (1 - phi)^n is rational, so it is whole (the Lucas numbers)
x, y = (F(1), F(0)), (F(1), F(0))
for n in range(10):
    x, y = mul(x, phi, 5), mul(y, (F(1, 2), F(-1, 2)), 5)
s = (x[0] + y[0], x[1] + y[1])
lucas = [2, 1]
while len(lucas) < 11:
    lucas.append(lucas[-1] + lucas[-2])
print("phi^10 + (1 - phi)^10 =", s[0], "+", s[1], "sqrt 5; the whole-number recurrence 2, 1, 3, 4, ... gives", lucas[10])
assert s == (lucas[10], 0)
print(f"figure, sqrt(-5) at (0, {5 ** 0.5:.6f}), sqrt(-5)/2 at (0, {5 ** 0.5 / 2:.6f})")
print("ALL CHECKS PASS")
