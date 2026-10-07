# Matrix multiplication -- the check behind the card.  Nothing is imported.
# A: grams per product.  B: products per day.  C: weekdays in four weeks.  Each
# product is reached twice: by the row-by-column definition, and by slices.
A = [[20, 0], [0, 60]]      # rows: beans, flour.     columns: brew, loaf
B = [[2, 1], [1, 1]]        # rows: brew, loaf.       columns: Monday, Tuesday
C = [[4], [4]]              # rows: Monday, Tuesday.  one column: four weeks

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
show("A  grams per product, beans/flour by brew/loaf", A)
show("B  products per day, brew/loaf by Mon/Tue", B)
show("C  count of each day in four weeks", C)
show("AB grams per day, beans/flour by Mon/Tue", AB)
for nm, i, j in (("beans on Monday", 0, 0), ("beans on Tuesday", 0, 1),
                 ("flour on Monday", 1, 0), ("flour on Tuesday", 1, 1)):
    parts = " + ".join(f"{A[i][k]}*{B[k][j]}" for k in range(2))
    print(f"   {nm:<18}{parts} = {AB[i][j]}")
show("BA the swapped order, same numbers, no meaning", BA)
show("BC products in four weeks, brew/loaf", BC)
show("(AB)C grams in four weeks, grams per day first", ABC)
show("A(BC) grams in four weeks, products first", A_BC)
show("slice 1, beans column times the brew row", s1)
show("slice 2, flour column times the loaf row", s2)
show("(AB)C again, as slices of AB against C", f"{t1} + {t2} = {add(t1, t2)}")
show("wrong: entry by entry", [[A[i][j] * B[i][j] for j in range(2)] for i in range(2)])
show("wrong: first product only, rest of the sum dropped", s1)
show("wrong: C on the left of AB", "no product: 2x1 then 2x2, inner sizes 1 and 2")
print(f"sizes: {size(A)[0]}x{size(A)[1]} times {size(B)[0]}x{size(B)[1]} -> {size(AB)[0]}x{size(AB)[1]}"
      f", and {size(AB)[0]}x{size(AB)[1]} times {size(C)[0]}x{size(C)[1]} -> {size(ABC)[0]}x{size(ABC)[1]}")
assert AB == [[40, 20], [60, 60]] and BA == [[40, 60], [20, 60]] and AB != BA
assert add(s1, s2) == AB and s1 == [[40, 20], [0, 0]] and s2 == [[0, 0], [60, 60]]
assert (ABC == [[240], [480]] and A_BC == [[240], [480]] and BC == [[12], [8]]
        and t1 == [[160], [240]] and t2 == [[80], [240]] and add(t1, t2) == ABC)
assert times(C, AB) is None and size(A_BC) == (2, 1)
print("ALL CHECKS PASS")
