# Gauss's lemma -- the check behind the card.  Nothing is imported.  Three roads to
# "is a a square on the p-clock?": try every x, Euler's power, and Gauss's count.
def euler(a, p):                 # a multiplied in (p - 1)/2 times, read as 1 or -1
    r = 1
    for _ in range((p - 1) // 2): r = r * a % p
    return -1 if r == p - 1 else r
def top(a, p):                   # readings of a, 2a, ... up to (p - 1)/2 times a, above p/2
    return [k * a % p for k in range(1, (p + 1) // 2) if 2 * (k * a % p) > p]
def root(a, p): return next((x for x in range(1, p) if x * x % p == a % p), None)
reads = [k * 3 % 11 for k in range(1, 6)]
fold = [r if 2 * r < 11 else 11 - r for r in reads]
print("3 x 1, 2, 3, 4, 5 on the 11-clock reads:", *reads)
print("above 5.5:", *top(3, 11), f"(count {len(top(3, 11))}, even); folded:", *fold)
print(f"Euler: 3^5 = {3 ** 5} = {3 ** 5 // 11} x 11 + {3 ** 5 % 11}, reads {euler(3, 11)}; root {root(3, 11)}: 25 reads {25 % 11}")
print("the squares on the 11-clock:", *sorted({x * x % 11 for x in range(1, 11)}))
print(f"-1 on 11: count {len(top(-1, 11))}, Euler {euler(-1, 11)}, root {root(-1, 11) or '-'}; on 17: count {len(top(-1, 17))}, Euler {euler(-1, 17)}, root {root(-1, 17)}")
for p in (7, 11, 13, 17, 23):
    print(f"2 on the {p:>2}-clock ({p % 8} mod 8): count above {p / 2:>4} is {len(top(2, p))}, Euler {euler(2, p):>2}, root {root(2, p) or '-'}")
below = sum(2 * r < 11 for r in reads)
allten = sum(2 * (k * 3 % 11) > 11 for k in range(1, 11))
print(f"mistakes: bottom-half count {below}, all ten multiples count {allten}, 2^10 reads {2 ** 10 % 11}, 2 on 15 counts {len(top(2, 15))}, root {root(2, 15) or '-'}")
primes = [p for p in range(3, 200) if all(p % d for d in range(2, p))]
for p in primes:
    for a in range(1, p):        # brute force, Euler and Gauss all agree
        assert euler(a, p) == (1 if root(a, p) else -1) == (-1) ** len(top(a, p))
    assert (root(-1, p) is not None) == (p % 4 == 1) and (root(2, p) is not None) == (p % 8 in (1, 7))
assert root(3, 11) == 5 and euler(2, 11) == -1 and len(top(2, 15)) == 4 and root(2, 15) is None
print("ALL CHECKS PASS")
