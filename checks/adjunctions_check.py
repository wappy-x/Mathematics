# Adjunctions -- the check behind the card.  Nothing is imported.
# Free groups against forgetting: a homomorphism out of the free group on the
# letters a, b is the same thing as a choice of where a and b go.  The target
# is the tile group: the 8 ways a square tile fits its recess, written as
# permutations of the corners 0, 1, 2, 3.  Then a Galois connection on numbers.

def compose(p, q):                        # do q first, then p
    return tuple(p[q[i]] for i in range(4))

def inverse(p):
    out = [0] * 4
    for i in range(4):
        out[p[i]] = i
    return tuple(out)

def power(p, k):
    out = (0, 1, 2, 3)
    for _ in range(k):
        out = compose(p, out)
    return out

E, R, F = (0, 1, 2, 3), (1, 2, 3, 0), (0, 3, 2, 1)   # unmoved, quarter turn, flip
TILE, NAME = [], {}
for j in range(2):
    for k in range(4):
        p = compose(power(R, k), power(F, j))
        TILE.append(p)
        NAME[p] = (["", "r", "r2", "r3"][k] + ("f" if j else "")) or "e"
INV = {"a": "A", "A": "a", "b": "B", "B": "b"}     # A is a backwards, B is b backwards

def reduce(word):                         # cancel neighbouring letter-undo pairs
    out = []
    for x in word:
        if out and out[-1] == INV[x]:
            out.pop()
        else:
            out.append(x)
    return "".join(out)

words = [""]                              # every reduced word up to length 4
for n in range(4):
    words += [w + x for w in words if len(w) == n for x in "abAB" if reduce(w + x) == w + x]
short = [w for w in words if len(w) <= 2]

def extend(img, word):                    # the counit's job: multiply the letters out
    acc = E
    for x in word:
        acc = compose(acc, img[x])
    return acc

def law_holds(img):                       # phi(u v) = phi(u) phi(v) on every short pair
    return all(extend(img, reduce(u + v)) == compose(extend(img, u), extend(img, v))
               for u in short for v in short)

choices = [(x, y) for x in TILE for y in TILE]      # functions from {a, b} to the tile
homs = 0
for x, y in choices:
    img = {"a": x, "A": inverse(x), "b": y, "B": inverse(y)}
    if law_holds(img) and extend(img, "a") == x and extend(img, "b") == y:
        homs += 1
commuting = sum(1 for x, y in choices if compose(x, y) == compose(y, x))
killed = sum(1 for x, y in choices
             if extend({"a": x, "A": inverse(x), "b": y, "B": inverse(y)}, "abAB") == E)
classes = {tuple(sorted(compose(compose(g, x), inverse(g)) for g in TILE)) for x in TILE}
ex = {"a": R, "A": inverse(R), "b": F, "B": inverse(F)}

print("== the tile group: 8 moves of a square tile ==")
print("moves:", " ".join(NAME[p] for p in TILE))
print("reduced words of length 1 to 4:", [sum(1 for w in words if len(w) == n) for n in range(1, 5)])
print("== the correspondence: a homomorphism out of the free group <-> where a and b go ==")
print(f"functions from {{a, b}} to the tile: 8 x 8 = {len(choices)}")
print(f"their extensions passing the law on all {len(short)} x {len(short)} short pairs: {homs}")
print(f"example a -> r, b -> f: ab -> {NAME[extend(ex, 'ab')]}, aab -> {NAME[extend(ex, 'aab')]}, "
      f"abAB -> {NAME[extend(ex, 'abAB')]}")
unit_ok = sum(1 for g in TILE if extend({"g": g}, "g") == g)
def rebuild(w):                           # F(unit): letter -> one-letter word; then multiply
    acc = ""
    for x in w:
        piece = x if x in "ab" else "".join(INV[c] for c in reversed(INV[x]))
        acc = reduce(acc + piece)
    return acc
back = sum(1 for w in words if len(w) <= 3 and rebuild(w) == w)
print(f"triangle 1, counit after unit on each move: {unit_ok} of 8 come back unchanged")
print(f"triangle 2, each reduced word up to length 3 rebuilt letter by letter: "
      f"{back} of {sum(1 for w in words if len(w) <= 3)}")
print("== moving a problem across: homomorphisms from <a, b | ab = ba> to the tile ==")
print(f"pairs (p, q) with pq = qp, counted directly: {commuting}")
print(f"extensions sending abAB to e: {killed}")
print(f"conjugacy classes: {len(classes)}; 8 moves x {len(classes)} classes = {8 * len(classes)}")
print(f"pairs in tile x tile, the product the forgetful side keeps: {len(TILE) * len(TILE)}")
print("== a Galois connection: 3x <= y exactly when x <= floor(y / 3) ==")
grid = [(x, y) for x in range(-30, 31) for y in range(-30, 31)]
agree = sum(1 for x, y in grid if (3 * x <= y) == (x <= y // 3))
searched = [max(x for x in range(-30, 31) if 3 * x <= y) for y in range(-30, 31)]
print(f"pairs from -30 to 30 where the two sides agree: {agree} of {len(grid)}")
same = searched == [y // 3 for y in range(-30, 31)]
print(f"right side found by search equals floor division: {'yes' if same else 'no'}")
print(f"van holds 20 boxes, packs of 3: at most {20 // 3} packs")
rounded = sum(1 for x, y in grid if (3 * x <= y) != (x <= (y + 1) // 3))
print(f"mistake, rounding instead of floor: 20 -> {(20 + 1) // 3} packs = {3 * ((20 + 1) // 3)} boxes; "
      f"{rounded} pairs disagree")
z3 = [NAME[x] for x in TILE if power(x, 3) == E]
print(f"mistake, one-generator group of order 3 (not free): 8 choices, {len(z3)} extend: {' '.join(z3)}")
fin = [w for w in words if w and reduce(w * 4) == ""]   # non-empty words with w^4 = 1
def lift(p, w1, w2):                      # r^k f^j -> w1^k w2^j: a candidate map tile -> words
    i = TILE.index(p)
    return reduce(w1 * (i % 4) + w2 * (i // 4))
swapped = sum(1 for w1 in words for w2 in words
              if all(lift(compose(p, q), w1, w2) == reduce(lift(p, w1, w2) + lift(q, w1, w2))
                     for p in TILE for q in TILE))
print(f"mistake, sides swapped: 2^8 = {2 ** 8} functions from tile to {{a, b}}; "
      f"non-empty words up to length 4 with w^4 = 1: {len(fin) or 'none'}")
print(f"  homomorphisms tile -> free group sending r and f to words up to length 4: {swapped}")
print(f"mistake, relation forgotten: {len(choices)} pairs counted, {commuting} are homomorphisms")
assert len(set(TILE)) == 8 and all(compose(p, q) in TILE for p in TILE for q in TILE)
assert homs == len(choices) == 64                   # every choice extends: the bijection
assert commuting == killed == 8 * len(classes) == 40   # three counts of one answer
assert agree == len(grid) and same
assert unit_ok == len(TILE) and back == 1 + sum(4 * 3 ** (n - 1) for n in range(1, 4))   # both triangles
assert rounded > 0 and len(z3) == 1 and fin == [] and swapped == 1
print("ALL CHECKS PASS")
