# Negating a quantifier -- the check behind the card.  Nothing is imported.
# Five bags at the gate: weight in kg, and whether each one went in the cabin.
# Road 1 reads every/some straight off the list; road 2 counts.  They agree.
KG = [4, 5, 6, 9, 11]
CABIN = [True, True, False, False, False]
LIGHT = [i for i in range(len(KG)) if KG[i] < 7]     # the bags the sign is about
BROKE = [i for i in LIGHT if not CABIN[i]]           # the ones that break the sign
tf = lambda b: "T" if b else "F"
def row(name, b): print(f"{name:<37}{tf(b):>2}")
every_in, some_out = all(CABIN[i] for i in LIGHT), any(not CABIN[i] for i in LIGHT)
some_big, every_small = any(w > 20 for w in KG), all(w <= 20 for w in KG)
every_out = all(not CABIN[i] for i in LIGHT)         # the wreck: not-every read as every-not
print(f"{'bags at the gate, in kg':<24}" + "".join(f"{w:>3}" for w in KG))
print(f"{'did it go in the cabin?':<24}" + "".join(f"{'Y' if c else 'N':>3}" for c in CABIN))
print(f"bags under 7 kg {len(LIGHT)}: in the cabin {len(LIGHT) - len(BROKE)}, refused {len(BROKE)}")
row("every bag under 7 kg in the cabin?", every_in)
row("some bag under 7 kg refused?", some_out)
row("some bag over 20 kg?", some_big)
row("every bag 20 kg or under?", every_small)
row("the wreck, every under-7 bag refused", every_out)
print(f"counterexample: bag {BROKE[0]+1} at {KG[BROKE[0]]} kg; 1 bag kills 'every', {len(KG)} to kill 'some'" if BROKE else "no counterexample: the sign stands")
n = 0
for p in [(a, b, c) for a in (0, 1) for b in (0, 1) for c in (0, 1)]:
    assert (not all(p)) == any(not q for q in p) and (not any(p)) == all(not q for q in p)
    n += 1
print(f"all {n} yes/no patterns for the light bags: both swaps hold")
assert len(LIGHT) == 3 and len(BROKE) == 1 and KG[BROKE[0]] == 6
assert every_in == (len(BROKE) == 0) and some_out == (len(BROKE) >= 1)   # road 2: counts
assert every_in is False and some_out is True and every_out is False and some_big is False
print("ALL CHECKS PASS")
