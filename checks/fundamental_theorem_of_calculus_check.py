# Fundamental theorem of calculus -- the check behind the card.  Standard
# library only: math.sin and math.cos are primitives, every sum is our own.
# The tank: water flows in at f(t) = 3 + 2t litres per minute for 10 minutes.
import math

def f(t): return 3 + 2 * t               # the rate, litres per minute
def G(t): return 3 * t + t * t           # a guessed antiderivative: G'(t) = f(t)

def rsum(g, a, b, n, at):                # n rectangles; at = 0 left, 0.5 mid, 1 right
    h = (b - a) / n
    return sum(g(a + (k + at) * h) for k in range(n)) * h

def A(x): return rsum(f, 0, x, 1000, 0.5)  # litres in by minute x, from sums alone
def ints(xs): return "[" + ", ".join(f"{x:.0f}" for x in xs) + "]"

exact = G(10) - G(0)
for n in (10, 100, 1000):
    lo, hi = rsum(f, 0, 10, n, 0), rsum(f, 0, 10, n, 1)
    print(f"{n} strips: left sum {lo:.6f}, right sum {hi:.6f}, gap {hi - lo:.6f}")
    assert lo < exact < hi and abs((hi - lo) - 200 / n) < 1e-9   # sums trap G's answer
print(f"antiderivative road: G(10) - G(0) = {G(10):.0f} - {G(0):.0f} = {exact:.0f}")
steps = [G(k) - G(k - 1) for k in range(1, 11)]
mids = [f(k - 0.5) for k in range(1, 11)]
print(f"minute by minute, G(k) - G(k-1): {ints(steps)}, total {sum(steps):.0f}")
print(f"rate at each half minute, f(k - 0.5): {ints(mids)}, total {sum(mids):.0f}")
assert all(abs(s - m) < 1e-12 for s, m in zip(steps, mids))  # mean value points found
print(f"level G(t), t = 0..10: {ints(G(k) for k in range(11))}")
print(f"one-minute left rectangles, running: {ints(rsum(f, 0, k, k, 0) if k else 0 for k in range(11))}")
qs = [(A(4 + h) - A(4)) / h for h in (1, 0.1, 0.01)]
print(f"slope of the level at t = 4, from sums: h = 1 {qs[0]:.4f}, h = 0.1 {qs[1]:.4f}, "
      f"h = 0.01 {qs[2]:.4f}; rate f(4) = {f(4):.0f}")
assert all(f(4) - 1e-9 <= q <= f(4 + h) + 1e-9 for q, h in zip(qs, (1, 0.1, 0.01)))
print(f"within 0.001 of 11: h = 0.0005 gives {(A(4.0005) - A(4)) / 0.0005:.4f}")
s = rsum(math.sin, 0, math.pi, 1000, 0.5)
print(f"second case, sin from 0 to pi: 1000 midpoint strips {s:.6f}; "
      f"-cos(pi) + cos(0) = {math.cos(0) - math.cos(math.pi):.6f}")
assert abs(s - (math.cos(0) - math.cos(math.pi))) < 1e-5
def fv(t): return 0 if t < 5 else 4      # valve opens at minute 5: a jump
def Av(x): return rsum(fv, 0, x, round(x * 1000), 0.5)
print(f"break 1, valve jumps at t = 5: slope from the left {(Av(5) - Av(4.9)) / 0.1:.3f}, "
      f"from the right {(Av(5.1) - Av(5)) / 0.1:.3f}")
blow = [rsum(lambda t: 1 / (t * t), -1, 1, n, 0.5) for n in (10, 100, 1000)]
print(f"break 2, 1/t^2 on [-1, 1]: -1/t gives {-1 / 1 - (-1 / -1):.0f}; midpoint sums "
      f"n = 10 {blow[0]:.1f}, n = 100 {blow[1]:.1f}, n = 1000 {blow[2]:.1f}")
print(f"break 3, minutes 2 to 10: G(10) alone {G(10):.0f}; G(10) - G(2) = {G(10) - G(2):.0f}; "
      f"sums {rsum(f, 2, 10, 1000, 0.5):.6f}")
px, py = (lambda t: 50 + 28 * t), (lambda r: 200 - 7 * r)
print(f"figure, rate line ({px(0):.0f}, {py(f(0)):.0f}) to ({px(10):.0f}, {py(f(10)):.0f}); "
      f"strip x {px(4):.0f} to {px(5):.0f}, top y {py(f(4)):.0f} to {py(f(5)):.0f}")
print("ALL CHECKS PASS")
