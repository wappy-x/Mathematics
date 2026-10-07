# The order of a number, and primitive roots -- the check behind the card.  Nothing
# is imported.  Road one: multiply by 10 on the clock until the remainder is 1.
# Road two: long-divide 1 by n and see how long the repeating block is.
def order(a, n):                # fewest multiplications until the remainder is 1
    r, k = a % n, 1
    while r != 1 and k <= n: r, k = r * a % n, k + 1
    return k if r == 1 else 0
def powers(a, n, k):            # the running remainders, k of them
    out, r = [], 1
    for _ in range(k): r = r * a % n; out.append(r)
    return out
def long_division(n):           # digits of 1/n and block length; right only if n and 10 share no factor
    digits, r, seen = "", 1, []
    while r not in seen: seen.append(r); digits += str(10 * r // n); r = 10 * r % n
    return digits, len(digits)
def phi(n):                     # how many of 1 to n share no factor above 1 with n
    def gcd(x, y): return x if y == 0 else gcd(y, x % y)
    return sum(1 for i in range(1, n + 1) if gcd(i, n) == 1)
for n in (7, 13):
    block, period = long_division(n)
    print(f"1/{n:<3}= 0.{block}...  repeats every {period}")
    print(f"  10 on the {n}-clock: {powers(10, n, 6)}  order {order(10, n)}  phi {phi(n)}")
print(f"2 on the 7-clock: {powers(2, 7, 3)}  order {order(2, 7)}")
print(f"10 on the 14-clock: {powers(10, 14, 6)}  order {order(10, 14)} means it never reaches 1")
assert long_division(7) == ("142857", 6) and long_division(13) == ("076923", 6)
assert all(long_division(m)[1] == order(10, m) for m in (7, 13))   # two roads agree
assert powers(10, 7, 6) == [3, 2, 6, 4, 5, 1] and powers(10, 13, 6) == [10, 9, 12, 3, 4, 1]
assert powers(10, 14, 6) == [10, 2, 6, 4, 12, 8] and powers(2, 7, 3) == [2, 4, 1]
assert phi(7) == 6 and phi(13) == 12 and phi(14) == 6 and order(2, 7) == 3 and order(10, 14) == 0
print("ALL CHECKS PASS")
