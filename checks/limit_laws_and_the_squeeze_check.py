# Limit laws and the squeeze -- the check behind the card.  Standard library
# only; math.sin is the one primitive.  h(x) = x^2 sin(1/x) heads for 0 as x
# heads for 0.  Road one: the squeeze bound x^2 picks the window sqrt(eps).
# Road two: a brute scan of h itself on that window, sharing no arithmetic.
import math

def h(x):
    return x * x * math.sin(1 / x)

def scan(fn, width, n=200000):          # every grid point with 0 < |x| < width
    xs = [width * k / n for k in range(1, n)]
    return [fn(s * x) for x in xs for s in (1, -1)]

for x in (0.1, 0.01, 0.001):
    print(f"x = {x}: h = {h(x):.8f}, bound x^2 = {x * x:.8f}")
worst = {}
for eps in (0.01, 0.001, 0.00001):
    delta = math.sqrt(eps)              # road one: x^2 < eps once |x| < sqrt(eps)
    worst[eps] = max(abs(v) for v in scan(h, delta))      # road two: look
    print(f"tolerance {eps:.6f}: window {delta:.6f}, largest |h| found {worst[eps]:.8f}")
sines = scan(lambda x: math.sin(1 / x), 0.001)
print(f"sin(1/x) for 0 < |x| < 0.001 reaches {max(sines):.6f} and {min(sines):.6f}")
peaks = [1 / (math.pi / 2 + n * math.pi) for n in range(1, 9)]  # sine is +1 or -1
by_sine = [h(x) for x in peaks]
by_sign = [(-1) ** n * x * x for n, x in zip(range(1, 9), peaks)]
print("chart x:                  " + ", ".join(f"{x:.4f}" for x in peaks))
print("chart h, thousandths:     " + ", ".join(f"{1000 * v:.2f}" for v in by_sine))
print("chart x^2, thousandths:   " + ", ".join(f"{1000 * x * x:.2f}" for x in peaks))
print("chart -x^2, thousandths:  " + ", ".join(f"{-1000 * x * x:.2f}" for x in peaks))
law = (0 + 5) / (0 + 2)                 # limits of the parts: h -> 0, x -> 0
direct = [(h(x) + 5) / (x + 2) for x in (0.01, 0.001, 0.000001)]
print(f"(h + 5)/(x + 2): laws give {law:.6f}; direct at 0.01, 0.001, 0.000001: "
      + ", ".join(f"{v:.6f}" for v in direct))
gaps = [abs(v - law) for v in direct]
print("gap from 2.5 at those three points: " + ", ".join(f"{g:.6f}" for g in gaps))
print(f"infinite limit: 1/x^2 at 0.001 is {1 / 0.001 ** 2:.0f}; 1/x at 0.001 and -0.001 is "
      f"{1 / 0.001:.0f} and {1 / -0.001:.0f}; at infinity: 1/x at 1000 is {1 / 1000:.6f}")
print(f"mistake, bounds -1 and 1 disagree: sin(1/x) at x = {peaks[7]:.4f} and {peaks[6]:.4f} "
      f"is {math.sin(1 / peaks[7]):.0f} and {math.sin(1 / peaks[6]):.0f}")
print(f"mistake, 0/0 at x = 0.001: x/x = {0.001 / 0.001:.0f}, x^2/x = {0.001 ** 2 / 0.001:.6f}, "
      f"x/x^2 = {0.001 / 0.001 ** 2:.0f}")
assert all(worst[e] < e for e in worst)                    # the squeeze window works
assert max(sines) > 0.999 and min(sines) < -0.999          # the factor never settles
assert all(abs(a - b) < 1e-12 for a, b in zip(by_sine, by_sign))
assert gaps[0] > gaps[1] > gaps[2] and gaps[2] < 0.00001  # looking agrees with laws
print("ALL CHECKS PASS")
