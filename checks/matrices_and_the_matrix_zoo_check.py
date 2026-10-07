# Matrices -- the check behind the card.  Nothing is imported.  The cafe's
# sales table has five days down the rows and two products across the columns.
# Two roads to the per-product totals: add down the columns of the table, and
# add across the rows of its transpose.  Second worked case: the two-day square
# table A, its sum with week two, its scaling, and the named shapes.
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]
PRODUCTS = ["coffee", "pastry"]
SALES = [[2, 1], [1, 1], [3, 2], [2, 1], [4, 3]]      # 5 rows by 2 columns

def rows(M): return len(M)
def cols(M): return len(M[0])
def transpose(M): return [[M[i][j] for i in range(rows(M))] for j in range(cols(M))]
def add(M, N): return [[M[i][j] + N[i][j] for j in range(cols(M))] for i in range(rows(M))]
def scale(c, M): return [[c * M[i][j] for j in range(cols(M))] for i in range(rows(M))]

def trace(M):                                          # add the main diagonal
    total = 0
    for i in range(rows(M)):
        total += M[i][i]
    return total

def show(M): return "[[" + "], [".join(", ".join(str(x) for x in r) for r in M) + "]]"

def grid(label, M, names, what):
    print("%s, %d rows by %d columns (%s)" % (label, rows(M), cols(M), what))
    for name, row in zip(names, M):
        print("  %-7s" % name + "".join("%3d" % x for x in row))

FLIPPED = transpose(SALES)
down = [sum(SALES[i][j] for i in range(rows(SALES))) for j in range(cols(SALES))]   # road one
across = [sum(row) for row in FLIPPED]                                             # road two
grid("sales table", SALES, DAYS, "days by products")
grid("transposed", FLIPPED, PRODUCTS, "products by days")
print("coffees and pastries, down the columns:  %d  %d   (%d items in all)"
      % (down[0], down[1], down[0] + down[1]))
print("coffees and pastries, across the rows of the transpose:  %d  %d" % (across[0], across[1]))
print("day totals, across the rows of the sales table: " + " ".join(str(sum(r)) for r in SALES))

A = [[2, 1], [1, 1]]
B = [[3, 2], [2, 1]]
TRI = [[2, 1], [0, 1]]
IDENT = [[1, 0], [0, 1]]
PRICES = [[4, 0], [0, 3]]
print("two days only, A = %s, %d rows by %d columns" % (show(A), rows(A), cols(A)))
print("week two B = %s;  A + B = %s;  2A = %s" % (show(B), show(add(A, B)), show(scale(2, A))))
print("A transposed = %s, equal to A, so A is symmetric" % show(transpose(A)))
print("upper triangular %s: row 2 column 1 is %d, row 1 column 2 is %d; transposed %s, not equal to it"
      % (show(TRI), TRI[1][0], TRI[0][1], show(transpose(TRI))))
print("prices on the diagonal %s; identity %s" % (show(PRICES), show(IDENT)))
print("traces: A %d, identity %d, prices %d, triangular %d"
      % (trace(A), trace(IDENT), trace(PRICES), trace(TRI)))

assert FLIPPED == [[2, 1, 3, 2, 4], [1, 1, 2, 1, 3]] and (rows(FLIPPED), cols(FLIPPED)) == (cols(SALES), rows(SALES))
assert down == across and down == [12, 8]
assert transpose(FLIPPED) == SALES and add(A, B) == [[5, 3], [3, 2]] and scale(2, A) == [[4, 2], [2, 2]]
assert transpose(A) == A and transpose(TRI) != TRI and [trace(A), trace(IDENT), trace(PRICES), trace(TRI)] == [3, 2, 7, 3]
print("ALL CHECKS PASS")
