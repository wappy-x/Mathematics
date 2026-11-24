# Normal families: Montel and Hurwitz -- the check behind the card.  Standard library only.
# Montel: z^n stays below 1 on the unit disc; on |z| <= 0.9 its worst size falls and its slopes obey
# one Cauchy bound.  Hurwitz: zeros counted by the argument principle (the turns of f round a circle)
# against roots found by algebra.  Riemann mapping: g_n = (z + z^2/n)/(1 + 1/n) climbs to z.
import cmath, math

def ring(r, m=2000):                           # m even steps round the circle |z| = r
    return [r * cmath.exp(2j * math.pi * k / m) for k in range(m)]
def turns(f, r, m=2000):                       # argument principle: angle steps of f summed, over 2 pi
    v = [f(z) for z in ring(r, m)]
    return round(sum(cmath.phase(v[k] / v[k - 1]) for k in range(m)) / (2 * math.pi))
def yn(claim):
    return "yes" if claim else "no"
disc = [k / 50 * cmath.exp(1j * t / 10) for k in range(46) for t in range(63)]   # grid on |z| <= 0.9
ns = (1, 5, 10, 20, 40)
grid = [max(abs(z ** n) for z in disc) for n in ns]
print("Montel: worst |z^n| on |z| <= 0.9 by grid, n = 1, 5, 10, 20, 40: " + ", ".join(f"{w:.6f}" for w in grid))
print("the same by 0.9^n: " + ", ".join(f"{0.9 ** n:.6f}" for n in ns))
print(f"on the open disc |z| < 1: z^40 at z = 0.9999 is {0.9999 ** 40:.6f}, so the worst size stays 1")
slope = max(abs(n * z ** (n - 1)) for z in disc for n in range(1, 120))
print(f"largest slope |n z^(n-1)| on |z| <= 0.9, any n: {slope:.6f}; Cauchy bound 1/(1 - 0.9) = {1 / (1 - 0.9):.6f}")
lin = [turns(lambda z, n=n: z - 1 / n, 0.5) for n in (3, 10, 100)]
print(f"Hurwitz: z - 1/n, turns on |z| = 1/2 for n = 3, 10, 100: {lin}; limit z: {turns(lambda z: z, 0.5)}")
sq = [turns(lambda z, n=n: z * z + 1 / n, 0.5) for n in (5, 100)]
print(f"z^2 + 1/n, n = 5, 100: turns {sq}, roots of size {1 / math.sqrt(5):.6f}, {1 / math.sqrt(100):.6f}; "
      f"limit z^2: turns {turns(lambda z: z * z, 0.5)}, distinct zeros 1")
edge = [turns(lambda z, n=n: z - 0.5 + 1 / n, 0.5) for n in (10, 100)]
print(f"z - 1/2 + 1/n, n = 10, 100: turns on |z| = 1/2 {edge}; the limit's zero 0.5 sits on the circle: 0 inside")
f = lambda z, n: z + z * z / n
print(f"one-to-one test, n = 1: f(-0.3) = {f(-0.3, 1):.6f}, f(-0.7) = {f(-0.7, 1):.6f}")
pre = [turns(lambda z, n=n: f(z, n) - f(-0.3, n), 0.999) for n in (1, 2, 10)]
print(f"solutions of f(z) = f(-0.3) in |z| < 0.999, n = 1, 2, 10: {pre}")
every = all(turns(lambda z, n=n, a=a: f(z, n) - f(a, n), 0.95, 400) == 1 for n in (2, 10) for a in disc[::7])
print(f"every grid point a hit once, n = 2 and 10: {yn(every)}; factor |1 + (a + b)/n| above 1 - 2/n: "
      + ", ".join(f"{1 - 2 / n:.6f}" for n in (2, 3, 10)))
print(f"z/n: one-to-one, worst size on the disc 1/n = {1 / 100:.6f} at n = 100; the limit 0 is constant")
g = lambda z, n: (z + z * z / n) / (1 + 1 / n)
cau = [sum(g(z, n) / z for z in ring(0.5)).real / 2000 for n in (2, 3, 10, 100)]
print("Riemann mapping: g_n'(0) by Cauchy's formula, n = 2, 3, 10, 100: " + ", ".join(f"{c:.6f}" for c in cau))
print("the same by n/(n + 1): " + ", ".join(f"{n / (n + 1):.6f}" for n in (2, 3, 10, 100)))
rim = ring(1.0, 720)
gap = [max(abs(g(z, n) - z) for z in rim) for n in (2, 10, 100)]
big = max(abs(g(z, n)) for z in rim for n in (2, 10, 100))
print(f"worst gap |g_n - z| on the rim, n = 2, 10, 100: {', '.join(f'{x:.6f}' for x in gap)}; largest |g_n| {big:.6f}")
assert all(abs(w - 0.9 ** n) < 1e-12 for w, n in zip(grid, ns))          # grid against formula
assert slope <= 1 / (1 - 0.9) and abs(slope - 9 * 0.9 ** 8) < 1e-9          # Cauchy bound holds
assert lin == [1, 1, 1] and sq == [2, 2] and edge == [1, 1] and pre == [2, 1, 1] and every
assert abs(f(-0.3, 1) - f(-0.7, 1)) < 1e-12                                 # n = 1 is two-to-one
assert all(abs(c - n / (n + 1)) < 1e-12 for c, n in zip(cau, (2, 3, 10, 100)))
assert all(abs(x - 2 / (n + 1)) < 1e-9 for x, n in zip(gap, (2, 10, 100))) and abs(big - 1) < 1e-12
print("ALL CHECKS PASS")
