# Singular integrals and the Hilbert transform bound -- the check behind the card.
# Standard library only.  Signal: a gate g, 1 V while |t| < W/2, t in ms, W = 1 ms.
# Its Hilbert transform is Hg(t) = (1/pi) ln|(t + W/2)/(t - W/2)|, in volts.
from math import pi, sin, cos, exp, log, sinh, tan, sqrt

W = 1.0                                       # gate width, ms
c = W / 2
g = lambda t: 1.0 if abs(t) < c else 0.0
Hg = lambda t: log(abs((t + c) / (t - c))) / pi

def midpoint(f, a, b, n):                     # the integral of f from a to b, n cells
    h = (b - a) / n
    return h * sum(f(a + (k + 0.5) * h) for k in range(n))

def pv(t, e_neg, e_pos, n=400000):            # (1/pi) integral of g(t-u)/u, gap -e_neg < u < e_pos
    pos = midpoint(lambda s: g(t - exp(s)), log(e_pos), log(10.0), n)    # u = e^s > 0
    neg = midpoint(lambda s: g(t + exp(s)), log(e_neg), log(10.0), n)    # u = -e^s < 0
    return (pos - neg) / pi

def power_integral(p, n=40000):              # integral of |Hg|^p over the line, by time
    a = c ** (1 / 3)                          # t = c -+ v^3 near the spike, t = 1/w far out
    near = midpoint(lambda v: 3 * v * v * (abs(Hg(c - v ** 3)) ** p + abs(Hg(c + v ** 3)) ** p), 0, a, n)
    far = midpoint(lambda w: abs(Hg(1 / w)) ** p / (w * w), 0, 1 / (2 * c), n)
    return 2 * (near + far)

m = lambda a: 2 * W / sinh(pi * a)            # measure of {|Hg| > a}, in ms

# The partner of the gate: kernel road against the closed form, and the logarithmic spike.
for t in [0.3, 1.0, 2.0]:
    k = pv(t, 1e-6, 1e-6)
    print("Hg(%.1f ms): closed form %.6f V, kernel road %.6f V" % (t, Hg(t), k))
    assert abs(k - Hg(t)) < 1e-4
for d in [0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001]:
    print("spike: %.6f ms past the edge, Hg = %.3f V" % (d, Hg(c + d)))
print("spike growth per factor of ten closer: ln(10)/pi = %.6f V" % (log(10) / pi))

# Energy: the multiplier -i sgn has size 1, so the energy of Hg equals the energy of g, W.
L = 1000.0
fr = 2 * midpoint(lambda x: (sin(pi * W * x) / (pi * x)) ** 2, 0, L, 200000)
print("energy of g: W = %.6f V^2 ms" % W)
print("frequency road: integral of |m ghat|^2 up to %.0f kHz = %.6f, tail at most %.6f" % (L, fr, 2 / (pi * pi * L)))
assert 0 <= W - fr <= 2 / (pi * pi * L)
e_time = power_integral(2)
e_dist = midpoint(lambda a: 2 * a * m(a), 0, 30, 60000)
e_ser = 8 * W / pi ** 2 * sum(1 / (2 * k + 1) ** 2 for k in range(200000))
print("time road: integral of Hg^2 = %.6f V^2 ms" % e_time)
print("level-set road: integral of 2a m(a) da = %.6f V^2 ms" % e_dist)
print("series road: (8W/pi^2)(1 + 1/9 + 1/25 + ...) = %.6f V^2 ms" % e_ser)
assert abs(e_time - W) < 1e-6 and abs(e_dist - W) < 1e-6 and abs(e_ser - W) < 1e-5

# Level sets, weak type (1,1): m(a) = 2W/sinh(pi a), counted on a grid.
for a in [0.1, 0.5, 1.0, 2.0]:
    r = exp(pi * a)
    inner, outer = c * (r - 1) / (r + 1), c * (r + 1) / (r - 1)
    h = 1e-4
    cnt = sum(1 for k in range(-int(2 * outer / h), int(2 * outer / h)) if abs(Hg((k + 0.5) * h)) > a) * h
    print("level %.1f V: set from %.6f to %.6f ms each side; measure %.6f ms, grid count %.4f ms; a x measure %.6f V ms"
          % (a, inner, outer, m(a), cnt, a * m(a)))
    assert abs(cnt - m(a)) < 2e-3 and a * cnt < 2 * W / pi
r = exp(pi / 2)
print("by hand at level 0.5 V: r = e^(pi a) = %.6f, r - 1 = %.6f, r + 1 = %.6f, sinh(pi a) = %.6f" % (r, r - 1, r + 1, sinh(pi / 2)))
print("weak-type ratio a m(a) / ||g||_1 tends to 2/pi = %.6f as a -> 0" % (2 / pi))

# Failure in mass: the area of |Hg| inside |t| < R grows by (2W/pi) ln 10 per factor of ten.
F = lambda t: ((t + c) * log(t + c) - (t - c) * log(abs(t - c))) / pi
area = lambda R: 2 * (F(R) - F(0))
num = 2 * (midpoint(lambda v: 3 * v * v * (Hg(c - v ** 3) + Hg(c + v ** 3)), 0, c ** (1 / 3), 40000)
           + midpoint(Hg, 2 * c, 10, 200000))
print("area of g: %.6f V ms; area of |Hg| inside 10 ms: antiderivative %.6f, integral %.6f V ms" % (W, area(10), num))
assert abs(num - area(10)) < 1e-6
for R in [100, 1000, 10000]:
    print("area of |Hg| inside %d ms: %.6f V ms" % (R, area(R)))
print("growth per decade (2W/pi) ln 10 = %.6f V ms" % (2 * W * log(10) / pi))
assert abs(area(10000) - area(1000) - 2 * W * log(10) / pi) < 1e-6

# Kernel conditions for K(t) = 1/(pi t): size, smoothness (Hormander), cancellation.
for y in [1.0, 0.01]:                         # x = +-2y e^s on the two sides of |x| > 2|y|
    hor = midpoint(lambda s: y / (2 * y * exp(s) - y) + y / (2 * y * exp(s) + y), 0, 50, 100000) / pi
    print("Hormander integral at y = %.2f ms: %.6f, closed form ln(3)/pi = %.6f" % (y, hor, log(3) / pi))
    assert abs(hor - log(3) / pi) < 1e-6
def Si(x):                                    # integral of sin(u)/u from 0 to x, by its series
    term, s, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= -x * x * (2 * k - 1) / ((2 * k + 1) * (2 * k) * (2 * k + 1))
        s += term
    return s
cap = 2 / pi * Si(pi)
print("cut kernel's multiplier is at most (2/pi) Si(pi) = (2/pi) x %.6f = %.6f for every cut-off" % (Si(pi), cap))
assert abs(Si(pi) - midpoint(lambda u: sin(u) / u, 0, pi, 20000)) < 1e-8
eps = 0.001
for R in [1, 10, 100, 1000]:
    q = lambda xi: 2 / pi * (Si(2 * pi * xi * R) - Si(2 * pi * xi * eps))   # size of the cut multiplier, by Si
    direct = 2 / pi * midpoint(lambda t: sin(pi * t / R) / t, eps, R, 20000)  # (2/pi) int sin(2 pi xi t)/t dt at xi = 1/(2R)
    top = max(q(k / (2000 * R)) for k in range(1, 4001))                     # 4000 frequencies up to 2/R
    print("cut %.3f < |t| < %d ms: mass of |K| %.6f, multiplier at 1/(2R) %.6f, direct %.6f; largest up to 2/R %.6f"
          % (eps, R, 2 / pi * log(R / eps), q(1 / (2 * R)), direct, top))
    assert abs(direct - q(1 / (2 * R))) < 1e-6 and top <= cap and cap - top < 0.0021
print("lopsided gap (-eps, 2eps) at t = 0: %.6f V, true Hg(0) = %.6f V, -ln(2)/pi = %.6f"
      % (pv(0.0, eps, 2 * eps), Hg(0.0), -log(2) / pi))
assert abs(pv(0.0, eps, 2 * eps) + log(2) / pi) < 1e-4

# L^p: Riesz's theorem with the best constant cot(pi/2p) for p >= 2 (Pichorides); the gate at p = 4.
q_time, q_dist = power_integral(4), midpoint(lambda a: 4 * a ** 3 * m(a), 0, 30, 60000)
print("p = 4: integral of Hg^4 by time %.6f, by level sets %.6f; ||Hg||_4/||g||_4 = %.6f; bound cot(pi/8) = %.6f"
      % (q_time, q_dist, (q_time / W) ** 0.25, 1 / tan(pi / 8)))
assert abs(q_time - q_dist) < 1e-5 and (q_time / W) ** 0.25 <= 1 / tan(pi / 8)
print("p = 2 bound: 1, attained by every signal; p = 1: no bound (area above grows without limit)")

# Chart points.
ts = [-1.45 + 0.1 * k for k in range(30)]
print("chart t ms: [" + ", ".join("%.2f" % t for t in ts) + "]")
print("chart g V: [" + ", ".join("%.0f" % g(t) for t in ts) + "]")
print("chart Hg V: [" + ", ".join("%.3f" % Hg(t) for t in ts) + "]")
print("ALL CHECKS PASS")
