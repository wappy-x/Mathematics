# The Cantor set -- the check behind the card.  Standard library only.  The road
# is [0, 1] km.  Stretch ends are whole numbers over D = 3^12, so every night up
# to 12 is exact; staircase values are exact fractions; coin flips are SplitMix64.
from fractions import Fraction as Fr

N, MASK = 12, (1 << 64) - 1
D = 3 ** N

def dec(q, places):                          # exact fraction as a decimal, half up
    s = 10 ** places
    v = (q.numerator * s * 2 + q.denominator) // (2 * q.denominator)
    return f"{v // s}.{v % s:0{places}d}" if places else str(v)

def nights(n):                               # road one: cut out every middle third, n times
    pieces, gaps = [(0, D)], []
    for _ in range(n):
        nxt = []
        for lo, hi in pieces:
            w = (hi - lo) // 3
            nxt += [(lo, lo + w), (hi - w, hi)]
            gaps.append((lo + w, hi - w))
        pieces = nxt
    return pieces, gaps

def by_digits(n):                            # road two: keep stretches whose address has no 1
    w = 3 ** (N - n)
    return [(k * w, k * w + w) for k in range(3 ** n) if all(k // 3 ** j % 3 != 1 for j in range(n))]

def F_digits(x, m=40):                       # staircase, road A: ternary digits read in binary
    if x >= 1:
        return Fr(1)
    total, half = Fr(0), Fr(1, 2)
    for _ in range(m):
        x *= 3
        d = x.numerator // x.denominator
        x -= d
        if d == 1:                           # inside a resurfaced gap: flat from here
            return total + half
        total, half = total + half * (d // 2), half / 2
    return total

def F_self(x, depth=40):                     # staircase, road B: each outer third is a half-size copy
    if x <= 0 or depth == 0:
        return Fr(0)
    if x >= 1:
        return Fr(1)
    if 3 * x < 1:
        return F_self(3 * x, depth - 1) / 2
    return Fr(1, 2) if 3 * x <= 2 else Fr(1, 2) + F_self(3 * x - 2, depth - 1) / 2

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

print("night  stretches  still waiting (m)  resurfaced (m)")
for n in (0, 1, 2, 3, 4, 5, 10, 12, 18, 20):
    wait = Fr(1000 * 2 ** n, 3 ** n)
    print(f"{n:>5}  {2 ** n:>9}  {dec(wait, 2):>17}  {dec(1000 - wait, 2):>14}")
under = next(n for n in range(60) if 1000 * 2 ** n < 3 ** n)
print(f"first night the waiting length drops under 1 m: {under}")
pieces, gaps = nights(N)
print(f"road one, night 12 built by cutting: {len(pieces)} stretches totalling "
      f"{dec(Fr(1000 * sum(h - l for l, h in pieces), D), 2)} m, {len(gaps)} gaps totalling "
      f"{dec(Fr(1000 * sum(h - l for l, h in gaps), D), 2)} m")
same = all(nights(n)[0] == by_digits(n) for n in range(9))
print(f"road two, stretches read from ternary addresses: same list as road one, nights 0 to 8: {'yes' if same else 'no'}")
tern = lambda x, n: "".join(str(int(x * 3 ** k) % 3) for k in range(1, n + 1))   # base-3 digits
inside = all(any(4 * lo < D < 4 * hi for lo, hi in nights(n)[0]) for n in range(N + 1))
print(f"250 m = 1/4 km = 0.{tern(Fr(1, 4), N)}... in base 3; strictly inside a waiting stretch "
      f"after each night 0 to 12: {'yes' if inside else 'no'}")
g800 = next(g for g in nights(2)[1] if 5 * g[0] < 4 * D < 5 * g[1])
print(f"800 m = 4/5 km = 0.{tern(Fr(4, 5), 8)}... in base 3; its first 1 is digit 2, and it lies in the night-2 gap "
      f"from {dec(Fr(1000 * g800[0], D), 2)} to {dec(Fr(1000 * g800[1], D), 2)} m")
xs = [Fr(k, 27) for k in range(28)]
FA, FB = [F_digits(x) for x in xs], [F_self(x) for x in xs]
print("chart x (m): " + ", ".join(dec(1000 * x, 0) for x in xs))
print("chart F (%): " + ", ".join(dec(100 * f, 2) for f in FA))
p6, g6 = nights(6)
flat = all(F_self(Fr(l, D)) == F_self(Fr(h, D)) for l, h in g6)
rise = {F_self(Fr(h, D)) - F_self(Fr(l, D)) for l, h in p6}
print(f"F equal at both ends of all {len(g6)} gaps of night 6: {'yes' if flat else 'no'}; "
      f"rise across each of the {len(p6)} waiting stretches: {', '.join(map(str, rise))}")
print(f"F(1/4) by digits and by copies, 40 steps: {dec(F_digits(Fr(1, 4)), 9)} and {dec(F_self(Fr(1, 4)), 9)}")
print("slope of F from 0 to 3^-n, which is (3/2)^n: " + ", ".join(
      f"n={n}: {dec(F_digits(Fr(1, 3 ** n)) * 3 ** n, 2)}" for n in (1, 5, 10, 20)))
T, state, D30 = 20000, 2026, 3 ** 30
below, in12, unif6, first = {250: 0, 500: 0, 800: 0}, 0, 0, []
for i in range(T):
    state, r = splitmix(state)
    num = sum(2 * (r >> j & 1) * 3 ** (29 - j) for j in range(30))   # X times 3^30, coin j gives digit j+1
    for m in below:
        below[m] += num * 1000 <= m * D30
    lo, hi = 0, len(pieces)                  # binary search among road one's night-12 stretches
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if pieces[mid][0] * 3 ** 18 <= num else (lo, mid)
    in12 += pieces[lo][0] * 3 ** 18 <= num <= pieces[lo][1] * 3 ** 18
    if i < 6:
        first.append([2 * (r >> j & 1) for j in range(6)])
    state, r = splitmix(state)
    unif6 += any(l <= r % D <= h for l, h in p6)
print(f"coin-flip points X (SplitMix64, seed 2026, 30 ternary digits each): {T}")
for m, c in below.items():
    print(f"share with X <= {m} m: {dec(Fr(c, T), 4)}; F({m} m) = {dec(F_digits(Fr(m, 1000)), 4)}")
print(f"X inside a night-12 stretch of road one: {in12} of {T}")
print(f"uniform points inside a night-6 stretch: {unif6} of {T}, share {dec(Fr(unif6, T), 4)}; "
      f"(2/3)^6 = {dec(Fr(64, 729), 4)}")
diag = [2 - first[k][k] for k in range(6)]
print("diagonal, listed addresses: " + ", ".join("0." + "".join(map(str, a)) for a in first))
value = lambda a: sum(Fr(d, 3 ** (k + 1)) for k, d in enumerate(a))
gapmin = min(abs(value(diag) - value(a)) for a in first)
print(f"diagonal, new address 0.{''.join(map(str, diag))}; nearest listed point {dec(1000 * gapmin, 2)} m away")
fat = [(0, 1 << 24)]                         # the fat version: at night n cut 1/4^n from each middle
for n in range(1, 11):
    half = (1 << 24) >> (2 * n + 1)
    fat = [p for lo, hi in fat for p in ((lo, (lo + hi) // 2 - half), ((lo + hi) // 2 + half, hi))]
fat_left = Fr(sum(h - l for l, h in fat), 1 << 24)
print(f"mistake, cut 1/4^n instead of a third: after 10 nights {len(fat)} stretches, "
      f"{dec(1000 * fat_left, 2)} m still waiting; the limit is 500.00 m")
print(f"mistake, count points for length: night 12 keeps {len(pieces)} stretches and {2 * len(pieces)} end points, "
      f"all in the set, on {dec(Fr(1000 * 2 ** 12, 3 ** 12), 2)} m")
print(f"mistake, add up the slope: F' = 0 on gaps totalling {dec(1000 - Fr(1000 * 2 ** 20, 3 ** 20), 2)} m "
      "after 20 nights, 1000 m in the limit; slope integral 0, yet F rises from 0 to 1")
print("figure, x = 18 + 324 t for t in km; night n drawn at y = 22 + 42 n, bars 12 high")
for n in range(5):
    print(f"figure, night {n}: width {324 // 3 ** n} at x " + ", ".join(str(18 + 324 * l // D) for l, h in nights(n)[0]))
assert same and inside and flat and in12 == T                  # the roads agree, stretch by stretch
assert sum(h - l for l, h in pieces) * 3 ** N == 2 ** N * D and sum(h - l for l, h in gaps) == D - 2 ** N
assert FA == FB and rise == {Fr(1, 64)} and all(F_digits(Fr(1, 3 ** n)) * 3 ** n == Fr(3, 2) ** n for n in (1, 5, 10, 20))
assert abs(F_self(Fr(1, 4)) - Fr(1, 3)) < Fr(1, 2 ** 39) and abs(F_digits(Fr(1, 4)) - Fr(1, 3)) < Fr(1, 2 ** 39)
for m, c in below.items():                                      # simulation within 4 standard errors
    p = float(F_digits(Fr(m, 1000)))
    assert abs(c / T - p) < 4 * (p * (1 - p) / T) ** 0.5
assert abs(unif6 / T - 64 / 729) < 4 * (64 / 729 * 665 / 729 / T) ** 0.5 and gapmin * 3 ** 6 >= 1
assert fat_left == Fr(1, 2) + Fr(1, 2 ** 11)
print("ALL CHECKS PASS")
