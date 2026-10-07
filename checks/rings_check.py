# Rings -- the check behind the card.  Nothing is imported.  The twelve readings
# of a 12-hour clock, 0 where 12 sits, are added and multiplied by wrapping at 12.
# Road one hunts by brute force, trying every reading; road two argues from the
# greatest common divisor, written out below.  The two roads share no arithmetic.
N = 12
def hcf(a, b):                                   # greatest common divisor
    while b:
        a, b = b, a % b
    return a
def row(values):
    return " ".join(str(v) for v in values)
def times(a, b):                                 # product of two 2 by 2 matrices
    return [[a[i][0] * b[0][j] + a[i][1] * b[1][j] for j in (0, 1)] for i in (0, 1)]
def show(m):
    return f"[[{m[0][0]}, {m[0][1]}], [{m[1][0]}, {m[1][1]}]]"
def value(poly, x):                              # a polynomial at one integer
    return sum(c * x ** k for k, c in enumerate(poly))
readings = list(range(N))
reach = [len(set(a * x % N for x in readings)) for a in readings]       # road one
reach_hcf = [N // hcf(a, N) for a in readings]                          # road two
undo = [[x for x in readings if a * x % N == 1] for a in readings]      # road one
units = [a for a in readings if undo[a]]
units_hcf = [a for a in range(1, N) if hcf(a, N) == 1]                  # road two
zd = [a for a in range(1, N) if any(a * b % N == 0 for b in range(1, N))]
partner = [N // hcf(a, N) for a in zd]
triples = [(a, b, c) for a in readings for b in readings for c in readings]
spread = sum(1 for a, b, c in triples if a * ((b + c) % N) % N == (a * b + a * c) % N)
p, q, prod = [1, 1], [-1, 1], [0, 0, 0]          # (x + 1) and (x - 1), constant first
for i, pi in enumerate(p):
    for j, qj in enumerate(q):
        prod[i + j] += pi * qj
agree = all(value(prod, x) == value(p, x) * value(q, x) for x in range(-3, 4))
no2 = [k for k in range(-20, 21) if 2 * k == 1]
int_units = [k for k in range(-20, 21) if any(k * m == 1 for m in range(-20, 21))]
A, B, E, F = [[1, 1], [0, 1]], [[1, 0], [1, 1]], [[1, 0], [0, 0]], [[0, 0], [0, 1]]
print(f"clock size {N}: 3 x 4 = {3 * 4 % N}, and 5 x 5 = {5 * 5 % N}")
print(f"readings reached by multiplying by 0 to 11: {row(reach)}")
print(f"units by hunting an undo:  {row(units)}")
print(f"units by the gcd test:     {row(units_hcf)}")
print(f"the undo of each of them:  {row([undo[a][0] for a in units])}")
print(f"nonzero zero divisors: {row(zd)}")
print(f"a partner taking each to zero: {row(partner)}")
print(f"2 times 0 to 11: {row([2 * x % N for x in readings])}, and 1 is not there")
print(f"2x = 2 on the clock: x = {row([x for x in readings if 2 * x % N == 2])}")
print(f"distributivity: of {len(triples)} triples of readings, {spread} agree")
print(f"integers: 2k = 1 has {len(no2)} answers from -20 to 20; "
      f"the only units are {row(int_units)}")
print(f"polynomials: (x + 1)(x - 1) has coefficients {row(prod)} for 1, x, x^2; "
      f"agrees at every x from -3 to 3: {'yes' if agree else 'no'}")
print(f"A = {show(A)} and B = {show(B)}")
print(f"AB = {show(times(A, B))} but BA = {show(times(B, A))}")
print(f"matrix zero divisors: {show(E)} times {show(F)} = {show(times(E, F))}")
assert units == units_hcf == [1, 5, 7, 11] and reach == reach_hcf
assert zd == [2, 3, 4, 6, 8, 9, 10] and not set(units) & set(zd) and all(
    a * b % N == 0 for a, b in zip(zd, partner))
assert spread == len(triples) == 1728 and undo[2] == [] and no2 == [] and int_units == [-1, 1]
assert prod == [-1, 0, 1] and agree and times(A, B) == [[2, 1], [1, 1]] and times(
    B, A) == [[1, 1], [1, 2]] and times(E, F) == [[0, 0], [0, 0]]
print("ALL CHECKS PASS")
