# Antiderivatives and path independence -- the check behind the card.  Standard library only.
# Road one: an antiderivative F with F' = f, read at the two ends of the path.
# Road two: the path itself, a trapezoid sum of f(z(t)) z'(t) over t from 0 to 1.
# For 1/z, road two meets log z carried step by step along the path.
import math

def integral(f, path, speed, n):              # trapezoid rule in the parameter t
    g = [f(path(k / n)) * speed(k / n) for k in range(n + 1)]
    return (sum(g) - (g[0] + g[-1]) / 2) / n

def segment(a, b):                             # straight from a to b; its velocity is b - a
    return (lambda t: a + (b - a) * t), (lambda t: b - a)

def arc(sweep):                                # unit circle from 1, turning through sweep radians
    point = lambda t: complex(math.cos(sweep * t), math.sin(sweep * t))
    return point, (lambda t: 1j * sweep * point(t))

def along(f, legs, n=2000): return sum(integral(f, *leg, n) for leg in legs)

def carried_log(path, n=1000):                 # ln|z| plus the angle swept, one small step at a time
    turn = sum(math.atan2((path((k + 1) / n) / path(k / n)).imag,
                          (path((k + 1) / n) / path(k / n)).real) for k in range(n))
    return complex(math.log(abs(path(1))) - math.log(abs(path(0))), turn)

def show(w):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

end = 1 + 1j
square, inverse, bar = (lambda z: z * z), (lambda z: 1 / z), (lambda z: z.conjugate())
F = end * end * end / 3
straight, broken = [segment(0, end)], [segment(0, 1), segment(1, end)]
errs = [abs(along(square, straight, n) - F) for n in (10, 100, 1000)]
s, b = along(square, straight), along(square, broken)
print(f"z^2 from 0 to 1 + i, antiderivative z^3/3 at the ends: {show(F)}")
print("straight path, trapezoid error at N = 10, 100, 1000: " + ", ".join(f"{e:.9f}" for e in errs))
print(f"straight path, N = 2000: {show(s)}")
print(f"broken path 0 -> 1 -> 1 + i, N = 2000: {show(b)}")
print(f"broken path legs, by the antiderivative: {show(1 / 3 + 0j)} and {show((end * end * end - 1) / 3)}")
tri = along(square, [segment(0, 2), segment(2, end), segment(end, 0)], 10000)
print(f"regatta triangle 0 -> 2 -> 1 + i -> 0, z^2, N = 10000 per leg: {show(tri)}")
loops = {n: along(lambda z: z ** n, [arc(2 * math.pi)], 64) for n in (-3, -2, -1, 0, 1, 2)}
others = max(abs(loops[n]) for n in loops if n != -1)
lap, low = carried_log(arc(2 * math.pi)[0]), carried_log(arc(-math.pi)[0])
up, down = along(inverse, [arc(math.pi)]), along(inverse, [arc(-math.pi)])
print(f"loop of 1/z round the unit circle, N = 64: {show(loops[-1])}")
print(f"largest loop of z^n for n = -3, -2, 0, 1, 2: {others:.6f}")
print(f"log z carried once round the unit circle: {show(lap)}")
print(f"1/z from 1 to -1: upper half {show(up)}, lower half {show(down)}")
print(f"log z carried along the lower half: {show(low)}")
print(f"mistake, principal Log(-1) - Log(1) on the lower half: {show(complex(0, math.atan2(0.0, -1.0)))}")
cs, cb = along(bar, straight), along(bar, broken)
print(f"mistake, z-bar: straight {show(cs)}, broken {show(cb)}")
print(f"figure, 0 at (110, 190), 1 at ({110 + 120 * 1}, 190), 1 + i at ({110 + 120 * 1}, {190 - 120 * 1})")
print(f"figure, circle centre (180, 120), radius 80, 1 at ({180 + 80}, 120), -1 at ({180 - 80}, 120)")
assert abs(s - F) < 1e-6 and abs(b - F) < 1e-6 and 99 < errs[0] / errs[1] < 101
assert abs(loops[-1] - lap) < 1e-9 and abs(loops[-1] - 2j * math.pi) < 1e-9
assert others < 1e-9 and abs(tri) < 1e-6 and abs(cb - cs - 1j) < 1e-9
assert abs(down - low) < 1e-9 and abs(up - down - 2j * math.pi) < 1e-9
print("ALL CHECKS PASS")
