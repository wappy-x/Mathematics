# Asset value and asset volatility from the share price -- the check behind the card.
# Standard library only: normal CDF, root finders, Newton and random numbers are written here.
from math import log, sqrt, exp, pi, cos, sin

B, T, r = 80.0, 1.0, 0.05                 # debt face ($m), years, riskless rate
KD = B * exp(-r * T)                      # the debt's face, discounted to today

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                 # bell-curve area left of x, by its power series
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def merton(V, u, t=T):                    # equity = call on assets V, asset vol u, debt B
    a = u * sqrt(t)
    d1 = log(V / (B * exp(-r * t))) / a + 0.5 * a
    return V * N(d1) - B * exp(-r * t) * N(d1 - a), d1, d1 - a

def by_integral(V, u, n=200000):        # road 0: equity as the average payoff, Simpson's rule
    h, drift, vol = 20.0 / n, (r - 0.5 * u * u) * T, u * sqrt(T)
    f = lambda z: max(V * exp(drift + vol * z) - B, 0.0) * phi(z)
    return exp(-r * T) * h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(-10 + i * h) for i in range(n + 1))
def bisect(f, lo, hi):                    # f rises through zero between lo and hi
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def assets_for_price(E, u): return bisect(lambda V: merton(V, u)[0] - E, E, E + KD)
def assets_for_vol(E, s, u): return bisect(lambda V: u * V * N(merton(V, u)[1]) - s * E, 1e-9, 1e6)

def G(E, u):                              # currency volatility along the price curve
    V = assets_for_price(E, u)
    return V, u * V * N(merton(V, u)[1])

def road_bisect(E, s):                    # road 3: nested bisection, no derivatives
    u = bisect(lambda x: G(E, x)[1] - s * E, 1e-9, 5.0)
    return G(E, u)[0], u
def misses(E, s, V, u):
    C, d1, _ = merton(V, u)
    return C - E, u * V * N(d1) - s * E

def road_newton(E, s, show=False):        # road 1: Newton on the pair, damped by halving
    V, u = E + KD, s * E / (E + KD)
    for k in range(50):
        f1, f2 = misses(E, s, V, u)
        if show: print(f"newton step {k}   V {V:12.6f}   sigma_V {u:9.6f}   miss {abs(f1) + abs(f2):11.6f}")
        if abs(f1) + abs(f2) < 1e-11: return V, u, k
        _, d1, d2 = merton(V, u)
        a11, a12 = N(d1), V * phi(d1) * sqrt(T)
        a21, a22 = u * N(d1) + phi(d1) / sqrt(T), V * (N(d1) - phi(d1) * d2)
        det = a11 * a22 - a12 * a21
        dV, du = (f1 * a22 - f2 * a12) / det, (a11 * f2 - a21 * f1) / det
        lam = 1.0
        while V - lam * dV <= 0 or u - lam * du <= 0 or sum(map(abs, misses(E, s, V - lam * dV, u - lam * du))) > abs(f1) + abs(f2):
            lam *= 0.5
        V, u = V - lam * dV, u - lam * du
    raise RuntimeError("Newton did not converge")
def road_fixed_point(E, s):               # road 2: the fixed-point iteration
    u = s * E / (E + KD)
    for k in range(1, 500):
        V = assets_for_price(E, u)
        u_new = s * E / (V * N(merton(V, u)[1]))
        if abs(u_new - u) < 1e-13: return V, u_new, k
        u = u_new
    raise RuntimeError("fixed point did not converge")
def simulated_equity_vol(V, u, pairs=100000, dt=1.0 / 252):   # road 4: one-day moves, measured
    M, st, E0, xs = 0xFFFFFFFFFFFFFFFF, 20260928, merton(V, u)[0], []
    def unif():                           # splitmix64, written out
        nonlocal st
        st = (st + 0x9E3779B97F4A7C15) & M
        z = ((st ^ (st >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    for _ in range(pairs):                # Box-Muller: two bell-curve draws per pair
        rad, ang = sqrt(-2.0 * log(1.0 - unif())), 2 * pi * unif()
        for z in (rad * cos(ang), rad * sin(ang)):
            V1 = V * exp((r - 0.5 * u * u) * dt + u * sqrt(dt) * z)
            xs.append(log(merton(V1, u, T - dt)[0] / E0))
    m = sum(xs) / len(xs)
    return sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / dt)

# ---- forward: the house firm, assets 100, asset vol 20% ----
E0, d1, d2 = merton(100.0, 0.20)
L0, s0, E_int = 100.0 * N(d1) / E0, 20.0 * N(d1) / E0, by_integral(100.0, 0.20)
print(f"debt face B e^-rT                  {KD:12.6f}")
for name, v in (("ln(V / B e^-rT)", log(100.0 / KD)), ("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)), ("phi(d1)", phi(d1)), ("asset half V N(d1)", 100.0 * N(d1)), ("debt half B e^-rT N(d2)", KD * N(d2)), ("equity E", E0), ("equity E by integral", E_int),
                ("debt V - E", 100.0 - E0), ("leverage L = V N(d1) / E", L0), ("equity vol L x 0.20", s0)):
    print(f"{name:<34} {v:12.6f}")
# ---- inverse, from the rounded quotes ----
E, s = 24.59, 0.755
V1, u1, k1 = road_newton(E, s, show=True)
(V2, u2, k2), (V3, u3) = road_fixed_point(E, s), road_bisect(E, s)
Vx, ux, _ = road_newton(E0, s0)
sim = simulated_equity_vol(100.0, 0.20)
print(f"road 1 Newton        V {V1:12.6f}   sigma_V {u1:9.6f}   steps {k1}")
print(f"road 2 fixed point   V {V2:12.6f}   sigma_V {u2:9.6f}   steps {k2}")
print(f"road 3 bisection     V {V3:12.6f}   sigma_V {u3:9.6f}")
print(f"round trip, exact quotes   V {Vx:12.6f}   sigma_V {ux:9.6f}")
print(f"road 4 simulated equity vol, 200000 one-day moves {sim:9.4f}   (L x 0.20 = {s0:.4f})")
grid = [0.12 + 0.02 * i for i in range(9)]
print("chart1 sigma_V   " + " ".join(f"{g:7.2f}" for g in grid))
print("chart1 price V   " + " ".join(f"{assets_for_price(E, g):7.2f}" for g in grid))
print("chart1 vol V     " + " ".join(f"{assets_for_vol(E, s, g):7.2f}" for g in grid))
vs = [60.0 + 10.0 * i for i in range(11)]
print("chart2 assets V  " + " ".join(f"{v:7.0f}" for v in vs))
print("chart2 eq vol %  " + " ".join(f"{20 * v * N(merton(v, 0.2)[1]) / merton(v, 0.2)[0]:7.2f}" for v in vs))
# ---- conditioning: a 1% error in equity vol, firms of rising leverage ----
print("assets  equity E   equity vol   % move in sigma_V   % move in V   (per 1% error in equity vol)")
for V in (120.0, 100.0, 80.0, 60.0, 50.0, 40.0):
    Ec, d1c, _ = merton(V, 0.20)
    sc = 0.20 * V * N(d1c) / Ec
    Vb, ub = road_bisect(Ec, sc * 1.01)
    print(f"{V:6.0f} {Ec:10.5f} {sc:12.4f} {100 * (ub / 0.20 - 1):19.2f} {100 * (Vb / V - 1):13.3f}")
# ---- no fixed floor, and the floor that does exist ----
Vl, ul, _ = road_newton(E, 0.10)
Ll = Vl * N(merton(Vl, ul)[1]) / E
print(f"equity vol 10%: V {Vl:10.6f}  sigma_V {ul:9.6f}  leverage L {Ll:8.4f}")
print(f"fixed sigma_V 0.20: L at V = 1000 {1000.0 * N(merton(1000.0, 0.2)[1]) / merton(1000.0, 0.2)[0]:9.6f}")
print(f"wrong: equity vol used as asset vol, V {assets_for_price(E, s):10.4f}")
print(f"wrong: share-of-value shortcut, V {E + KD:10.4f}  sigma_V {s * E / (E + KD):8.4f}")
print(f"wrong: undiscounted debt, V = E + B {E + B:10.4f}")
print(f"wrong: price equation only, guess sigma_V 0.30, V {assets_for_price(E, 0.30):10.4f}")

assert abs(Vx - 100.0) < 1e-7 and abs(ux - 0.20) < 1e-9, "round trip returns the generating firm"
assert abs(V1 - V3) < 1e-7 and abs(u1 - u3) < 1e-9, "Newton and bisection agree"
assert k1 <= 5, "Newton with the true Jacobian converges in a handful of steps"
assert abs(V2 - V3) < 1e-7 and abs(u2 - u3) < 1e-9, "fixed point and bisection agree"
assert abs(sim - s0) < 0.006, "simulated equity vol matches leverage x asset vol"
assert abs(E_int - E0) < 1e-8, "average payoff matches the call formula"
assert all(G(E, a)[1] < G(E, b)[1] for a, b in zip(grid, grid[1:])), "G rises: one crossing"
assert 0 < ul < 0.10 and Ll > 1.0, "10% equity vol solves, with equity vol above asset vol"
print("ALL CHECKS PASS")
