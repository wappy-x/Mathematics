# Graph isomorphism -- the check behind the card.  Standard library only; no
# graph library.  Graph A is the 20-sided die's corner network (an icosahedron:
# 12 corners, 30 edges) numbered ring by ring; graph B is the same network under
# a secret renaming, written with letters.  Three roads say "the same graph":
# a backtracking search, an individualise-and-refine canonical form, and the
# hand count 12 x 5 x 2 of the die's symmetries.  Both programs print the same.
import math

def icosahedron():
    e = [(0, i) for i in range(1, 6)] + [(11, 6 + j) for j in range(5)]
    e += [(1 + j, 1 + (j + 1) % 5) for j in range(5)] + [(6 + j, 6 + (j + 1) % 5) for j in range(5)]
    e += [(1 + j, 6 + j) for j in range(5)] + [(1 + j, 6 + (j + 1) % 5) for j in range(5)]
    return e

def adjacency(n, edges):
    a = [[False] * n for _ in range(n)]
    for u, v in edges:
        a[u][v] = a[v][u] = True
    return a

def nbrs(a, v):
    return [u for u in range(len(a)) if a[v][u]]

def refine(a, col):                       # colour refinement: a colour plus the
    k = -1                                 # sorted colours of the neighbours
    while True:
        sig = [(col[v], sorted(col[u] for u in nbrs(a, v))) for v in range(len(a))]
        names = sorted(set((c, tuple(s)) for c, s in sig))
        col = [names.index((c, tuple(s))) for c, s in sig]
        if len(names) == k:
            return col
        k = len(names)

def canon(a, col):            # road 2: individualise one vertex, refine, recurse
    col = refine(a, col)      # returns (smallest form, leaves giving it, leaves)
    n = len(a)
    if len(set(col)) == n:
        order = sorted(range(n), key=lambda v: col[v])
        form = "".join("1" if a[order[i]][order[j]] else "0" for i in range(n) for j in range(i + 1, n))
        return form, 1, 1
    c = min(x for x in set(col) if col.count(x) > 1)
    best, hits, leaves = None, 0, 0
    for v in [u for u in range(n) if col[u] == c]:
        new = [2 * col[u] + (1 if col[u] == c and u != v else 0) for u in range(n)]
        f, h, l = canon(a, new)
        leaves += l
        if best is None or f < best:
            best, hits = f, h
        elif f == best:
            hits += h
    return best, hits, leaves

def search(a, b):                  # road 1: map A's vertices 0, 1, 2, ... in turn
    n, found, nodes, f = len(a), [], [0, 0], []   # nodes: count, and the count at the first find
    def go(i):
        nodes[0] += 1
        if i == n:
            found.append(list(f)); nodes[1] = nodes[1] or nodes[0]; return
        for w in range(n):
            if w not in f and all(a[i][u] == b[w][f[u]] for u in range(i)):
                f.append(w); go(i + 1); f.pop()
    go(0)
    return found, nodes[0], nodes[1]

def triangles(a):
    n = len(a)
    return sum(a[i][j] and a[j][k] and a[i][k] for i in range(n) for j in range(i) for k in range(j))

L = "abcdefghijkl"
secret = [7, 2, 10, 4, 11, 0, 9, 5, 1, 8, 3, 6]          # A's corner i is B's letter L[secret[i]]
A = adjacency(12, icosahedron())
B = adjacency(12, [(secret[u], secret[v]) for u, v in icosahedron()])
for name, g, lab in (("A", A, str), ("B", B, lambda v: L[v])):
    d = [len(nbrs(g, v)) for v in range(12)]
    print(f"graph {name}: 12 corners, {sum(d) // 2} edges, every degree {min(d)} to {max(d)}, triangles {triangles(g)}")
    print("  " + "; ".join(lab(v) + ": " + " ".join(lab(u) for u in nbrs(g, v)) for v in range(12)))
union = [[False] * 24 for _ in range(24)]
for i in range(12):
    for j in range(12):
        union[i][j], union[12 + i][12 + j] = A[i][j], B[i][j]
cr = refine(union, [0] * 24)
print(f"colour refinement on A and B: {len(set(cr[:12]))} colour in A, {len(set(cr[12:]))} in B: {'it cannot tell' if sorted(cr[:12]) == sorted(cr[12:]) else 'they differ'}")
cA, cB = refine(A, [0] + [1] * 11), refine(B, [0] + [1] * 11)
print(f"after marking corner 0, refinement gives cells of sizes {[cA.count(c) for c in sorted(set(cA))]}")
isos, nodes, first = search(A, B)
print(f"road 1, search: {len(isos)} renamings work; the first at search node {first}; all listed after {nodes} nodes, against 12! = {math.factorial(12)}")
depth = [len({tuple(p[:i]) for p in isos}) for i in range(13)]   # prefixes of the renamings, by length
print("  prefixes of the renamings, length 0 to 12: " + " ".join(map(str, depth)) + f"; sum {sum(depth)}")
f = isos[0]
print("  first one: " + " ".join(f"{i}{L[f[i]]}" for i in range(12)))
checks = sum(A[i][j] == B[f[i]][f[j]] for i in range(12) for j in range(i + 1, 12))
print(f"verifier: {checks} of 66 pairs agree, {sum(A[i][j] and B[f[i]][f[j]] for i in range(12) for j in range(12)) // 2} edges land on edges")
print("secret renaming: " + " ".join(f"{i}{L[secret[i]]}" for i in range(12)) + f"; among the 120: {'yes' if secret in isos else 'no'}")
fa, ha, la = canon(A, [0] * 12)
fb, hb, lb = canon(B, [0] * 12)
print(f"road 2, canonical forms equal: {'yes' if fa == fb else 'no'}; tree leaves {la} and {lb}; leaves giving the form {ha} and {hb}")
print(f"road 3, by hand: 12 corners x 5 neighbours x 2 turns = {12 * 5 * 2}")
naive = sum(A[i][j] and B[i][j] for i in range(12) for j in range(i + 1, 12))
both = {frozenset(e) for e in icosahedron()} & {frozenset((secret[u], secret[v])) for u, v in icosahedron()}
print(f"mistake, reading the labels as matched (corner i = letter i): {naive} of 30 edges land on edges")
k33 = adjacency(6, [(i, j) for i in range(3) for j in range(3, 6)])
prism = adjacency(6, [(0, 1), (1, 2), (0, 2), (3, 4), (4, 5), (3, 5), (0, 3), (1, 4), (2, 5)])
u2 = [[False] * 12 for _ in range(12)]
for i in range(6):
    for j in range(6):
        u2[i][j], u2[6 + i][6 + j] = k33[i][j], prism[i][j]
c2 = refine(u2, [0] * 12)
print(f"K(3,3) against prism: degrees {sorted(len(nbrs(k33, v)) for v in range(6))} and {sorted(len(nbrs(prism, v)) for v in range(6))}")
print(f"  refinement colours {len(set(c2[:6]))} and {len(set(c2[6:]))}, the same: it cannot tell")
print(f"  triangles {triangles(k33)} and {triangles(prism)}; search finds {len(search(k33, prism)[0])} renamings; forms equal: {'yes' if canon(k33, [0] * 6)[0] == canon(prism, [0] * 6)[0] else 'no'}")
print("log10 of step counts, constants set to 1 (illustrative):")
print("        n   n^3  n^(log2 n)  2^((log2 n)^3)  e^sqrt(n ln n)    2^n")
for n in (16, 100, 1000, 1000000):
    lg = lambda x: f"{x:.1f}"
    print(f"{n:>9} {lg(3 * math.log10(n)):>5} {lg(math.log2(n) ** 2 * math.log10(2)):>11} {lg(math.log2(n) ** 3 * math.log10(2)):>15}"
          f" {lg(math.sqrt(n * math.log(n)) / math.log(10)):>15} {lg(n * math.log10(2)):>6}")
assert len(isos) == 120 and secret in isos and checks == 66     # road 1, verified
assert sum(depth) == nodes and first == len(A) + 1              # no dead end; first find with no backing out
assert fa == fb and ha == hb == len(isos)                       # road 2 agrees
assert 12 * 5 * 2 == len(isos) and naive == len(both)           # road 3 agrees; shared labels counted twice
assert len(set(cr)) == 1 and c2[:6] == c2[6:] and len(search(k33, prism)[0]) == 0   # refinement is fooled
assert triangles(A) == triangles(B) == 20 and triangles(prism) == 2
print("ALL CHECKS PASS")
