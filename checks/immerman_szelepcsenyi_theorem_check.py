# NL = coNL: a guessing machine certifies "no path" by inductive counting.
# Standard library only. Rooms 1 to 6, start room 1, exit room 6, one-way doors.
# The guessing machine is simulated by trying every guess it could make: every guessed
# set of rooms (a 6-bit mask, 64 of them) and every guessed walk of at most k doors.
N, START, EXIT = 6, 1, 6
MAZE_A = [(1, 2), (1, 3), (2, 4), (3, 4), (4, 1), (5, 6), (6, 5), (5, 2), (6, 3)]
MAZE_B = MAZE_A + [(4, 5)]                      # one extra door: now the exit is reachable
CORRIDOR = [(r, r + 1) for r in range(1, N)]   # 1 -> 2 -> 3 -> 4 -> 5 -> 6

def layers(doors, rounds):
    """Road 1, no guessing: the sets R_0, R_1, ... built explicitly, one door at a time."""
    sets = [{START}]
    for _ in range(rounds):
        sets.append(sets[-1] | {b for a, b in doors if a in sets[-1]})
    return sets

def walks(door, u, k):
    """The machine's walk guess, every guess tried: room sequences of at most k doors
    from START that end at u. A guess that is not a real door kills that branch."""
    good, seqs = 0, [[START]]
    for _ in range(k + 1):
        good += sum(1 for s in seqs if s[-1] == u)
        seqs = [s + [r] for s in seqs for r in range(1, N + 1) if (s[-1], r) in door]
    return good

def members(g):
    return [u for u in range(1, N + 1) if g >> (u - 1) & 1]

def round_answers(door, v, c, k, check=True):
    """One counting round, for room v: each branch guesses a set G of rooms 'within k doors',
    proves each member by a walk, and (if check) must have exactly c members.
    Returns the answers 'v is within k + 1 doors' given by surviving branches, and their number."""
    answers, alive = set(), 0
    for g in range(2 ** N):
        G = members(g)
        if (check and len(G) != c) or not all(walks(door, u, k) for u in G):
            continue                                          # this branch rejects
        alive += 1
        answers.add(any(u == v or (u, v) in door for u in G))
    return answers, alive

def machine(doors, final_check=True, max_rounds=99):
    """Road 2: the guessing machine, every branch tried. Counts c_k until the count
    repeats, then re-finds c rooms one by one and accepts 'no path' if none is the exit."""
    door, c, k, counts = set(doors), 1, 0, [1]
    while k < max_rounds:
        new = 0
        for v in range(1, N + 1):
            answers, alive = round_answers(door, v, c, k)
            assert alive == 1 and len(answers) == 1           # exactly one branch survives
            new += answers.pop()
        k += 1
        counts.append(new)
        if new == c:
            break
        c = new
    acc = sum(1 for g in range(2 ** N)
              if (not final_check or len(members(g)) == c)
              and all(walks(door, u, k) for u in members(g)) and EXIT not in members(g))
    return counts, acc, k

def names(s):
    return "{" + ", ".join(str(r) for r in sorted(s)) + "}"

print("maze A: rooms 1-6, start 1, exit 6, doors " + " ".join(f"{a}>{b}" for a, b in MAZE_A))
counts, acc, k = machine(MAZE_A)
sets = layers(MAZE_A, len(counts) - 1)
for j, s in enumerate(sets):
    print(f"road 1, k {j}: R_{j} = {names(s):<14} size {len(s)}   road 2, c_{j} = {counts[j]}")
assert counts == [len(s) for s in sets] == [1, 3, 4, 4]       # guessing count = explicit sets
print(f"road 2: count stops growing at round {k}; 6 rooms x 64 guessed sets per round, 1 branch survives per room")
print(f"road 2: final pass, 64 guessed sets, only those listing exactly {counts[-1]} rooms count: {acc} branch accepts 'no path'")
assert acc == 1 and EXIT not in sets[-1]
for j, c in enumerate(counts):
    print(f"bar c_{j} " + "####" * c + " " * (4 * (N - c)) + f" {c}")
w4 = walks(set(MAZE_A), 4, 2)
print(f"walk guesses: room 4 within 2 doors has {w4} proofs (1>2>4, 1>3>4); room 5 within 3 doors has {walks(set(MAZE_A), 5, 3)}")
assert w4 == 2

cb, ab, kb = machine(MAZE_B)
sb = layers(MAZE_B, len(cb) - 1)
print(f"maze B (add door 4>5): counts {cb}, R = {names(sb[-1])}, accepting branches {ab}")
assert cb == [len(s) for s in sb] and ab == 0 and EXIT in sb[-1]
cc, ac, kc = machine(CORRIDOR)
print(f"corridor 1>2>3>4>5>6: counts {cc}, growth stops at round {kc - 1} = n - 1, accepting branches {ac}")
assert cc == [len(s) for s in layers(CORRIDOR, len(cc) - 1)] and kc - 1 == N - 1

_, wrong1, _ = machine(MAZE_B, final_check=False)
print(f"wrong: drop the final count check, maze B: {wrong1} branches accept 'no path'")
assert wrong1 == 32
_, a2, _ = machine(MAZE_A, final_check=False)
c2, wrong2, _ = machine(MAZE_B, max_rounds=2)
print(f"wrong: stop after 2 rounds, maze B: counts {c2}, {wrong2} branch accepts 'no path'; exit is 4 doors away")
assert wrong2 == 1 and EXIT in layers(MAZE_B, 4)[4] and EXIT not in layers(MAZE_B, 3)[3]
mixed = [v for v in range(1, N + 1) if len(round_answers(set(MAZE_A), v, 3, 1, check=False)[0]) == 2]
print(f"wrong: drop the count check in round 2, maze A: rooms {mixed} get both answers")
assert mixed == [1, 2, 3, 4]

def reg_bits(n):        # 8 registers of a room number or count, plus one 'found' flag
    return 8 * n.bit_length() + 1
print("memory: rooms n, counting registers (8 numbers up to n in binary + 1 flag), one-bit-per-room list")
for n in (6, 1000, 1000000):
    print(f"  n {n:>9,}  registers {reg_bits(n):>4} bits  list {n:>9,} bits")
cross = next(n for n in range(2, 10 ** 4) if all(reg_bits(m) < m for m in range(n, 10 ** 4)))
print(f"registers beat the list for every n from {cross} on (checked to 9,999)")
assert cross == 50 and reg_bits(10 ** 6) == 161
print(f"try: drop the final count check, maze A: {a2} branches accept, all happen to be right")
print(f"try: n = 10^9 rooms: registers {reg_bits(10 ** 9)} bits")
print("ALL CHECKS PASS")
