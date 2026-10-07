# Subsets and the power set -- the check behind the card.  Nothing is imported.
# Three toppings are on offer, so every pizza is a subset of that list.  Build
# the eight pizzas one topping at a time, then count them a second way.
TOPPINGS = ["mushroom", "olive", "chilli"]

def build(toppings):                     # every subset, one topping at a time
    out = [[]]                           # start with the plain pizza, no toppings
    for t in toppings:
        out = out + [p + [t] for p in out]    # each new topping doubles the menu
    return out

def name(pizza): return ", ".join(pizza) if pizza else "plain"
def row(label, value): print(f"{label:<34}{value:>5}")

pizzas = build(TOPPINGS)
sizes = [len(build((TOPPINGS + ["anchovy"])[:k])) for k in range(5)]
free = [p for p in pizzas if "chilli" not in p]
nonempty = [p for p in pizzas if p]
row("toppings on offer", len(TOPPINGS))
row("pizzas possible, 2 x 2 x 2", len(pizzas))
print("the eight pizzas: " + " | ".join(name(p) for p in pizzas))
print(f"{'menu size after each topping':<29}" + "".join(f"{v:>5}" for v in sizes))
row("chilli-free pizzas", len(free))
row("pizzas with at least one topping", len(nonempty))
print(f"the three mistakes come out at {len(nonempty)}, {len(TOPPINGS)} and {2 + 2 + 2}")
assert sorted(map(name, free)) == ["mushroom", "mushroom, olive", "olive", "plain"]
assert len(pizzas) == 2 * 2 * 2 and len(free) == 2 * 2 and len(nonempty) == 7
assert sizes == [1, 2, 4, 8, 16]
print("ALL CHECKS PASS")
