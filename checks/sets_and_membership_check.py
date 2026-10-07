# Sets and membership -- the check behind the card.  Nothing is imported.  The
# office is five people with ages.  The party guest list is everyone under 30,
# written out by name and built again from the rule, plus two empty lists.
OFFICE = [("Ana", 24), ("Ben", 31), ("Cleo", 28), ("Dev", 41), ("Eli", 29)]

def under_30(age): return age < 30   # the party rule, strict: a 30-year-old is out
def by_rule(test):              # keep the office people the test says yes to
    return frozenset(name for name, age in OFFICE if test(age))

def row(name, value):
    print(f"{name:<30}{value:>6}")

names = ["Eli", "Ana", "Cleo", "Ana"]                 # scrambled, one name twice
written = frozenset(["Ana", "Cleo", "Eli"])           # the list, written out
guests = by_rule(under_30)                            # the same list, from the rule
row("people in the office", len(OFFICE))
row("guests, by the rule", len(guests))
row("guests, written out", len(written))
row("same guests either way", str(guests == written))
row("Ana is on the list", str("Ana" in guests))
row("Ben is on the list", str("Ben" in guests))
row("scrambled spelling, guests", len(frozenset(names)))
row("nobody in the office under 20", len(by_rule(lambda age: age < 20)))
row("nobody in the office over 60", len(by_rule(lambda age: age > 60)))
row("the two empty lists agree", str(by_rule(lambda age: age < 20) == by_rule(lambda age: age > 60)))
print(f"count the repeat: {len(names)} guests; count the orders: {3 * 2 * 1} spellings; drop the rule: {len(OFFICE)} guests")
assert guests == written and frozenset(names) == written    # order and repeats do not count
assert all(under_30(age) == (name in written) for name, age in OFFICE)   # person by person
assert len(guests) == 3 and len(OFFICE) == 5 and len(by_rule(lambda age: age > 60)) == 0 and not under_30(30)
print("ALL CHECKS PASS")
