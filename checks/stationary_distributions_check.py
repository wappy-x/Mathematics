# Stationary distributions -- the check behind the card.  Nothing is imported.
# A town's days are sunny, cloudy or rainy; tomorrow depends only on today.
# Three roads to the long-run share of each kind of day: the balance equations
# solved exactly; mean return times from first-step equations (share = 1/return
# time); and 100000 simulated days, with a standard error from blocks of days.
from fractions import Fraction as Fr

NAMES = ("sunny", "cloudy", "rainy")
TENTHS = [[6, 3, 1], [4, 4, 2], [4, 3, 3]]    # row = today, column = tomorrow
P = [[Fr(x, 10) for x in row] for row in TENTHS]
DAYS, BLOCKS, SEED = 100000, 100, 20260929
MASK = (1 << 64) - 1

def solve(A, b):                               # exact Gaussian elimination
    n = len(A)
    M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        piv = next(r for r in range(c, n) if M[r][c] != 0)
        M[c], M[piv] = M[piv], M[c]
        for r in range(n):
            if r != c and M[r][c] != 0:
                f = M[r][c] / M[c][c]
                M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def balance(P, left=True):                     # pi P = pi (left) or P x = x (right), sum 1
    n = len(P)
    A = [[(P[i][j] if left else P[j][i]) - (1 if i == j else 0) for i in range(n)] for j in range(n)]
    A[-1] = [Fr(1)] * n                        # one balance equation is spare: swap in the total
    return solve(A, [Fr(0)] * (n - 1) + [Fr(1)])

def mean_return(P, j):                         # first-step equations for days until j
    others = [i for i in range(len(P)) if i != j]
    A = [[(1 if a == b else 0) - P[a][b] for b in others] for a in others]
    h = dict(zip(others, solve(A, [Fr(1)] * len(others))))
    return 1 + sum(P[j][k] * h[k] for k in others)

def vecmat(v, P):
    return [sum(v[i] * P[i][j] for i in range(len(v))) for j in range(len(P[0]))]

class SplitMix64:
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def step(g, today):
    u, acc = g.uniform(), 0
    for j in range(3):
        acc += TENTHS[today][j]
        if u < acc / 10: return j
    return 2

pi = balance(P)
print("table P, rows today sunny, cloudy, rainy: " + "; ".join(", ".join(f"{float(x):.1f}" for x in row) for row in P))
print("road 1, balance equations: " + ", ".join(f"{NAMES[i]} {pi[i]}" for i in range(3)))
m = [mean_return(P, j) for j in range(3)]
print("road 2, mean days between visits: " + ", ".join(f"{NAMES[j]} {m[j]}" for j in range(3)))
print("road 2, one over those: " + ", ".join(f"{NAMES[j]} {1 / m[j]}" for j in range(3)))
assert [1 / x for x in m] == pi                # two exact roads agree
assert vecmat(pi, P) == pi                     # includes the balance equation that was swapped out
print(f"hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = {pi[0]}")
pr = (P[0][2] * pi[0] + P[1][2] * (1 - pi[0])) / (1 - P[2][2] + P[1][2])   # rainy balance, pi_C = 1/2 - pi_R
assert pr == pi[2]                             # the hand route lands on road 1
print(f"hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = {pr}")
print(f"hand, spare cloudy equation: {float(pi[0] * P[0][1]):.4f} + {float(pi[1] * P[1][1]):.4f} + {float(pi[2] * P[2][1]):.4f} = {vecmat(pi, P)[1]}")
print(f"rainy days in a 365-day year: {float(365 * pi[2]):.2f}")
print("excursion from rain, expected days of each kind, pi times m_R: " + ", ".join(str(x * m[2]) for x in pi))
print(f"detailed balance fails: pi_S p_SR = {float(pi[0] * P[0][2]):.4f}, pi_R p_RS = {float(pi[2] * P[2][0]):.4f}")
print("flow, out of rainy per day: " + f"{pi[2] * (1 - P[2][2])}; into rainy: {pi[0] * P[0][2] + pi[1] * P[1][2]}")

g, today, counts, blk, cur = SplitMix64(SEED), 0, [0, 0, 0], [], [0, 0, 0]
marks = (10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000)
running = []
for d in range(1, DAYS + 1):                   # day 0 is sunny; count days 1 .. DAYS
    today = step(g, today)
    counts[today] += 1
    cur[today] += 1
    if d % (DAYS // BLOCKS) == 0: blk.append(cur); cur = [0, 0, 0]
    if d in marks: running.append(100 * counts[2] / d)
print("figure, rainy days per 100, running, days " + ", ".join(map(str, marks)) + ": " + ", ".join(f"{x:.2f}" for x in running) + f"; exact {100 * float(pi[2]):.2f}")
frac = [c / DAYS for c in counts]
bs = DAYS // BLOCKS
ses = [(sum((b[i] / bs - frac[i]) ** 2 for b in blk) / (BLOCKS - 1) / BLOCKS) ** 0.5 for i in range(3)]
se = ses[2]
naive = (frac[2] * (1 - frac[2]) / DAYS) ** 0.5
print("road 3, simulated shares of 100000 days: " + ", ".join(f"{NAMES[i]} {frac[i]:.4f} +- {ses[i]:.4f}" for i in range(3)))
print(f"road 3, rainy share {frac[2]:.4f} +- {se:.4f} (100 blocks of 1000 days); naive iid s.e. {naive:.4f}")
print(f"road 3, rainy days {counts[2]}, days per rainy day, simulated: {DAYS / counts[2]:.2f} +- {se / frac[2] ** 2:.2f}; exact mean return {m[2]}")
assert all(abs(frac[i] - float(pi[i])) < 4 * ses[i] for i in range(3))   # simulation against the exact shares

v = [1.0, 0.0, 0.0]
fc = {}
for n in range(1, 61):
    v = vecmat(v, [[float(x) for x in r] for r in P])
    fc[n] = v[2]
print("forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: " + ", ".join(f"{fc[n]:.4f}" for n in (1, 2, 3, 5, 10)))
assert abs(fc[60] - float(pi[2])) < 1e-12      # this chain's forecasts settle (next card: why)

print(f"mistake, column convention P x = x: rainy {balance(P, left=False)[2]} (uniform, since rows sum to 1)")
print(f"mistake, average of the rain column: {sum(P[i][2] for i in range(3)) / 3}")
print(f"mistake, rain after rain read as the share: {P[2][2]}")
ROTA = [[Fr(0), Fr(1), Fr(0)], [Fr(0), Fr(0), Fr(1)], [Fr(1), Fr(0), Fr(0)]]
rp = balance(ROTA)
print("rota sunny -> cloudy -> rainy -> sunny: stationary " + ", ".join(str(x) for x in rp))
v, st, seen, fcr, frr = [Fr(1), Fr(0), Fr(0)], 0, 0, [], []
for n in range(1, 13):
    v = vecmat(v, ROTA); st = (st + 1) % 3; seen += st == 2
    fcr.append(100 * v[2]); frr.append(100 * seen / n)
print("figure, rota, chance of rain on day n (per 100), n = 1..12: " + ", ".join(f"{float(x):.2f}" for x in fcr))
print("figure, rota, rainy days per 100 up to day n, n = 1..12: " + ", ".join(f"{x:.2f}" for x in frr))
assert fcr[9] == 0 and fcr[10] == 100         # day 10 dry for sure, day 11 wet for sure: no settling
assert abs(frr[-1] - 100 * float(rp[2])) < 1e-9   # yet the share of rainy days is the stationary 1/3
SPLIT = [[Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(0), Fr(0), Fr(1)]]
a, b = [Fr(1, 2), Fr(1, 2), Fr(0)], [Fr(0), Fr(0), Fr(1)]
assert vecmat(a, SPLIT) == a and vecmat(b, SPLIT) == b
print("split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1")
z, s6, hf = Fr(0), Fr(1, 6), Fr(1, 2)          # classifying-states' board: start S, ring A, B, C, jail J
BOARD = [[1 - s6, s6, z, z, z], [z, z, hf, z, hf], [z, hf, z, hf, z], [z, z, hf, z, hf], [z, s6, z, z, 1 - s6]]
bp = balance(BOARD)
print("one closed class plus a transient start (classifying-states' board, S A B C J): stationary " + ", ".join(str(x) for x in bp))
assert bp[0] == 0                              # the transient start gets share 0
assert vecmat(bp, BOARD) == bp                 # includes the balance equation that was swapped out
TRY = [[Fr(x, 10) for x in row] for row in ([6, 3, 1], [4, 4, 2], [2, 3, 5])]
print("try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): " + ", ".join(str(x) for x in balance(TRY)) + f"; rain returns every {mean_return(TRY, 2)} days")
r = [40 * (float(x) / 0.5) ** 0.5 for x in pi]
print("figure, circle radius 40 sqrt(share / 0.5): " + ", ".join(f"{NAMES[i]} {r[i]:.2f}" for i in range(3)) + "; centres (80, 160), (280, 160), (180, 62)")
print("ALL CHECKS PASS")
