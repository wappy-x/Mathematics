# Degrees and the handshaking lemma -- the check behind the card.  Nothing is imported.
# The metro map is stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E
# and C-F.  The degree total is reached twice: the ends tallied station by station, and
# the station-by-line table added down its columns.  A census of all 64 graphs on four
# named stations tests parity and lists their degree sequences; then Havel-Hakimi runs.
NAMES = "ABCDEF"
METRO = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]
WISHES = [[3, 3, 3, 3, 2, 2], [3, 3, 3, 1], [3, 3, 3], [4] * 9]
LOOPED, DOUBLED = METRO + [(0, 0)], METRO + [(1, 2)]
def degrees(n, edges):                   # road one: the ends met at each station
    deg = [0] * n
    for u, v in edges:                   # a loop has u == v, so it adds two ends
        deg[u] += 1
        deg[v] += 1
    return deg
def havel_hakimi(wish):                  # build a graph for the list, or give up
    left, built = [[d, i] for i, d in enumerate(wish)], []
    while True:
        left.sort(key=lambda p: (-p[0], p[1]))
        if left[0][0] == 0:
            return built
        d, v = left[0]
        left[0][0] = 0                   # the greediest station is now served
        if d >= len(left) or any(p[0] == 0 for p in left[1:d + 1]):
            return None
        for p in left[1:d + 1]:
            p[0] -= 1
            built.append((v, p[1]))
def yn(claim): return "yes" if claim else "no"
deg = degrees(6, METRO)
t = [[(u == s) + (v == s) for u, v in METRO] for s in range(6)]   # road two: the table
rows, cols = [sum(r) for r in t], [sum(c) for c in zip(*t)]
odd = [NAMES[i] for i, d in enumerate(deg) if d % 2]
pairs4, dist, census, seqs = [(a, b) for a in range(4) for b in range(a + 1, 4)], [0] * 5, True, set()
for mask in range(1 << len(pairs4)):     # every graph on four named stations, all 64 of them
    dg = degrees(4, [p for i, p in enumerate(pairs4) if mask >> i & 1])
    census = census and sum(dg) == 2 * bin(mask).count("1")
    dist[sum(d % 2 for d in dg)] += 1; seqs.add(tuple(sorted(dg, reverse=True)))
hh = [havel_hakimi(w) for w in WISHES]
graphic = [b is not None and sorted(degrees(len(w), b), reverse=True) == w for w, b in zip(WISHES, hh)]
looped, doubled = degrees(6, LOOPED), degrees(6, DOUBLED)
print(f"the metro: 6 stations, {len(METRO)} lines\n  " + "   ".join(f"{NAMES[i]} deg {d}" for i, d in enumerate(deg)))
print(f"degree sequence, largest first: {sorted(deg, reverse=True)}")
print(f"road 1, the ends tallied at each station and added: {sum(deg)}; average per station {sum(deg)} / 6 = {sum(deg) / 6:.2f}")
print("road 2, the station-by-line table, a 1 where a line ends at a station: " + "  ".join(NAMES[s] + " " + "".join(str(x) for x in t[s]) for s in range(6)) + f"; columns add to {cols} = {sum(cols)}; rows add to the degrees: {yn(rows == deg)}")
print(f"odd-degree stations: {' '.join(odd)}, {len(odd)} of them; an even count: {yn(len(odd) % 2 == 0)}")
print(f"all {1 << len(pairs4)} graphs on four named stations: degree total = 2 x lines every time: {yn(census)}; {len(seqs)} degree sequences appear, (3, 3, 2, 2) among them and (3, 3, 3, 1) not: {yn((3, 3, 2, 2) in seqs and (3, 3, 3, 1) not in seqs)}")
print("odd-station counts, and how many graphs each: " + ", ".join(f"{k} -> {c}" for k, c in enumerate(dist) if c) + f"; never 1 or 3: {yn(dist[1] == 0 and dist[3] == 0)}")
print(f"party of 9 each shaking 3 hands: 9 x 3 = {9 * 3}, odd, so no such party\nparty of 9 each shaking 4 hands: 9 x 4 = {9 * 4} = 2 x {9 * 4 // 2} handshakes, so possible")
print("Havel-Hakimi on wished-for degree lists:")
for w, b, g in zip(WISHES, hh, graphic):
    print(f"  {w} sum {sum(w)} even {yn(sum(w) % 2 == 0)}  graphic {yn(g)}" + (f"  built {len(b)} lines" if g else ""))
print(f"mistake 1, each line counted once, not at both ends: {len(METRO)}, not {sum(deg)}")
print(f"mistake 2, a loop at A counted as one end: {sum(looped) - 1} for {len(LOOPED)} lines, odd; the truth is {sum(looped)}\nmistake 3, the second B-C track merged away: {sum(deg)} for {len(DOUBLED)} lines; the truth is {sum(doubled)}")
assert rows == deg and cols == [2] * len(METRO) and sum(cols) == sum(deg)
assert sorted(deg, reverse=True) == [3, 3, 3, 3, 2, 2] and odd == ["B", "C", "E", "F"]
assert census and dist == [8, 0, 48, 0, 8] and len(seqs) == 11 and (3, 3, 2, 2) in seqs and (3, 3, 3, 1) not in seqs
assert graphic == [True, False, False, True] and sum(looped) == 2 * len(LOOPED) and sum(doubled) == 2 * len(DOUBLED)
print("ALL CHECKS PASS")
