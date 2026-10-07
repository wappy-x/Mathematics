# Diffie-Hellman -- the check behind the card.  Nothing is imported.  A group chat
# everyone can read: clock 23, base 5.  Mia keeps 6 to herself, Ray keeps 15.
P, G, MIA, RAY = 23, 5, 6, 15
def stepwise(base, count, p):          # the plain way: multiply, drop whole clocks
    out = 1
    for _ in range(count): out = out * base % p
    return out
def squaring(base, count, p):          # road two: square and multiply, same answer
    out, b = 1, base % p
    while count:
        if count % 2: out = out * b % p
        b, count = b * b % p, count // 2
    return out
pm, pr = stepwise(G, MIA, P), stepwise(G, RAY, P)
sm, sr = stepwise(pr, MIA, P), stepwise(pm, RAY, P)
both, counts = stepwise(G, MIA * RAY, P), [c for c in range(1, P) if stepwise(G, c, P) == pm]
two, reach = stepwise(stepwise(2, RAY, P), MIA, P), sorted({stepwise(2, c, P) for c in range(1, P)})
print(f"clock {P} and base {G} are public; Mia keeps {MIA}, Ray keeps {RAY}, and neither is ever posted")
print(f"Mia posts {G} multiplied out {MIA} times: {G ** MIA} = {G ** MIA // P} x {P} + {pm}")
print(f"Ray posts {G} multiplied out {RAY} times: {G ** RAY} = {G ** RAY // P} x {P} + {pr}")
print(f"Mia multiplies Ray's {pr} out {MIA} times: {pr ** MIA} = {pr ** MIA // P} x {P} + {sm}; Ray multiplies Mia's {pm} out {RAY} times: {sr}")
print(f"both are {G} multiplied out {MIA * RAY} times on the {P} clock: {both}")
print(f"by squaring instead of stepping: {squaring(G, MIA, P)}, {squaring(G, RAY, P)}, {squaring(pr, MIA, P)}")
print(f"a listener has {P}, {G}, {pm}, {pr}; every count 1 to {P - 1} tried against {pm} gives {counts}")
print(f"count {MIA + 1} would give {stepwise(G, MIA + 1, P)}, not {pm}: a near miss tells you nothing")
print(f"mistakes: {pm} x {pr} lands on {pm * pr % P}; base 2 shares {two} and reaches only {len(reach)} values")
assert pm == 8 and pr == 19 and sm == 2 and sm == sr and both == 2
assert squaring(G, MIA, P) == pm and squaring(G, RAY, P) == pr and squaring(pr, MIA, P) == sm and squaring(G, MIA * RAY, P) == 2
assert counts == [MIA] and stepwise(G, MIA + 1, P) == 17 and pm * pr % P == 14 and two == 4 and len(reach) == 11
print("ALL CHECKS PASS")
