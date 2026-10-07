# The Gaussian integral -- the check behind the card.  Standard library only;
# math supplies exp and sqrt as primitives, never pi.  Road one integrates
# e^(-x^2) by Simpson's rule; road two builds pi from Machin's arctan series
# and takes its root.  A grid over the disk checks the polar step without polar.
from math import exp, sqrt

def simpson(f, a, b, n=1200):             # n even: weights 1, 4, 2, 4, ..., 4, 1
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def arctan_inv(x):                        # arctan(1/x) from its own partial sums
    return sum((-1) ** k / ((2 * k + 1) * x ** (2 * k + 1)) for k in range(30))

def disk_by_grid(R, n=1000):              # squares whose centres lie in the disk
    h, tot = 2 * R / n, 0.0
    for i in range(n):
        x = -R + (i + 0.5) * h
        for j in range(n):
            y = -R + (j + 0.5) * h
            if x * x + y * y <= R * R:
                tot += exp(-x * x - y * y)
    return tot * h * h

g = lambda x: exp(-x * x)
PI = 16 * arctan_inv(5) - 4 * arctan_inv(239)
I = simpson(g, -6, 6)
print(f"pi by Machin's series: {PI:.12f}")
print(f"road 1, Simpson on [-6, 6], 1200 strips: I = {I:.12f}")
print(f"road 2, square root of the series pi:     {sqrt(PI):.12f}")
squeeze = []
for R in (1, 2, 3):
    lo, sq, hi = PI * (1 - exp(-R * R)), simpson(g, -R, R) ** 2, PI * (1 - exp(-2 * R * R))
    squeeze.append((lo, sq, hi))
    print(f"squeeze R = {R}: I_R = {sqrt(sq):.6f}; disk {lo:.6f} <= square {sq:.6f} <= disk {hi:.6f}")
for R in (2, 3):
    print(f"tails beyond R = {R}: actual {I - simpson(g, -R, R):.6f}, bound e^(-R^2)/R {exp(-R * R) / R:.6f}")
grid = disk_by_grid(1)
print(f"disk R = 1 by a 1000 x 1000 grid, no polar: {grid:.6f}; polar formula {PI * (1 - exp(-1)):.6f}")
root2pi = sqrt(2 * PI)
bell = lambda x: exp(-x * x / 2) / root2pi
print(f"bell: sqrt(2 pi) = {root2pi:.6f}; peak height 1/sqrt(2 pi) = {1 / root2pi:.6f}")
area = simpson(bell, -8, 8)
print(f"bell area by Simpson on [-8, 8]: {area:.9f}")
print("bell area within 1, 2, 3 of the centre: " + ", ".join(f"{simpson(bell, -k, k):.6f}" for k in (1, 2, 3)))
print("chart, bell height at x = -3, -2.5, ..., 3: " + ", ".join(f"{bell(k / 2):.2f}" for k in range(-6, 7)))
print(f"figure, centre (180, 120); 60 per unit; square 120 to 240; inner radius 60.00; outer radius {60 * sqrt(2):.2f} = 60 x {sqrt(2):.3f}")
print(f"mistake, drop r in the polar disk R = 1: {2 * PI * simpson(g, 0, 1):.6f}")
print(f"mistake, 1/sqrt(pi) in front of e^(-x^2/2): area {simpson(lambda x: exp(-x * x / 2), -8, 8) / sqrt(PI):.6f}")
print(f"mistake, a = 0: the strip [-10, 10] holds {simpson(lambda x: exp(0 * x * x), -10, 10):.6f}")
assert abs(I - sqrt(PI)) < 1e-10                       # two roads to root pi
assert all(lo <= sq <= hi for lo, sq, hi in squeeze)   # square trapped between disks
assert abs(grid - PI * (1 - exp(-1))) < 1e-3           # polar factor r, checked on a grid
assert abs(area - 1) < 1e-10                           # the bell's area is 1
print("ALL CHECKS PASS")
