# The Lebesgue differentiation theorem -- the check behind the card.
# Standard library only; fractions keeps the window averages exact.
# Demand f(t) in kW, t in minutes: 2 + t^2/200 before minute 20, 5 from 20 to 45,
# 3 from 45 to 60; the log also holds a glitch, f(30) = 100, at one instant.
# Road 1: exact window averages from the running total F, in fractions.
# Road 2: the same averages summed as a meter would: 2000 midpoint samples.
# Road 3: the closed forms worked by hand on the card.
# Maximal inequality: g = f - phi, phi the continuous ramp version of f. The set
# where the largest average of |g| beats alpha, found on a grid, against the
# bound 3 ||g||_1 / alpha, with the Vitali greedy choice run on the witnesses.
# Failures: the jump instants, the glitch, the maximal function of a block, and 1/|x|.
# The code checks windows down to h = 0.001 on grids; that averages converge at
# almost every point of every integrable f is the proof's work.
from fractions import Fraction as Fr
from math import log

def f(t):
    if t == 30: return 100.0                              # the glitch: one instant
    if t < 20: return 2 + t * t / 200
    return 5.0 if t < 45 else 3.0
def F(t):                                                 # integral of f from 0 to t
    t = Fr(t)
    if t < 20: return 2 * t + t ** 3 / 600
    return Fr(160, 3) + 5 * (t - 20) if t < 45 else Fr(535, 3) + 3 * (t - 45)
def avg(t, h): return (F(t + h) - F(t - h)) / (2 * h)       # road 1
def meter(fn, a, b, n=2000):                                # road 2: midpoint sum
    w = (b - a) / n
    return sum(fn(a + (k + 0.5) * w) for k in range(n)) * w
closed = {10: lambda h: Fr(5, 2) + h * h / 600, 20: lambda h: Fr(9, 2) - h / 20 + h * h / 1200,
          30: lambda h: 5, 45: lambda h: 4, 52: lambda h: 3}          # road 3
HS = [Fr(4), Fr(2), Fr(1), Fr(1, 4), Fr(1, 1000)]
print("windows h (minutes): 4 2 1 0.25 0.001")
for t in (10, 20, 30, 45, 52):
    row = [avg(t, h) for h in HS]
    assert all(row[i] == closed[t](HS[i]) for i in range(5))
    assert all(abs(float(row[i]) - meter(f, t - float(HS[i]), t + float(HS[i])) / (2 * float(HS[i]))) < 1e-8 for i in range(5))
    lim = (f(t - 1e-9) + f(t + 1e-9)) / 2                   # the two one-sided values
    assert abs(float(row[-1]) - lim) < 1e-3
    print(f"average at t = {t}: " + " ".join(f"{float(v):.6f}" for v in row) + f" | recorded f(t) {f(t):g}")
for h in (1, 0.001):                                      # Lebesgue-point test, roads 2 and 3
    for t, c, want in ((10, 2.5, h / 20), (20, 5, 0.5 + h / 20 - h * h / 1200), (20, 4.5, 0.5 + h / 20 - h * h / 1200),
                       (30, 100, 95), (30, 5, 0), (45, 3, 1)):
        d = meter(lambda s: abs(f(s) - c), t - h, t + h) / (2 * h)
        assert abs(d - want) < 1e-9
        print(f"spread h = {h:g}: t = {t}, value {c:g}: average of |f - value| = {d:.6f}")
q = Fr(1, 1000)
rq, lq = (F(20 + q) - F(20)) / q, (F(20) - F(20 - q)) / q
assert lq == 4 - q / 10 + q * q / 600
assert rq == 5
print(f"window [19, 21] at t = 20: left minute {float(F(20) - F(19)):.6f}, right minute {float(F(21) - F(20)):.6f}")
print(f"slopes of F at 20, h = 0.001: right {float(rq):.6f}, left {float(lq):.6f}; at 10: {float((F(10 + q) - F(10)) / q):.6f}")

def Gg(x, d):                                             # integral of |g| up to x
    u, v = min(max(x - 20, 0), d), min(max(x - 45, 0), d)
    return (u - u * u / (2 * d)) + (2 * v - v * v / d)
def phi(t, d):                                            # continuous: jumps ramped, no glitch
    if t == 30: return 5.0
    if 20 <= t < 20 + d: return 4 + (t - 20) / d
    if 45 <= t < 45 + d: return 5 - 2 * (t - 45) / d
    return f(t)
HG = [0.001]                                              # window grid 0.001 up to about 64
for _ in range(559): HG.append(HG[-1] * 1.02)
def maxavg(G, x, extra):                                  # sup over the grid of h, with witness
    return max(((G(x + h) - G(x - h)) / (2 * h), h) for h in HG + extra if h > 0)
ALPHA, D = 0.2, 1.0
n1 = meter(lambda s: abs(f(s) - phi(s, D)), 0, 60, 60000)
assert abs(n1 - 1.5 * D) < 1e-6
xs = [k * 0.05 for k in range(1201)]
wit = []
for x in xs:
    m, h = maxavg(lambda y: Gg(y, D), x, [abs(x - p) for p in (20, 20 + D, 45, 45 + D) if x != p])
    if m > ALPHA: wit.append((x - h, x + h, x))
chosen = []
for a, b, x in sorted(wit, key=lambda I: I[0] - I[1]):   # Vitali: longest first, keep if disjoint
    if all(b <= c or a >= e for c, e in chosen): chosen.append((a, b))
tot = sum(b - a for a, b in chosen)
def in3(x, J): return abs(x - (J[0] + J[1]) / 2) <= 1.5 * (J[1] - J[0])
assert all(any(in3(a, J) and in3(b, J) for J in chosen) for a, b, x in wit)
assert tot <= n1 / ALPHA
assert len(wit) * 0.05 <= 3 * tot
print(f"ramps delta = {D:g}: ||g||_1 closed form {1.5 * D:.6f}, meter {n1:.6f}")
print(f"maximal, alpha = {ALPHA}: grid points with M g > alpha: {len(wit)}, about {len(wit) * 0.05:.2f} minutes")
print(f"Vitali: {len(wit)} witness windows, {len(chosen)} chosen disjoint, total length {tot:.4f}; "
      f"3 x total {3 * tot:.4f}; bound 3 ||g||_1 / alpha = {3 * n1 / ALPHA:.4f}")
print("  chosen: " + " ".join(f"({a:.3f}, {b:.3f})" for a, b in sorted(chosen)))
for dd in (1, 4, 16, 1024):
    print(f"bad set bound, delta = 1/{dd}: 4 ||g||_1 / alpha = {4 * 1.5 / dd / ALPHA:.6f}")
print("bad set itself: t = 20, 30, 45 (spreads 0.5, 95, 1); total length 0")

def GB(x): return min(max(x, 0.0), 1.0)                   # a block: 1 on [0, 1]
for x in (2, 5, 10):
    m, _ = maxavg(GB, x, [abs(x), abs(x - 1)])
    assert abs(m - 1 / (2 * x)) < 1e-12
    print(f"block, M at x = {x}: grid sup {m:.6f}; 1/(2x) {1 / (2 * x):.6f}")
lev = sum(maxavg(GB, x, [abs(x), abs(x - 1)])[0] > 0.1 for x in [-10 + k * 0.01 for k in range(2101)]) * 0.01
assert abs(lev - 9) < 0.03
print(f"block, set where M > 0.1: grid {lev:.2f}; closed form 1/0.1 - 1 = 9; bound 3/0.1 = 30")
num = meter(lambda x: maxavg(GB, x, [abs(x), abs(x - 1)])[0], 1, 10, 900)
assert abs(num - log(10) / 2) < 1e-4
print(f"block, integral of M from 1 to 10: meter {num:.6f}; ln(10)/2 {log(10) / 2:.6f}")
print("block, integral of M from 1 to R, ln(R)/2: R = 10^3 " + f"{log(1e3) / 2:.6f}, R = 10^6 {log(1e6) / 2:.6f}")
row = []
for k in (1, 3, 6):                                       # drop local integrability: 1/|x| capped at 10^k
    cap = lambda s: min(1 / abs(s), 10 ** k)
    ends = [0.0] + [1 / 10 ** j for j in range(k, -1, -1)]   # the cap's edge, then one piece per decade
    a1 = sum(meter(cap, a, b) + meter(cap, -b, -a) for a, b in zip(ends, ends[1:])) / 2
    assert abs(a1 - (1 + log(10 ** k))) < 1e-4
    row.append(f"k = {k} meter {a1:.6f}, 1 + ln 10^k {1 + log(10 ** k):.6f}")
print("1/|x| capped at 10^k, average at 0 over h = 1: " + "; ".join(row))
print("chart, average at 20 for h = 8 4 2 1 0.5 0.25: " + " ".join(f"{float(avg(20, Fr(h))):.2f}" for h in (8, 4, 2, 1, 0.5, 0.25)))
print("chart, average at 10 for h = 8 4 2 1 0.5 0.25: " + " ".join(f"{float(avg(10, Fr(h))):.2f}" for h in (8, 4, 2, 1, 0.5, 0.25)))
pts = " ".join(f"({40 + 5 * t},{200 - 30 * f(t):.1f})" for t in (0, 4, 8, 12, 16))
print(f"figure, curve px {pts} (140,{200 - 30 * f(20 - 1e-9):.1f}); y at 5 kW {200 - 30 * f(31):.1f}, at 3 kW "
      f"{200 - 30 * f(50):.1f}; window x 120..160 top {200 - 30 * float(avg(20, 4)):.1f}; "
      f"midpoints y {200 - 15 * (f(20 - 1e-9) + f(20)):.1f} and {200 - 15 * (f(45 - 1e-9) + f(45)):.1f}")
print("ALL CHECKS PASS")
