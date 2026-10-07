# Riesz-Fischer -- the check behind the card.  Standard library only.
# The example: t = (1, 1/2, 1/3, ...) in l2, which is L2 of counting measure on
# 1, 2, 3, ..., and its truncations t_N.  Road one reaches ||t||_2 through pi
# (Machin's formula) and a square root (Newton), both written here; road two
# sums 1/n^2 directly and adds the Euler-Maclaurin tail.  The wind week and
# the ramps use exact fractions.  Code checks finite stages; the proof does
# the rest.
from fractions import Fraction as Q

def atan_inv(x, terms=40):              # arctan(1/x) by its power series
    s, p = 0.0, 1.0 / x
    for k in range(terms):
        s += (-1) ** k * p / (2 * k + 1)
        p /= x * x
    return s

def sqrt(a):                            # Newton's method for the square root
    if a == 0:
        return 0.0
    r = max(a, 1.0)
    for _ in range(80):
        r = 0.5 * (r + a / r)
    return r

PI = 4 * (4 * atan_inv(5) - atan_inv(239))
Z1 = PI * PI / 6                        # road one: sum of 1/n^2 is pi^2/6
M = 4000
H2 = [0.0]                              # H2[N] = 1 + 1/4 + ... + 1/N^2
for n in range(1, M + 1):
    H2.append(H2[-1] + 1.0 / (n * n))

def tail2(N):                           # road one: sum over n > N of 1/n^2
    return Z1 - H2[N]

def tail2_direct(N):                    # road two: sum to M, Euler-Maclaurin after
    s = sum(1.0 / (n * n) for n in range(M, N, -1))
    return s + 1 / M - 1 / (2 * M * M) + 1 / (6 * M ** 3) - 1 / (30 * M ** 5)

print(f"pi by Machin's formula {PI:.8f}")
print(f"||t||_2 = pi/sqrt(6): road one {sqrt(Z1):.8f}, road two {sqrt(tail2_direct(0)):.8f}")
print("N, ||t_N||_2, ||t - t_N||_2, lower 1/sqrt(N+1), Cauchy bound 1/sqrt(N)")
for N in (1, 2, 5, 10, 100, 1000):
    print(f"{N}, {sqrt(H2[N]):.4f}, {sqrt(tail2(N)):.4f}, {1 / sqrt(N + 1):.4f}, {1 / sqrt(N):.4f}")
print("chart, ||t - t_N||_2, N=1..10:", ", ".join(f"{sqrt(tail2(N)):.2f}" for N in range(1, 11)))
print("chart, 1/sqrt(N), N=1..10:", ", ".join(f"{1 / sqrt(N):.2f}" for N in range(1, 11)))

# the fast subsequence: n_k = first N with ||t - t_N||_2 <= 2^-k
nk = [next(N for N in range(1, M) if tail2(N) <= 4.0 ** -k) for k in range(1, 6)]
print("fast subsequence n_k, k=1..5, by search:", ", ".join(map(str, nk)),
      "; by the bounds, 4^k:", ", ".join(str(4 ** k) for k in range(1, 6)))
gaps = [sqrt(H2[nk[i + 1]] - H2[nk[i]]) for i in range(4)]
print("gaps ||t_n(k+1) - t_n(k)||_2, k=1..4:", ", ".join(f"{g:.4f}" for g in gaps),
      "; each below 2^-k:", "yes" if all(g < 2.0 ** -(i + 1) for i, g in enumerate(gaps)) else "no")
print(f"Minkowski bound on g: ||g||_2 = {sqrt(Z1):.4f} <= ||t_4||_2 + 1 = {sqrt(H2[4]) + 1:.4f}")

# simple functions: the staircase phi_k(n) = floor(2^k/n)/2^k, zero past n = 2^k
print("staircase k, values used, ||t - phi_k||_2, bound sqrt(2) 2^(-k/2)")
stair, roads = [], []
for k in range(1, 9):
    near = sum((1 / n - (2 ** k // n) / 2 ** k) ** 2 for n in range(1, 2 ** k + 1))
    down = [max(j for j in range(2 ** k + 1) if j * n <= 2 ** k) for n in range(1, 2 ** k + 1)]
    roads.append(abs(near - sum((1 / n - j / 2 ** k) ** 2 for n, j in enumerate(down, 1))) < 1e-12)
    stair.append(sqrt(near + tail2(2 ** k)))
    vals = len({2 ** k // n for n in range(1, 2 ** k + 2)})
    print(f"{k}, {vals}, {stair[-1]:.4f}, {sqrt(2) * 2 ** (-k / 2):.4f}")

# what breaks in l1: the same truncations are not Cauchy there
ln2 = 2 * sum((1 / 3) ** (2 * j + 1) / (2 * j + 1) for j in range(40))
H1 = lambda N: sum(1.0 / n for n in range(N, 0, -1))
for N in (10, 100, 1000):
    print(f"l1: N={N}, ||t_2N - t_N||_1 = {H1(2 * N) - H1(N):.4f}, ||t_N||_1 = {H1(N):.4f}")
print(f"ln 2 by its own series {ln2:.4f}")

# the wind week under counting measure, truncated to the first d days
w = [3, 5, 8, 2, 6, 4, 7]
wt = [sum(x * x for x in w[d:]) for d in range(8)]
wp = [sum(x * x for x in w) - sum(x * x for x in w[:d]) for d in range(8)]
print("wind, ||w - w_d||_2^2, d=0..7:", ", ".join(map(str, wt)))
print("wind, ||w - w_d||_2, d=0..7:", ", ".join(f"{sqrt(x):.4f}" for x in wt))
print(f"wind under the uniform 1/7: ||w||_2 = sqrt({Q(wt[0], 7)}) = {sqrt(wt[0] / 7):.4f}")

# ramps r_n: 0 left of 1/2 - 1/(2n), 1 right of 1/2 + 1/(2n), straight between
D = 20160                               # cells on [0, 1]; kinks land on cell edges
def ramp(n, x):
    return min(Q(1), max(Q(0), n * (x - Q(1, 2)) + Q(1, 2)))
def step(x):
    return Q(1) if x >= Q(1, 2) else Q(0)
def l1_grid(f, g):                      # midpoint rule, exact for pieces that are straight
    return sum(abs(f(Q(2 * t + 1, 2 * D)) - g(Q(2 * t + 1, 2 * D))) for t in range(D)) / D
ramps = []
for n in (1, 2, 4, 8, 16):
    to_step = l1_grid(lambda x: ramp(n, x), step)
    to_next = l1_grid(lambda x: ramp(n, x), lambda x: ramp(2 * n, x))
    sup = max(abs(ramp(n, Q(t, D)) - step(Q(t, D))) for t in range(D + 1))
    ramps.append((n, to_step, to_next, sup))
    print(f"ramp n={n}: ||r_n - step||_1 = {to_step} (formula 1/(4n) = {Q(1, 4 * n)}), "
          f"||r_n - r_2n||_1 = {to_next}, sup gap {sup}")
for n in (1, 2, 4):
    a, b = Q(1, 2) - Q(1, 2 * n), Q(1, 2) + Q(1, 2 * n)
    print(f"figure, r_{n} rises from ({float(40 + 280 * a):g},200) to ({float(40 + 280 * b):g},40)")
print("figure, step: 0 on [0, 1/2) at y=200, 1 on [1/2, 1] at y=40, x=180 at 1/2")

assert abs(sqrt(Z1) - sqrt(tail2_direct(0))) < 1e-10          # two roads to pi/sqrt(6)
assert all(1 / (N + 1) < tail2(N) < 1 / N for N in range(1, 1001))   # telescoping bounds
assert nk == [4 ** k for k in range(1, 6)] and all(g < 2.0 ** -(i + 1) for i, g in enumerate(gaps))
assert all(roads)                        # staircase: floor formula agrees with rounding down by search
assert all(s < sqrt(2) * 2 ** (-k / 2) for k, s in enumerate(stair, 1)) and stair == sorted(stair, reverse=True)
assert all(abs(H1(2 * N) - H1(N) - (ln2 - 1 / (4 * N))) < 1 / N ** 2 for N in (10, 100, 1000))
assert wt == wp and all(a == Q(1, 4 * n) and b == Q(1, 8 * n) and s == Q(1, 2) for n, a, b, s in ramps)
print("ALL CHECKS PASS")
