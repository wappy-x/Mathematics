# Choosing a proof strategy -- the check behind the card.  Nothing is imported.
# The mechanic's sheet, on three claims: every whole number is even or odd;
# some number leaves any sum alone; only one number does.  Whole numbers 0 to 40.
NUMBERS = list(range(41))
def rule(n):                    # even or odd by dividing: 7 = 2 x 3 + 1, odd
    return "even" if n % 2 == 0 else "odd"
def flip(n):                    # the induction route: even at 0, flip at every step
    label = "even"
    for _ in range(n):
        label = "odd" if label == "even" else "even"
    return label
def row(claim, shape, move, verdict):
    print(f"{claim:<34}{shape:<12}{move:<16}{verdict}")
by_rule, by_flip = [rule(n) for n in NUMBERS], [flip(n) for n in NUMBERS]
agree = sum(1 for a, b in zip(by_rule, by_flip) if a == b)
works = [z for z in NUMBERS if all(z + n == n for n in NUMBERS)]   # produce one, and count them
row("claim", "shape", "move", "verdict")
row("every whole number is even or odd", "for every", "induction", f"holds 0 to {NUMBERS[-1]}")
row("some number leaves any sum alone", "there is", "produce one", f"{works[0]} works")
row("only one such number does", "exactly one", "two, then equal", f"{len(works)} of {len(NUMBERS)} candidates")
print(f"7 = 2 x 3 + 1, {rule(7)}; 8 = 2 x 4, {rule(8)}; 0 = 2 x 0, {rule(0)}")
print(f"the dividing rule and the flipping route agree on {agree} numbers")
print(f"the witness: 0 + 7 = {0 + 7}, 0 + 23 = {0 + 23}; a wrong one: 1 + 7 = {1 + 7}, not 7")
print(f"the search found {len(works)} candidate; the proof, not the code, rules out a second")
assert by_rule == by_flip and agree == 41 and by_rule[7] == "odd"
assert works == [0] and 1 + 7 == 8 and 0 + 7 == 7
assert 7 == 2 * 3 + 1 and 8 == 2 * 4 and 2 * (3 + 1) == 8
print("ALL CHECKS PASS")
