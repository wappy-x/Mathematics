# Diagonalisation -- the check behind the card.  Nothing is imported.  A rental
# fleet shuffles between two cities each month under A = [[0.8, 0.3], [0.2, 0.7]]
# and 1,000 cars start in city A.  Road one multiplies A by itself, month after
# month.  Road two builds A^n as P D^n P inverse: three multiplications.  The
# hand formulas 600 + 400 x 0.5^n and 400 - 400 x 0.5^n are a third road.
A = [[0.8, 0.3], [0.2, 0.7]]
P = [[3.0, 1.0], [2.0, -1.0]]
PINV = [[0.2, 0.2], [0.4, -0.6]]
START = [1000.0, 0.0]
MONTHS = list(range(13))

def mul(m, k):                              # 2 by 2 matrix times 2 by 2 matrix
    return [[m[i][0] * k[0][j] + m[i][1] * k[1][j] for j in range(2)] for i in range(2)]

def act(m, v):                              # matrix times a column of two numbers
    return [m[i][0] * v[0] + m[i][1] * v[1] for i in range(2)]

def dpow(n): return [[1.0, 0.0], [0.0, 0.5 ** n]]      # D^n: 1 stays, 0.5 halves
def three(p, d, q): return mul(mul(p, d), q)           # p times d times q
def gap(m, k): return max(abs(m[i][j] - k[i][j]) for i in range(2) for j in range(2))
def pair(v): return f"({v[0]:.6f}, {v[1]:.6f})"
def grid(name, vals): print(f"{name:<27}" + "".join(f"{v:>8}" for v in vals))
power = [[[1.0, 0.0], [0.0, 1.0]]]          # month 0: the do-nothing matrix
for _ in range(12): power.append(mul(A, power[-1]))    # road one: one more A a month
slow = [act(power[n], START) for n in MONTHS]
fast = [act(three(P, dpow(n), PINV), START) for n in MONTHS]
hand = [[600.0 + 400.0 * 0.5 ** n, 400.0 - 400.0 * 0.5 ** n] for n in MONTHS]
w = act(PINV, START)                    # the start, read in eigenvector amounts
steady, fade = [P[0][0] * w[0], P[1][0] * w[0]], [P[0][1] * w[1], P[1][1] * w[1]]
shear, spow = [[1.0, 1.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]]
for _ in range(12): spow = mul(shear, spow)            # the shear, twelve months of it
rows, rinv = [[3.0, 2.0], [1.0, -1.0]], [[0.2, 0.4], [0.2, -0.6]]
swap, sinv = [[1.0, 3.0], [-1.0, 2.0]], [[0.4, -0.6], [0.2, 0.2]]
wrong = [act(three(rows, dpow(12), rinv), START), act(three(P, dpow(12), P), START),
         act(three(P, dpow(1), PINV), START), act(three(swap, dpow(12), sinv), START)]
labels = ["eigenvectors as rows of P", "P where P inverse belongs",
          "D left at the first power", "P columns swapped, D not"]
print("fleet matrix A = [[0.8, 0.3], [0.2, 0.7]], start (1000, 0) cars")
print("eigenvectors (3, 2) and (1, -1); eigenvalues 1 and 0.5")
print("P = [[3, 1], [2, -1]], D = [[1, 0], [0, 0.5]], P inverse = [[0.2, 0.2], [0.4, -0.6]]")
print(f"P D P inverse rebuilds A: largest entry gap {gap(three(P, dpow(1), PINV), A):.12f}")
print(f"eigenvector amounts, P inverse times (1000, 0): {pair(w)} = {w[0]:.0f} x (3, 2) + "
      f"{w[1]:.0f} x (1, -1) = {pair(steady)} + {pair(fade)}")
grid("month", MONTHS)
grid("city A, twelve multiplies", [f"{slow[n][0]:.2f}" for n in MONTHS])
grid("city B, twelve multiplies", [f"{slow[n][1]:.2f}" for n in MONTHS])
grid("city A, three multiplies", [f"{fast[n][0]:.2f}" for n in MONTHS])
grid("city B, three multiplies", [f"{fast[n][1]:.2f}" for n in MONTHS])
print(f"hand formula, city A at months 1, 6 and 12: {hand[1][0]:.6f}, {hand[6][0]:.6f}, "
      f"{hand[12][0]:.6f}; city B at month 12: {hand[12][1]:.6f}")
print(f"month 12 in full: {pair(fast[12])}; city A to one decimal = {fast[12][0]:.1f} cars")
for name, v in zip(labels, wrong):
    print(f"mistake, {name:<26}" + pair(v))
print(f"shear [[1, 1], [0, 1]] to the 12th = [[1, {spow[0][1]:.0f}], [0, 1]], "
      f"eigenvectors only along (1, 0)")
assert gap(three(P, dpow(1), PINV), A) < 1e-12
assert all(gap(three(P, dpow(n), PINV), power[n]) < 1e-12 for n in MONTHS)
assert all(abs(fast[n][j] - hand[n][j]) < 1e-9 for n in MONTHS for j in range(2))
assert spow == [[1.0, 12.0], [0.0, 1.0]] and act(shear, [1.0, 0.0]) == [1.0, 0.0] and act(shear, [1.0, 1.0]) == [2.0, 1.0]
print("ALL CHECKS PASS")
