# Mittag-Leffler's theorem: the check behind the card.  Python standard library
# only.  A row of charged wires sits at every whole number n; the wire at n adds
# 1/(z - n) to the field at z.  The sum diverges until each term has its value
# at 0 subtracted; then it is pi cot(pi z), and its derivative gives pi^2/6.
import math
from fractions import Fraction
N = 100000                                       # wires counted on each side
f6 = lambda x: f"{round(x, 6) + 0.0:.6f}"         # six decimals, never -0.000000
def cot_series(z, n=N):                          # road one: 1/z + sum of 2z/(z^2 - k^2), plus its tail
    return 1 / z + sum(2 * z / (z * z - k * k) for k in range(1, n + 1)) - 2 * z / (n + 0.5)
def sq_series(z, n=N):                           # sum over all k of 1/(z - k)^2, plus its tail
    return sum(1 / (z - k) ** 2 for k in range(-n, n + 1)) + 2 / (n + 0.5)
pcot = lambda z: math.pi * math.cos(math.pi * z) / math.sin(math.pi * z)   # road two: the closed form
tele = sum(Fraction(1, 1) / (Fraction(k * k) - Fraction(1, 4)) for k in range(1, 1001))   # road three
print(f"z = 0.5, midway: series {f6(cot_series(0.5))}; pi cot(pi z) {f6(pcot(0.5))}")
print("pairs n = 1, 2, 3 at z = 0.5, 1/(1/4 - n^2): " + ", ".join(f6(1 / (0.25 - k * k)) for k in (1, 2, 3)))
print(f"sum of 1/(n^2 - 1/4) to n = 1000, exact: {tele} = 2 - 1/1000.5 = {f6(float(tele))}")
assert tele == 2 - Fraction(2, 2001) and abs(cot_series(0.5)) < 1e-9
for z in (0.25, 0.1):
    print(f"z = {z}: series {f6(cot_series(z))}; pi cot(pi z) {f6(pcot(z))}")
    assert abs(cot_series(z) - pcot(z)) < 1e-9
y = 2.0                                         # straight above the wire at 0: z = 2i
above = 1 / y + sum(2 * y / (y * y + k * k) for k in range(1, N + 1)) + 2 * y / (N + 0.5)
coth = math.pi * (math.exp(2 * math.pi * y) + 1) / (math.exp(2 * math.pi * y) - 1)
print(f"z = 2i: field -i x {f6(above)}; pi coth(2 pi) = {f6(coth)}; a flat sheet gives pi = {f6(math.pi)}")
assert abs(above - coth) < 1e-9
s2 = sq_series(0.25)
print(f"z = 0.25: sum of 1/(z - n)^2 {f6(s2)}; pi^2/sin^2(pi z) {f6((math.pi / math.sin(math.pi / 4)) ** 2)}")
print(f"one step along the row: cot series at 1.25 minus at 0.25 = {f6(cot_series(1.25) - cot_series(0.25))}")
assert abs(s2 - 2 * math.pi ** 2) < 1e-9 and abs(cot_series(1.25) - cot_series(0.25)) < 1e-6
basel = sum(1 / (k * k) for k in range(1, N + 1)) + 1 / (N + 0.5)
near0 = (math.pi / math.sin(math.pi * 1e-3)) ** 2 - 1e6
print(f"pi^2/sin^2(pi z) - 1/z^2 at z = 0.001: {f6(near0)}; pi^2/3 = {f6(math.pi ** 2 / 3)}")
print(f"sum of 1/n^2: {f6(basel)}; half of pi^2/3 = pi^2/6 = {f6(math.pi ** 2 / 6)}")
assert abs(near0 - math.pi ** 2 / 3) < 1e-4 and abs(basel - math.pi ** 2 / 6) < 1e-12
Ms = (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000)  # chart: wires n = -M ... 2M, lopsided
raw = [sum(1 / (0.25 - k) for k in range(-M, 2 * M + 1)) for M in Ms]
fix = [4 + sum(1 / (0.25 - k) + 1 / k for k in range(-M, 2 * M + 1) if k) for M in Ms]
print("chart, raw sum at z = 0.25, n = -M ... 2M: " + ", ".join(f"{v:.2f}" for v in raw))
print("chart, corrected sum, same wires: " + ", ".join(f"{v:.2f}" for v in fix))
assert abs(raw[-1] - (math.pi - math.log(2))) < 1e-3 and abs(fix[-1] - math.pi) < 1e-3
one = sum(1 / (0.25 - k) for k in range(0, 1001))
print(f"mistake, raw sum over n = 0 ... 1000 only: {f6(one)}; raw limit for n = -M ... 2M: "
      f"{f6(raw[-1])}, near pi - ln 2 = {f6(math.pi - math.log(2))}")
print(f"mistake, pi^2/3 read as the sum of 1/n^2: {f6(math.pi ** 2 / 3)}, not {f6(math.pi ** 2 / 6)}")
d0 = lambda K: sum(0.5 / (math.sqrt(k) * (0.5 - math.sqrt(k))) for k in range(1, K + 1))
d1 = lambda K: sum(0.25 / (k * (0.5 - math.sqrt(k))) for k in range(1, K + 1))
Ks = (1000, 10000, 100000)
print("poles at sqrt(k), z = 0.5, K = 1000, 10000, 100000: degree-0 fix "
      + ", ".join(f6(d0(K)) for K in Ks) + "; degree-1 fix " + ", ".join(f6(d1(K)) for K in Ks))
assert abs((d0(Ks[1]) - d0(Ks[2])) - 0.5 * math.log(10)) < 0.01 and abs(d1(Ks[1]) - d1(Ks[2])) < 0.005
print("ALL CHECKS PASS")
