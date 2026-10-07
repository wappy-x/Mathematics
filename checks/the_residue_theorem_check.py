# The residue theorem -- the check behind the card.  f(z) = 1/(z^2 + 1) has
# poles at i and -i.  Road one: each residue by its own limit, times 2 pi i.
# Road two: a trapezoid sum of f(z) dz round each circle, nothing borrowed.
import math
POLES = [1j, -1j]

def f(z):
    return 1 / (z * z + 1)

def loop(g, c, r, n, turns=1):          # trapezoid sum of g(z) dz round |z - c| = r
    total, step = 0, 2 * math.pi / n * (1 if turns > 0 else -1)
    for k in range(n * abs(turns)):
        w = complex(math.cos(k * step), math.sin(k * step))
        total += g(c + r * w) * 1j * r * w * step
    return total

def res(a):                             # (z - a) f(z) = 1/(z - b), b the other pole; let z -> a
    b = [p for p in POLES if p != a][0]
    return 1 / (a - b)

def show(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sci(x):
    e = math.floor(math.log10(x))
    return f"{x / 10 ** e:.1f}e{e}"

TWO_PI_I = 2j * math.pi
print(f"residue at i, by the limit: {show(res(1j))}; at -i: {show(res(-1j))}")
circles = [("|z - i| = 1", 1j, 1), ("|z + i| = 1", -1j, 1), ("|z| = 3", 0, 3), ("|z| = 1/2", 0, 0.5)]
gaps = []
for name, c, r in circles:
    inside = [a for a in POLES if abs(a - c) < r]
    theorem = TWO_PI_I * sum(res(a) for a in inside)
    direct = loop(f, c, r, 64)
    gaps.append(abs(direct - theorem))
    tag = ", ".join("i" if a == 1j else "-i" for a in inside) or "none"
    print(f"{name}: encloses {tag}; 2 pi i x residues = {show(theorem)}; trapezoid, 64 points = {show(direct)}")
errs = [abs(loop(f, 1j, 1, n) - math.pi) for n in (8, 16, 32)]
print(f"|z - i| = 1, trapezoid error at 8, 16, 32 points: {', '.join(sci(e) for e in errs)}")
tiny, big = loop(f, 1j, 0.01, 64), loop(f, 1j, 1, 64)
print(f"shrunk to |z - i| = 0.01: {show(tiny)}")
twice = loop(f, 1j, 1, 64, turns=2)
print(f"twice round |z - i| = 1: {show(twice)}")
print(f"mistake, |z - i| = 1 run clockwise: {show(loop(f, 1j, 1, 64, turns=-1))}")
print(f"mistake, residue at i taken as 1: 2 pi i x 1 = {show(TWO_PI_I)}")
print(f"mistake, |z - i| = 1 with the outside pole counted too: {show(TWO_PI_I * (res(1j) + res(-1j)))}")
conj = loop(lambda z: z.conjugate(), 0, 1, 64)
print(f"break, z-bar round |z| = 1 (no poles, not holomorphic): {show(conj)}, not 0")
s, cx, cy = 34, 180, 125
print(f"figure, {s} units per 1, 0 at ({cx}, {cy}); i at ({cx}, {cy - s}), -i at ({cx}, {cy + s}); "
      f"radii {s}, {3 * s}, {s // 2}")
assert max(gaps) < 1e-9                                  # two roads agree on all four circles
assert abs(tiny - big) < 1e-9 and errs[2] < errs[1] < errs[0]  # shrinking the loop changes nothing
assert abs(twice - 2 * TWO_PI_I * res(1j)) < 1e-9        # winding twice counts the residue twice
assert abs(conj - TWO_PI_I) < 1e-9                       # z-bar dz = i d(theta) round the unit circle
print("ALL CHECKS PASS")
