# Konig's theorem -- the check behind the card.  Nothing is imported.  The town plan: eight
# junctions, four on the west bank (W1-W4) and four on the east (E1-E4), joined by eight
# streets, each one a bridge.  A triangle of streets is the second case, where equality fails.
NAMES = ["W1", "W2", "W3", "W4", "E1", "E2", "E3", "E4"]
WESTM, EASTM = 0b1111, 0b11110000                  # the two banks, one bit per junction
ST = [(0, 4), (0, 5), (1, 4), (1, 5), (2, 5), (3, 5), (3, 6), (3, 7)]
TRI = [(0, 1), (1, 2), (0, 2)]                     # three junctions in a ring, so no two banks
show = lambda m: ", ".join(NAMES[i] for i in range(8) if m >> i & 1)
def brute(n, st):                                  # ROAD ONE: every set of junctions, every set of streets
    pc, touch = int.bit_count, lambda p: {x for i, (u, v) in enumerate(st) if p >> i & 1 for x in (u, v)}
    cov = [m for m in range(1 << n) if all(m >> u & 1 or m >> v & 1 for u, v in st)]
    tau = min(map(pc, cov))
    alpha = max(pc(m) for m in range(1 << n) if all(not (m >> u & 1 and m >> v & 1) for u, v in st))
    nu = max(pc(p) for p in range(1 << len(st)) if len(touch(p)) == 2 * pc(p))
    rho = min(pc(p) for p in range(1 << len(st)) if len(touch(p)) == n)
    return nu, tau, alpha, rho, [m for m in cov if pc(m) == tau]
def grow(a, mate, seen, nbr):                      # one alternating walk out of a west junction
    for b in nbr[a]:
        if b in seen: continue
        seen.add(b)
        if b not in mate or grow(mate[b], mate, seen, nbr): mate[b] = a; return True
    return False
def built(st):                                     # ROAD TWO: grow a matching, then read the guards off it
    nbr, mate = {a: [b for u, b in st if u == a] for a in range(4)}, {}   # mate: east -> west partner
    for a in range(4): grow(a, mate, set(), nbr)
    stack = [a for a in range(4) if a not in mate.values()]               # west junctions left unmatched
    z = set(stack)                                                       # all an alternating walk reaches
    while stack:
        for b in nbr[stack.pop()]:
            if b in z: continue
            z.add(b)
            if b in mate and mate[b] not in z: z.add(mate[b]); stack.append(mate[b])
    cover = sum(1 << x for x in range(8) if (x not in z if x < 4 else x in z))
    return sorted((a, b) for b, a in mate.items()), cover
def hall(st):                                      # ROAD THREE: the west set Hall's test fails worst on
    nbrs = lambda m: {b for u, b in st if m >> u & 1}
    bad = max(range(16), key=lambda m: int.bit_count(m) - len(nbrs(m)))
    gap, side = int.bit_count(bad) - len(nbrs(bad)), sum(1 << b for b in nbrs(bad))
    return gap, bad, side, side + sum(1 << a for a in range(4) if not bad >> a & 1)
(nu, tau, alpha, rho, mins), (pairs, cover), (gap, bad, side, hcover) = brute(8, ST), built(ST), hall(ST)
t_nu, t_tau = brute(3, TRI)[:2]
print(f"plan: {len(NAMES)} junctions, west {show(WESTM)} and east {show(EASTM)}; {len(ST)} streets, each a bridge")
print(f"road one, all {1 << 8} sets of junctions: fewest guards tau = {tau}, largest independent set alpha = {alpha}")
print(f"road one, all {1 << len(ST)} sets of streets: largest matching nu = {nu}, smallest edge cover rho = {rho}")
print(f"road one, guard sets of size {tau}: {len(mins)}, namely {show(mins[0])}")
print("road two, matching grown by alternating walks: " + "; ".join(f"{NAMES[a]}-{NAMES[b]}" for a, b in pairs))
print(f"road two, guards read off that matching: {show(cover)}")
print(f"road three, worst west set for Hall's test: {show(bad)} reaching only {show(side)}; shortfall {gap}; guards from it: {show(hcover)}")
print(f"Konig: largest matching {nu} = fewest guards {tau}")
print(f"Gallai: alpha + tau = {alpha} + {tau} = {alpha + tau}, and nu + rho = {nu} + {rho} = {nu + rho}")
print(f"mistakes: both ends of each matched street {2 * nu} guards; one whole bank {int.bit_count(WESTM)} guards; an edge cover {rho} streets, not {tau}")
print(f"a triangle of streets: nu = {t_nu} but tau = {t_tau}, so Konig needs two banks")
assert nu == tau == len(pairs) == 3                  # Konig: brute force meets the alternating walk
assert cover == mins[0] and len(mins) == 1           # the built guard set is the only smallest one
assert hcover == cover and nu == 4 - gap             # Hall's shortfall names the same guards
assert alpha + tau == 8 and nu + rho == 8 and (t_nu, t_tau) == (1, 2)
print("ALL CHECKS PASS")
