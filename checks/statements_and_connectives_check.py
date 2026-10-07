# Statements and connectives -- the check behind the card.  Nothing is imported.
# The club door after 9 pm: show ID and be over 21.  Two facts per person, so
# four rows.  Every row is worked twice: straight from the words, then by
# counting how many of the two facts came out true.
DOOR = [("Nia", True, True), ("Sam", True, False), ("Ray", False, True), ("Jo", False, False)]
YN = {True: "yes", False: "no"}
ands, ors, nots, ones, agree = [], [], [], [], 0

print("the door after 9 pm: show ID and be over 21")
print(f"{'name':<6}{'showed ID':>11}{'over 21':>9}{'not over 21':>13}"
      f"{'ID and over 21':>16}{'ID or over 21':>15}")
for name, shown, older in DOOR:
    both = shown and older                       # straight from the words
    either = shown or older
    trues = [shown, older].count(True)           # the second road: count the trues
    agree += int(both == (trues == 2) and either == (trues >= 1))
    ands.append(both); ors.append(either); nots.append(not older); ones.append(trues == 1)
    print(f"{name:<6}{YN[shown]:>11}{YN[older]:>9}{YN[not older]:>13}"
          f"{YN[both]:>16}{YN[either]:>15}")
print(f"and lets in {ands.count(True)} of 4, or lets in {ors.count(True)} of 4, "
      f"not over 21 is true for {nots.count(True)} of 4")
print(f"the counting road agrees on {agree} of 4 rows")
print(f"the three mistakes let in {ors.count(True)}, {ones.count(True)} and "
      f"{[d[1] for d in DOOR].count(True)} of 4")

assert ands == [True, False, False, False]
assert ors == [True, True, True, False] and nots == [False, True, False, True]
assert ands.count(True) == 1 and ors.count(True) == 3 and agree == 4
assert ones.count(True) == 2 and [d[1] for d in DOOR].count(True) == 2
print("ALL CHECKS PASS")
