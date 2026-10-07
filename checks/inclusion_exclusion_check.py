# Inclusion-exclusion -- the check behind the card.  Nothing is imported.  A class
# of 30 students, by number: who plays football, who plays chess, who sings in the
# choir.  The formula is worked the plain way, then checked against the roster.
CLASS = set(range(30))                                     # the whole class, by number
FOOT = {*range(0, 9), *range(18, 25), *range(26, 28)}      # 18 play football
CHESS = {*range(9, 13), *range(18, 23), *range(25, 28)}    # 12 play chess
CHOIR = {*range(13, 18), *range(23, 28)}                   # 10 sing in the choir
def row(name, *values):
    print(f"{name:<34}" + "".join(f"{v:>5}" for v in values))
foot, chess, choir = len(FOOT), len(CHESS), len(CHOIR)
fc, fh, ch, all3 = len(FOOT & CHESS), len(FOOT & CHOIR), len(CHESS & CHOIR), len(FOOT & CHESS & CHOIR)
two = foot + chess - fc                              # the overlap comes off once
three = foot + chess + choir - fc - fh - ch + all3   # pairs off, triple back on
alone = [len(a - b - d) for a, b, d in ((FOOT, CHESS, CHOIR), (CHESS, FOOT, CHOIR), (CHOIR, FOOT, CHESS))]
slices = alone + [fc - all3, fh - all3, ch - all3, all3]
row("football, chess, choir", foot, chess, choir)
row("both: F&C, F&H, C&H", fc, fh, ch)
row("all three", all3)
row("at least one of the two, formula", two)
row("at least one of the two, roster", len(FOOT | CHESS))       # the second road
row("neither of the two", len(CLASS) - two)
row("at least one of three, formula", three)
row("at least one of three, roster", len(FOOT | CHESS | CHOIR))
row("none of the three", len(CLASS) - three)
row("the seven slices of a class of 30", *slices)
print(f"the three mistakes come out at {foot + chess}, {three - all3} and {three - 2 * all3}")
assert len(CLASS) == 30 and two == len(FOOT | CHESS) == 23 and len(CLASS) - two == len(CLASS - (FOOT | CHESS)) == 7
assert three == len(FOOT | CHESS | CHOIR) == 28 and len(CLASS) - three == len(CLASS - (FOOT | CHESS | CHOIR)) == 2
assert sum(slices) == three and (foot, chess, choir, fc, fh, ch, all3) == (18, 12, 10, 7, 4, 3, 2)
print("ALL CHECKS PASS")
