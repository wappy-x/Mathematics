# Why a new integral -- the check behind the card.  Nothing is imported.
# Part 1: a till of 37 coins, $23.45, totalled in the order received and by
# denomination.  Part 2: the rational-minute reading on one hour: 1 when the
# minute count t is a fraction p/q, 0 otherwise.  The code only ever holds
# fractions; what happens at the other times is the proof's job, not the code's.
MASK = (1 << 64) - 1

def splitmix(state):                        # SplitMix64, written out here
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

def usd(cents):                             # whole cents printed as dollars
    return f"${cents // 100}.{cents % 100:02d}"

def gcd(a, b):                              # Euclid's algorithm
    while b:
        a, b = b, a % b
    return a

def queue(count):                           # fractions in [0, 60]: denominator 1, then 2, 3...
    out, q = [], 1
    while len(out) < count:
        for p in range(60 * q + 1):
            if gcd(p, q) == 1 and len(out) < count:
                out.append((p, q))
        q += 1
    return out

def upper_sum(points, n):                   # Riemann upper sum of "1 at these points" on n slices
    touched = set()
    for p, q in points:
        k, r = divmod(p * n, 60 * q)        # the point p/q sits at slice position k + r/(60q)
        if k < n:
            touched.add(k)
        if r == 0 and k > 0:
            touched.add(k - 1)              # on a cut: it touches the slice on its left too
    return len(touched) * 60 / n

def upper_brute(points, n):                 # road two: slice by slice, exact integer comparison
    hit = [k for k in range(n) if any(k * 60 * q <= p * n <= (k + 1) * 60 * q for p, q in points)]
    return len(hit) * 60 / n

def cover(points, eps, fixed=None):         # an interval round each point; sum and clipped union
    width, total, spans = eps, 0.0, []
    for p, q in points:
        width = fixed if fixed else width / 2          # eps/2, eps/4, eps/8 ...
        total += width
        spans.append((max(0.0, p / q - width / 2), min(60.0, p / q + width / 2)))
    spans.sort()
    union, lo, hi = 0.0, spans[0][0], spans[0][1]
    for a, b in spans[1:]:
        if a > hi:
            union, lo, hi = union + hi - lo, a, b
        else:
            hi = max(hi, b)
    return total, union + hi - lo

DENOMS, COUNTS = [100, 50, 25, 10, 5, 1], [20, 5, 2, 3, 2, 5]
coins = [v for v, k in zip(DENOMS, COUNTS) for _ in range(k)]
state = 2026                                # seed for the order the coins arrived in
for i in range(len(coins) - 1, 0, -1):      # Fisher-Yates shuffle
    state, z = splitmix(state)
    j = z % (i + 1)
    coins[i], coins[j] = coins[j], coins[i]
running, marks = 0, []                      # road one: in the order received
for i, c in enumerate(coins):
    running += c
    if i + 1 in (10, 20, 30, 37):
        marks.append(running)
heaps = [(v, sum(1 for c in coins if c == v)) for v in DENOMS]
by_value = sum(v * k for v, k in heaps)     # road two: heaps, count times value
print(f"till: {len(coins)} coins; order received (cents): {coins[:19]}")
print(f"  ... continued: {coins[19:]}")
print("running total after 10, 20, 30, 37 coins: " + ", ".join(usd(m) for m in marks))
for v, k in heaps:
    print(f"heap of {v:>3}c coins: {k:>2} coins x {v:>3}c = {usd(k * v):>6}")
small = [(v, k) for v, k in heaps if v <= 25]
print(f"small change, 25c and below: {sum(k for _, k in small)} coins, {usd(sum(v * k for v, k in small))}")
print(f"by order received: {usd(running)}   by denomination: {usd(by_value)}")
print(f"mistake, counting coins not value: {len(coins)}; one coin per denomination: {usd(sum(DENOMS))}")
x = 20
print("figure, bar width 8, 0.6 px per cent; heap spans in x: "
      + ", ".join(f"{v}c {x + 8 * sum(k for _, k in heaps[:i])}-{x + 8 * sum(k for _, k in heaps[:i + 1])}"
                  for i, (v, _) in enumerate(heaps)))

fr = queue(10000)
halves = next(i for i, (p, q) in enumerate(fr) if q > 1)
print(f"fractions queued: first {', '.join(f'{p}/{q}' for p, q in fr[:3])}; whole minutes fill places 1 to {halves}; place {halves + 1} is {fr[halves][0]}/{fr[halves][1]}")
def reading(p, q):                          # any time the code can hold is p/q, a fraction: reads 1
    return 1
tagged = []
for n in (6, 60, 600):                      # midpoint of slice k is 60(2k+1)/(2n), a fraction
    tagged.append(sum(reading(60 * (2 * k + 1), 2 * n) * 60 / n for k in range(n)))
print("Riemann sums with midpoint tags, n = 6, 60, 600: " + ", ".join(f"{t:.4f}" for t in tagged))
first = fr[:100]
ups = [upper_sum(first, n) for n in (600, 6000, 60000, 600000)]
print("upper sums, reading switched on at the first 100 fractions, n = 600, 6000, 60000, 600000: "
      + ", ".join(f"{u:.4f}" for u in ups))
brute = [upper_brute(first, n) for n in (600, 6000)]
print("upper sums again, slice by slice, n = 600, 6000: " + ", ".join(f"{u:.4f}" for u in brute))
print("bound 2 x 100 x 60 / n:  " + ", ".join(f"{2 * 100 * 60 / n:.4f}" for n in (600, 6000, 60000, 600000)))
rows = [(N,) + cover(fr[:N], 1.0) for N in (61, 10000)]
print(f"cover of first 10000 fractions, eps = 1 minute: widths add to {rows[1][1]:.4f}, "
      f"at most 1: {'yes' if rows[1][1] <= 1.0 else 'no'}; union inside the hour {rows[1][2]:.4f}")
for eps in (0.01, 0.0001):
    s, u = cover(fr, eps)
    print(f"cover of first 10000 fractions, eps = {eps}: widths add to {s:.8f}, so 1 x size + 0 x rest <= {s:.8f}")
fs, fu = cover(fr[:1000], 1.0, fixed=0.1)
print(f"mistake, every width 0.1 for the first 1000: widths add to {fs:.4f}, union inside the hour {fu:.4f}")

in_order, regrouped, sign = 0.0, 0.0, 1.0   # 1 - 1/2 + 1/3 - ...: order matters once signs mix
for k in range(1, 200001):
    in_order += sign / k
    sign = -sign
odd, even = 1, 2
for _ in range(100000):                     # two positive terms, then one negative
    regrouped += 1 / odd + 1 / (odd + 2) - 1 / even
    odd, even = odd + 4, even + 2
ln2, t = 0.0, 1 / 3                         # ln 2 = 2 (t + t^3/3 + t^5/5 + ...), t = 1/3
for k in range(40):
    ln2 += 2 * t ** (2 * k + 1) / (2 * k + 1)
print(f"mistake, 1 - 1/2 + 1/3 - ... in order: {in_order:.4f}; two positives per negative: {regrouped:.4f}")
print(f"ln 2 by its own series: {ln2:.4f}; 1.5 x ln 2: {1.5 * ln2:.4f}")

assert running == by_value, "two roads to the till"
assert by_value == 2345, "the $23.45 counted in by the till"
assert all(abs(s - (1.0 - 0.5 ** N)) < 1e-12 and u <= s for N, s, u in rows), "halving widths: 1 - 2^-N"
assert all(a > b for a, b in zip(ups, ups[1:])) and all(u <= 12000 / n for u, n in zip(ups, (600, 6000, 60000, 600000)))
assert brute == ups[:2], "two roads to the upper sums"
assert abs(in_order - ln2) < 1e-5 and abs(regrouped - 1.5 * ln2) < 1e-5, "two orders, two sums"
print("ALL CHECKS PASS")
