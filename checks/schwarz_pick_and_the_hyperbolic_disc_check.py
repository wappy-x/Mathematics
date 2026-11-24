# Schwarz-Pick and the hyperbolic disc -- the check behind the card.  Standard library
# only.  f(z) = z^2 on the unit disc, the Mobius map m(z) = (z - 0.5)/(1 - 0.5z).
# Road one: closed forms (2 artanh, the cosh formula, Schwarz-Pick's weights).
# Road two: the ruler 2/(1 - t^2) summed by Simpson's rule, a difference quotient,
# and a search over 108 grid points for the largest stretch of distance.
import math
def mob(c, z): return (z - c) / (1 - c.conjugate() * z)   # sends c to 0, keeps the disc
def dist(z, w): return 2 * math.atanh(abs(mob(w, z)))      # hyperbolic distance
def dist_cosh(z, w):                                       # the same, by the cosh formula
    return math.acosh(1 + 2 * abs(z - w) ** 2 / ((1 - abs(z) ** 2) * (1 - abs(w) ** 2)))
def ruler(r, n=1000):                    # Simpson's rule on 2/(1 - t^2) from 0 to r
    h = r / n
    s = sum((1 if k in (0, n) else 4 if k % 2 else 2) * 2 / (1 - (k * h) ** 2) for k in range(n + 1))
    return s * h / 3
def sp(f, df, z): return abs(df(z)) * (1 - abs(z) ** 2) / (1 - abs(f(z)) ** 2)
f, df = (lambda z: z * z), (lambda z: 2 * z)
m, dm = (lambda z: mob(0.5 + 0j, z)), (lambda z: 0.75 / (1 - 0.5 * z) ** 2)
p, dp = (lambda z: mob(-0.5 + 0j, z)), (lambda z: 0.75 / (1 + 0.5 * z) ** 2)
a, h = 0.5 + 0j, 1e-5
g = lambda w: mob(f(a), f(p(w)))         # move 0 to a, apply f, move f(a) to 0
dq = abs(g(h) - g(-h)) / (2 * h)
ratio = sp(f, df, a)
grid = [r / 10 * complex(math.cos(k * math.pi / 6), math.sin(k * math.pi / 6)) for r in range(1, 10) for k in range(12)]
pairs = [(z, w) for i, z in enumerate(grid) for w in grid[i + 1:]]
fr = [dist(f(z), f(w)) / dist(z, w) for z, w in pairs]
mr = [dist(m(z), m(w)) / dist(z, w) for z, w in pairs]
z0, d1, d2 = 0j, dist(0j, a), dist(0j, f(a))
print(f"f(z) = z^2 at 0.5: f = {f(a).real:.6f}, |f'| = {abs(df(a)):.6f}, 1 - |z|^2 = {1 - abs(a) ** 2:.6f}, 1 - |f|^2 = {1 - abs(f(a)) ** 2:.6f}")
print(f"Schwarz-Pick ratio {ratio:.6f}; |g'(0)| by difference quotient {dq:.6f}")
print(f"0 to 0.5: 2 artanh 0.5 = {d1:.6f}; ln 3 = {math.log(3):.6f}; ruler summed = {ruler(0.5):.6f}")
print(f"0 to 0.25: 2 artanh 0.25 = {d2:.6f}; ln(5/3) = {math.log(5 / 3):.6f}; ruler summed = {ruler(0.25):.6f}")
print(f"0.5 to -0.5: artanh form {dist(a, -a):.6f}; cosh form {dist_cosh(a, -a):.6f}; after z^2 {dist(f(a), f(-a)):.6f}")
print(f"0.25 to 0.5i: artanh form {dist(f(a), 0.5j):.6f}; cosh form {dist_cosh(f(a), 0.5j):.6f}")
print(f"z^2 on {len(pairs)} grid pairs: largest distance ratio {max(fr):.6f}")
print(f"m(z) = (z - 0.5)/(1 - 0.5z): m(0.5) = {abs(m(a)):.6f}, m(0) = {m(z0).real:.6f}, distance after {dist(m(a), m(z0)):.6f}")
print(f"m on the grid pairs: distance ratios from {min(mr):.6f} to {max(mr):.6f}")
print(f"m at 0.5: |m'| = {abs(dm(a)):.6f}, hyperbolic stretch {sp(m, dm, a):.6f}")
print(f"mistake 1, drawn stretch of (z + 0.5)/(1 + 0.5z) at -0.5: |p'| = {abs(dp(-a)):.6f}; hyperbolic {sp(p, dp, -a):.6f}")
print(f"mistake 2, ruler 1/(1 - t^2): artanh 0.5 = {math.atanh(0.5):.6f}, not {d1:.6f}")
print(f"mistake 3, Schwarz lemma on p, which moves 0: |p(0)| = {abs(p(z0)):.6f} > |0|")
print(f"mistake 4, 2z^2 leaves the disc: ratio at 0.5 = {sp(lambda z: 2 * z * z, lambda z: 4 * z, a):.6f}; 2(0.8)^2 = {2 * 0.8 ** 2:.6f}")
assert abs(ratio - 0.8) < 1e-12 and abs(dq - ratio) < 1e-8            # weights vs difference quotient
assert abs(d1 - math.log(3)) < 1e-12 and abs(ruler(0.5) - d1) < 1e-9    # formula vs summed ruler
assert abs(d2 - ruler(0.25)) < 1e-9 and d2 < d1                         # and z^2 shrinks it
assert abs(dist(a, -a) - dist_cosh(a, -a)) < 1e-12 and abs(dist(f(a), 0.5j) - dist_cosh(f(a), 0.5j)) < 1e-12
assert max(fr) < 1 and all(abs(r - 1) < 1e-9 for r in mr)              # contraction; isometry
print("ALL CHECKS PASS")
