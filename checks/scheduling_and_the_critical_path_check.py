# Scheduling and the critical path -- the check behind the card.  Nothing is imported.
# Fitting out a new bakery: 9 jobs, durations p in working days, and arrows i -> j
# meaning "i must finish before j starts".  Then one oven, five batches, two rules.
JOBS = "ABCDEFGHI"
NAME = {"A": "strip out the old shop", "B": "plumbing and drains", "C": "three-phase electrics",
        "D": "floor tiling", "E": "fit the two ovens", "F": "counter and shelving",
        "G": "paint and signage", "H": "test bakes", "I": "hygiene inspection"}
P = {"A": 3, "B": 4, "C": 5, "D": 3, "E": 6, "F": 5, "G": 3, "H": 4, "I": 2}
ARCS = [("A", "B"), ("A", "C"), ("B", "D"), ("C", "E"), ("D", "E"),
        ("D", "F"), ("F", "G"), ("E", "H"), ("G", "I"), ("H", "I")]

def topo(arcs):                      # Kahn's peeling, lowest letter first
    ins, order = {j: sum(v == j for _, v in arcs) for j in JOBS}, []
    while len(order) < len(JOBS):
        j = min(x for x in JOBS if x not in order and ins[x] == 0)
        order.append(j)
        for u, v in arcs:
            if u == j: ins[v] -= 1
    return order

def passes(p, arcs):                 # road one: forward pass, then backward pass
    order, es, lf = topo(arcs), {}, {}
    for j in order: es[j] = max([es[i] + p[i] for i, k in arcs if k == j], default=0)
    t = max(es[j] + p[j] for j in JOBS)
    for j in reversed(order): lf[j] = min([lf[k] - p[k] for i, k in arcs if i == j], default=t)
    return order, es, lf, t

def chains(arcs):                    # road two: every chain of arrows, first job to last
    out = []
    def walk(path):
        nxt = [k for i, k in arcs if i == path[-1]]
        if not nxt: out.append(path)
        for k in nxt: walk(path + k)
    for j in JOBS:
        if all(k != j for _, k in arcs): walk(j)
    return out

def orders(items):                   # every order of the items, generated here
    if not items: yield ()
    for i, x in enumerate(items):
        for rest in orders(items[:i] + items[i + 1:]): yield (x,) + rest

order, ES, LF, T = passes(P, ARCS)
EF = {j: ES[j] + P[j] for j in JOBS}
LS = {j: LF[j] - P[j] for j in JOBS}
TF = {j: LS[j] - ES[j] for j in JOBS}
FF = {j: min([ES[k] for i, k in ARCS if i == j], default=T) - EF[j] for j in JOBS}
zero = [j for j in order if TF[j] == 0]
print(f"bakery fit-out: {len(JOBS)} jobs, {len(ARCS)} arrows, {sum(P.values())} working days of work in all")
print(f"Kahn order for the passes: {' '.join(order)}")
print("job  name                     p  ES  EF  LS  LF  TF  FF")
for j in JOBS:
    print(f"{j}    {NAME[j]:<24}{P[j]:>2}{ES[j]:>4}{EF[j]:>4}{LS[j]:>4}{LF[j]:>4}{TF[j]:>4}{FF[j]:>4}")
ch = chains(ARCS)
crit = [c for c in ch if sum(P[j] for j in c) == T][0]
print(f"makespan T = {T} working days; zero-float jobs {' '.join(zero)}")
for c in ch: print(f"road two, chain {' '.join(c)}: {' + '.join(str(P[j]) for j in c)} = {sum(P[j] for j in c)}")
through = {j: T - max(sum(P[x] for x in c) for c in ch if j in c) for j in JOBS}
print("road two, float = T - longest chain through the job: " + " ".join(f"{j}{through[j]}" for j in JOBS))
slip = {j: max(k for k in range(10) if passes({**P, j: P[j] + k}, ARCS)[3] == T) for j in JOBS}
print("road three, days each job can slip before T moves:   " + " ".join(f"{j}{slip[j]}" for j in JOBS))
both = passes({**P, "F": P["F"] + 2, "G": P["G"] + 2}, ARCS)[3]
crew = [passes(P, ARCS + [arc])[3] for arc in [("B", "C"), ("C", "B")]]
print(f"slip F by 2 alone: T = {passes({**P, 'F': 7}, ARCS)[3]}; slip F by 2 and G by 2: T = {both}")
print(f"mistake, every job end to end: {sum(P.values())} days, not {T}")
print(f"mistake, one crew for B and C: plumbing first T = {crew[0]}, electrics first T = {crew[1]}")
def wobble(p, lo):                   # every job runs p + lo, p + lo + 1 or p + lo + 2 days, all 3^9 ways
    tot, hit, alone, worst, n = 0, 0, 0, 0, 0
    for w in range(3 ** len(JOBS)):
        q, es = {}, {}
        for j in JOBS: q[j], w = p[j] + w % 3 + lo, w // 3
        for j in order: es[j] = max([es[i] + q[i] for i, k in ARCS if k == j], default=0)
        t = max(es[j] + q[j] for j in JOBS)
        tot, hit, worst, n = tot + t, hit + (t <= T), max(worst, t), n + 1
        alone += sum(q[j] for j in crit) <= T
    return tot, hit, alone, worst, n
tot, hit, alone, worst, n = wobble(P, -1)
print(f"wobble, every job p-1, p or p+1 days, all {n} cases: mean finish {tot / n:.2f} days, "
      f"on time (<= {T}) in {100 * hit / n:.1f}%, worst {worst}")
print(f"wobble, the critical path alone: mean {sum(P[j] for j in crit)} days, on time in {100 * alone / n:.1f}%")
BATCH = {"croissants": (25, 60), "sourdough": (50, 90), "baguettes": (30, 105),
         "muffins": (15, 150), "birthday cake": (60, 180)}   # bake minutes, van leaves (min after 5:00)
def score(seq, batch=BATCH):         # completions C, total completion, worst lateness, late count
    c, now = [], 0
    for b in seq: now += batch[b][0]; c.append(now)
    late = [c[i] - batch[b][1] for i, b in enumerate(seq)]
    return c, sum(c), max(late), sum(x > 0 for x in late)
def rule(key):                       # repeatedly take the batch with the smallest key
    left, out = list(BATCH), []
    while left:
        b = min(left, key=key); left.remove(b); out.append(b)
    return out
spt, edd = rule(lambda b: BATCH[b][0]), rule(lambda b: BATCH[b][1])
gut = rule(lambda b: -BATCH[b][0])
print(f"one oven, {len(BATCH)} batches, {sum(v[0] for v in BATCH.values())} minutes of baking in any order")
print("bake minutes / van leaves, minutes after 5:00: " + ", ".join(f"{b} {v[0]}/{v[1]}" for b, v in BATCH.items()))
for lab, seq in [("SPT, shortest bake first", spt), ("EDD, earliest van first", edd), ("gut, biggest batch first", gut)]:
    c, s, lmax, nl = score(seq)
    print(f"{lab}: {', '.join(seq)}")
    print(f"  done at {c}; total {s}, mean {s / len(c):.0f} min; worst lateness {lmax} min; late batches {nl}")
wt = [BATCH[b][0] * (len(spt) - i) for i, b in enumerate(spt)]   # each bake, times batches still waiting
print("SPT total, each bake counted once per batch still waiting: "
      + " + ".join(f"{BATCH[b][0]}x{len(spt) - i}" for i, b in enumerate(spt)) + f" = {sum(wt)}")
allo = [score(s) + (s,) for s in orders(tuple(BATCH))]
best_s = min(a[1] for a in allo)
best_l = min(a[2] for a in allo)
print(f"brute force, all {len(allo)} orders: least total {best_s}, orders reaching it "
      f"{sum(a[1] == best_s for a in allo)}; least worst lateness {best_l}, orders reaching it "
      f"{sum(a[2] == best_l for a in allo)}")
p7, b120, c7, ov = {**P, "C": 7}, {**BATCH, "sourdough": (50, 120)}, wobble({**P, "C": 7}, -1), wobble(P, 0)
print(f"try, C = 7: T = {passes(p7, ARCS)[3]}, chains at T {sum(sum(p7[j] for j in c) == T for c in ch)}; "
      f"wobble mean {c7[0] / c7[4]:.2f}, on time in {100 * c7[1] / c7[4]:.1f}%")
print(f"try, E = 3: T = {passes({**P, 'E': 3}, ARCS)[3]}")
print(f"try, jobs only overrun, p, p+1 or p+2 days: mean finish {ov[0] / ov[4]:.2f}, on time in {100 * ov[1] / ov[4]:.1f}%")
print(f"try, sourdough van at 120: SPT worst lateness {score(spt, b120)[2]} min; orders with every van on time "
      f"{sum(score(s, b120)[2] <= 0 for s in orders(tuple(BATCH)))} of {len(allo)}")
x = {j: 40 + 13 * ES[j] for j in JOBS}
print("figure, x = 40 + 13 per day, row y = 34 + 20 per job; bar starts and ends: "
      + " ".join(f"{j}{x[j]}-{x[j] + 13 * P[j]}" for j in JOBS) + f"; float tails end C{40 + 13 * LF['C']} "
      f"G{40 + 13 * LF['G']}; day {T} at x {40 + 13 * T}")
assert T == 22 and max(sum(P[j] for j in c) for c in ch) == T          # pass against chains
assert TF == through == slip and zero == list("ABDEHI")                 # three roads to float
assert FF["F"] == 0 and TF["F"] == 2 and both == 24 and crew == [24, 27]
assert score(spt)[1] == best_s == sum(wt) and score(edd)[2] == best_l == 0 and score(spt)[2] == 30
assert tot / n > T and hit < alone < n                                    # merging costs time
print("ALL CHECKS PASS")
