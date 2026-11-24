# Sperner and LYM -- the check behind the card.  Nothing is imported.  Managers
# 1 to 4; a group of them is a 4-bit mask.  Road one tries all 2^16 families of
# groups and keeps the antichains.  Road two walks the 24 arrival orders.  Road
# three splits the 16 groups into 6 chains.  The odd case n = 5 comes last.
def size(s): return bin(s).count("1")
def fact(k): return 1 if k < 2 else k * fact(k - 1)
def show(s, n=4): return "{" + ",".join(str(i + 1) for i in range(n) if s >> i & 1) + "}"
def weight(fam, n): return sum(fact(size(a)) * fact(n - size(a)) for a in fam)
def orders(rest):                         # every arrival order, built one place at a time
    return [[x] + o for x in rest for o in orders([y for y in rest if y != x])] if rest else [[]]
def hits(fam, n):                         # orders whose growing group meets fam, and the most meetings
    met = []
    for o in orders(list(range(n))):
        groups = [sum(1 << x for x in o[:j]) for j in range(n + 1)]
        met.append(sum(g in fam for g in groups))
    return sum(m > 0 for m in met), max(met)
def antichain(fam): return all(a & b != a for a in fam for b in fam if a != b)
above = [sum(1 << b for b in range(16) if a & b == a and a != b) for a in range(16)]
anti = [f for f in range(1 << 16) if all(f & above[a] == 0 for a in range(16) if f >> a & 1)]
fams = [[a for a in range(16) if f >> a & 1] for f in anti]
best = max(len(f) for f in fams)
tops = [f for f in fams if len(f) == best]
example = [0b0001, 0b0110, 0b1010, 0b1100]
print(f"groups of each size, 0 to 4: {[sum(size(a) == k for a in range(16)) for k in range(5)]}")
print(f"tidy rule books (antichains) of 4 managers: {len(fams)}; largest has {best} lines")
print(f"rule books with {best} lines: {len(tops)}: {[show(a) for a in tops[0]]}")
h, most = hits(example, 4)
print(f"example {[show(a) for a in example]}: 1/4 + 3/6 = {sum(1 / (24 // fact(size(a)) // fact(4 - size(a))) for a in example):.2f}")
room = [b for b in range(16) if b not in example and antichain(example + [b])]
print(f"  arrival orders meeting it: {h} of 24 = {h / 24:.2f}; most meetings in one order: {most}; groups that still fit: {len(room)}")
print(f"  orders through each line, k!(4-k)!: {[fact(size(a)) * fact(4 - size(a)) for a in example]}")
road_two = all(hits(f, 4) == (weight(f, 4), min(1, len(f))) for f in fams)
print(f"every antichain: orders met = sum of k!(4-k)!, never twice: {'yes' if road_two else 'no'}")
print(f"largest LYM score over all antichains: {max(weight(f, 4) for f in fams)}/24")
chains = [[0, 1, 3, 7, 15], [2, 6, 14], [4, 5, 13], [8, 9, 11], [10], [12]]
cover = sorted(a for c in chains for a in c) == list(range(16))
nested = all(c[i] & c[i + 1] == c[i] for c in chains for i in range(len(c) - 1))
print(f"16 groups split into {len(chains)} chains, sizes {[len(c) for c in chains]}: {'yes' if cover and nested else 'no'}")
pairs = [a for a in range(16) if size(a) == 2]
plus1 = pairs + [0b0001]
print(f"mistake 1, six pairs plus {{1}}: {len(plus1)} lines, {sum(a & b == a and a != b for a in plus1 for b in plus1)} nested, score {weight(plus1, 4)}/24")
print(f"mistake 2, one member per order, unweighted: at most {fact(4)} lines, not {best}")
singles = [1, 2, 4, 8]
print(f"mistake 3, the four singles meet {hits(singles, 4)[0]} of 24 orders but have {len(singles)} lines")
mid5 = {k: [a for a in range(32) if size(a) == k] for k in (2, 3)}
for k, lay in mid5.items():
    print(f"n = 5, all {k}-groups: {len(lay)} lines, antichain {'yes' if antichain(lay) else 'no'}, orders met {hits(lay, 5)[0]} of 120")
caps = [fact(n) // fact(n // 2) // fact(n - n // 2) for n in range(1, 11)]
print(f"largest tidy rule book, C(n, n//2), for n = 1 to 10: {caps}")
assert len(fams) == 168 and best == 6 == 24 // fact(2) // fact(2)     # Dedekind number; C(4,2)
assert len(tops) == 1 and tops[0] == pairs                           # only the middle layer
assert road_two and h == 18 == weight(example, 4) and room == []                   # chains agree with weights
assert max(weight(f, 4) for f in fams) == 24 and cover and nested     # LYM <= 1; 6 chains cover
assert hits(singles, 4)[0] == 24 and all(len(l) == 10 and antichain(l) for l in mid5.values())
print("ALL CHECKS PASS")
