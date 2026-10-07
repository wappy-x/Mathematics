# Counting divisors -- the check behind the card.  Nothing is imported.  A box
# of 96 tiles: 96 = 2 x 2 x 2 x 2 x 2 x 3.  The count is read off that prime
# factorisation, then checked the slow way, by trying every number up to 96.
def primes_of(n):                    # 96 -> [2, 2, 2, 2, 2, 3]
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def by_formula(n):                   # one more than each prime's count, multiplied
    total, ps = 1, primes_of(n)
    for p in sorted(set(ps)): total *= ps.count(p) + 1
    return total
def by_hand(n): return [d for d in range(1, n + 1) if n % d == 0]   # the slow road
def row(name, value): print(f"{name:<44}{value:>4}")
print("96 = " + " x ".join(str(p) for p in primes_of(96)))
row("(5 + 1) x (1 + 1)", by_formula(96))
row("divisors of 96, the slow way", len(by_hand(96)))
print("divisors of 96: " + ", ".join(str(d) for d in by_hand(96)))
print("the grid, no 3:  " + ", ".join(str(d) for d in by_hand(96) if d % 3))
print("the grid, one 3: " + ", ".join(str(d) for d in by_hand(96) if d % 3 == 0))
row("rectangle shapes, 12 / 2", by_formula(96) // 2)
row("360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)", by_formula(360))
row("divisors of 360, the slow way", len(by_hand(360)))
row("sum of the divisors of 96, 63 x 4", sum(by_hand(96)))
print(f"the three mistakes come out at {5 * 1}, {(5 + 1) + (1 + 1)} and {by_formula(96) - 2}")
assert by_formula(96) == len(by_hand(96)) == 12 and by_hand(96)[-1] == 96
assert sorted([d for d in by_hand(96) if d % 3] + [d for d in by_hand(96) if d % 3 == 0]) == by_hand(96)
assert by_formula(360) == len(by_hand(360)) == 24 and sum(by_hand(96)) == 63 * 4
print("ALL CHECKS PASS")
