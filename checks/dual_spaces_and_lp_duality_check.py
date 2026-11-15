# Dual spaces and Lp duality -- the check behind the card. Standard library only.
# A cafe's day of hourly sales, scored by a weighted rule. Every number on the
# card is printed here. A rule's norm is found by the dual-norm formula and,
# separately, by brute force over the unit ball's corners or the extremal list.
import math

X = [120, 340, 260, 410, 380, 150, 90, 250]   # sales in pounds, 9:00 to 17:00
W = [1.5, 1, 1, 0.5, 0.5, 1, 1.5, 1]          # head office's weight per hour
INF = math.inf

def size(v, p):
    if p == INF:
        return max(abs(a) for a in v)
    return sum(abs(a) ** p for a in v) ** (1 / p)

def rule(w, v):
    return sum(a * b for a, b in zip(w, v))

def conj(p):
    return INF if p == 1 else 1.0 if p == INF else p / (p - 1)

def name(p):
    return "inf" if p == INF else f"{p:g}"

def signs(n):
    return [[1 if (k >> i) & 1 else -1 for i in range(n)] for k in range(2 ** n)]

state = 20261115
def unif():  # SplitMix64, seed 20261115, uniform on [-1, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    z ^= z >> 31
    return (z >> 11) / 2.0 ** 53 * 2 - 1

score = rule(W, X)
print(f"day: score {score:.2f}  total {size(X, 1):.2f}  busiest {size(X, INF):.2f}  root-sum-square {size(X, 2):.6f}")
print("hourly score w_n x_n " + " ".join(f"{a * b:g}" for a, b in zip(W, X)))
print("size rule p | rule norm ||w||_q | brute force | Holder ceiling ||w||_q ||x||_p")
norms = {}
for p in [1, 2, 3, INF]:
    q = conj(p)
    formula = size(W, q)
    if p == 1:        # corners of the l1 ball: +-e_n
        brute = max(abs(rule(W, [1 if j == i else 0 for j in range(8)])) for i in range(8))
    elif p == INF:    # corners of the sup ball: the 256 sign lists
        brute = max(rule(W, s) for s in signs(8))
    else:             # the extremal list x_n = |w_n|^(q-1), then a random search
        ext = [abs(a) ** (q - 1) for a in W]
        brute = rule(W, ext) / size(ext, p)
        best = 0.0
        for _ in range(20000):
            v = [unif() for _ in range(8)]
            best = max(best, abs(rule(W, v)) / size(v, p))
        print(f"  p={name(p)}: best of 20000 random lists {best:.6f}, never above {formula:.6f}")
        assert best <= formula + 1e-12 and best > 0.9 * formula
    assert abs(brute - formula) < 1e-9 and score <= formula * size(X, p) + 1e-9
    norms[p] = formula
    print(f"p={name(p):>3} q={name(q):>3} | {formula:.6f} | {brute:.6f} | {formula * size(X, p):.2f}")
assert abs(norms[2] - 3) < 1e-12 and abs(norms[1] - 1.5) < 1e-12 and abs(norms[INF] - 8) < 1e-12

# transpose: S = running totals; psi reads the running total at noon and at close
S = [[1 if j <= i else 0 for j in range(8)] for i in range(8)]
ST = [[S[j][i] for j in range(8)] for i in range(8)]
apply = lambda A, v: [rule(row, v) for row in A]
psi = [0, 0, 1, 0, 0, 0, 0, 1]
Sx, pulled = apply(S, X), apply(ST, psi)
print("running totals Sx " + " ".join(str(a) for a in Sx))
print("pulled-back weights S^t psi " + " ".join(str(a) for a in pulled))
print(f"psi(Sx) {rule(psi, Sx)}  (S^t psi)(x) {rule(pulled, X)}")
assert rule(psi, Sx) == rule(pulled, X) == 2720
normS = max(size([S[i][j] for i in range(8)], 1) for j in range(8))   # ||S|| on l1, columns
normST = max(size(apply(ST, s), INF) for s in signs(8))               # ||S^t|| on sup, corners
print(f"||S|| on l1 by columns {normS:g}  ||S^t|| on sup by 256 corners {normST:g}")
assert normS == normST == 8

# annihilator: reshuffles (total 0) are killed exactly by multiples of the total
r = [0, 0, 0, -50, 0, 0, 50, 0]            # move 50 pounds from 12:00 to 15:00
D = [[(1 if i == j else 0) - 1 / 8 for j in range(8)] for i in range(8)]   # deviation from the mean; D^t = D
print(f"reshuffle: head office rule {rule(W, r):g}  total-takings rule {rule([1] * 8, r):g}")
print(f"D^t on the all-ones rule, largest entry {max(abs(a) for a in apply(D, [1] * 8)):.6f}")
assert rule(W, r) == 50 and rule([1] * 8, r) == 0 and max(abs(a) for a in apply(D, W)) > 0.4
assert max(abs(a) for a in apply(D, [1] * 8)) < 1e-12   # ker D^t = (ran D)^perp holds the total

# infinite dimensions: weights 1/n on an endless list of hours, cut to N
gamma = 0.5772156649015329
print(f"weights 1/n; pi/sqrt6 = {math.pi / math.sqrt(6):.6f}")
print("N | l2 rule norm | gap to pi/sqrt6 | sup-size rule norm H_N | ln N + gamma | l2 tail of 1/n")
for k in [1, 2, 3, 4]:
    N = 10 ** k
    s1 = sum(1 / m for m in range(1, N + 1))
    s2 = sum(1 / m ** 2 for m in range(1, N + 1))
    gap = math.pi / math.sqrt(6) - math.sqrt(s2)
    tail = math.sqrt(math.pi ** 2 / 6 - s2)
    print(f"{N:>5} | {math.sqrt(s2):.6f} | {gap:.6f} | {s1:.6f} | {math.log(N) + gamma:.6f} | {tail:.6f}")
    assert 0 < gap < 0.5 / N and abs(s1 - math.log(N) - gamma - 1 / (2 * N)) < 1 / N ** 2
    assert abs(tail * math.sqrt(N) - 1) < 1 / N
lim = lambda v: v[-1]          # the limit reading, on lists that are constant after hour N
N = 1000
weights = [lim([1 if j == i else 0 for j in range(N + 1)]) for i in range(N)]
ones = [1] * (N + 1)
cut_gap = size([a - (1 if i < N else 0) for i, a in enumerate(ones)], INF)
print(f"limit rule: weights lim(e_n) all {max(weights)}, weighted sum on all-ones {rule(weights, ones)}, "
      f"limit {lim(ones)}; sup gap from all-ones to its cut {cut_gap}")
assert rule(weights, ones) == 0 and lim(ones) == 1 and cut_gap == 1

# C[0, 8]: the noon reading f(3) against any weight function, here the step g = w
g = lambda t: W[min(int(t), 7)]
alpha = [0.0]                                  # alpha(t) = integral of g from 0 to t, on a grid of 800
for k in range(800):
    alpha.append(alpha[-1] + g((k + 0.5) / 100) / 100)
alpha_tv = sum(abs(alpha[k + 1] - alpha[k]) for k in range(800))
print(f"weight rule on C: value on f = 1 is {rule(W, [1] * 8):g}, total variation of alpha {alpha_tv:.6f}")
assert abs(alpha_tv - norms[INF]) < 1e-9
for N in [10, 100, 1000]:
    h, M = 1 / N, 2000
    tent = lambda t: max(0.0, 1 - abs(t - 3) / h)
    integral = sum(g(3 - h + (i + 0.5) * 2 * h / M) * tent(3 - h + (i + 0.5) * 2 * h / M) for i in range(M)) * 2 * h / M
    print(f"tent half-width 1/{N}: noon reading {tent(3):g}, weight rule {integral:.6f}")
    assert abs(integral - 0.75 * h) < 1e-9
# what breaks
print(f"wrong: same exponent p on the weights, busiest-hour ceiling {size(W, INF) * size(X, INF):.2f} < score {score:.2f}")
print(f"wrong: pull back with S, not S^t: {rule(apply(S, psi), X)} instead of 2720")
W2 = W[:6] + [3] + W[7:]
print(f"try: weight 3 at 15:00: score {rule(W2, X):g}, rule norm on total takings {size(W2, INF):g}")
psi2 = [0, 0, 0, 0, 1, 0, 0, 1]
print(f"try: read the running total at 14:00 and close: weights {' '.join(str(a) for a in apply(ST, psi2))}, "
      f"score {rule(psi2, apply(S, X))}")
print(f"try: weights 1/n^2, sup-size rule norm at N = 10000 {sum(1 / m ** 2 for m in range(1, 10001)):.6f}, "
      f"limit pi^2/6 {math.pi ** 2 / 6:.6f}")
print("ALL CHECKS PASS")
