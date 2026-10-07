# Coprime numbers -- the check behind the card.  Nothing is imported.  Two
# meshing gears, 15 teeth and 28 teeth, then 15 and 27 for contrast.  Euclid
# finds the shared factor; a whole-number mix of the two is the second road.
def gcd(a, b):                       # Euclid: keep the remainder, repeat
    while b:
        a, b = b, a % b
    return a
def meets(small, big):               # slots of the big gear that tooth 0 meets
    seen, step = [0], small
    while step % big:
        seen.append(step % big)
        step += small
    return seen
def row(name, value):
    print(f"{name:<42}{value:>7}")
for small, big in ((15, 28), (15, 27)):
    g = gcd(small, big)
    met = meets(small, big)
    row(f"gcd of {small} and {big}, by Euclid", g)
    row(f"slots of the {big}-gear that tooth 0 meets", len(met))
    row(f"tooth pairs used, of the {small * big} there are", small * len(met))
    row(f"{small}/{big} in lowest terms", f"{small // g}/{big // g}")
row("the mix 28 x 7 - 15 x 13", 28 * 7 - 15 * 13)
row("the mix 27 x 4 - 15 x 7, the smallest", 27 * 4 - 15 * 7)
print("slots of the 27-gear tooth 0 meets: " + " ".join(str(t) for t in meets(15, 27)))
assert gcd(15, 28) == 1 and 28 * 7 - 15 * 13 == 1 and meets(15, 28)[:4] == [0, 15, 2, 17]
assert len(meets(15, 28)) == 28 and 15 * len(meets(15, 28)) == 15 * 28
assert gcd(15, 27) == 3 and len(meets(15, 27)) == 27 // 3 and 15 * len(meets(15, 27)) == 135
print("ALL CHECKS PASS")
