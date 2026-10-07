# One-way streets -- the check behind the card.  Nothing is imported.  Two easy
# jobs: 1,009 x 1,013 on paper, and 11 raised to the 613 on a clock of 1,009.
# Then both jobs backwards, counting what the way back costs.
A, B, BASE, SECRET, CLOCK = 1009, 1013, 11, 613, 1009
def row(name, value):
    print(f"{name:<40}{value:>9}")
n = A * B
row("1,009 x 1,013, the easy way", n)
row("digit by digit, that is 4 x 4", 4 * 4)
primes = [i for i in range(2, 1011) if all(i % d for d in range(2, i))]  # up to the square root of n
tries = next(i for i, p in enumerate(primes) if n % p == 0)              # trial division, the slow road back
row("primes tried before 1,009 turns up", tries)
row("the check, going back: 1022117 / 1009", n // primes[tries])
fast, steps = 1, 0
for bit in bin(SECRET)[2:]:                     # square and multiply; the first squaring, of 1, is free
    fast, steps = fast * fast % CLOCK, steps + 1
    if bit == "1": fast, steps = fast * BASE % CLOCK, steps + 1
slow, back = 1, 0
while slow != fast:                             # walking, one multiply at a time
    slow, back = slow * BASE % CLOCK, back + 1
row("11 to the 613 on a clock of 1,009", fast)
row("squarings and multiplies that took", steps)
row("walking one multiply at a time, steps", back)
inv = next(k for k in range(CLOCK) if BASE * k % CLOCK == 1)
stop100 = sum(1 for p in primes if p < 100 and n % p == 0)   # trial division stopped at 100
print(f"the three mistakes come out at {stop100}, {4 * 4} and {fast * inv % CLOCK}")
assert n == 1022117 and primes[tries] == A and n // primes[tries] == B
assert tries == 168 and all(n % p for p in primes[:tries]) and inv == 367 and stop100 == 0
assert fast == 956 and slow == fast and back == SECRET and fast * inv % CLOCK == 729
print("ALL CHECKS PASS")
