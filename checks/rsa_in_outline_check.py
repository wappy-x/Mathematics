# RSA in outline -- the check behind the card.  Nothing is imported.  Two secret primes,
# 61 and 53, make the public clock size 3233.  The message 65 locks with the public
# exponent 17 and unlocks with the private one, 2753.
P, Q, E, MSG = 61, 53, 17, 65
def power(base, times, clock):          # square and multiply, remainder kept small
    out = 1
    while times:
        if times & 1: out = out * base % clock
        base, times = base * base % clock, times >> 1
    return out
def row(name, value): print(f"{name:<42}{value:>6}")
n, phi = P * Q, (P - 1) * (Q - 1)
count = sum(1 for k in range(1, n + 1) if k % P and k % Q)  # the same count, one at a time
d, slow = next(k for k in range(1, phi) if E * k % phi == 1), 1   # by search, not by Euclid
for _ in range(E): slow = slow * MSG % n                    # the plain way: 1 times 65, 17 times
c = power(MSG, E, n)
row("clock size, 61 x 53", n)
row("how many share no factor, 60 x 52", phi)
row("private exponent, 17 undone on 3120", d)
print(f"17 x {d} = {E * d} = {E * d // phi} x {phi} + {E * d % phi}")
row("lock: 65 to the 17th, 3233s off", c)
row("unlock: 2790 to the 2753rd, 3233s off", power(c, d, n))
row("65 to the 3120th, 3233s off", power(MSG, phi, n))
row("65 to the 46801st, 3233s off", power(MSG, E * d, n))
bad = next(k for k in range(1, n) if E * k % n == 1)        # a d built on 3233, not 3120
print(f"unlocked with 17: {power(c, E, n)}; with a d built on {n}: {power(c, bad, n)}; {MSG + n} comes back as {power(power(MSG + n, E, n), d, n)}")
assert n == 3233 and phi == count == 3120 and n - P - Q + 1 == phi
assert d == 2753 and E * d == 15 * phi + 1 and c == slow == 2790
assert power(c, d, n) == MSG and power(MSG, phi, n) == 1
print("ALL CHECKS PASS")
