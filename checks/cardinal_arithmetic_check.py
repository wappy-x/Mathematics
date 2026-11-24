# Cardinal arithmetic -- the check behind the card.  Nothing is imported.  The full
# hotel takes a second hotel, then a coach of coaches; then the 0-1 lists outgrow it.
def coach(m, n): return 2 ** m * (2 * n + 1)          # coach m, seat n -> room
def back(r):                                           # room -> (coach, seat): halve out the 2s
    m = 0
    while r % 2 == 0: r, m = r // 2, m + 1
    return m, (r - 1) // 2
def place(m, n):                                       # the same pairs, queued shell by shell
    k = max(m, n); return k * k + (m if m < k else k + n) + 1
merged = sorted([2 * n for n in range(1, 501)] + [2 * n - 1 for n in range(1, 501)])
rooms = sorted(coach(m, n) for m in range(10) for n in range(500) if coach(m, n) <= 1000)
shells = sorted((max(m, n), m, n) for m in range(30) for n in range(30))   # second road: sort
places = [place(m, n) for k, m, n in shells]
print(f"merge: hotel A room 7 -> {2 * 7}, hotel B room 7 -> {2 * 7 - 1}; rooms 1-1000 filled once: {len(set(merged))}")
print(f"coaches: (0,0) -> room {coach(0, 0)}, (2,1) -> room {coach(2, 1)}, (3,4) -> room {coach(3, 4)}")
print(f"room 12 -> halve {back(12)[0]} times -> odd part {12 // 2 ** back(12)[0]} -> coach {back(12)[0]}, seat {back(12)[1]}")
print(f"coach rule: guests landing in rooms 1-1000: {len(rooms)}, different rooms: {len(set(rooms))}")
print(f"shells by max: pairs below 30: {len(places)}, places used once: {len(set(places))}, (2,1) at place {place(2, 1)}")
lists = [format(i, "03b") for i in range(2 ** 3)]
print(f"finite: 3 + 4 = {len(['a'] * 3 + ['b'] * 4)}, 3 x 4 = {len([(c, s) for c in range(3) for s in range(4)])}, 0-1 lists of length 3: {len(set(lists))}")
third, half_a, half_b = sum(2.0 ** -i for i in range(2, 60, 2)), 0.5, sum(2.0 ** -i for i in range(2, 60))
print(f"binary lists as points: 0.0101... = {third:.6f}; 0.1000... = {half_a:.6f}, 0.0111... = {half_b:.6f}")
plus, noodd = (len({f(m, n) for m in range(10) for n in range(10)}) for f in (lambda m, n: m + n + 1, lambda m, n: 2 ** m * (n + 1)))
left = len([r for r in range(1, 101) if r % 2 == 1])   # the even rooms emptied
print(f"mistakes: room m+n+1 puts 100 guests in {plus} rooms; room 2^m(n+1) in {noodd}; evens out leaves {left} of rooms 1-100 full")
assert merged == list(range(1, 1001)) and rooms == list(range(1, 1001))
assert all(coach(*back(r)) == r for r in range(1, 1001)) and back(12) == (2, 1)
assert places == list(range(1, 901)) and place(2, 1) == 8                    # formula = sorted order
assert abs(third - 1 / 3) < 1e-12 and abs(half_b - half_a) < 1e-12 and plus == 2 * 10 - 1 and noodd == 55 and left == 50
print("ALL CHECKS PASS")
