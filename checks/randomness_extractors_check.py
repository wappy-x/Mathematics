# Randomness extractors -- the check behind the card.  Standard library only.
# Part 1: von Neumann's trick on a coin that lands heads 70% of the time.
# Part 2: 16-bit sensor readings with min-entropy 8, hashed to 2 bits by a random
# Toeplitz matrix (a 17-bit seed), measured against the leftover hash lemma.
from math import log2, sqrt
MASK, N16 = (1 << 64) - 1, 1 << 16

class SplitMix64:                            # small seeded generator, written out
    def __init__(self, seed):
        self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def flips(rng, n, p1, p2):                   # n coin flips, 1 = heads; odd flips use p1, even p2
    return [1 if (rng.next() >> 11) / 2.0 ** 53 < (p1 if i % 2 == 0 else p2) else 0 for i in range(n)]

def von_neumann(f, step):                    # pairs (f[i], f[i+1]); HT -> 0, TH -> 1, else nothing
    return [f[i + 1] for i in range(0, len(f) - 1, step) if f[i] != f[i + 1]]

def parity(v):                               # 1 if v has an odd number of 1 bits
    p = 0
    while v:
        p ^= v & 1
        v >>= 1
    return p

def wht(a, size):                            # Walsh-Hadamard: out[r] = sum_x a[x] * (-1)^parity(r AND x)
    a, h = a[:], 1
    while h < size:
        for i in range(0, size, 2 * h):
            for j in range(i, i + h):
                a[j], a[j + h] = a[j] + a[j + h], a[j] - a[j + h]
        h *= 2
    return a

def cells(F, z, m):                          # 2^m * weight landing in each output cell, Toeplitz seed z
    rows = [(z >> j) & 0xFFFF for j in range(m)]
    comb = [0] * (1 << m)
    for S in range(1, 1 << m):               # each mix of rows, XORed together
        low = S & -S
        comb[S] = comb[S ^ low] ^ rows[low.bit_length() - 1]
    return wht([F[c] for c in comb], 1 << m)

def dist(c, W, m):                           # statistical distance of the cells from uniform
    return sum(abs(v - W) for v in c) / (2 * W * (1 << m))

print("PART 1: a coin with Pr[heads] = 0.7")
p, q = 0.7, 0.3
print(f"one pair: HH {p * p:.4f}, HT {p * q:.4f}, TH {q * p:.4f}, TT {q * q:.4f}, discarded {p * p + q * q:.4f}")
print(f"von Neumann, exact: a pair gives a bit with chance {2 * p * q:.4f}; Pr[bit = 1] = {q * p / (2 * p * q):.4f}; bits per flip {p * q:.4f}")
print(f"per flip: min-entropy {-log2(p):.4f} bits, Shannon entropy {-(p * log2(p) + q * log2(q)):.4f} bits")
f = flips(SplitMix64(2026), 200000, p, p)
print("first 12 flips: " + "".join("H" if b else "T" for b in f[:12]) + " -> bits " + "".join(map(str, von_neumann(f[:12], 2))))
out = von_neumann(f, 2)
se = sqrt(0.25 / len(out))
print(f"simulated, 200000 flips, seed 2026: {len(out)} bits, {len(out) / 200000:.4f} per flip, share of 1s {sum(out) / len(out):.4f}, standard error {se:.4f}")
same = sum(out[i] == out[i + 1] for i in range(len(out) - 1)) / (len(out) - 1)
print(f"simulated: next bit equals the last one with share {same:.4f} (fair coins: 0.5000)")
ov = von_neumann(f, 1)
alt = sum(ov[i] != ov[i + 1] for i in range(len(ov) - 1)) / (len(ov) - 1)
print(f"mistake, overlapping pairs: {len(ov)} bits, each bit differs from the last with share {alt:.4f}")
dr_exact = p * 0.4 / (p * 0.4 + q * 0.6)
dr = von_neumann(flips(SplitMix64(7), 200000, 0.7, 0.6), 2)
dr_se = sqrt(dr_exact * (1 - dr_exact) / len(dr))
print(f"mistake, bias drifts 0.7 then 0.6 inside a pair: HT {p * 0.4:.4f}, TH {q * 0.6:.4f}, Pr[bit = 0] exact {dr_exact:.4f}, simulated {1 - sum(dr) / len(dr):.4f}")

print("PART 2: 16-bit readings = 32768 + a - b, with a, b uniform on 0..255")
w = [0] * N16
for d in range(-255, 256):
    w[32768 + d] = 256 - abs(d)              # chance (256 - |d|) / 65536
W, sq = sum(w), sum(v * v for v in w)
print(f"readings {sum(v > 0 for v in w)}, most likely chance {max(w)}/{W} = 1/{W // max(w)}, min-entropy {-log2(max(w) / W):.4f} bits")
print(f"collision probability {sq / W ** 2:.6f} = 1/{W ** 2 / sq:.1f}, Shannon entropy {-sum(v / W * log2(v / W) for v in w if v):.4f} bits")
F = wht(w, N16)
z0, x0 = 0b10110010011000101, 32768 + 37
r0, r1 = z0 & 0xFFFF, (z0 >> 1) & 0xFFFF
print(f"worked seed {z0:017b}: row 0 {r0:016b}, row 1 {r1:016b}")
print(f"reading {x0} = {x0:016b}: AND row 0 has {bin(r0 & x0).count('1')} ones, AND row 1 has {bin(r1 & x0).count('1')} ones -> output {parity(r1 & x0)}{parity(r0 & x0)}")
c0 = cells(F, z0, 2)
print(f"worked seed: weight in cells 00, 01, 10, 11 = {[v // 4 for v in c0]} of {W}, distance {dist(c0, W, 2):.6f}")
tot, worst, over, sumsq = 0, 0, 0, 0
for z in range(1 << 17):                     # every seed of the family, by the Fourier road
    c = cells(F, z, 2)
    s = sum(abs(v - W) for v in c)
    tot, worst, over, sumsq = tot + s, max(worst, s), over + (2 * s > W), sumsq + sum(v * v for v in c)
avg2, bound2, cpb = tot / (8 * W * (1 << 17)), 0.5 * 2.0 ** (-(8 - 2) / 2), 0.5 * sqrt(3 * sq / W ** 2)
print(f"all 131072 seeds, m = 2: average distance {avg2:.6f}, worst {worst / (8 * W):.6f}, seeds above 1/16: {over} ({100 * over / (1 << 17):.2f}%)")
print(f"leftover hash lemma: min-entropy bound {bound2:.6f}, collision-probability bound {cpb:.6f}")
pred = (1 << 17) * (12 * sq + 4 * W * W)     # universality: average of sum of squares, predicted
print(f"universality: sum over seeds of squared cell weights {sumsq}, predicted {pred}: {'equal' if sumsq == pred else 'different'}")
rng, agree, sup = SplitMix64(11), 0, [x for x in range(N16) if w[x]]
for _ in range(200):                         # direct count over the 511 readings, no Fourier
    z = rng.next() >> 47
    direct = [0] * 4
    for x in sup:
        direct[2 * parity(((z >> 1) & 0xFFFF) & x) + parity((z & 0xFFFF) & x)] += w[x]
    agree += [4 * v for v in direct] == cells(F, z, 2)
print(f"direct count against Fourier road, 200 sampled seeds: {agree} agree")
print("m | bound 0.5 * 2^(-(8 - m)/2) | sampled average over 1000 seeds")
sweep, bnds, rng = [], [], SplitMix64(5)
for m in range(1, 9):
    vals = [dist(cells(F, rng.next() >> (64 - 15 - m), m), W, m) for _ in range(1000)]
    sweep.append(sum(vals) / 1000)
    bnds.append(0.5 * 2.0 ** (-(8 - m) / 2))
    print(f"{m} | {bnds[-1]:.4f} | {sweep[-1]:.4f}")
print("figure, bound: " + ", ".join(f"{b:.4f}" for b in bnds))
print("figure, sampled: " + ", ".join(f"{s:.4f}" for s in sweep))
dead = [1 if 0x3000 <= x < 0x3400 and x % 4 == 0 else 0 for x in range(N16)]
fixed = [sum(dead[x] for x in range(N16) if x & 3 == c) for c in range(4)]
print(f"mistake, dead low bits (readings 12288, 12292, ..., 13308) with fixed 'keep the low 2 bits': cells {fixed}, distance {sum(abs(4 * v - 256) for v in fixed) / 2048:.4f}")
Fd = wht(dead, N16)
avgd = sum(dist(cells(Fd, z, 2), 256, 2) for z in range(1 << 17)) / (1 << 17)
print(f"same dead-bit readings, random seed: average distance {avgd:.6f}")
bad = (to00 := [x for x in range(N16) if parity(r0 & x) == 0 and parity(r1 & x) == 0])[:256]
bw = [0] * N16
for x in bad:
    bw[x] = 1
print(f"mistake, worked seed fixed in advance: it sends {len(to00)} readings to 00; the first 256 as a source, distance {dist(cells(wht(bw, N16), z0, 2), 256, 2):.4f}")
st = [1] * N16
st[0] = N16 - 1                              # stuck at 0 half the time, else any other reading
Ws = sum(st)
Hs = -sum(v / Ws * log2(v / Ws) for v in st)
Fs = wht(st, N16)
avgs = sum(dist(cells(Fs, z, 2), Ws, 2) for z in range(1 << 17)) / (1 << 17)
print(f"mistake, stuck sensor: Shannon entropy {Hs:.4f} bits, min-entropy {-log2(st[0] / Ws):.4f} bits, average distance {avgs:.6f}")
print(f"real size: k = 256 bits, eps = 2^-64 -> m = 256 - 2 * 64 + 2 = {256 - 128 + 2} bits")
assert abs(len(out) / 200000 - p * q) < 4 * sqrt(p * q / 200000)        # simulated rate against pq
assert abs(sum(out) / len(out) - 0.5) < 4 * se                          # simulated bits against exact 1/2
assert alt == 1.0                                                       # overlapping pairs alternate
assert abs(1 - sum(dr) / len(dr) - dr_exact) < 4 * dr_se                # drift: simulation against formula
assert sumsq == pred and agree == 200                                   # universality identity; two roads agree
assert avg2 <= cpb <= bound2 and abs(sweep[1] - avg2) < 0.003            # bound holds; sampling meets exact
assert all(s <= b for s, b in zip(sweep, bnds))                         # bound holds at every m
assert fixed == [256, 0, 0, 0] and len(bad) == 256 and avgs > 0.25      # no seed, or low min-entropy: fails
assert W == 256 * max(w) and sq == 256 ** 2 + 255 * 256 * 511 // 3     # min-entropy 8; sum of squares by formula
print("ALL CHECKS PASS")
