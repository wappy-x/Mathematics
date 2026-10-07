# Exercise boundary and smooth pasting -- the check behind the card.  Standard library only.
# Three roads to the house put's exercise boundary: a 2000-step CRR tree, the early-exercise
# integral equation solved by a root finder, and a PSOR grid on the linear complementarity problem.
from math import log, exp, sqrt
S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0

def N(x):                                   # normal CDF from its Taylor series, no erf
    if abs(x) > 9: return 1.0 if x > 0 else 0.0
    s, t, k = x, x, 1
    while abs(t) > 1e-17 * abs(s):
        k += 2; t *= x * x / k; s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * 3.141592653589793)
def d12(S, b, u):
    d1 = (log(S / b) + (r - q + 0.5 * sig * sig) * u) / (sig * sqrt(u)); return d1, d1 - sig * sqrt(u)
def euro(S, u):                             # European put, u years left
    d1, d2 = d12(S, K, u); return K * exp(-r * u) * N(-d2) - S * exp(-q * u) * N(-d1)
def root(f, lo, hi):                        # bisection: f(lo) and f(hi) have opposite signs
    flo = f(lo)
    for _ in range(60):
        m = 0.5 * (lo + hi); fm = f(m)
        if (fm > 0) == (flo > 0): lo, flo = m, fm
        else: hi = m
    return 0.5 * (lo + hi)

# ---- road 1: CRR tree, 2000 steps a year, started m steps early so the t = 0 slice is wide
def tree(n, m=0, rule=None, want=()):
    dt = T / n; u = exp(sig * sqrt(dt)); p = (exp((r - q) * dt) - 1 / u) / (u - 1 / u); D = exp(-r * dt)
    V = [max(K - S0 * u ** (2 * j - n - m), 0.0) for j in range(n + m + 1)]; edge = {}
    for i in range(n + m - 1, m - 1, -1):
        left = round((n + m - i) * dt, 6); bnd = rule(left) if rule else None; ex = None
        for j in range(i + 1):
            s = S0 * u ** (2 * j - i); c = D * (p * V[j + 1] + (1 - p) * V[j])
            stop = K - s > c if rule is None else s <= bnd
            V[j] = K - s if stop else c
            if stop: ex = s
        if left in want: edge[left] = ex
    return V[m // 2], edge, u * u
LEFT = (1.0, 0.75, 0.5, 0.25, 0.09, 0.04, 0.01, 0.0025)
A_tree, edge, gap = tree(2000, 400, want=LEFT)

# ---- road 2: the early-exercise integral equation, marched from expiry with bisection
def prem(S, taus, Bs, i):                   # early-exercise premium, trapezoid over the boundary
    tot, pu, pf = 0.0, None, None
    for j in range(i, -1, -1):
        u = taus[i] - taus[j]
        if u == 0: f = 0.5 * (r * K - q * S) if S == Bs[j] else (r * K - q * S) * (S < Bs[j])
        else:
            d1, d2 = d12(S, Bs[j], u); f = r * K * exp(-r * u) * N(-d2) - q * S * exp(-q * u) * N(-d1)
        if pu is not None: tot += 0.5 * (f + pf) * (u - pu)
        pu, pf = u, f
    return tot
n = 200; taus = [T * (i / n) ** 2 for i in range(n + 1)]; Bs = [K]
for i in range(1, n + 1):
    Bs.append(root(lambda b: K - b - euro(b, taus[i]) - prem(b, taus, Bs[:i] + [b], i), 40.0, Bs[-1]))
def B_int(t):                               # boundary at t years left, linear between grid dates
    i = max(k for k in range(n) if taus[k] <= t); w = (t - taus[i]) / (taus[i + 1] - taus[i])
    return Bs[i] + w * (Bs[i + 1] - Bs[i]) if i < n else Bs[n]
def V_int(S, m=800):                        # price anywhere: Simpson in v, where u = v^2 years from now
    if S <= Bs[n]: return K - S
    hv, tot = sqrt(T) / m, 0.0
    for k in range(1, m + 1):
        u = (k * hv) ** 2; d1, d2 = d12(S, B_int(T - u), u)
        f = r * K * exp(-r * u) * N(-d2) - q * S * exp(-q * u) * N(-d1)
        tot += (4 if k % 2 else 2 if k < m else 1) * f * 2 * k * hv
    return euro(S, T) + tot * hv / 3
A_int = V_int(S0)

# ---- road 3: implicit grid in log-price; PSOR solves the complementarity problem each step
dx, nt, w = 0.005, 1000, 1.5
Sg = [S0 * exp(k * dx) for k in range(-500, 401)]; M = len(Sg) - 1; g = [max(K - s, 0.0) for s in Sg]
dt = T / nt; a = 0.5 * sig * sig * dt / dx ** 2; b = (r - q - 0.5 * sig * sig) * dt / (2 * dx)
dn, up, dg = a - b, a + b, 1 + 2 * a + r * dt
V = g[:]
for step in range(nt):
    rhs = V[:]
    while True:
        err = 0.0
        for k in range(1, M):
            y = max(g[k], V[k] + w * ((rhs[k] + dn * V[k - 1] + up * V[k + 1]) / dg - V[k]))
            err = max(err, abs(y - V[k])); V[k] = y
        if err < 1e-11: break
res = [dg * V[k] - dn * V[k - 1] - up * V[k + 1] - rhs[k] for k in range(1, M)]
gapc = max(abs(min(V[k] - g[k], res[k - 1])) for k in range(1, M))
def V_grid(S):
    k = int(log(S / Sg[0]) / dx); f = (S - Sg[k]) / (Sg[k + 1] - Sg[k]); return V[k] + f * (V[k + 1] - V[k])
A_grid = V_grid(S0); B_grid = max(s for s, v, x in zip(Sg, V, g) if s < K and v - x < 1e-9)

# ---- smooth pasting at t = 0: slopes by nudging, and the curvature balance at the boundary
B1, h = Bs[n], 0.05
def slope(f, S): return (f(S + h) - f(S - h)) / (2 * h)
def eu_delta(S): return -exp(-q * T) * N(-d12(S, K, T)[0])
side = [(V_int(B1 + e) - (K - B1)) / e for e in (2.0, 1.0, 0.5)]
bal_int = 0.5 * sig * sig * B1 * B1 * (V_int(B1 + 0.75) - 2 * V_int(B1 + 0.5) + V_int(B1 + 0.25)) / 0.0625
j = Sg.index(B_grid) + 1; sl = [(V[i + 1] - V[i]) / (Sg[i + 1] - Sg[i]) for i in (j - 1, j)]
bal_grid = 0.5 * sig * sig * B1 * B1 * (sl[1] - sl[0]) / (0.5 * (Sg[j + 1] - Sg[j - 1]))
c = r - q - 0.5 * sig * sig; beta = (-c - sqrt(c * c + 2 * sig * sig * r)) / (sig * sig); B_perp = beta * K / (beta - 1)

# ---- what breaks: exercise rules that are not the free boundary, priced on the same tree
cross = lambda t: root(lambda s: euro(s, t) - (K - s), 20.0, K - 1e-9)
wrong = [tree(2000, rule=lambda t: B1)[0], tree(2000, rule=lambda t: B_perp)[0], tree(2000, rule=cross)[0]]

print("American put today   tree %.6f   integral %.6f   grid %.6f" % (A_tree, A_int, A_grid))
print("European put %.6f   early-exercise premium %.6f" % (euro(S0, T), A_int - euro(S0, T)))
print("boundary   years left   tree node   integral")
for t in LEFT: print("           %10.4f %11.2f %10.2f" % (t, edge[t], B_int(t)))
print("           %10.4f %11.2f %10.2f" % (0.0, K, K))
print("tree node spacing factor u^2 %.6f   grid exercise node %.3f" % (gap, B_grid))
print("grid complementarity gap %.1e   perpetual floor %.3f" % (gapc, B_perp))
print("today       S    value    K-S  delta int  delta grid  delta Euro")
for S in (70.0, 74.0, 78.0, 82.0, 86.0, 90.0, 94.0, 98.0):
    print("       %6.1f %8.3f %6.2f %10.4f %11.4f %11.4f" % (S, V_int(S), K - S, slope(V_int, S), slope(V_grid, S), eu_delta(S)))
print("chart delta American " + " ".join("%.2f" % slope(V_int, S) for S in range(70, 99, 4)))
print("chart delta European " + " ".join("%.2f" % eu_delta(S) for S in range(70, 99, 4)))
print("slope from B out by 2, 1, 0.5:  %.4f  %.4f  %.4f" % tuple(side))
print("European delta at B %.4f" % eu_delta(B1))
print("balance at B: integral %.4f  grid %.4f  rK - qB %.4f" % (bal_int, bal_grid, r * K - q * B1))
print("wrong: freeze today's B %.6f" % wrong[0])
print("wrong: perpetual floor  %.6f" % wrong[1])
print("wrong: European cross   %.6f   (cross today %.3f)" % (wrong[2], cross(T)))

assert abs(euro(S0, T) - 6.330080627550) < 1e-9, "series CDF against the pilot card's European put"
assert abs(A_int - A_tree) < 0.002 and abs(A_grid - A_tree) < 0.005, "three roads, one price"
assert all(abs(edge[t] - B_int(t)) < edge[t] * (gap - 1) for t in LEFT), "tree within one node"
assert abs(B_grid - B1) < B_grid * (exp(dx) - 1), "grid within one node"
assert all(B_int(a) < B_int(b) for a, b in zip(LEFT, LEFT[1:])) and B_perp < B1 and K - Bs[1] < 0.5, "rises to K"
g1, g2, g3 = (1 + x for x in side)
assert 1.8 < g1 / g2 < 2.2 and 1.8 < g2 / g3 < 2.2, "slope gap halves with the step: no corner"
assert abs(slope(V_int, 78.0) - slope(V_grid, 78.0)) < 0.005 and eu_delta(B1) > -0.9, "pasting"
assert abs(bal_int / (r * K - q * B1) - 1) < 0.01 and abs(bal_grid / (r * K - q * B1) - 1) < 0.01
assert gapc < 1e-9 and max(wrong) < A_tree - 0.1, "complementarity holds; wrong rules lose"
print("ALL CHECKS PASS")
