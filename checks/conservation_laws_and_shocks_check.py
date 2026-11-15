# Conservation law rho_t + q(rho)_x = 0 -- the check behind the card.  Cars bunch behind
# a red light on a one-lane road.  Greenshields flux q = VM rho (1 - rho/RM).  Roads: the
# breaking-time formula against a search over characteristics; Rankine-Hugoniot against
# counting cars; both against a cell-transmission grid that knows no formula.
from fractions import Fraction as F
from math import exp

VM, RM = 90.0, 150.0                       # top speed km/h, jam density cars/km
def q(r): return VM * r * (1 - r / RM)     # flow, cars/h
def c(r): return VM * (1 - 2 * r / RM)     # characteristic (wave) speed q'(rho), km/h
def v(r): return VM * (1 - r / RM)         # car speed, km/h
def rho0(x):                               # t = 0: 30 cars/km, braking zone, queue to the light
    return 30.0 if x <= -0.7 else 30 + 300 * (x + 0.7) if x <= -0.3 else 150.0
def smooth0(x): return 90 + 60 * (1 - 2 / (1 + exp(2 * (x + 0.5) / 0.2)))  # 90 + 60 tanh
TB = 1 / (2 * VM / RM * 300)               # breaking time: -1/(q'' * steepest slope), h
XS = -0.5 + c(90) * TB                     # where: the ramp's centre line, km
S = (q(150) - q(30)) / (150 - 30)          # Rankine-Hugoniot shock speed, km/h

def exact(x, t):                           # the entropy solution, x <= 0 km, t in h
    if t < TB:
        a, b = -0.7 + c(30) * t, -0.3 + c(150) * t
        return 30.0 if x <= a else 150.0 if x >= b else 30 + 120 * (x - a) / (b - a)
    return 30.0 if x < XS + S * (t - TB) else 150.0

def by_characteristics(x, t):              # road 2 before breaking: solve x0 + c(rho0(x0)) t = x
    lo, hi = -3.0, 0.0
    for _ in range(60):
        m = (lo + hi) / 2
        if m + c(rho0(m)) * t < x: lo = m
        else: hi = m
    return rho0((lo + hi) / 2)

def search(prof, n=20000):                 # earliest crossing of neighbouring characteristics
    xs = [-1.5 + 1.5 * i / n for i in range(n + 1)]; cs = [c(prof(x)) for x in xs]
    return min((xs[i] - xs[i + 1]) / (cs[i + 1] - cs[i]) for i in range(n) if cs[i + 1] < cs[i])

def grid(h, T):                            # road 3: cell transmission (Godunov) on [-2, 0] km
    n = round(2 / h); r = [rho0(-2 + (i + 0.5) * h) for i in range(n)]
    qm = q(RM / 2); dem = lambda a: q(a) if a < RM / 2 else qm; sup = lambda a: qm if a < RM / 2 else q(a)
    steps = int(T / (0.9 * h / VM)) + 1; k = T / steps   # each step inside the CFL limit
    for _ in range(steps):                 # inflow at 30 cars/km on the left, red light on the right
        fl = [min(dem(30.0), sup(r[0]))] + [min(dem(r[i]), sup(r[i + 1])) for i in range(n - 1)] + [0.0]
        r = [r[i] - k / h * (fl[i + 1] - fl[i]) for i in range(n)]
    return r

def tail(r, h):                            # where the grid's density crosses 90 cars/km
    i = next(i for i in range(len(r)) if r[i] >= 90); xa = -2 + (i - 0.5) * h
    return xa + (90 - r[i - 1]) / (r[i] - r[i - 1]) * h

print(f"start: 30 cars/km to -0.7 km, rising 300 cars/km per km over 400 m to 150 at -0.3 km, queue to the light at 0 km")
print(f"top speed {VM:.0f} km/h, jam {RM:.0f} cars/km = one car per {1000 / RM:.1f} m; top flow q(75) = {q(75):.0f} cars/h")
print(f"flux q(rho) = {VM:.0f} rho (1 - rho/{RM:.0f}): q(30) = {q(30):.0f} cars/h at {v(30):.0f} km/h; q(150) = {q(150):.0f}")
print(f"wave speeds q'(30) = {c(30):+.0f} km/h, q'(90) = {c(90):+.0f} km/h, q'(150) = {c(150):+.0f} km/h")
print(f"breaking time by formula: 1/(1.2 x 300) = {TB:.6f} h = {TB * 3600:.1f} s, at x = {XS:.3f} km")
lin, smo = search(rho0), search(smooth0)
print(f"road 2, search over 20001 characteristics: braking ramp {lin * 3600:.4f} s, smooth tanh zone {smo * 3600:.4f} s")
print(f"slope inside the ramp at 5 s: 300/(1 - 5/10) = {300 / (1 - 5 / (TB * 3600)):.0f} cars/km per km")
qf = lambda r: F(90 * r * (150 - r), 150)  # exact flow, cars/h
Fs = (qf(150) - qf(30)) / (150 - 30)
print(f"Rankine-Hugoniot: s = (0 - 2160)/(150 - 30) = {Fs} km/h exactly = {S / 3.6:.1f} m/s")
print(f"same by the Greenshields shortcut 90 (1 - 180/150) = {VM * (1 - 180 / RM):.0f} km/h")
T = 1 / 60; X = XS + S * (T - TB)
print(f"queue tail at 60 s: -0.55 + (-18)(50/3600) = {X:.4f} km; queue {-X * 1000:.0f} m holding {-X * 150:.0f} cars")
cars0 = 1.3 * 30 + 0.4 * 90 + 0.3 * 150; inflow = q(30) * T
Xc = (cars0 + inflow - 30 * 2) / (30 - 150)
print(f"road 2, count cars on [-2, 0] km: {cars0:.0f} at start + {inflow:.0f} in = {cars0 + inflow:.0f}; tail where 30(X + 2) + 150(-X) = 156: X = {Xc:.4f} km")
errs = []
for h in (0.01, 0.005, 0.0025):
    r5, r60 = grid(h, 5 / 3600), grid(h, T)
    errs.append(sum(abs(r5[i] - exact(-2 + (i + 0.5) * h, 5 / 3600)) for i in range(len(r5))) * h)
    print(f"road 3, cell grid h = {h * 1000:g} m: tail at 60 s {tail(r60, h):.4f} km, cars {sum(r60) * h:.4f};"
          f" at 5 s {errs[-1]:.4f} cars out of place")
print(f"error ratios as h halves: {errs[0] / errs[1]:.2f}, {errs[1] / errs[2]:.2f} (order 1)")
mid = [-0.95 + 0.1 * i for i in range(10)]
gap = max(abs(by_characteristics(x, 5 / 3600) - exact(x, 5 / 3600)) for x in mid)
print(f"profile at 5 s by tracing characteristics back, largest gap from formula: {gap:.6f} cars/km")
for t in (0, 5, 60):
    print(f"chart, t = {t} s:", ", ".join(f"{exact(x, t / 3600):.0f}" for x in mid))
tw = 1 / (VM / RM * 300)
print(f"mistake 1, characteristics at car speed v: breaks at {tw * 3600:.1f} s, not {TB * 3600:.1f} s")
Xw = XS - S * (T - TB); cw = 30 * (Xw + 2) + 150 * (-Xw)
print(f"mistake 2, sign flipped, +18 km/h: tail at {Xw:.4f} km, cars counted {cw:.0f}, not 156")
jmp = lambda f: f(F(0)) - f(F(1))          # Burgers 1-to-0 jump [f] = f(u_R) - f(u_L), exact
b1 = jmp(lambda u: u * u / 2) / jmp(lambda u: u); b2 = jmp(lambda u: u ** 3 / 3) / jmp(lambda u: u * u / 2)
print(f"mistake 3, Burgers 1-to-0 jump: conserving u gives {b1}, conserving u^2/2 gives {b2}")
print(f"try, arriving at 60 cars/km: s = {(q(150) - q(60)) / 90:.0f} km/h; braking zone 800 m: breaks at {1 / (1.2 * 150) * 3600:.1f} s")
print(f"figure, shock from ({XS:.3f} km, {TB * 3600:.1f} s) to ({XS + S * (30 / 3600 - TB):.3f} km, 30.0 s)")
up = [(-0.5 - x0) / ((c(30) - S) / 3600) for x0 in (-1.0, -0.9, -0.8, -0.7)]
dn = [(x0 + 0.5) / ((S - c(150)) / 3600) for x0 in (-0.3, -0.2, -0.1, 0.0)]
print("figure, lines from -1.0 -0.9 -0.8 -0.7 km hit the shock at", " ".join(f"{t:.1f}" for t in up),
      "s; from -0.3 -0.2 -0.1 0.0 km at", " ".join(f"{t:.1f}" for t in dn), "s")
assert abs(lin - TB) < 1e-9 and abs(smo - TB) < 1e-4 * TB      # search meets breaking formula
assert Fs == -18 and abs(Xc - X) < 1e-12                        # RH meets the car count
assert abs(tail(r60, 0.0025) - X) < 1e-4 and abs(sum(r60) * 0.0025 - 156) < 1e-6  # grid meets RH, count
assert errs[2] < 0.1 and 1.8 < errs[1] / errs[2] < 2.2         # grid meets the profile at order 1
assert gap < 1e-9                                               # characteristics meet formula
assert b1 == F(1, 2) and b2 == F(2, 3)                          # Burgers: the jump depends on what is conserved
print("ALL CHECKS PASS")
