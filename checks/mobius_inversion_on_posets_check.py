# Mobius inversion on an order -- the check behind the card.  Nothing is imported.
# An order is a list of members and a test "x is below y".  mu comes from the
# recursion alone, then every count it recovers is rebuilt by brute force.
def mobius(xs, le):                      # mu(x, y) for every x below y, bottom up
    mu = {}
    for x in xs:
        for y in sorted((y for y in xs if le(x, y)), key=lambda y: sum(le(z, y) for z in xs)):
            mu[x, y] = 1 if x == y else -sum(mu[x, z] for z in xs if le(x, z) and le(z, y) and z != y)
    return mu
def mirror_ok(xs, le, mu):               # Step 2: mu(x, y) summed over x from w up to y is 1 or 0
    return all(sum(mu[x, y] for x in xs if le(w, x) and le(x, y)) == (w == y)
               for w in xs for y in xs if le(w, y))
def divisors(n): return [d for d in range(1, n + 1) if n % d == 0]
divides, subset = (lambda a, b: b % a == 0), (lambda a, b: a <= b)    # the two orders
def subsets(items): return [frozenset(x for j, x in enumerate(items) if k >> j & 1) for k in range(2 ** len(items))]
def by_inversion(n):                     # f(n) = sum over d dividing n of mu(d, n) 2^d
    mu = mobius(divisors(n), divides)
    return sum(mu[d, n] * 2 ** d for d in divisors(n))
def strings(n): return [format(k, f"0{n}b") for k in range(2 ** n)]
def primitive(s):                        # road two: not a shorter block written out again and again
    return all(s != s[:d] * (len(s) // d) for d in divisors(len(s)) if d < len(s))
def necklaces(ss): return {min(s[i:] + s[:i] for i in range(len(s))) for s in ss}
def yn(claim): return "yes" if claim else "no"
D6 = divisors(6); mu6 = mobius(D6, divides); f6 = by_inversion(6)
brute = [s for s in strings(6) if primitive(s)]
inv8 = [by_inversion(n) for n in range(1, 9)]
brute8 = [sum(1 for s in strings(n) if primitive(s)) for n in range(1, 9)]
E, B3, B4 = frozenset(), subsets([1, 2, 3]), subsets([1, 2, 3, 4])
muB3, muB4 = mobius(B3, subset), mobius(B4, subset)
pairs = [(S, T) for S in B3 for T in B3 if S <= T]
signs = all(muB3[S, T] == (-1) ** len(T - S) for S, T in pairs)
top4 = [muB4[E, T] for T in B4]
REGIONS = {"BPS": 5, "BP": 15, "BS": 10, "PS": 5, "B": 20, "P": 15, "S": 10, "": 20}
ROSTER = [set(r) for r, n in REGIONS.items() for _ in range(n)]
H = subsets("BPS"); muH = mobius(H, subset)
g = {S: sum(1 for guest in ROSTER if S <= guest) for S in H}     # guests with at least S
layers = [sum(g[T] for T in H if len(T) == j) for j in range(4)]
none = sum(muH[E, T] * g[T] for T in H)
print(f"divisors of 6 under 'divides'; mu(d, 6) for d = {D6}: {[mu6[d, 6] for d in D6]}; "
      f"mu(1, 4) = {mobius(divisors(4), divides)[1, 4]}")
print(f"f(6) = 2 - 4 - 8 + 64 = {f6}; testing all {2 ** 6} strings: {len(brute)}")
print(f"lengths 1 to 8, by inversion:   {inv8}")
print(f"lengths 1 to 8, by brute force: {brute8}")
print(f"necklaces with no repeating block: {f6} / 6 = {f6 // 6}, listing {len(necklaces(brute))}")
print(f"all necklaces of length 6, repeats allowed: {len(necklaces(strings(6)))}")
print(f"mu(empty, {{1, 2, 3}}) = {muB3[E, frozenset([1, 2, 3])]}; "
      f"(-1)^(|T| - |S|) on all {len(pairs)} pairs: {yn(signs)}")
print(f"16 subsets of {{1, 2, 3, 4}}: mu(empty, T) is +1 for {top4.count(1)}, -1 for {top4.count(-1)}, "
      f"total {sum(top4)}; mu(empty, {{1, 2, 3, 4}}) = {muB4[E, frozenset([1, 2, 3, 4])]}")
print(f"mirror sums are 1 or 0 on all three orders: {yn(all(mirror_ok(*o) for o in ((D6, divides, mu6), (B3, subset, muB3), (B4, subset, muB4))))}")
print(f"hotel: layers {layers}; none = 100 - 120 + 45 - 5 = {none}; walking the roster: {sum(1 for x in ROSTER if not x)}")
print(f"mistake 1, subtract every shorter block: 64 - 2 - 4 - 8 = {64 - 2 - 4 - 8}, not {f6}")
print(f"mistake 2, subtract only the blocks of 3 and 2: 64 - 8 - 4 = {64 - 8 - 4}, not {f6}")
print(f"mistake 3, all 64 strings shared by 6 turns: 64 / 6 = {64 / 6:.2f}, not a whole number")
assert f6 == len(brute) == 54 and inv8 == brute8                 # inversion against brute force
assert f6 // 6 == len(necklaces(brute)) == 9 and f6 % 6 == 0       # every turn of a primitive string differs
assert signs and muB3[E, frozenset([1, 2, 3])] == -1 and sum(top4) == 0
assert none == sum(1 for x in ROSTER if not x) == 20 and layers == [100, 120, 45, 5]  # the hotel card's layers
assert all(mirror_ok(*o) for o in ((D6, divides, mu6), (B3, subset, muB3), (B4, subset, muB4)))
print("ALL CHECKS PASS")
