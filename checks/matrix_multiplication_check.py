# Matrix multiplication -- the check behind the card.  Nothing is imported.
# A: kilograms per batch.  B: batches per day.  C: weekdays in four weeks.  Each
# product is reached twice: by the row-by-column definition, and by slices.
A = [[5, 3], [2, 2]]        # rows: flour, butter.       columns: brioche, croissant
B = [[2, 1], [1, 1]]        # rows: brioche, croissant.  columns: Monday, Tuesday
C = [[4], [4]]              # rows: Monday, Tuesday.     one column: four weeks

def size(M): return len(M), len(M[0])

def times(M, N):                                   # road 1: the definition itself
    (rm, cm), (rn, cn) = size(M), size(N)
    if cm != rn: return None                       # inner sizes disagree: no product
    out = []
    for i in range(rm):
        row = []
        for j in range(cn):
            total = 0
            for k in range(cm):                    # across M's row, down N's column
                total += M[i][k] * N[k][j]
            row.append(total)
        out.append(row)
    return out

def slice_k(M, N, k):                              # road 2: column k of M times row k of N
    return [[M[i][k] * N[k][j] for j in range(size(N)[1])] for i in range(size(M)[0])]

def add(M, N):
    return [[M[i][j] + N[i][j] for j in range(len(M[0]))] for i in range(len(M))]

def show(name, value): print(f"{name:<52}{value}")

AB, BA, BC = times(A, B), times(B, A), times(B, C)
s1, s2, t1, t2 = slice_k(A, B, 0), slice_k(A, B, 1), slice_k(AB, C, 0), slice_k(AB, C, 1)
ABC, A_BC = times(AB, C), times(A, BC)
show("A  kg per batch, flour/butter by brioche/croissant", A)
show("B  batches per day, brioche/croissant by Mon/Tue", B)
show("C  count of each day in four weeks", C)
show("AB kg per day, flour/butter by Mon/Tue", AB)
for nm, i, j in (("flour on Monday", 0, 0), ("flour on Tuesday", 0, 1),
                 ("butter on Monday", 1, 0), ("butter on Tuesday", 1, 1)):
    parts = " + ".join(f"{A[i][k]}*{B[k][j]}" for k in range(2))
    print(f"   {nm:<18}{parts} = {AB[i][j]}")
show("BA the swapped order, same numbers, no meaning", BA)
show("BC batches in four weeks, brioche/croissant", BC)
show("(AB)C kg in four weeks, kg per day first", ABC)
show("A(BC) kg in four weeks, batches first", A_BC)
show("slice 1, brioche recipe times brioche schedule", s1)
show("slice 2, croissant recipe times croissant schedule", s2)
show("(AB)C again, as slices of AB against C", f"{t1} + {t2} = {add(t1, t2)}")
show("wrong: entry by entry", [[A[i][j] * B[i][j] for j in range(2)] for i in range(2)])
show("wrong: first product only, rest of the sum dropped", s1)
show("wrong: C on the left of AB", "no product: 2x1 then 2x2, inner sizes 1 and 2")
print(f"sizes: {size(A)[0]}x{size(A)[1]} times {size(B)[0]}x{size(B)[1]} -> {size(AB)[0]}x{size(AB)[1]}"
      f", and {size(AB)[0]}x{size(AB)[1]} times {size(C)[0]}x{size(C)[1]} -> {size(ABC)[0]}x{size(ABC)[1]}")
assert AB == [[13, 8], [6, 4]] and BA == [[12, 8], [7, 5]] and AB != BA
assert add(s1, s2) == AB and s1 == [[10, 5], [4, 2]] and s2 == [[3, 3], [2, 2]]
assert (ABC == [[84], [40]] and A_BC == [[84], [40]] and BC == [[12], [8]]
        and t1 == [[52], [24]] and t2 == [[32], [16]] and add(t1, t2) == ABC)
assert times(C, AB) is None and size(A_BC) == (2, 1)
print("ALL CHECKS PASS")
