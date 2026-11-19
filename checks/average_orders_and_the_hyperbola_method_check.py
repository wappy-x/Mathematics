# Average orders and the hyperbola method -- the check behind the card.  Standard library only.
# D(x) = tau(1) + ... + tau(x) counts the lattice points (a, b) with a*b <= x.  Three roads to D(10^6):
# a divisor sieve, the column sum of floor(x/d), and Dirichlet's hyperbola cut at sqrt(x).  Then the
# formula x log x + (2 gamma - 1) x, its error against the proved bound 2 sqrt(x) + 5, and the totient.
import math

N = 10 ** 6
tau = [0] * (N + 1)                            # road 1: tau(m) = number of divisors, by a sieve
for d in range(1, N + 1):
    for m in range(d, N + 1, d):
        tau[m] += 1
phi = list(range(N + 1))                       # Euler's totient by a sieve over the primes
for p in range(2, N + 1):
    if phi[p] == p:                            # p untouched so far, so p is prime
        for m in range(p, N + 1, p):
            phi[m] -= phi[m] // p
D = [0] * (N + 1)                              # D[x] = tau(1) + ... + tau(x)
for x in range(1, N + 1):
    D[x] = D[x - 1] + tau[x]

def isqrt(x):                                  # largest m with m*m <= x
    m = int(math.sqrt(x))
    while m * m > x: m -= 1
    while (m + 1) * (m + 1) <= x: m += 1
    return m

def column_sum(x):                             # road 2: column d holds floor(x/d) points
    return sum(x // d for d in range(1, x + 1))

def hyperbola(x):                              # road 3: columns d <= m, rows b <= m, minus the m-by-m square
    m = isqrt(x)
    return 2 * sum(x // d for d in range(1, m + 1)) - m * m

n = 10000                                      # Euler's constant from H(n) - log n with Euler-Maclaurin terms
g = sum(1 / k for k in range(1, n + 1)) - math.log(n) - 1 / (2 * n) + 1 / (12 * n * n)
c = 2 * g - 1

def predicted(x): return x * math.log(x) + c * x

cols = [10 // d for d in range(1, 11)]
print(f"x = 10, columns floor(10/d): {cols}, total {sum(cols)}; hyperbola 2 x ({cols[0]} + {cols[1]} + {cols[2]}) - 3 x 3 = {hyperbola(10)}")
print(f"x = 10: average {D[10] / 10:.4f}; log 10 = {math.log(10):.4f}, log 10 + 2 gamma - 1 = {math.log(10) + c:.4f}")
print("chart, columns floor(10/d) as bars; hyperbola 10/d: " + ", ".join(f"{10 / d:.2f}" for d in range(1, 11)))
print(f"Euler's constant gamma {g:.10f}, 2 gamma - 1 = {c:.10f}")
h = sum(N // d for d in range(1, 1001))
print(f"x = 10^6: sieve {D[N]}, column sum {column_sum(N)}, hyperbola 2 x {h} - 1000 x 1000 = {hyperbola(N)}")
print(f"x = 10^6: average {D[N] / N:.6f}; x log x {N * math.log(N):.2f}, (2 gamma - 1) x {c * N:.2f}, predicted {predicted(N):.2f}")
print(f"x = 10^6: error Delta = {D[N] - predicted(N):.2f}, sqrt x = {math.sqrt(N):.0f}, Delta / sqrt x = {(D[N] - predicted(N)) / math.sqrt(N):.4f}, bound 2 sqrt x + 5 = {2 * math.sqrt(N) + 5:.0f}")
print("x | D(x) | average | log x + 2 gamma - 1 | ratio D/predicted | Delta | Delta/sqrt x")
xs = [10, 100, 1000, 10 ** 4, 10 ** 5, 10 ** 6]
for x in xs:
    dl = D[x] - predicted(x)
    print(f"{x} | {D[x]} | {D[x] / x:.4f} | {math.log(x) + c:.4f} | {D[x] / predicted(x):.6f} | {dl:.2f} | {dl / math.sqrt(x):.4f}")
print("chart, average D(x)/x: " + ", ".join(f"{D[x] / x:.2f}" for x in xs))
print("chart, log x + 2 gamma - 1: " + ", ".join(f"{math.log(x) + c:.2f}" for x in xs))
print("chart, log x alone: " + ", ".join(f"{math.log(x):.2f}" for x in xs))
worst, wx, ok = 0.0, 0, True
for x in range(1, N + 1):
    dl = D[x] - predicted(x)
    ok = ok and abs(dl) < 2 * math.sqrt(x) + 5
    if abs(dl) / math.sqrt(x) > worst: worst, wx = abs(dl) / math.sqrt(x), x
print(f"every x up to 10^6: |Delta| < 2 sqrt x + 5 is {ok}; largest |Delta|/sqrt x = {worst:.4f}, at x = {wx}")
k, f, e = 720720, [], 1                        # 720720 by trial division, then tau from the exponents
for p in range(2, 14):
    a = 0
    while k % p == 0: k, a = k // p, a + 1
    if a: f.append(f"{p}^{a}"); e *= a + 1
print(f"720720 = {' '.join(f)}: tau by exponents {e}, by sieve {tau[720720]}, largest tau up to 10^6 {max(tau)}")
mx = max(tau)
top = [m for m in range(1, N + 1) if tau[m] == mx]
print(f"numbers up to 10^6 with {mx} divisors: {len(top)}: {', '.join(map(str, top))}")
srt = sorted(tau[1:])
few = sum(1 for v in tau[1:] if v < 14)
print(f"median tau up to 10^6: {srt[N // 2 - 1]}; numbers with fewer than 14 divisors: {few} ({100 * few / N:.1f} percent)")
print(f"mistake, count columns and rows but not the square: {2 * h}")
H = sum(1 / d for d in range(1, N + 1))
print(f"mistake, drop the floors: H(10^6) = {H:.4f}, x H(x) = {N * H:.2f}, over by {N * H - D[N]:.2f} = {(N * H - D[N]) / N:.4f} x; 1 - gamma = {1 - g:.4f}")
print(f"mistake, average log x alone: {math.log(N):.4f}, total {N * math.log(N):.2f}, short by {D[N] - N * math.log(N):.2f} = {(D[N] - N * math.log(N)) / math.sqrt(N):.1f} sqrt x")
P1000 = sum(phi[1:1001])
cop = sum(1 for a in range(1, 1001) for b in range(1, 1001) if math.gcd(a, b) == 1)
print(f"totient: phi(1) + ... + phi(1000) = {P1000}, 3 x^2 / pi^2 = {3 * 10 ** 6 / math.pi ** 2:.2f}; 2 x {P1000} - 1 = {2 * P1000 - 1}; coprime pairs by gcd {cop}")
PN, main = sum(phi[1:]), 3 * N * N / math.pi ** 2
bound = N * math.log(N) + 1.5 * N
print(f"totient: Phi(10^6) = {PN}, 3 x^2 / pi^2 = {main:.2f}, difference {PN - main:.2f}, proved bound x log x + 1.5x = {bound:.2f}")
print(f"totient: average phi(n)/n up to 10^6 {sum(phi[m] / m for m in range(1, N + 1)) / N:.6f}, 6/pi^2 {6 / math.pi ** 2:.6f}")
assert D[N] == column_sum(N) == hyperbola(N) and all(D[x] == hyperbola(x) for x in range(1, 2001))   # three roads agree
assert ok and worst < 2                        # Dirichlet's root-x error bound holds at every x up to 10^6
assert abs(g - 0.5772156649) < 1e-9 and abs(D[N] / N - (math.log(N) + c)) < (2 * math.sqrt(N) + 5) / N  # the average
assert e == tau[720720] == 240 and top[0] == 720720 and 2 * P1000 - 1 == cop and abs(PN - main) < bound   # 720720; totient
print("ALL CHECKS PASS")
