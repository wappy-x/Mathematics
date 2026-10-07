# Order of operations -- the check behind the card.  Nothing is imported.
# Everything is counted in whole cents: the note is 1000, one apple is 75.
cash, apples, price, friends = 1000, 12, 75, 4

bill = apples * price            # the multiply happens before the subtract
change = cash - bill             # what comes back over the counter
each = change // friends         # the brackets close, then the divide

cost_each = bill // friends      # second route: split the bill, split the note
note_each = cash // friends
no_brackets = cash - apples * price // friends   # the keystrokes, as typed

for label, value in (("twelve apples", bill),
                     ("change from the note", change),
                     ("each friend's change", each),
                     ("each friend's cost", cost_each),
                     ("cost each plus change each", cost_each + each),
                     ("the note split four ways", note_each),
                     ("brackets dropped", no_brackets),
                     ("8 / 2 * 4 by the rungs", 8 // 2 * 4),
                     ("8 / 2 * 4 multiply first", 8 // (2 * 4)),
                     ("five friends, not four", (cash - apples * price) // 5),
                     ("apples at 80 cents", (cash - apples * 80) // friends)):
    print(f"{label:<28}{value:>6}")

assert each == 25, "twelve apples from a 1000-cent note, four ways, is 25 cents each"
assert cost_each + each == note_each, "cost each plus change each is the note split four ways"
assert no_brackets == 775, "without the brackets the divide grabs the apples"
print("ALL CHECKS PASS")
