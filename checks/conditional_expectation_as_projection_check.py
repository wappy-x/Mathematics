# Conditional expectation as a projection -- the check behind the card.
# Standard library only; fractions give exact arithmetic.  A month at the
# station is one of 8 equally likely outcomes: a season and a dry or wet year,
# 10 mm below or above that season's mean.  What is known, G, is the season.
# The forecast E[X | G] is found by two roads that share no arithmetic:
# averaging each season's cell, and least squares on the features 1, T, T^2,
# T^3 (T the season's temperature), solved by Gaussian elimination.
from fractions import Fraction as Fr
from itertools import product

NAME = ["winter", "spring", "summer", "autumn"]
MEAN = [30, 60, 90, 40]                          # seasonal mean rainfall, mm
TEMP = [5, 11, 19, 13]                           # seasonal mean temperature, C
P = Fr(1, 8)                                     # each outcome weighs 0.125
S = [s for s in range(4) for _ in (0, 1)]        # the season of each outcome
X = [MEAN[s] + d for s in range(4) for d in (-10, 10)]   # rainfall, mm
T = [TEMP[s] for s in S]

def E(v):                                        # expectation: weighted sum
    return sum(P * x for x in v)

def mse(z):                                      # mean squared error against X
    return E([(x - y) ** 2 for x, y in zip(X, z)])

def show(v):
    return " ".join(str(x) for x in v)

def lstsq(y, feats):                             # normal equations, eliminated
    k = len(feats)
    A = [[E([f[i] * g[i] for i in range(8)]) for g in feats]
         + [E([f[i] * y[i] for i in range(8)])] for f in feats]
    for c in range(k):
        piv = next(r for r in range(c, k) if A[r][c] != 0)
        A[c], A[piv] = A[piv], A[c]
        for r in range(k):
            if r != c and A[r][c] != 0:
                m = A[r][c] / A[c][c]
                A[r] = [a - m * b for a, b in zip(A[r], A[c])]
    coef = [A[r][k] / A[r][r] for r in range(k)]
    return coef, [sum(c * f[i] for c, f in zip(coef, feats)) for i in range(8)]

# road one: the partition formula, E[X 1_B] / P(B) on each season's cell B
M = [E([x * (t == s) for x, t in zip(X, S)]) / E([t == s for t in S]) for s in S]
print("1. the eight outcomes, each with probability 0.125")
print("   season  :", " ".join(f"{NAME[s]:>6}" for s in S))
print("   rain X  :", " ".join(f"{x:>6}" for x in X))
print("   E[X | G]:", " ".join(f"{str(m):>6}" for m in M))
print("   temp T  :", " ".join(f"{t:>6}" for t in T))
events = 0
for mask in range(16):                           # every event G can see
    A = [(mask >> s) & 1 for s in S]
    assert E([x * a for x, a in zip(X, A)]) == E([m * a for m, a in zip(M, A)])
    events += 1
print(f"   defining property E[X 1_A] = E[M 1_A] holds on {events} of 16 events in G")
# road two: least squares on 1, T, T^2, T^3, which never looks at a season name
coef, M2 = lstsq(X, [[1] * 8, T, [t * t for t in T], [t ** 3 for t in T]])
assert M2 == M
print(f"2. least squares on 1, T, T^2, T^3 gives {show(M2[::2])}: the same forecast")
print("3. the error X - M is perpendicular to every known quantity")
R = [x - m for x, m in zip(X, M)]
for s in range(4):
    dot = E([r * (t == s) for r, t in zip(R, S)])
    assert dot == 0
    print(f"   E[(X - M) 1_{NAME[s]}] = {dot}")
rt = E([r * t for r, t in zip(R, T)])
assert rt == 0                                   # and to the temperature, a known quantity
print(f"   E[(X - M) T] = {rt}")
EX, EX2, EM2 = E(X), E([x * x for x in X]), E([m * m for m in M])
assert EM2 <= EX2
print(f"   E[X] = {EX}, E[X^2] = {EX2}, E[M^2] = {EM2}: M is in L2(G)")
print("4. all 81 forecasts M + d, d in {-10, 0, 5} for each season")
best, beat, worst = None, 0, 0
for d in product((-10, 0, 5), repeat=4):
    Z = [m + d[s] for m, s in zip(M, S)]
    extra = E([d[s] ** 2 for s in S])            # E[(M - Z)^2], from d alone
    assert mse(Z) == mse(M) + extra                # Pythagoras, exactly
    beat += mse(Z) < mse(M)
    worst = max(worst, mse(Z))
    best = min(best, mse(Z)) if best is not None else mse(Z)
assert beat == 0
assert best == mse(M)
print(f"   Pythagoras exact on 81 of 81; best {best} at d = 0; worst {worst}; {beat} beat M")
print("5. the law of total variance")
var_direct = E([(x - EX) ** 2 for x in X])
within, between = E([r * r for r in R]), E([(m - EX) ** 2 for m in M])
cond_var = [E([r * r * (t == s) for r, t in zip(R, S)]) / Fr(1, 4) for s in range(4)]
assert var_direct == EX2 - EX ** 2 == within + between
print(f"   Var X = E[(X - 55)^2] = {var_direct}; E[X^2] - 55^2 = {EX2 - EX ** 2}")
print(f"   55^2 = {EX ** 2}; seasonal means minus 55: {show([m - EX for m in M[::2]])}")
print(f"   Var(X | season) = {show(cond_var)}; within {within} + between {between}")
print(f"   = {within + between}; share explained by the season {float(between / var_direct):.2f}")
print("6. least squares on 1 and T only: a smaller space of known quantities")
(a, b), fit = lstsq(X, [[1] * 8, T])
(a2, b2), fitM = lstsq(M, [[1] * 8, T])
gap = E([(m - f) ** 2 for m, f in zip(M, fit)])
Tm = E(T)
cov, vt = E([(t - Tm) * (m - EX) for t, m in zip(T, M)]), E([(t - Tm) ** 2 for t in T])
assert b == cov / vt and a == EX - b * Tm        # slope and intercept by formula
assert (a, b) == (a2, b2) and mse(fit) == within + gap
print(f"   from X: rain = {a} + {b} T;  from M: rain = {a2} + {b2} T")
print(f"   by hand: mean T {Tm}, deviations {show([t - Tm for t in T[::2]])}, "
      f"mean square {vt}, average product with M - 55 {cov}")
print(f"   M minus line: {show([m - f for m, f in zip(M[::2], fit[::2])])}")
print(f"   fitted {show(fit[::2])}; error {mse(fit)} = {within} + {gap}")
print(f"   explained by the line {E([(f - EX) ** 2 for f in fit])}; plus {gap} = {between}")
print("7. what breaks")
peek = mse(X)
cross = E([r * (m - x) for r, m, x in zip(R, M, X)])
pyth = within + E([(m - x) ** 2 for m, x in zip(M, X)])
assert peek < mse(M)
assert peek != pyth
assert cross != 0                                # orthogonality fails: Z is not known
print(f"   peeking forecast Z = X: error {peek}, Pythagoras would say {pyth}, E[(X - M)(M - Z)] = {cross}")
desert = [0, 0, 0, 40]
mu = Fr(sum(desert), 4)
sq = [sum(Fr(y - c) ** 2 for y in desert) / 4 for c in (mu, 0)]
ab = [sum(abs(Fr(y - c)) for y in desert) / 4 for c in (mu, 0)]
assert sq[0] < sq[1] and ab[0] > ab[1]
print(f"   desert month 0, 0, 0, 40: squared loss mean {mu} -> {sq[0]}, 0 -> {sq[1]}; "
      f"absolute loss mean {mu} -> {ab[0]}, 0 -> {ab[1]}")
tail = lambda n: sum(Fr(3, 4 ** k) * 4 ** k for k in range(1, n + 1))
mean20 = sum(Fr(3, 4 ** k) * 2 ** k for k in range(1, 21))
print(f"   X = 2^k w.p. 3/4^k: E[X^2] partial sums {tail(5)}, {tail(10)}, {tail(20)}; "
      f"E[X] to 20 terms {float(mean20):.6f}")
print("8. chart and figure")
print("chart, X:", show(X))
print("chart, M:", show(M))
print("chart, line:", show(fit))
print("chart, mean:", show([EX] * 8))
sc = 8.0                                        # figure: 8 units per mm
print(f"figure, scale {sc:.0f} per mm, O=(40,200) M=({40 + sc * float(between) ** 0.5:.2f},200) "
      f"X=({40 + sc * float(between) ** 0.5:.2f},{200 - sc * float(within) ** 0.5:.2f}) "
      f"legs {float(between) ** 0.5:.2f} and {float(within) ** 0.5:.2f}, "
      f"hypotenuse {float(var_direct) ** 0.5:.2f}")
