# Line integral of a function -- the check behind the card.  Standard library
# only; math gives sqrt as a primitive, and every sum below is written out here.
# A wire bent along y = x^2 / 2 from x = 1 to x = 2 m.  Its density is 3x kg/m,
# rising from 3 at the near end to 6 at the far end.  Its mass, two roads.
from math import sqrt

def rho(x, y): return 3 * x                      # density, kg per metre
def y_of(x):   return x * x / 2                  # the wire's shape

def simpson(g, a, b, n=200):                     # Simpson's rule, n even strips
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def line_integral(x, y, dx, dy, a, b):           # density times speed, over the clock
    return simpson(lambda t: rho(x(t), y(t)) * sqrt(dx(t) ** 2 + dy(t) ** 2), a, b)

def pieces(n):                                   # road two: the definition itself
    xs = [1 + i / n for i in range(n + 1)]
    total = 0.0
    for p, q in zip(xs, xs[1:]):
        chord = sqrt((q - p) ** 2 + (y_of(q) - y_of(p)) ** 2)
        m = (p + q) / 2
        total += rho(m, y_of(m)) * chord         # density at the middle, times chord
    return total

exact = 5 ** 1.5 - 2 ** 1.5                      # (1 + x^2)^(3/2) from x = 1 to 2
by_x = line_integral(lambda t: t, lambda t: t * t / 2, lambda t: 1.0, lambda t: t, 1, 2)
by_u = line_integral(lambda u: sqrt(u), lambda u: u / 2,
                     lambda u: 1 / (2 * sqrt(u)), lambda u: 0.5, 1, 4)
back = line_integral(lambda s: 3 - s, lambda s: (3 - s) ** 2 / 2,
                     lambda s: -1.0, lambda s: -(3 - s), 1, 2)
sign = lambda t: -1.0 if t > 0 else 1.0           # out to the far end, then back
twice = line_integral(lambda t: 2 - abs(t), lambda t: (2 - abs(t)) ** 2 / 2,
                      sign, lambda t: (2 - abs(t)) * sign(t), -1, 1)
length = simpson(lambda t: sqrt(1 + t * t), 1, 2)
print("wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end")
print(f"closed form 5^1.5 - 2^1.5 = {5 ** 1.5:.6f} - {2 ** 1.5:.6f} = {exact:.6f} kg")
print(f"clock x = t, t from 1 to 2, speed sqrt(1 + t^2): {by_x:.6f} kg")
print(f"clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): {by_u:.6f} kg")
print(f"reversed, x = 3 - s, s from 1 to 2, far end first: {back:.6f} kg")
for n in (1, 4, 16, 64, 256):
    print(f"pieces {n:5d}: density x chord {pieces(n):.6f} kg, off by {pieces(n) - exact:+.6f}")
print(f"wire length (density 1): {length:.6f} m; average density {exact / length:.4f} kg/m")
print(f"mistake, drop the speed (density x dx): {simpson(lambda t: rho(t, y_of(t)), 1, 2):.6f} kg")
print(f"mistake, signed length when reversed: {simpson(lambda t: rho(t, y_of(t)) * sqrt(1 + t * t), 2, 1):.6f} kg")
X = lambda x: 40 + 100 * x
Y = lambda x: 220 - 100 * y_of(x)
print(f"mistake, a clock that runs out and back: {twice:.6f} kg")
print("figure, 100 units per m, curve:", " ".join(f"{X(1 + i / 10):.1f},{Y(1 + i / 10):.1f}" for i in range(11)))
print("figure, chord points:", " ".join(f"{X(1 + i / 4):.1f},{Y(1 + i / 4):.1f}" for i in range(5)))
assert abs(by_x - exact) < 1e-9                  # the formula against the antiderivative
assert abs(by_u - exact) < 1e-9                  # a new clock, the same mass
assert abs(back - exact) < 1e-9                  # the other direction, the same mass
assert abs(pieces(256) - exact) < 1e-5          # the definition closes in on it
print("ALL CHECKS PASS")
