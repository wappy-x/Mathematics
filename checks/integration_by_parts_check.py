# Integration by parts -- the check behind the card.  Standard library only;
# math.exp and math.log are the only primitives used.
# Road one: the parts formula, and its reduction J_n = e - n * J_(n-1).
# Road two: a Simpson sum of the original integrand, refined until it closes.
import math

def simpson(f, a, b, n):                 # n even; weights 1, 4, 2, 4, ..., 4, 1
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

E = math.exp(1.0)
xex = lambda x: x * math.exp(x)
bx, lx = 1.0 * E - 0.0 * 1.0, E - 1.0    # [x e^x] from 0 to 1; integral of e^x
bl, ll = E * 1.0 - 1.0 * 0.0, E - 1.0    # [x ln x] from 1 to e; integral of 1
print(f"x e^x on 0..1: boundary {bx:.6f} - leftover {lx:.6f} = {bx - lx:.6f}")
print(f"ln x on 1..e:  boundary {bl:.6f} - leftover {ll:.6f} = {bl - ll:.6f}")
for n in (4, 8, 16, 32):
    s = simpson(xex, 0.0, 1.0, n)
    print(f"Simpson x e^x, {n:2d} strips: {s:.12f}, error {s - (bx - lx):.12f}")
J, rows = E - 1.0, []                    # J_0 = e - 1, then the reduction
for n in range(5):
    if n > 0:
        J = E - n * J
    se = simpson(lambda x: x ** n * math.exp(x), 0.0, 1.0, 128)
    sl = simpson(lambda x: math.log(x) ** n, 1.0, E, 128)
    rows.append((J, se, sl))
    print(f"J_{n}: reduction {J:.6f}, Simpson x^{n} e^x {se:.6f}, Simpson (ln x)^{n} {sl:.6f}")
h = 1e-5                                 # the antiderivatives, differentiated back
F = lambda x: math.exp(x) * (x - 1)       # the antiderivative of x e^x
G = lambda x: x * math.log(x) - x         # the antiderivative of ln x
dF, dG = (F(0.5 + h) - F(0.5 - h)) / (2 * h), (G(2 + h) - G(2 - h)) / (2 * h)
print(f"rates: e^x (x - 1) at 0.5 is {dF:.6f}, x e^x {xex(0.5):.6f}; x ln x - x at 2 is {dG:.6f}, ln 2 {math.log(2.0):.6f}")
pts = " ".join(f"({60 + 200 * u:.1f}, {215 - 70 * math.exp(u):.1f})" for u in (0, 0.25, 0.5, 0.75, 1))
print(f"figure, curve v = e^u in px (1 across = 200 px, 1 up = 70 px): {pts}")
print(f"mistake, plus sign instead of minus: {bx + lx:.6f}, not 1")
print(f"mistake, boundary term alone: {bx:.6f}, not 1")
step = lambda x: 1.0 if x >= 1.0 else 0.0              # v jumps from 0 to 1 at x = 1
vdash = lambda x: (step(x + 1e-6) - step(x - 1e-6)) / 2e-6
left = simpson(lambda x: x * vdash(x), 0.0, 3.0, 1000)  # no node lies within 1e-6 of 1
right = (3.0 * step(3.0) - 0.0 * step(0.0)) - simpson(step, 1.0, 3.0, 1000)  # v is 0 before 1
print(f"mistake, v with a jump at 1 on 0..3: left side {left:.6f}, right side {right:.6f}")
J20 = E - 1.0
for n in range(1, 21):
    J20 = E - n * J20
s20 = simpson(lambda x: x ** 20 * math.exp(x), 0.0, 1.0, 256)
print(f"mistake, reduction run to J_20 in floating point: {J20:.6f}; Simpson {s20:.6f}")
assert abs((bx - lx) - simpson(xex, 0.0, 1.0, 128)) < 1e-8          # road one against road two
assert abs((bl - ll) - simpson(math.log, 1.0, E, 128)) < 1e-8
assert all(abs(j - se) < 1e-8 and abs(j - sl) < 1e-8 for j, se, sl in rows)
assert abs((right - left) - 1.0) < 1e-6 and abs(J20 - s20) > 1.0   # the breaks are real
print("ALL CHECKS PASS")
