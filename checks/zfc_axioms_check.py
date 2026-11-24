# The ZFC axioms -- the check behind the card.  Nothing is imported.  Road 1: nested frozensets.
# Road 2: each set as a number, 2 to the power of each member's number, added up.
E = frozenset()                                           # the empty set axiom
def pair(a, b): return frozenset([a, b])                  # pairing
def union(a): return frozenset(m for s in a for m in s)   # union: the members of the members
def power(a): ms = list(a); return frozenset(frozenset(m for i, m in enumerate(ms) if k >> i & 1) for k in range(2 ** len(ms)))
def code(s): return sum(2 ** code(m) for m in s)          # road 2: x is in y when bit x of y is 1
def show(c): return "{" + ",".join(show(i) for i in range(c.bit_length()) if c >> i & 1) + "}"
def row(name, value): print(f"{name:<48}{value}")
nums, wraps, ncode, wcode = [E], [E], [0], [0]
for _ in range(3):
    nums.append(union(pair(nums[-1], pair(nums[-1], nums[-1]))))   # n + 1 = n together with {n}
    wraps.append(pair(wraps[-1], wraps[-1]))              # replacement's rule: wrap once more
    ncode.append(ncode[-1] + 2 ** ncode[-1]); wcode.append(2 ** wcode[-1])   # the same, on road 2
p2, p2code = power(nums[2]), sum(2 ** c for c in range(ncode[2] + 1) if c & ncode[2] == c)   # road 2: parts of 2
deck = [(s, r) for s in "CDHS" for r in range(13)]; hearts = [c for c in deck if c[0] == "H"]
russell = frozenset(x for x in nums[3] if x not in x)     # separation: the Russell cut of 3
row("0, 1, 2, 3: members", " ".join(str(len(n)) for n in nums))
row("0, 1, 2, 3: numbers on road 2", " ".join(str(code(n)) for n in nums))
row("3 written out", show(code(nums[3])))
row("power set of 2: members, number, written out", f"{len(p2)} {code(p2)} {show(code(p2))}")
row("hearts cut from the deck by separation", f"{len(hearts)} of {len(deck)}")
row("Russell cut of 3: members, equals 3, inside 3", f"{len(russell)} {'yes' if russell == nums[3] else 'no'} {'yes' if russell in nums[3] else 'no'}")
row("replacement: n goes to 0 wrapped n times", " ".join(show(code(w)) for w in wraps))
row("mistakes: 2 as {1}, no empty part, 2's members", f"{len(pair(nums[1], nums[1]))} {len(p2) - 1} {len(nums[2])}")
assert [code(n) for n in nums] == ncode == [0, 1, 3, 11] and [code(w) for w in wraps] == wcode == [0, 1, 2, 4] and len(hearts) * 4 == len(deck)
assert code(p2) == p2code == 15 and len(p2) == 2 ** len(nums[2]) and russell == nums[3] == frozenset(nums[:3])
print("ALL CHECKS PASS")
