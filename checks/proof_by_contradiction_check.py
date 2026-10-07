# Proof by contradiction -- the check behind the card.  Nothing is imported.
# An 8-by-8 chessboard with the corners (1,1) and (8,8) cut off, and a box of
# 31 dominoes.  Road 1 colours every square by the row-plus-column rule and
# counts.  Road 2 lists every place a domino can sit and checks what it covers.
BOARD = [(r, c) for r in range(1, 9) for c in range(1, 9)]
def dark(s):                     # (1,1) and (8,8) are dark: row + column is even
    return (s[0] + s[1]) % 2 == 0
def tally(name, squares):
    d = sum(1 for s in squares if dark(s))
    print(f"{name:<32}{len(squares):>8}{d:>6}{len(squares) - d:>7}")
    return (len(squares), d, len(squares) - d)
PLACES = [(a, b) for a in BOARD for b in BOARD
          if a < b and abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1]
SPLIT = sum(1 for a, b in PLACES if dark(a) != dark(b))   # road 2: one of each?
CUT = [s for s in BOARD if s not in ((1, 1), (8, 8))]
MIX = [s for s in BOARD if s not in ((1, 1), (1, 8))]
print(f"{'board':<32}{'squares':>8}{'dark':>6}{'light':>7}")
full = tally("the whole chessboard", BOARD)
cut = tally("two corners cut, both dark", CUT)
mix = tally("two corners cut, one of each", MIX)
print(f"places a domino can sit {len(PLACES)}, of those covering one dark and one light {SPLIT}")
print(f"31 dominoes cover 31 dark and 31 light; the cut board has {cut[1]} dark and {cut[2]} light")
print(f"root 2: 99 x 99 = {99 * 99}, 2 x 70 x 70 = {2 * 70 * 70}, apart by {99 * 99 - 2 * 70 * 70}")
assert full == (64, 32, 32) and cut == (62, 30, 32) and mix == (62, 31, 31)
assert len(PLACES) == 112 and SPLIT == 112
assert 31 * 2 == len(CUT) and 31 != cut[1] and 31 == mix[1]
print("ALL CHECKS PASS")
