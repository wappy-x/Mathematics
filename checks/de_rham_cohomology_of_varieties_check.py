# De Rham cohomology of the punctured plane -- the check behind the card.
# Standard library only.  Three roads to one answer, H^0 = 1, H^1 = 1, H^2 = 0:
#   road 1: algebraic de Rham of C[z, 1/z], ranks by exact integer elimination
#   road 2: loop integrals of the angle form, by Simpson's rule written out
#   road 3: two local angle potentials on slit planes, and the jump between them
from fractions import Fraction
import math
TAU = 2 * math.pi

def rank(m, p=0):                 # fraction-free elimination; p = 0 means over Q
    m = [[v % p if p else v for v in row] for row in m]
    r = 0
    for c in range(len(m[0])):
        piv = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if piv is None:
            continue
        m[r], m[piv] = m[piv], m[r]
        for i in range(len(m)):
            if i != r and m[i][c] != 0:
                a, b = m[r][c], m[i][c]
                m[i] = [(a * x - b * y) % p if p else a * x - b * y for x, y in zip(m[i], m[r])]
        r += 1
    return r

def de_rham(lo, hi, p=0):         # d: z^n -> n z^(n-1) dz, n = lo..hi; no z^-1 dz when lo = 0
    src, tgt = list(range(lo, hi + 1)), list(range(lo - 1 if lo else 0, hi))
    d = [[n if m == n - 1 else 0 for n in src] for m in tgt]
    rk = rank(d, p)
    missed = [m for m in tgt if rank([row + [1 if t == m else 0] for row, t in zip(d, tgt)], p) > rk]
    return rk, len(src) - rk, len(tgt) - rk, missed

def show(poly):                   # a Laurent polynomial {exponent: coefficient}, leading term first
    out = ""
    for e in sorted(poly, reverse=True):
        c = poly[e]
        s = ("-" if c < 0 else "+") if out else ("-" if c < 0 else "")
        out += (" " + s + " " if out else s) + ("" if abs(c) == 1 and e != 0 else str(abs(c)))
        out += "" if e == 0 else "z" if e == 1 else f"z^{e}"
    return out

def simpson(f, n=2000):           # integral of f over [0, 1]
    h = 1 / n
    return h / 3 * sum(f(k * h) * (1 if k in (0, n) else 4 if k % 2 else 2) for k in range(n + 1))

def along(form, path, vel):       # integral of P dx + Q dy along a path on [0, 1]
    def g(t):
        (x, y), (u, v) = path(t), vel(t)
        P, Q = form(x, y)
        return P * u + Q * v
    return simpson(g)

def circle(cx, cy, R, turns=1):
    w = TAU * turns
    return (lambda t: (cx + R * math.cos(w * t), cy + R * math.sin(w * t)),
            lambda t: (-R * w * math.sin(w * t), R * w * math.cos(w * t)))

def square(form, cx, cy, s):      # anticlockwise square of half-side s, four straight sides
    c = [(cx + s, cy - s), (cx + s, cy + s), (cx - s, cy + s), (cx - s, cy - s)]
    total = 0.0
    for (ax, ay), (bx, by) in zip(c, c[1:] + c[:1]):
        total += along(form, lambda t: (ax + t * (bx - ax), ay + t * (by - ay)), lambda t: (bx - ax, by - ay))
    return total

def omega(x, y):
    r2 = x * x + y * y
    return (-y / r2, x / r2)

def alpha(x, y):                  # d ln(x^2 + y^2) + 3 omega, written out as one form
    r2 = x * x + y * y
    return ((2 * x - 3 * y) / r2, (3 * x + 2 * y) / r2)

def f6(x):
    return f"{0.0 if abs(x) < 5e-7 else x:.6f}"

def theta1(x, y): return math.atan2(y, x)             # slit along the negative x-axis
def theta2(x, y): return math.atan2(-y, -x) + math.pi  # slit along the positive x-axis

rk, h0, h1, missed = de_rham(-6, 6)
print("road 1, algebra on C[z, 1/z], degrees -6 to 6, exact ranks")
print(f"rank of d over Q: {rk} of 13; dim H^0 = {h0}; dim H^1 = {h1}; not hit: {', '.join('z^%d dz' % m for m in missed)}")
alg = {2: Fraction(3), 0: Fraction(-2), -1: Fraction(5), -3: Fraction(4)}
res = alg[-1]
F = {m + 1: c / (m + 1) for m, c in alg.items() if m != -1}       # antiderivative, term by term
dF = {e - 1: e * c for e, c in F.items() if e != 0}
dF[-1] = dF.get(-1, 0) + res
print(f"alpha = ({show(alg)}) dz = d({show(F)}) + {res} dz/z: {'yes' if dF == alg else 'no'}")
fz = lambda z: sum(float(c) * z ** e for e, c in alg.items())
zi = simpson(lambda t: fz(complex(math.cos(TAU * t), math.sin(TAU * t))) * 1j * TAU * complex(math.cos(TAU * t), math.sin(TAU * t)))
print(f"contour integral of alpha round |z| = 1: {f6(zi.real)} + {f6(zi.imag)}i; 2 pi x {res} = {f6(TAU * float(res))}")
print("road 2, loop integrals of omega = (-y dx + x dy)/(x^2 + y^2)")
h = 1e-5
qx = (omega(1 + h, 2)[1] - omega(1 - h, 2)[1]) / (2 * h)
py = (omega(1, 2 + h)[0] - omega(1, 2 - h)[0]) / (2 * h)
print(f"cross rates at (1, 2): dQ/dx = {f6(qx)}, dP/dy = {f6(py)}")
loops = [("unit circle, once round", along(omega, *circle(0, 0, 1))),
         ("square of half-side 1 round the origin", square(omega, 0, 0, 1)),
         ("square of half-side 1 centred at (3, 0)", square(omega, 3, 0, 1)),
         ("circle of radius 2, twice round", along(omega, *circle(0, 0, 2, 2)))]
for name, v in loops:
    print(f"{name}: {f6(v)}")
la = along(alpha, *circle(0, 0, 1))
rest = along(lambda x, y: tuple(a - 3 * w for a, w in zip(alpha(x, y), omega(x, y))), *circle(0.5, -0.2, 2))
ca = (alpha(1 + h, 2)[1] - alpha(1 - h, 2)[1]) / (2 * h) - (alpha(1, 2 + h)[0] - alpha(1, 2 - h)[0]) / (2 * h)
print(f"alpha_real = ((2x - 3y) dx + (3x + 2y) dy)/(x^2 + y^2): curl at (1, 2) {f6(ca)}, loop {f6(la)}, class c = {f6(la / TAU)}")
print(f"alpha_real - 3 omega round a circle of radius 2 at (0.5, -0.2): {f6(rest)}")
g = lambda x, y: tuple(((x * x + y * y - 1) / 2) * w for w in omega(x, y))
curl = (g(1 + h, 2)[1] - g(1 - h, 2)[1]) / (2 * h) - (g(1, 2 + h)[0] - g(1, 2 - h)[0]) / (2 * h)
print(f"H^2: dx dy = d(((x^2 + y^2 - 1)/2) omega); curl at (1, 2) = {f6(curl)}")
print("road 3, two local angles, slit along the negative and the positive x-axis")
gap = max(abs((th(1 + h, 2) - th(1 - h, 2)) / (2 * h) - omega(1, 2)[0]) for th in (theta1, theta2))
jump = theta2(0, -1) - theta1(0, -1)
print(f"d(theta) = omega at (1, 2): {'yes' if gap < 1e-8 else 'no'}; theta2 - theta1 at (0, 1): "
      f"{f6(theta2(0, 1) - theta1(0, 1))}, at (0, -1): {f6(jump)}")
mu_i = 4 * math.pi * 1e-7 * 10 * 1e6                               # mu0 I in microtesla metres
wire = lambda x, y: tuple(mu_i / TAU * w for w in omega(x, y))
c1, c2 = along(wire, *circle(0, 0, 0.05)), square(wire, 0.03, 0.02, 0.1)
print(f"wire, 10 A: B-form = {f6(mu_i / TAU)} omega microtesla m; |B| at 0.05 m = {f6(mu_i / TAU / 0.05)} microtesla")
print(f"clamp loops: circle r 0.05 m {f6(c1)}, square half-side 0.1 m at (0.03, 0.02) {f6(c2)}; current {f6(c2 / mu_i * 10)} A")
rk5, h05, h15, missed5 = de_rham(-6, 6, 5)
rkz, h0z, h1z, _ = de_rham(0, 6)
print(f"mistake 1, zero curl so exact: predicted 0.000000, unit circle {f6(loops[0][1])}")
print(f"mistake 2, atan2 as one potential: end - start {f6(theta1(*circle(0, 0, 1)[0](1)) - theta1(*circle(0, 0, 1)[0](0)))}; "
      f"across the negative x-axis it jumps {f6(theta1(-1, -1e-9) - theta1(-1, 1e-9))}")
print(f"mistake 3, over F_5: rank {rk5}, dim H^0 = {h05}, dim H^1 = {h15}, not hit: {', '.join('z^%d dz' % m for m in missed5)}")
print(f"mistake 4, the whole line C[z], degrees 0 to 6: rank {rkz}, dim H^0 = {h0z}, dim H^1 = {h1z}")
circ, tor, chi = 3 - 3, 9 - 27 + 18, 4 ** 3 - 4 * 4 ** 2 + 6 * 4   # Euler counts: hollow triangle, 3 x 3 torus grid, quartic
print(f"Betti counts from Euler counts: punctured plane, circle 3 - 3 = {circ}, so 1 {1 - circ} 0; "
      f"square-lattice torus 9 - 27 + 18 = {tor}, so 1 {2 - tor} 1; quartic 64 - 64 + 24 = {chi}, so 1 0 {chi - 2} 0 1")
assert (h0, h1, missed) == (1, 1, [-1]) and dF == alg            # road 1: one class, dz/z
assert abs(zi.imag - TAU * 5) < 1e-9 and abs(zi.real) < 1e-9       # residue against contour
assert all(abs(v - TAU) < 1e-9 for _, v in loops[:2]) and abs(loops[2][1]) < 1e-9
assert abs(loops[3][1] - 2 * TAU) < 1e-9 and abs(la - 3 * TAU) < 1e-9 and abs(rest) < 1e-9 and abs(ca) < 1e-6
assert abs(jump - loops[0][1]) < 1e-9 and gap < 1e-8               # road 3 against road 2
assert abs(curl - 1) < 1e-6 and abs(c1 - c2) < 1e-9 and abs(c2 / mu_i * 10 - 10) < 1e-9
assert (h05, missed5) == (3, [-6, -1, 4]) and h1z == 0
print("ALL CHECKS PASS")
