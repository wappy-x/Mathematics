# Linear maps as matrices -- the check behind the card.  Nothing is imported.
# A game sprite sits on the unit square.  Two moves: a shear that leans it, and
# a quarter turn.  Each is tested for linearity, turned into a matrix from the
# images of the two axis arrows, run by rule and by matrix, then composed.

def shear(v):  return (v[0] + v[1], v[1])        # lean the top to the right
def turn(v):   return (-v[1], v[0])              # quarter turn, anticlockwise
def slide(v):  return (v[0] + 1, v[1])           # NOT linear: it moves (0, 0)

E1, E2, C = (1, 0), (0, 1), (1, 1)               # the axis arrows, and the corner followed
SQUARE = [(0, 0), (1, 0), (1, 1), (0, 1)]        # the sprite's four corners

def matrix_of(f):                                # columns are the images of the axes
    a, b = f(E1), f(E2)
    return [[a[0], b[0]], [a[1], b[1]]]

def apply(M, v):                                 # matrix times vector: mix the columns
    return (M[0][0] * v[0] + M[0][1] * v[1], M[1][0] * v[0] + M[1][1] * v[1])
def times(M, N):                                 # M after N: push each column of N through M
    c1, c2 = apply(M, (N[0][0], N[1][0])), apply(M, (N[0][1], N[1][1]))
    return [[c1[0], c2[0]], [c1[1], c2[1]]]

def add(a, b):    return (a[0] + b[0], a[1] + b[1])
def scale(k, a):  return (k * a[0], k * a[1])
def s(v):         return f"({v[0]}, {v[1]})"
def m(M):         return f"[[{M[0][0]}, {M[0][1]}], [{M[1][0]}, {M[1][1]}]]"

S, R = matrix_of(shear), matrix_of(turn)
print(f"shear: e1 -> {s(shear(E1))}, e2 -> {s(shear(E2))}, so the matrix is {m(S)}")
print(f"turn:  e1 -> {s(turn(E1))}, e2 -> {s(turn(E2))}, so the matrix is {m(R)}")
print("the sprite's corners             " + "  ".join(s(v) for v in SQUARE))
print("after the shear, by the rule     " + "  ".join(s(shear(v)) for v in SQUARE))
print("after the shear, by its matrix   " + "  ".join(s(apply(S, v)) for v in SQUARE))
print("after the turn, by the rule      " + "  ".join(s(turn(v)) for v in SQUARE))
print("after the turn, by its matrix    " + "  ".join(s(apply(R, v)) for v in SQUARE))

TS, ST = times(S, R), times(R, S)
print(f"turn first, then shear: one matrix {m(TS)}")
print(f"  two steps, corner {s(C)}: turn -> {s(turn(C))}, then shear -> {s(shear(turn(C)))}")
print(f"  that one matrix, corner {s(C)}: {s(apply(TS, C))}")
print(f"shear first, then turn: one matrix {m(ST)}")
print(f"  two steps, corner {s(C)}: shear -> {s(shear(C))}, then turn -> {s(turn(shear(C)))}")
print(f"  that one matrix, corner {s(C)}: {s(apply(ST, C))}")

u, v, k = (1, 0), (0, 1), 3
print(f"linearity of the shear, with u = {s(u)}, v = {s(v)}, c = {k}")
print(f"  T(u + v) = {s(shear(add(u, v)))} and T(u) + T(v) = {s(add(shear(u), shear(v)))}")
print(f"  T(cu) = {s(shear(scale(k, u)))} and cT(u) = {s(scale(k, shear(u)))}")
print(f"slide right by 1 fails: D(u + v) = {s(slide(add(u, v)))} but D(u) + D(v) = {s(add(slide(u), slide(v)))}")

rows_not_cols, no_minus = [[1, 0], [1, 1]], [[0, 1], [1, 0]]
print(f"mistakes on corner {s(C)}: wrong order {s(apply(ST, C))}, "
      f"rows not columns {s(apply(rows_not_cols, C))}, turn with no minus {s(apply(no_minus, C))}")

assert S == [[1, 1], [0, 1]] and R == [[0, -1], [1, 0]]
assert all(apply(S, w) == shear(w) and apply(R, w) == turn(w) for w in SQUARE)
assert TS == [[1, -1], [1, 0]] and ST == [[0, -1], [1, 1]]
assert apply(TS, C) == shear(turn(C)) == (0, 1) and apply(ST, C) == turn(shear(C)) == (-1, 2)
print("ALL CHECKS PASS")
