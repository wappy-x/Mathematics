# Countable sets -- the check behind the card.  Nothing is imported.  The hotel desk
# queues the integers 0, 1, -1, 2, -2, ..., then the positive fractions off the grid of
# top over bottom, walked along the diagonals, repeats skipped.  Rooms found twice over.
def hcf(a, b):                      # highest common factor, by repeated remainders
    while b: a, b = b, a % b
    return a
def guests(rooms):                  # room 1 holds 0, even rooms go up, odd rooms down
    return [0 if r == 1 else r // 2 if r % 2 == 0 else (1 - r) // 2 for r in range(1, rooms + 1)]
def room_of(k):                     # the other way round: the room a given integer gets
    return 1 if k == 0 else 2 * k if k > 0 else 1 - 2 * k
def queue(rooms, skip=True):        # 0 first, then the diagonals, one height at a time
    q = ["0"]
    for height in range(2, rooms + 2):
        q += [f"{t}/{height - t}" for t in range(1, height) if not skip or hcf(t, height - t) == 1]
    return q[:rooms]
def room_by_counting(top, bottom):  # second road: count what the earlier diagonals held
    earlier = sum(1 for h in range(2, top + bottom) for t in range(1, h) if hcf(t, h - t) == 1)
    return 1 + earlier + sum(1 for t in range(1, top + 1) if hcf(t, top + bottom - t) == 1)
ints, fracs, kept, nozero, long = guests(9), queue(10), queue(7, False), queue(4)[1:], queue(60)
print("integer queue, rooms 1 to 9    " + " ".join(str(k) for k in ints))
print("those integers, read back      " + " ".join(str(room_of(k)) for k in ints))
print("grid rows 1 to 3               " + " | ".join(" ".join(f"{t}/{b}" for b in (1, 2, 3)) for t in (1, 2, 3)))
print("fraction queue, rooms 1 to 10  " + " ".join(fracs))
print(f"1/2 is in room {fracs.index('1/2') + 1} and 2/1 in room {fracs.index('2/1') + 1}, both agreed by counting the diagonals")
print(f"repeats left in, 2/2 takes room {kept.index('2/2') + 1}; the 0 dropped, 1/2 takes room {nozero.index('1/2') + 1} and 2/1 room {nozero.index('2/1') + 1}")
print(f"the first 60 rooms hold {len(set(long))} different guests")
assert ints == [0, 1, -1, 2, -2, 3, -3, 4, -4] and [room_of(k) for k in ints] == list(range(1, 10))
assert fracs == ["0", "1/1", "1/2", "2/1", "1/3", "3/1", "1/4", "2/3", "3/2", "4/1"] and kept[5] == "2/2"
assert len(set(long)) == 60 and all(room_by_counting(int(f.split("/")[0]), int(f.split("/")[1])) == i + 1 for i, f in enumerate(long) if i)
print("ALL CHECKS PASS")
