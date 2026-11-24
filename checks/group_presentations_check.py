# Group presentations -- the check behind the card.  Nothing is imported.  A word
# is a string of letters.  Road one rewrites words with the relations alone.
# Road two is von Dyck's map: send each letter to a concrete move and multiply.
# Road three multiplies the concrete moves together until nothing new appears.
def reduce(word, rules):                   # road one: apply a relation while one fits
    while any(old in word for old, new in rules):
        for old, new in rules:
            if old in word: word = word.replace(old, new, 1)
    return word
def image(word, gens, mul, one):           # road two: von Dyck's map, letter by letter
    for x in word: one = mul(one, gens[x])
    return one
def close(gens, mul, one):                 # road three: multiply until nothing new
    seen, todo = {one}, [one]
    while todo:
        a = todo.pop(); new = {mul(a, g) for g in gens.values()} - seen
        seen |= new; todo += list(new)
    return seen
def words(letters, n):                     # every word of 1 to n letters
    out, layer = [], [""]
    for _ in range(n): layer = [v + x for v in layer for x in letters]; out += layer
    return out
order = lambda a, mul, one: next(k for k in range(1, 9) if image("x" * k, {"x": a}, mul, one) == one)
turn = lambda p, q: tuple(p[c] for c in q)           # corner maps: q first, then p
quat = lambda p, q: (p[0]*q[0] - p[1]*q[1] - p[2]*q[2] - p[3]*q[3], p[0]*q[1] + p[1]*q[0] + p[2]*q[3] - p[3]*q[2],
                     p[0]*q[2] - p[1]*q[3] + p[2]*q[0] + p[3]*q[1], p[0]*q[3] + p[1]*q[2] - p[2]*q[1] + p[3]*q[0])
TILE = [("ff", ""), ("rrrr", ""), ("fr", "rrrf")]             # f r f = r^-1, used as f r = r^3 f
GROUPS = [("tile <r, f | r^4, f^2, f r f = r^-1>", TILE, {"r": (1, 2, 3, 0), "f": (0, 3, 2, 1)}, turn, (0, 1, 2, 3)),
          ("Q8 <i, j | i^4, i^2 = j^2, j i j^-1 = i^-1>", [("jj", "ii"), ("iiii", ""), ("ji", "iiij")],
           {"i": (0, 1, 0, 0), "j": (0, 0, 1, 0)}, quat, (1, 0, 0, 0))]
twos = []
for name, rules, gens, mul, one in GROUPS:
    ws, im = words("".join(gens), 8), lambda w: image(w, gens, mul, one)
    holds = all(im(a) == im(b) for a, b in rules)
    forms = sorted({reduce(w, rules) for w in ws}, key=lambda w: (w[-1:] in "fj" and w != "", len(w)))
    lands = all(im(w) == im(reduce(w, rules)) for w in ws)
    moves, found = {im(w) for w in forms}, close(gens, mul, one)
    orders = [order(im(w), mul, one) for w in forms]
    twos.append(orders.count(2))
    print(f"{name}\n  relations hold on the concrete moves: {'yes' if holds else 'no'}; words of 1 to 8 letters: {len(ws)}")
    print(f"  normal forms reached: {' '.join(w or 'e' for w in forms)} ({len(forms)})")
    print(f"  every word lands where its normal form lands: {'yes' if lands else 'no'}")
    print(f"  distinct moves from the forms: {len(moves)}; moves found by brute closure: {len(found)}")
    print(f"  orders: {orders}; elements of order 2: {orders.count(2)}")
    assert holds and lands and len(forms) == 8 and moves == found and len(found) == 8
free = [len({reduce(w, TILE[:2]) for w in words("rf", n)}) for n in (4, 6, 8)]
bad = lambda w: image(w, {"r": (1, 2, 3, 0), "f": (2, 3, 0, 1)}, turn, (0, 1, 2, 3))     # f sent to the half turn
miss = sum(bad(w) != bad(reduce(w, TILE)) for w in words("rf", 8))
print(f"mistake 1, drop f r f = r^-1: different elements from words up to 4, 6, 8 letters: {free}")
print(f"mistake 2, f sent to the half turn: f r f lands on {list(bad('frf'))}, r^-1 on {list(bad('rrr'))}; "
      f"{miss} of {len(words('rf', 8))} words land off their normal form")
print(f"mistake 3, order 8 taken as sameness: elements of order 2, tile {twos[0]}, Q8 {twos[1]}")
COLL, S4 = TILE[:2] + [("fr", "rrf")], close({"a": (1, 0, 2, 3), "b": (1, 2, 3, 0)}, turn, (0, 1, 2, 3))  # f r f = r^2
fits = [len(close(g, turn, (0, 1, 2, 3))) for g in ({"r": r, "f": f} for r in S4 for f in S4)
        if all(image(a, g, turn, (0, 1, 2, 3)) == image(b, g, turn, (0, 1, 2, 3)) for a, b in COLL)]
coll, ffr = {reduce(w, COLL) for w in words("rf", 8)}, [reduce("ffr", COLL), reduce("ffr", COLL[::-1])]   # two rule orders
print(f"trap, f r f = r^2: {len(coll)} normal forms; f f r rewrites to {ffr[0] or 'e'} or to {ffr[1] or 'e'}; largest model in {len(S4)} corner maps: {max(fits)} moves")
assert twos == [5, 1] and free[0] < free[1] < free[2] and bad("frf") != bad("rrr") and miss > 0
assert len(coll) == 8 and ffr == ["r", ""] and max(fits) == 2                # so r = e: the group is e and f
print("ALL CHECKS PASS")
