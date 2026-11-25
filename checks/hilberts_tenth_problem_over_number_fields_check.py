# Hilbert's tenth problem over number fields -- the check behind the card.
# Standard library only.  Part 1: Lagrange's four squares pick out 0, 1, 2, ...
# inside the integers, counted by brute force and by Jacobi's divisor formula.
# Part 2: in Z[sqrt2] a square need not be a whole number.  Part 3: the curve
# E5: y^2 = x^3 - 25x and its point P = (-4, 6); the denominators of kP come
# by adding points and by the division-polynomial recursion.  Part 4: the twist
# by 2 decides whether the rank grows in Q(sqrt2): Tunnell's counts against a
# search for points.  Both programs print the same lines.
from fractions import Fraction as Fr
from math import isqrt

N, R = 60, range(-8, 9)

def r3(n):                              # signed, ordered ways as three squares
    return sum(1 for a in R for b in R for c in R if a*a + b*b + c*c == n)

def r4(n):                              # the same, as four squares
    return sum(r3(n - d*d) for d in R if d*d <= n)

def jacobi(n):                          # 8 times the divisors not divisible by 4
    return 8 * sum(d for d in range(1, n + 1) if n % d == 0 and d % 4 != 0)

def form_8t7(n):                        # n = 4^e (8s + 7)?
    while n > 0 and n % 4 == 0:
        n //= 4
    return n % 8 == 7

def zmul(u, v):                         # (u0 + u1 sqrt2)(v0 + v1 sqrt2)
    return (u[0]*v[0] + 2*u[1]*v[1], u[0]*v[1] + u[1]*v[0])

def add(P, Q, n):                       # chord and tangent on y^2 = x^3 - n^2 x
    (x1, y1), (x2, y2) = P, Q
    lam = (3*x1*x1 - n*n) / (2*y1) if P == Q else (y2 - y1) / (x2 - x1)
    x3 = lam*lam - x1 - x2
    return (x3, lam*(x1 - x3) - y1)

def psi(K):                             # division polynomials of E5 at x = -4, y = 6
    a, x, y = -25, -4, 6
    p = [0, 1, 2*y, 3*x**4 + 6*a*x*x - a*a,
         4*y*(x**6 + 5*a*x**4 - 5*a*a*x*x - a**3)]
    for k in range(5, K + 1):
        m = k // 2
        if k % 2:
            p.append(p[m+2]*p[m]**3 - p[m-1]*p[m+1]**3)
        else:
            p.append(p[m]*(p[m+2]*p[m-1]**2 - p[m-2]*p[m+1]**2) // p[2])
    return p

def tunnell(n):                         # Tunnell's two counts for y^2 = x^3 - n^2 x
    m, c = (n, 2) if n % 2 else (n // 2, 4)
    T = range(-isqrt(m), isqrt(m) + 1)
    A = sum(1 for x in T for y in T for z in T if x*x + c*y*y + 8*z*z == m)
    B = sum(1 for x in T for y in T for z in T if x*x + c*y*y + 32*z*z == m)
    return A, B

def search(n, amax=2000, emax=12):      # points x = a/e^2, y = b/e^3 with y > 0
    found = []
    for e in range(1, emax + 1):
        for a in range(-amax, amax + 1):
            if Fr(a, e*e).denominator != e*e:
                continue
            v = a**3 - n*n*a*e**4
            if v > 0 and isqrt(v)**2 == v:
                found.append((a, e))
    return found

print("part 1: the whole numbers 0, 1, 2, ... picked out by four squares")
print(f"7 = 4 + 1 + 1 + 1; signed ways to write 7: three squares {r3(7)}, four squares {r4(7)}")
counts = [r4(n) for n in range(1, N + 1)]
jac_ok = counts == [jacobi(n) for n in range(1, N + 1)]
print(f"four-square counts agree with Jacobi's divisor formula for n <= {N}: {'yes' if jac_ok else 'no'}")
need4 = [n for n in range(N + 1) if r3(n) == 0]
print(f"n <= {N} needing four squares: {need4}")
print(f"the same list from the form 4^e(8s + 7): {'yes' if need4 == [n for n in range(N + 1) if form_8t7(n)] else 'no'}")
print(f"n <= {N} with no four-square form: {sum(1 for c in counts if c == 0)}")
print("part 2: four squares fail in Z[sqrt2]")
a, b = zmul((1, 1), (1, 1))             # (1 + sqrt2) times itself, in Z[sqrt2]
print(f"(1 + sqrt2)^2 = {a} + {b} sqrt2, a square that is not a whole number; norm {a*a - 2*b*b}")
print("part 3: E5: y^2 = x^3 - 25x and the point P = (-4, 6)")
P = (Fr(-4), Fr(6))
print(f"check: 6^2 = {6*6} and (-4)^3 - 25(-4) = {(-4)**3 + 100}")
Q2 = add(P, P, 5)
print(f"2P = ({Q2[0]}, {Q2[1]}), not whole, so P has infinite order (Nagell-Lutz)")
p = psi(8)
mult, Q = [P], P
for k in range(2, 5):
    Q = add(Q, P, 5)
    mult.append(Q)
road1 = [isqrt(M[0].denominator) for M in mult]
d = [abs(v) for v in p]
print("k, d_k by adding points, d_k by the division-polynomial recursion, its digits")
for k in range(1, 9):
    print(f"{k} {road1[k-1] if k <= 4 else '-'} {d[k]} {len(str(d[k]))}")
strong = all((d[k] % d[j] == 0) == (k % j == 0) for j in range(1, 9) for k in range(1, 9))
print(f"d_j divides d_k exactly when j divides k, checked for j, k <= 8: {'yes' if strong else 'no'}")
eds = all(p[m+n]*p[m-n] == p[m+1]*p[m-1]*p[n]**2 - p[n+1]*p[n-1]*p[m]**2 for m, n in ((5, 2), (6, 2)))
print(f"second road to d_5..d_8: psi(m+n)psi(m-n) = psi(m+1)psi(m-1)psi(n)^2 - psi(n+1)psi(n-1)psi(m)^2"
      f" at (m, n) = (5, 2), (6, 2), pairs the recursion never uses: {'yes' if eds else 'no'}")
print("part 4: does the rank grow in Q(sqrt2)? ask the twist by 2")
res = {}
for n in (3, 5, 6, 10, 41):              # at 41 the z terms count, testing 8 and 32
    A, B = tunnell(n)
    pts = search(n)
    res[n] = (A, B, pts)
    verdict = "A = 2B: rank may be positive" if A == 2*B else "A != 2B: rank 0 (Tunnell, Coates-Wiles)"
    first = f"first x = {Fr(pts[0][0], pts[0][1]**2)}" if pts else "none"
    print(f"E{n}: A = {A}, B = {B}, {verdict}; search finds {len(pts)} points, {first}")
print("rank E5 over Q(sqrt2) = rank E5 over Q + rank E10 over Q = rank E5 over Q + 0")
print("part 5: what breaks")
print(f"mistake 1, three squares instead of four: 7 has {r3(7)} forms; {len(need4)} numbers <= {N} missed")
print(f"mistake 2, four squares in Z[sqrt2]: {a} + {b} sqrt2 passes and is not a whole number")
X, Y = Fr(-3), Fr(9)                      # E6's point (-3, 9) becomes (X/2, Y sqrt2/4) on E3
x3, ysq = X / 2, (Y / 4)**2 * 2
print(f"mistake 3, E3 in place of E5: rank 0 over Q, but ({x3}, {Y/4} sqrt2) lies on it over Q(sqrt2): "
      f"x^3 - 9x = {x3**3 - 9*x3}, y^2 = {ysq}")
print(f"  that point has infinite order: 2(-3, 9) on E6 has x = {add((X, Y), (X, Y), 6)[0]}")
assert jac_ok and r4(7) == 64 and r3(7) == 0                    # brute force against Jacobi
assert need4 == [n for n in range(N + 1) if form_8t7(n)]       # brute force against Legendre's form
assert road1 == d[1:5] and strong                               # two roads to the denominators
assert eds                                                      # the identity checks d_5 to d_8
assert all((res[n][0] == 2*res[n][1]) == bool(res[n][2]) for n in res)   # Tunnell against search
assert x3**3 - 9*x3 == ysq and Q2[0].denominator != 1
print("ALL CHECKS PASS")
