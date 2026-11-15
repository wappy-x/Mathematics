# Van Kampen's theorem -- the check behind the card.  Nothing is imported.
# A word is a string of loops: a = once round post A, b = once round post B,
# and the capitals A, B are the same loops run backwards (a^-1, b^-1).
INV = {"a": "A", "A": "a", "b": "B", "B": "b"}

def reduce(word):                         # cancel neighbours like aA until none is left
    out = []
    for c in word:
        if out and out[-1] == INV[c]:
            out.pop()
        else:
            out.append(c)
    return "".join(out)

def reduced_words(n):                     # road 1: build every reduced word of length n
    words = [""]
    for _ in range(n):
        words = [w + c for w in words for c in "abAB" if not (w and w[-1] == INV[c])]
    return words

M = {"a": ((1, 2), (0, 1)), "A": ((1, -2), (0, 1)),   # road 2: each letter becomes
     "b": ((1, 0), (2, 1)), "B": ((1, 0), (-2, 1))}   # a 2 x 2 whole-number matrix
I2 = ((1, 0), (0, 1))

def mul(p, q):
    return tuple(tuple(sum(p[i][k] * q[k][j] for k in range(2)) for j in range(2)) for i in range(2))

def matrix(word):
    out = I2
    for c in word:
        out = mul(out, M[c])
    return out

def show(m):
    return f"[[{m[0][0]}, {m[0][1]}], [{m[1][0]}, {m[1][1]}]]"

def windings(word):                       # net turns round post A and round post B
    return (word.count("a") - word.count("A"), word.count("b") - word.count("B"))

def torus_form(word):                     # torus road 1: use ab = ba to move every a-letter
    return reduce(sorted(word, key=lambda c: c in "bB"))   # left, then cancel

def rank(vertices, edges):                # road 3: loops in a graph = E - V + pieces
    parent = {v: v for v in vertices}
    def find(v):
        while parent[v] != v:
            v = parent[v]
        return v
    for u, v in edges:
        parent[find(u)] = find(v)
    pieces = len({find(v) for v in vertices})
    return len(edges) - len(vertices) + pieces, pieces

def drop(word, letters):                  # pull a post out: its loops become nothing
    return reduce("".join(c for c in word if c not in letters))

w = "abAB"
print("one post, wound then unwound: aA reduces to '" + reduce("aA") + "', the lead comes free")
print(f"two posts, wound then unwound in turn: {w} reduces to '{reduce(w)}', length {len(reduce(w))}")
print(f"{w} net turns round post A and round post B: {windings(w)}")
print("matrix after each letter: " + ", ".join(f"{w[:k]} {show(matrix(w[:k]))}" for k in range(1, 5)))
print(f"{w} as a matrix: {show(matrix(w))}; the identity: {'yes' if matrix(w) == I2 else 'no'}")
print(f"pull post A out: {w} becomes '{drop(w, 'aA')}'; pull post B out: '{drop(w, 'bB')}'")

counts = [len(reduced_words(n)) for n in range(5)]
formula = [1] + [4 * 3 ** (n - 1) for n in range(1, 5)]
ball = [x for n in range(5) for x in reduced_words(n)]
mats = {matrix(x) for x in ball}
only_empty = [x for x in ball if matrix(x) == I2] == [""]
print(f"free group on a, b: reduced words of length 0 to 4: {counts}")
print(f"formula 4 x 3^(L-1) for L = 1 to 4: {formula[1:]}")
print(f"words of length at most 4: {len(ball)}; distinct matrices: {len(mats)}; "
      f"only the empty word gives the identity: {'yes' if only_empty else 'no'}")

V8 = ["x0", "a1", "a2", "b1", "b2"]       # the figure eight as two triangles at x0
E8 = [("x0", "a1"), ("a1", "a2"), ("a2", "x0"), ("x0", "b1"), ("b1", "b2"), ("b2", "x0")]
rX, _ = rank(V8, E8)
rU, _ = rank(V8, [e for e in E8 if e != ("b1", "b2")])      # U: cut the point q on loop b
rV, _ = rank(V8, [e for e in E8 if e != ("a1", "a2")])      # V: cut the point p on loop a
rW, pW = rank(V8, [e for e in E8 if e not in (("a1", "a2"), ("b1", "b2"))])
print(f"figure eight as a graph: V = {len(V8)}, E = {len(E8)}, independent loops {rX}")
print(f"piece U (cut q): {rU} loop; piece V (cut p): {rV} loop; overlap: {rW} loops in {pW} piece")
print(f"van Kampen: U gives {rU} letter, V gives {rV}, the overlap adds no relation: free, rank {rU + rV}")

print(f"torus: overlap loop read in U = {w}, read in V = '' (it bounds the disc), so {w} = 1")
tor_swap = [len({torus_form(x) for x in ball if len(x) <= n}) for n in range(5)]
tor_sums = [len({windings(x) for x in ball if len(x) <= n}) for n in range(5)]
tor_formula = [2 * n * n + 2 * n + 1 for n in range(5)]
print(f"torus, {w} by swaps: '{torus_form(w)}'; abaB stays '{reduce('abaB')}' in the free group, "
      f"by swaps on the torus: '{torus_form('abaB')}'")
print(f"torus elements within L letters, L = 0 to 4, by swaps: {tor_swap}")
print(f"the same, by net turns: {tor_sums}; formula 2L^2 + 2L + 1: {tor_formula}")
print(f"free group within L letters, L = 0 to 4: {[sum(counts[:n + 1]) for n in range(5)]}")

VC, EC = ["x0", "y", "z"], [("x0", "y"), ("y", "z"), ("z", "x0")]
rC, _ = rank(VC, EC)                                           # the whole circle
rCU, _ = rank(VC, EC[:1] + EC[2:])                             # U: cut a point on y-z
rCV, _ = rank(VC, EC[:2])                                      # V: cut a point on z-x0
_, pC = rank(VC, EC[:1])                                       # overlap: both cuts
print(f"mistake 1, circle cut into two arcs: overlap in {pC} pieces; naive answer {rCU} + {rCV} = {rCU + rCV} "
      f"letters, the trivial group; true rank {rC}, the integers")
print(f"mistake 2, product instead of free product: {w} has net turns {windings(w)} and would be 1; "
      f"its matrix {show(matrix(w))} says it is not")
print(f"mistake 3, torus with its relation forgotten: {sum(counts[:3])} elements within 2 letters, "
      f"true {tor_swap[2]}")
print(f"mistake 4, letters never cancelled: {sum(4 ** n for n in range(3))} strings within "
      f"2 letters, true {sum(counts[:3])}")
print("figure, circles centred (120, 110) and (300, 110), radius 90, x0 = (210, 110), "
      "p = (30, 110), q = (390, 110)")
assert counts == formula and len(mats) == len(ball) == 161 and only_empty   # words against matrices
assert windings(w) == (0, 0) and matrix(w) != I2 and reduce(w) == w        # stuck, though net 0
assert rX == rU + rV == 2 and rW == 0 and pW == 1                           # graph road
assert tor_swap == tor_sums == tor_formula and torus_form(w) == ""         # torus, three roads
assert rC == 1 and rCU + rCV == 0 and pC == 2                                                 # the bad cut
print("ALL CHECKS PASS")
