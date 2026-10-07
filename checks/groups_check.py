# Groups -- the check behind the card.  Nothing is imported.  A square tile sits
# eight ways.  A move is a pair (sign, shift): it sends corner i to sign*i +
# shift, wrapped at 4, with sign 1 for a turn and sign -1 for a flip.  Road one
# combines two moves by that arithmetic; road two pushes each corner through the
# two moves one after the other.  Road two never uses road one's formula.
TURNS = 4

def compose(a, b):                       # road one: arithmetic on the pairs, b first
    return (a[0] * b[0], (a[0] * b[1] + a[1]) % TURNS)

def homes(a):                            # where move a sends corners 0, 1, 2, 3
    return tuple((a[0] * i + a[1]) % TURNS for i in range(TURNS))

def through(a, b):                       # road two: corner by corner, b first
    return tuple(homes(a)[j] for j in homes(b))

def name(a):                             # r2f means flip first, then two turns
    return f"r{a[1]}" + ("f" if a[0] == -1 else "")

def row(values):
    return " ".join(str(v) for v in values)

moves = [(s, k) for s in (1, -1) for k in range(TURNS)]
e, r, f = (1, 0), (1, 1), (-1, 0)
for a in moves:
    print(f"move {name(a):<3} is (sign {a[0]:>2}, shift {a[1]}) and sends "
          f"corners 0 1 2 3 to: {row(homes(a))}")
inside = sum(1 for a in moves for b in moves if compose(a, b) in moves)
agree = sum(1 for a in moves for b in moves if homes(compose(a, b)) == through(a, b))
print(f"closure: of {len(moves) ** 2} pairs of the {len(moves)} moves, {inside} land "
      f"inside and {agree} agree with the corner-by-corner road")
triples = [(a, b, c) for a in moves for b in moves for c in moves]
same = sum(1 for a, b, c in triples
           if compose(compose(a, b), c) == compose(a, compose(b, c)))
print(f"associativity: of {len(triples)} triples, {same} regroup to the same move")
tf, ft = compose(f, r), compose(r, f)
print(f"turn then flip: {name(tf)}, sending corner 0 to {homes(tf)[0]}")
print(f"flip then turn: {name(ft)}, sending corner 0 to {homes(ft)[0]}")
undo_r = next(b for b in moves if compose(r, b) == e and compose(b, r) == e)
print(f"undo of one quarter turn: {name(undo_r)}; flip twice: {name(compose(f, f))}")
undo_7 = next(b for b in range(12) if (7 + b) % 12 == 0)
print(f"integers: 3 + (-3) = {3 + (-3)}; clock: 9 + 5 on a 12-hour clock = "
      f"{(9 + 5) % 12}, and the undo of 7 is {undo_7}")
inv7 = [next(b for b in range(1, 7) if a * b % 7 == 1) for a in range(1, 7)]
print(f"mod 7 undo list for 1 2 3 4 5 6: {row(inv7)}")
print(f"mod 7 with 0 kept: 0 times 0 1 2 3 4 5 6 gives "
      f"{row(0 * b % 7 for b in range(7))}, never 1")
leak = [(a, b) for a in range(1, 6) for b in range(1, 6) if a * b % 6 == 0]
print(f"mod 6 without 0: {leak[0][0]} times {leak[0][1]} = "
      f"{leak[0][0] * leak[0][1] % 6}, outside the set")
assert homes(r) == (1, 2, 3, 0) and homes(f) == (0, 3, 2, 1)
assert len(set(homes(a) for a in moves)) == 8 and inside == 64 and agree == 64 and same == 512
assert all(compose(e, a) == a and compose(a, e) == a for a in moves) and all(
    any(compose(a, b) == e and compose(b, a) == e for b in moves) for a in moves)
assert tf == (-1, 3) and ft == (-1, 1) and inv7 == [1, 4, 5, 2, 3, 6] and leak[0] == (2, 3)
print("ALL CHECKS PASS")
