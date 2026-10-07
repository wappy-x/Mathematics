# The argument principle -- the check behind the card.  Walk a circle and count
# the turns of f(z) round 0 by two roads that share nothing but f.  Road one:
# (1/2 pi i) times a trapezoid sum of f'/f dz.  Road two: a compass needle,
# adding the small turn between neighbouring values of f, read off atan2.
import math

def f(z): return z * (z - 0.4), 2 * z - 0.4                      # value, derivative
def g(z): return (z - 0.5) / (z - 2) ** 3, ((z - 2) - 3 * (z - 0.5)) / (z - 2) ** 4

def walk(r, n):                          # n + 1 points round |z| = r, anticlockwise
    return [r * complex(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n + 1)]

def integral(fn, r, n=256):              # road one: (1/2 pi i) x sum of f'/f dz
    total = 0
    for z in walk(r, n)[:-1]:
        v, d = fn(z)
        total += d / v * 1j * z * (2 * math.pi / n)
    return total / (2j * math.pi)

def compass(fn, r, n=256, marks=None):   # road two: add up the needle's small turns
    pts, turn, seen = walk(r, n), 0.0, [0.0]
    for k in range(n):
        q = fn(pts[k + 1])[0] / fn(pts[k])[0]
        turn += math.atan2(q.imag, q.real)
        if marks and (k + 1) % (n // marks) == 0: seen.append(turn / (2 * math.pi))
    return (turn / (2 * math.pi), seen) if marks else turn / (2 * math.pi)

def show(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def sci(x): e = math.floor(math.log10(x)); return f"{x / 10 ** e:.1f}e{e}"

def count(zeros, poles, r):              # road three: located zeros and poles, with multiplicity
    return sum(m for a, m in zeros if abs(a) < r) - sum(m for a, m in poles if abs(a) < r)

cases = [("z(z - 0.4)", f, [(0, 1), (0.4, 1)], [], 1), ("z(z - 0.4)", f, [(0, 1), (0.4, 1)], [], 0.2),
         ("(z - 0.5)/(z - 2)^3", g, [(0.5, 1)], [(2, 3)], 1), ("(z - 0.5)/(z - 2)^3", g, [(0.5, 1)], [(2, 3)], 3)]
gaps = []
for name, fn, zs, ps, r in cases:
    truth, i1, c2 = count(zs, ps, r), integral(fn, r), compass(fn, r)
    gaps += [abs(i1 - truth), abs(c2 - truth)]
    print(f"{name} round |z| = {r}: N - P = {truth}; integral = {show(i1)}; compass = {c2:.6f}")
errs = [abs(integral(f, 1, n) - 2) for n in (8, 16, 32)]
print("z(z - 0.4), |z| = 1, integral error at 8, 16, 32 points: " + ", ".join(sci(e) for e in errs))
turns, marks = compass(f, 1, 256, 8)
print("needle turns at 0, 1/8, ..., 8/8 of the walk: " + ", ".join(f"{t:.2f}" for t in marks))
few = [compass(f, 1, n) for n in (3, 4, 5)]
print("compass sampled at only 3, 4, 5 points: " + ", ".join(str(int(math.floor(c + 0.5))) for c in few))
cz = compass(lambda z: (z.conjugate(), None), 1)     # z-bar: no derivative exists
print(f"break, z-bar round |z| = 1 (one zero inside, not holomorphic): compass = {cz:.6f}")
print(f"mistake, pole of order 3 counted once, |z| = 3: 1 - 1 = 0, not {count([(0.5, 1)], [(2, 3)], 3)}")
print("figure, left 55 units per 1, 0 at (75, 120), zeros at (75, 120) and (97, 120); right 65 units per 1, 0 at (240, 120)")
img = [f(z)[0] for z in walk(1, 72)]
print("figure, image points: " + " ".join(f"{math.floor(240 + 65 * w.real + 0.5)},{math.floor(120 - 65 * w.imag + 0.5)}" for w in img))
assert max(gaps) < 1e-9                                 # both roads land on N - P in all four cases
assert errs[2] < errs[1] < errs[0] and errs[2] < 1e-9   # the trapezoid error shrinks
assert abs(few[2] - integral(f, 1)) < 1e-9 and abs(few[0] - 2) > 2.5   # 5 points suffice, 3 miss turns
assert abs(cz + count([(0, 1)], [], 1)) < 1e-9          # z-bar turns the other way: -1, not +1
print("ALL CHECKS PASS")
