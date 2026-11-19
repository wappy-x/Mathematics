# The Riemann hypothesis and three equivalents -- the check behind the card.  Standard library only.
# Primes by a sieve and by Legendre's count; Li by series and by Simpson's rule; M(x) by the Mobius
# sieve and by the recursion sum M(x/n) = 1; psi checked by Chebyshev's identity sum psi(x/n) = log x!.
import math, functools
X, SIZES = 10**6, (10**4, 10**5, 10**6)
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
mu, sig = [1] * (X + 1), [0] * (X + 1)
for p in range(2, X + 1):                      # sieve: primes, and mu(n) one prime at a time
    if flag[p]:
        flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
        for m in range(p, X + 1, p): mu[m] = -mu[m]
        for m in range(p * p, X + 1, p * p): mu[m] = 0
primes = [p for p in range(2, X + 1) if flag[p]]
for d in range(1, X + 1):                      # sigma(n), the sum of the divisors of n
    for m in range(d, X + 1, d): sig[m] += d
Mc, psic, M, ps = [0] * (X + 1), [0.0] * (X + 1), 0, 0.0
lam = [0.0] * (X + 1)
for p in primes:
    q = p
    while q <= X: lam[q] = math.log(p); q *= p
for n in range(1, X + 1):                      # running totals M(n) and psi(n)
    M += mu[n]; ps += lam[n]; Mc[n], psic[n] = M, ps
@functools.lru_cache(None)
def phi(x, a):                                 # numbers up to x free of the first a primes (Legendre)
    return x if a == 0 or x == 0 else phi(x, a - 1) - phi(x // primes[a - 1], a - 1)
@functools.lru_cache(None)
def mert(x):                                   # M(x) from sum_{n<=x} M(x/n) = 1 alone, no Mobius values
    total, n = 1, 2
    while n <= x:
        v = x // n; n2 = x // v; total -= (n2 - n + 1) * mert(v); n = n2 + 1
    return total
gam = sum(1 / k for k in range(1, 1001)) - math.log(1000) - 1 / 2000 + 1 / 12e6   # Euler's constant
li = lambda y: gam + math.log(y) + sum(y ** k / (k * math.factorial(k)) for k in range(1, 150))  # y = log x
def simpson(f, a, b, n=20000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n)))
Li_ser = lambda x: li(math.log(x)) - li(math.log(2))
Li_int = lambda x: simpson(lambda u: math.exp(u) / u, math.log(2), math.log(x))  # t = e^u
def zeta(s, N=50):                             # Euler-Maclaurin, valid for real s > -5, s != 1
    r = lambda m: math.prod(s + j for j in range(m)) * N ** (-s - m)
    return (sum(n ** -s for n in range(1, N)) + N ** (1 - s) / (s - 1) + N ** -s / 2
            + r(1) / 12 - r(3) / 720 + r(5) / 30240)
print("1. The prime count against Li(x), and the RH-sized error")
for x in SIZES:
    pi, a = sum(1 for p in primes if p <= x), sum(1 for p in primes if p * p <= x)
    b = math.sqrt(x) * math.log(x)
    print(f"x = {x}: pi sieve {pi}, Legendre {phi(x, a) + a - 1}; Li series {Li_ser(x):.2f}, Simpson {Li_int(x):.2f}; "
          f"pi - Li {pi - Li_ser(x):.2f}; sqrt(x) log x {b:.2f}; /(8 pi) {b / (8 * math.pi):.2f}")
print(f"li(2) = {li(math.log(2)):.4f}; pi - li at 10^6 {78498 - li(math.log(X)):.2f}; x/log x at 10^6 {X / math.log(X):.2f}, "
      f"gap {78498 - X / math.log(X):.2f}, ratio {78498 / (X / math.log(X)):.4f}")
print("2. Chebyshev's psi(x) against x")
for x in SIZES:
    print(f"x = {x}: psi {psic[x]:.2f}; psi - x {psic[x] - x:.2f}; sqrt(x) log^2 x / (8 pi) {math.sqrt(x) * math.log(x) ** 2 / (8 * math.pi):.2f}")
lhs, rhs = sum(psic[X // n] for n in range(1, X + 1)), sum(math.log(k) for k in range(2, X + 1))
print(f"Chebyshev at 10^6: sum psi(x/n) {lhs:.2f}; log x! {rhs:.2f}")
print(f"3. The Mertens function M(x); mu(6), mu(30), mu(12): {mu[6]} {mu[30]} {mu[12]}")
worst = max((abs(Mc[n]) / math.sqrt(n), n) for n in range(2, X + 1))
late = max((abs(Mc[n]) / math.sqrt(n), n) for n in range(1000, X + 1))
for x in SIZES:
    print(f"x = {x}: M sieve {Mc[x]}, recursion {mert(x)}; |M|/sqrt(x) {abs(Mc[x]) / math.sqrt(x):.4f}; "
          f"x^0.6 {x ** 0.6:.1f}")
print(f"largest |M(x)|/sqrt(x), 2 <= x <= 10^6: {worst[0]:.4f} at x = {worst[1]} (M = {Mc[worst[1]]}); "
      f"from 1000 on: {late[0]:.4f} at x = {late[1]} (M = {Mc[late[1]]})")
print("4. The Mellin step: sum mu(n)/n^s against 1/zeta(s)")
for s in (2.0, 0.75, 0.6):
    part = [0.0]; acc = 0.0
    for n in range(1, X + 1):
        if mu[n]: acc += mu[n] * n ** -s
        if n in SIZES: part.append(acc)
    abel = Mc[X] * X ** -s + sum(Mc[n] * (n ** -s - (n + 1) ** -s) for n in range(1, X))
    print(f"s = {s}: 1/zeta {1 / zeta(s):.6f}; partial sums to 10^4, 10^5, 10^6: "
          + ", ".join(f"{v:.6f}" for v in part[1:]) + f"; M-integral form at 10^6 {abel:.6f}")
    if s == 0.75: miss75, abel75, acc75 = abs(part[3] - 1 / zeta(s)), abel, acc
print(f"zeta(0.75) {zeta(0.75):.6f}; 6/pi^2 {6 / math.pi ** 2:.6f}")
print("5. Robin's inequality sigma(n) < e^gamma n log log n")
eg, ratio = math.exp(gam), lambda n: sig[n] / (n * math.log(math.log(n)))
gam2 = sum(1 / k for k in range(1, X + 1)) - math.log(X) - 1 / (2 * X)           # second road, 10^6 terms
print(f"Euler's constant: 1000 terms + corrections {gam:.10f}; 10^6 terms {gam2:.10f}")
bad = [n for n in range(3, X + 1) if ratio(n) >= eg]
top = max((ratio(n), n) for n in range(5041, X + 1))
print(f"e^gamma {eg:.6f}; failures for 3 <= n <= 10^6: {len(bad)}, largest {bad[-1]}; sigma(5040) {sig[5040]}, "
      f"ratio {ratio(5040):.6f}")
print("failures: " + " ".join(map(str, bad)))
print(f"largest ratio for 5040 < n <= 10^6: {top[0]:.6f} at n = {top[1]}, sigma {sig[top[1]]}")
print("6. The zeros' waves, and one zero off the line at height 14.134725")
T = 1000.0                                     # cut-off height for the zeros, T = sqrt(10^6)
print(f"T = 1000: zeros N(T) by the main term (T/2pi) log(T/(2pi e)) + 7/8 = "
      f"{T / (2 * math.pi) * math.log(T / (2 * math.pi * math.e)) + 7 / 8:.2f}; sum of 1/|rho| about "
      f"log^2(T/2pi) / (2pi) = {math.log(T / (2 * math.pi)) ** 2 / (2 * math.pi):.4f}; times sqrt(x) {1000 * math.log(T / (2 * math.pi)) ** 2 / (2 * math.pi):.1f}")
for beta in (0.5, 0.6):
    print(f"real part {beta}: wave size 2 x^beta / |rho| at 10^6 = {2 * X ** beta / abs(complex(beta, 14.134725)):.1f}")
print("chart x = 20000k: M " + ", ".join(str(Mc[20000 * k]) for k in range(1, 51)))
print("chart sqrt(x): " + ", ".join(f"{math.sqrt(20000 * k):.0f}" for k in range(1, 51)))
print("chart -sqrt(x): " + ", ".join(f"{-math.sqrt(20000 * k):.0f}" for k in range(1, 51)))
def sigma_by_factors(n):                       # product of (p^(k+1) - 1)/(p - 1), by trial division
    out, p = 1, 2
    while n > 1:
        k = 0
        while n % p == 0: n //= p; k += 1
        out *= (p ** (k + 1) - 1) // (p - 1); p += 1
    return out
assert sum(1 for p in primes if p <= X) == phi(X, 168) + 167 == 78498        # two prime counts
assert all(abs(Li_ser(x) - Li_int(x)) < 1e-4 for x in SIZES)                  # two roads to Li
assert all(Mc[x] == mert(x) for x in SIZES) and Mc[X] == 212                  # two roads to M
assert abs(lhs - rhs) < 1e-6 * rhs                                            # Chebyshev's identity
assert abs(abel75 - acc75) < 1e-9 and miss75 < 0.01                           # Abel step; Mellin evidence
assert sig[5040] == sigma_by_factors(5040) and sig[top[1]] == sigma_by_factors(top[1]) and bad[-1] == 5040
assert abs(gam - gam2) < 1e-10 and len(bad) == 26                             # two roads to gamma; Robin's list
assert all(abs(psic[x] - x) < math.sqrt(x) * math.log(x) ** 2 / (8 * math.pi) for x in SIZES)
print("ALL CHECKS PASS")
