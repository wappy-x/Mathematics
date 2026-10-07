# Matchings and augmenting paths -- the check behind the card.  Nothing is imported.
# Five volunteers, five tasks, nine 'can do' lines.  Road one: a greedy pairing repaired
# by an alternating route.  Road two: all 512 sets of lines, for the largest and for Berge.
TASKS = ["registration", "first aid", "water", "parking", "timing"]
NAMES = ["Priya", "Omar", "Lena", "Sam", "Tomas"]
CAN = [[0, 1], [2, 3], [1, 4], [2, 3], [0]]
LINES = [(v, t) for v in range(5) for t in CAN[v]]
def greedy(order):                  # each takes the first task on their list still free
    owner = [-1] * 5
    for v in order:
        free = [t for t in CAN[v] if owner[t] < 0]
        if free: owner[free[0]] = v
    return owner
def route(v, owner, seen):          # alternating route from volunteer v to a free task
    for t in CAN[v]:
        if t not in seen:
            seen.add(t)
            if owner[t] < 0: return [v, t]
            rest = route(owner[t], owner, seen)
            if rest: return [v, t] + rest
def augmenting(owner):              # the first route found from an unpaired volunteer
    routes = [route(v, owner, set()) for v in range(5) if v not in owner]
    return next((r for r in routes if r), None)
def flip(owner, r):                 # the route's outside lines go in, its inside lines out
    owner = owner[:]
    for i in range(0, len(r), 2): owner[r[i + 1]] = r[i]
    return owner
def perms(xs):                      # every order of a list, written out here
    return [[x] + p for x in xs for p in perms([y for y in xs if y != x])] if xs else [[]]
size = lambda owner: sum(1 for v in owner if v >= 0)
show = lambda owner: ", ".join(f"{NAMES[v]}-{TASKS[t]}" for t, v in enumerate(owner) if v >= 0)
g = greedy(range(5)); r = augmenting(g); fixed = flip(g, r); half = flip(g, r[:4])
by_size, agree, perfect = [0] * 6, 0, []
for mask in range(1 << len(LINES)):                         # road two: every set of lines
    pick = [LINES[i] for i in range(len(LINES)) if mask >> i & 1]
    if len({v for v, _ in pick}) < len(pick) or len({t for _, t in pick}) < len(pick): continue
    by_size[len(pick)] += 1
    owner = [next((v for v, u in pick if u == t), -1) for t in range(5)]
    if len(pick) == 5: perfect.append(owner)
    agree += (augmenting(owner) is not None) == (len(pick) < 5)
census = sum(all(p[v] in CAN[v] for v in range(5)) for p in perms(list(range(5))))
orders = perms(list(range(5))); hits = sum(size(greedy(o)) == 5 for o in orders)
best, other = max(k for k in range(6) if by_size[k]), [p for p in perfect if p != fixed][0]
print(f"volunteers 5, tasks 5, can-do lines {len(LINES)}")
print(f"greedy, in listed order: {show(g)}; size {size(g)}")
print(f"augmenting route: {' - '.join((NAMES if i % 2 == 0 else TASKS)[x] for i, x in enumerate(r))}; {len(r) - 1} lines, {len(r) // 2} out, {len(r) // 2 - 1} in")
print(f"after the flip: {show(fixed)}; size {size(fixed)}; route left: {'yes' if augmenting(fixed) else 'none'}")
print(f"matchings by size 0 to 5, from all {1 << len(LINES)} sets of lines: {by_size}")
print(f"largest by brute force: {best}; perfect matchings: {len(perfect)}; by all 120 orders of tasks: {census}")
print(f"Berge on every matching, route found exactly when size < 5: {agree} of {sum(by_size)}")
print(f"greedy orders of volunteers that reach 5: {hits} of {len(orders)}")
print(f"the other perfect matching: {show(other)}")
print(f"lines in exactly one of greedy and it: {sum((g[t] == v) != (other[t] == v) for v, t in LINES)}, "
      f"{sum(other[t] == v != g[t] for v, t in LINES)} from it, {sum(g[t] == v != other[t] for v, t in LINES)} from greedy")
print(f"mistake, flip the route only as far as Lena: {show(half)}; size {size(half)}")
assert best == size(fixed) and size(g) < best                    # two roads to 5
assert agree == sum(by_size)                                     # Berge on all matchings
assert len(perfect) == census                                    # two counts of perfect
assert hits * 6 == len(orders)       # greedy wins only when Tomas, Priya, Lena come in that order
print("ALL CHECKS PASS")
