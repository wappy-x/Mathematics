# Summation by parts and Dirichlet's test -- the check behind the card.
# Road one adds sin(n)/n term by term.  Road two gets the target (pi - 1)/2 with
# no series: pi from Simpson's rule on 4/(1 + t^2).  Road three re-adds the same
# terms in the summation-by-parts form and must agree with road one.
from math import sin, cos, tan

def simpson(f, a, b, panels):                 # parabolas through pairs of strips
    h = (b - a) / panels
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, panels))) * h / 3

PI = simpson(lambda t: 4 / (1 + t * t), 0.0, 1.0, 2000)
target, M = (PI - 1) / 2, 1 / sin(0.5)
print(f"pi by Simpson: {PI:.9f}  target (pi-1)/2 = {target:.6f}  bound M = 1/sin(1/2) = {M:.4f}")
A, S, lo, hi, chartA, chartS = 0.0, 0.0, 9.0, -9.0, [], []
for n in range(1, 100001):
    A, S = A + sin(n), S + sin(n) / n
    assert abs(A - (cos(0.5) - cos(n + 0.5)) / (2 * sin(0.5))) < 1e-9   # telescoped closed form
    lo, hi = min(lo, A), max(hi, A)
    if n <= 16:
        chartA.append(f"{A:.2f}"); chartS.append(f"{S:.2f}")
    if n in (10, 100, 1000, 10000):
        assert abs(S - target) <= M / (n + 1)                    # Dirichlet's tail bound
        print(f"N={n}: S_N={S:.6f}  miss={target - S:+.6f}  bound M/(N+1)={M / (n + 1):.6f}")
print("chart A_n, n=1..16: " + " ".join(chartA))
print("chart S_n, n=1..16: " + " ".join(chartS))
print(f"A_n over n<=100000: lowest {lo:.4f}, highest {hi:.4f}; "
      f"exact range {-tan(0.25) / 2:.4f} to {1 / tan(0.25) / 2:.4f}")
assert -tan(0.25) / 2 - 1e-12 <= lo and hi <= 1 / tan(0.25) / 2 + 1e-12 and hi > 1.95
N = 1000                                      # road three: the identity, at N = 1000
a = [0.0] + [sin(n) for n in range(1, N + 1)]
b = [0.0] + [1 / n for n in range(1, N + 2)]
Acum = [0.0]
for n in range(1, N + 1):
    Acum.append(Acum[-1] + a[n])
direct = sum(a[n] * b[n] for n in range(1, N + 1))
parts = Acum[N] * b[N] + sum(Acum[n] * (b[n] - b[n + 1]) for n in range(1, N))
assert abs(direct - parts) < 1e-12
print(f"identity at N=1000: term by term {direct:.12f}  by parts {parts:.12f}")
abel = sum(sin(n) / n * (1 + 1 / n) for n in range(1, 200001))
sq = sum(sin(n) / n ** 2 for n in range(1, 200001))
assert abs(abel - (target + sq)) < 2 * M / 200001 + 1e-9
print(f"Abel, weights 1+1/n: {abel:.4f} = {target:.4f} + sum sin(n)/n^2 {sq:.4f}")
alt = [sum((-1) ** (k + 1) for k in range(1, n + 1)) for n in range(1, 7)]
print(f"alternating case: A_n = {alt}, so M = 1 and the miss after 10 terms is at most 1/11 = {1 / 11:.4f}")
H = sum(1 / n for n in range(1, 1001))
bounce = sum((-1) ** (n + 1) * (2 + (-1) ** n) / n for n in range(1, 1001))
assert H > 7 and bounce < -6
print(f"sin(n) alone, A_998..A_1000: {Acum[998]:.4f} {Acum[999]:.4f} {Acum[1000]:.4f}")
print(f"a_n = 1 (unbounded A_n), b_n = 1/n: H_1000 = {H:.4f}")
print(f"bouncing sizes (2+(-1)^n)/n with signs +-: total at 1000 = {bounce:.4f}")
absum = {}
t = 0.0
for n in range(1, 1000001):
    t += abs(sin(n)) / n
    if n in (100, 10000, 1000000):
        absum[n] = t
assert absum[1000000] - absum[10000] > 2.5     # grows like (2/pi) ln N: no finite total
print("sizes |sin n|/n: " + "  ".join(f"N={k}: {v:.4f}" for k, v in absum.items()))
print("ALL CHECKS PASS")
