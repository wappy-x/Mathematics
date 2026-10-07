# Group actions -- the check behind the card.  Nothing is imported.  A square tile
# sits down eight ways; a move is the pair (sign, shift) of the groups card, sending
# the corner in position i to position sign*i + shift, wrapped at 4.  The four
# corners are painted black or white, giving 16 patterns.  Road one lists the orbits
# by brute force; road two counts the patterns each move leaves alone and averages
# them (Burnside).  The two roads share no arithmetic.
TURNS = 4
MOVES = [(s, k) for s in (1, -1) for k in range(TURNS)]
def name(a): return f"r{a[1]}" + ("f" if a[0] == -1 else "")   # r2f: flip, 2 turns
def homes(a): return tuple((a[0] * i + a[1]) % TURNS for i in range(TURNS))
def combine(a, b): return (a[0] * b[0], (a[0] * b[1] + a[1]) % TURNS)  # b first
def fixed(a, colours): return sum(1 for p in patterns(colours) if push(a, p) == p)
def row(t, values): print(f"{t:<28}" + "".join(f"{v:>6}" for v in values))

def push(a, p):                          # the action: every corner carries its
    out = [0] * TURNS                    # colour to the position it lands on
    for i, j in enumerate(homes(a)): out[j] = p[i]
    return tuple(out)
def pull(a, p):                          # the same action read backwards: every
    back = homes((a[0], -a[0] * a[1] % TURNS))      # position asks the undo of a
    return tuple(p[back[j]] for j in range(TURNS))  # which corner it is handed
def patterns(colours):                   # every way to paint corners 0, 1, 2, 3
    return [(w, x, y, z) for w in range(colours) for x in range(colours)
            for y in range(colours) for z in range(colours)]
def orbits(colours, group):              # road one: each pattern's orbit, deduped
    seen = set(frozenset(push(a, p) for a in group) for p in patterns(colours))
    return sorted(seen, key=lambda o: (-len(o), sorted(o)))

orbs = orbits(2, MOVES)
reps = [sorted(o)[0] for o in orbs]      # the most-black pattern of each orbit
stabs = [sum(1 for a in MOVES if push(a, r) == r) for r in reps]
alone = [fixed(a, 2) for a in MOVES]     # road two's raw material
row("move", [name(a) for a in MOVES])
row("positions 0 1 2 3 go to", ["".join(str(j) for j in homes(a)) for a in MOVES])
row("patterns it leaves alone", alone)
row("one pattern per orbit", ["".join("BWG"[v] for v in r) for r in reps])
row("patterns in that orbit", [len(o) for o in orbs])
row("moves leaving it put", stabs)
row("orbit size x stabiliser", [len(o) * s for o, s in zip(orbs, stabs)])
print(f"road one, by listing: the {len(patterns(2))} patterns fall into {len(orbs)} "
      f"orbits, their sizes adding to {sum(map(len, orbs))}")
print("road two, Burnside: " + " + ".join(str(v) for v in alone) +
      f" = {sum(alone)}, and {sum(alone)} / {len(MOVES)} = {sum(alone) // len(MOVES)}")
seats = sorted(set(homes(a)[0] for a in MOVES))          # corner 0's own orbit,
keep = [name(a) for a in MOVES if homes(a)[0] == 0]      # then its stabiliser
print(f"the same moves on the four corners: corner 0 reaches {len(seats)} positions, "
      f"{' and '.join(keep)} leave it put, {len(seats)} x {len(keep)} = {len(seats) * len(keep)}")
o3, f3 = orbits(3, MOVES), [fixed(a, 3) for a in MOVES]  # a third colour, grey
print(f"three colours: {len(patterns(3))} patterns, Burnside {sum(f3)} / {len(MOVES)} "
      f"= {sum(f3) // len(MOVES)}, by listing {len(o3)}")
t2, t3 = [sum(fixed(a, c) for a in MOVES[:TURNS]) // TURNS for c in (2, 3)]
print(f"turns only, flips forgotten: two colours still gives {t2}, three gives {t3}")
print(f"the four mistakes come out at {len(patterns(2)) // len(MOVES)}, "
      f"{(sum(alone) - alone[0]) // len(MOVES)}, {stabs[2]} and {t3}")
assert all(push(a, p) == pull(a, p) for a in MOVES for p in patterns(2))
assert all(push(combine(a, b), p) == push(a, push(b, p))
           for a in MOVES for b in MOVES for p in patterns(2))
assert all(len(o) * s == len(MOVES) for o, s in zip(orbs, stabs)) and sum(map(len, orbs)) == 16
assert sum(alone) == 48 and sum(alone) // 8 == len(orbs) and len(o3) == sum(f3) // 8
print("ALL CHECKS PASS")
