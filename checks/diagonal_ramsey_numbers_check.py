# Diagonal Ramsey numbers -- the check behind the card.  Standard library only; math gives log2 and sqrt.
# R(k,k): the fewest dots n such that every red/blue colouring of the lines of K(n) has k dots joined
# all in one colour.  Ceilings: Erdos-Szekeres, three roads.  Floors: Erdos's count, and real colourings.
import math

def binom_pascal(n, k):                       # road 1: build Pascal's triangle row by row
    row = [1]
    for _ in range(n):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[k]

def binom_prod(n, k):                         # road 2: falling product over a factorial
    top, bot = 1, 1
    for i in range(k):
        top, bot = top * (n - i), bot * (i + 1)
    return top // bot

def rec(s, t):                                # road 3: the recursion R(s,t) <= R(s-1,t) + R(s,t-1)
    return t if s == 2 else s if t == 2 else rec(s - 1, t) + rec(s, t - 1)

def count_floor(k):                           # largest n with 2 C(n,k) < 2^C(k,2): some colouring dodges
    n = k
    while 2 * binom_prod(n + 1, k) < 2 ** binom_prod(k, 2):
        n += 1
    return n

def cliques(adj, m, k, lo=0):                 # k-sets inside the dot set m, every line among them in adj
    if k == 0:
        return 1
    return sum(cliques(adj, adj[v] & m, k - 1, v + 1) for v in range(lo, len(adj)) if m >> v & 1)

def paley(q):                                 # red line i-j when the gap j - i is a nonzero square mod q
    sq = {x * x % q for x in range(1, q)}
    red = [sum(1 << j for j in range(q) if (j - i) % q in sq) for i in range(q)]
    blue = [((1 << q) - 1) ^ a ^ (1 << i) for i, a in enumerate(red)]
    return red, blue

def dodgers(n):                               # colourings of K(n) with no one-colour triangle, by listing
    pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]
    idx = {p: b for b, p in enumerate(pairs)}
    tri = [(idx[(a, b)], idx[(a, c)], idx[(b, c)]) for a in range(n) for b in range(a + 1, n) for c in range(b + 1, n)]
    good = 0
    for col in range(1 << len(pairs)):
        if all(0 < (col >> x & 1) + (col >> y & 1) + (col >> z & 1) < 3 for x, y, z in tri):
            good += 1
    return good

def sci(log10x):                              # a number given by its log10, printed as m.mme+XX
    e = math.floor(log10x)
    return f"{10 ** (log10x - e):.2f}e+{e}"

KNOWN = {3: (6, 6), 4: (18, 18), 5: (43, 46), 6: (102, 160), 7: (205, 492), 8: (282, 1518), 9: (565, 4956), 10: (798, 16064)}
print("k = 5, the card's example")
p5, q5, r5 = binom_pascal(8, 4), binom_prod(8, 4), rec(5, 5)
print(f"ceiling, Erdos-Szekeres: C(8,4) = {p5} by Pascal's triangle, {q5} by the falling product, {r5} by the recursion")
f5 = count_floor(5)
print(f"floor, clean form: 2^(5/2) = {math.sqrt(32):.2f}, so R(5,5) > {math.isqrt(32)}")
print(f"floor, exact count: 2 x C({f5},5) = {2 * binom_prod(f5, 5)} < 2^10 = {2 ** 10} <= 2 x C({f5 + 1},5) = "
      f"{2 * binom_prod(f5 + 1, 5)}, so R(5,5) > {f5}")
red37, blue37 = paley(37)
k5r, k5b = cliques(red37, (1 << 37) - 1, 5), cliques(blue37, (1 << 37) - 1, 5)
print(f"floor, Paley colouring of K(37): one-colour K(5)s {k5r} red + {k5b} blue of {binom_prod(37, 5)}, so R(5,5) > 37")
red41, blue41 = paley(41)
k41 = cliques(red41, (1 << 41) - 1, 5) + cliques(blue41, (1 << 41) - 1, 5)
print(f"the same rule on K(41): one-colour K(5)s {k41}, so the pattern stops")
print(f"known, quoted: {KNOWN[5][0]} <= R(5,5) <= {KNOWN[5][1]}")
print(f"lines among 43 dots C(43,2) = {binom_prod(43, 2)}; fifth roots 43^(1/5) = {43 ** 0.2:.2f}, "
      f"46^(1/5) = {46 ** 0.2:.2f}; sqrt(2) = {math.sqrt(2):.2f}")
d5, d6 = dodgers(5), dodgers(6)
print(f"search: K(5) colourings with no one-colour triangle {d5} of {2 ** 10}; K(6) {d6} of {2 ** 15}, so R(3,3) = 6")
red17, blue17 = paley(17)
k17 = cliques(red17, (1 << 17) - 1, 4) + cliques(blue17, (1 << 17) - 1, 4)
print(f"Paley colouring of K(17): one-colour K(4)s {k17} of {binom_prod(17, 4)}, so R(4,4) > 17")
red101, blue101 = paley(101)
k101 = (cliques(red101, red101[0], 5), cliques(blue101, blue101[0], 5))
print(f"Paley colouring of K(101): one-colour K(6)s through dot 0, {k101[0]} red + {k101[1]} blue; "
      f"shifting moves any K(6) onto dot 0, so R(6,6) > 101")
print("  k  2^(k/2)  count floor  known lower  known upper  C(2k-2,k-1)     4^(k-1)")
for k in range(3, 11):
    lo, hi = KNOWN[k]
    print(f"{k:>3}{math.sqrt(2 ** k):>9.2f}{count_floor(k):>13}{lo:>13}{hi:>13}{binom_prod(2 * k - 2, k - 1):>13}{4 ** (k - 1):>12}")
print("k = 100")
l10c = sum(math.log10((99 + i) / i) for i in range(1, 100))
print(f"floor 2^50 = {2 ** 50} = {sci(50 * math.log10(2))}; ceiling C(198,99) = {sci(l10c)}; 4^100 = {sci(200 * math.log10(2))}")
print(f"2^50 to C(198,99) spans {math.floor(l10c) - math.floor(50 * math.log10(2))} powers of ten")
print(f"(4 - 2^-7)^100 = {sci(100 * math.log10(4 - 2 ** -7))}; 3.8^100 = {sci(100 * math.log10(3.8))}")
lc, k, cross = 0.0, 1, {}
while len(cross) < 2:                         # lc = log2 C(2k-2, k-1), grown one k at a time
    lc += math.log2((2 * k - 1) * (2 * k) / (k * k))
    k += 1
    for base in (3.8, 4 - 2 ** -7):
        if base not in cross and k * math.log2(base) < lc:
            cross[base] = k
print(f"first k where base^k falls below C(2k-2,k-1): 3.8 at k = {cross[3.8]}, 4 - 2^-7 = {4 - 2 ** -7} at k = {cross[4 - 2 ** -7]}")
ks = list(range(2, 21, 2))
print("chart, k: " + ", ".join(str(k) for k in ks))
print("chart, log2 floor k/2: " + ", ".join(f"{k / 2:.2f}" for k in ks))
print("chart, log2 C(2k-2,k-1): " + ", ".join(f"{math.log2(binom_prod(2 * k - 2, k - 1)):.2f}" for k in ks))
print("chart, log2 4^k: " + ", ".join(f"{2 * k:.2f}" for k in ks))
print(f"mistake 1, clean floor taken as the count's best: R(5,5) > {math.isqrt(32)} against > {f5}")
print(f"mistake 2, ceiling read as the value: R(5,5) = {p5} against at most 46")
print(f"mistake 3, 4^k written for the ceiling: 4^5 = {4 ** 5} against C(8,4) = {p5}")
assert p5 == q5 == r5 == 70                   # three roads to the ceiling agree
assert all(binom_pascal(2 * k - 2, k - 1) == binom_prod(2 * k - 2, k - 1) == rec(k, k) <= 4 ** (k - 1) for k in range(2, 12))
assert 2 * binom_prod(f5, 5) < 2 ** 10 <= 2 * binom_prod(f5 + 1, 5) and f5 >= math.isqrt(32)
assert (d5, d6) == (12, 0) and k17 == 0 and (k5r, k5b) == (0, 0) and k41 > 0 and k101 == (0, 0)
assert all(count_floor(k) < KNOWN[k][0] <= KNOWN[k][1] <= binom_prod(2 * k - 2, k - 1) for k in range(3, 11))
assert cross[3.8] < 100 < cross[4 - 2 ** -7]  # the 2023 base beats the binomial only for very large k
print("ALL CHECKS PASS")
