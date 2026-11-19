# Ideals and varieties -- the check behind the card.  Standard library only.
# Beacon A at (0, 0) reads 6 km; beacon B at (10, 0) reads 8 km.  A polynomial
# is a dict {(i, j): coefficient of x^i y^j}, every coefficient an exact fraction.
from fractions import Fraction as Q
P = 101                                       # the clock for brute-force counts

def add(*ps):
    out = {}
    for p in ps:
        for m, c in p.items():
            out[m] = out.get(m, 0) + c
    return {m: Q(c) for m, c in out.items() if c != 0}

def mul(p, q):
    out = {}
    for (a, b), c in p.items():
        for (d, e), k in q.items():
            out[(a + d, b + e)] = out.get((a + d, b + e), 0) + c * k
    return add(out)

def sc(k, p): return add({m: k * c for m, c in p.items()})
def at(p, x, y): return sum(c * x**i * y**j for (i, j), c in p.items())

def show(p):                                  # leading term first, x before y
    s = ""
    for (i, j) in sorted(p, reverse=True):
        c = p[(i, j)]
        mono = ("x" if i else "") + (f"^{i}" if i > 1 else "") + ("y" if j else "") + (f"^{j}" if j > 1 else "")
        txt = (str(abs(c)) if abs(c) != 1 or not mono else "") + mono
        s += (("-" if c < 0 else "") if not s else (" - " if c < 0 else " + ")) + txt
    return s or "0"

def rem(p, X, Y2):                            # divide by x - X and y^2 - Y2: a + b y is left
    return add(*[{(0, j % 2): c * X**i * Y2**(j // 2)} for (i, j), c in p.items()])

def circle(cx, r): return add({(2, 0): 1, (0, 2): 1, (1, 0): -2 * cx, (0, 0): cx * cx - r * r})
def modp(c): return c.numerator * pow(c.denominator, P - 2, P) % P
def count(*ps):                               # every (x, y) on the 101-clock, tried
    qs = [{m: modp(c) for m, c in p.items()} for p in ps]
    return [(x, y) for x in range(P) for y in range(P)
            if all(sum(c * x**i * y**j for (i, j), c in q.items()) % P == 0 for q in qs)]

def fix(ra, d, rb):                           # two roads to x and y^2 for two range circles
    line = add(circle(0, ra), sc(-1, circle(d, rb)))       # f1 - f2, a line
    X = -line.get((0, 0), 0) / line[(1, 0)]
    Y2 = -at(circle(0, ra), X, 0)
    assert X == Q(d * d + ra * ra - rb * rb, 2 * d) and Y2 == ra * ra - X * X   # the triangle
    return line, X, Y2

seed = 2026
state = seed
def rnd(n):                                   # SplitMix64, started from the seed
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = (state ^ (state >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return (z ^ (z >> 31)) % n
def rpoly(deg): return add({(i, j): rnd(19) - 9 for i in range(deg + 1) for j in range(deg + 1 - i)})

x, y = {(1, 0): Q(1)}, {(0, 1): Q(1)}
f1, f2 = circle(0, 6), circle(10, 8)
line, X, Y2 = fix(6, 10, 8)
g1 = sc(Q(1, 4), line)
g2 = add(sc(25, f1), sc(-1, mul(add(sc(5, x), {(0, 0): 18}), g1)))
fixes = [(X, Q(24, 5)), (X, Q(-24, 5))]
print("field: rational coefficients, real points; terms in lex order, x before y")
print(f"f1 = {show(f1)}  (beacon A at (0, 0) reads 6 km)")
print(f"f2 = {show(f2)}  (beacon B at (10, 0) reads 8 km)")
print(f"g1 = (f1 - f2)/4 = {show(g1)}")
print(f"g2 = 25 f1 - (5x + 18) g1 = {show(g2)}")
back1 = sc(Q(1, 25), add(g2, mul(add(sc(5, x), {(0, 0): 18}), g1))) == f1
back2 = add(f1, sc(-4, g1)) == f2
print(f"back again: (g2 + (5x + 18) g1)/25 = f1: {'yes' if back1 else 'no'}; f1 - 4 g1 = f2: {'yes' if back2 else 'no'}")
print(f"fixes from g1 = 0 and g2 = 0: ({X}, 24/5) and ({X}, -24/5); y^2 = {Y2}")
print(f"in decimals: x = {float(X):.1f} km, y^2 = {float(Y2):.2f}, y = +/-{24 / 5:.1f} km")
print(f"by the triangle: x = (10^2 + 6^2 - 8^2)/(2 x 10) = {Q(72, 20)}; y^2 = 6^2 - x^2 = {36 - Q(72, 20)**2}")
vals = [[at(p, *pt) for p in (f1, f2, g1, g2)] for pt in fixes]
print(f"f1, f2, g1, g2 at the north fix: {', '.join(map(str, vals[0]))}; at the south fix: {', '.join(map(str, vals[1]))}")
xx = add(mul(x, f1), sc(-1, mul(x, f2)))
print(f"by hand: x f1 - x f2 = {show(xx)}; at x = 18/5: {20 * X * X} - {72 * X} = {at(xx, X, 0)}")
combos = [add(mul(rpoly(2), f1), mul(rpoly(2), f2)) for _ in range(1000)]
others = [rpoly(4) for _ in range(1000)]
tally = lambda ps: (sum(all(at(p, *pt) == 0 for pt in fixes) for p in ps), sum(rem(p, X, Y2) == {} for p in ps))
(cz, cr), (oz, orr) = tally(combos), tally(others)
print(f"1000 random h1 f1 + h2 f2 (SplitMix64, seed {seed}): zero at both fixes {cz}, remainder 0 in {cr}")
print(f"1000 random polynomials not built that way: zero at both fixes {oz}, remainder 0 in {orr}")
brute = count(f1, f2)
reduced = [(modp(a), modp(b)) for a, b in fixes]
print(f"over the 101-clock, every (x, y) tried: V(f1, f2) = {brute}")
print(f"the two fixes reduced mod 101: {reduced[0]} and {reduced[1]}")
bear = add(sc(4, x), sc(-3, y))
left = [pt for pt in fixes if at(bear, *pt) == 0]
print(f"add a bearing 4x - 3y: remainder {show(rem(bear, X, Y2))}, not in the ideal; "
      f"fixes left [({left[0][0]}, {left[0][1]})]; mod 101 points {len(count(f1, f2, bear))}")
inside = add(mul(x, f1), mul(y, f2))
print(f"add x f1 + y f2: remainder {show(rem(inside, X, Y2))}, in the ideal; mod 101 points {len(count(f1, f2, inside))}")
tl, tX, tY2 = fix(6, 10, 4)
print(f"tangent, B reads 4 km: f1 - f2 = {show(tl)}; x = {tX}, y^2 = {tY2}; ideal <x - 6, y^2>; point ({tX}, 0)")
print(f"  y is zero at ({tX}, 0), yet its remainder is {show(rem(y, tX, tY2))}: not in the ideal; "
      f"mod 101 points {len(count(circle(0, 6), circle(10, 4)))}")
print(f"x^2 + 1: no real point, since x^2 + 1 >= 1; mod 101 roots {[t for t in range(P) if (t * t + 1) % P == 0]}")
print(f"mistake 1, one beacon only (f1): mod 101 points {len(count(f1))}")
print(f"mistake 2, f1 f2 = 0 instead of both: mod 101 points {len(count(mul(f1, f2)))}")
print(f"mistake 3, the line g1 kept, both circles dropped: mod 101 points {len(count(g1))}")
for t in (4, 6):
    _, aX, aY2 = fix(3, t, 2)
    print(f"arm, links 3 m and 2 m, target {t} m: elbow x = {aX}, y^2 = {aY2}, real places {(aY2 > 0) + (aY2 >= 0)}")
px = lambda u: 20 * (u + 7)
py = lambda v: 20 * (9 - v)
print(f"figure, 20 px per km: A ({px(0)}, {py(0)}) r 120; B ({px(10)}, {py(0)}) r 160; "
      f"fixes ({px(X)}, {py(Q(24, 5))}) and ({px(X)}, {py(Q(-24, 5))})")
assert back1 and back2 and g1 == {(1, 0): 5, (0, 0): -18} and g2 == {(0, 2): 25, (0, 0): -576}
assert all(v == 0 for row in vals for v in row) and Y2 == Q(24, 5) ** 2
assert cz == cr == 1000 and oz == orr == 0                    # vanishing agrees with remainder
assert brute == sorted(reduced) and len(left) == 1            # brute force agrees with algebra
assert tY2 == 0 and rem(y, tX, tY2) == y and len(count(f1)) == 100 and len(count(mul(f1, f2))) == 198
print("ALL CHECKS PASS")
