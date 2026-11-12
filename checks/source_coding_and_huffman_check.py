# Huffman codes -- the check behind the card.  Standard library only, nothing imported that codes.
# A weather station sends one 4-way forecast a day.  Roads: Huffman merging; brute force
# over every code of words up to 3 bits; the entropy bound; Kraft's sum; McMillan's counting
# argument on a code that breaks the rule; and 10,000 synthetic days drawn with SplitMix64.
from math import log2, ceil

NAMES = ["Sun", "Cloud", "Rain", "Snow"]
SUMMER = [0.5, 0.25, 0.125, 0.125]     # the forecast odds: powers of one half
AUTUMN = [0.4, 0.3, 0.2, 0.1]          # a second season: not powers of one half

def entropy(p): return -sum(q * log2(q) for q in p)
def avg(p, lens): return sum(q * l for q, l in zip(p, lens))
def kraft(lens): return sum(2.0 ** -l for l in lens)

def huffman(p, log=None):
    # each node: [weight, creation number, {symbol: code so far}]; merge the two lightest
    nodes = [[q, i, {i: ""}] for i, q in enumerate(p)]
    made = len(p)
    while len(nodes) > 1:
        pair = []
        for _ in range(2):                       # linear scan: lightest, ties to the older node
            best = 0
            for j in range(1, len(nodes)):
                if (nodes[j][0], nodes[j][1]) < (nodes[best][0], nodes[best][1]): best = j
            pair.append(nodes.pop(best))
        (wa, _, ca), (wb, _, cb) = pair
        codes = {s: "0" + c for s, c in ca.items()}
        codes.update({s: "1" + c for s, c in cb.items()})
        if log is not None: log.append((wa, wb, wa + wb))
        nodes.append([wa + wb, made, codes]); made += 1
    return [nodes[0][2][i] for i in range(len(p))]

def brute(p):
    # every ordered choice of 4 distinct words of 1 to 3 bits; keep the prefix-free ones
    words = [format(v, "0%db" % n) for n in (1, 2, 3) for v in range(2 ** n)]
    tried = free = 0; best = 99.0
    for a in words:
        for b in words:
            for c in words:
                for d in words:
                    code = [a, b, c, d]
                    if len(set(code)) < 4: continue
                    tried += 1
                    if any(x != y and y.startswith(x) for x in code for y in code): continue
                    free += 1; best = min(best, avg(p, [len(w) for w in code]))
    return best, tried, free

def decode(bits, code):
    out, word = [], ""
    for b in bits:
        word += b
        if word in code: out.append(code.index(word)); word = ""
    return out

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, (z ^ (z >> 31)) >> 11

def counts(lens, k):                             # k-forecast messages, counted by total bits
    a = {0: 1}
    for _ in range(k):
        b = {}
        for m, c in a.items():
            for l in lens: b[m + l] = b.get(m + l, 0) + c
        a = b
    return a

def line(label, v): print(f"{label:<44}{v:>12.6f}")

log = []
code = huffman(SUMMER, log)
lens = [len(c) for c in code]
for i in range(4): print(f"{NAMES[i]:<6} p {SUMMER[i]:.3f}  code {code[i]:<4} length {lens[i]}  p*length {SUMMER[i] * lens[i]:.3f}  p*log2(1/p) {-SUMMER[i] * log2(SUMMER[i]):.3f}")
for wa, wb, w in log: print(f"merge {wa:.3f} + {wb:.3f} -> {w:.3f}")
line("sum of the merged weights", sum(w for _, _, w in log))
print("slots at depth 3 claimed: " + " ".join(str(2 ** (3 - l)) for l in lens) + " of 8")
H, L = entropy(SUMMER), avg(SUMMER, lens)
best, tried, free = brute(SUMMER)
line("entropy H, bits a day", H); line("Huffman average L, bits a day", L)
line("brute force best prefix-free L", best); line("fixed 2-bit code, bits a day", 2.0)
line("Kraft sum of the Huffman code", kraft(lens))
print(f"codes tried {tried}, prefix-free {free}")
print(f"a year: fixed {365 * 2} bits, Huffman {365 * L:.2f} bits, saved {365 * (2 - L):.2f}")
week = [0, 0, 1, 2, 0, 3, 1]
bits = "".join(code[s] for s in week)
print(f"week Sun Sun Cloud Rain Sun Snow Cloud -> {bits} ({len(bits)} bits, fixed 14)")
state, days, cum = 2026, [], [0.5, 0.75, 0.875, 1.0]
for _ in range(10000):
    state, r = splitmix(state)
    u = r / 2.0 ** 53
    days.append(next(i for i in range(4) if u < cum[i]))
stream = "".join(code[s] for s in days)
sim = len(stream) / 10000
se = (sum(q * l * l for q, l in zip(SUMMER, lens)) - L * L) ** 0.5 / 100
print(f"10000 synthetic days (seed 2026): {len(stream)} bits, {sim:.4f} a day, standard error {se:.4f}")
print(f"decoded back exactly: {decode(stream, code) == days}")
bad = ["0", "1", "10", "11"]                     # too short: breaks Kraft
blens = [len(w) for w in bad]
line("wrong: code 0,1,10,11, Kraft sum", kraft(blens)); line("wrong: code 0,1,10,11, average", avg(SUMMER, blens))
print(f"  Rain -> {bad[2]}, Cloud Sun -> {bad[1] + bad[0]}")
cb, cg = counts(blens, 3), counts(lens, 3)
print(f"  3 forecasts in 4 bits: {cb[4]} messages, {2 ** 4} bit strings")
print(f"  Huffman code: 3-forecast messages per bit string, at most {max(c / 2 ** m for m, c in cg.items()):.6f}")
line("wrong: short codes to the rare days", avg(SUMMER, lens[::-1]))
shan = [ceil(-log2(q)) for q in AUTUMN]
acode = huffman(AUTUMN, alog := [])
alens = [len(c) for c in acode]
HA, LA, abest = entropy(AUTUMN), avg(AUTUMN, alens), brute(AUTUMN)[0]
print("autumn odds 0.4 0.3 0.2 0.1, Huffman code " + " ".join(acode))
print("autumn merges " + ", ".join(f"{a:.1f}+{b:.1f}" for a, b, _ in alog) + f", sum {sum(w for _, _, w in alog):.6f}")
line("autumn entropy H", HA); line("autumn Huffman L", LA); line("autumn brute force best L", abest)
print(f"autumn Shannon lengths {' '.join(map(str, shan))}, Kraft {kraft(shan):.4f}")
line("autumn Shannon-length average", avg(AUTUMN, shan))
pairs = [a * b for a in AUTUMN for b in AUTUMN]
L2 = avg(pairs, [len(c) for c in huffman(pairs)]) / 2
line("autumn, two days per codeword, bits a day", L2)
DESERT = [0.9, 0.1]
HD = entropy(DESERT)
line("desert 0.9 dry 0.1 rain: entropy H", HD)
for k in (1, 2, 3):
    blk = [1.0]
    for _ in range(k): blk = [a * b for a in blk for b in DESERT]
    line(f"desert, {k}-day blocks, bits a day", avg(blk, [len(c) for c in huffman(blk)]) / k)
pos = {"": (210, 40)}
for c in ["0", "1", "10", "11", "110", "111"]:
    x, y = pos[c[:-1]]
    pos[c] = (x + (100 if c[-1] == "1" else -100) // 2 ** (len(c) - 1), y + 60)
print("figure, " + " ".join(f"{c or 'root'}=({pos[c][0]},{pos[c][1]})" for c in pos))

assert abs(L - best) < 1e-12 and abs(LA - abest) < 1e-12, "Huffman must match brute force"
assert abs(sum(w for _, _, w in log) - L) < 1e-12 and abs(sum(w for _, _, w in alog) - LA) < 1e-12, "merges"
assert H <= L + 1e-12 and L < H + 1 and HA <= LA < HA + 1, "entropy bound"
assert abs(kraft(lens) - 1) < 1e-12 and kraft(shan) <= 1, "Kraft"
assert abs(sim - H) < 5 * se and decode(stream, code) == days, "simulation"
assert cb[4] > 2 ** 4 and max(c / 2 ** m for m, c in cg.items()) <= 1, "McMillan counting"
assert HA <= L2 < LA and abs(H - 1.75) < 1e-12, "pairs close the gap"
print("ALL CHECKS PASS")
