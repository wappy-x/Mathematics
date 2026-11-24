# Ordinals -- the check behind the card.  Nothing is imported.  An ordinal below ω·ω is (a, b): a full hotels, then b people.
def name(o):
    w = "" if o[0] == 0 else "ω" if o[0] == 1 else f"ω·{o[0]}"
    return w + "+" + str(o[1]) if w and o[1] else w or str(o[1])
def add(x, y): return (x[0] + y[0], y[1]) if y[0] else (x[0], x[1] + y[1])  # y queues behind x
def walk(blocks):           # the same rule, piece by piece: "H" is a full hotel; a number is that many people
    a, b, last = 0, 0, False                 # ω·a + b people stand ahead of the next one
    for blk in blocks:      # after a full hotel the count of people restarts, and nobody is last
        a, b, last = (a + 1, 0, False) if blk == "H" else (a, b + blk, blk > 0)
    return (a, b), last
W, ONE, P = (1, 0), (0, 1), 5                                # P: the room the back guest is sent to
ROWS = [("the hotel, room by room", W, ["H"]), ("late guest at the back", add(W, ONE), ["H", 1]),
        ("late guest at the front", add(ONE, W), [1, "H"]), ("two hotels in a row", add(W, W), ["H", "H"])]
print(f"{'line-up':<26}{'by the rule':<13}{'by walking':<12}last person")
for label, rule, blocks in ROWS: print(f"{label:<26}{name(rule):<13}{name(walk(blocks)[0]):<12}{'yes' if walk(blocks)[1] else 'no'}")
rooms = [1 if g == "L" else g + 1 for g in ["L", 1, 2, 3, 4, 5]]  # 1 + ω re-paired with ω
pairs = [p for k in range(1, 4) for p in (2 * k - 1, 2 * k)]     # 2·ω: pair k takes two places
vn = [s := frozenset()] + [s := s | {s} for _ in range(3)]      # next ordinal: all so far, plus itself
bad = lambda x, y: y if y[0] else add(x, y)                    # "an endless line swallows what is in front"
assert all(walk(b) == (r, r[1] > 0) for _, r, b in ROWS)       # rule and walk agree
assert rooms == pairs == list(range(1, 7))                     # both pairings keep order and fill places 1 to 6
assert all(len(v) == i and vn[i - 1] in v for i, v in enumerate(vn) if i) and W < add(W, ONE) < add(W, W)
assert add(W, ONE) != add(ONE, W) and bad(W, W) != add(W, W) and add((0, 2), (0, 3)) == walk([3, 2])[0]
print(f"front guest re-paired: L, 1, 2, 3, 4, 5 go to rooms {', '.join(map(str, rooms))}, order kept")
print(f"back guest sent to room {P}: {len(range(1, P))} rooms ahead of it, but guests 1 to {P} all stand ahead of him")
print(f"2·ω, pair k takes places 2k-1 and 2k: {' '.join(map(str, pairs))} ..., so 2·ω = ω; ω·2 = {name(add(W, W))}")
print(f"finite line-ups: 2+3 = {name(add((0, 2), (0, 3)))} and 3+2 = {name(add((0, 3), (0, 2)))}")
print("von Neumann: " + ", ".join(f"{i} = {{{', '.join(str(len(e)) for e in sorted(v, key=len))}}}" for i, v in enumerate(vn)))
print(f"order: ω < ω+1 < ω·2; mistakes come out at {name(add(W, ONE))}, {name(add(W, W))} and {name(bad(W, W))}")
print("ALL CHECKS PASS")
