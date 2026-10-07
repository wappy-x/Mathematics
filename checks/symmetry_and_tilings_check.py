# Symmetry and tilings: four counts, two roads each.  Standard library only; math gives cos, sin, atan2.
from math import cos, sin, atan2, radians, degrees
def turn(t): c, s = cos(radians(t)), sin(radians(t)); return (c, -s, s, c)          # R_theta
def flip(p): c, s = cos(radians(2 * p)), sin(radians(2 * p)); return (c, s, s, -c)  # F_phi
def mul(a, b):  # the 2 x 2 matrix a times b, entries row by row: b acts first, then a
    return (a[0]*b[0] + a[1]*b[2], a[0]*b[1] + a[1]*b[3], a[2]*b[0] + a[3]*b[2], a[2]*b[1] + a[3]*b[3])
def key(m): return tuple(round(v * 1e6) for v in m)
def imp(a, b): return b or not a
moves, todo = {key(turn(0)): turn(0)}, [turn(0)]         # road 1: close up R_60 and F_0
while todo:
    q = todo.pop()
    for m in (mul(turn(60), q), mul(flip(0), q)):
        if key(m) not in moves: moves[key(m)] = m; todo.append(m)
tipmaps = sum(1 for f in ([c // 6 ** i % 6 for i in range(6)] for c in range(6 ** 6))  # road 2: relabel tips
              if len(set(f)) == 6 and all((f[(i + 1) % 6] - f[i]) % 6 in (1, 5) for i in range(6)))
W, found, rules = 6, set(), set()                         # strips: 6 cells long, 2 rows, repeating
def img(S, fx, fy): return frozenset((fx(x) % W, fy(y)) for x, y in S)
def has(S, fx, fy, cs): return any(img(S, lambda x: fx(x, c), fy) == S for c in cs)
same, over, slide, mirror = (lambda y: y), (lambda y: 1 - y), (lambda x, c: x + c), (lambda x, c: c - x)
for code in range(2 ** (2 * W)):                          # road 1: every strip, its symmetries read off
    S = frozenset((i % W, i // W) for i in range(2 * W) if code >> i & 1)
    p = min(d for d in (1, 2, 3, 6) if has(S, slide, same, [d]))
    found.add((has(S, mirror, same, range(W)), has(S, slide, over, [0]), has(S, mirror, over, range(W)),
               has(S, slide, over, [t for t in range(1, W) if t % p])))
for V, H, R, G in [tuple(bool(code >> i & 1) for i in range(4)) for code in range(16)]:  # road 2: rules
    if not (H and G) and imp(V and H, R) and imp(H and R, V) and imp(V and R, H or G) and imp(V and G, R) and imp(R and G, V):
        rules.add((V, H, R, G))
def name(k): return "".join(l for l, f in zip("VHRG", k) if f) or "-"
def pw(m, k): return m if k == 1 else mul(m, pw(m, k - 1))
def order(m): return next((k for k in range(1, 13) if pw(m, k) == (1, 0, 0, 1)), 0)
lattice = sorted({order((a, b, c, d)) for a in range(-2, 3) for b in range(-2, 3) for c in range(-2, 3)
                  for d in range(-2, 3) if a * d - b * c == 1} - {0})       # every whole-number turn matrix
trace = [n for n in range(1, 13) if abs(2 * cos(radians(360 / n)) - round(2 * cos(radians(360 / n)))) < 1e-9]
L, walls = 55440, []                                      # costs counted in 55440ths: whole numbers
pre, post = (lambda n: L * (n - 1) // n), (lambda n: L * (n - 1) // (2 * n))  # turn centre off / on mirrors
def bags(cost, budget, low=2):  # every multiset of turn orders >= low whose costs fit the budget
    return [((), 0)] + [((n,) + b, cost(n) + k) for n in range(low, 13) if cost(n) <= budget for b, k in bags(cost, budget - cost(n), n)]
for h, s, x, left in [(h, s, x, L * (2 - 2 * h - s - x)) for h in (0, 1) for s in (0, 1, 2) for x in (0, 1, 2) if 2 * h + s + x <= 2]:
    for a, ca in bags(pre, left):
        for b, cb in (bags(post, left - ca) if s == 1 else [((), 0)]):
            if ca + cb == left: walls.append("o" * h + "".join(map(str, a[::-1])) + "*" * s + "".join(map(str, b[::-1])) + "x" * x)
digits, top = sorted({int(ch) for w in walls for ch in w if ch.isdigit()}), [max([int(ch) for ch in w if ch.isdigit()] + [1]) for w in walls]
f60, f300 = (round(degrees(atan2(m[2], m[0]))) % 360 for m in (mul(flip(30), flip(0)), mul(flip(0), flip(30))))
turns = sum(1 for m in moves.values() if m[0] * m[3] - m[1] * m[2] > 0)       # a turn keeps the clockwise order
print(f"snowflake moves, closing up R_60 and F_0: {len(moves)} ({turns} turns, {len(moves) - turns} flips)",
      f"tip relabellings keeping neighbours, of 6^6 = {6 ** 6}: {tipmaps}",
      f"R_60 = ({turn(60)[0]:.4f}, {turn(60)[1]:.4f}; {turn(60)[2]:.4f}, {turn(60)[3]:.4f}), trace {turn(60)[0] + turn(60)[3]:.4f}",
      f"F_0 then F_30: turn by {f60} deg; F_30 then F_0: turn by {f300} deg",
      f"strip kinds from all {2 ** (2 * W)} strips: {len(found)}: {', '.join(sorted(map(name, found)))}",
      f"strip kinds from the rules, of 16 on-off lists: {len(rules)}: {', '.join(sorted(map(name, rules)))}", sep="\n")
print(f"turn orders of whole-number matrices: {lattice}; by the trace 2cos: {trace}",
      f"5-fold: 2cos(72 deg) = {2 * cos(radians(72)):.4f}, not whole", f"cost of 632 = {pre(6) / L:.4f} + {pre(3) / L:.4f} + {pre(2) / L:.4f} = {(pre(6) + pre(3) + pre(2)) / L:.4f}; of *632 = 1 + {post(6) / L:.4f} + {post(3) / L:.4f} + {post(2) / L:.4f} = {1 + (post(6) + post(3) + post(2)) / L:.4f}", sep="\n")
print(f"wall signatures costing exactly 2: {len(walls)}", "  " + " ".join(sorted(walls)),
      f"turn orders used: {digits}; count by largest turn: " + ", ".join(f"{n}: {top.count(n)}" for n in (1, 2, 3, 4, 6)),
      "figure, centre (130, 120), 1 mm = 90 units, tips " + " ".join(f"({130 + 90 * cos(radians(90 + 60 * k)):.2f}, {120 - 90 * sin(radians(90 + 60 * k)):.2f})" for k in range(6)), sep="\n")
assert len(moves) == tipmaps == 12                         # matrices against relabelled tips
assert found == rules and len(rules) == 7                  # brute force against the rules
assert lattice == trace == [1, 2, 3, 4, 6]                 # whole-number matrices against the trace
assert len(walls) == 17 and digits == [n for n in lattice if n > 1]   # costs against the lattice
print("ALL CHECKS PASS")
