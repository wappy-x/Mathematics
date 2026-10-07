# Euler's formula -- the check behind the card.  Standard library only.
# Road one: e^z summed from its own power series, 1 + z + z^2/2! + ...
# Road two: cos and sin, the real functions, read off as a point on the circle.
# Road three: compounding, (1 + z/N)^N for large N, one multiply at a time.
import math

TERMS = 60                                   # enough for |z| < 8 to full precision

def exp_series(z, terms=TERMS):              # each term is the last one times z/n
    total, term = 0j, 1 + 0j
    for n in range(1, terms + 1):
        total += term
        term = term * z / n
    return total

def compound(z, steps):                      # (1 + z/N) multiplied in N times
    w = 1 + 0j
    for _ in range(steps):
        w *= 1 + z / steps
    return w

def show(w):                                 # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

theta = 2 * math.pi * 440 * 0.001            # the A440 arrow one millisecond on
road1 = exp_series(1j * theta)
road2 = complex(math.cos(theta), math.sin(theta))
half = exp_series(1j * math.pi)
z = math.log(2) + 1j * math.pi / 2
print(f"A440 at t = 0.001 s: theta = {theta:.6f} rad ({theta / (2 * math.pi):.2f} turns)")
print(f"series, {TERMS} terms:   {show(road1)}")
print(f"cos + i sin:        {show(road2)}")
print(f"shadow on the real axis: {road2.real:.6f}")
print(f"e^(i pi), series: {show(half)}")
print(f"e^(ln 2 + i pi/2), series: {show(exp_series(z))}")
print(f"e^(ln 2 + i pi/2 + 2 pi i), series: {show(exp_series(z + 2j * math.pi))}")
gaps = []
for n in (10, 1000, 100000):
    w = compound(1j * math.pi, n)
    gaps.append(abs(w + 1))
    print(f"compounding, N = {n}: {show(w)}, distance from -1 {gaps[-1]:.6f}")
for deg in (6, 12):
    print(f"series cut after degree {deg} at i pi: distance from -1 {abs(exp_series(1j * math.pi, deg + 1) + 1):.6f}")
print(f"mistake, degrees for radians: cos 180 + i sin 180 = {show(complex(math.cos(180), math.sin(180)))}")
wrong = sum(math.pi ** n / math.factorial(n) * (1j if n % 2 else 1) for n in range(TERMS))
print(f"mistake, i^2 = +1 in the series: {show(wrong)}")
print(f"mistake, e^(i 440 t) without 2 pi: {440 / (2 * math.pi):.6f} turns a second")
tip = (180 + 80 * road2.real, 120 - 80 * road2.imag)
print(f"figure, arrow tip ({tip[0]:.2f}, {tip[1]:.2f}), shadow foot ({tip[0]:.2f}, 120.00)")
walk = [exp_series(1j * math.pi, k) for k in range(1, 9)]
print("figure, partial sums " + " ".join(f"({210 + 36 * s.real:.1f},{140 - 36 * s.imag:.1f})" for s in walk))
assert abs(road1 - road2) < 1e-12 and abs(half - complex(math.cos(math.pi), math.sin(math.pi))) < 1e-12
assert abs(exp_series(z) - 2 * complex(math.cos(math.pi / 2), math.sin(math.pi / 2))) < 1e-12
assert gaps[0] > gaps[1] > gaps[2] and gaps[2] < math.pi ** 2 / 100000
assert abs(exp_series(z + 2j * math.pi) - exp_series(z)) < 1e-12
print("ALL CHECKS PASS")
