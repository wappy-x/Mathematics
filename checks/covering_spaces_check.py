# Covering spaces -- the check behind the card.  Standard library only.
# The plan of a spiral car park is the circle; the ramp above it is the line.
# Positions are whole degrees: a plan angle is taken mod 360, a ramp position
# is not.  One circuit = 360 degrees = one floor, 3 m up; 24 bays a circuit.
from fractions import Fraction
from math import atan2, cos, sin, radians, degrees

READ = [0, 100, 200, 300, 40, 140, 240, 340, 80, 180]  # plan angle every 30 s

def step(a, b):            # road one: the short way from a to b, in (-180, 180]
    return (b - a + 179) % 360 - 179

def lift(angles, start=0):  # follow the readings up the ramp, one step at a time
    out = [start]
    for a, b in zip(angles, angles[1:]):
        out.append(out[-1] + step(a, b))
    return out

def lift_by_search(angles, start=0):  # road two: search the stack above each reading
    out = [start]
    for b in angles[1:]:
        near = [b + 360 * m for m in range(-20, 21) if abs(b + 360 * m - out[-1]) < 180]
        assert len(near) == 1                        # one copy in reach: the lift is unique
        out.append(near[0])
    return out

def turns_by_arrows(angles):  # road three: add the turning angle between plan arrows
    tot = 0.0
    for a, b in zip(angles, angles[1:]):
        x1, y1, x2, y2 = cos(radians(a)), sin(radians(a)), cos(radians(b)), sin(radians(b))
        tot += degrees(atan2(x1 * y2 - y1 * x2, x1 * x2 + y1 * y2))
    return tot / 360

def floor_of(pos):
    return pos // 360

def loop(k, per_turn=12):  # z -> z^k on the plan: k turns, 30 degrees a sample
    return [(30 * k * j) % 360 for j in range(per_turn + 1)]

def lift_mod(angles, n):   # lift into the n-fold cover: ramp positions kept mod 360 n
    return [p % (360 * n) for p in lift(angles)]

up = lift(READ)
end = up[-1]
s = Fraction(end, 360)
print("readings (deg):", READ)
print("lift, step by step (deg):", up)
cands = [80 + 360 * m for m in range(4)]                  # the stack over 80 deg, floors 0 to 3
near = [c for c in cands if abs(c - up[7]) < 180]
print(f"step 340 -> 80 from ramp {up[7]}: candidates {cands}; within 180 of {up[7]}: {near}")
print(f"end of lift: {end} deg = {s} turns; floor {floor_of(end)}, bay {end % 360 // 15}, height {float(s * 3)} m")
print("same lift by searching the stack over each reading:", "yes" if lift_by_search(READ) == up else "no")
print(f"turns by adding plan-arrow angles: {turns_by_arrows(READ):.6f}")
print("lift started on floor 1 = first lift + 360 everywhere:",
      "yes" if [a - b for a, b in zip(lift(READ, 360), up)] == [360] * len(up) else "no")
back = READ + READ[-2::-1]
print(f"drive up and back down: lift ends at {lift(back)[-1]} deg, floor {floor_of(lift(back)[-1])}")
lead = [(90 * j) % 360 for j in range(13)] + [(90 * j) % 360 for j in range(11, -1, -1)]
print(f"lead wound 3 times, then unwound: lift ends at {lift(lead)[-1]} deg")
two_then_back = loop(2) + loop(-1)[1:]
print(f"loop of 2 turns then loop of -1: lift ends at {lift(two_then_back)[-1] // 360} turn")
print(f"identity map, a ramp point above each plan spot: lift of one circuit ends at "
      f"{lift(loop(1))[-1]} deg, not 0, so no such rule")
print("lifting criterion, maps z^k through the n-fold cover: lift closes?")
table = {}
for n in range(1, 5):
    row = []
    for k in range(-3, 4):
        closes = lift_mod(loop(k), n)[-1] == 0
        in_sub = set(range(k * -10, k * 10 + 1, k) if k else [0]) <= set(range(-120 * n, 120 * n + 1, n))
        table[(n, k)] = (closes, in_sub)
        row.append("Y" if closes else ".")
    print(f"  n = {n}, k = -3..3: {' '.join(row)}")
agree = sum(1 for v in table.values() if v[0] == v[1])
print(f"criterion k Z inside n Z agrees with the lift: {agree} of {len(table)} cases")
sheets = [lift_mod(loop(k), 3)[-1] // 360 for k in range(6)]
print("loop of k turns lifted into the 3-fold cover ends on sheet:", sheets)
fibre = sorted({(0 + 360 * j) % (360 * 3) for j in range(-9, 10)})
cosets = sorted({tuple(x for x in range(-9, 10) if (x - g) % 3 == 0) for g in range(-9, 10)})
print(f"3-fold cover: fibre over 0 = {fibre}; cosets of 3Z in Z: {len(cosets)}")
decks = [m for m in range(0, 721) if all((x + m) % 360 == x % 360 for x in range(-720, 721))]
print("shifts m in 0..720 that keep every plan spot:", decks)
coarse = READ[::2]
bad = lift(coarse)[-1]
print(f"mistake, readings every 60 s {coarse}: lift ends at {bad} deg = {bad / 360:.2f} turns, floor {floor_of(bad)}")
print(f"mistake, last reading alone: {READ[-1]} deg, floor 0, bay {READ[-1] // 15}")
print(f"mistake, [0, 1) as the cover: 340 deg -> {Fraction(340, 360)} turn, 80 deg -> {Fraction(80, 360)} turn, "
      f"a jump of {Fraction(80 - 340, 360)} turn")
odd = lift_mod(loop(3), 2)[-1]
print(f"mistake, z^3 through the double cover: lift ends at {odd} deg, sheet {odd // 360}, not closed")
stack = ", ".join(f"(50, {290 - 75 * (m + 0.5):.1f})" for m in range(3))
print(f"figure, start (370, 290); end (50, {290 - 75 * float(s):.1f}); stack over 180 deg: {stack}; plan spot (50, 350)")
assert lift_by_search(READ) == up and end == 900                      # two roads, one lift
assert abs(turns_by_arrows(READ) - float(s)) < 1e-9                    # third road
assert lift(back)[-1] == 0 and lift(lead)[-1] == 0 and lift(two_then_back)[-1] == 360
assert agree == len(table) and lift(loop(1))[-1] == 360                # criterion vs lift
assert sheets == [k % 3 for k in range(6)] and len(fibre) == len(cosets)  # sheets match cosets
assert decks == [0, 360, 720]                                         # shifts by whole floors only
assert (floor_of(end), floor_of(bad), bad, odd) == (2, -2, -640, 360)  # hand values
assert near == [up[8]]                                                # the one copy in reach
print("ALL CHECKS PASS")
