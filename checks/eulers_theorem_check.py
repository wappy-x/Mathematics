# Euler's theorem -- the check behind the card.  Nothing is imported.  The last
# two digits of 3 to the 2026 on the 100-clock: phi(100) = 40, 2026 = 50 x 40 + 26.
def gcd(a, b): return a if b == 0 else gcd(b, a % b)       # Euclid, the largest common divisor
def product(xs, n):                 # multiply a list together on the n-clock
    p = 1
    for x in xs: p = p * x % n
    return p
def power_mod(base, e, n): return product([base] * e, n)   # ground out, no shortcuts
def row(name, value): print(f"{name:<36}{value:>6}")
n, a, big = 100, 3, 2026
units = [u for u in range(1, n) if gcd(u, n) == 1]         # the coprime residues
phi = len(units)
phi_factored = n // 2 * (2 - 1) // 5 * (5 - 1)             # half of 100, then four fifths
shuffled = sorted(a * u % n for u in units)
q, rem = divmod(big, phi)
row("gcd(3, 100)", gcd(a, n))
row("phi(100), counted one by one", phi)
row("phi(100), from 100 = 2 x 2 x 5 x 5", phi_factored)
row("3 to the 40 (mod 100)", power_mod(a, phi, n))
print(f"the same 40 come back, in a different order: {sum(1 for i in range(phi) if shuffled[i] == units[i])} of {phi} once sorted; multiplied, {product(units, n)} before and {product(shuffled, n)} after")
print(f"{big} = {q} x {phi} + {rem}")
row("3 to the 26 (mod 100), the shortcut", power_mod(a, rem, n))
row("3 to the 2026 (mod 100), ground out", power_mod(a, big, n))
print(f"the mistakes: 10 to the {phi} gives {power_mod(10, phi, n)}, 2 to the {phi} gives {power_mod(2, phi, n)}, 3 to the {n - 1} gives {power_mod(a, n - 1, n)}, 3 to the {q} gives {power_mod(a, q, n)}")
print(f"the wrong cut hides here but shows on the 7-clock: 3 to the 10 is {power_mod(a, 10 % 6, 7)} cut by 6, {power_mod(a, 10 % 7, 7)} cut by 7")
assert gcd(a, n) == 1 and phi == 40 and phi_factored == 40
assert shuffled == units and product(units, n) == product(shuffled, n) and power_mod(a, phi, n) == 1
assert power_mod(a, big, n) == 29 and power_mod(a, rem, n) == 29
assert power_mod(a, 10 % 6, 7) == power_mod(a, 10, 7) != power_mod(a, 10 % 7, 7)
print("ALL CHECKS PASS")
