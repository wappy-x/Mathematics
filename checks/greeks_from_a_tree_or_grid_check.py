# Greeks from a tree or grid -- the check behind the card.  Standard library
# only.  Nothing imported already knows a Greek: the bell-curve area is built
# from math.erf, every slope below is a difference of prices this script computed
# itself.  Four roads reach the Acme call's delta; the tree's nodes give delta,
# gamma and theta; a grid in log coordinates gives two of them again.
from math import log, sqrt, exp, erf, pi

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def pdf(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x

def d1d2(s, t):
    vt = sig * sqrt(t)
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * t) / vt
    return d1, d1 - vt

def call(s, t):                                           # the Black-Scholes call
    if t <= 0.0: return max(s - K, 0.0)
    d1, d2 = d1d2(s, t)
    return s * exp(-q * t) * N(d1) - K * exp(-r * t) * N(d2)

def bs_delta(s, t):                                       # e^-qT N(d1)
    d1, _ = d1d2(s, t); return exp(-q * t) * N(d1)
def bs_gamma(s, t):
    d1, _ = d1d2(s, t); return exp(-q * t) * pdf(d1) / (s * sig * sqrt(t))
def bs_theta(s, t):                                       # calendar time forward, per year
    d1, d2 = d1d2(s, t)
    return (-s * exp(-q * t) * pdf(d1) * sig / (2.0 * sqrt(t))
            + q * s * exp(-q * t) * N(d1) - r * K * exp(-r * t) * N(d2))
def stencil(vm, v0, vp, hm, hp):                          # chord slope, node curvature
    return (vp - vm) / (hp + hm), 2.0 * ((vp - v0) / hp - (v0 - vm) / hm) / (hp + hm)

def tree(steps):                                          # CRR tree, rows 0, 1, 2 kept
    dt = T / steps; x = sig * sqrt(dt)                    # one step's length and log move
    u, d = exp(x), exp(-x)
    p = (exp((r - q) * dt) - d) / (u - d); disc = exp(-r * dt)
    v = [max(S * exp((2 * j - steps) * x) - K, 0.0) for j in range(steps + 1)]
    rows = {}
    for n in range(steps - 1, -1, -1):
        v = [disc * ((1.0 - p) * v[j] + p * v[j + 1]) for j in range(n + 1)]
        if n <= 2: rows[n] = v[:]
    return u, d, p, rows

def node_greeks(steps):
    dt = T / steps
    u, d, p, rows = tree(steps)
    hp, hm = S * (u * u - 1.0), S * (1.0 - d * d)
    delta = (rows[1][1] - rows[1][0]) / (S * u - S * d)
    gamma = stencil(rows[2][0], rows[2][1], rows[2][2], hm, hp)[1]
    theta = (rows[2][1] - rows[0][0]) / (2.0 * dt)
    return u, d, p, rows, hm, hp, delta, gamma, theta

# ---- an exact fixture: three samples of 3 + 2x + 5x^2 on gaps 1.5 and 4.0 ----
fx_chord, fx_curv = stencil(3.0 - 3.0 + 11.25, 3.0, 3.0 + 8.0 + 80.0, 1.5, 4.0)

# ---- the four-quarter tree of the earlier card ----
u4, d4, p4, r4, hm4, hp4, dl4, gm4, th4 = node_greeks(4)

# ---- a grid in x = ln(S/100), spacing a: slopes in x, converted to slopes in S ----
def grid(a):
    um, u0, up = call(S * exp(-a), T), call(S, T), call(S * exp(a), T)
    ux, uxx = (up - um) / (2.0 * a), (up - 2.0 * u0 + um) / (a * a)
    return ux, uxx, ux / S, (uxx - ux) / (S * S)

ux, uxx, d_grid, g_grid = grid(0.01)
_, _, d_fine, g_fine = grid(0.002)

# ---- four roads to the same delta ----
d_form = bs_delta(S, T)
h = 0.01
d_bump = (call(S + h, T) - call(S - h, T)) / (2.0 * h)
sizes = [4, 8, 16, 32, 64, 128, 256, 1024]
fine = {m: node_greeks(m) for m in sizes}
d_tree = fine[1024][6]

# ---- what breaks ----
g_equal = (r4[2][2] - 2.0 * r4[2][1] + r4[2][0]) / (0.25 * (hm4 + hp4) ** 2)
g_noterm = uxx / (S * S)
th_up = (r4[2][2] - r4[0][0]) / (2.0 * (T / 4.0))
amp = 0.01 * 4.0 / (fine[1024][4] * fine[1024][5])

print(f"house call price, formula                {call(S, T):>12.6f}")
print(f"Black-Scholes delta  e^-qT N(d1)         {d_form:>12.6f}")
print(f"Black-Scholes gamma                      {bs_gamma(S, T):>12.6f}")
print(f"Black-Scholes theta, per year            {bs_theta(S, T):>12.6f}")
print(f"exact fixture 3 + 2x + 5x^2 on gaps 1.5 and 4.0: chord {fx_chord:.6f} curvature {fx_curv:.6f}")
print()
print("the Acme call's delta by four roads")
print(f"  1 tree node slope, 1024 steps          {d_tree:>12.6f}")
print(f"  2 formula e^-qT N(d1)                  {d_form:>12.6f}")
print(f"  3 log-grid slope U_x / S, a = 0.002    {d_fine:>12.6f}")
print(f"  4 price bumped in S, h = 0.01          {d_bump:>12.6f}")
print()
print("the four-quarter tree, node by node")
print(f"  u, d, p                                {u4:.6f} {d4:.6f} {p4:.6f}")
print(f"  step 0   S = {S:.6f}                V = {r4[0][0]:.6f}")
print(f"  step 1   S = {S*d4:.6f} / {S*u4:.6f}      V = {r4[1][0]:.6f} / {r4[1][1]:.6f}")
print(f"  step 2   S = {S*d4*d4:.6f} / {S:.6f} / {S*u4*u4:.6f}")
print(f"  step 2   V = {r4[2][0]:.6f} / {r4[2][1]:.6f} / {r4[2][2]:.6f}")
print(f"  gaps h-, h+                            {hm4:.6f} {hp4:.6f}")
print(f"  slopes below, above the middle node     {(r4[2][1]-r4[2][0])/hm4:.6f} {(r4[2][2]-r4[2][1])/hp4:.6f}")
print(f"  node delta, dated 3 months in          {dl4:>12.6f}")
print(f"  node gamma, dated 6 months in          {gm4:>12.6f}")
print(f"  node theta, per year                   {th4:>12.6f}")
print()
print("the grid in x = ln(S/100): delta = U_x / S, gamma = (U_xx - U_x) / S^2")
print(f"  spacing a = 0.010    delta {d_grid:.6f}   gamma {g_grid:.6f}")
print(f"  spacing a = 0.002    delta {d_fine:.6f}   gamma {g_fine:.6f}")
print()
print("finer trees: the node estimates, and the formula at the node's own date")
print("  steps   node delta   node gamma   node theta   formula delta at that date")
for m in sizes:
    _, _, _, _, _, _, dl, gm, th = fine[m]
    print(f"  {m:>5d}  {dl:>11.6f}  {gm:>11.6f}  {th:>11.6f}   {bs_delta(S, T - T / m):>11.6f}")
print()
print("chart, steps M       " + " ".join(f"{m:>6d}" for m in sizes))
print("chart, gamma error % " + " ".join(f"{100.0*abs(fine[m][7]/bs_gamma(S,T)-1.0):>6.2f}" for m in sizes))
print("chart, theta error % " + " ".join(f"{100.0*abs(fine[m][8]/bs_theta(S,T)-1.0):>6.2f}" for m in sizes))
print()
print("what breaks")
print(f"  4 steps, gaps assumed equal: gamma     {g_equal:>12.6f}")
print(f"  U_x read as a share delta              {ux:>12.6f}")
print(f"  grid gamma with the -U_x term dropped  {g_noterm:>12.6f}")
print(f"  4 steps, theta taken along an up move  {th_up:>12.6f}")
print(f"  1024 steps, one cent of node error     {amp:>12.6f}  of gamma")

assert abs(call(S, T) - 9.227005508154) < 1e-9,  "formula vs the house call price"
assert abs(fx_chord - 14.5) < 1e-12,             "chord on the exact quadratic, by hand 14.5"
assert abs(fx_curv - 10.0) < 1e-12,              "curvature on the exact quadratic, by hand 10"
assert abs(d_fine - d_form) < 2e-6,              "log-grid slope vs the derivative formula"
assert abs(g_fine - bs_gamma(S, T)) < 5e-7,      "log-grid curvature vs the gamma formula"
assert 15.0 * abs(d_fine - d_form) < abs(d_grid - d_form), "the grid's error must shrink like a^2"
assert abs(d_bump - d_form) < 1e-6,              "bumped price vs the derivative formula"
assert abs(d_tree - d_form) < 1e-4,              "1024-step node slope vs the formula"
assert abs(fine[1024][7] - bs_gamma(S, T)) < 5e-4, "1024-step node gamma vs the formula"
assert abs(fine[1024][8] - bs_theta(S, T)) < 0.02, "1024-step node theta vs the formula"
assert abs(g_noterm - bs_gamma(S, T)) > 5e-3,    "dropping the -U_x term must really break gamma"
assert abs(fine[256][7] / bs_gamma(S, T) - 1.0) * 8.0 < abs(fine[4][7] / bs_gamma(S, T) - 1.0), "gamma error must shrink with steps"
print("ALL CHECKS PASS")
