# Counting by multiplying series -- the check behind the card.  Nothing is
# imported.  Making 50 cents from pennies, nickels, dimes and quarters is the
# coefficient of x^50 in 1/((1-x)(1-x^5)(1-x^10)(1-x^25)).  Road one multiplies
# the four series and collects like powers; road two counts coin piles instead.
N, COINS = 50, (1, 5, 10, 25)
def mul(a, b, top):                       # collect a_i * b_j onto degree i + j
    out = [0] * (top + 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            if ai and bj and i + j <= top:
                out[i + j] += ai * bj
    return out
def factor(v, top, least=0):              # one kind of coin: x^(least*v) + ...
    f = [0] * (top + 1)
    for m in range(least, top // v + 1):
        f[m * v] = 1
    return f
def product(coins, top=N, least=0):       # road one: multiply the factors
    out = [1] + [0] * top
    for v in coins:
        out = mul(out, factor(v, top, least), top)
    return out
def piles(target, coins):                 # road two: count coin piles, no series
    if not coins:
        return 1 if target == 0 else 0
    v = coins[0]
    return sum(piles(target - m * v, coins[1:]) for m in range(target // v + 1))
def choose(m, r):                         # Pascal's rule, written out here
    row = [1]
    for _ in range(m):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[r]
def yn(claim): return "yes" if claim else "no"
ways = product(COINS)
row = [ways[n] for n in range(0, N + 1, 5)]
growing = [product(COINS[:i + 1])[N] for i in range(len(COINS))]
quartered = [piles(N - 25 * d, COINS[:3]) for d in range(3)]   # 0, 1 or 2 quarters
dice = mul(factor(1, 6, 1), factor(1, 6, 1), 12)     # one die: x^1 + ... + x^6
threefold = product((1, 1, 1), top=5)
blind = product((1, 1, 1, 1))[N]
spread = (N // 5 + 1) * (N // 10 + 1) * (N // 25 + 1)   # nickels x dimes x quarters
print(f"making {N} cents from pennies (1), nickels (5), dimes (10), quarters (25)")
print(f"road one, the coefficient of x^{N} in the product of four series: {ways[N]}")
print(f"road two, counting the coin piles, no series named: {piles(N, COINS)}")
print(f"one kind added at a time, the count at {N} cents: {', '.join(str(g) for g in growing)}")
print(f"ways to make 0, 5, 10 ... {N} cents: {row}")
print(f"the same eleven counts by counting piles: {yn(row == [piles(n, COINS) for n in range(0, N + 1, 5)])}")
print(f"by hand, split on the quarters: {' + '.join(str(q) for q in quartered)} = {sum(quartered)}")
print(f"two dice, (x + x^2 + ... + x^6) squared: coefficient of x^7 = {dice[7]}")
print(f"the same pairs listed by hand: {sum(1 for d in range(1, 7) if 1 <= 7 - d <= 6)}; every coefficient added: {sum(dice)}")
print(f"three unlimited kinds, total 5: series {threefold[5]}, stars and bars C(7, 2) = {choose(7, 2)}")
print(f"mistake 1, the {N // 5 + 1} x {N // 10 + 1} x {N // 25 + 1} pile counts multiplied as if free: {spread}, not {ways[N]}")
print(f"mistake 2, the four series added instead of multiplied: {sum(factor(v, N)[N] for v in COINS)}")
print(f"mistake 3, every factor started at its own coin: {product(COINS, least=1)[N]}")
print(f"mistake 4, coin values ignored, stars and bars alone: C(53, 3) = {blind}")
assert ways[N] == piles(N, COINS) and row == [piles(n, COINS) for n in range(0, N + 1, 5)]
assert ways[N] == 49 and growing == [1, 11, 36, 49] and sum(quartered) == 49
assert threefold[5] == choose(7, 2) and blind == choose(N + 3, 3)
assert dice[7] == sum(1 for d in range(1, 7) if 1 <= 7 - d <= 6) and sum(dice) == 36
print("ALL CHECKS PASS")
