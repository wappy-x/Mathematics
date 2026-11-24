# Binary quadratic forms of discriminant -20 -- the check behind the card.  Nothing is imported.
FORMS, D, TOP = [(1, 0, 5), (2, 2, 3)], -20, 100     # (a, b, c) stands for a x^2 + b xy + c y^2
def f(F, x, y): return F[0] * x * x + F[1] * x * y + F[2] * y * y
def disc(F): return F[1] * F[1] - 4 * F[0] * F[2]
def gcd(x, y): return gcd(y, x % y) if y else abs(x)
def reach(F, n):                                     # road 1: search coprime x, y with f(x, y) = n
    return any(f(F, x, y) == n and gcd(x, y) == 1 for x in range(-11, 12) for y in range(-11, 12))
def roots(n): return [b for b in range(2 * n) if (b * b - D) % (4 * n) == 0]   # road 2: D = b^2 mod 4n
print("discriminants:", *[disc(F) for F in FORMS])
for F in FORMS: print(f"{F} reaches, up to 30:", *[n for n in range(1, 31) if reach(F, n)])
p, q = 3, 2                                          # 29 = 3^2 + 5 x 2^2
r, s = next((r, s) for r in range(6) for s in range(6) if p * s - q * r == 1)
A, C = f(FORMS[0], p, q), f(FORMS[0], r, s)
B = f(FORMS[0], p + r, q + s) - A - C                # the new form at X = Y = 1 is A + B + C
print(f"{A} = f({p}, {q}); r, s = {r}, {s}; new form {(A, B, C)}, discriminant {disc((A, B, C))};",
      f"{B}^2 + 20 = {B * B + 20} = {(B * B + 20) // (4 * A)} x {4 * A}")
b = [b for b in roots(23) if b % 2 == 0][0]
print(f"23: b = {b}, form {(23, b, (b * b - D) // 92)}, discriminant {disc((23, b, (b * b - D) // 92))}")
primes = [n for n in range(3, TOP) if n != 5 and all(n % k for k in range(2, n))]
byF = [[n for n in primes if reach(F, n)] for F in FORMS]
none = [n for n in primes if not roots(n)]
for name, L in [("first form", byF[0]), ("second form", byF[1]), ("neither", none)]:
    print(f"primes below {TOP}, {name}:", *L, "| mod 20:", *sorted({n % 20 for n in L}))
print("mistakes: middle read as 1 gives", 1 - 4 * 2 * 3, "| 4 tested mod 4 has roots",
      *[b for b in range(4) if (b * b - D) % 4 == 0], "| x^2 + 5y^2 alone misses", len(byF[1]), "primes")
assert all(any(reach(F, n) for F in FORMS) == bool(roots(n)) for n in range(1, TOP))
assert A == 29 and disc((A, B, C)) == D and (B * B - D) % (4 * A) == 0 and (r, s) == (1, 1)
assert sorted({n % 20 for n in byF[0]}) == [1, 9] and sorted({n % 20 for n in byF[1]}) == [3, 7]
assert sorted(byF[0] + byF[1] + none) == primes and not roots(4) and not any(reach(F, 4) for F in FORMS)
print("ALL CHECKS PASS")
