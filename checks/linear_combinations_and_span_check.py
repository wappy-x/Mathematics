# Linear combinations and span -- the check behind the card.  Nothing is
# imported.  Fertiliser bag A = (10, 5) and bag B = (2, 8), counted in kg of
# nitrogen and kg of phosphorus.  Which targets can a mix of the two bags hit?
A, B, C = (10, 5), (2, 8), (20, 10)     # C is two bags of A, so no new direction

def mix(x, y):                          # x bags of A plus y bags of B
    return (x * A[0] + y * B[0], x * A[1] + y * B[1])

def cross(u, v):                        # the cross-number of two vectors
    return u[0] * v[1] - v[0] * u[1]

def eliminate(t):                       # road one: elimination, in decimals
    f = A[1] / A[0]                     # scale the nitrogen row by this to kill x
    y = (t[1] - f * t[0]) / (B[1] - f * B[0])
    x = (t[0] - B[0] * y) / A[0]        # back-substitute
    return x, y

def gcd(a, b):
    while b: a, b = b, a % b
    return abs(a)

def frac(n, d):                         # a whole-number fraction, tidied
    g = gcd(n, d)
    n, d = n // g, d // g
    return str(n) if d == 1 else f"{n}/{d}"

def rule(t):                            # road two: the cross-number rule, exact
    return cross(t, B), cross(A, t)     # both divided by cross(A, B)

d = cross(A, B)
print(f"bag A = {A} and bag B = {B}, in kg of nitrogen and kg of phosphorus")
print(f"{'the cross-number of A and B':<52}{d:>10}")
for t in ((14, 21), (14, 22)):
    x, y = eliminate(t)
    nx, ny = rule(t)
    g = mix(x, y)
    print(f"target {t}: elimination gives x = {x:.4f}, y = {y:.4f}")
    print(f"target {t}: the cross-number rule gives x = {frac(nx, d)}, y = {frac(ny, d)}")
    print(f"target {t}: rebuilt, {x:.4f} x A + {y:.4f} x B = ({g[0]:.4f}, {g[1]:.4f}) -> in the span")
grid = [mix(1, b) for b in (0, 1, 2, 3)]
print("one bag of A with 0, 1, 2 and 3 bags of B")
print("  nitrogen, kg    " + ", ".join(str(p[0]) for p in grid))
print("  phosphorus, kg  " + ", ".join(str(p[1]) for p in grid))
print(f"bag C = {C} is two bags of A: the cross-number of A and C is {cross(A, C)}")
m1, m2, m3 = mix(1.4, 0), mix(1, 1), mix(2, 1)
print(f"the three mistakes come out at ({m1[0]:.4f}, {m1[1]:.4f}), {m2} and {m3}")
assert rule((14, 21)) == (70, 140) and d == 70      # 14x8-2x21, 10x21-14x5, 10x8-2x5
assert rule((14, 22)) == (68, 150) and cross(A, C) == 0
assert abs(eliminate((14, 21))[0] - 1) < 1e-12 and abs(eliminate((14, 21))[1] - 2) < 1e-12
assert m2 == (12, 13) and m3 == (22, 18) and abs(m1[0] - 14) < 1e-9 and abs(m1[1] - 7) < 1e-9
print("ALL CHECKS PASS")
