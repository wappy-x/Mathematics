# Burgard-Kjaer -- the check behind the card.  Standard library only.
# The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind with no
# collateral.  Northwind's hazard 2%, the bank's own 1%, recovery 40% each; the bank borrows at
# 100 bp over r and lends at r.  One equation, three roads: closed forms where the funding never
# changes sign, a Crank-Nicolson grid (kink handled by policy iteration), and a binomial tree.
from math import exp, log, sqrt, pi

S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LC, LO, RC, RO, SB, SL = 0.02, 0.01, 0.40, 0.40, 0.01, 0.0   # hazards, recoveries, spreads

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                            # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, j = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        j += 2; term *= x * x / j; total += term
    return 0.5 + phi(x) * total
def bs(s, left, put=False):                          # clean Acme option, `left` years to run
    v = sig * sqrt(left); d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * left) / v
    if put: return K * exp(-r * left) * N(v - d1) - s * exp(-q * left) * N(-d1)
    return s * exp(-q * left) * N(d1) - K * exp(-r * left) * N(d1 - v)

M, NT, XM = 300, 200, 1.5                            # grid in x = ln(S/K), steps in time to go
h, k = 2 * XM / M, T / NT
A, B = 0.5 * sig * sig, r - q - 0.5 * sig * sig
lo, hi, md = A * k / h / h - B * k / 2 / h, A * k / h / h + B * k / 2 / h, 2 * A * k / h / h
ea, eb = exp(-h), exp(h)                             # far edges: value straight in S

def thomas(sub, dia, sup, rhs):
    n = len(dia); c, d = [0.0] * n, [0.0] * n
    c[0], d[0] = sup[0] / dia[0], rhs[0] / dia[0]
    for i in range(1, n):
        m = dia[i] - sub[i] * c[i - 1]
        c[i], d[i] = sup[i] / m, (rhs[i] - sub[i] * d[i - 1]) / m
    for i in range(n - 2, -1, -1): d[i] -= c[i] * d[i + 1]
    return d

def grid(pay, rate, src=None):
    """W_tau = A W_xx + B W_x - rate(W) W + src, Crank-Nicolson from expiry. rate(w) reads the
    node's own sign (the kink); each step re-solves until no node changes side.  All rows."""
    W, rows, z = list(pay), [list(pay)], [0.0] * (M + 1)
    for n in range(NT):
        s0, s1 = (src(n), src(n + 1)) if src else (z, z)
        rhs = [W[i] + 0.5 * (lo * W[i - 1] - (md + k * rate(W[i])) * W[i] + hi * W[i + 1])
               + 0.5 * k * (s0[i] + s1[i]) for i in range(1, M)]
        guess = W
        for _ in range(50):
            rho = [rate(w) for w in guess]
            dia = [1 + 0.5 * (md + k * rho[i]) for i in range(1, M)]
            sub, sup = [-0.5 * lo] * (M - 1), [-0.5 * hi] * (M - 1)
            dia[0] -= 0.5 * lo * (1 + ea); sup[0] += 0.5 * lo * ea
            dia[-1] -= 0.5 * hi * (1 + eb); sub[-1] += 0.5 * hi * eb
            u = thomas(sub, dia, sup, rhs)
            new = [(1 + ea) * u[0] - ea * u[1]] + u + [(1 + eb) * u[-1] - eb * u[-2]]
            if [rate(w) for w in new] == rho: break
            guess = new
        W = new; rows.append(W)
    return rows

S = [K * exp(-XM + i * h) for i in range(M + 1)]
mid = M // 2
cpay = [max(s - K, 0.0) for s in S]; cpay[mid] = K * (exp(h / 2) - 1 - h / 2) / h   # cell average
V = grid(cpay, lambda w: r)                          # clean call, every row
pos = lambda n: [max(v, 0.0) for v in V[n]]
z0 = [0.0] * (M + 1)
cva_g = grid(z0, lambda w: r + LC, lambda n: [(1 - RC) * LC * v for v in pos(n)])[-1][mid]
fca_g = grid(z0, lambda w: r + LC, lambda n: [SB * v for v in pos(n)])[-1][mid]
dva_g = grid(z0, lambda w: r + LC + LO, lambda n: [(1 - RO) * LO * v for v in pos(n)])[-1][mid]
# full Burgard-Kjaer for the bought call: U jumps to R_C V at Northwind's default, to V at the bank's
U = grid(cpay, lambda w: r + LC + LO + (SB if w > 0 else SL), lambda n: [(LC * RC + LO) * v for v in pos(n)])
bk_g = V[-1][mid] - U[-1][mid]
Us = grid([-c for c in cpay], lambda w: r + LC + LO + (SB if w > 0 else SL),   # the call sold instead
          lambda n: [-(LC + LO * RO) * v for v in pos(n)])
sold_g = -V[-1][mid] - Us[-1][mid]

C0, P0 = bs(S0, T), bs(S0, T, put=True)
ann = lambda lam: (1 - exp(-lam * T)) / lam          # expected years alive within the year
cva_u, fca_u = (1 - RC) * C0 * (1 - exp(-LC * T)), SB * C0 * ann(LC)
cva_b, fca_b, dva_b = (1 - RC) * LC * C0 * ann(LC + LO), SB * C0 * ann(LC + LO), (1 - RO) * LO * C0 * ann(LC + LO)
bk_c = ((1 - RC) * LC + SB) * C0 * ann(LC + LO + SB)   # U never changes sign: closed form

def tree(pay, lc, lo_, sl, n=2000):                  # binomial road, same rules one step at a time
    dt = T / n; u = exp(sig * sqrt(dt)); p = (exp((r - q) * dt) - 1 / u) / (u - 1 / u)
    v = [pay(S0 * u ** (2 * j - n)) for j in range(n + 1)]; w = list(v)
    for m in range(n - 1, -1, -1):
        v = [exp(-r * dt) * (p * v[j + 1] + (1 - p) * v[j]) for j in range(m + 1)]
        c = [p * w[j + 1] + (1 - p) * w[j] for j in range(m + 1)]
        w = [exp(-(r + lc + lo_ + (SB if c[j] > 0 else sl)) * dt) * c[j]
             + dt * (lc * (RC * max(v[j], 0) + min(v[j], 0)) + lo_ * (max(v[j], 0) + RO * min(v[j], 0)))
             for j in range(m + 1)]
    return v[0] - w[0]
bk_t = tree(lambda s: max(s - K, 0.0), LC, LO, SL)

# funding alone (no defaults): call bought plus put sold, one netting set = a forward at K
fpay = [s - K for s in S]
VF = grid(fpay, lambda w: r)[-1][mid]
net = {}
for bp in (0, 25, 50, 75, 100):
    sl = bp / 10000
    net[bp] = VF - grid(fpay, lambda w, sl=sl: r + (SB if w > 0 else sl))[-1][mid]
pieces = {bp: C0 * (1 - exp(-SB * T)) - P0 * (1 - exp(-bp / 10000 * T)) for bp in net}
net_t = tree(lambda s: s - K, 0.0, 0.0, SL)

rows = [
    ("clean call C0", C0), ("clean put P0", P0), ("clean forward C0 - P0", C0 - P0),
    ("expected years alive, Northwind only", ann(LC)), ("expected years alive, both", ann(LC + LO)),
    ("expected years alive, plus spread", ann(LC + LO + SB)),
    ("linear, Northwind only: CVA closed", cva_u), ("  CVA grid", cva_g),
    ("  FCA closed", fca_u), ("  FCA grid", fca_g),
    ("linear, both can fail: CVA", cva_b), ("  FCA", fca_b), ("  DVA (bought call)", 0.0),
    ("  sum of pieces", cva_b + fca_b), ("  DVA of the sold call, closed", dva_b),
    ("  DVA of the sold call, grid", dva_g),
    ("full equation, call: closed", bk_c), ("  grid", bk_g), ("  tree, 2000 steps", bk_t),
    ("  all-in value C0 - X", C0 - bk_g), ("  gap: pieces minus full", cva_b + fca_b - bk_g),
    ("funding alone: call FCA", C0 * (1 - exp(-SB * T))), ("  sold put, no lending benefit", 0.0),
    ("  trade by trade, sum", pieces[0]), ("  netting set, grid", net[0]),
    ("  netting set, tree", net_t), ("  netting set, symmetric 100 bp", net[100]),
    ("  symmetric closed (C0-P0)(1-e^-s)", (C0 - P0) * (1 - exp(-SB * T))),
    ("wrong: one blended rate, 50 bp", (C0 - P0) * (1 - exp(-0.005 * T))),
    ("try: sold call, full equation, grid", sold_g),
]
for name, v in rows: print(f"{name:<38}{v:12.6f}")
print("chart, lending spread bp " + " ".join(f"{bp:6d}" for bp in net))
print("chart, netting set grid  " + " ".join(f"{100 * net[bp]:6.2f}" for bp in net))
print("chart, trade by trade    " + " ".join(f"{100 * pieces[bp]:6.2f}" for bp in net))

assert abs(C0 - 9.227005508154) < 1e-9, "own normal CDF reproduces the house call"
assert abs(cva_g - cva_u) < 2e-5 and abs(fca_g - fca_u) < 2e-5, "linear grid gives the CVA and FVA cards"
assert abs(dva_g - dva_b) < 2e-5, "grid DVA of the sold call matches its closed form"
assert abs(bk_g - bk_c) < 2e-5, "nonlinear grid matches the closed form where U keeps one sign"
assert abs(sold_g + dva_b) < 2e-5, "sold call: the full equation leaves exactly minus the DVA"
assert abs(bk_t - bk_c) < 2e-4, "tree matches the closed form"
assert abs(net[100] - (C0 - P0) * (1 - exp(-SB * T))) < 2e-5, "symmetric funding: netting set adds up"
assert abs(net_t - net[0]) < 2e-4, "tree and grid agree on the kinked netting set"
assert net[100] + 1e-3 < net[0] < pieces[0] - 1e-3, "kink: neither symmetric nor additive"
print("ALL CHECKS PASS")
