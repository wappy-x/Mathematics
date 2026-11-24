# Dilworth's theorem -- the check behind the card.  Nothing is imported.  Three orders: the divisors of 12
# under "divides", ten closing prices (day i below day j when earlier and cheaper), the subsets of {1, 2, 3, 4}
# under "inside".  Road one: a largest matching, then Konig's cover.  Road two: every set, every dealing.
D, CENTS = [1, 2, 3, 4, 6, 12], [4320, 4210, 4460, 4165, 4395, 4630, 4288, 4515, 4705, 4570]
DIV = lambda i, j: i != j and D[j] % D[i] == 0
DAY = lambda i, j: i < j and CENTS[i] < CENTS[j]
SUB = lambda a, b: a != b and a & b == a          # subsets of {1, 2, 3, 4} as 4-bit numbers
def match(n, below):                   # left copy i links to right copy j when i is below j
    mate = {}                          # mate[j] = i: i sits just under j in one chain
    def grow(i, seen):                 # an alternating walk from i, as on the Konig card
        for j in (j for j in range(n) if below(i, j) and j not in seen):
            seen.add(j)
            if j not in mate or grow(mate[j], seen): mate[j] = i; return True
        return False
    for i in range(n): grow(i, set())
    return mate
def chains(n, mate):                   # climb the links from every item with nothing linked below
    up, climb = {i: j for j, i in mate.items()}, lambda x: [x] + climb(up[x]) if x in up else [x]
    return [climb(s) for s in range(n) if s not in mate]
def konig_antichain(n, below, mate):   # walk from unlinked left copies; keep items reached on the left only
    zl, zr, todo = set(), set(), [i for i in range(n) if i not in mate.values()]
    while todo:
        i = todo.pop(); zl.add(i)
        new = [j for j in range(n) if below(i, j) and j not in zr]
        zr |= set(new); todo += [mate[j] for j in new if j in mate and mate[j] not in zl]
    return [x for x in range(n) if x in zl and x not in zr]
def best_antichains(n, below):         # road two: every set, keep the largest with no two comparable
    comp = [sum(1 << y for y in range(n) if below(x, y) or below(y, x)) for x in range(n)]
    ok = [s for s in range(1 << n) if all(not (s >> x & 1 and comp[x] & s) for x in range(n))]
    top = max(s.bit_count() for s in ok)
    return [[x for x in range(n) if s >> x & 1] for s in ok if s.bit_count() == top]
def fewest_dealing(n, below):          # road two: deal items into k unlabelled piles, each pile a chain
    for k in range(1, 4):
        ways = sum(all(c // k ** x % k != c // k ** y % k or below(x, y) or below(y, x) for x in range(n) for y in range(x)) for c in range(k ** n))
        if ways: return k, ways // [1, 1, 2, 6][k]
def layers(n, below):                  # Mirsky: height = longest chain ending at an item
    h = []
    for y in range(n): h.append(1 + max([h[x] for x in range(y) if below(x, y)], default=0))
    return [[x for x in range(n) if h[x] == t] for t in range(1, max(h) + 1)]
def study(n, below): return (m := match(n, below)), chains(n, m), konig_antichain(n, below, m), best_antichains(n, below), layers(n, below)
(m, cd, ad, bd, ld), (mh, ch, ah, bh, lh), (ms, cs, As, bs, ls) = study(6, DIV), study(10, DAY), study(16, SUB)
(kd, wd), (kh, wh), nm, g = fewest_dealing(6, DIV), fewest_dealing(10, DAY), lambda grp, xs: [[xs[x] for x in c] for c in grp], {}
for i in range(6):                     # mistake 1: link each divisor to its largest free multiple
    if free := [j for j in range(6) if DIV(i, j) and j not in g]: g[max(free)] = i
print(f"divisors of 12: 6 items, {sum(DIV(i, j) for i in range(6) for j in range(6))} comparable pairs, largest matching {len(m)}")
print(f"road one: chains 6 - {len(m)} = {len(cd)}: {nm(cd, D)}; Konig antichain {nm([ad], D)[0]}")
print(f"road two: largest antichains {nm(bd, D)}; fewest chains {kd}, in {wd} ways")
print(f"Mirsky: longest chain {len(ld)}, height layers {nm(ld, D)}")
print(f"prices: matching {len(mh)}, rising runs {len(ch)}: {nm(ch, range(1, 11))}")
print(f"falling run from the cover: days {nm([ah], range(1, 11))[0]} at {', '.join(f'{CENTS[x] // 100}.{CENTS[x] % 100:02d}' for x in ah)}; every set: {len(bh[0])}, dealing: {kh}")
print(f"longest rising run {len(lh)}; 10 days <= {len(ch)} runs x {len(lh)} = {len(ch) * len(lh)}")
print(f"16 subsets: matching {len(ms)}, chains {len(cs)}, antichain {len(As)}; every set: {len(bs[0])}, found {len(bs)} time")
print(f"mistake 1, greedy links (1 to 12 first): matching {len(g)}, chains {6 - len(g)}")
print(f"mistake 2, longest chain taken as the count: {len(ld)}, not {len(cd)}")
print(f"mistake 3, rising stretches of days in a row: {1 + sum(CENTS[i + 1] < CENTS[i] for i in range(9))}, not {len(ch)}")
assert len(cd) == kd == len(ad) == len(bd[0]) == 2 and sorted(x for c in cd for x in c) == list(range(6)) and all(DIV(c[t], c[t + 1]) for c in cd for t in range(len(c) - 1))
assert len(ch) == kh == len(ah) == len(bh[0]) == 3 and all(DAY(c[t], c[t + 1]) for c in ch for t in range(len(c) - 1))
assert len(cs) == len(As) == len(bs[0]) == 6 and len(bs) == 1 and all(SUB(c[t], c[t + 1]) for c in cs for t in range(len(c) - 1)) and len(ld) == len(lh) == 4 and len(g) == 2
assert all(not DIV(x, y) for x in ad for y in ad) and all(not DAY(x, y) for x in ah for y in ah) and all(not SUB(x, y) for x in As for y in As)
print("ALL CHECKS PASS")
