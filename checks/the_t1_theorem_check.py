# The T(1) theorem -- the check behind the card.  Standard library only.
# Operator: Calderon's first commutator for the corner A(x) = |x|, x in metres:
#   C f(x) = p.v. integral of (|x| - |y|) / (x - y)^2 f(y) dy.
# Roads: closed forms against direct quadrature, against the Mellin side.
from math import pi, log, exp, tanh, sin, sinh, atan


def sech(x):
    return 2 * exp(-abs(x)) / (1 + exp(-2 * abs(x)))


def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3


def kern(x, y):
    return (abs(x) - abs(y)) / (x - y) ** 2


def t_closed(x, R):          # C applied to the gate 1 on |y| < R, closed form
    return log(x * x / abs(x * x - R * R)) + 2 * R / (abs(x) + R)


def t_quad(x, R):            # the same, pairing y = x + u with y = x - u
    def pair(u):             # the two halves cancel exactly while u < |x|
        return 0.0 if u == 0 else sum(kern(x, y) for y in (x + u, x - u) if abs(y) < R)
    cuts = sorted({0.0, R - abs(x), R + abs(x)} | {abs(x) * 2 ** k for k in range(8) if abs(x) * 2 ** k < R})
    return sum(simpson(pair, a + 1e-12, b - 1e-12) for a, b in zip(cuts, cuts[1:]) if b > a)


print("T(1) for the corner: C applied to the gate |y| < R, minus its value at x = 1 m")
xs, Rs = [0.1, 0.5, 2.0, 5.0], [10, 1000, 100000]
for x in xs:
    d = [t_closed(x, R) - t_closed(1.0, R) for R in Rs]
    print("x = %.1f m: R = 10, 1000, 100000 give %.6f %.6f %.6f; 2 ln x = %.6f"
          % (x, d[0], d[1], d[2], 2 * log(x)))
    assert abs(d[2] - 2 * log(x)) < 1e-4 * (1 + x * x)
    q = t_quad(x, 10.0)
    assert abs(q - t_closed(x, 10.0)) < 1e-6
print("quadrature against closed form at R = 10, x = 0.5 m: %.6f %.6f"
      % (t_quad(0.5, 10.0), t_closed(0.5, 10.0)))
raw = [t_closed(1.0, R) for R in Rs]
print("raw value at x = 1 m for R = 10, 1000, 100000: %.6f %.6f %.6f" % tuple(raw))


def F(x):                    # antiderivative of ln|x|
    return x * log(abs(x)) - x if x != 0 else 0.0


def osc(a, b):               # mean oscillation of 2 ln|x| on [a, b], exactly
    m = 2 * (F(b) - F(a)) / (b - a)
    r = exp(m / 2)
    pts = [a] + [p for p in (-r, r) if a < p < b] + [b]
    G = lambda x: 2 * F(x) - m * x
    return sum(abs(G(q) - G(p)) for p, q in zip(pts, pts[1:])) / (b - a)


grid = [i / 1000 for i in range(4001)]
c0 = max(grid, key=lambda c: osc(c - 1, c + 1))
lo, hi = c0 - 0.001, c0 + 0.001
for _ in range(60):
    m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    if osc(m1 - 1, m1 + 1) < osc(m2 - 1, m2 + 1):
        lo = m1
    else:
        hi = m2
bmo = osc(lo - 1, lo + 1)
print("BMO norm of T(1) = 2 ln|x|: centred %.6f = 4/e %.6f; largest %.6f at centre/radius %.4f"
      % (osc(-1, 1), 4 / exp(1), bmo, lo))
assert abs(osc(-1, 1) - 4 / exp(1)) < 1e-12
assert abs(osc(-37 * 0.3, 37 * 1.7) - osc(-0.3, 1.7)) < 1e-9     # scale invariance
assert bmo >= osc(-1, 1) and bmo < 2


def sym(t, sgn):             # Mellin multiplier / pi on even (+1) or odd (-1) signals
    return tanh(pi * t) + sgn * 2 * t * sech(pi * t)


a, b = 0.1, 2.0              # peak: d/dt of sym(t, +1) changes sign
for _ in range(80):
    m = (a + b) / 2
    a, b = (m, b) if pi * sech(pi * m) + 2 - 2 * pi * m * tanh(pi * m) > 0 else (a, m)
peak = pi * sym(a, 1)
assert abs(peak - max(pi * sym(k / 20000, 1) for k in range(60000))) < 1e-8   # road two for the peak: a grid search
print("L2 norm of C: peak of the even-signal multiplier at tau = %.6f, norm %.6f; straight line %.6f"
      % (a, peak, pi))
for t in (0.25, a, 1.0):     # road two: the multipliers as integrals over log-distance v
    mp = 2 * simpson(lambda v: sin(t * v) / (2 * sinh(v / 2)), 1e-9, 80, 20000)
    mq = 2 * simpson(lambda v: sinh(v / 2) * sin(t * v) / (2 * (1 / sech(v / 2)) ** 2), 0, 80, 20000)
    print("tau = %.6f: P %.6f vs pi tanh %.6f; Q %.6f vs 2 pi tau sech %.6f"
          % (t, mp, pi * tanh(pi * t), mq, 2 * pi * t * sech(pi * t)))
    assert abs(mp - pi * tanh(pi * t)) < 1e-6 and abs(mq - 2 * pi * t * sech(pi * t)) < 1e-6


def gate_out(x, sgn):        # C on the even gate (sgn +1) or the odd gate (sgn -1), x > 0
    return log(x * x / abs(x * x - 1)) + 2 / (x + 1) if sgn > 0 else log((x + 1) / abs(x - 1)) - 2 / (x + 1)


def energy_time(sgn, n=40000):
    tot = 0.0
    for i in range(n):
        s = (i + 0.5) / n
        w, dw = 3 * s * s - 2 * s ** 3, 6 * s * (1 - s)
        tot += (gate_out(w, sgn) ** 2 + gate_out(1 + w, sgn) ** 2) * dw / n
        tot += gate_out(2 / s, sgn) ** 2 * 2 / (s * s) / n
    return 2 * tot


def energy_mellin(sgn, L=40.0, n=200000):
    h = L / n
    tot = sum(sym((i + 0.5) * h, sgn) ** 2 / (0.25 + ((i + 0.5) * h) ** 2) for i in range(n)) * h
    return 2 * pi * (tot + 2 * (pi / 2 - atan(2 * L)))


for name, sgn in (("even gate", 1), ("odd gate", -1)):
    e1, e2 = energy_time(sgn), energy_mellin(sgn)
    print("%s, energy 2 V^2 m in: out %.6f by time, %.6f by Mellin; stretch %.6f"
          % (name, e1, e2, (e2 / 2) ** 0.5))
    assert abs(e1 - e2) < 1e-4 and (e2 / 2) ** 0.5 < peak
wbp = 2 * simpson(lambda s: gate_out(3 * s * s - 2 * s ** 3, 1) * 6 * s * (1 - s), 1e-12, 1 - 1e-12, 20000)
print("weak boundedness: size of <C g, g> on the gate %.6f, against 2 m" % abs(wbp))
assert abs(wbp) < 1e-4
for eps in (1e-3, 1e-6):     # a positive kernel 1/|x - y| on [0, 1], gap eps
    num = 2 * simpson(lambda w: (1 - exp(w)), log(eps), 0, 20000)
    print("positive kernel, gap %.6f m: pairing %.6f by quadrature, %.6f by formula"
          % (eps, num, 2 * (log(1 / eps) - 1 + eps)))
    assert abs(num - 2 * (log(1 / eps) - 1 + eps)) < 1e-6
print("chart, tau        " + " ".join("%5.2f" % (k / 4) for k in range(11)))
print("chart, even       " + " ".join("%5.2f" % (pi * sym(k / 4, 1)) for k in range(11)))
print("chart, odd        " + " ".join("%5.2f" % (pi * sym(k / 4, -1)) for k in range(11)))
print("chart, straight   " + " ".join("%5.2f" % (pi * (tanh(pi * k / 4) ** 2 + sech(pi * k / 4) ** 2) ** 0.5) for k in range(11)))
print("ALL CHECKS PASS")
