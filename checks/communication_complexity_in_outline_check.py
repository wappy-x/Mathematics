# Communication complexity -- the check behind the card.  Standard library only.
# Two warehouses, Leeds (list x) and Bristol (list y), each mark 1,000 product
# codes in stock (1) or out (0), and ask whether the two lists match: EQUALITY.
# Roads: an exhaustive search for the best protocol against the fooling-set
# bound; a fingerprint's error counted prime by prime, simulated, and bounded.
import math

def ceil_log2(m):                    # fewest bits to give m outcomes distinct names
    return (m - 1).bit_length()

def popcount(v):
    return bin(v).count("1")

def best_protocol_bits(n):           # exhaustive search over every protocol for EQUALITY on n bits
    size = 1 << (1 << n)             # rectangles: a set of Leeds rows times a set of Bristol columns
    D = [0] * (size * size)
    for r in range(size):
        for c in range(size):
            ones, cells = popcount(r & c), popcount(r) * popcount(c)
            if ones == 0 or ones == cells:
                continue                       # one answer fills it: no more bits needed
            best = 99
            s = (r - 1) & r                    # Leeds splits its rows in two: one bit sent
            while s:
                best = min(best, 1 + max(D[s * size + c], D[(r ^ s) * size + c]))
                s = (s - 1) & r
            s = (c - 1) & c                    # or Bristol splits its columns in two
            while s:
                best = min(best, 1 + max(D[r * size + s], D[r * size + (c ^ s)]))
                s = (s - 1) & c
            D[r * size + c] = best
    return D[size * size - 1]

def sieve(limit):
    flag = bytearray([1]) * limit
    flag[0:2] = b"\x00\x00"
    for i in range(2, int(limit ** 0.5) + 1):
        if flag[i]:
            flag[i * i::i] = bytearray(len(range(i * i, limit, i)))
    return [i for i in range(limit) if flag[i]]

def stream_mod(bits, p):             # one pass over the list, keeping only a remainder
    r = 0
    for b in bits:
        r = (2 * r + b) % p
    return r

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & (2**64 - 1)
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
        return z ^ (z >> 31)

print("== deterministic: exhaustive search against the fooling-set bound ==")
for n in (1, 2, 3):
    found, bound = best_protocol_bits(n), ceil_log2(2**n + 1)
    print(f"n = {n}: best protocol {found} bits; fooling-set bound {bound}; send-the-list protocol {n + 1}")
    assert found == bound == n + 1
print("n = 2 send-the-list transcripts (row x = Leeds, column y = Bristol):")
for x in range(4):
    print(f"  x = {x:02b}: " + "  ".join(f"{x:02b}|{int(x == y)}" for y in range(4)))

print("== the warehouses: n = 1000 product codes ==")
n, LIMIT, TRIALS = 1000, 10**6, 200000
primes = sieve(LIMIT)
pbits = ceil_log2(LIMIT)
print(f"send the whole list, plus the answer: {n + 1} bits")
print(f"primes below {LIMIT}: {len(primes)}; bits to name one: {pbits}")
print(f"fingerprint: prime {pbits} + remainder {pbits} + answer 1 = {2 * pbits + 1} bits")
d, k = 1, 0
while d * primes[k] < 2**n:          # the worst difference: as many small primes as fit below 2^n
    d, k = d * primes[k], k + 1
g = SplitMix64(2026)
y = sum(g.next() << (64 * i) for i in range(16)) % 2**998   # so x = y + d stays below 2^1000
x = y + d
xb = [(x >> (n - 1 - i)) & 1 for i in range(n)]
fool = sum(1 for p in primes if (x - y) % p == 0)
print(f"worst lists: x - y = product of the first {k} primes, largest {primes[k - 1]}; times the next, {primes[k]}, it passes 2^{n}")
print(f"primes that fool the check, counted one by one: {fool}")
assert fool == k                                     # construction against count
assert sum(math.log2(p) for p in primes[:k]) < n <= sum(math.log2(p) for p in primes[:k + 1])  # and no gap has more
assert all(stream_mod(xb, p) == x % p for p in primes[-3:])  # one-pass remainder against division
hits = 0
for _ in range(TRIALS):
    p = primes[g.next() % len(primes)]
    hits += x % p == y % p
exact, bound = fool / len(primes), n / len(primes)
sd = math.sqrt(exact * (1 - exact) / TRIALS)
print(f"error: exact {exact:.6f}; simulated {hits / TRIALS:.6f} over {TRIALS} runs; bound n/pi {bound:.6f}")
assert abs(hits / TRIALS - exact) < 4 * sd and exact <= bound
assert len(primes) == 78498                          # the published count of primes below a million
one = y ^ (1 << 500)                 # an easy case: one product's line flipped
print(f"one line differs: primes that fool the check {sum(1 for p in primes if (one - y) % p == 0)}")
print("== growth: bits to settle EQUALITY ==")
for e in (3, 6, 9):
    m = 10**e
    b = ceil_log2(m * m)
    print(f"n = 10^{e}: whole list {m + 1}; fingerprint {2 * b + 1}; error at most 1 in {round(m / math.log(m * m))}")

print("== memory: a one-pass checker needs n bits ==")
small, keep = 10, 9                  # a checker that keeps only the low 9 bits of Leeds's list
seen = {}
for lst in range(2**small):
    st = lst % 2**keep
    if st in seen:
        a, b = seen[st], lst
        break
    seen[st] = lst
print(f"{keep}-bit memory, {small}-bit lists: {2**small} lists, {2**keep} states; "
      f"{a:0{small}b} and {b:0{small}b} share state {a % 2**keep}")
bits = lambda v: [(v >> (small - 1 - i)) & 1 for i in range(small)]
said = stream_mod(bits(b), 2**keep) == stream_mod(bits(a), 2**keep)   # the 9-bit checker, run bit by bit
print(f"stream {b:0{small}b} then {a:0{small}b}: checker says {'match' if said else 'no match'}, lists differ")
assert said

print("== what breaks ==")
print(f"counting only Leeds's message, n = 2: {ceil_log2(2**2)} bits, but the search finds {best_protocol_bits(2)}")
q = primes[-1]
print(f"fixed prime {q}, lists differing by {q}: remainders {x % q} and {(x - q) % q}: fooled every run")
d25 = 1
for p in primes[:25]:
    d25 *= p
print(f"primes below 100 only: {sum(1 for p in primes[:25] if d25 % p == 0)} of 25 fool the check, error 1")
print("ALL CHECKS PASS")
