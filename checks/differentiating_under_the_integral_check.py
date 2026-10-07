# Differentiating under the integral -- the check behind the card.  Only exp
# and e come from the standard library; every integral is the card's own
# Simpson sum.  Road one integrates x^n e^(-tx) directly; road two differentiates
# the easy total 1/t n times.  Then the bounded rule, a moving cutoff, a failure.
from math import exp, e as E                   # primitives only; every integral is ours
def simpson(g, a, b, m=6000):                  # parabolas through equal steps
    w = (b - a) / m
    return w / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * g(a + i * w) for i in range(m + 1))
def area(n, t, b=60.0): return simpson(lambda x: x ** n * exp(-t * x), 0, b)
def by_parameter(n, t):                        # (1/t) differentiated n times, sign dropped
    p = 1
    for k in range(1, n + 1): p *= k
    return p / t ** (n + 1)
for n in (1, 2, 3):
    print(f"chart n={n}:", " ".join(f"{x ** n * exp(-x):.2f}" for x in range(13)))
lad = [area(n, 1.0) for n in range(5)]
print("t=1, n=0..4, Simpson on [0, 60]: ", " ".join(f"{v:.6f}" for v in lad))
print("t=1, n=0..4, n!/t^(n+1):         ", " ".join(f"{by_parameter(n, 1.0):.6f}" for n in range(5)))
print(f"n=3, t=2: Simpson {area(3, 2.0):.6f}; 3!/2^4 {by_parameter(3, 2.0):.6f}; forget the t: 6")
F10 = lambda t: simpson(lambda x: exp(-t * x), 0, 10, 2000)
slope = simpson(lambda x: -x * exp(-x), 0, 10, 2000)
print(f"bounded rule on [0, 10] at t=1: integral of -x e^(-x) {slope:.9f}; closed -(1 - 11/e^10) {-(1 - 11 * exp(-10)):.9f}")
worst = max((x / 1000) ** 2 * exp(-(x / 1000) / 2) for x in range(10001))
miss = []
for h in (0.1, 0.01, 0.001):
    dq = (F10(1 + h) - F10(1)) / h
    miss.append((h, abs(dq - slope)))
    print(f"  difference quotient, h={h}: {dq:.9f}, off by {abs(dq - slope):.9f}; guaranteed within {10 * worst * h:.6f}")
print(f"tolerance game: worst x^2 e^(-x/2) on [0, 10] {worst:.3f}; step for 0.001: {0.001 / (10 * worst):.7f}")
cut = simpson(lambda x: x ** 3 * exp(-x), 0, 10, 2000)
closed = 6 * (1 - exp(-10) * (1 + 10 + 50 + 1000 / 6))
tail60 = 96 * exp(-30) * (1 + 30 + 450 + 4500)
print(f"n=3 cut at b=10: Simpson {cut:.6f}; endpoint-built {closed:.6f}; tail {6 - closed:.6f}; worst tail at b=60, t>=1/2: {tail60:.9f}")
J = lambda t: simpson(lambda x: x * exp(-t * x), 0, 1 / t, 2000)
inner = simpson(lambda x: -x * x * exp(-x), 0, 1, 2000)
edge = 1 * exp(-1) * -1                        # f(1, b(1)) times b'(1), b(t) = 1/t
dqJ = (J(1.0001) - J(0.9999)) / 0.0002
print(f"moving cutoff b=1/t at t=1: J {J(1.0):.6f}; inside {inner:.6f}; endpoint {edge:.6f}; sum {inner + edge:.6f}")
print(f"  J'(1) by difference quotient {dqJ:.6f}; closed -2 + 4/e {-2 + 4 / E:.6f}")
print(f"mistakes: drop the endpoint {inner:.6f}; flip its sign {inner - edge:.6f}")
bad = lambda x, t: x * t ** 3 / (x * x + t * t) ** 2 if x or t else 0.0
Fb = simpson(lambda x: bad(x, 0.01), 0, 1, 20000)
print(f"broken hypothesis: slope of total at t=0 {Fb / 0.01:.6f}; integral of slopes 0; quotient at x=t=0.01 {bad(0.01, 0.01) / 0.01:.1f}")
assert all(abs(lad[n] - by_parameter(n, 1.0)) < 1e-6 for n in range(5)) and abs(area(3, 2.0) - by_parameter(3, 2.0)) < 1e-7
assert all(m <= 10 * worst * h for h, m in miss) and miss[-1][1] < 1e-3 and abs(slope + 1 - 11 * exp(-10)) < 1e-9
assert abs(cut - closed) < 1e-8 and abs(Fb / 0.01 - 0.5) < 1e-4
assert abs(dqJ - (inner + edge)) < 1e-6 and abs(dqJ - (-2 + 4 / E)) < 1e-6
print("ALL CHECKS PASS")
