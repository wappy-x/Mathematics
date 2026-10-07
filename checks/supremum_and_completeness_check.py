# No gaps: least upper bounds -- the check behind the card.  Nothing is
# imported.  S is every number strictly between 0 and 1.  Road one plays the
# ceiling game in exact ten-thousandths: every proposed maximum, and every
# proposed ceiling below 1, is beaten by a member.  Road two scans finer and
# finer grids of members: the largest climbs toward 1 and never lands on it.
U = 10000                                     # one unit, in ten-thousandths

def dec(n, places=4):                         # dec(9500) -> "0.95", exact
    sign, n = ("-" if n < 0 else ""), abs(n)
    s = f"{n // 10 ** places}.{n % 10 ** places:0{places}d}"
    return sign + s.rstrip("0").rstrip(".")

def in_s(x):                                  # is x (in ten-thousandths) in S?
    return 0 < x < U

def beat(t):                                  # a member of S above t, for t < 1
    return (t + U) // 2 if t > 0 else U // 2

print("S = every number strictly between 0 and 1")
maxes, lows = [9000, 9900, 9990], [9990, 5000, -30000]
assert all(in_s(beat(x)) and beat(x) > x for x in maxes + lows)  # road one
for m in maxes:                               # no largest member
    print(f"proposed maximum {dec(m)}: ({dec(m)} + 1)/2 = {dec(beat(m))}, a larger member")
for t in lows:                                # no ceiling below 1
    print(f"proposed ceiling {dec(t)}: member {dec(beat(t))} passes it")
tops = []
for n in range(1, 21):                        # road two: grids of step 1/2^n
    d = 2 ** n
    k = max(j for j in range(2 * d + 1) if 0 < j < d)
    assert k == d - 1                          # scan agrees with 1 - 1/2^n
    tops.append(k / d)
print("road two, largest member on the grid of step 1/2^n, n = 1 to 8:")
print("  " + ", ".join(str(x) for x in tops[:8]))
print("  to two places: " + ", ".join(f"{x:.2f}" for x in tops[:8]))
print(f"  n = 20: gap to 1 is 1/{2 ** 20}; every grid member stays below 1")
print("ceiling 1.2 holds, and so does 1, which is lower: sup S = 1, no max S")
print("same set with 1 put in, (0, 1]: sup = 1 = max, a member")
p, r, trims = 3, 2, []                        # fraction ceilings over q*q < 2
for _ in range(5):
    assert p * p > 2 * r * r and all(p * b < a * r for a, b in trims[-1:])  # lower ceiling
    trims.append((p, r))
    p, r = 2 * p + 2 * r, p + 2 * r            # q -> (2q + 2)/(q + 2), lower
    g = next(x for x in range(min(p, r), 0, -1) if p % x == 0 and r % x == 0)
    p, r = p // g, r // g
print("fraction ceilings over the fractions whose square is under 2:")
print("  " + ", ".join(f"{a}/{b} = {a / b:.6f}" for a, b in trims))
lo, hi, den = 1, 2, 1                         # halving: where the gap sits
for _ in range(20):
    lo, hi, den = 2 * lo, 2 * hi, 2 * den
    mid = (lo + hi) // 2
    lo, hi = (mid, hi) if mid * mid < 2 * den * den else (lo, mid)
assert all(a * den > hi * b for a, b in trims)  # every fraction ceiling sits above
print(f"halving 20 times: the lowest ceiling is between {lo / den:.7f} and {hi / den:.7f}")
c = 10005                                     # a ceiling over 1, 2, 3, ... ?
print(f"no ceiling over 1, 2, 3, ...: proposed ceiling {dec(c, 1)} is passed by {c // 10 + 1}")
xs = [(dec(t, 1), 40 + 25 * t) for t in (0, 5, 10, 12)]   # t in tenths
print("figure, x = 40 + 250 t: " + ", ".join(f"{t} -> {x}" for t, x in xs))
print("ALL CHECKS PASS")
