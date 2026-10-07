# The sieve of Eratosthenes -- the check behind the card.  Nothing is imported.  100 lockers, all open.  Shut locker 1,
# keep 2 and slam every second locker after it, then 3, then 5, then 7.  Trial division is the second road to the 25.
TOP, divs = 100, []                                              # divs tallies trial division's work
def sieve(top, shut_prime=False, shut_one=True, last=99):        # the plain road: slam the multiples
    open_, passes = [False, not shut_one] + [True] * (top - 1), []
    for p in [q for q in range(2, top + 1) if q * q <= top and q <= last]:
        if open_[p]:
            hit = [k for k in range(p if shut_prime else p * p, top + 1, p) if open_[k]]   # start at p x p
            for k in hit: open_[k] = False
            passes.append((p, hit, sum(open_)))
    return [n for n in range(1, top + 1) if open_[n]], passes
def by_trial(n): return n > 1 and all(divs.append(1) or n % d for d in range(2, n) if d * d <= n)   # the second road
def open_count(ps): return sum(1 for n in range(2, TOP + 1) if n in ps or all(n % q for q in ps))
primes, passes = sieve(TOP)
for p, hit, still in passes:
    shown = " ".join(map(str, hit)) if len(hit) <= 6 else " ".join(map(str, hit[:3])) + " ... " + str(hit[-1])
    print(f"{p}'s pass slams {shown:<21} -- {len(hit):>2} lockers, {still} still open")
print(f"next open locker is 11, and 11 x 11 = {11 * 11} is past {TOP}, so the passes stop")
counts = [open_count(ps) for ps in ((2,), (2, 3), (2, 3, 5), (2, 3, 5, 7))]
print(f"lockers still open, before any pass and after each: {TOP - 1} " + " ".join(map(str, counts)))
print(f"the {len(primes)} open lockers: " + ", ".join(map(str, primes)))
trial, open5 = [n for n in range(1, TOP + 1) if by_trial(n)], sieve(TOP, last=5)[0]
print(f"trial division, one locker at a time, agrees: {len(trial)} primes, the same list, after {len(divs)} divisions")
print(f"stopping after 5's pass: {len(open5)} open, and {', '.join(str(n) for n in open5 if n not in primes)} are not prime")
print(f"slamming each prime along with its multiples: {len(sieve(TOP, shut_prime=True)[0])} open")
print(f"leaving locker 1 open: {len(sieve(TOP, shut_one=False)[0])} open")
assert primes == trial and len(primes) == 25 and primes[-1] == 97
assert [still for _, _, still in passes] == counts and counts == [50, 34, 28, 25]
assert len(open5) == 28 and 7 * 7 <= TOP < 11 * 11
print("ALL CHECKS PASS")
