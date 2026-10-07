# American Greeks and implied volatility -- the check behind the card.
# Standard library only.  Nothing imported knows the answer: the bell-curve
# area is Simpson's rule, the tree, the grid and both root finders are loops.
from math import exp, sqrt, log, pi

def N(x, n=2000):                        # bell-curve area left of x, by Simpson
    h = x / n; f = lambda z: exp(-0.5 * z * z) / sqrt(2 * pi)
    s = f(0.0) + f(x) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))
    return 0.5 + s * h / 3

def bs_put(S, K, r, q, sig, T):          # European put, the pilot's formula
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return K * exp(-r * T) * N(-(d1 - sig * sqrt(T))) - S * exp(-q * T) * N(-d1), d1

def tree(S, K, r, q, sig, T, n=2000, american=True):
    # Road 1: Cox-Ross-Rubinstein tree.  Returns price and the node Greeks.
    dt = T / n; u = exp(sig * sqrt(dt)); d = 1 / u
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    s = [S * d ** n * u ** (2 * j) for j in range(n + 1)]
    v = [max(K - x, 0.0) for x in s]
    keep = {}
    for i in range(n - 1, -1, -1):
        s = [x * u for x in s[:-1]]                       # prices one step earlier
        v = [disc * (p * v[j + 1] + (1 - p) * v[j]) for j in range(i + 1)]
        if american: v = [max(v[j], K - s[j]) for j in range(i + 1)]
        if i <= 2: keep[i] = (s, v)
    (s1, v1), (s2, v2) = keep[1], keep[2]
    delta = (v1[1] - v1[0]) / (s1[1] - s1[0])
    gamma = bend(s2, v2, 1)
    return v[0], delta, gamma, (v2[1] - v[0]) / (2 * dt)

def bend(s, v, i):                       # three unevenly spaced prices -> gamma
    hp, hm = s[i + 1] - s[i], s[i] - s[i - 1]
    return 2 / (hp + hm) * ((v[i + 1] - v[i]) / hp - (v[i] - v[i - 1]) / hm)

def slope(s, v, i):                      # slope of the same parabola at the middle
    hp, hm = s[i + 1] - s[i], s[i] - s[i - 1]
    return ((v[i + 1] - v[i]) / hp * hm + (v[i] - v[i - 1]) / hm * hp) / (hp + hm)

def grid(S, K, r, q, sig, T, dx=0.005, L=1.5, M=2500):
    # Road 2: explicit finite differences in x = ln(S/100), early exercise
    # enforced after every time step.  Returns node prices now and one step later.
    n = round(L / dx); ss = [S * exp((i - n) * dx) for i in range(2 * n + 1)]
    g = [max(K - x, 0.0) for x in ss]; dt = T / M; nu = r - q - 0.5 * sig * sig
    a = dt * (0.5 * sig * sig / dx ** 2 - nu / (2 * dx))
    c = dt * (0.5 * sig * sig / dx ** 2 + nu / (2 * dx)); b = 1 - dt * (sig * sig / dx ** 2 + r)
    v = g[:]
    for m in range(M):
        prev = v
        v = [g[0]] + [max(g[i], a * prev[i - 1] + b * prev[i] + c * prev[i + 1])
                      for i in range(1, 2 * n)] + [0.0]
    return ss, v, prev, dt, g, n

def bisect(f, lo, hi, tol=1e-9):         # f(lo) < 0 < f(hi); halve until tiny
    while hi - lo > tol:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return 0.5 * (lo + hi)

def secant(f, x0, x1, tol=1e-10):
    f0, f1 = f(x0), f(x1)
    while abs(x1 - x0) > tol:
        x0, x1, f0 = x1, x1 - f1 * (x1 - x0) / (f1 - f0), f1
        f1 = f(x1)
    return x1

S, K, r, q, sig, T, QUOTE = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 6.660226
P, D, G, TH = tree(S, K, r, q, sig, T)
PE_tree, DE_tree, _, _ = tree(S, K, r, q, sig, T, american=False)
PE, d1 = bs_put(S, K, r, q, sig, T); DE = -exp(-q * T) * N(-d1)
ss, v, prev, dt, g, n = grid(S, K, r, q, sig, T)
gp = lambda **kw: grid(**{**dict(S=S, K=K, r=r, q=q, sig=sig, T=T), **kw})[1][n]
tp = lambda **kw: tree(**{**dict(S=S, K=K, r=r, q=q, sig=sig, T=T), **kw})[0]
v21, v19 = tp(sig=sig + 0.01), tp(sig=sig - 0.01); vega_t = (v21 - v19) / 0.02
vega_g = (gp(sig=sig + 0.01) - gp(sig=sig - 0.01)) / 0.02
rho_t = (tp(r=r + 0.01) - tp(r=r - 0.01)) / 0.02
rho_g = (gp(r=r + 0.01) - gp(r=r - 0.01)) / 0.02
b = max(i for i in range(1, 2 * n) if v[i] == g[i])      # last node exercised today
jump = 2 * (r * K - q * ss[b]) / (sig * sig * ss[b] ** 2)
_, D70, G70, _ = tree(70.0, K, r, q, sig, T)
iv_tree = bisect(lambda x: tp(sig=x) - QUOTE, 0.01, 2.0)
iv_grid = secant(lambda x: gp(sig=x) - QUOTE, 0.18, 0.22)
iv_euro = bisect(lambda x: bs_put(S, K, r, q, x, T)[0] - QUOTE, 0.01, 2.0)
bump_gamma = (tp(S=S + 0.01) - 2 * P + tp(S=S - 0.01)) / 0.01 ** 2
P_rich = 2 * P - tp(n=1000)                              # Richardson: tree error ~ 1/steps
rows = [("price, tree 2000 steps", P), ("price, grid", v[n]), ("price, Richardson 1000/2000", P_rich),
        ("price, tree + control variate", P + PE - PE_tree),
        ("European put, formula", PE), ("European put, tree 2000 steps", PE_tree),
        ("delta, tree nodes", D), ("delta, grid", slope(ss, v, n)),
        ("gamma, tree nodes", G), ("gamma, grid", bend(ss, v, n)),
        ("theta per year, tree nodes", TH), ("theta per year, grid", (prev[n] - v[n]) / dt),
        ("theta per day, tree nodes", TH / 365), ("early-exercise premium, tree", P - PE),
        ("tree price at sigma 0.21", v21), ("tree price at sigma 0.19", v19),
        ("vega per 1.00, tree, bump 0.01", vega_t), ("vega per 1.00, grid, bump 0.01", vega_g),
        ("rho per 1.00, tree, bump 0.01", rho_t), ("rho per 1.00, grid, bump 0.01", rho_g), ("vega per vol point, tree", vega_t / 100),
        ("last exercised node today, grid", ss[b]), ("first held node today, grid", ss[b + 1]),
        ("carry rK - qS* there", r * K - q * ss[b]),
        ("sigma^2 S*^2 there", sig * sig * ss[b] ** 2), ("gamma one node above, grid", bend(ss, v, b + 1)), ("gamma jump 2(rK-qS*)/(s^2 S*^2)", jump),
        ("S = 70: delta, tree nodes", D70), ("S = 70: gamma, tree nodes", round(G70, 9) + 0.0),
        ("implied vol, bisection on tree", iv_tree), ("implied vol, secant on grid", iv_grid),
        ("wrong: European formula inverted", iv_euro), ("wrong: European delta", DE),
        ("wrong: gamma by 1-cent spot bump", bump_gamma),
        ("range: price at sigma 0.01", tp(sig=0.01)), ("range: price at sigma 2.00", tp(sig=2.0))]
for name, x in rows:
    print(f"{name:<36} {x:>12.6f}")
print("S = 70, sigma 0.10 0.20 0.30 0.40:" + "".join(f" {tp(S=70.0, sig=x):.6f}" for x in (0.1, 0.2, 0.3, 0.4)))
sigs = [0.05 * k for k in range(1, 9)]
print("chart, sigma        " + " ".join(f"{x:6.2f}" for x in sigs))
print("chart, American put " + " ".join(f"{tp(sig=x):6.2f}" for x in sigs))
print("chart, European put " + " ".join(f"{bs_put(S, K, r, q, x, T)[0]:6.2f}" for x in sigs))
idx = [n + k for k in (-60, -51, -49, -40, -30, -20, -10, 0, 10, 20)]
eu = [bs_put(ss[i], K, r, q, sig, T)[1] for i in idx]
print("chart, spot         " + " ".join(f"{ss[i]:7.2f}" for i in idx))
print("chart, Am. delta    " + " ".join(f"{slope(ss, v, i):7.2f}" for i in idx))
print("chart, Eu. delta    " + " ".join(f"{-exp(-q * T) * N(-x):7.2f}" for x in eu))
print("chart, Am. gamma x100" + " ".join(f"{100 * bend(ss, v, i):7.2f}" for i in idx))
print("chart, Eu. gamma x100" + " ".join(f"{100*exp(-q*T-x*x/2)/sqrt(2*pi)/(ss[i]*sig):7.2f}" for x, i in zip(eu, idx)))

assert abs(P - QUOTE) < 1e-6, "tree reproduces the house quote"
assert abs(PE - 6.330080627550) < 1e-9, "own bell curve reproduces the house European put"
assert abs(P_rich - v[n]) < 1e-4, "tree (extrapolated) and grid agree on the price"
assert abs(D - slope(ss, v, n)) < 1e-5, "delta: tree nodes vs grid"
assert abs(G - bend(ss, v, n)) < 1e-4, "gamma: tree nodes vs grid"
assert abs(TH - (prev[n] - v[n]) / dt) < 0.01, "theta: tree nodes vs grid"
assert abs(vega_t - vega_g) < 0.05, "vega: tree bump vs grid bump"
assert abs(rho_t - rho_g) < 0.05, "rho: tree bump vs grid bump"
assert abs(D70 + 1.0) < 1e-12, "delta is -1 inside the exercise region"
assert abs(G70) < 1e-12, "gamma is 0 inside the exercise region"
assert abs(bend(ss, v, b + 1) - jump) < 0.01 * jump, "gamma jump: grid vs 2(rK - qS*)/(sigma^2 S*^2)"
assert abs(iv_tree - sig) < 1e-6, "bisection on the tree recovers 20 percent"
assert abs(iv_grid - iv_tree) < 1e-4, "secant on the grid lands beside it"
assert iv_euro > iv_tree + 0.005, "European inversion books the premium as volatility"
assert all(abs(tp(S=70.0, sig=x) - 30.0) < 1e-9 for x in (0.1, 0.2)), "flat at $70: a plateau"
am = [tp(sig=x) for x in sigs]
assert all(x < y for x, y in zip(am, am[1:])), "American price strictly rises in volatility"
print("ALL CHECKS PASS")
