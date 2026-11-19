# Exterior derivative on the valley wind -- the check behind the card.  Standard library only.
# x east, y north, z up, in metres; the mast M stands at (200, 300, 50).  Three roads:
# (1) the rule by hand, (2) sums round small boxes with no derivatives at all,
# (3) one general d by central differences, in the map chart and in a terrain-following chart.
from itertools import combinations, permutations

def P(x, y, z): return 0.001 * x - 0.0006 * y + 0.004 * z            # east wind, m/s
def Q(x, y, z): return 4 + 0.0003 * y + 0.01 * z - 0.000004 * x * x  # north wind, along the valley
def R(x, y, z): return 0.0005 * x - 0.0013 * z                       # upward wind
def T(x, y, z): return 20 + 0.003 * x - 0.0065 * z                   # air temperature, degC
M, MS, H = (200.0, 300.0, 50.0), (200.0, 300.0, 30.0), 0.01           # MS: the mast in the terrain chart
def cl(v): return 0.0 if abs(v) < 1e-8 else v
def f6(*vs): return " ".join(f"{cl(v):.6f}" for v in vs)

def hand(x, y, z):            # road 1: the rule by hand, each rate read off the formulas above
    Px, Py, Pz, Qx, Qy, Qz, Rx, Ry, Rz = 0.001, -0.0006, 0.004, -0.000008 * x, 0.0003, 0.01, 0.0005, 0.0, -0.0013
    return (0.003, 0.0, -0.0065), (Ry - Qz, Pz - Rx, Qx - Py), Px + Qy + Rz, (Px, Qy, Rz), Qx + Py

# A k-form is a dict {sorted index tuple: coefficient function}; 0, 1, 2 stand for dx, dy, dz.
def partial(f, j, p, h=H):
    a, b = list(p), list(p); a[j] += h; b[j] -= h
    return (f(*a) - f(*b)) / (2 * h)
def d(form, signed=True):     # road 3: the one rule, for every degree; signed=False drops the sign rule
    terms = {}
    for I, f in form.items():
        for j in range(3):
            if j in I: continue                               # dx^j wedge dx^j = 0
            sign = (-1) ** sum(1 for i in I if i < j) if signed else 1   # each swap past a smaller dx^i flips the sign
            terms.setdefault(tuple(sorted(I + (j,))), []).append((sign, f, j))
    return {J: (lambda *p, t=t: sum(s * partial(f, j, p) for s, f, j in t)) for J, t in terms.items()}
def sgn(pm): return (-1) ** sum(1 for a in range(len(pm)) for b in range(a + 1, len(pm)) if pm[a] > pm[b])
def det(m):
    out = 0.0
    for pm in permutations(range(len(m))):
        t = sgn(pm)
        for r in range(len(m)): t *= m[r][pm[r]]
        out += t
    return out
def chart(x, y, s, k=0.0005): return (x, y, s + k * x * x)     # s: height above the valley floor k x^2
def pull(form, k=0.0005):     # pullback to (x, y, s): coefficients times minors of the chart's Jacobian
    def coeff(A):
        def c(*q):
            J = [[partial(lambda *u: chart(*u, k)[i], a, q) for a in range(3)] for i in range(3)]
            return sum(f(*chart(*q, k)) * det([[J[i][a] for a in A] for i in I]) for I, f in form.items())
        return c
    return {A: coeff(A) for A in combinations(range(3), len(next(iter(form))))}

temp, omega = {(): T}, {(0,): P, (1,): Q, (2,): R}
Phi = {(1, 2): P, (0, 2): lambda *p: -Q(*p), (0, 1): R}      # P dy^dz + Q dz^dx + R dx^dy
gT, curl, div, own, swapped = hand(*M)
print(f"mast M (200, 300, 50) m: wind {f6(P(*M), Q(*M), R(*M))} m/s, T {T(*M):.6f} degC")
print(f"road 1, dT = gradient (dx dy dz): {f6(*gT)} degC/m; dT(wind) {gT[0] * P(*M) + gT[2] * R(*M):.7f} degC/s"
      f" = {(gT[0] * P(*M) + gT[2] * R(*M)) * 3600:.6f} degC/h")
print(f"road 1, d omega = curl (dy^dz dz^dx dx^dy): {f6(*curl)} per s; spin {f6(*[c / 2 for c in curl])} rad/s")
turn = 2 * 3.141592653589793 / abs(curl[0] / 2)
print(f"  rates (x y z): P 0.001000 -0.000600 0.004000; Q {-0.000008 * M[0]:.6f} 0.000300 0.010000; R 0.000500 0.000000 -0.001300")
print(f"  east-west spin: a turn in {turn:.1f} s = {turn / 60:.1f} min")
print(f"road 1, d Phi = div (dx^dy^dz): {f6(div)} per s = {f6(own[0])} + {f6(own[1])} + {f6(own[2])}")
g0, g1, g2 = d(temp), d(omega), d(Phi)
r3 = ([g0[(i,)](*M) for i in range(3)], [g1[(1, 2)](*M), -g1[(0, 2)](*M), g1[(0, 1)](*M)], g2[(0, 1, 2)](*M))
print(f"road 3, general d: dT {f6(*r3[0])}; d omega {f6(*r3[1])}; d Phi {f6(r3[2])}")
for a, b in zip(gT + curl + (div,), r3[0] + r3[1] + [r3[2]]): assert abs(a - b) < 1e-9

def simpson(g, a, b, n=4):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n)))
def pt(*moves):
    p = list(M)
    for ax, amt in moves: p[ax] += amt
    return p
F = (P, Q, R)
def circ(i, j, L):            # walk the L-square round M in the plane of axes i, j, turning from i towards j
    a = L / 2
    return (simpson(lambda u: F[i](*pt((i, u), (j, -a))) - F[i](*pt((i, u), (j, a))), -a, a)
            + simpson(lambda v: F[j](*pt((i, a), (j, v))) - F[j](*pt((i, -a), (j, v))), -a, a))
def outflow(k, L):            # net air leaving the L-cube through its two faces across axis k, m^3/s
    i, j = [m for m in range(3) if m != k]; a = L / 2
    return simpson(lambda u: simpson(lambda v: F[k](*pt((k, a), (i, u), (j, v)))
                                     - F[k](*pt((k, -a), (i, u), (j, v))), -a, a), -a, a)
L = 10.0
seg = [(T(*pt((0, L))) - T(*M)) / L, (T(*pt((2, L))) - T(*M)) / L]
cs, fl = [circ(1, 2, L), circ(2, 0, L), circ(0, 1, L)], [outflow(k, L) for k in range(3)]
print(f"road 2, 10 m east and up: T changes {f6(*seg)} degC/m")
print(f"road 2, 10 m squares: circulation {f6(*cs)} m^2/s; per area {f6(*[c / L ** 2 for c in cs])}")
print(f"road 2, 10 m cube: outflow east-west {f6(fl[0])}, north-south {f6(fl[1])}, top-bottom {f6(fl[2])},"
      f" total {f6(sum(fl))} m^3/s")
assert abs(seg[0] - gT[0]) < 1e-12 and abs(seg[1] - gT[2]) < 1e-12
for c, h in zip(cs, curl): assert abs(c / L ** 2 - h) < 1e-12        # Stokes in the small, degree 1
for f, h in zip(fl, own): assert abs(f / L ** 3 - h) < 1e-12          # Stokes in the small, degree 2
cs100 = [circ(1, 2, 100.0) / 1e4, circ(2, 0, 100.0) / 1e4, circ(0, 1, 100.0) / 1e4]

pT, pw, pP = pull(temp), pull(omega), pull(Phi)
dpw = d(pw)
pdw = pull({(1, 2): lambda *p: hand(*p)[1][0], (0, 2): lambda *p: -hand(*p)[1][1], (0, 1): lambda *p: hand(*p)[1][2]})
print(f"terrain chart s = z - 0.0005 x^2: at M floor {0.0005 * MS[0] ** 2:.0f} m, s = {MS[2]:.0f} m, floor slope {0.001 * MS[0]:.6f}")
print(f"  dT pulled back (dx dy ds): {f6(*[d(pT)[(i,)](*MS) for i in range(3)])} degC/m")
print(f"  omega pulled back (dx dy ds): {f6(*[pw[(i,)](*MS) for i in range(3)])} m/s")
row = lambda f: [f[(1, 2)](*MS), -f[(0, 2)](*MS), f[(0, 1)](*MS)]
print(f"  d(pulled-back omega) (dy^ds ds^dx dx^dy): {f6(*row(dpw))}")
print(f"  pulled-back d omega  (dy^ds ds^dx dx^dy): {f6(*row(pdw))}")
print(f"  d(pulled-back Phi) {f6(d(pP)[(0, 1, 2)](*MS))}; Jacobian determinant {pull({(0, 1, 2): lambda *p: 1.0})[(0, 1, 2)](*MS):.6f}")
for a, b in zip(row(dpw), row(pdw)): assert abs(a - b) < 1e-9          # d commutes with pullback
pg = [d(pT)[(i,)](*MS) for i in range(3)]
assert abs(pg[0] - (gT[0] + gT[2] * 0.2)) < 1e-9 and abs(pg[2] - gT[2]) < 1e-9
test = {(0,): lambda x, y, z: P(x, y, z) + 0.001 * y * z, (1,): Q, (2,): R}   # a mixed second rate, 0.001
dd = [v(*M) for f in (temp, omega, test) for v in d(d(f)).values()] + [v(*MS) for f in (pw, pull(test)) for v in d(d(f)).values()]
print(f"d(d .) of T, omega, omega + 0.001 yz dx; of pulled-back omega, omega + 0.001 yz dx: largest coefficient {max(abs(cl(v)) for v in dd):.9f}")
assert max(abs(v) for v in dd) < 1e-9

def fx(x, y): return 0.0 if x == y == 0 else y * (x ** 4 + 4 * x * x * y * y - y ** 4) / (x * x + y * y) ** 2
def fy(x, y): return 0.0 if x == y == 0 else x * (x ** 4 - 4 * x * x * y * y - y ** 4) / (x * x + y * y) ** 2
rule = (fy(1e-4, 0) - fy(-1e-4, 0)) / 2e-4 - (fx(0, 1e-4) - fx(0, -1e-4)) / 2e-4
a = 0.5e-3
box = (simpson(lambda u: fx(u, -a) - fx(u, a), -a, a, 256) + simpson(lambda v: fy(a, v) - fy(-a, v), -a, a, 256)) / (2 * a) ** 2
naive = d({(i,): (lambda *q, i=i: F[i](*chart(*q))) for i in range(3)})
print(f"breaks: commuting wedge, up part {f6(swapped)}; dx^dz for dz^dx, d Phi {f6(own[0] - own[1] + own[2])};"
      f" chart without dz = ds + 0.2 dx, ds^dx {f6(-naive[(0, 2)](*MS))}")
print(f"breaks: pinched f = xy(x^2-y^2)/(x^2+y^2) at 0: rule gives d(df) {f6(rule)}, box gives {f6(box)}")
assert abs(rule - 2.0) < 1e-9 and abs(box) < 1e-8 and abs(swapped - d(omega, False)[(0, 1)](*M)) < 1e-9
Q2 = lambda x, y, z: Q(x, y, z) + 0.01 * z
dw2 = d({(0,): P, (1,): Q2, (2,): R})
print(f"try: mast at x = 400 m, up part {f6(hand(400, 300, 50)[1][2])}; floor 0.001 x^2, slope {0.002 * MS[0]:.6f}, terrain dx^dy"
      f" {f6(d(pull(omega, 0.001))[(0, 1)](*MS))}; shear 0.02, dy^dz {f6(dw2[(1, 2)](*M))}")
print(f"try: 100 m squares, per area {f6(*cs100)}")
for a, b in zip(cs100, curl): assert abs(a - b) < 1e-12
print("ALL CHECKS PASS")
