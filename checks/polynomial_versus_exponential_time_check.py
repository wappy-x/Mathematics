# Polynomial or exponential -- the check behind the card.  Standard library only.
# A van's round of 40 stops.  Every cost is a count of named steps, never a stopwatch;
# the times below are those counts divided by an assumed 10^9 steps a second.
# The road chart is synthetic: SplitMix64, seed 2026, each road 5 to 60 miles.
import math
M, RATE, HOUR = (1 << 64) - 1, 10**9, 3600 * 10**9
state = 2026
def rand():                                   # SplitMix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & M
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return z ^ (z >> 31)
def sci(x):                                   # "1.10 x 10^12", built the same way in both languages
    e = 0
    while x >= 10: x, e = x / 10, e + 1
    return f"{x:.2f} x 10^{e}"
def span(steps):                              # a step count read as time at RATE
    s = steps / RATE
    for unit, size in (("million years", 31557600e6), ("years", 31557600.0), ("days", 86400.0),
                       ("hours", 3600.0), ("minutes", 60.0), ("seconds", 1.0)):
        if s >= size: return f"{s / size:,.1f} {unit}"
    return f"{s * 1e6:.0f} microseconds"
N = 40
d = [[0] * N for _ in range(N)]
for i in range(N):
    for j in range(i + 1, N): d[i][j] = d[j][i] = 5 + rand() % 56
def table(n):                                 # shortest road between every pair: try each stop k as a stopover
    t, checks = [row[:n] for row in d[:n]], 0
    for k in range(n):
        for i in range(n):
            for j in range(n):
                checks += 1
                if t[i][k] + t[k][j] < t[i][j]: t[i][j] = t[i][k] + t[k][j]
    return t, checks
t40, checks40 = table(N)
assert checks40 == N ** 3 and table(20)[1] == 8000          # road 1: counted against the formula n^3
assert all(t40[i][j] <= t40[i][k] + t40[k][j] for i in range(N) for j in range(N) for k in range(N))
def set_by_set(n):                            # exact cheapest round from stop 0, counting additions
    best, adds = {}, 0
    for S in range(1, 1 << (n - 1)):          # every set of stops 1..n-1, as a bit mask
        for j in range(1, n):
            if not S >> (j - 1) & 1: continue
            R = S & ~(1 << (j - 1))
            if R == 0: best[S, j] = t40[0][j]; continue
            v = None
            for i in range(1, n):
                if R >> (i - 1) & 1:
                    adds += 1
                    c = best[R, i] + t40[i][j]
                    if v is None or c < v: v = c
            best[S, j] = v
    full = (1 << (n - 1)) - 1
    return min(best[full, j] + t40[j][0] for j in range(1, n)), len(best), adds + n - 1
def brute(n):                                 # road 2: every order of the stops after 0
    def go(last, left, miles):
        if not left: return miles + t40[last][0]
        return min(go(x, [y for y in left if y != x], miles + t40[last][x]) for x in left)
    return go(0, list(range(1, n)), 0)
def hk_adds(n): m = n - 1; return m * (m - 1) * 2 ** (m - 2) + m if n > 2 else n - 1
for n in (6, 7, 8, 9):
    assert set_by_set(n)[0] == brute(n)                      # same cheapest round, two methods
print("set-by-set exact round on the first n stops: steps counted, and growth")
prev = None
for n in range(8, 15):
    miles, recs, adds = set_by_set(n)
    assert adds == hk_adds(n) and recs == (n - 1) * 2 ** (n - 2)   # counted against the formula
    print(f"  n {n:2d}  cheapest {miles:3d} miles  records {recs:7,}  steps {adds:9,}"
          + (f"  x{adds / prev:.3f}" if prev else ""))
    prev = adds
print("the 40-stop round, steps counted or by formula")
rows = [("distance table, n^3 (counted)", checks40), ("every set of stops, 2^n", 2 ** N),
        ("set-by-set exact round", hk_adds(N))]
for label, c in rows: print(f"  {label:31s} {c:>22,}   {span(c)}")
brute40 = 1.0
for k in range(2, N): brute40 *= k
print(f"  listing every round, 39!/2       {sci(brute40 / 2):>21}   {sci(brute40 / 2 / RATE / 31557600)} years")
print(f"  2^40 / 40^3 = {2 ** N // N ** 3:,}")
print(f"  one more stop: 41^3 = {41 ** 3:,} (x{41 ** 3 / N ** 3:.3f}), 2^41 = {2 ** 41:,} (x2)")
for n in (50, 60, 80):
    print(f"  n = {n}: n^3 {span(n ** 3)};  2^n {span(2 ** n)};  set-by-set {span(hk_adds(n))}")
lead = [n for n in range(1, 121) if 2 ** n <= n ** 3]        # road 3: scan for the crossing
print(f"crossing: n^3 >= 2^n for n = {lead[0]} to {lead[-1]}; "
      f"2^9 = {2**9} <= 9^3 = {9**3}; 2^10 = {2**10} > 10^3 = {10**3}; for n^5 it is n = 23")
assert lead == list(range(2, 10)) and all((n + 1) ** 3 < 2 * n ** 3 for n in range(4, 121))
assert max(n for n in range(1, 121) if 2 ** n <= n ** 5) == 22
def largest(cost, budget):                    # step n up until the cost passes the budget
    n = 1
    while cost(n + 1) <= budget: n += 1
    return n
print("largest n inside a budget, by search and by formula")
for name, budget in (("1 hour", HOUR), ("1 hour, 1000x faster", 1000 * HOUR), ("1 day", 24 * HOUR)):
    c, e = largest(lambda n: n ** 3, budget), largest(lambda n: 2 ** n, budget)
    assert c == math.floor(budget ** (1 / 3)) and e == math.floor(math.log2(budget))
    print(f"  {name:21s} n^3: {c:>7,}   2^n: {e}")
print(f"what breaks: n = 8 looks fine: 2^8 = {2**8} < 8^3 = {8**3}")
print(f"what breaks: 1000x faster buys 2^n {largest(lambda n: 2**n, 1000*HOUR)} stops, not {10*41}")
print(f"what breaks: 40^2 = {40**2:,}, not 2^40")
print(f"what breaks: n^3 on 1,000,000 tracks = {sci(1e18)} = {span(10**18)}; n^2 = {span(10**12)}")
s82 = (2 ** 82 + HOUR - 1) // HOUR                           # least speed-up that fits 82 stops
assert largest(lambda n: 2 ** n, s82 * HOUR) == 82 and largest(lambda n: 2 ** n, (s82 - 1) * HOUR) == 81
print(f"what breaks: 82 stops in one hour, by speed alone, needs {s82:,}x = {sci(s82)}")
print("chart, n          " + "".join(f"{n:7d}" for n in range(10, 81, 10)))
print("chart, log10 n^3  " + "".join(f"{3 * math.log10(n):7.2f}" for n in range(10, 81, 10)))
print("chart, log10 2^n  " + "".join(f"{n * math.log10(2):7.2f}" for n in range(10, 81, 10)))
print(f"chart, one hour   {math.log10(HOUR):7.2f}")
print("ALL CHECKS PASS")
