# Carmichael's function -- the check behind the card.  Nothing is imported.
def gcd(a, b): return gcd(b, a % b) if b else a
def lcm(xs): return xs[0] * lcm(xs[1:]) // gcd(xs[0], lcm(xs[1:])) if xs else 1
def pw(a, e, n): return 1 % n if e == 0 else pw(a * a % n, e // 2, n) * (a if e % 2 else 1) % n
def primes(n, p=2): return [] if n < 2 else [n] if p * p > n else [p] + primes(n // p, p) if n % p == 0 else primes(n, p + 1)
def factor(n): return [(p, primes(n).count(p)) for p in sorted(set(primes(n)))]     # prime, power
def piece(p, k): return 2 ** (k - 2) if p == 2 and k >= 3 else (p - 1) * p ** (k - 1)
def lam(n): return lcm([piece(p, k) for p, k in factor(n)])         # road one: the factorisation
def units(n): return [a for a in range(1, n) if gcd(a, n) == 1]
def order(a, n): return next(e for e in range(1, n + 1) if pw(a, e, n) == 1)
def lam_brute(n): return max(order(a, n) for a in units(n))      # road two: the longest cycle
def korselt(n): return factor(n)[0][0] < n and all(k == 1 and (n - 1) % (p - 1) == 0 for p, k in factor(n))
def fools_all(n): return factor(n)[0][0] < n and all(pw(a, n - 1, n) == 1 for a in units(n))
def has_root(n): return n in (2, 4) or (f := factor(n // 2 if n % 4 == 2 else n)) != [] and len(f) == 1 and f[0][0] > 2
print(f"15 = 3 x 5: lambda = lcm(2, 4) = {lam(15)}, phi = {len(units(15))}, 2^4 mod 15 = {pw(2, 4, 15)}")
print(f"561 = 3 x 11 x 17: lambda = lcm(2, 10, 16) = {lam(561)}, phi = {len(units(561))}, 560 = {560 // lam(561)} x 80")
print(f"longest cycle, every base tried: 15 -> {lam_brute(15)}, 561 -> {lam_brute(561)}; cycles of 2, 5, 13 on 561: {order(2, 561)}, {order(5, 561)}, {order(13, 561)}")
print("2-power clocks 8, 16, 32, 64: lambda", [lam(2 ** k) for k in (3, 4, 5, 6)], "phi", [len(units(2 ** k)) for k in (3, 4, 5, 6)], "cycle of 5", [order(5, 2 ** k) for k in (3, 4, 5, 6)])
same, eq, roots = (sum(map(t, range(2, 201))) for t in (lambda n: lam(n) == lam_brute(n), lambda n: lam(n) == len(units(n)), has_root))
print(f"clocks 2 to 200: formula = longest cycle on {same}; lambda = phi on {eq}, primitive root on {roots}")
brute, kors = [n for n in range(4, 10000) if fools_all(n)], [n for n in range(4, 10000) if korselt(n)]
print(f"Carmichael numbers below 10000, every base tried: {brute}\nCarmichael numbers below 10000, Korselt's test:   {kors}")
d_phi, d_lam = (next(d for d in range(1, m) if 17 * d % m == 1) for m in (3120, lam(3233)))
print(f"RSA, 3233 = 61 x 53, e = 17: d = {d_phi} from phi 3120, d = {d_lam} from lambda {lam(3233)}; 65 -> {pw(65, 17, 3233)} -> {pw(pw(65, 17, 3233), d_lam, 3233)}")
print(f"mistakes: 2 x 10 x 16 = {2 * 10 * 16}; 3^2, 5^2, 7^2 mod 8 = {pw(3, 2, 8)}, {pw(5, 2, 8)}, {pw(7, 2, 8)}; 9 passes Korselt minus 'no prime twice': {['no', 'yes'][all((9 - 1) % (p - 1) == 0 for p, k in factor(9))]}, yet 2^8 mod 9 = {pw(2, 8, 9)}; 3^80 mod 561 = {pw(3, 80, 561)}")
assert lam(561) == lam_brute(561) == 80 and lam(15) == lam_brute(15) == 4 and same == 199 and all(pw(a, 80, 561) == 1 for a in units(561))
assert all((lam(n) == len(units(n))) == has_root(n) for n in range(2, 201)) and roots == eq == 84 and not korselt(9)
assert brute == kors == [561, 1105, 1729, 2465, 2821, 6601, 8911] and pw(pw(65, 17, 3233), d_lam, 3233) == 65 and d_lam == 413
print("ALL CHECKS PASS")
