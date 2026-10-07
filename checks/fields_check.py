# Fields -- the check behind the card.  Nothing is imported.  On a cycle of n days
# the labels are 0 to n-1, and a*x is read on the cycle.  Reciprocals come by two
# independent roads, trying every label and Euclid's algorithm, and are compared.
WEEK, SIX, CLOCK = 7, 6, 12

def answers(a, b, n):                       # road one: try every label on the cycle
    return [x for x in range(n) if a * x % n == b]

def reciprocal(a, n):                       # road two: Euclid, gcd as a combination
    r0, r1, t0, t1 = n, a % n, 0, 1         # r0 is always t0 jumps of a, plus n's
    while r1:
        q = r0 // r1
        r0, r1 = r1, r0 - q * r1
        t0, t1 = t1, t0 - q * t1
    return t0 % n if r0 == 1 else None      # nothing to return unless the gcd is 1

def is_prime(n):                            # trial division, independent of the rest
    return n >= 2 and all(n % d for d in range(2, n))

def grid(name, values): print(f"{name:<27}" + "".join(f"{v:>4}" for v in values))

sizes = list(range(2, CLOCK + 1))
euclid = [reciprocal(a, WEEK) for a in range(1, WEEK)]
searched = [answers(a, 1, WEEK)[0] for a in range(1, WEEK)]
units = [[a for a in range(1, n) if answers(a, 1, n)] for n in sizes]
by_search = [len(u) for u in units]
by_euclid = [len([a for a in range(1, n) if reciprocal(a, n) is not None]) for n in sizes]
fields = [n for n, c in zip(sizes, by_search) if c == n - 1]
primes = [n for n in sizes if is_prime(n)]
pairs = [(a, b) for a in range(1, WEEK) for b in range(WEEK)]
most = max(len(answers(a, b, WEEK)) for a, b in pairs)
x, wrong = 4 * reciprocal(3, WEEK) % WEEK, 4 * 4 % WEEK
print(f"week labels 0 to {WEEK - 1}; reciprocals of 1 to {WEEK - 1}: {euclid}")
print(f"reciprocal checks mod {WEEK}: 2*4 = {2 * 4 % WEEK}, 3*5 = {3 * 5 % WEEK}, "
      f"6*6 = {6 * 6 % WEEK}")
print(f"3x = 4 mod {WEEK}: Euclid road x = {x}, search road {answers(3, 4, WEEK)}")
print(f"by hand: 3*5 = {3 * 5}, {3 * 5} - {2 * WEEK} = {3 * 5 - 2 * WEEK}; 5*4 = {5 * 4}, "
      f"{5 * 4} - {2 * WEEK} = {5 * 4 - 2 * WEEK}; 3*6 = {3 * 6}, {3 * 6} - {2 * WEEK} = {3 * 6 - 2 * WEEK}")
print(f"all {len(pairs)} equations a*x = b mod {WEEK}, a nonzero: at most {most} answer")
print(f"zero coefficient mod {WEEK}: 0x = 1 has {len(answers(0, 1, WEEK))} answers, "
      f"0x = 0 has {len(answers(0, 0, WEEK))}")
print(f"3+4 = {(3 + 4) % WEEK} mod {WEEK} but 3*4 = {3 * 4 % WEEK}; that road gives "
      f"x = {wrong}, and 3*{wrong} = {3 * wrong % WEEK}, not 4")
print(f"six-day cycle: reciprocals only for {units[SIX - 2]}; 2*3 = {2 * 3 % SIX}; "
      f"2x = 1 answers {answers(2, 1, SIX)}; 2x = 2 answers {answers(2, 2, SIX)}")
print(f"twelve-hour clock: reciprocals only for {units[CLOCK - 2]}; "
      f"3*4 = {3 * 4 % CLOCK}; 3x = 0 answers {answers(3, 0, CLOCK)}")
print(f"integers: 2k = 1 has {len([k for k in range(-20, 21) if 2 * k == 1])} answers "
      f"for k from -20 to 20; rationals: (3/4)*(4/3) = {3 * 4}/{4 * 3} = 1")
grid("cycle size n", sizes)
grid("nonzero labels, n - 1", [n - 1 for n in sizes])
grid("of those, with a reciprocal", by_search)
grid("the same count, by Euclid", by_euclid)
print(f"cycle sizes that are fields: {fields}")
print(f"primes up to {CLOCK}, by trial division: {primes}")
assert euclid == searched == [1, 4, 5, 2, 3, 6]
assert all(answers(a, b, WEEK) == [b * reciprocal(a, WEEK) % WEEK] for a, b in pairs)
assert fields == primes == [2, 3, 5, 7, 11] and by_search == by_euclid
assert (answers(2, 1, SIX), answers(2, 2, SIX), answers(3, 0, CLOCK)) == ([], [1, 4], [0, 4, 8])
print("ALL CHECKS PASS")
