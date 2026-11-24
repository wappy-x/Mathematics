# Tightness and Prokhorov's theorem -- the check behind the card.  Standard library
# only.  Normal chances come two ways: a power series for erf, and Simpson's rule on
# the bell-curve density.  Die totals come from the exact law, built roll by roll.
# Helly's selection is run on a real sequence of laws and checked against its limit.
from math import sin, sqrt, pi, exp

def erf(x):                                   # road 1: 2/sqrt(pi) times sum of (-1)^k x^(2k+1) / (k! (2k+1))
    term, total = x, 0.0
    for k in range(90):
        total += term / (2 * k + 1)
        term *= -x * x / (k + 1)
    return 2 / sqrt(pi) * total
def Phi(x): return 0.5 * (1 + erf(x / sqrt(2)))
def dens(x): return exp(-x * x / 2) / sqrt(2 * pi)
def simpson(f, a, b, n):                      # road 2: Simpson's rule
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
def inside(var, K): return 2 * Phi(K / sqrt(var)) - 1
def inside_simpson(var, K): return simpson(dens, -K / sqrt(var), K / sqrt(var), 2000)
def f4(x): return f"{x:.4f}"
def f6(x): return f"{x:.6f}"

# ---- 1. point masses at 0, 1, 2, ...: every one is a law, the family is not tight ----
Fdelta = [1.0 if 5 >= n else 0.0 for n in range(11)]            # F_n(5) = P(n <= 5)
print("point masses: F_n(5) for n = 0..10:", " ".join(f"{v:.0f}" for v in Fdelta))
worst = [max(0.0 if n <= K else 1.0 for n in range(10001)) for K in (1, 10, 100)]
print("point masses: worst mass outside [-K, K] over n <= 10000, K = 1, 10, 100:", " ".join(f"{v:.0f}" for v in worst))
mix = [0.5 + (0.5 if n <= 5 else 0.0) for n in (1, 5, 6, 100)]  # half at 0, half at n
print("half at 0, half at n: F_n(5) for n = 1, 5, 6, 100:", " ".join(f"{v:.1f}" for v in mix))

# ---- 2. normal laws with variance between 1 and 2 ----
vs = [1.0, 1.25, 1.5, 1.75, 2.0]
a, b = [inside(v, 3) for v in vs], [inside_simpson(v, 3) for v in vs]
print("normal, mass in [-3, 3], variance 1 .. 2 (series):  ", " ".join(f6(x) for x in a))
print("normal, mass in [-3, 3], variance 1 .. 2 (Simpson): ", " ".join(f6(x) for x in b))
assert max(abs(x - y) for x, y in zip(a, b)) < 1e-10                 # two roads agree
assert all(a[i] > a[i + 1] for i in range(4)) and abs(a[-1] - 0.9661) < 5e-5   # worst case is variance 2
print("normal, variance 2: K / sigma = 3 / sqrt 2 =", f4(3 / sqrt(2)), "; Phi of it =", f6(Phi(3 / sqrt(2))),
      "; leak", f6(1 - inside(2.0, 3)))
lo, hi = 0.0, 10.0                             # smallest K holding 0.99 of every law in the family
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (lo, mid) if inside(2.0, mid) >= 0.99 else (mid, hi)
print("normal family: smallest K with mass >= 0.99 in [-K, K] for all:", f4(hi))
wide = [inside(v, 3) for v in (1, 10, 100, 1000)]
print("normal, variance 1, 10, 100, 1000: mass in [-3, 3]:", " ".join(f4(x) for x in wide))
assert wide[3] < 0.08                          # no bound on the variance, no tightness

# ---- 3. the standardised die total Z_n = (S_n - 3.5n) / sqrt(35n/12) ----
laws = [[1.0]]
for n in range(1, 201):
    q = [0.0] * (len(laws[-1]) + 6)
    for s, p in enumerate(laws[-1]):
        for k in range(1, 7):
            q[s + k] += p / 6
    laws.append(q)
def tail(n, k2):                               # P(|Z_n| > K), with k2 = (2K)^2, by whole-number test
    return sum(p for s, p in enumerate(laws[n]) if 12 * (2 * s - 7 * n) ** 2 > 35 * n * k2)
var100 = sum(p * (s - 350) ** 2 for s, p in enumerate(laws[100])) / (100 * 35 / 12)
print("die total, variance of Z_100 from its law:", f6(var100))
for K in (2, 3):
    row = [tail(n, 4 * K * K) for n in (1, 2, 10, 100, 200)]
    print(f"die total, P(|Z_n| > {K}), n = 1, 2, 10, 100, 200:", " ".join(f6(x) for x in row), "  Chebyshev", f6(1 / K ** 2))
t3 = [tail(n, 36) for n in range(1, 201)]
m3 = max(t3)
print("die total, worst P(|Z_n| > 3) over n = 1..200:", f6(m3), "at n =", t3.index(m3) + 1)
print("die total, K = 10: Chebyshev", f6(1 / 100), "; worst exact over n = 1..200:", f6(max(tail(n, 400) for n in range(1, 201))))
print("normal tail outside [-3, 3]:", f6(1 - inside(1.0, 3)))
assert abs(var100 - 1) < 1e-9 and m3 <= 1 / 9                    # law against formula; Chebyshev holds
assert abs(t3[99] - (1 - inside(1.0, 3))) < 1e-3                 # exact law against the CLT bell

# ---- 4. the chart: worst mass outside [-K, K] across each family, K = 0, 0.5, ..., 5 ----
Ks = [k / 2 for k in range(11)]
die_worst = [max(tail(n, k * k) for n in range(1, 201)) for k in range(11)]
print("figure, K:", " ".join(f"{K:.1f}" for K in Ks))
print("figure, point masses:", " ".join("1.00" for _ in Ks))
print("figure, normal variance 2:", " ".join(f"{1 - inside(2.0, K):.2f}" for K in Ks))
print("figure, die totals n <= 200:", " ".join(f"{x:.2f}" for x in die_worst))
print("figure, Chebyshev 1/K^2:", " ".join(f"{min(1.0, 1 / K ** 2) if K else 1.0:.2f}" for K in Ks))
assert all(x <= min(1.0, 4 / k ** 2) + 1e-12 for x, k in zip(die_worst[1:], range(1, 11)))

# ---- 5. Helly's selection on variances 1.5 + 0.5 sin n, which never settle ----
N = 20000
var = {n: 1.5 + 0.5 * sin(n) for n in range(1, N + 1)}
idx, G = list(range(1, N + 1)), {}
for x in (0.5, 1.0, 2.0):                      # one threshold at a time, as in the diagonal argument
    F = {n: Phi(x / sqrt(var[n])) for n in idx}
    lo, hi = 0.0, 1.0
    for _ in range(10):                        # keep the half of [0, 1] that holds more of F_n(x)
        mid = (lo + hi) / 2
        left = [n for n in idx if F[n] <= mid]
        right = [n for n in idx if F[n] > mid]
        idx, lo, hi = (left, lo, mid) if len(left) >= len(right) else (right, mid, hi)
    G[x] = (lo + hi) / 2
print("Helly: sequence kept", len(idx), "of", N, "; first n_k:", " ".join(str(n) for n in idx[:6]))
print("Helly: variances along it:", " ".join(f4(var[n]) for n in idx[:6]))
s = (min(var[n] for n in idx) + max(var[n] for n in idx)) / 2
print("Helly: variances kept lie in", f4(min(var[n] for n in idx)), "..", f4(max(var[n] for n in idx)), "; s =", f4(s))
for x in (0.5, 1.0, 2.0):
    print(f"Helly: limit at x = {x}: selected {G[x]:.4f}   normal with variance s {Phi(x / sqrt(s)):.4f}")
    assert abs(G[x] - Phi(x / sqrt(s))) < 1 / 1024 + 1e-3        # selection against the parameter limit
print("ALL CHECKS PASS")
