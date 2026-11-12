# Two roads and a mutation -- the check behind the card.  Standard library only.
# Road 1 decodes Hamming (7,4) with a lookup table built by brute force: for each
# of the 128 possible 7-bit words, the nearest of the 16 codewords.  Road 2 uses
# the syndrome.  Then five bugs (mutants) are planted one at a time, and each
# test is scored by how many of them it catches.
from math import log, ceil

GROUPS = ((1, 3, 5, 7), (2, 3, 6, 7), (4, 5, 6, 7))  # check position first
DATA = (3, 5, 6, 7)                                   # where d1..d4 sit
MUT = None                                            # which bug is planted

def bits(x, n): return [(x >> (n - 1 - i)) & 1 for i in range(n)]
def show(b): return "".join(map(str, b))

def encode(m):                              # [d1, d2, d3, d4] -> positions 1..7
    c = [0] * 8
    for p, d in zip(DATA, m): c[p] = d
    for g in GROUPS: c[g[0]] = sum(c[p] for p in g[1:]) % 2
    return c[1:]

def extract(c):                             # shared by both roads
    where = (5, 3, 6, 7) if MUT == "M5" else DATA
    return [c[p - 1] for p in where]

CODEWORDS = [encode(bits(x, 4)) for x in range(16)]
WORDS = [bits(x, 7) for x in range(128)]

def dist(a, b): return sum(x != y for x, y in zip(a, b))

def nearest(r):                             # brute force over all 16 codewords
    return min(CODEWORDS, key=lambda c: dist(r, c))
TABLE = [nearest(r) for r in WORDS]         # built once, from distances alone

def road1(r):                               # the lookup table
    c = TABLE[int(show(r), 2)]
    if MUT == "M3" and show(r) == "0000011": c = CODEWORDS[15]  # one typo
    return extract(c)

def syndrome(r):
    s = 0
    for k, g in enumerate(GROUPS):
        if MUT == "M2" and k == 1: g = (2, 3, 6)                 # forgot 7
        s += (sum(r[p - 1] for p in g) % 2) << k
    if MUT == "M1": s = int(format(s, "03b")[::-1], 2)          # bits read backwards
    return s

def road2(r):                               # the syndrome names the bad position
    s, c = syndrome(r), list(r)
    if s and MUT != "M4": c[s - 1] ^= 1                         # M4: forgot to flip
    return extract(c)

PIN = [1, 0, 0, 1, 1, 1, 0]                 # 1001100 with position 6 flipped
TESTS = {
    "T0 tautology: road 2 equals road 2": lambda: all(road2(r) == road2(r) for r in WORDS),
    "T1 round trip, 16 clean codewords": lambda: all(road2(encode(bits(x, 4))) == bits(x, 4) for x in range(16)),
    "T2 two roads agree on all 128 words": lambda: all(road1(r) == road2(r) for r in WORDS),
    "T3 pinned hand value 1001110 -> 0100": lambda: road2(PIN) == [0, 1, 0, 0],
}
MUTANTS = {"M1": "syndrome bits read backwards", "M2": "check 2 forgets position 7",
           "M3": "one typo in the table", "M4": "decoder forgets to flip",
           "M5": "shared extract swaps d1, d2"}

# ---- the clean code: both roads, and the hand-worked word ----
print("codeword for 0100", show(encode([0, 1, 0, 0])))
print("pinned word", show(PIN), "syndrome", syndrome(PIN), "-> road 1", show(road1(PIN)), "road 2", show(road2(PIN)))
sums = [sum(PIN[p - 1] for p in g) for g in GROUPS]
print("pinned word check sums", *sums, "-> parities", *[x % 2 for x in sums])
print("distances from pinned word to the 16 codewords", " ".join(str(dist(PIN, c)) for c in CODEWORDS))
agree = sum(road1(r) == road2(r) for r in WORDS)
single = sum(syndrome(c[:p] + [1 - c[p]] + c[p + 1:]) == p + 1 for c in CODEWORDS for p in range(7))
print("clean: roads agree on", agree, "of 128; syndrome = position on", single, "of 112 one-flip words")
G_COLUMNS = ["1110000", "1001100", "0101010", "1101001"]   # from the Hamming card's G
assert [show(encode(bits(8 >> i, 4))) for i in range(4)] == G_COLUMNS, "encoder matches G"
assert agree == 128, "the two roads must agree on every word"
assert single == 112, "one flip at position p must give syndrome p"
assert all(t() for t in TESTS.values()), "every test passes on clean code"
assert syndrome(PIN) == 6, "hand value: the checks name position 6"
assert show(road2(PIN)) == "0100", "hand value: 1001110 decodes to 0100"

# ---- plant each bug, run every test ----
print()
print("mutant   w  T0 T1 T2 T3  pin  what was broken")
kills, W, any_kill = {t: 0 for t in TESTS}, {}, 0
for m, what in MUTANTS.items():
    MUT = m
    W[m] = sum(road1(r) != road2(r) for r in WORDS)              # words where the roads disagree
    row = []
    for t, f in TESTS.items():
        caught = not f()
        kills[t] += caught
        row.append(" K" if caught else " -")
    any_kill += "K" in "".join(row[1:])
    print(f"{m:<6}{W[m]:>4} " + " ".join(row) + "  " + show(road2(PIN)) + " " + what)
MUT = "M1"
flipped = PIN[:]; flipped[syndrome(PIN) - 1] ^= 1
print("M1 on pinned word: syndrome", syndrome(PIN), "flipped word", show(flipped), "data", show(road2(PIN)))
MUT = None
print()
for t, k in kills.items(): print(f"{t:<40} kills {k} of 5")
print(f"{'T1 + T2 + T3 together':<40} kills {any_kill} of 5")
assert [kills[t] for t in list(TESTS)[1:]] == [1, 4, 3], "T1, T2 and T3 kill 1, 4 and 3 of the 5"
assert W["M5"] == 0 and any_kill == 5, "two roads miss shared code; the pin catches it"

# ---- a random test of k words instead of all 128: formula against simulation ----
MASK = (1 << 64) - 1
state = 20261111                            # SplitMix64, written out, stated seed
def nxt():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def p_catch(w, k): return 1 - (1 - w / 128) ** k
def k_for(w, goal): return ceil(log(1 - goal) / log(1 - w / 128))
print()
print("mutant   w  P(catch), 5 random words  simulated, 20000 runs  words for 99%")
for m in ("M1", "M2", "M3", "M4"):
    MUT = m
    bad = [road1(r) != road2(r) for r in WORDS]
    hits = sum(max(bad[nxt() % 128] for _ in range(5)) for _ in range(20000))
    sim, f = hits / 20000, p_catch(W[m], 5)
    print(f"{m:<6}{W[m]:>4}  {f:>24.4f}  {sim:>22.4f}  {k_for(W[m], 0.99):>13}")
    assert abs(sim - f) < 4 * (f * (1 - f) / 20000) ** 0.5, "simulation must meet the formula"
MUT = None
q = 1 - 1 / 128
print(f"by hand, w = 1: 1 - w/128 = {q:.5f}, to the 5th = {q ** 5:.5f}, catch = {1 - q ** 5:.5f}")
print(f"by hand, 99%: ln 0.01 = {log(0.01):.5f}, ln(127/128) = {log(q):.7f}, ratio = {log(0.01) / log(q):.2f}")
print()
ks = [1, 5, 10, 20, 50, 100, 200, 400, 600]
print("chart, words tested k" + "".join(f"{k:>7}" for k in ks))
for w in (64, 32, 1):
    print(f"chart, w = {w:<10}" + "".join(f"{p_catch(w, k):>7.3f}" for k in ks))
print("ALL CHECKS PASS")
