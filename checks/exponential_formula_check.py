# The exponential formula -- the check behind the card.  Nothing is imported.  A series
# is kept as its counts: entry n is n! times the coefficient of x^n.  Multiplying two
# series is then the labelled product, C(n, k) ways to share the labels, in whole numbers.
N = 6                                                  # sizes 0 to 5
def fact(n): return 1 if n < 2 else n * fact(n - 1)
def choose(n, k): return fact(n) // (fact(k) * fact(n - k))
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def times(a, b, n): return [sum(choose(m, k) * a[k] * b[m - k] for k in range(m + 1)) for m in range(n)]
def power(c, k, n): return [1] + [0] * (n - 1) if k == 0 else times(power(c, k - 1, n), c, n)
def exp(c, n=N):                                       # road 1: add up C^k / k!
    return [sum(power(c, k, n)[m] // fact(k) for k in range(m + 1)) for m in range(n)]
def log(a, n=N):                                       # add up (-1)^(k+1) (A - 1)^k / k
    return [sum((-1) ** (k + 1) * (power([0] + a[1:n], k, n)[m] // fact(k)) * fact(k - 1)
                for k in range(1, m + 1)) for m in range(n)]
def newest(c, n=N):                                    # road 2: the piece holding label n
    a = [1]
    for m in range(1, n): a.append(sum(choose(m - 1, k - 1) * c[k] * a[m - k] for k in range(1, m + 1)))
    return a
def peel(a, n=N):                                      # road 2 run backwards
    c = [0]
    for m in range(1, n): c.append(a[m] - sum(choose(m - 1, k - 1) * c[k] * a[m - k] for k in range(1, m)))
    return c
def selfundo(n):                                       # road 3: try every map, keep p(p(i)) = i
    maps = ([code // n ** i % n for i in range(n)] for code in range(n ** n))
    return sum(all(p[p[i]] == i for i in range(n)) for p in maps)
def graphs(n):                                         # road 3: every graph, flood from vertex 0
    pairs, conn, bare = [(i, j) for i in range(n) for j in range(i + 1, n)], 0, 0
    for mask in range(2 ** len(pairs)):
        e, seen = [p for b, p in enumerate(pairs) if mask >> b & 1], {0}
        for _ in range(n): seen |= {j for i, j in e if i in seen} | {i for i, j in e if j in seen}
        conn, bare = conn + (len(seen) == n), bare + all(any(v in p for p in e) for v in range(n))
    return conn, bare
inv = [0, 1, 1, 0, 0, 0]                               # a lone letter, or one cable
I, G, R = exp(inv), [2 ** (n * (n - 1) // 2) for n in range(N)], newest(inv)
ordered, g = [power(inv, k, N)[5] for k in (3, 4, 5)], gcd(I[5], fact(5))
print(f"involutions, e^(x + x^2/2), n = 0..5: {I}")
print(f"  same by the newest-letter recurrence: {R}, a_5 = {R[4]} + 4 x {R[3]} = {R[4] + 4 * R[3]}")
print(f"  same by trying every map:             {[selfundo(n) for n in range(N)]}")
print(f"n = 5 by pieces k = 3, 4, 5: ordered {ordered}, {ordered[0]} = 120 x {ordered[0] // gcd(ordered[0], 120)}/{120 // gcd(ordered[0], 120)}; divided by k! {[o // fact(k) for o, k in zip(ordered, (3, 4, 5))]}")
print(f"coefficient of x^5: {I[5]}/120 = {I[5] // g}/{120 // g}, and 120 x {I[5] // g}/{120 // g} = {I[5]}")
print(f"set partitions, e^(e^x - 1): {exp([0] + [1] * 5)}")
print(f"shuffles by cycles, e^(-ln(1 - x)): {exp([0] + [fact(n - 1) for n in range(1, N)])}")
L, brute = log(G), [graphs(n) for n in range(1, N)]
hand = [(choose(3, k - 1), L[k], G[4 - k]) for k in (1, 2, 3)]       # pieces holding computer 4
print(f"graphs on n = 1..5 vertices:        {G[1:]}")
print(f"  connected, by the logarithm:      {L[1:]}")
print(f"  connected, by peeling backwards:  {peel(G)[1:]}")
print(f"  connected, by searching them all: {[b[0] for b in brute]}")
print(f"n = 4 by hand: 2^{4 * 3 // 2} = {G[4]}, and {G[4]} - ({' + '.join(f'{a} x {b} x {c}' for a, b, c in hand)}) = {G[4]} - ({' + '.join(str(a * b * c) for a, b, c in hand)}) = {G[4] - sum(a * b * c for a, b, c in hand)}")
P, ten = newest([0, 1, 1] + [0] * 24, 27)[26], fact(26) // (fact(6) * fact(10) * 2 ** 10)
print(f"plugboard, 26 letters: 10 cables {ten}; any number of cables {P}")
print(f"mistake 1, pieces as a list (no 1/k!): {sum(power(inv, k, N)[5] for k in range(6))}")
print(f"mistake 2, a cable counted as an ordered pair: {exp([0, 1, 2, 0, 0, 0])[5]}")
print(f"mistake 3, only a lone computer counts as cut off: {brute[3][1]}")
assert I == newest(inv) == [selfundo(n) for n in range(N)] == [1, 1, 2, 4, 10, 26]
assert exp([0] + [1] * 5) == newest([0] + [1] * 5) == [1, 1, 2, 5, 15, 52]
assert exp([0] + [fact(n - 1) for n in range(1, N)]) == [fact(n) for n in range(N)]
assert L == peel(G) == [0] + [b[0] for b in brute] and L[4] == 38 and exp(L) == G
assert P == sum(fact(26) // (fact(26 - 2 * j) * fact(j) * 2 ** j) for j in range(14))
print("ALL CHECKS PASS")
