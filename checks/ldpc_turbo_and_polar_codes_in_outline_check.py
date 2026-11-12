# LDPC, turbo and polar codes in outline -- the check behind the card.  Standard library only.
# Part 1: the Tanner graph of the Hamming (7,4) code; belief propagation (min-sum and
# sum-product) on one received weather reading, against all 16 codewords enumerated.
# Part 2: Viterbi on the (7,5) convolutional code, against all 256 messages enumerated.
# Part 3: polar channels on an erasure channel, recursion against all 256 erasure patterns.
# Part 4: a (3,6) LDPC code of 504 bits against Hamming frames on a bit-flipping channel,
# simulated with SplitMix64, seed 2026; the rate-1/2 limit found by bisection on 1 - h(p).
from math import tanh, atanh, log, log2, exp, sqrt, prod
M64, state = 2 ** 64 - 1, 2026
def draw():                                   # SplitMix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return z ^ (z >> 31)
unif = lambda: (draw() >> 11) / 2 ** 53; below = lambda m: ((draw() >> 32) * m) >> 32
def bp(checks, n, L, rounds, rule, stop):    # belief propagation on a Tanner graph
    msg = [[0] * len(r) for r in checks]
    for it in range(rounds + 1):
        tot = list(L)
        for c, row in enumerate(checks):
            for t, v in enumerate(row): tot[v] += msg[c][t]
        hard = [1 if x < 0 else 0 for x in tot]
        if it == rounds or (stop and all(sum(hard[v] for v in r) % 2 == 0 for r in checks)): return hard, it, msg, tot
        msg = [rule([tot[v] - msg[c][t] for t, v in enumerate(row)]) for c, row in enumerate(checks)]
def minsum(off):                              # sign of the others times (smallest other size - off)
    def rule(ins):
        out = []
        for t in range(len(ins)):
            o = [x for u, x in enumerate(ins) if u != t]
            out.append((-1) ** sum(x < 0 for x in o) * max(min(abs(x) for x in o) - off, 0))
        return out
    return rule
def sumprod(ins): return [2 * atanh(prod(tanh(x / 2) for u, x in enumerate(ins) if u != t)) for t in range(len(ins))]
f2 = lambda v: " ".join(f"{x:+.2f}" for x in v); s = lambda v: "".join(map(str, v)); wrong = lambda v: sum(a != b for a, b in zip(v, SENT))
# ---- part 1 ----
H = [[1, 0, 1, 0, 1, 0, 1], [0, 1, 1, 0, 0, 1, 1], [0, 0, 0, 1, 1, 1, 1]]
HAM = [[v for v in range(7) if r[v]] for r in H]
SENT, LLR = [0, 1, 1, 0, 0, 1, 1], [4, -5, 1, 3, -1, -4, -6]
hard0 = [1 if x < 0 else 0 for x in LLR]
syn = [sum(hard0[v] for v in r) % 2 for r in HAM]; pos = syn[0] + 2 * syn[1] + 4 * syn[2]
hamfix = [b ^ (v + 1 == pos) for v, b in enumerate(hard0)]
ms, _, msg1, tot1 = bp(HAM, 7, LLR, 1, minsum(0), False)
sp1 = bp(HAM, 7, LLR, 1, sumprod, False)[3]; sp5 = bp(HAM, 7, LLR, 5, sumprod, False)[3]
def marg(checks):                             # exact confidences: every word meeting the checks, weighted by L
    ws = [w for w in ([(x >> (6 - v)) & 1 for v in range(7)] for x in range(128)) if all(sum(w[v] for v in r) % 2 == 0 for r in checks)]
    wt = [exp(sum(LLR[v] / 2 * (1 - 2 * w[v]) for v in range(7))) for w in ws]
    return ws, wt, [log(sum(q for q, w in zip(wt, ws) if w[v] == 0) / sum(q for q, w in zip(wt, ws) if w[v] == 1)) for v in range(7)]
words, wt, exact = marg(HAM)
ml = words[max(range(len(words)), key=lambda i: wt[i])]
print(f"Tanner graph: checks A, B, C on bits {[[v + 1 for v in r] for r in HAM]}; {sum(map(len, HAM))} edges; {len(words)} codewords")
print(f"sent {s(SENT)}; confidences L = {LLR}; hard decisions {s(hard0)}, wrong at bits {[v + 1 for v in range(7) if hard0[v] != SENT[v]]}")
print(f"Hamming syndrome {s(syn)} -> flips bit {pos} -> {s(hamfix)}, wrong bits {wrong(hamfix)}")
for c in range(3): print(f"min-sum round 1, check {'ABC'[c]} to bits {[v + 1 for v in HAM[c]]}: {msg1[c]}")
print(f"min-sum totals {tot1} -> {s(ms)}, wrong bits {wrong(ms)}")
print(f"sum-product totals, 1 round  {f2(sp1)}\nsum-product totals, 5 rounds {f2(sp5)}\nexact, all 16 codewords      {f2(exact)}")
print(f"most likely codeword {s(ml)}; bitwise exact decisions {s([1 if x < 0 else 0 for x in exact])}")
TREE = [HAM[0], [1, 2, 5], [3, 4]]; tr = bp(TREE, 7, LLR, 5, sumprod, False)[3], marg(TREE)[2]   # less edges 7B, 6C, 7C: no loop
print(f"tree, checks on bits {[[v + 1 for v in r] for r in TREE]}: sum-product, 5 rounds {f2(tr[0])}; exact {f2(tr[1])}")
# ---- part 2 ----
def conv(u):                                  # (7,5): outputs u+a+b and u+b, a and b the last two inputs
    a = b = 0; out = []
    for x in u + [0, 0]: out += [x ^ a ^ b, x ^ b]; a, b = x, a
    return out
def viterbi(r):
    M, back, rows = [0, 99, 99, 99], [], []   # state 2a + b
    for t in range(len(r) // 2):
        new, arg = [99] * 4, [None] * 4
        for st in range(4):
            a, b = st >> 1, st & 1
            for x in (0, 1):
                d = M[st] + ((x ^ a ^ b) != r[2 * t]) + ((x ^ b) != r[2 * t + 1])
                if d < new[2 * x + a]: new[2 * x + a], arg[2 * x + a] = d, (st, x)
        M = new; back.append(arg); rows.append(M)
    st, u = 0, []
    for arg in reversed(back): st, x = arg[st]; u.insert(0, x)
    return u[:-2], rows
MSG = [0, 0, 0, 1, 0, 1, 1, 1]
cw = conv(MSG); allm = [[(m >> (7 - i)) & 1 for i in range(8)] for m in range(256)]
dfree = min(sum(conv(m)) for m in allm[1:])
print(f"message {s(MSG)} (23 degrees C); codeword {s(cw)}; free distance by enumeration {dfree}")
vres = []
for ps in ([4, 13], [7, 8, 9]):
    r = [x ^ (i + 1 in ps) for i, x in enumerate(cw)]; dec, rows = viterbi(r)
    ds = [sum(a != b for a, b in zip(conv(m), r)) for m in allm]; best = min(ds)
    vres.append((dec, allm[ds.index(best)], ds.count(best)))
    print(f"errors at {ps}: received {s(r)}; Viterbi {s(dec)} (={int(s(dec), 2)}), metric {rows[-1][0]}; enumeration best {s(allm[ds.index(best)])} at distance {best}, {ds.count(best)} tied")
    if len(ps) == 2: print("  path metrics by step, states 00 01 10 11: " + " | ".join(" ".join(str(m) if m < 99 else "-" for m in row) for row in rows))
# ---- part 3 ----
def polar(n, e):
    z = [e]
    for _ in range(n): z = [w for q in z for w in (2 * q - q * q, q * q)]   # worse, better
    return z
G = [sum(1 << j for j in range(8) if j & ~i == 0) for i in range(8)]   # rows of the 8 x 8 transform, as bit masks
cnt = [0] * 8                                 # erasure patterns (each 1 in 256) that leave u_i undecided
for er in range(256):
    for i in range(8):
        for tail in range(1 << (7 - i)):
            x = G[i]
            for k in range(7 - i): x ^= G[i + 1 + k] * (tail >> k & 1)
            if x & ~er & 255 == 0: cnt[i] += 1; break
z8 = polar(3, 0.5); info = sorted(sorted(range(8), key=lambda i: z8[i])[:4])
print(f"polar N = 8, erasure 0.5: recursion x 256 {[int(q * 256) for q in z8]}; enumeration {cnt}; best 4 channels {[i + 1 for i in info]}")
for n in (10, 20):
    z = polar(n, 0.5)
    print(f"polar N = 2^{n}: share nearly perfect (z < 0.001) {sum(q < 1e-3 for q in z) / 2 ** n:.4f}, nearly useless (z > 0.999) {sum(q > 0.999 for q in z) / 2 ** n:.4f}, in between {sum(1e-3 <= q <= 0.999 for q in z) / 2 ** n:.4f}")
# ---- part 4 ----
NB, J, K, LD, basis = 504, 3, 6, [], {}
for band in range(J):                         # Gallager's construction: three shuffled bands
    perm = list(range(NB))
    for i in range(NB - 1, 0, -1) if band else []:
        j = below(i + 1); perm[i], perm[j] = perm[j], perm[i]
    LD += [perm[c * K:(c + 1) * K] for c in range(NB // K)]
for row in LD:
    r = sum(1 << v for v in row)
    while r and r.bit_length() - 1 in basis: r ^= basis[r.bit_length() - 1]
    if r: basis[r.bit_length() - 1] = r
kb = NB - len(basis)
h = lambda p: -p * log2(p) - (1 - p) * log2(1 - p); lo, hi = 0.01, 0.5
for _ in range(60): lo, hi = ((lo + hi) / 2, hi) if h((lo + hi) / 2) < 0.5 else (lo, (lo + hi) / 2)
print(f"LDPC: {NB} bits, {len(LD)} checks, 3 per bit, 6 per check, rank {len(basis)}, {kb} data bits, rate {kb / NB:.4f}; Hamming frame: 63 blocks, 252 data bits, 441 bits sent; rate-1/2 limit p = {lo:.4f}")
PS, BL, FR, res = [0.02, 0.04, 0.06, 0.08, 0.10, 0.12], 100, 1000, []
for p in PS:
    fail = sum(any(bp(LD, NB, [-4 if unif() < p else 4 for _ in range(NB)], 50, minsum(1), True)[0]) for _ in range(BL))
    hf = sum(sum(sum(unif() < p for _ in range(7)) > 1 for _ in range(63)) > 0 for _ in range(FR))   # draw all 441 bits
    exact_h = 1 - ((1 - p) ** 7 + 7 * p * (1 - p) ** 6) ** 63
    res.append((fail / BL, hf / FR, exact_h))
    print(f"p {p:.2f}  capacity {1 - h(p):.4f}  LDPC 504-bit frames failed {fail}/{BL}  Hamming 63-block frames failed {hf}/{FR} = {hf / FR:.3f} (exact {exact_h:.3f})")
plain = sum(any(bp(LD, NB, [-4 if unif() < 0.04 else 4 for _ in range(NB)], 50, minsum(0), True)[0]) for _ in range(BL))
print(f"what breaks, min-sum without the offset at p 0.04: {plain}/{BL} frames failed")
print(f"chart, LDPC {', '.join(f'{r[0]:.2f}' for r in res)}; Hamming exact {', '.join(f'{r[2]:.3f}' for r in res)}")
print(f"figure, bits at x = {[40 + 47 * v for v in range(7)]}, y = 50; checks A, B, C at x = {[87, 181, 275]}, y = 190; edges {' '.join(f'{v + 1}{chr(65 + c)}' for c in range(3) for v in HAM[c])}")
se = lambda f, m: sqrt(max(f * (1 - f), 1 / m) / m)
assert ms == SENT and ml == SENT and [1 if x < 0 else 0 for x in exact] == SENT and hamfix != SENT
assert all(abs(a - b) < 1e-9 for a, b in zip(*tr))   # on a tree, belief propagation meets the exact confidences
assert vres[0][0] == MSG == vres[0][1] and vres[0][2] == 1 and dfree == 5 and vres[1][0] == vres[1][1] != MSG
assert cnt == [round(q * 256) for q in z8] and abs(lo - 0.110028) < 1e-5
assert all(abs(r[1] - r[2]) < 4 * se(r[2], FR) for r in res) and res[1][0] < res[1][2] / 10
pe = [sum(prod((1 if b >> j & 1 else exp(LLR[v])) / (1 + exp(LLR[v])) for j, v in enumerate((1, 5, 6))) for b in range(8) if bin(b).count("1") % 2 == q) for q in (0, 1)]
assert abs(sumprod([LLR[v] for v in HAM[1]])[1] - log(pe[0] / pe[1])) < 1e-9   # check B to bit 3: rule against its 8 parity cases
print("ALL CHECKS PASS")
