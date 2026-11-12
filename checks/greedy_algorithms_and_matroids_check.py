# Greedy: the check behind the card.  Standard library only, nothing imported.  Twelve talk
# proposals for one lecture room, 9:00 to 18:00 (synthetic).  Roads: the earliest-finish greedy
# against brute force over all 4,096 subsets; the staying-ahead claim tested on every schedule;
# a table (dynamic programming) against brute force when talks carry audiences; and the matroid
# exchange test with seeded random weights, on the talks and on wing 04's eleven campus runs.
TALKS = [("A", "9:00", "13:00", 120), ("B", "9:30", "10:30", 60), ("C", "10:00", "11:15", 50),
         ("D", "10:45", "12:00", 70), ("E", "11:45", "12:30", 55), ("F", "12:15", "13:30", 40),
         ("G", "13:00", "14:00", 80), ("H", "13:50", "14:40", 30), ("I", "14:30", "15:30", 75),
         ("J", "15:00", "16:30", 65), ("K", "16:00", "17:30", 90), ("L", "17:15", "18:00", 35)]
def mins(s): h, m = s.split(":"); return 60 * int(h) + int(m)
NAME = [t[0] for t in TALKS]; S = [mins(t[1]) for t in TALKS]; F = [mins(t[2]) for t in TALKS]
AUD = [t[3] for t in TALKS]; n = len(TALKS)
def clash(i, j): return i != j and S[i] < F[j] and S[j] < F[i]
def fits(mask): return all(not clash(i, j) for i in range(n) for j in range(i) if mask >> i & 1 and mask >> j & 1)
def names(mask): return " ".join(NAME[i] for i in range(n) if mask >> i & 1)
def aud(mask): return sum(AUD[i] for i in range(n) if mask >> i & 1)
def size(mask): return bin(mask).count("1")
def greedy(order, ok):              # walk the order, keep each item that still fits
    kept = 0
    for i in order:
        if ok(kept | 1 << i): kept |= 1 << i
    return kept
CLASHES = [sum(clash(i, j) for j in range(n)) for i in range(n)]
by_finish = sorted(range(n), key=lambda i: F[i])
rules = [("earliest finish", by_finish), ("earliest start", sorted(range(n), key=lambda i: S[i])),
         ("shortest first", sorted(range(n), key=lambda i: (F[i] - S[i], S[i]))),
         ("fewest clashes", sorted(range(n), key=lambda i: (CLASHES[i], S[i]))),
         ("biggest audience", sorted(range(n), key=lambda i: -AUD[i]))]
SETS = [m for m in range(1 << n) if fits(m)]          # every schedule the room allows
best = max(size(m) for m in SETS)
print(f"{n} talks, {1 << n} subsets, {len(SETS)} fit the room, most talks in one schedule {best}")
print("clashes per talk: " + " ".join(f"{NAME[i]} {CLASHES[i]}" for i in range(n)))
print("audience per talk: " + " ".join(f"{NAME[i]} {AUD[i]}" for i in range(n)))
res = {}
for label, order in rules:
    res[label] = g = greedy(order, fits)
    print(f"rule {label:<16}: keeps {names(g):<12} = {size(g)} talks, audience {aud(g)}")
g, last, looks, log = 0, 0, 0, []                     # the real walk: one comparison per talk
for i in by_finish:
    looks += 1
    if S[i] >= last: g, last = g | 1 << i, F[i]
    log.append(f"{NAME[i]} {TALKS[i][1]}-{TALKS[i][2]} {'keep' if g >> i & 1 else 'skip'}")
kept = [i for i in by_finish if g >> i & 1]
print("walk by finish: " + " | ".join(log))
ahead, checked = True, 0                              # staying ahead, on every schedule
for m in SETS:
    ends = sorted(F[i] for i in range(n) if m >> i & 1)
    checked += 1
    ahead = ahead and all(ends[k] >= F[kept[k]] for k in range(len(ends)) if k < len(kept))
print(f"staying ahead: in all {checked} schedules the k-th talk ends no sooner than greedy's: {'yes' if ahead else 'no'}")
print(f"schedules with {best} talks: {sum(size(m) == best for m in SETS)}; cost: {looks} comparisons after the sort, against {1 << n} subsets")
# audiences: biggest-first greed against a table and against brute force
order = by_finish
p = [max([k + 1 for k in range(j) if F[order[k]] <= S[order[j]]] or [0]) for j in range(n)]
table = [0] * (n + 1)
for j in range(n):
    table[j + 1] = max(table[j], AUD[order[j]] + table[p[j]])
bw = max(SETS, key=aud)
print("table, best audience using the first j talks by finish: " + " ".join(map(str, table)))
print(f"best audience by brute force {aud(bw)} with {names(bw)}; by the table {table[n]}")
gw = res["biggest audience"]
print(f"biggest audience first: {aud(gw)}, short by {aud(bw) - aud(gw)}; earliest finish: {aud(g)}")
# matroids: the exchange property, and greed under random weights
def exchange_failures(ind, items):
    bad = 0
    for I in ind:
        for J in ind:
            if size(J) > size(I) and not any(J >> x & 1 and not I >> x & 1 and (I | 1 << x) in ind for x in range(items)):
                bad += 1
    return bad
A, B, D = 1, 1 << 1, 1 << 3
print(f"exchange test on the talks: {{A}} against {{B, D}}: can B or D join A? {'yes' if fits(A | B) or fits(A | D) else 'no'}")
TS = set(SETS)
sizes = sorted({size(m) for m in SETS if all(m >> i & 1 or not fits(m | 1 << i) for i in range(n))})
print(f"talks: failing pairs {exchange_failures(TS, n)}; sizes of schedules nothing can join: {sizes}")
RUNS = [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6),
        (4, 5, 8), (4, 6, 9), (5, 6, 11)]
def forest(mask):                                      # no loop among the chosen runs
    root = list(range(7))
    def r(x):
        while root[x] != x: x = root[x]
        return x
    for k in range(len(RUNS)):
        if mask >> k & 1:
            a, b = r(RUNS[k][0]), r(RUNS[k][1])
            if a == b: return False
            root[a] = b
    return True
FS = {m for m in range(1 << len(RUNS)) if forest(m)}
fsizes = sorted({size(m) for m in FS if all(m >> k & 1 or (m | 1 << k) not in FS for k in range(len(RUNS)))})
print(f"campus runs: {len(FS)} loop-free sets, failing pairs {exchange_failures(FS, len(RUNS))}; sizes of sets nothing can join: {fsizes}")
cheap = greedy(sorted(range(len(RUNS)), key=lambda k: RUNS[k][2]), lambda m: m in FS)
print(f"cheapest-first greed on the runs: {sum(RUNS[k][2] for k in range(len(RUNS)) if cheap >> k & 1)}")
SEED = state = 2026                                    # SplitMix64, seeded
def nxt():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2**64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2**64
    return z ^ (z >> 31)
miss = {"talks": 0, "runs": 0}
for trial in range(200):
    for label, fam, items in (("talks", TS, n), ("runs", FS, len(RUNS))):
        w = [nxt() % 100 + 1 for _ in range(items)]
        val = lambda m: sum(w[i] for i in range(items) if m >> i & 1)
        gm = greedy(sorted(range(items), key=lambda i: -w[i]), lambda m: m in fam)
        miss[label] += val(gm) < max(val(m) for m in fam)
print(f"200 random weightings (SplitMix64, seed {SEED}), heaviest-first misses the best: talks {miss['talks']}, runs {miss['runs']}")
coins, amount = [4, 3, 1], 6                           # greed on coins {1, 3, 4}
left, used = amount, 0
for c in coins:
    used += left // c; left %= c
print(f"coins 1, 3, 4 for 6: greedy uses {used} coins (4 + 1 + 1), best is 2 (3 + 3)")
print("figure, x of start-end per talk: " + " ".join(f"{NAME[i]} {40 + (S[i] - 540) * 3 // 5}-{40 + (F[i] - 540) * 3 // 5}" for i in range(n)))
assert g == res["earliest finish"] and size(g) == best == 6 and sum(size(m) == best for m in SETS) == 1 and ahead
assert size(res["earliest start"]) == 4 and size(res["shortest first"]) == 5 and size(res["fewest clashes"]) == 5
assert table[n] == aud(bw) == 375 and aud(gw) == 365
assert exchange_failures(FS, len(RUNS)) == 0 and miss["runs"] == 0 and miss["talks"] > 0
assert sum(RUNS[k][2] for k in range(len(RUNS)) if cheap >> k & 1) == 39 and used == 3
print("ALL CHECKS PASS")
