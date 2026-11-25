# Apery's theorem by Beukers' integral -- the check behind the card.  Standard library only.
# Road 1: exact whole numbers A_n, B_n with d_n^3 I_n = A_n + B_n zeta(3), zeta(3) to 54 digits.
# Road 2: the triple integral I_n by Gauss-Legendre quadrature, in floating point.
# Also: Apery numbers by a sum and by a recurrence; the bound (sqrt2 - 1)^4 by a grid search.
from math import comb, gcd, cos, pi, log, log10, exp
from functools import reduce

S = 10 ** 54                                  # fixed point: an integer v stands for v / 10^54

# zeta(3), road 1: Apery's series 5/2 * sum (-1)^(k+1) / (k^3 C(2k, k)), in whole numbers
pos, neg, t, k = 0, 0, S // 2, 1
while t:
    pos, neg = (pos + t, neg) if k % 2 else (pos, neg + t)
    k += 1
    t = t * (k - 1) ** 3 // (2 * k * k * (2 * k - 1))
Z = (pos - neg) * 5 // 2
# zeta(3), road 2: 1 + 1/8 + ... + 1/1000^3, plus the tail 1/(2N^2) - 1/(2N^3) + 1/(4N^4)
N, z3 = 1000, 0.0
for k in range(1, N + 1): z3 += 1 / k ** 3
z3 += 1 / (2 * N * N) - 1 / (2 * N ** 3) + 1 / (4 * N ** 4)
zr = (Z + 5 * 10 ** 42) // 10 ** 43           # zeta(3) rounded to 11 decimals, as an integer
print(f"zeta(3): Apery series {zr // 10 ** 11}.{zr % 10 ** 11:011d} | sum to 1000 plus tail {z3:.11f}")
assert abs(Z / S - z3) < 1e-14

def lcm_to(n):                                 # d_n = lcm(1, 2, ..., n)
    d = 1
    for k in range(1, n + 1): d = d * k // gcd(d, k)
    return d
# Apery numbers a_n: road 1 the binomial sum, road 2 the recurrence
apery = [sum(comb(n, k) ** 2 * comb(n + k, k) ** 2 for k in range(n + 1)) for n in range(13)]
u = [1, 5]
for n in range(2, 13):
    u.append(((34 * n ** 3 - 51 * n * n + 27 * n - 5) * u[-1] - (n - 1) ** 3 * u[-2]) // n ** 3)
assert u == apery
print("Apery numbers a_0..a_8:", ", ".join(f"{a:,}" for a in apery[:9]))
r2 = 2 ** 0.5
print(f"a_12 / a_11 = {apery[12] / apery[11]:.6f}; (1 + sqrt2)^4 = 17 + 12 sqrt2 = {17 + 12 * r2:.6f}")

def coeffs(n):                                 # P_n(x) = (1/n!) (d/dx)^n [x^n (1-x)^n]
    return [(-1) ** k * comb(n, k) * comb(n + k, k) for k in range(n + 1)]
def J(r, s, d):                                # d^3 J(r, s) = A + B zeta(3), by Step 1's formula
    lo, hi = min(r, s), max(r, s)
    if r == s: return -2 * sum((d // m) ** 3 for m in range(1, r + 1)), 2 * d ** 3
    return (d // (hi - lo)) * sum((d // m) ** 2 for m in range(lo + 1, hi + 1)), 0
def whole_AB(c, d):                            # d^3 * sum c_r c_s J(r, s) = A + B zeta(3)
    terms = [(c[r] * c[s], J(r, s, d)) for r in range(len(c)) for s in range(len(c))]
    return sum(k * j[0] for k, j in terms), sum(k * j[1] for k, j in terms)

def gauss(m):                                  # Gauss-Legendre nodes and weights on [0, 1]
    xs, ws = [], []
    for i in range(1, m + 1):
        x = cos(pi * (i - 0.25) / (m + 0.5))
        for _ in range(100):
            p0, p1 = 1.0, x
            for j in range(2, m + 1): p0, p1 = p1, ((2 * j - 1) * x * p1 - (j - 1) * p0) / j
            dp = m * (x * p1 - p0) / (x * x - 1)
            dx = p1 / dp; x -= dx
            if abs(dx) < 1e-16: break
        xs.append((1 - x) / 2); ws.append(1 / ((1 - x * x) * dp * dp))
    return xs, ws
def power(b, n): return reduce(lambda p, _: p * b, range(n), 1.0)   # b^n by n multiplications

X, W = gauss(24)
def triple(n, legendre):                       # x = u^2, y = t^2, w = 1 - v^2 smooth the corner
    s = 0.0
    for u_, wu in zip(X, W):
        for t_, wt in zip(X, W):
            x, y = u_ * u_, t_ * t_
            for v_, wv in zip(X, W):
                w = 1 - v_ * v_
                den = 1 - (1 - x * y) * w
                top = x * (1 - x) * y * (1 - y) * w * (1 - w) if legendre else x * (1 - x) * y * (1 - y)
                f = power(top, n) / power(den, n + 1) if legendre else power(top, n) / den
                s += 8 * u_ * t_ * v_ * wu * wt * wv * f
    return s

M = power(r2 - 1, 4)                           # the proved maximum (sqrt2 - 1)^4
print(f"J(0, 0) = {J(0, 0, 1)[1]} zeta(3); J(1, 1) = {J(1, 1, 1)[1]} zeta(3) - {-J(1, 1, 1)[0]}; J(1, 0) = {J(1, 0, 1)[0]}")
print("n | d_n | A_n | B_n")
for n in range(1, 5):
    A, B = whole_AB(coeffs(n), lcm_to(n))
    print(f"{n} | {lcm_to(n)} | {A:,} | {B:,}")
assert whole_AB(coeffs(1), 1) == (-12, 10)     # by hand: I_1 = 10 zeta(3) - 12
print("n | d_n | d_n^3 I_n exact | by quadrature | bound d_n^3 2 zeta(3) (sqrt2-1)^(4n) | q at least")
chart = []
for n in range(1, 13):
    d = lcm_to(n)
    A, B = whole_AB(coeffs(n), d)
    assert B == 2 * u[n] * d ** 3              # the zeta(3) part is twice the Apery number, by the recurrence
    V = B * Z + A * S                          # d^3 I_n in units of 10^-54
    quad, bound = d ** 3 * triple(n, True), d ** 3 * 2 * z3 * power(M, n)
    assert V > 0 and abs(quad / (V / S) - 1) < 1e-6 and V / S < bound
    print(f"{n} | {d:,} | 0.{(V + 5 * 10 ** 41) // 10 ** 42:012d} | {quad:.12f} | {bound:.12f} | {int(S / V) + 1:,}")
    chart.append((log10(S / V) + 3 * log10(d), 3 * log10(d)))
print("chart log10(1/I_n):", ", ".join(f"{a:.2f}" for a, b in chart))
print("chart log10(d_n^3):", ", ".join(f"{b:.2f}" for a, b in chart))
A2, B2 = whole_AB(coeffs(2), 2)
print(f"without d_2^3: I_2 = {B2 // 8} zeta(3) - {-A2 / 8}")

# the bound: grid search for the largest x(1-x) y(1-y) w(1-w) / (1 - (1-xy) w)
best = (0.0, 0, 0, 0)
for i in range(1, 100):
    for j in range(1, 100):
        x, y = i / 100, j / 100
        for l in range(1, 100):
            w = l / 100; f = x * (1 - x) * y * (1 - y) * w * (1 - w) / (1 - (1 - x * y) * w)
            if f > best[0]: best = (f, i, j, l)
print(f"grid max {best[0]:.10f} at x = {best[1] / 100}, y = {best[2] / 100}, w = {best[3] / 100}")
print(f"proved max (sqrt2 - 1)^4 = {M:.10f} at x = y = sqrt2 - 1 = {r2 - 1:.6f}, w = 1/sqrt2 = {1 / r2:.6f}")
assert M - 1e-5 < best[0] <= M

# d_n against 3^n: psi(n) = log d_n, a sum of log p over prime powers p^k <= n
NP = 100000
lp, sieve = [0.0] * (NP + 1), [True] * (NP + 1)
for p in range(2, NP + 1):
    if sieve[p]:
        for m in range(p * p, NP + 1, p): sieve[m] = False
        pk = p
        while pk <= NP: lp[pk] = log(p); pk *= p
psi, worst = 0.0, (0.0, 0)
for n in range(1, NP + 1):
    psi += lp[n]
    worst = max(worst, (psi / n, n))
    assert psi < n * log(3)                    # d_n < 3^n, checked to NP
print(f"psi(n)/n up to {NP:,}: largest {worst[0]:.6f} at n = {worst[1]}; at n = {NP:,}: {psi / NP:.6f}; log 3 = {log(3):.6f}")

# the race, per step of n
e3 = exp(3)
print(f"(sqrt2-1)^4 = {M:.6f}; times e^3 = {e3:.6f}: {e3 * M:.6f}; times 27: {27 * M:.6f}; times 64: {64 * M:.6f}")
p10, p11 = triple(10, False), triple(11, False)
print(f"plain x^n(1-x)^n: at most 1/16 per step, e^3/16 = {e3 / 16:.6f}; I'_11 / I'_10 = {p11 / p10:.6f}, "
      f"times e^3: {e3 * p11 / p10:.6f}")
assert e3 * p11 / p10 > 1                      # the plain integral loses the race already at n = 10 to 11
L = 4 * log(1 + r2)
print(f"irrationality exponent of zeta(3) at most 1 + (4 log(1+sqrt2) + 3)/(4 log(1+sqrt2) - 3) = {1 + (L + 3) / (L - 3):.4f}")
print("quoted, not computed: Rhin and Viola (2001) lowered the exponent bound to 5.513891")
print(f"1/zeta(3) = {1 / z3:.6f}")
print("ALL CHECKS PASS")
