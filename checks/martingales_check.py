# Martingales -- the check behind the card.  Standard library only.
# A gambler starts with $10 and bets $1 a round on a fair coin.  The fortune
# X_n and the process X_n^2 - n are checked to be martingales three ways: the
# one-step forecast by formula, every history of 10 rounds enumerated in exact
# integers, and 20000 simulated gamblers drawn from SplitMix64, seed 2026.
# Roulette odds (red wins 18 times in 37) give the supermartingale.
from math import sqrt

X0, N, G, R = 10, 10, 20000, 100
P_RED = 18 / 37
MASK = (1 << 64) - 1
state = 2026

def draw():                                  # SplitMix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def uniform():                               # 53 random bits in [0, 1)
    return (draw() >> 11) / 9007199254740992.0

# ---- road 1: the one-step forecast, by formula, from a fortune of x ----
def fair_next(x):    return 0.5 * (x + 1) + 0.5 * (x - 1)
def fair_next_sq(x): return 0.5 * (x + 1) ** 2 + 0.5 * (x - 1) ** 2
def red_next(x):     return P_RED * (x + 1) + (1 - P_RED) * (x - 1)

# ---- road 2: every history of N rounds, exact integer sums ----
# path p: bit k (first round = highest bit) is 1 for a win.  X[p][m] = fortune after m rounds.
X = []
for p in range(1 << N):
    row = [X0]
    for k in range(N):
        row.append(row[-1] + (1 if (p >> (N - 1 - k)) & 1 else -1))
    X.append(row)
wins = [bin(p).count("1") for p in range(1 << N)]
w_red = [18 ** wins[p] * 19 ** (N - wins[p]) for p in range(1 << N)]   # roulette weights, total 37^N

checks = fair_ok = sq_ok = sub_ok = red_ok = steps = agree = 0
for n in range(N + 1):
    size = 1 << (N - n)                      # paths sharing one history of n rounds
    for cell in range(1 << n):
        paths = range(cell * size, (cell + 1) * size)
        xn = X[cell * size][n]
        wsum = sum(w_red[p] for p in paths)
        for m in range(n, N + 1):
            checks += 1
            sx = sum(X[p][m] for p in paths)
            sq = sum(X[p][m] ** 2 for p in paths)
            fair_ok += sx == size * xn                                   # E[X_m | F_n] = X_n
            sq_ok += sq - size * m == size * (xn * xn - n)               # X^2 - n keeps its forecast
            sub_ok += sq - size * xn * xn == size * (m - n)              # X^2 alone rises by m - n
            swx = sum(w_red[p] * X[p][m] for p in paths)
            red_ok += 37 * swx == 37 * wsum * xn - (m - n) * wsum        # roulette: drops 1/37 a round
            if m == n + 1:                                               # road 1 against road 2
                steps += 1
                agree += abs(sx / size - fair_next(xn)) < 1e-12 and abs(swx / wsum - red_next(xn)) < 1e-12
mean_sq_10 = sum(X[p][N] ** 2 for p in range(1 << N)) / (1 << N)
half = 1 << (N - 1)                      # the insider knows toss 1 at round 0: two cells of 512 paths
ins_sum = [sum(X[q][1] for q in range(c * half, (c + 1) * half)) for c in (0, 1)]   # 512 E[X_1 | toss 1]
insider_off = sum(1 for p in range(1 << N) if ins_sum[p >> (N - 1)] != half * X[p][0])   # forecast vs X_0

# ---- road 3: simulated gamblers ----
path0 = []
s1 = s2 = s3 = s4 = 0.0
c14 = c14_next = c14_next_sq = 0
for g in range(G):
    x = X0
    for r in range(1, R + 1):
        x += 1 if draw() >> 63 else -1
        if g == 0 and r <= 40: path0.append(x)
        if r == 50: x50 = x
        if r == 51 and x50 == 14:
            c14 += 1; c14_next += x; c14_next_sq += x * x
    y = x * x - R
    s1 += x; s2 += x * x; s3 += y; s4 += y * y
red_s1 = red_s2 = 0.0
for g in range(G):
    x = X0
    for r in range(R):
        x += 1 if uniform() < P_RED else -1
    red_s1 += x; red_s2 += x * x

def mean_se(s, ss, k):
    m = s / k
    return m, sqrt((ss - k * m * m) / (k - 1) / k)

mx, sex = mean_se(s1, s2, G)
my, sey = mean_se(s3, s4, G)
m51, se51 = mean_se(c14_next, c14_next_sq, c14)
mred, sered = mean_se(red_s1, red_s2, G)
exact_red = X0 - R / 37

print(f"road 1, from $12 the next fortune is 13 or 11, averaging {fair_next(12):.4f}")
print(f"road 1, its square is 169 or 121, averaging {fair_next_sq(12):.4f}  (= 144 + 1)")
print(f"road 1, forecast of the next fortune from $12, roulette:  {red_next(12):.4f}  (= 12 - 1/37)")
print(f"road 2, {1 << N} histories, {checks} (cell, later time) pairs checked")
print(f"  E[X_m | F_n] = X_n held:            {fair_ok} of {checks}")
print(f"  E[X_m^2 - m | F_n] = X_n^2 - n held: {sq_ok} of {checks}")
print(f"  X^2 forecast rose by exactly m - n:  {sub_ok} of {checks}")
print(f"  roulette forecast fell by (m - n)/37: {red_ok} of {checks}")
print(f"  one-round cell averages equal road 1: {agree} of {steps}")
print(f"  E[X_10^2] = {mean_sq_10:.4f}, so Var(X_10) = {mean_sq_10 - X0 * X0:.4f}")
print(f"road 3, {G} gamblers, {R} rounds each, seed 2026")
print(f"  mean X_100          {mx:.4f}  se {sex:.4f}  (exact 10)")
print(f"  mean X_100^2 - 100  {my:.4f}  se {sey:.4f}  (exact 100)")
print(f"  mean X_100^2        {my + R:.4f}  se {sey:.4f}  (exact 200, so Var = 100, sd 10)")
print(f"  {c14} gamblers at $14 after round 50: mean X_51 {m51:.4f}  se {se51:.4f}")
print(f"roulette, mean X_100  {mred:.4f}  se {sered:.4f}  (exact {exact_red:.4f})")
print(f"roulette, one-round forecast factor of (19/18)^X: {P_RED * 19 / 18 + (1 - P_RED) * 18 / 19:.12f}")
print("what breaks:")
print(f"  house edge, forecast after one round from $10: {red_next(10):.4f}; after 100 rounds {exact_red:.4f}")
print(f"  squared fortune without the -n: E[X_100^2] = {X0 * X0 + R}, not {X0 * X0}")
print(f"  insider who sees the next toss: forecast differs from X_0 on {insider_off} of {1 << N} paths")
print("figure, path of gambler 0, rounds 0 to 40:", ", ".join(str(v) for v in [X0] + path0))
print("figure, upper band 10 + sqrt(n):", ", ".join(f"{X0 + sqrt(n):.2f}" for n in range(41)))
print("figure, lower band 10 - sqrt(n):", ", ".join(f"{X0 - sqrt(n):.2f}" for n in range(41)))
print("figure, parabola s^2 from s = -2 to 2: M 50 40 Q 150 360 250 40; s = -1, 0, 1 at (100,160) (150,200) (200,160); chord midpoint (150,160); gap 1 = 40 px")

assert fair_ok == checks                                          # the fortune: enumeration vs X_n
assert sq_ok == checks                                            # X^2 - n: enumeration vs X_n^2 - n
assert sub_ok == checks                                           # X^2 rises by exactly m - n
assert red_ok == checks                                           # roulette drops by exactly 1/37
assert agree == steps                                             # road 1 against road 2
assert mean_sq_10 == X0 * X0 + N                                  # E[X_10^2] against 100 + 10
assert abs(mx - X0) < 4 * sex                                     # road 3 against exact values
assert abs(my - X0 * X0) < 4 * sey
assert abs(m51 - 14) < 4 * se51
assert abs(mred - exact_red) < 4 * sered
print("ALL CHECKS PASS")
