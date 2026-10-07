# Logistic growth -- the check behind the card.  Nothing is imported but
# math.exp and math.log.  A rumour in a 1,000-pupil school: P' = 0.8 P (1 - P/1000),
# P pupils who have heard it, t in days, 10 pupils on day 0.  Road one is the
# closed form; road two steps along the slope; road three is the area under
# 1/rate, the separated equation integrated with no partial fractions.
from math import exp, log
R, K, P0 = 0.8, 1000.0, 10.0

def rate(p): return R * p * (1 - p / K)                    # the right-hand side

def closed(p0, t): return K / (1 + (K / p0 - 1) * exp(-R * t))

def euler(p0, t, h):                                       # small steps along the slope
    p = p0
    for _ in range(round(t / h)): p += h * rate(p)
    return p

def simpson(f, a, b, n=20000):                             # area under f, written out
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def slope(p, d=1e-4): return (rate(p + d) - rate(p - d)) / (2 * d)   # f' by differences
def row(xs, fmt): return " ".join(format(x, fmt) for x in xs)
A = K / P0 - 1
t_half = log(A) / R
area = simpson(lambda p: 1 / rate(p), P0, K / 2)
p, n = P0, 0
while p < K / 2: p, n = p + 0.001 * rate(p), n + 1       # step until half the school
err = [euler(P0, 6, h) - closed(P0, 6) for h in (0.1, 0.05, 0.025)]
coarse = [P0]
for _ in range(6): coarse.append(coarse[-1] + 3 * rate(coarse[-1]))
print(f"rate law P' = 0.8 P (1 - P/1000), pupils and days; A = K/P0 - 1 = {A:.0f}")
print(f"rests: rate at 0 = {rate(0):.2f}, at 1000 = {rate(K):.2f}; slope there {slope(0):+.6f} and {slope(K):+.6f} per day")
print(f"phase line signs: rate at 10 = {rate(10):.2f}, at 500 = {rate(500):.2f} (up, the fastest), at 1250 = {rate(1250):.2f} (down)")
print(f"half the school, closed form ln(99)/0.8 = {log(A):.6f}/0.8: {t_half:.6f} days")
print(f"half the school, area under 1/rate from 10 to 500: {area:.6f} days")
print(f"half the school, Euler h = 0.001: {n * 0.001:.3f} days")
print("chart, from 10, days 0 to 12:", row((closed(P0, t) for t in range(13)), ".0f"))
print("chart, from 1500, days 0 to 12:", row((closed(1500, t) for t in range(13)), ".0f"))
print(f"day 6 from 10: 99 e^(-4.8) = {A * exp(-4.8):.4f}; closed {closed(P0, 6):.2f}, Euler h = 0.001 {euler(P0, 6, 0.001):.2f}")
print(f"day 2 from 1500: A = {K / 1500 - 1:.4f}, 1 + A = {K / 1500:.4f}; closed {closed(1500, 2):.2f}, Euler h = 0.001 {euler(1500, 2, 0.001):.2f}")
print("Euler error at day 6, h = 0.1, 0.05, 0.025:", row(err, ".4f"))
print(f"never everyone: 999 pupils at day {log(A * 999) / R:.2f}; day 20 gives {closed(P0, 20):.3f}")
print(f"mistake 1, no crowding factor: 10 e^(0.8 t) at day 5.74 = {P0 * exp(R * t_half):.2f}, at day 7 = {P0 * exp(R * 7):.2f}")
print(f"mistake 2, sign of A dropped from 1500: A = {abs(K / 1500 - 1):.4f}, P(0) = {K / (1 + abs(K / 1500 - 1)):.2f}")
print("mistake 3, Euler h = 3 days from 10:", row(coarse, ".2f"))
X = lambda q: 40 + 0.24 * q; Y = lambda q: 110 - 0.4 * rate(q)   # 0.24 per pupil, 0.4 per pupil/day
print(f"figure, axis y = 110; rests at x = {X(0):.1f} and {X(K):.1f}; top at ({X(500):.1f}, {Y(500):.1f})")
print("figure, rate curve:", " ".join(f"{X(q):.1f},{Y(q):.1f}" for q in range(0, 1251, 125)))
assert abs(area - log(99) / 0.8) < 1e-6                     # separation, two ways
assert abs(n * 0.001 - t_half) < 0.01 and 1.9 < err[0] / err[1] < 2.1   # stepping, order one
assert abs(slope(0) - R) < 1e-6 and abs(slope(K) + R) < 1e-6          # 0 repels, K attracts
assert 1000 < euler(1500, 2, 0.001) < 1500 and abs(euler(1500, 2, 0.001) - closed(1500, 2)) < 0.5
print("ALL CHECKS PASS")
