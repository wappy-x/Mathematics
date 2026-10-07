# Roots -- the check behind the card.  Nothing is imported.  A square bed that
# must cover 50 square metres, and a cube tank that must hold 8,000 litres.
# Each root is found by dividing and averaging, then multiplied back.
def sqroot(a, guess):            # divide and average: guess, a/guess, meet in the middle
    out = []
    for _ in range(4):          # a fourth round, to show it no longer moves
        guess = (guess + a / guess) / 2
        out.append(guess)
    return out
def cuberoot(a):                 # same idea, weighted: two parts old guess, one part a/(guess x guess)
    x = a
    for _ in range(60):
        x = (2 * x + a / (x * x)) / 3
    return x
steps = sqroot(50.0, 7.0)
bed, tank = steps[2], cuberoot(8.0)
litre = 20.0 / 10                # no root: 20 litre cubes to an edge, a tenth of a metre each
face = tank * tank               # 8 to the 2/3: cube root first, then multiplied by itself
print(f"{'squares of sides 4 to 8 metres':<36}" + "".join(f"{s * s:>5.0f}" for s in [4, 5, 6, 7, 8]))
for name, v in [("guess 7, divide and average", steps[0]), ("round two, closer", steps[1]),
                ("round three, and it settles", bed), ("that side squared, back to 50", bed * bed),
                ("the minus twin", -bed), ("the minus twin squared", (-bed) * (-bed)),
                ("tank side, cube root of 8", tank), ("tank side the litre way, 20 dm", litre),
                ("one face of the tank, 8 to the 2/3", face)]:
    print(f"{name:<36}{v:>18.12f}")
print(f"mistakes: 25 metres a side covers {25 * 25}; 8,000 cubic metres gives a side of {cuberoot(8000.0):.0f}")
assert abs(bed * bed - 50.0) < 1e-9 and abs((-bed) * (-bed) - 50.0) < 1e-9 and steps[3] == bed
assert abs(tank - litre) < 1e-9 and abs(tank * tank * tank - 8.0) < 1e-9 and 20 * 20 * 20 == 8000
assert abs(face - 4.0) < 1e-9 and abs(steps[0] - 7.071428571428571) < 1e-15
print("ALL CHECKS PASS")
