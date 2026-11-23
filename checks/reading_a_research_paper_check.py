# Reading a paper: Zhang's bounded gaps, abstract against Theorem 1 -- the check behind the card.
# Standard library only.  Four roads:
# 1. a sieve of Eratosthenes to 7 x 10^7 counts primes and builds the paper's own 3,500,000-tuple;
# 2. Lucy's prime-counting recursion finds pi(x) with no sieve, for the paper's inequality;
# 3. admissibility, by the paper's shortcut against the full residue-class definition;
# 4. the dependency list as a graph: longest chain by Kahn's queue and by depth-first search.
from fractions import Fraction as Fr
from itertools import compress
from math import isqrt, log10

X, K0 = 70_000_000, 3_500_000
s = bytearray([1]) * (X + 1); s[0] = s[1] = 0
for i in range(2, isqrt(X) + 1):
    if s[i]: s[i * i::i] = bytearray(len(range(i * i, X + 1, i)))
ps = list(compress(range(X + 1), s))
pi_x, pi_k = len(ps), s[:K0 + 1].count(1)

def lucy(n):                          # pi(n) by Lucy's recursion: no list of primes is kept
    r = isqrt(n); V = [n // i for i in range(1, r + 1)]; V += list(range(V[-1] - 1, 0, -1))
    S = {v: v - 1 for v in V}
    for p in range(2, r + 1):
        if S[p] > S[p - 1]:
            sp, p2 = S[p - 1], p * p
            for v in V:
                if v < p2: break
                S[v] -= S[v // p] - sp
    return S[n]

print("Road 1 and 2: the paper's inequality pi(7 x 10^7) - pi(3.5 x 10^6) > 3.5 x 10^6")
print(f"pi(70,000,000) = {pi_x:,} by sieve, {lucy(X):,} by Lucy's recursion")
print(f"pi(3,500,000) = {pi_k:,} by sieve, {lucy(K0):,} by Lucy's recursion")
print(f"difference = {pi_x - pi_k:,}, needed > {K0:,}: {pi_x - pi_k > K0}")
H = ps[pi_k:pi_k + K0]                # the k0 primes just above k0: the paper's admissible set
print(f"the tuple: primes {H[0]:,} (prime number {pi_k + 1:,}) to {H[-1]:,} (prime number {pi_k + K0:,})")
print(f"width h_k0 - h_1 = {H[-1] - H[0]:,}; abstract's bound 70,000,000; slack {X - (H[-1] - H[0]):,}")
print(f"shortcut: every entry prime and above k0, so class 0 mod each p <= k0 is empty: {H[0] > K0}")

def admissible(T):                    # the definition: fewer than p classes met, for every prime p
    for p in range(2, len(T) + 1):    # a prime p > k cannot be filled by k entries
        if s[p] and len({h % p for h in T}) == p: return False, p
    return True, None

print("Road 3: admissibility, shortcut against the full residue check")
for k in (10, 50, 300):
    T = [p for p in ps if p > k][:k]; F = ps[:k]
    print(f"k = {k}: primes above k from {T[0]} to {T[-1]}, admissible {admissible(T)[0]}; "
          f"first k primes from {F[0]} to {F[-1]}, admissible {admissible(F)[0]}, fails at p = {admissible(F)[1]}")
    assert admissible(T)[0] == (T[0] > k) and not admissible(F)[0]
print(f"(0, 2, 4): classes mod 3 met = {len({0 % 3, 2 % 3, 4 % 3})} of 3, so not admissible")

print("What the theorem does not say")
tw = sum(1 for p in ps if p + 2 <= X and s[p + 2])
g, at = max((q - p, p) for p, q in zip(ps, ps[1:]))
print(f"twin pairs below 70,000,000: {tw:,} (evidence only; gap 2 is not claimed)")
print(f"widest gap below 70,000,000: {g}, after {at:,} (true of this range, not 'infinitely often')")
f10 = 3_628_800                       # 10!: 10! + 2, ..., 10! + 10 are all composite
print(f"10! + 2 to 10! + 10 composite: {all(not s[f10 + j] for j in range(2, 11))}; gaps are unbounded")

w = Fr(1, 1168)
print(f"Theorem 2: varpi = {w}, level 1/2 + 2 varpi = {Fr(1, 2) + 2 * w} = {float(Fr(1, 2) + 2 * w):.6f}")
print(f"cut-off D = x^(1/4 + varpi) = x^({Fr(1, 4) + w}); excess over Bombieri-Vinogradov 2 varpi = {2 * w}")
q = Fr(1, 2) + Fr(7, 300)               # Polymath 2014, smooth moduli: quoted, not proved here
print(f"Polymath 2014 exponent (quoted): 1/2 + 7/300 = {q} = {float(q):.6f}")

print("Road 4: the dependency list (A <- B means A uses B)")
uses = {"Theorem 1": ["GPY sieve [7]", "Theorem 2"],
        "Theorem 2": ["Bombieri-Vinogradov", "Heath-Brown identity [9]", "Type I/II", "Type III"],
        "Type I/II": ["dispersion method [1], [5]", "Siegel-Walfisz", "Weil's Kloosterman bound", "Shiu [12]"],
        "Type III": ["Birch-Bombieri, appendix to [6]", "Weil's Kloosterman bound"],
        "Birch-Bombieri, appendix to [6]": ["Deligne 1974 [4]"]}
nodes = sorted(set(uses) | {b for v in uses.values() for b in v})
outside = [n for n in nodes if n not in uses or n.startswith("Birch")]
print(f"proved in the paper: {', '.join(n for n in nodes if n not in outside)}")
byname = [n for n in outside if "[" not in n]
print(f"main outside results: {len(outside)}, of which {len(outside) - len(byname)} carry a reference number")
print(f"cited by name only: {', '.join(byname)}")
def depth(n): return 1 + max((depth(b) for b in uses.get(n, [])), default=0)
indeg = {n: 0 for n in nodes}
for a in uses:
    for b in uses[a]: indeg[b] += 1
level, queue, longest = {n: 1 for n in nodes}, [n for n in nodes if indeg[n] == 0], 0
while queue:
    a = queue.pop(); longest = max(longest, level[a])
    for b in uses.get(a, []):
        level[b] = max(level[b], level[a] + 1); indeg[b] -= 1
        if indeg[b] == 0: queue.append(b)
print(f"longest chain: {depth('Theorem 1')} results by depth-first search, {longest} by Kahn's queue")
print("Theorem 1 <- Theorem 2 <- Type III <- Birch-Bombieri <- Deligne 1974")
assert depth("Theorem 1") == longest and all(v == 0 for v in indeg.values())

print("bars: proved bound on a gap that recurs forever, log10")
for lab, v in [("Zhang 2013, abstract", X), ("Zhang's own tuple", H[-1] - H[0]),
               ("Maynard 2013", 600), ("Polymath 2014", 246), ("twin primes, open", 2)]:
    print(f"{lab:<21}{'#' * round(4 * log10(v)):<32}{log10(v):.2f}")
assert pi_x == lucy(X) and pi_k == lucy(K0) and pi_x - pi_k > K0
assert len(H) == K0 and lucy(H[-1]) == pi_k + K0 == lucy(H[-1] - 1) + 1 and lucy(H[0] - 1) == pi_k
print("ALL CHECKS PASS")
