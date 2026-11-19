# Weierstrass form, discriminant and j-invariant -- the check behind the card.
# Standard library only.  Exact fractions throughout; floats only place the
# figure.  Roads: reduce a long equation step by step, against Tate's c4, c6
# formulas; the discriminant by formula, by a Sylvester determinant, and by
# hunting singular points mod p; j by a and b, by g2 and g3, and by rescaling.
from fractions import Fraction as Fr

def disc_ab(a, b):                      # Delta of y^2 = x^3 + a x + b
    return -16 * (4 * a**3 + 27 * b**2)

def j_ab(a, b):                         # j of y^2 = x^3 + a x + b, Delta not 0
    return Fr(1728 * 4 * a**3) / (4 * a**3 + 27 * b**2)

def reduce_long(a1, a2, a3, a4, a6):    # road one: square, then shift
    c = [Fr(1), a2 + Fr(a1 * a1, 4), a4 + Fr(a1 * a3, 2), a6 + Fr(a3 * a3, 4)]
    s = -c[1] / 3                       # x = X + s kills the x^2 term
    a = 3 * s * s + 2 * c[1] * s + c[2]
    b = s**3 + c[1] * s * s + c[2] * s + c[3]
    return c, s, a, b

def tate(a1, a2, a3, a4, a6):           # road two: Tate's b, c formulas
    b2, b4, b6 = a1 * a1 + 4 * a2, 2 * a4 + a1 * a3, a3 * a3 + 4 * a6
    b8 = a1 * a1 * a6 + 4 * a2 * a6 - a1 * a3 * a4 + a2 * a3 * a3 - a4 * a4
    c4, c6 = b2 * b2 - 24 * b4, -b2**3 + 36 * b2 * b4 - 216 * b6
    return (b2, b4, b6, b8), c4, c6, -b2 * b2 * b8 - 8 * b4**3 - 27 * b6 * b6 + 9 * b2 * b4 * b6

def det(m):                             # Gaussian elimination on fractions
    m, d = [[Fr(v) for v in row] for row in m], Fr(1)
    for i in range(len(m)):
        p = next((r for r in range(i, len(m)) if m[r][i] != 0), None)
        if p is None:
            return Fr(0)
        if p != i:
            m[i], m[p], d = m[p], m[i], -d
        d *= m[i][i]
        for r in range(i + 1, len(m)):
            f = m[r][i] / m[i][i]
            m[r] = [x - f * y for x, y in zip(m[r], m[i])]
    return d

def disc_sylvester(a, b):               # disc f = -Res(f, f') for a monic cubic
    f, g = [1, 0, a, b], [3, 0, a]
    return -det([f + [0], [0] + f, g + [0, 0], [0] + g + [0], [0, 0] + g])

def singular_mod(p, a, b):              # points where F and both slopes vanish
    return [(x, y) for x in range(p) for y in range(p)
            if (y * y - x**3 - a * x - b) % p == 0 and 2 * y % p == 0
            and (3 * x * x + a) % p == 0]

def count_mod(p, a, b):                 # points on y^2 = x^3 + a x + b mod p, with O
    return 1 + sum(1 for x in range(p) for y in range(p)
                   if (y * y - x**3 - a * x - b) % p == 0)

A, B = 0, -2                            # the house curve y^2 = x^3 - 2
LONG = (2, 2, 2, 1, -2)                 # y^2 + 2xy + 2y = x^3 + 2x^2 + x - 2
c, s, ra, rb = reduce_long(*LONG)
bs, c4, c6, D_long = tate(*LONG)
print(f"long form y^2 + 2xy + 2y = x^3 + 2x^2 + x - 2; point (2, 2): "
      f"{2*2 + 2*2*2 + 2*2} = {2**3 + 2*2**2 + 2 - 2}")
print(f"step 1, Y = y + x + 1: Y^2 = x^3 + ({c[1]})x^2 + ({c[2]})x + ({c[3]})")
print(f"step 2, x = X + ({s}): Y^2 = X^3 + ({ra})X + ({rb})")
print(f"Tate road: b2, b4, b6, b8 = {bs}")
print(f"Tate road: c4 = {c4}, c6 = {c6}, Delta = {D_long}; a = -c4/48 = {Fr(-c4, 48)}, "
      f"b = -c6/864 = {Fr(-c6, 864)}")
X, Y = 2 - s, 2 + 2 + 1
print(f"point (2, 2) moves to ({X}, {Y}): {Y*Y} = {X**3 + B}")
D = disc_ab(A, B)
print(f"house: 4a^3 + 27b^2 = {4*A**3 + 27*B**2}; Delta = -16 x {4*A**3 + 27*B**2} = {D}")
print(f"at (3, 5): F, F_x, F_y = {25 - 27 - A*3 - B}, {-(3*9 + A)}, {2*5}; "
      f"g2, g3 = -4a, -4b = {-4*A}, {-4*B}; 1728 = 2^6 x 3^3 = {2**6 * 3**3}")
print(f"Sylvester road: disc(x^3 - 2) = {disc_sylvester(A, B)}; 16 x disc = {16*disc_sylvester(A, B)}")
primes = [p for p in range(2, 50) if all(p % q for q in range(2, p))]
bad = [p for p in primes if singular_mod(p, A, B)]
print(f"primes below 50 where y^2 = x^3 - 2 has a singular point: {bad}, "
      f"at {[singular_mod(p, A, B)[0] for p in bad]}")
print(f"primes below 50 dividing 1728: {[p for p in primes if 1728 % p == 0]}")
for name, a, b, P in [("node", -3, 2, (1, 0)), ("cusp", 0, 0, (0, 0))]:
    x, y = P
    print(f"{name} y^2 = x^3 + ({a})x + ({b}): Delta = {disc_ab(a, b)}; at {P} "
          f"F, F_x, F_y = {y*y - x**3 - a*x - b}, {-(3*x*x + a)}, {2*y}")
print(f"node: y^2 = (x - 1)^2 (x + 2) near (1, 0) is y^2 ~ {1 + 2}(x - 1)^2, two slopes")
j0, ja, jb = j_ab(A, B), j_ab(-1, 1), j_ab(-16, 64)
g2, g3 = 4, -4                          # y^2 = 4x^3 - g2 x - g3 with a = -g2/4, b = -g3/4
jg = Fr(1728 * g2**3, g2**3 - 27 * g3**2)
print(f"j(x^3 - 2) = {j0}; j(x^3 - x + 1) = {ja}; j(x^3 - 16x + 64) = {jb}")
print(f"Delta(x^3 - x + 1) = {disc_ab(-1, 1)}; Delta(x^3 - 16x + 64) = {disc_ab(-16, 64)} "
      f"= {disc_ab(-1, 1)} x 2^12 = {disc_ab(-1, 1) * 2**12}")
print(f"j(x^3 - x) = {j_ab(-1, 0)} = 12^3 = {12**3}; secp256k1 y^2 = x^3 + 7 (SEC 2): "
      f"j = {j_ab(0, 7)}, Delta = {disc_ab(0, 7)}")
print(f"same curve as y^2 = 4x^3 - {g2}x + {-g3}: 1728 g2^3/(g2^3 - 27 g3^2) = {jg}")
u2 = Fr(1 * -16, -1 * 64)               # u^2 = b a'/(a b')
print(f"u^2 = {u2}; u^4 = {u2**2} = a/a' = {Fr(-1, -16)}; u^6 = {u2**3} = b/b' = {Fr(1, 64)}; "
      f"(1, 1) -> (4, 8): {8*8} = {4**3 - 16*4 + 64}")
ps = [p for p in primes if p > 3]
cE, cS, cT = ([count_mod(p, 0, b) for p in ps] for b in (-2, -128, 1))
print(f"primes {ps}")
print(f"points mod p, y^2 = x^3 - 2:   {cE}")
print(f"points mod p, y^2 = x^3 - 128: {cS}")
print(f"points mod p, y^2 = x^3 + 1:   {cT}")
print(f"(3, 5) -> (12, 40) on x^3 - 128: {40*40} = {12**3 - 128}; 2(3, 5) has x = {Fr(27, 10)**2 - 6}")
print(f"mistake 1, a, b read with the x^2 term left in: Delta = {disc_ab(c[2], c[3])}, "
      f"j = {j_ab(c[2], c[3])}")
*_, D_cub = tate(0, 0, 1, 0, 0)
print(f"mistake 2, y^2 + y = x^3: right side x^3 has disc {disc_sylvester(0, 0)}; "
      f"Tate Delta = {D_cub}; F at (0, -1/2) = {Fr(1, 4) - Fr(1, 2)}")
f2 = [(a, b, singular_mod(2, a, b)) for a in (0, 1) for b in (0, 1)]
print("mistake 3, over F_2 every short form is singular: "
      + "; ".join(f"a={a} b={b} at {pt[0]}" for a, b, pt in f2))
print(f"mistake 4, equal j over Q: mod 7, x^3 - 2 has {count_mod(7, 0, -2)} points, "
      f"x^3 + 1 has {count_mod(7, 0, 1)}")
print(f"figure, smooth root {2**(1/3):.6f}; P (3, 5); node (1, 0) and root -2; cusp (0, 0)")
assert (ra, rb) == (Fr(-c4, 48), Fr(-c6, 864)) == (A, B)          # two roads to a, b
assert D_long == D == 16 * disc_sylvester(A, B) == -1728          # three roads to Delta
assert bad == [p for p in primes if D % p == 0]                    # singular mod p iff p | Delta
assert ja == jb == jg                                             # j three ways
assert disc_ab(-16, 64) == disc_ab(-1, 1) * 4096                  # Delta / u^12
assert cE == cS and cE != cT and D_cub != 0 and all(f2[i][2] for i in range(4))
print("ALL CHECKS PASS")
