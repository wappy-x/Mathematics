# Hamming (7,4) and Reed-Solomon -- the check behind the card.  Standard library only.
# A disc track holds the text "CD": two bytes, four nibbles (4-bit halves).  Code A:
# each nibble becomes 7 bits by Hamming (7,4).  Code B: the four nibbles are symbols
# of GF(16), and the disc stores 8 values of the polynomial they define.
from math import log2

def bits(v, n): return [(v >> (n - 1 - i)) & 1 for i in range(n)]      # high bit first
def mat_vec(M, v): return [sum(r[i] * v[i] for i in range(len(v))) % 2 for r in M]
def yn(claim): return "yes" if claim else "no"
G = [[1, 1, 0, 1], [1, 0, 1, 1], [1, 0, 0, 0], [0, 1, 1, 1],          # positions 1..7:
     [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]                         # chk1 chk2 m1 chk4 m2 m3 m4
H = [[(j >> k) & 1 for j in range(1, 8)] for k in range(3)]   # column j is j in binary
def ham_enc(nib): return mat_vec(G, bits(nib, 4))
def syndrome(r): s = mat_vec(H, r); return s[0] + 2 * s[1] + 4 * s[2]
def ham_dec(r):                                               # road 1: the syndrome
    r = r[:]; s = syndrome(r)
    if s: r[s - 1] ^= 1
    return 8 * r[2] + 4 * r[4] + 2 * r[5] + r[6], s
def dist(a, b): return sum(x != y for x, y in zip(a, b))
BOOK = [ham_enc(m) for m in range(16)]
def ham_near(r): return min(range(16), key=lambda m: dist(BOOK[m], r))  # road 2: try all 16
def flip(word, places): return [b ^ (i + 1 in places) for i, b in enumerate(word)]

def gmul(a, b):                    # GF(16): shift and add, wrap by x^4 + x + 1 (binary 10011)
    p = 0
    for _ in range(4):
        if b & 1: p ^= a
        b >>= 1; a <<= 1
        if a & 16: a ^= 0b10011
    return p
def ginv(a): return [b for b in range(1, 16) if gmul(a, b) == 1][0]
PTS = [1]
while len(PTS) < 8: PTS.append(gmul(PTS[-1], 2))              # a^0 .. a^7, with a = 2
def peval(c, x, mul=gmul, add=lambda u, v: u ^ v):            # Horner's rule
    y = 0
    for co in reversed(c): y = add(mul(y, x), co)
    return y
def rs_enc(msg): return [peval(msg, x) for x in PTS]
def interp(xs, ys):                # the one cubic through 4 points, by Lagrange, over GF(16)
    out = [0] * 4
    for i in range(4):
        num, den = [1], 1
        for j in range(4):
            if j != i:             # multiply num by (x + xs[j]); minus is plus here
                num = [(num[k - 1] if k else 0) ^ (gmul(num[k], xs[j]) if k < len(num) else 0)
                       for k in range(len(num) + 1)]
                den = gmul(den, xs[i] ^ xs[j])
        f = gmul(ys[i], ginv(den))
        out = [o ^ gmul(f, c) for o, c in zip(out, num)]
    return out
def rs_fit(r):                     # road 2: fit every 4 of the 8 values, keep a fit within 2
    for s in range(256):
        idx = [i for i in range(8) if s >> i & 1]
        if len(idx) == 4:
            m = interp([PTS[i] for i in idx], [r[i] for i in idx])
            if dist(rs_enc(m), r) <= 2: return m
    return None
ALL = [[m >> 12, (m >> 8) & 15, (m >> 4) & 15, m & 15] for m in range(1 << 16)]
RSBOOK = [rs_enc(m) for m in ALL]
def rs_near(r):                    # road 1: nearest of all 65,536 codewords
    ds = [dist(c, r) for c in RSBOOK]; best = min(ds)
    return ALL[ds.index(best)], best, ds.count(best)

def cut(track, w): return [track[i:i + w] for i in range(0, len(track), w)]
def show(nibs):
    bs = [16 * nibs[i] + nibs[i + 1] for i in range(0, len(nibs), 2)]
    return f"{bs} " + ("".join(chr(b) if 32 <= b < 127 else "?" for b in bs))
msg = [n for ch in b"CD" for n in (ch >> 4, ch & 15)]
print(f"track text CD = bytes {show(msg)} = nibbles {msg}")
print(f"nibble 4 = data bits {bits(4, 4)} -> Hamming codeword {ham_enc(4)}")
r = flip(ham_enc(4), {6})
print(f"flip position 6: {r}; checks (1,3,5,7) (2,3,6,7) (4,5,6,7) = {mat_vec(H, r)}; syndrome {syndrome(r)}")
dmin = min(dist(BOOK[a], BOOK[b]) for a in range(16) for b in range(a + 1, 16))
words = [flip(c, {p}) for c in BOOK for p in range(8)]
agree = all(ham_dec(w)[0] == ham_near(w) for w in words)
print(f"Hamming: H times every codeword = 0: {yn(all(syndrome(c) == 0 for c in BOOK))}; "
      f"min distance {dmin}, fixes {(dmin - 1) // 2}, detects {dmin - 1}")
print(f"Hamming: 16 codewords x 8 words within one flip, all different: {len(set(map(tuple, words)))} = 2^7; "
      f"syndrome = nearest on all {len(words)}: {yn(agree)}")
print(f"Hamming: flip positions 1, 2, 3 of codeword 4: syndrome {syndrome(flip(ham_enc(4), {1, 2, 3}))}, a weight-3 codeword")
track = [b for n in msg for b in ham_enc(n)]
print(f"Hamming track, 28 bits: {''.join(map(str, track))}")
SCARS = (("speck at bit 6", {6}), ("scratch, bits 12-13", {12, 13}),
         ("scratch, bits 10-14", {10, 11, 12, 13, 14}))
for name, places in SCARS:
    out = [ham_dec(b) for b in cut(flip(track, places), 7)]
    print(f"  {name:<20} syndromes {[o[1] for o in out]} -> {show([o[0] for o in out])}")
b2 = flip(track, {12, 13})[7:14]; fixed = flip(b2, {syndrome(b2)})
print(f"  block 2 under the scratch: sent {track[7:14]}, read {b2}, 'repaired' to {fixed} = nibble {ham_dec(b2)[0]}")
code = rs_enc(msg)
terms = [gmul(c, x) for c, x in zip(msg, [1, 2, 4, 8])]
print(f"GF(16): points a^0..a^7 = {PTS}; 1/a = {ginv(2)}; m(1) = {' + '.join(map(str, msg))} = {code[0]}; m(a) = {' + '.join(map(str, terms))} = {code[1]}")
print(f"RS(8,4): message {msg} -> codeword {code}, 32 bits")
wts = [sum(v != 0 for v in c) for c in RSBOOK[1:]]
print(f"RS: {len(RSBOOK)} codewords; least weight of the {len(wts)} nonzero ones = {min(wts)} = 8 - 4 + 1, so fixes 2 symbols")
rs_track = [b for s in code for b in bits(s, 4)]
found = {}
for name, places in SCARS + (("three symbols, case 1", {1, 13, 25}), ("three symbols, case 2", {1, 6, 25})):
    got = [int("".join(map(str, s)), 2) for s in cut(flip(rs_track, places), 4)]
    near, d, ties = rs_near(got); fit = rs_fit(got)
    found[name] = (near, d, fit)
    print(f"  {name:<21} reads {got}: nearest at {d} ({ties} tied) {show(near)}; "
          f"fit within 2: {'none' if fit is None else show(fit)}")
modbook = [[peval(m, x, lambda u, v: u * v % 16, lambda u, v: (u + v) % 16) for x in PTS] for m in ALL]
zero = [ALL[i] for i in range(1, 1 << 16) if not any(modbook[i])]
print(f"mistake, nibbles as hours mod 16: message {zero[0]} also writes {modbook[0]}; {len(zero)} such messages")

state = 2026                       # SplitMix64, seed 2026: the same flips in Python and Rust
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64; z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2**53
p, trials, wrong = 0.01, 200000, 0
for t in range(trials):
    sent = ham_enc(t % 16)
    if ham_dec([b ^ (rand() < p) for b in sent])[0] != t % 16: wrong += 1
fail = 1 - (1 - p) ** 7 - 7 * p * (1 - p) ** 6
se = (fail * (1 - fail) / trials) ** 0.5
print(f"flip chance {p}: raw nibble wrong {1 - (1 - p) ** 4:.6f}; Hamming block wrong {fail:.6f} "
      f"by formula, {wrong / trials:.6f} in {trials} blocks")
print(f"rate 4/7 = {4 / 7:.4f}; capacity at p = {p} is {1 + p * log2(p) + (1 - p) * log2(1 - p):.4f}; "
      f"CD: C1 RS(32,28) and C2 RS(28,24) have distance {32 - 28 + 1} and {28 - 24 + 1}, fix {(32 - 28) // 2} each")
def block_fail(q): return 1 - (1 - q) ** 7 - 7 * q * (1 - q) ** 6
print(f"try: Hamming block wrong at flip chance 0.001 is {block_fail(0.001):.6f}, at 0.1 is {block_fail(0.1):.6f}")
got = [int("".join(map(str, s)), 2) for s in cut(flip(rs_track, set(range(9, 17))), 4)]
print(f"try: scratch, bits 9-16: Hamming reads {show([ham_dec(b)[0] for b in cut(flip(track, set(range(9, 17))), 7)])}; "
      f"RS nearest {show(rs_near(got)[0])}, fit {show(rs_fit(got))}")

assert dmin == 3 and agree                                    # exhaustive vs syndrome
assert len(set(map(tuple, words))) == 2 ** 7                  # the 16 balls fill all 7-bit words
assert [r[0] for r in [ham_dec(b) for b in cut(flip(track, {6}), 7)]] == msg
assert min(wts) == 8 - 4 + 1                                  # exhaustive vs n - k + 1
for name, _ in SCARS:                                         # two RS decoders, one answer
    assert found[name][0] == msg and found[name][2] == msg
assert found["three symbols, case 1"][2] is None and found["three symbols, case 2"][2] not in (None, msg)
assert abs(wrong / trials - fail) < 4 * se                    # simulation vs formula
print("ALL CHECKS PASS")
