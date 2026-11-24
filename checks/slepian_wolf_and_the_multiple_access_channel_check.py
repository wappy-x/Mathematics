# Slepian-Wolf and the multiple-access channel -- the check behind the card.
# Standard library only: math gives logs, exp, cos, sqrt, pi; nothing knows a rate region.
# Part 1: two weather stations A and B log rain (1) or dry (0); half the days are wet,
# and B disagrees with A on 10% of days.  Part 2: two radios, power 1 each, share
# one receiver with noise power 1.  Random numbers: SplitMix64, seed 2026.
from math import log, log2, cos, sqrt, pi

P_DIS, LOW, HIGH, P1, P2, NOISE, MASK = 0.1, 0.40, 0.55, 1.0, 1.0, 1.0, (1 << 64) - 1
def h(p): return -p * log2(p) - (1 - p) * log2(1 - p)          # binary entropy, bits
def H(ps): return -sum(q * log2(q) for q in ps if q > 0)       # entropy of a list of chances, bits
def C(snr): return 0.5 * log2(1 + snr)                         # bits per pulse at a signal-to-noise ratio

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def unif(self): return ((self.next() >> 11) + 0.5) / 2.0**53

def log2_binoms(n):                          # log2 of C(n, j) for j = 0..n, built up
    out, v = [0.0], 0.0
    for j in range(n): v += log2((n - j) / (j + 1)); out.append(v)
    return out
def log2_add(a, b):                          # log2(2^a + 2^b)
    if a < b: a, b = b, a
    return a + log2(1 + 2.0 ** (b - a)) if b > -1e300 else a
def best_success(n, rate):                   # any scheme: 2^(nR) bin labels name at most
    lb, room, used, s = log2_binoms(n), n * rate, -1e308, 0.0   # 2^(nR) disagreement patterns,
    for j in range(n + 1):                   # so keep the likeliest: fewest disagreements
        lp = j * log2(P_DIS) + (n - j) * log2(1 - P_DIS)
        if log2_add(used, lb[j]) <= room + 1e-9:
            s += 2.0 ** (lb[j] + lp); used = log2_add(used, lb[j])
        elif room - used < 1e-9: return s
        else: return s + 2.0 ** (room + log2(1 - 2.0 ** (used - room)) + lp)
    return s

def binning_error(n, rate):                  # random bins, decoder takes the candidate with the
    lb, vol, e = log2_binoms(n), -1e308, 0.0  # fewest disagreements: union bound on the error
    for d in range(n + 1):
        vol = log2_add(vol, lb[d])
        lp = lb[d] + d * log2(P_DIS) + (n - d) * log2(1 - P_DIS)
        e += 2.0 ** (lp + min(0.0, vol - n * rate))
    return e
HCOL = [1, 2, 3, 4, 5, 6, 7]                 # Hamming (7,4): column i of the check matrix is i in binary
def syndrome(word):                          # word: 7 bits in an int; XOR of the columns of its 1s
    s = 0
    for i in range(7): s ^= HCOL[i] * (word >> i & 1)
    return s
def decode(a, sB):                           # town holds A's week and B's 3-bit label
    s = syndrome(a) ^ sB
    return a if s == 0 else a ^ (1 << (s - 1))

def lp(x, v): return -x * x / (2 * v * log(2)) - 0.5 * log2(2 * pi * v)   # log2 of pdf
def entropy_simpson(v, m=4000):              # -integral of f log2 f for a normal of variance v
    a, b = -14 * sqrt(v), 14 * sqrt(v); w = (b - a) / m
    f = lambda x: -2.0 ** lp(x, v) * lp(x, v)
    return w / 3 * sum((1 if k in (0, m) else 4 if k % 2 else 2) * f(a + k * w) for k in range(m + 1))

out = []
def show(label, x): out.append(f"{label:<46}{x:>12.6f}"); return x

# ---- Part 1: Slepian-Wolf ----
hA = show("H(A) = H(B), one station alone", H([0.5, 0.5]))
hAB_f = show("H(A,B) by 1 + h(0.1)", 1 + h(P_DIS))
c4 = [(1 - P_DIS) / 2, P_DIS / 2, P_DIS / 2, (1 - P_DIS) / 2]   # (A, B) = dry-dry, dry-wet, wet-dry, wet-wet
hAB_t = show("H(A,B) from the four cells " + " ".join(f"{q:.2f}" for q in c4), H(c4))
hBgA = show("H(B|A) = H(A,B) - H(A)", hAB_t - hA)
show("separate coding, no correlation used", 2 * hA); show("saving per day, 2 - H(A,B)", 2 * hA - hAB_t)
show("B, long-run bits per 365 days, at H(B|A)", 365 * hBgA)
show("both, long-run bits per 365 days, at H(A,B)", 365 * hAB_t)
show("one 365-day block with 171 bits: best success", best_success(365, 171 / 365))
show("  fewest bits for success 0.9 or more", next(k for k in range(366) if best_success(365, k / 365) >= 0.9))
ok = 0.0
for a in range(128):
    for b in range(128):
        d = bin(a ^ b).count("1"); pr = 2.0**-7 * P_DIS**d * (1 - P_DIS)**(7 - d)
        ok += pr * (decode(a, syndrome(b)) == b)
rng, weeks, hits = SplitMix64(2026), 100000, 0
for _ in range(weeks):
    a = rng.next() & 127; e = 0
    for i in range(7): e |= (rng.unif() < P_DIS) << i
    hits += decode(a, syndrome(a ^ e)) == a ^ e
wa, wb = 0b1001101, 0b1011101                 # days 1..7 are bits 0..6: A rains days 1,3,4,7
out.append(f"example week: A rains days 1,3,4,7, B days 1,3,4,5,7: B's label {syndrome(wb)},"
           f" A's label {syndrome(wa)}, town flips day {syndrome(wa) ^ syndrome(wb)}, right: {'yes' if decode(wa, syndrome(wb)) == wb else 'no'}")
show("Hamming label: B's rate 3/7 bits per day", 3 / 7)
p_ham = show("  weeks decoded right, all 2^14 week pairs", ok)
p_sim = show("  weeks decoded right, 100,000 simulated", hits / weeks)
p_best7 = show("  best any 3-bit label can do, n = 7", best_success(7, 3 / 7))
w12 = [P_DIS**bin(e).count("1") * (1 - P_DIS)**(12 - bin(e).count("1")) for e in range(4096)]
p_b12 = show("n = 12, rate 1/2: top 64 of 4,096 patterns", sum(sorted(w12, reverse=True)[:64]))
bs = [show(f"best success at rate {LOW:.2f}, n = {n}", best_success(n, LOW)) for n in (100, 1000, 2000)]
be = [show(f"binning error bound at rate {HIGH:.2f}, n = {n}", binning_error(n, HIGH)) for n in (100, 1000, 2000)]
c, cum, e100 = 1, 0, 0.0                      # n = 100 again, a second road: whole-number counts, no logs
for d in range(101): cum += c; e100 += c * P_DIS**d * (1 - P_DIS)**(100 - d) * min(1.0, cum / 2.0**(100 * HIGH)); c = c * (100 - d) // (d + 1)
show(f"B alone at rate {HIGH:.2f}, n = 1000: log2 success", 1000 * HIGH - 1000)

# ---- Part 2: the Gaussian multiple-access channel ----
c1, c2 = show("R1 at most C(P1/N)", C(P1 / NOISE)), show("R2 at most C(P2/N)", C(P2 / NOISE))
csum = show("R1 + R2 at most C((P1+P2)/N)", C((P1 + P2) / NOISE))
r2c = show("corner: R2 = C(P2/(P1+N)), radio 1 as noise", C(P2 / (P1 + NOISE)))
show("corner: R1 = C(P1/N), radio 2 subtracted", c1)
s_sum = show("sum by Simpson: h(Y) - h(Z)", entropy_simpson(3) - entropy_simpson(1))
s_r2 = show("R2 by Simpson: h(Y) - h(Y|X2)", entropy_simpson(3) - entropy_simpson(2))
rng, n_mc, acc = SplitMix64(2026), 200000, [[0.0, 0.0], [0.0, 0.0]]
for _ in range(n_mc):
    g = []
    for _ in range(2):
        u1, u2 = rng.unif(), rng.unif(); r = sqrt(-2 * log(u1))
        g += [r * cos(2 * pi * u2), r * cos(2 * pi * u2 - pi / 2)]
    x1, x2, z = g[0], g[1], g[2]; y = x1 + x2 + z
    for k, s in enumerate((lp(z, 1) - lp(y, 3), lp(y - x2, 2) - lp(y, 3))):
        acc[k][0] += s; acc[k][1] += s * s
mc = [(m0 / n_mc, sqrt((m1 / n_mc - (m0 / n_mc)**2) / n_mc)) for m0, m1 in acc]
show("sum by simulation, 200,000 pulses", mc[0][0]); show("  its standard error", mc[0][1])
show("R2 corner by simulation", mc[1][0]); show("  its standard error", mc[1][1])
show("both treat the other as noise: sum", 2 * C(P1 / (P2 + NOISE)))
show("take turns, power 1 each: sum", 0.5 * C(P1 / NOISE) + 0.5 * C(P2 / NOISE))
show("take turns, power 2 in each turn: sum", 0.5 * C(2 * P1 / NOISE) + 0.5 * C(2 * P2 / NOISE))
show("wrong: both at single-user rate 0.5: sum", c1 + c2)
show("one sender, same pulse on both radios: C(4)", C((sqrt(P1) + sqrt(P2))**2 / NOISE))
show("sum rate x 1,000 pulses a second", 1000 * csum)
[show(f"try: HIGH = 0.50, binning bound, n = {n}", binning_error(n, 0.50)) for n in (100, 1000, 2000)]
[show(f"try: LOW = 0.45, best success, n = {n}", best_success(n, 0.45)) for n in (1000, 2000)]
show("try: P_DIS = 0.2, H(A,B) = 1 + h(0.2)", 1 + h(0.2)); show("  week-long label decodes", 0.8**7 + 7 * 0.2 * 0.8**6)
for line in out: print(line)
X0, Y0, S1, X0M, S2 = 42, 230, 150, 300, 320  # figure: pixels per bit, left and right panels
print(f"figure, SW corners ({X0 + S1 * 1:.1f},{Y0 - S1 * hBgA:.1f}) ({X0 + S1 * hBgA:.1f},{Y0 - S1 * 1:.1f});"
      f" MAC corners ({X0M + S2 * c1:.1f},{Y0 - S2 * r2c:.1f}) ({X0M + S2 * r2c:.1f},{Y0 - S2 * c2:.1f})")
assert abs(hAB_f - hAB_t) < 1e-12 and abs(hAB_t - 1.468996) < 1e-6          # two roads to H(A,B)
assert abs(p_ham - (0.9**7 + 7 * 0.1 * 0.9**6)) < 1e-12 and abs(p_ham - p_best7) < 1e-12
assert abs(p_sim - p_ham) < 4 * sqrt(p_ham * (1 - p_ham) / weeks)         # simulation within 4 SE
assert abs(s_sum - 0.5 * log2(3)) < 1e-9 and abs(s_r2 - (csum - c1)) < 1e-9  # Simpson against closed form
assert abs(mc[0][0] - csum) < 4 * mc[0][1] and abs(mc[1][0] - r2c) < 4 * mc[1][1]
assert abs(p_b12 - best_success(12, 0.5)) < 1e-12 and bs[2] < bs[1] < bs[0] and be[2] < be[1] < be[0]
assert abs(be[0] - e100) < 1e-9                                              # binning bound: logs against whole numbers
print("ALL CHECKS PASS")
