# The logistic map x -> r x (1 - x) and period doubling.  Standard library only.
# Road one: algebra (quadratic formula, chain rule).  Road two: iterate and solve numerically.
from math import sqrt, floor
def f(r, x): return r * x * (1 - x)
def settle(r, x=0.2, n=2000):            # iterate n times from x
    for _ in range(n): x = f(r, x)
    return x
def mult(r, p):                          # multiplier of the p-cycle: land on it, polish by Newton
    x = settle(r, 0.5, 3000)
    for _ in range(40):
        y, d = x, 1.0
        for _ in range(p): d, y = d * r * (1 - 2 * y), f(r, y)
        x -= (y - x) / (d - 1)
    return d
def onset(p, lo, hi):                    # bisection: where the p-cycle's multiplier hits -1
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if mult(mid, p) > -1 else (lo, mid)
    return (lo + hi) / 2
def sup(p, r):                           # Newton in r: the p-cycle passes through x = 1/2
    for _ in range(50):
        x, dx = 0.5, 0.0
        for _ in range(p): x, dx = f(r, x), x * (1 - x) + r * (1 - 2 * x) * dx
        r -= (x - 0.5) / dx
    return r
def cyc2(r):                             # the quadratic formula on the period-2 factor
    s = sqrt((r + 1) * (r - 3))
    return (r + 1 - s) / (2 * r), (r + 1 + s) / (2 * r)
def fm(v, d=6): return " ".join(f"{x:.{d}f}" for x in v)
r = 3.2; lo, hi = cyc2(r); a, b = sorted((settle(r), settle(r, 0.2, 2001)))
chain = r * (1 - 2 * a) * r * (1 - 2 * b)
print(f"r = 3.2: fixed point 1 - 1/r = {1 - 1 / r:.6f}, slope 2 - r = {2 - r:.6f}, so it repels")
print(f"2-cycle by the quadratic formula: (r+1)(r-3) = {(r + 1) * (r - 3):.6f}, {lo:.6f} and {hi:.6f}; sum {lo + hi:.6f}, product {lo * hi:.6f}")
print(f"2-cycle by iterating from 0.2 for 2000 steps: {a:.6f} and {b:.6f}")
print(f"multiplier, chain rule on the orbit: {r * (1 - 2 * a):.6f} x {r * (1 - 2 * b):.6f} = {chain:.6f}; by 4 + 2r - r^2: {4 + 2 * r - r * r:.6f}")
house = [sorted({round(settle(q, 0.2, 2000 + i), 6) for i in range(64)}) for q in (2.8, 3.5, 3.9)]
print(f"house example, x0 = 0.2, after 2000 steps: r = 2.8 -> {fm(house[0])} | r = 3.5 -> {fm(house[1])} | r = 3.9 -> {len(house[2])} different values in 64 steps")
R = [2.0, sup(2, 3.2)]
for k in range(2, 9):                    # next guess: the last gap shrunk by the last measured ratio
    R.append(sup(2 ** k, R[-1] + (R[-1] - R[-2]) / (4.0 if k == 2 else (R[-2] - R[-3]) / (R[-1] - R[-2]))))
B = [3.0] + [onset(2 ** k, R[k], R[k + 1]) for k in range(1, 6)]
db = [(B[i] - B[i - 1]) / (B[i + 1] - B[i]) for i in range(1, len(B) - 1)]
ds = [(R[i] - R[i - 1]) / (R[i + 1] - R[i]) for i in range(1, len(R) - 1)]
inf_b, inf_s = B[-1] + (B[-1] - B[-2]) / (db[-1] - 1), R[-1] + (R[-1] - R[-2]) / (ds[-1] - 1)
print(f"period-4 onset: bisection on the multiplier {B[1]:.6f}; 1 + sqrt(6) = {1 + sqrt(6):.6f}")
print(f"doublings, multiplier reaches -1: {fm(B)}\n  gap ratios: {fm(db, 4)}")
print(f"superstable, cycle through 1/2: {fm(R)}\n  gap ratios: {fm(ds, 4)}")
print(f"pile-up point extrapolated: from doublings {inf_b:.6f}, from superstable {inf_s:.6f}")
print(f"mistake 1, one slope for the whole cycle: f'({hi:.6f}) = {r * (1 - 2 * hi):.6f}")
m, q = cyc2(3.5), 2.8
print(f"mistake 2, the 2-cycle at r = 3.5: {m[0]:.6f} and {m[1]:.6f}, multiplier {3.5 * (1 - 2 * m[0]) * 3.5 * (1 - 2 * m[1]):.6f}")
print(f"mistake 3, r = 2.8: (r+1)(r-3) = {(q + 1) * (q - 3):.6f}, no real 2-cycle")
print(f"figure, marks at px x: 3.449490 -> {40 + 250 * (B[1] - 2.8):.1f}, 3.569946 -> {40 + 250 * (inf_b - 2.8):.1f}")
cols = [f"{40 + 10 * k}:" + "/".join(str(y) for y in sorted({floor(200 - 180 * settle(2.8 + 0.04 * k, 0.2, 2000 + i) + 0.5) for i in range(32)})) for k in range(31)]
print("figure, dots px x:y " + " ".join(cols))
assert max(abs(lo - a), abs(hi - b)) < 1e-9             # formula against iteration
assert abs(chain - (4 + 2 * r - r * r)) < 1e-9          # chain rule on the orbit against algebra
assert abs(B[1] - (1 + sqrt(6))) < 1e-9                 # bisection against closed form
assert abs(inf_b - inf_s) < 1e-5 and abs(db[-1] - ds[-1]) < 1e-3   # two sequences, one limit
print("ALL CHECKS PASS")
