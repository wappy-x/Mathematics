# The binomial theorem -- the check behind the card.  Nothing is imported.  Three
# roads to (10 + 1)^4 = 14,641: Pascal's triangle built by adding neighbours, the
# same counts built from factorials, and all 16 picks from the four brackets
# multiplied out.  Then $100 at 5% for ten years, and (100 + 10 + 1)^3 = 111^3.
ROWS = [[1]]
for _ in range(10):                          # road one: a row from the row above
    p = ROWS[-1]
    ROWS.append([1] + [p[i] + p[i + 1] for i in range(len(p) - 1)] + [1])
def fact(m):                                 # factorials, written out here
    out = 1
    for i in range(2, m + 1): out *= i
    return out
def choose(n, k): return fact(n) // (fact(k) * fact(n - k))   # road two, from factorials
def expand(a, b, n): return [ROWS[n][k] * a ** (n - k) * b ** k for k in range(n + 1)]
def picks(parts, n):                         # road three: every pick from every bracket
    total = 0
    for word in range(len(parts) ** n):
        prod, w = 1, word
        for _ in range(n): prod, w = prod * parts[w % len(parts)], w // len(parts)
        total += prod
    return total
def split3(a, b, c, n):                      # n!/(i! j! l!) over every split of n
    total = 0
    for i in range(n + 1):
        for j in range(n + 1 - i):
            l = n - i - j
            total += fact(n) // (fact(i) * fact(j) * fact(l)) * a ** i * b ** j * c ** l
    return total
def money(c): return f"{c // 100}.{c % 100:02d}"              # whole cents, as dollars
terms, signed = expand(10, 1, 4), expand(10, -1, 4)
digits = int("".join(str(v) for v in ROWS[5]))
cents = [(sum(ROWS[10][k] * 100 ** (10 - k) * 5 ** k for k in range(m + 1))
          + 5 * 10 ** 15) // 10 ** 16 for m in range(11)]     # exact, in whole cents
grown = 100.0
for _ in range(10): grown *= 1.05            # the same ten years, by multiplying
laws = all(sum(r) == 2 ** n and (n == 0 or sum((-1) ** k * v for k, v in enumerate(r)) == 0)
           for n, r in enumerate(ROWS))
print(f"row 4 by adding neighbours: {ROWS[4]}; by factorials: {[choose(4, k) for k in range(5)]}")
print(f"(10 + 1)^4 term by term: {' + '.join(str(t) for t in terms)} = {sum(terms)}; 11^4 = {11 ** 4}")
print(f"all {2 ** 4} picks from the four brackets, multiplied and added: {picks([10, 1], 4)}")
print(f"(10 - 1)^4 term by term: {signed} adds to {sum(signed)}; 9^4 = {9 ** 4}")
print(f"row 5: {ROWS[5]}; pasted together as digits {digits}, but 11^5 = {11 ** 5}")
print(f"row 10: {ROWS[10]}")
print(f"row 10 added up: {sum(ROWS[10])}; with alternating signs: "
      f"{sum((-1) ** k * v for k, v in enumerate(ROWS[10]))}")
print(f"every row 0 to 10 adds to 2^n, and alternates to 0 after row 0: {'yes' if laws else 'no'}")
print("$100 at 5% for ten years, one term at a time: " + " ".join(money(c) for c in cents))
print(f"the same balance by multiplying 1.05 in ten times: {grown:.2f}")
print(f"first two terms alone: {money(cents[1])}, simple interest; the other nine: {money(cents[10] - cents[1])}")
print(f"(100 + 10 + 1)^3 by split counts: {split3(100, 10, 1, 3)}; 111^3 = {111 ** 3}")
print(f"all {3 ** 3} picks from the three brackets, multiplied and added: {picks([100, 10, 1], 3)}")
print(f"one bracket each: 3!/(1!1!1!) = {fact(3) // (fact(1) ** 3)} orders, term {fact(3) * 100 * 10}")
print(f"mistake 1, (10 + 1)^4 read as 10^4 + 1^4: {10 ** 4 + 1 ** 4}, not {sum(terms)}")
print(f"mistake 2, the counts dropped: {sum(10 ** (4 - k) for k in range(5))}, not {sum(terms)}")
print(f"mistake 3, (10 - 1)^4 with the minus signs lost: {sum(terms)}, not {sum(signed)}")
assert sum(terms) == picks([10, 1], 4) == 11 ** 4 == 14641
assert [choose(4, k) for k in range(5)] == ROWS[4] and sum(ROWS[10]) == 2 ** 10
assert sum(signed) == 9 ** 4 and round(grown * 100) == cents[10] == 16289
assert split3(100, 10, 1, 3) == picks([100, 10, 1], 3) == 111 ** 3 and laws
print("ALL CHECKS PASS")
