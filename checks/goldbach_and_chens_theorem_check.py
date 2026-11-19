# Goldbach and Chen's theorem -- the check behind the card.  Standard library
# only: math supplies log, cos and sin.  Every prime, count and constant is
# computed here.  Roads to each answer: a smallest-factor sieve against a
# Miller-Rabin test written out; direct counts against the circle-method
# integral; counts against the Hardy-Littlewood and Vinogradov predictions.
import math

N = 1_000_002
spf = list(range(N + 1))                          # smallest prime factor of m
for i in range(2, 1001):
    if spf[i] == i:
        for k in range(i * i, N + 1, i):
            if spf[k] == k:
                spf[k] = i
P = [m for m in range(2, N + 1) if spf[m] == m]

def is_p(m): return m > 1 and spf[m] == m

def factors(m):                                   # prime factors, with repeats
    out = []
    while m > 1:
        out.append(spf[m]); m //= spf[m]
    return out

def miller_rabin(m):                              # road two; bases 2, 3, 5, 7 are exact below 3.2e9
    for a in (2, 3, 5, 7):
        if m % a == 0: return m == a
    d, s = m - 1, 0
    while d % 2 == 0: d, s = d // 2, s + 1
    for a in (2, 3, 5, 7):
        x = pow(a, d, m)
        if x == 1 or x == m - 1: continue
        for _ in range(s - 1):
            x = x * x % m
            if x == m - 1: break
        else: return False
    return m > 1

def pairs(n):                                     # smaller prime p of each p + q = n
    out = []
    for p in P:
        if p > n // 2: break
        if is_p(n - p): out.append(p)
    return out

C2 = 1.0                                          # twin-prime constant, primes to 10^6
for p in P[1:]: C2 *= 1 - 1 / (p - 1) ** 2

def sing(n):                                      # Hardy-Littlewood local factor sing(n)
    s = 2 * C2
    for p in set(factors(n)):
        if p > 2: s *= (p - 1) / (p - 2)
    return s

def j_int(n, steps=2_000_000):                      # Simpson's rule for the integral J(n)
    a, h = 2.0, (n - 4.0) / steps
    f = lambda t: 1 / (math.log(t) * math.log(n - t))
    s = f(a) + f(n - 2.0)
    for i in range(1, steps): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def circle(n, k, M=4096):                         # (1/M) sum of F(a)^k e(-n a) over a = j/M
    tot, sq, ps = 0.0, 0.0, [p for p in P if p <= n]
    for j in range(M):
        re = sum(math.cos(2 * math.pi * p * j / M) for p in ps)
        im = sum(math.sin(2 * math.pi * p * j / M) for p in ps)
        z = complex(re, im) ** k * complex(math.cos(2 * math.pi * n * j / M), -math.sin(2 * math.pi * n * j / M))
        tot += z.real; sq += re * re + im * im
    return tot / M, sq / M

n = 10 ** 6
first = pairs(100)[:4]
print("100 = " + " = ".join(f"{p} + {100 - p}" for p in first) + f" (4 of {len(pairs(100))})")
R = pairs(n)
R_mr = sum(1 for p in range(2, n // 2 + 1) if miller_rabin(p) and miller_rabin(n - p))
print(f"primes up to 1000000: {sum(1 for p in P if p <= n)}")
print(f"R(1000000) = {len(R)} by the sieve, {R_mr} by Miller-Rabin; smallest pair {R[0]} + {n - R[0]}")
worst, where, ok = 0, 0, True
for m in range(4, n + 1, 2):
    p = next((p for p in P if is_p(m - p)), None)
    if p is None: ok = False; break
    if p > worst: worst, where = p, m
print(f"every even n from 4 to 1000000 has a pair: {'yes' if ok else 'no'}; largest smallest prime {worst}, at n = {where}")
w = pairs(999998)[0]
print(f"so every odd N from 7 to 1000003 is three primes; 1000001 = 3 + {w} + {999998 - w}")
print(f"twin-prime constant C2, primes to a million: {C2:.6f}")
print("n | factors | sing(n) | R(n) | sing n/(2 log^2 n) | sing J/2 | R/(sing J/2)")
hl = {}
for m in (100, 1000, 10 ** 4, 10 ** 5, 10 ** 6, 999998, 1000002):
    pred = sing(m) * j_int(m) / 2
    hl[m] = len(pairs(m)) / pred
    print(f"{m} | {factors(m)} | {sing(m):.4f} | {len(pairs(m))} | {sing(m) * m / math.log(m) ** 2 / 2:.1f} | {pred:.1f} | {hl[m]:.4f}")
L = math.log(n)
print(f"by hand, n = 1000000: log n = {L:.4f}, squared {L * L:.3f}, n over that {n / (L * L):.1f}; "
      f"sing = 2 x {C2:.6f} x 4/3 = {sing(n):.6f}; half the product {sing(n) * n / (L * L) / 2:.1f}")
print("N | sing3(N) | ordered triples | sum log p log q log r | sing3 N^2/2 | ratio")
vin = []
for T in (1001, 10001, 100001):
    s3 = 1.0
    for p in P: s3 *= (1 - 1 / (p - 1) ** 2) if T % p == 0 else (1 + 1 / (p - 1) ** 3)
    ps, cnt, wt = [p for p in P if p < T], 0, 0.0
    for p in ps:
        for q in ps:
            r = T - p - q
            if r < 2: break
            if is_p(r): cnt += 1; wt += math.log(p) * math.log(q) * math.log(r)
    vin.append((cnt, wt / (s3 * T * T / 2)))
    print(f"{T} | {s3:.4f} | {cnt} | {wt:.0f} | {s3 * T * T / 2:.0f} | {vin[-1][1]:.4f}")
c2, pars = circle(1000, 2)
c3, _ = circle(1001, 3)
print(f"circle method, 4096 points: ordered pairs of 1000 = {c2:.3f}, ordered triples of 1001 = {c3:.3f}, mean |F|^2 = {pars:.3f}")
chen = sum(1 for p in P if p <= n - 2 and len(factors(n - p)) <= 2)
twin_chen = sum(1 for p in P if p < n and len(factors(p + 2)) <= 2)
twins = sum(1 for p in P if p < n and is_p(p + 2))
print(f"Chen: p from 2 to n - 2 with n - p prime or two primes: {chen}, of which {2 * len(R)} have n - p prime")
print(f"Chen's twin form: p below a million with p + 2 prime or two primes: {twin_chen}, of which {twins} are twins")
print(f"mistake 1, two primes for odd 1000001: {len(pairs(1000001))} ways, since 999999 = {factors(999999)}")
print(f"mistake 2, no local factor: predicts {C2 * j_int(999998):.1f} for 999998 and {C2 * j_int(1000002):.1f} for 1000002; "
      f"true {len(pairs(999998))} and {len(pairs(1000002))}")
print(f"mistake 3, Chen read as Goldbach: {chen} against {2 * len(R)} ordered prime pairs")
print(f"mistake 4, two primes in Vinogradov's budget: error room {sum(1 for p in P if p <= n)} against {2 * len(R)} ordered pairs")
assert len(R) == R_mr == 5402                                 # sieve against Miller-Rabin
assert round(c2) == 2 * len(pairs(1000)) and round(c3) == vin[0][0]   # circle method against counting
assert round(pars) == sum(1 for p in P if p <= 1000)          # Parseval: mean |F|^2 is pi(1000)
assert abs(hl[10 ** 6] - 1) < 0.01 and abs(hl[999998] - 1) < 0.01 and abs(hl[1000002] - 1) < 0.01
assert vin[0][1] < vin[1][1] < vin[2][1] < 1 and vin[2][1] > 0.98
assert ok and miller_rabin(w) and miller_rabin(999998 - w) and chen > 2 * len(R) and twin_chen > twins
print("ALL CHECKS PASS")
