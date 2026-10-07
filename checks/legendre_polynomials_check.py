# Legendre polynomials -- the check behind the card.  Standard library only.
# Legendre's equation: (1 - x^2) y'' - 2x y' + n(n+1) y = 0.  Road one: the
# power series, which stops at x^n when n is whole.  Road two: Bonnet's rule,
# no series.  Orthogonality: exact from coefficients, and by Simpson's rule.
# The sphere: radius 10 cm, surface held at 30 cos^2(theta) volts.
import math

def series(n, start, terms):            # a_(k+2) = (k - n)(k + n + 1) / ((k + 1)(k + 2)) a_k
    a = [0.0] * start + [1.0]
    for k in range(start, terms - 2, 2): a += [0.0, (k - n) * (k + n + 1) / ((k + 1) * (k + 2)) * a[k]]
    return a
def P(n):                               # the series of n's parity, cut at x^n, scaled so P_n(1) = 1
    a = series(n, n % 2, n + 1)
    return [ak / sum(a) + 0.0 for ak in a]
def bonnet(n):                          # (m + 1) P_(m+1) = (2m + 1) x P_m - m P_(m-1)
    p, q = [1.0], [0.0, 1.0]
    for m in range(1, n):
        p, q = q, [((2 * m + 1) * ([0.0] + q)[i] - m * (p + [0.0, 0.0])[i]) / (m + 1) for i in range(m + 2)]
    return p if n == 0 else q
def ev(c, x): return sum(ck * x ** k for k, ck in enumerate(c))
def mul(a, b): return [sum(a[i] * b[k - i] for i in range(len(a)) if 0 <= k - i < len(b)) for k in range(len(a) + len(b) - 1)]
def exact(c): return sum(2 * ck / (k + 1) for k, ck in enumerate(c) if k % 2 == 0)   # integral over [-1, 1]
def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(a + i * h) for i in range(m + 1))

Ps = [P(n) for n in range(5)]
print("before scaling, value at x = 1 for n = 2, 3, 4:", " ".join(f"{sum(series(n, n % 2, n + 1)):.4f}" for n in (2, 3, 4)), "; n = 2 coefficients:", " ".join(f"{a:.4f}" for a in series(2, 0, 3)))
for n in (2, 3, 4): print(f"P{n}, series, coefficients of x^0..x^{n}:", " ".join(f"{c:.4f}" for c in Ps[n]))
gap = max(abs(a - b) for n in range(5) for a, b in zip(Ps[n], bonnet(n)))
print(f"largest gap, series against Bonnet, P0..P4: {gap:.1e}")
G = [[exact(mul(Ps[m], Ps[n])) for n in range(5)] for m in range(5)]
S = [[simpson(lambda x: ev(Ps[m], x) * ev(Ps[n], x), -1, 1) for n in range(5)] for m in range(5)]
print("integral of P_n^2, exact:", " ".join(f"{G[n][n]:.4f}" for n in range(5)), "; 2/(2n+1):", " ".join(f"{2 / (2 * n + 1):.4f}" for n in range(5)))
off = max(abs(S[m][n]) for m in range(5) for n in range(5) if m != n)
print(f"integral of P1 P2: exact {G[1][2]:.6f}, Simpson {S[1][2] + 0.0:.6f}; largest m != n, Simpson: {off:.1e}")
errs = []
for N in (100, 200, 400):               # Euler's rule on the equation, n = 2, from x = 0 to 0.5
    x, y, v, h = 0.0, -0.5, 0.0, 0.5 / N
    for _ in range(N): x, y, v = x + h, y + h * v, v + h * (2 * x * v - 6 * y) / (1 - x * x)
    errs.append(y - ev(Ps[2], 0.5))
print(f"Euler to x = 0.5, n = 2, 100/200/400 steps: errors {errs[0]:+.5f} {errs[1]:+.5f} {errs[2]:+.5f}; P2(0.5) = {ev(Ps[2], 0.5):.4f}")
c = [(2 * n + 1) / 2 * exact(mul([0, 0, 30.0], Ps[n])) + 0.0 for n in range(5)]
cs = [(2 * n + 1) / 2 * simpson(lambda x: 30 * x * x * ev(Ps[n], x), -1, 1) for n in range(5)]
print("sphere, c0..c4 in volts, exact:", " ".join(f"{v:.4f}" for v in c), f"; Simpson gap {max(abs(a - b) for a, b in zip(c, cs)):.1e}")
avg = simpson(lambda t: 30 * math.cos(t) ** 2 * math.sin(t) / 2, 0, math.pi)
V = lambda r, ct: sum(c[n] * (r / 0.1) ** n * ev(Ps[n], ct) for n in range(5))
print(f"potential: centre {V(0, 1):.2f} V, surface average {avg:.4f} V; 5 cm, on the axis {V(0.05, 1):.2f} V, at the equator {V(0.05, 0):.2f} V")
half = [sum(series(0.5, 0, t)) for t in (11, 101, 1001)]
print("mistake, n = 0.5, series at x = 1 up to x^10, x^100, x^1000:", " ".join(f"{s:.4f}" for s in half))
print(f"mistake, weight (1 - x^2): integral of P0 P2 = {exact(mul([1, 0, -1], Ps[2])):.4f}; dropping (2n+1)/2: centre {2 * c[0]:.2f} V")
xs = [(i - 5) / 5 for i in range(11)]
for lab, f in (("P1", lambda x: ev(Ps[1], x)), ("P2", lambda x: ev(Ps[2], x)), ("P1 P2", lambda x: ev(Ps[1], x) * ev(Ps[2], x))):
    print(f"figure, {lab} at x = -1, -0.8, ..., 1:", " ".join(f"{f(x) + 0.0:.2f}" for x in xs))
assert gap < 1e-12 and max(abs(S[n][n] - 2 / (2 * n + 1)) for n in range(5)) < 1e-9 and off < 1e-9
assert abs(errs[2]) < 0.005 and 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2
assert abs(c[0] - avg) < 1e-9 and max(abs(a - b) for a, b in zip(c, cs)) < 1e-8
assert half[1] - half[2] > 0.5 and half[0] - half[1] > 0.5
print("ALL CHECKS PASS")
