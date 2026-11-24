# Runge's theorem -- the check behind the card.  Standard library only: the
# complex exponential is built from math.exp, math.cos and math.sin.
import math
TAU = 2 * math.pi

def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def ring(r, m): return [r * cexp(complex(0, TAU * k / m)) for k in range(m)]
def loop_integral(g, m=64): return sum(g(z) * 1j * z for z in ring(1, m)) * TAU / m
def worst(g, pts): return max(abs(g(z)) for z in pts)
def horner(c, z):                                  # c[0] + c[1] z + c[2] z^2 + ...
    out = 0j
    for a in reversed(c): out = out * z + a
    return out
def push(a, b, n):                                 # 1/(z - a) rebuilt from poles at b
    return lambda z: horner([(a - b) ** k for k in range(n)], 1 / (z - b)) / (z - b)
K = ring(1, 720)                                   # the circle |z| = 1
disc = [r / 10 * z for r in range(11) for z in ring(1, 72)]   # the closed disc |z| <= 1
powers = max(abs(loop_integral(lambda z, k=k: z ** k)) for k in range(5))
loop = loop_integral(lambda z: 1 / z)
print(f"loop integrals of 1, z, ..., z^4: largest size {powers:.6f}; of 1/z: {loop.imag:.6f}i, real part {abs(loop.real):.6f}")
print(f"so every polynomial misses 1/z somewhere by at least |2 pi i| / 2 pi = {abs(loop) / TAU:.6f}")
seed, best = 2026, 9.0
def rnd():                                         # a small home-made random number
    global seed
    seed = (seed * 1103515245 + 12345) % 2 ** 31
    return (seed / 2 ** 31 - 0.5) / 5     # between -0.1 and 0.1
for trial in range(300):
    c = [complex(rnd(), rnd()) for _ in range(6)]
    best = min(best, worst(lambda z: 1 / z - horner(c, z), K))
print(f"300 random polynomials of degree 5, {len(K)} points on the circle: smallest worst gap {best:.6f}")
gap_inf = worst(lambda z: 1 / (z - 2) + 0.5 * horner([1] * 11, z / 2), disc)
print(f"1/(z - 2) by its degree-10 polynomial on |z| <= 1, {len(disc)} points: worst gap {gap_inf:.9f}; 2^-11 = {2 ** -11:.9f}")
gap_hole = worst(lambda z: 1 / z - push(0, 0.25, 11)(z), K)
print(f"1/z by 11 powers of 1/(z - 1/4) on |z| = 1: worst gap {gap_hole:.9f}; 3^-11 = {3 ** -11:.9f}")
f = lambda z: cexp(z) / z
def riemann(m, inner=True):                        # Cauchy's formula on two circles, as a sum
    pts = [(w, 1) for w in ring(2, m)] + ([(w, -1) for w in ring(0.5, m)] if inner else [])
    return lambda z: sum(s * f(w) * w / (w - z) for w, s in pts) / m
gaps = [worst(lambda z: f(z) - riemann(m)(z), K) for m in (8, 16, 32)]
print("e^z/z on |z| = 1 by Riemann sums, 8, 16, 32 points per circle: worst gaps "
      + ", ".join(f"{g:.9f}" for g in gaps))
bad_push = [worst(lambda z: 1 / z - push(0, 0.5, n)(z), K) for n in (11, 101)]
bad_taylor = worst(lambda z: 1 / z - horner([(-1) ** n for n in range(11)], z - 1), K)
no_inner = worst(lambda z: f(z) - riemann(32, False)(z), K)
print(f"mistake 1, pole pushed from 0 to 1/2 in one jump: worst gap {bad_push[0]:.6f} (11 terms), {bad_push[1]:.6f} (101)")
print(f"mistake 2, Taylor polynomial of 1/z about 1, degree 10: worst gap {bad_taylor:.6f}")
print(f"mistake 3, e^z/z with the inner circle dropped, 32 points: worst gap {no_inner:.6f}")
print("figure, 60 units per 1, 0 at (200, 150): K radius 60, inner loop 30, outer loop 120, 1/4 at (215, 150)")
assert abs(loop - TAU * 1j) < 1e-9 and powers < 1e-9         # the obstruction, against 2 pi i
assert best >= 1                                            # brute force respects the bound
assert abs(gap_inf - 2 ** -11) < 1e-12                       # tail formula against sampling
assert abs(gap_hole - 3 ** -11) < 1e-12                      # the same, inside the hole
assert gaps[0] > gaps[1] > gaps[2] and gaps[2] < 1e-6        # Riemann sums close in
assert abs(bad_push[1] - 1) < 1e-9 and abs(bad_taylor - 2048) < 1e-6
print("ALL CHECKS PASS")
