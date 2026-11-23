# Collatz conjecture -- the check behind the card.  Standard library only.
# T(n) = n/2 for even n, 3n + 1 for odd n.  Follows 27 to 1, counts its steps
# two ways, tests the coin-flip model against a million starts, confirms
# Terras's parity fact, matches a backward tree against a forward count, and
# prints the 3n - 1 cycle.  Asserts check instances, never the conjecture.
import math

def T(n): return n // 2 if n % 2 == 0 else 3 * n + 1
def S(n): return n // 2 if n % 2 == 0 else (3 * n + 1) // 2   # shortcut map

def orbit(n, f, stop):                       # n, f(n), f(f(n)), ... until stop
    out = [n]
    while out[-1] != stop or len(out) == 1:
        out.append(f(out[-1]))
        if len(out) > 10_000: break
    return out

# ---- road 1: the plain trajectory of 27 ----
tr = orbit(27, T, 1)
steps, odd = len(tr) - 1, sum(x % 2 for x in tr[:-1])
peak = max(tr)
sigma = next(i for i, x in enumerate(tr) if x < 27)          # stopping time
print("trajectory of 27, 14 values a line:")
for i in range(0, len(tr), 14):
    print(" ".join(str(x) for x in tr[i:i + 14]))
print(f"27: total stopping time {steps}, odd steps {odd}, halvings {steps - odd}, "
      f"peak {peak} at step {tr.index(peak)}, peak/start {peak / 27:.1f}")
print(f"27: stopping time {sigma}, first value below 27 is {tr[sigma]}")
# ---- road 2: the shortcut map, counted separately ----
short = len(orbit(27, S, 1)) - 1
print(f"27 under the shortcut map: {short} steps; plain minus odd = {steps - odd}")
assert (steps, odd, peak, sigma) == (111, 41, 9232, 96)
assert short == steps - odd                  # two counts, two loops
# ---- road 3: the exact product identity 27 * prod(3n+1) = 2^halvings * prod(n) ----
lhs, rhs = 27, 2 ** (steps - odd)
for x in tr[:-1]:
    if x % 2: lhs, rhs = lhs * (3 * x + 1), rhs * x
assert lhs == rhs
nudge = 2 ** (steps - odd) / 3 ** (odd + 3)  # 27 = 3^3
print(f"identity 27 * prod(3n+1) = 2^{steps - odd} * prod(n): exact; "
      f"the +1 nudges multiply by {nudge:.4f}")
longest = max(range(2, 27), key=lambda n: len(orbit(n, T, 1)))
print(f"starts 2 to 26: longest is {longest} with {len(orbit(longest, T, 1)) - 1} steps")
# ---- the coin-flip model against a million starts ----
drift = 0.5 * math.log(3 / 4)                # mean log factor per shortcut step
per_ln = 1.5 * (-1 / drift)                  # plain steps per unit of ln n
print(f"model: mean log factor per shortcut step {drift:.6f}, "
      f"typical factor {math.sqrt(3 / 4):.6f}")
print(f"model: {per_ln:.4f} plain steps per unit of ln n; for 27: "
      f"{per_ln * math.log(27):.2f} steps, actual {steps}")
N, M = 1_000_000, 2 ** 20
st = [0] * (M + 1)
for n in range(2, M + 1):                    # memory: walk only until below n
    m, s = n, 0
    while m >= n:
        m, s = T(m), s + 1
    st[n] = s + st[m]
mean = sum(st[1:N + 1]) / N
model = per_ln * sum(math.log(n) for n in range(1, N + 1)) / N
print(f"checked n <= {N}: every start reaches 1")
print(f"mean total stopping time {mean:.4f}, model {model:.4f}, ratio {mean / model:.4f}")
assert st[27] == steps and abs(mean / model - 1) < 0.05
full = 0                                     # second road: walk every start all the way to 1
for n in range(1, N + 1):
    m = n
    while m != 1:
        m, full = (m // 2 if m % 2 == 0 else 3 * m + 1), full + 1
print(f"sum of total stopping times, n <= {N}: with memory {sum(st[1:N + 1])}, by full walks {full}")
assert full == sum(st[1:N + 1])
best = max(range(2, 1000), key=lambda n: st[n])
print(f"starts below 1000: longest is {best} with {st[best]} steps")
for n0 in (28, 97, 871):
    o = orbit(n0, T, 1)
    print(f"start {n0}: {len(o) - 1} steps, peak {max(o)}, model {per_ln * math.log(n0):.2f}")
assert st[97] == len(orbit(97, T, 1)) - 1 and st[871] == len(orbit(871, T, 1)) - 1
print(f"Korec exponent log 3 / log 4 = {math.log(3) / math.log(4):.5f}; "
      f"log log log of 10^100 = {math.log(math.log(100 * math.log(10))):.4f}")
# ---- Terras: the first k shortcut parities depend on n mod 2^k, one-to-one ----
def parity(n, k):
    v = []
    for _ in range(k):
        v.append(n % 2); n = S(n)
    return tuple(v)
for k in range(1, 13):
    vecs = [parity(r, k) for r in range(2 ** k)]
    assert len(set(vecs)) == 2 ** k
    assert all(parity(r + 2 ** k, k) == vecs[r] for r in range(2 ** k))
print("Terras: k = 1 to 12, the 2^k residues give 2^k different parity strings")
print("k = 3: " + " ".join(f"{r}:{''.join(map(str, parity(r, 3)))}" for r in range(8)))
# ---- the tree of starts: backward from 1 against forward counting ----
layer, back = {1}, [1]
for k in range(1, 21):
    nxt = set()
    for m in layer:
        nxt.add(2 * m)
        if m % 6 == 4 and m > 4: nxt.add((m - 1) // 3)
    layer = nxt; back.append(len(layer))
fwd = [sum(1 for n in range(1, M + 1) if st[n] == k) for k in range(21)]
print("starts with total stopping time k, k = 0 to 20:")
print(" ".join(map(str, back)))
assert back == fwd
print("backward tree and forward count over n <= 2^20 agree")
# ---- what breaks ----
c5, c17 = orbit(5, lambda n: n // 2 if n % 2 == 0 else 3 * n - 1, 5), \
          orbit(17, lambda n: n // 2 if n % 2 == 0 else 3 * n - 1, 17)
neg = orbit(-5, T, -5)
print("3n - 1 from 5: " + " ".join(map(str, c5)))
print(f"3n - 1 from 17: a cycle of {len(c17) - 1} steps, peak {max(c17)}")
print("3n + 1 from -5: " + " ".join(map(str, neg)))
assert c5 == [5, 14, 7, 20, 10, 5] and len(c17) - 1 == 18 and neg == [-x for x in c5]
print(f"verification bound 2^71 = {2 ** 71} (quoted, not run here)")
print("ALL CHECKS PASS")
