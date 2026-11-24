# List colouring and choosability -- the check behind the card.  Nothing is imported.  Two hilltop
# masts P, Q each interfere with four village stations A B C D: the graph K(2,4).  Exhaustive search
# meets the card's count of bad licence sets; Thomassen's proof runs as a program on K(2,4) with A-B,
# B-C, C-D added (still flat), against a brute-force search.
G = {"P": "ABCD", "Q": "ABCD", "A": "PQ", "B": "PQ", "C": "PQ", "D": "PQ"}
T = {v: set(n + {"A": "B", "B": "AC", "C": "BD", "D": "C"}.get(v, "")) for v, n in G.items()}
BAD = {"P": (1, 2), "Q": (3, 4), "A": (1, 3), "B": (1, 4), "C": (2, 3), "D": (2, 4)}
def colourings(g, L, col):                  # every proper colouring with each vertex on its own list
    rest = [v for v in g if v not in col]
    if not rest: yield col; return
    for c in L[rest[0]]:
        if all(col.get(u) != c for u in g[rest[0]]): yield from colourings(g, L, {**col, rest[0]: c})
def ok(g, L): return next(colourings(g, L, {}), None) is not None
def subsets(n, k, lo=1): return [()] if k == 0 else [(i,) + s for i in range(lo, n + 1) for s in subsets(n, k - 1, i + 1)]
def assign(vs, opts): return [{}] if not vs else [{vs[0]: o, **a} for o in opts for a in assign(vs[1:], opts)]
def sub(g, keep): return {v: g[v] & keep for v in keep}
def thomassen(g, outer, L, col, log):       # outer: the outer cycle in order, its first two coloured
    n = len(outer)
    if n == 2: return col
    chords = [(i, j) for i in range(n) for j in range(i + 2, n) if (i, j) != (0, n - 1) and outer[j] in g[outer[i]]]
    if chords:                              # case 1: split along the chord, the side holding x, y first
        i, j = chords[0]; log.append(f"chord {outer[i]}-{outer[j]}")
        c1, c2 = (outer[:j + 1], [outer[0], outer[j]] + outer[j + 1:]) if i == 0 else (outer[:i + 1] + outer[j:], [outer[j], outer[i]] + outer[i + 1:j])
        side, stack = set(c2), c2[2:]
        while stack: stack += [w for w in g[stack.pop()] if w not in side and not side.add(w)]
        col = thomassen(sub(g, set(g) - side | set(c2[:2])), c1, L, col, log)
        return thomassen(sub(g, side), c2, L, col, log)
    x, u, w, path = outer[0], outer[-2], outer[-1], []     # case 2: w is x's other outer neighbour
    while nxt := sorted(v for v in g[w] & g[path[-1] if path else x] if v not in outer and v not in path): path.append(nxt[0])
    a, b = [c for c in L[w] if c != col[x]][:2]; log.append(f"{w} keeps {a},{b}")
    L2 = {**L, **{v: tuple(c for c in L[v] if c not in (a, b)) for v in path}}
    col = thomassen(sub(g, set(g) - {w}), outer[:-1] + path[::-1], L2, col, log)
    return {**col, w: a if col[u] != a else b}
def run(L, col):                            # Thomassen from P and A, then check the answer
    out = thomassen(T, ["P", "A", "Q", "D"], L, col, log := [])
    return out, log, all(out[v] in L[v] and all(out[v] != out[u] for u in T[v]) for v in T)
def show(c, f=str): return " ".join(f"{v}{f(c[v])}" for v in "PQABCD")
def braces(t): return "{" + ",".join(map(str, t)) + "}"
two = list(colourings(G, {v: (1, 2) for v in G}, {}))
blocked = [f"P{p} Q{q} blocks {next((v for v in 'ABCD' if set(BAD[v]) <= {p, q}), 'none')}" for p in BAD["P"] for q in BAD["Q"]]
bad4, bad3, ch3 = [[a for a in assign("PQABCD", subsets(p, k)) if not ok(G, a)] for p, k in ((4, 2), (3, 2), (4, 3))]
E, tri = sum(map(len, T.values())) // 2, sum(1 for u in T for v in T[u] for w in T[v] if u < v < w and w in T[u])
col, log, good = run({v: BAD[v] + (5, 6, 7) for v in G}, {"P": 1, "A": 3})
sweep = [run(L, {"P": L["P"][0], "A": [c for c in L["A"] if c != L["P"][0]][0]})[2] for L in assign("PQABCD", subsets(6, 5))]
def outer_k(k): return [{"P": (p,), "A": (q,), "B": (1, 2, 3, 4, 5), "C": (1, 2, 3, 4, 5), **a}
                        for p in range(1, 6) for q in range(1, 6) if p != q for a in assign("QD", subsets(5, k))]
strong, short = outer_k(3), outer_k(2)
st_th, st_bf, stuck = [run(L, {"P": L["P"][0], "A": L["A"][0]})[2] for L in strong], [ok(T, L) for L in strong], [L for L in short if not ok(T, L)]
print(f"K(2,4): {len(G)} vertices, {sum(map(len, G.values())) // 2} edges, most at one vertex {max(map(len, G.values()))}; proper colourings from channels 1 and 2 only: {len(two)}, so chromatic number 2")
print(f"the bad licences {show(BAD, braces)}: channel choices tried {sum(1 for _ in colourings({v: "" for v in G}, BAD, {}))}, proper {sum(1 for _ in colourings(G, BAD, {}))}\n  " + "; ".join(blocked))
print(f"2-channel licences from 4 channels: bad {len(bad4)} of {6 ** 6}; formula 6 x 24 = {6 * 24}\n2-channel licences from 3 channels: bad {len(bad3)} of {3 ** 6}\n3-channel licences from 4 channels: bad {len(ch3)} of {4 ** 6}, so choice number 3")
print(f"with A-B, B-C, C-D added: V = {len(T)}, E = {E}, most at one vertex {max(map(len, T.values()))}, triangles {tri} + the outer face P A Q D = {tri + 1} = E - V + 2")
print(f"Thomassen on licences of 5 (the bad ones plus 5, 6, 7): " + "; ".join(log) + f"\n  result {show(col)}, proper and on every list: {'yes' if good else 'no'}")
print(f"every 5-channel licence set from 6 channels: {len(sweep)} sets, Thomassen fails {sweep.count(False)}")
print(f"stronger form, P and A fixed, Q and D lists of 3, B and C lists of 5: {len(strong)} cases, Thomassen fails {st_th.count(False)}, search finds {st_bf.count(False)} stuck")
print(f"mistake, Q and D lists of 2: {len(stuck)} of {len(short)} cases stuck, first {show(stuck[0], braces)}")
assert len(two) == 2 and not ok(G, BAD) and len(bad4) == 6 * 24 and bad3 == [] and ch3 == []
assert good and all(sweep) and all(st_th) and all(st_bf) and len(stuck) > 0
assert tri + 1 == E - len(T) + 2 and all(set(a["P"]).isdisjoint(a["Q"]) for a in bad4)
print("ALL CHECKS PASS")
