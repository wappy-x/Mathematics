# Differentiating under the integral sign -- the check behind the card.
# Standard library only.  A bakery sells N e^(-z p) loaves at price p (in
# pounds) on a day whose price sensitivity is z; z is random with density
# 4 z e^(-2z), rate 2.  Profit that day: (p - c) N e^(-z p).
# The marginal average profit at p = 3 is found four ways: a formula worked
# by hand, the derivative of the average, the average of the derivative, and
# a simulation.  Then the dominating bound, the Gaussian moment trick, and
# two cases where the swap fails.
import math

N, C, RATE, P0 = 500.0, 1.0, 2.0, 3.0

def simpson(f, a, b, n):                    # composite Simpson rule, n even
    w = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * w) for i in range(1, n))
    return s * w / 3

def dens(z):                                # sensitivity density, per pound
    return RATE * RATE * z * math.exp(-RATE * z)

def avg(g):                                 # integral of g(z) dens(z) dz over [0, 40]
    return simpson(lambda z: g(z) * dens(z), 0.0, 40.0, 16000)

def profit(p, z):
    return (p - C) * N * math.exp(-z * p)

def dprofit(p, z):                          # partial derivative in p, by hand
    return N * math.exp(-z * p) * (1 - (p - C) * z)

def avg_profit(p):
    return avg(lambda z: profit(p, z))

def avg_dprofit(p):
    return avg(lambda z: dprofit(p, z))

print(f"density: total {avg(lambda z: 1.0):.6f}, mean sensitivity {avg(lambda z: z):.6f} per pound")
formula = N * RATE ** 2 * (RATE + 2 * C - P0) / (RATE + P0) ** 3
print(f"road 1, formula: Pi(3) = {N * (P0 - C) * (RATE / (RATE + P0)) ** 2:.4f}, Pi'(3) = 2000(4 - p)/(2 + p)^3 = {formula:.4f}")
for h in (0.1, 0.01, 0.001):
    q = (avg_profit(P0 + h) - avg_profit(P0 - h)) / (2 * h)
    print(f"road 2, derivative of the average: h = {h}: (Pi(3 + h) - Pi(3 - h))/2h = {q:.6f}")
assert abs(q - formula) < 1e-5
road3 = avg_dprofit(P0)
e0, e1 = avg(lambda z: math.exp(-z * P0)), avg(lambda z: z * math.exp(-z * P0))
print(f"road 3, average of the derivative: 500 x ({e0:.6f} - 2 x {e1:.6f}) = {road3:.6f}")
assert abs(road3 - formula) < 1e-6

state = 20260929                            # SplitMix64, seed 20260929
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    x = state
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((x ^ (x >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
n, s1, s2, fd = 200000, 0.0, 0.0, 0.0
for _ in range(n):
    z = (-math.log(unif()) - math.log(unif())) / RATE   # sum of two exponentials
    d = dprofit(P0, z)
    s1, s2 = s1 + d, s2 + d * d
    fd += (profit(P0 + 0.001, z) - profit(P0 - 0.001, z)) / 0.002
mean, se = s1 / n, math.sqrt((s2 / n - (s1 / n) ** 2) / n)
print(f"road 4, simulation of {n} days: average of the derivative {mean:.2f} (standard error {se:.2f}); difference quotient, same days {fd / n:.2f}")
assert abs(mean - formula) < 4 * se

g = lambda z: N * (1 + 3 * z) * math.exp(-2 * z)   # bound for p in [2, 4]
worst = max(abs(dprofit(2 + i / 50, j / 20)) / g(j / 20) for i in range(101) for j in range(801))
bound = avg(g)
print(f"bound on [2, 4]: g(z) = 500(1 + 3z)e^(-2z); largest |dy/dp|/g on a grid {worst:.4f}; integral of g = {bound:.4f}")
assert worst <= 1.0
assert abs(bound - N * (RATE ** 2 / (RATE + 2) ** 2 + 3 * 2 * RATE ** 2 / (RATE + 2) ** 3)) < 1e-6

def root(fn, lo, hi):                       # bisection: fn > 0 at lo, fn < 0 at hi
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fn(mid) > 0 else (lo, mid)
    return lo
lo = root(avg_dprofit, 2.0, 7.0)            # best price: where the average derivative is zero
print(f"best price: average derivative zero at p = {lo:.4f}, Pi = {avg_profit(lo):.4f}; formula rate + 2c = {RATE + 2 * C:.4f}")
assert abs(lo - (RATE + 2 * C)) < 1e-6

def two(v):
    return f"{0.0 if abs(v) < 0.005 else v:.2f}"
ps = [2 + k / 2 for k in range(11)]
print("chart, price: " + ", ".join(f"{p:.1f}" for p in ps))
print("chart, average profit: " + ", ".join(two(avg_profit(p)) for p in ps))
print("chart, marginal profit: " + ", ".join(two(avg_dprofit(p)) for p in ps))
print(f"average day, z = 1: profit {two(profit(P0, 1.0))}, derivative {two(dprofit(P0, 1.0))}, best price {root(lambda p: dprofit(p, 1.0), 1.0, 7.0):.2f}")

G = lambda t: simpson(lambda x: math.exp(-t * x * x), -12.0, 12.0, 2400)
m2 = simpson(lambda x: x * x * math.exp(-x * x), -12.0, 12.0, 2400)
m4 = simpson(lambda x: x ** 4 * math.exp(-x * x), -12.0, 12.0, 2400)
d1 = -(G(1.001) - G(0.999)) / 0.002
d2 = (G(1.0001) - 2 * G(1.0) + G(0.9999)) / 1e-8
rp = math.sqrt(math.pi)
print(f"gauss: G(1) = {G(1.0):.6f}, sqrt(pi) = {rp:.6f}")
print(f"gauss: -G'(1) = {d1:.6f}; integral of x^2 e^(-x^2) = {m2:.6f}; sqrt(pi)/2 = {rp / 2:.6f}")
print(f"gauss: G''(1) = {d2:.6f}; integral of x^4 e^(-x^2) = {m4:.6f}; 3 sqrt(pi)/4 = {3 * rp / 4:.6f}")
assert abs(d1 - m2) < 1e-6
assert abs(m2 - rp / 2) < 1e-10
assert abs(d2 - m4) < 1e-6
assert abs(m4 - 3 * rp / 4) < 1e-10

# breaks 1: a buyer with willingness to pay W, uniform on [1, 6], buys one loaf if W >= p
K = 500000
def per_buyer(p):                           # average of (p - 1) 1{W >= p}, midpoint rule
    return sum(p - C for i in range(K) if 1 + (i + 0.5) * 5 / K >= p) / K
true_d = (per_buyer(3.001) - per_buyer(2.999)) / 0.002
inside = sum(1.0 for i in range(K) if 1 + (i + 0.5) * 5 / K > 3) / K
print(f"breaks, threshold buyer: average profit {per_buyer(3.0):.4f}; derivative of the average {true_d:.4f}; average of the derivative {inside:.4f}")
for h in (0.1, 0.01, 0.001):
    qa = (per_buyer(3 + h) - per_buyer(3.0)) / h
    strip = sum(1 for i in range(K) if 3 <= 1 + (i + 0.5) * 5 / K < 3 + h) / K
    print(f"breaks, threshold buyer: h = {h}: quotient -2/h = {-2 / h:.0f} on a strip of probability {strip:.4f}, carrying {strip * -2 / h:.4f}; average quotient {qa:.4f}")
assert abs(true_d - 0.2) < 1e-3
assert abs(inside - true_d) > 0.3

# breaks 2: f(t, x) = t^3 e^(-t^2 x) on [0, inf): F(t) = t, but df/dt(0, x) = 0
for h in (0.1, 0.01, 0.001):
    area = simpson(lambda x: h * h * math.exp(-h * h * x), 0.0, 40 / h ** 2, 4000)
    print(f"breaks, spreading: h = {h}: quotient h^2 e^(-h^2 x) has integral {area:.6f}, value at x = 1 {h * h * math.exp(-h * h):.8f}")
    assert abs(area - 1) < 1e-6
env = max((k / 1000) ** 2 * math.exp(-(k / 1000) ** 2 * 100) for k in range(1, 1001))
print(f"breaks, spreading: largest quotient at x = 100 over h in (0, 1]: {env:.6f}; 1/(100 e) = {1 / (100 * math.e):.6f}")
assert abs(env - 1 / (100 * math.e)) < 1e-6
for X in (100, 10000, 1000000):
    print(f"breaks, spreading: 1/(e x) integrated from 1 to {X} = {math.log(X) / math.e:.4f}")
print("ALL CHECKS PASS")
