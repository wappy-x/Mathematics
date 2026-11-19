# Multiplicative functions and Dirichlet convolution -- the check behind the card.
# Nothing is imported.  The number is 720720 = 2^4 * 3^2 * 5 * 7 * 11 * 13.
# Road one lists divisors and counts by brute force.  Road two rebuilds each
# function from its values at prime powers.  Road three sieves every n up to a
# million.  Dirichlet inverses come by a recursion and by prime powers.
N0, LIMIT = 720720, 10**6

def gcd(a, b):                                   # Euclid's algorithm, written out
    while b:
        a, b = b, a % b
    return a

def factor(n):                                   # trial division: [(p, a), ...]
    out, p = [], 2
    while p * p <= n:
        a = 0
        while n % p == 0:
            n, a = n // p, a + 1
        if a:
            out.append((p, a))
        p += 1
    return out + [(n, 1)] if n > 1 else out

def divisors(n):                                 # brute force: try every d up to sqrt(n)
    small = [d for d in range(1, int(n ** 0.5) + 1) if n % d == 0]
    return sorted(set(small + [n // d for d in small]))

def rebuild(n, at_pp):                           # product of the values at each p^a exactly dividing n
    out = 1
    for p, a in factor(n):
        out *= at_pp(p, a)
    return out

tau_pp = lambda p, a: a + 1
sigma_pp = lambda p, a: (p ** (a + 1) - 1) // (p - 1)
sigma2_pp = lambda p, a: (p ** (2 * a + 2) - 1) // (p * p - 1)
phi_pp = lambda p, a: p ** (a - 1) * (p - 1)
mu_pp = lambda p, a: -1 if a == 1 else 0

def conv(f, g, n):                               # Dirichlet convolution at n
    return sum(f(d) * g(n // d) for d in divisors(n))

def inverse(f, ds):                              # Dirichlet inverse on a divisor-closed list, f(1) = 1
    inv = {}
    for m in ds:
        inv[m] = 1 if m == 1 else -sum(f(m // d) * inv[d] for d in ds if d < m and m % d == 0)
    return inv

def yn(claim):
    return "yes" if claim else "no"

def first_failure(f, pairs):                     # first pair (m, n) with f(mn) != f(m) f(n)
    for m, n in pairs:
        if f(m * n) != f(m) * f(n):
            return f"no, {m} x {n} gives {f(m * n)} against {f(m) * f(n)}"
    return "yes"

ds = divisors(N0)
brute = {"tau": len(ds), "sigma": sum(ds), "sigma_2": sum(d * d for d in ds),
         "phi": sum(1 for m in range(1, N0 + 1) if gcd(m, N0) == 1)}
pp = {"tau": tau_pp, "sigma": sigma_pp, "sigma_2": sigma2_pp, "phi": phi_pp}
print(f"720720 = {' * '.join(f'{p}^{a}' for p, a in factor(N0))}")
print("p^a   tau  sigma  sigma_2  phi")
for p, a in factor(N0):
    print(f"{p ** a:<5} {tau_pp(p, a):>3} {sigma_pp(p, a):>6} {sigma2_pp(p, a):>8} {phi_pp(p, a):>4}")
for name in brute:
    print(f"{name}(720720): by listing {brute[name]}, from prime powers {rebuild(N0, pp[name])}")
    assert brute[name] == rebuild(N0, pp[name])         # road one against road two, four functions
print(f"720720 = 16 x {N0 // 16}: {len(ds)} divisors = 5 x {len(divisors(N0 // 16))}; gcd(360, 2002) = {gcd(360, 2002)}")

tau = [0] * (LIMIT + 1)                          # road three: 1 * 1 summed literally, for every n
for d in range(1, LIMIT + 1):
    for m in range(d, LIMIT + 1, d):
        tau[m] += 1
spf = list(range(LIMIT + 1))                     # smallest prime factor of every n
for p in range(2, int(LIMIT ** 0.5) + 1):
    if spf[p] == p:
        for m in range(p * p, LIMIT + 1, p):
            if spf[m] == m:
                spf[m] = p
phi = list(range(LIMIT + 1))                     # phi by the product sieve: n times (1 - 1/p)
for p in range(2, LIMIT + 1):
    if spf[p] == p:
        for m in range(p, LIMIT + 1, p):
            phi[m] -= phi[m] // p
phi_sum = [0] * (LIMIT + 1)                      # (phi * 1)(n), summed literally
for d in range(1, LIMIT + 1):
    for m in range(d, LIMIT + 1, d):
        phi_sum[m] += phi[d]

def tau_from_spf(n):                             # road two again, using the smallest-factor table
    out = 1
    while n > 1:
        p, a = spf[n], 0
        while n % p == 0:
            n, a = n // p, a + 1
        out *= a + 1
    return out

coprime = [(m, n) for m in range(2, 101) for n in range(m, 101) if gcd(m, n) == 1]
every = [(m, n) for m in range(2, 101) for n in range(m, 101)]
omega = lambda n: len(factor(n))
print("f(mn) = f(m) f(n) on all coprime m, n up to 100:")
for name, f in [("tau", lambda n: tau[n]), ("sigma", lambda n: rebuild(n, sigma_pp)),
                ("phi", lambda n: phi[n]), ("n + 1", lambda n: n + 1), ("distinct-prime count", omega)]:
    print(f"  {name}: {first_failure(f, coprime)}")
print("f(mn) = f(m) f(n) on all m, n up to 100, coprime or not:")
print(f"  n^2: {first_failure(lambda n: n * n, every)}; tau: {first_failure(lambda n: tau[n], every)}")
agree = all(tau[n] == tau_from_spf(n) for n in range(1, LIMIT + 1))
top = max(tau)
champs = [n for n in range(1, LIMIT + 1) if tau[n] == top]
print(f"tau to 1000000, divisor sieve against prime-power rebuild: {'all agree' if agree else 'MISMATCH'}")
print(f"largest tau to 1000000: {top}, at {champs}")
print(f"(phi * 1)(720720) over its {len(ds)} divisors: {conv(lambda n: phi[n], lambda n: 1, N0)}")
print(f"(phi * 1)(n) = n for every n to 1000000: {yn(all(phi_sum[n] == n for n in range(1, LIMIT + 1)))}")
print(f"(id * 1)(720720) = {conv(lambda n: n, lambda n: 1, N0)}; (1 * 1)(720720) = {conv(lambda n: 1, lambda n: 1, N0)}")
assert agree and champs[0] == N0 and top == brute["tau"]                 # sieve against rebuild
assert all(phi_sum[n] == n for n in range(1, LIMIT + 1))                 # phi * 1 = id, every n
assert conv(lambda n: n, lambda n: 1, N0) == rebuild(N0, sigma_pp) == 3249792   # id * 1 against prime powers

inv_phi, inv_tau, inv_one, inv_id = [inverse(f, ds) for f in (lambda n: phi[n], lambda n: tau[n], lambda n: 1, lambda n: n)]
print(f"at 1, 2, 4, 8, 16: phi {[phi[2 ** k] for k in range(5)]}, tau inverse by recursion {[inv_tau[2 ** k] for k in range(5)]}")
print(f"phi inverse at 720720: by recursion {inv_phi[N0]}, product of (1 - p) {rebuild(N0, lambda p, a: 1 - p)}")
print(f"id inverse at 30: {inv_id[30]}; 1's inverse at 30: {inv_one[30]}")
eps = lambda n: 1 if n == 1 else 0
checks = [all(inv_phi[d] == rebuild(d, lambda p, a: 1 - p) for d in ds),
          all(inv_tau[d] == rebuild(d, lambda p, a: [1, -2, 1][a] if a < 3 else 0) for d in ds),
          all(inv_one[d] == rebuild(d, mu_pp) for d in ds),
          all(inv_id[d] == d * rebuild(d, mu_pp) for d in ds),
          all(conv(lambda n: phi[n], lambda n: inv_phi[n], d) == eps(d) for d in ds)]
print(f"recursion against prime powers on all 240 divisors (phi, tau, 1, id), and phi * inverse = epsilon: {' '.join(yn(c) for c in checks)}")
assert all(checks)                                                       # two roads to each inverse

print(f"mistake 1, tau(360) x tau(2002) = {tau[360]} x {tau[2002]} = {tau[360] * tau[2002]}, not {tau[N0]}")
print(f"mistake 2, phi(360) x phi(2002) = {phi[360]} x {phi[2002]} = {phi[360] * phi[2002]}, not {phi[N0]}")
print(f"mistake 3, phi(p^a) taken as p^a - 1: {rebuild(N0, lambda p, a: p ** a - 1)}, not {phi[N0]}")
print(f"mistake 4, phi times 1 value by value: {phi[N0] * 1} at 720720, not {phi_sum[N0]}")
print("ALL CHECKS PASS")
