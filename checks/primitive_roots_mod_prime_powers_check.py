# Primitive roots on prime-power clocks -- the check behind the card.  Nothing is imported.  Road one:
# brute force, multiplying until the remainder is 1.  Road two: the lifting test, and Gauss's list from the factors.
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def order(a, n):                    # fewest multiplications by a back to 1; 0 if it never gets there
    r, k = a % n, 1
    while r != 1 and k <= n: r, k = r * a % n, k + 1
    return k if r == 1 else 0
def phi(n): return sum(1 for i in range(1, n + 1) if gcd(i, n) == 1)
def best(n): return max(order(a, n) for a in range(1, n))          # the longest order on the clock
def on_list(n):                     # Gauss's list: 2, 4, p to the k, 2 x p to the k, p an odd prime
    if n in (2, 4): return True
    m = n // 2 if n % 4 == 2 else n
    p = next(d for d in range(2, m + 1) if m % d == 0)            # smallest prime factor
    while m % p == 0: m //= p
    return p > 2 and m == 1
sizes, bad = [7, 49, 343, 2401, 98], [x for x in range(1, 49) if x % 7 == 3 and x ** 6 % 49 == 1]
units15, twos = [x for x in range(1, 15) if gcd(x, 15) == 1], [8, 16, 32, 64]
agree = sum(1 for n in range(2, 101) if on_list(n) == (best(n) == phi(n)))                 # Gauss against brute force
print(f"3 to the 6 = {3 ** 6} = {3 ** 6 // 49} x 49 + {3 ** 6 % 49}, and {3 ** 6 % 49} = 1 + {(3 ** 6 % 49 - 1) // 7} x 7; 3 to the 42 on the 343-clock: {3 ** 42 % 343} = 1 + {(3 ** 42 % 343 - 1) // 49} x 49")
print(f"powers of 3 on the 7-clock: {[3 ** e % 7 for e in range(1, 7)]}; order of 3 on the {sizes} clocks: {[order(3, n) for n in sizes]}, phi {[phi(n) for n in sizes]}")
print(f"order of 10 on the 7, 49, 343 clocks: {[order(10, n) for n in (7, 49, 343)]}")
print(f"lifts of 3 that fail on the 49-clock: {bad}, order {order(bad[0], 49)}; {bad[0]} + 7 has order {order(bad[0] + 7, 49)}")
print(f"8-clock: 1, 9, 25, 49 leave {[x * x % 8 for x in (1, 3, 5, 7)]}; best order on {twos}: {[best(n) for n in twos]}, phi {[phi(n) for n in twos]}")
print(f"15-clock: fourth powers of {units15} leave {[x ** 4 % 15 for x in units15]}; best order {best(15)}, phi {phi(15)}")
print(f"clocks 2 to 30 with a primitive root: {[n for n in range(2, 31) if best(n) == phi(n)]}; to 100, Gauss agrees on {agree} of 99")
print(f"mistakes: {bad[0]} on the 49-clock, order {order(bad[0], 49)}; 52 on the 98-clock, order {order(52, 98) or 'none'}; best on the 8-clock {best(8)}")
assert bad == [31] and order(38, 49) == 42
assert [order(3, n) for n in sizes] == [phi(n) for n in sizes] == [6, 42, 294, 2058, 42] and agree == 99
assert all(x ** 4 % 15 == 1 for x in units15) and [best(n) for n in twos] == [n // 4 for n in twos]
print("ALL CHECKS PASS")
