# Interactive proofs -- the check behind the card.  Nothing is imported.
# Stations A to F are 0 to 5.  RING and TOURIST are one network drawn twice
# (the Graphs card); DECOY has the same station and line counts and tally.
RING = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
TOURIST = [(0, 2), (0, 4), (0, 5), (1, 4), (1, 5), (2, 3), (3, 4), (3, 5)]
DECOY = [(0, 1), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
M64 = (1 << 64) - 1
class Rng:                                   # SplitMix64, written out
    def __init__(s, seed): s.x = seed
    def below(s, n):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = ((s.x ^ (s.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (z ^ (z >> 31)) % n
def perms(items):                            # all 720 renamings, generated here
    if not items: return [()]
    return [(x,) + r for i, x in enumerate(items) for r in perms(items[:i] + items[i + 1:])]
ALL, ID = perms(tuple(range(6))), tuple(range(6))
def mask(edges, pi):                         # a renamed map as a set of bits
    return sum(1 << (min(pi[a], pi[b]) * 6 + max(pi[a], pi[b])) for a, b in edges)
def tally(e): return sorted(sum(v in p for p in e) for v in range(6))
def triangles(e):
    s = {mask([p], ID) for p in e}
    return sum(1 for a in range(6) for b in range(a + 1, 6) for c in range(b + 1, 6)
               if {mask([(a, b)], ID), mask([(a, c)], ID), mask([(b, c)], ID)} <= s)
def shuffle(rng):                            # Fisher-Yates: a random renaming
    p = list(range(6))
    for i in range(5, 0, -1):
        j = rng.below(i + 1); p[i], p[j] = p[j], p[i]
    return p
def round_ok(rng, maps, answer, shuffled=True):   # True if prover names the coin
    b = rng.below(2)
    return answer(mask(maps[b], shuffle(rng) if shuffled else ID)) == b
# ---- part 1: the sceptic's protocol for "these two maps are different networks"
cR, cD, cT = ({mask(m, p) for p in ALL} for m in (RING, DECOY, TOURIST))
aR, aD = (sum(1 for p in ALL if mask(m, p) == mask(m, ID)) for m in (RING, DECOY))
print(f"tube maps: 6 stations, 8 lines each; tally ring {tally(RING)}, decoy {tally(DECOY)}")
print(f"triangles: ring {triangles(RING)}, tourist {triangles(TOURIST)}, decoy {triangles(DECOY)}")
print(f"renamings that leave a map unchanged: ring {aR}, decoy {aD}")
print(f"distinct shuffled copies: ring {len(cR)} = 720 / {aR}, decoy {len(cD)} = 720 / {aD}, shared {len(cR & cD)}")
print(f"same network (ring, tourist): copies {len(cR)} and {len(cT)}, shared {len(cR & cT)}")
count = {}
for b, m in enumerate((RING, TOURIST)):
    for p in ALL:
        h = mask(m, p); count.setdefault(h, [0, 0])[b] += 1
best = sum(max(c) for c in count.values())
print(f"best cheater over all 1440 (coin, renaming) pairs: wins {best}, rate {best / 1440:.6f}")
rng = Rng(2026)
honest = sum(round_ok(rng, (RING, DECOY), lambda h: 0 if h in cR else 1) for _ in range(20000))
print(f"honest prover, different maps: {honest} of 20000 rounds named correctly")
guess = lambda h: 0 if h & (1 << 1) else 1           # "ring if line A-B is drawn"
wins = sum(round_ok(rng, (RING, TOURIST), guess) for _ in range(100000))
print(f"cheater, same network, one round: {wins} of 100000, rate {wins / 100000:.6f} (exact 0.5)")
print("chart,rounds,simulated,exact")
sims = []
for k in range(1, 9):
    alive = sum(all(round_ok(rng, (RING, TOURIST), guess) for _ in range(k)) for _ in range(20000))
    sims.append(alive / 20000); print(f"chart,{k},{alive / 20000:.4f},{0.5 ** k:.4f}")
print(f"20 rounds: a cheater survives with chance 1 in {2 ** 20}")
blind = sum(round_ok(rng, (RING, TOURIST), lambda h: 0 if h == mask(RING, ID) else 1, False) for _ in range(20))
print(f"no shuffle (map sent under its own names): cheater names {blind} of 20")
assert len(cR) * aR == 720 and len(cD) * aD == 720 and not (cR & cD) and cR == cT
assert triangles(RING) == triangles(TOURIST) == 0 and triangles(DECOY) == 2 and tally(RING) == tally(DECOY)
assert honest == 20000 and best == 720 and blind == 20
assert abs(wins / 100000 - 0.5) < 4 * (0.25 / 100000) ** 0.5
assert all(abs(s - 0.5 ** k) < 4 * (0.5 ** k / 20000) ** 0.5 for k, s in enumerate(sims, 1))
# ---- part 2: sum-check, the engine of IP = PSPACE, on "the decoy has 2 triangles"
P, H = 2 ** 31 - 1, 2 ** 30                  # field size; H is 1/2 mod P
A = [[0] * 8 for _ in range(8)]
for a, b in DECOY: A[a][b] = A[b][a] = 1
def chi(pt):                                 # weight of each 3-bit corner at a point
    w = []
    for c in range(8):
        x = 1
        for i in range(3): x = x * (pt[i] if (c >> (2 - i)) & 1 else 1 - pt[i] + P) % P
        w.append(x)
    return w
def At(x, y):                                # the adjacency table, extended smoothly
    cx, cy = chi(x), chi(y)
    return sum(A[a][b] * cx[a] % P * cy[b] for a in range(8) for b in range(8)) % P
def f(z): return At(z[0:3], z[3:6]) * At(z[3:6], z[6:9]) % P * At(z[0:3], z[6:9]) % P
def corners(k): return [[(c >> (k - 1 - i)) & 1 for i in range(k)] for c in range(2 ** k)]
def at(g, r):                                # the degree-2 polynomial through g, at r
    return (g[0] * (r - 1) * (r - 2) * H - g[1] * r * (r - 2) + g[2] * r * (r - 1) * H) % P
def sumcheck(claim, rng, lie=0, final=True, show=0, who=""):
    fixed = []
    for i in range(9):
        g = [(sum(f(fixed + [t] + c) for c in corners(8 - i)) + lie) % P for t in range(3)]
        if (g[0] + g[1]) % P != claim: return f"rejected in round {i + 1}"
        r = rng.below(P); claim, lie = at(g, r), lie * H % P; fixed.append(r)
        if i < show: print(f"{who}round {i + 1}: g(0) = {g[0]}, g(1) = {g[1]}, g(2) = {g[2]}, r = {r}")
    if not final: return "accepted after 9 of 9 rounds"
    return f"final f = {f(fixed)}, last claim {claim}: " + ("accept" if f(fixed) == claim else "reject")
total = sum(f(c) for c in corners(9))
print(f"sum-check on the decoy, 9 variables, field size p = {P}")
print(f"brute force over 512 corners: {total} = 6 x {triangles(DECOY)} triangles")
honest_run = sumcheck(total, Rng(7), show=9)
print("honest prover, claim 12: " + honest_run)
lie_run = sumcheck(18, Rng(7), lie=3, show=1, who="lying prover, ")
print("lying prover, claim 18 (3 triangles): " + lie_run)
blind_run = sumcheck(18, Rng(7), lie=3, final=False)
print("lying prover, verifier skips the final check: " + blind_run)
print(f"escape chance at most 18 / {P}, under 1 in {P // 18}")
print("cost,stations,rounds,numbers sent,brute-force terms,table entries read")
for m in (3, 8, 10): print(f"cost,{2 ** m},{3 * m},{9 * m},{8 ** m},{4 ** m}")
assert total == 6 * triangles(DECOY) and honest_run.endswith("accept") and lie_run.endswith("reject")
assert blind_run.startswith("accepted") and sumcheck(total + 1, Rng(7)) == "rejected in round 1"
# ---- part 3: spot checks, and why a proof must be rewritten before they work
def broken(e, col): return sum(1 for a, b in e if col[a] == col[b])
def best_col(e, n): return min((broken(e, [(c >> i) & 1 for i in range(n)]), c) for c in range(2 ** n))
loop = lambda n: [(i, (i + 1) % n) for i in range(n)]
bR, bD, b9 = best_col(RING, 6)[0], best_col(DECOY, 6), best_col(loop(9), 9)[0]
b1001 = broken(loop(1001), [i % 2 for i in range(1001)])
print(f"2-colouring proofs: ring best breaks {bR} of 8; decoy best breaks {bD[0]} of 8")
print(f"odd loop of 9: best breaks {b9} of 9 (all 512 colourings); loop of 1001, alternating: breaks {b1001}")
def checks(q):
    k, x = 0, 1.0
    while x > 0.01: k, x = k + 1, x * (1 - q)
    return k
qD, qL = bD[0] / 8, b1001 / 1001
print(f"one check catches the best wrong proof: decoy {qD:.6f}, loop of 1001 {qL:.6f}")
print(f"checks for 99% confidence: decoy {checks(qD)}, loop of 1001 {checks(qL)}")
col = [(bD[1] >> i) & 1 for i in range(6)]
fooled = sum(all(col[a] != col[b] for a, b in (DECOY[rng.below(8)] for _ in range(17)))
             for _ in range(10000))
print(f"17 checks on the best decoy colouring, 10000 trials: fooled {fooled / 10000:.4f}, exact {0.75 ** 17:.6f}")
sat = sum(1 for c in range(8) if (c & 1) or (c & 2) or (c & 4))   # (x or y or z)
print(f"a 3-literal clause holds on {sat} of its 8 settings")
assert bR == 0 and bD[0] == 2 and b9 == 1 and b1001 == 1
assert checks(qD) == 17 and checks(qL) > 1001 and abs(fooled / 10000 - 0.75 ** 17) < 4 * (0.0075 / 10000) ** 0.5
print("ALL CHECKS PASS")
