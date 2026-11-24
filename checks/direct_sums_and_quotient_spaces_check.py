# Direct sums and quotient spaces -- the check behind the card.  Nothing is imported.
# A basket is (loaves, milks, dozens of eggs); the price list ($3, $2, $4) reads its bill.
def bill(x): return 3 * x[0] + 2 * x[1] + 4 * x[2]
def sub(x, y): return tuple(a - b for a, b in zip(x, y))
def det(c1, c2, c3):                     # 3 x 3 determinant of the columns c1, c2, c3
    (a, d, g), (b, e, h), (c, f, i) = c1, c2, c3
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
def yn(claim): return "yes" if claim else "no"
def dimq(n, q):                          # n = q ** k members on a q-hour clock means k dimensions
    k = 0
    while n > 1: n, k = n // q, k + 1
    return k

x, y, u1, u2, milk, e1 = (2, 3, 1), (4, 0, 1), (2, -3, 0), (0, 2, -1), (0, 1, 0), (1, 0, 0)
print(f"bills: {x} -> ${bill(x)}, {y} -> ${bill(y)}; difference {sub(y, x)} -> ${bill(sub(y, x))}")
minor = u1[0] * u2[1] - u1[1] * u2[0]
print(f"$0 plane U: {u1} -> ${bill(u1)}, {u2} -> ${bill(u2)}; 2 x 2 minor {minor}, so dim U = 2")
D = det(u1, u2, milk)                    # road one to the split: Cramer's rule
a, b, m = det(x, u2, milk) // D, det(u1, x, milk) // D, det(u1, u2, x) // D
zero_part = tuple(a * p + b * q for p, q in zip(u1, u2))
print(f"U + milk line: det {D}, not 0, so direct; {x} = {a} x {u1} + {b} x {u2} + {m} milks")
by_bill = sub(x, (0, bill(x) // 2, 0))   # road two: 8 milks carry the $16, the rest is $0
print(f"split: $0 part {zero_part} + milk part (0, {m}, 0); by bill / 2: {by_bill} + (0, {bill(x) // 2}, 0)")
r = max(abs(det(*c)) for c in [(u1, u2, e1), (u1, u2, milk), (u1, e1, milk), (u2, e1, milk)])
print(f"U + no-eggs plane: largest 3 x 3 minor {r}, so U + E fills 3; overlap 2 + 2 - 3 = 1")
print(f"basket {u1} splits two ways: {u1} + (0, 0, 0) and (0, 0, 0) + {u1}")
q = 7                                    # road two to every dimension: count over the 7-clock
V7 = [(a, b, c) for a in range(q) for b in range(q) for c in range(q)]
U7 = [v for v in V7 if bill(v) % q == 0]
E7, W7 = {v for v in V7 if v[2] == 0}, [(0, b, 0) for b in range(q)]
add = lambda v, w: tuple((s + t) % q for s, t in zip(v, w))
cosets = {frozenset(add(v, u) for u in U7) for v in V7}
UW, UE = {add(u, w) for u in U7 for w in W7}, {add(u, e) for u in U7 for e in E7}
capW, capE = [v for v in U7 if v in W7], [v for v in U7 if v in E7]
print(f"mod {q}: {len(V7)} baskets, U has {len(U7)}, cosets {len(cosets)} = {len(V7)} / {len(U7)}; "
      f"dim V/U = {dimq(len(cosets), q)} = 3 - {dimq(len(U7), q)}")
print(f"mod {q}: U + W has {len(UW)}, U and W share {len(capW)}; U + E has {len(UE)}, U and E share {len(capE)}")
box = [(a, b, c) for a in range(5) for b in range(5) for c in range(5)]
classes = {frozenset(v for v in box if det(u1, u2, sub(w, v)) == 0) for w in box}
bills = {bill(v) for v in box}
one_bill = all(len({bill(v) for v in c}) == 1 for c in classes)
c16 = [c for c in classes if x in c][0]
print(f"box 0-4 each: {len(box)} baskets, {len(classes)} classes by the U test, {len(bills)} bills; one bill per class: {yn(one_bill)}")
print(f"the $16 class holds {len(c16)} box baskets, {y} among them: {yn(y in c16)}")
s = tuple(p + t for p, t in zip(x, y))
print(f"cosets add: $16 class + $16 class holds {s} -> ${bill(s)}; 3 x {x} -> ${bill(tuple(3 * t for t in x))}")
print(f"mistake 1, dimensions added: 2 + 2 = 4, but U + E is {dimq(len(UE), q)}-dimensional")
print(f"mistake 2, V/U read as division: 3 / 2 = {3 / 2}, but dim V/U = {dimq(len(cosets), q)}")
print(f"mistake 3, baskets counted: {len(box)}, but the box meets only {len(classes)} cosets")
print(f"mistake 4, a 'complement' inside U: det {det(u1, u2, u1)}, so no split of a ${bill(x)} basket")
assert D != 0 and minor != 0 and det(u2, u1, milk) == -D and bill(zero_part) == 0 and zero_part == by_bill and m == bill(x) // 2
assert len(cosets) == len(V7) // len(U7) == 7 and dimq(len(U7), q) == 2 and len(capE) == 7
assert len(UW) == 343 and len(capW) == 1 and len(UE) == 343 and r != 0
assert one_bill and len(classes) == len(bills) and y in c16 and det(u1, u2, u1) == 0
print("ALL CHECKS PASS")
