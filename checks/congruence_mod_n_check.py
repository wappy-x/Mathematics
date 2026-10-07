# Congruence -- the check behind the card.  Nothing is imported.  A 12-hour
# clock at 9 am, 100 hours later.  Two roads to the same hour: take the whole
# turns out by dividing, or walk the face one tick at a time.
def leftover(a, n):        # a = n x whole turns + leftover, with 0 <= leftover < n
    turns = 0
    while a - turns * n < 0: turns -= 1
    while a - turns * n >= n: turns += 1
    return a - turns * n
def walk(start, steps, n):                     # the long way round, tick by tick
    hand = start
    for _ in range(steps): hand = hand + 1 if hand + 1 < n else 0
    return hand
def row(name, value): print(f"{name:<40}{value:>4}")
row("100 = 8 x 12 + 4, leftover on 12", leftover(100, 12))
row("100 = 4 x 24 + 4, leftover on 24", leftover(100, 24))
row("9 + 100, counted straight out", 9 + 100)
row("the face reads, by dividing", leftover(109, 12))
row("the face reads, by walking the ticks", walk(9, 100, 12))
row("109 - 1 = 9 whole turns of 12", 109 - 1)
row("3 hours before midnight: -3 leaves", leftover(-3, 12))
row("9 - (-3), exactly one turn of 12", 9 - (-3))
row("109 - 2 = 107, whose leftover is not 0", leftover(107, 12))
print(f"{'hour count':<20}" + "".join(f"{a:>4}" for a in range(96, 111)))
print(f"{'each one leaves':<20}" + "".join(f"{leftover(a, 12):>4}" for a in range(96, 111)))
assert leftover(100, 12) == 4 and leftover(100, 24) == 4 and 9 + 100 == 109
assert walk(9, 100, 12) == leftover(109, 12) == 1 and (109 - 1) % 12 == 0
assert leftover(-3, 12) == 9 and 9 - (-3) == 12 and leftover(107, 12) == 11
assert [leftover(a, 12) for a in range(96, 111)] == [0,1,2,3,4,5,6,7,8,9,10,11,0,1,2]
assert all(((a-b) % 12 == 0) == (leftover(a,12) == leftover(b,12)) for a in range(-40,41) for b in range(-40,41))
print("ALL CHECKS PASS")
