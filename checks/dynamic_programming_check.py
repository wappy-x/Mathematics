# Dynamic programming -- the check behind the card.  Nothing is imported.
# A trader packs a 15 kg rucksack for a fair from 6 items; each goes in whole or not at all.
# K(i, w) = the most value from the first i items with w kg of room.
NAMES = ["books", "soap", "wool", "cheese", "honey", "candles"]
KG = [6, 4, 7, 5, 3, 2]                   # weight of item 1..6, kg
GBP = [100, 60, 135, 95, 80, 50]          # what it sells for, pounds
CAP = 15

def table(kg, gbp, cap):                  # road one: fill the table forwards, row by row
    K, cells = [[0] * (cap + 1)], 0
    for i in range(1, len(kg) + 1):
        row = []
        for w in range(cap + 1):
            skip = K[i - 1][w]
            take = gbp[i - 1] + K[i - 1][w - kg[i - 1]] if kg[i - 1] <= w else -1
            row.append(max(skip, take)); cells += 1
        K.append(row)
    return K, cells

def solve(kg, gbp, cap, memo, seen=None): # road two: recurse backwards from K(n, cap); memo=None is naive
    calls = [0]
    def K(i, w):
        calls[0] += 1
        if seen is not None:
            seen[(i, w)] = seen.get((i, w), 0) + 1
        if memo is not None and (i, w) in memo:
            return memo[(i, w)]
        best = 0 if i == 0 else K(i - 1, w)
        if i > 0 and kg[i - 1] <= w:
            best = max(best, gbp[i - 1] + K(i - 1, w - kg[i - 1]))
        if memo is not None:
            memo[(i, w)] = best
        return best
    return K(len(kg), cap), calls[0]

def brute(kg, gbp, cap):                  # road three: every one of the 2^n packings
    best, legal = 0, 0
    for m in range(2 ** len(kg)):
        w = sum(kg[j] for j in range(len(kg)) if m >> j & 1)
        if w <= cap:
            legal += 1
            best = max(best, sum(gbp[j] for j in range(len(kg)) if m >> j & 1))
    return best, legal

def greedy(order):                        # mistake: pack in a fixed order while things fit
    room, val, took = CAP, 0, []
    for j in order:
        if KG[j] <= room:
            room, val = room - KG[j], val + GBP[j]; took.append(NAMES[j])
    return val, took

K, cells = table(KG, GBP, CAP)
print("items: " + ", ".join(f"{i + 1} {NAMES[i]} {KG[i]} kg {GBP[i]}" for i in range(6)))
print("table K(i, w), rows i = 0..6, columns w = 0..15 kg")
for i, row in enumerate(K):
    print(f"  i={i}" + "".join(f"{v:4d}" for v in row))
w, took = CAP, []
for i in range(6, 0, -1):                 # read the packing back: did row i change the answer?
    if K[i][w] != K[i - 1][w]:
        took.append(i); w -= KG[i - 1]
took.reverse()
for i in (6, 3):                          # two cells, written out
    r = CAP - KG[i - 1]
    print(f"cell K({i},{CAP}) = max(K({i - 1},{CAP}), {GBP[i - 1]} + K({i - 1},{r})) = "
          f"max({K[i - 1][CAP]}, {GBP[i - 1] + K[i - 1][r]}) = {K[i][CAP]}")
print("packing: " + " + ".join(NAMES[i - 1] for i in took) + f", {sum(KG[i - 1] for i in took)} kg, "
      + " + ".join(str(GBP[i - 1]) for i in took) + f" = {sum(GBP[i - 1] for i in took)}")
seen = {}
best_naive, calls_naive = solve(KG, GBP, CAP, None, seen)
memo = {}
best_memo, calls_memo = solve(KG, GBP, CAP, memo)
best_brute, legal = brute(KG, GBP, CAP)
print(f"small questions: (6 + 1) x ({CAP} + 1) = {7 * (CAP + 1)}; packings with 20 items: {2 ** 20}")
print(f"table: {cells} cells filled, best {K[6][CAP]}")
print(f"naive recursion: {calls_naive} calls, best {best_naive}")
print(f"memoised: {calls_memo} calls, {len(memo)} different subproblems, best {best_memo}")
print(f"brute force: 64 packings, {legal} fit, best {best_brute}")
print(f"naive repeats: {len(seen)} different subproblems; K(3,10) asked {seen.get((3, 10), 0)} times, value {K[3][10]}")
ratio = sorted(range(6), key=lambda j: -GBP[j] / KG[j])
for label, order in (("value per kg", ratio), ("highest value", sorted(range(6), key=lambda j: -GBP[j]))):
    v, t = greedy(order)
    print(f"wrong: greedy by {label}: {' + '.join(t)} = {v}")
one = [0] * (CAP + 1)                     # wrong: one row updated left to right, so items repeat
for j in range(6):
    for w in range(KG[j], CAP + 1):
        one[w] = max(one[w], GBP[j] + one[w - KG[j]])
print(f"wrong: one row filled left to right, items reused: {one[CAP]}")
bad = {}                                  # wrong: memo keyed on the item count, room forgotten
def badK(i, w):
    if i in bad:
        return bad[i]
    best = 0 if i == 0 else badK(i - 1, w)
    if i > 0 and KG[i - 1] <= w:
        best = max(best, GBP[i - 1] + badK(i - 1, w - KG[i - 1]))
    bad[i] = best
    return best
print(f"wrong: memo keyed on i alone: {badK(6, CAP)}")
pw = [1, 2, 4, 8, 16, 32]                 # no overlap: every packing leaves a different room
pm = {}
print(f"no overlap, weights 1,2,4,8,16,32 kg, room 63: naive {solve(pw, pw, 63, None)[1]} calls, "
      f"memoised {solve(pw, pw, 63, pm)[1]} calls, {len(pm)} subproblems")
print(f"weights in grams: table {6 * (15000 + 1)} cells, not {cells}")

def splitmix(s):                          # SplitMix64, written out, for the synthetic shops
    s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return s, z ^ (z >> 31)
print("synthetic, seed 2026, weights 1-10 kg, values 10-99, room 50 kg")
chart = []
for n in (4, 8, 12, 16, 20):
    s, kg, gbp = 2026, [], []
    for _ in range(n):
        s, a = splitmix(s); s, b = splitmix(s)
        kg.append(1 + a % 10); gbp.append(10 + b % 90)
    Kn, cn = table(kg, gbp, 50)
    bn, nc = solve(kg, gbp, 50, None)
    mm = {}
    bm, mc = solve(kg, gbp, 50, mm)
    assert Kn[n][50] == bn == bm, "three roads disagree on a synthetic shop"
    chart.append((n, nc, cn))
    print(f"  n={n:2d}: naive {nc:8d} calls, memo {len(mm):4d} subproblems, table {cn:4d} cells, best {bn}")
print("chart, items " + " ".join(str(c[0]) for c in chart))
print("chart, naive calls " + " ".join(str(c[1]) for c in chart))
print("chart, table cells " + " ".join(str(c[2]) for c in chart))

assert K[6][CAP] == best_brute == 310, "table against all 64 packings"
assert best_naive == best_memo == best_brute, "both recursions against brute force"
assert sum(GBP[i - 1] for i in took) == K[6][CAP] and sum(KG[i - 1] for i in took) <= CAP
assert calls_memo < calls_naive and seen.get((3, 10), 0) == 2, "the overlap the card names"
assert one[CAP] > best_brute, "reusing items must beat the honest best"
print("ALL CHECKS PASS")
