# Godunov's method: solve a small Riemann problem at every cell edge -- the check
# behind the card.  Standard library only.  Burgers' equation u_t + (u^2/2)_x = 0.
# Road 1: the Rankine-Hugoniot speed.  Road 2: Godunov's method at five grid sizes, on the
# shock and on a smooth wave.  Road 3: the mass identity (telescoping end fluxes).  Road 4: the
# exact Riemann solution against the closed-form flux; Roe and HLL against Godunov and HLL's middle state.
from math import sin, pi

def f(u): return 0.5 * u * u                           # Burgers' flux
def riemann(ul, ur, xi):                               # exact Riemann solution at x/t = xi
    if ul > ur: return ul if xi < (ul + ur) / 2 else ur    # shock, Rankine-Hugoniot speed
    if xi <= ul: return ul                             # rarefaction fan: u = x/t inside
    if xi >= ur: return ur
    return xi
def godunov(ul, ur): return f(riemann(ul, ur, 0.0))    # flux through the edge, x/t = 0
def closed(ul, ur): return max(f(max(ul, 0.0)), f(min(ur, 0.0)))
def roe(ul, ur, d=0.0):                                # Roe: one wave at the averaged speed
    a = abs(ul + ur) / 2
    if a < d: a = (a * a + d * d) / (2 * d)            # Harten's entropy fix, width d
    return (f(ul) + f(ur)) / 2 - a / 2 * (ur - ul)
def hll(ul, ur):                                       # HLL: two waves, one middle state
    sl, sr = min(ul, ur), max(ul, ur)
    if sl >= 0: return f(ul)
    if sr <= 0: return f(ur)
    return (sr * f(ul) - sl * f(ur) + sl * sr * (ur - ul)) / (sr - sl)
def hll2(ul, ur, sl, sr):                              # HLL again: middle state um from conservation over
    um = (sr * ur - sl * ul - (f(ur) - f(ul))) / (sr - sl)   # the fan, then the jump condition
    return f(ul) + sl * (um - ul)                      # across the left wave

def step(flux, u, nu):                                # finite-volume update; ghost cells copy the ends
    g = [u[0]] + u + [u[-1]]
    F = [flux(g[i], g[i + 1]) for i in range(len(g) - 1)]
    return [u[j] - nu * (F[j + 1] - F[j]) for j in range(len(u))]
def nonc(u, nu):                                       # non-conservative upwind u_j - nu u_j (u_j - u_{j-1})
    return [v - nu * v * (v - (u[j - 1] if j else u[0])) for j, v in enumerate(u)]
def squares(u, nu):                                    # conserves u^2 with flux (2/3) u^3 instead
    v = [w * w for w in u]
    g = [2 / 3 * w ** 1.5 for w in v]
    return [max(v[j] - nu * (g[j] - g[j - 1 if j else 0]), 0.0) ** 0.5 for j in range(len(u))]

def start(n, x0=0.3, a=1.0, b=0.0): return [a if (j + 0.5) / n < x0 else b for j in range(n)]
def run(n, nu=0.5, t=0.5, how=None, u=None):
    u = start(n) if u is None else u
    for _ in range(round(t * n / nu)): u = how(u, nu) if how else step(godunov, u, nu)
    return u
def cross(u):                                          # where the profile crosses 1/2
    n = len(u)
    j = max(i for i in range(n - 1) if u[i] >= 0.5 > u[i + 1])
    return (j + 0.5 + (u[j] - 0.5) / (u[j] - u[j + 1])) / n
def l1(u, xs):                                         # distance from the exact shock's cell averages
    n = len(u)
    return sum(abs(v - min(max(xs * n - j, 0.0), 1.0)) for j, v in enumerate(u)) / n
def wave(x, t):                                        # smooth wave on a loop: u = u0(x - u t), by iteration
    v = 0.5
    for _ in range(60): v = 0.5 + 0.25 * sin(2 * pi * (x - v * t))
    return v

s = (f(1.0) - f(0.0)) / (1.0 - 0.0)
XS = 0.3 + s * 0.5
print(f"Burgers, u = 1 left of 0.3, 0 right; 100 cells h = 0.01, dt = 0.005, nu = 0.50, 100 steps to t = 0.5")
print(f"Rankine-Hugoniot: s = (0.5 - 0)/(1 - 0) = {s:.4f}; exact shock at 0.3 + {s:.1f} x 0.5 = {XS:.4f}")
grid = [i / 10 - 2 for i in range(41)]
print(f"Riemann solver sampled at x/t = 0 against max(f(max(uL,0)), f(min(uR,0))), 1681 pairs: largest gap "
      f"{max(abs(godunov(a, b) - closed(a, b)) for a in grid for b in grid):.1e}")
same = [abs(roe(a, b) - godunov(a, b)) for a in grid for b in grid if not a < 0 < b]
tr = [abs(roe(a, b) - godunov(a, b)) for a in grid for b in grid if a < 0 < b]
print(f"Roe against Godunov: largest gap {max(same):.1e} on the {len(same)} pairs without uL < 0 < uR;"
      f" smallest gap {min(tr):.1e} on the {len(tr)} with it")
hg = [abs(hll(a, b) - hll2(a, b, min(a, b), max(a, b))) for a in grid for b in grid if min(a, b) < 0 < max(a, b)]
print(f"HLL against f(uL) + sL (um - uL), um from conservation, {len(hg)} pairs with sL < 0 < sR: largest gap {max(hg):.1e}")

u = start(100)
print("by hand, the first two steps at the cell from 0.30 to 0.31 (left neighbour 1, right neighbour 0):")
for k in (1, 2):
    a, b, c = u[29], u[30], u[31]
    Fl, Fr = godunov(a, b), godunov(b, c)
    u = step(godunov, u, 0.5)
    print(f"  step {k}: F_left = {Fl:.5f}, F_right = {Fr:.5f}, new u = {b:.6f} - 0.5 x ({Fr:.5f} - {Fl:.5f}) = {u[30]:.6f}")

gd, nc, sq = run(100), run(100, how=nonc), run(100, how=squares)
print(f"Godunov: crossing {cross(gd):.4f}, true error {cross(gd) - XS:+.4f} = {(cross(gd) - XS) * 100:+.2f} cells;"
      f" mass {sum(gd) / 100:.4f}; range {min(gd):.4f} to {max(gd):.4f}")
print(f"  mass identity 0.3 + 100 x 0.005 x 0.5 = {0.3 + 100 * 0.005 * 0.5:.4f}; gap {abs(sum(gd) / 100 - 0.55):.1e}")
print("  cells 0.50 to 0.60:", " ".join(f"{v:.4f}" for v in gd[50:60]))
print(f"non-conservative upwind: crossing {cross(nc):.4f}, true error {cross(nc) - XS:+.4f}; mass {sum(nc) / 100:.4f}")
print(f"conserving u^2 instead: speed (2/3)/1 = {2 / 3:.4f}, shock at {0.3 + 0.5 * 2 / 3:.4f}; crossing {cross(sq):.4f},"
      f" where u^2 itself crosses 1/2: {cross([w * w for w in sq]):.4f}")
rs, hs = run(100, how=lambda u, nu: step(roe, u, nu)), run(100, how=lambda u, nu: step(hll, u, nu))
print(f"Roe and HLL on the shock: largest gap from Godunov {max(abs(a - b) for a, b in zip(rs, gd)):.1e},"
      f" {max(abs(a - b) for a, b in zip(hs, gd)):.1e}")

print("Lax-Wendroff theorem at work: refine, nu = 0.5 | L1 error = h x sum |u_j - exact cell average|")
print(f"  and Godunov on a smooth wave u0 = 0.5 + 0.25 sin(2 pi x), on a loop, to t = 0.2, before it breaks at 1/(0.25 x 2 pi) = {1 / (0.5 * pi):.4f} | L1 against exact u at centres")
eg, en, es = [], [], []
for n in (100, 200, 400, 800, 1600):
    a, b = run(n), run(n, how=nonc)
    w = run(n, t=0.2, how=lambda u, nu: step(godunov, [u[-1]] + u + [u[0]], nu)[1:-1], u=[wave((j + 0.5) / n, 0) for j in range(n)])
    eg.append(l1(a, XS)); en.append(l1(b, XS)); es.append(sum(abs(v - wave((j + 0.5) / n, 0.2)) for j, v in enumerate(w)) / n)
    print(f"  {n:>4} cells: Godunov crossing {cross(a):.4f}, L1 {eg[-1]:.5f} | non-conservative crossing {cross(b):.4f},"
          f" L1 {en[-1]:.4f} | smooth L1 {es[-1]:.6f}")
for name, e in (("shock", eg), ("smooth wave", es)):
    print(f"  Godunov L1 ratios as h halves, {name}: " + ", ".join(f"{e[i] / e[i + 1]:.2f}" for i in range(4)))

def fan(j, n, t=0.25):                                 # exact cell average of the fan from x = 0.5
    def G(y): return y * y / (2 * t) if abs(y) <= t else abs(y) - t / 2
    return (G((j + 1) / n - 0.5) - G(j / n - 0.5)) * n
print("transonic fan: u = -1 left of 0.5, +1 right, 100 cells, nu = 0.5, 50 steps to t = 0.25 | L1 error")
fans, fl1 = {}, {}
for name, fl in (("Godunov", godunov), ("Roe, no fix", roe), ("Roe, fix width 0.5", lambda a, b: roe(a, b, 0.5)),
                 ("Roe, fix width 0.2", lambda a, b: roe(a, b, 0.2)), ("HLL", hll)):
    v = fans[name] = run(100, t=0.25, how=lambda u, nu: step(fl, u, nu), u=start(100, 0.5, -1.0, 1.0))
    fl1[name] = sum(abs(w - fan(j, 100)) for j, w in enumerate(v)) / 100
    print(f"  {name:<19} L1 {fl1[name]:.4f}; cells either side of 0.5: {v[49]:+.4f} {v[50]:+.4f}")
print(f"  exact cell averages there: {fan(49, 100):+.4f} {fan(50, 100):+.4f}")

big = run(100, nu=1.25)
print(f"what breaks: nu = 1.25 (dt = 0.0125, 40 steps): range {min(big):.4f} to {max(big):.4f}, overshoot {max(big) - 1:.4f}")
print(f"cost: {101 * 100} edge fluxes for the 100-cell run, about 6 operations each")

lab = [0.245 + 0.02 * i for i in range(21)]
print("chart, x:", ", ".join(f"{x:.3f}" for x in lab))
for name, v in (("exact", None), ("Godunov", gd), ("non-conservative", nc)):
    print(f"chart, {name}:", ", ".join(f"{(1.0 if x < XS else 0.0) if v is None else v[round(x * 100 - 0.5)]:.2f}" for x in lab))
lab2 = [0.205 + 0.04 * i for i in range(15)]
print("chart2, x:", ", ".join(f"{x:.3f}" for x in lab2))
print("chart2, exact:", ", ".join(f"{fan(round(x * 100 - 0.5), 100):.2f}" for x in lab2))
for name in ("Godunov", "Roe, no fix"):
    print(f"chart2, {name}:", ", ".join(f"{fans[name][round(x * 100 - 0.5)]:.2f}" for x in lab2))

assert abs(cross(gd) - XS) < 0.02                      # within two cells of Rankine-Hugoniot
assert abs(sum(gd) / 100 - (0.3 + 0.25)) < 1e-12       # mass identity: telescoping fluxes
assert abs(cross(nc) - 0.3) < 1e-12 and en[-1] > 0.24   # non-conservative: frozen, wrong limit
assert abs(cross(sq) - (0.3 + 1 / 3)) < 0.02           # u^2 conserved: the other speed, 2/3
assert all(1.8 < es[i] / es[i + 1] < 2.2 for i in range(4))   # first order, seen on the smooth wave
assert all(abs(godunov(a, b) - closed(a, b)) < 1e-15 for a in grid for b in grid)
assert all(g < 1e-15 for g in same) and all(g > 1e-3 for g in tr)   # Roe differs only on transonic fans
assert max(abs(a - b) for a, b in zip(rs, gd)) < 1e-12 and all(g < 1e-12 for g in hg)   # HLL, two roads
assert abs(fans["Roe, no fix"][49] + 1.0) < 1e-12      # no fix: the expansion shock never opens
assert all(fl1[k] < 0.05 for k in fl1 if k != "Roe, no fix")   # fixed solvers open the fan (NaN fails)
assert max(big) > 1.005 and max(gd) <= 1.0 and min(gd) >= 0.0
print("ALL CHECKS PASS")
