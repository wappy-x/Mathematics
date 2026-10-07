# Subgroups and cyclic groups -- the check behind the card.  Nothing is imported.
# The group is the twelve musical pitch classes 0 to 11, added and wrapped at 12.
# Orders come out twice: by walking a jump home, and from 12 / gcd(jump, 12).
N = 12

def walk(step, n):                      # road one: repeat the jump, collect notes
    out, x = [], 0
    while x not in out:
        out.append(x)
        x = (x + step) % n
    return out

def gcd(a, b):                          # Euclid, used only by road two
    while b: a, b = b, a % b
    return a

def is_subgroup(h, n):                  # brute force: a - b must stay inside
    return bool(h) and all((a - b) % n in h for a in h for b in h)

def show(xs): return " ".join(str(x) for x in xs)

def row(name, values): print(f"{name:<16}" + "".join(f"{v:>4}" for v in values))

jumps = list(range(N))
walked = [len(walk(a, N)) for a in jumps]
formula = [N // gcd(a, N) for a in jumps]                 # road two
row("jump a", jumps)
row("order, walked", walked)
row("order, 12/gcd", formula)
for a in (4, 5, 3):
    notes = walk(a, N)
    print(f"jump {a} reaches: {show(notes)}; order {len(notes)}; "
          f"subgroup: {str(is_subgroup(set(notes), N)).lower()}")
gens = [a for a in jumps if len(walk(a, N)) == N]
coprime = [a for a in jumps if gcd(a, N) == 1]
print(f"jumps reaching all 12 notes: {show(gens)}; count {len(gens)}; "
      f"jumps coprime to 12: {show(coprime)}")
subs = sorted({frozenset(walk(a, N)) for a in jumps}, key=len)
divisors = [d for d in range(1, N + 1) if N % d == 0]
print(f"cyclic subgroups, by size: {show(len(s) for s in subs)}; "
      f"count {len(subs)}; divisors of 12: {show(divisors)}")
quarter, half = walk(1, 4), walk(2, 4)
print(f"tile: quarter turns {show(quarter)}, order {len(quarter)}; "
      f"half turns {show(half)}, order {len(half)}")
print(f"undo of jump 4 is {(-4) % N}, inside the triad: "
      f"{str((-4) % N in walk(4, N)).lower()}")
shifted = [(1 + x) % N for x in walk(4, N)]
print(f"the pair 0 and 4: subgroup {str(is_subgroup({0, 4}, N)).lower()}, "
      f"because 4 + 4 gives {(4 + 4) % N}")
print(f"the shifted loop {show(shifted)}: subgroup "
      f"{str(is_subgroup(set(shifted), N)).lower()}, holds a 0: "
      f"{str(0 in shifted).lower()}")
print(f"multiplying instead of adding: 4^3 wraps to {4 ** 3 % N}, "
      f"while three jumps of 4 give {3 * 4 % N}")
assert walked == formula and walked[4] == 3 and walked[5] == N
assert walk(5, N) == [0, 5, 10, 3, 8, 1, 6, 11, 4, 9, 2, 7] and walk(4, N) == [0, 4, 8]
assert gens == coprime == [1, 5, 7, 11] and [len(s) for s in subs] == divisors
assert (is_subgroup({0, 4, 8}, N) and not is_subgroup({0, 4}, N)
        and not is_subgroup(set(shifted), N) and not is_subgroup(set(), N))
print("ALL CHECKS PASS")
