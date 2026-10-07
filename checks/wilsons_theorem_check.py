# Wilson's theorem -- the check behind the card.  Nothing is imported.  Six
# dancers, 1 to 6, on a 7-hour clock: each pairs off with the partner that
# undoes it, so the whole product reads 6, one short of a clock, which is -1.
CLOCK = 7
def product(top, clock):        # 1 x 2 x ... x top, whole clocks taken off
    out = 1
    for k in range(1, top + 1): out = (out * k) % clock
    return out

def row(name, value): print(f"{name:<48}{value:>5}")
partners = [b for a in range(1, CLOCK) for b in range(1, CLOCK) if (a * b) % CLOCK == 1]
alone = [a for a in range(1, CLOCK) if partners[a - 1] == a]          # 1 and 6
pairs = [(a, partners[a - 1]) for a in range(1, CLOCK) if a < partners[a - 1]]
plain = 1
for k in range(1, CLOCK): plain = plain * k                           # 720, in full
paired = 1
for a, b in pairs: paired = (paired * a * b) % CLOCK                  # each pair reads 1
for a in alone: paired = (paired * a) % CLOCK                         # 1 and 6 are left
row("1 x 2 x 3 x 4 x 5 x 6", plain)
row(f"{plain} = {plain // CLOCK} x {CLOCK} + {plain % CLOCK}, so the 7-clock reads", plain % CLOCK)
print("who undoes who, dancers 1 to 6:  " + " ".join(str(b) for b in partners))
print("the two pairs: " + ", ".join(f"{a} x {b} = {a * b} reads {a * b % CLOCK}" for a, b in pairs))
print(f"their own partner: 1 x 1 = 1 and 6 x 6 = {alone[1] * alone[1]}, both read 1")
row("the pairing road, 1 x 1 x 1 x 6, reads", paired)
row(f"that reading as a negative: {plain % CLOCK} - {CLOCK}", plain % CLOCK - CLOCK)
print(f"composites: an 8-clock (5040) reads {product(7, 8)}, a 4-clock (6) reads {product(3, 4)}")
assert plain == 720 and plain == 102 * CLOCK + 6
assert partners == [1, 4, 5, 2, 3, 6] and alone == [1, 6] and pairs == [(2, 4), (3, 5)]
assert paired == 6 and plain % CLOCK == 6 and product(7, 8) == 0 and product(3, 4) == 2
print("ALL CHECKS PASS")
