# Euler's totient -- the check behind the card.  Nothing is imported.  The musical clock: 12 semitones
# to an octave.  Road one walks each jump size round the N notes; road two reads phi(N) off the primes.
N = 12
gcd = lambda a, b: a if b == 0 else gcd(b, a % b)
def walk(jump, n):                  # the notes one jump size actually visits
    seen, k = [], 0
    while k not in seen: seen.append(k); k = (k + jump) % n
    return seen
primes_of = lambda n: [p for p in range(2, n + 1) if n % p == 0 and all(p % q != 0 for q in range(2, p))]
by_counting = lambda n: sum(1 for k in range(1, n + 1) if gcd(k, n) == 1)   # the definition
def cull(n, ps):                    # start at n; for each p on the list, throw away one in every p
    out = n
    for p in ps: out = out // p * (p - 1)
    return out
by_primes = lambda n: cull(n, primes_of(n))     # one bracket per distinct prime -- the formula
tours, coprime = [j for j in range(1, N + 1) if len(walk(j, N)) == N], [k for k in range(1, N + 1) if gcd(k, N) == 1]
same, brackets = sum(1 for n in range(1, 61) if by_counting(n) == by_primes(n)), " x ".join(f"(1 - 1/{p})" for p in primes_of(N))
per_copy, stop_early = cull(N, [2, 2, 3]), cull(N, [2])   # the same culling, run wrong: a bracket per copy; only the first prime
print("jump by 7 from C: " + " ".join(str(k) for k in walk(7, N)) + ", back to 0")
print(f"notes visited, jumps 1 to {N}: " + " ".join(str(len(walk(j, N))) for j in range(1, N + 1)))
print(f"{'jumps that tour all ' + str(N) + ' notes':<41}{str(tours):>14}")
print(f"{'numbers 1 to ' + str(N) + ' sharing no factor with ' + str(N):<41}{str(coprime):>14}")
print(f"phi({N}) by counting the survivors: {by_counting(N)};  by the primes, {N} x {brackets}: {by_primes(N)}")
print(f"by coprime parts: phi(4) x phi(3) = {by_primes(4)} x {by_primes(3)} = {by_primes(4) * by_primes(3)};  a prime clock: phi(7) = 7 - 1 = {by_primes(7)}")
print(f"the two roads agree for {same} of the 60 clock sizes from 1 to 60")
print(f"the three mistakes come out at {N - 1}, {per_copy} and {stop_early}")
assert coprime == [1, 5, 7, 11] and tours == coprime and by_counting(N) == 4
assert by_primes(N) == 4 and by_primes(4) * by_primes(3) == 4 and by_primes(7) == 6
assert same == 60 and by_counting(1) == 1 and (N - 1, per_copy, stop_early) == (11, 2, 6)
print("ALL CHECKS PASS")
