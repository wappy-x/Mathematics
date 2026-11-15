# Complete space and completion -- the check behind the card.  Nothing is
# imported.  The space is the rationals with d(x, y) = |x - y|.  Every
# rational is held exactly as a pair of integers (numerator, denominator).
# Decimals of root 2 are built two ways, a second Cauchy sequence (Newton's)
# is checked to sit at the same gap, and the "what breaks" numbers follow.
def isqrt(n):                            # road one: largest r with r*r <= n, by halving
    lo, hi = 0, 1
    while hi * hi <= n:                  # first find a power of 2 past the root
        hi *= 2
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * mid <= n else (lo, mid)
    return lo

def digit_search(k):                     # road two: pick each decimal digit greedily
    a = 1
    for place in range(1, k + 1):
        a = a * 10 + max(d for d in range(10) if (a * 10 + d) ** 2 <= 2 * 100 ** place)
    return a

def gcd(a, b):                           # Euclid, so each fraction is counted once
    while b:
        a, b = b, a % b
    return a

def dec(p, q, k):                        # p/q >= 0, cut off (not rounded) to k places
    s = str(p * 10 ** k // q).rjust(k + 1, "0")
    return s[:-k] + "." + s[-k:] if k else s

def exact(p, k):                         # p / 10^k written out exactly, zeros trimmed
    return dec(p, 10 ** k, k).rstrip("0").rstrip(".") if k else str(p)

A = [isqrt(2 * 100 ** n) for n in range(13)]           # a_n = A[n] / 10^n
print("a_n = root 2 cut off at n decimal places; every a_n is a fraction")
for n in range(7):
    print(f"a_{n} = {exact(A[n], n):<9} 2 - a_{n}^2 = {exact(2 * 100 ** n - A[n] ** 2, 2 * n)}")
pairs = [(n, m) for n in range(13) for m in range(n + 1, 13)]
cauchy = all(abs(A[m] - A[n] * 10 ** (m - n)) < 10 ** (m - n) for n, m in pairs)
print(f"Cauchy test |a_m - a_n| < 10^-n: {'holds' if cauchy else 'FAILS'} on the {len(pairs)} pairs n < m <= 12")
cut = next(N for N in range(13) if all(abs(A[m] * 10 ** (12 - m) - A[n] * 10 ** (12 - n)) < 10 ** 9 for n, m in pairs if n > N))
print(f"smallest N with |a_m - a_n| < 10^-3 for all m, n > N (to 12): {cut}, so from a_{cut + 1} = {exact(A[cut + 1], cut + 1)} on")
hits = [(p, q) for q in range(1, 2001) for p in (isqrt(2 * q * q), isqrt(2 * q * q) + 1) if p * p == 2 * q * q]
print(f"fractions p/q with q <= 2000 and p^2 = 2 q^2: {len(hits)}")

B = [(1, 1)]                                           # Newton: b -> (b + 2/b) / 2
for _ in range(4):
    p, q = B[-1]
    B.append((p * p + 2 * q * q, 2 * p * q))
for k, (p, q) in enumerate(B):
    gap = abs(A[k] * q - p * 10 ** k)
    print(f"b_{k} = {p}/{q} = {dec(p, q, 8)}   |a_{k} - b_{k}| = {dec(gap, q * 10 ** k, 8)}")
print("chart, decimals:", ", ".join(dec(A[k], 10 ** k, 6) for k in range(5)))
print("chart, Newton:  ", ", ".join(dec(p, q, 6) for p, q in B))
far_a = 3 * 10 ** 6 - 2 * A[6]                          # |a_6 - 3/2| = far_a / (2 * 10^6)
p4, q4 = B[4]
far_b = 3 * q4 - 2 * p4                                # |b_4 - 3/2| = far_b / (2 * q4)
print(f"distance from the new point to 3/2: via a_6 {dec(far_a, 2 * 10 ** 6, 8)}, via b_4 {dec(far_b, 2 * q4, 8)}")

stage = {}                                             # Cantor: nest [a_n, a_n + 10^-n]
for q in range(1, 101):
    for p in [p for p in range(q, 2 * q + 1) if gcd(p, q) == 1]:
        stage[(p, q)] = next((n for n in range(13) if p * 10 ** n < A[n] * q
                              or p * 10 ** n > (A[n] + 1) * q), None)
(lp, lq), last = max(stage.items(), key=lambda kv: (kv[1], -kv[0][1]))
print(f"Cantor nest in the rationals: {len(stage)} fractions in [1, 2] with q <= 100, "
      f"all thrown out by stage 12; the last, {lp}/{lq}, at stage {last}")
gx, gy = 3, 4                                          # street grid: corner (0, 0) to corner (3, 4)
walk, line2 = gx + gy, gx * gx + gy * gy               # walking distance, and straight distance squared
print(f"street grid, corner ({gx}, {gy}): walk {walk} blocks, straight {isqrt(line2)}; "
      f"{isqrt(line2)}^2 = {line2} <= {walk}^2 = {walk * walk} <= 2 x {isqrt(line2)}^2 = {2 * line2}")
print("mistake 1, neighbours close but not Cauchy: 1/101 + ... + 1/200 =",
      f"{sum(1.0 / k for k in range(101, 201)):.6f}, at least 100 x 1/200 = 0.5")
p2 = 1000 - 10                                         # 1/10 - 1/1000 = (1000 - 10) / (10 x 1000) = p2 / 10^4
print(f"mistake 2, 1/n in (0, 1]: d(1/10, 1/1000) = {exact(p2, 4)}; the limit 0 is not in (0, 1]")
leave = next(n for n in range(100) if n > 7.5)          # first [n, inf) without 7.5
print(f"mistake 3, closed sets [n, inf) never shrink in width: x = 7.5 leaves at n = {leave}, so none is common")
lo, hi = 10, 100
hp, hq = hi * (1 + lo) - lo * (1 + hi), (1 + lo) * (1 + hi)   # f(x) = x/(1+x): f(100) - f(10)
print(f"mistake 4, f(x) = x/(1+x): d({lo}, {hi}) = {hi - lo}, d(f({lo}), f({hi})) = {hp}/{hq} = {dec(hp, hq, 7)}")

assert all(digit_search(n) == A[n] for n in range(13))          # two roads to the decimals
assert cauchy and hits == []                                    # Cauchy, and no square root in reach
assert all(p * p - 2 * q * q == 1 for p, q in B[1:])            # Newton's squares land 1/q^2 above 2
assert all(abs(A[k] * q - p * 10 ** k) * 10 ** (k - 1) <= q * 10 ** k for k, (p, q) in enumerate(B) if k)
assert abs(far_a * q4 - far_b * 10 ** 6) * 10 ** 6 < 2 * 10 ** 6 * q4   # one distance, two roads
assert None not in stage.values()                               # every fraction leaves the nest
def inside(p, q, n):                     # nest test two: truncate p/q to n places
    k = p * 10 ** n // q
    return k == A[n] or (k == A[n] + 1 and k * q == p * 10 ** n)
assert all(s == next((n for n in range(13) if not inside(p, q, n)), None) for (p, q), s in stage.items())
print("ALL CHECKS PASS")
