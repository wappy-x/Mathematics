# Fractions -- the check behind the card.  Nothing is imported.  A pizza cut into
# 8 slices for three people, and a recipe wanting 3/4 cup of flour when you make
# half a batch.  Second road: the same story counted in whole eighths of a pizza.
def hcf(a, b):                          # the biggest whole number dividing both
    return a if b == 0 else hcf(b, a % b)
def tidy(t, b):                         # 2/8 -> 1/4
    return (t // hcf(t, b), b // hcf(t, b))
def add(x, y):                          # a common bottom, add the tops, then tidy
    return tidy(x[0] * y[1] + y[0] * x[1], x[1] * y[1])
def times(x, y):                        # tops times tops, bottoms times bottoms
    return tidy(x[0] * y[0], x[1] * y[1])
def row(name, f):
    print(f"{name:<34}{f[0]:>3}/{f[1]}")
yours, friend, share = (3, 8), (1, 4), tidy(8, 3)
both, flour = add(yours, friend), times((1, 2), (3, 4))
left, scoops = add((1, 1), (-both[0], both[1])), times(flour, (8, 1))  # take away: add a minus top
row(f"you ate {yours[0]} of the 8 slices", yours)
row("your friend ate a quarter", (2, 8))
row("together", both)
row("left in the box", left)
row("half a batch of 3/4 cup, in cups", flour)
row("that flour in 1/8-cup scoops", scoops)
row("a fair share of the 8 slices", share)
print(f"a fair share is {share[0] // share[1]} slices and {share[0] % share[1]}/{share[1]} of a slice")
m1, m2 = tidy(3 + 1, 8 + 4), times(yours, (1, 8))
print(f"the three mistakes come out at {m1[0]}/{m1[1]}, {m2[0]}/{m2[1]} and {8 // 3}")
assert both == tidy(3 + 2, 8) and left == tidy(8 - 5, 8)
assert flour == tidy(6 // 2, 8) and share[0] == 2 * share[1] + 2
assert scoops == (3, 1) and times(scoops, (1, 8)) == flour
print("ALL CHECKS PASS")
