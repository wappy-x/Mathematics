# Arithmetic and Lempel-Ziv coding -- the check behind the card.  Standard library
# only: math.log2 and math.ceil know nothing about compression.  A weather station
# sends C (cloudy), S (sunny) or R (rain) each day.  Arithmetic coding turns a month
# into one interval and one binary fraction; LZ78 builds a dictionary of phrases.
from math import log2, ceil

NAMES = "CSR"                            # cloudy, sunny, rain
F = [8, 1, 1]                            # chances in tenths: 0.8, 0.1, 0.1
CUM = [0, 8, 9]                          # where each slice starts, in tenths
MONTH = "CCSCCCCCRCCCCCCSCCCCRCCCCCCSCR"  # 30 days: 24 cloudy, 3 sunny, 3 rain
HUFF = [1, 2, 2]                         # Huffman lengths for 0.8, 0.1, 0.1
SEED = 2026

def encode(msg):                         # interval [L/D, (L+W)/D), then the code
    L, W, D = 0, 1, 1
    for ch in msg:
        s = NAMES.index(ch)
        L, W, D = 10 * L + W * CUM[s], W * F[s], 10 * D
    k = 0
    while W << k < D:                    # smallest k with 2^-k <= width
        k += 1
    x = -(-(L << k) // D)                # first k-bit fraction at or above L/D
    assert x * D < (L + W) << k          # ... and it lies inside the interval
    return L, W, D, k, x

def decode(x, k, n):                     # follow the point x/2^k down the splits;
    num, den, out = x, 1 << k, ""        # num/den = where it sits inside the interval
    for _ in range(n):
        s = next(s for s in (2, 1, 0) if CUM[s] * den <= 10 * num)
        num, den, out = 10 * num - CUM[s] * den, F[s] * den, out + NAMES[s]
    return out

def lz78(x, m):                          # phrases = earlier phrase + one new symbol
    trie, i, bits, out = [[0] * m], 0, 0, []
    while i < len(x):
        node = 0
        while i < len(x) and trie[node][x[i]]:
            node, i = trie[node][x[i]], i + 1
        bits += (len(trie) - 1).bit_length()          # index: ceil(log2 of phrases so far + 1)
        if i < len(x):
            trie[node][x[i]] = len(trie)
            trie.append([0] * m)
            out.append((node, x[i]))
            bits, i = bits + 2, i + 1                 # new symbol: 2 bits
        else:
            out.append((node, -1))                    # last phrase already known
    return out, bits

def unlz78(pairs):                       # rebuild the phrases from the pairs
    phrases = [[]]
    for j, s in pairs:
        phrases.append(phrases[j] + ([s] if s >= 0 else []))
    return phrases[1:]

MASK = (1 << 64) - 1
def splitmix64(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

def weather(n, rows):                    # synthetic days; rows[t] = chances after state t
    state, today, out = SEED, 0, []
    for _ in range(n):
        state, z = splitmix64(state)
        u = (z >> 11) / 2.0**53          # uniform in [0, 1); pick the first slice past u
        today = next((s for s in range(3) if u < sum(rows[today][:s + 1])), 2)
        out.append(today)
    return out

P = [f / 10 for f in F]
H = sum(p * log2(1 / p) for p in P)
L, W, D, k, x = encode(MONTH)
ideal = sum(log2(10 / F[NAMES.index(c)]) for c in MONTH)
huff = sum(HUFF[NAMES.index(c)] for c in MONTH)
print(f"chances 0.8, 0.1, 0.1: surprise {log2(1.25):.4f}, {log2(10):.4f} bits; H = {H:.4f} bits a day; "
      f"Huffman lengths {HUFF}, {sum(p * l for p, l in zip(P, HUFF)):.4f} a day")
print(f"month: {MONTH}: {MONTH.count('C')} C, {MONTH.count('S')} S, {MONTH.count('R')} R")
print(f"width = 0.8^24 x 0.1^6 = {W}/10^30, 1 in {D / W:.1f}; log2(1/width) = {ideal:.4f}")
print(f"arithmetic code: {k} bits, {x:0{k}b}; bits per day {k / 30:.4f}")
print(f"Huffman {huff} bits; two fixed bits a day {2 * 30}; 30 x H = {30 * H:.4f}; 10^30 is about 2^{log2(D):.1f}")
lo, hi, rows5 = 0.0, 1.0, []
for c in MONTH[:5]:
    s = NAMES.index(c)
    lo, hi = lo + (hi - lo) * CUM[s] / 10, lo + (hi - lo) * (CUM[s] + F[s]) / 10
    rows5.append((c, lo, hi))
print("first 5 days: " + "; ".join(f"{c} [{a:.5f}, {b:.5f})" for c, a, b in rows5))
L5, W5, D5, k5, x5 = encode(MONTH[:5])
print(f"5 days: width {W5 / D5:.5f}, log2(1/width) {log2(D5 / W5):.4f}, code {x5:0{k5}b} = {x5 / 2**k5:.5f}, "
      f"Huffman {sum(HUFF[NAMES.index(c)] for c in MONTH[:5])} bits")
print("figure, x = 30 + 300 v: " + " ".join(f"{30 + 300 * a:.1f}-{30 + 300 * b:.1f}" for _, a, b in rows5)
      + f" code {30 + 300 * x5 / 2**k5:.1f}")
def by_formula(n):                       # expected bits per day, grouped by counts
    e, coef = 0.0, 2.0**n
    for a in range(n + 1):               # a cloudy days, n - a others: coef = C(n, a) 2^(n-a)
        e += coef * 0.8**a * 0.1**(n - a) * ceil(a * log2(1.25) + (n - a) * log2(10))
        coef = coef * (n - a) / (a + 1) / 2
    return e / n
total, ok = 0.0, 0                       # every 5-day message, encoded and decoded
for m in range(3**5):
    msg = "".join(NAMES[m // 3**j % 3] for j in range(5))
    Lm, Wm, Dm, km, xm = encode(msg)
    total, ok = total + Wm / Dm * km, ok + (decode(xm, km, 5) == msg)
print(f"all 243 five-day messages: {ok} decode; average {total / 5:.4f} bits a day; formula {by_formula(5):.4f}")
print("expected bits a day, coding n days as one: " + ", ".join(f"n={n} {by_formula(n):.4f}" for n in (1, 2, 5, 10, 30, 100)))
pairs, bits = lz78([NAMES.index(c) for c in MONTH], 3)
show = ["".join(NAMES[s] for s in p) + f"=({j},{NAMES[s] if s >= 0 else '-'}):{i.bit_length() + 2 * (s >= 0)}"
        for i, (p, (j, s)) in enumerate(zip(unlz78(pairs), pairs))]   # phrase = (earlier, new):bits
print(f"LZ78 on the month: {len(pairs)} phrases, {bits} bits: " + " ".join(show))
SPELL = [[0.95, 0.025, 0.025], [0.2, 0.8, 0.0], [0.2, 0.0, 0.8]]   # weather in spells
INDEP = [P, P, P]                                                  # every day fresh
rate = 0.8 * sum(p * log2(1 / p) for p in SPELL[0]) + 0.2 * sum(p * log2(1 / p) for p in SPELL[1] if p)
lo, hi, day = 0.0, 1.0, 0                # mistake: ordinary floats for the interval
while lo < hi:
    s, day = NAMES.index(MONTH[day % 30]), day + 1
    lo, hi = lo + (hi - lo) * CUM[s] / 10, lo + (hi - lo) * (CUM[s] + F[s]) / 10
print(f"mistakes: one day at a time {by_formula(1) * 30:.0f} bits; no length sent, 33 days decode as "
      f"{decode(x, k, 33)}; floats collapse to zero width on day {day}")
print(f"spells: after C, C 0.95, S 0.025, R 0.025; S or R stays 0.8, else C; entropy rate {rate:.4f} bits a day")
for n in (1000, 10000, 100000, 300000):
    sp, iid = weather(n, SPELL), weather(n, INDEP)
    ps, bs = lz78(sp, 3)
    pi, bi = lz78(iid, 3)
    assert [s for p in unlz78(ps) for s in p] == sp and [s for p in unlz78(pi) for s in p] == iid
    model = sum(log2(1 / SPELL[a][b]) for a, b in zip([0] + sp, sp))   # start after a cloudy day
    print(f"n={n}: LZ78 spells {bs / n:.4f}, independent {bi / n:.4f}; "
          f"Huffman spells {sum(HUFF[s] for s in sp) / n:.4f}; spell-model ideal {model / n:.4f}")

assert W == 8**24 and D == 10**30 and k == ceil(30 * log2(5) - 42)   # width = product of chances
assert decode(x, k, 30) == MONTH and k < huff < 60                    # round trip; beats Huffman
assert ok == 243 and abs(total / 5 - by_formula(5)) < 1e-12           # brute force = formula
assert all(H <= by_formula(n) < H + 1 / n for n in (1, 2, 5, 10, 30, 100))  # never below H, within 1 bit a message
assert [s for p in unlz78(pairs) for s in p] == [NAMES.index(c) for c in MONTH] and bits > k
assert bits == sum(ceil(log2(i)) + 2 for i in range(1, len(pairs) + 1)) - 2 * (pairs[-1][1] < 0)  # LZ78 formula
assert model / n < bs / n < H and bi / n > H                         # spells: LZ beats per-day codes
assert abs(model / n - rate) < 0.01 and rate < bs / n                # model cost meets the rate; LZ78 above it
print("ALL CHECKS PASS")
