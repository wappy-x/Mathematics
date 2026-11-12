# Approximation algorithms -- the check behind the card.  One import, math, for ln.
# A synthetic city: 30 bus routes.  Stations N and S are depots, A to F outer
# termini, X, Y, Z mid-route interchanges.  A route lists the stations it calls
# at: its two ends first, then any interchange.  An inspector posted at a station
# checks every route calling there.  Every promise below meets a brute-force optimum.
import math
NAMES = "N S A B C D E F X Y Z".split()
R = ([["N", t] for t in "DEFABCDEFABCD"] + [["S", t] for t in "EFABCDEFABCDE"]
     + [["A", "B"], ["B", "C"], ["C", "A"], ["N", "S"]])        # routes 1-30, ends only
for i in range(30):                                            # interchanges on the way
    if i < 8 or 13 <= i < 21: R[i].append("X")
    elif i < 12 or 21 <= i < 25: R[i].append("Y")
    elif 26 <= i < 29: R[i].append("Z")
T = 8                                                          # stations 0-7 are termini
ID = {s: k for k, s in enumerate(NAMES)}
END = [(ID[r[0]], ID[r[1]]) for r in R]
SEES = [{i for i, r in enumerate(R) if s in r} for s in NAMES]
names = lambda ks: " ".join(NAMES[k] for k in ks)
nums = lambda rs: " ".join(str(i + 1) for i in rs)
bits = lambda m, n: [k for k in range(n) if m >> k & 1]
unchecked = lambda posts: [i for i in range(30) if not any(ID[s] in posts for s in R[i][:2])]

# PART 1: termini only.  Every route has two ends, so this is vertex cover.
covers = [m for m in range(1 << T) if not unchecked(bits(m, T))]
opt1 = min(len(bits(m, T)) for m in covers)
best1 = next(m for m in covers if len(bits(m, T)) == opt1)
matched, posts = [], set()                                     # the matching rule
for i, (u, v) in enumerate(END):
    if u not in posts and v not in posts:
        matched.append(i); posts |= {u, v}
alg1 = len(posts)
lp = None                                                      # LP: every half-step point
for code in range(3 ** T):
    x = [code // 3 ** k % 3 for k in range(T)]                 # x[k] in half-units 0, 1, 2
    if all(x[u] + x[v] >= 2 for u, v in END) and (lp is None or sum(x) < sum(lp)):
        lp = x
lpval = sum(lp) / 2
y = [2 if i in (0, 13) else 1 if 26 <= i < 29 else 0 for i in range(30)]  # a packing
load = [sum(y[i] for i, e in enumerate(END) if k in e) for k in range(T)]
rounded = [k for k in range(T) if lp[k] >= 1]
floored = [k for k in range(T) if lp[k] == 2]
half = lambda h: f"{h // 2}" + (".5" if h % 2 else "")            # half-units as text
lines = {}                                                     # depot lines and their routes
for u, v in END[:26]:
    lines[(u, v)] = lines.get((u, v), 0) + 1
three = [f"{NAMES[u]}-{NAMES[v]}" for (u, v), c in lines.items() if c == 3]
print(f"{len(R)} routes; {T} termini ({names(range(T))}); 3 interchanges (X Y Z); {len(NAMES)} stations; synthetic")
print(f"routes 1-13 leave N, 14-26 leave S, 27-29 ring A-B-C, 30 is the N-S express; "
      f"{' and '.join(three)} carry 3 routes, the other {len(lines) - len(three)} depot lines 2")
print(f"termini only, all {1 << T} sets of posts tried: fewest {opt1} ({names(bits(best1, T))})")
print(f"matching rule picks routes {nums(matched)}, no two sharing a station: posts {names(sorted(posts))} = {alg1}")
print(f"so every cover needs at least {len(matched)}; ratio {alg1}/{opt1} = {alg1 / opt1:.2f}, promise <= 2")
print(f"LP, all {3 ** T} half-step points: {half(sum(lp))} at " + ", ".join(f"{NAMES[k]} {half(lp[k])}" for k in range(T)))
print(f"packing: routes 1, 14 weight 1, routes 27 28 29 weight 0.5; heaviest station load {half(max(load))}; total {half(sum(y))}")
print(f"posts come whole, so {half(sum(lp))} means at least {-(-sum(lp) // 2)}")
print(f"rounding, post where x >= 0.5: {names(rounded)} = {len(rounded)} <= 2 x {half(sum(lp))} = {half(2 * sum(lp))}; ratio {len(rounded)}/{opt1} = {len(rounded) / opt1:.2f}")

# PART 2: any station.  A route calls at up to 3 stations: set cover.
n2 = len(NAMES)
full = [m for m in range(1 << n2) if len(set().union(*[SEES[k] for k in bits(m, n2)])) == 30]
opt2 = min(len(bits(m, n2)) for m in full)
best2 = next(m for m in full if len(bits(m, n2)) == opt2)
print("routes seen per station: " + ", ".join(f"{NAMES[k]} {len(SEES[k])}" for k in range(n2)))
left, picks, prices = set(range(30)), [], []
while left:                                                    # greedy: most new routes
    k = max(range(n2), key=lambda j: (len(SEES[j] & left), -j))
    new = len(SEES[k] & left)
    print(f"greedy pick {len(picks) + 1}: {NAMES[k]}  {'#' * new:<16} {new:>2} new of {len(left):>2} left, "
          f"price 1/{new} each <= OPT/left = {opt2}/{len(left)}")
    picks.append(k); prices.append((new, len(left))); left -= SEES[k]
H = sum(1 / k for k in range(1, 31))
f = max(len(r) for r in R)                                     # most stations on one route
print(f"any station: a route calls at up to {f}; all {1 << n2} sets tried: fewest {opt2} ({names(bits(best2, n2))})")
print(f"greedy: {len(picks)} posts ({names(picks)}); ratio {len(picks)}/{opt2} = {len(picks) / opt2:.2f}")
print(f"promise: H(30) x OPT = {H:.3f} x {opt2} = {H * opt2:.2f}; 1 + ln 30 = {1 + math.log(30):.3f}")
print(f"mistake, LP rounded down: posts {names(floored)}, routes {nums(unchecked(floored))} unchecked")
ones = [END[i][0] for i in matched]
print(f"mistake, one end of each matched route: posts {names(ones)}, route {nums(unchecked(ones))} unchecked")
print(f"mistake, LP value read as the minimum: ratio {len(rounded)}/{half(sum(lp))} = {len(rounded) / lpval:.2f} claimed, true {len(rounded) / opt1:.2f}")
print(f"mistake, greedy read as the minimum: {len(picks)} posts, {len(picks) - opt2} more than {opt2}")
assert opt1 == 4 and alg1 <= 2 * opt1 and len(matched) <= opt1          # 2-approximation
assert all(not (set(END[i]) & set(END[j])) for i in matched for j in matched if i < j)
assert all(l <= 2 for l in load) and sum(y) == sum(lp) == 7             # LP = 3.5 two ways
assert lpval <= opt1 and not unchecked(rounded) and len(rounded) <= 2 * lpval
assert opt2 == 3 and f == 3 and len(picks) <= H * opt2 and len(picks) > opt2         # greedy misses here
assert all(opt2 * new >= l for new, l in prices)                         # price <= OPT/left
assert math.log(31) < H <= 1 + math.log(30)                              # integral bounds on H(30)
assert len(unchecked(floored)) == 3 and len(unchecked(ones)) == 1 and three == ["N-D", "S-E"]
FIG = {"N": (40, 140), "S": (320, 140), "D": (180, 26), "E": (180, 66),
       "F": (180, 106), "B": (180, 172), "A": (222, 206), "C": (138, 206)}
print("figure, " + " ".join(f"{k} ({x},{y})" for k, (x, y) in FIG.items()))
print("ALL CHECKS PASS")
