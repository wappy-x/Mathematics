# The abc conjecture, status card: the quality of a triple, the record 2 + 3^10*109 = 23^5,
# and what the epsilon and the constant mean.  Standard library only.  abc is open, so every
# count is evidence.  Roads: radical by sieve against trial division; hits by a pruned search
# against brute force; the record's quality by logarithms against exact integer powers.
from math import gcd, log

def rad_trial(n):                            # product of the distinct primes dividing n
    r, p = 1, 2
    while p * p <= n:
        if n % p == 0:
            r *= p
            while n % p == 0: n //= p
        p += 1
    return r * n if n > 1 else r

def rad_sieve(N):
    rad = [1] * (N + 1)
    for p in range(2, N + 1):
        if rad[p] == 1:                      # untouched so far: p is prime
            for m in range(p, N + 1, p): rad[m] *= p
    return rad

def q(a, b, c): return log(c) / log(rad_trial(a * b * c))

# ---- the record triple ----
a, b, c = 2, 3 ** 10 * 109, 23 ** 5
r = rad_trial(a * b * c)
print(f"record: 2 + 3^10*109 = 23^5:  {a} + {b:,} = {c:,}")
print(f"rad = 2*3*109*23 = {r:,}   log c = {log(c):.4f}   log rad = {log(r):.4f}   quality = {q(a, b, c):.4f}")
assert a + b == c and gcd(a, b) == 1 and r == 2 * 3 * 109 * 23   # trial division against the factorisation
assert r ** 16299 < c ** 10000 < r ** 16300  # exact: quality lies between 1.6299 and 1.6300
assert 1.6299 < q(a, b, c) < 1.6300           # the logarithm road lands inside the exact bracket
print("exact powers: rad^16299 < c^10000 < rad^16300, so 1.6299 < quality < 1.6300")
print(f"c / rad = {c / r:.4f}")
print(f"small example: 1 + 8 = 9  rad = {rad_trial(72)}  quality = {q(1, 8, 9):.4f}")

# ---- every hit with c below 100,000, by a pruned search ----
N = 100_000
rad = rad_sieve(N)
assert all(rad[m] == rad_trial(m) for m in range(1, 3001))
order = sorted(range(1, N + 1), key=lambda x: rad[x])
hits = []
for cc in range(3, N):
    bound = cc // rad[cc]                    # rad(a) * rad(b) must stay below c / rad(c)
    for aa in order:
        if rad[aa] > bound: break
        bb = cc - aa
        if aa < bb and gcd(aa, bb) == 1 and rad[aa] * rad[bb] * rad[cc] < cc:
            hits.append((aa, bb, cc))
brute = [(x, y - x, y) for y in range(3, 2000) for x in range(1, (y + 1) // 2)
         if gcd(x, y) == 1 and rad_trial(x * (y - x) * y) < y]
assert sorted(brute) == sorted(h for h in hits if h[2] < 2000)   # two roads, same list
print(f"\nhits (rad(abc) < c) with c below 2,000: pruned {sum(1 for h in hits if h[2] < 2000)}, brute force {len(brute)}")
quals = sorted(((log(z) / log(rad[x] * rad[y] * rad[z]), x, y, z) for x, y, z in hits), reverse=True)
print("quality ladder, c below 100,000 (the record lies beyond); one # per 7 hits, rounded up:")
for t in (1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6):
    n = sum(1 for v in quals if v[0] > t)
    print(f"  quality > {t:.1f}  {'#' * ((n + 6) // 7):<60}  {n:>3}")
print("top three, c below 100,000:")
for v, x, y, z in quals[:3]:
    print(f"  {x:,} + {y:,} = {z:,}   rad = {rad[x] * rad[y] * rad[z]:,}   quality = {v:.4f}")
assert quals[0][1:] == (1, 4374, 4375) and len(quals) == 418

# ---- what the constant K must be, for each epsilon, on what is known ----
print("\nsmallest K with c < K rad^(1+eps) on the hits below 100,000 plus the record")
pool = [(x, y, z, rad[x] * rad[y] * rad[z]) for x, y, z in hits] + [(a, b, c, r)]
for eps in (0.0, 0.2, 0.4, 0.6, 0.7):
    k, x, y, z = max((z / rr ** (1 + eps), x, y, z) for x, y, z, rr in pool)
    print(f"  eps = {eps:.1f}:  K at least {k:10.4f}   set by {x:,} + {y:,} = {z:,}")
    if eps == 0.7: assert k < 1                # no triple here reaches quality 1.7
    else: assert k > 1

# ---- what abc would buy: a Fermat solution x^n + y^n = z^n has quality above n/3 ----
print("\nFermat: rad(x^n y^n z^n) <= xyz < z^3, so quality > log z^n / log z^3 = n/3")
for n in (4, 5, 6):
    print(f"  n = {n}: quality above {n / 3:.4f}   beats the record: {n / 3 > q(a, b, c)}")

# ---- proved against conjectured, on the record (logarithms of c) ----
lr = log(r)
print("\nsize of log c on the record:")
print(f"  actual log c                         {log(c):12.4f}")
print(f"  abc, eps = 0.7: (1 + eps) log rad    {1.7 * lr:12.4f}   plus log K")
print(f"  proved shape rad^(1/3) (log rad)^3   {r ** (1 / 3) * lr ** 3:12.4f}   times an unstated K")

# ---- what breaks ----
print("\nwhat breaks")
print(f"no constant, eps = 0.2: 6^1.2 = {6 ** 1.2:.4f} < 9, so c < rad^1.2 fails at 1 + 8 = 9")
assert 6 ** 6 < 9 ** 5                         # exact: 6^1.2 < 9
fam = [(3 ** 2 ** k, rad_trial(3 ** 2 ** k - 1) * 3) for k in range(1, 6)]
print("eps = 0, family 1 + (3^(2^k) - 1) = 3^(2^k):  c/rad =", ", ".join(f"{z / w:.4f}" for z, w in fam))
assert all(z1 * w2 < z2 * w1 for (z1, w1), (z2, w2) in zip(fam, fam[1:]))  # exact: c/rad grows
print(f"product, not radical: log c / log(abc) = {log(c) / log(a * b * c):.4f}")
print(f"common factor: 512 + 512 = 1024  quality = {log(1024) / log(rad_trial(512 * 512 * 1024)):.4f}")
assert rad_trial(512 * 512 * 1024) == 2

print("\ntry changing")
print(f"hits with c below 10,000: {sum(1 for h in hits if h[2] < 10_000)}")
print(f"eps = 0.65: K at least {c / r ** 1.65:.4f}")
print(f"3 + 125 = 128: quality = {q(3, 125, 128):.4f}")
print(f"Fermat n = 7: quality above {7 / 3:.4f}")
print("ALL CHECKS PASS")
