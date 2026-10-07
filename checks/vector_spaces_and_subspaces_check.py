# Vector spaces and subspaces -- the check behind the card.  Nothing is imported.
# A recipe is three numbers: grams of flour, grams of sugar, grams of butter.
# Adding two recipes adds slot by slot; scaling multiplies every slot.  Road one
# walks the eight rules and the three subspace tests on named recipes.  Road two
# reaches the same two verdicts another way: one slot of a mix a u + b v is
# a times that slot of u plus b times that slot of v, so a set pinned at
# "this slot equals c" closes up when c is 0 and comes apart when it is not.
def add(u, v):   return tuple(x + y for x, y in zip(u, v))
def scale(a, u): return tuple(a * x for x in u)
def show(u):     return "(" + ", ".join(str(x) for x in u) + ")"
def line(name, text): print(f"{name:<22}{text}")

SHORT, SPONGE, OAT, ZERO = (300, 100, 200), (200, 200, 100), (150, 50, 100), (0, 0, 0)
a, b = 2, -3
F1, F2 = (300, 0, 200), (100, 0, 50)        # sugar-free: the sugar slot is 0
G1, G2 = (200, 100, 50), (200, 50, 150)     # exactly 200 g of flour

print("recipes are (flour, sugar, butter) in grams")
line("shortbread", show(SHORT))
line("sponge", show(SPONGE))
line("oat biscuit", show(OAT))
line("shortbread + sponge", show(add(SHORT, SPONGE)))
line("2 x shortbread", show(scale(2, SHORT)))
line("(2 + -3) x shortbread", show(scale(a + b, SHORT)))

rules = [add(SHORT, SPONGE) == add(SPONGE, SHORT),                                 # order
         add(add(SHORT, SPONGE), OAT) == add(SHORT, add(SPONGE, OAT)),             # grouping
         add(SHORT, ZERO) == SHORT,                                                # a zero
         add(SHORT, scale(-1, SHORT)) == ZERO,                                     # an opposite
         scale(a, add(SHORT, SPONGE)) == add(scale(a, SHORT), scale(a, SPONGE)),   # spread over recipes
         scale(a + b, SHORT) == add(scale(a, SHORT), scale(b, SHORT)),             # spread over numbers
         scale(a, scale(b, SHORT)) == scale(a * b, SHORT),                         # scale twice, or once
         scale(1, SHORT) == SHORT]                                                 # scaling by 1
print(f"all eight rules on these three, a = {a}, b = {b}: {'OK' if all(rules) else 'FAILED'}")

line("sugar-free, added", f"{show(add(F1, F2))}   sugar {add(F1, F2)[1]}")
line("sugar-free, tripled", f"{show(scale(3, F1))}   sugar {scale(3, F1)[1]}")
line("sugar-free, zero", f"{show(ZERO)}   sugar {ZERO[1]}")
line("200 g flour, added", f"{show(add(G1, G2))}   flour {add(G1, G2)[0]}")
line("200 g flour, tripled", f"{show(scale(3, G1))}   flour {scale(3, G1)[0]}")
line("200 g flour, zero", f"{show(ZERO)}   flour {ZERO[0]}")
line("grams kept positive", f"the opposite of shortbread is {show(scale(-1, SHORT))}")

sugar_mix = add(scale(a, F1), scale(b, F2))[1]        # road two: one slot of a mix
flour_mix = add(scale(a, G1), scale(b, G2))[0]
print(f"second road: the slot of the mix {a} u + {b} v, worked from the two slots alone")
line("sugar of the mix", f"{sugar_mix} = {a} x {F1[1]} + {b} x {F2[1]}   still sugar-free")
line("flour of the mix", f"{flour_mix} = {a} x {G1[0]} + {b} x {G2[0]}   not 200")

assert add(SHORT, SPONGE) == (500, 300, 300) and scale(2, SHORT) == (600, 200, 400)
assert all(rules) and scale(a + b, SHORT) == (-300, -100, -200)
assert add(F1, F2)[1] == 0 and scale(3, F1)[1] == 0 and sugar_mix == 0
assert add(G1, G2)[0] == 400 and scale(3, G1)[0] == 600 and flour_mix == -200 and ZERO[0] != 200
print("ALL CHECKS PASS")
