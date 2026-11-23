# Permanent against determinant -- the check behind the card.  Standard library
# only; math is used for log10 on the chart alone.  Eight leads face eight follows
# in a rotating class; lead i has danced with follows i, i+1 and i+2 (wrapping).
# The permanent counts the ways to pair everyone with a practised partner: three
# roads (every pairing, Ryser's inclusion-exclusion, a backtracking search).  The
# determinant takes two roads (every pairing signed, fraction-free elimination).
import math
N, F = 8, "ABCDEFGH"
def dance(n): return [[1 if (j - i) % n in (0, 1, 2) else 0 for j in range(n)] for i in range(n)]
A = dance(N)

def perms(n):                         # every way to give each row its own column
    if n == 0:
        yield []
        return
    for p in perms(n - 1):
        for k in range(n):
            yield p[:k] + [n - 1] + p[k:]

def sign(p):                          # +1 if an even count of pairs sit out of order
    inv = sum(1 for i in range(len(p)) for j in range(i + 1, len(p)) if p[i] > p[j])
    return -1 if inv % 2 else 1

def by_definition(M):                 # road 1: all n! products, plain and signed
    per = det = even = odd = mults = 0
    for p in perms(len(M)):
        prod = M[0][p[0]]
        for i in range(1, len(M)):
            prod *= M[i][p[i]]
            mults += 1
        per += prod
        det += sign(p) * prod
        if prod != 0 and sign(p) == 1: even += 1
        if prod != 0 and sign(p) == -1: odd += 1
    return per, det, even, odd, mults

def ryser(M):                         # road 2: sum over column sets, signs alternate
    n, total, mults = len(M), 0, 0
    for s in range(1, 1 << n):
        prod = 1
        for i in range(n):
            prod *= sum(M[i][j] for j in range(n) if s >> j & 1)
            mults += 1
        total += prod if (n - bin(s).count("1")) % 2 == 0 else -prod
    return total, mults

def search(M, i=0, used=0):           # road 3: give lead i a free practised follow
    if i == len(M): return 1
    return sum(search(M, i + 1, used | 1 << j) for j in range(len(M)) if M[i][j] and not used >> j & 1)

def bareiss(M):                       # the determinant by elimination, whole numbers only
    M, n, sg, prev, mults = [r[:] for r in M], len(M), 1, 1, 0
    for k in range(n - 1):
        if M[k][k] == 0:
            r = [r for r in range(k + 1, n) if M[r][k] != 0]
            if not r: return 0, mults
            M[k], M[r[0]], sg = M[r[0]], M[k], -sg
        for i in range(k + 1, n):
            for j in range(k + 1, n):
                M[i][j] = (M[i][j] * M[k][k] - M[i][k] * M[k][j]) // prev
                mults += 2
        prev = M[k][k]
    return sg * M[n - 1][n - 1], mults

def tilings(R, C):                    # chessboard road 2: fill cell by cell, one bit per column
    ways = [1] + [0] * ((1 << C) - 1)
    for cell in range(R * C):
        r, c, new = cell // C, cell % C, [0] * (1 << C)
        for m, w in enumerate(ways):
            if w == 0: continue
            if m >> c & 1: new[m & ~(1 << c)] += w; continue
            if r + 1 < R: new[m | 1 << c] += w
            if c + 1 < C and not m >> (c + 1) & 1: new[m | 1 << (c + 1)] += w
        ways = new
    return ways[0]

def fact(n): return 1 if n < 2 else n * fact(n - 1)
def cost(n): return fact(n) * (n - 1), ((1 << n) - 1) * n, 2 * sum(m * m for m in range(1, n))

small = dance(4)
p4, d4, e4, o4, _ = by_definition(small)
print("4 couples: pairings", " ".join("".join(F[j] for j in p) + ("+" if sign(p) > 0 else "-")
      for p in perms(4) if all(small[i][p[i]] for i in range(4))))
print(f"4 couples: permanent {p4}, determinant {d4}, even {e4}, odd {o4}")
for i in range(N): print(f"lead {i + 1} has danced with", ", ".join(F[j] for j in range(N) if A[i][j]))
per, det, even, odd, m_def = by_definition(A)
ry, m_ry = ryser(A)
bd, m_el = bareiss(A)
print(f"{N} couples, every pairing: permanent {per}, determinant {det}, even {even}, odd {odd}")
print(f"{N} couples, Ryser: permanent {ry}; backtracking search: {search(A)} pairings")
print(f"{N} couples, elimination: determinant {bd}")
print(f"multiplications counted at n = {N}: every pairing {m_def}, Ryser {m_ry}, elimination {m_el}")
print(f"same counts by formula: {cost(N)[0]}, {cost(N)[1]}, {cost(N)[2]}")
for n in (8, 16, 32): print(f"n = {n}: every pairing {cost(n)[0]}, Ryser {cost(n)[1]}, elimination {cost(n)[2]}")
ns = list(range(4, 33, 4))
for k, name in enumerate(("every pairing", "Ryser", "elimination")):
    print(f"chart log10 {name}:", ", ".join(f"{math.log10(cost(n)[k]):.2f}" for n in ns))
B, B2 = [[1, 2], [3, 4]], [[1, 2], [0, -2]]
print(f"2 by 2 [[1, 2], [3, 4]]: permanent {by_definition(B)[0]}, determinant {by_definition(B)[1]}")
print(f"after row 2 minus 3 x row 1: permanent {by_definition(B2)[0]}, determinant {by_definition(B2)[1]}")
print(f"sign trick at n = 2: det [[1, -2], [3, 4]] = {by_definition([[1, -2], [3, 4]])[1]}")
best = max(abs(by_definition([[1 - 2 * (s >> (3 * i + j) & 1) for j in range(3)] for i in range(3)])[1])
           for s in range(512))
print(f"sign trick at n = 3: largest |det| over all 512 sign patterns {best}, permanent of all ones {by_definition([[1] * 3] * 3)[0]}")
print(f"mistake, |determinant| read as the count: {abs(det)}, not {per}")
MINUS = ((0, 0), (1, 2), (3, 4), (5, 6), (7, 7))    # lead 1 with A, 2 with C, 4 with E, 6 with G, 8 with H
S = [[-A[i][j] if (i, j) in MINUS else A[i][j] for j in range(N)] for i in range(N)]
print(f"dance class, five entries made negative: determinant {bareiss(S)[0]}")
sq = [(r, c) for r in range(8) for c in range(8)]
blk, wht = [s for s in sq if sum(s) % 2 == 0], [s for s in sq if sum(s) % 2 == 1]
K = [[(1 if r == r2 and abs(c - c2) == 1 else (-1) ** c if c == c2 and abs(r - r2) == 1 else 0)
      for (r2, c2) in wht] for (r, c) in blk]
kd = bareiss(K)[0]
print(f"chessboard dominoes: signed 32 by 32 determinant {kd}, cell-by-cell count {tilings(8, 8)}")
assert per == ry == search(A) and p4 == search(small)          # three roads to the permanent
assert det == bd and d4 == bareiss(small)[0]                   # two roads to the determinant
assert bareiss([[0, 1], [1, 0]])[0] == by_definition([[0, 1], [1, 0]])[1]   # a row swap flips the sign
assert even + odd == per and even - odd == det                 # the signs split the same pairings
assert (m_def, m_ry, m_el) == cost(N)                          # counted work matches the formulas
assert best < by_definition([[1] * 3] * 3)[0]                  # no sign pattern works at n = 3
assert abs(bareiss(S)[0]) == per                                # a sign pattern fits this class
assert abs(kd) == tilings(8, 8)                                # planar board: the trick works
print("ALL CHECKS PASS")
