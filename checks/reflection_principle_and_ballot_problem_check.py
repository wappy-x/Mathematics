# The reflection principle and the ballot problem -- the check behind the card.
# Nothing is imported.  Eight votes are counted one at a time, 5 for A and 3
# for B.  Every order is listed and tested; the same count is then reached by
# the mirror argument and by the ballot formula.  The shelf's ten-step paths
# back to the start are counted the same two ways at the end.
A, B = 5, 3
N, GOOD, SPOILED = A + B, "AABABABA", "ABABBAAA"

def choose(n, k):                          # n choose k, built from a plain loop
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def orders(a, b):                          # every arrangement of a A's and b B's
    if a + b == 0:
        return [""]
    out = ["A" + tail for tail in orders(a - 1, b)] if a else []
    return out + (["B" + tail for tail in orders(a, b - 1)] if b else [])

def leads(order):                          # A's lead after each vote, from 0
    out = [0]
    for v in order:  out.append(out[-1] + (1 if v == "A" else -1))
    return out

def mirror(order):                         # swap A and B up to the first level score
    cut = leads(order).index(0, 1)
    return "".join("B" if v == "A" else "A" for v in order[:cut]) + order[cut:]

every = orders(A, B)                                              # road one: list them
ahead = [o for o in every if all(x > 0 for x in leads(o)[1:])]
b_open = sorted(o for o in every if o[0] == "B")
tied = [o for o in every if o[0] == "A" and 0 in leads(o)[1:]]
mirrored = sorted(mirror(o) for o in tied)                        # road two: mirror them
ballot = (A - B) * choose(N, A) // N                              # road three: the formula
level_ok = [o for o in every if all(x >= 0 for x in leads(o)[1:])]
dyck = orders(5, 5)
low_ok = [o for o in dyck if all(x >= 0 for x in leads(o))]

print(f"{N} votes counted one at a time, {A} for A and {B} for B: all orders C({N},{A}) = {choose(N, A)}")
print(f"by listing all {len(every)} orders: A strictly ahead after every vote in {len(ahead)} of them")
print(f"by the ballot formula: ({A} - {B}) / ({A} + {B}) x {choose(N, A)} = {ballot}")
print(f"{len(b_open)} orders open with a vote for B; {len(every) - len(b_open)} open with A, and {len(tied)} of those reach a tie later")
print(f"the mirror matches those {len(tied)} to the {len(b_open)} B-openers, one to one: {'yes' if mirrored == b_open else 'no'}")
print(f"so the count is C({N-1},{A-1}) - C({N-1},{A}) = {choose(N-1, A-1)} - {choose(N-1, A)} = {choose(N-1, A-1) - choose(N-1, A)}")
print(f"a good order, {' '.join(GOOD)}: A's lead after each vote {leads(GOOD)}")
print(f"a spoiled order, {' '.join(SPOILED)}: A's lead after each vote {leads(SPOILED)}")
print(f"its mirror, {' '.join(mirror(SPOILED))}: A's lead after each vote {leads(mirror(SPOILED))}")
print(f"the two agree from vote {leads(SPOILED).index(0, 1)} on: {'yes' if leads(mirror(SPOILED))[2:] == leads(SPOILED)[2:] else 'no'}")
print(f"mistake 1, counting a tie as still ahead: {len(level_ok)} orders, not {len(ahead)}")
print(f"mistake 2, forgetting the orders that open with B: {choose(N, A)} - {len(tied)} = {choose(N, A) - len(tied)}, not {len(ahead)}")
print(f"mistake 3, dividing by A's votes alone: ({A} - {B}) / {A} x {choose(N, A)} = {(A - B) * choose(N, A) / A:.1f}, not a whole count")
print(f"ten steps back to the start: C(10,5) = {len(dyck)} orders, {len(low_ok)} of them never dip below zero")
print(f"the same {len(low_ok)} by mirroring at one step below: {len(dyck)} - C(10,4) = {len(dyck)} - {choose(10, 4)} = {len(dyck) - choose(10, 4)}")
assert len(ahead) == ballot == 14                                 # listing against the formula
assert mirrored == b_open and len(every) - len(b_open) - len(tied) == len(ahead)
assert len(ahead) == choose(N - 1, A - 1) - choose(N - 1, A)      # listing against Pascal's split
assert len(low_ok) == len(dyck) - choose(10, 4) and len(low_ok) == choose(10, 5) // 6
print("ALL CHECKS PASS")
