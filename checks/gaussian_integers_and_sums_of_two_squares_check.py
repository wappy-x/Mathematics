# Gaussian integers -- the check behind the card.  Nothing is imported.  The
# pair (a, b) stands for a + bi, where i times i is -1.  Road one factors a whole
# number and applies the exponent rule for primes leaving remainder 3 on division
# by 4.  Road two searches every pair of squares, and the roads are compared for
# every whole number from 1 to 400.
LIMIT, CASES = 400, [5, 13, 21, 45, 65]
def mul(z, w):                                  # (a+bi)(c+di), i times i = -1
    return z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0]
def conj(z): return (z[0], -z[1])               # the mirror image: flip b
def norm(z): return z[0] * z[0] + z[1] * z[1]   # the norm a*a + b*b
def quotient(z, w): return mul(z, conj(w)), norm(w)   # numerators, divisor
def divides(w, z):                              # exact division on the grid
    (across, up), den = quotient(z, w)
    return den != 0 and across % den == 0 and up % den == 0
def primes_in(n):                               # trial division: prime, power
    out, p = [], 2
    while p * p <= n:
        e = 0
        while n % p == 0: n //= p; e += 1
        if e: out.append((p, e))
        p += 1
    if n > 1: out.append((n, 1))
    return out
def rule(n):                                    # road one: the exponent rule
    return all(p % 4 != 3 or e % 2 == 0 for p, e in primes_in(n))
def pairs(n):                                   # road two: search the squares
    top = 0
    while (top + 1) * (top + 1) <= n: top += 1
    return [(a, b) for a in range(top + 1) for b in range(a, top + 1) if a * a + b * b == n]

Z, W = (2, 1), (3, 2)                           # the points 2 + i and 3 + 2i
five, thirteen, prod = mul(Z, conj(Z)), mul(W, conj(W)), mul(Z, W)
units = [(a, b) for a in (-1, 0, 1) for b in (-1, 0, 1) if norm((a, b)) == 1]
exact, off = quotient((5, 0), Z), quotient(Z, conj(Z))
agree = sum(1 for n in range(1, LIMIT + 1) if rule(n) == bool(pairs(n)))

print("the pair (a, b) means a + bi, i times i = -1; the grid holds the norm a*a + b*b, columns a = 0 to 4")
for b in (3, 2, 1, 0): print(f"b = {b} |" + "".join(f"{a * a + b * b:>4}" for a in range(5)))
print(f"(2 + i) + (3 + 2i) = {Z[0] + W[0]} + {Z[1] + W[1]}i")
print(f"(2 + i)(2 - i) = {five[0]} + {five[1]}i, factor norms {norm(Z)} and "
      f"{norm(conj(Z))}, and the norm of 5 + 0i is {norm((5, 0))}")
print(f"(3 + 2i)(3 - 2i) = {thirteen[0]} + {thirteen[1]}i, factor norms {norm(W)} and {norm(conj(W))}")
print(f"(2 + i)(3 + 2i) = {prod[0]} + {prod[1]}i, norm {norm(prod)} = "
      f"{norm(Z)} x {norm(W)}, and 4*4 + 7*7 = {prod[0] ** 2 + prod[1] ** 2}")
print(f"the grid points of norm 1, the units, are {units}: -1, -i, i and 1")
print(f"5 over (2 + i): numerators {exact[0]} over {exact[1]}, quotient "
      f"({exact[0][0] // exact[1]}, {exact[0][1] // exact[1]}), on the grid")
print(f"(2 + i) over (2 - i): numerators {off[0]} over {off[1]}, off the grid, "
      f"norm ratio {norm(Z) // norm(conj(Z))}")
for n in CASES:
    got, ps = pairs(n), " ".join(f"{p}^{e}" for p, e in primes_in(n))
    shown = " ".join(f"({a}, {b})" for a, b in got) if got else "none"
    print(f"n = {n}: primes {ps}, rule says {'yes' if rule(n) else 'no'}, pairs {shown}")
print(f"rule and square-search agree for every n from 1 to {LIMIT}: {agree} of {LIMIT}")
print(f"with i times i = +1, (2 + i)(2 - i) would be {2 * 2 - 1 * 1}, not {five[0]}; and 21 mod 4 = {21 % 4}")
assert five == (5, 0) and thirteen == (13, 0) and units == [(-1, 0), (0, -1), (0, 1), (1, 0)]
assert norm(prod) == norm(Z) * norm(W) and prod == (4, 7)
assert agree == LIMIT and pairs(5) == [(1, 2)] and pairs(21) == []
assert exact == ((10, -5), 5) and off == ((3, 4), 5) and not divides(conj(Z), Z) and divides(Z, (5, 0))
print("ALL CHECKS PASS")
