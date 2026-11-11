# Heuristics with a promise -- the check behind the card.  Standard library only.  Fees in £ thousand, distances in metres.
# Part 1: greedy covering of ten genres, each genre's price, the dual-fitting bound, against every lineup and a dual certificate.
# Part 2: the nearest-neighbour buggy round, improved by two-opt, checked against every one of the 2,520 rounds.
from itertools import permutations
from math import sqrt, log

GENRES = ["rock", "pop", "folk", "jazz", "soul", "indie", "techno", "hip-hop", "reggae", "metal"]
ACTS = [("P", 50, [0, 1, 2, 3, 4]), ("Q", 50, [5, 6, 7, 8, 9]), ("R", 54, [0, 1, 2, 5, 6, 7]),
        ("S", 30, [3, 4]), ("T", 36, [8, 9]), ("U", 40, [2, 3, 8]), ("V", 28, [1, 9])]
def H(k): return sum(1 / j for j in range(1, k + 1))          # the harmonic sum
def greedy(acts, n, by_fee=True):          # cheapest fee per new genre, or most new genres
    left, steps, price = set(range(n)), [], [0.0] * n
    while left:
        best = None
        for name, fee, gs in acts:
            new = [g for g in gs if g in left]
            key = (fee / len(new) if by_fee else -len(new)) if new else None
            if key is not None and (best is None or key < best[0]): best = (key, name, fee, new)
        _, name, fee, new = best
        steps.append((name, fee, new, [len([g for g in gs if g in left]) for _, _, gs in acts]))
        for g in new: price[g] = fee / len(new)
        left -= set(new)
    return steps, price

def bill(acts, by_fee=True):                # greedy's picks and its bill
    st = greedy(acts, 10, by_fee)[0]
    return " ".join(s[0] for s in st), sum(s[1] for s in st)

def cheapest(acts, n):                      # every lineup tried
    best = (float("inf"), "")
    for mask in range(1 << len(acts)):
        chosen = [a for i, a in enumerate(acts) if mask >> i & 1]
        if len({g for a in chosen for g in a[2]}) == n:
            best = min(best, (sum(a[1] for a in chosen), " ".join(a[0] for a in chosen)))
    return best

for name, fee, gs in ACTS: print(f"act {name}, fee {fee}: {' '.join(GENRES[g] for g in gs)}")
steps, price = greedy(ACTS, 10)
G = sum(s[1] for s in steps)
for k, (name, fee, new, _) in enumerate(steps, 1):
    print(f"greedy step {k}: act {name}, fee {fee}, {len(new)} new genres at {fee / len(new):.2f} each")
opt, opt_names = cheapest(ACTS, 10)
print(f"greedy lineup costs {G}; cheapest of all 128 lineups: {opt_names} at {opt}; ratio {G / opt:.2f}")
y = [9, 9, 9, 11.5, 11.5, 9, 9, 9, 11.5, 11.5]                 # dual prices, one per genre
dual_ok = all(sum(y[g] for g in gs) <= fee for _, fee, gs in ACTS)
print(f"dual prices {' '.join(f'{v:g}' for v in y)} sum to {sum(y):.2f}; every act's genres within its fee: {'yes' if dual_ok else 'no'}")
d = max(len(gs) for _, _, gs in ACTS)
print(f"promise: H({d}) = {H(d):.3f}, H(10) = {H(10):.3f}, 1 + ln 10 = {1 + log(10):.3f}")
ratios = [sum(price[g] for g in gs) / fee for _, fee, gs in ACTS]
print("greedy prices on each act / its fee: " + " ".join(f"{a[0]} {r:.3f}" for a, r in zip(ACTS, ratios)))
print(f"fitted floor {G} / H({d}) = {G / H(d):.2f}; shrinking by {max(ratios):.3f} instead gives {G / max(ratios):.2f}")
checks = held = 0                           # each price against fee / (act's genres still open)
for name, fee, new, open_counts in steps:
    for (_, f, _), k in zip(ACTS, open_counts):
        if k: checks += 1; held += fee / len(new) <= f / k
p_lines = [f"{fee / len(new):.2f} <= 50/{oc[0]} = {50 / oc[0]:.2f}" for _, fee, new, oc in steps if oc[0]]
print(f"act P's allowances: {', '.join(p_lines)}; all {held} of {checks} step checks hold")
TIGHT = [(f"solo{i}", 60 / i, [i - 1]) for i in range(1, 11)] + [("big", 61, list(range(10)))]
(_, tG), topt = bill(TIGHT), cheapest(TIGHT, 10)[0]
print(f"near-tight case, solo act i at 60/i and big act at 61: greedy {tG:.2f}, best {topt}, ratio {tG / topt:.3f} against H(10) {H(10):.3f}")
mnames, mG = bill(ACTS, by_fee=False)       # ties go to the act listed first
print(f"mistakes: raw prices as a floor {sum(price):.2f} > {opt}; act P's raw prices {sum(price[g] for g in ACTS[0][2]):.2f} > 50; most-genres greedy {mnames} costs {mG}")
BAD = [(f"solo{i}", 10, [i - 1]) for i in range(1, 11)] + [("big", 1000, list(range(10)))]
(bnames, bG), bopt = bill(BAD, by_fee=False), cheapest(BAD, 10)[0]
print(f"most-genres case, ten solo acts at 10 and a big act at 1000: most-genres greedy {bnames} {bG}, best {bopt}, ratio {bG / bopt:.3f} > H(10) {H(10):.3f}")

SITE = [("O", 30, 20), ("A", 50, 110), ("M", 100, 230), ("D", 190, 80), ("J", 380, 60),
        ("B", 380, 10), ("S", 370, 210), ("C", 100, 130)]
def dist(i, j): return sqrt((SITE[i][1] - SITE[j][1]) ** 2 + (SITE[i][2] - SITE[j][2]) ** 2)
def length(t):                              # added leg by leg, in order, as the Rust does
    total = 0.0
    for i in range(len(t)): total += dist(t[i], t[(i + 1) % len(t)])
    return total
def word(t): return "-".join(SITE[i][0] for i in t + [t[0]])
def two_opt(t, log_moves=False):            # best improving swap of two legs, until none
    t, n, moves, looks = list(t), len(t), 0, 0
    while True:
        best, at = -1e-9, None
        for i in range(n - 1):
            for j in range(i + 2, n if i else n - 1):
                a, b, c, e = t[i], t[i + 1], t[j], t[(j + 1) % n]
                looks += 1
                delta = dist(a, c) + dist(b, e) - dist(a, b) - dist(c, e)
                if delta < best: best, at = delta, (i, j)
        if at is None: return t, moves, looks
        i, j = at
        new = t[:i + 1] + t[i + 1:j + 1][::-1] + t[j + 1:]
        if log_moves:
            print(f"two-opt move {moves + 1}: drop {word([t[i], t[i + 1]])[:3]} and {word([t[j], t[(j + 1) % n]])[:3]}, "
                  f"change {best:.1f}, recount {length(new) - length(t):.1f}")
        t, moves = new, moves + 1

def crossings(t):                           # pairs of legs that cross, by orientation signs
    def o(p, q, r): return (q[1] - p[1]) * (r[2] - p[2]) - (q[2] - p[2]) * (r[1] - p[1])
    legs, count = [(SITE[t[i]], SITE[t[(i + 1) % len(t)]]) for i in range(len(t))], 0
    for x in range(len(t)):
        for z in range(x + 2, len(t) if x else len(t) - 1):
            (p, q), (r, s) = legs[x], legs[z]
            count += o(p, q, r) * o(p, q, s) < 0 and o(r, s, p) * o(r, s, q) < 0
    return count
def nearest():                              # from the office, always to the nearest stage not yet visited
    t, left = [0], set(range(1, 8))
    while left: k = min(left, key=lambda v: (dist(t[-1], v), v)); t.append(k); left.remove(k)
    return t

nn = nearest()
print(f"nearest-neighbour round {word(nn)}: {length(nn):.1f} m, {crossings(nn)} crossing pair(s)")
best_t, moves, looks = two_opt(nn, True)
print(f"two-opt round {word(best_t)}: {length(best_t):.1f} m after {moves} moves and {looks} looks, {crossings(best_t)} crossings")
rounds = [[0] + list(p) for p in permutations(range(1, 8)) if p[0] < p[-1]]
L = min(length(t) for t in rounds)
in_tree, tree = {0}, 0.0                    # Prim's cheapest connecting tree, the floor
while len(in_tree) < 8: w, v = min((dist(u, v), v) for u in in_tree for v in range(8) if v not in in_tree); tree += w; in_tree.add(v)
print(f"shortest of all {len(rounds)} rounds: {L:.1f} m; cheapest tree floor {tree:.1f} m; nearest-neighbour {100 * (length(nn) / L - 1):.1f}% above")
ends = [length(two_opt(t)[0]) for t in rounds]
hit = sum(abs(e - L) < 1e-6 for e in ends)
worst = max(range(len(rounds)), key=lambda k: ends[k])
print(f"two-opt from every round: {hit} of {len(rounds)} end at the shortest, {len(rounds) - hit} above; distinct stopping lengths {len({round(e, 6) for e in ends})}")
print(f"worst stop {word(two_opt(rounds[worst])[0])}: {ends[worst]:.1f} m, {100 * (ends[worst] / L - 1):.1f}% above, {crossings(two_opt(rounds[worst])[0])} crossings")
print("figure, scale 0.75 per m, " + " ".join(f"{p[0]}({p[1]},{p[2]})" for p in SITE))

assert opt == 100 and abs(sum(y) - opt) < 1e-9 and dual_ok          # certificate meets enumeration
assert G <= H(d) * opt and max(ratios) <= H(d) and held == checks   # the theorem, act by act
assert abs(sum(price) - G) < 1e-9                                   # every pound charged once
assert topt == 61 and tG / topt <= H(10) and tG / topt > 2.8         # nearly tight, never over
assert abs(length(best_t) - L) < 1e-6 and tree <= L                 # two-opt against enumeration
assert crossings(best_t) == 0 and crossings(nn) == 2 and all(e >= L - 1e-6 for e in ends)
assert bG / bopt > H(10) and bopt == 100                            # most genres first: no promise
R60 = [(a, 60 if a == "R" else f, gs) for a, f, gs in ACTS]
print(f"try R at 60: greedy {' costs '.join(map(str, bill(R60)))}, cheapest {cheapest(R60, 10)[0]};",
      f"dual certificate fits: {'yes' if all(sum(y[g] for g in gs) <= f for _, f, gs in R60) else 'no'}")
T59 = TIGHT[:-1] + [("big", 59, list(range(10)))]
print(f"try big act at 59: greedy {bill(T59)[0]} {bill(T59)[1]:.2f}, best {cheapest(T59, 10)[0]}, ratio {bill(T59)[1] / cheapest(T59, 10)[0]:.3f}")
y10 = y[:2] + [10] + y[3:]                  # folk's price raised to 10
print(f"try folk at 10: prices sum to {sum(y10):.2f}; overpriced acts: {' '.join(a for a, f, gs in ACTS if sum(y10[g] for g in gs) > f)}")
SITE[7] = ("C", 150, 130)                   # move the comedy tent
nn2, L2 = nearest(), min(length(t) for t in rounds); t2, m2, _ = two_opt(nn2)
print(f"try C at (150, 130): nearest-neighbour {word(nn2)} {length(nn2):.1f} m, {crossings(nn2)} crossings, {100 * (length(nn2) / L2 - 1):.1f}% above "
      f"the shortest {L2:.1f} m; two-opt reaches {length(t2):.1f} m in {m2} moves")
print("ALL CHECKS PASS")
