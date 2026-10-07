# Same size means pairable -- the check behind the card.  Nothing is imported.
# The hotel has a room for every counting number and every room is full; the
# first 8 rooms are shown.  Two pairings, each read forwards and then backwards,
# and a finite hotel of 8 rooms that manages neither.
N = 8
guests = list(range(1, N + 1))
shift = [n + 1 for n in guests]                            # a new guest: everyone moves up one
even = [2 * n for n in guests]                             # every guest into an even room
back = [r // 2 for r in even]                              # the same pairing, read backwards
listed = [r for r in range(1, 2 * N + 1) if r % 2 == 0]    # the even rooms, listed straight
small = list(range(1, N + 1))                              # the finite hotel: 8 rooms and no more
housed = len([n for n in small if n + 1 in small])
small_even = [r for r in small if r % 2 == 0]
def row(name, values):
    print(f"{name}: " + ", ".join(str(v) for v in values))
row("the hotel, rooms 1 to 8 shown, every room full", guests)
row("a new guest: everyone moves up one, room n to room n+1", shift)
print(f"room 1 is now empty: {len(set(shift))} guests in {len(set(shift))} different rooms, none lost")
row("every guest into an even room, room n to room 2n", even)
row("the same pairing backwards, each even room halved", back)
row("the even rooms up to 16, listed straight", listed)
print(f"that is {len(listed)} even rooms for {len(guests)} guests, nobody doubled up, no even room left empty")
print(f"the endless hotel has room {N + 1}; the finite one stops at {N} -- same {N} guests, different answer")
print(f"finite hotel of 8 rooms: moving up one houses {housed} of {N}, {N - housed} guest left outside")
print(f"finite hotel of 8 rooms: the even rooms are {', '.join(str(r) for r in small_even)} -- {len(small_even)} rooms for {N} guests, {N - len(small_even)} left outside")
assert len(set(shift)) == N and 1 not in shift and sorted(shift) == list(range(2, N + 2))
assert back == guests and even == listed and len(set(even)) == N
assert housed == 7 and small_even == [2, 4, 6, 8] and len(small_even) == 4
print("ALL CHECKS PASS")
