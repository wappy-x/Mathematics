# The coin problem -- the check behind the card.  Nothing is imported.  Stamps of 5 and 7
# cents, then boxes of 6, 9 and 20.  Roads: search, the remainder ladder, the formula, pairing.
def payable(sizes, top):                    # road one: build every amount upward
    ok = [True] + [False] * top
    for n in range(1, top + 1): ok[n] = any(n >= s and ok[n - s] for s in sizes)
    return ok
def ladder(sizes):                          # road two: cheapest amount in each row, from the other sizes only
    a, ok = sizes[0], payable(sizes[1:], sizes[0] * max(sizes) * 3)
    return [min(n for n in range(len(ok)) if ok[n] and n % a == r) for r in range(a)]
A, B, BOXES = 5, 7, [6, 9, 20]
ok, rows, F = payable([A, B], 100), ladder([A, B]), A * B - A - B   # road three: formula
gaps, pairs = [n for n in range(101) if not ok[n]], sum(ok[n] != ok[F - n] for n in range(F + 1)) // 2  # road four: n, 23 - n
print(f"{A} and {B} cannot pay:", " ".join(str(n) for n in gaps))
print(f"first payable in rows 0..{A - 1}: {rows}; gaps per row {[r // A for r in rows]}; largest gap {max(rows)} - {A} = {max(rows) - A}")
print(f"formula {A} x {B} - {A} - {B} = {F}; gaps {len(gaps)}, ({A}-1)({B}-1)/2 = {(A - 1) * (B - 1) // 2}, pairs split {pairs} of {(F + 1) // 2}")
ys = {n: min(y for y in range(A) if (n - B * y) % A == 0) for n in range(F + 1, F + A + 1)}  # the next five
print("; ".join(f"{n} = {(n - B * y) // A} x {A} + {y} x {B}" for n, y in ys.items()))
box, brows, c = payable(BOXES, 200), ladder(BOXES), BOXES[0]
bgaps = [n for n in range(201) if not box[n]]
print(f"boxes {', '.join(map(str, BOXES))}: largest gap {bgaps[-1]}, rows {brows}, {max(brows)} - {c} = {max(brows) - c}; gaps {len(bgaps)}")
(u, v), (s, t), R = (-1, 1), (7, -1), range(-10, 11)      # Bezout twice: 6u + 9v = 3, then 3s + 20t = 1
print(f"negatives allowed: 3 x {A} - 2 x {B} = {3 * A - 2 * B}; 6 x {u} + 9 x {v} = {6 * u + 9 * v}, {6 * u + 9 * v} x {s} + 20 x {t} = {(6 * u + 9 * v) * s + 20 * t}, so 6 x {u * s} + 9 x {v * s} + 20 x {t} = {6 * u * s + 9 * v * s + 20 * t}")
mix = lambda p, q, w: sorted({p * x + q * y + w * z for x in R for y in R for z in R} & set(range(51)))
print(f"counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach {len(mix(6, 9, 20))} of 51; 6, 9, 15 reach only {' '.join(map(str, mix(6, 9, 15)))}")
print(f"the three mistakes come out at {A * B}, {max(rows)} and {(A - 1) * (B - 1)}")
assert gaps[-1] == F == max(rows) - A == 23 and len(gaps) == (A - 1) * (B - 1) // 2 == pairs == sum(r // A for r in rows) == 12
assert rows == [0, 21, 7, 28, 14] and all(d % A == r and ok[d] and (d < A or not ok[d - A]) for r, d in enumerate(rows)) and all(ok[24:]) and ok[A * B] and ok[max(rows)]
assert bgaps[-1] == max(brows) - c == 43 and len(bgaps) == sum(r // c for r in brows) == 22 and all(d % c == r and box[d] and (d < c or not box[d - c]) for r, d in enumerate(brows))
assert 6 * u * s + 9 * v * s + 20 * t == 1 and len(mix(6, 9, 20)) == 51 and mix(6, 9, 15) == list(range(0, 51, 3))
print("ALL CHECKS PASS")
