# Homomorphisms and isomorphisms -- the check behind the card.  Nothing is
# imported.  The 24-hour clock is sent onto the 12-hour clock by f(x) = x mod 12,
# and the tile's four quarter turns are matched against the 4-clock.  Every
# number quoted on the card is printed here, and each answer is reached twice.
DAY, HALF, QUARTERS = 24, 12, 4
QUARTER = (1, 2, 3, 0)   # a quarter turn sends corners 0 1 2 3 here; compose it for the rest

def add_then_send(a, b): return ((a + b) % DAY) % HALF        # road one
def send_then_add(a, b): return (a % HALF + b % HALF) % HALF  # road two
def after(p, q): return tuple(p[q[i]] for i in range(QUARTERS))
def row(v): return "[" + ", ".join(str(x) for x in v) + "]"

def agreeing_pairs(g, ring):           # pairs a map gets right, out of all 576
    return sum(1 for a in range(DAY) for b in range(DAY)
               if g((a + b) % DAY) == (g(a) + g(b)) % ring)

def order(x, combine, home):           # how many copies of x it takes to get home
    y, n = x, 1
    while y != home:
        y, n = combine(y, x), n + 1
    return n

pairs = [(a, b) for a in range(DAY) for b in range(DAY)]
road_one = [add_then_send(a, b) for a, b in pairs]
road_two = [send_then_add(a, b) for a, b in pairs]
same = sum(1 for x, y in zip(road_one, road_two) if x == y)
kernel = [x for x in range(DAY) if x % HALF == 0]
shows_11 = [x for x in range(DAY) if x % HALF == 11]
reached = sorted({x % HALF for x in range(DAY)})
shifted = agreeing_pairs(lambda x: (x + 1) % HALF, HALF)
tenner = agreeing_pairs(lambda x: x % 10, 10)
turns = [tuple(range(QUARTERS)), QUARTER, after(QUARTER, QUARTER), after(after(QUARTER, QUARTER), QUARTER)]
by_turning = [[turns.index(after(turns[a], turns[b])) for b in range(QUARTERS)]
              for a in range(QUARTERS)]
by_clock = [[(a + b) % QUARTERS for b in range(QUARTERS)] for a in range(QUARTERS)]
cells = sum(1 for a in range(QUARTERS) for b in range(QUARTERS)
            if by_turning[a][b] == by_clock[a][b])
turn_orders = [order(t, after, turns[0]) for t in turns]
unit_orders = [order(u, lambda a, b: a * b % 8, 1) for u in (1, 3, 5, 7)]

print(f"the 24-hour clock onto the 12-hour clock, f(x) = x mod {HALF}")
print(f"add then send against send then add: {same} of {len(pairs)} pairs agree")
print(f"23 and 5: add first gives {add_then_send(23, 5)}, send first gives {send_then_add(23, 5)}")
print(f"kernel, the readings sent to 0: {row(kernel)}, size {len(kernel)}")
print(f"the two 24-hour readings that both show 11: {row(shows_11)}")
print(f"readings reached: {len(reached)}, and {DAY} / {len(kernel)} = {DAY // len(kernel)}")
print(f"wrong map, shift by one, x -> (x + 1) mod 12: {shifted} of {len(pairs)} pairs agree")
print(f"wrong map, onto a 10-clock, x -> x mod 10: {tenner} of {len(pairs)} pairs agree")
print("the tile's four turns, where corners 0 1 2 3 land: " + " ".join(row(p) for p in turns))
print("turn a then turn b, counted in quarter turns:      " + " ".join(row(r) for r in by_turning))
print("a + b on the 4-clock:                              " + " ".join(row(r) for r in by_clock))
print(f"the two tables agree in {cells} of 16 cells")
print(f"quarter turns to get home, the four turns: {row(turn_orders)}")
print(f"steps to get home, 1 3 5 7 multiplied mod 8: {row(unit_orders)}")
assert road_one == road_two and same == len(pairs)
assert kernel == [0, 12] and shows_11 == [11, 23] and len(reached) == DAY // len(kernel)
assert by_turning == by_clock and cells == 16
assert shifted == 0 and tenner == 300 and turn_orders == [1, 4, 2, 4] and unit_orders == [1, 2, 2, 2]
print("ALL CHECKS PASS")
