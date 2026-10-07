# Orders -- the check behind the card.  Nothing is imported.  The six divisors of 12 under "divides",
# and the same six under "less than or equal": three order tests each, then comparability, then covers.
D, NAMES = [1, 2, 3, 4, 6, 12], ["reflexive", "antisymmetric", "transitive", "all pairs compare"]
DIV, LEQ = {(a, b) for a in D for b in D if b % a == 0}, {(a, b) for a in D for b in D if a <= b}
def tests(R):                  # the three order tests, then the extra one that makes it total
    return (all((a, a) in R for a in D), all(a == b for a, b in R if (b, a) in R),
            all((a, c) in R for a, b in R for c in D if (b, c) in R),
            all((a, b) in R or (b, a) in R for a in D for b in D))
def covers(R):                 # a step up with nothing strictly in between: the Hasse edges
    return sorted((a, b) for a, b in R if a != b and not any((a, m) in R and (m, b) in R for m in D if m != a and m != b))
def rebuild(edges):            # the loops, then chain the edges over and over: the second road
    R = {(a, a) for a in D} | set(edges)
    while any((a, c) not in R for a, b in R for x, c in R if b == x):
        R |= {(a, c) for a, b in R for x, c in R if b == x}
    return R
COV, LCOV = covers(DIV), covers(LEQ)
INCOMP = sorted((a, b) for a in D for b in D if a < b and (a, b) not in DIV and (b, a) not in DIV)
STRICT, GAPPY = {(a, b) for a, b in DIV if a != b}, {(a, a) for a in D} | {(1, 2), (2, 4)}   # loops dropped; 1 to 2 and 2 to 4, no 1 to 4
print(f"the six divisors of 12: {', '.join(map(str, D))} -- {len(D) * len(D)} ordered pairs to ask about")
print("divides pairs, counting multiples: " + " + ".join(str(sum(1 for b in D if b % a == 0)) for a in D) + f" = {len(DIV)}")
print("less than or equal pairs:          " + " + ".join(str(sum(1 for b in D if a <= b)) for a in D) + f" = {len(LEQ)}")
print(f"{'test':<20}{'divides':<9}less than or equal")
for n, x, y in zip(NAMES, tests(DIV), tests(LEQ)): print(f"{n:<20}{('yes' if x else 'no'):<9}{'yes' if y else 'no'}")
print(f"incomparable under divides: {', '.join(f'({a}, {b})' for a, b in INCOMP)} -- {len(INCOMP)} of the {len(D) * (len(D) - 1) // 2} pairs")
print(f"Hasse edges: divides {len(COV)} ({', '.join(f'{a}-{b}' for a, b in COV)}), the chain {len(LCOV)}")
print(f"rebuilt from those {len(COV)} edges plus loops: {len(rebuild(COV))} pairs, the same list; strict divides: {len(STRICT)} pairs, reflexive {'yes' if tests(STRICT)[0] else 'no'}")
assert len(DIV) == 18 and len(LEQ) == 21 and len(STRICT) == 12 and INCOMP == [(2, 3), (3, 4), (4, 6)]
assert tests(DIV) == (True, True, True, False) and tests(LEQ) == (True, True, True, True) and not tests(STRICT)[0] and tests(GAPPY) == (True, True, False, False)
assert rebuild(COV) == DIV and COV == [(1, 2), (1, 3), (2, 4), (2, 6), (3, 6), (4, 12), (6, 12)] and LCOV == [(1, 2), (2, 3), (3, 4), (4, 6), (6, 12)]
print("ALL CHECKS PASS")
