# Absolute value -- the check behind the card.  Nothing is imported.  One
# street: the bus stop is house number 0, the bakery is 40, the chemist is 65,
# and the laundrette is -30, on the far side of the stop.
def size(n):                          # |n|: how far n is from 0, sign dropped
    return n if n >= 0 else -n

def gap(x, y): return size(x - y)     # |x - y|: the distance from x to y

def paced(x, y): return sum(1 for _ in range(min(x, y), max(x, y)))   # counted house by house

def row(name, value): print(f"{name:<38}{value:>5}")

stop, bakery, chemist, laundrette = 0, 40, 65, -30
row("|40|   bus stop to the bakery", size(bakery))
row("|65|   bus stop to the chemist", size(chemist))
row("|-30|  bus stop to the laundrette", size(laundrette))
row("|40 - 65|   bakery to chemist", gap(bakery, chemist))
row("|65 - 40|   chemist to bakery", gap(chemist, bakery))
row("|40 - (-30)|  bakery to laundrette", gap(bakery, laundrette))
counted = [paced(bakery, chemist), paced(chemist, bakery), paced(bakery, laundrette)]
print("the same three gaps, counted a step at a time  " + " ".join(str(c) for c in counted))
print("distance from the stop at -30, 0, 40, 65:   " + " ".join(str(size(n)) for n in (laundrette, stop, bakery, chemist)))
out, back, there = 40, 25, -70
print(f"one trip out: |40 + 25| = {size(out + back)} and |40| + |25| = {size(out) + size(back)}")
print(f"doubling back: |40 + (-70)| = {size(out + there)} but |40| + |-70| = {size(out) + size(there)}")
print(f"the three mistakes come out at {bakery - chemist}, {size(bakery - 30)} and {size(out) + size(there)}")
assert size(bakery) == 40 and size(laundrette) == 30 and size(stop) == 0
assert counted == [25, 25, 70] and gap(bakery, chemist) == 25 and gap(bakery, laundrette) == 70
assert size(out + there) == 30 and size(out) + size(there) == 110
print("ALL CHECKS PASS")
