# Arthur-Merlin and two provers -- the check behind the card.  Standard library only.
# Part 1: the Goldwasser-Sipser protocol, with public coins, on the claim "a 4-station
# path and a 4-station star are different networks".  Part 2: the CHSH game, two
# suspects in separate rooms: fixed strategies against a two-qubit state vector.
from math import cos, sin, sqrt, pi
M64 = (1 << 64) - 1
class Rng:                                   # SplitMix64, as on the Interactive proofs card
    def __init__(s, seed): s.x = seed
    def next(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = ((s.x ^ (s.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def below(s, n): return s.next() % n
    def unit(s): return (s.next() >> 11) / 9007199254740992.0
def perms(items):                            # all 24 renamings of 4 stations
    if not items: return [()]
    return [(x,) + r for i, x in enumerate(items) for r in perms(items[:i] + items[i + 1:])]
ALL = perms((0, 1, 2, 3))
PAIRS = [(a, b) for a in range(4) for b in range(a + 1, 4)]          # the 6 possible lines
def mask(edges, pi):                         # a renamed network as 6 bits, one per line
    return sum(1 << PAIRS.index((min(pi[a], pi[b]), max(pi[a], pi[b]))) for a, b in edges)
def lines(h): return [PAIRS[i] for i in range(6) if h >> i & 1]
PATH, STAR, PATH2 = [(0, 1), (1, 2), (2, 3)], [(0, 1), (0, 2), (0, 3)], [(2, 0), (0, 3), (3, 1)]
def copies(g): return {mask(g, p) for p in ALL}
def syms(h): return [k for k, p in enumerate(ALL) if mask(lines(h), p) == h]
def pairset(g0, g1):                         # Merlin's set: (copy, symmetry) as 11-bit codes
    return sorted(h * 32 + k for h in copies(g0) | copies(g1) for k in syms(h))
def parity(v): return bin(v).count("1") & 1
def hsh(rows, x): return sum(parity(r & x) << j for j, r in enumerate(rows))
def play(rng, S, k, n, show=False):          # n rounds: Arthur's public coins, Merlin's search
    acc, hits = [], 0
    for _ in range(n):
        rows, y = [rng.below(2048) for _ in range(k)], rng.below(1 << k)
        found = [x for x in S if hsh(rows, x) == y]
        if show and found and not any(acc):
            x = found[0]; h = x >> 5
            print(f"round {len(acc) + 1}: target {y}; Merlin sends code {x}: lines {lines(h)}, a copy of the "
                  f"{'path' if h in copies(PATH) else 'star'}, symmetry {ALL[x & 31]}")
        acc.append(len(found) > 0); hits += len(found)
    return acc, hits
def tail(t, q, lo):                          # Pr[at least lo hits in t rounds, each with chance q]
    term, tot = 1.0, 0.0
    for _ in range(t): term *= 1 - q
    for k in range(t + 1):
        if k >= lo: tot += term
        term = term * (t - k) / (k + 1) * q / (1 - q)
    return tot
# ---- part 1: public coins prove "the set is big"
cP, cS, sP, sS = copies(PATH), copies(STAR), syms(mask(PATH, ALL[0])), syms(mask(STAR, ALL[0]))
print(f"renamings of 4 stations: {len(ALL)}; symmetries: path {len(sP)}, star {len(sS)}")
print(f"labelled copies: path {len(cP)} = 24 / {len(sP)}, star {len(cS)} = 24 / {len(sS)}, shared {len(cP & cS)}")
print(f"copies only: path+star {len(cP | cS)}, path+path {len(cP | copies(PATH2))}, star+star {len(cS)}")
YES, NO = pairset(PATH, STAR), pairset(PATH, PATH2)
print(f"(copy, symmetry) pairs: path {len(pairset(PATH, PATH))}, star {len(pairset(STAR, STAR))}; "
      f"claim true {len(YES)}, claim false {len(NO)}")
K = 7; T = 1 << K; pY, pN = len(YES) / T, len(NO) / T
lo = pY - len(YES) * (len(YES) - 1) / 2 / T ** 2
print(f"hash 11 bits to {K}: {T} targets; true claim hits with chance at least {pY:.6f} - "
      f"{len(YES) * (len(YES) - 1) // 2}/{T * T} = {lo:.6f}")
print(f"false claim hits with chance at most {len(NO)}/{T} = {pN:.6f}, whatever Merlin does")
rng = Rng(2026)
aY, hY = play(rng, YES, K, 20000, True); aN, hN = play(rng, NO, K, 20000)
rY, rN = sum(aY) / 20000, sum(aN) / 20000
print(f"20000 rounds each: true claim accepted {sum(aY)} ({rY:.4f}), false claim {sum(aN)} ({rN:.4f})")
print(f"mean hits per round: true {hY / 20000:.4f} (exact {pY:.4f}), false {hN / 20000:.4f} (exact {pN:.4f})")
bY = sum(sum(aY[i:i + 100]) >= 25 for i in range(0, 20000, 100))
bN = sum(sum(aN[i:i + 100]) >= 25 for i in range(0, 20000, 100))
print(f"100 rounds at once, accept if 25 or more hit: true claim {bY} of 200 runs, false claim {bN} of 200")
print("chart,rounds,true claim rejected,false claim accepted")
errs = [(t, 1 - tail(t, lo, t // 4), tail(t, pN, t // 4)) for t in range(40, 401, 40)]
for t, e1, e2 in errs: print(f"chart,{t},{e1:.6f},{e2:.6f}")
cheat = 0
for _ in range(20):
    rows = [rng.below(2048) for _ in range(K)]
    cheat += any(hsh(rows, x) == hsh(rows, NO[0]) for x in NO)    # Merlin picks the target
print(f"Merlin chooses the target himself: false claim accepted {cheat} of 20")
a4, _ = play(rng, YES, 4, 20000); n4, _ = play(rng, NO, 4, 20000)
print(f"only 16 targets: true claim {sum(a4) / 20000:.4f}, false claim {sum(n4) / 20000:.4f}")
assert len(cP) * len(sP) == len(cS) * len(sS) == len(ALL) == 24 and not (cP & cS)
assert len(YES) == 2 * len(NO) == 48 and len(cP | copies(PATH2)) == 12
se = (0.25 / 20000) ** 0.5
assert lo - 4 * se < rY < pY + 4 * se and rN < pN + 4 * se and rN < lo
assert abs(hY / 20000 - pY) < 0.02 and abs(hN / 20000 - pN) < 0.02
assert bY > 150 and bN < 50 and errs[-1][1] < 0.01 and errs[-1][2] < 0.01 and cheat == 20
# ---- part 2: two suspects in separate rooms, the CHSH game
def win(x, y, a, b): return (a ^ b) == (x & y)
Q = [(x, y) for x in (0, 1) for y in (0, 1)]
det = [sum(win(x, y, s >> x & 1, s >> (2 + y) & 1) for x, y in Q) for s in range(16)]
print(f"CHSH, 16 fixed strategy pairs: {det.count(3)} win 3 of 4, {det.count(1)} win 1 of 4, "
      f"best {max(det) / 4:.4f}, average {sum(det) / 64:.4f}")
talk = sum(win(x, y, 0, x & y) for x, y in Q)
print(f"suspects who hear both questions: win {talk} of 4")
S2 = 1 / sqrt(2)
def chances(al, be):                         # read A at angle al, B at be, on (|00> + |11>)/sqrt 2
    v = [S2, 0.0, 0.0, S2]                   # state vector as on the Qubits card; index 2a + b
    for bit, th in ((2, al), (1, be)):
        c, s = cos(th), sin(th)
        for i in range(4):
            if i & bit == 0:
                j = i | bit
                v[i], v[j] = c * v[i] + s * v[j], -s * v[i] + c * v[j]
    return [a * a for a in v]
AL, BE = [0.0, pi / 4], [pi / 8, -pi / 8]
def qwin(al, be):
    return sum(p for x, y in Q for i, p in enumerate(chances(al[x], be[y])) if win(x, y, i >> 1, i & 1)) / 4
qw, cf = qwin(AL, BE), cos(pi / 8) * cos(pi / 8)
print(f"entangled pair, A at 0 or pi/4, B at pi/8 or -pi/8: win {qw:.12f}; cos^2(pi/8) = {cf:.12f}")
same = [[sum(chances(i * pi / 16, j * pi / 16)[k] for k in (0, 3)) for j in range(16)] for i in range(16)]
best = max((same[a][c] + same[a][d] + same[b][c] + 1 - same[b][d]) / 4
           for a in range(16) for b in range(16) for c in range(16) for d in range(16))
print(f"best over 65536 angle settings in steps of pi/16: {best:.12f}")
rng, cw, qn = Rng(7), 0, 0
for _ in range(100000):
    x, y = rng.below(2), rng.below(2)
    cw += win(x, y, 0, 0)
    p, u, i = chances(AL[x], BE[y]), rng.unit(), 0
    while i < 3 and u >= p[i]: u -= p[i]; i += 1
    qn += win(x, y, i >> 1, i & 1)
print(f"100000 sampled games: best fixed strategy wins {cw / 100000:.4f}, entangled pair {qn / 100000:.4f}")
for name, r in (("random answers", sum(det) / 64), ("best fixed strategy", max(det) / 4),
                ("entangled pair", qw), ("suspects who talk", talk / 4)):
    print(f"{name:<20}{'#' * round(r * 40):<41}{r:.4f}")
print("strategy pairs to try, q-bit questions, 1-bit answers: "
      + ", ".join(f"q = {q}: {2 ** (2 ** (q + 1))}" for q in (1, 2, 3, 4)))
assert max(det) == 3 and det.count(3) == 8 and talk == 4 and abs(qw - (2 + sqrt(2)) / 4) < 1e-12
assert abs(best - cf) < 1e-12 and abs(cw / 100000 - 0.75) < 4 * (0.1875 / 100000) ** 0.5
assert abs(qn / 100000 - qw) < 4 * (0.125 / 100000) ** 0.5 and qn / 100000 > 0.8
print("ALL CHECKS PASS")
