# Delta-gamma-vega hedging -- the check behind the card.  Standard library only.
# A book short 10,000 one-year Acme calls is flattened with two listed options and shares.
# Road 1: analytic Greeks, Cramer's rule on the 2x2, shares last.
# Road 2: Greeks by bumping the price, Gaussian elimination on the full 3x3.
# Road 3: revalue the hedged book under bumps and scenarios; its Greeks must vanish.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height
def N(x):                                                       # bell-curve area, by its power series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

S0, R, Q, SIG = 100.0, 0.05, 0.02, 0.20                         # the house market

def price(kind, K, T, S=S0, sig=SIG):
    if T <= 0: return max(S - K, 0.0) if kind == "call" else max(K - S, 0.0)
    vt = sig * sqrt(T)
    d1 = (log(S / K) + (R - Q + 0.5 * sig * sig) * T) / vt; d2 = d1 - vt
    if kind == "call": return S * exp(-Q * T) * N(d1) - K * exp(-R * T) * N(d2)
    return K * exp(-R * T) * N(-d2) - S * exp(-Q * T) * N(-d1)

def greeks(kind, K, T, S=S0, sig=SIG):                          # delta, gamma, vega per 1 vol point
    vt = sig * sqrt(T); d1 = (log(S / K) + (R - Q + 0.5 * sig * sig) * T) / vt
    delta = exp(-Q * T) * (N(d1) if kind == "call" else N(d1) - 1.0)
    return delta, exp(-Q * T) * phi(d1) / (S * vt), S * exp(-Q * T) * phi(d1) * sqrt(T) / 100.0

def bumped(kind, K, T, h=0.01, e=1e-4):                         # the same three, by nudging the price
    p = lambda S=S0, sig=SIG: price(kind, K, T, S, sig)
    return ((p(S0 + h) - p(S0 - h)) / (2 * h), (p(S0 + h) - 2 * p() + p(S0 - h)) / (h * h),
            (p(sig=SIG + e) - p(sig=SIG - e)) / (2 * e) / 100.0)

BOOK, A, B = ("call", 100.0, 1.0), ("put", 100.0, 0.25), ("call", 110.0, 2.0)
NBOOK = -10000.0                                                # sold 10,000 one-year calls

def det(ga, gb): return ga[1] * gb[2] - gb[1] * ga[2]            # gamma-vega determinant D

def cramer(gp, ga, gb):                                         # road 1: 2x2 for options, then shares
    D = det(ga, gb)
    na = (-gp[1] * gb[2] + gb[1] * gp[2]) / D
    nb = (-ga[1] * gp[2] + gp[1] * ga[2]) / D
    return na, nb, -(gp[0] + na * ga[0] + nb * gb[0]), D

def gauss(M, v):                                                # road 2: elimination, partial pivoting
    M = [row[:] + [x] for row, x in zip(M, v)]; n = len(M)
    for c in range(n):
        piv = max(range(c, n), key=lambda i: abs(M[i][c])); M[c], M[piv] = M[piv], M[c]
        for i in range(c + 1, n):
            f = M[i][c] / M[c][c]; M[i] = [a - f * b for a, b in zip(M[i], M[c])]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x

gP = [NBOOK * g for g in greeks(*BOOK)]; gA, gB = greeks(*A), greeks(*B)
na, nb, ns, D = cramer(gP, gA, gB)
bP = [NBOOK * g for g in bumped(*BOOK)]; bA, bB = bumped(*A), bumped(*B)
ns2, na2, nb2 = gauss([[1.0, bA[0], bB[0]], [0.0, bA[1], bB[1]], [0.0, bA[2], bB[2]]], [-x for x in bP])

def value(pos, S=S0, sig=SIG, dt=0.0):                          # road 3: full revaluation of a book
    return sum(n * (S if leg == "share" else price(leg[0], leg[1], leg[2] - dt, S, sig)) for n, leg in pos)
full = [(NBOOK, BOOK), (na, A), (nb, B), (ns, "share")]
donly = [(NBOOK, BOOK), (-gP[0], "share")]
bare = [(NBOOK, BOOK)]
v0 = value(full); h, e = 0.01, 1e-4
rev = ((value(full, S0 + h) - value(full, S0 - h)) / (2 * h),
       (value(full, S0 + h) - 2 * v0 + value(full, S0 - h)) / (h * h),
       (value(full, sig=SIG + e) - value(full, sig=SIG - e)) / (2 * e) / 100.0)
pnl = lambda pos, S=S0, sig=SIG, dt=0.0: value(pos, S, sig, dt) - value(pos)

def show(label, *xs, f="{:>13.4f}"): print(f"{label:<30}" + "".join(f.format(x) for x in xs))
print(f"{'per option':<30}{'price':>13}{'delta':>13}{'gamma':>13}{'vega/pt':>13}")
for lab, leg, g in (("book: 1y call K100", BOOK, greeks(*BOOK)), ("A: 3m put K100", A, gA), ("B: 2y call K110", B, gB)):
    show(lab, price(*leg), *g, f="{:>13.6f}")
for lab, g in (("bumped: book call", bumped(*BOOK)), ("bumped: A", bA), ("bumped: B", bB)):
    print(f"{lab:<30}{'':>13}" + "".join(f"{x:>13.6f}" for x in g))
show("book x -10000: value, Greeks", NBOOK * price(*BOOK), *gP, f="{:>13.2f}")
show("vega/gamma: A, book, B", *(g[2] / g[1] for g in (gA, greeks(*BOOK), gB)))
show("S^2 sigma T / 100: A, book, B", *(S0 * S0 * SIG * leg[2] / 100.0 for leg in (A, BOOK, B)))
show("determinant D", D, f="{:>13.8f}")
show("Cramer tops: nA x D, nB x D", na * D, nb * D, f="{:>13.6f}")
rA, rP, rB = (g[2] / g[1] for g in (gA, greeks(*BOOK), gB))
show("gamma shares wA, wB", (rB - rP) / (rB - rA), (rP - rA) / (rB - rA), f="{:>13.6f}")
show("road 1 Cramer: nA nB nS", na, nb, ns, f="{:>13.2f}")
show("road 2 Gauss, bumped: nA nB nS", na2, nb2, ns2, f="{:>13.2f}")
show("delta: book, from A, from B", gP[0], na * gA[0], nb * gB[0], f="{:>13.2f}")
show("hedge cost: A, B, shares", na * price(*A), nb * price(*B), ns * S0, f="{:>13.2f}")
show("road 3 revalued: |d| |g| |v|", *(abs(x) for x in rev))
print(f"{'spot':<30}{'no hedge':>13}{'delta only':>13}{'all three':>13}")
for s in range(80, 121, 5): show(f"  S = {s}", pnl(bare, s), pnl(donly, s), pnl(full, s), f="{:>13.2f}")
show("Taylor at 90: gamma_P x 10^2 / 2", 0.5 * gP[1] * 100.0, f="{:>13.2f}")
for lab, kw in (("vol 20% -> 25%", dict(sig=0.25)), ("S 100 -> 95, vol -> 21%", dict(S=95.0, sig=0.21)),
                ("S 100 -> 90, vol -> 25%", dict(S=90.0, sig=0.25))):
    show(lab, pnl(bare, **kw), pnl(donly, **kw), pnl(full, **kw), f="{:>13.2f}")
rnd = [(NBOOK, BOOK), (2700.0, A), (6000.0, B), (4183.0, "share")]
def g_of(pos, S=S0, dt=0.0):                                    # a book's Greeks: position-weighted sums
    tot = [0.0, 0.0, 0.0]
    for n, leg in pos:
        g = (1.0, 0.0, 0.0) if leg == "share" else greeks(leg[0], leg[1], leg[2] - dt, S)
        tot = [t + n * x for t, x in zip(tot, g)]
    return tot
show("rounded 27, 60 lots, 4183 sh", *g_of(rnd), f="{:>13.2f}")
show("stale: S moves to 110", *g_of(full, 110.0), f="{:>13.2f}")
show("stale: one month passes", *g_of(full, dt=1 / 12), f="{:>13.2f}")
same = abs(det(gA, greeks("call", 110.0, 0.25)))
show("wrong: A and a 3m K110 call, D", same, f="{:>13.8f}")
show("wrong: options added, old shares", *(round(x, 2) + 0.0 for x in g_of([(NBOOK, BOOK), (na, A), (nb, B), (-gP[0], "share")])), f="{:>13.2f}")
flip = [(NBOOK, BOOK), (-na, A), (-nb, B), (-(gP[0] - na * gA[0] - nb * gB[0]), "share")]
show("wrong: sold A, B; P&L 90, 110", pnl(flip, 90.0), pnl(flip, 110.0), f="{:>13.2f}")
mix = cramer(gP, gA, (gB[0], gB[1], gB[2] * 100.0))
show("wrong: B vega per unit, Greeks", *g_of([(NBOOK, BOOK), (mix[0], A), (mix[1], B), (mix[2], "share")]), f="{:>13.2f}")
C = greeks("call", 100.0, 0.25); show("try: 3m call for A: nA nB nS", *cramer(gP, C, gB)[:3], f="{:>13.2f}")
g6 = greeks("call", 105.0, 0.5); show("try: 6m K105 vega/gamma", g6[2] / g6[1])
show("try: B = 6m call K105: nA nB nS", *cramer(gP, gA, greeks("call", 105.0, 0.5))[:3], f="{:>13.2f}")

assert abs(price(*BOOK) - 9.227005508154) < 1e-9, "house call price"
assert max(abs(na - na2), abs(nb - nb2), abs(ns - ns2)) < 0.01, "Cramer (analytic) vs Gauss (bumped)"
assert abs(rev[0]) < 1e-3 and abs(rev[1]) < 1e-3, "revalued hedged book has no delta and no gamma"
assert abs(rev[2]) < 1e-3, "revalued hedged book has no vega"
assert abs(gA[2] / gA[1] - S0 * S0 * SIG * A[2] / 100.0) < 1e-9, "vega/gamma = S^2 sigma T / 100"
assert abs(pnl(full, 98.0)) < 0.01 * abs(pnl(donly, 98.0)), "gamma hedged: a $2 drop costs under 1% of delta-only"
assert abs(pnl(full, sig=0.21)) < 0.01 * abs(pnl(donly, sig=0.21)), "vega hedged: one vol point"
assert abs(same) < 1e-12, "same expiry: determinant vanishes"
print("ALL CHECKS PASS")
