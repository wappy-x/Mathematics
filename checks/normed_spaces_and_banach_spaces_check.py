# Normed and Banach spaces -- the check behind the card.  Standard library only.
# A week is 168 hourly prices in GBP/MWh (illustrative), read as a step function of time t in hours.
from math import sqrt

BLOCKS = [55, 70, 90, 75, 120, 80]            # one day, six 4-hour blocks
DAY = [BLOCKS[h // 4] for h in range(24)]
FORECAST = DAY * 7                            # hour 0 = Monday 00:00
SPIKES = {41: 60, 42: 80, 43: 40,             # Tuesday 17:00-20:00, a wind lull
          131: -20, 132: -20, 133: -20, 134: -20}   # Saturday 11:00-15:00, sunshine
ERR = [SPIKES.get(h, 0) for h in range(168)]
ACTUAL = [f + e for f, e in zip(FORECAST, ERR)]
WIND = [e if h < 100 else 0 for h, e in enumerate(ERR)]
SUN = [e if h >= 100 else 0 for h, e in enumerate(ERR)]

def sup(x): return max(abs(v) for v in x)                 # worst hour, GBP/MWh
def one(x): return sum(abs(v) for v in x) * 1.0           # each hour lasts 1 h: GBP/MW
def two(x): return sqrt(sum(v * v for v in x) * 1.0)      # (GBP/MWh) sqrt(h)
NORMS = [("sup", sup), ("1", one), ("2", two)]
def add(x, y): return [a + b for a, b in zip(x, y)]
def scale(c, x): return [c * a for a in x]

print("the week (illustrative): forecast blocks", BLOCKS, "GBP/MWh, every day")
print(f"forecast: peak {sup(FORECAST)}  ||f||_1 = {one(FORECAST):.0f} GBP/MW  RMS {two(FORECAST) / sqrt(168):.2f} GBP/MWh")
print(f"actual:   peak {sup(ACTUAL)}  ||f||_1 = {one(ACTUAL):.0f} GBP/MW  RMS {two(ACTUAL) / sqrt(168):.2f} GBP/MWh")
s, a, r = sup(ERR), one(ERR), two(ERR)
print(f"error e:  ||e||_sup = {s} GBP/MWh  ||e||_1 = {a:.0f} GBP/MW  ||e||_2 = {r:.3f}")
# second road: the hand formula, from the seven non-zero hours only
assert s == max(60, 80, 40, 20) and a == 60 + 80 + 40 + 4 * 20
assert abs(r - sqrt(60**2 + 80**2 + 40**2 + 4 * 20**2)) < 1e-12
assert abs(two(ACTUAL) ** 2 - (7 * 4 * sum(b * b for b in BLOCKS) + 54800 - 11000)) < 1e-6
print(f"bars: worst hour {s:.2f}, RMS {r / sqrt(168):.2f}, mean absolute {a / 168:.2f} GBP/MWh")

print("rule 2, scale by c = 0.1 (to p/kWh) and c = -1:")
for name, n in NORMS:
    for c in (0.1, -1):
        assert abs(n(scale(c, ERR)) - abs(c) * n(ERR)) < 1e-9
    print(f"  ||0.1 e||_{name} = {n(scale(0.1, ERR)):.4f}   ||-e||_{name} = {n(scale(-1, ERR)):.4f}")
print("rule 3, e = wind lull + sunshine:")
for name, n in NORMS:
    lhs, rhs = n(add(WIND, SUN)), n(WIND) + n(SUN)
    assert lhs <= rhs + 1e-12
    print(f"  ||e||_{name} = {lhs:.3f} <= {n(WIND):.3f} + {n(SUN):.3f} = {rhs:.3f}")

# rules 1 to 3 on 2000 random weeks, prices -50..300 (negative prices do happen)
state = 20261115
def rng():                                    # SplitMix64
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2**64 - 1)
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return z ^ (z >> 31)
for trial in range(1000):
    x = [rng() % 351 - 50 for _ in range(168)]
    y = [rng() % 351 - 50 for _ in range(168)]
    c = (rng() % 41 - 20) / 4
    for name, n in NORMS:
        assert n(x) > 0 and n([0] * 168) == 0
        assert abs(n(scale(c, x)) - abs(c) * n(x)) < 1e-6 * (1 + n(x))
        assert n(add(x, y)) <= n(x) + n(y) + 1e-9
    assert sup(x) <= one(x) <= 168 * sup(x)
print("random weeks: 1000 pairs, rules 1-3 hold for all three norms")
print(f"sandwich: ||e||_sup x 1 h = {s} <= ||e||_1 = {a:.0f} <= 168 h x ||e||_sup = {168 * s}")

print("what breaks:")
const = [10] * 168
print(f"  range max-min of a flat +10 error: {max(const) - min(const)} (rule 1 fails, yet ||.||_1 = {one(const):.0f})")
sq = lambda x: sum(v * v for v in x)
print(f"  no square root: sum of squares of e = {sq(ERR)}, of 2e = {sq(scale(2, ERR))} (rule 2 wants {2 * sq(ERR)})")
half = lambda x: sum(sqrt(abs(v)) for v in x) ** 2
hw, hs, he = half(WIND), half(SUN), half(ERR)
assert he > hw + hs
print(f"  p = 1/2: size(e) = {he:.2f} > size(wind) + size(sun) = {hw:.2f} + {hs:.2f} = {hw + hs:.2f}")

# continuous curves: a 100 GBP/MWh jump at Tuesday 17:00 (t0 = 41 h) spread over a ramp of 1/n hour
T0, H, GRID = 41, 100, 3840                   # grid: 3840 cells per hour, all ramp ends land on it
def ramp(n, t): return H * min(1.0, max(0.0, (t - T0) * n))
def dist1(n, m):                              # midpoint rule on [t0, t0 + 1]
    return sum(abs(ramp(n, T0 + (k + 0.5) / GRID) - ramp(m, T0 + (k + 0.5) / GRID)) for k in range(GRID)) / GRID
def distsup(n, m): return max(abs(ramp(n, T0 + k / GRID) - ramp(m, T0 + k / GRID)) for k in range(GRID + 1))
print("ramps f_n (rise over 1/n h): Cauchy test ||f_n - f_2n||")
pts1, ptss = [], []
for n in (1, 2, 4, 8, 16, 32, 64):
    d1, ds = dist1(n, 2 * n), distsup(n, 2 * n)
    assert abs(d1 - 50 * (1 / n - 1 / (2 * n))) < 1e-9 and abs(ds - H / 2) < 1e-9
    pts1.append(f"{d1:.6f}"); ptss.append(f"{ds:.1f}")
    print(f"  n = {n:2d}: L1 {d1:9.6f} GBP/MW (closed form 25/n)   sup {ds:.1f} GBP/MWh")
print("chart, L1:", ", ".join(pts1)); print("chart, sup:", ", ".join(ptss))
gap = H - ramp(60, T0 + 1 / GRID)
print(f"  1-minute ramp to the step: L1 distance 50/60 = {50 / 60:.4f} GBP/MW; sup gap at t0 + 1/{GRID} h = {gap:.4f}, heading to {H}")
total = 0.0
for k in range(1, 8):                        # corrections x_k = f_(2^k) - f_(2^(k-1))
    total += dist1(2 ** (k - 1), 2 ** k)
print(f"series of corrections: sum of L1 sizes over 7 terms = {total:.6f} = 50(1 - 2^-7), limit 50; sup sizes 50 each, sum grows without bound")
assert abs(total - 50 * (1 - 2 ** -7)) < 1e-9
print("ALL CHECKS PASS")
