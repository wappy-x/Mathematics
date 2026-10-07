# Arc length -- the check behind the card.  Standard library only; math gives
# sqrt and log as primitives, and every sum below is written out here.
# A suspension cable hangs as the parabola y = x^2 / 1000 between towers at
# x = -200 and x = 200 m: span 400 m, sag 40 m.  Its length, three roads.
from math import sqrt, log

S, D = 400.0, 40.0                 # span and sag, metres
A, B = -S / 2, S / 2               # the towers
def f(x):  return 4 * D * x * x / (S * S)          # height above the low point
def fp(x): return 8 * D * x / (S * S)              # slope, metres per metre

def step(x): return D if x >= 0 else 0.0            # a 40 m jump at midspan

def polygon(n, g=f):               # road one: n straight chords, tower to tower
    xs = [A + (B - A) * i / n for i in range(n + 1)]
    return sum(sqrt((xs[i] - xs[i - 1]) ** 2 + (g(xs[i]) - g(xs[i - 1])) ** 2)
               for i in range(1, n + 1))

def simpson(g, a, b, n):           # road two: Simpson's rule, n even strips
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

k = 8 * D / (S * S)                # slope per metre of x: 1/500
u = k * B                          # slope at the tower: 0.4
exact = (u * sqrt(1 + u * u) + log(u + sqrt(1 + u * u))) / k   # road three
graph = simpson(lambda x: sqrt(1 + fp(x) ** 2), A, B, 100)
param = simpson(lambda t: sqrt((S / 2) ** 2 + (2 * D * t) ** 2), -1.0, 1.0, 100)

r = sqrt(1 + u * u)
print(f"span {S:.0f} m, sag {D:.0f} m, cable y = x^2/1000, slope x/500, at the tower {u:.1f}")
print(f"sqrt(1.16) = {r:.6f}; 0.4 x it = {u * r:.6f}; asinh 0.4 = ln({u + r:.6f}) = "
      f"{log(u + r):.6f}; sum {u * r + log(u + r):.6f}")
print(f"closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): {exact:.6f} m")
print(f"Simpson on sqrt(1 + f'(x)^2), 100 strips: {graph:.6f} m")
print(f"Simpson on the speed of x = 200t, y = 40t^2, 100 strips: {param:.6f} m")
lengths = []
for n in (1, 2, 4, 8, 16, 32, 64):
    lengths.append(polygon(n))
    print(f"chords {n:4d}: polygon {lengths[-1]:.2f} m, short by {exact - lengths[-1]:.4f} m")
print(f"mistake 1, integrate |slope| only: {simpson(lambda x: abs(fp(x)), A, B, 100):.3f} m")
print(f"mistake 2, drop the square root: {simpson(lambda x: 1 + fp(x) ** 2, A, B, 100):.3f} m")
print(f"no jumps dropped, a {D:.0f} m step at midspan: formula (slope 0) {S:.2f} m, "
      f"1024 chords {polygon(1024, step):.2f} m")
print(f"rule of thumb s + 8d^2/(3s): {S + 8 * D * D / (3 * S):.3f} m")
X = lambda x: 180 + 0.8 * x
Y = lambda x: 150 - 0.8 * f(x)
print("figure, 0.8 units per m, chord points:",
      " ".join(f"({X(x):.1f},{Y(x):.1f})" for x in (-200, -100, 0, 100, 200)))
assert abs(graph - exact) < 1e-7                  # road two against road three
assert abs(param - exact) < 1e-7                  # a new clock, the same length
assert all(p < q for p, q in zip(lengths, lengths[1:] + [exact]))   # chords climb, stay under
assert 0 < exact - polygon(1024) < 1e-4           # road one closes the gap, from below
print("ALL CHECKS PASS")
