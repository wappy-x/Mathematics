# Schwarz reflection -- the check behind the card.  Standard library only.
# e^z is used only on or above the real axis; below it, the mirror conj f(conj z).  Road one: the
# mirror against e^z from cos and sin.  Road two: Morera, the glued function round a triangle across
# the axis.  Road three: Taylor coefficients by a Cauchy integral against 1/n!.  Then Cayley mirrors.
import math
def exp_series(z, terms=40):              # e^z from its power series
    total, term = 0j, 1 + 0j
    for n in range(1, terms + 1):
        total, term = total + term, term * z / n
    return total
def glue(f, z, mirror=True):              # f on and above the axis; below, its mirror image
    if z.imag >= 0:
        return f(z)
    return f(z.conjugate()).conjugate() if mirror else f(z.conjugate())
def around(F, corners, n=800):            # midpoint rule once round a closed polygon
    total = 0j
    for a, b in zip(corners, corners[1:] + corners[:1]):
        h = (b - a) / n
        total += sum(F(a + (k + 0.5) * h) for k in range(n)) * h
    return total

def show(w):                              # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

p = 0.3 + 0.4j
up, low = exp_series(p), glue(exp_series, p.conjugate())
direct = math.exp(0.3) * complex(math.cos(-0.4), math.sin(-0.4))
print(f"by hand: e^0.3 = {math.exp(0.3):.6f}, cos 0.4 = {math.cos(0.4):.6f}, sin 0.4 = {math.sin(0.4):.6f}")
print(f"e^z at p = 0.3 + 0.4i: {show(up)}; mirror at 0.3 - 0.4i: {show(low)}; e^(0.3 - 0.4i) = {show(direct)}")
tri = [-0.4 - 0.3j, 0.6 - 0.3j, 0.1 + 0.5j]
good, bad = around(lambda z: glue(exp_series, z), tri), around(lambda z: glue(lambda w: 1j, z), tri)
nomirror, pole = around(lambda z: glue(exp_series, z, False), tri), around(lambda z: glue(lambda w: -1 / w, z), tri)
cross = [(a + (b - a) * (a.imag / (a.imag - b.imag))).real for a, b in ((tri[0], tri[2]), (tri[1], tri[2]))]
print(f"triangle crosses the axis at {cross[0]:.6f} and {cross[1]:.6f}: chord {cross[1] - cross[0]:.6f}")
print(f"Morera triangle: glued e^z {show(good)}; i above, -i below {show(bad)}; e^(conj z) below {show(nomirror)}; -1/z {show(pole)}")
r, m = 0.5, 64
pts = [r * complex(math.cos(2 * math.pi * k / m), math.sin(2 * math.pi * k / m)) for k in range(m)]
coef = [sum(glue(exp_series, z) * z ** -n for z in pts) / m for n in range(5)]
print("Taylor coefficients of the glued function: " + ", ".join(show(a) for a in coef))
print("1/n! for n = 0..4: " + ", ".join(f"{1 / math.factorial(n):.6f}" for n in range(5)))
cay = lambda z: (z - 1j) / (z + 1j)
print(f"Cayley: C(p) = {show(cay(p))}; C(conj p) = {show(cay(p.conjugate()))}; 1/conj C(p) = {show(1 / cay(p).conjugate())}")
g = lambda z: ((1 + z) / (1 - z)) ** 2       # upper half disc onto upper half plane
star = 1 / p.conjugate()                     # p mirrored in the unit circle
arc = complex(math.cos(math.pi / 3), math.sin(math.pi / 3))
print(f"half-disc map g: g(0.5) = {show(g(0.5))}; g(e^(i pi/3)) = {show(g(arc))}; g(p) = {show(g(p))}")
print(f"  across the diameter at conj p: mirror {show(g(p).conjugate())}; formula {show(g(p.conjugate()))}")
print(f"  across the arc at p* = {show(star)}: mirror {show(g(1 / star.conjugate()).conjugate())}; "
      f"formula {show(g(star))}; 1/z for 1/conj z: {show(g(1 / star).conjugate())}")
sc = lambda z: f"({160 + 80 * z.real:.1f},{160 - 80 * z.imag:.1f})"
print("figure, p " + sc(p) + " conj p " + sc(p.conjugate()) + " p* " + sc(star) + " triangle "
      + " ".join(sc(z) for z in tri) + " crossings " + sc(complex(cross[0])) + " " + sc(complex(cross[1])))
assert abs(low - direct) < 1e-12                                          # road one
assert abs(bad - (-2j * (cross[1] - cross[0]))) < 1e-9                    # -2i times the chord
assert abs(good) < 1e-6 and abs(nomirror) > 0.1 and abs(pole + 2j * math.pi) < 1e-5  # road two: Morera
assert all(abs(coef[n] - 1 / math.factorial(n)) < 1e-12 for n in range(5))  # road three
assert abs(cay(p.conjugate()) - 1 / cay(p).conjugate()) < 1e-12           # mirror pairs kept
assert abs(g(1 / star.conjugate()).conjugate() - g(star)) < 1e-9 and abs(g(arc).imag) < 1e-9 and abs(star - p / abs(p) ** 2) < 1e-12
print("ALL CHECKS PASS")
