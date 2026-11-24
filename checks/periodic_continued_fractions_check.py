# Periodic continued fractions -- the check behind the card.  Nothing is imported.  Road one: flip-and-peel run exactly on
# (P + root D)/Q in whole numbers.  Road two: the repeating block solved as a quadratic.  Road three: 13,228 starts swept.
def isqrt(n): r = int(n ** 0.5); return r - (r * r > n) + ((r + 1) ** 2 <= n)   # whole part of root n
def run(P, Q, D):                              # steps and pairs until a pair comes back
    seen, steps = [], []
    while (P, Q) not in seen:
        seen.append((P, Q)); r = isqrt(D * Q * Q); a = (P * Q + (r if Q > 0 else -r - 1)) // (Q * Q)   # whole part
        steps.append(a); P = a * Q - P; Q = (D - P * P) // Q
    return steps, seen, seen.index((P, Q))     # the loop starts at this step
def stops(steps, p=1, pb=0, q=0, qb=1):        # top/bottom pairs, built as on Continued fractions
    for a in steps: p, pb, q, qb = a * p + pb, p, a * q + qb, q; yield p, q
def euler(front, block):                       # y = (p y + pb)/(q y + qb), so q y^2 + (qb - p) y - pb = 0
    (pb, qb), (p, q) = ([(1, 0)] + list(stops(block)))[-2:]
    A, B, C = q, qb - p, -pb; y = (-B + (B * B - 4 * A * C) ** 0.5) / (2 * A)
    for a in reversed(front): y = a + 1 / y
    return A, B, C, y
for name, P, Q, D in [("golden ratio", 1, 2, 5), ("(1 + root 3)/2", 1, 2, 3), ("root 7", 0, 1, 7), ("root 2", 0, 1, 2)]:
    st, seen, k = run(P, Q, D); A, B, C, y = euler(st[:k], st[k:]); x, disc = (P + D ** 0.5) / Q, B * B - 4 * A * C
    print(f"{name:<15}{', '.join(map(str, (st[:k] + st[k:] * 9)[:9]))}  repeat length {len(st) - k}  {A}y^2 {B:+}y {C:+} = 0  {x:.10f} = {y:.10f}")
    assert abs(x - y) < 1e-12 and disc % D == 0 and isqrt(disc // D) ** 2 == disc // D   # roads one and two agree
s7, g, r2, x, n, true = list(stops([2, 1, 1, 1])), list(stops([1] * 6)), list(stops([1] + [2] * 5)), 7 ** 0.5, 0, [2] + [1, 1, 1, 4] * 20
print("root 7 pairs (P, Q):", *run(0, 1, 7)[1], run(0, 1, 7)[1][1], "...  stops", *[f"{p}/{q}" for p, q in s7], f" {s7[-1][0]}^2 - 7 x {s7[-1][1]}^2 = {s7[-1][0] ** 2 - 7 * s7[-1][1] ** 2}")
print("golden stops", *[f"{p}/{q}" for p, q in g], "  root 2 stops", *[f"{p}/{q}" for p, q in r2], " A4 297/210 =", *[f"{p}/{q}" for p, q in r2 if p * 210 == q * 297])
runs = [(D, *run(P, Q, D)) for D in range(2, 101) if isqrt(D) ** 2 != D for P in range(-12, 13) for Q in range(-12, 13) if Q and (D - P * P) % Q == 0]
inbox = all(0 < q <= D and p * p < D for D, st, seen, k in runs for p, q in seen[k:])   # the proof's box
print(f"starts tried {len(runs)}, every one repeats, longest wait {max(k for D, st, seen, k in runs)} steps, longest loop {max(len(st) - k for D, st, seen, k in runs)}, loop pairs in the box: {inbox}")
while int(x) == true[n]: x, n = 1 / (x - int(x)), n + 1   # the same flip-and-peel on a decimal
print(f"mistakes: block 2, 1, 1, 1 gives {euler([], [2, 1, 1, 1])[3]:.4f}; other root {(1 - 5 ** 0.5) / 2:.4f}; decimals go wrong at flip {n}: {int(x)}, not {true[n]}")
assert inbox and s7[-1][0] ** 2 - 7 * s7[-1][1] ** 2 == 1 and all(p * p - p * q - q * q in (1, -1) for p, q in g)
print("ALL CHECKS PASS")
