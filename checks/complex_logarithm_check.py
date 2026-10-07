# The complex logarithm -- the check behind the card.  Standard library only.
# Road one: the formula, ln|z| + i(atan2(y, x) + 2 pi k), one value per floor k.
# Road two: drive the ramp.  From 1, add up each small step divided by the
# position there: a sum of small relative changes that never calls atan2.
import math

def log_floor(z, k=0):                        # ln|z| + i(Arg z + 2 pi k); k = 0 is Log
    return complex(math.log(math.hypot(z.real, z.imag)), math.atan2(z.imag, z.real) + 2 * math.pi * k)

def exp(w):                                   # e^w = e^u (cos v + i sin v)
    return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))

def drive(turn, steps=100000):                # from 1 round the unit circle by 'turn' radians
    total, prev = 0j, 1 + 0j
    for n in range(1, steps + 1):
        here = exp(1j * turn * n / steps)
        total += (here - prev) / ((here + prev) / 2)    # step over mean position
        prev = here
    return total

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

pi, h = math.pi, 0.001
for k in (-1, 0, 1):
    w = log_floor(-1 + 0j, k)
    print(f"floor k = {k:2d}: log(-1) = {show(w)}, e^log = {show(exp(w))}")
ramps = {"half turn down (0 to -pi)": -pi, "half turn up (0 to pi)": pi,
         "one and a half turns up (0 to 3 pi)": 3 * pi, "one full turn (0 to 2 pi)": 2 * pi}
sums = {name: drive(t) for name, t in ramps.items()}
for name, s in sums.items():
    print(f"ramp, {name}: {show(s)}")
errs = [abs(drive(pi, n) - 1j * pi) for n in (10, 100, 1000)]
print("ramp error, half turn up, 10 / 100 / 1000 steps: " + " / ".join(f"{e:.6f}" for e in errs))
L = log_floor(-1 + 0j)
print(f"Log(-1) = {show(L)}; Log((-1)(-1)) = Log 1 = {show(log_floor(1 + 0j))}; 2 Log(-1) = {show(2 * L)}")
above, below = log_floor(complex(-1, h)), log_floor(complex(-1, -h))
print(f"just above the cut, Log(-1 + 0.001i) = {show(above)}")
print(f"just below the cut, Log(-1 - 0.001i) = {show(below)}; jump {abs(above - below):.6f}")
d_re = (log_floor(1j + h) - log_floor(1j - h)) / (2 * h)
d_im = (log_floor(1j + 1j * h) - log_floor(1j - 1j * h)) / (2j * h)
print(f"Log i = {show(log_floor(1j))}; slope at i, real step {show(d_re)}, imaginary step {show(d_im)}; 1/i = {show(1 / 1j)}")
wrong = complex(math.log(math.hypot(-1, h)), math.atan(h / -1))
print(f"mistake, atan(y/x) for the angle at -1 + 0.001i: {show(wrong)}")
print(f"mistake, slope of Log at -1 from below, step -0.001i: {show((below - L) / (-1j * h))}")
px = lambda z: f"({180 + 80 * z.real:.2f}, {120 - 80 * z.imag:.2f})"    # 80 units per 1, 0 at (180, 120)
print(f"figure, z-plane: 1 at {px(exp(0j))}, -1 at {px(exp(L))}, arc tops {px(exp(1j * pi / 2))} and {px(exp(-1j * pi / 2))}")
print("figure, w-plane: dots at x = 180.00, y = " + ", ".join(f"{180 - 15 * log_floor(-1 + 0j, k).imag:.2f}" for k in (-1, 0, 1)))
assert all(abs(drive(pi * (2 * k + 1)) - log_floor(-1 + 0j, k)) < 1e-7 for k in (-1, 0, 1))
assert all(abs(exp(log_floor(-1 + 0j, k)) + 1) < 1e-12 for k in (-1, 0, 1))
assert abs(d_re - 1 / 1j) < 1e-6 and abs(d_im - 1 / 1j) < 1e-6
assert abs((2 * L - log_floor(1 + 0j)) - sums["one full turn (0 to 2 pi)"]) < 1e-7
print("ALL CHECKS PASS")
