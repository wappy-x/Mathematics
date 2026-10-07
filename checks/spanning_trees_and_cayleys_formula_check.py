# Spanning trees and Cayley's formula -- the check behind the card.  Nothing is imported.  Villages
# Ayle, Brook, Crag, Dale, then Ember.  A layout reaches every village and holds no loop.  Counted
# twice, by trying every choice of roads and by decoding every Prufer word, a determinant third.
NAMES = ["Ayle", "Brook", "Crag", "Dale", "Ember"]
SPARSE = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4)]
FULL = {n: [(i, j) for i in range(n) for j in range(i + 1, n)] for n in (4, 5)}

def flood(n, edges):                  # rings out from Ayle; each village keeps the road that reached it
    rings, kept = [[0]], []
    while rings[-1]:
        seen = {v for r in rings for v in r}
        nxt = sorted({w for v in rings[-1] for e in edges for w in e if v in e and w not in seen})
        kept += [min((min(v, w), max(v, w)) for v in rings[-1] if tuple(sorted((v, w))) in edges) for w in nxt]
        rings.append(nxt)
    return rings[:-1], tuple(sorted(kept))

def is_tree(n, edges):                # n-1 roads, and the flood reaches every village
    return len(edges) == n - 1 and sum(len(r) for r in flood(n, edges)[0]) == n

def by_listing(n, roads):             # road one: try every choice of n-1 of the roads
    tried = [tuple(r for i, r in enumerate(roads) if m >> i & 1) for m in range(1 << len(roads))]
    tried = [s for s in tried if len(s) == n - 1]
    return len(tried), sorted(s for s in tried if is_tree(n, s))

def decode(n, word):                  # road two: a word of n-2 names back into a layout
    deg, edges = [1 + list(word).count(v) for v in range(n)], []
    for letter in word:
        leaf = min(v for v in range(n) if deg[v] == 1)
        edges.append((min(leaf, letter), max(leaf, letter))); deg[leaf] -= 1; deg[letter] -= 1
    return tuple(sorted(edges + [tuple(v for v in range(n) if deg[v] == 1)]))

def det3(m):                          # road three: a 3-by-3 determinant, multiplied out here
    return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
def show(edges): return " ".join(f"{NAMES[u]}-{NAMES[v]}" for u, v in edges)
def say(vs): return " ".join(NAMES[v] for v in vs)

print(f"four villages {say(range(4))}; roads possible {len(FULL[4])}; each layout uses 3 roads")
counts, four = [], []
for label, n, roads in (("all 6 roads", 4, FULL[4]), ("all 10 roads", 5, FULL[5]), ("6 of the 10", 5, SPARSE)):
    tried, listed = by_listing(n, roads)
    words = sorted({decode(n, [m // n ** i % n for i in range(n - 2)]) for m in range(n ** (n - 2))})
    fit = [t for t in words if all(e in roads for e in t)]
    print(f"{n} villages, {label}: {tried} choices of {n - 1} roads tried, layouts by listing "
          f"{len(listed)}, from the {len(words)} words {len(fit)}")
    assert listed == fit and len(words) == n ** (n - 2)
    counts.append(len(listed)); four = listed if n == 4 else four
stars = sum(1 for t in four if max(sum(v in e for e in t) for v in range(4)) == 3)
rings, tree = flood(5, SPARSE)
print("the flood from Ayle over the sparse map, rings: " + " | ".join(f"{i} " + say(r) for i, r in enumerate(rings)))
print(f"  the layout it keeps: {show(tree)}; roads {len(tree)}; a tree: {'yes' if is_tree(5, tree) else 'no'}")
print(f"the word {say([1, 2])} decodes to {show(decode(4, [1, 2]))}, and {say([0, 0])} to {show(decode(4, [0, 0]))}")
k4tab = [[3, -1, -1], [-1, 3, -1], [-1, -1, 3]]
print(f"the four-village table, one row and column cut, has determinant {det3(k4tab)}")
print(f"Cayley 4^2 = {4 ** 2} and 5^3 = {5 ** 3}; the 16 plans are {stars} stars and "
      f"{counts[0] - stars} lines; 6 of the 10 roads allow {counts[2]}")
assert counts == [4 ** 2, 5 ** 3, 8] and det3(k4tab) == counts[0] and stars == 4
assert tree in listed and decode(4, [1, 2]) == ((0, 1), (1, 2), (2, 3)) and decode(4, [0, 0]) == ((0, 1), (0, 2), (0, 3))
print("ALL CHECKS PASS")
