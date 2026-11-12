# AES-256 and GCM -- the check behind the card.  Nothing is imported: the field
# GF(2^8), the S-box, the cipher, its inverse and GCM are all written out here.
# The key is a published test key (FIPS 197): never use it for real data.

def xt(a): return ((a << 1) ^ 0x11B) if a & 0x80 else a << 1   # times x, wrapped by x^8+x^4+x^3+x+1
def gmul(a, b):                                                # multiply in GF(2^8)
    p = 0
    while b:
        if b & 1: p ^= a
        a, b = xt(a), b >> 1
    return p
def inv_search(a): return next((b for b in range(1, 256) if gmul(a, b) == 1), 0)
def power(a, n): return 1 if n == 0 else gmul(a, power(a, n - 1))
def inv_power(a): return power(a, 254)                         # a^254 is a^-1, since a^255 = 1
def rotl(b, n): return ((b << n) | (b >> (8 - n))) & 0xFF
def affine(b): return b ^ rotl(b, 1) ^ rotl(b, 2) ^ rotl(b, 3) ^ rotl(b, 4) ^ 0x63
SBOX = [affine(inv_search(a)) for a in range(256)]
INV = [SBOX.index(y) for y in range(256)]
M = [[2, 3, 1, 1], [1, 2, 3, 1], [1, 1, 2, 3], [3, 1, 1, 2]]
MI = [[14, 11, 13, 9], [9, 14, 11, 13], [13, 9, 14, 11], [11, 13, 9, 14]]
def mix(A, s):                                                 # each column of s times the 4 x 4 matrix A
    return [gmul(A[r][0], s[4 * c]) ^ gmul(A[r][1], s[4 * c + 1]) ^ gmul(A[r][2], s[4 * c + 2])
            ^ gmul(A[r][3], s[4 * c + 3]) for c in range(4) for r in range(4)]
def shift(s, d=1): return [s[r + 4 * ((c + d * r) % 4)] for c in range(4) for r in range(4)]
def xor(a, b): return [x ^ y for x, y in zip(a, b)]
def expand(key):                                               # 32-byte key -> 15 round keys
    w = [list(key[4 * i:4 * i + 4]) for i in range(8)]
    rc = 1
    for i in range(8, 60):
        t = list(w[i - 1])
        if i % 8 == 0:
            t = [SBOX[b] for b in t[1:] + t[:1]]; t[0] ^= rc; rc = xt(rc)
        elif i % 8 == 4:
            t = [SBOX[b] for b in t]
        w.append(xor(w[i - 8], t))
    return [sum(w[4 * r:4 * r + 4], []) for r in range(15)]
def rounds(rk, block, mixing=True, sbox=SBOX):                 # the state after each of the 14 rounds
    s, out = xor(block, rk[0]), []
    for r in range(1, 15):
        s = shift([sbox[b] for b in s])
        if mixing and r < 14: s = mix(M, s)
        s = xor(s, rk[r]); out.append(s)
    return out
def E(rk, b): return rounds(rk, b)[-1]
def D(rk, b):                                                  # the inverse cipher, run backwards
    s = list(b)
    for r in range(14, 0, -1):
        s = xor(s, rk[r])
        if r < 14: s = mix(MI, s)
        s = [INV[x] for x in shift(s, -1)]
    return xor(s, rk[0])

def gf128(x, y):                                               # multiply in GF(2^128), GCM's bit order
    z = 0
    for i in range(127, -1, -1):
        if (x >> i) & 1: z ^= y
        y = (y >> 1) ^ (0xE1 << 120) if y & 1 else y >> 1
    return z
def num(b): return int.from_bytes(bytes(b), "big")
def blk(n): return list(n.to_bytes(16, "big"))
def pieces(c, aad=()):                                         # padded 128-bit blocks, then the lengths
    bs = [num(list(p[i:i + 16]) + [0] * (16 - len(p[i:i + 16]))) for p in (aad, c) for i in range(0, len(p), 16)]
    return bs + [(len(aad) * 8) << 64 | len(c) * 8]
def ghash(H, bs):                                              # road 1: multiply as you go (Horner)
    x = 0
    for b in bs: x = gf128(x ^ b, H)
    return x
def ghash_sum(H, bs):                                          # road 2: sum of block_j times H^(n+1-j)
    total, p = 0, H
    for b in reversed(bs): total, p = total ^ gf128(b, p), gf128(p, H)
    return total
def ctr(rk, j0, data):                                         # counter mode: XOR with E(nonce || 2, 3, ...)
    return [x for i in range(0, len(data), 16) for x in xor(data[i:i + 16], E(rk, blk(j0 + 1 + i // 16)))]
def gcm(key, nonce, data):                                     # returns ciphertext and tag
    rk = expand(key); H = num(E(rk, [0] * 16)); j0 = num(list(nonce) + [0, 0, 0, 1])
    c = ctr(rk, j0, list(data))
    return c, num(E(rk, blk(j0))) ^ ghash(H, pieces(c))
def opens(key, nonce, c, tag):                                 # the receiver: check the tag first
    rk = expand(key); H = num(E(rk, [0] * 16)); j0 = num(list(nonce) + [0, 0, 0, 1])
    return num(E(rk, blk(j0))) ^ ghash(H, pieces(c)) == tag
def hx(b): return bytes(b).hex()
key, pt = list(range(32)), list(bytes.fromhex("00112233445566778899aabbccddeeff"))
rk = expand(key)
print("AES-256: key", 8 * len(key), "bits, block", 8 * len(pt), "bits,", len(rk) - 1, "rounds; GCM nonce 96 bits, tag 128 bits")
print("S(00) S(50) S(a0) S(f0) S(53):", " ".join(f"{SBOX[a]:02x}" for a in (0, 0x50, 0xA0, 0xF0, 0x53)))
print(f"inverse of 50: by search {inv_search(0x50):02x}, by power 254 {inv_power(0x50):02x}, 50 x it = {gmul(0x50, inv_power(0x50)):02x}")
print("affine(ed): xor of", " ".join(f"{rotl(0xED, n):02x}" for n in range(5)), f"and 63 = {affine(0xED):02x}")
eye = [int(r == c) for c in range(4) for r in range(4)]
MMI = mix(M, [MI[r][c] for c in range(4) for r in range(4)])   # M times MI, column by column
print("M times its inverse is the identity:", MMI == eye)
st = xor(pt, rk[0]); sb = [SBOX[b] for b in st]; sr = shift(sb); mc = mix(M, sr)
for name, v in (("start", st), ("s_box", sb), ("s_row", sr), ("m_col", mc), ("k_sch", rk[1]), ("end", xor(mc, rk[1]))):
    print(f"round 1 {name:<6}{hx(v)}")
a, b = gmul(2, 0x63), gmul(3, 0x53)
print(f"column 0 by hand: 02.63={a:02x} 02.53={gmul(2, 0x53):02x} 03.53={b:02x}; {a:02x}^{b:02x}={a ^ b:02x} ^e0={a ^ b ^ 0xE0:02x} ^8c={a ^ b ^ 0xE0 ^ 0x8C:02x}")
ct = E(rk, pt)
print("FIPS 197 C.3 ciphertext", hx(ct), "decrypts to", hx(D(rk, ct)))
flip = [pt[0] ^ 1] + pt[1:]
diff = [sum(x != y for x, y in zip(s1, s2)) for s1, s2 in zip(rounds(rk, pt), rounds(rk, flip))]
bits = lambda u, v: sum(bin(x ^ y).count("1") for x, y in zip(u, v))
avg = sum(bits(ct, E(rk, pt[:i // 8] + [pt[i // 8] ^ (1 << (i % 8))] + pt[i // 8 + 1:])) for i in range(128)) / 128
nomix = [sum(x != y for x, y in zip(s1, s2)) for s1, s2 in zip(rounds(rk, pt, False), rounds(rk, flip, False))]
print("one plaintext bit flipped, bytes changed after rounds 1-4:", diff[:4], "after 14:", diff[13])
print(f"bits changed: this flip {bits(ct, E(rk, flip))} of 128, average over all 128 flips {avg:.2f}")
print("no MixColumns, bytes changed after 14 rounds:", nomix[13])
ident, m2, m3 = list(range(256)), [7] * 16, list(range(16, 32))
lin = lambda sb: xor(xor(rounds(rk, pt, True, sb)[-1], rounds(rk, m2, True, sb)[-1]), rounds(rk, m3, True, sb)[-1]) == rounds(rk, xor(xor(pt, m2), m3), True, sb)[-1]
print("E(a)^E(b)^E(c) == E(a^b^c): identity S-box", lin(ident), "| real S-box", lin(SBOX), "| blocks to solve a linear one, 128 + 1:", 8 * len(pt) + 1)
c13, t13 = gcm([0] * 32, [0] * 12, [])
c14, t14 = gcm([0] * 32, [0] * 12, [0] * 16)
print(f"GCM test 13 tag {t13:032x}")
print(f"GCM test 14 ct {hx(c14)} tag {t14:032x}")
H0, bs = num(E(expand([0] * 32), [0] * 16)), pieces(c14)
print("GHASH by Horner equals GHASH as a sum of powers:", ghash(H0, bs) == ghash_sum(H0, bs))
nonce, backup = list(bytes.fromhex("cafebabefacedbaddecaf888")), list(b"BACKUP v1 part 1") + [0] * 48
ecb = [hx(E(rk, backup[i:i + 16]))[:8] for i in range(0, 64, 16)]
cg, tg = gcm(key, nonce, backup)
gc = [hx(cg[i:i + 16])[:8] for i in range(0, 64, 16)]
print("backup, 4 blocks, ECB:", " ".join(ecb), "distinct", len(set(ecb)))
print("backup, 4 blocks, GCM:", " ".join(gc), "distinct", len(set(gc)))
bad = [cg[0] ^ 1] + cg[1:]
j0 = num(nonce + [0, 0, 0, 1])
print("one bit flipped: counter mode alone reads", bytes(ctr(rk, j0, bad)[:16]).decode("latin-1"), "| GCM accepts:", opens(key, nonce, bad, tg), "| untouched:", opens(key, nonce, cg, tg))
m1, m2 = list(b"balance: 1200.00"), list(b"balance: 9875.50")
k1, k2 = gcm(key, nonce, m1)[0], gcm(key, nonce, m2)[0]
print("nonce reused: c1^c2 == m1^m2:", xor(k1, k2) == xor(m1, m2), "| m1 known, so m2 =", bytes(xor(xor(k1, k2), m1)).decode("latin-1"))
size = 4 * 2 ** 30; nb = size // 16; q = 2 ** 32
print(f"4 GB backup: {size} bytes = {nb} blocks; AES calls {nb + 2}; GHASH multiplies {nb + 1}; stored extra {12 + 16} bytes")
print(f"one GCM message may hold at most {(2 ** 32 - 2) * 16} bytes")
print(f"random 96-bit nonces, {q} messages: repeat chance about 1 in {2 ** 97 // (q * (q - 1))}")
print(f"tag forgery per try at most about 2^{(nb + 1).bit_length() - 1 - 128}; block birthday 2^{2 * (nb.bit_length() - 1) - 129}")
assert SBOX[0x00] == 0x63 and SBOX[0x53] == 0xED and all(SBOX[a] == affine(inv_power(a)) for a in range(256))
assert hx(mc) == "5f72641557f5bc92f7be3b291db9f91a"           # FIPS 197 C.3, round[1].m_col
assert hx(ct) == "8ea2b7ca516745bfeafc49904b496089" and D(rk, ct) == pt
assert t13 == 0x530f8afbc74536b9a963b4f1c4cb738b and hx(c14) == "cea7403d4d606b6e074ec5d3baf39d18"
assert t14 == 0xd0d1c8a799996bf0265b98b5d48ab919 and ghash(H0, bs) == ghash_sum(H0, bs)
assert diff[:2] == [4, 16] and nomix[13] == 1 and 60 < avg < 68 and lin(ident) and not lin(SBOX)
assert len(set(ecb)) == 2 and len(set(gc)) == 4 and not opens(key, nonce, bad, tg) and opens(key, nonce, cg, tg)
assert bytes(xor(xor(k1, k2), m1)) == b"balance: 9875.50" and MMI == eye
print("ALL CHECKS PASS")
