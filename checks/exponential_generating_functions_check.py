# Exponential generating functions -- the check behind the card.  Nothing is
# imported.  A Scrabble rack holds five tiles: A, A, B, B, C.  How many words of
# each length it can spell is found three ways: by multiplying one series per
# letter and reading n! times the coefficient of x^n, by choosing which places
# each letter fills, and by listing every word.  Lengths n = 0 up to 5.
RACK, TOP = [("A", 2), ("B", 2), ("C", 1)], 5
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def fact(n): return 1 if n < 2 else n * fact(n - 1)
def choose(n, k): return fact(n) // (fact(k) * fact(n - k))       # C(n, k)
def frac(a, b):                                                  # lowest terms
    g = gcd(a, b) or 1
    return f"{a // g}" if b // g == 1 else f"{a // g}/{b // g}"
def row(num, den): return ", ".join(frac(c, den) for c in num)
def conv(p, q):                                                  # plain product
    return [sum(p[i] * q[n - i] for i in range(n + 1) if i < len(p) and n - i < len(q))
            for n in range(len(p) + len(q) - 1)]
def bconv(u, v):                                                 # split the places
    return [sum(choose(n, k) * u[k] * v[n - k] for k in range(n + 1))
            for n in range(min(len(u), len(v)))]
def digits(code, base, n): return [code // base ** i % base for i in range(n)]
def words(n):                                                    # list them all
    return [w for w in (digits(c, len(RACK), n) for c in range(len(RACK) ** n))
            if all(w.count(i) <= RACK[i][1] for i in range(len(RACK)))]
def shape(w): return "".join(RACK[i][0] for i in sorted(w))
num, den, shown = [1], 1, []                     # road one: one series per letter
for letter, copies in RACK:
    num = conv(num, [fact(copies) // fact(j) for j in range(copies + 1)])
    den *= fact(copies)
    shown.append(row(num, den))
egf = [fact(n) * num[n] // den for n in range(TOP + 1)]
acc, parts = [1] + [0] * TOP, []                 # road two: whole numbers only
for _, copies in RACK:
    acc = bconv(acc, [1] * (copies + 1) + [0] * (TOP - copies))
    parts.append(acc)
ab, listed = parts[1], [len(words(n)) for n in range(TOP + 1)]
kinds = [(s, sum(1 for w in words(4) if shape(w) == s)) for s in sorted({shape(w) for w in words(4)})]
osel = [1]                                       # the ordinary series, no factorials
for _, copies in RACK: osel = conv(osel, [1] * (copies + 1))
tiles = sum(1 for c in range(5 ** 4) if len(set(digits(c, 5, 4))) == 4)
s3, s4, mp = choose(4, 3) * ab[3], ab[4], fact(5) // (fact(2) * fact(2))
print("rack: " + ", ".join(f"{L} x {c}" for L, c in RACK) + "; one series per letter")
print(f"coefficients of x^0 up, after the A tile: {shown[0]}")
print(f"after the B tile as well: {shown[1]}")
print(f"after the C tile, the whole rack: {shown[2]}")
print(f"road one, n! times the coefficient of x^n: {egf}")
print(f"road two, choosing which places each letter fills: {acc}")
print(f"road three, listing every word: {listed}")
print(f"the split at n = 4: C(4,3) x {ab[3]} = {s3}, C(4,4) x {ab[4]} = {s4}, total {s3 + s4}")
print(f"four-letter words: 4! x {frac(num[4], den)} = {fact(4)} x {frac(num[4], den)} = {egf[4]}")
print(f"five-letter words: 5! x {frac(num[5], den)} = {fact(5)} x {frac(num[5], den)} = {egf[5]}, and 5!/(2! 2!) = {mp}")
print("the four-letter words by selection: " + ", ".join(f"{s} {c}" for s, c in kinds))
print(f"mistake 1, the ordinary series read ordinarily: {osel[4]} selections, not {egf[4]} words")
print(f"mistake 2, the coefficient of x^4 left as it stands: {frac(num[4], den)}, not a count")
print(f"mistake 3, all five tiles taken as distinct: {tiles}, each word {tiles // egf[4]} times over")
print(f"mistake 4, no division by 2! but still times 4!: {fact(4)} x {osel[4]} = {fact(4) * osel[4]}")
assert egf == listed                             # the series road against the listing
assert acc == listed                             # the choosing road against the listing
assert listed[5] == mp and tiles == listed[4] * fact(2) * fact(2)
assert osel[4] == len(kinds)                     # selections, two ways
print("ALL CHECKS PASS")
