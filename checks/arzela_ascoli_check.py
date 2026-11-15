# Arzela-Ascoli -- the check behind the card.  Simulated archive: 100 weather
# stations x 200 days = 20,000 daily temperature curves, t in hours 0 to 24:
#     f_k(t) = m_k + a_k cos(pi (t - 15) / 12),   peak at 15:00,
# mean m_k from 12 to 18 C and half-swing a_k from 3 to 6 C, stepped by two
# irrational numbers, so the whole sequence never settles.  The code checks
# the two hypotheses, extracts a subsequence by nested balls, and names its
# limit.  Roads to each distance: the closed form |dm| + |da|, a one-minute
# grid, and readings half a step off the peak hours plus the slope term K h.
from math import sqrt, cos, sin, pi, floor

N, K = 20000, pi / 2                      # curves; shared slope bound, C per hour
AL, BE = (sqrt(5) - 1) / 2, sqrt(2) - 1   # the two irrational steps

def params(k):                            # (mean m_k, half-swing a_k), in C
    x, y = k * AL, k * BE
    return 12 + 6 * (x - floor(x)), 3 + 3 * (y - floor(y))

P = [None] + [params(k) for k in range(1, N + 1)]

def temp(k, t):
    return P[k][0] + P[k][1] * cos(pi * (t - 15) / 12)

def formula_dist(j, k):                   # exact sup distance of two curves
    return abs(P[j][0] - P[k][0]) + abs(P[j][1] - P[k][1])

MINUTE = [i / 60 for i in range(1441)]

def grid_dist(j, k):                      # sup distance on a one-minute grid
    return max(abs(temp(j, t) - temp(k, t)) for t in MINUTE)

def offpeak(j, k, h):                     # largest gap at readings half a step off 03:00 and 15:00
    return max(abs(temp(j, t) - temp(k, t)) for t in [h / 2 + i * h for i in range(round(24 / h))])

for k in (2, 27):
    print(f"chart #{k}:", " ".join(f"{temp(k, h):.1f}" for h in range(25)))

# Hypothesis 1, pointwise bounded; hypothesis 2, equicontinuous (one slope bound K)
top = max(m + a for m, a in P[1:])
bottom = min(m - a for m, a in P[1:])
grid_top = max(temp(k, t) for k in range(1, 501) for t in MINUTE)
assert abs(grid_top - max(m + a for m, a in P[1:501])) < 1e-12
assert top < 24
steep = max(abs(temp(k, t + 1 / 60) - temp(k, t)) * 60 for k in range(1, 501) for t in MINUTE[:-1])
steep_formula = max(a * pi / 12 for m, a in P[1:501])
assert 0 <= steep_formula - steep < 1e-4
assert steep_formula < K
print(f"bounded: every curve between {bottom:.3f} and {top:.3f} C; minute grid, first 500: top {grid_top:.3f}")
print(f"equicontinuous, first 500: steepest minute step {steep:.4f} C/h; formula a*pi/12 {steep_formula:.4f}; shared K = {K:.4f}")
print(f"  so one delta serves every curve: for 1 C, delta = 1/K = {60 / K:.1f} minutes")
print(f"  in Fahrenheit (F = 1.8 C + 32): ceiling {1.8 * 24 + 32:.1f} F, K = {1.8 * K:.4f} F/h")

# Extraction: stage s keeps the fullest ball of radius r around one of the
# first 30 kept curves, measured at readings every h hours, with K h <= r.
pool, picks, centres, rows = list(range(1, N + 1)), [], [], []
for s in range(6):
    r, h = 1.6 / 2 ** s, 1 / 2 ** s
    ts = [i * h for i in range(round(24 / h) + 1)]
    vals = {k: [temp(k, t) for t in ts] for k in pool}
    best = None
    for c in pool[:30]:
        ball = [k for k in pool if all(abs(x - y) <= r for x, y in zip(vals[k], vals[c]))]
        if best is None or len(ball) > len(best[1]):
            best = (c, ball)
    c, pool = best
    pick = next(k for k in pool if k > (picks[-1] if picks else 0))
    picks.append(pick)
    centres.append(c)
    hi, lo = [m + a for m, a in (P[k] for k in pool)], [m - a for m, a in (P[k] for k in pool)]
    diam = max(max(hi) - min(hi), max(lo) - min(lo))          # closed form
    band = max(max(temp(k, t) for k in pool) - min(temp(k, t) for k in pool) for t in MINUTE)
    bound = 2 * r + K * h                                    # three pieces
    assert abs(diam - band) < 1e-9 and diam <= bound
    rows.append((r, h, bound))
    print(f"stage {s + 1}: r {r:.2f} C, readings every {60 * h:g} min, centre #{c}, kept {len(pool)},"
          f" pick #{pick}, widest pair {diam:.3f} <= {bound:.3f}")
g = centres[-1]
named = rows[-1][0] + K * rows[-1][1]
print(f"limit: within {named:.4f} C everywhere of curve #{g}:"
      f" {P[g][0]:.4f} + {P[g][1]:.4f} cos(pi (t - 15) / 12)")
for s, k in enumerate(picks):
    d, off = formula_dist(k, g), offpeak(k, g, rows[s][1])
    assert abs(d - grid_dist(k, g)) < 1e-9 and off <= d <= off + K * rows[s][1] and d <= rows[s][2]
    print(f"  pick #{k}: mean {P[k][0]:.3f}, half-swing {P[k][1]:.3f}, distance to #{g} {d:.3f} (allowed {rows[s][2]:.3f})")
o1, d1 = offpeak(picks[0], g, 1), formula_dist(picks[0], g)
assert o1 < d1 <= o1 + K                  # the readings alone fall short; K h covers it
print(f"readings moved half an hour off the peaks: #{picks[0]} to #{g} reads {o1:.4f}, true {d1:.4f} <= {o1:.4f} + K = {o1 + K:.4f}")
print(f"chart limit #{g}:", " ".join(f"{temp(g, h):.1f}" for h in range(25)))
print(f"centres in order: {centres} (not increasing: not a subsequence)")
print(f"whole sequence: #{N - 1} to #{N} distance {formula_dist(N - 1, N):.3f} C")

# What breaks
for n in (10, 100, 1000):
    x = 2 ** (-1 / n)
    print(f"x^n, n={n}: inputs {1 - x:.6f} apart, values {1 - x ** n:.6f} apart")
fast = lambda k, t: 15 + 5 * sin(2 * pi * k * t / 24)
pair = []
for j in range(1, 21):
    for k in range(j + 1, 21):
        diffs = [fast(j, t) - fast(k, t) for t in MINUTE[:-1]]
        assert abs(sum(d * d for d in diffs) / 1440 - 25) < 1e-9  # mean square 25
        pair.append(max(abs(d) for d in diffs))
assert min(pair) >= 5
print(f"fast sensor 15 + 5 sin(2 pi k t / 24), k = 1..20: closest pair at least {min(pair):.3f} C apart")
print(f"  delta for 1 C: k=1 {60 * 24 / (10 * pi):.1f} min, k=20 {60 * 24 / (200 * pi):.1f} min; slope at k=20 {10 * pi * 20 / 24:.2f} C/h")
at_read = max(abs(fast(144, i / 6) - 15) for i in range(145))
print(f"k=144: off 15 C by {at_read:.6f} at every 10-min reading, by {abs(fast(144, 1 / 24) - 15):.6f} at 00:02:30")
print(f"drift 0.5 C a day: any two days at least 0.5 C apart; day 200 reads {0.5 * 199:.1f} C high")
print("ALL CHECKS PASS")
