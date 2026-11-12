# Hashes and MACs -- the check behind the card.  Standard library only.
# SHA-256 (FIPS 180-4), HMAC (RFC 2104) and PBKDF2 are written out: no hashlib, no hmac.
# The attacks run on digests cut to a few bits: toy sizes, insecure on purpose.
import math
M32 = 0xFFFFFFFF
def primes(c):
    out, x = [], 2
    while len(out) < c:
        if all(x % p for p in out if p * p <= x): out.append(x)
        x += 1
    return out
def frac_root(r, x):                         # 32 bits after the point of x^(1/r), integers only
    lo, hi = 0, 1 << 40
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if mid ** r <= x << (32 * r): lo = mid
        else: hi = mid - 1
    return lo & M32
K = [frac_root(3, p) for p in primes(64)]    # round constants: cube roots of the first 64 primes
H0 = [frac_root(2, p) for p in primes(8)]    # starting state: square roots of the first 8 primes
COUNT = [0]                                  # compressions done: the unit of cost
# (x >> s | x << 32 - s) below is x rotated right by s places, written inline for speed
def compress(st, blk):                       # one 64-byte block folded into the 8-word state
    COUNT[0] += 1
    w = [int.from_bytes(blk[4 * i:4 * i + 4], 'big') for i in range(16)]
    for i in range(16, 64):
        a, b = w[i - 15], w[i - 2]
        s0 = (a >> 7 | a << 25) ^ (a >> 18 | a << 14) ^ (a >> 3); s1 = (b >> 17 | b << 15) ^ (b >> 19 | b << 13) ^ (b >> 10)
        w.append((w[i - 16] + s0 + w[i - 7] + s1) & M32)
    a, b, c, d, e, f, g, h = st
    for i in range(64):
        t1 = (h + ((e >> 6 | e << 26) ^ (e >> 11 | e << 21) ^ (e >> 25 | e << 7)) + ((e & f) ^ (~e & g)) + K[i] + w[i]) & M32
        t2 = (((a >> 2 | a << 30) ^ (a >> 13 | a << 19) ^ (a >> 22 | a << 10)) + ((a & b) ^ (a & c) ^ (b & c))) & M32
        a, b, c, d, e, f, g, h = (t1 + t2) & M32, a, b, c, (d + t1) & M32, e, f, g
    return [(x + y) & M32 for x, y in zip(st, [a, b, c, d, e, f, g, h])]
def pad(total): return b'\x80' + b'\0' * ((55 - total) % 64) + (8 * total).to_bytes(8, 'big')
def sha256(m, st=H0, done=0):                # done = bytes already folded into st
    m = m + pad(done + len(m))
    for i in range(0, len(m), 64): st = compress(st, m[i:i + 64])
    return b''.join(x.to_bytes(4, 'big') for x in st)
def top(dg, bits): return int.from_bytes(dg[:4], 'big') >> (32 - bits)
def hmac(k, m):
    k = (sha256(k) if len(k) > 64 else k).ljust(64, b'\0')
    return sha256(bytes(x ^ 0x5C for x in k) + sha256(bytes(x ^ 0x36 for x in k) + m))
def xor(a, b): return bytes(x ^ y for x, y in zip(a, b))
def pbkdf2(pw, salt, r, blocks=1, cached=False):
    mac = lambda m: hmac(pw, m)              # plain: 4 compressions per HMAC
    if cached:                               # careful: fold the two key blocks once, then 2 per HMAC
        k = pw.ljust(64, b'\0')              # passwords here are under 64 bytes
        ist, ost = compress(H0, xor(k, b'\x36' * 64)), compress(H0, xor(k, b'\x5C' * 64))
        mac = lambda m: sha256(sha256(m, ist, 64), ost, 64)
    out = b''
    for j in range(1, blocks + 1):
        u = acc = mac(salt + j.to_bytes(4, 'big'))
        for _ in range(r - 1): u = mac(u); acc = xor(acc, u)
        out += acc
    return out
def bitdiff(a, b): return sum(bin(x ^ y).count('1') for x, y in zip(a, b))
print("== SHA-256 against FIPS 180-4 ==")
print(f"K[0] = {K[0]:08x}  K[63] = {K[63]:08x}  H0[0] = {H0[0]:08x}")
abc = sha256(b"abc").hex(); print(f"h(abc) = {abc}")
assert abc == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "FIPS vector 1"
assert sha256(b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq").hex() == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "FIPS vector 2"
print("== the contract ==")
C = b"Sale of 14 Elm Road for GBP 250,000; completes 1/3/2027"
dc, dc2 = sha256(C), sha256(C.replace(b"250,000", b"260,000"))
print(f"bytes {len(C)}  h = {dc.hex()}")
print(f"260,000 h = {dc2.hex()}")
flips = [bitdiff(dc, sha256(bytes(C[:i // 8]) + bytes([C[i // 8] ^ (1 << (i % 8))]) + C[i // 8 + 1:])) for i in range(8 * len(C))]
mean = sum(flips) / len(flips); se = math.sqrt(sum((f - mean) ** 2 for f in flips) / (len(flips) - 1) / len(flips))
print(f"one char changed: {bitdiff(dc, dc2)} of 256 bits differ")
print(f"all {len(flips)} one-bit edits: mean {mean:.2f} bits differ (ideal 128, se {se:.2f}), min {min(flips)} max {max(flips)}")
assert abs(mean - 128) < 4 * se, "avalanche: a one-bit edit should flip half the bits"
print(f"pigeonhole: 2^{8 * 33} messages of 33 bytes into 2^256 digests, some digest shared by >= {2 ** (8 * 33) // 2 ** 256}")
print("== the bounds, for an ideal n-bit hash ==")
def exact_mean(d):                           # E[T] = sum over k of P(first k values all differ)
    s, p, k = 0.0, 1.0, 0
    while p > 1e-18: s += p; p *= 1 - k / d; k += 1
    return s
for n in (256, 160, 64):
    print(f"n={n}: half-chance at {math.sqrt(2 * math.log(2)):.4f} x 2^{n // 2}, mean {math.sqrt(math.pi / 2):.4f} x 2^{n // 2}, guessing 2^{n}")
print(f"n=256 in tries: 2^128 = {2 ** 128 / 1e38:.4f} x 10^38, half-chance {math.sqrt(2 * math.log(2)) * 2 ** 128 / 1e38:.4f} x 10^38")
print(f"SHA-1: promised 2^80, published attack 2^63.1, short by about 2^{round(80 - 63.1)} = {2 ** round(80 - 63.1)}")
print(f"64-bit digest, mean tries to a collision = {math.sqrt(math.pi / 2 * 2 ** 64):.0f}")
print("== collisions on digests cut to n bits (toy, insecure) ==")
def first_repeat(bits, label):
    seen, i = {}, 0
    while True:
        v = top(sha256(label + b"%d" % i), bits)
        if v in seen: return i + 1, seen[v], i
        seen[v] = i; i += 1
for n in (8, 12, 16, 20):
    t = [first_repeat(n, b"Elm Road draft %d." % r)[0] for r in range(40)]
    m = sum(t) / 40; se = math.sqrt(sum((x - m) ** 2 for x in t) / 39 / 40); ex = exact_mean(2 ** n)
    print(f"n={n:2d} runs 40 measured {m:8.2f} (se {se:6.2f})  exact {ex:8.2f}  sqrt(pi/2 2^n) {math.sqrt(math.pi / 2 * 2 ** n):8.2f}")
    assert abs(m - ex) < 4 * se, f"collision cost at n={n}"
L = b"Sale of 14 Elm Road for GBP 250,000; ref "
tries, a, b = first_repeat(32, L)
print(f"n=32: refs {a} and {b} share {sha256(L + b'%d' % a)[:4].hex()}, after {tries} tries (exact mean {exact_mean(2 ** 32):.0f})")
assert top(sha256(L + b"%d" % a), 32) == top(sha256(L + b"%d" % b), 32) and a != b, "32-bit collision"
print("== second preimages: match the contract's first n bits ==")
ratios = []
for n in (8, 10, 12):
    t = [next(i for i in range(1, 10 ** 6) if top(sha256(b"Sale of 14 Elm Road for GBP 25,000; v%d.%d" % (r, i)), n) == top(dc, n)) for r in range(20)]
    ratios += [x / 2 ** n for x in t]
    print(f"n={n:2d} runs 20 measured {sum(t) / 20:8.1f}  ideal 2^n = {2 ** n}")
rm = sum(ratios) / len(ratios)
print(f"all 60 runs: measured / 2^n = {rm:.3f} (ideal 1, se {1 / math.sqrt(60):.3f})")
assert abs(rm - 1) < 4 / math.sqrt(60), "second preimage cost should be 2^n"
print("== MACs: one message from the laptop to the bank ==")
KEY = bytes(range(32))                       # a toy key, printed, so insecure on purpose
MSG = b"from=laptop&pay=250000.00&to=12345678"
naive = sha256(KEY + MSG); glue = pad(len(KEY) + len(MSG)); EXT = b"&to=66666666"
state = [int.from_bytes(naive[4 * i:4 * i + 4], 'big') for i in range(8)]   # the tag IS the state
forged = sha256(EXT, state, len(KEY) + len(MSG) + len(glue))                 # no key used
print(f"naive tag h(k||m) = {naive.hex()[:16]}...  glue {len(glue)} bytes, forged message {len(MSG + glue + EXT)} bytes")
print(f"forged tag, made without k = {forged.hex()[:16]}...  bank's check: {'accepted' if forged == sha256(KEY + MSG + glue + EXT) else 'rejected'}")
assert forged == sha256(KEY + MSG + glue + EXT), "length extension"
real = hmac(KEY, MSG + glue + EXT)
print(f"HMAC tag of forged message = {real.hex()[:16]}...  bank's check: {'accepted' if forged == real else 'rejected'}")
assert forged != real, "HMAC must not fall to length extension"
rfc = hmac(b"Jefe", b"what do ya want for nothing?").hex()
print(f"RFC 4231 case 2: {rfc[:16]}...")
assert rfc == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "HMAC vector"
print("== password key derivation ==")
v, v2 = pbkdf2(b"passwd", b"salt", 1, 2).hex(), pbkdf2(b"Password", b"NaCl", 80000, 1, True).hex()
print(f"RFC 7914 PBKDF2 vectors: r=1 {v[:16]}..., r=80000 {v2[:16]}...")
assert v.startswith("55ac046e56e3089fec1691c22544b605") and v.endswith("49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783"), "PBKDF2 vector"
assert v2 == "4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56", "PBKDF2 vector 2: the XOR over 80000 rounds"
pw, s1, s2 = b"letmein1", b"customer-000001", b"customer-000002"
print(f"same password, no salt: both customers store {sha256(pw).hex()[:8]}")
print(f"same password, salted, r=1000: {pbkdf2(pw, s1, 1000).hex()[:8]} and {pbkdf2(pw, s2, 1000).hex()[:8]}")
for cached in (False, True):
    COUNT[0] = 0; out = pbkdf2(pw, s1, 1000, 1, cached)
    print(f"{'cached' if cached else 'plain '} code: {COUNT[0]} compressions per guess, key {out.hex()[:8]}")
    assert COUNT[0] == (2 * 1000 + 2 if cached else 4 * 1000) and out == pbkdf2(pw, s1, 1000), "cost count"
G, R, U = 26 ** 8, 100000, 10 ** 6
print(f"8 lower-case letters: {G} guesses; plain hash {G} compressions; r={R}: {G * (2 * R + 2)}")
print(f"{U} customers: unsalted, one pass {G * (2 * R + 2)}; salted, {U} passes {G * (2 * R + 2) * U}")
print("ALL CHECKS PASS")
