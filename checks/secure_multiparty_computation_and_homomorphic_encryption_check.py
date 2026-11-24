# Computing on secrets -- the check behind the card.  Standard library only.
# Additive shares mod 2^32, one Beaver-triple multiplication, toy Paillier (n = 77)
# and a toy integer FHE.  TOY SIZES, INSECURE: real Paillier uses n of 3072 bits
# (ISO/IEC 18033-6); real FHE uses lattice (LWE) schemes with far larger keys.
from math import gcd, log2
M, M64 = 1 << 32, (1 << 64) - 1
class SplitMix64:                         # seeded generator, same in Rust
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
def power(b, e, m):                       # square-and-multiply, written out
    out, b = 1, b % m
    while e:
        out = out * b % m if e & 1 else out
        b, e = b * b % m, e >> 1
    return out
def inverse(a, m):                        # extended Euclid: a * inverse = 1 mod m
    r0, r1, t0, t1 = m, a % m, 0, 1
    while r1:
        k = r0 // r1
        r0, r1, t0, t1 = r1, r0 - k * r1, t1, t0 - k * t1
    return t0 % m
rng = SplitMix64(2026)
def share(x, m=M):                        # three random shares that add up to x mod m
    s1, s2 = rng.next() % m, rng.next() % m
    return [s1, s2, (x - s1 - s2) % m]
def pounds(p): return f"£{p // 100:,}.{p % 100:02d}"
def yn(t): return "yes" if t else "no"

# ---- 1. the sum: three branches, takings in pence, shares mod 2^32 ----
names, takings = ["Leeds", "York", "Hull"], [184250, 231675, 150920]
sh = [share(t) for t in takings]          # sh[i][j]: share of branch i's takings, held by j
for i in range(3): print(f"{names[i]} takes {pounds(takings[i])} = {takings[i]} p; shares {sh[i]}")
held = [sum(sh[i][j] for i in range(3)) % M for j in range(3)]
total = sum(held) % M
print(f"each branch adds what it holds: {held}")
print(f"published sums added mod 2^32 = {total} p = {pounds(total)}; direct sum {sum(takings)}; "
      f"Leeds infers York + Hull = {total - takings[0]} p; ceiling 2^32 p = {pounds(M)}")
pairs = [(t, i, j, v[i], v[j]) for t in range(8) for s1 in range(8) for s2 in range(8)
         for v in [[s1, s2, (t - s1 - s2) % 8]] for i, j in [(0, 1), (0, 2), (1, 2)]]
uniform = len(pairs) == len(set(pairs)) == 8 * 3 * 64   # privacy, modulus 8, every coin
print(f"privacy, modulus 8: any two of three shares take all 64 value pairs once each, for all 8 inputs: {yn(uniform)}")
w1, w2 = rng.next() % 10000, rng.next() % 10000          # break 1: narrow shares, no wrap
leak = takings[0] - w1 - w2
print(f"break 1, shares 0..9,999 p with no wrap: Hull holds {leak} p, so Leeds took {pounds(leak)} to {pounds(leak + 19998)}")
# ---- 2. one product with a Beaver triple ----
x, y = 120, 1840                          # sacks of flour (Hull), pence per sack (York)
a0, b0, c0, d0, e0 = 100, 1000, 100 * 1000, x - 100, y - 1000   # a small triple, by hand
hand = c0 + d0 * b0 + e0 * a0 + d0 * e0
print(f"by hand: a = {a0}, b = {b0}, c = {c0}; d = {d0}, e = {e0}; c + d b + e a + d e = "
      f"{c0} + {d0 * b0} + {e0 * a0} + {d0 * e0} = {hand}")
a, b = rng.next() % M, rng.next() % M
c = a * b % M
xs, ys, as_, bs, cs = share(x), share(y), share(a), share(b), share(c)
d = sum(xs[i] - as_[i] for i in range(3)) % M            # opened in public
e = sum(ys[i] - bs[i] for i in range(3)) % M
z = [(cs[i] + d * bs[i] + e * as_[i] + (d * e if i == 0 else 0)) % M for i in range(3)]
prod_xy = sum(z) % M
print(f"triple: a = {a}, b = {b}, c = ab mod 2^32 = {c}")
print(f"opened: d = x - a = {d}, e = y - b = {e} (mod 2^32)")
print(f"product shares {z}; sum mod 2^32 = {prod_xy} p = {pounds(prod_xy)}; direct {x} * {y} = {x * y}")
ident = all((aa * bb + dd * bb + ee * aa + dd * ee) % 16 == (xx * yy) % 16
            for xx in range(16) for yy in range(16) for aa in range(16) for bb in range(16)
            for dd in [(xx - aa) % 16] for ee in [(yy - bb) % 16])
dun = all(len({(xx - aa) % 16 for aa in range(16)}) == 16 for xx in range(16))
print(f"identity mod 16, all 65536 (x, y, a, b): {yn(ident)}; d takes all 16 values for every x: {yn(dun)}")
x2, d2 = 95, (95 - a) % M                 # break 2: the same triple reused
print(f"break 2, triple reused for x' = {x2}: d - d' = {(d - d2) % M} = x - x', leaked")
# ---- 3. toy Paillier, n = 7 * 11 = 77 ----
p, q = 7, 11
n, n2, g, lam = p * q, (p * q) ** 2, p * q + 1, (p - 1) * (q - 1) // gcd(p - 1, q - 1)
L = lambda u: (u - 1) // n
mu = inverse(L(power(g, lam, n2)), n)
enc = lambda m, r: power(g, m, n2) * power(r, n, n2) % n2
dec = lambda ct: L(power(ct, lam, n2)) * mu % n
print(f"Paillier: n = {n}, n^2 = {n2}, g = {g}, lambda = {lam}, mu = {mu}; real n 3072 bits (about 2^128 work), ciphertexts {2 * 3072} bits")
ms, rs = [18, 23, 15], [5, 13, 20]        # takings in hundreds of pounds, rounded
cts = [enc(m, r) for m, r in zip(ms, rs)]
for i in range(3):
    print(f"  {names[i]}: m = {ms[i]}, r = {rs[i]}: g^m = {power(g, ms[i], n2)}, "
          f"r^n = {power(rs[i], n, n2)}, Enc = {cts[i]}, decrypts to {dec(cts[i])}")
prod = cts[0] * cts[1] % n2 * cts[2] % n2
print(f"product of ciphertexts mod n^2 = {prod}; to the lambda mod n^2 = {power(prod, lam, n2)}, "
      f"L = {L(power(prod, lam, n2))}, times mu mod n = {dec(prod)}; sum {sum(ms)}")
binom = all(power(g, m, n2) == (1 + m * n) % n2 for m in range(n))
table = {enc(m, r): m for m in range(n) for r in range(1, n) if gcd(r, n) == 1}
units = sum(1 for u in range(1, n2) if gcd(u, n2) == 1)
look = all(dec(ct) == m for ct, m in table.items())
hom = all(dec(enc(m1, 5) * enc(m2, 13) % n2) == (m1 + m2) % n for m1 in range(n) for m2 in range(n))
same = len({enc(18, r) for r in range(1, n) if gcd(r, n) == 1})
print(f"(1 + n)^m = 1 + mn mod n^2 for all 77 m: {yn(binom)}; {len(table)} (m, r) pairs give "
      f"{len(table)} distinct ciphertexts = {units} units mod n^2")
print(f"lookup agrees with decryption: {yn(look)}; Dec(Enc(m1) Enc(m2)) = m1 + m2 mod n for "
      f"all 5929 pairs: {yn(hom)}; 18 encrypts {same} ways")
c1 = enc(18, 1)                           # break 3: r = 1, no randomness
print(f"break 3, r = 1: Enc(18) = {c1}; anyone computes ({c1} - 1)/{n} = {(c1 - 1) // n}")
week = power(prod, 7, n2)                 # break 4: past n the sum wraps
print(f"break 4, a week, Enc(56)^7: decrypts to {dec(week)}, not {7 * sum(ms)}")
f = next(k for k in range(2, n) if n % k == 0)
lam2 = (f - 1) * (n // f - 1) // gcd(f - 1, n // f - 1)
crack = (power(prod, lam2, n2) - 1) // n * inverse(lam2, n) % n
print(f"break 5, trial division splits 77 = {f} * {n // f} after {f - 1} tries; total read without the key: {crack}")
# ---- 4. toy FHE over the integers: secret odd K, noise grows ----
K, U0, X = 1000003, 4294967311, 1000003 * 4294967311   # X: public multiple of K
def fenc(bit):
    nu = 2 * (rng.next() % 9 - 4) + bit   # noise: small, with the bit as its parity
    return (K * (rng.next() % U0) + nu) % X, nu
fdec = lambda ct: (ct % K - K if ct % K > K // 2 else ct % K) % 2   # centre, read parity
(e1, v1), (e2, v2) = fenc(1), fenc(0)
print(f"FHE toy: K = {K}, X = K * {U0}; Enc(1) noise {v1}, Enc(0) noise {v2}; "
      f"add -> {fdec((e1 + e2) % X)} (1 XOR 0), multiply -> {fdec(e1 * e2 % X)} (1 AND 0)")
tot, nz, par = 0, 0, 0
for _ in range(1000):
    ct, nu = fenc(1)
    tot, nz, par = (tot + ct) % X, nz + nu, par ^ 1
print(f"1000 additions of Enc(1): noise {nz}, decrypts to {fdec(tot)}, true XOR {par}")
acc, noise, bits = e1, [v1], []
while len(bits) < 14:                     # multiply by fresh Enc(1), 14 times
    ct, nu = fenc(1)
    acc = acc * ct % X
    noise.append(noise[-1] * nu)
    bits.append(fdec(acc))
first = next(k for k in range(len(noise)) if abs(noise[k]) > K // 2)
print(f"chain of multiplications by Enc(1), noise after each: {noise}")
print(f"chart, log2 |noise| after 0..14 multiplications: {[round(log2(abs(v)), 1) for v in noise]}; "
      f"limit log2(K/2) = {log2(K // 2):.1f}")
print(f"decrypted bit after each (true value 1): {bits}; noise passes K/2 = {K // 2} at multiplication {first}")
assert total == sum(takings) == 566845 and uniform                   # sum, two roads
assert leak == (takings[0] - w1 - w2) % M and leak <= takings[0] <= leak + 19998   # break 1: Hull's share by share()'s rule
assert hand == prod_xy == x * y and ident and (d - d2) % M == x - x2
assert mu * lam % n == 1 and dec(prod) == sum(ms) == 56 and binom and look and hom
assert len(table) == units == 4620 and same == 60 and (c1 - 1) // n == 18
assert dec(week) == 7 * sum(ms) % n and crack == 56 and f == p
assert fdec((e1 + e2) % X) == 1 and fdec(e1 * e2 % X) == 0 and fdec(tot) == par
assert all(bits[k - 1] == 1 for k in range(1, first)) and bits[first - 1:].count(0) > 0
print("ALL CHECKS PASS")
