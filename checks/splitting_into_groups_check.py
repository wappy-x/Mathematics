# Splitting into groups -- the check behind the card.  Nothing is imported.
# Nine players, A to I, are split into three piles.  The named count (tables
# numbered 1, 2, 3) and the unnamed count are each reached twice, by roads that
# share no arithmetic: hand out table numbers and count, or divide factorials.
PLAYERS, EVEN, ODD = "ABCDEFGHI", (3, 3, 3), (4, 3, 2)

def fact(m):                                   # 1 x 2 x ... x m, written out here
    out = 1
    for j in range(2, m + 1): out *= j
    return out

def choose(a, b):                              # C(a, b) from Pascal's triangle alone
    row = [1]
    for _ in range(a):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[b]

def by_factorials(sizes):                      # road two: n! divided by each pile's factorial
    out = fact(sum(sizes))
    for s in sizes: out //= fact(s)
    return out

def labellings(sizes):                         # road one: every way to hand out table numbers
    k, out = len(sizes), []
    for code in range(k ** len(PLAYERS)):
        tags = [(code // k ** i) % k for i in range(len(PLAYERS))]
        if all(tags.count(t) == sizes[t] for t in range(k)):
            out.append(frozenset(frozenset(PLAYERS[i] for i, x in enumerate(tags) if x == t)
                                 for t in range(k)))
    return out

def com(v):                                    # 1680 printed 1,680, as written on the card
    s, out = str(v), ""
    for i, ch in enumerate(s):
        out += ch + ("," if (len(s) - i - 1) % 3 == 0 and i < len(s) - 1 else "")
    return out

even, orbit = labellings(EVEN), {}
for s in even:
    orbit[s] = orbit.get(s, 0) + 1
odd = set(labellings(ODD))
seq = [choose(9, 3), choose(6, 3), choose(3, 3)]
named, unnamed, even_piles = len(even), len(orbit), fact(3) ** 3
print("nine players, A to I, into three piles at tables numbered 1, 2 and 3")
print(f"road one, every labelling: 3^9 = {com(3 ** 9)} in all, {com(named)} put three players at each table")
print(f"road two, factorials: 9! / (3! 3! 3!) = {com(fact(9))} / {even_piles} = {com(by_factorials(EVEN))}")
print(f"road three, choose in turn: C(9,3) x C(6,3) x C(3,3) = {seq[0]} x {seq[1]} x {seq[2]} = {com(seq[0] * seq[1] * seq[2])}")
print(f"unnamed trios, by collecting the distinct splits: {com(unnamed)}")
print(f"unnamed trios, by formula: {com(named)} / 3! = {com(named)} / {fact(3)} = {com(named // fact(3))}")
print(f"every unnamed split wears exactly {fact(3)} sets of table numbers: {'yes' if set(orbit.values()) == {fact(3)} else 'no'}")
print(f"piles of 4, 3 and 2: 9! / (4! 3! 2!) = {com(by_factorials(ODD))} named, and {com(len(odd))} unnamed")
print(f"mistake 1, dividing by 3! when the tables are numbered: {com(named // 6)}, not {com(named)}")
print(f"mistake 2, forgetting the last pile's 3!: {com(fact(9) // (fact(3) * fact(3)))}, not {com(named)}")
print(f"mistake 3, dividing by 3! when the piles are 4, 3 and 2: {com(by_factorials(ODD) // 6)}, not {com(by_factorials(ODD))}")
assert named == by_factorials(EVEN) == seq[0] * seq[1] * seq[2]     # three roads, one count
assert unnamed == by_factorials(EVEN) // fact(3) and set(orbit.values()) == {fact(3)}
assert len(odd) == by_factorials(ODD)                               # uneven piles, brute against formula
assert choose(9, 3) * fact(3) * fact(6) == fact(9)                  # Pascal against factorials
print("ALL CHECKS PASS")
