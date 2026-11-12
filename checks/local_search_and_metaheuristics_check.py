# Local search on an exam timetable: the check behind the card.  Standard library only.
# No random: the generator (SplitMix64) is written out.  Every dataset is synthetic.
from math import exp, log, log10, ceil, sqrt
M64 = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def below(self, m): return self.next() % m
    def unif(self): return (self.next() >> 11) / 9007199254740992.0     # in [0, 1)
def build(rng, n, slots):    # 40 first-years sit 4 of the 12 core exams 0-11; 80 others sit 4 of all 40
    adj, hidden = [set() for _ in range(n)], [e % slots for e in range(n)]
    for who in range(120):
        pool, pick = (12 if who < 40 else n), []
        while len(pick) < 4:
            c = rng.below(pool)
            if all(hidden[c] != hidden[p] for p in pick): pick.append(c)   # so a clash-free timetable exists
        for a in pick: adj[a] |= {b for b in pick if b != a}
    return [sorted(a) for a in adj]
def clashes(adj, x): return sum(x[a] == x[b] for a in range(len(adj)) for b in adj[a] if a < b)
def table(adj, x, slots):    # t[e][s]: how many of exam e's clash partners sit in slot s
    t = [[0] * slots for _ in adj]
    for a in range(len(adj)):
        for b in adj[a]: t[a][x[b]] += 1
    return t
def deltas(adj, x, slots):   # the change in clashes of every move: exam e to slot s
    t = table(adj, x, slots)
    return [t[e][s] - t[e][x[e]] for e in range(len(adj)) for s in range(slots) if s != x[e]]
def move(adj, t, x, e, s):
    for b in adj[e]: t[b][x[e]] -= 1; t[b][s] += 1
    x[e] = s
def hill(adj, x, slots, trace=None):    # steepest descent: take the best move until none improves
    t, c, looks = table(adj, x, slots), clashes(adj, x), 0
    while True:
        best, bm = 0, None
        for e in range(len(adj)):
            for s in range(slots):
                if s == x[e]: continue
                looks += 1
                if trace is not None and looks % 1000 == 0: trace.append(c)
                if t[e][s] - t[e][x[e]] < best: best, bm = t[e][s] - t[e][x[e]], (e, s)
        if bm is None: return c, looks
        move(adj, t, x, *bm); c += best
def anneal(adj, x, slots, rng, T0, alpha, steps, stop=True, trace=None):   # T0 = 0: never uphill
    t, c, T, zero_time = table(adj, x, slots), clashes(adj, x), T0, 0
    best = c
    for i in range(1, steps + 1):
        e, s = rng.below(len(adj)), rng.below(slots - 1)
        if s >= x[e]: s += 1                                 # a different slot, every one equally likely
        d = t[e][s] - t[e][x[e]]
        if d <= 0 or (T > 0 and rng.unif() < exp(-d / T)): move(adj, t, x, e, s); c += d   # Metropolis
        best, zero_time, T = min(best, c), zero_time + (c == 0), T * alpha
        if trace is not None and i % 1000 == 0: trace.append(c)
        if stop and c == 0: return 0, i, zero_time
    return best, steps, zero_time
def genetic(adj, slots, rng, size, children):   # two parents, each exam's slot from one, one random move
    pop = [[rng.below(slots) for _ in adj] for _ in range(size)]; cost = [clashes(adj, x) for x in pop]
    for i in range(1, children + 1):
        pa = [min(rng.below(size), rng.below(size), key=lambda k: (cost[k], k)) for _ in "ab"]
        child = [pop[pa[rng.below(2)]][e] for e in range(len(adj))]
        e, s = rng.below(len(adj)), rng.below(slots); child[e] = s           # mutation: one random move
        c, w = clashes(adj, child), max(range(size), key=lambda k: (cost[k], k))
        if c <= cost[w]: pop[w], cost[w] = child, c
        if c == 0: return 0
    return min(cost)
def rx(rng, n, slots): return [rng.below(slots) for _ in range(n)]
def wins(rs): return sum(r[0] == 0 for r in rs)
# ---- the instance: 40 exams, 12 slots, 120 synthetic students, seed 20261111 ----
N, SL = 40, 12
adj = build(SplitMix64(20261111), N, SL)
pairs, g = sum(len(a) for a in adj) // 2, [-1] * N
for e in range(N): g[e] = min(s for s in range(N) if all(g[b] != s for b in adj[e]))   # greedy, listed order
core = all(b in adj[a] for a in range(12) for b in range(12) if a != b)
print(f"clash pairs {pairs}, busiest exam {max(len(a) for a in adj)}, core 12 all clash {core}, greedy uses {max(g) + 1} slots")
print(f"timetables 12^40 = 10^{40 * log10(12):.2f}, moves per timetable {N * (SL - 1)}, random start expects {pairs / SL:.2f}")
# ---- hill climbing from 400 random starts, then restarts ----
rng = SplitMix64(1)
runs = [hill(adj, rx(rng, N, SL), SL) for _ in range(400)]
w, looks = wins(runs), sum(r[1] for r in runs) / 400
p, x1 = w / 400, rx(SplitMix64(1), N, SL); c1 = clashes(adj, x1)
print(f"hill: {w} of 400 reach 0, p {p:.4f}, mean looks {looks:.1f}, ends {[sum(r[0] == c for r in runs) for c in range(7)]}")
h1 = hill(adj, x1, SL); d1, t1 = deltas(adj, x1, SL), table(adj, x1, SL)
print(f"run 1: start {c1}, stuck at {h1[0]} after {h1[1]} looks; moves improve {sum(d < 0 for d in d1)}, "
      f"tie {sum(d == 0 for d in d1)}, worsen {sum(d > 0 for d in d1)}")
e0, s0 = next((e, s) for e in range(N) for s in range(SL) if s != x1[e] and t1[e][s] == t1[e][x1[e]] > 0)
print(f"a tie move in run 1: exam {e0} from slot {x1[e0]} ({t1[e0][x1[e0]]} partner there) to slot {s0} ({t1[e0][s0]} there)")
groups, pse, need = sum(wins(runs[i:i + 10]) > 0 for i in range(0, 400, 10)), sqrt(p * (1 - p) / 400), lambda q: ceil(log(0.05) / log(1 - q))
print(f"restarts: 10 runs win {1 - (1 - p) ** 10:.4f} by formula, {groups} of 40 blocks of 10; "
      f"95% needs {need(p)} runs ({need(p + 1.96 * pse)} to {need(p - 1.96 * pse)} with p +/- 1.96 se), expected looks {looks / p:.0f}")
# ---- annealing, T0 = 2, alpha = 0.9995, and the zero-temperature control, at most 20000 looks ----
rng = SplitMix64(2)
ann = [anneal(adj, rx(rng, N, SL), SL, rng, 2.0, 0.9995, 20000) for _ in range(50)]
tie = [anneal(adj, rx(rng, N, SL), SL, rng, 0.0, 1.0, 20000) for _ in range(50)]
print(f"anneal: {wins(ann)} of 50 reach 0, mean looks {sum(r[1] for r in ann) / 50:.1f}, most {max(r[1] for r in ann)}")
print(f"ties only, T = 0: {wins(tie)} of 50 reach 0, mean looks {sum(r[1] for r in tie) / 50:.1f}, most {max(r[1] for r in tie)}")
T5 = 2.0 * 0.9995 ** 5000; print(f"accept a +1 move: T 2 {exp(-1 / 2):.4f}, T 1 {exp(-1):.4f}, after 5000 looks T {T5:.4f} {exp(-1 / T5):.6f}")
xa = rx(SplitMix64(3), N, SL); ra = anneal(adj, xa, SL, SplitMix64(4), 2.0, 0.9995, 20000)
print(f"one finished timetable: {ra[1]} looks, full recount {clashes(adj, xa)} clashes, slots used {len(set(xa))}")
# ---- what breaks, and genetic moves ----
rng = SplitMix64(5); hot = [anneal(adj, rx(rng, N, SL), SL, rng, 2.0, 1.0, 20000)[0] for _ in range(20)]
s11 = [anneal(adj, rx(rng, N, 11), 11, rng, 2.0, 0.9995, 20000)[0] for _ in range(20)]
gen = [genetic(adj, SL, rng, 30, 10000) for _ in range(5)]
print(f"never cool, T 2: {hot.count(0)} of 20 reach 0, mean best {sum(hot) / 20:.2f}; 11 slots: best {min(s11)}, worst {max(s11)}")
print(f"genetic, 30 parents, 10000 children: bests {gen}")
# ---- the small timetable: 8 exams, 13 clashes, 3 slots, every timetable tried ----
E8 = [(0, 1), (0, 3), (0, 6), (1, 2), (1, 3), (1, 6), (1, 7), (2, 6), (2, 7), (4, 5), (4, 6), (5, 6), (5, 7)]
a8 = [[b for a, b in E8 if a == v] + [a for a, b in E8 if b == v] for v in range(8)]
xs = [[k // 3 ** i % 3 for i in range(8)] for k in range(3 ** 8)]
cs = [clashes(a8, x) for x in xs]
traps = [x for x, c in zip(xs, cs) if c > 0 and min(deltas(a8, x, 3)) > 0]
stuck = [x for x, c in zip(xs, cs) if c > 0 and min(deltas(a8, x, 3)) >= 0]
p8 = sum(hill(a8, list(x), 3)[0] == 0 for x in xs) / len(xs)
print(f"8 exams: timetables {len(xs)}, clash-free {cs.count(0)}, stuck {len(stuck)}, every move worse {len(traps)} with clashes {[clashes(a8, t) for t in traps]}, "
      f"trap {traps[0]}, its {len(deltas(a8, traps[0], 3))} moves add at least {min(deltas(a8, traps[0], 3))}")
rng = SplitMix64(8); sim3 = sum(any(hill(a8, rx(rng, 8, 3), 3)[0] == 0 for _ in range(3)) for _ in range(4000)) / 4000
print(f"8 exams: hill wins from {p8:.4f} of starts; 3 restarts win {1 - (1 - p8) ** 3:.4f} by formula, {sim3:.4f} simulated")
esc = [anneal(a8, list(traps[0]), 3, rng, 1.0, 0.999, 5000) for _ in range(50)]
st0 = [anneal(a8, list(traps[0]), 3, rng, 0.0, 1.0, 5000) for _ in range(50)]
print(f"from the trap: anneal T0 1 escapes {wins(esc)} of 50, mean looks {sum(r[1] for r in esc) / 50:.1f}; T = 0 escapes {wins(st0)}")
Z, ch = sum(exp(-c / 0.5) for c in cs), [anneal(a8, list(traps[0]), 3, rng, 0.5, 1.0, 50000, False)[2] / 50000 for _ in range(20)]
fixed, fse = sum(ch) / 20, sqrt(sum((v - sum(ch) / 20) ** 2 for v in ch) / 19 / 20)
print(f"T fixed 0.5, 20 runs: share of time clash-free {fixed:.4f} se {fse:.4f}, exp(-C/T)/Z over all 6561 {cs.count(0) / Z:.4f}")
# ---- chart: clashes every 1000 looks from run 1's start ----
tr_h, tr_a, tr_t = [], [], []; hill(adj, rx(SplitMix64(1), N, SL), SL, tr_h)
for T0, al, tr in ((2.0, 0.9995, tr_a), (0.0, 1.0, tr_t)): anneal(adj, rx(SplitMix64(1), N, SL), SL, SplitMix64(9), T0, al, 10000, False, tr)
for name, tr in (("hill climb", tr_h), ("anneal", tr_a), ("ties only", tr_t)):
    print(f"chart, {name:<10} {[c1] + (tr + [h1[0]] * 10)[:10]}")
assert core and max(g) + 1 == 13, "floor 12 by the clique of core exams; greedy in listed order needs 13"
assert [clashes(adj, x1[:e] + [s] + x1[e + 1:]) - h1[0] for e in range(N) for s in range(SL) if s != x1[e]] == d1, \
    "every move's change from the table equals a full recount"
assert min(d1) >= 0 and h1[0] > 0 and ra[0] == 0 == clashes(adj, xa), "run 1 is stuck; the annealed timetable recounts to 0"
assert abs(groups / 40 - (1 - (1 - p) ** 10)) < 4 * sqrt(0.25 / 40), "restart formula against blocks of runs"
assert abs(sim3 - (1 - (1 - p8) ** 3)) < 4 * sqrt(0.25 / 4000), "restart formula against exhaustion"
assert wins(st0) == 0 < wins(esc), "from a true trap only an uphill move escapes"
assert min(s11) >= 1, "11 slots can never reach 0: the 12 core exams need 12 slots"
assert abs(fixed - cs.count(0) / Z) < 4 * fse, "fixed T visits timetables in proportion to exp(-C/T)"
print("ALL CHECKS PASS")
