# Graphs -- the check behind the card.  Nothing is imported.  Map 1 is the metro
# ring: stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E and
# C-F.  Map 2 is the tourist map, stations 1 to 6.  Map 3 is a decoy carrying the
# same station count, line count and station-by-station tally as map 1.
NAMES = "ABCDEF"
RING = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
TOURIST = [(0, 2), (0, 4), (0, 5), (1, 4), (1, 5), (2, 3), (3, 4), (3, 5)]
DECOY = [(0, 1), (0, 2), (1, 2), (1, 4), (2, 5), (3, 4), (3, 5), (4, 5)]
def lines(pairs):                        # each line written once, low end first
    return frozenset(tuple(sorted(p)) for p in pairs)
def perms(items):                        # every renaming, generated here
    if not items:
        yield ()
    for i, x in enumerate(items):
        for rest in perms(items[:i] + items[i + 1:]):
            yield (x,) + rest
def fingerprint(pairs, n=6):             # road two: counts no renaming can change
    E = lines(pairs)
    tally = sorted(sum(v in e for e in E) for v in range(n))
    tri = sum(1 for a in range(n) for b in range(a + 1, n) for c in range(b + 1, n)
              if (a, b) in E and (a, c) in E and (b, c) in E)
    return (len(E), tally, tri)
def renamings(src, dst, n=6):            # road one: try all n! renamings
    target, E = lines(dst), lines(src)
    return sum(1 for p in perms(tuple(range(n)))
               if lines((p[a], p[b]) for a, b in E) == target)

pairs6 = [(a, b) for a in range(6) for b in range(a + 1, 6)]     # listed, not counted
k33 = lines((a, b) for a in (0, 2, 4) for b in (1, 3, 5))        # A C E against B D F
cube = [(u, v) for u in range(8) for v in range(8) if u < v and bin(u ^ v).count("1") == 1]
per_dir = [sum(1 for u, v in cube if u ^ v == 1 << b) for b in range(3)]
ring, inner = lines(RING), {1, 2, 4, 5}
ring_only = ring - {(1, 4), (2, 5)}
induced = frozenset(e for e in ring if e[0] in inner and e[1] in inner)
gap = sorted(k33 - ring)[0]
orders = sum(1 for _ in perms(tuple(range(6))))
f1, f2, f3 = fingerprint(RING), fingerprint(TOURIST), fingerprint(DECOY)
print(f"map 1, the ring: 6 stations, {len(ring)} lines; the adjacency list")
for v in range(6):
    print(f"  {NAMES[v]}: " + " ".join(NAMES[w] for e in sorted(ring) if v in e for w in e if w != v))
print(f"all pairs of 6 stations, listed: {len(pairs6)}; by formula 6 x 5 / 2 = "
      f"{6 * 5 // 2}; map 1 runs {len(ring)}, so {len(pairs6) - len(ring)} pairs have no line")
print(f"named families on 6 stations: K(6) {len(pairs6)} lines, "
      f"C(6) {len(lines((i, (i + 1) % 6) for i in range(6)))}, "
      f"P(6) {len(lines((i, i + 1) for i in range(5)))}, K(3,3) {len(k33)}")
print(f"map 1 is K(3,3) less one line: {len(k33)} - 1 = {len(ring)}; "
      f"the missing pair is {NAMES[gap[0]]}-{NAMES[gap[1]]}")
print(f"the 3-cube Q(3): 8 corners, {len(cube)} lines by flipping one coordinate; by formula 8 x 3 / 2 = {8 * 3 // 2}; {per_dir} in the three directions")
print(f"drop the crossings B-E and C-F: {len(ring_only)} lines left, the ring C(6)")
print(f"keep B C E F and every line between them: {len(induced)} lines, the 4-cycle B-C-F-E-B")
print(f"map 2 onto map 1: {renamings(TOURIST, RING)} of the {orders} renamings work")
print(f"map 3 onto map 1: {renamings(DECOY, RING)} of the {orders} renamings work")
print(f"lines and tally: map 1 {f1[0]} {f1[1]}, map 2 {f2[0]} {f2[1]}, map 3 {f3[0]} {f3[1]}")
print(f"triangles: map 1 {f1[2]}, map 2 {f2[2]}, map 3 {f3[2]}")
assert len(pairs6) == 6 * 5 // 2 and len(cube) == 8 * 3 // 2 and per_dir == [4, 4, 4]
assert ring == k33 - {(0, 3)} and ring_only == lines((i, (i + 1) % 6) for i in range(6))
assert induced == frozenset({(1, 2), (1, 4), (2, 5), (4, 5)}) and renamings(TOURIST, RING) == 8
assert f2 == f1 and f3 != f1 and renamings(DECOY, RING) == 0
print("ALL CHECKS PASS")
