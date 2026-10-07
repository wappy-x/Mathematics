# Linear equations -- the check behind the card.  Nothing is imported.  A taxi
# charges $3 to start plus $2 a mile, so the fare in dollars is 3 + 2m.  Every
# equation here is solved by undoing: subtract the 3 from both sides, then
# halve both sides.  A second road builds an equation from an answer picked
# first, then solves it back and must land on the answer it started from.
A, B = 2.0, 3.0                    # $2 a mile, $3 to start: fare = A*m + B

def fare(m):                       # the recipe, run forwards
    return A * m + B

def solve(a, b, c):                # a*x + b = c, undone in reverse order
    if a == 0:                     # the unknown has vanished from both sides
        return "every" if b == c else None
    return (c - b) / a             # subtract b from both sides, then divide by a

def n(v):                          # 6.0 prints as 6, 4.5 as 4.5
    return f"{v:g}"

def grid(name, values):
    print(f"{name:<32}" + "".join(f"{v:>5}" for v in values))

miles = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
grid("miles m", [n(m) for m in miles])
grid("fare 3 + 2m, in dollars", [n(fare(m)) for m in miles])
grid("the $15 target", [n(15.0) for _ in miles])
for c in (15.0, 45.0):             # one road: undo the two steps
    m = solve(A, B, c)
    print(f"2m + 3 = {n(c)}  ->  subtract 3: 2m = {n(c - B)},  halve: m = {n(m)},"
          f"  check: 3 + 2({n(m)}) = {n(fare(m))}")
for want in (6.0, 21.0):           # second road: build it from a known answer
    print(f"built from a known answer: m = {n(want)} gives fare {n(fare(want))},"
          f" solved back to m = {n(solve(A, B, fare(want)))}")
limit = solve(A, B, 15.0)
print(f"staying under $15: 2m + 3 < 15  ->  m < {n(limit)}; at m = 5 the fare is"
      f" {n(fare(5.0))}, at m = 7 it is {n(fare(7.0))}")
flip = solve(-A, 0.0, -12.0)       # 12 - 2m > 0 becomes -2m > -12
print(f"money left out of $15: 12 - 2m > 0  ->  -2m > -12  ->  m < {n(flip)} after the flip")
no_answer = solve(0.0, 3.0, 5.0)   # 3 + 2m = 5 + 2m, the 2m taken off both sides
every = solve(0.0, 0.0, 0.0)       # 3 + m + m = 3 + 2m, everything taken off
print("3 + 2m = 5 + 2m  ->  3 = 5, false: no answer")
print("3 + m + m = 3 + 2m  ->  0 = 0, true: every number works")
halved_first = 15.0 / A - B        # halving before the 3 comes off
one_side = 15.0 / A                # the 3 taken off the left side only
print(f"the three mistakes come out at {n(halved_first)}, {n(one_side)} and m > 6")
assert solve(A, B, 15.0) == 6.0 and solve(A, B, 45.0) == 21.0
assert solve(A, B, fare(6.0)) == 6.0 and solve(A, B, fare(21.0)) == 21.0
assert no_answer is None and every == "every" and flip == 6.0
assert fare(5.0) == 13.0 and fare(7.0) == 17.0 and halved_first == 4.5 and one_side == 7.5
print("ALL CHECKS PASS")
