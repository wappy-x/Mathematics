# Dual spaces -- the check behind the card.  Nothing is imported.  The dual basis
# is found by inverting and by search; item prices are pulled back to hamper
# prices by the transpose; row rank = column rank is tested on 300 matrices.
def bill(p, v):                                   # a price list reading a basket
    return sum(a * b for a, b in zip(p, v))

def rank(rows):                                   # elimination in whole numbers
    rows, r = [list(x) for x in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if rows[i][c]), None)
        if piv is None: continue
        rows[r], rows[piv] = rows[piv], rows[r]
        for i in range(r + 1, len(rows)):
            rows[i] = [rows[r][c] * x - rows[i][c] * y for x, y in zip(rows[i], rows[r])]
        r += 1
    return r

def dual_by_inverse(b1, b2):                      # rows of the inverse basis matrix
    d = b1[0] * b2[1] - b2[0] * b1[1]             # the determinant, 1 or -1 here
    return [(b2[1] // d, -b2[0] // d), (-b1[1] // d, b1[0] // d)]

def dual_by_search(b1, b2):                       # every price list from -5 to 5
    grid = [(x, y) for x in range(-5, 6) for y in range(-5, 6)]
    return [next(f for f in grid if (bill(f, b1), bill(f, b2)) == w) for w in ((1, 0), (0, 1))]

transpose = lambda m: [list(c) for c in zip(*m)]  # rows become columns
b1, b2, p, v = (2, 1), (1, 1), (3, 2), (2, 3)
f = dual_by_inverse(b1, b2)
readings = [[bill(fi, bj) for bj in (b1, b2)] for fi in f]
p_back = tuple(bill(p, b1) * f[0][k] + bill(p, b2) * f[1][k] for k in range(2))
v_back = tuple(bill(f[0], v) * b1[k] + bill(f[1], v) * b2[k] for k in range(2))
A, q, order = [[2, 1], [3, 0], [1, 2]], [3, 2, 4], [1, 2]     # columns are the hampers
hamper_prices = [bill(col, q) for col in transpose(A)]           # A^T q
items = [bill(row, order) for row in A]                          # A times the order
r3 = range(-3, 4)
hidden = [(a, b, c) for a in r3 for b in r3 for c in r3 if all(bill((a, b, c), h) == 0 for h in transpose(A))]
seed, vals = 7, []
for _ in range(3600):                             # 300 matrices, 3 by 4, entries 0 or 1
    seed = (seed * 1103515245 + 12345) % 2**31
    vals.append(seed // 65536 % 2)
batch = [[vals[12 * k + 4 * i:12 * k + 4 * i + 4] for i in range(3)] for k in range(300)]
same = all(rank(m) == rank(transpose(m)) for m in batch)
print(f"the weekly shop's bill: price list (3, 2, 4) reads basket (2, 3, 1) as ${bill((3, 2, 4), (2, 3, 1))}")
print(f"dual basis by inverting: {f}; by search: {dual_by_search(b1, b2)}")
print(f"readings f_i(b_j): {readings}")
print(f"price list {p} = {bill(p, b1)} f1 + {bill(p, b2)} f2 -> {p_back}")
print(f"basket {v} = {bill(f[0], v)} b1 + {bill(f[1], v)} b2 -> {v_back}")
print(f"hamper prices A^T q: {hamper_prices}; order {order} -> items {items}")
print(f"bill of the order: item road ${bill(q, items)}, hamper road ${bill(hamper_prices, order)}")
print(f"hidden price changes by search: {hidden}; independent: {rank(hidden)} = 3 - {rank(A)}")
print(f"rank of A {rank(A)}, rank of A^T {rank(transpose(A))}")
print(f"row rank = column rank on 300 matrices: {'yes' if same else 'no'}; ranks seen {sorted({rank(m) for m in batch})}")
print(f"mistake 1, basis basket (2, 1) as a price list reads b1, b2 as {[bill(b1, b) for b in (b1, b2)]}")
print(f"mistake 2, hamper prices pushed forward by A: {[bill(row, hamper_prices) for row in A]}")
print(f"mistake 3, b2 swapped to (1, 0): dual basis becomes {dual_by_inverse(b1, (1, 0))}")
assert f == dual_by_search(b1, b2) and dual_by_inverse(b1, (1, 0)) == dual_by_search(b1, (1, 0))
assert readings == [[1, 0], [0, 1]] and p_back == p and v_back == v
assert bill(q, items) == bill(hamper_prices, order) == 38       # two roads to one bill
assert rank(hidden) == len(q) - rank(A) and same                # annihilator size; the theorem
print("ALL CHECKS PASS")
