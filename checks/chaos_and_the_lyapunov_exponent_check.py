# The Lyapunov exponent of the logistic map x -> r x (1 - x): the check behind the card.
# Standard library only; math.log and math.sin are the only borrowed functions.
import math
f = lambda r, x: r * x * (1 - x)
fmt = lambda v: ", ".join(f"{u:.2f}" for u in v)

def lam(r, x=0.2, d0=1e-9, n=200000):     # road 1: mean of ln|f'| on one orbit
    for _ in range(1000):                  # road 2: a twin orbit d0 away, no derivative
        x = f(r, x)
    y, s1, s2, s3 = x + d0, 0.0, 0.0, 0.0
    for _ in range(n):
        s1, s3 = s1 + math.log(abs(r * (1 - 2 * x))), s3 + abs(r * (1 - 2 * x))
        x, y = f(r, x), f(r, y)
        s2 += math.log(abs(y - x) / d0)
        y = x + (d0 if y > x else -d0)      # pull the twin back to distance d0
    return s1 / n, s2 / n, s3 / n

def cross(r, x, d):                        # steps until two starts d apart differ by 0.5
    y, n = x + d, 0
    while abs(x - y) < 0.5 and n < 1000:
        x, y, n = f(r, x), f(r, y), n + 1
    return n

(l4, t4, mean4), (l39, t39, _) = lam(4.0), lam(3.9)
lo, hi = 0.0, math.pi / 2                  # bisection for theta with sin^2(theta) = 0.2
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if math.sin(mid) ** 2 < 0.2 else (lo, mid)
x, prod = 0.2, 1.0
for _ in range(20):
    prod, x = prod * abs(4 * (1 - 2 * x)), f(4.0, x)
x20, sin20 = x, math.sin(2 ** 20 * lo) ** 2
tele = 2 ** 20 * abs(math.sin(2 ** 21 * lo) / math.sin(2 * lo))
hor, gain = math.log(0.5 / 1e-10) / l39, math.log(1000) / l39
c10 = sorted(cross(3.9, (k + 0.5) / 1000, 1e-10) for k in range(1000))
m10, m13 = sum(c10) / 1000, sum(cross(3.9, (k + 0.5) / 1000, 1e-13) for k in range(1000)) / 1000
x, y, gap = 0.2, 0.2 + 1e-10, []
for n in range(61):
    gap += [math.log(abs(x - y)) / math.log(10)] if n % 5 == 0 else []
    x, y = f(3.9, x), f(3.9, y)
lr = [lam(2.8 + k / 10)[0] for k in range(13)]
print(f"r = 4.0: road 1, average of ln|f'| = {l4:.4f}; road 2, twin orbits = {t4:.4f}; ln 2 = {math.log(2):.4f}")
print(f"r = 3.9: road 1, average of ln|f'| = {l39:.4f}; road 2, twin orbits = {t39:.4f}; bits per step {l39 / math.log(2):.3f}")
print(f"r = 4.0, from 0.2: x20 by the map = {x20:.8f}; sin^2(2^20 theta) = {sin20:.8f}")
print(f"product of |f'| over 20 steps = {prod:.2f}; 2^20 |sin 2theta20 / sin 2theta0| = {tele:.2f}")
print(f"horizon at r = 3.9, gap 1e-10 to 0.5: ln(5e9) = {math.log(5e9):.2f}, / lambda = {hor:.2f} steps")
print(f"1000 starts, first step the gap reaches 0.5: median {(c10[499] + c10[500]) / 2:.0f}, mean {m10:.2f}, fewest {c10[0]}, most {c10[-1]}; from 0.2 alone {cross(3.9, 0.2, 1e-10)}")
print(f"gap 1e-13 instead: mean {m13:.2f}, {m13 - m10:.2f} steps gained; ln(1000) = {math.log(1000):.2f}, / lambda = {gain:.2f}")
print(f"settled: r = 2.8 gives {lr[0]:.4f}, ln 0.8 = {math.log(0.8):.4f}; r = 3.2 gives {lr[4]:.4f}, ln(0.16) / 2 = {math.log(0.16) / 2:.4f}; r = 3.5 gives {lr[7]:.4f}")
print(f"figure, lambda at r = 2.8, 2.9, ..., 4.0: {fmt(lr)}")
print(f"figure, log10 of the gap from 0.2 at steps 0, 5, ..., 60: {fmt(gap)}")
print(f"figure, prediction -10 + lambda n / ln 10: {fmt([-10 + l39 * 5 * k / math.log(10) for k in range(13)])}")
print(f"mistake 1, ln of the average |f'| at r = 4: ln {mean4:.4f} = {math.log(mean4):.4f}")
print(f"mistake 2, one step from 0.2 at r = 3.9: ln 2.34 = {math.log(2.34):.4f}, horizon {math.log(5e9) / math.log(2.34):.2f} steps")
print(f"mistake 3, start on the fixed point 0 at r = 4: {lam(4.0, 0.0)[0]:.4f} = ln 4")
assert abs(l39 - t39) < 0.01 and abs(l4 - t4) < 0.01         # two roads to lambda agree
assert abs(l4 - math.log(2)) < 0.005 and abs(lr[0] - math.log(0.8)) < 1e-6
assert abs(prod / tele - 1) < 1e-6 and abs(x20 - sin20) < 1e-6  # the sine-squared telescope
assert abs((c10[499] + c10[500]) / 2 - hor) < 1 and abs(m13 - m10 - gain) < 1
print("ALL CHECKS PASS")
