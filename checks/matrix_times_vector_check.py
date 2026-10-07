# Matrix times vector -- the check behind the card.  Nothing is imported.
# The cafe's table A = [[2, 1], [1, 1]] holds the two days down and the two
# products across: Monday 2 coffees + 1 pastry, Tuesday 1 coffee + 1 pastry.
# The price vector x = (4, 3) is a $4 coffee and a $3 pastry.  The takings are
# reached by two roads that share no code, then again with a third day added.
A = [[2, 1], [1, 1]]
B = [[2, 1], [1, 1], [3, 2]]          # Wednesday as well: 3 coffees + 2 pastries
x = [4, 3]

def columns(M):                       # the table read down instead of across
    return [[row[j] for row in M] for j in range(len(M[0]))]

def by_columns(M, v):                 # road 1: weigh each column, add them up
    out = [0] * len(M)
    for weight, col in zip(v, columns(M)):
        out = [o + weight * c for o, c in zip(out, col)]
    return out

def by_rows(M, v):                    # road 2: each row against v, entry by entry
    return [sum(e * p for e, p in zip(row, v)) for row in M]

def fits(M, v):                       # the size rule: n columns eat n entries
    return all(len(row) == len(v) for row in M)

def show(name, v):
    print(f"{name:<32}{'(' + ', '.join(str(k) for k in v) + ')':>14}")

show("the coffee column, weighed by 4", [4 * c for c in columns(A)[0]])
show("the pastry column, weighed by 3", [3 * c for c in columns(A)[1]])
show("road 1: the columns, mixed", by_columns(A, x))
for i, row in enumerate(A):
    parts = " + ".join(f"{e}*{p}" for e, p in zip(row, x))
    print(f"road 2: row {i + 1} against the prices   {parts} = {by_rows(A, x)[i]}")
show("road 2: row by entry, added", by_rows(A, x))
print(f"sizes: A is {len(A)} by {len(A[0])}, x has {len(x)} entries, "
      f"the answer has {len(by_rows(A, x))}")
show("wrong: columns added, no prices", by_columns(A, [1, 1]))
show("wrong: prices swapped to (3, 4)", by_columns(A, [3, 4]))
print("a 2 by 2 handed three prices: "
      f"{'fits' if fits(A, [4, 3, 5]) else 'refused, the sizes do not fit'}")
show("third day added, road 1", by_columns(B, x))
show("third day added, road 2", by_rows(B, x))
print(f"sizes: B is {len(B)} by {len(B[0])}, x has {len(x)} entries, "
      f"the answer has {len(by_rows(B, x))}")
assert by_columns(A, x) == [11, 7] and by_rows(A, x) == [11, 7]
assert by_columns(B, x) == [11, 7, 18] and by_rows(B, x) == [11, 7, 18]
assert by_columns(A, [1, 1]) == [3, 2] and by_columns(A, [3, 4]) == [10, 7]
assert not fits(A, [4, 3, 5]) and fits(B, x) and len(by_rows(B, x)) == 3
print("ALL CHECKS PASS")
