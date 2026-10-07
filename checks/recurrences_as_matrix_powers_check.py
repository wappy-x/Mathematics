# A recurrence is a matrix -- the check behind the card.  Nothing is imported.
# A hallway 2 feet wide and n feet long is tiled with 1 x 2 tiles: T(n) ways.
# Four roads to the count: laying real tiles, stepping the rule, powers of the
# companion matrix M = [[1, 1], [1, 0]], and Binet from M's two eigenvalues.
N, MOD, FAR, M = 10, 1000000007, 1000000, [[1, 1], [1, 0]]

def tilings(n, used=0):                     # road one: lay real tiles, no formula
    if used == (1 << 2 * n) - 1: return 1
    k = 0
    while used >> k & 1: k += 1             # first empty cell, numbered row + 2 x column
    v = tilings(n, used | 3 << k) if k % 2 == 0 and not used >> (k + 1) & 1 else 0
    return v + (tilings(n, used | 5 << k) if k // 2 + 1 < n and not used >> (k + 2) & 1 else 0)

def mul(a, b, m=0):                         # 2 x 2 matrix product, wrapped if m > 0
    out = [[a[i][0] * b[0][j] + a[i][1] * b[1][j] for j in range(2)] for i in range(2)]
    return [[v % m for v in row] for row in out] if m else out

def power(a, n, m=0):                       # road two: square and multiply
    out, mults = [[1, 0], [0, 1]], -1       # the opening multiply by the identity is free
    while n:
        if n & 1: out, mults = mul(out, a, m), mults + 1
        n >>= 1
        if n: a, mults = mul(a, a, m), mults + 1
    return out, max(mults, 0)

def step(n, m=0):                           # road three: one foot at a time
    a, b, adds = 1, 1, 0                    # T(0) = 1 empty hallway, T(1) = 1
    for _ in range(n - 1): a, b, adds = b, (a + b) % m if m else a + b, adds + 1
    return b, adds

brute, (p10, mults), (stepped, adds) = tilings(N), power(M, N), step(N)
r5 = 2.0
for _ in range(40): r5 = (r5 + 5.0 / r5) / 2            # our own square root of 5, by Newton
phi, psi, fp, fq = (1 + r5) / 2, (1 - r5) / 2, 1.0, 1.0
for _ in range(N + 1): fp, fq = fp * phi, fq * psi      # the two roots to the 11th, by hand
binet = (fp - fq) / r5
det_m = M[0][0] * M[1][1] - M[0][1] * M[1][0]; det_pow = det_m ** N
cassini = p10[0][0] * p10[1][1] - p10[0][1] * p10[1][0]
(far_pow, far_mults), (far_step, far_adds) = power(M, FAR, MOD), step(FAR, MOD)
wrong, entry = power([[1, 1], [0, 1]], N)[0], [[v ** N for v in row] for row in M]
print(f"hallway 2 feet wide, {N} feet long, tiles 1 x 2: {brute} tilings, laid one by one")
print("the ladder: " + ", ".join(f"M^{e} = {power(M, e)[0]}" for e in (1, 2, 4, 8)))
print(f"M^{N} = " + " x ".join(f"M^{1 << i}" for i in reversed(range(N.bit_length())) if N >> i & 1)
      + f" = {p10}, reached in {mults} matrix multiplications")
print(f"the stacks: ({p10[0][1]}, {p10[1][1]}) -> ({p10[0][0]}, {p10[0][1]}) -> ({p10[0][0] + p10[0][1]}, {p10[0][0]})")
print(f"stepping the rule one foot at a time: {stepped} at {N} feet, in {adds} additions")
print(f"trace {M[0][0] + M[1][1]}, determinant {det_m}; eigenvalues {phi:.12f} and {psi:.12f}")
print(f"each eigenvalue squared, minus itself: {phi * phi - phi:.12f} and {psi * psi - psi:.12f}")
print(f"Binet from those roots at {N + 1}: {binet:.9f}, rounding to {round(binet)}")
print(f"Cassini: {p10[0][0]} x {p10[1][1]} - {p10[0][1]} x {p10[1][0]} = {cassini}, and ({det_m})^{N} = {det_pow}")
print(f"term {FAR} wrapped at {MOD}, by squaring: {far_pow[0][0]}, in {far_mults} matrix multiplications")
print(f"the same term, by {far_adds} additions: {far_step}")
print(f"mistake 1, the matrix written [[1, 1], [0, 1]]: {wrong}, top-left {wrong[0][0]}, not {brute}")
print(f"mistake 2, each entry raised to the {N}th on its own: {entry}, top-left {entry[0][0]}; "
      f"mistake 3, the stack (1, 1) carried through M^{N}: {p10[0][0] + p10[0][1]}, one foot too far")
assert brute == p10[0][0] == stepped == round(binet)      # four roads, one count
assert cassini == det_pow and far_pow[0][0] == far_step and far_mults == FAR.bit_count() + FAR.bit_length() - 2 < far_adds
assert abs(phi + psi - (M[0][0] + M[1][1])) < 1e-12 and abs(phi * psi - det_m) < 1e-12
assert mults == N.bit_count() + N.bit_length() - 2 < adds and abs(phi * phi - phi - 1) < 1e-12
print("ALL CHECKS PASS")
