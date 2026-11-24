# The Mandelbrot set -- the check behind the card.  Standard library only.  f(z) = z*z + c,
# and c is in M when the orbit of 0 stays bounded.  Road one iterates the orbit; road two is
# the algebra of fixed points and 2-cycles; road three rescales the logistic map.
from math import cos, sin, pi
def orbit(c, z, n):                      # z and its next n images
    out = [z]
    for _ in range(n): out.append(out[-1] * out[-1] + c)
    return out
def escape(c, n=1000):                   # first step with |z| > 2, or 0 if none
    z = 0
    for k in range(1, n + 1):
        z = z * z + c
        if abs(z) > 2: return k
    return 0
def regrows(c):                          # 1 if the orbit passes 2, then fails to grow
    k = escape(c, 50)
    if k == 0: return 0
    rs = [abs(z) for z in orbit(c, orbit(c, 0, k)[-1], 6)]
    return int(any(b <= a for a, b in zip(rs, rs[1:])))
def f4(x): return f"{round(x, 4) + 0.0:.4f}"     # 4 decimals, no negative zero
def cx(z): return f"{f4(z.real)}{'-' if round(z.imag, 4) < 0 else '+'}{f4(abs(z.imag))}i"
def gi(a, b):                            # a whole-number point a + bi, written like -1+i
    s = {1: "i", -1: "-i"}.get(b, f"{b}i")
    return str(a) if b == 0 else s if a == 0 else f"{a}{'+' if b > 0 else ''}{s}"
def g(zs): return ", ".join(gi(int(z.real), int(z.imag)) for z in zs)
def card(lam): return lam / 2 - lam * lam / 4    # the cardioid: fixed point with multiplier lam
oi = orbit(1j, 0, 5); m_i = 4 * oi[2] * oi[3]   # 2-cycle multiplier: f' = 2z at both points
print(f"house c = -1: orbit of 0 is {g(orbit(-1, 0, 4))}; orbit of 2 is {g(orbit(-1, 2, 3))}")
print(f"c = i: orbit of 0 is {g(oi)}: a 2-cycle, so i is in M")
print(f"c = i: cycle multiplier 4(-1+i)(-i) = {g([m_i])}, size {f4(abs(m_i))}; |c + 1| = {f4(abs(1j + 1))}")
print(f"c = 1: orbit of 0 is {g(orbit(1, 0, 4))}; first |z| > 2 at step {escape(1)}")
print(f"cardioid: lambda = 1 gives c = {f4(card(1))}, lambda = -1 gives c = {f4(card(-1))}, |c + 1| = {f4(abs(card(-1) + 1))}")
ps = [orbit(card(lam), 0, 400)[-1] for lam in (0.5, 0.5j)]
for name, lam, p in (("0.5", 0.5, ps[0]), ("0.5i", 0.5j, ps[1])):
    print(f"lambda = {name}: c = {cx(card(lam))}, orbit of 0 settles at {cx(p)}, measured 2z = {cx(2 * p)}")
c2 = -1.1; a = orbit(c2, 0, 400)[-1]; b = a * a + c2
print(f"c = {c2}: orbit settles on {f4(a)} and {f4(b)}; 4ab = {f4(4 * a * b)}, formula 4(c + 1) = {f4(4 * (c2 + 1))}")
pts = [complex(x / 10, y / 10) for x in range(-30, 31) for y in range(-30, 31)]
held, regrew = sum(escape(c, 50) == 0 for c in pts if abs(c) > 2), sum(regrows(c) for c in pts)
print(f"grid of {len(pts)} c: with |c| > 2 and bounded {held}; passed 2 then failed to grow {regrew}")
ring = [complex(cos(2 * pi * k / 200), sin(2 * pi * k / 200)) for k in range(200)]
edge = sum(escape(c) > 0 for c in [card(0.99 * w) for w in ring] + [-1 + 0.24 * w for w in ring])
print(f"400 c just inside the cardioid and the disc, 1000 steps each: escaped {edge}")
r, xs, zs = 3.2, [0.5], orbit(card(3.2), 0, 50)
for _ in range(50): xs.append(r * xs[-1] * (1 - xs[-1]))
gap = max(abs(r * (0.5 - x) - z) for x, z in zip(xs, zs))
print(f"logistic r = 3.2 from x = 1/2, rescaled by z = r(1/2 - x): matches c = {f4(card(r))} for 50 steps: {'yes' if gap < 1e-9 else 'no'}")
print(f"slow escape: c = 0.26 first passes 2 at step {escape(0.26)}")
print(f"mistake, |z| >= 2 as escape: c = -2 has orbit {g(orbit(-2, 0, 4))}, never past 2: {'yes' if escape(-2) == 0 else 'no'}")
print(f"mistake, cardioid sign flipped: lambda = 1 gives c = {f4(1 / 2 + 1 / 4)}, orbit {', '.join(f4(z) for z in orbit(0.75, 0, 3))}, out at step {escape(0.75)}")
print(f"mistake, disc |c + 1| < 1: c = -1.9 gets 2-cycle multiplier 4(c + 1) = {f4(4 * (-1.9 + 1))}")
print(f"figure, cusp {f4(card(1))}, back {f4(card(-1))}, disc centre -1 radius {f4(0.25)}, points i 1 -1 -2, 100 px per unit")
assert oi[2] == oi[4] == -1 + 1j and oi[3] == oi[5] == -1j and escape(1) == 3    # the orbits by hand
assert abs(2 * ps[0] - 0.5) < 1e-9 and abs(2 * ps[1] - 0.5j) < 1e-9          # iteration meets lambda
assert abs(4 * a * b - 4 * (c2 + 1)) < 1e-9                                    # iteration meets 4(c + 1)
assert held == 0 and regrew == 0 and edge == 0 and escape(card(-1)) == 0       # the radius-2 theorems
assert gap < 1e-9                                                              # logistic road agrees
print("ALL CHECKS PASS")
