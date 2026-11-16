# Viscosity solutions -- the check behind the card.  Imports only math's exp.
# A car breaks down at km x of a 10 km road with garages at km 0 and km 10.
# Limping on costs C dollars per km; stopping for a tow costs PSI dollars.
# Least cost u(x) = min(PSI, C x, C (L - x)) solves max(u - PSI, |u'| - C) = 0.
# Roads: the closed form, dynamic programming on a grid, smooth functions that
# touch the graph, comparison with sub- and supersolutions, vanishing viscosity.
from math import exp
L, C, PSI = 10.0, 30.0, 120.0            # road km, damage $/km, tow $ (illustrative)
K, HALF, NS = 100.0, 0.5, 100            # test parabola curvature $/km^2, window km, samples
SLOPES = range(-40, 41, 5)               # test slopes tried, $/km

def value(x, c=C, psi=PSI): return min(psi, c * x, c * (L - x))   # road 1
def u(x): return value(x)
def tent(x): return C * min(x, L - x)                             # no tow on offer
def phantom(x): return min(PSI, C * x, C * abs(x - 5.0), C * (L - x))   # fake garage at km 5
def half_u(x): return 0.5 * u(x)
def flat(x): return PSI
def F(r, p): return max(r - PSI, abs(p) - C)    # the equation's left side
def G(r, p): return abs(p) - C                   # no tow: |u'| - C
def Gflip(r, p): return C - abs(p)               # the same, sign flipped

def touches(f, x0, p, side):                     # phi = f(x0) + p s + side K s^2
    for j in range(1, NS + 1):                   # stays above (side +1) or below (-1)?
        for s in (-HALF * j / NS, HALF * j / NS):
            gap = f(x0) + p * s + side * K * s * s - f(x0 + s)
            if side * gap < -1e-9:
                return False
    return True

def test(f, x0, eq=F):                           # the two viscosity tests at x0
    above = [p for p in SLOPES if touches(f, x0, p, +1)]
    below = [p for p in SLOPES if touches(f, x0, p, -1)]
    sub = max([eq(f(x0), p) for p in above], default=None)    # needs <= 0
    sup = min([eq(f(x0), p) for p in below], default=None)    # needs >= 0
    return above, below, sub, sup

def ok(f, x0, eq=F, need="both"):
    _, _, sub, sup = test(f, x0, eq)
    good_sub, good_sup = sub is None or sub <= 1e-9, sup is None or sup >= -1e-9
    return {"sub": good_sub, "super": good_sup, "both": good_sub and good_sup}[need]

def show(name, f, x0, eq=F):
    a, b, sub, sup = test(f, x0, eq)
    rng = lambda s: f"{s[0]} to {s[-1]}" if s else "none"
    num = lambda v: "-" if v is None else f"{v:.0f}"
    print(f"{name:<20} km {x0:3.1f}: value {f(x0):7.2f} $; from above {rng(a):>9}, max F {num(sub):>2}; "
          f"from below {rng(b):>9}, min F {num(sup):>3}")

H, N = 0.1, 100                                  # road 2: Bellman on a 0.1 km grid
def dp(start):
    v, sweeps = [0.0] + [start] * (N - 1) + [0.0], 0
    while True:
        new = [0.0] + [min(PSI, C * H + min(v[i - 1], v[i + 1])) for i in range(1, N)] + [0.0]
        sweeps += 1
        if max(abs(a - b) for a, b in zip(new, v)) < 1e-12:
            return new, sweeps
        v = new
grid = [i * H for i in range(N + 1)]
down, s1 = dp(PSI)
up, s2 = dp(0.0)
err = max(abs(d - u(x)) for d, x in zip(down, grid))
err2 = max(abs(d - u(x)) for d, x in zip(up, grid))

print(f"road {L:.0f} km, garages at km 0 and 10; limping {C:.0f} $/km; tow {PSI:.0f} $")
print(f"closed form: u(3) = {u(3):.2f} $, u(4) = {u(4):.2f} $, u(5) = {u(5):.2f} $, u(6) = {u(6):.2f} $")
print(f"stop where u = tow fee: km {PSI / C:.2f} to {L - PSI / C:.2f}; no-tow tent at km 5: {tent(5):.2f} $")
print(f"dynamic programming, step 0.1 km: from above {s1} sweeps, from below {s2} sweeps; "
      f"both equal the closed form to 1e-9 $ at all {N + 1} nodes: {'yes' if err < 1e-9 and err2 < 1e-9 else 'no'}")
print(f"by hand at km 4: slope 40 line at km 3.9 gives {120 + 40 * (3.9 - 4):.2f} $, u(3.9) = {u(3.9):.2f} $")
show("value u", u, 3.0); show("value u", u, 4.0); show("value u", u, 5.0); show("value u", u, 6.0)
show("phantom garage", phantom, 5.0); show("phantom garage", phantom, 2.5)
show("tent, no tow", tent, 5.0, G); show("tent, flipped sign", tent, 5.0, Gflip)
show("minus tent, flipped", lambda x: -tent(x), 5.0, Gflip)
inner = grid[1:N]
fails = lambda f, eq=F, need="both": [x for x in inner if not ok(f, x, eq, need)]
fu, fph = fails(u), fails(phantom, F, "super")
fph_sub = fails(phantom, F, "sub")
smooth = [x for x in inner if round(x * 10) not in (25, 50, 75)]
ae = max(abs(F(phantom(x), (phantom(x + 0.01) - phantom(x - 0.01)) / 0.02)) for x in smooth)
print(f"grid scan, {len(inner)} points: u fails a test at {len(fu)}; phantom fails at {len(fph)} "
      f"(km {fph[0]:.1f}, the super test) and the sub test at {len(fph_sub)}")
print(f"phantom's largest |F| at its {len(smooth)} smooth grid points: {ae:.6f} $/km")
subs = [("half of u", half_u), ("phantom", phantom)]
sups = [("tent", tent), ("flat 120", flat)]
for name, f in subs:
    assert not fails(f, F, "sub")
for name, f in sups:
    assert not fails(f, F, "super")
gap_lo = min(u(x) - f(x) for _, f in subs for x in grid)
gap_hi = min(f(x) - u(x) for _, f in sups for x in grid)
print(f"comparison on all {N + 1} nodes: least of u - sub {gap_lo:.2f} $, least of super - u {gap_hi:.2f} $")
print(f"  at km 5: half of u {half_u(5):.2f}, phantom {phantom(5):.2f} <= u {u(5):.2f} <= "
      f"flat {flat(5):.2f}, tent {tent(5):.2f} $")

def visc(x, e):                                  # -e u'' + |u'| = C, u(0) = u(L) = 0
    y = min(x, L - x)
    return C * y - C * e * (exp((y - L / 2) / e) - exp(-L / 2 / e))
def resid(x, e, d):                              # centred differences
    u2 = (visc(x + d, e) - 2 * visc(x, e) + visc(x - d, e)) / d ** 2
    u1 = (visc(x + d, e) - visc(x - d, e)) / (2 * d)
    return -e * u2 + abs(u1) - C
EPS = [1.0, 0.5, 0.25, 0.125]
print("vanishing viscosity, eps km    " + "".join(f"{e:9.3f}" for e in EPS))
print("  u_eps(5) $                   " + "".join(f"{visc(5, e):9.4f}" for e in EPS))
print("  tent(5) - u_eps(5) $         " + "".join(f"{tent(5) - visc(5, e):9.4f}" for e in EPS))
r1, r2 = abs(resid(2.0, 0.5, 0.01)), abs(resid(2.0, 0.5, 0.005))
print(f"  residual at km 2, eps 0.5, step 0.01, 0.005 km: {r1 * 1e6:.3f} {r2 * 1e6:.3f} x 1e-6 $/km")
print(f"  first-order residual at the top, km 5: {G(visc(5, 0.5), 0.0):.0f} $/km for every eps")
xs = list(range(11))
print("chart, km          " + "".join(f"{x:>8}" for x in xs))
print("chart, eps 1 km    " + "".join(f"{visc(x, 1.0):8.2f}" for x in xs))
print("chart, eps 0.25 km " + "".join(f"{visc(x, 0.25):8.2f}" for x in xs))
print("chart, tent        " + "".join(f"{tent(x):8.2f}" for x in xs))
print(f"mistake 1, phantom garage at km 5: {phantom(5):.2f} $, not {u(5):.2f} $; tooth tops {phantom(2.5):.2f} $")
print(f"mistake 2, sign flipped, no tow: {-tent(5):.2f} $ at km 5, not {tent(5):.2f} $")
print(f"mistake 3, tow forgotten: {tent(5):.2f} $ at km 5, not {u(5):.2f} $")
print(f"try: tow 150 $ gives u(5) = {value(5, C, 150):.2f} $; damage 20 $/km gives u(5) = "
      f"{value(5, 20, PSI):.2f} $; eps 0.05 km gives u_eps(5) = {visc(5, 0.05):.4f} $")
print(f"figure, x 0 to 10 km at 50 px/km from 60; y 0 to 160 $ at 1.5 px/$ up from 300; "
      f"kinks (4, {u(4):.0f}) (6, {u(6):.0f}); phantom teeth (2.5, {phantom(2.5):.0f}) (5, {phantom(5):.0f}) (7.5, {phantom(7.5):.0f})")
assert err < 1e-9 and err2 < 1e-9                            # Bellman grid = closed form
assert test(u, 4.0)[0] == [0, 5, 10, 15, 20, 25, 30] and test(u, 4.0)[1] == []
assert fu == [] and fph == [5.0] and fph_sub == [] and ae < 1e-6
assert test(tent, 5.0, Gflip)[2] > 0 and ok(lambda x: -tent(x), 5.0, Gflip)
assert gap_lo >= 0 and gap_hi >= 0 and abs(gap_lo) < 1e-9     # phantom touches u at km 0
for e in EPS:
    d = tent(5) - visc(5, e)
    assert 0 < d <= C * e and abs(visc(0, e)) < 1e-9          # below the tent; u_eps(0) = 0
assert r2 < r1 / 3 and r1 < 1e-3                               # second order in the step
print("ALL CHECKS PASS")
