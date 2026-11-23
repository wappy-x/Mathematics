# Pseudo-polynomial time -- the check behind the card.  Standard library only:
# math for log10.  A van carries at most 800 kg; five parcels, each taken whole
# or left.  Three roads to the best fee: the capacity table (counting cells),
# brute force over all 32 packings, and a list of reachable (weight, fee) pairs.
# Then the same parcels in finer units: the answer stays, the table explodes.
import math
NAMES = ["tiles", "timber", "boiler", "piano", "fridge"]
KG, FEE, VAN = [300, 400, 200, 500, 100], [90, 110, 70, 150, 40], 800

def bits(x):  # binary digits needed to write x (at least 1)
    b = 1
    while x > 1:
        x //= 2
        b += 1
    return b

def table(w, v, cap):  # capacity table K(i, c); returns last row, cells filled
    row, cells = [0] * (cap + 1), cap + 1          # row 0: no parcels, all zero
    for i in range(len(w)):
        new = row[:]
        for c in range(cap + 1):
            cells += 1
            if w[i] <= c and v[i] + row[c - w[i]] > new[c]:
                new[c] = v[i] + row[c - w[i]]
        row = new
    return row, cells

def brute(w, v, cap):  # every one of the 2^k packings
    best, pick = -1, 0
    for s in range(1 << len(w)):
        tw = sum(w[i] for i in range(len(w)) if s >> i & 1)
        tv = sum(v[i] for i in range(len(w)) if s >> i & 1)
        if tw <= cap and tv > best:
            best, pick = tv, s
    return best, pick

def pairs(w, v, cap):  # reachable (weight, fee) pairs, dominated ones dropped
    L, biggest = [(0, 0)], 1
    for i in range(len(w)):
        M = L + [(a + w[i], b + v[i]) for a, b in L if a + w[i] <= cap]
        M.sort(key=lambda p: (p[0], -p[1]))        # by weight; at equal weight, highest fee first
        L = []
        for a, b in M:                             # keep a pair only if it pays more than all lighter ones
            if not L or b > L[-1][1]:
                L.append((a, b))
        assert all(p[0] < q[0] and p[1] < q[1] for p, q in zip(L, L[1:])), "no kept pair is dominated"
        biggest = max(biggest, len(L))
    return L[-1][1], biggest

def size(w, v, cap):  # input length n: binary digits of every number
    return sum(bits(x) for x in w + v) + bits(cap)

print("van " + str(VAN) + " kg; " + ", ".join(f"{NAMES[i]} {KG[i]} kg {FEE[i]}" for i in range(5)))
row, _ = table([x // 100 for x in KG], FEE, VAN // 100)
assert row == [brute([x // 100 for x in KG], FEE, c)[0] for c in range(9)], "table row vs brute force"
print("capacity table, 0 to 800 kg in 100 kg steps:", " ".join(str(x) for x in row))
res = {}
for unit, per in (("100 kg", 1), ("1 kg", 100), ("1 g", 100000)):
    w, cap = [x * per // 100 for x in KG], VAN * per // 100
    row, cells = table(w, FEE, cap)
    bb, pick = brute(w, FEE, cap)
    pp, big = pairs(w, FEE, cap)
    n = size(w, FEE, cap)
    res[unit] = (n, cells)
    print(f"unit {unit:>6}: W {cap:>6}, n {n:>3} bits, cells {cells:>7} = 6 x {cap + 1}; "
          f"table {row[cap]}, brute {bb}, pairs {pp} (list <= {big})")
    print("  binary digits: weights", " ".join(str(bits(x)) for x in w), "| van", bits(cap),
          "| fees", " ".join(str(bits(x)) for x in FEE))
    assert row[cap] == bb == pp == 260, "three roads must agree"
    assert big <= min(1 << len(w), cap + 1), "the list stays within 2^k and W + 1"
    assert cells == (len(w) + 1) * (cap + 1), "counted cells must match (k+1)(W+1)"
print("best packing:", " + ".join(NAMES[i] for i in range(5) if pick >> i & 1), "= 800 kg, 260")
print(f"n grew {res['100 kg'][0]} -> {res['1 g'][0]} bits (x{res['1 g'][0] / res['100 kg'][0]:.2f}); "
      f"cells grew {res['100 kg'][1]} -> {res['1 g'][1]} (x{res['1 g'][1] / res['100 kg'][1]:.0f})")
# doubling every weight and the van: answer fixed, 6 more bits, about twice the cells
prev = 0
for j in range(4):
    w, cap = [x << j for x in KG], VAN << j
    _, cells = table(w, FEE, cap)
    assert brute(w, FEE, cap)[0] == 260 and size(w, FEE, cap) == 87 + 6 * j
    print(f"doubled {j} times: n {size(w, FEE, cap)} bits, cells counted {cells}"
          + (f", ratio {cells / prev:.4f}" if prev else ""))
    assert prev == 0 or 1.99 < cells / prev < 2, "one more bit per number doubles the table"
    prev = cells
print("chart: j, n bits, cells (formula), log10 cells, n^3, log10 n^3")
chart_cells, chart_cube = [], []
cnt = {j: (size([x << j for x in KG], FEE, VAN << j), table([x << j for x in KG], FEE, VAN << j)[1]) for j in (0, 10)}
for j in (0, 10, 20, 30, 40):
    n, cells = 87 + 6 * j, 6 * ((VAN << j) + 1)
    assert j not in cnt or cnt[j] == (n, cells), "chart points 0 and 10 are counted tables"
    chart_cells.append(f"{math.log10(cells):.2f}")
    chart_cube.append(f"{math.log10(n ** 3):.2f}")
    print(f"  {j:>2} {n:>3} {cells:>16} {chart_cells[-1]:>5} {n ** 3:>8} {chart_cube[-1]}")
print("chart line, table:", ", ".join(chart_cells))
print("chart line, n^3:  ", ", ".join(chart_cube))
assert cnt[0][1] < cnt[0][0] ** 3 and cnt[10][1] > cnt[10][0] ** 3, "counted tables: under n^3 at 87 bits, over it at 147"
# unary: one mark per unit, so the length is at least W and the table is polynomial
for unit, per in (("1 kg", 100), ("1 g", 100000)):
    w, cap = [x * per // 100 for x in KG], VAN * per // 100
    nu, (nb, cells) = sum(w) + sum(FEE) + cap, res[unit]      # marks; binary length and cells counted above
    assert cells <= (len(w) + 1) * (nu + 1) <= (nu + 1) ** 2, "unary length bounds the counted table"
    assert cells > (len(w) + 1) * (nb + 1), "the same bound fails against the binary length"
    print(f"unary, unit {unit}: n {nu} marks, cells {cells} <= (k+1)(n+1) = {(len(w) + 1) * (nu + 1)}; "
          f"against binary n {nb}, (k+1)(n+1) = {(len(w) + 1) * (nb + 1)} fails")
# what breaks: rounding true weights to 100 kg to keep the table small
TRUE = [330, 420, 240, 470, 140]
rnd = [(x + 50) // 100 for x in TRUE]
_, pick = brute(rnd, FEE, VAN // 100)
load = sum(TRUE[i] for i in range(5) if pick >> i & 1)
exact, epick = brute(TRUE, FEE, VAN)
row, cells = table(TRUE, FEE, VAN)
assert row[VAN] == exact and load > VAN
print(f"rounded table packs " + " + ".join(NAMES[i] for i in range(5) if pick >> i & 1)
      + f": truly {load} kg, {load - VAN} kg over; exact best {exact} ("
      + " + ".join(NAMES[i] for i in range(5) if epick >> i & 1)
      + f", {sum(TRUE[i] for i in range(5) if epick >> i & 1)} kg) in {cells} cells")
print(f"counting parcels only: k = 5 for both {res['100 kg'][1]} and {res['1 g'][1]} cells")
# try changing: a table by fee instead of weight; ten parcels; decimal digits
v_row, v_cells = [0] + [10 ** 9] * sum(FEE), 0       # least weight for each exact fee
for i in range(5):
    for f in range(sum(FEE), -1, -1):
        v_cells += 1
        if f >= FEE[i] and v_row[f - FEE[i]] + KG[i] < v_row[f]:
            v_row[f] = v_row[f - FEE[i]] + KG[i]
best_by_fee = max(f for f in range(sum(FEE) + 1) if v_row[f] <= VAN)
assert best_by_fee == 260
print(f"try: table by fee: best {best_by_fee}, cells {v_cells + sum(FEE) + 1}; in pence {6 * (100 * sum(FEE) + 1)}")
_, c10 = table(KG * 2, FEE * 2, VAN)
print(f"try: ten parcels (each twice), 1 kg unit: cells {c10}, best {brute(KG * 2, FEE * 2, VAN)[0]}")
dec = lambda x: len(str(x))
print(f"try: decimal digits: n {sum(dec(x) for x in KG + FEE) + dec(VAN)} at 1 kg, "
      f"{sum(dec(x * 1000) for x in KG) + sum(dec(x) for x in FEE) + dec(VAN * 1000)} at 1 g")
print("ALL CHECKS PASS")
