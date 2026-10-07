# Powers and roots -- the check behind the card.  Standard library only.
# A spinner with 8 sectors (the 8th roots of unity), the cube roots of 8, the
# fourth roots of -16.  Road one is de Moivre in polar form.  Road two uses no
# angles: repeated multiplication for powers, Newton's method for roots.
import math

def fmt(z):
    re, im = round(z.real, 6) + 0.0, round(z.imag, 6) + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

def power(z, n):                  # road two for powers: multiply n times
    out = 1 + 0j
    for _ in range(n):
        out *= z
    return out
def polar(z): return math.sqrt(z.real ** 2 + z.imag ** 2), math.atan2(z.imag, z.real)
def turn(r, t): return complex(r * math.cos(t), r * math.sin(t))
def de_moivre(z, n): r, t = polar(z); return turn(r ** n, n * t)   # length^n, angle x n
def roots(c, n):                  # road one: n-th root of the length, angle (t + 2 pi k) / n
    r, t = polar(c)
    return [turn(r ** (1 / n), (t + 2 * math.pi * k) / n) for k in range(n)]

def newton(c, n):                 # road two: Newton's method from every grid point but 0
    found = []
    for z in (complex(x, y) for x in range(-3, 4) for y in range(-3, 4) if x or y):
        for _ in range(80):
            z -= (power(z, n) - c) / (n * power(z, n - 1))
        if abs(power(z, n) - c) < 1e-9 and all(abs(z - f) > 1e-6 for f in found):
            found.append(z)
    return found

def gap(a, b): return max(min(abs(x - y) for y in b) for x in a)
def reach(z): return len({fmt(power(z, k)) for k in range(8)})
def show(zs): return ", ".join(fmt(z) for z in zs)

spin, cube, quart = roots(1, 8), roots(8, 3), roots(-16, 4)
w, a, b, g = spin[1], complex(-1, math.sqrt(3)), complex(math.sqrt(2), math.sqrt(2)), 1 + 1j
px = lambda zs, s: " ".join(f"({180 + s * z.real:.1f}, {120 - s * z.imag:.1f})" for z in zs)
print(f"figure, spinner, 90 px per unit, centre (180, 120): {px(spin, 90)}")
print(f"figure, radius 2, 45 px per unit: cube roots of 8 {px(cube, 45)}; fourth roots of -16 {px(quart, 45)}")
print(f"spinner omega = {fmt(w)}; omega^8 by 8 multiplications = {fmt(power(w, 8))}")
print(f"omega^0 to omega^7: {show(power(w, k) for k in range(8))}")
print(f"sum of the 8 sectors = {fmt(sum(spin))}; by (1 - omega^8)/(1 - omega) = {fmt((1 - power(w, 8)) / (1 - w))}")
print(f"powers of omega^3 reach {reach(power(w, 3))} sectors; powers of omega^2 reach {reach(power(w, 2))}")
for z, n in ((a, 3), (b, 4), (g, 10)):
    print(f"({fmt(z)})^{n}: de Moivre = {fmt(de_moivre(z, n))}; multiplied out = {fmt(power(z, n))}")
found = {n: newton(complex(c), n) for c, n in ((8, 3), (-16, 4), (1, 8))}
for c, n, rs in ((8, 3, cube), (-16, 4, quart), (1, 8, spin)):
    print(f"z^{n} = {c}: angles {[round(math.degrees(polar(z)[1]) % 360, 6) for z in rs]} deg; Newton finds "
          f"{len(found[n])}, same points: {'yes' if gap(rs, found[n]) < 1e-9 else 'no'}; sum = {fmt(sum(rs))}")
print(f"cube roots of 8: {show(cube)}; fourth roots of -16: {show(quart)}")
print(f"mistake 1, k = 0 only: 1 cube root of 8, {fmt(cube[0])}; misses {len(cube) - 1}")
print(f"mistake 2, length divided by 3, not cube-rooted: {8 / 3:.6f}, cubed = {(8 / 3) ** 3:.6f}, not 8")
print(f"mistake 3, -16 read at angle 0: {fmt(roots(16, 4)[0])} to the 4th = {fmt(power(roots(16, 4)[0], 4))}, not -16")
print(f"mistake 4, angle x 4 but length kept: {fmt(turn(2, 4 * polar(b)[1]))}, not {fmt(power(b, 4))}")
assert all(abs(power(w, k) - spin[k]) < 1e-12 for k in range(8))       # multiply vs formula
assert all(abs(de_moivre(z, n) - power(z, n)) < 1e-11 for z, n in ((a, 3), (b, 4), (g, 10)))
assert all(len(found[n]) == n and gap(roots(c, n), found[n]) < 1e-9 for c, n in ((8, 3), (-16, 4), (1, 8)))
assert abs(sum(spin)) < 1e-12 and abs(sum(cube)) < 1e-12 and abs(sum(quart)) < 1e-12
print("ALL CHECKS PASS")
