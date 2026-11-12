# One-time pad -- the check behind the card.  Standard library only.
# The pad bytes come from SplitMix64 so Python and Rust print the same thing.
# That makes this pad INSECURE: a real pad needs bytes nobody can predict.
from math import log2, sqrt

M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def byte(self): return self.next() & 0xFF

def xor(a, b): return bytes(x ^ y for x, y in zip(a, b))
def hx(b): return " ".join(f"{x:02X}" for x in b)

# ---- the example: one 20-character order from a laptop to a bank ----
rng = SplitMix64(2026)
m = b"TRANSFER 750 TO BOB."
k = bytes(rng.byte() for _ in range(20))
c = xor(m, k)
back = xor(c, k)
print("pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad")
print("m  ", m.decode())
print("m  ", hx(m))
print("k  ", hx(k))
print("c  ", hx(c))
assert back == m
print("c xor k:", back.decode())
# char 10 (index 9), bit by bit: XOR is addition mod 2 in each bit
bits = lambda x: f"{x:08b}"
sum_mod2 = int("".join(str((int(a) + int(b)) % 2) for a, b in zip(bits(m[9]), bits(k[9]))), 2)
print(f"char 10: m {bits(m[9])} k {bits(k[9])} c {bits(c[9])}")
assert sum_mod2 == c[9]

# ---- every other message fits the same ciphertext under exactly one key ----
alt = b"TRANSFER 950 TO EVE."
k_alt = xor(c, alt)
print("key that turns c into", alt.decode() + ":", hx(k_alt))
assert xor(alt, k_alt) == c and k_alt != k
e = len(str(256**20)) - 1
print(f"keys of 20 bytes: 256^20 = 2^160 = {256**20 / 10**e:.4f} x 10^{e}")
assert 256**20 == 2**160

# ---- exhaustive toy: 4 messages (2 bits), prior 1/2, 1/4, 1/8, 1/8 ----
prior8 = [4, 2, 1, 1]                      # chances in eighths
def leak(pk):                              # pk[key] = chance of that key
    pm = [p / 8 for p in prior8]
    joint = [[pm[mm] * pk[mm ^ cc] for cc in range(4)] for mm in range(4)]
    pc = [sum(joint[mm][cc] for mm in range(4)) for cc in range(4)]
    i1 = sum(j * log2(j / (pm[mm] * pc[cc])) for mm in range(4)
             for cc in range(4) if (j := joint[mm][cc]) > 0)
    hc = -sum(p * log2(p) for p in pc if p > 0)
    hc_m = -sum(pm[mm] * q * log2(q) for mm in range(4) for q in pk if q > 0)
    zeros = sum(1 for mm in range(4) for cc in range(4) if pc[cc] > 0 and joint[mm][cc] == 0)
    return i1, hc - hc_m, zeros
hm = -sum(p / 8 * log2(p / 8) for p in prior8)
print(f"toy: H(M) = {hm:.4f} bits")
# uniform key, exact in 32nds: posterior P(m|c) must equal prior P(m) for all 16 pairs
key4 = [1, 1, 1, 1]                        # each key has chance 1/4
joint32 = [[prior8[mm] * key4[mm ^ cc] for cc in range(4)] for mm in range(4)]
pc32 = [sum(joint32[mm][cc] for mm in range(4)) for cc in range(4)]
same = all(joint32[mm][cc] * 8 == prior8[mm] * pc32[cc] for mm in range(4) for cc in range(4))
print("uniform key: posterior equals prior in all 16 cells:", same)
assert same and pc32 == [8, 8, 8, 8]
rows = [("uniform key", [0.25] * 4), ("biased key", [0.4, 0.3, 0.2, 0.1]),
        ("3 keys only", [1 / 3, 1 / 3, 1 / 3, 0.0]), ("1 key only", [1.0, 0, 0, 0])]
res = {}
for name, pk in rows:
    i1, i2, z = leak(pk)
    res[name] = (i1, z)
    print(f"{name:11}: I(M;C) = {i1:.4f} bits, H(M|C) = {hm - i1:.4f}, impossible cells = {z}")
    assert abs(i1 - i2) < 1e-12           # two formulas for the leak agree
assert abs(res["uniform key"][0]) < 1e-12 and res["uniform key"][1] == 0
assert res["biased key"][0] > 0.01 and res["3 keys only"][1] > 0
assert abs(res["1 key only"][0] - hm) < 1e-12   # no secret key: everything leaks

# ---- simulation: is it 750 or 950?  The guesser sees only c ----
N = 100_000
sim = SplitMix64(7)
win_fresh = win_weak = win_reuse = 0
old_m = b"TRANSFER 200 TO ANN."
rule = lambda c9: m if (c9 ^ m[9]) & 0x0E == 0 else alt   # reads bits 1-3, where '7' and '9' differ
for _ in range(N):
    sent = m if sim.byte() & 1 else alt
    key = bytes(sim.byte() for _ in range(20))
    ct = xor(sent, key)
    win_fresh += rule(ct[9]) == sent
    win_weak += rule(sent[9] ^ (sim.byte() & sim.byte())) == sent   # weak pad byte: each bit 1 with chance 1/4
    old_c = xor(old_m, key)                          # same key used before, old order known
    win_reuse += xor(xor(ct, old_c), old_m) == sent  # an XOR identity: shows the attack, tests only XOR
p, se = win_fresh / N, sqrt(0.25 / N)
weak = 0.5 * 0.75 ** 3 + 0.5 * (1 - 0.25 ** 3)       # exact: right if bits 1-3 are 000 (750 sent) or not 111 (950)
print(f"guessing 750 or 950 over {N} trials: fresh pad {p:.4f} (se {se:.4f}), reused pad {win_reuse / N:.4f}")
print(f"same guesser, weak pad (each bit 1 with chance 1/4): {win_weak / N:.4f}, exact {weak:.4f}")
assert abs(p - 0.5) < 4 * se                         # fails for any pad that is not uniform in those bits
assert abs(win_weak / N - weak) < 4 * se             # fails if the guesser is blind to the message
assert win_reuse == N

# ---- what breaks: the same pad used twice ----
c2 = xor(old_m, k)
leak2 = xor(c, c2)
print("c xor c2:", hx(leak2))
print("bytes equal to 00:", leak2.count(0), "of 20")
assert leak2 == xor(m, old_m)
print("c2 xor c xor m:", xor(leak2, m).decode())
assert xor(leak2, m) == old_m

# ---- what breaks: a short key repeated to fill 20 bytes ----
ok = set(b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .")      # 38 readable characters
counts = []
for L in range(1, 6):
    ct = bytes(x ^ k[i % L] for i, x in enumerate(m))
    n_read = 1                                           # key positions are independent
    for j in range(L):
        n_read *= sum(all((x ^ b) in ok for x in ct[j::L]) for b in range(256))
    counts.append(n_read)
print("repeated key of 1 to 5 bytes, readable decryptions:", ", ".join(map(str, counts)))
ct2 = bytes(x ^ k[i % 2] for i, x in enumerate(m))     # brute force all 65,536 two-byte keys
brute2 = sum(all((x ^ (a, b)[i % 2]) in ok for i, x in enumerate(ct2)) for a in range(256) for b in range(256))
assert counts[0] == 1 and brute2 == counts[1] and all(x < y for x, y in zip(counts, counts[1:]))
print(f"pad of 20 bytes: every string of those 38 characters fits, 38^20 = {38**20 / 10**31:.4f} x 10^31")
# ---- what breaks: secrecy is not integrity ----
tampered = bytearray(c)
tampered[9] ^= ord("7") ^ ord("9")
print("flip c[9] by", f"{ord('7') ^ ord('9'):02X}", "-> bank reads:", xor(tampered, k).decode())
assert xor(tampered, k) == b"TRANSFER 950 TO BOB."

# ---- the price: pad bytes the bank must hold in advance ----
per_day = 10_000_000 * 20
print(f"pad for 10,000,000 orders a day: {per_day:,} bytes a day, {per_day * 365:,} a year")
print("ALL CHECKS PASS")
