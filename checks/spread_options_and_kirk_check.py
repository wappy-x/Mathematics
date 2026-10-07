# Spread options and Kirk's approximation -- the check behind the card.  Standard library only.
# Two house shares, each at 100, 20% volatility, 2% dividend; correlation 0.5; r = 5%; one year.
# Nothing imported knows the answer: the bell-curve area is Marsaglia's series written out,
# the integral is Simpson's rule written out, the random numbers are splitmix64 written out.
from math import log, sqrt, exp, cos, sin, pi

S1, S2, v1, v2, q1, q2, r, T, RHO, K = 100.0, 100.0, 0.20, 0.20, 0.02, 0.02, 0.05, 1.0, 0.5, 5.0
disc = exp(-r * T)

def N(x):                                   # area left of x under the bell curve
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0
        b *= x * x / i
        t, s = s, s + b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)

def kirk(k, rho, a=S1, b=S2, fold=None, w_one=False):   # road 1: fold the strike into asset 2
    F1, F2 = a * exp((r - q1) * T), b * exp((r - q2) * T)
    Y = F2 + k if fold is None else fold                   # the forward of "asset 2 plus strike"
    w = 1.0 if w_one else F2 / Y
    vk = sqrt((v1 * v1 - 2.0 * rho * v1 * v2 * w + v2 * v2 * w * w) * T)
    d1 = (log(F1 / Y) + 0.5 * vk * vk) / vk
    return disc * (F1 * N(d1) - Y * N(d1 - vk)), w, vk, d1, F1, F2, Y

def margrabe(rho):                          # the K = 0 closed form, in spot terms (sibling card 01)
    v = sqrt(v1 * v1 + v2 * v2 - 2.0 * rho * v1 * v2)
    d1 = (log(S1 / S2) + (q2 - q1 + 0.5 * v * v) * T) / (v * sqrt(T))
    return S1 * exp(-q1 * T) * N(d1) - S2 * exp(-q2 * T) * N(d1 - v * sqrt(T))

def exact(k, rho, a=S1, b=S2, put=False, n=400):   # road 2: fix asset 2's draw, Black-Scholes on asset 1
    F1, F2, rt = a * exp((r - q1) * T), b * exp((r - q2) * T), sqrt(T)
    s = v1 * rt * sqrt(1.0 - rho * rho)             # asset 1's leftover spread once asset 2 is known
    def f(z):
        X = F2 * exp(-0.5 * v2 * v2 * T + v2 * rt * z) + k            # asset 2 at expiry, plus strike
        G = F1 * exp(-0.5 * v1 * v1 * rho * rho * T + v1 * rt * rho * z)   # asset 1's forward given z
        d1 = (log(G / X) + 0.5 * s * s) / s
        c = X * N(s - d1) - G * N(-d1) if put else G * N(d1) - X * N(d1 - s)
        return c * exp(-0.5 * z * z) / sqrt(2.0 * pi)
    h = 18.0 / n
    tot = f(-9.0) + f(9.0)
    for i in range(1, n): tot += (4.0 if i % 2 else 2.0) * f(-9.0 + i * h)
    return disc * tot * h / 3.0

state = 20260924                            # splitmix64: 64-bit integer mixing
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

# road 3: simulate 1,000,000 expiries; Cholesky turns two independent draws into correlated ones
cells = ((0.5, 0.0), (0.5, 5.0), (-0.5, 20.0))
F1, F2 = S1 * exp((r - q1) * T), S2 * exp((r - q2) * T)
sm, sq, paths = [0.0] * 3, [0.0] * 3, 1000000
for _ in range(paths):
    rad, ang = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    g1, g2 = rad * cos(ang), rad * sin(ang)           # Box-Muller: two independent bell-curve draws
    for c, (rho, k) in enumerate(cells):
        z1 = rho * g1 + sqrt(1.0 - rho * rho) * g2
        A = F1 * exp(-0.5 * v1 * v1 * T + v1 * sqrt(T) * z1)
        B = F2 * exp(-0.5 * v2 * v2 * T + v2 * sqrt(T) * g1)
        p = disc * max(A - B - k, 0.0)
        sm[c] += p; sq[c] += p * p
mc = [sm[c] / paths for c in range(3)]
se = [sqrt((sq[c] / paths - mc[c] * mc[c]) / (paths - 1)) for c in range(3)]

ck, w, vk, d1, F1, F2, Y = kirk(K, RHO)
ce, pe, mg = exact(K, RHO), exact(K, RHO, put=True), margrabe(RHO)
def bump(f, h): return (f(h) - f(-h)) / (2.0 * h)
greeks = [("delta, asset 1", lambda h: kirk(K, RHO, a=S1 + h)[0], lambda h: exact(K, RHO, a=S1 + h), 0.01, 1.0),
          ("delta, asset 2", lambda h: kirk(K, RHO, b=S2 + h)[0], lambda h: exact(K, RHO, b=S2 + h), 0.01, 1.0),
          ("correlation, per 0.01", lambda h: kirk(K, RHO + h)[0], lambda h: exact(K, RHO + h), 0.001, 0.01)]
rows = [("forward of each share, F1 = F2", F1), ("asset 2 plus strike, F2 + K", Y), ("weight w = F2/(F2+K)", w),
        ("Kirk volatility sigma_K", vk), ("Kirk d1", d1), ("Kirk d2", d1 - vk), ("N(d1)", N(d1)), ("N(d2)", N(d1 - vk)),
        ("share leg  e^-rT F1 N(d1)", disc * F1 * N(d1)), ("cash leg   e^-rT (F2+K) N(d2)", disc * Y * N(d1 - vk)),
        ("1 Kirk, K = 5", ck), ("2 exact integral, K = 5", ce), ("3 simulation, K = 5", mc[1]),
        ("  simulation error bar", se[1]), ("  Kirk minus exact, cents", 100.0 * (ck - ce)),
        ("Margrabe closed form, K = 0", mg), ("  ratio volatility, K = 0", kirk(0.0, RHO)[2]),
        ("  exact integral, K = 0", exact(0.0, RHO)),
        ("  simulation, K = 0", mc[0]), ("  simulation error bar", se[0]),
        ("put by integral, K = 5", pe), ("  C - P", ce - pe), ("  e^-rT (F1 - F2 - K)", disc * (F1 - F2 - K))]
for name, fk, fe, h, unit in greeks:
    rows += [(name + ", Kirk", bump(fk, h) * unit), ("  " + name + ", exact", bump(fe, h) * unit)]
rows += [("wrong: Margrabe minus e^-rT K", mg - disc * K), ("wrong: Kirk with w = 1", kirk(K, RHO, w_one=True)[0]),
         ("wrong: strike added to spot", kirk(K, RHO, fold=(S2 + K) * exp((r - q2) * T))[0]),
         ("wrong: correlation left out", exact(K, 0.0)), ("simulation, rho -0.5, K = 20", mc[2]),
         ("  simulation error bar", se[2]), ("  Kirk, rho -0.5, K = 20", kirk(20.0, -0.5)[0])]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")

Ks, rhos = (0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0), (-0.5, 0.0, 0.5, 0.9)
grid = {(p, k): (kirk(k, p)[0], exact(k, p)) for p in rhos for k in Ks}
print("exact price    K:" + "".join(f"{k:>8.0f}" for k in Ks))
for p in rhos: print(f"  rho {p:>5.1f}      " + "".join(f"{grid[p, k][1]:>8.2f}" for k in Ks))
print("Kirk - exact, cents")
for p in rhos: print(f"  rho {p:>5.1f}      " + "".join(f"{round(100.0 * (grid[p, k][0] - grid[p, k][1]), 2) + 0.0:>8.2f}" for k in Ks))
print("Kirk - exact, percent of exact")
for p in rhos: print(f"  rho {p:>5.1f}      " + "".join(f"{round(100.0 * (grid[p, k][0] / grid[p, k][1] - 1.0), 2) + 0.0:>8.2f}" for k in Ks))
xs = (-10.0, -5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0)
print("chart, spread at expiry" + "".join(f"{x:>7.0f}" for x in xs))
print("chart, profit after 5.67" + "".join(f"{max(x - K, 0.0) - round(ce, 2):>7.2f}" for x in xs)[1:])

assert abs(exact(0.0, RHO) - 7.807839) < 1e-6,          "integral at K = 0 must land on Margrabe's house number"
assert abs(mg - exact(0.0, RHO)) < 1e-9,                "Margrabe formula vs the conditional integral"
assert all(abs(mc[c] - exact(k, p)) < 3.0 * se[c] for c, (p, k) in enumerate(cells)), "simulation within 3 error bars"
assert abs(ck - ce) < 0.001 * ce,                     "Kirk within a tenth of a percent at the house strike"
assert abs((ce - pe) - disc * (F1 - F2 - K)) < 1e-9,    "put-call parity with an independently priced put"
assert all(grid[p, a][0] / grid[p, a][1] < grid[p, b][0] / grid[p, b][1] for p in (-0.5, 0.0, 0.5)
           for a, b in zip(Ks[1:], Ks[2:])), "Kirk's percent error grows with the strike at correlation 0.5 and below"
assert all(grid[a, k][0] - grid[a, k][1] > grid[b, k][0] - grid[b, k][1] for k in Ks[1:]
           for a, b in ((-0.5, 0.0), (0.0, 0.5))), "Kirk's error in cents shrinks as correlation rises to 0.5"
print("ALL CHECKS PASS")
