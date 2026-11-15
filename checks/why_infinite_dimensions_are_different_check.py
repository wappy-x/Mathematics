# Infinite dimensions -- the check behind the card.  Standard library only.
# A spike e_n is a price record that is 1 GBP/MWh at hour n and 0 at every
# other hour.  Every infinite object here is a truncation: a record cut to N
# hours, shown at several N.  Only the proofs on the card cover N = infinity.
import math

def norm(v, p):                       # l1, l2 or sup size of a finite list
    if p == 0:                        # p = 0 stands for the sup size here
        return max(abs(a) for a in v)
    return sum(abs(a) ** p for a in v) ** (1.0 / p)

def spike(n, size):                   # e_n cut to `size` hours, n counts from 1
    return [1.0 if k == n else 0.0 for k in range(1, size + 1)]

def minus(u, v):
    return [a - b for a, b in zip(u, v)]

# 1. Two spikes, three size rules.
d1, d2, dsup = (norm(minus(spike(3, 10), spike(7, 10)), p) for p in (1, 2, 0))
print(f"distance from e_3 to e_7: l1 {d1:.6f}, l2 {d2:.6f}, sup {dsup:.6f}")
assert abs(d1 - 2) < 1e-12 and abs(d2 - math.sqrt(2)) < 1e-12 and abs(dsup - 1) < 1e-12

# 2. Spikes at every hour of a record of N hours: closest pair, and a greedy
#    cover by balls of radius 1/2 (a ball holds a spike within 1/2 of its centre).
for size in (10, 100, 168):
    spikes = [spike(n, size) for n in range(1, size + 1)]
    closest = min(norm(minus(spikes[i], spikes[j]), 2)
                  for i in range(size) for j in range(i + 1, size))
    centres = []
    for s in spikes:
        if all(norm(minus(s, c), 2) > 0.5 for c in centres):
            centres.append(s)
    print(f"N = {size:3d} hours: closest pair of spikes {closest:.6f}, "
          f"balls of radius 1/2 needed {len(centres)}")
    assert abs(closest - math.sqrt(2)) < 1e-12 and len(centres) == size
week = [spike((k - 1) % 168 + 1, 168) for k in range(1, 170)]
print(f"spike number 169 in a 168-hour week sits at hour {(169 - 1) % 168 + 1}; "
      f"distance to spike 1: {norm(minus(week[168], week[0]), 2):.6f}")
print(f"volume bound on points of the 168-hour ball that are sqrt 2 apart: "
      f"10^{168 * math.log10(1 + math.sqrt(2)):.2f}")

# 3. Riesz's recipe in the plane under the sup size.  M = all multiples t(1, 1).
def dist_to_line(v):                  # road one: search t on a grid of 0.0001
    best, best_t = 9.0, 0.0
    for k in range(-30000, 30001):
        t = k / 10000
        size = max(abs(v[0] - t), abs(v[1] - t))
        if size < best:
            best, best_t = size, t
    return best, best_t

z = (1.0, 0.0)
dz, tz = dist_to_line(z)
m0 = (tz, tz)
w = (z[0] - m0[0], z[1] - m0[1])
x = (w[0] / max(map(abs, w)), w[1] / max(map(abs, w)))
dx, tx = dist_to_line(x)
print(f"z = ({z[0]:.4f}, {z[1]:.4f}): distance to M {dz:.4f}, nearest point t = {tz:.4f}")
print(f"x = (z - m0) / size = ({x[0]:.4f}, {x[1]:.4f}): size {max(map(abs, x)):.4f}, "
      f"distance to M {dx:.4f}, nearest t = {tx:.4f}")
for v, dv in ((z, dz), (x, dx)):      # road two: the closed form |a - b| / 2
    assert abs(dv - abs(v[0] - v[1]) / 2) < 1e-9

# 4. y = (1, 1/2, 1/3, ...) written in the spikes.  Error after N terms is the
#    tail sqrt(sum over n > N of 1/n^2).  Road A: pi^2/6 minus the partial sum.
#    Road B: sum the tail up to 10^6 directly, plus the Euler-Maclaurin rest.
total = math.pi ** 2 / 6
print(f"size of y squared, pi^2/6 = {total:.6f}; size of y {math.sqrt(total):.6f}")
big = 10 ** 6
rest = 1 / big - 1 / (2 * big ** 2) + 1 / (6 * big ** 3)
for n_terms in (1, 10, 100, 1000, 10000):
    road_a = math.sqrt(total - sum(1 / n ** 2 for n in range(1, n_terms + 1)))
    road_b = math.sqrt(sum(1 / n ** 2 for n in range(big, n_terms, -1)) + rest)
    print(f"N = {n_terms:5d}: error {road_a:.7f} (direct tail {road_b:.7f}), "
          f"log10 N {math.log10(n_terms):.0f}, log10 error {math.log10(road_a):.3f}")
    assert abs(road_a - road_b) < 1e-9
    assert 1 / (n_terms + 1) < road_a ** 2 < 1 / n_terms
print(f"the coefficient of e_n is y_n: y_1 = {1:.4f}, y_10 = {1 / 10:.4f}, "
      f"y_100 = {1 / 100:.4f}, y_1000 = {1 / 1000:.4f}")

# 5. The sup size.  Partial sums of spikes never close in on the all-ones record,
#    and the records of 0s and 1s are 2^N points, every two exactly 1 apart.
for n_terms in (10, 100, 1000):
    ones = [1.0] * (2 * n_terms)
    partial = [1.0 if k <= n_terms else 0.0 for k in range(1, 2 * n_terms + 1)]
    gap = norm(minus(ones, partial), 0)
    print(f"all-ones record, sup size, N = {n_terms:4d}: error {gap:.6f}")
    assert gap == 1.0
for size in (4, 8, 10):                # greedy cover by balls of radius 1/2, as in 2.
    records = [[float((k >> h) & 1) for h in range(size)] for k in range(2 ** size)]
    centres, closest = [], 9.0
    for r in records:
        gaps = [norm(minus(r, c), 0) for c in centres]
        closest = min([closest] + gaps)
        if all(g > 0.5 for g in gaps):
            centres.append(r)
    print(f"N = {size:2d} hours: {len(records):4d} records of 0s and 1s, closest pair "
          f"{closest:.6f} (sup size), balls of radius 1/2 needed {len(centres)}")
    assert closest == 1.0 and len(centres) == 2 ** size

# 6. Buy 1 MWh, split over hours, at 50 + 10/n GBP/MWh in hour n (illustrative).
#    Road one: search every hour.  Road two: the last hour is cheapest.  A plan
#    spread evenly over the hours costs the average price, more than the best.
for size in (168, 1000, 10000):
    prices = [50 + 10 / n for n in range(1, size + 1)]
    best = min(range(size), key=lambda k: prices[k])
    print(f"buy 1 MWh within N = {size:5d} hours: best hour {best + 1}, "
          f"cost {prices[best]:.6f} GBP")
    assert best + 1 == size and sum(prices) / size > prices[best] > 50
print("ALL CHECKS PASS")
