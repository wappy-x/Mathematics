# ISBN-10 -- the check behind the card.  Nothing is imported.  ISBN 0-306-40615-2:
# ten digits, weights 10 down to 1, and the total has to land on a multiple of 11.
DIGITS = [0, 3, 0, 6, 4, 0, 6, 1, 5, 2]
WEIGHTS = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

def total(ds):                          # each digit times its weight, added up
    return sum(d * w for d, w in zip(ds, WEIGHTS))

t = total(DIGITS)
print(" + ".join(f"{w} x {d}" for d, w in zip(DIGITS, WEIGHTS)) + f" = {t}")
print(f"{t} = {t // 11} x 11, so ISBN 0-306-40615-2 checks out")
runs = [sum(DIGITS[:k + 1]) for k in range(10)]      # second road: running totals
print("running totals: " + ", ".join(str(r) for r in runs) + f", and those add to {sum(runs)}")
nine = total(DIGITS[:9] + [0])          # the first nine alone, weights 10 down to 2
check = (11 - nine % 11) % 11
print(f"first nine digits: {nine} = {nine // 11} x 11 + {nine % 11}, so the check digit is 11 - {nine % 11} = {check}")
swapped = DIGITS[:7] + [DIGITS[8], DIGITS[7]] + DIGITS[9:]
s = total(swapped)
print(f"swap the 1 and the 5: 0-306-40651-2 gives {s} = {s // 11} x 11 + {s % 11}, rejected")
print(f"the swap moved the total by (3 - 2) x (5 - 1) = {s - t}")
print(f"weight gaps run 1 to {WEIGHTS[0] - WEIGHTS[9]} and digit gaps at most 10, and 11 divides neither")
print(f"on a clock of 10 a weight gap of 2 and a digit gap of 5 move it by {2 * 5}, which leaves {2 * 5 % 10}")
print(f"the three mistakes come out at {sum(DIGITS)}, {t % 10} and {nine % 11}")
assert t == 132 and t == sum(runs) and t % 11 == 0
assert check == DIGITS[9] and check == 2 and nine == 130
assert s == 136 and s - t == (3 - 2) * (5 - 1) and s % 11 == 4
print("ALL CHECKS PASS")
