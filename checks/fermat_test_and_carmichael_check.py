# The Fermat test -- the check behind the card.  Nothing is imported.  Is 341 prime?
# Base 2 answers 1, which says only maybe; base 3 answers 56, which proves composite.
def modpow(base, exp, n):                   # road one: square and multiply
    r, base = 1, base % n
    while exp:
        if exp & 1: r = r * base % n
        base, exp = base * base % n, exp >> 1
    return r
def slow_pow(base, exp, n):                 # road two: one multiplication at a time
    r = 1
    for _ in range(exp): r = r * base % n
    return r
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def fermat(n):                              # coprime bases, and how many answer 1
    co = [a for a in range(1, n) if gcd(a, n) == 1]
    return len(co), sum(1 for a in co if modpow(a, n - 1, n) == 1)
(co341, pass341), (co561, pass561) = fermat(341), fermat(561)
glued = next(x for x in range(341) if x % 11 == 1 and x % 31 == 25)   # road three
print(f"341 = 11 x 31 = {11 * 31}, composite; 561 = 3 x 11 x 17 = {3 * 11 * 17}, composite")
print(f"2 to the 10 is {2 ** 10} = {2 ** 10 // 341} x 341 + {2 ** 10 % 341}, so 2 to the 340 answers {modpow(2, 340, 341)}; 340 steps in a row: {slow_pow(2, 340, 341)}")
print(f"3 to the 340 on the 341 clock: {modpow(3, 340, 341)}; 340 steps in a row: {slow_pow(3, 340, 341)}")
print(f"340 = {340 // 10} x 10, so on the 11 clock 3 to the 340 is {modpow(3, 340, 11)}; 340 = {340 // 30} x 30 + {340 % 30}, so on the 31 clock it is 3 to the 10, {modpow(3, 10, 31)}; glued back: {glued}")
print(f"bases 1 to 340 sharing no factor with 341: {co341}, and {pass341} of them answer 1")
print(f"bases 1 to 560 sharing no factor with 561: {co561}, and {pass561} of them answer 1")
print(f"1105 and 1729 do it too: {fermat(1105)} and {fermat(1729)}, coprime bases and how many answer 1")
print(f"base 1 on 341 answers {modpow(1, 340, 341)}; the exponent 341 answers {modpow(2, 341, 341)}; base 3 answers {modpow(3, 340, 341)}")
assert modpow(2, 340, 341) == 1 == slow_pow(2, 340, 341) and 11 * 31 == 341 and 2 ** 10 == 3 * 341 + 1
assert modpow(3, 340, 341) == 56 == slow_pow(3, 340, 341) == glued and modpow(3, 340, 31) == 25 and modpow(3, 340, 11) == 1
assert co341 == 10 * 30 and pass341 == 100 and co561 == 2 * 10 * 16 and pass561 == co561 and fermat(1105) == (768, 768) and fermat(1729) == (1296, 1296)
print("ALL CHECKS PASS")
