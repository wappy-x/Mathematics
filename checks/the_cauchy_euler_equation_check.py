# The Cauchy-Euler equation -- the check behind the card.  Standard library
# only.  A thick steel pipe: bore 50 mm, outside 100 mm, oil at 20 MPa inside.
# The wall's outward shift y (um) at distance x (mm) from the axis obeys
# x^2 y'' + x y' - y = 0.  Road one: the powers x and 1/x, fitted to the two
# pressures.  Road two: Euler's small steps shot across the wall, no powers.
import math
E, NU, P, XI, XO = 200000.0, 0.3, 20.0, 50.0, 100.0   # MPa, ratio, MPa, mm, mm
K = E / (1 - NU * NU) / 1000                           # MPa per um/mm of rate

def roots(a, b):                         # roots of r(r - 1) + a r + b = 0
    d = math.sqrt((a - 1) ** 2 - 4 * b)
    return (1 - a + d) / 2, (1 - a - d) / 2
def radial(y, v, x): return K * (v + NU * y / x)      # stress across the wall
def hoop(y, v, x): return K * (y / x + NU * v)        # stress around the wall
def resid(a, b, r, x=2.0, h=1e-3):       # x^r put into the equation, rates by differences, over x^r
    return (x * x * ((x + h) ** r - 2 * x ** r + (x - h) ** r) / h ** 2 + a * x * ((x + h) ** r - (x - h) ** r) / (2 * h) + b * x ** r) / x ** r

def euler(a, b, x, y, v, x1, n):         # step x^2 y'' + a x y' + b y = 0 to x1
    h = (x1 - x) / n
    for _ in range(n):
        y, v, x = y + h * v, v - h * (a * x * v + b * y) / (x * x), x + h
    return y, v

# road one: y = A x + B / x, radial stress -P at the bore and 0 outside
m = [[K * (1 + NU), -K * (1 - NU) / XI ** 2], [K * (1 + NU), -K * (1 - NU) / XO ** 2]]
det = m[0][0] * m[1][1] - m[0][1] * m[1][0]
A, B = -P * m[1][1] / det, P * m[1][0] / det
y = lambda x: A * x + B / x
dy = lambda x: A - B / x ** 2
print("indicial roots, a = 1, b = -1: %.0f and %.0f" % roots(1, -1))
print(f"steel K = {K * 1000:.0f} MPa; fitted amounts: A = {A:.5f} um per mm, B = {B:.2f} um mm")
print(f"shift, powers: bore {y(XI):.4f} um, outside {y(XO):.4f} um")
errs = []
for n in (100, 200, 400):                # road two: shoot from the bore
    f = lambda s: radial(*euler(1, -1, XI, s, -P / K - NU * s / XI, XO, n), XO)
    s = -f(0) * 10 / (f(10) - f(0))
    errs.append(s - y(XI))
    print(f"shift at bore, Euler shot, h = {(XO - XI) / n:.3f} mm: {s:.4f} um; error {errs[-1]:+.4f}")
print(f"error ratio when h halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f}")
lame = P * (XO ** 2 + XI ** 2) / (XO ** 2 - XI ** 2)
print(f"hoop stress at bore: from the shift {hoop(y(XI), dy(XI), XI):.2f} MPa; Lame's formula {lame:.2f} MPa")
print(f"radial stress: bore {radial(y(XI), dy(XI), XI):.2f} MPa, outside {round(radial(y(XO), dy(XO), XO), 9) + 0.0:.2f} MPa; hoop outside {hoop(y(XO), dy(XO), XO):.2f} MPa")
xs = [50, 60, 70, 80, 90, 100]
print("figure, x (mm):   ", " ".join(f"{x:5.0f}" for x in xs))
print("figure, y (um):   ", " ".join(f"{y(x):5.2f}" for x in xs))
print("figure, A x (um): ", " ".join(f"{A * x:5.2f}" for x in xs))
print("figure, B/x (um): ", " ".join(f"{B / x:5.2f}" for x in xs))
r1, r2 = roots(-1, 1)                    # second case: x^2 y'' - x y' + y = 0
yr = [euler(-1, 1, 1.0, 0.0, 1.0, 2.0, n)[0] for n in (100, 200, 400)]
print(f"repeated case a = -1, b = 1: roots {r1:.0f}, {r2:.0f}; x ln x at 2 = {2 * math.log(2):.6f}")
print("  Euler from y(1) = 0, y'(1) = 1, 100/200/400 steps:", " ".join(f"{v:.6f}" for v in yr))
rw = (-1 + math.sqrt(1 + 4)) / 2         # mistake: r^2 + a r + b = 0, a = 1, b = -1
print(f"mistake, r^2 + r - 1 = 0 gives r = {rw:.3f}: x^r leaves {resid(1, -1, rw):.3f} x^r")
print(f"mistake, thin-wall rule P x mean radius / thickness: {P * 75 / 50:.2f} MPa, not {lame:.2f}")
print(f"mistake, one power C x fitted to y(1) = 0: C = 0, so y(2) = {0.0 * 2:.6f}, not {2 * math.log(2):.6f}")
assert abs(errs[2]) < 0.1 and 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2
assert abs(hoop(y(XI), dy(XI), XI) - lame) < 1e-9 and abs(radial(y(XO), dy(XO), XO)) < 1e-9
assert abs(yr[2] - 2 * math.log(2)) < 0.005 and abs(yr[1] - 2 * math.log(2)) > abs(yr[2] - 2 * math.log(2))
assert max(abs(resid(1, -1, r)) + abs(resid(-1, 1, q)) for r, q in zip(roots(1, -1), roots(-1, 1))) < 1e-5 and resid(1, -1, rw) < -0.5
print("ALL CHECKS PASS")
