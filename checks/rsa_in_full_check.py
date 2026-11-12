# RSA in full -- the check behind the card.  Standard library only; no three-argument pow.
# A real-size key: two 1024-bit primes, a 2048-bit n, and OAEP with SHA-256 (RFC 8017).
# INSECURE: every random number comes from SplitMix64, seed 2026, so the Rust twin draws the
# same ones; a real key needs a secret random source.  A 64-bit toy key serves Pollard's rho.
from hashlib import sha256                         # Rust's std has no SHA-256, so the twin writes it out
from math import log, log10, sqrt
M64 = (1 << 64) - 1
state = 2026
def rand64():                                      # SplitMix64
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
def rand_bytes(k): return b"".join(rand64().to_bytes(8, "big") for _ in range(k // 8))
def power(b, x, m):                                # square and multiply, top bit down; counts multiplies
    r, mults = b % m, 0
    for i in range(x.bit_length() - 2, -1, -1):
        r, mults = r * r % m, mults + 1
        if x >> i & 1: r, mults = r * b % m, mults + 1
    return r, mults
def pw(b, x, m): return power(b, x, m)[0]
def gcd(a, b):
    while b: a, b = b, a % b
    return a
def inverse(a, m):                                 # extended Euclid
    r0, r1, s0, s1 = m, a % m, 0, 1
    while r1: k = r0 // r1; r0, r1, s0, s1 = r1, r0 - k * r1, s1, s0 - k * s1
    return s0 % m
def miller_rabin(n):                               # bases: the first 12 primes, a sure answer below 3.3 x 10^24
    t, s = n - 1, 0
    while t % 2 == 0: t, s = t // 2, s + 1
    for a in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        x = pw(a, t, n)
        if x in (1, n - 1): continue
        for _ in range(s - 1):
            x = x * x % n
            if x == n - 1: break
        else: return False
    return True
E = 65537
def new_prime(bits):                               # odd, top two bits set; redraw until prime
    for draws in range(1, 20001):
        x = 0
        for _ in range((bits + 63) // 64): x = x << 64 | rand64()
        x = x >> (-bits % 64) | 3 << (bits - 2) | 1
        if miller_rabin(x) and (x - 1) % E: return x, draws
    raise AssertionError("no prime in 20,000 draws")    # about 355 are expected at 1024 bits
def by_trial(n): return all(n % k for k in range(3, int(sqrt(n)) + 1, 2))
def row(name, *v): print(f"{name:<48}" + ", ".join(str(x) for x in v))
def hx(x, size=0): h = x.to_bytes(size or (x.bit_length() + 7) // 8, "big").hex(); return h[:8] + "..." + h[-8:]
HL, K = 32, 256                                    # SHA-256 output, and the key, in bytes
LH = sha256(b"").digest()                          # the hash of the empty label
def mgf1(z, n): return b"".join(sha256(z + i.to_bytes(4, "big")).digest() for i in range(-(-n // HL)))[:n]
def xor(a, b): return bytes(x ^ y for x, y in zip(a, b))
def oaep_pad(msg, seed):                           # RFC 8017 7.1.1: EM = 00 | maskedSeed | maskedDB
    assert len(msg) <= K - 2 * HL - 2, "message too long for OAEP"
    mdb = xor(LH + bytes(K - len(msg) - 2 * HL - 2) + b"\x01" + msg, mgf1(seed, K - HL - 1))
    return int.from_bytes(b"\0" + xor(seed, mgf1(mdb, HL)) + mdb, "big")
def oaep_unpad(x):                                 # None for every kind of failure, never a reason
    em = x.to_bytes(K, "big"); mdb = em[1 + HL:]
    db = xor(mdb, mgf1(xor(em[1:1 + HL], mgf1(mdb, HL)), K - HL - 1)); rest = db[HL:].lstrip(b"\0")
    return rest[1:] if em[0] == 0 and db[:HL] == LH and rest[:1] == b"\x01" else None
(tp, tdp), (tq, tdq) = new_prime(32), new_prime(32)   # the toy key is drawn first, then 400 more toy primes
draws = [new_prime(32)[1] for _ in range(400)]
(p, dp_), (q, dq_) = new_prime(1024), new_prime(1024)
n, phi = p * q, (p - 1) * (q - 1)
d = inverse(E, phi); dP, dQ, qinv = d % (p - 1), d % (q - 1), inverse(q, p)
assert E * d % phi == 1                            # checked at once: the loops below rely on it
print("2048-bit key from SplitMix64, seed 2026: real size, INSECURE source")
row("p: odd draws, bits, hex", dp_, p.bit_length(), hx(p))
row("q: odd draws, bits, hex", dq_, q.bit_length(), hx(q))
row("n = p x q: bits, decimal digits, hex", n.bit_length(), len(str(n)), hx(n))
row("d: bits, hex; e x d mod phi", d.bit_length(), hx(d), E * d % phi)
row("expected odd draws, one 1024-bit prime", f"{(1024 * log(2) + log(0.875)) / 2:.1f}")
aes, seed = rand_bytes(32), rand_bytes(32)
em = oaep_pad(aes, seed); c = pw(em, E, n)
row("AES key, 32 bytes; OAEP seed, 32 bytes", hx(int.from_bytes(aes, "big"), 32), hx(int.from_bytes(seed, "big"), 32))
row("OAEP block EM: bytes, hex", K, hx(em, K))
row("e; c = EM^e mod n: multiplies, hex", E, power(em, E, n)[1], hx(c))
em1, k_direct = power(c, d, n)
def crt(c, flip=0):                                # decrypt mod p and mod q, then glue
    (m1, k1), (m2, k2) = power(c % p, dP, p), power(c % q, dQ, q)
    m2 ^= flip                                     # flip=1: one bit of the mod-q half goes wrong
    return m2 + (qinv * (m1 - m2) % p) * q, k1, k2
em2, k1, k2 = crt(c)
assert em1 == em2 == em and oaep_unpad(em2) == aes # direct = CRT; OAEP round trip; checked at once
row("decrypt: direct multiplies; CRT mod p, mod q", k_direct, k1, k2)
print(f"{'cost: direct, CRT, speed-up':<48}{k_direct} x 4, {k1 + k2} x 1, {4 * k_direct / (k1 + k2):.2f}")
row("direct and CRT both give EM; OAEP gives key", "yes" if em1 == em2 == em else "no", "yes" if oaep_unpad(em2) == aes else "no")
c2 = pw(oaep_pad(aes, rand_bytes(32)), E, n)
row("same key, fresh seed: c, decodes to the key", hx(c2), "yes" if oaep_unpad(crt(c2)[0]) == aes else "no")
row("OAEP, 2048-bit key: largest message, bytes", K - 2 * HL - 2)
m, c500 = 500, pw(500, E, n)                       # a small amount, sent textbook-style
guess = next(k for k in range(1, 10001) if pw(k, E, n) == c500)
row("break 1, textbook 500: found, encryptions", guess, guess)
doubled = crt(c500 * pw(2, E, n) % n)[0]
row("break 2, textbook c x 2^e decrypts to", doubled)
tamper = sum(oaep_unpad(crt(c * pw(s, E, n) % n)[0]) is not None for s in range(2, 202))
row("break 2 on OAEP: accepted, tried; 1 in 2^", tamper, 200, 8 * HL)
g3 = gcd((pw(crt(c, 1)[0], E, n) - c) % n, n)
row("break 3, CRT fault: gcd(bad^e - c, n)", hx(g3))
q2 = new_prime(1024)[0]
row("break 4, shared prime: gcd(n, p x q2)", hx(gcd(n, p * q2)))
k = E * d - 1
while k % 2 == 0: k //= 2
for a in range(2, 1000):                           # bases sharing no factor with n
    x = pw(a, k, n); y = x * x % n
    while y != 1: x, y = y, y * y % n
    if x not in (1, n - 1): break                  # a square root of 1 that is not +1 or -1
g5 = gcd(x - 1, n)
row("break 5, leaked d: base used, factor", a, hx(g5))
tn, td = tp * tq, inverse(E, (tp - 1) * (tq - 1))
row("toy key, INSECURE: 32-bit p, q; n = p x q, bits", tp, tq, tn, tn.bit_length())
mean = sum(draws) / 400; se = sqrt(sum((x - mean) ** 2 for x in draws) / 399 / 400)
theory = (32 * log(2) + log(0.875)) / 2
row("odd draws: toy p, q; mean of 400; theory", tdp, tdq, f"{mean:.2f}", f"{theory:.2f}")
x, y, steps, f = 2, 2, 0, 1                        # Pollard rho, f(x) = x^2 + 1; the hare takes two steps
while f == 1:
    x, y, steps = (x * x + 1) % tn, ((y * y + 1) ** 2 + 1) % tn, steps + 1
    f = gcd((x - y) % tn, tn)
row("Pollard rho on toy n: factor, steps; sqrt(p)", f, steps, int(sqrt(tp)))
d2 = inverse(E, (f - 1) * (tn // f - 1))
row("toy d rebuilt from that factor matches", "yes" if d2 == td else "no")
row("RSA 1978, p 47, q 59, e 17: d, 920^17 mod 2773", inverse(17, 46 * 58), pw(920, 17, 2773))
row("log2 work, 2048-bit n: trial division, rho", 2048 // 2 - 1, 2048 // 4)
print("log2 work to factor: key bits, GNFS formula, NIST")
for bits, nist in ((1024, 80), (2048, 112), (3072, 128), (7680, 192), (15360, 256)):
    ln_n = bits * log(2)
    gnfs = (64 / 9) ** (1 / 3) * ln_n ** (1 / 3) * log(ln_n) ** (2 / 3) / log(2)
    print(f"  {bits:>5}  {gnfs:6.1f}  {nist:>3}")
    assert 0 < gnfs - nist < 15                    # formula without its o(1) sits a little above
assert by_trial(tp) and by_trial(tq) and abs(mean - theory) < 3 * se
assert len(str(n)) == int(2047 * log10(2)) + 1 and c2 != c
assert k_direct == d.bit_length() - 2 + bin(d).count("1") and 3.5 < 4 * k_direct / (k1 + k2) < 4.5
assert guess == m and doubled == 2 * m and tamper == 0
assert g3 == p and gcd(n, p * q2) == p and g5 in (p, q)
assert f in (tp, tq) and d2 == td and inverse(17, 2668) == 157 and pw(920, 17, 2773) == 948
print("ALL CHECKS PASS")
