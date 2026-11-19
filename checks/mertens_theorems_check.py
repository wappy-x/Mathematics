# Mertens' theorems -- the check behind the card.  Standard library only.
# A sieve lists the primes to 5,200,000.  Road one adds 1/p, log p / p and
# multiplies 1 - 1/p over them.  Road two finds the constants M and gamma by
# different series and checks the three theorems' predictions against road one.
import math
LIMIT, X = 5_200_000, 10**6
sieve = bytearray([1]) * (LIMIT + 1)
sieve[0] = sieve[1] = 0
for i in range(2, int(LIMIT**0.5) + 1):
    if sieve[i]:
        sieve[i*i::i] = bytearray(len(range(i*i, LIMIT + 1, i)))
primes = [p for p in range(LIMIT + 1) if sieve[p]]
def add(values):                                 # plain left-to-right sum, as in Rust
    t = 0.0
    for v in values:
        t += v
    return t
def euler_gamma(n):                              # gamma = H(n) - log n, refined
    return add(1.0 / k for k in range(n, 0, -1)) - math.log(n) - 1/(2*n) + 1/(12*n*n)
gamma, gamma_half = euler_gamma(X), euler_gamma(X // 2)
c = add(math.log(p) / (p * (p - 1)) for p in primes)         # sum log p/(p(p-1))
H = add(-math.log(1 - 1/p) - 1/p for p in primes)            # higher terms of -log
M = gamma + add(math.log(1 - 1/p) + 1/p for p in primes)     # road two to M
eg = math.exp(-gamma)
print(f"primes up to {LIMIT:,}: {len(primes):,}; gamma from harmonic numbers {gamma:.10f}"
      f" (n = 10^6), {gamma_half:.10f} (n = 500,000)")
print(f"road two: M = gamma - H = {M:.6f}; H = {H:.6f}; c = {c:.6f}; E = -gamma - c = {-gamma - c:.6f}")
print(f"e^-gamma = {eg:.6f}; e^gamma = {1/eg:.6f}")
print("x | pi(x) | sum 1/p | loglog x + M | gap | sum log p/p - log x | product * log x")
S1 = S2 = 0.0; P = 1.0; k = 0; row = {}; lo1, hi1, rs = 0.0, -9.0, 0.0; cross = None
marks = [10**j for j in range(1, 7)]
for i, p in enumerate(primes):
    while k < 6 and p > marks[k]:                # running totals just below a mark
        row[marks[k]] = (i, S1, S2, P); k += 1
    S1 += math.log(p) / p; S2 += 1/p; P *= 1 - 1/p
    nxt = primes[i + 1] if i + 1 < len(primes) else LIMIT
    hi1 = max(hi1, S1 - math.log(p)); lo1 = min(lo1, S1 - math.log(nxt))
    if nxt > 286:                                # Rosser-Schoenfeld range
        a = max(p, 286)
        rs = max(rs, (S2 - math.log(math.log(a)) - M) * 2 * math.log(a)**2,
                 (M + math.log(math.log(nxt)) - S2) * 2 * math.log(nxt)**2)
    if p == 283:                                 # just below the range: bound fails
        r283 = (S2 - math.log(math.log(p)) - M) * 2 * math.log(p)**2
    if cross is None and S2 > 3:
        cross = p
    if p == primes[-1]:
        row[LIMIT] = (i + 1, S1, S2, P)
for x in marks:
    cnt, s1, s2, pr = row[x]
    L = math.log(x)
    print(f"{x:>7} | {cnt:>5} | {s2:.6f} | {math.log(L) + M:.6f} | {s2 - math.log(L) - M:+.6f}"
          f" | {s1 - L:+.6f} | {pr * L:.6f}")
cnt, s1, s2, pr = row[X]; L = math.log(X)
print(f"at 10^6: road one M = sum - loglog x = {s2 - math.log(L):.6f}; gap to road two "
      f"{s2 - math.log(L) - M:+.6f}; bound 1/(2 log^2 x) = {1/(2*L*L):.6f}")
print(f"at 10^6: product * log x / e^-gamma = {pr * L / eg:.6f}; road one M + H = {s2 - math.log(L) + H:.6f},"
      f" gamma {gamma:.6f}")
logfact = add(math.log(m) for m in range(2, X + 1))          # road A to log n!
def vp(m, p):                                                 # Legendre's formula
    t, q = 0, p
    while q <= m:
        t += m // q; q *= p
    return t
leg = add(vp(X, p) * math.log(p) for p in primes if p <= X)  # road B to log n!
theta = add(math.log(p) for p in primes if p <= X)
print(f"10! = 2^{vp(10, 2)} 3^{vp(10, 3)} 5^{vp(10, 5)} 7^{vp(10, 7)}; "
      f"check {2**vp(10, 2) * 3**vp(10, 3) * 5**vp(10, 5) * 7**vp(10, 7)} = {math.factorial(10)}")
print(f"log(10^6 !): sum of logs {logfact:,.1f}; by Legendre {leg:,.1f}; theta(10^6)/10^6 = {theta / X:.6f}")
print(f"step 2 sandwich at 10^6: {L - 1 - c:.4f} <= sum log p/p = {s1:.4f} <= {L + theta / X:.4f} <= {L + math.log(4):.4f}")
print(f"sum log p/p - log x over 2 <= x <= {LIMIT:,}: lowest {lo1:.6f}, highest {hi1:.6f}")
print(f"Rosser-Schoenfeld, 286 <= x <= {LIMIT:,}: largest gap / (1/(2 log^2 x)) = {rs:.6f}; at x = 283 {r283:.6f}")
pred3 = math.exp(math.exp(3 - M))
print(f"sum 1/p first passes 3 at p = {cross:,}; loglog x + M = 3 predicts {pred3:,.0f}")
print(f"sum 1/p reaches 4 near x = {math.exp(math.exp(4 - M)) / 1e18:.2f} x 10^18")
plus = math.prod(1 + 1/p for p in primes if p <= X)
print(f"product of 1 + 1/p to 10^6: {plus:.4f}; (6/pi^2) e^gamma log x = {6 / math.pi**2 / eg * L:.4f}")
two = math.prod(1 - 2/p for p in primes[1:] if p <= X)                     # a = -2, primes 3 to 10^6
rule = math.exp(1 - 2*M + add(math.log(1 - 2/p) + 2/p for p in primes[1:]))  # general rule's constant
print(f"product of 1 - 2/p, 3 <= p <= 10^6: {two:.9f}; times log^2 x {two * L * L:.6f}; rule's constant {rule:.6f}")
for z in (10, 100, 1000):                        # numbers <= 10^6 with no prime factor <= z
    left = bytearray([1]) * (X + 1); left[0] = 0
    for p in primes:
        if p > z:
            break
        left[p::p] = bytearray(len(range(p, X + 1, p)))
    prod_z = math.prod(1 - 1/p for p in primes if p <= z)
    print(f"no prime factor <= {z}: counted {sum(left):,}; 10^6 times product {X * prod_z:,.1f};"
          f" 10^6 e^-gamma / log z {X * eg / math.log(z):,.1f}")
logN = 1024 * math.log(2)
pz = math.prod(1 - 1/p for p in primes if p <= 1000)
print(f"1024-bit search: 1 in {logN:.1f} prime; survivors of division by primes <= 1000: "
      f"share {pz:.4f}, 1 in {logN * pz:.1f} prime")
print(f"mistake 1, sieve to sqrt(10^6) as independent: {X * pz:,.0f} against {sum(left):,} survivors, "
      f"ratio {X * pz / sum(left):.4f}; x / log x = {X / L:,.0f}; 2e^-gamma = {2 * eg:.4f}")
print(f"mistake 2, drop M: loglog 10^6 = {math.log(L):.4f} against {s2:.4f}")
print(f"mistake 3, log(1 - 1/p) taken as -1/p: e^-sum = {math.exp(-s2):.5f} against {pr:.5f}")
print(f"mistake 4, drop e^-gamma: 1/log 10^6 = {1/L:.5f} against {pr:.5f}")
print(f"by hand: log 10^6 = {L:.6f}; loglog 10^6 = {math.log(L):.6f}; plus M = {math.log(L) + M:.6f}")
print(f"by hand: log x + E = {L - gamma - c:.6f} against {s1:.6f}; e^-gamma / log x = {eg / L:.6f}"
      f" against product {pr:.6f}")
omega = sum(X // p for p in primes if p <= X)                 # distinct prime factors, all n
print(f"average count of distinct prime factors, n <= 10^6: {omega / X:.6f}")
print("chart, sum 1/p:", ", ".join(f"{row[x][2]:.2f}" for x in marks))
print("chart, loglog x + M:", ", ".join(f"{math.log(math.log(x)) + M:.2f}" for x in marks))
assert cnt == 78498                                               # pi(10^6), known table
assert abs(logfact - leg) < 1e-6 * logfact                        # Legendre = sum of logs
assert L - 1 - c <= s1 <= L + theta / X                           # step 2 sandwich
assert -2 < lo1 and hi1 < 2                                       # Mertens' own bound
assert abs((s2 - math.log(L)) - M) < 1 / (2 * L * L) and rs < 1 < r283  # theorem 2
assert abs((s1 - L) - (-gamma - c)) < 1e-3                        # theorem 1's constant E
assert abs(gamma - gamma_half) < 1e-11 and abs(pr * L - eg) < 1e-3 and abs(cross / pred3 - 1) < 0.01
assert sum(left) == 1 + cnt - 168                                 # survivors: 1 and primes > 1000
assert abs(two * L * L - rule) < 1e-3                             # step 6 rule, a = -2
print("ALL CHECKS PASS")
