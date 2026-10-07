# Functions -- the check behind the card.  Nothing is imported.  A vending machine: 6 buttons, 5 snacks stocked.  The wiring is read forwards, button by button, then backwards, snack by snack, and the two readings must agree.
BUTTONS = ["A1", "A2", "A3", "B1", "B2", "B3"]
SNACKS = ["crisps", "chocolate", "flapjack", "gum", "mints"]
WIRING = [("A1", "crisps"), ("A2", "crisps"), ("A3", "chocolate"), ("B1", "flapjack"), ("B2", "gum"), ("B3", "gum")]
SOLD_OUT = ["chocolate", "mints"]
def out(pairs, b):                       # forwards: the snacks this button hands out
    return [s for x, s in pairs if x == b]
def preimage(pairs, target):             # backwards: every button whose snack is in target
    return [b for b in BUTTONS if any(s in target for s in out(pairs, b))]
def image(pairs, buttons):               # forwards: every snack those buttons hand out
    return [s for s in SNACKS if any(s in out(pairs, b) for b in buttons)]
counts, answered = [len(preimage(WIRING, [s])) for s in SNACKS], [len(out(WIRING, b)) for b in BUTTONS]
rng, rng2 = image(WIRING, BUTTONS), [s for s in SNACKS if counts[SNACKS.index(s)] > 0]   # two routes to the range
indicator = [1 if s in SOLD_OUT else 0 for s in SNACKS]
jam, double = [p for p in WIRING if p[0] != "B3"], WIRING + [("A1", "chocolate")]         # B3 gives nothing; A1 drops two
print(f"buttons (domain): {', '.join(BUTTONS)} -- {len(BUTTONS)}")
print(f"snacks stocked (codomain): {', '.join(SNACKS)} -- {len(SNACKS)}")
print("wiring: " + ", ".join(f"{b} {s}" for b, s in WIRING))
print(f"every button answered exactly once: {'yes' if answered == [1] * len(BUTTONS) else 'no'}, {len(WIRING)} pairs for {len(BUTTONS)} buttons")
print(f"range (snacks actually given): {', '.join(rng)} -- {len(rng)}")
print("buttons per snack: " + ", ".join(f"{s} {n}" for s, n in zip(SNACKS, counts)) + f" -- {sum(counts)} in total")
print(f"preimage of crisps: {', '.join(preimage(WIRING, ['crisps']))} -- {len(preimage(WIRING, ['crisps']))} buttons; preimage of mints: none -- {len(preimage(WIRING, ['mints']))} buttons")
print(f"image of A1 and A3: {', '.join(image(WIRING, ['A1', 'A3']))} -- {len(image(WIRING, ['A1', 'A3']))} snacks")
print(f"sold out {{{', '.join(SOLD_OUT)}}}: indicator {' '.join(str(i) for i in indicator)}, sum {sum(indicator)}; buttons hitting it: {', '.join(preimage(WIRING, SOLD_OUT))} -- {len(preimage(WIRING, SOLD_OUT))}")
print(f"broken: a jammed B3 answers {len(jam)} of {len(BUTTONS)}; A1 dropping two answers {len(double)} pairs for {len(BUTTONS)} buttons")
assert answered == [1] * 6 and len(WIRING) == 6 and len(jam) == 5 and len(double) == 7
assert rng == ["crisps", "chocolate", "flapjack", "gum"] and rng == rng2 and len(rng) == 4 and "mints" not in rng
assert counts == [2, 1, 1, 2, 0] and sum(counts) == len(BUTTONS) and preimage(WIRING, ["crisps"]) == ["A1", "A2"] and preimage(WIRING, ["mints"]) == []
assert sum(indicator) == 2 and preimage(WIRING, SOLD_OUT) == ["A3"] and image(WIRING, ["A1", "A3"]) == ["crisps", "chocolate"] and preimage(double, ["chocolate"]) == ["A1", "A3"]
print("ALL CHECKS PASS")
