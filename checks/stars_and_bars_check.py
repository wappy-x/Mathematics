# Stars and bars -- the check behind the card.  Nothing is imported.  Five
# identical scoops across three flavours; twelve identical tins on three
# shelves with none empty; the number 6 written as an ordered sum of positive
# parts.  Every count is reached twice, by roads that share no arithmetic.
SCOOPS, FLAVOURS, TINS, SHELVES, TARGET = 5, 3, 12, 3, 6

def choose(m, r):                          # C(m, r), built one factor at a time
    out = 1
    for i in range(r):
        out = out * (m - i) // (i + 1)
    return out

def tubs_listed(n, k, low):                # road one: write every way out in full
    if k == 0:
        return [()] if n == 0 else []
    return [(first,) + rest for first in range(low, n + 1)
            for rest in tubs_listed(n - first, k - 1, low)]

def rows_listed(n, k):                     # road two: every row of stars and bars
    slots, out = n + k - 1, []
    for mask in range(1 << slots):         # one bit per slot, a 1 means a bar
        bars = [s for s in range(slots) if (mask >> s) & 1]
        if len(bars) == k - 1:
            cut = [-1] + bars + [slots]
            out.append(tuple(cut[i + 1] - cut[i] - 1 for i in range(k)))
    return sorted(out)

def picture(tub):                          # the row of stars and bars for one tub
    return "|".join("*" * c for c in tub)

tubs = sorted(tubs_listed(SCOOPS, FLAVOURS, 0))
rows = rows_listed(SCOOPS, FLAVOURS)
ladder = [SCOOPS - c + 1 for c in range(SCOOPS + 1)]   # road three: fix the chocolate
full = tubs_listed(TINS, SHELVES, 1)
gift = tubs_listed(TINS - SHELVES, SHELVES, 0)
comps = [c for k in range(1, TARGET + 1) for c in tubs_listed(TARGET, k, 1)]
listed = [len(tubs_listed(TARGET, k, 1)) for k in range(1, TARGET + 1)]
formula = [choose(TARGET - 1, k - 1) for k in range(1, TARGET + 1)]
shapes = {tuple(sorted(t, reverse=True)) for t in tubs}
shown = [(5, 0, 0), (2, 0, 3), (0, 5, 0), (1, 2, 2)]
print(f"{SCOOPS} scoops across {FLAVOURS} flavours, a flavour may be skipped")
print("  four tubs written out: " + ", ".join(f"{t} -> {picture(t)}" for t in shown))
print(f"  every tub listed: {len(tubs)}")
print(f"  {SCOOPS} stars and {FLAVOURS - 1} bars in {SCOOPS + FLAVOURS - 1} slots: {len(rows)} rows, "
      f"the same list: {'yes' if tubs == rows else 'no'}; C(7, 2) = {choose(7, 2)}")
print(f"  chocolate 0 to {SCOOPS}, the rest shared by two flavours: {ladder}, adding to {sum(ladder)}")
print(f"{TINS} tins on {SHELVES} shelves, no shelf left empty")
print(f"  every arrangement listed: {len(full)}; C(11, 2) = {choose(11, 2)}")
print(f"  one tin to each shelf first, then {TINS - SHELVES} shared with empties allowed: {len(gift)}")
print(f"{TARGET} as an ordered sum of positive parts: {len(comps)} ways")
print(f"  split by number of parts, listed: {listed}")
print(f"  split by number of parts, from C(5, parts - 1): {formula}")
print(f"  cut or leave each of the {TARGET - 1} gaps: 2 x 2 x 2 x 2 x 2 = {2 ** (TARGET - 1)}")
print(f"wrong turns on the {SCOOPS}-scoop tub: C(7, 3) = {choose(7, 3)}, C(5, 2) = {choose(5, 2)}, "
      f"C(4, 2) = {choose(4, 2)}, flavours left unlabelled = {len(shapes)}")
assert tubs == rows and len(tubs) == choose(SCOOPS + FLAVOURS - 1, FLAVOURS - 1)
assert sum(ladder) == len(tubs) and len(tubs) == 21
assert len(full) == choose(TINS - 1, SHELVES - 1) and len(full) == len(gift)
assert listed == formula and len(comps) == 2 ** (TARGET - 1)
print("ALL CHECKS PASS")
