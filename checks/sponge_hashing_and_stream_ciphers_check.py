# SHA-3 and ChaCha20-Poly1305 -- the check behind the card.  Standard library only: Keccak-f[1600], the sponge,
# ChaCha20, Poly1305 and the AEAD are written out.  Toy capacities and printed keys are insecure on purpose.
import math
M64, M32 = (1 << 64) - 1, (1 << 32) - 1
def rol64(v, n): return ((v << n) | (v >> (64 - n))) & M64 if n else v
RC, R = [0] * 24, 1                               # round constants from FIPS 202's 8-bit LFSR
for i in range(24):
    for j in range(7): R = ((R << 1) ^ ((R >> 7) * 0x71)) & 0xFF; RC[i] |= (R >> 1 & 1) << ((1 << j) - 1)
PERMS = [0]                                       # permutations run: the unit of cost
def keccak_f(A):                                  # A[x][y]: 25 lanes of 64 bits
    PERMS[0] += 1
    for rc in RC:
        C = [A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4] for x in range(5)]
        D = [C[(x - 1) % 5] ^ rol64(C[(x + 1) % 5], 1) for x in range(5)]
        A = [[A[x][y] ^ D[x] for y in range(5)] for x in range(5)]               # theta
        x, y, cur = 1, 0, A[1][0]
        for t in range(24):                       # rho and pi: offsets (t+1)(t+2)/2
            x, y = y, (2 * x + 3 * y) % 5
            cur, A[x][y] = A[x][y], rol64(cur, (t + 1) * (t + 2) // 2 % 64)
        A = [[A[x][y] ^ (~A[(x + 1) % 5][y] & A[(x + 2) % 5][y]) for y in range(5)] for x in range(5)]  # chi
        A[0][0] ^= rc                             # iota
    return A
def absorb(A, blk):                               # XOR a block into the rate part, then permute
    for i in range(0, len(blk), 8): A[i // 8 % 5][i // 40] ^= int.from_bytes(blk[i:i + 8], 'little')
    return keccak_f(A)
def state_bytes(A): return b''.join(A[i % 5][i // 5].to_bytes(8, 'little') for i in range(25))
def sponge(m, rate, zero_pad=False):              # rate in bytes; capacity = 200 - rate; 32 bytes out
    if zero_pad: m = m + b'\0' * (-len(m) % rate)                # the broken padding
    else: m = m + b'\x06' + b'\0' * (-(len(m) + 1) % rate); m = m[:-1] + bytes([m[-1] | 0x80])
    A = [[0] * 5 for _ in range(5)]
    for i in range(0, len(m), rate): A = absorb(A, m[i:i + rate])
    return state_bytes(A)[:32]                    # one squeeze: 32 bytes <= rate
def sha3_256(m): return sponge(m, 136)
print(f"== SHA3-256: the FIPS 202 sponge, against NIST's worked examples ==\nwidth 1600 bits, rate R = {136 * 8}, capacity C = {1600 - 136 * 8}, block 136 bytes, {len(RC)} rounds; RC[0] = {RC[0]:016x}  RC[23] = {RC[23]:016x}")
assert RC[0] == 1 and RC[23] == 0x8000000080008008, "LFSR round constants against the iota steps of rounds 0 and 23 in NIST's example"
PERMS[0] = 0; e = sha3_256(b"").hex(); print(f"h('') = {e}  ({PERMS[0]} permutation)")
assert e == "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", "NIST example: the 0-bit message"
assert sha3_256(b"\xa3" * 200).hex() == "79f38adec5c20307a98ef76e8324afbfd46cfd81b22e3973c65fa1bd9de31787", "NIST example: the 1600-bit message, two blocks"
ORDER = b"from=laptop&pay=250000.00&to=12345678"
print(f"order, {len(ORDER)} bytes: h = {sha3_256(ORDER).hex()}\nbits shown 256, bits kept hidden {1600 - 256}; collision 2^{256 // 2}, preimage 2^{min(512 // 2, 256)}")
z1, z2 = sponge(b"abc", 136, True), sponge(b"abc\0", 136, True); print(f"zero padding: h(abc) = {z1.hex()[:16]}...  h(abc+00) = {z2.hex()[:16]}...  equal: {z1 == z2}")
assert z1 == z2 and sha3_256(b"abc") != sha3_256(b"abc\0"), "zero padding merges messages; SHA-3 padding does not"
print("== capacity sets the security: inner collisions (toy capacities, insecure) ==")
def inner_hunt(cap, label):                       # one-block messages until two share the hidden part
    rate, seen, i = 200 - cap, {}, 0
    while True:
        blk = (label + b" #%d" % i).ljust(rate, b"."); s = state_bytes(absorb([[0] * 5 for _ in range(5)], blk))
        if s[rate:] in seen: return i + 1, seen[s[rate:]], (blk, s)
        seen[s[rate:]] = (blk, s); i += 1
def exact_mean(d, s=0.0, p=1.0, k=0):            # E[T] = sum over k of P(first k values all differ)
    while p > 1e-18: s += p; p *= 1 - k / d; k += 1
    return s
t = [inner_hunt(2, b"order %d" % run)[0] for run in range(40)]; m = sum(t) / 40; se = math.sqrt(sum((x - m) ** 2 for x in t) / 39 / 40)
print(f"C=16 bits, 40 hunts: mean tries {m:.2f} (se {se:.2f}), exact {exact_mean(2 ** 16):.2f}, sqrt(pi/2 2^16) {math.sqrt(math.pi / 2 * 2 ** 16):.2f}")
assert abs(m - exact_mean(2 ** 16)) < 4 * se, "inner collisions arrive at the birthday count for c bits"
tries, (b1, s1), (b2, s2) = inner_hunt(3, b"pay GBP 250,000 to account 12345678")
X = b"&memo=rent".ljust(197, b".")                  # second block; the other message cancels the rate difference
M1, M2 = b1 + X, b2 + bytes(a ^ b ^ c for a, b, c in zip(X, s1, s2))
H1, H2 = sponge(M1, 197), sponge(M2, 197)
print(f"C=24 bits: inner collision after {tries} tries; two {len(M1)}-byte messages, 256-bit outputs\n  h1 = {H1.hex()}\n  h2 = {H2.hex()}  equal: {H1 == H2}")
assert H1 == H2 and M1 != M2, "full collision from an inner collision"
print("== ChaCha20: add, rotate, xor, against RFC 8439 ==")
def rotl(v, n): return ((v << n) | (v >> (32 - n))) & M32
def qr(*v, trace=None):                           # add word j into i, xor i into k, rotate k left by n
    v = list(v)
    for i, j, k, n in ((0, 1, 3, 16), (2, 3, 1, 12), (0, 1, 3, 8), (2, 3, 1, 7)):
        v[i] = (v[i] + v[j]) & M32; v[k] = rotl(v[k] ^ v[i], n); trace is None or trace.append(f"{v[i]:08x} {v[k]:08x}")
    return tuple(v)
def qr_inv(a, b, c, d):                           # every step undone, in reverse order
    b = rotl(b, 25) ^ c; c = (c - d) & M32; d = rotl(d, 24) ^ a; a = (a - b) & M32
    b = rotl(b, 20) ^ c; c = (c - d) & M32; d = rotl(d, 16) ^ a; return (a - b) & M32, b, c, d
IDX = [(0, 4, 8, 12), (1, 5, 9, 13), (2, 6, 10, 14), (3, 7, 11, 15), (0, 5, 10, 15), (1, 6, 11, 12), (2, 7, 8, 13), (3, 4, 9, 14)]
def rounds(s, n, inv=False):                      # odd rounds use columns, even rounds diagonals
    s = list(s)
    for r in (range(n - 1, -1, -1) if inv else range(n)):
        qs = IDX[4 * (r % 2):4 * (r % 2) + 4]
        for q in (qs[::-1] if inv else qs):
            for i, x in zip(q, (qr_inv if inv else qr)(*[s[i] for i in q])): s[i] = x
    return s
def words(b): return [int.from_bytes(b[i:i + 4], 'little') for i in range(0, len(b), 4)]
def setup(key, ctr, nonce): return words(b"expand 32-byte k") + words(key) + [ctr] + words(nonce)
def block(key, ctr, nonce, s=None):
    s = setup(key, ctr, nonce); return b''.join(((x + y) & M32).to_bytes(4, 'little') for x, y in zip(rounds(s, 20), s))
def chacha20(key, ctr, nonce, data):            # keystream blocks ctr, ctr+1, ... XORed onto the data
    return bytes(x ^ y for x, y in zip(data, b''.join(block(key, ctr + i, nonce) for i in range((len(data) + 63) // 64))))
QIN, TR = (0x11111111, 0x01020304, 0x9b8d6f43, 0x01234567), []; QOUT = qr(*QIN, trace=TR); print("steps: " + " | ".join(TR))
print("quarter round: " + " ".join(f"{x:08x}" for x in QIN) + " -> " + " ".join(f"{x:08x}" for x in QOUT))
assert QOUT == (0xea2a92f4, 0xcb1cf8ce, 0x4581472e, 0x5881c4bb), "RFC 8439 2.1.1 quarter-round vector"
print("inverse quarter round returns " + " ".join(f"{x:08x}" for x in qr_inv(*QOUT))); assert qr_inv(*QOUT) == QIN, "undone exactly"
K, NONCE = bytes(range(32)), bytes.fromhex("000000090000004a00000000")
blk = block(K, 1, NONCE).hex(); print(f"block, counter 1: {blk[:32]}...{blk[-16:]}")
assert blk == "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e", "RFC 8439 2.3.2"
print("diffusion: flip each of the 256 key bits, bits of the 512-bit state that change"); base, spread = setup(K, 1, NONCE), []
def flip(s, i): s = list(s); s[4 + i // 32] ^= 1 << (i % 32); return s
for n in range(1, 9):
    f = [sum(bin(x ^ y).count('1') for x, y in zip(rounds(base, n), rounds(flip(base, i), n))) for i in range(256)]
    spread.append(sum(f) / 256); print(f"  rounds {n}: mean {spread[-1]:6.2f}, min {min(f):3d}")
assert spread[0] < 50 and abs(spread[7] - 256) < 4 * math.sqrt(128) / 16, "one round barely mixes; eight look random"; print("figure,rounds," + ",".join(f"{x:.2f}" for x in spread))
back = rounds(rounds(setup(K, 1, NONCE), 20), 20, True)    # the block WITHOUT the final addition, inverted
print(f"no final addition: inverting 20 rounds gives key {b''.join(x.to_bytes(4, 'little') for x in back[4:12]).hex()}"); assert back[4:12] == words(K), "without the final addition the key comes straight back"
print("== Poly1305: a polynomial in r modulo p = 2^130 - 5 =="); P, T128, CL = (1 << 130) - 5, 1 << 128, 0x0ffffffc0ffffffc0ffffffc0fffffff
def chunks(m): return [int.from_bytes(m[i:i + 16] + b'\x01', 'little') for i in range(0, len(m), 16)]
def rs(key): return int.from_bytes(key[:16], 'little') & CL, int.from_bytes(key[16:], 'little')
def poly1305(key, m):                             # road 1: Horner, as specified
    (r, s), acc = rs(key), 0
    for c in chunks(m): acc = (acc + c) * r % P
    return ((acc + s) % T128).to_bytes(16, 'little')
def poly_sum(key, m):                             # road 2: sum of c_i times r^(q-i+1)
    (r, s), tot, rp = rs(key), 0, 1
    for c in reversed(chunks(m)): rp = rp * r % P; tot += c * rp
    return ((tot % P + s) % T128).to_bytes(16, 'little')
PK, PM = bytes.fromhex("85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b"), b"Cryptographic Forum Research Group"
tag = poly1305(PK, PM).hex(); print(f"RFC 8439 2.5.2 tag {tag}, sum-of-powers road {poly_sum(PK, PM).hex()}")
assert tag == "a8061dc1305136c6c22b8baf0c0127a9" and poly_sum(PK, PM).hex() == tag, "Poly1305 vector, two roads"
L = len(ORDER) + (-len(ORDER) % 16) + 16; print(f"clamped r: {bin(CL).count('1')} free bits; order's MAC input {L} bytes, forgery chance <= {8 * (L // 16)}/2^106 = 1 in 2^{106 - round(math.log2(8 * (L // 16)))}")
def aead_tag(key, nonce, aad, ct):                # Poly1305 key = first 32 bytes of ChaCha20 block 0
    mac = aad + b'\0' * (-len(aad) % 16) + ct + b'\0' * (-len(ct) % 16) + len(aad).to_bytes(8, 'little') + len(ct).to_bytes(8, 'little')
    return poly1305(block(key, 0, nonce)[:32], mac)
def aead(key, nonce, aad, pt): ct = chacha20(key, 1, nonce, pt); return ct, aead_tag(key, nonce, aad, ct)
pt = b"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
ct, tg = aead(bytes(range(0x80, 0xa0)), bytes.fromhex("070000004041424344454647"), bytes.fromhex("50515253c0c1c2c3c4c5c6c7"), pt)
print(f"RFC 8439 2.8.2 AEAD: ciphertext {ct[:8].hex()}... tag {tg.hex()}"); assert ct[:16].hex() == "d31a8d34648e60db7b86afbc53ef7ec2" and tg.hex() == "1ae10b594f09e26a7e902ecbd0600691", "AEAD vector"
NB = bytes.fromhex("000000000000000000000001")    # toy key K above, printed: insecure on purpose
c1, t1 = aead(K, NB, b"", ORDER); bad = bytes([c1[0] ^ 1]) + c1[1:]
print(f"the order: ciphertext {c1.hex()[:24]}... tag {t1.hex()}, decrypts back: {chacha20(K, 1, NB, c1) == ORDER}")
print(f"one bit flipped: decrypts to {chacha20(K, 1, NB, bad)[:12].decode()}..., tag now {aead_tag(K, NB, b'', bad).hex()[:16]}..., bank {'accepts' if aead_tag(K, NB, b'', bad) == t1 else 'rejects'}")
assert aead_tag(K, NB, b"", bad) != t1 and chacha20(K, 1, NB, c1) == ORDER, "tag catches a flipped bit"
print("== a reused Poly1305 key (what a repeated nonce causes) ==")
def inv(x, y=1, e=P - 2):                         # x^(p-2) mod p, square and multiply
    while e: y = y * x % P if e & 1 else y; x = x * x % P; e >>= 1
    return y
OTK, (A1, A2, A3) = block(K, 0, NB)[:32], ( b"PAY GBP 250 #001", b"PAY GBP 120 #002", b"PAY GBP 950 #003")
(T1, T2), (C1, C2), found = (int.from_bytes(poly1305(OTK, a), 'little') for a in (A1, A2)), (chunks(A1)[0], chunks(A2)[0]), []
for k in range(-4, 5):                            # the mod 2^128 wrap hides a small multiple of 2^128
    r = (T1 - T2 + k * T128) * inv((C1 - C2) % P) % P
    if r & CL == r: found.append((r, (T1 - C1 * r % P) % T128))
r, s = found[0]; forged = (chunks(A3)[0] * r % P + s) % T128
print(f"candidates tried 9, of the clamped shape {len(found)}; r = {r:032x}\nforged tag for '{A3.decode()}' = {forged:032x}; bank's check: {'accepted' if forged.to_bytes(16, 'little') == poly1305(OTK, A3) else 'rejected'}")
assert len(found) == 1 and r == rs(OTK)[0], "two tags under one key give away r"; assert forged.to_bytes(16, 'little') == poly1305(OTK, A3), "forgery made without the key"
print("ALL CHECKS PASS")
