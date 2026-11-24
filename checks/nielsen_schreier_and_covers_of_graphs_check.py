# Nielsen-Schreier -- the check behind the card.  Nothing is imported.
# The free group on a, b; A and B are the same loops run backwards.  A subgroup
# H is given only by a membership test.  Road 1 enumerates the cosets H w as a
# covering graph, grows a spanning tree, and reads a basis off the other edges.
# Road 2 rewrites every short word of H in that basis and tests freeness.
# The rank is then one count read three ways: by edges, by Schreier's formula, by Euler.
INV = {"a": "A", "A": "a", "b": "B", "B": "b", "x": "X", "X": "x",
       "y": "Y", "Y": "y", "z": "Z", "Z": "z"}

def reduce(w):                                   # cancel neighbouring pairs such as aA
    out = []
    for c in w:
        if out and out[-1] == INV[c]:
            out.pop()
        else:
            out.append(c)
    return "".join(out)

def inverse(w):
    return "".join(INV[c] for c in reversed(w))

def even(w):                                     # the card's subgroup: even length
    return len(w) % 2 == 0

def turns3(w):                                   # net turns, both posts, a multiple of 3
    return (w.count("a") + w.count("b") - w.count("A") - w.count("B")) % 3 == 0

def net_zero(w):                                 # net turns 0 round each post separately
    return w.count("a") == w.count("A") and w.count("b") == w.count("B")

def coset_graph(member, cap=60):                 # road 1: vertices are the cosets H w
    reps, out, tree, i = [""], {}, set(), 0
    while i < len(reps) and len(reps) <= cap:
        for x in "ab":
            w = reduce(reps[i] + x)              # same coset as r exactly when w r^-1 is in H
            j = next((k for k, r in enumerate(reps) if member(reduce(w + inverse(r)))), None)
            if j is None:
                j = len(reps)
                reps.append(w)
                tree.add((i, x))                 # the edge that found a vertex joins the tree
            out[(i, x)] = j
        i += 1
    return reps, out, tree

def basis(reps, out, tree):                      # one loop per edge outside the tree
    return [(u, x, out[(u, x)], reduce(reps[u] + x + inverse(reps[out[(u, x)]])))
            for x in "ab" for u in range(len(reps)) if (u, x) not in tree]

def reduced_words(alphabet, n):                  # every reduced word of length 0 to n
    words, layer = [""], [""]
    for _ in range(n):
        layer = [w + c for w in layer for c in alphabet if not w or w[-1] != INV[c]]
        words += layer
    return words

def show(w):
    return w if w else "1"

reps, out, tree = coset_graph(even)
k, V, E = len(reps), len(reps), len(out)
B = basis(reps, out, tree)
names = {(u, x): "xyz"[i] for i, (u, x, v, w) in enumerate(B)}
meaning = {"xyz"[i]: w for i, (u, x, v, w) in enumerate(B)}

def rewrite(w):                                  # road 2: walk w, note each non-tree edge
    v, word = 0, ""
    for c in w:
        if c in "ab":
            word, v = word + names.get((v, c), ""), out[(v, c)]
        else:
            u = next(u for u in range(k) if out[(u, INV[c])] == v)
            word, v = word + INV[names[(u, INV[c])]] if (u, INV[c]) in names else word, u
    return v, word

def expand(word):
    return reduce("".join(meaning[c] if c in meaning else inverse(meaning[INV[c]]) for c in word))

print("subgroup H: reduced words of even length in a, b (A, B: a, b run backwards)")
print(f"cosets found by enumeration: {k}, representatives {', '.join(show(r) for r in reps)}")
for (u, x) in sorted(tree):
    print(f"edge {u} -{x}-> {out[(u, x)]}: spanning tree")
for (u, x, v, w) in B:
    print(f"edge {u} -{x}-> {v}: loop {show(reps[u])}.{x}.{show(inverse(reps[v]))} = {w}, named {names[(u, x)]}")
cover = all(sum(out[(u, x)] == v for u in range(k)) == 1 for v in range(k) for x in "ab")
print(f"one a-edge and one b-edge out of and into every vertex (a cover): {'yes' if cover else 'no'}")
print(f"each basis loop lies in H: {'yes' if all(even(w) for (_, _, _, w) in B) else 'no'}")
B2 = basis(["", "b"], out, {(0, "b")})             # the other tree: the b-edge from 0 to 1, so vertex 1 is read b
print(f"another spanning tree, the b-edge from 0 to 1: basis {', '.join(w for *_, w in B2)}, again {len(B2)} words")
chi = V - E
print(f"rank three ways: E - V + 1 = {E} - {V} + 1 = {E - V + 1}; Schreier 1 + {k} x (2 - 1) = "
      f"{1 + k * (2 - 1)}; Euler chi = {k} x (1 - 2) = {chi}, rank 1 - chi = {1 - chi}")
for w in ["bb", "ba", "abab"]:
    end, word = rewrite(w)
    print(f"rewrite {w}: path ends at vertex {end}, crosses {word}; expands back to {expand(word)}")
F = reduced_words("abAB", 6)
ok = [w for w in F if even(w) and rewrite(w)[0] == 0 and expand(rewrite(w)[1]) == w]
closes = all((rewrite(w)[0] == 0) == even(w) for w in F)
print(f"reduced words up to length 6: {len(F)}; walk closes exactly for the even ones: {'yes' if closes else 'no'}")
print(f"even ones rewritten in x, y, z and expanded back unchanged: {len(ok)} of {sum(even(w) for w in F)}")
G = reduced_words("xyzXYZ", 4)
images = {expand(g) for g in G}
print(f"reduced words in x, y, z up to length 4: {len(G)}; distinct words in a, b they expand to: "
      f"{len(images)}; only the empty word gives 1: {'yes' if [g for g in G if expand(g) == ''] == [''] else 'no'}")
reps3, out3, tree3 = coset_graph(turns3)
B3 = basis(reps3, out3, tree3)
print(f"second subgroup, net turns a multiple of 3: index {len(reps3)}, basis {', '.join(w for *_, w in B3)}")
print(f"  rank: E - V + 1 = {len(out3)} - {len(reps3)} + 1 = {len(out3) - len(reps3) + 1}; "
      f"Schreier 1 + {len(reps3)} x (2 - 1) = {1 + len(reps3)}")
print("figure, vertex 0 at (330, 120), vertex 1 at (490, 120), tree edge a from 0 to 1, base eight at (120, 120)")
print(f"mistake 1, keep the tree edge as a generator: its loop 1.a.A = {show(reduce('a' + inverse(reps[1])))}, the empty word")
print(f"mistake 2, edges minus vertices with no + 1: {E} - {V} = {E - V}, true rank {E - V + 1}")
repsC, outC, _ = coset_graph(net_zero)
pt = [(r.count("a") - r.count("A"), r.count("b") - r.count("B")) for r in repsC]   # each coset's (net a, net b)
grid = len(set(pt)) == len(pt) and all(pt[j] == (pt[i][0] + (x == "a"), pt[i][1] + (x == "b")) for (i, x), j in outC.items())
box = [{i for i, (p, q) in enumerate(pt) if 0 <= p < n and 0 <= q < n} for n in range(2, 6)]
boxes = [sum(i in s and j in s for (i, _), j in outC.items()) - len(s) + 1 for s in box]   # edges - vertices + 1
print(f"mistake 3, infinite index (net turns 0 round each post): cosets still growing at {len(repsC)}; each is a grid "
      f"point (net a, net b), each arrow one step: {'yes' if grid else 'no'}; n by n boxes of it, n = 2 to 5, hold {boxes} loops")
vec = {w: (w.count("a") - w.count("A"), w.count("b") - w.count("B")) for (*_, w) in B}
rel = all(vec["aa"][d] == vec["ab"][d] - vec["bA"][d] for d in (0, 1))
print(f"mistake 4, the torus group Z x Z: x, y, z become {vec['aa']}, {vec['bA']}, {vec['ab']}, and x = z - y "
      f"there: {'yes' if rel else 'no'}; in F2, x = z y^-1 reads {expand('zY')}, not aa")
assert k == 2 and [w for *_, w in B] == ["aa", "bA", "ab"] and [w for *_, w in B2] == ["aB", "ba", "bb"]  # by hand
assert len(B) == 1 + k * (2 - 1) == 3                                      # the verified basis has Schreier's count
assert closes and len(ok) == 1 + 12 + 108 + 972                            # generates H, 1093 words
assert len(images) == len(G) == 1 + 6 + 30 + 150 + 750                     # no hidden relation
assert [w for *_, w in B3] == ["aaa", "bA", "abAA", "aab"] and len(repsC) > 60
assert grid and boxes == [1, 4, 9, 16] and rel and expand("zY") != "aa"
print("ALL CHECKS PASS")
