# Order statistics -- the check behind the card.  Nothing imported holds the answer.
# A $1,000,000 portfolio loses L dollars a day, L ~ N(0, SIG^2) with SIG = $10,000, independent
# across N = 20 trading days.  Work in units of SIG (z = dollars / SIG).  Roads: the closed forms
# F^n and the binomial tail; Simpson's rule on the k-th density; a seeded simulation of 100,000
# months; and an exact count over every sequence of a small three-valued day, ties included.
from math import exp, log, sqrt, cos, pi
from fractions import Fraction

N, SIG, MONTHS, RHO = 20, 10000.0, 100000, 0.5

def choose(n, k):
    out = 1
    for j in range(k):
        out = out * (n - j) // (j + 1)
    return out

def phi(z):                                   # standard normal density
    return exp(-z * z / 2) / sqrt(2 * pi)

def Phi(z):                                   # its area to the left, by the odd power series
    term, s = z, z
    for k in range(250):
        term *= z * z / (2 * k + 3)
        s += term
    return 0.5 + phi(z) * s

def solve(g, target, lo=-9.0, hi=9.0):         # g increasing: bisection for g(z) = target
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) < target else (lo, mid)
    return (lo + hi) / 2

def tail(k, p, n=N):                          # P(X_(k) <= x) = P(at least k of n at or below x)
    return sum(choose(n, j) * p ** j * (1 - p) ** (n - j) for j in range(k, n + 1))

def g(k, z, n=N, coef=True):                  # density of the k-th smallest of n
    c = n * choose(n - 1, k - 1) if coef else 1
    F = Phi(z)
    return c * phi(z) * F ** (k - 1) * (1 - F) ** (n - k)

def simpson(h, a, b, m=2000):                 # Simpson's rule, m even
    w = (b - a) / m
    return w / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * h(a + i * w) for i in range(m + 1))

MASK, state = (1 << 64) - 1, 20260928         # SplitMix64, seed 20260928, same in Rust
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53

def normal():                                 # Box-Muller, cosine half only
    return sqrt(-2 * log(uniform())) * cos(2 * pi * uniform())

z99, z95 = solve(Phi, 0.99), solve(Phi, 0.95)
p_worst = 1 - Phi(z99) ** N                                # road 1: F^n
p_worst_int = 1 - simpson(lambda z: g(N, z), -8, z99)      # road 2: area under the density
p2 = tail(N - 1, Phi(z95))                                   # road 1: binomial tail
p2_int = simpson(lambda z: g(N - 1, z), -8, z95)             # road 2
med_worst = solve(lambda z: Phi(z) ** N, 0.5)
med2 = solve(lambda z: tail(N - 1, Phi(z)), 0.5)
mean_worst = simpson(lambda z: z * g(N, z), -8, 8)
mean_250 = simpson(lambda z: z * g(250, z, 250), -8, 8)
areas = [simpson(lambda z: g(k, z), -8, 8) for k in (1, 10, N - 1, N)]
u_mean = [simpson(lambda z: Phi(z) * g(k, z), -8, 8) for k in (1, 10, N - 1, N)]   # average of F(L_(k)), the uniform road
modes = [solve(lambda z: z - (k - 1) * phi(z) / Phi(z) + (N - k) * phi(z) / (1 - Phi(z)), 0.0) for k in (N - 1, N)]   # slope of log g_k is 0
p_best = 1 - (1 - Phi(-2.0)) ** N
p_median = sum(choose(N, j) for j in range(6, 15)) / 2 ** N
bare = simpson(lambda z: g(N - 1, z, coef=False), -8, 8)
p_dep = 1 - simpson(lambda c: phi(c) * Phi((z99 - sqrt(RHO) * c) / sqrt(1 - RHO)) ** N, -8, 8)

hits = {"worst": 0, "second": 0, "best": 0, "median": 0, "dep": 0}
s1 = s2 = 0.0
for _ in range(MONTHS):                       # road 3: simulate 100,000 months of 20 days
    days = sorted(normal() for _ in range(N))
    common = normal()
    worst = days[-1]
    s1, s2 = s1 + worst, s2 + worst * worst
    hits["worst"] += worst > z99
    hits["second"] += days[-2] <= z95
    hits["best"] += days[0] <= -2.0
    hits["median"] += days[5] <= 0.0 <= days[14]
    hits["dep"] += max(sqrt(RHO) * common + sqrt(1 - RHO) * d for d in days) > z99
sim = {key: v / MONTHS for key, v in hits.items()}
se = {key: sqrt(p * (1 - p) / MONTHS) for key, p in sim.items()}
sim_mean = s1 / MONTHS
se_mean = sqrt((s2 / MONTHS - sim_mean ** 2) / MONTHS)

checks = 0                                    # road 4: every 6-day sequence of down/flat/up
for t in (-1, 0, 1):
    p = Fraction(t + 2, 3)
    for k in range(1, 7):
        count = 0
        for w in range(3 ** 6):
            seq = sorted((w // 3 ** i) % 3 - 1 for i in range(6))
            count += seq[k - 1] <= t
        checks += Fraction(count, 3 ** 6) == sum(choose(6, j) * p ** j * (1 - p) ** (6 - j) for j in range(k, 7))

print(f"one-day 99% VaR: ${z99 * SIG:,.0f}; one-day 95% VaR: ${z95 * SIG:,.0f}")
print(f"P(worst of 20 <= 99% VaR) = 0.99^20 = {Phi(z99) ** N:.4f}")
print(f"P(worst of 20 > 99% VaR): formula {p_worst:.4f}, area under density {p_worst_int:.4f}, "
      f"simulated {sim['worst']:.4f} (se {se['worst']:.4f})")
print(f"median of the worst: ${med_worst * SIG:,.0f}; its 0.5^(1/20) = {0.5 ** (1 / N):.5f}")
print(f"mean of the worst: Simpson ${mean_worst * SIG:,.0f}, simulated ${sim_mean * SIG:,.0f} (se ${se_mean * SIG:,.0f})")
print(f"mean of the worst of 250 days: ${mean_250 * SIG:,.0f}")
print(f"P(2nd worst <= true 95% VaR): binomial {p2:.4f}, area under density {p2_int:.4f}, "
      f"simulated {sim['second']:.4f} (se {se['second']:.4f})")
print(f"median of the 2nd worst: ${med2 * SIG:,.0f}; peaks of the densities: 2nd worst ${modes[0] * SIG:,.0f}, worst ${modes[1] * SIG:,.0f}")
print(f"P(best day gains over $20,000): formula {p_best:.4f}, simulated {sim['best']:.4f} (se {se['best']:.4f})")
print(f"P(all 20 days are losses) = 0.5^20 = 1 in {2 ** N:,}")
print(f"P(6th <= true median 0 <= 15th): binomial {p_median:.4f}, simulated {sim['median']:.4f} (se {se['median']:.4f})")
print("areas under the densities of k = 1, 10, 19, 20: " + ", ".join(f"{a:.6f}" for a in areas))
print("average of F(L_(k)) for k = 1, 10, 19, 20: Simpson " + ", ".join(f"{m:.6f}" for m in u_mean) +
      "; k/(n + 1) " + ", ".join(f"{k / (N + 1):.6f}" for k in (1, 10, N - 1, N)))
print(f"exact count over 729 six-day sequences, ties included: {checks} of 18 rank CDFs match")
print("chart, loss $000, percent per $1,000: single day, 2nd worst, worst")
for x in range(-20, 45, 5):
    z = x / 10
    print(f"chart, {x}, {10 * phi(z):.2f}, {10 * g(N - 1, z):.2f}, {10 * g(N, z):.2f}")
print("bar, days n, percent chance the worst of n exceeds the 99% VaR: " +
      ", ".join(f"{n} {100 * (1 - Phi(z99) ** n):.2f}" for n in (1, 5, 10, 20, 60, 250)))
print(f"mistake 1, add the daily chances: 20 x 0.01 = {N * (1 - Phi(z99)):.4f}, not {p_worst:.4f}")
print(f"mistake 2, drop the coefficient 380: total area {bare:.5f}, not 1")
print(f"mistake 3, days share a common shock (rho {RHO}): P(worst > 99% VaR) = {p_dep:.4f} exact, "
      f"{sim['dep']:.4f} simulated (se {se['dep']:.4f}), not {p_worst:.4f}")
print(f"mistake 4, 2nd worst of 20 read as the 95% VaR: under ${z95 * SIG:,.0f} in {100 * p2:.2f}% of months")
assert abs(p_worst - p_worst_int) < 1e-6 and abs(p2 - p2_int) < 1e-6   # formula vs integral
assert abs(sim["worst"] - p_worst) < 4 * se["worst"] and abs(sim["second"] - p2) < 4 * se["second"]
assert abs(sim_mean - mean_worst) < 4 * se_mean and abs(sim["dep"] - p_dep) < 4 * se["dep"]
assert checks == 18 and all(abs(a - 1) < 1e-6 for a in areas) and abs(sim["best"] - p_best) < 4 * se["best"]
assert abs(sim["median"] - p_median) < 4 * se["median"]
assert max(abs(m - k / (N + 1)) for m, k in zip(u_mean, (1, 10, N - 1, N))) < 1e-6   # Simpson vs the beta law's k/(n + 1)
print("ALL CHECKS PASS")
