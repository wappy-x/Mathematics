# Digital signatures -- the check behind the card.  Standard library only.
# SHA-256 (FIPS 180-4) and ECDSA (FIPS 186-5) are written out: no hashlib, no pow.
# The curve is a TOY, insecure on purpose: about 2^20 points, where P-256 has about 2^256.
M32 = 0xFFFFFFFF
def primes(c):
    out, x = [], 2
    while len(out) < c:
        if all(x % p for p in out if p * p <= x): out.append(x)
        x += 1
    return out
def root_bits(r, x):                         # 32 bits after the point of x^(1/r), integers only
    lo, hi = 0, 1 << 40
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if mid ** r <= x << (32 * r): lo = mid
        else: hi = mid - 1
    return lo & M32
K = [root_bits(3, p) for p in primes(64)]
H0 = [root_bits(2, p) for p in primes(8)]
def rotr(x, s): return ((x >> s) | (x << (32 - s))) & M32
def sha256(m):
    m = m + b'\x80' + b'\0' * ((55 - len(m)) % 64) + (8 * len(m)).to_bytes(8, 'big')
    st = H0
    for j in range(0, len(m), 64):
        w = [int.from_bytes(m[j + 4 * i:j + 4 * i + 4], 'big') for i in range(16)]
        for i in range(16, 64):
            a, b = w[i - 15], w[i - 2]
            w.append((w[i - 16] + (rotr(a, 7) ^ rotr(a, 18) ^ (a >> 3)) + w[i - 7]
                      + (rotr(b, 17) ^ rotr(b, 19) ^ (b >> 10))) & M32)
        a, b, c, d, e, f, g, h = st
        for i in range(64):
            t1 = (h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + ((e & f) ^ (~e & g)) + K[i] + w[i]) & M32
            t2 = ((rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) ^ (a & c) ^ (b & c))) & M32
            a, b, c, d, e, f, g, h = (t1 + t2) & M32, a, b, c, (d + t1) & M32, e, f, g
        st = [(x + y) & M32 for x, y in zip(st, [a, b, c, d, e, f, g, h])]
    return b''.join(x.to_bytes(4, 'big') for x in st)

# ---- the toy curve: y^2 = x^3 + 7 mod p, the equation Bitcoin uses, at 20 bits ----
p, n, G = 1_000_003, 999_007, (100, 2)       # base point G; n = number of multiples of G
def inv(a, m):                               # 1/a mod m by Euclid's algorithm
    r0, r1, t0, t1 = m, a % m, 0, 1
    while r1: qq = r0 // r1; r0, r1, t0, t1 = r1, r0 - qq * r1, t1, t0 - qq * t1
    assert r0 == 1
    return t0 % m
def add(P, Q):                               # None is the point at infinity
    if P is None or Q is None: return Q if P is None else P
    if P[0] == Q[0] and (P[1] + Q[1]) % p == 0: return None
    lam = (3 * P[0] * P[0] * inv(2 * P[1], p) if P == Q else (Q[1] - P[1]) * inv(Q[0] - P[0], p)) % p
    x = (lam * lam - P[0] - Q[0]) % p
    return (x, (lam * (P[0] - x) - P[1]) % p)
def mul(k, P):                               # kP by double-and-add
    R = None
    while k:
        if k & 1: R = add(R, P)
        P, k = add(P, P), k >> 1
    return R
assert all(n % f for f in range(2, 1000)) and mul(n, G) is None and G[1] ** 2 % p == (G[0] ** 3 + 7) % p
def z_of(msg): return int.from_bytes(sha256(msg), 'big') >> (256 - n.bit_length())   # leftmost 20 bits
def sign(d, k, msg):
    z, r = z_of(msg), mul(k, G)[0] % n
    return r, inv(k, n) * (z + r * d) % n
def verify(Q, msg, sig):
    r, s = sig
    if not (0 < r < n and 0 < s < n): return False
    w = inv(s, n)
    X = add(mul(z_of(msg) * w % n, G), mul(r * w % n, Q))
    return X is not None and X[0] % n == r

print("sha256('abc') =", sha256(b"abc").hex()[:16], "...", sha256(b"abc").hex()[-8:])
assert sha256(b"abc").hex() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
print(f"toy curve y^2 = x^3 + 7 mod {p}, G = {G}, n = {n} (prime, {n.bit_length()} bits), nG = infinity")
# ---- the example: the bank signs a 65,536-byte laptop update (synthetic bytes) ----
upd1 = bytes((i * 37 + (i >> 8)) & 0xFF for i in range(65536))
upd2 = upd1[:-1] + b'\x01'                   # the next release: last byte changed
d, k = 512_377, 90_210                       # private key; nonce (must be fresh each time)
Q = mul(d, G)
z1, z2 = z_of(upd1), z_of(upd2)
print("public key Q = dG =", Q)
print("update 1: 65,536 bytes; h(update 1) starts", sha256(upd1).hex()[:16], "-> z1 =", z1)
assert z1 == int(sha256(upd1).hex()[:5], 16)          # leftmost 20 bits = first 5 hex digits
r1, s1 = sign(d, k, upd1)
print(f"kG = {mul(k, G)}, r = {r1}, 1/k mod n = {inv(k, n)}, z1 + r d mod n = {(z1 + r1 * d) % n}, s = {s1}")
w = inv(s1, n); u1, u2 = z1 * w % n, r1 * w % n
print(f"verify: w = {w}, u1 = {u1}, u2 = {u2}, u1G + u2Q = {add(mul(u1, G), mul(u2, Q))}")
assert add(mul(u1, G), mul(u2, Q)) == mul(k, G) and verify(Q, upd1, (r1, s1))
bad = bytearray(upd1); bad[1000] ^= 1
print("one bit flipped in byte 1000: z =", z_of(bytes(bad)), "verifies:", verify(Q, bytes(bad), (r1, s1)))
assert not verify(Q, bytes(bad), (r1, s1))
# ---- what breaks: the same nonce for two updates ----
r2, s2 = sign(d, k, upd2)
print(f"update 2 with the same nonce: z2 = {z2}, r = {r2}, s = {s2}")
print(f"s1 - s2 = {(s1 - s2) % n}, z1 - z2 = {(z1 - z2) % n} (mod n)")
k_found = (z1 - z2) * inv((s1 - s2) % n, n) % n
d_found = (s1 * k_found - z1) * inv(r1, n) % n
print(f"recovered nonce k = {k_found}, recovered key d = {d_found}")
assert r2 == r1 and k_found == k and d_found == d
X, steps = G, 1                              # road 2: brute-force discrete log, one add per step
while X != Q: X, steps = add(X, G), steps + 1
print(f"brute force: walked G, 2G, 3G, ... and met Q = {steps:,} G after {steps - 1:,} additions (average about n/2 = {n // 2:,})")
assert steps == d_found
evil = b"update 4.2.2: also install remote-access tool"
sig_e = sign(d_found, 777, evil)              # check: the stolen key signs anything
print("forged signature on a new update:", sig_e, "verifies:", verify(Q, evil, sig_e))
assert verify(Q, evil, sig_e)
s_leak = (s1 * k - z1) * inv(r1, n) % n
print("one signature plus its leaked nonce gives d =", s_leak)
assert s_leak == d
# ---- what breaks: no hash.  Public key only, a signature on a number nobody chose ----
a, b = 1234, 5678
R = add(mul(a, G), mul(b, Q)); r_f = R[0] % n; s_f = r_f * inv(b, n) % n; z_f = a * s_f % n
w = inv(s_f, n)
X = add(mul(z_f * w % n, G), mul(r_f * w % n, Q))
print(f"no hash: a = {a}, b = {b} give r = {r_f}, s = {s_f} on 'message' {z_f}: verifies {X[0] % n == r_f}")
assert X[0] % n == r_f and z_f != z1
# ---- what breaks: a hash cut too short.  A chosen-message attack by birthday collision ----
seen, drafts = {}, 2048
for i in range(drafts):
    msg = b"update 4.2.1 notes, build %d: fix typo in help page" % i
    seen[z_of(msg)] = msg
j = 0
while True:
    harm = b"update 4.2.1 notes, build %d: add remote-access tool" % j
    j += 1
    if z_of(harm) in seen: break
benign = seen[z_of(harm)]
print(f"collision: {drafts} harmless drafts, {len(seen)} distinct z; {j} harmful drafts; z = {z_of(harm)}")
print("  signer signs:", benign.decode())
sig_b = sign(d, 424_242, benign)
print("  attacker attaches it to:", harm.decode(), "-> verifies:", verify(Q, harm, sig_b))
assert verify(Q, harm, sig_b) and harm != benign
print(f"expected harmful drafts: 2^20 / {len(seen)} = {2 ** 20 / len(seen):.0f}")
print("real sizes: P-256 with SHA-256, n and digest about 2^256; best known attacks, collision or key, about 2^128 operations")
print("ALL CHECKS PASS")
