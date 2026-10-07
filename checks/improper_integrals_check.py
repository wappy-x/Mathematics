# Improper integrals -- the check behind the card.  Standard library only:
# math.log and math.sqrt are primitives; every integral is our own Simpson sum.
# The tap pours 1/t^2 litres a minute from minute 1 on; its rival pours 1/t.
import math

def simpson(f, a, b, n=64):              # Simpson's rule, n strips (n even)
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))
    return s * h / 3

def blocks(f, k):                        # areas over [1,2], [2,4], ... k doubling blocks
    return [simpson(f, 2.0 ** j, 2.0 ** (j + 1)) for j in range(k)]

def fmt(xs, d=6): return ", ".join(f"{x:.{d}f}" for x in xs)
def sq(t): return 1 / (t * t)
def inv(t): return 1 / t

print(f"road 1, antiderivative 1 - 1/B: B = 10, 100, 1000 -> {fmt(1 - 1 / B for B in (10, 100, 1000))}")
b2, b1 = blocks(sq, 10), blocks(inv, 10)
print(f"road 2, Simpson on doubling blocks of 1/t^2: {fmt(b2[:4])}, ...")
print(f"  10 blocks, 1 to 1024: sum {sum(b2):.6f}; 1 - 1/1024 = {1 - 1 / 1024:.6f}")
assert all(abs(sum(b2[:k]) - (1 - 2.0 ** -k)) < 1e-7 for k in range(1, 11))
print(f"1/t, same blocks: {fmt(b1[:4])}, ...; ln 2 = {math.log(2):.6f}")
print(f"  10 blocks, 1 to 1024: sum {sum(b1):.6f}; ln 1024 = {math.log(1024):.6f}")
assert all(abs(x - math.log(2)) < 1e-7 for x in b1)
run2 = [0.0] + [sum(b2[:k]) for k in range(1, 11)]
run1 = [0.0] + [sum(b1[:k]) for k in range(1, 11)]
print(f"chart, 1/t^2 totals at B = 1, 2, 4, ..., 1024: [{fmt(run2, 2)}]")
print(f"chart, 1/t totals at the same B: [{fmt(run1, 2)}]")
print(f"within 0.001 of 1: tail 1/B at B = 999 is {1 / 999:.6f}, at B = 1000 {1 / 1000:.6f}")
ps = (1.5, 2, 3)
pt = [sum(blocks(lambda t: t ** -p, 60)) for p in ps]
print(f"p-test at infinity, p = 1.5, 2, 3: 60 blocks {fmt(pt)}; 1/(p - 1) = {fmt(1 / (p - 1) for p in ps)}")
assert all(abs(x - 1 / (p - 1)) < 1e-6 for x, p in zip(pt, ps))
spk = [sum(simpson(lambda t: t ** -0.5, 2.0 ** -(j + 1), 2.0 ** -j) for j in range(k)) for k in (20, 40)]
print(f"spike 1/sqrt(t) on [s, 1]: 2 - 2 sqrt(s) at s = 0.01, 0.0001, 0.000001 -> "
      f"{fmt(2 - 2 * math.sqrt(s) for s in (0.01, 1e-4, 1e-6))}")
print(f"  Simpson on halving blocks: 20 blocks {spk[0]:.6f}, 40 blocks {spk[1]:.6f}; "
      f"formula {2 - 2 * 2.0 ** -10:.6f}, {2 - 2 * 2.0 ** -20:.6f}")
cmp = sum(blocks(lambda t: 1 / (t * t + t), 40))
print(f"comparison, 1/(t^2 + t) below 1/t^2: 40 blocks {cmp:.6f}, under the cap 1; "
      f"partial fractions give ln 2 = {math.log(2):.6f}")
assert abs(spk[1] - (2 - 2 * 2.0 ** -20)) < 1e-7 and abs(cmp - math.log(2)) < 1e-7
big = [2 * math.sqrt(B) - 2 for B in (100, 10000)]
print(f"comparison, 1/sqrt(t) above 1/t from 1: totals {fmt(big)} at B = 100, 10000")
print(f"break 1, stop at B = 100 and call it done: {1 - 1 / 100:.6f}, missing tail {1 / 100:.6f}")
print(f"break 2, -1/t is below 1/t^2 yet its totals are {fmt(-math.log(B) for B in (1e3, 1e6))} "
      f"at B = 1000, 1000000")
print(f"break 3, 1/t on [-1, 1]: gaps 0.01 and 0.01 sum {math.log(0.01) - math.log(0.01):.6f}; "
      f"gaps 0.01 and 0.02 sum {math.log(0.01) - math.log(0.02):.6f}")
print(f"break 4, -1/t across 0 for 1/t^2 on [-1, 1] gives {-1 / 1 - (-1 / -1):.0f}; "
      f"from 1/1024 to 1 alone {sum(simpson(sq, 2.0 ** -(j + 1), 2.0 ** -j) for j in range(10)):.2f}")
print("ALL CHECKS PASS")
