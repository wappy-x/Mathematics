# Solving 6x = 4 (mod 10) -- the check behind the card.  Nothing is imported.
# A 10-position dial, 6 places per click.  Road one: try all ten step counts.
# Road two: the gcd rule -- shrink the clock, undo the step, unfold.
A, B, N = 6, 4, 10

def plain_gcd(a, b):              # list the divisors; no algorithm assumed
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)

def brute(a, b, n):               # road one: every step count on the dial
    return [x for x in range(n) if (a * x) % n == b % n]

g = plain_gcd(A, N)
orbit = [(A * x) % N for x in range(N)]
print(f"where the dial sits after 0..{N - 1} clicks: " + " ".join(str(p) for p in orbit))
print(f"{f'gcd({A}, {N})':<34}{g:>4}")
print(f"{'answers by trying every click':<34}{str(brute(A, B, N)):>8}")
a2, b2, n2 = A // g, B // g, N // g          # road two: shrink the whole line by 2
inv = next(t for t in range(n2) if (a2 * t) % n2 == 1)
first = (inv * b2) % n2
found = [first + n2 * k for k in range(g)]
print(f"shrunk to {a2}x = {b2} (mod {n2}); undo the {a2} with {inv}; x = {first} (mod {n2})")
print(f"{'unfolded, in steps of ' + str(n2):<34}{str(found):>8}")
print(";  ".join(f"{A} x {x} = {A * x} = {A * x // N} x {N} + {A * x % N}" for x in found))
print("as whole numbers: " + ", ".join(f"{A} x {x} + {N} x {(B - A * x) // N} = {B}" for x in found))
print(f"aiming at 3: {len(brute(A, 3, N))} answers; shrinking {A} and {B} but not the {N}: {brute(a2, b2, N)}")
assert g == 2 and found == brute(A, B, N) == [4, 9] and len(found) == g
assert (A * 4) % N == B and A * 4 + N * -2 == B and A * 9 + N * -5 == B
assert brute(A, 3, N) == [] and brute(a2, b2, N) == [4] and N // g == 5
print("ALL CHECKS PASS")
