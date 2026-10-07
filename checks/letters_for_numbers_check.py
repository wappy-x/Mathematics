# Letters for numbers -- the check behind the card.  Nothing is imported.  A
# taxi charges $3 to start plus $2 a mile, so the fare in dollars is 3 + 2m,
# where m is the number of miles.  Every number quoted on the card is printed
# here, and the fare is reached by two roads that share no arithmetic.
START, PER_MILE = 3, 2

def fare(m):                                   # road one: the recipe in one line
    return START + PER_MILE * m

def fare_a_mile_at_a_time(m):                  # road two: add $2, m times over
    total = START
    for _ in range(m):
        total = total + PER_MILE
    return total

def two_taxis_collected(m):                    # two fares, collected: 6 + 4m
    return 6 + 4 * m

def two_taxis_bracketed(m):                    # two fares, bracketed: 2(3 + 2m)
    return 2 * (START + PER_MILE * m)

miles = [0, 2, 4, 6, 8, 10]

def grid(name, values):
    print(f"{name:<24}" + "".join(f"{v:>6}" for v in values))

grid("miles m", miles)
grid("mileage charge, 2m", [PER_MILE * m for m in miles])
grid("one taxi, 3 + 2m", [fare(m) for m in miles])
grid("two taxis, 6 + 4m", [two_taxis_collected(m) for m in miles])
grid("two taxis, 2(3 + 2m)", [two_taxis_bracketed(m) for m in miles])
print(f"fare at m = 6 and at m = 10: {fare(6)} and {fare(10)}")
built = " + ".join([str(START)] + [str(PER_MILE)] * 6)
print(f"a mile at a time, m = 6: {built} = {fare_a_mile_at_a_time(6)}")
print(f"two fares at m = 6: {fare(6)} + {fare(6)} = {fare(6) + fare(6)}, "
      f"collected {two_taxis_collected(6)}, bracketed {two_taxis_bracketed(6)}")
hits = [m for m in range(0, 21) if fare(m) == 15]
print(f"whole miles from 0 to 20 with a fare of 15: {len(hits)}, namely m = {hits[0]}")
wrong = [5 * 6, START + PER_MILE + 6, 6 + PER_MILE * 6, START + 4 * 6]
print(f"the four mistakes at m = 6 come out at "
      f"{wrong[0]}, {wrong[1]}, {wrong[2]} and {wrong[3]}")
assert fare(0) == 3 and fare(6) == 15 and fare(10) == 23
assert all(fare_a_mile_at_a_time(m) == fare(m) for m in range(21))
assert all(two_taxis_collected(m) == two_taxis_bracketed(m) == fare(m) + fare(m)
           for m in range(21))
assert hits == [6] and wrong == [30, 11, 18, 27]
print("ALL CHECKS PASS")
