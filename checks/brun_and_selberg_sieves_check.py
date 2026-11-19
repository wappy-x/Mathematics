# Brun's sieve and Selberg's -- the check behind the card.  Standard library only;
# math supplies exp, log, ceil and prod.  Twin primes p, p + 2 with p up to a million are
# counted twice, then bounded three ways: Legendre (keep every layer), Brun (stop
# after an even number of layers) and Selberg (squared, optimised weights).
import math
X, M = 10**6, 200001
def c(n): return f"{n:,}"
def gcd(a, b):
    while b: a, b = b, a % b
    return a
spf = list(range(M))                         # smallest prime factor of each n < M
for i in range(2, 448):
    if spf[i] == i:
        for j in range(i * i, M, i):
            if spf[j] == j: spf[j] = i
primes = [p for p in range(2, M) if spf[p] == p]
isp = bytearray([0, 0, 1]) + bytearray([1, 0]) * ((X + 1) // 2)   # odd n marked prime
for p in primes[1:168]: isp[p * p::2 * p] = bytes(len(range(p * p, len(isp), 2 * p)))
twins = [p for p in range(2, X + 1) if isp[p] and isp[p + 2]]
def rho(p, r2=1): return r2 if p == 2 else 2      # classes n mod p with p | n(n + 2)
def sifted(z):                               # S(10^6, z): strike n = 0 and n = -2 mod p
    alive = bytearray([0]) + bytearray([1]) * X
    for p in [q for q in primes if q < z]:
        for s in sorted({p, p - 2} - {0}): alive[s::p] = bytes(len(range(s, X + 1, p)))
    return sum(alive)
def esym(vals, m):                           # layer totals e_0 .. e_m
    e = [1.0] + [0.0] * m
    for v in vals:
        for j in range(m, 0, -1): e[j] += e[j - 1] * v
    return e
def brun(x, z, m, r2=1):                     # stop after m layers: main part, error allowance
    P = [p for p in primes if p < z]
    g, r = esym([rho(p, r2) / p for p in P], m), esym([float(rho(p, r2)) for p in P], m)
    return [x * sum((-1) ** j * g[j] for j in range(k + 1)) for k in range(m + 1)], [sum(r[:k + 1]) for k in range(m + 1)], len(P)
def weights(z):                              # h, rho, g, mu for squarefree d < z; then Selberg's lambda_d
    h, r, g, mu = [0.0] * z, [0] * z, [0.0] * z, [0] * z
    for d in range(1, z):
        n, ps = d, []
        while n > 1 and ps is not None:
            p = spf[n]; n //= p; ps = None if n % p == 0 else ps + [p]
        if ps is None: continue
        h[d], r[d], g[d], mu[d] = 1.0, 1, 1.0, (-1) ** len(ps)
        for p in ps: h[d], r[d], g[d] = h[d] * rho(p) / (p - rho(p)), r[d] * rho(p), g[d] * rho(p) / p
    G = sum(h)
    lam = [mu[d] * sum(h[e] for e in range(1, (z - 1) // d + 1) if mu[e] and gcd(e, d) == 1) / g[d] * h[d] / G if mu[d] else 0.0 for d in range(z)]
    return G, lam, r, g, mu
def quad(lam, g):                            # x-free main part: sum of lam_a lam_b g([a, b])
    ds = [d for d in range(1, len(lam)) if lam[d]]
    return sum(lam[a] * lam[b] * g[a] * g[b] / g[gcd(a, b)] for a in ds for b in ds)
cache = {z: weights(z) for z in (100, 150, 200, 300, 500, 1000, 2000, 3000, 5000, 10**4, 2 * 10**4, 5 * 10**4, 10**5, 2 * 10**5)}
def selberg(x, z):
    G, lam, r, g, mu = cache[z]
    return x / G + sum(abs(lam[d]) * r[d] for d in range(z)) ** 2 + sum(1 for p in primes if p < z)
road2 = sifted(1001) + sum(1 for p in twins if p < 1001)
print(f"twin pairs with p up to {c(X)}: {c(len(twins))}; by sifting n(n + 2) with primes below 1001: {c(road2)}")
print(f"largest pair {c(twins[-1])}, {c(twins[-1] + 2)}; primes up to 10^6: {c(sum(isp[2:X + 1]))}")
c2 = 1.0
for p in primes[1:]:
    if p < X: c2 *= 1 - 1 / ((p - 1) * (p - 1))
for p in range(primes[-1] + 2, X, 2):
    if isp[p]: c2 *= 1 - 1 / ((p - 1) * (p - 1))
for e in range(1, 7):
    b = sum(1 / p + 1 / (p + 2) for p in twins if p + 2 <= 10**e)
    s = sum(1 / p for p in range(2, 10**e + 1) if isp[p])
    print(f"chart, x = 10^{e}: twin reciprocals {b:.4f}, all prime reciprocals {s:.4f}")
lx = math.log(X)
print(f"C2 = {c2:.6f}; tail estimate 4 C2 / log x = {4 * c2 / lx:.4f}; sum plus tail {b + 4 * c2 / lx:.5f}, Brent 1.90216")
n, a = 20000, math.log(2)                    # Simpson's rule for the integral of dt / (log t)^2, t = e^u
hs = (lx - a) / n
li2 = sum((1 if i in (0, n) else 4 if i % 2 else 2) * math.exp(a + i * hs) / ((a + i * hs) * (a + i * hs)) for i in range(n + 1)) * hs / 3
print(f"Hardy-Littlewood prediction 2 C2 Li2(10^6) = {2 * c2 * li2:.0f} (a conjecture)")
mains, rems, r = brun(X, 23, 8)
gl = esym([rho(p) / p for p in primes[:8]], 8)
true23 = sifted(23)
print(f"S(10^6, 23) counted directly: {c(true23)}; sifting primes below 23: {r}")
n3 = sum(1 for n in range(1, X + 1) if n * (n + 2) % 3 == 0)
print(f"n up to 10^6 with 3 | n(n + 2): {c(n3)}; x g(3) = {X * 2 / 3:.1f}")
for j in range(9):
    print(f"layer {j}: e_j(g) = {gl[j]:.6f}, kept to here {mains[j]:.1f} + {rems[j]:.0f}")
for m in (2, 4, 6, 8):
    print(f"Brun, z = 23, {m} layers: bound {c(math.ceil(mains[m] + rems[m] + r))}")
res = {}
for x in (10**6, 10**9, 10**12):
    bb = min((math.ceil(mn + rm + k), z, m) for z in primes[:168] for mm, rr, k in [brun(x, z, 20)] for m, (mn, rm) in enumerate(zip(mm, rr)) if m % 2 == 0)
    lb = min((math.ceil(brun(x, z, 99)[0][-1] + brun(x, z, 99)[1][-1] + i), z) for i, z in enumerate(primes[:60]))
    sb = min((math.ceil(selberg(x, z)), z) for z in cache)
    u = x / (math.log(x) * math.log(x))
    res[x] = (lb[0], bb[0], sb[0])
    print(f"x = 10^{len(str(x)) - 1}: Legendre {c(lb[0])} (z = {lb[1]}), Brun {c(bb[0])} (z = {bb[1]}, {bb[2]} layers), Selberg {c(sb[0])} (z = {sb[1]})")
    print(f"  bound / (x / (log x)^2): {lb[0] / u:.2f}, {bb[0] / u:.2f}, {sb[0] / u:.2f}")
print(f"the same ratio for the true count at 10^6: {8169 * lx * lx / X:.2f}; Hardy-Littlewood 2 C2 = {2 * c2:.2f}; Selberg's limit 16 C2 = {16 * c2:.2f}")
G, lam, rr, g, mu = cache[200]
Q = quad(lam, g)
print(f"Selberg, z = 200: G = {G:.6f}; 1/G = {1 / G:.9f}; double sum of lam lam g = {Q:.9f}")
sr = sum(abs(lam[d]) * rr[d] for d in range(200))
print(f"Selberg at 10^6, z = 200: x/G = {X / G:.1f}, remainder {sr * sr:.1f}, plus 46 primes, total {X / G + sr * sr + 46:.2f}")
print(f"lambda_1 = {lam[1]:.4f}, lambda_2 = {lam[2]:.4f}, lambda_3 = {lam[3]:.4f}, lambda_6 = {lam[6]:.4f}, largest |lambda| = {max(abs(v) for v in lam):.4f}")
mu200 = [float(v) for v in mu]
wrong = [brun(X, 23, 99, 2), brun(X, 101, 99), brun(X, 23, 1)]
print(f"mistake 1, rho(2) = 2: bound {wrong[0][0][-1] + wrong[0][1][-1] + 8:.0f}, below the true {c(len(twins))}")
print(f"mistake 2, every layer at z = 101: bound {c(math.ceil(wrong[1][0][-1] + wrong[1][1][-1] + wrong[1][2]))}")
print(f"mistake 3, one layer read as a ceiling: {wrong[2][0][1] - wrong[2][1][1]:.0f}")
print(f"mistake 4, plain Mobius weights at z = 200: bound {c(math.ceil(X * quad(mu200, g) + sum(rr) ** 2 + 46))}")
assert len(twins) == road2 == 8169                                  # two counts agree
assert all(true23 <= math.ceil(mains[m] + rems[m]) for m in (2, 4, 6, 8)) and len(twins) <= true23 + r
assert abs(brun(X, 23, 99)[0][-1] - X * math.prod(1 - rho(p) / p for p in primes[:8])) < 1e-6   # expansion = product
assert abs(n3 - X * rho(3) / 3) <= rho(3)                            # one prime's count against x g(3)
assert abs(true23 - X * math.prod(1 - rho(p) / p for p in primes[:8])) <= 2 * 3 ** 7   # Legendre, both sides
assert abs(Q - 1 / G) < 1e-12 and abs(lam[1] - 1) < 1e-12           # quadratic form at its minimum
assert abs(b + 4 * c2 / lx - 1.9021604) < 0.001                     # against Brent's estimate
assert res[10**6][2] > res[10**6][1] and res[10**12][2] < res[10**12][1]
print("ALL CHECKS PASS")
