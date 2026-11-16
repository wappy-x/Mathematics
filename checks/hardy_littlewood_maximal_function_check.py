# Hardy-Littlewood maximal function -- the check behind the card.  Standard library only.
# A rain gauge's record for one day, illustrative: rate in mm per hour, t in hours.
# Mf(x) is the biggest average rate over windows (x - h, x + h).  Roads: the exact
# maximum over the window sizes where the average can peak, a brute-force sweep of
# 40,000 sizes, and hand values; the tent smoothing in closed form and as a blend of
# window averages; integrals with exact tails; closed forms for the single burst.
from math import log, sqrt

RAIN = [(2.0, 8.0, 1.0), (14.0, 14.1, 60.0), (15.0, 15.1, 60.0), (17.0, 18.0, 10.0)]
STORM = RAIN[1:3]                  # the two bursts on their own
ALPHA = 8.0                        # the level, mm/h

def add(xs):                       # plain left-to-right sum, as in the Rust twin
    s = 0.0
    for x in xs: s += x
    return s

def rain(rec, a, b):               # mm that fall between times a < b
    return add(r * max(0.0, min(b, e) - max(a, s)) for s, e, r in rec)

def rate(rec, x): return add(r for s, e, r in rec if s <= x < e)

def avg(rec, x, h): return rain(rec, x - h, x + h) / (2 * h)

def M(rec, x):                     # road 1: between edge distances the average is monotone in h
    best = (rate(rec, x) + add(r for s, e, r in rec if s < x <= e)) / 2      # the limit as h shrinks to 0
    for s, e, r in rec:
        for h in (abs(x - s), abs(x - e)):
            if h > 0: best = max(best, avg(rec, x, h))
    return best

def M_sweep(rec, x):               # road 2: try every h = 0.0005, 0.001, ..., 20 hours
    return max(avg(rec, x, k * 0.0005) for k in range(1, 40001))

def tent(rec, x, eps):             # road 1: smoothing by K(u) = 1 - |u| on |u| < 1, closed form
    def T(u):                      # area of the tent to the left of u
        u = max(-1.0, min(1.0, u))
        return (1 + u) * (1 + u) / 2 if u <= 0 else 1 - (1 - u) * (1 - u) / 2
    return add(r * (T((x - s) / eps) - T((x - e) / eps)) for s, e, r in rec)

def tent_blend(rec, x, eps, n=4000):   # road 2: the tent is the blend 2r dr of windows of half-width eps r
    return add(2 * ((i + 0.5) / n) * avg(rec, x, eps * (i + 0.5) / n) / n for i in range(n))

def level_length(rec, a, b, alpha, step=0.001):   # length of {Mf > alpha}, sampled at cell midpoints
    n = round((b - a) / step)
    return step * add(1.0 for k in range(n) if M(rec, a + (k + 0.5) * step) > alpha)

def integral(g, a, b, step):       # midpoint rule
    n = round((b - a) / step)
    return step * add(g(a + (k + 0.5) * step) for k in range(n))

total = rain(RAIN, -1e9, 1e9)
f2 = add(r * r * (e - s) for s, e, r in RAIN)
print(f"record: rain {total:.4f} mm; integral of f^2 {f2:.4f}; ||f||_2 {sqrt(f2):.6f}")
hand = {5.0: 28 / 26, 12.0: 2.0, 14.0: 30.0, 14.05: 60.0, 14.5: 10.0, 17.5: 10.0}
for x, want in hand.items():
    m, sw = M(RAIN, x), M_sweep(RAIN, x)
    assert abs(m - want) < 1e-9 and -1e-9 < m - sw < 0.01
    print(f"Mf({x:g}) exact {m:.6f}, sweep {sw:.6f}, by hand {want:.6f}")
print(f"Mf(12): window [6, 18] holds {rain(RAIN, 6, 18):.4f} mm over 12 h")
print("Mf(14.5), windows h 0.4 0.5 0.6 1 6:", " ".join(f"{avg(RAIN, 14.5, h):.4f}" for h in (0.4, 0.5, 0.6, 1.0, 6.0)))
xs = [13.05 + 0.1 * k for k in range(30)]
print("chart, f:", " ".join(f"{rate(RAIN, x):.0f}" for x in xs))
print("chart, Mf:", " ".join(f"{M(RAIN, x):.1f}" for x in xs))

L = level_length(RAIN, -2.0, 26.0, ALPHA)
bound = 3 * total / ALPHA
assert L <= bound and abs(L - 2.65) < 0.002        # hand: (13.725, 15.375) plus the shower
print(f"weak bound, alpha {ALPHA:g}: length of Mf > alpha {L:.3f} h; 3||f||_1/alpha {bound:.3f} h; ratio {L / bound:.4f}")
Ls, storm = level_length(STORM, 12.0, 17.0, ALPHA), rain(STORM, 0, 24)
assert abs(Ls - (1.1 + 2 * (6 / (2 * ALPHA) - 0.1))) < 0.002 and Ls > storm / ALPHA # constant 1 fails, constant 3 holds
print(f"storm alone: length of Mf > alpha {Ls:.3f} h; ||f||_1/alpha {storm / ALPHA:.3f} h; 3||f||_1/alpha {3 * storm / ALPHA:.3f} h")
dmax = 6 / (2 * ALPHA) - 0.1                       # hand: 6 mm over a window reaching the far edge
print(f"storm alone, by hand: d < 6/(2 alpha) - 0.1 = {dmax:.3f}; set ({14 - dmax:.3f}, {15.1 + dmax:.3f}), length {1.1 + 2 * dmax:.3f} h")
print(f"storm alone: rain {storm:.4f} mm; windows holding both bursts beat alpha when h < {storm / (2 * ALPHA):.3f}: ({15.1 - storm / (2 * ALPHA):.3f}, {14 + storm / (2 * ALPHA):.3f})")
print(f"storm alone: needed constant at least {Ls * ALPHA / storm:.4f}; best possible (11 + sqrt 61)/12 = {(11 + sqrt(61)) / 12:.6f}")

def Msq(x): m = M(RAIN, x); return m * m
def lineint(g, A, B, step):        # midpoint rule: cells of step on [-6, 30], edges on the jumps; 250 x step beyond
    return integral(g, -6.0, 30.0, step) + integral(g, A, -6.0, 250 * step) + integral(g, 30.0, B, 250 * step)
def norm2sq(A, B, step):           # beyond A and B Mf is 14/(18 - x) and 14/(x - 2): exact tails
    assert abs(M(RAIN, B) - 14 / (B - 2)) < 1e-15 and abs(M(RAIN, A) - 14 / (18 - A)) < 1e-15
    return lineint(Msq, A, B, step) + 196 / (B - 2) + 196 / (18 - A)
A, B = -980.0, 1000.0
Mf2, Mf2b, Mf2c = norm2sq(A, B, 1e-4), norm2sq(-480.0, 500.0, 1e-4), norm2sq(A, B, 2e-4)
assert abs(Mf2 - Mf2b) < 1e-5 and abs(Mf2 - Mf2c) < 3e-4   # a second cut-off and a doubled step must agree
print(f"integral of Mf^2: step 0.0001 h, cut-off 1000 h {Mf2:.4f}, cut-off 500 h {Mf2b:.4f}; step 0.0002 h {Mf2c:.4f}")
Cp = lambda p: 2 * (3 * p / (p - 1)) ** (1 / p)
assert sqrt(Mf2) <= Cp(2) * sqrt(f2) and Mf2 > f2
print(f"strong bound, p 2: ||Mf||_2 {sqrt(Mf2):.3f}; C_2 ||f||_2 {Cp(2) * sqrt(f2):.3f}; ratio ||Mf||_2/||f||_2 {sqrt(Mf2 / f2):.4f}; C_2 {Cp(2):.6f}")

def M1(x): return M(RAIN, x)
I1 = lineint(M1, A, B, 1e-4)
for S in (990.0, 4380.0, 438000.0):  # spans [10 - S, 10 + S]: a little over 82 days, a year, a century
    print(f"p 1: integral of Mf over {2 * S:.0f} h = {I1 + 28 * log((S + 8) / 998):.2f} mm; rain {total:.0f} mm")
burst = STORM[:1]
grid = integral(lambda x: M(burst, x) * M(burst, x), 13.1, 15.0, 0.0005) + 2 * 9 / 1.0
assert abs(grid / 360 - 1.5) < 1e-4
print(f"single burst, p 2: ratio^2 grid {grid / 360:.6f}, closed form 1 + 2^(1-p)/(p-1) = 1.500000")
for p in (2.0, 1.5, 1.1, 1.01):
    assert abs(Cp(p) ** p / (6 * p * 2 ** (p - 1) / (p - 1)) - 1) < 1e-12   # the fold's sum over levels
    print(f"single burst, p {p:g}: ||Mf||_p/||f||_p {(1 + 2 ** (1 - p) / (p - 1)) ** (1 / p):.4f}; C_p {Cp(p):.4f}")

eps_list = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 4.0, 8.0]
vals = [tent(RAIN, 14.5, e) for e in eps_list]
for e, v in zip(eps_list, vals):
    assert abs(v - tent_blend(RAIN, 14.5, e)) < 1e-5 and v <= M(RAIN, 14.5)
sup = max(tent(RAIN, 14.5, 0.01 * k) for k in range(1, 2001))
assert sup <= M(RAIN, 14.5)
print("tent at 14.5, eps", " ".join(f"{e:g}" for e in eps_list), ":", " ".join(f"{v:.4f}" for v in vals))
print(f"tent at 14.5: largest over eps = 0.01..20 {sup:.4f}; Mf(14.5) {M(RAIN, 14.5):.4f}")
for x in (5.0, 14.0, 14.05, 14.5):
    row = [tent(RAIN, x, e) for e in (1.0, 0.3, 0.1, 0.03, 0.01)]
    print(f"tent at {x:g}, eps 1 0.3 0.1 0.03 0.01: " + " ".join(f"{v:.4f}" for v in row))
assert abs(tent(RAIN, 14.0, 0.01) - 30) < 1e-9 and abs(tent(RAIN, 14.05, 0.01) - 60) < 1e-9

jumps = add(abs(r) * 2 for s, e, r in RAIN)          # each piece has two jumps of size r
print(f"jumps in the record add up to {jumps:.0f} mm/h")
for d in (0.01, 0.001):                               # phi = window average of width d: f with ramps
    phi = lambda x: rain(RAIN, x - d / 2, x + d / 2) / d
    b1 = add(integral(lambda x: abs(rate(RAIN, x) - phi(x)), j - d, j + d, d / 200)
             for s, e, r in RAIN for j in (s, e))
    assert abs(b1 - jumps * d / 4) < 1e-6
    print(f"ramps {d:g} h: ||f - phi||_1 sampled {b1:.6f}, sum of jumps x d/4 {jumps * d / 4:.6f}; bad-set bound at alpha 1: {4 * b1:.6f} h")
print("ALL CHECKS PASS")
