# Permutations -- the check behind the card.  Nothing is imported.  A shuffle of n
# places is a list of destinations: entry i says where the card lying in place i
# goes.  Composition does the right-hand shuffle first, so rt means t and then r.
# Every number quoted on the card is printed here, and each answer is reached by
# two roads: the count by listing every shuffle and by multiplying n down to 1,
# the even-or-odd label by out-of-order pairs and by places minus cycles, the
# square's symmetries by the turn-and-flip rule and by keeping corner neighbours.
def all_shuffles(n):                   # road one to the count: pick unused places
    def grow(used):
        if len(used) == n: return [tuple(used)]
        return [s for d in range(1, n + 1) if d not in used for s in grow(used + [d])]
    return grow([])
def multiply_down(n):                  # road two to the count: n x (n - 1) x ... x 1
    total = 1
    for k in range(2, n + 1): total = total * k
    return total
def compose(a, b): return tuple(a[j - 1] for j in b)          # do b first, then a
def undo(a): return tuple(a.index(i) + 1 for i in range(1, len(a) + 1))
def cycles(a):                         # follow each place until it comes back
    seen, out = set(), []
    for start in range(1, len(a) + 1):
        if start in seen: continue
        cyc, j = [], start
        while j not in seen:
            cyc.append(j); seen.add(j); j = a[j - 1]
        out.append(cyc)
    return out
def name(a):                           # cycle notation, single places left out
    return "".join("(" + " ".join(str(x) for x in c) + ")" for c in cycles(a) if len(c) > 1) or "e"
def out_of_order(a):                   # pairs of places standing in the wrong order
    return sum(1 for i in range(len(a)) for j in range(i + 1, len(a)) if a[i] > a[j])
def swaps(a): return len(a) - len(cycles(a))                  # places minus cycles
def parity(a): return "odd" if swaps(a) % 2 else "even"
def row(a): return " ".join(str(x) for x in a)

s3, s4 = all_shuffles(3), all_shuffles(4)
e, r, t, four = (1, 2, 3), (2, 3, 1), (2, 1, 3), (2, 3, 4, 1)
print("the six shuffles of three cards: destinations, cycle name, even or odd")
for p in s3:
    print(f"  {row(p)}  {name(p):<9}{parity(p)}")
print(f"swap then shift, rt: destinations {row(compose(r, t))} = {name(compose(r, t))}")
print(f"shift then swap, tr: destinations {row(compose(t, r))} = {name(compose(t, r))}")
print(f"the undo of r: destinations {row(undo(r))} = {name(undo(r))}")
print(f"r as swaps: 3 places minus {len(cycles(r))} cycle = {swaps(r)} swaps, {parity(r)}")
print(f"out-of-order pairs in {row(r)}: {out_of_order(r)}, so {parity(r)}")
counts = [len(all_shuffles(k)) for k in range(1, 6)]
print("shuffles of 1, 2, 3, 4, 5 places: " + ", ".join(str(c) for c in counts))
print(f"S_3 splits: even {sum(1 for p in s3 if swaps(p) % 2 == 0)}, "
      f"odd {sum(1 for p in s3 if swaps(p) % 2)}")
print(f"the four-cycle {name(four)}: {swaps(four)} swaps, {parity(four)}")
tile = {tuple((s * i + k) % 4 + 1 for i in range(4)) for s in (1, -1) for k in range(4)}
rigid = {p for p in s4 if all((p[(i + 1) % 4] - p[i]) % 4 in (1, 3) for i in range(4))}
print(f"corner shuffles of the square: {len(s4)}; rigid symmetries among them: {len(tile)}")
print(f"the list 2 2 1 is a shuffle: {'yes' if len(set((2, 2, 1))) == 3 else 'no'}")
assert counts == [multiply_down(k) for k in range(1, 6)]
assert all(out_of_order(p) % 2 == swaps(p) % 2 for p in s4)
assert compose(r, t) == (3, 2, 1) and compose(t, r) == (1, 3, 2) and undo(r) == (3, 1, 2)
assert all(compose(p, undo(p)) == e and all(compose(p, q) in s3 for q in s3) for p in s3) and tile == rigid
print("ALL CHECKS PASS")
