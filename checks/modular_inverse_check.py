# The modular inverse -- the check behind the card.  Nothing is imported.  A cipher
# on 26 letters multiplies each letter's number by the key 7.  Road one: Euclid.
KEY, N, LETTERS = 7, 26, "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
def listing_gcd(a, b):                 # independent of Euclid: list the divisors
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)
chain, g, b = [], N, KEY
while b:                               # divide, keep the remainder, go again
    chain.append((g, g // b, b, g % b))
    g, b = b, g % b                    # g ends as the gcd
print(f"{f'gcd({KEY}, {N}), by listing divisors':<44}{listing_gcd(KEY, N):>3}")
print("Euclid down: " + ", ".join(f"{u} = {q} x {v} + {r}" for (u, q, v, r) in chain[:-1]))
p, s = 1, -chain[-2][1]                # the last useful line: 1 = 5 - 2 x 2
for (u, q, v, r) in reversed(chain[:-2]):
    p, s = s, p - s * q                # swap in the line above it
print(f"Euclid back up: {KEY} x {s} + {N} x {p} = {KEY * s} + {N * p} = {KEY * s + N * p}")
inv = s % N
print(f"inverse of {KEY} on {N} letters: {s} + {N} = {inv}")
print(f"{KEY} x {inv} = {KEY * inv} = {KEY * inv // N} x {N} + {KEY * inv % N}")
brute, lands = [k for k in range(N) if KEY * k % N == 1], sorted({13 * k % N for k in range(N)})
print(f"by search, the only k in 0 to 25 with {KEY} x k = 1: {brute[0]}")
for i in (7, 8):
    e = i * KEY % N
    print(f"{LETTERS[i]} is {i}: {i} x {KEY} = {i * KEY} = {e}, that is {LETTERS[e]}; {e} x {inv} = {e * inv} = {e * inv % N}, back to {LETTERS[e * inv % N]}")
print(f"key 13: gcd(13, {N}) = {listing_gcd(13, N)}, and 13 x k lands only on {lands[0]} or {lands[1]}")
print(f"key 13: H is 7 and J is 9, both land on {13 * 7 % N}, that is {LETTERS[13 * 7 % N]}")
print(f"the three mistakes come out at {23 * KEY % N}, {23 * 3 % N} and {23 * 13 % N}")
assert g == 1 and g == listing_gcd(KEY, N) and KEY * inv == 4 * N + 1
assert inv == 15 and brute == [inv] and 7 * KEY % N == 23 and 23 * inv % N == 7
assert lands == [0, 13] and listing_gcd(13, N) == 13 and 1 not in lands
print("ALL CHECKS PASS")
