# The axiom of choice -- the check behind the card.  Nothing is imported.  Ten
# lost-property boxes, two socks in each.  Count every full pick -- one sock out
# of every box, all at once -- twice: by multiplying, and by building them all.
SOCKS = ("left", "right")
def full_picks(boxes):          # every way to take one thing out of every box
    picks = [()]
    for box in boxes:
        picks = [p + (s,) for p in picks for s in box]
    return picks

def row(name, value): print(f"{name:<44}{value:>5}")

ten, three = [SOCKS] * 10, [SOCKS] * 3
gap = [SOCKS] * 9 + [()]                       # one box with nothing in it
picks = full_picks(ten)
shoe_rule = tuple("left" for box in ten)       # "take the left one", written out
mult = 1
for box in ten: mult = mult * len(box)         # the second road: 2 x 2 x ... x 2
row("boxes of socks", len(ten))
row("socks in each box", len(SOCKS))
row("full picks, by multiplying", mult)
row("full picks, by building every one", len(picks))
row("full picks with only three boxes", len(full_picks(three)))
row("full picks when one box is empty", len(full_picks(gap)))
row("picks the shoe rule names", picks.count(shoe_rule))
row("different picks, ten socks in each", len({p for p in picks if len(p) == len(ten)}))
assert mult == 1024 and len(picks) == 1024 == len(set(picks))
assert len(full_picks(three)) == 8 and len(full_picks(gap)) == 0
assert picks.count(shoe_rule) == 1 and shoe_rule in picks
print("ALL CHECKS PASS")
