# Edmonds' blossom algorithm -- the check behind the card.  Nothing is imported.  Dots a to f are 0 to 5.
N, PAIRS = 6, [(i, j) for i in range(6) for j in range(i + 1, 6)]     # road two, brute force, tries all 15 lines
def adjacency(lines, n=N): return [sorted({j for i, j in lines if i == v} | {i for i, j in lines if j == v}) for v in range(n)]
def flip(match, path):                       # the route's outside lines go in, its inside lines out
    for i in range(0, len(path), 2): match[path[i]], match[path[i + 1]] = path[i + 1], path[i]
def edmonds(adj, match, root, log=None):     # road one: grow a tree from root; shrink each blossom to its base
    p, base, outer, q, todo = [-1] * N, list(range(N)), [v == root for v in range(N)], [root], [iter(a) for a in adj]
    up = lambda x: [base[x]] + (up(p[match[base[x]]]) if match[base[x]] >= 0 else [])   # bases back to root
    while q:                                 # depth first: the newest outer dot, q[-1], tries its next line
        if (t := next(todo[v := q[-1]], None)) is None: q.pop()   # every line tried: step back
        elif base[v] == base[t] or match[v] == t: continue
        elif t == root or match[t] >= 0 and p[match[t]] >= 0:        # two outer dots: a blossom
            b, flower = next(x for x in up(t) if x in up(v)), [False] * N
            for x, child in ((v, t), (t, v)):                  # point each dot back across the closing line
                while base[x] != b:
                    flower[base[x]] = flower[base[match[x]]] = True
                    p[x], child, x = child, match[x], p[match[x]]
            if log is not None: log.append((v, t, b, [i for i in range(N) if flower[base[i]] or base[i] == b]))
            for i in [i for i in range(N) if flower[base[i]]]: q += [i] * (not outer[i]); outer[i] = True; base[i] = b
        elif p[t] < 0:
            p[t], path = v, [t]
            if match[t] < 0:                                   # a free dot: lift the route
                while (u := p[path[-1]]) != root: path += [u, match[u]]
                return (path + [root])[::-1]
            outer[match[t]] = True; q.append(match[t])
def naive(adj, match, root):                 # the two-sided search: every dot labelled once, no shrinking
    seen = [v == root for v in range(N)] + [False]                 # the spare last slot absorbs match -1
    def go(v):
        for t in (t for t in adj[v] if not seen[t]):
            seen[t] = seen[match[t]] = True
            if match[t] < 0: return [v, t]
            if rest := go(match[t]): return [v, t] + rest
    return go(root)
def solve(adj, search):                      # one search from each free dot, flipping what it finds
    match = [-1] * N
    for v in range(N): flip(match, (match[v] < 0 and search(adj, match, v)) or [])
    assert all(match[match[v]] == v and match[v] in adj[v] for v in range(N) if match[v] >= 0)   # mutual pairs, real lines
    return N - match.count(-1) >> 1
def nu(adj, left):                           # brute force: leave the first dot out, or pair it each way
    return max([nu(adj, left[1:])] + [1 + nu(adj, [u for u in left[1:] if u != t]) for t in adj[left[0]] if t in left]) if left else 0
G, M, WRONG = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4), (3, 5)], [(1, 2), (3, 4)], [(0, 1), (1, 2), (2, 3), (3, 5)]
adj, name, m0, log = adjacency(G), lambda path: "-".join("abcdefB"[v] for v in path), [-1, 2, 1, 4, 3, -1], []
stuck = naive(adj, m0, 0); route = edmonds(adj, m0, 0, log); v, t, b, flower = log[0]; flip(m0, route)
out = lambda x: N if x in flower else x; shrunk = sorted({(out(i), out(j)) for i, j in G if out(i) != out(j)})
m_shrunk = [l for l in M if out(l[0]) != out(l[1])]; nu_shrunk = nu(adjacency(shrunk, N + 1), sorted({out(x) for x in range(N)}))
graphs = [adjacency([PAIRS[i] for i in range(15) if g >> i & 1]) for g in range(1 << 15)]
best = [nu(a, list(range(N))) for a in graphs]; ed = [solve(a, edmonds) for a in graphs]
short = [a for a, x in zip(graphs, best) if solve(a, naive) < x]; odd = [not any(all(c >> i & 1 != c >> j & 1 for i in range(N) for j in a[i]) for c in range(64)) for a in short]
print(f"search without shrinking from a: route {stuck or 'none'}; matching stays at {len(M)} lines")
print(f"blossom closed by {name([v, t])}: {name(flower)}, {len(flower)} dots, base {name([b])}, {len(flower) // 2} matched lines inside")
print(f"shrunk to B: lines {', '.join(map(name, shrunk))}; matching lines {len(m_shrunk)}; largest {nu_shrunk}")
print(f"lifted route {name(route)}; after the flip {', '.join(name([x, m0[x]]) for x in range(N) if x < m0[x])}")
print(f"lines after the flip: {N - m0.count(-1) >> 1}, the draft's {len(M)} plus 1; largest by brute force: {nu(adj, list(range(N)))}")
print(f"mistake, lift the odd way round, a-b-c-d-f: dot d on {sum(3 in l for l in M + WRONG if (l in M) != (l in WRONG))} lines")
print(f"all {len(graphs)} graphs on 6 dots: Edmonds equals brute force on {sum(e == x for e, x in zip(ed, best))}")
print(f"search without shrinking falls short on {len(short)}; with an odd loop: {sum(odd)}")
assert route == [0, 4, 3, 5] and stuck is None and N - m0.count(-1) >> 1 == nu(adj, list(range(N))) == 3   # the card's graph
assert ed == best and all(odd) and len(short) > 0      # Edmonds against brute force everywhere; the plain search fails only on odd loops
assert (nu_shrunk > len(m_shrunk)) == (nu(adj, list(range(N))) > len(M))   # shrinking lemma, both graphs
print("ALL CHECKS PASS")
