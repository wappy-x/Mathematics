# Jensen's inequality on a measure space -- the check behind the card.
# Standard library only: fractions for exact sums, math for log, exp and
# powers.  The space: seven days, wind speeds (3, 5, 8, 2, 6, 4, 7) m/s.
# Under P each day weighs 1/7; under counting measure each weighs 1.
from fractions import Fraction as Q
import math

SPEEDS = [3, 5, 8, 2, 6, 4, 7]
P = [Q(1, 7)] * 7                        # the uniform probability
COUNT = [Q(1)] * 7                       # counting measure, total mass 7

def integral(g, weights):                # a simple function: value times weight
    return sum(w * g(x) for x, w in zip(SPEEDS, weights))

def dec(v, digits):                        # fixed decimals, same in both checks
    return f"{v:.{digits}f}"

# ---- road 1: both sides of Jensen, summed exactly ----
m = integral(lambda x: x, P)
print(f"speeds in m/s: {SPEEDS}; weight under P {P[0]} each, under counting measure {COUNT[0]}")
mean_cube, mean_square = integral(lambda x: x ** 3, P), integral(lambda x: x ** 2, P)
print(f"mean speed E[f] = {m}; cube of the mean = {m ** 3}; mean cube E[f^3] = {mean_cube}")
print(f"ratio mean cube / cube of mean = {dec(float(mean_cube / m ** 3), 4)}")
rho = 1.225                              # air density, kg per cubic metre
print(f"power per square metre, 0.5 rho v^3 with rho = {rho}: steady {dec(0.5 * rho * float(m ** 3), 2)} W, "
      f"actual average {dec(0.5 * rho * float(mean_cube), 2)} W")

# ---- road 2: the supporting line at the mean, never cubing a day's speed ----
slope = 3 * m * m                        # derivative of x^3 at m
gaps = [(x - m) ** 2 * (x + 2 * m) for x in SPEEDS]   # x^3 - line(x), factorised
print(f"tangent at the mean: line(x) = {m ** 3} + {slope}(x - {m})")
print(f"gap cube minus line, day by day: {[int(g) for g in gaps]}")
print("figure, cube at speeds 2 to 8: " + ", ".join(str(x ** 3) for x in range(2, 9)))
print("figure, line at speeds 2 to 8: " + ", ".join(str(m ** 3 + slope * (x - m)) for x in range(2, 9)))
line_avg = integral(lambda x: m ** 3 + slope * (x - m), P)   # the line itself, integrated against P
gap_avg = sum(g * w for g, w in zip(gaps, P))
print(f"average of the line = {line_avg}; average gap = {gap_avg}; line + gap = {line_avg + gap_avg}")
assert line_avg + gap_avg == mean_cube                  # two roads to 185
assert all(g >= 0 for g in gaps) and gap_avg > 0
assert line_avg == m ** 3                               # P(Omega) = 1: the line averages to its value at m

# ---- road 3: sampling days from P with SplitMix64, seed 20260929 ----
MASK = (1 << 64) - 1
SEED = 20260929
state = SEED
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
n, total = 70000, 0
for _ in range(n):
    total += SPEEDS[splitmix() % 7] ** 3
sd = math.sqrt(float(integral(lambda x: x ** 6, P) - mean_cube ** 2))
print(f"seed {SEED}: sampled mean cube over {n} days = {dec(total / n, 4)}; standard error {dec(sd / math.sqrt(n), 4)}")
assert abs(total / n - float(mean_cube)) < 4 * sd / math.sqrt(n)

# ---- the square: Jensen's gap is the variance ----
var = integral(lambda x: (x - m) ** 2, P)
print(f"E[f^2] = {mean_square}; (E[f])^2 = {m ** 2}; gap {mean_square - m ** 2}; variance {var}")
assert mean_square - m ** 2 == var                      # two roads to 4

# ---- AM-GM: the logarithm is concave ----
prod = math.prod(SPEEDS)
gm_log = math.exp(sum(math.log(x) for x in SPEEDS) / 7)
lo, hi = 1.0, 8.0                                       # bisection on g^7 = product
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if mid ** 7 < prod else (lo, mid)
print(f"product of speeds {prod}; geometric mean by logs {dec(gm_log, 6)}, by bisection {dec(lo, 6)}")
assert abs(gm_log - lo) < 1e-9 and gm_log < m

# ---- Lyapunov: p-norms under P rise with p ----
def norm(p, weights):
    return float(integral(lambda x: Q(x) ** p, weights)) ** (1 / p)
ps = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
means = [norm(p, P) for p in ps]
print("figure, p: 0 " + " ".join(str(p) for p in ps))
print("figure, norm under P: " + ", ".join(dec(v, 2) for v in [gm_log] + means))
for p, q in [(1, 2), (1, 3), (2, 4)]:                # exact: (E f^p)^(q/p) <= E f^q
    lhs, rhs = integral(lambda x: x ** p, P) ** (q // p), integral(lambda x: x ** q, P)
    print(f"exact, p = {p}, q = {q}: (E[f^{p}])^{q // p} = {lhs} <= E[f^{q}] = {rhs}")
    assert lhs <= rhs and (norm(p, P) <= norm(q, P))
assert all(a < b for a, b in zip(means, means[1:])) and means[-1] < max(SPEEDS)

# ---- what breaks 1: counting measure, total mass 7 ----
s1, s3 = integral(lambda x: x, COUNT), integral(lambda x: x ** 3, COUNT)
print(f"counting measure: integral of f = {s1}, cubed {s1 ** 3}; integral of f^3 = {s3}")
counts = [norm(p, COUNT) for p in (1, 2, 3)]
print(f"counting measure norms p = 1, 2, 3: {', '.join(dec(v, 2) for v in counts)}")
print(f"divided by 7^(1/p): {', '.join(dec(v / 7 ** (1 / p), 2) for v, p in zip(counts, (1, 2, 3)))}")
assert s1 ** 3 > s3 and counts[0] > counts[1] > counts[2]
assert abs(counts[2] / 7 ** (1 / 3) - means[2]) < 1e-12

# ---- what breaks 2: infinite measure, f(x) = 1/x on [1, N] under lambda ----
for N in (10, 100, 1000, 10000):
    k = 200 * (N - 1)
    h = (N - 1) / k
    mids = [1 + (i + 0.5) * h for i in range(k)]         # midpoint rule, both integrals
    i1, i2 = h * sum(1 / t for t in mids), h * sum(1 / (t * t) for t in mids)
    print(f"N = {N}: integral of f = {dec(i1, 4)} (ln N = {dec(math.log(N), 4)}); "
          f"integral of f^2 = {dec(i2, 4)} (1 - 1/N = {dec(1 - 1 / N, 4)})")
    assert abs(i1 - math.log(N)) < 1e-5 and abs(i2 - (1 - 1 / N)) < 1e-5

# ---- what breaks 3: a concave function, and equality for a still day ----
root_mean = sum(math.sqrt(x) for x in SPEEDS) / 7
print(f"square root: E[sqrt f] = {dec(root_mean, 4)} < sqrt(E[f]) = {dec(math.sqrt(m), 4)}")
still = [5] * 7
print(f"steady 5 m/s every day: mean cube {sum(x ** 3 for x in still) // 7}, cube of mean {Q(sum(still), 7) ** 3}")
assert root_mean < math.sqrt(m)
print("ALL CHECKS PASS")
