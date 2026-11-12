# From local error to global error -- the check behind the card.  Standard library only.
# A model rocket coasts from burnout: height y, speed v, y' = v, v' = -g - k v.
# Road one: run a one-step method and subtract the closed-form flight.
# Road two: carry each step's local error to the end, step by step, and add.
# Road three: the theorem's bound, which must sit above both.
from math import exp, log2, log10

G, K, T, Y0, V0 = 9.8, 0.05, 30.0, 40.0, 180.0      # m/s^2, 1/s, s, m, m/s

def sci(x, d=3):                                     # 2.280e-3, the same in Rust
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def exact(t, y0=Y0, v0=V0, a=0.0, k=K):              # closed form, thrust a
    vi = (a - G) / k; A = v0 - vi; q = exp(-k * t)
    return (y0 + vi * t + A * (1 - q) / k, vi + A * q)
def rocket(k, a=0.0, tb=0.0):                        # rate law; thrust a until tb
    return lambda t, x: (x[1], (a if t < tb else 0.0) - G - k * x[1])
EULER = ([], [1.0], [0.0])
HEUN = ([[1.0]], [0.5, 0.5], [0.0, 1.0])
RK4 = ([[0.5], [0.0, 0.5], [0.0, 0.0, 1.0]], [1/6, 1/3, 1/3, 1/6], [0.0, 0.5, 0.5, 1.0])
def step(tab, f, t, x, h):                           # one explicit Runge-Kutta step
    A, b, c = tab; ks = []
    for i in range(len(b)):
        z = x
        for j in range(i): z = (z[0] + h * A[i-1][j] * ks[j][0], z[1] + h * A[i-1][j] * ks[j][1])
        ks.append(f(t + c[i] * h, z))
    s0 = s1 = 0.0                                    # a plain loop: sum() compensates
    for i in range(len(b)): s0 += b[i] * ks[i][0]; s1 += b[i] * ks[i][1]
    return (x[0] + h * s0, x[1] + h * s1)
def run(tab, f, h, x, t_end):
    for n in range(round(t_end / h)): x = step(tab, f, n * h, x, h)
    return x
def size(d, k=K): return max(abs(d[0]), abs(d[1]) / k)   # metres: height, or speed x 1/k
def err(x, xe): return (xe[0] - x[0], xe[1] - x[1])
def E(tab, h, k=K, t_end=T): return size(err(run(tab, rocket(k), h, (Y0, V0), t_end), exact(t_end, k=k)), k)
def lam(L, h): return L * (1 + h * L / 2 + (h * L) ** 2 / 6 + (h * L) ** 3 / 24)  # RK4's increment
def theorem(h, k=K, t_end=T):                        # true error, carried sum, bound
    f, fh = rocket(k), (lambda t, x: (x[1], -k * x[1]))  # fh: the rate law minus gravity
    e, taus = (0.0, 0.0), []
    for n in range(round(t_end / h)):
        x0, x1 = exact(n * h, k=k), exact((n + 1) * h, k=k)
        loc = err(step(RK4, f, n * h, x0, h), x1)    # h times tau_n
        taus.append(size(loc, k) / h)
        r = step(RK4, fh, 0.0, e, h); e = (r[0] + loc[0], r[1] + loc[1])
    return E(RK4, h, k, t_end), size(e, k), max(taus) * (exp(lam(k, h) * t_end) - 1) / lam(k, h), taus

print(f"rocket from burnout: y0 = 40 m, v0 = 180 m/s, g = 9.8 m/s^2, k = 0.05 /s, T = 30 s")
xT = exact(T)
print(f"exact at 30 s: height {xT[0]:.4f} m, speed {xT[1]:.4f} m/s")
HS = [2.0 / 2 ** j for j in range(13)]               # 2 s down to 1/2048 s
errs = {}
for name, tab in (("Euler", EULER), ("Heun", HEUN), ("RK4", RK4)):
    errs[name] = [E(tab, h) for h in HS]
for h in HS[:4]:
    d = err(run(RK4, rocket(K), h, (Y0, V0), T), xT)
    print(f"RK4 h = {h}: height error {sci(d[0])} m, speed error {sci(d[1])} m/s, E = {sci(size(d))} m")
er = errs["RK4"]
print("RK4 error ratio per halving: " + ", ".join(f"{er[i] / er[i+1]:.2f}" for i in range(3)))
for name in errs:
    e = errs[name]
    print(f"observed order, {name}: " + ", ".join(f"{log2(e[i] / e[i+1]):.2f}" for i in range(3)))
loc = [size(err(step(RK4, rocket(K), 0.0, (Y0, V0), h), exact(h))) for h in (1.0, 0.5)]
print(f"one RK4 step from burnout: local error h = 1: {sci(loc[0])} m, h = 0.5: {sci(loc[1])} m, ratio {loc[0] / loc[1]:.2f}")
true1, carried, bound1, taus = theorem(1.0)
print(f"h = 1: size of exact minus run {sci(true1, 6)} m; local errors carried and added {sci(carried, 6)} m")
print(f"theorem, h = 1: L = 0.05 /s, Lambda = {lam(K, 1.0):.6f} /s, largest tau = {sci(max(taus))} m/s, "
      f"last tau = {sci(taus[-1])} m/s")
print(f"theorem, h = 1: bound {sci(bound1)} m, true {sci(true1)} m, bound / true {bound1 / true1:.2f}")
print(f"over 30 s the bound lets errors grow by e^(Lambda T) = {exp(lam(K, 1.0) * T):.2f}; "
      f"drag shrinks a speed error by e^(-kT) = {exp(-K * T):.3f}")
print("along the flight, h = 1: t, true E, bound, bound / true")
for tt in (6.0, 12.0, 18.0, 24.0, 30.0):
    tr, _, b, _ = theorem(1.0, K, tt)
    print(f"  {tt:4.0f} s  {sci(tr)} m  {sci(b)} m  {b / tr:.2f}")
LP = lam(1.0, 1.0)                                   # L = 1 /s if speed counts as metres
plain = max(taus) * (exp(LP * T) - 1) / LP          # height part is the larger: same tau
print(f"plain sizes (L = 1 /s, Lambda = {LP:.6f} /s): bound {sci(plain)} m, bound / true {sci(plain / true1)}")
for h in (2.0, 0.5):
    tr, _, b, _ = theorem(h)
    print(f"theorem, h = {h}: bound {sci(b)} m, true {sci(tr)} m, bound / true {b / tr:.2f}")
print("chart x, log10 h: " + ", ".join(f"{log10(h):.2f}" for h in HS))
for name in errs: print(f"chart, log10 E, {name}: " + ", ".join(f"{log10(e):.2f}" for e in errs[name]))
lo = min(range(len(HS)), key=lambda i: er[i])
print(f"rounding floor, RK4: smallest E {sci(er[lo], 1)} m at h = 1/{round(1 / HS[lo])} s; "
      f"at h = 1/2048 s, E = {sci(er[-1], 1)} m")
AT, TB = 110.0, 1.7                                  # mistake 1: thrust inside the run
yb, vb = exact(TB, 0.0, 0.0, AT)
xe = exact(T - TB, yb, vb)
th = [size(err(run(RK4, rocket(K, AT, TB), h, (0.0, 0.0), T), xe)) for h in (1.0, 0.5, 0.25, 0.125)]
print(f"mistake 1, 1.7 s burn at 110 m/s^2 inside the run, h = 1, 0.5, 0.25, 0.125: E = " + ", ".join(f"{e:.1f}" for e in th)
      + " m; orders " + ", ".join(f"{log2(th[i] / th[i+1]):.2f}" for i in range(3)))
BAD = (RK4[0], [1/6, 1/6, 1/3, 1/3], RK4[2])         # weights still add to 1
INC = (RK4[0], [1/6, 1/3, 1/3, 1/3], RK4[2])         # weights add to 7/6
bad = [E(BAD, h) for h in (1.0, 0.5, 0.25)]
print("mistake 2, weights 1/6, 1/6, 1/3, 1/3, h = 1, 0.5, 0.25: E = " + ", ".join(f"{x:.2f}" for x in bad) + " m; orders "
      + ", ".join(f"{log2(bad[i] / bad[i+1]):.2f}" for i in range(2)))
print("mistake 3, weights adding to 7/6, h = 1, 0.5, 0.25: E = " + ", ".join(f"{E(INC, h):.2f}" for h in (1.0, 0.5, 0.25)) + " m")
print(f"mistake 4, the 32-fold local gain read as the global one: guess E(0.5) = {sci(er[1] / 32)} m, "
      f"actual {sci(er[2])} m")
tr, _, b, _ = theorem(1.0, 0.1)
print(f"try, drag k = 0.1 /s, h = 1: bound / true {b / tr:.2f}")
tr, _, b, _ = theorem(1.0, K, 10.0)
print(f"try, stop at T = 10 s, h = 1: bound / true {b / tr:.2f}")

for h in (2.0, 1.0, 0.5):                                     # road two equals road one,
    tr, cr, b, _ = theorem(h)                                 # to the 1e-12 m rounding floor
    assert abs(cr - tr) < 1e-10 and tr < b                    # and the bound sits above
fh = lambda t, x: (x[1], -K * x[1])                           # linear law: a gap obeys the law minus gravity
stretch = max(size(((s[0] - d[0]) / 1.0, (s[1] - d[1]) / 1.0)) for d in ((1.0, 0.0), (0.0, K))
              for s in [step(RK4, fh, 0.0, d, 1.0)])        # 1 m gaps, in height and in speed (k m/s)
assert stretch <= lam(K, 1.0) < 1.1 * stretch                 # Lambda bounds the measured stretch, closely
assert 9 < bound1 / true1 < 11                                # the bound sits about 10 times above
assert 0.95 < log2(bad[1] / bad[2]) < 1.05                    # two swapped weights: order 1
assert all(3.9 < log2(er[i] / er[i+1]) < 4.2 for i in range(4))  # RK4: order 4 overall
assert 0.95 < log2(errs["Euler"][1] / errs["Euler"][2]) < 1.05
assert 1.9 < log2(errs["Heun"][1] / errs["Heun"][2]) < 2.1
assert 31 < loc[0] / loc[1] < 33                              # one step: order 5 locally
assert er[-1] > er[lo] and 1e-13 < er[lo] < 1e-10             # rounding stops the fall
assert abs(xT[0] - run(RK4, rocket(K), 1 / 64, (Y0, V0), T)[0]) < 1e-9   # closed form vs fine run
print("ALL CHECKS PASS")
