# Hardy space H1 and its duality with BMO -- the check behind the card.
# Standard library only.  x counts milliseconds; signals are in volts.
# Atom pair a = +1 V on (0, 1), -1 V on (-1, 0).  Gate b = 1 V on (0, 1).  phi(x) = log|x - 1/2|.
from math import pi, log, exp, sqrt, e

Ha = lambda x: log(x * x / abs(x * x - 1)) / pi     # Hilbert transform of a, closed form
Hb = lambda x: log(abs(x / (x - 1))) / pi           # Hilbert transform of b, closed form
a = lambda x: (1.0 if 0 < x < 1 else 0.0) - (1.0 if -1 < x < 0 else 0.0)

def midpoint(f, lo, hi, n):                          # integral of f from lo to hi, n cells
    h = (hi - lo) / n
    return h * sum(f(lo + (k + 0.5) * h) for k in range(n))

def pv(x, n=400000):                                 # (1/pi) p.v. integral of a(x - u)/u du
    pos = midpoint(lambda s: a(x - exp(s)), log(1e-6), log(20.0), n)
    neg = midpoint(lambda s: a(x + exp(s)), log(1e-6), log(20.0), n)
    return (pos - neg) / pi

for x in [0.3, 1.5, 3.0, 10.0]:
    k = pv(x)
    print("Ha(%.1f): closed form %.6f V, kernel road %.6f V" % (x, Ha(x), k))
    assert abs(k - Ha(x)) < 1e-4
for x in [10.0, 100.0]:
    print("tail at x = %d: x^2 Ha = %.6f, x Hb = %.6f, 1/pi = %.6f" % (x, x * x * Ha(x), x * Hb(x), 1 / pi))
assert abs(100 ** 2 * Ha(100) - 1 / pi) < 1e-4
assert abs(100 * Hb(100) - 1 / pi) < 2e-3
for k in range(1, 7):                                # chart points: log10 of the two tails
    x = 10 ** (k / 2)
    print("chart log10 x = %.1f: log10 Ha = %.3f, log10 Hb = %.3f" % (k / 2, log(Ha(x)) / log(10), log(Hb(x)) / log(10)))

# Area of |Ha|: antiderivative G against the integrator on four pieces of x > 0 (Ha is even).
G = lambda x: 2 * x * log(x) - (x - 1) * log(abs(x - 1)) - (x + 1) * log(x + 1)
def pieces(f, n=200000):                             # integrals over (0,1/2), (1/2,1), (1,2), (2,inf)
    r = sqrt(0.5)                                    # x = v^2 or 1 -+ v^2 near the log spikes, x = 1/w far out
    return [midpoint(lambda v: 2 * v * f(v * v), 0, r, n), midpoint(lambda v: 2 * v * f(1 - v * v), 0, r, n),
            midpoint(lambda v: 2 * v * f(1 + v * v), 0, 1, n), midpoint(lambda w: f(1 / w) / (w * w), 0, 0.5, n)]
s = 1 / sqrt(2)                                      # Ha changes sign at 1/sqrt(2)
P_abs, P = pieces(lambda x: abs(Ha(x))), pieces(Ha)
area_exact, area_num = -4 * G(s) / pi, 2 * sum(P_abs)
print("Ha changes sign at x = %.6f, where G = %.6f" % (s, G(s)))
print("area of |Ha|: antiderivative %.6f, integrator %.6f V ms" % (area_exact, area_num))
print("size of the total of Ha: integrator %.6f V ms (antiderivative: exactly 0)" % abs(2 * sum(P)))
assert abs(area_num - area_exact) < 1e-5
assert abs(2 * sum(P)) < 1e-5
near, far = 2 * sum(P_abs[:3]), 2 * P_abs[3]
B = log(3) / pi                                      # Hormander constant of 1/(pi t)
hor = midpoint(lambda v: 1 / (2 * exp(v) - 1) + 1 / (2 * exp(v) + 1), 0, 50, 100000) / pi   # its integral, x = +-2e^v
print("Hormander constant B: ln 3/pi = %.6f; integral of |K(x - 1) - K(x)| over |x| > 2 = %.6f" % (B, hor))
assert abs(hor - B) < 1e-6
print("near part |x| < 2: %.6f, bound 2 sqrt 2 = %.6f; far part: %.6f, bound 2B = %.6f" % (near, 2 * sqrt(2), far, 2 * B))
assert abs(far - 2 * -G(2) / pi) < 1e-5
assert near < 2 * sqrt(2)
assert far < 2 * B
print("atom bound for a = 2(sqrt 2 + B), also the L-infinity to BMO constant: %.6f; true area %.6f; ratio %.6f" % (2 * sqrt(2) + 2 * B, area_exact, area_exact / (2 * sqrt(2) + 2 * B)))

# The gate fails: the area of |Hb| inside |x| < R grows by (2/pi) ln 10 per factor of ten.
K = lambda x: x * log(abs(x)) - (x - 1) * log(abs(x - 1))
gate_area = lambda R: (K(R) + K(-R) - 2 * K(0.5)) / pi
hb = lambda x: abs(Hb(x))
num = (midpoint(lambda v: 2 * v * hb(-v * v), 0, sqrt(10), 400000) + midpoint(lambda v: 2 * v * hb(v * v), 0, sqrt(0.5), 200000)
       + midpoint(lambda v: 2 * v * hb(1 - v * v), 0, sqrt(0.5), 200000) + midpoint(lambda v: 2 * v * hb(1 + v * v), 0, 3, 400000))
print("area of |Hb| inside |x| < 10: antiderivative %.6f, integrator %.6f V ms" % (gate_area(10), num))
assert abs(num - gate_area(10)) < 1e-4
print("area of |Hb| inside 100, 1000, 10000: %.6f, %.6f, %.6f V ms" % tuple(gate_area(R) for R in [100, 1000, 10000]))
L = lambda x: (x + 1) * log(abs(x + 1)) - x * log(abs(x))     # pi times antiderivative of H of 1 on (-1, 0)
def decade(w):                                       # area of |H(b - w c)| added between 1000 and 10000, both sides
    P2 = lambda x: (K(x) - w * L(x)) / pi
    return abs(P2(1e4) - P2(1e3)) + abs(P2(-1e3) - P2(-1e4))
for w, name in [(0.0, "gate b"), (0.9, "10% imbalance"), (1.0, "atom pair a")]:
    print("decade 1000 to 10000, %s: %.6f V ms" % (name, decade(w)))
assert abs(decade(0.9) - 0.1 * 2 * log(10) / pi) < 1e-4
assert abs(decade(1.0) - (2 / pi) * (1e-3 - 1e-4)) < 1e-6

# Pairing a with phi(x) = log|x - 1/2|: exact, integrator, and through the Hilbert transform.
F = lambda x: x * log(abs(x)) - x if x != 0 else 0.0        # antiderivative of log|x|
right, left = F(0.5) - F(-0.5), F(1.5) - F(0.5)              # integrals of phi over (0,1) and (-1,0)
pair = right - left
print("hand steps: ln 2 = %.6f, ln 1.5 = %.6f, ln 3 = %.6f, 0.5 ln 0.5 - 0.5 = %.6f, 1.5 ln 1.5 - 1.5 = %.6f"
      % (log(2), log(1.5), log(3), F(0.5), F(1.5)))
num_r = 2 * midpoint(lambda v: 2 * v * log(v * v), 0, sqrt(0.5), 200000)
num_l = midpoint(lambda x: log(abs(x - 0.5)), -1, 0, 200000)
print("phi over (0,1): %.6f; over (-1,0): %.6f; pairing %.6f V ms, -1.5 ln 3 = %.6f" % (right, left, pair, -1.5 * log(3)))
road_H = -(pi / 2) * (sum(P[1:]) - (sum(P) + P[0]))         # -(pi/2) integral of Ha(x) sgn(x - 1/2)
print("pairing by integrator %.6f; by Hilbert road -(pi/2) int Ha sgn(x - 1/2): %.6f V ms" % (num_r - num_l, road_H))
assert abs(pair + 1.5 * log(3)) < 1e-12
assert abs(num_r - num_l - pair) < 1e-5
assert abs(road_H - pair) < 1e-5

# Mean oscillation of log|x| on (lo, hi): exact by splitting where the sign of log|x| - mean changes.
def osc(lo, hi):
    m = (F(hi) - F(lo)) / (hi - lo)
    cuts = sorted([lo, hi] + [p for p in (-exp(m), 0.0, exp(m)) if lo < p < hi])
    return m, sum(abs(F(v) - F(u) - m * (v - u)) for u, v in zip(cuts, cuts[1:])) / (hi - lo)
m, o = osc(-1.5, 0.5)                                        # phi on I = (-1, 1) is log|u| on (-1.5, 0.5)
o_num = (midpoint(lambda v: 2 * v * abs(log(v * v) - m), 0, sqrt(1.5), 200000)
         + midpoint(lambda v: 2 * v * abs(log(v * v) - m), 0, sqrt(0.5), 200000)) / 2
print("on I = (-1,1): mean of phi %.6f, mean oscillation exact %.6f, integrator %.6f" % (m, o, o_num))
assert abs(o_num - o) < 1e-5
print("atom bound 2 x oscillation = %.6f >= |pairing| %.6f, ratio %.6f" % (2 * o, -pair, -pair / (2 * o)))
assert -pair <= 2 * o
best = max((osc(k / 1000 - 1, k / 1000 + 1)[1], k / 1000) for k in range(4001))   # centre/radius 0 to 4
lo, hi = best[1] - 0.001, best[1] + 0.001
for _ in range(60):                                          # golden-section search for the peak
    p, q = hi - (hi - lo) * 0.618034, lo + (hi - lo) * 0.618034
    lo, hi = (lo, q) if osc(p - 1, p + 1)[1] > osc(q - 1, q + 1)[1] else (p, hi)
bmo = osc(lo - 1, lo + 1)[1]
print("BMO norm of log|x|: centred intervals %.6f = 2/e %.6f; largest %.6f at centre/radius %.4f" % (osc(-1, 1)[1], 2 / e, bmo, lo))
assert abs(osc(-1, 1)[1] - 2 / e) < 1e-12
assert bmo >= best[0]
assert bmo >= o
grid = max(osc(k / 1000 - 1, 1.0)[1] for k in range(2000))  # road 2: intervals [u, 1], u = -1 to 0.999
print("BMO norm, second road: largest over 2000 intervals [u, 1]: %.6f" % grid)
assert -1e-12 < bmo - grid < 1e-5
print("duality bound |pairing| <= 2 x BMO norm = %.6f; Hilbert-road bound (pi/2) x area |Ha| = %.6f" % (2 * bmo, pi / 2 * area_exact))

# L1 is not enough: gates of area 1 squeezed onto phi's spike pair to log(eps/2) - 1, without limit.
for eps in [0.1, 0.01, 0.001]:
    print("gate of width %.3f at 1/2, area 1: pairing %.6f" % (eps, log(eps / 2) - 1))
nar = 2 * midpoint(lambda v: 2 * v * log(v * v), 0, sqrt(0.05), 200000) / 0.1
assert abs(nar - (log(0.05) - 1)) < 1e-5
print("ALL CHECKS PASS")
