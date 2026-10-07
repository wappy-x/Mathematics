# Ideals and quotient rings -- the check behind the card.  Nothing is imported.  An
# invoice claims 47 crates at $23 each come to $1,081.  Casting out nines maps the
# whole numbers to Z mod 9, with the multiples of 9 as its kernel; the class of the
# total is reached by three roads, no two sharing a step.  Polynomials follow.
A, B, N = 47, 23, 9
def digit_class(n):                 # a road with no division by 9 in it at all
    while n > 9:
        n = sum(int(c) for c in str(n))
    return 0 if n == 9 else n
def is_ideal(ring, sub, add, mul):  # a subgroup under +, and it absorbs the ring
    closed = all(any(add(b, c) == a for c in sub) for a in sub for b in sub)
    return closed and all(mul(r, a) in sub and mul(a, r) in sub
                          for r in ring for a in sub)
def reduce_poly(c):                 # x^2 + 1 is zero, so x^k becomes -x^(k-2)
    c = list(c)
    while len(c) > 2:
        top = c.pop()
        c[len(c) - 2] -= top
    return tuple(c)
def poly_product(a, b):             # road one: multiply out in full, then reduce
    raw = [0] * (len(a) + len(b) - 1)
    for i in range(len(a)):
        for j in range(len(b)):
            raw[i + j] += a[i] * b[j]
    return raw, reduce_poly(raw)
def pair_product(a, b, m=0):        # road two: the two-coordinate formula
    c, d = a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]
    return (c % m, d % m) if m else (c, d)
def reciprocals(n):                 # how many nonzero classes have a reciprocal
    return len([a for a in range(1, n) if any((a * b) % n == 1 for b in range(1, n))])
total, direct, classes = A * B, (A * B) % N, (A % N) * (B % N)  # reduce late, or early
shifted = [((A + N * i) * (B + N * j)) % N for i in range(-5, 6) for j in range(-5, 6)]
kernel = [k for k in range(41) if k % N == 0]
clock, cadd, cmul = list(range(12)), lambda a, b: (a + b) % 12, lambda a, b: (a * b) % 12
world = [(c, d) for c in range(3) for d in range(3)]   # x^2 = -1, coefficients mod 3
consts, wadd = [(c, 0) for c in range(3)], lambda p, q: ((p[0] + q[0]) % 3, (p[1] + q[1]) % 3)
ideals = [is_ideal(clock, [0, 3, 6, 9], cadd, cmul), is_ideal(clock, [0, 4, 6, 8], cadd, cmul),
          is_ideal(world, consts, wadd, lambda p, q: pair_product(p, q, 3))]
raw, poly = poly_product((2, 3), (4, 1))
pair, xx = pair_product((2, 3), (4, 1)), reduce_poly([0, 0, 1])
r9, r7, x1 = reciprocals(9), reciprocals(7), pair_product((0, 1), (1, 0))
print(f"the invoice: {A} x {B} = {total}")
print(f"class of the total, three roads: remainder of {total} is {direct}; classes "
      f"{A % N} x {B % N} = {classes} then {classes % N}; digit sums {digit_class(total)}")
print(f"other names, {A + N} x {B + N} = {(A + N) * (B + N)}, class {((A + N) * (B + N)) % N}")
print(f"all {len(shifted)} shifted pairs of names give one class: {sorted(set(shifted))}")
print(f"the wrong total 1090 has class {digit_class(1090)} too, so the check passes it")
print(f"kernel of casting out nines, 0 to 40: {kernel}")
print(f"ideal test: {{0, 3, 6, 9}} in Z mod 12 {str(ideals[0]).lower()}, {{0, 4, 6, 8}} "
      f"{str(ideals[1]).lower()}, the constants in the x^2 = -1 world {str(ideals[2]).lower()}")
print(f"(2 + 3x)(4 + x) multiplied out: {raw[0]} + {raw[1]}x + {raw[2]}x^2")
print(f"reduced by x^2 + 1: {poly[0]} + {poly[1]}x; coordinates: {pair[0]} + {pair[1]}x")
print(f"x times x reduced: {xx[0]} + {xx[1]}x; x times the constant 1: {x1[0]} + {x1[1]}x")
print(f"zero product among nonzero classes: 3 x 3 = {(3 * 3) % 9} in Z mod 9; with a "
      f"reciprocal: {r9} of 8 in Z mod 9, {r7} of 6 in Z mod 7")
assert direct == classes % N == digit_class(total) == 1
assert set(shifted) == {direct} and digit_class(1090) == direct and digit_class(1082) != direct
assert ideals == [True, False, False] and kernel == [0,9,18,27,36] and raw == [8, 14, 3]
assert poly == pair == (5, 14) and xx == (-1, 0) and x1 == (0, 1) and r9 == 6 and r7 == 6
print("ALL CHECKS PASS")
