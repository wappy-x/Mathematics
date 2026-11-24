# Dedekind cuts -- the check behind the card.  Exact fractions, nothing rounds.  L is
# the cut for the tile's diagonal: every fraction q with q < 0 or q x q < 2.
from fractions import Fraction as F
def in_L(q): return q < 0 or q * q < 2
def below(t, q): return q < t                      # q is in the cut at the fraction t
def dec(n, k): s = str(n).rjust(k + 1, "0"); return s[:-k] + "." + s[-k:]
print("in L?", ", ".join(f"{dec(n, 2)} squares to {dec(n * n, 4)}: {'yes' if in_L(F(n, 100)) else 'no'}" for n in (140, 141, 142)))
chain = [F(7, 5)]                                  # road 1: (2q + 2)/(q + 2) is a bigger member
for _ in range(3): q = chain[-1]; chain.append((2 * q + 2) / (q + 2))
assert all(in_L(b) and b > a for a, b in zip(chain, chain[1:]))
print("no largest member:", " -> ".join(map(str, chain)), "square to", ", ".join(f"{float(q * q):.5f}" for q in chain))
tops, n = [], 1                                    # road 2: the cuts at 1.4, 1.41, ..., digit by digit
for k in range(1, 9):
    n *= 10
    while in_L(F(n + 1, 10 ** k)): n += 1
    tops.append(F(n, 10 ** k))
grid = [F(k, 997) for k in range(-3000, 3001)]     # test fractions that are not decimals
nested = all(below(b, q) for a, b in zip(tops, tops[1:]) for q in grid if below(a, q))
union = [q for q in grid if any(below(t, q) for t in tops)]
assert nested and union == [q for q in grid if in_L(q)] and all(below(F(3, 2), q) for q in union)
print("cuts at", ", ".join(str(float(t)) for t in tops[:4]), "...", float(tops[-1]), "each inside the next")
print(f"of {len(grid)} test fractions, the cuts catch exactly the {len(union)} in L, all below 1.5")
mem = union[-300:]                                 # road 3: every pair from the 300 largest test members of L
assert all(in_L((a + b) / 2) and a * b < 2 for a in mem for b in mem) and in_L(F(2828, 2000)) and not in_L(F(2829, 2000)) and tops[4] ** 2 > F(1999, 1000)
print(f"L + L: for all {len(mem) ** 2} pairs of the {len(mem)} largest test members, half the sum is in L; 2.828 is in, 2.829 is out (1.4145 squares to {dec(14145 ** 2, 8)})")
print(f"L x L: all {len(mem) ** 2} products are under 2; {float(tops[2])} x {float(tops[2])} = {dec(int(tops[2] ** 2 * 10 ** 6), 6)} and {float(tops[4])} x {float(tops[4])} = {dec(int(tops[4] ** 2 * 10 ** 10), 10)}")
inter = [q for q in grid if all(below(t, q) for t in tops)]  # 1.414213562 is in L, past all eight cuts
assert inter == [q for q in grid if below(F(7, 5), q)] and in_L(F(1414213562, 10 ** 9)) and not below(tops[-1], F(1414213562, 10 ** 9)) and not below(tops[0], F(7, 5))
print(f"mistakes: -5 squares to {(-5) ** 2}; the intersection is the cut at {float(tops[0])}; {float(tops[-1])} squares to {dec(int(tops[-1] ** 2 * 10 ** 16), 16)}, missing {dec(1414213562, 9)}")
print("ALL CHECKS PASS")
