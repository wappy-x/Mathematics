# Transforming a random variable -- the check behind the card.  Standard
# library only; nothing imported holds the answer.  A filling machine misses
# its 500 ml target by X ml, X normal with centre 0 and spread SIGMA = 2.
# The squared error is Y = X^2, in ml^2.  Roads: the branch-sum density; the
# CDF route, differentiated numerically; Simpson's rule on the density; a
# seeded simulation of 200,000 bottles.
from math import exp, sqrt, pi, log

SIGMA = 2.0

def phi(z):                                  # standard normal height
    return exp(-z * z / 2) / sqrt(2 * pi)
def Phi(z):                                  # standard normal area, Taylor series
    term, total = z, z
    for n in range(1, 200):
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)
def f_X(x, mu=0.0):                          # density of the fill error
    return phi((x - mu) / SIGMA) / SIGMA
def f_Y(y):                                  # road 1: add the two branches
    r = sqrt(y)
    return (f_X(r) + f_X(-r)) / (2 * r)
def F_Y(y, mu=0.0):                          # road 2: P(-sqrt y <= X <= sqrt y)
    r = sqrt(y)
    return Phi((r - mu) / SIGMA) - Phi((-r - mu) / SIGMA)
def simpson(g, a, b, n=20000):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n)))
def area(dens, a, b):                        # integral over y in [a, b]; y = t^2 tames the spike at 0
    return simpson(lambda t: dens(t * t) * 2 * t, max(sqrt(a), 1e-12), sqrt(b))

print(f"model: fill error X normal, centre 0 ml, spread {SIGMA:.1f} ml; Y = X^2 in ml^2")
print(f"formula: f_Y(1) = {f_Y(1):.6f}, f_Y(4) = {f_Y(4):.6f}, f_Y(9) = {f_Y(9):.6f} per ml^2")
print(f"by hand: f_X(1) = {f_X(1):.6f}, f_X(2) = {f_X(2):.6f}, f_X(3) = {f_X(3):.6f} per ml")
print(f"CDF route: P(Y <= 1) = {F_Y(1):.4f}, P(Y > 4) = {1 - F_Y(4):.4f}, P(Y > 9) = {1 - F_Y(9):.4f},"
      f" P(Y > 16) = {1 - F_Y(16):.4f}")
print(f"by hand: Phi(0.5) = {Phi(0.5):.5f}, Phi(1) = {Phi(1):.5f}, Phi(1.5) = {Phi(1.5):.5f}, Phi(2) = {Phi(2):.5f}")
gap = max(abs((F_Y(y + 1e-5) - F_Y(y - 1e-5)) / 2e-5 - f_Y(y)) for y in (0.5, 1, 4, 9))
print(f"slope of the CDF against the branch sum, y = 0.5, 1, 4, 9: largest gap {gap:.1e}")
lo, hi = 0.25, 16                            # median of Y by bisection on the CDF
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if F_Y(mid) < 0.5 else (lo, mid)
median = (lo + hi) / 2
print(f"median of Y by bisection: {median:.4f}; its square root {sqrt(median):.5f} ml")

# road 3: Simpson's rule on the density itself
TOP = 400.0                                  # sqrt(400) = 20 ml = 10 spreads
tot, p1, p4 = area(f_Y, 0, TOP), area(f_Y, 0, 1), area(f_Y, 4, TOP)
mean_i = area(lambda y: y * f_Y(y), 0, TOP)
var_i = area(lambda y: (y - mean_i) ** 2 * f_Y(y), 0, TOP)
band = area(f_Y, 1, 2.25)
print(f"Simpson: area {tot:.9f}, P(Y <= 1) = {p1:.4f}, P(Y > 4) = {p4:.4f}")
print(f"Simpson: mean {mean_i:.4f}, variance {var_i:.4f}, spread {sqrt(var_i):.4f}")
print(f"band 1 <= Y <= 2.25: Simpson {band:.4f}; two strips 2 x P(1 <= X <= 1.5) = {2 * (Phi(0.75) - Phi(0.5)):.4f};"
      f" strip width {1.5 - 1:.2f}, band width {2.25 - 1:.2f}")

# road 4: simulate 200,000 bottles (SplitMix64, seed 20260928; Marsaglia polar)
MASK, state = (1 << 64) - 1, 20260928
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def uniform():
    return ((splitmix() >> 11) + 0.5) / 2.0 ** 53
def normal_pair():
    while True:
        u, v = 2 * uniform() - 1, 2 * uniform() - 1
        q = u * u + v * v
        if 0 < q < 1:
            k = sqrt(-2 * log(q) / q)
            return u * k, v * k
N = 200_000
xs = [SIGMA * z for _ in range(N // 2) for z in normal_pair()]
ys = sorted(x * x for x in xs)
m_sim = sum(ys) / N
se_m = sqrt(sum((y - m_sim) ** 2 for y in ys) / (N - 1) / N)
q1, q4 = sum(y <= 1 for y in ys) / N, sum(y > 4 for y in ys) / N
se1, se4 = sqrt(q1 * (1 - q1) / N), sqrt(q4 * (1 - q4) / N)
med_sim = (ys[N // 2 - 1] + ys[N // 2]) / 2
se_med = 1 / (2 * f_Y(median) * sqrt(N))
clip0 = sum(x <= 0 for x in xs) / N          # a gauge that logs max(X, 0): the flat branch
pit = sum(Phi(x / SIGMA) <= 0.3 for x in xs) / N   # F_X(X) = Phi(X/2) should be uniform
print(f"simulated {N} bottles, seed 20260928; estimate (standard error)")
print(f"  P(Y <= 1) {q1:.4f} ({se1:.4f}), P(Y > 4) {q4:.4f} ({se4:.4f})")
print(f"  mean {m_sim:.4f} ({se_m:.4f}), median {med_sim:.4f} ({se_med:.4f})")
bins, worst = [0.5 * k for k in range(1, 21)], 0.0
sim_h = []
for c in bins:                               # histogram, bins 0.5 wide centred on c
    p_hat = sum(c - 0.25 <= y < c + 0.25 for y in ys) / N
    p_ex = F_Y(c + 0.25) - F_Y(c - 0.25)
    worst = max(worst, abs(p_hat - p_ex) / sqrt(p_ex * (1 - p_ex) / N))
    sim_h.append(100 * p_hat / 0.5)
print(f"  20 histogram bins against the CDF route: largest gap {worst:.1f} standard errors")
print(f"  F_X(X) = Phi(X/2) at most 0.3: {pit:.4f} ({sqrt(0.3 * 0.7 / N):.4f}); a uniform gives 0.3")

# what breaks
one = area(lambda y: f_X(sqrt(y)) / (2 * sqrt(y)), 0, TOP)
one4 = area(lambda y: f_X(sqrt(y)) / (2 * sqrt(y)), 4, TOP)
bare = area(lambda y: f_X(sqrt(y)) + f_X(-sqrt(y)), 0, TOP)
mean_x = simpson(lambda x: x * f_X(x), -20, 20)
print(f"mistake, one branch only: area {one:.4f}, P(Y > 4) = {one4:.4f} instead of {1 - F_Y(4):.4f}")
print(f"mistake, no stretch factor: area {bare:.4f}; 4 sigma / sqrt(2 pi) = {4 * SIGMA / sqrt(2 * pi):.4f}")
print(f"mistake, square of the average: E[X]^2 = {mean_x ** 2:.4f} instead of E[X^2] = {mean_i:.4f}")
print(f"hypothesis dropped, gauge logs max(X, 0): branch-formula area {area(lambda w: f_X(w), 0, TOP):.4f};"
      f" simulated P(reading = 0) {clip0:.4f} ({sqrt(clip0 * (1 - clip0) / N):.4f})")
print(f"try: spread 1 ml: P(Y > 4) = {1 - (Phi(2) - Phi(-2)):.4f}, mean {simpson(lambda x: x * x * phi(x), -20, 20):.4f}")
print(f"try: centre 1 ml: f_Y(4) = {(f_X(2, 1) + f_X(-2, 1)) / 4:.6f}, P(Y > 4) = {1 - F_Y(4, 1):.4f},"
      f" mean {area(lambda y: y * (f_X(sqrt(y), 1) + f_X(-sqrt(y), 1)) / (2 * sqrt(y)), 0, TOP):.4f}")
print(f"try: Y = X^3, one branch: f_Y(8) = {f_X(2) / 12:.6f}, P(Y > 8) = {1 - Phi(1):.4f}")
print(f"try: Y = |X|, no stretch: f(1) = {2 * f_X(1):.6f}, mean {simpson(lambda x: 2 * x * f_X(x), 0, 20):.4f}")

# figures: the density in percent per ml^2, and the fold drawn to scale
print("figure, y (ml^2): " + ", ".join(f"{c:.1f}" for c in bins))
print("figure, formula: " + ", ".join(f"{100 * f_Y(c):.2f}" for c in bins))
print("figure, simulated: " + ", ".join(f"{h:.2f}" for h in sim_h))
px = lambda x: 180 + 45 * x
py = lambda y: 200 - 20 * y
print(f"figure, parabola: ends ({px(-3):.0f},{py(9):.0f}) ({px(3):.0f},{py(9):.0f}), control ({px(0):.0f},{py(-9):.0f});"
      f" band y {py(2.25):.0f} to {py(1):.0f}; strips x {px(-1.5):.1f} to {px(-1):.0f} and {px(1):.0f} to {px(1.5):.1f}")

assert abs(tot - 1) < 1e-6 and abs(one - 0.5) < 1e-6
assert abs(p1 - F_Y(1)) < 1e-7 and abs(p4 - (1 - F_Y(4))) < 1e-7 and gap < 1e-5
assert abs(mean_i - SIGMA ** 2) < 1e-6 and abs(var_i - 2 * SIGMA ** 4) < 1e-4
assert abs(bare - 4 * SIGMA / sqrt(2 * pi)) < 1e-6 and abs(band - 2 * (Phi(0.75) - Phi(0.5))) < 1e-7
assert abs(f_Y(4) - exp(-4 / (2 * SIGMA ** 2)) / (SIGMA * sqrt(2 * pi * 4))) < 1e-12
assert abs(q4 - (1 - F_Y(4))) < 4 * se4 and abs(m_sim - SIGMA ** 2) < 4 * se_m
assert abs(med_sim - median) < 4 * se_med and worst < 4
assert abs(clip0 - 0.5) < 4 * sqrt(0.25 / N)
assert abs(pit - 0.3) < 4 * sqrt(0.3 * 0.7 / N)
