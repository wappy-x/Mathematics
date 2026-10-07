# Even and odd -- the check behind the card.  Nothing is imported.  The hallway switch:
# eleven trips, three flips each, plus four.  Counts paired off, then flipped one by one.
def parity(n):                     # n // 2 is whole-number division: the number of pairs
    return "even" if n - 2 * (n // 2) == 0 else "odd"   # the leftover is 0 or 1

def flip(n):                       # the switch starts off; flip it n times
    on = False
    for _ in range(n): on = not on
    return "on" if on else "off"

def row(label, work, value):
    print(f"{label:<30}{work:>16}   {parity(value)}")

trips, each, extra, instead = 11, 3, 4, 5
mine = trips * each
total, other = mine + extra, mine + instead
row("eleven trips, three flips each", f"{trips} x {each} = {mine}", mine)
row("the housemate's flips", f"{extra}", extra)
row("all the flips", f"{mine} + {extra} = {total}", total)
row("paired off", f"{total // 2} x 2{' + 1' if parity(total) == 'odd' else ''} = {total}", total)
print(f"{f'starts off, {total} flips':<30}{flip(total):>16}")
row("had the housemate flipped 5", f"{mine} + {instead} = {other}", other)
row("paired off", f"{other // 2} x 2{' + 1' if parity(other) == 'odd' else ''} = {other}", other)
print(f"{f'starts off, {other} flips':<30}{flip(other):>16}")
row("peel one trip off the eleven", f"{trips - 1} x {each} = {mine - each}", mine - each)
row("nobody touches it", "0", 0)
assert flip(total) == "on" and parity(total) == "odd" and total == 2 * (total // 2) + 1
assert flip(other) == "off" and parity(other) == "even" and other == 2 * (other // 2)
assert mine == (trips - 1) * each + each and parity(mine - each) == "even"
print("ALL CHECKS PASS")
