# The RSK correspondence -- the check behind the card.  Nothing is imported.  Row insertion
# turns a shuffle into tableaux P (the numbers) and Q (when each box appeared); reverse bumping undoes it.
def rsk(w, pick=min):                      # road one: row insertion, with a recording
    P, Q = [], []
    for step, x in enumerate(w, 1):
        r = 0
        while r < len(P) and P[r][-1] > x:            # x bumps the first larger entry
            j = pick(i for i, y in enumerate(P[r]) if y > x); P[r][j], x, r = x, P[r][j], r + 1
        if r == len(P): P.append([]); Q.append([])
        P[r].append(x); Q[r].append(step)             # x lands at the end of row r
    return P, Q
def unrsk(P, Q):                          # reverse bumping: undo the last step first
    P, Q, w = [r[:] for r in P], [r[:] for r in Q], []
    for step in range(sum(map(len, Q)), 0, -1):
        r = [i for i, row in enumerate(Q) if row and row[-1] == step][0]
        Q[r].pop(); x = P[r].pop()
        for rr in range(r - 1, -1, -1):               # push x back up: it displaces the largest smaller entry
            j = max(i for i, y in enumerate(P[rr]) if y < x); P[rr][j], x = x, P[rr][j]
        w.append(x)
    return tuple(w[::-1])
def shapes(n, cap=99):                    # partitions of n, largest part first
    if n == 0: yield (); return
    for k in range(min(n, cap), 0, -1): yield from ((k,) + rest for rest in shapes(n - k, k))
def f(lam):                               # road two: the box holding n sits at a corner
    lam = tuple(p for p in lam if p)
    return 1 if not lam else sum(f(lam[:i] + (lam[i] - 1,) + lam[i + 1:])
        for i in range(len(lam)) if i == len(lam) - 1 or lam[i] > lam[i + 1])
def run(w, sign):                         # longest rising (+1) or falling (-1) run, by DP
    best = []
    for j in range(len(w)): best.append(1 + max([best[i] for i in range(j) if sign * (w[j] - w[i]) > 0] or [0]))
    return max(best)
def standard(P): return all(x < y for r in P for x, y in zip(r, r[1:])) and all(len(a) >= len(b) and all(x < y for x, y in zip(a, b)) for a, b in zip(P, P[1:]))
T = lambda P: " / ".join(" ".join(map(str, r)) for r in P if r); L = lambda xs: ", ".join(map(str, xs)); S = lambda lam: "(" + L(lam) + ")"; yn = lambda b: "yes" if b else "no"
w = (2, 4, 1, 3); P, Q = rsk(w); lams = list(shapes(4)); fs = [f(l) for l in lams]
print(f"insert {L(w)}: " + " | ".join(T(rsk(w[:k])[0]) for k in range(1, 5)))
print(f"P = {T(P)}; Q = {T(Q)}; shape {S([len(r) for r in P])}; reverse bumping gives {L(unrsk(P, Q))}")
print(f"first row {len(P[0])} = longest rising run {run(w, 1)}, so 4 - {run(w, 1)} = {4 - run(w, 1)} volumes move; rows {len(P)} = longest falling run {run(w, -1)}")
print("n = 4 tableau counts, by corners: " + ", ".join(f"{S(l)} {c}" for l, c in zip(lams, fs)))
print(f"squares {' + '.join(str(c * c) for c in fs)} = {sum(c * c for c in fs)} = 4!")
fact, total, schensted, es, ws = 1, 0, 0, 0, [()]
for n in range(1, 8):                     # every shuffle of 1..n: slot n into every shuffle of 1..n-1
    fact *= n; ws = [v[:i] + (n,) + v[i:] for v in ws for i in range(n)]; out = [rsk(v) for v in ws]
    pairs = {repr(o) for o in out}; back = all(unrsk(*o) == v for o, v in zip(out, ws))
    tot = sum(f(l) ** 2 for l in shapes(n)); byshape = {}; total += len(ws)
    for (p, q), v in zip(out, ws):
        byshape.setdefault(tuple(map(len, p)), set()).add(repr(p))
        schensted += len(p[0]) == run(v, 1) and len(p) == run(v, -1)
        es += run(v, 1) * run(v, -1) >= n
    if n >= 4: print(f"n = {n}: {len(ws)} shuffles, {len(pairs)} distinct (P, Q) pairs, sum of squares {tot}, all undone: {yn(back)}")
    assert len(pairs) == fact == tot and back and all(len(byshape[l]) == f(l) for l in shapes(n)) and all(standard(p) and standard(q) and list(map(len, p)) == list(map(len, q)) for p, q in out)
    if n == 4: out4, ws4 = out, ws
print(f"Schensted, first row = longest rising run and rows = longest falling run: {schensted} of {total} shuffles")
print(f"Erdos-Szekeres, rising x falling >= n: {es} of {total} shuffles, n = 1 to 7")
inv, same = sum(all(v[v[i] - 1] == i + 1 for i in range(4)) for v in ws4), sum(p == q for p, q in out4)
print(f"mistake 1, counts unsquared: {' + '.join(map(str, fs))} = {sum(fs)}, the {inv} shuffles that are their own undo ({same} with P = Q)")
print(f"mistake 2, P alone: 24 shuffles give {len({repr(p) for p, q in out4})} tableaux; 2, 1, 4, 3 also gives {T(rsk((2, 1, 4, 3))[0])}")
print(f"mistake 3, first row read as the run: 3, 4, 2, 1 gives first row {T(rsk((3, 4, 2, 1))[0][:1])}, but 4 comes before 1")
print(f"mistake 4, bump the last larger entry: 2, 3, 1 gives {T(rsk((2, 3, 1), max)[0])}, whose first row falls")
assert schensted == es == total == 5913 and sum(fs) == inv == same == 10        # Schensted, involutions
print("ALL CHECKS PASS")
