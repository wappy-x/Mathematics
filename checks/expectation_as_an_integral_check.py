# Expectation as an integral -- the check behind the card.  Standard library
# only.  A boat is moored at a uniformly random point w of a 1 km river; the
# depth there is X(w) = 4w(1 - w) metres.  E[X], E[X^2] and the variance are
# found on the river (the outcome space) and on the line (against the law of
# X) by roads that share no arithmetic, then checked by a seeded simulation.
from fractions import Fraction as Fr
from math import sqrt, isqrt

def depth(w):
    return 4 * w * (1 - w)

def mul(p, q):                          # multiply polynomials, lowest power first
    out = [Fr(0)] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            out[i + j] += a * b
    return out

def integral01(p):                      # integral from 0 to 1: w^m gives 1/(m + 1)
    return sum(c * Fr(1, m + 1) for m, c in enumerate(p))

def power(p, k):
    out = [Fr(1)]
    for _ in range(k):
        out = mul(out, p)
    return out

# road 1, on the river: E[X^k] is the length-integral of (4w - 4w^2)^k over [0, 1]
river = {k: integral01(power([Fr(0), Fr(4), Fr(-4)], k)) for k in range(1, 5)}
# road 2, on the line: the law has P(X > t) = sqrt(1 - t); with u = sqrt(1 - t) the
# density integral of t^k becomes the integral of (1 - u^2)^k over [0, 1]
line = {k: integral01(power([Fr(1), Fr(0), Fr(-1)], k)) for k in range(1, 5)}
mean = river[1]
var_river = integral01(power([-mean, Fr(4), Fr(-4)], 2))   # integral of (X - E[X])^2 directly
var_line = line[2] - line[1] ** 2                         # E[X^2] - E[X]^2, on the line
print("moment k | on the river | on the line | decimal")
for k in range(1, 5):
    print(f"E[X^{k}]   | {str(river[k]):>12} | {str(line[k]):>11} | {float(line[k]):.4f}")
print(f"variance: river E[(X - 2/3)^2] = {var_river}, line E[X^2] - E[X]^2 = {var_line}; "
      f"= {float(var_line):.4f} m^2, sd {sqrt(var_line):.4f} m")
print(f"cross-section area: mean depth x 1000 m = {float(mean * 1000):.2f} m^2")

def root(t, lo, hi):                    # where the depth equals t, by bisection
    up = depth(lo) < depth(hi)
    for _ in range(80):
        mid = (lo + hi) / 2
        if (depth(mid) < t) == up:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2

def river_tail(t):                      # P(X >= t): the length of the stretch at least t deep
    return root(t, 0.5, 1.0) - root(t, 0.0, 0.5)

def law_tail(t):                        # the same number read off the law's formula
    return sqrt(1 - t)

print("cdf, t | law 1 - sqrt(1 - t) | river 1 - length | uniform t")
for i in range(11):
    t = i / 10
    print(f"cdf, {t:.1f} | {1 - law_tail(t):.4f} | {1 - river_tail(t):.4f} | {t:.4f}")
print("chart, law at t = 0.0 to 1.0, two decimals: " + ", ".join(f"{1 - law_tail(i / 10):.2f}" for i in range(11)))
print("gauge floor(2^n X)/2^n | integral on the river | against the law | gap to 2/3")
sums = []
for n in (1, 2, 3, 4, 6, 8, 10):
    h = 2.0 ** -n
    on_river = sum(h * river_tail(k * h) for k in range(1, 2 ** n))
    on_line = sum(h * law_tail(k * h) for k in range(1, 2 ** n))
    sums.append((n, on_river, on_line))
    print(f"n = {n:2} | {on_river:.6f} | {on_line:.6f} | {2 / 3 - on_line:.6f}")
probs = [law_tail(v / 4) - law_tail((v + 1) / 4) for v in range(4)]
print("quarter-metre gauge R, sum formula: P(R = 0, 0.25, 0.5, 0.75) = "
      + ", ".join(f"{p:.4f}" for p in probs)
      + f"; E[R] = {sum(v / 4 * p for v, p in enumerate(probs)):.4f}")
print(f"density f(t) = 1/(2 sqrt(1 - t)): f(0.5) = {1 / (2 * law_tail(0.5)):.4f}, "
      f"f(0.99) = {1 / (2 * law_tail(0.99)):.4f}")

state, s1, s2, N = 2026, 0.0, 0.0, 100000   # SplitMix64, seed 2026
for _ in range(N):
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    x = depth(((z ^ (z >> 31)) >> 11) / 2 ** 53)
    s1 += x
    s2 += x * x
sim_mean, sim_var = s1 / N, s2 / N - (s1 / N) ** 2
print(f"simulation, {N} boats: mean {sim_mean:.4f} m, variance {sim_var:.4f} m^2, "
      f"standard error {sqrt(4 / 45 / N):.4f} m")

def fsqrt(q):                           # exact square root of a square fraction
    return Fr(isqrt(q.numerator), isqrt(q.denominator))

total_line, total_river, cuts = Fr(0), 0.0, []
for k in range(6):                      # band k: 1 - 4^-k <= X < 1 - 4^-(k+1), payout (-2)^k
    a, b = 1 - Fr(1, 4 ** k), 1 - Fr(1, 4 ** (k + 1))
    size = 2 ** k * (fsqrt(1 - a) - fsqrt(1 - b))
    total_line += (-1) ** k * size
    total_river += (-2) ** k * (river_tail(float(a)) - river_tail(float(b)))
    cuts.append((total_line, total_river))
print(f"break, payout (-2)^k on depth band k: |payout| x probability per band {abs(size)}; "
      "totals after 1..6 bands " + ", ".join(str(c[0]) for c in cuts))
print(f"break, depth read as uniform on [0, 1] m: integral of t dt = {integral01([Fr(0), Fr(1)])}, not {mean}")
print(f"break, (E[X])^2 = {mean ** 2} = {float(mean ** 2):.4f} for E[X^2] = {river[2]} = {float(river[2]):.4f}")
print(f"figure, x = 40 + 280 w, y = 40 + 160 d; bed M 40 40 Q {40 + 280 * 0.5:.0f} "
      f"{40 + 160 * 2 * depth(0.5):.0f} 320 40; deepest ({40 + 280 * 0.5:.0f}, {40 + 160 * depth(0.5):.0f}); depth 0.75 at y {40 + 160 * 0.75:.0f}, "
      f"from x {40 + 280 * root(0.75, 0.0, 0.5):.0f} to {40 + 280 * root(0.75, 0.5, 1.0):.0f}; "
      f"boat at w = 0.3: depth {depth(0.3):.2f} m, x {40 + 280 * 0.3:.0f}, bed y {40 + 160 * depth(0.3):.0f}")
assert river == line and mean == Fr(2, 3)                      # two exact roads, four moments
assert var_river == var_line == Fr(4, 45)                      # variance two ways
assert all(abs(r - l) < 1e-12 for _, r, l in sums)             # simple functions transfer
assert all(0 < 2 / 3 - l <= 2.0 ** -n for n, _, l in sums)      # the gap obeys its 2^-n bound
assert abs(sim_mean - 2 / 3) < 4 * sqrt(4 / 45 / N) and abs(sim_var - 4 / 45) < 0.0012
assert all(abs(float(c) - r) < 1e-9 for c, r in cuts)
assert [c[0] for c in cuts] == [Fr(1, 2), 0] * 3
print("ALL CHECKS PASS")
