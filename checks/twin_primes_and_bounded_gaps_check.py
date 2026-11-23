# Twin primes and bounded gaps -- the check behind the card.  Standard library only.
# Road 1: a sieve of Eratosthenes counts twin pairs below a million; a segmented sieve counts
# them near a billion and is tested against the plain sieve; trial division checks the example.
# Road 2: the Hardy-Littlewood prediction, as an integral by Simpson's rule and as a direct sum.
# Road 3: the twin constant, as a product over primes and from counted remainders.
from math import log, exp
L = 1_000_010
s = bytearray([1]) * (L + 1); s[0] = s[1] = 0
for i in range(2, int(L ** 0.5) + 1):
    if s[i]: s[i * i::i] = bytearray(len(s[i * i::i]))
ps = [p for p in range(2, 1_000_000) if s[p]]
cum, c = [0] * (L + 1), 0                     # cum[x] = twin pairs p, p + 2 with p <= x
for x in range(L + 1):
    if x + 2 <= L and s[x] and s[x + 2]: c += 1
    cum[x] = c
gap, at = max((q - p, p) for p, q in zip(ps, ps[1:]))
print(f"primes below 1,000,000: {len(ps)}; twin pairs p, p+2 with p <= 1,000,000: {cum[10**6]}")
print(f"widest gap below 1,000,000: {gap}, after {at}")
def segment(a, w):                             # primality flags for a, a+1, ..., a+w+1
    seg = bytearray([1]) * (w + 2)
    for p in range(2, int((a + w + 2) ** 0.5) + 1):
        if s[p]:
            st = max(p * p, (a + p - 1) // p * p)
            seg[st - a::p] = bytearray(len(seg[st - a::p]))
    for k in range(max(0, 2 - a)): seg[k] = 0
    return seg
low = segment(0, 1_000_000)
assert sum(1 for i in range(1_000_001) if low[i] and low[i + 2]) == cum[10**6]
print(f"segmented sieve on 0..1,000,000 agrees with the plain sieve: {cum[10**6]} twin pairs")
def by_division(n):
    d = 2
    while d * d <= n and n % d: d += 1
    return d * d > n
A, W = 10**9, 10**6
seg = segment(A, W)
first = next(A + i for i in range(W) if seg[i] and seg[i + 2])
tw = sum(1 for i in range(W) if seg[i] and seg[i + 2]); pr = sum(seg[:W])
print(f"first twin pair from 1,000,000,000 up: {first}, {first + 2}")
print(f"trial division: {first} prime {by_division(first)}, {first + 2} prime {by_division(first + 2)}")
print(f"window 1,000,000,000 to 1,000,999,999: {pr} primes, {tw} twin pairs, mean spacing {W / pr:.2f}")
C2 = 1.0
for p in ps[1:]: C2 *= 1 - 1 / (p - 1) ** 2
print(f"C2 = product over odd primes below 1,000,000 of 1 - 1/(p-1)^2 = {C2:.6f}; 2 C2 = {2 * C2:.6f}")
print("local factor: p, both-coprime share counted, independent share, ratio, formula")
for p in (2, 3, 5, 7, 11):
    both = sum(1 for r in range(p) if r % p and (r + 2) % p)
    cnt, ind = both / p, (1 - 1 / p) ** 2
    form = 2.0 if p == 2 else 1 - 1 / (p - 1) ** 2
    print(f"  p = {p}: {both}/{p} = {cnt:.6f}, {ind:.6f}, {cnt / ind:.6f}, {form:.6f}")
    assert abs(cnt / ind - form) < 1e-12
def li2(a, b, n=20000):                       # integral of dt / (log t)^2, Simpson in u = log t
    u0, h = log(a), (log(b) - log(a)) / n
    f = lambda u: exp(u) / (u * u)
    return h / 3 * (f(u0) + f(u0 + n * h) + sum((4 if k % 2 else 2) * f(u0 + k * h) for k in range(1, n)))
direct, tot, nxt = {}, 0.0, 10**3
for n in range(3, 10**6 + 1):
    tot += 2 * C2 / log(n) ** 2
    if n == nxt: direct[n] = tot; nxt *= 10
print("x, twin pairs counted, 2 C2 Li2(x), direct sum, counted / predicted")
for x in (10**3, 10**4, 10**5, 10**6):
    hl = 2 * C2 * li2(2, x)
    print(f"  {x}: {cum[x]}, {hl:.1f}, {direct[x]:.1f}, {cum[x] / hl:.4f}")
    assert abs(hl - direct[x]) < 1.2 and abs(cum[x] / hl - 1) < 0.25
xs = list(range(100_000, 1_000_001, 100_000))
print("chart x (thousands):", [x // 1000 for x in xs])
print("chart counted:", [cum[x] for x in xs])
print("chart Hardy-Littlewood:", [round(2 * C2 * li2(2, x)) for x in xs])
print("chart no correction:", [round(li2(2, x)) for x in xs])
lA = log(A)
print(f"by hand near 10^9: log = {lA:.4f}, log^2 = {lA * lA:.2f}, 1/log^2 = {1 / lA ** 2:.7f}")
print(f"by hand: x 2 = {2 / lA ** 2:.7f}, x C2 = {2 * C2 / lA ** 2:.7f} = 1 in {lA ** 2 / (2 * C2):.1f}")
hand, simp = 2 * C2 * W / lA ** 2, 2 * C2 * li2(A, A + W)
print(f"window prediction: by hand {hand:.0f}, by Simpson {simp:.0f}; counted {tw}; counted / predicted {tw / simp:.4f}")
assert abs(hand - simp) < 1 and abs(tw / simp - 1) < 0.05
naive, two, crude = li2(2, 10**6), 2 * li2(2, 10**6), 2 * C2 * 10**6 / log(10**6) ** 2
trip_naive = sum(1 / log(n) ** 3 for n in range(3, 10**6 + 1))
trip = sum(1 for p in ps if s[p + 2] and s[p + 4])
print(f"mistakes below 10^6: no correction {naive:.0f}; factor 2 only {two:.0f}; x/(log x)^2 {crude:.0f}")
print(f"triples n, n+2, n+4 all prime below 10^6: coin model {trip_naive:.0f}, counted {trip}")
cousins, sexy = (sum(1 for p in ps if s[p + h]) for h in (4, 6))
print(f"pairs p, p+4 below 10^6: {cousins}; p, p+6: {sexy}; prediction for gap 6 is twice the twin one: {2 * 2 * C2 * li2(2, 10**6):.0f}")
gaps = [q - p for p, q in zip(ps, ps[1:])]
ladder = [sum(1 for g in gaps if g == 2)] + [sum(1 for g in gaps if g <= b) for b in (6, 12, 246)]
print("consecutive gaps below 10^6 equal to 2, at most 6, 12, 246:", ladder, "of", len(gaps))
assert ladder[0] == cum[10**6] and ladder[3] == len(gaps)
def chen(p):                                   # p + 2 prime, or a product of exactly two primes
    m = p + 2
    if s[m]: return True
    d = 2
    while m % d: d += 1
    return s[m // d] == 1
ch = sum(1 for p in ps if chen(p))
print(f"primes p below 10^6 with p+2 prime or a product of two primes: {ch} (twins among them {cum[10**6]})")
print("quoted, not computed: gap 70,000,000 (2013), 600 (2013), 246 (2014); 12 on EH, 6 on GEH")
assert len(ps) == 78498 and cum[10**6] == 8169 and (gap, at) == (114, 492113)
assert first == 1_000_000_007 and by_division(first) and by_division(first + 2) and tw == 3037
assert abs(2 * C2 - 1.3203236316) < 1e-6 and trip == 1 and trip_naive > 100
assert cum[1000] == sum(1 for p in range(2, 1001) if by_division(p) and by_division(p + 2))
assert ch == 29949 and (cousins, sexy) == (8144, 16386)   # pin the counts printed above
print("ALL CHECKS PASS")
