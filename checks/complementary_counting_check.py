# Counting the complement -- the check behind the card.  Nothing is imported.  A
# 6-character password from 26 letters and 10 digits must carry at least one digit.
# The count is reached twice: the whole collection minus the letters-only passwords,
# and by adding the six "exactly k digits" terms.  A toy version is then listed string
# by string, and a 20-player squad subset by subset, against the same closed forms.
LETTERS, DIGITS, LENGTH = 26, 10, 6
SQUAD, PICK, KEEPERS = 20, 11, 2
TL, TD, TN = 3, 2, 4                       # toy size: 3 letters, 2 digits, length 4

def comb(n, k):                            # n choose k, multiplied out, nothing imported
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

total = (LETTERS + DIGITS) ** LENGTH                       # every password
letters_only = LETTERS ** LENGTH                           # the complement: no digit
by_subtraction = total - letters_only                      # road one
terms = [comb(LENGTH, k) * DIGITS ** k * LETTERS ** (LENGTH - k) for k in range(1, LENGTH + 1)]
by_terms = sum(terms)                                      # road two: exactly k digits
share = 100 * by_subtraction / total

toy_all = toy_letters = 0
for code in range((TL + TD) ** TN):                        # every toy string, listed
    c, seen = code, False
    for _ in range(TN):
        seen, c = seen or c % (TL + TD) >= TL, c // (TL + TD)
    toy_all, toy_letters = toy_all + 1, toy_letters + (0 if seen else 1)
toy_listed = (toy_all, toy_letters, toy_all - toy_letters)
toy_closed = ((TL + TD) ** TN, TL ** TN, (TL + TD) ** TN - TL ** TN)

elevens = keeperless = 0
for mask in range(1 << SQUAD):                             # every subset of the squad, listed
    if bin(mask).count("1") == PICK:
        elevens, keeperless = elevens + 1, keeperless + (0 if mask & ((1 << KEEPERS) - 1) else 1)
squad_listed = (elevens, keeperless, elevens - keeperless)
squad_closed = (comb(SQUAD, PICK), comb(SQUAD - KEEPERS, PICK), comb(SQUAD, PICK) - comb(SQUAD - KEEPERS, PICK))
digit_first = LENGTH * DIGITS * (LETTERS + DIGITS) ** (LENGTH - 1)
keeper_first = KEEPERS * comb(SQUAD - 1, PICK - 1)

print(f"all 6-character passwords from 36 symbols: 36^6 = {total}")
print(f"passwords with no digit at all, 26 letters only: 26^6 = {letters_only}")
print(f"at least one digit, by subtraction: {total} - {letters_only} = {by_subtraction}")
print(f"at least one digit, by adding the six exact-count terms: {by_terms}")
print(f"exactly 1, 2, 3, 4, 5, 6 digits: {terms}")
print(f"share of all passwords the rule allows: {share:.2f}%")
print(f"toy question, 3 letters and 2 digits in strings of 4, every string listed: {toy_listed}")
print(f"the same toy counts from the closed forms: {toy_closed}")
print(f"every starting eleven from 20 players: C(20,11) = {squad_closed[0]}")
print(f"elevens with no goalkeeper, 11 from the other 18: C(18,11) = {squad_closed[1]}")
print(f"at least one goalkeeper, by subtraction: {squad_closed[0]} - {squad_closed[1]} = {squad_closed[2]}")
print(f"the same three counts by listing all {1 << SQUAD} subsets: {squad_listed}")
print(f"mistake 1, a digit placed first then the rest free: 6 x 10 x 36^5 = {digit_first}, over the {total} that exist")
print(f"mistake 2, complement read as exactly one digit: {total} - {terms[0]} = {total - terms[0]}")
print(f"mistake 3, a keeper placed first then ten from 19: 2 x C(19,10) = {keeper_first}, over the {squad_closed[0]} that exist")
assert by_subtraction == by_terms                  # subtraction against the six separate terms
assert toy_listed == toy_closed                    # 625 strings listed against the closed forms
assert squad_listed == squad_closed                # 1,048,576 subsets listed against C(n, k)
assert digit_first > total and keeper_first > squad_closed[0]    # both overcounts break their ceilings
print("ALL CHECKS PASS")
