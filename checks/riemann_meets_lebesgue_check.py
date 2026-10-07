# Riemann meets Lebesgue -- the check behind the card.  Standard library only.
# River depth d(x) = 4x(1 - x) metres at x km along a 1 km stretch.  Road 1:
# Riemann strips in exact fractions.  Road 2: Lebesgue value slices, each level
# set an interval whose length comes from the quadratic formula.  Road 3: the
# antiderivative.  Then the depth-1-at-rationals function, Thomae's function,
# sin(x)/x on (0, infinity) and 1/sqrt(x) on (0, 1].
from fractions import Fraction as Fr
from math import gcd, sin, sqrt, pi, log

def d(x):
    return 4 * x * (1 - x)

def riemann(n):                           # lower, upper, midpoint sums on n equal strips, n even
    lo = up = mid = Fr(0)
    for k in range(n):                    # d rises to x = 1/2, a cut, then falls: extremes at the ends
        a, b = d(Fr(k, n)), d(Fr(k + 1, n))
        lo += min(a, b) / n
        up += max(a, b) / n
        mid += d(Fr(2 * k + 1, 2 * n)) / n
    return lo, up, mid

def staircase(levels):                    # integral of floor(levels * d) / levels, slice by value
    total = 0.0
    for k in range(1, levels):
        s = sqrt(1 - k / levels)          # d >= t on [(1 - s)/2, (1 + s)/2], s = sqrt(1 - t)
        total += (1 + s) / 2 - (1 - s) / 2
    return total / levels

def thomae_upper(n):                      # strip's top value is 1/q, q the least denominator in it
    total = 0.0
    for k in range(n):                    # least q with a multiple of 1/q in [k/n, (k+1)/n]
        q = 1
        while -(-k * q // n) > (k + 1) * q // n:
            q += 1
        total += 1 / q
    return total / n

def thomae_by_fractions(n):               # second road: place every p/q, q <= n, in its strips
    best = [n + 1] * n
    for q in range(1, n + 1):
        for p in range(q + 1):
            if gcd(p, q) == 1:
                j = p * n // q
                for k in ((j - 1, j) if p * n % q == 0 else (j,)):
                    if 0 <= k < n:
                        best[k] = min(best[k], q)
    total = 0.0
    for q in best:                        # a plain loop: sum() compensates, and would round differently
        total += 1 / q
    return total / n

def hump(k, panels=32):                   # integral of sin(x)/x over [k pi, (k+1) pi], Simpson
    h = pi / panels
    f = lambda x: 1.0 if x == 0 else sin(x) / x
    s = f(k * pi) + f((k + 1) * pi)
    for i in range(1, panels):
        s += (4 if i % 2 else 2) * f(k * pi + i * h)
    return s * h / 3

def simpson(f, a, b, panels):
    h = (b - a) / panels
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, panels)))

print("Riemann meets Lebesgue: river depth d(x) = 4x(1 - x) m over 1 km")
exact = Fr(2) - Fr(4, 3)                  # [2x^2 - (4/3)x^3] from 0 to 1
lo, up, mid = riemann(1000)
assert lo < exact < up and up - lo == Fr(2, 1000)          # gap: (top - bottom) twice, over n
assert mid - exact == Fr(1, 3 * 1000 ** 2)                 # midpoint error h^2 * 8 / 24
print(f"road 1, 1000 strips: lower {float(lo):.7f}, upper {float(up):.7f}, gap {float(up - lo):.3f}, midpoint {float(mid):.10f}")
print(f"road 3, antiderivative: {exact} = {float(exact):.10f}; midpoint minus exact = 1/{1 / (mid - exact)}")
prev = 0.0
for m in (2, 4, 8, 12, 16):
    st = staircase(2 ** m)
    assert prev < st < float(exact)       # simple functions below d, rising
    prev = st
    print(f"road 2, staircase with {2 ** m} value levels: {st:.7f}")
assert abs(prev - float(exact)) < 1 / 2 ** 16
print(f"all three roads, 4 places: {float(mid):.4f} {prev:.4f} {float(exact):.4f}")
print(f"figure, 8-strip lower sum {float(riemann(8)[0]):.5f}, 4-level staircase {staircase(4):.4f}")
print("figure, strip heights px:", " ".join(f"{150 * float(min(d(Fr(k, 8)), d(Fr(k + 1, 8)))):.3f}" for k in range(8)))
print("worked, lowest depth in each of 8 strips (m):", " ".join(f"{float(min(d(Fr(k, 8)), d(Fr(k + 1, 8)))):.4f}" for k in range(8)))
print("worked, length where depth >= 0.25 0.5 0.75 (km):", " ".join(f"{sqrt(1 - j / 4):.4f}" for j in (1, 2, 3)))
bands = []
for j in (1, 2, 3):
    s = sqrt(1 - j / 4)
    bands.append(f"{190 + 150 * (1 - s) / 2:.2f}-{190 + 150 * (1 + s) / 2:.2f}")
print("figure, band x px at t = 0.25 0.5 0.75:", " ".join(bands))
print("figure, curve px:", " ".join(f"{20 + 150 * j / 16:.2f},{200 - 150 * d(j / 16):.2f}" for j in range(17)))

for n in (10, 100, 1000):                 # depth 1 at rational x, 0 elsewhere
    up_q = lo_q = Fr(0)
    for k in range(n):                    # witnesses r = (2k+1)/(2n) and k/n + c sqrt(2), irrational because sqrt(2) is
        r, c = Fr(2 * k + 1, 2 * n), Fr(1, 2 * n)
        assert Fr(k, n) < r < Fr(k + 1, n) and 0 < c and 2 * c * c < Fr(1, n) ** 2   # both strictly inside the strip
        dep = [1 if cc == 0 else 0 for cc in (Fr(0), c)]   # depth at each: 1 exactly when its sqrt(2) part is 0
        up_q, lo_q = up_q + Fr(max(dep), n), lo_q + Fr(min(dep), n)   # depth is only 0 or 1: the strip's top and bottom
    assert (up_q, lo_q) == (1, 0)         # gap 1: the jumps fill the whole stretch
    print(f"rational depth, {n} strips: upper sum {up_q}, lower sum {lo_q}")
print(f"rational depth, Lebesgue: 1 x length(rationals) + 0 x length(rest) = 1 x 0 + 0 x 1 = {1 * 0 + 0 * 1}")

F = lambda Q: sum(1 for q in range(1, Q + 1) for p in range(q + 1) if gcd(p, q) == 1)
Fs = [F(Q) for Q in range(1, 201)]
for n in (10, 100, 1000, 10000):
    u = thomae_upper(n)
    bound = min(2 * Fs[Q - 1] / n + 1 / Q for Q in range(1, 201))
    assert 0 < u <= bound                 # counting fractions with small denominators
    assert n > 1000 or u == thomae_by_fractions(n)
    print(f"thomae, {n} strips: upper sum {u:.6f}, counting bound {bound:.6f}, lower sum 0")

a = [hump(k) for k in range(1001)]
S, B = [0.0], [0.0]
for k in range(1001):
    S.append(S[-1] + a[k])
    B.append(B[-1] + abs(a[k]))
    assert abs(a[k]) >= 2 / ((k + 1) * pi) and (a[k] > 0) == (k % 2 == 0)
half_pi = 2 * simpson(lambda t: 1 / (1 + t * t), 0.0, 1.0, 1000)
avg = (S[1000] + S[1001]) / 2
assert abs(avg - half_pi) < 1e-6          # humps against the Laplace road, 2 * integral of 1/(1+t^2)
print(f"sin x/x, first humps: {a[0]:.6f} {a[1]:.6f} {a[2]:.6f} {a[3]:.6f}")
print(f"sin x/x, improper integral: humps {avg:.6f}, Laplace road {half_pi:.6f}, pi/2 {pi / 2:.6f}")
H = sum(1 / k for k in range(1, 1001))
assert B[1000] >= 2 / pi * H              # each hump at least 2 / ((k+1) pi)
pos = sum(a[k] for k in range(0, 1000, 2))
print(f"|sin x/x| over 1000 humps: {B[1000]:.4f}, floor (2/pi) x H_1000 = {2 / pi * H:.4f}; ln 1000 = {log(1000):.4f}")
print(f"positive part over 1000 humps {pos:.4f}, negative part {pos - S[1000]:.4f}: both grow without limit")
Ns = [1, 2, 3, 4, 5, 10, 20, 50, 100, 200, 500, 1000]
print("chart, signed to N humps:", " ".join(f"{S[N]:.2f}" for N in Ns))
print("chart, absolute to N humps:", " ".join(f"{B[N]:.2f}" for N in Ns))
J = 50000                                 # exhaust (0, infinity) as 2 positive humps, then 1 negative
tot = sum(hump(2 * i) for i in range(2 * J)) + sum(hump(2 * i + 1) for i in range(J))
target = pi / 2 + log(2) / pi             # rearranged alternating series: shift (c/2) ln(p/q), c = 2/pi
assert abs(tot - target) < 1e-4
print(f"sin x/x, two positive humps per negative, {3 * J} humps: {tot:.5f}; pi/2 + ln 2 / pi = {target:.5f}")

for n in (10, 100, 1000):                 # 1/sqrt(x): continuous on (0, 1], unbounded at 0
    low = sum(1 / sqrt(n * k) for k in range(1, n + 1))
    assert low < 2 - 1 / sqrt(n) + 1e-12  # sum of k^(-1/2) <= 2 sqrt(n) - 1
    print(f"1/sqrt(x), {n} strips: lower sum {low:.4f}, upper sum infinite (first strip)")
print("1/sqrt(x), Lebesgue by truncation min(f, m), m = 10 100 1000:", " ".join(f"{2 - 1 / m:.3f}" for m in (10, 100, 1000)))
print("All checks passed.")
