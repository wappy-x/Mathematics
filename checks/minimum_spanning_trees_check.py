# The cheapest skeleton -- the check behind the card.  Nothing is imported.  Seven campus
# buildings A to G, eleven possible fibre runs, prices in thousands of dollars.  Three roads
# to the cheapest network reaching all seven: Kruskal's sorted walk, Prim's growing group,
# brute force over every six-run subset.
V, E = "ABCDEFG", [("A", "B", 7), ("A", "D", 5), ("B", "C", 8), ("B", "D", 9),
     ("B", "E", 7), ("C", "E", 5), ("D", "E", 15), ("D", "F", 6), ("E", "F", 8),
     ("E", "G", 9), ("F", "G", 11)]
CHEAP = sorted(E, key=lambda r: (r[2], r[0], r[1]))   # cheap to dear, ties by name
def show(t): return ", ".join(f"{u}{v} {w}" for u, v, w in t)
def total(t): return sum(w for _, _, w in t)
def yn(c): return "yes" if c else "no"
def root(p, x):
    while p[x] != x: x = p[x]
    return x
def walk(edges):                     # keep a run only if it joins two separate groups
    p, kept, log = {v: v for v in V}, [], []
    for u, v, w in edges:
        add = root(p, u) != root(p, v)
        if add: p[root(p, u)] = root(p, v); kept.append((u, v, w))
        log.append(f"{u}{v} {w} {'add' if add else 'skip'} {len(V) - len(kept)}")
    return kept, log
def prim(s):                         # over and over, take the cheapest run leaving the group
    grown, kept = [s], []
    while len(grown) < len(V):
        w, u, v = min((w, u, v) for u, v, w in E if (u in grown) != (v in grown))
        kept.append((u, v, w)); grown.append(v if u in grown else u)
    return kept
kk, klog = walk(CHEAP)
pa, grp = prim("A"), "ABDF"          # grp: the group Kruskal has joined after four adds
subs = [[e for i, e in enumerate(E) if m >> i & 1]
        for m in range(1 << len(E)) if bin(m).count("1") == len(V) - 1]
nets = [s for s in subs if len(walk(s)[0]) == len(V) - 1]    # no loop, so a network
low, high = min(map(total, nets)), max(map(total, nets))
cross = sorted((e for e in E if (e[0] in grp) != (e[1] in grp)), key=lambda r: r[2])
forced = [(e, min(total(t) for t in nets if e in t)) for e in sorted(E) if e not in kk]
six, dearfirst = walk(CHEAP[:6])[0], walk(CHEAP[::-1])[0]
print(f"{len(V)} buildings, {len(E)} candidate runs, {len(V) - 1} runs in a network"
      "\nruns cheap to dear: " + show(CHEAP))
print("Kruskal walk, run price action groups-left: " + " | ".join(klog))
print(f"Kruskal keeps {show(sorted(kk))}, total {total(kk)}")
print(f"Prim from A keeps, in its own order, {show(pa)}, total {total(pa)}")
print("Prim's total from each start: " + " ".join(f"{s} {total(prim(s))}" for s in V)
      + f"; the same six runs every time: {yn(all(sorted(prim(s)) == sorted(kk) for s in V))}")
print(f"six-run subsets {len(subs)}, of them networks {len(nets)}, cheapest {low}, dearest "
      f"{high}, networks at the cheapest price {sum(1 for t in nets if total(t) == low)}")
print(f"split {grp} against {''.join(v for v in V if v not in grp)}: crossing runs "
      + show(cross) + f"; cheapest {cross[0][0]}{cross[0][1]} {cross[0][2]}; "
      f"kept by Kruskal: {yn(cross[0] in kk)}")
print("cheapest network that keeps a left-out run: "
      + " | ".join(f"{u}{v} {w} -> {c}" for (u, v, w), c in forced)
      + f"; every one dearer than {low}: {yn(all(c > low for _, c in forced))}")
print(f"mistake 1, the six cheapest runs with no loop test: total {total(CHEAP[:6])}, groups "
      f"left {len(V) - len(six)}; mistake 2, one run short: total {total(kk[:5])}, groups left 2")
print(f"mistake 3, dearest first with the loop test: total {total(dearfirst)}, "
      f"and the brute-force dearest network: {high}")
assert sorted(kk) == sorted(min(nets, key=total)) and total(kk) == low == 39
assert all(total(prim(s)) == low and sorted(prim(s)) == sorted(kk) for s in V)
assert sum(1 for t in nets if total(t) == low) == 1 and all(c > low for _, c in forced)
assert total(dearfirst) == high and cross[0] in kk
print("ALL CHECKS PASS")
