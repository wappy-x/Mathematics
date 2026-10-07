# Direct proof -- the check behind the card.  Nothing is imported.  Two egg trays,
# 12 and 18, added plainly and again the way the proof does it; then one chessboard
# row split into its two cases, and all 64 squares counted one at a time.
def strip_pairs(n):                 # take 2 away until you cannot: 30 -> (15, 0)
    c = 0
    while n >= 2:
        n, c = n - 2, c + 1
    return c, n
def row(name, value):
    print(f"{name:<39}{value}")
m, n = 12, 18
a, b, total = m // 2, n // 2, m + n
pairs, over = strip_pairs(total)
odd_pairs, odd_over = strip_pairs(m + 15)
black_row, white_row = [i % 2 == 0 for i in range(8)], [i % 2 == 1 for i in range(8)]  # two kinds of row
board = [(r + c) % 2 == 0 for r in range(8) for c in range(8)]
row("tray one, 12 eggs", f"{m} = 2 x {a}")
row("tray two, 18 eggs", f"{n} = 2 x {b}")
row("the two trays added", f"{m} + {n} = {total}")
row("the 2 pulled out, as the proof does it", f"2 x ({a} + {b}) = 2 x {a + b} = {2 * (a + b)}")
row("taking pairs away until none are left", f"{pairs} pairs, {over} left over")
row("a row that starts black", f"{black_row.count(True)} black, {black_row.count(False)} white")
row("a row that starts white", f"{white_row.count(True)} black, {white_row.count(False)} white")
row("8 rows of 8, by cases", f"{8 * black_row.count(True)} black, {8 * white_row.count(False)} white")
row("counting all 64 squares one by one", f"{board.count(True)} black, {board.count(False)} white")
print(f"the three mistakes come out at {m + 15} ({odd_pairs} pairs, {odd_over} over), {4 * black_row.count(True)} and {2 * a + b}")
assert total == 30 and total == 2 * (a + b) and (pairs, over) == (15, 0)
assert board.count(True) == 8 * black_row.count(True) == 32 and board.count(False) == 32
assert (odd_pairs, odd_over) == (13, 1) and 2 * a + b == 21 and len(board) == 64
print("ALL CHECKS PASS")
