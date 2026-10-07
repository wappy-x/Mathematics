# The layer-cake formula -- the check behind the card.  Standard library only.
# A dart lands uniformly on a 1 m by 1 m board; M = max(x, y) is its larger
# coordinate, with tail P(M > t) = 1 - t^2.  The moments of M are found by the
# tail integral, by a double integral on the board, by exact enumeration on
# finite grids and by a seeded simulation; the failures are printed as well.
from fractions import Fraction as Fr
from math import log, sqrt

def integral(p, a=Fr(0), b=Fr(1)):     # exact integral over [a, b] of a polynomial, lowest power first
    return sum(c * (b ** (m + 1) - a ** (m + 1)) / (m + 1) for m, c in enumerate(p))

def pmul(p, q):                        # multiply two polynomials
    out = [Fr(0)] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            out[i + j] += a * b
    return out

def mono(c, k):                        # c t^k as a coefficient list
    return [Fr(0)] * k + [Fr(c)]

TAIL = [Fr(1), Fr(0), Fr(-1)]          # P(M > t) = 1 - t^2 on [0, 1], and 0 from t = 1 on
# road 1, the tail: E[M^p] = integral of p t^(p-1) P(M > t) dt
tail_road = {p: integral(pmul(mono(p, p - 1), TAIL)) for p in (1, 2, 3)}
# road 2, the board: where y < x the max is x, the strip under it has length x,
# and the half where x < y gives the same again
board_road = {p: 2 * integral(pmul(mono(1, p), [Fr(0), Fr(1)])) for p in (1, 2, 3)}
print("moment | tail integral | on the board | decimal")
for p in (1, 2, 3):
    print(f"E[M^{p}] | {tail_road[p]} | {board_road[p]} | {float(tail_road[p]):.4f}")
var = tail_road[2] - tail_road[1] ** 2
print(f"variance E[M^2] - E[M]^2 = {tail_road[2]} - {tail_road[1] ** 2} = {var} = {float(var):.4f} m^2, sd {sqrt(var):.4f} m")
half = Fr(1, 2)
tail_k = integral(TAIL, half)                            # integral of P(M > t) from 0.5 to 1
board_k = 2 * integral(pmul([-half, Fr(1)], [Fr(0), Fr(1)]), half)
print(f"shifted, E[(M - 0.5)^+]: tail from 0.5 = {tail_k}, on the board = {board_k} = {float(tail_k):.4f}")
markov = half * sum(c * half ** m for m, c in enumerate(TAIL))   # the rectangle t P(M > t) under the tail curve
print(f"markov, rectangle 0.5 x P(M > 0.5) = {markov} = {float(markov):.4f} <= E[M] = {float(tail_road[1]):.4f}")

print("grid n | direct average | layer-cake sum | (n+1)(4n-1)/(6n^2) | excess over 2/3 | bound 1/(2n)")
grid = []
for n in (2, 4, 10, 100):              # the dart's coordinates rounded up to multiples of 1/n
    pts = [(i, j) for i in range(1, n + 1) for j in range(1, n + 1)]
    direct = sum(Fr(max(i, j), n) for i, j in pts) / n ** 2
    layer = sum(Fr(sum(1 for i, j in pts if max(i, j) > k), n ** 2) for k in range(n)) / n
    closed = Fr((n + 1) * (4 * n - 1), 6 * n * n)
    grid.append((n, direct, layer, closed))
    print(f"n = {n:3} | {direct} | {layer} | {closed} | {float(direct - Fr(2, 3)):.6f} | {1 / (2 * n):.6f}")
pts4 = [(i, j) for i in range(1, 5) for j in range(1, 5)]
sq_direct = sum(Fr(max(i, j) ** 2, 16) for i, j in pts4) / 16
sq_layer = sum(Fr(sum(1 for i, j in pts4 if max(i, j) > k), 16) * Fr(2 * k + 1, 16) for k in range(4))
print("grid n = 4, points with max 1/4, 2/4, 3/4, 1: " + ", ".join(str(sum(1 for i, j in pts4 if max(i, j) == k)) for k in range(1, 5))
      + "; points with max > 0, 1/4, 2/4, 3/4: " + ", ".join(str(sum(1 for i, j in pts4 if max(i, j) > k)) for k in range(4)))
print(f"grid n = 4, E[M^2]: direct {sq_direct}, layer-cake with weight 2t {sq_layer}")

ts = [k / 10 for k in range(11)]
print("chart, t = " + ", ".join(f"{t:.1f}" for t in ts))
print("chart, tail 1 - t^2 = " + ", ".join(f"{1 - t * t:.2f}" for t in ts))
print("chart, weighted 2t(1 - t^2) = " + ", ".join(f"{2 * t * (1 - t * t):.2f}" for t in ts))

state, N = 2026, 100000                # SplitMix64, seed 2026, two draws per dart
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
s = [0.0] * 6                          # sums of M, M^2, [M > 0.5], (M - 0.5)^+, x - y, (x - y)^+
for _ in range(N):
    x, y = uniform(), uniform()
    m = max(x, y)
    for i, v in enumerate((m, m * m, float(m > 0.5), max(m - 0.5, 0.0), x - y, max(x - y, 0.0))):
        s[i] += v
sim = [v / N for v in s]
se = [sqrt(v / N) for v in (1 / 18, 1 / 12, 3 / 16, 1 / 18)]   # standard errors from exact variances
print(f"simulation, {N} darts: E[M] {sim[0]:.4f}, E[M^2] {sim[1]:.4f}, P(M > 0.5) {sim[2]:.4f}, "
      f"E[(M - 0.5)^+] {sim[3]:.4f}; standard errors {se[0]:.4f}, {se[1]:.4f}, {se[2]:.4f}")
print(f"simulation, signed D = x - y: E[D] {sim[4]:.4f}, E[D^+] {sim[5]:.4f}, standard error {se[3]:.4f}")

d_tail = [half, Fr(-1), half]          # P(D > t) = (1 - t)^2 / 2, and P(D < -t) is the same
pos, neg = integral(d_tail), integral(d_tail)
print(f"break, signed D = x - y: positive tail alone {pos}, true E[D] = {pos - neg} (positive tail {pos} minus negative tail {neg})")
print(f"break, E[M^2] without the weight 2t: integral of the tail {integral(TAIL)}, "
      f"integral of t times the tail {integral(pmul(mono(1, 1), TAIL))}; true {tail_road[2]}")
print(f"break, integrating P(M <= t) instead of the tail: {integral(mono(1, 2))}, not {tail_road[1]}")

def midpoint(f, a, b, steps):          # composite midpoint rule
    h = (b - a) / steps
    return h * sum(f(a + (k + 0.5) * h) for k in range(steps))
print("heavy tail Y = 1/x, cut at T | tail integral to T | E[min(Y, T)] on the board | 1 + ln T")
heavy = []
for T in (10.0, 100.0, 1000.0):
    by_tail = midpoint(lambda t: min(1.0, 1.0 / t), 0.0, T, 200000)
    on_board = midpoint(lambda u: min(1.0 / u, T), 0.0, 1.0, 200000)
    heavy.append((by_tail, on_board, 1 + log(T)))
    print(f"T = {T:6.0f} | {by_tail:.4f} | {on_board:.4f} | {1 + log(T):.4f}")
print(f"figure, x = 40 + 160 u, y = 180 - 160 v; board (40, 20) to (200, 180); "
      f"inner square to ({40 + 160 * 0.5:.0f}, {180 - 160 * 0.5:.0f}), area {0.5 * 0.5:.2f}; "
      f"shaded L area {1 - 0.5 * 0.5:.2f}; dart (0.3, 0.8) at ({40 + 160 * 0.3:.0f}, {180 - 160 * 0.8:.0f}), max 0.8")

assert tail_road == board_road                                  # tail road against the board, three moments
assert tail_road[1] == Fr(2, 3) and tail_road[2] == Fr(1, 2)
assert tail_k == board_k == Fr(5, 24)                           # shifted tail against a direct payoff
assert all(d == l == c for _, d, l, c in grid)                  # exact finite layer cake, three ways
assert all(0 < d - Fr(2, 3) <= Fr(1, 2 * n) for n, d, _, _ in grid)
assert sq_direct == sq_layer == Fr(85, 128)
assert abs(sim[0] - 2 / 3) < 4 * se[0] and abs(sim[1] - 0.5) < 4 * se[1]
assert abs(sim[2] - 0.75) < 4 * se[2] and abs(sim[3] - 5 / 24) < 0.002
assert abs(float(markov) - 0.5 * sim[2]) < 2 * se[2]           # Markov rectangle against 0.5 x simulated P(M > 0.5)
assert abs(sim[5] - float(pos)) < 4 * se[3] and abs(sim[4] - float(pos - neg)) < 4 * sqrt(1 / (6 * N))   # simulated D^+, D against tails
assert all(abs(a - b) < 1e-4 and abs(a - c) < 1e-4 for a, b, c in heavy)
print("ALL CHECKS PASS")
