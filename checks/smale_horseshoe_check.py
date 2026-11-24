# The Smale horseshoe -- the check behind the card.  Only math.log is imported.
# f stretches the unit square 3 times up, squeezes it to 1/3 across and folds:
# bottom third (x, y) -> (x/3, 3y); top third -> (1 - x/3, 3 - 3y); middle leaves.
# Points are exact: whole numbers over whole-number denominators.
import math
def fold(seq):                         # compose u -> 3u (symbol 0) or 3 - 3u (symbol 1)
    c, d = 1, 0
    for s in seq: c, d = (3 * c, 3 * d) if s == 0 else (-3 * c, 3 - 3 * d)
    return (d, 1 - c) if c < 1 else (-d, c - 1)      # u = d / (1 - c), denominator > 0
def solve(code): return fold(code[::-1]) + fold(code)   # road one: x from the past, y forward
def gcd(a, b): return gcd(b, a % b) if b else a
def red(a, b): return a // gcd(a, b), b // gcd(a, b)
def pt(c): X, qx, Y, qy = solve(c); return red(X, qx) + red(Y, qy)
def show(p): return f"({p[0]}/{p[1]}, {p[2]}/{p[3]})".replace("0/1", "0")
def codes(n): return [[(m >> i) & 1 for i in range(n)] for m in range(2 ** n)]
def run(X, qx, Y, qy, n):              # road two: the true map n times; None if it leaves
    X, top = X * 3 ** n, qx * 3 ** n   # x kept over qx * 3^n, so x/3 stays whole
    for _ in range(n):
        if 3 * Y <= qy: X, Y = X // 3, 3 * Y
        elif 3 * Y >= 2 * qy: X, Y = top - X // 3, 3 * qy - 3 * Y
        else: return None
    return (X // 3 ** n if X % 3 ** n == 0 else -1), Y

by_code = [{pt(c) for c in codes(n)} for n in range(1, 6)]   # the points themselves
brute = []
for n in range(1, 6):
    qs = (3 ** n - 1, 3 ** n + 1)
    brute.append({red(X, qx) + red(Y, qy) for qx in qs for qy in qs for X in range(qx + 1)
                      for Y in range(qy + 1) if run(X, qx, Y, qy, n) == (X, Y)})
exact = []                             # points of exact period n: drop those of smaller period
for n in range(1, 6): exact.append(len(by_code[n - 1]) - sum(exact[d - 1] for d in range(1, n) if n % d == 0))
cells = [sum(run(0, 1, 2 * m + 1, 2 * 3 ** k, k) is not None for m in range(3 ** k)) for k in range(1, 6)]
word = [int(ch) for ch in "0000100110101111"]          # every 4-symbol block once, cyclically
windows = {tuple((word * 2)[i:i + 4]) for i in range(16)}
squares = {(9 * X // qx, 9 * Y // qy) for i in range(16) for X, qx, Y, qy in [solve(word[i:] + word[:i])]}
boxes = len({(243 * X // qx, 243 * Y // qy) for X, qx, Y, qy in map(solve, codes(10))})   # period-10 points, side 1/243
x, y, steps = 0.9, 0.3, 0              # the period-2 point (9/10, 3/10), in floating point
while (3 * y <= 1 or 3 * y >= 2) and steps < 1000:
    x, y, steps = *((x / 3, 3 * y) if 3 * y <= 1 else (1 - x / 3, 3 - 3 * y)), steps + 1
two, dim = sorted({pt(c) for c in codes(2)}), math.log(2) / math.log(3)
print("fixed points (symbols 0, 1):", show(pt([0])), show(pt([1])))
print("points fixed by f^2:", *map(show, two), "; f sends", show(pt([0, 1])), "to", show(pt([1, 0])))
print("points fixed by f^n, n = 1..5, solving each block of symbols:", *map(len, by_code))
print("the same, running f on every fraction over 3^n - 1 or 3^n + 1:", *map(len, brute))
print("exact period n, n = 1..5:", *exact, "; cycles:", *(e // n for n, e in enumerate(exact, 1)))
print("strips of height 1/3^k kept for k steps, k = 1..5:", *cells)
print("height kept after k steps, k = 1..5:", *(f"{(2 / 3) ** k:.4f}" for k in range(1, 6)), f"; k = 10: {(2 / 3) ** 10:.4f}")
print(f"dimension across or up: log 2 / log 3 = {dim:.4f}; whole set log 4 / log 3 = {math.log(4) / math.log(3):.4f}")
print(f"box count, level 5: log {cells[4]} / log 243 = {math.log(cells[4], 243):.4f}; squares log {boxes} / log 243 = {math.log(boxes, 243):.4f}")
print(f"period-16 orbit of 0000100110101111: 4-blocks seen {len(windows)}, 1/9 squares visited {len(squares)}")
print(f"stretch rate per step: up ln 3 = {math.log(3):.4f}, across {-math.log(3):.4f}")
print(f"logistic map at r = 3.9 tops out at {3.9 / 4:.3f}, short of 1")
print(f"mistake 1, one direction taken for the whole set: {dim:.4f}, not {2 * dim:.4f}")
print(f"mistake 2, cycles counted for points at n = 4: {exact[3] // 4}, not {len(by_code[3])}")
print(f"mistake 3, (9/10, 3/10) iterated in floating point falls into the gap after {steps} steps")
assert by_code == brute and [len(s) for s in brute] == [2 ** n for n in range(1, 6)]  # same points, 2^n
assert two == sorted([(0, 1, 0, 1), (3, 4, 3, 4), (9, 10, 3, 10), (3, 10, 9, 10)])
assert cells == [2 ** k for k in range(1, 6)] and abs(math.log(boxes, 243) - math.log(4, 3)) < 1e-12
assert len(windows) == len(squares) == 16 and exact == [2, 2, 6, 12, 30]
print("ALL CHECKS PASS")
