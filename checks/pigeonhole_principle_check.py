# Pigeonhole -- the check behind the card.  Nothing is imported.  Thirteen guests
# at a dinner and the twelve months, then a sentence of 27 words and the 26 letters.
# Route 1 walks the list and catches the repeat; route 2 counts what each hole holds.
MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
LETTERS = list("abcdefghijklmnopqrstuvwxyz")
BORN = ["March", "November", "July", "January", "September", "December", "April", "June", "February", "August", "May", "October", "July"]
SENTENCE = "Every guest brought a dish, and dinner ran late, so nobody counted the months until Priya asked, quietly, whether any two of us shared a birthday month"
INITIALS, LATER = [w[0].lower() for w in SENTENCE.split()], [MONTHS[(MONTHS.index(m) + 1) % 12] for m in BORN]
def first_repeat(labels):                       # route 1: stop at the first hole used twice
    seen = {}
    for i, lab in enumerate(labels):
        if seen.setdefault(lab, i) != i: return seen[lab] + 1, i + 1, lab
    return None
def loads(labels, holes): return [labels.count(h) for h in holes]      # route 2: how many landed in each hole
def show(what, labels, holes, one, many, holes_name):
    rep, n = first_repeat(labels), loads(labels, holes)
    assert (rep is None) == (max(n) <= 1)       # the two routes agree, every time
    print(f"{what}: {len(labels)} {many} into {len(holes)} {holes_name} -- {len(labels) - len(holes)} more than there are {holes_name}")
    print(f"  the forced repeat: {one} {rep[0]} and {one} {rep[1]}, both {rep[2]}" if rep else f"  no repeat forced, the fullest hole holds {max(n)}")
    print(f"  {holes_name} holding two or more: {sum(1 for x in n if x > 1)}, holding one: {n.count(1)}, holding none: {n.count(0)}")
    print(f"  with no sharing: {len(holes)} {holes_name} hold {len(holes)} {many} at most, and {len(labels)} {many} do not fit")
    return rep, n
rep_m, n_m = show("the dinner", BORN, MONTHS, "guest", "guests", "months")
rep_w, n_w = show("the sentence", INITIALS, LETTERS, "word", "words", "letters")
assert rep_m == (3, 13, "July") and n_m.count(1) == 11 and n_m.count(0) == 0
assert rep_w == (4, 6, "a") and max(n_w) == 5 and len(INITIALS) == 27
print(f"breaks: the first 12 guests into 12 months -- no repeat forced, fullest month holds {max(loads(BORN[:12], MONTHS))}")
print(f"breaks: every guest born a month later -- the repeat moves to {first_repeat(LATER)[2]}, still {max(loads(LATER, MONTHS))} guests")
assert first_repeat(BORN[:12]) is None and max(loads(BORN[:12], MONTHS)) == 1 and first_repeat(LATER)[2] == "August"
print("ALL CHECKS PASS")
