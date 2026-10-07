# EAN-13 check digits -- the check behind the card.  Nothing is imported.  The
# barcode 5901234123457: weights 1, 3, 1, 3, ... left to right, and all
# thirteen weighted digits must add to a multiple of 10.
CODE = "5901234123457"
def weighted(code):                 # 1, 3, 1, 3, ... starting at 1 on the left
    return [int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(code)]

def total(code):
    return sum(weighted(code))

def row(name, value, tail=""):
    print(f"{name:<38}{value:>4}{tail}")

first12 = total(CODE[:12])
check = (10 - first12 % 10) % 10                      # the second road: no search
print("the twelve digits, weighted:  " + " ".join(str(v) for v in weighted(CODE[:12])))
row("weighted sum of the first twelve", first12)
row("the multiple of 10 it lands on", first12 + check)
row("what is missing, the check digit", check)
row(f"all thirteen weighted, {first12} + {check}", total(CODE))
for name, code in (("one digit wrong, 5901834123457", "5901834123457"),
                   ("neighbours swapped, 5091234123457", "5091234123457"),
                   ("a 0 and a 5 side by side, valid", "5905234123455"),
                   ("those two swapped, 5950234123455", "5950234123455")):
    row(name, total(code), "  passes" if total(code) % 10 == 0 else "  fails")
print(f"a Luhn double folds: 2 x 7 = {2 * 7}, then {14 // 10} + {14 % 10} = {14 // 10 + 14 % 10}")
assert check == 7 and int(CODE[12]) == check and first12 == 83
assert total(CODE) == 90 and total("5901834123457") == 96 and total("5091234123457") == 72
assert total("5905234123455") == 100 and total("5950234123455") == 90
print("ALL CHECKS PASS")
