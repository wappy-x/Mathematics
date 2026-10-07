# Catalan bijections -- the check behind the card.  Nothing is imported.  At size 4 five families are counted
# separately, each by its own rule: 8-step paths that never dip, bracket words that cancel away, plane binary
# trees, cuttings of a hexagon, handshakes among 8 with no arms crossing.  The recipes then carry each across.
dips = lambda w: min([0] + [2 * w[:i].count("(") - i for i in range(1, len(w) + 1)]) < 0
cancels = lambda w: cancels(w.replace("()", "")) if "()" in w else w == ""
cross = lambda p, q: p[0] < q[0] < p[1] < q[1] or q[0] < p[0] < q[1] < p[1]
untree = lambda t: "" if t is None else "(" + untree(t[0]) + ")" + untree(t[1])
fold = lambda t: "." if t is None else "(" + "".join(sorted([fold(t[0]), fold(t[1])])) + ")"
shakeword = lambda p, k: "".join("(" if i in {a for a, _ in p} else ")" for i in range(k))
fact = lambda j: 1 if j == 0 else j * fact(j - 1)
cat = lambda j: fact(2 * j) // fact(j) ** 2 // (j + 1)
yn = lambda c: "yes" if c else "no"
def grow(n):                                   # rule three: plane binary trees, grown as trees
    return [None] if n == 0 else [(l, r) for i in range(n) for l in grow(i) for r in grow(n - 1 - i)]
def tree(w):                                   # a bracket word -> a tree, cut at the first return
    if w == "": return None
    i = next(j for j in range(len(w)) if 2 * w[:j + 1].count("(") == j + 1)
    return tree(w[1:i]), tree(w[i + 1:])
def cuttings(m):                               # rule four: sets of m-3 diagonals, none crossing
    ds = [(a, b) for a in range(m) for b in range(a + 2, m) if (a, b) != (0, m - 1)]
    sub = ([ds[i] for i in range(len(ds)) if j >> i & 1] for j in range(1 << len(ds)))
    return [p for p in sub if len(p) == m - 3 and not any(cross(x, y) for x in p for y in p)]
def apex(cut, m, a, b):                        # the corner the triangle on edge a-b points at
    side = lambda p, q: q == p + 1 or (p, q) in cut or (p, q) == (0, m - 1)
    return next(c for c in range(a + 1, b) if side(a, c) and side(c, b))
def cutword(cut, m, a, b):                     # one piece of the cut polygon, read as brackets
    if b == a + 1: return ""
    c = apex(cut, m, a, b); return "(" + cutword(cut, m, a, c) + ")" + cutword(cut, m, c, b)
def pairings(s):                               # rule five: every pairing of the seats, crossings and all
    return [()] if not s else [((s[0], b),) + r for i, b in enumerate(s[1:]) for r in pairings(s[1:i + 1] + s[i + 2:])]
def census(n):                                 # the five families at size n, each on its own terms
    ws = ["".join("()"[j >> i & 1] for i in range(2 * n)) for j in range(1 << (2 * n))]
    level = [w for w in ws if w.count("(") == n]
    sh = [p for p in pairings(tuple(range(2 * n))) if not any(cross(x, y) for x in p for y in p)]
    return level, [w for w in level if not dips(w)], [w for w in ws if cancels(w)], grow(n), cuttings(n + 2), sh
level, dyck, brack, forest, cuts, shakes = census(4); l5, d5, b5, f5, c5, s5 = census(5)   # and the case at five pairs
fan, nest = [(0, 2), (0, 3), (0, 4)], [(0, 7), (1, 6), (2, 5), (3, 4)]   # one named cutting, one named handshake
cw, sw = sorted(cutword(c, 6, 0, 5) for c in cuts), sorted(shakeword(p, 8) for p in shakes)
back, ds, byapex = sorted(untree(t) for t in forest), sorted(dyck), [sum(1 for c in cuts if apex(c, 6, 0, 5) == j + 1) for j in range(4)]
print("size 4: a hexagon, corners 0 to 5, base edge 0-5, 3 diagonals, 4 triangles; 8 seats; 8 steps")
print(f"words of 8 marks with 4 opens: {len(level)}; of those, never dipping below the start: {len(dyck)}")
print(f"each family by its own rule -- paths {len(dyck)}, words that cancel away {len(brack)}, trees {len(forest)}, "
      f"cuttings {len(cuts)}, handshakes {len(shakes)}; and by the closed form, {len(level)} divided by 4 + 1 = {cat(4)}")
print(f"the {cat(4)} bracket words in order: {' '.join(ds)}")
print(f"word -> tree -> word returns every one of them: {yn(all(untree(tree(w)) == w for w in dyck))}; the {len(forest)} "
      f"grown trees give back those same {cat(4)} words: {yn(back == ds)}; the fan cut from corner 0, diagonals {fan}, "
      f"reads {cutword(fan, 6, 0, 5)}, and so do the nested handshakes {nest}: {yn(shakeword(nest, 8) == cutword(fan, 6, 0, 5))}")
print(f"every cutting's word, and every handshake's word, lands on all {cat(4)}, one apiece: {yn(cw == ds)} and {yn(sw == ds)}")
print(f"the {cat(4)} cuttings by the corner the base triangle points at (1, 2, 3, 4): {byapex}; Cat(i) x Cat(3-i): {[cat(i) * cat(3 - i) for i in range(4)]}")
print(f"at size 5, the shelf's 10-step paths: {len(l5)} words come back level, {len(d5)} never dip, and paths, "
      f"words, trees, cuttings of a 7-gon, handshakes among 10 count {len(d5)}, {len(b5)}, {len(f5)}, {len(c5)}, {len(s5)}")
print(f"mistake 1, a hexagon read as size 6: {cat(6)}, not {cat(4)}; mistake 2, arms allowed to cross: "
      f"{len(pairings(tuple(range(8))))} pairings of 8 people, not {len(shakes)}")
print(f"mistake 3, both branches of every fork swapped freely: {len({fold(t) for t in forest})} shapes, not "
      f"{len(forest)}; mistake 4, every word with 4 opens, dips included: {len(level)}, not {len(dyck)}")
assert len(dyck) == len(brack) == len(forest) == len(cuts) == len(shakes) == cat(4) and len(level) == fact(8) // fact(4) ** 2
assert cw == ds and sw == ds and back == ds and all(untree(tree(w)) == w for w in dyck)
assert fan in cuts and tuple(nest) in shakes and cutword(fan, 6, 0, 5) == shakeword(nest, 8) and all(shakeword(p, 8) in ds for p in pairings(tuple(range(8))))
assert byapex == [cat(i) * cat(3 - i) for i in range(4)] and len(d5) == len(b5) == len(f5) == len(c5) == len(s5) == cat(5)
print("ALL CHECKS PASS")
