# The von Mangoldt function -- the check behind the card.  Standard library
# only.  Lambda(n) is ln p when n is a power of a prime p, and 0 otherwise.
# Every prime here comes from a sieve written out below; nothing imported
# knows a prime.  Roads: the sieve, trial division, an lcm built by Euclid's
# gcd, Mobius signs, partial summation, and zeta by Euler-Maclaurin.
from math import log

N = 10**6
spf = list(range(N + 1))                 # smallest prime factor of each n
for p in range(2, 1001):
    if spf[p] == p:
        for m in range(p * p, N + 1, p):
            if spf[m] == m: spf[m] = p

def lam(n):                              # von Mangoldt, from the sieve
    if n < 2: return 0.0
    p, m = spf[n], n
    while m % p == 0:
        m //= p
    return log(p) if m == 1 else 0.0

def mu(n):                               # Mobius: 0 if a square divides n
    s = 1
    while n > 1:
        p, n = spf[n], n // spf[n]
        if n % p == 0: return 0
        s = -s
    return s

def gcd(a, b):                           # Euclid, written out
    while b: a, b = b, a % b
    return a

def is_prime(n): return n > 1 and all(n % d for d in range(2, int(n**0.5) + 1))

marks = list(range(10, 101, 10)) + [1000, 10**4, 10**5, 10**6]
pi = th = ps = 0
at, primes, L = {}, [], [0.0] * (N + 1)
for n in range(2, N + 1):
    L[n] = lam(n)
    ps += L[n]
    if spf[n] == n:
        pi, th = pi + 1, th + log(n)
        primes.append(n)
    if n in marks:
        at[n] = (pi, th, ps)

pi100, th100, ps100 = at[100]
trial = sum(1 for n in range(2, 101) if is_prime(n))
print(f"primes to 100: sieve {pi100}, trial division {trial}")
print(f"psi(100) = {ps100:.2f}; theta(100) = {th100:.2f}; prime powers p^2, p^3, ... add {ps100 - th100:.2f}")
big = 1
for n in range(1, 101):                  # lcm(1..100) by gcd; never names a prime
    big = big * n // gcd(big, n)
print(f"lcm(1..100), built by gcd: {len(str(big))} digits, ln = {log(big):.6f}; psi(100) = {ps100:.6f}")

def theta_upto(m): return sum(log(p) for p in primes if p <= m)

def iroot(x, k):                         # largest m with m^k <= x
    m = int(round(x ** (1 / k)))
    while m ** k > x: m -= 1
    while (m + 1) ** k <= x: m += 1
    return m

parts = [theta_upto(iroot(100, k)) for k in range(1, 7)]
print("psi(100) as theta(100) + theta(10) + theta(4) + theta(3) + theta(2) + theta(2) = "
      + " + ".join(f"{t:.2f}" for t in parts) + f" = {sum(parts):.2f}")
cheb = sum(L[d] * (100 // d) for d in range(2, 101))
lnfact = sum(log(n) for n in range(2, 101))
print(f"sum of Lambda(d) floor(100/d) = {cheb:.6f}; ln(100!) = {lnfact:.6f}")
H = 720720
divs = [d for d in range(1, H + 1) if H % d == 0]
pp = [d for d in divs if L[d] > 0]
print(f"720720: {len(divs)} divisors, {len(pp)} of them prime powers; their Lambda add to "
      f"{sum(L[d] for d in pp):.6f}; ln 720720 = {log(H):.6f}")

M = 10**4
one_lam, mu_log = [0.0] * (M + 1), [0.0] * (M + 1)
for d in range(1, M + 1):
    for m in range(d, M + 1, d):
        one_lam[m] += L[d]               # (1 * Lambda)(m)
        mu_log[m] -= mu(d) * log(d)      # minus sum of mu(d) ln d over d dividing m
e1 = max(abs(one_lam[n] - log(n)) for n in range(1, M + 1))
e2 = max(abs(mu_log[n] - L[n]) for n in range(1, M + 1))
print(f"up to {M}: sum of Lambda(d) over d | n equals ln n: {'yes' if e1 < 1e-12 else 'no'}")
print(f"up to {M}: minus sum of mu(d) ln d over d | n equals Lambda(n): {'yes' if e2 < 1e-12 else 'no'}")

def pi_from_theta(x):                    # partial summation, theta -> pi
    ps_ = [p for p in primes if p <= x]
    t, out = 0.0, 0.0
    for i, p in enumerate(ps_):
        t += log(p)
        nxt = ps_[i + 1] if i + 1 < len(ps_) else x
        out += t * (1 / log(p) - 1 / log(nxt))
    return t / log(x) + out

def theta_from_pi(x):                    # partial summation, pi -> theta
    ps_ = [p for p in primes if p <= x]
    out = 0.0
    for i, p in enumerate(ps_):
        nxt = ps_[i + 1] if i + 1 < len(ps_) else x
        out += (i + 1) * (log(nxt) - log(p))
    return len(ps_) * log(x) - out

r100, r6, t100 = pi_from_theta(100), pi_from_theta(N), theta_from_pi(100)
print(f"pi from theta by partial summation: pi(100) = {r100:.6f}, pi(10^6) = {r6:.6f}")
print(f"theta from pi by partial summation: theta(100) = {t100:.6f}")

dsum = sum(L[n] / n**2 for n in range(2, N + 1)) + 1 / N   # tail ~ 1/N since psi ~ x
K = 1000
z2 = sum(1 / n**2 for n in range(1, K + 1)) + 1 / K - 1 / (2 * K**2) + 1 / (6 * K**3)
lk = log(K)
dz2 = sum(log(n) / n**2 for n in range(2, K + 1)) + (lk + 1) / K - lk / (2 * K**2) - (1 - 2 * lk) / (12 * K**3)
print(f"zeta(2) = {z2:.6f}; -zeta'(2) = {dz2:.6f}; -zeta'(2)/zeta(2) = {dz2 / z2:.5f}")
print(f"sum of Lambda(n)/n^2 to 10^6, plus tail 1/10^6 = {dsum:.5f}")

print("x | pi(x) | theta(x) | psi(x) | psi - theta | psi/x | pi ln x / x")
for x in [100, 1000, 10**4, 10**5, 10**6]:
    a, b, c = at[x]
    print(f"{x} | {a} | {b:.2f} | {c:.2f} | {c - b:.2f} | {c / x:.4f} | {a * log(x) / x:.4f}")
print("chart x: " + ", ".join(str(x) for x in marks[:10]))
print("chart psi: " + ", ".join(f"{at[x][2]:.2f}" for x in marks[:10]))
print("chart theta: " + ", ".join(f"{at[x][1]:.2f}" for x in marks[:10]))
print("chart pi: " + ", ".join(str(at[x][0]) for x in marks[:10]))

npp = sum(1 for n in range(2, 101) if L[n] > 0)
whole = sum(log(n) for n in range(2, 101) if L[n] > 0)
print(f"mistake 1, primes only: theta(100) = {th100:.2f}, not {ps100:.2f}; at n = 8 the divisor sum gives {log(2):.4f}, not ln 8 = {log(8):.4f}")
print(f"mistake 2, weight ln n at each prime power: {whole:.2f}, not {ps100:.2f}")
print(f"mistake 3, weight 1 at each prime power: {npp}; pi(100) x ln 100 = {pi100 * log(100):.2f}")
print(f"mistake 4, log base 10: {ps100 / log(10):.2f}, not {ps100:.2f}")

assert pi100 == trial == 25                                   # sieve against trial division
assert abs(log(big) - ps100) < 1e-9                           # lcm road against Lambda road
assert abs(sum(parts) - ps100) < 1e-9 and abs(cheb - lnfact) < 1e-9
assert e1 < 1e-9 and e2 < 1e-9                                # 1*Lambda = ln, mu*ln = Lambda
assert abs(r100 - 25) < 1e-9 and abs(r6 - at[N][0]) < 1e-6 and abs(t100 - th100) < 1e-9
assert abs(dsum - dz2 / z2) < 1e-5                            # Dirichlet series = -zeta'/zeta
print("ALL CHECKS PASS")
