# Inverting by partial fractions -- the check behind the card.  Only math's
# exp, sin, cos, sqrt, pi and prod are imported.  Case 1: the car released from 1 cm,
# Y = (s + 2)/(s^2 + 2s + 5).  Case 2: a steady push, Y = 5/(s(s^2 + 2s + 5)).
# Road one completes the square and reads the table.  Road two splits over the
# complex roots by cover-up.  Road three transforms road one's answer forward.
from math import exp, sin, cos, sqrt, pi, prod
P, Q = 2.0, 5.0                                  # the denominator s^2 + P s + Q

def square(al, be):                              # road one: (al s + be) over the square
    a = P / 2; w = sqrt(Q - a * a)               # (s + a)^2 + w^2
    return a, w, al, (be - al * a) / w           # e^(-at)(C cos wt + D sin wt)

def cover_up(num, poles):                        # road two: residue at each simple pole
    return [(p, num(p) / prod(p - q for q in poles if q != p)) for p in poles]

def at(terms, t):                                # sum of r e^(pt): its real part
    return sum((r * complex(cos(p.imag * t), sin(p.imag * t))).real * exp(p.real * t) for p, r in terms)

def simpson(f, s, R=40.0, n=4000):               # road three: integral of e^(-st) f(t)
    h = R / n
    return h / 3 * sum((1 if k in (0, n) else 4 if k % 2 else 2) * exp(-s * k * h) * f(k * h)
                       for k in range(n + 1))

root = (-P + complex(P * P - 4 * Q) ** 0.5) / 2  # quadratic formula, complex square root
poles, grid = [root, root.conjugate()], [k * 0.01 for k in range(401)]
a, w, C, D = square(1.0, 2.0)
print(f"discriminant P^2 - 4Q = {P * P - 4 * Q:g}: no real roots; completed square (s + {a:g})^2 + {w * w:g}")
y1 = lambda t: exp(-a * t) * (C * cos(w * t) + D * sin(w * t))
r1 = cover_up(lambda s: s + 2, poles)[0][1]
print(f"case 1, completed square: shift a = {a:g}, w = {w:g}, cos coefficient {C:.6f}, sin coefficient {D:.6f}")
print(f"case 1, cover-up at {root.real:g}{root.imag:+g}i: residue {r1.real:.6f} {r1.imag:+.6f}i, "
      f"so cos {2 * r1.real:.6f}, sin {-2 * r1.imag:.6f}")
gap1 = max(abs(y1(t) - at(cover_up(lambda s: s + 2, poles), t)) for t in grid)
low = min(grid[50:301], key=y1)
print(f"case 1, forward transform at s = 2: {simpson(y1, 2.0):.6f} against Y(2) = 4/13 = {4 / 13:.6f}")
print(f"case 1 in the car: y(0) = {y1(0):.6f} cm, y(0.5) = {y1(0.5):.6f} cm, lowest {y1(low):.6f} cm at t = {low:.2f} s")
A = 5 / Q                                        # cover-up at the real pole s = 0
a2, w2, C2, D2 = square(-A, -A * P)              # leftover (5 - A D(s))/s = -A s - A P
y2 = lambda t: A + exp(-a2 * t) * (C2 * cos(w2 * t) + D2 * sin(w2 * t))
gap2 = max(abs(y2(t) - at(cover_up(lambda s: 5 + 0j, [0j] + poles), t)) for t in grid)
print(f"case 2, cover-up at s = 0: A = {A:.6f}; leftover ({-A:.6f} s {-A * P:+.6f})/(s^2 + 2s + 5)")
print(f"case 2, so y = {A:g} - e^(-t)(cos 2t + {D2 / C2:.1f} sin 2t); forward transform at s = 2: "
      f"{simpson(y2, 2.0):.6f} against 5/26 = {5 / 26:.6f}")
print(f"roads one and two, largest gap on 0 to 4 s: case 1 {'below' if gap1 < 1e-12 else 'ABOVE'} 1e-12, "
      f"case 2 {'below' if gap2 < 1e-12 else 'ABOVE'} 1e-12")
print(f"mistake 1, e^(+t) for (s + 1): y(0.5) = {exp(0.5) * (cos(1) + 0.5 * sin(1)):.6f}, not {y1(0.5):.6f}")
print(f"mistake 2, s + 2 left whole over the square: y(0.5) = {exp(-0.5) * cos(1):.6f}")
print(f"mistake 3, sin entry without dividing by w: y(0.5) = {exp(-0.5) * (cos(1) + sin(1)):.6f}")
ts = [k * 0.25 for k in range(16)]
print("figure, t     " + " ".join(f"{t:5.2f}" for t in ts))
print("figure, cos   " + " ".join(f"{exp(-t) * cos(2 * t):5.2f}" for t in ts))
print("figure, sin   " + " ".join(f"{0.5 * exp(-t) * sin(2 * t):5.2f}" for t in ts))
print("figure, y     " + " ".join(f"{y1(t):5.2f}" for t in ts))
assert gap1 < 1e-12 and gap2 < 1e-12                             # square + table = cover-up
assert abs(simpson(y1, 2.0) - 4 / 13) < 1e-7                     # the answer transforms back
assert abs(simpson(y2, 2.0) - 5 / 26) < 1e-7
assert abs(low - pi / 2) < 0.01 and abs(y1(low) + exp(-pi / 2)) < 1e-4  # the shelf-3 dip
print("ALL CHECKS PASS")
