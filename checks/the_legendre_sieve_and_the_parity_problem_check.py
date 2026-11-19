# Legendre's sieve and the parity problem -- the check behind the card.
# Standard library only.  Road one crosses out multiples and counts what is left.
# Road two is Legendre's signed sum of floor(x/d) over squarefree d.  Road three
# is the main term x * prod(1 - 1/p), set against the 2^k ceiling on the error.
import math
X = 10**6
spf = list(range(X + 1))                          # smallest prime factor of each n
for i in range(2, 1001):
    if spf[i] == i:
        for j in range(i * i, X + 1, i):
            if spf[j] == j:
                spf[j] = i
primes = [p for p in range(2, X + 1) if spf[p] == p]
lam = [0, 1] + [0] * (X - 1)                      # Liouville's lambda from spf
for n in range(2, X + 1):
    lam[n] = -lam[n // spf[n]]
Lsum = [0] * (X + 1)                              # running total L(n) of lambda
for n in range(1, X + 1):
    Lsum[n] = Lsum[n - 1] + lam[n]
def big(k):                                       # 2^k, written for the reader
    if k <= 30:
        return f"{2**k:,}"
    e = int(k * math.log10(2))
    return f"{2**k / 10**e:.2f} x 10^{e}"
def legendre(x, ps):                              # walk squarefree d <= x built from ps
    out = {"layers": [0] * (len(ps) + 1), "terms": 0, "near": 0.0, "frac": 0.0}
    def go(i, d, k):
        s = 1 if k % 2 == 0 else -1
        out["layers"][k] += x // d; out["terms"] += 1
        out["near"] += s * x / d; out["frac"] += (x % d) / d
        for j in range(i, len(ps)):
            if d * ps[j] > x:
                break
            go(j + 1, d * ps[j], k + 1)
    go(0, 1, 0)
    out["sum"] = sum((-1)**k * v for k, v in enumerate(out["layers"]))
    return out
def count(x, ps):                                 # road one: test every n <= x
    return sum(1 for n in range(1, x + 1) if all(n % p for p in ps))
def mainterm(x, ps):
    return x * math.prod(1 - 1/p for p in ps)
small = [2, 3, 5, 7]
r = legendre(100, small)
pi = lambda y: sum(1 for p in primes if p <= y)
print(f"x = 100, primes 2, 3, 5, 7: layers {r['layers'][:4]} -> Legendre {r['sum']};"
      f" counted {count(100, small)}; pi(100) - pi(10) + 1 = {pi(100)} - {pi(10)} + 1")
print(f"x = 100: {2**4} terms, {r['terms']} with d <= 100; main term {mainterm(100, small):.3f};"
      f" error {r['sum'] - mainterm(100, small):+.3f}")
divs = sorted((bin(m).count("1"), math.prod(q for b, q in enumerate(small) if m >> b & 1)) for m in range(16))
print("x = 100, each d: floor(100/d):", " ".join(f"{d}:{100 // d}" for k, d in divs))
idsum = sum((-1)**k * (210 // d) for k, d in divs)
print(f"sum of mu(d) * 210/d over d | 210 = {idsum}; prod (p - 1) = {math.prod(p - 1 for p in small)}")
print(f"x = 100, primes 2, 3, 5 only: counted {count(100, small[:3])}; main term {mainterm(100, small[:3]):.3f}")
print("x = 10^6: z | k | 2^k | terms d <= x | Legendre | counted | main term | error | error/main")
alive = bytearray([1]) * (X + 1); alive[0] = 0
rows = {}
for z in (7, 30, 100, 1000):                      # road one, prime by prime
    ps = [p for p in primes if p <= z]
    for p in ps:
        alive[p::p] = bytearray(len(range(p, X + 1, p)))
    r, m, c = legendre(X, ps), mainterm(X, ps), sum(alive)
    rows[z] = (len(ps), r, m, c)
    print(f"{z:>4} | {len(ps):>3} | {big(len(ps))} | {r['terms']:,} | {r['sum']:,} | {c:,} | {m:,.1f}"
          f" | {c - m:+,.1f} | {100 * (c - m) / m:+.4f}%")
k, r, m, c = rows[1000]
print(f"z = 1000 split: near part (d <= x) {r['near']:,.1f}; tail (d > x) {m - r['near']:+,.1f};"
      f" rounding {r['sum'] - r['near']:+,.1f}; rounding terms in size {r['frac']:,.1f}")
pix = len(primes)
print(f"pi(10^6) = {pix:,}; survivors at z = 1000 are 1 and the primes above 1000: {1 + pix - 168:,};"
      f" main / counted = {m / c:.4f}; 2e^-gamma = {2 * math.exp(-0.5772156649015329):.4f}")
cross = next(p for p in primes if 2.0**pi(p) > mainterm(X, [q for q in primes if q <= p]))
print(f"x = 10^6: 2^k first passes the main term at z = {cross} (k = {pi(cross)})")
print("Legendre's best bound on pi(x): x | best z | bound | x / log x | ratio")
best = {}
for e in (6, 9, 12, 15):
    x = 10**e
    b = min((pi(z) - 1 + mainterm(x, primes[:pi(z)]) + 2.0**pi(z), z) for z in primes[:60])
    best[e] = b[0]
    print(f"10^{e} | {b[1]} | {b[0]:,.0f} | {x / math.log(x):,.0f} | {b[0] * math.log(x) / x:.3f}")
chart = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
print("chart, log10 main term:", ", ".join(f"{math.log10(mainterm(X, primes[:pi(zz)])):.2f}" for zz in chart))
print("chart, log10 2^k:", ", ".join(f"{pi(zz) * math.log10(2):.2f}" for zz in chart))
plus = sum(1 for n in range(1, X + 1) if lam[n] == 1)
print(f"lambda = +1 below 10^6: {plus:,}; lambda = -1: {X - plus:,}; L(10^6) = {Lsum[X]}")
om = bytearray(X + 1)                             # Omega(n) a second way: +1 per prime power dividing n
for p in primes:
    q = p
    while q <= X:
        for j in range(q, X + 1, q): om[j] += 1
        q *= p
print("d | A+_d counted | A+_d by formula | A-_d | x/(2d)")
for d in (2, 3, 6, 210):
    direct = sum(1 for n in range(d, X + 1, d) if lam[n] == 1)
    formula = (X // d + lam[d] * Lsum[X // d]) // 2
    print(f"{d} | {direct:,} | {formula:,} | {X // d - direct:,} | {X / (2 * d):,.1f}")
    assert direct == formula                       # parity counts, two roads
worst = max((abs((X // d + lam[d] * Lsum[X // d]) / 2 - X / (2 * d)), d)
            for d in range(1, 1001) if all(d % (p * p) for p in primes[:11]))
print(f"largest |A+_d - x/(2d)| over squarefree d <= 1000: {worst[0]:.1f}, at d = {worst[1]}")
sp = sum(1 for n in range(1, X + 1) if alive[n] and lam[n] == 1)
sm = sum(1 for n in range(1, X + 1) if alive[n] and lam[n] == -1)
print(f"survivors at z = 1000: lambda = +1 {sp:,}; lambda = -1 {sm:,}; main term for each {m / 2:,.1f}")
twins = sum(1 for p in primes if p + 2 <= X and spf[p + 2] == p + 2)
tw = sum(1 for n in range(1, X - 1) if alive[n] and alive[n + 2])
tmain = X * 0.5 * math.prod(1 - 2/p for p in primes[1:168])
print(f"twin pairs below 10^6: {twins:,}; pairs above 1000 by the sieve {tw:,};"
      f" main term {tmain:,.1f}; ratio {tmain / tw:.4f}")
for z in (7, 30, 100, 1000):
    k, r, m, c = rows[z]
    assert r["sum"] == c and abs(c - m) <= 2**k     # Legendre = count; error under 2^k
assert count(100, small) == 22 == pi(100) - pi(10) + 1 and idsum == 48
assert pix == 78498 and c == 1 + pix - 168          # pi(10^6), known table
assert sp == 1 and sm == pix - 168 and sum(1 - 2 * (om[n] & 1) for n in range(1, X + 1)) == Lsum[X]   # L(10^6) two ways
assert twins == 8169 and tw == twins - sum(1 for p in primes if p + 2 <= 1000 and spf[p + 2] == p + 2)
assert best[6] >= pix and all(best[e] * math.log(10**e) / 10**e > 1.5 for e in best)
print("ALL CHECKS PASS")
