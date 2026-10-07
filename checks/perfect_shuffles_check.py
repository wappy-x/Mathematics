# Perfect shuffles -- the check behind the card.  Nothing is imported.  A deck
# of 52, positions 0 to 51.  One perfect out-riffle doubles a position on the
# 51-clock; 0 and 51 never move.  Two roads: the doubling, and a real riffle.
def moved(p, n, times=1):            # where the card at position p sits after some riffles
    for _ in range(times): p = p if p == n - 1 else (2 * p) % (n - 1)
    return p
def riffle(deck, inn=0):             # cut the deck in half and interleave the two halves
    half = len(deck) // 2
    top, bot = (deck[half:], deck[:half]) if inn else (deck[:half], deck[half:])
    return [c for pair in zip(top, bot) for c in pair]
def by_riffling(n, inn=0):           # riffle a real deck, counting until it is back in order
    home, deck, count = list(range(n)), list(range(n)), 0
    while count == 0 or deck != home: deck, count = riffle(deck, inn), count + 1
    return count
def by_doubling(n): return min(t for t in range(1, 999) if moved(1, n, t) == 1)
def row(name, *vals): print(f"{name:<42}" + "".join(f"{v:>4}" for v in vals))
row("one perfect riffle sends position 10 to", moved(10, 52))
row("all 52 home: by doubling, by real riffles", by_doubling(52), by_riffling(52))
row("1 doubled eight times, 256 = 5 x 51 + 1", 2 ** 8)
row("after seven riffles, cards out of place", sum(1 for p in range(52) if moved(p, 52, 7) != p))
row("on a 52-clock, position 10 after eight", (10 * 2 ** 8) % 52)
row("in-shuffles, on a 53-clock, come home in", by_riffling(52, 1))
row("cards that never move: positions", *[p for p in range(52) if moved(p, 52) == p])
row("the trip home from 10", *[moved(10, 52, t) for t in range(9)])
row("1 doubled on the 51-clock", *[moved(1, 52, t) for t in range(1, 9)])
row("decks of 8, 10, 52, 64 come home after", *[by_doubling(n) for n in (8, 10, 52, 64)])
assert [moved(10, 52, t) for t in range(9)] == [10, 20, 40, 29, 7, 14, 28, 5, 10]
assert by_doubling(52) == 8 == by_riffling(52) and 2 ** 8 == 5 * 51 + 1 and by_riffling(52, 1) == 52
assert [by_doubling(n) for n in (8, 10, 52, 64)] == [3, 6, 8, 6] and all(moved(p, 52, 8) == p for p in range(52))
print("ALL CHECKS PASS")
