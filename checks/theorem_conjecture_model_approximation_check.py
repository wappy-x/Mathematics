# Kinds of claim -- the check behind the card.  Standard library only.
# Ten claims get a kind (fixed) and a dated status (moves).  The numbers
# behind them are computed here, each by two roads that share no arithmetic.
from math import exp, log, sqrt, pi, log10

LIMIT = 10**6
LEDGER = [  # (claim, kind, status, year of that status, what backs it)
    ("central limit theorem", "theorem", "proved", 1901, "Lyapunov's proof"),
    ("four-colour theorem", "conjecture", "proved", 1977, "refereed; formal proof 2005"),
    ("Fermat's last theorem", "conjecture", "proved", 1995, "open 1637 to 1993"),
    ("Poincare conjecture", "conjecture", "proved", 2006, "checked by three teams"),
    ("Goldbach", "conjecture", "open", 2026, "checked to 4e18 in 2014"),
    ("Riemann hypothesis", "conjecture", "open", 2026, "zeros checked to 3e12"),
    ("Polya: L(n) <= 0 for n >= 2", "conjecture", "refuted", 1958, "Haselgrove; first failure 906150257"),
    ("Black-Scholes call 9.23", "model", "proved", 1973, "inside the model; fit is evidence"),
    ("P(<= 55 heads) ~ Phi(1.1)", "approximation", "proved", 2026, "error computed below"),
    ("pi(1e6) ~ 1e6/ln(1e6)", "approximation", "proved", 2026, "error computed below"),
]
TIMELINE = {"four-colour": [(1852, "open"), (1879, "proved"), (1890, "open"),
                            (1976, "claimed"), (1977, "proved")],
            "Fermat": [(1637, "open"), (1993, "claimed"), (1995, "proved")]}

def status_on(claim, year):              # the latest event on or before the year
    s = "not yet stated"
    for y, st in TIMELINE[claim]:
        if y <= year:
            s = st
    return s

sieve = bytearray([1]) * (LIMIT + 1)     # road A to the primes: Eratosthenes
sieve[0] = sieve[1] = 0
for p in range(2, int(LIMIT ** 0.5) + 1):
    if sieve[p]:
        sieve[p * p::p] = bytearray(len(range(p * p, LIMIT + 1, p)))
spf = list(range(LIMIT + 1))             # road B: smallest prime factor of each n
for p in range(2, int(LIMIT ** 0.5) + 1):
    if spf[p] == p:
        for m in range(p * p, LIMIT + 1, p):
            if spf[m] == m:
                spf[m] = p
primes = [p for p in range(2, LIMIT + 1) if sieve[p]]
count_b = sum(1 for n in range(2, LIMIT + 1) if spf[n] == n)

def trial_prime(n):                      # a third test, by trial division
    return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))

goldbach_ok = True                       # every even 4 <= n <= LIMIT, one pair each
for n in range(4, LIMIT + 1, 2):
    for p in primes:
        if p > n // 2 or sieve[n - p]:   # stop at n/2: n - p never goes below 0
            break
    goldbach_ok = goldbach_ok and p <= n // 2
r100 = sum(1 for p in primes if p <= 50 and sieve[100 - p])
r100_trial = sum(1 for p in range(2, 51) if trial_prime(p) and trial_prime(100 - p))

lam = [0, 1] + [0] * (LIMIT - 1)         # Liouville: -1 to the number of prime factors
for n in range(2, LIMIT + 1):
    lam[n] = -lam[n // spf[n]]
def lam_trial(n):                       # the same sign, by factoring n by hand
    k, d = 0, 2
    while n > 1:
        while n % d == 0:
            n //= d; k += 1
        d += 1
    return (-1) ** k
L, worst = 1, -LIMIT
for n in range(2, LIMIT + 1):
    L += lam[n]
    worst = max(worst, L)

def colourings(k):                       # Belgium, France, Germany, Luxembourg, Netherlands
    edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 0), (4, 2)]
    total = 0
    for c in range(k ** 5):
        col = [c // k ** i % k for i in range(5)]
        total += all(col[a] != col[b] for a, b in edges)
    return total
colour_formula = lambda k: k * (k - 1) * (k - 2) ** 2 * (k - 3)   # road two

row = [1]                                # 100 fair flips: Pascal's rule, exact integers
for _ in range(100):
    row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
prod = [1]                               # road two: C(n,k) = C(n,k-1)(n-k+1)/k
for k in range(1, 101):
    prod.append(prod[-1] * (101 - k) // k)
exact = sum(row[:56]) / 2 ** 100; z = (55.5 - 100 * 0.5) / sqrt(100 * 0.25)  # half step

def Phi(z):                              # bell-curve area left of z, by the erf series
    s, term, n = 0.0, z, 0
    while abs(term) > 1e-17:
        s += term / (2 * n + 1); n += 1; term *= -z * z / (2 * n)
    return 0.5 + s / sqrt(2 * pi)
def Phi_simpson(z, m=2000):              # the same area, by Simpson's rule
    h = z / m
    f = lambda x: exp(-x * x / 2) / sqrt(2 * pi)
    return 0.5 + h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(i * h) for i in range(m + 1))

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
d1 = (log(S / K) + (r - q + sig * sig / 2) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
bs = S * exp(-q * T) * Phi(d1) - K * exp(-r * T) * Phi(d2)
m, a, b = 4000, -d2, 10.0                # road two: average the payoff over the bell
h = (b - a) / m
pay = lambda x: (S * exp((r - q - sig * sig / 2) * T + sig * sqrt(T) * x) - K) * exp(-x * x / 2) / sqrt(2 * pi)
bs_int = exp(-r * T) * h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * pay(a + i * h) for i in range(m + 1))
xlnx = LIMIT / log(LIMIT)

print("ledger, status as of 2026-11-23")
for name, kind, st, yr, why in LEDGER:
    print(f"  {name:<28} {kind:<13} {st:<8} {yr}  {why}")
kinds = ["theorem", "conjecture", "model", "approximation"]
stats = ["open", "claimed", "proved", "refuted"]
print("grid, kind down, status across:  " + "  ".join(stats))
for kd in kinds:
    print(f"  {kd:<13}" + "".join(f"{sum(1 for x in LEDGER if x[1] == kd and x[2] == st):>9}" for st in stats))
for claim, years in (("four-colour", (1860, 1885, 1900, 1976, 2010)), ("Fermat", (1900, 1994, 2000))):
    print(f"status of {claim}: " + ", ".join(f"{y} {status_on(claim, y)}" for y in years))
print(f"primes below 1e6: Eratosthenes {len(primes)}, smallest-factor sieve {count_b}")
print(f"Goldbach, every even n from 4 to 1e6 has a pair: {'yes' if goldbach_ok else 'no'}; r(100) = {r100} by sieve, {r100_trial} by trial division")
print(f"Polya, largest L(n) for 2 <= n <= 1e6: {worst}; lambda by sieve = by trial division to 1e4: {'yes' if all(lam[n] == lam_trial(n) for n in range(1, 10001)) else 'no'}")
print(f"map of 5 neighbours: 3 colours {colourings(3)} ways, 4 colours {colourings(4)} ways; formula {colour_formula(3)}, {colour_formula(4)}")
print(f"P(at most 55 heads in 100): exact {exact:.6f}; Pascal = product formula: {'yes' if row == prod else 'no'}")
print(f"  bell with half step, z = (55.5 - 50) / 5 = {z:.1f}: Phi {Phi(z):.6f}, Simpson {Phi_simpson(z):.6f}, error {abs(Phi(z) - exact):.6f}")
print(f"  bell without it   Phi(1.0) {Phi(1.0):.6f}, error {abs(Phi(1.0) - exact):.6f}")
print(f"Black-Scholes call: formula {bs:.6f}, integral {bs_int:.6f}")
print(f"pi(1e6) = {len(primes)}; 1e6/ln(1e6) = {xlnx:.1f}; ratio {len(primes) / xlnx:.6f}; short by {1 - xlnx / len(primes):.4f}")
print("log10 of how far each pattern is known to hold:")
for label, x in (("Polya, checked here", LIMIT), ("Polya, first failure", 906150257),
                 ("Goldbach, checked here", LIMIT), ("Goldbach, checked 2014", 4e18)):
    print(f"  {label:<24} {'#' * round(2 * log10(x)):<37} {log10(x):5.2f}")

assert len(primes) == count_b == 78498                    # two sieves, the known count
assert goldbach_ok and r100 == r100_trial == 6            # checked for n <= 1e6 only
assert worst == 0 and all(lam[n] == lam_trial(n) for n in range(1, 10001))
assert colourings(3) == colour_formula(3) == 0 and colourings(4) == colour_formula(4)
assert row == prod and abs(Phi(z) - Phi_simpson(1.1)) < 1e-9 and abs(Phi(z) - exact) < 1e-4
assert abs(bs - bs_int) < 1e-6 and abs(bs - 9.227005508154) < 1e-9
assert status_on("four-colour", 1885) == "proved" and status_on("four-colour", 1900) == "open"
assert len({x[2] for x in LEDGER if x[1] == "conjecture"}) == 3   # one kind, three statuses
print("ALL CHECKS PASS")
