# Incompressibility and randomness -- the check behind the card.  Standard library
# only: no zlib, lzma or random.  Four roads: count descriptions by a sum and by a
# closed form; run a tiny decompressor D on every 16-bit file; zip a text twice with
# LZ78, written out below (the Lempel-Ziv card explains it); price lopsided strings.
from math import log2, e, ceil
MASK = (1 << 64) - 1

class SplitMix64:                        # small seeded generator, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def lz78_pack(data):                     # bytes in, bytes out: 32-bit length, then (index, byte) pairs
    bits, book, w, i = [], {b"": 0}, b"", 1
    put = lambda v, k: bits.extend((v >> (k - 1 - j)) & 1 for j in range(k))
    put(len(data), 32)
    for b in data:
        wb = w + bytes([b])
        if wb in book:
            w = wb
            continue
        put(book[w], (i - 1).bit_length()); put(b, 8)
        book[wb], w, i = i, b"", i + 1
    if w:
        put(book[w], (i - 1).bit_length())
    bits += [0] * (-len(bits) % 8)
    return bytes(sum(bits[k + j] << (7 - j) for j in range(8)) for k in range(0, len(bits), 8))

def lz78_unpack(blob):                   # the decompressor: a program that reads the packed file
    pos = 0
    def get(k):
        nonlocal pos
        v = 0
        for _ in range(k):
            v = (v << 1) | ((blob[pos >> 3] >> (7 - (pos & 7))) & 1); pos += 1
        return v
    n, book, out, i = get(32), [b""], bytearray(), 1
    while len(out) < n:
        w = book[get((i - 1).bit_length())]
        if len(out) + len(w) == n: out += w; break
        w += bytes([get(8)]); out += w; book.append(w); i += 1
    return bytes(out)

def byte_entropy(data):                  # bits per byte if each byte were coded by its own frequency
    f = [0] * 256
    for b in data: f[b] += 1
    return -sum(c / len(data) * log2(c / len(data)) for c in f if c)

# ---- road 1: count the short descriptions ----
n = 16
print(f"files of {n} bits: 2^{n} = {1 << n}")
for c in (1, 2, 4, 8):
    short = sum(1 << L for L in range(n - c))      # every bit string of length 0 .. n-c-1
    print(f"c = {c}: descriptions shorter than {n - c} bits: {short} = 2^{n - c} - 1; at least {(1 << n) - short} files ({100 * (1 - short / (1 << n)):.4f}%) need {n - c} bits or more")
    assert short == (1 << (n - c)) - 1             # the sum against the closed form
print(f"a file of 1048576 bytes is {8 * 1048576} bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < {1 / 256:.8f}; shrink by 1%: share < 2^-{8 * 1048576 // 100}")

# ---- road 2: a tiny decompressor D, run on every description up to 17 bits ----
def D(desc, L):                          # reads a description of L bits; prints a 16-bit file
    if L == 17 and desc >> 16 == 0:      # 0 then 16 bits: the file written out
        return desc
    if L >= 4 and desc >> (L - 1) == 1:  # 1, two bits for period p in (1, 2, 4, 8), then p bits
        p = 1 << ((desc >> (L - 3)) & 3)
        if L == 3 + p:
            pat = desc & ((1 << p) - 1)
            return sum(pat << (p * j) for j in range(16 // p))
    return None                          # not a valid description: D prints nothing
def shortest(dec, top):                  # run dec on every description up to top bits; keep the shortest
    best = {}
    for L in range(top + 1):
        for desc in range(1 << L):
            x = dec(desc, L)
            if x is not None and x not in best:
                best[x] = L              # L rises, so the first hit is the shortest
    return best
best = shortest(D, 17)
hist = sorted((L, list(best.values()).count(L)) for L in set(best.values()))
print(f"D: every one of {len(best)} files gets a description; shortest lengths in bits: {hist}")
assert hist == [(3 + p, 2 ** p - (2 ** (p // 2) if p > 1 else 0)) for p in (1, 2, 4, 8)] + [(17, 2 ** n - 2 ** 8)]  # files by period
for c in (1, 5, 8, 12):
    k = sum(1 for L in best.values() if L < n - c)
    print(f"D: files with a description shorter than {n - c} bits: {k}, bound 2^{n - c} - 1 = {(1 << (n - c)) - 1}")
    assert k <= (1 << (n - c)) - 1                   # brute force under the count
print(f"D: share of 16-bit files that shrink at all: {sum(1 for L in best.values() if L < 16) / (1 << 16):.6f}")
x0 = 0b0110100110010110
print(f"D: file 0101010101010101 (eight 1s, balanced) has shortest description {best[0x5555]} bits; file 0110100110010110 has {best[x0]}")
def D2(desc, L):                         # D with file x0 built in: '1' prints x0, '0' + d runs D on d
    if L == 1:
        return x0 if desc == 1 else None
    return D(desc, L - 1) if L >= 2 and desc >> (L - 1) == 0 else None
best2 = shortest(D2, 18)
k2 = sum(1 for L in best2.values() if L < 15)
print(f"mistake, file built into the decompressor: x0 now {best2[x0]} bit, 0101010101010101 now {best2[0x5555]}; shorter than 15 bits: {k2}, bound 32767")
assert k2 <= (1 << 15) - 1 and best2[0x5555] == best[0x5555] + 1
keep8 = [0] * 256
for x in range(1 << 16): keep8[x >> 8] += 1   # a 'compressor' that keeps the first 8 bits
print(f"mistake, keep the first 8 bits: every file shrinks to 8 bits, {sum(1 for v in keep8 if v)} outputs, {min(keep8)} files share each")

# ---- road 3: zip a text, then zip the zipped file ----
WORDS = ("the a of to and in is it that for on was with as at by this from or be "
         "we file data zip code bit byte short long once again table").split()
rng = SplitMix64(2026)
text = " ".join(WORDS[rng.next() % len(WORDS)] for _ in range(4000)).encode()
print(f"text: 4000 words drawn from {len(WORDS)} by SplitMix64 seed 2026, starting '{text[:40].decode()}'")
GEN = (f'w="{" ".join(WORDS)}".split()\ns=2026;M=2**64-1;t=[]\nfor _ in range(4000):s=s+0x9E3779B97F4A7C15&M;'
       'z=(s^s>>30)*0xBF58476D1CE4E5B9&M;z=(z^z>>27)*0x94D049BB133111EB&M;t.append(w[(z^z>>31)%32])\nprint(" ".join(t),end="")\n')
print(f"named program for the text: {len(GEN)} bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= {8 * len(GEN)} bits")
z1 = lz78_pack(text); z2 = lz78_pack(z1); z3 = lz78_pack(z2)
noise = bytes(rng.next() & 255 for _ in range(len(z1))); zn = lz78_pack(noise)
for name, a, b in (("text -> zip 1", text, z1), ("zip 1 -> zip 2", z1, z2), ("zip 2 -> zip 3", z2, z3), ("coin bytes -> zip", noise, zn)):
    print(f"{name}: {len(a)} bytes -> {len(b)} bytes, change {len(b) - len(a)}, ratio {len(b) / len(a):.4f}")
b1 = 8 * len(z1)
print(f"zip 1 is {b1} bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-{b1 // 10}")
print(f"byte entropy: text {byte_entropy(text):.4f}, zip 1 {byte_entropy(z1):.4f}, zip 2 {byte_entropy(z2):.4f}, coin bytes {byte_entropy(noise):.4f} bits per byte")
print(f"a coder using byte frequencies alone could bring zip 1 to about {byte_entropy(z1) / 8:.4f} of its size")
ok = lz78_unpack(z1) == text and lz78_unpack(lz78_unpack(z2)) == text and lz78_unpack(zn) == noise
print(f"every zip unpacks to its input exactly: {'yes' if ok else 'no'}")
assert ok                                          # lossless: the zipped file is a description
assert len(z1) < len(text) // 2 and len(z2) > len(z1) and len(zn) > len(noise)

# ---- road 4: a lopsided string is compressible, so a random one is balanced ----
N = 1000
def log2_choose(n, k):                   # log2 of n choose k, as a sum of logs
    return sum(log2((n - j) / (j + 1)) for j in range(k))
exact = [1]
for k in range(N):
    exact.append(exact[-1] * (N - k) // (k + 1))   # n choose k by whole numbers
for k in (500, 450, 400, 300, 100):
    cost = 10 + ceil(log2_choose(N, k))
    print(f"{N} bits with {k} ones: count in 10 bits, then which one of 2^{log2_choose(N, k):.4f} such strings: {cost} bits, saves {N - cost}")
    assert abs(log2_choose(N, k) - log2(exact[k])) < 1e-9   # sum of logs against whole numbers
tail = 2 * sum(exact[:401])
hoeff = 1 - 2 * 100 ** 2 / N * log2(e)            # log2 of 2 exp(-2 t^2 / n), t = 100
print(f"strings of {N} bits with at most 400 or at least 600 ones: share 2^{log2(tail) - N:.2f}; Hoeffding bound 2^{hoeff:.2f}")
assert log2(tail) - N < hoeff                      # exact count under an independent bound
print("ALL CHECKS PASS")
