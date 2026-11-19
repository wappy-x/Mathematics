# Hardy-Ramanujan -- the check behind the card.  Standard library only.
# A smallest-prime-factor sieve gives omega(n) (distinct primes) and Omega(n)
# (primes with repeats) for every n up to 1,050,000.  Road one counts n by n.
# Road two counts prime by prime and pair by pair (Turan's switch of the order
# of summation).  The two roads must agree exactly; then the prime sums give
# Turan's variance bound, which the direct count must respect.
import math
N, A, B, X = 1_050_000, 950_000, 1_050_000, 10**6
spf = list(range(N + 1))                         # smallest prime factor
for i in range(2, int(N**0.5) + 1):
    if spf[i] == i:
        for j in range(i * i, N + 1, i):
            if spf[j] == j:
                spf[j] = i
w, W, e, tau = [0] * (N + 1), [0] * (N + 1), [0] * (N + 1), [1] * (N + 1)
for n in range(2, N + 1):
    p = spf[n]; m = n // p
    W[n] = W[m] + 1
    e[n] = e[m] + 1 if spf[m] == p else 1        # exponent of p in n
    w[n] = w[m] + (e[n] == 1)
    tau[n] = tau[m] // e[n] * (e[n] + 1)         # divisor count
primes = [p for p in range(2, N + 1) if spf[p] == p]
def fac(n):                                      # factorisation as text
    out = []
    while n > 1:
        p, k = spf[n], 0
        while n % p == 0:
            n //= p; k += 1
        out.append(f"{p}^{k}" if k > 1 else f"{p}")
    return " x ".join(out)
for n in (999_999, X, 1_000_001, 720_720):
    print(f"n = {n:,} = {fac(n)}: omega = {w[n]}, Omega = {W[n]}, divisors = {tau[n]}")
def sum_left(vals):                              # plain left-to-right sum, as in Rust
    t = 0.0
    for v in vals:
        t += v
    return t
cnt = lambda d: B // d - (A - 1) // d             # multiples of d in the window
c = B - A + 1
s1 = sum(w[A:B + 1]); s2 = sum(v * v for v in w[A:B + 1]); sW = sum(W[A:B + 1])
by_p = sum(cnt(p) for p in primes)
pairs = []                                       # p < q with pq <= B
for i, p in enumerate(primes):
    if p * p > B:
        break
    for q in primes[i + 1:]:
        if p * q > B:
            break
        pairs.append((p, q))
by_pq = by_p + 2 * sum(cnt(p * q) for p, q in pairs)
print(f"window {A:,} to {B:,}: {c:,} numbers; sum of omega n by n {s1:,}, prime by prime {by_p:,}")
print(f"sum of omega^2 n by n {s2:,}, by primes and {len(pairs):,} prime pairs {by_pq:,}")
gamma = sum_left(1.0 / k for k in range(X, 0, -1)) - math.log(X) - 1 / (2 * X) + 1 / (12 * X * X)
M = gamma + sum_left(math.log(1 - 1 / p) + 1 / p for p in primes)
L = math.log(math.log(X))
print(f"Mertens' constant M = {M:.6f}; log log 10^6 = {L:.6f}; log log 10^6 + M = {L + M:.6f}")
mean, var = s1 / c, (c * s2 - s1 * s1) / (c * c)
print(f"window mean omega = {mean:.6f} (gap {mean - L - M:+.6f}, 1/log 10^6 = {1 / math.log(X):.6f});"
      f" mean Omega = {sW / c:.6f}")
print(f"window variance of omega = {var:.6f}; standard deviation {math.sqrt(var):.6f}")
hist = [w[A:B + 1].count(k) for k in range(8)]
for k in range(1, 8):
    print(f"omega = {k}: {hist[k]:>6,} {'#' * round(hist[k] / 1000):<38} {hist[k] / c:.4f}")
print(f"within L/2 of L (omega 2 or 3): {(hist[2] + hist[3]) / c:.4f}; omega 2, 3 or 4: "
      f"{(hist[2] + hist[3] + hist[4]) / c:.4f}")
T = by_p; sq = sum(cnt(p) ** 2 for p in primes)
diag = sum(c * cnt(p) - cnt(p) ** 2 for p in primes)
near_pq = sum(cnt(p) * cnt(q) for p, q in pairs)
small = [(p, q) for p, q in pairs if p * q <= c]          # pq fits in the window's length
inside = [(p, q) for p, q in pairs if p * q >= A]         # pq is itself a window number
cov = lambda ps: 2 * sum(c * cnt(p * q) - cnt(p) * cnt(q) for p, q in ps)
close_s, close_in = cov(small), cov(inside); close_m = cov(pairs) - close_s - close_in
far = -((T * T - sq) - 2 * near_pq)
print(f"variance split: each prime alone {diag / c**2:.6f}; pairs with pq <= {c:,} {close_s / c**2:+.6f};"
      f" pq up to {A - 1:,} {close_m / c**2:+.6f}")
print(f"variance split: pq inside the window ({len(inside):,} pairs) {close_in / c**2:+.6f}; pq > {B:,}"
      f" {far / c**2:+.6f}; total {(diag + close_s + close_m + close_in + far) / c**2:.6f}")
print(f"shares: 2 | n {cnt(2) / c:.6f}, 3 | n {cnt(3) / c:.6f}, product {cnt(2) * cnt(3) / c**2:.6f},"
      f" 6 | n {cnt(6) / c:.6f}; 1031 | n {cnt(1031)}, 1033 | n {cnt(1033)}, {1031 * 1033:,} | n {cnt(1031 * 1033)}")
gap = sum_left((W[n] - w[n]) for n in range(A, B + 1)) / c
pp1 = sum_left(1 / (p * (p - 1)) for p in primes)
gX = (sum(W[1:X + 1]) - sum(w[1:X + 1])) / X
print(f"Omega - omega: window mean {gap:.6f}; mean up to 10^6 {gX:.6f}; sum of 1/(p(p-1)) = {pp1:.6f}")
pX = [p for p in primes if p <= X]
S = sum_left(1 / p for p in pX)
sx1 = sum(w[1:X + 1]); sx2 = sum(v * v for v in w[1:X + 1])
D = sum_left((w[n] - L) ** 2 for n in range(1, X + 1))
U = X * (S * S + S) - 2 * L * (X * S - len(pX)) + X * L * L
print(f"n <= 10^6: sum 1/p = {S:.6f}; mean omega {sx1 / X:.6f}, by floor(x/p) "
      f"{sum(X // p for p in pX) / X:.6f}")
print(f"window mean against n <= 10^6: S - L - M = {S - L - M:+.6f}; mean up to 10^6 + 1/log 10^6 = "
      f"{sx1 / X + 1 / math.log(X):.6f}, window {mean:.6f}")
nX = [(p, q) for p, q in pairs if p * q <= X]
farX = -((sx1 * sx1 - sum((X // p) ** 2 for p in pX)) - 2 * sum((X // p) * (X // q) for p, q in nX))
heur = S * S - sum_left(1 / (p * p) for p in pX) - 2 * sum_left(1 / (p * q) for p, q in nX)
print(f"pairs with pq > 10^6, n <= 10^6: {farX / X**2:+.6f}; sum of 1/(pq) over them {heur:.6f};"
      f" limit pi^2/6 = {math.pi**2 / 6:.6f}")
print(f"turan: sum omega^2 / x = {sx2 / X:.6f} <= S^2 + S = {S * S + S:.6f}; "
      f"sum omega / x = {sx1 / X:.6f} >= S - pi(x)/x = {S - len(pX) / X:.6f}")
print(f"turan: sum (omega - L)^2 / x = {D / X:.6f} <= bound {U / X:.6f} = L + {U / X - L:.6f}")
for t in (1.0, 2.0, 3.0):
    out = sum(1 for n in range(1, X + 1) if abs(w[n] - L) >= t * math.sqrt(L))
    print(f"|omega - L| >= {t} sqrt(L): share {out / X:.6f}; Chebyshev bound {U / X / (t * t * L):.6f}")
for a, b in ((9_500, 10_500), (99_500, 100_500)):  # try changing: smaller windows
    s, q, k = sum(w[a:b + 1]), sum(v * v for v in w[a:b + 1]), b - a + 1
    print(f"try: window {a:,} to {b:,}: mean omega {s / k:.6f}, variance {(k * q - s * s) / (k * k):.6f}")
print(f"try: 997 x 1009 = {997 * 1009:,} divides {cnt(997 * 1009)} window number")
print("x | mean omega | variance | log log x | log log x + M")
chart = []
for k in range(2, 7):
    x = 10**k; a1 = sum(w[1:x + 1]); a2 = sum(v * v for v in w[1:x + 1])
    mx, vx = a1 / x, (x * a2 - a1 * a1) / (x * x); ll = math.log(math.log(x))
    chart.append((mx, vx, ll + M))
    print(f"10^{k} | {mx:.6f} | {vx:.6f} | {ll:.6f} | {ll + M:.6f}")
print("chart, mean:", ", ".join(f"{r[0]:.2f}" for r in chart))
print("chart, variance:", ", ".join(f"{r[1]:.2f}" for r in chart))
print("chart, log log x + M:", ", ".join(f"{r[2]:.2f}" for r in chart))
first7 = next(n for n in range(1, X + 1) if w[n] == 7)
print(f"largest omega up to 10^6: {max(w[1:X + 1])}, first at {first7:,} = {fac(first7)}")
for name, lg in (("10^9", 9 * math.log(10)), ("10^80", 80 * math.log(10)), ("2^1024", 1024 * math.log(2))):
    print(f"log log {name} = {math.log(lg):.4f}; plus M = {math.log(lg) + M:.4f}")
print(f"mean omega 10 needs about {math.exp(10 - M) / math.log(10):,.0f} digits")
tw = sorted(tau[A:B + 1])
print(f"divisors in window: mean {sum(tw) / c:.4f}; median {tw[c // 2]}; 2^L = {2**L:.4f}")
indep = sum_left(cnt(p) / c * (1 - cnt(p) / c) for p in primes)
print(f"mistake 1, variance read as log log n: {L:.4f} against {var:.4f}")
print(f"mistake 2, primes independent: variance {indep:.4f} against {var:.4f}")
print(f"mistake 3, count with repeats: mean Omega {sW / c:.4f} against omega {mean:.4f}")
print(f"mistake 4, base-10 logs: log10 log10 10^6 = {math.log10(6):.4f} against {L:.4f}")
assert s1 == by_p and s2 == by_pq                                   # two roads, exact
assert diag + close_s + close_m + close_in + far == c * s2 - s1 * s1  # variance split, exact
assert abs(close_s) < 0.01 * c * c                                 # this window's small pairs
assert len(inside) == sum(1 for n in range(A, B + 1) if w[n] == W[n] == 2)  # pq in window = semiprimes
assert -heur <= farX / X**2 < 0                                     # floor(x/p)/x <= 1/p
assert sx1 == sum(X // p for p in pX) and len(pX) == 78498          # pi(10^6), known table
assert sx2 <= X * (S * S + S) and sx1 >= X * S - len(pX)            # Turan's two steps
assert D <= U and U / X - L < 1                                     # variance <= L + O(1)
assert abs(mean - sx1 / X - 1 / math.log(X)) < 0.01 and gX <= pp1 and abs(gap - pp1) < 0.05  # means
assert abs(M - 0.261497) < 1e-5 and abs(S - L - M) < 0.001          # Mertens' constant and sum
print("ALL CHECKS PASS")
