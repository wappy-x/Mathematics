# Caratheodory's criterion -- the check behind the card.  Standard library only.
# A 3 m fence, lengths in metres as exact fractions.  E = [0.5, 1.2]; R = 100
# rust spots at 0.03, 0.06, ..., 3.00.  The test set T = [0.2, 0.8] and [1.0, 2.0].
# Four roads: exact interval lengths, grid cells that meet a set, one cover of T cut
# at the ends of E, and 1000 random test sets.  Then a toy fence of four panels.
from fractions import Fraction as F
from math import floor

def iv(a, b, lc=True, rc=True):              # interval a..b; lc, rc: ends included?
    return (F(a), F(b), lc, rc)

def length(pieces):                          # merge overlaps, add the lengths
    total, reach = F(0), None
    for a, b, _, _ in sorted(pieces):
        if reach is None or a > reach: total, reach = total + b - a, b
        elif b > reach: total, reach = total + b - reach, b
    return total

def meet(pieces, e):                         # the part of the pieces inside e
    out = []
    for a, b, lc, rc in pieces:
        lo, l2 = (a, lc) if a > e[0] else (e[0], e[2] and (lc or a < e[0]))
        hi, r2 = (b, rc) if b < e[1] else (e[1], e[3] and (rc or b > e[1]))
        if lo < hi: out.append((lo, hi, l2, r2))
    return out

def minus(pieces, e):                        # the part outside e: cut left and right
    left = meet(pieces, (F(-1), e[0], True, not e[2]))
    return left + meet(pieces, (e[1], F(10), not e[3], True))

def cells(pieces, n):                        # grid cells of width 1/n meeting the pieces
    got = set()
    for a, b, lc, rc in pieces:
        hi = b * n - 1 if (b * n).denominator == 1 and not rc else floor(b * n)
        got.update(range(floor(a * n), int(hi) + 1))
    return len(got)

def m(x):                                    # print a length to 4 decimals, exactly
    v = int(x * 10000)
    return f"{v // 10000}.{v % 10000:04d}"

E = iv("0.5", "1.2")
T = [iv("0.2", "0.8"), iv("1.0", "2.0")]
spots = [F(3 * k, 100) for k in range(1, 101)]
inT = [s for s in spots if any(a <= s <= b for a, b, _, _ in T)]
TminusR = T
for s in inT:
    TminusR = minus(TminusR, (s, s, True, True))
tE, tnE, tnR = length(meet(T, E)), length(minus(T, E)), length(TminusR)
tR = length([(s, s, True, True) for s in inT])     # 53 points: no length at all
print(f"fence [0, 3] m; E = [0.5, 1.2], size {m(length([E]))}; rust spots R = 0.03, 0.06, ..., 3.00 (100 points)")
print("test set T = [0.2, 0.8] and [1.0, 2.0]")
parts = lambda ps: " + ".join(m(length([p])) for p in ps)
print(f"road 1, exact lengths, an upper bound for outer measure: T = {parts(T)} = {m(length(T))}")
print(f"  E splits T: inside {parts(meet(T, E))} = {m(tE)}, outside {parts(minus(T, E))} = {m(tnE)}; total {m(tE + tnE)}")
per = " + ".join(str(sum(a <= s <= b for s in spots)) for a, b, _, _ in T)
print(f"  R splits T: inside {m(tR)} ({per} = {len(inT)} spots), outside {m(tnR)}; total {m(tR + tnR)}")
gap, hull = iv("0.8", "1.0", False, False), iv("0.2", "2.0")     # T and the gap make [0.2, 2.0]
lows = [(length([hull]), length([gap])), (length([E]), length([gap])), (length([hull]), length([E]))]
print("  lower bounds by subadditivity, gaps (0.8, 1.0) and E: " + ", ".join(
      f"{w} >= {m(a)} - {m(b)} = {m(a - b)}" for w, (a, b) in zip(("T", "inside", "outside"), lows)))
print("road 2, grid cells meeting each set, times cell width:")
print("  cells per metre | T | T and E | T minus E | sum | T and R | all of R")
grid = {}
for n in (10, 100, 1000, 10000):
    row = [F(c, n) for c in (cells(T, n), cells(meet(T, E), n), cells(minus(T, E), n))]
    rr = [F(len({floor(s * n) for s in inT}), n), F(len({floor(s * n) for s in spots}), n)]
    grid[n] = row + rr
    print(f"  {n:>5} | {m(row[0])} | {m(row[1])} | {m(row[2])} | {m(row[1] + row[2])} | {m(rr[0])} | {m(rr[1])}")
eps = F(1, 100)
cover = [iv(a - eps / 4, b + eps / 4, False, False) for a, b, _, _ in T]
ci, co = length(meet(cover, E)), length(minus(cover, E))
print(f"road 3, one cover of T, total {m(length(cover))} = outer(T) + {m(eps)}, cut at 0.5 and 1.2:")
print(f"  pieces inside E {m(ci)} + pieces outside E {m(co)} = {m(ci + co)}")
seed = state = 2026
def rand(k):                                 # SplitMix64, written out, then mod k
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return (z ^ (z >> 31)) % k
bad_E = bad_R = 0
for _ in range(1000):
    ends = [F(rand(30001), 10000) for _ in range(4)]
    S = [iv(*sorted(ends[:2])), iv(*sorted(ends[2:]))]
    bad_E += length(meet(S, E)) + length(minus(S, E)) != length(S)
    sR = [s for s in spots if any(a <= s <= b for a, b, _, _ in S)]
    rest = S
    for s in sR:
        rest = minus(rest, (s, s, True, True))
    bad_R += length(rest) != length(S)
print(f"road 4, 1000 random two-piece test sets (SplitMix64, seed {seed}): E fails {bad_E}, R fails {bad_R}")
names = ["-", "a", "b", "ab", "c", "ac", "bc", "abc", "d", "ad", "bd", "abd", "cd", "acd", "bcd", "abcd"]
boards = [1, 6, 12]                          # boards over {a}, {b, c}, {c, d}; each costs 1
def covered(k):                              # the panels under the boards chosen by k
    out = 0
    for i, bd in enumerate(boards):
        out |= bd if k >> i & 1 else 0
    return out
def bill(A):                                 # cheapest set of boards covering A
    return min(bin(k).count("1") for k in range(2 ** len(boards)) if A & ~covered(k) == 0)
ok = [A for A in range(16) if all(bill(X) == bill(X & A) + bill(X & ~A & 15) for X in range(16))]
print("toy fence, panels a b c d; boards over a, over b c, over c d; each board costs 1")
print("  cheapest bill: " + " ".join(f"{names[A]}:{bill(A)}" for A in range(16)))
print("  sets passing all 16 tests: " + ", ".join(names[A] for A in ok))
blocks = []                                  # road two: glue panels that share a board
for bd in boards:
    blocks = [b for b in blocks if not b & bd] + [bd | sum(b for b in blocks if b & bd)]
unions = sorted(sum(b for i, b in enumerate(blocks) if k >> i & 1) for k in range(2 ** len(blocks)))
print(f"  glued blocks {', '.join(names[b] for b in blocks)}; their unions: " + ", ".join(names[A] for A in unions))
closed = all(15 & ~A in ok and A | B in ok and A & B in ok for A in ok for B in ok)
print(f"  closed under complement, union, overlap: {'yes' if closed else 'no'}")
print(f"  additive on them: {bill(1)} + {bill(14)} = {bill(15)}")
print(f"what breaks: b passes the whole-fence test, {bill(2)} + {bill(13)} = {bill(15)},"
      f" but fails T = bc: {bill(2)} + {bill(4)} vs {bill(6)}")
print(f"  outer measure off the passing sets: bill(b) + bill(c) = {bill(2) + bill(4)}, bill(bc) = {bill(6)}")
def fx(ps):                                  # figure x-coordinates: 30 + 100 per metre
    return " and ".join(f"{int(30 + 100 * a)} to {int(30 + 100 * b)}" for a, b, _, _ in ps)
print(f"figure, x = 30 + 100 * metres: fence {fx([iv(0, 3)])}; E {fx([E])}; T {fx(T)};"
      f" T and E {fx(meet(T, E))}; T minus E {fx(minus(T, E))}; spots every 3")
assert tE + tnE == length(T) == F(8, 5) and tR + tnR == length(T)     # road 1 against the hand sum
assert [a - b for a, b in lows] == [length(T), tE, tnE]              # the squeeze: lower bounds meet the sums
assert grid[10][:3] == [F(9, 5), F(7, 10), F(6, 5)]                 # the coarse row quoted in What breaks
g = grid[10000]
assert all(0 <= g[i] - x <= F(2, 10000) for i, x in enumerate((length(T), tE, tnE)))  # one cell per piece
assert bad_E == 0 and bad_R == 0 and ci + co == length(cover)
assert ok == unions and closed and bill(1) + bill(14) == bill(15)  # toy: two roads, one family
assert bill(2) + bill(13) == bill(15) and bill(2) + bill(4) > bill(6)
print("ALL CHECKS PASS")
