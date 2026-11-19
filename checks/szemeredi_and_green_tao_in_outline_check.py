# Long progressions -- the check behind the card.  Standard library only.
# A progression is a, a+d, a+2d, ... with step d > 0.  The card's example is
# 5, 11, 17, 23, 29.  Road one tests primes by a sieve, road two by trial
# division.  The smallest prime progressions found by search must obey the
# mod-p rule proved on the card.  Small-set facts (van der Waerden, the largest
# set with no 3-term progression) are found by exhaustive search.  The rough
# number counts are made by a sieve and again by Legendre's formula.
from itertools import combinations
N = 10**6
sv = bytearray([1]) * (N + 1); sv[0] = sv[1] = 0
for i in range(2, 1001):
    if sv[i]:
        sv[i * i::i] = bytearray(len(range(i * i, N + 1, i)))
P = [i for i in range(N + 1) if sv[i]]
def trial(n):                                     # road two: trial division
    return n > 1 and all(n % q for q in range(2, int(n**0.5) + 1))
ex = [5 + 6 * i for i in range(5)]
print("example:", ex, "sieve", all(sv[n] for n in ex), "trial", all(trial(n) for n in ex))
print("residues mod 5:", [n % 5 for n in ex], "; next term 35 =", "5 x 7", "; term before -1")
print("primes between 5 and 29 that it skips:", [p for p in P if 5 < p < 29 and p not in ex])
assert all(sv[n] for n in ex) and all(trial(n) for n in ex) and not trial(35)
D6 = (6, 30)                                      # the two steps tried for six terms
six = [sum(1 for a in P if a + 5 * d <= N and all(sv[a + d * i] for i in range(6))) for d in D6]
print("6-term prime progressions up to 10^6:", " ; ".join(f"step {d}: {c:,}" for d, c in zip(D6, six)))
def smallest(k):                                  # smallest last term L
    for L in P:
        for d in range(1, (L - 2) // (k - 1) + 1):
            if all(sv[L - i * d] for i in range(k)):
                return L - (k - 1) * d, d, L
print("k | first term | step | last term | primes p <= k dividing step")
for k in range(3, 11):
    a, d, L = smallest(k)
    small = [p for p in P if p <= k]
    print(f"{k} | {a} | {d} | {L:,} | {[p for p in small if d % p == 0]}")
    for p in small:                               # mod-p rule: p | d, or p is a term
        assert d % p == 0 or (p - a) % d == 0 and a <= p <= L
    assert all(trial(a + i * d) for i in range(k))
M = 10**4
cnt = [0] * 9
for a in P:
    if a > M: break
    for d in range(1, (M - a) // 2 + 1):
        r = 1
        while r < 8 and a + r * d <= M and sv[a + r * d]: r += 1
        for k in range(3, r + 1): cnt[k] += 1
print(f"prime progressions with every term <= {M:,}: k=3..8:", [f"{c:,}" for c in cnt[3:9]])
def mono3(col, n):                                # one-colour 3-term progression?
    return any(col >> (a - 1) & 1 == col >> (a + d - 1) & 1 == col >> (a + 2 * d - 1) & 1
               for d in range(1, n) for a in range(1, n - 2 * d + 1))
free8 = [c for c in range(2**8) if not mono3(c, 8)]
free9 = [c for c in range(2**9) if not mono3(c, 9)]
print(f"2-colourings of 1..8 with no one-colour 3-term progression: {len(free8)}; of 1..9: {len(free9)}")
print("one that dodges, 1..8:", "".join("RB"[free8[0] >> i & 1] for i in range(8)))
assert len(free8) > 0 and len(free9) == 0
def r3(top):                                      # largest set in 1..n with no 3-term progression
    r = [0] * (top + 1)
    for n in range(1, top + 1):
        want = r[n - 1] + 1; r[n] = want; ch = []; cs = set()
        def dfs(pos, c):
            if c == want: return True
            if pos > n or c + r[n - pos + 1] < want: return False
            if not any(2 * y - pos in cs for y in ch):
                ch.append(pos); cs.add(pos)
                if dfs(pos + 1, c + 1): return True
                ch.pop(); cs.discard(pos)
            return dfs(pos + 1, c)
        if not dfs(1, 0): r[n] = want - 1
    return r
def has3(S):
    T = set(S)
    return any((x + y) % 2 == 0 and (x + y) // 2 in T for x, y in combinations(S, 2))
def base3(n):                                     # 1 + numbers with base-3 digits 0 and 1
    return [m + 1 for m in range(n) if all((m // 3**j) % 3 < 2 for j in range(11))]
R = r3(60)
print("N | r3(N) | r3(N)/N | base-3 set size | its share")
for n in (9, 20, 27, 40, 60, 81, 729, 59049):
    b = base3(n); assert not has3(b) if n <= 729 else True
    rr = f"{R[n]} | {R[n] / n:.3f}" if n <= 60 else "- | -"
    print(f"{n:,} | {rr} | {len(b):,} | {len(b) / n:.3f}")
brute = [max(bin(S).count("1") for S in range(2**n)
             if not has3([i + 1 for i in range(n) if S >> i & 1])) for n in range(1, 13)]
print("r3(1..12) by trying every subset:", brute)
assert brute == R[1:13] and R[20] == 9                          # pruned search vs brute force
pw = [2**j for j in range(20)]
print("powers of 2 up to 10^6:", len(pw), "numbers, 3-term progressions:", int(has3(pw)))
def legendre(n, ps):                              # sum of mu(d) floor(n/d) over d | P(z)
    t = 0
    for m in range(2**len(ps)):
        d, s = 1, 1
        for j, p in enumerate(ps):
            if m >> j & 1: d *= p; s = -s
        t += s * (n // d)
    return t
print("N | z | primes <= N | share of all | z-rough in 2..N | primes among them | share")
chart = []
for e in range(3, 7):
    n = 10**e; z = int(n**0.25 + 1e-9); ps = [p for p in P if p <= z]
    m = bytearray([1]) * (n + 1); m[0] = m[1] = 0
    for p in ps: m[p::p] = bytearray(len(range(p, n + 1, p)))
    rough = sum(m); pin = sum(1 for p in P if z < p <= n); pi = pin + len(ps)
    assert rough == legendre(n, ps) - 1 and pin == sum(m[p] for p in P if p <= n)
    chart.append((pi / n, pin / rough))
    print(f"10^{e} | {z} | {pi:,} | {pi / n:.4f} | {rough:,} | {pin:,} | {pin / rough:.4f}")
print("chart, share of all:", ", ".join(f"{a:.3f}" for a, b in chart))
print("chart, share of rough:", ", ".join(f"{b:.3f}" for a, b in chart))
z = 100; ps = [p for p in P if p <= z]                         # try: z = N^(1/3) = 100
m = bytearray([1]) * (N + 1); m[0] = m[1] = 0
for p in ps: m[p::p] = bytearray(len(range(p, N + 1, p)))
print(f"try: z = {z} at 10^6: rough {sum(m):,}, prime share {(len(P) - len(ps)) / sum(m):.4f}")
assert six[0] == 0 < six[1] and len(P) == 78498 and chart[-1][1] > 0.5 > 6 * chart[-1][0]
print("ALL CHECKS PASS")
