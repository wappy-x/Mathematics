# Square roots on a prime clock -- the check behind the card.  Nothing is imported.  Mod 23 the
# (p+1)/4 shortcut; mod 41 Tonelli-Shanks with the non-square 3; mod 77 four roots give a factor.
def roots(a, n): return [x for x in range(n) if x * x % n == a % n]   # brute force: try them all
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def tonelli(a, p, z, log=False):                  # z must be a non-square on the p clock
    s, t = 0, p - 1
    while t % 2 == 0: s, t = s + 1, t // 2        # p - 1 = 2^s x t, t odd
    x, err, fix = pow(a, (t + 1) // 2, p), pow(a, t, p), pow(z, t, p)   # x * x = a * err
    if log: print(f"mod {p}, a = {a}: {p - 1} = 2^{s} x {t}; first guess {a}^{(t + 1) // 2} = {x}, error {a}^{t} = {err}, fix {z}^{t} = {fix}")
    while err != 1:
        i, e = 0, err
        while e != 1: e, i = e * e % p, i + 1     # the error has order 2^i
        f = pow(fix, 2 ** (s - i - 1), p)         # a power of the fix with order 2^(i+1)
        x, err, fix, s = x * f % p, err * f * f % p, f * f % p, i
        if log: print(f"  error had order 2^{i}: multiply by {f} -> x = {x}, error now {err}")
    return x
r, c = pow(2, (23 + 1) // 4, 23), 4 ** 3 + 7     # c: y^2 on the curve y^2 = x^3 + 7 at x = 4
print(f"curve y^2 = x^3 + 7 at x = 4: y^2 = {c} = {c // 23} x 23 + {c % 23} on the 23 clock; Bitcoin's prime 2^256 - 2^32 - 977 leaves {(2 ** 256 - 2 ** 32 - 977) % 4} on division by 4")
print(f"mod 23 (23 % 4 = {23 % 4}): (23 + 1)/4 = {(23 + 1) // 4}; 2^6 = {2 ** 6} = {2 ** 6 // 23} x 23 + {r}; {r}^2 = {r * r} = {r * r // 23} x 23 + {r * r % 23}; other root {23 - r}; 2^11 = {pow(2, 11, 23)}")
print(f"mod 41 (41 % 4 = {41 % 4}): 3^20 = {pow(3, 20, 41)}, so 3 is a non-square; 2^20 = {pow(2, 20, 41)}, so 2 is a square; 10^10 = {pow(10, 10, 41)}; squares 32 -> {32 * 32 % 41}, 38 -> {38 * 38 % 41} -> {pow(38, 4, 41)} -> {pow(38, 8, 41)}, 40 -> {40 * 40 % 41}")
x10, x2, four = tonelli(10, 41, 3, True), tonelli(2, 41, 3, True), roots(4, 77)
print(f"roots of 10 mod 41: {x10} and {41 - x10}; {x10}^2 = {x10 * x10} = {x10 * x10 // 41} x 41 + {x10 * x10 % 41}; roots of 2: {x2} and {41 - x2}")
print(f"brute force: mod 23 roots of 2 {roots(2, 23)}, of 5 {roots(5, 23)}; mod 41 roots of 10 {roots(10, 41)}, of 2 {roots(2, 41)}")
print(f"mod 77 = 7 x 11, the roots of 4: {four}; gcd(root - 2, 77) for each: {[gcd(y - 2, 77) for y in four]}; gcd(9 + 2, 77) = {gcd(9 + 2, 77)}")
sq23, sq41 = sorted({x * x % 23 for x in range(1, 23)}), sorted({x * x % 41 for x in range(1, 41)})
print(f"every square checked against brute force: {len(sq23)} on the 23 clock, {len(sq41)} on the 41 clock")
assert r == 18 and roots(2, 23) == [5, 18] and roots(5, 23) == [] and all(pow(a, 6, 23) in roots(a, 23) for a in sq23)
assert x10 == 16 and x2 == 17 and all(tonelli(a, 41, 3) in roots(a, 41) for a in sq41)
assert four == [2, 9, 68, 75] and [gcd(y - 2, 77) for y in four] == [77, 7, 11, 1] and pow(10, 10, 41) not in roots(10, 41)
print("ALL CHECKS PASS")
