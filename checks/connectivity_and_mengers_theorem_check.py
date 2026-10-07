# Menger's theorem on an 8-station rail network -- the check behind the card.  Nothing imported.
# Road one: brute force over closed lines, closed stations and route families.  Road two: max flow.
NET = [("S", "A"), ("S", "B"), ("A", "J"), ("B", "J"), ("J", "C"), ("C", "T"), ("J", "D"), ("D", "E"), ("E", "T")]
def pieces(stations, lines):             # give both ends of each open line one label
    label = {x: x for x in stations}
    for u, v in (l for l in lines if l[0] in label and l[1] in label):
        old, new = label[u], label[v]
        label = {x: new if y == old else y for x, y in label.items()}
    return label
def flow(arcs, s, t):                    # push one unit at a time along a searched route
    cap, total = dict(arcs), 0
    while True:
        prev, todo = {s: None}, [s]
        for u in todo:
            for (a, b), c in cap.items():
                if a == u and c > 0 and b not in prev: prev[b] = a; todo.append(b)
        if t not in prev: return total
        b, total = t, total + 1
        while prev[b] is not None:
            a = prev[b]; cap[(a, b)] -= 1; cap[(b, a)] = cap.get((b, a), 0) + 1; b = a
def roads(lines, big=1, split=(), off=""):  # each open line becomes two one-way roads
    i, o = (lambda x: x + "i" if x in split else x), (lambda x: x + "o" if x in split else x)
    arcs = {(x + "i", x + "o"): 1 for x in split}  # a split station passes one unit
    for u, v in (l for l in lines if off not in l):
        arcs[(o(u), i(v))] = arcs[(o(v), i(u))] = big
    return arcs
def routes(lines, here, seen):           # every S-T route that repeats no station
    if here == "T": return [["T"]]
    nxt = sorted({b for a, b in lines if a == here} | {a for a, b in lines if b == here})
    return [[here] + r for x in nxt if x not in seen for r in routes(lines, x, seen | {x})]
def most_apart(rs, key):                 # the largest family of routes sharing no key
    fams = [[key(r) for i, r in enumerate(rs) if m >> i & 1] for m in range(1 << len(rs))]
    return max(len(f) for f in fams if len([k for r in f for k in r]) == len({k for r in f for k in r}))
on_lines, on_stations = (lambda r: [tuple(sorted(p)) for p in zip(r, r[1:])]), (lambda r: r[1:-1])
for name, lines in (("full network", NET), ("line C-T closed", [l for l in NET if l != ("C", "T")])):
    st = sorted({x for l in lines for x in l}); mid = [x for x in st if x not in "ST"]
    count = lambda xs, ls: len(set(pieces(xs, ls).values()))
    apart = lambda xs, ls: (lambda r: r["S"] != r["T"])(pieces(xs, ls))
    shut = ([l for i, l in enumerate(lines) if m >> i & 1] for m in range(1 << len(lines)))
    cuts = [len(c) for c in shut if apart(st, [l for l in lines if l not in c])]
    vk = min(len(c) for c in ([x for i, x in enumerate(mid) if m >> i & 1] for m in range(1 << len(mid)))
             if apart([x for x in st if x not in c], lines))
    lam, kap = flow(roads(lines), "S", "T"), flow(roads(lines, len(st), mid), "S", "T")
    br1 = ["-".join(l) for l in lines if count(st, [m for m in lines if m != l]) > count(st, lines)]
    br2 = [u + "-" + v for u, v in lines if flow(roads([l for l in lines if l != (u, v)]), u, v) == 0]
    cv1 = [x for x in st if count([y for y in st if y != x], lines) > count(st, lines)]
    nb = lambda x: [b for a, b in lines if a == x] + [a for a, b in lines if b == x]
    cv2 = [x for x in st if any(flow(roads(lines, off=x), a, b) == 0 for a in nb(x) for b in nb(x) if a < b)]
    rs = routes(lines, "S", {"S"}); ld, sd = most_apart(rs, on_lines), most_apart(rs, on_stations)
    print(f"{name}: {len(st)} stations, {len(lines)} lines, {len(rs)} S-T routes in all")
    print(f"  fewest lines to separate S from T: {min(cuts)} (brute force), {lam} (flow); {cuts.count(min(cuts))} such sets")
    print(f"  most line-disjoint routes: {ld} (brute force), {lam} (flow)")
    print(f"  fewest stations to separate: {vk} (brute force), {kap} (split flow); station-disjoint routes {sd}")
    print(f"  bridges: {', '.join(br1) or 'none'} (pieces); {', '.join(br2) or 'none'} (flow)")
    print(f"  cut vertices: {', '.join(cv1) or 'none'} (pieces); {', '.join(cv2) or 'none'} (flow)")
    assert min(cuts) == lam == ld          # Menger, line form: brute cut, flow, brute routes
    assert vk == kap == sd                 # Menger, station form: brute cut, split flow, brute routes
    assert br1 == br2 and cv1 == cv2       # weak spots: counting pieces against flow
print("ALL CHECKS PASS")
