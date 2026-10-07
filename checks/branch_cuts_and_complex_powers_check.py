# Branch cuts and complex powers.  Road one: the principal value e^(a Log z), Log z
# from ln|z| and atan2.  Road two takes no logarithm: it walks straight legs from a
# known value, multiplying in (1 + u)^a from the binomial series at each small step.
from math import log, exp, cos, sin, atan2, hypot, pi

def principal(z, a):                         # z^a = e^(a Log z), Arg in (-pi, pi]
    L = a * complex(log(hypot(z.real, z.imag)), atan2(z.imag, z.real))
    return exp(L.real) * complex(cos(L.imag), sin(L.imag))
def binom(u, a):                             # (1 + u)^a = sum of C(a, n) u^n, u small
    total, term, n = 0j, 1 + 0j, 0
    while abs(term) > 1e-18:
        total, term, n = total + term, term * (a - n) * u / (n + 1), n + 1
    return total
def walk(corners, a, w=1 + 0j, steps=4000):  # follow z^a continuously, corner to corner
    z, seen = corners[0], [w]
    for p, q in zip(corners, corners[1:]):
        for k in range(1, steps + 1):
            nz = p + (q - p) * k / steps
            w, z = w * binom(nz / z - 1, a), nz
        seen.append(w)
    return seen
def c(z):                                    # 'a + bi' to six decimals, no -0.000000
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

I, THIRD = 1j, 1 / 3
ii, ii_walk = principal(I, I), walk([1, I], I)[-1]
ii_loop = walk([1, I, -1, -I, 1, I], I)[-1]  # once round the origin, then on to i
ii_back = walk([1, -I, -1, I], I)[-1]        # clockwise to i: angle -3pi/2
print("i^i, principal e^(i Log i)    ", c(ii), f"= e^(-pi/2) = {exp(-pi / 2):.6f}")
print("i^i, walked from 1 to i       ", c(ii_walk))
print("i^i, extra loop; clockwise    ", c(ii_loop), ";", c(ii_back))
print(f"e^(-5pi/2), e^(3pi/2)          {exp(-5 * pi / 2):.6f}, {exp(3 * pi / 2):.6f}")
cr, cr_walk = principal(-8 + 0j, THIRD), walk([1, 1 + 8j, -8 + 8j, -8], THIRD)[-1]
roots = []
for w in (1 + 2j, -3 + 0j, 1 - 2j):          # Newton on w^3 + 8 = 0: no angle used
    roots.append([w := w - (w ** 3 + 8) / (3 * w * w) for _ in range(60)][-1])
best = max(roots, key=lambda w: (round(w.real, 9), w.imag))  # rightmost, then upper
print("(-8)^(1/3), principal         ", c(cr))
print("(-8)^(1/3), walked above 0    ", c(cr_walk))
print("cube roots of -8, Newton      ", ", ".join(c(w) for w in roots))
above, below = principal(complex(-8, 1e-12), THIRD), principal(complex(-8, -1e-12), THIRD)
loop = walk([1, I, -1, -I, 1], THIRD)[-1]
print("(-8)^(1/3) just above, below  ", c(above), ",", c(below))
print("jump above/below; loop factor ", c(above / below), ";", c(loop))
corners = [4, 4 * I, -4, -4 * I, 4]
seen = walk(corners, 0.5, w=2 + 0j)
print("sqrt round 4, 4i, -4, -4i, 4:  principal   |   followed")
for z, w in zip(corners, seen):
    print(f"  z = {c(complex(z)):>22}  {c(principal(complex(z), 0.5)):>22}  {c(w):>22}")
s = principal(-1 + 0j, 0.5)
print("sqrt(-1) sqrt(-1), sqrt(1)    ", c(s * s), ",", c(principal(1 + 0j, 0.5)))
print("figure, 20 per 1, diamond", " ".join(f"{180 + 20 * z.real:.1f},{120 - 20 * z.imag:.1f}" for z in map(complex, corners[:4])))
print("figure, 40 per 1, cube roots", " ".join(f"{180 + 40 * w.real:.1f},{120 - 40 * w.imag:.1f}" for w in roots),
      f"wedge {180 + 100 * cos(pi / 3):.1f},{120 - 100 * sin(pi / 3):.1f}")
assert abs(ii - ii_walk) < 1e-9 and abs(ii_back - exp(3 * pi / 2)) < 1e-6
assert abs(cr - best) < 1e-9 and abs(cr - cr_walk) < 1e-9
assert abs(above / below - loop) < 1e-9     # the jump at the cut is one loop's factor
assert abs(seen[-1] + principal(4 + 0j, 0.5)) < 1e-9  # once round: sqrt z becomes -sqrt z
print("ALL CHECKS PASS")
