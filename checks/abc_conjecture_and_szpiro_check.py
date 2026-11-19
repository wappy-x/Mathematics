# The abc conjecture: radicals of a + b = c, and what abc would decide.  Standard library only.
# abc is open, so every count here is evidence.  Roads: radical by sieve against trial division;
# hit count by a pruned search against brute force; Frey discriminant two ways.
from math import gcd, log
from fractions import Fraction as F

def primes_of(n):                           # trial division: the set of primes dividing n
    out, p = set(), 2
    while p * p <= n:
        while n % p == 0:
            out.add(p); n //= p
        p += 1
    if n > 1: out.add(n)
    return out

def rad_trial(n):
    r = 1
    for p in primes_of(n): r *= p
    return r

def rad_sieve(N):                           # rad[m] = product of the primes dividing m
    rad = [1] * (N + 1)
    for p in range(2, N + 1):
        if rad[p] == 1:                     # untouched so far: p is prime
            for m in range(p, N + 1, p): rad[m] *= p
    return rad

def qual(a, b, c): return log(c) / log(rad_trial(a * b * c))

print("example: 1 + 8 = 9")
print("rad(1*8*9) =", rad_trial(72), " c =", 9, " quality =", f"{qual(1, 8, 9):.4f}")
print("typical: 2 + 3 = 5   rad =", rad_trial(30), " quality =", f"{qual(2, 3, 5):.4f}")
assert rad_trial(72) == 6 and rad_trial(2 * 3 * 5) == 30   # trial division against the factorisations

print("\nfamily 1 + (3^(2^k) - 1) = 3^(2^k): c/rad grows without bound")
fam = []
for k in range(1, 6):
    c = 3 ** (2 ** k); b = c - 1
    ps = {3}
    for j in range(k):                      # b = 2 * (3+1)(3^2+1)...(3^(2^(k-1))+1)
        ps |= primes_of(3 ** (2 ** j) + 1)
    r = 1
    for p in ps: r *= p
    if k <= 4: assert r == rad_trial(b * c)  # second road for the radical
    assert b % 2 ** (k + 2) == 0 and 3 * c > 2 ** (k + 1) * r   # exact: c/rad > 2^(k+1)/3
    fam.append(c / r)
    print(f"k={k}  c={c:>20,}  rad={r:>14,}  c/rad={c / r:12.4f}  lower bound={2 ** (k + 1) / 3:.4f}"
          f"  quality={log(c) / log(r):.4f}")

N = 10 ** 5
rad = rad_sieve(N)
assert all(rad[m] == rad_trial(m) for m in range(1, 3001))
order = sorted(range(1, N + 1), key=lambda a: rad[a])
hits = []
for c in range(3, N + 1):                   # coprime a < b, a + b = c, rad(abc) < c
    bound = c // rad[c]
    for a in order:
        if rad[a] > bound: break
        b = c - a
        if a < b and gcd(a, b) == 1 and rad[a] * rad[b] * rad[c] < c: hits.append((a, b, c))
brute = sum(1 for c in range(3, 1000) for a in range(1, (c + 1) // 2)
            if gcd(a, c) == 1 and rad_trial(a * (c - a) * c) < c)
assert brute == sum(1 for h in hits if h[2] < 1000) == 31
print("\nhits: coprime a < b with a + b = c, c below the bound, and rad(abc) < c")
phi = list(range(N + 1))                    # Euler's phi by sieve: coprime a < c/2 number phi(c)/2
for p in range(2, N + 1):
    if phi[p] == p:
        for m in range(p, N + 1, p): phi[m] -= phi[m] // p
for M in (100, 1000, 10 ** 4, 10 ** 5):
    h, total = sum(1 for t in hits if t[2] < M), sum(phi[c] // 2 for c in range(3, M))
    print(f"c < {M:>7,}  hits={h:>4}  all triples={total:>13,}  share={h / total:.2e}")
    assert M > 1000 or total == sum(1 for c in range(3, M) for a in range(1, (c + 1) // 2) if gcd(a, c) == 1)
print("brute force below 1,000 agrees: 31")
top = sorted(hits, key=lambda t: -qual(*t))
print("highest quality, c <= 100,000:")
for t in top[:6]: print(f"  {t[0]} + {t[1]} = {t[2]}   rad={rad_trial(t[0] * t[1] * t[2]):,}   quality={qual(*t):.4f}")
print("triples with quality > 1.4:", sum(1 for t in hits if qual(*t) > 1.4))
assert max(qual(*t) for t in hits) < 2      # c < rad^2 holds throughout the search
a, b, c = 2, 3 ** 10 * 109, 23 ** 5; assert a + b == c
print(f"record: 2 + 3^10*109 = 23^5 = {c:,}   rad={rad_trial(a * b * c):,}   quality={qual(a, b, c):.4f}")

print("\nexponent room: rad(x^n y^n z^n) = rad(xyz) < z^3, so c < rad^2 forces n < 6")
s1 = max(F(3, n) for n in range(4, 40))
print(f"largest 3/n, n >= 4 (Fermat) = {s1}, abc bites for eps < {1 / s1 - 1}")
s2 = max(F(1, m) + F(1, n) for m in range(2, 40) for n in range(m, 40) if (m, n) != (2, 2))
s3 = max(t for l in range(2, 40) for m in range(l, 40) for n in range(m, 40)
         if (t := F(1, l) + F(1, m) + F(1, n)) < 1)
print(f"largest 1/m + 1/n (Catalan) = {s2}, abc bites for eps < {1 / s2 - 1}")
print(f"largest 1/l + 1/m + 1/n below 1 = {s3}, abc bites for eps < {1 / s3 - 1}")
assert s1 == F(3, 4) and s2 == F(5, 6) and s3 == F(41, 42)
print("\nwhat breaks")
print("product instead of radical: 1*8*9 =", 1 * 8 * 9, "(always above c)")
print(f"no epsilon, fixed K: family c/rad at k=5 is {fam[-1]:.4f}")
print(f"common factor: 512 + 512 = 1024, rad = {rad_trial(512 * 512 * 1024)}, "
      f"quality = {log(1024) / log(2):.4f}")

L = 10 ** 6                                 # perfect powers up to L, highest exponent kept
pw = {}
for e in range(2, L.bit_length()):          # 2^e <= L needs e below L's bit length
    x = 2
    while x ** e <= L:
        pw[x ** e] = (x, e); x += 1
pw[1] = (1, 10 ** 9)                        # 1 = 1^e for every e
vals = sorted(pw)
print(f"\nconsecutive perfect powers up to {L:,}:",
      [(u, v) for u, v in zip(vals[1:], vals[2:]) if v - u == 1])
fc, beal, beal_nc = [], 0, []
for i, u in enumerate(vals):
    for v in vals[i:]:
        w = u + v
        if w > L: break
        if w in pw and gcd(u, v) == 1:
            el, em, en = pw[u][1], pw[v][1], pw[w][1]
            if 1 / el + 1 / em + 1 / en < 1: fc.append((pw[u], pw[v], pw[w]))
            if min(el, em, en) >= 3: beal += 1
        elif w in pw and min(pw[u][1], pw[v][1], pw[w][1]) >= 3 and u > 1: beal_nc.append((u, v, w))
print(f"Fermat-Catalan solutions, coprime, 1/l + 1/m + 1/n < 1, up to {L:,}:")
for s in fc: print("  " + " + ".join(f"{x}^{e if x > 1 else 'any'}" for x, e in s[:2]) + f" = {s[2][0]}^{s[2][1]}")
print("coprime with all exponents >= 3 (Beal):", beal)
print("not coprime, all exponents >= 3:", len(beal_nc), " first:", beal_nc[0], " also 27 + 216 = 243:",
      (27, 216, 243) in beal_nc)
assert len(fc) == 5 and beal == 0 and (27, 216, 243) in beal_nc

print("\nFrey curves")
def invariants(a1, a2, a4):                 # y^2 + a1 xy = x^3 + a2 x^2 + a4 x
    b2, b4, b8 = a1 * a1 + 4 * a2, 2 * a4, -a4 * a4
    return -b2 * b2 * b8 - 8 * b4 ** 3, b2 * b2 - 24 * b4      # discriminant, c4
d, c4 = invariants(0, 7, -8)                # y^2 = x(x - 1)(x + 8), from 1 + 8 = 9
print("1 + 8 = 9: y^2 = x(x-1)(x+8)  disc =", f"{d:,}", " 16(abc)^2 =", f"{16 * 72 ** 2:,}",
      " c4 =", f"{c4:,}", " gcd(c4, disc) =", gcd(c4, d))
assert d == 16 * 72 ** 2 and c4 == 16 * (1 + 8 + 64)  # Tate's c4 against 16(A^2 + AB + B^2)
for c in (81, 6561):                        # 1 + (c-1) = c with A = -c, B = c - 1, 16 | B
    A, B = -c, c - 1                        # y^2 = x(x - A)(x + B), rescaled to a minimal model
    d, c4 = invariants(1, (B - A - 1) // 4, -A * B // 16)
    n_e = rad_trial(d)                      # semistable, so N = rad(disc): 2 drops out unless 32 | B
    assert d == (A * B) ** 2 // 2 ** 8 and gcd(c4, d) == 1 and n_e == rad_trial(B * c) // (2 if B % 32 else 1)
    print(f"1 + {B} = {c}: first disc 16(abc)^2 = {16 * (B * c) ** 2:,}, minimal disc = {d:,} = (abc)^2/2^8"
          f"\n   c4 = {c4:,}   gcd(c4, disc) = 1   conductor = {n_e:,}"
          f"   rad(abc) = {rad_trial(B * c):,}   log disc/log N = {log(d) / log(n_e):.4f}")
print("ALL CHECKS PASS")
