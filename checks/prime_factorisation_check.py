# Prime factorisation -- the check behind the card.  Nothing is imported.  360, the degrees in a
# circle, broken three ways: smallest prime first, the hand tree, and biggest factor first.
def smallest_prime(n): return next((d for d in range(2, n) if n % d == 0), n)   # n itself if none goes in
def peel(n):                    # road one: pull the smallest prime out, over and over
    out, chain = [], [n]
    while n > 1: p = smallest_prime(n); out.append(p); n //= p; chain.append(n)
    return out, chain
TREE = [(360, 6, 60), (60, 6, 10), (6, 2, 3), (10, 2, 5)]      # the hand tree, one split per row
def leaves(n):                  # road two: follow that tree down to the numbers that do not split
    for parent, a, b in TREE:
        if parent == n and a * b == n: return leaves(a) + leaves(b)
    return [n]
def biggest(n):                 # road three: split at the biggest factor under n, then split the pieces
    for d in range(n - 1, 1, -1):
        if n % d == 0: return biggest(d) + biggest(n // d)
    return [n]
def product(fs): return fs[0] * product(fs[1:]) if fs else 1
def show(fs): return " x ".join(str(f) for f in fs)
(one, chain), two, three = peel(360), leaves(360), biggest(360)
print(f"road one, peel the smallest prime: {' -> '.join(str(c) for c in chain)}  gives  {show(one)}")
print("the hand tree:  " + ",  ".join(f"{a} x {b} = {p}" for p, a, b in TREE))
print(f"road two, the leaves of that tree:  {show(two)};  road three, biggest factor first:  {show(three)}")
print(f"all three sorted:  {show(sorted(one))},  {show(sorted(two))},  {show(sorted(three))},  product {product(one)}")
print(f"a circle splits into equal whole-degree wedges {sum(1 for d in range(1, 361) if 360 % d == 0)} ways")
print(f"dropping one 2:  {show([2, 2, 3, 3, 5])} = {product([2, 2, 3, 3, 5])};  each prime listed once:  {show(sorted(set(one)))} = {product(sorted(set(one)))}")
print(f"stopping at 36 x 10 = {36 * 10}:  36 = {show(peel(36)[0])} and 10 = {show(peel(10)[0])}, neither is prime")
assert sorted(one) == sorted(two) == sorted(three) == [2, 2, 2, 3, 3, 5] and product(one) == 360
assert all(sorted(peel(n)[0]) == sorted(biggest(n)) and product(biggest(n)) == n and all(smallest_prime(p) == p for p in biggest(n)) for n in range(2, 1001))
print("every number from 2 to 1,000: roads one and three end at the same primes, and they multiply back")
print("ALL CHECKS PASS")
