# Adjoint differentiation -- the check behind the card.  Standard library only.
# Nothing imported that already knows a derivative.  A tape records every
# elementary step of the price; one backward sweep over it hands back the whole
# gradient.  Four roads: the sweep, forms differentiated by hand, central
# differences, forward mode.  Two identities and the wrong ways are printed too.
from math import log, sqrt, exp, erf, pi

INP, ADD, SUB, MUL, DIV, LN, EXP, SQRT, NCDF, SCALE = range(10)

def ncdf(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def npdf(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # the curve's height at x

def evaluate(tape, xs):            # forward pass: every value, and every edge's local slope
    v, sl = [], []
    for op, i, j, c in tape:
        if   op == INP:  v.append(xs[i]);       sl.append([])
        elif op == ADD:  v.append(v[i] + v[j]); sl.append([(i, 1.0), (j, 1.0)])
        elif op == SUB:  v.append(v[i] - v[j]); sl.append([(i, 1.0), (j, -1.0)])
        elif op == MUL:  v.append(v[i] * v[j]); sl.append([(i, v[j]), (j, v[i])])
        elif op == DIV:  v.append(v[i] / v[j]); sl.append([(i, 1.0 / v[j]), (j, -v[i] / (v[j] * v[j]))])
        elif op == LN:   v.append(log(v[i]));   sl.append([(i, 1.0 / v[i])])
        elif op == EXP:  v.append(exp(v[i]));   sl.append([(i, exp(v[i]))])
        elif op == SQRT: v.append(sqrt(v[i]));  sl.append([(i, 0.5 / sqrt(v[i]))])
        elif op == NCDF: v.append(ncdf(v[i]));  sl.append([(i, npdf(v[i]))])
        else:            v.append(c * v[i]);    sl.append([(i, c)])
    return v, sl
def sweep(tape, sl, add=True, back=True):     # the backward sweep: every node's adjoint,
    a = [0.0] * len(tape)                     # and the inputs are nodes 0, 1, 2, ... in order
    a[len(tape) - 1] = 1.0                    # seed: the answer's derivative with itself
    for k in (range(len(tape) - 1, -1, -1) if back else range(len(tape))):
        for p, s in sl[k]:
            if add: a[p] += a[k] * s          # a reused value collects every contribution
            else:   a[p] = a[k] * s           # the overwrite bug, for the card's table
    return a

def tangent(tape, sl, seed):       # forward mode: one pass carries one input's derivative
    t = [0.0] * len(tape)
    for k, (op, i, j, c) in enumerate(tape):
        t[k] = (1.0 if i == seed else 0.0) if op == INP else sum(s * t[p] for p, s in sl[k])
    return t[len(tape) - 1]
def counts(tape, sl): return sum(1 for n in tape if n[0] != INP), sum(len(e) for e in sl)

TOY = [(INP, 0, 0, 0.0), (INP, 1, 0, 0.0), (INP, 2, 0, 0.0), (INP, 3, 0, 0.0),  # S, r, q, T
       (SUB, 1, 2, 0.0), (MUL, 4, 3, 0.0),        # n4, n5 = r - q, then (r-q)T
       (EXP, 5, 0, 0.0), (MUL, 0, 6, 0.0)]        # n6, n7 = e^((r-q)T), then F = S times it
BS = [(INP, 0, 0, 0.0), (INP, 1, 0, 0.0), (INP, 2, 0, 0.0),      # n0..n2 = S, K, r
      (INP, 3, 0, 0.0), (INP, 4, 0, 0.0), (INP, 5, 0, 0.0),      # n3..n5 = q, sigma, T
      (SQRT, 5, 0, 0.0), (MUL, 4, 6, 0.0),        # n6, n7 = sqrt(T), one wiggle unit
      (DIV, 0, 1, 0.0), (LN, 8, 0, 0.0),          # n8, n9 = S/K, then ln(S/K)
      (SUB, 2, 3, 0.0),                           # n10 = r - q
      (MUL, 4, 4, 0.0), (SCALE, 11, 0, 0.5),      # n11, n12 = sigma*sigma, then half of it
      (ADD, 10, 12, 0.0), (MUL, 13, 5, 0.0),      # n13, n14 = the drift, then times T
      (ADD, 9, 14, 0.0), (DIV, 15, 7, 0.0),       # n15, n16 = d1's top, then d1
      (SUB, 16, 7, 0.0),                          # n17 = d2
      (NCDF, 16, 0, 0.0), (NCDF, 17, 0, 0.0),     # n18, n19 = N(d1), N(d2)
      (MUL, 3, 5, 0.0), (SCALE, 20, 0, -1.0), (EXP, 21, 0, 0.0),   # n20..n22 = e^-qT
      (MUL, 2, 5, 0.0), (SCALE, 23, 0, -1.0), (EXP, 24, 0, 0.0),   # n23..n25 = e^-rT
      (MUL, 0, 22, 0.0), (MUL, 26, 18, 0.0),      # n26, n27 = S e^-qT, then the share leg
      (MUL, 1, 25, 0.0), (MUL, 28, 19, 0.0),      # n28, n29 = K e^-rT, then the cash leg
      (SCALE, 29, 0, -1.0), (ADD, 27, 30, 0.0)]   # n30, n31 = minus the cash leg, the price
def closed(S, K, r, q, sg, T):     # the same six derivatives, differentiated by hand
    v = sg * sqrt(T); d1 = (log(S / K) + (r - q + 0.5 * sg * sg) * T) / v; d2 = d1 - v
    return [exp(-q * T) * ncdf(d1), -exp(-r * T) * ncdf(d2),
            K * T * exp(-r * T) * ncdf(d2), -S * T * exp(-q * T) * ncdf(d1),
            S * exp(-q * T) * npdf(d1) * sqrt(T),
            S * exp(-q * T) * npdf(d1) * sg / (2.0 * sqrt(T))
            - q * S * exp(-q * T) * ncdf(d1) + r * K * exp(-r * T) * ncdf(d2)]

NAMES, X = ("S", "K", "r", "q", "sigma", "T"), [100.0, 100.0, 0.05, 0.02, 0.20, 1.0]
def price(xs): return evaluate(BS, xs)[0][len(BS) - 1]
def grad(xs, add=True, back=True): return sweep(BS, evaluate(BS, xs)[1], add, back)
def bumped(k, h):
    up, dn = list(X), list(X); up[k] += h; dn[k] -= h
    return (price(up) - price(dn)) / (2.0 * h)
def row(lab, *xs): print(f"  {lab:<48}" + "".join(f"{x:>13.6f}" for x in xs))
ty = [100.0, 0.05, 0.02, 1.0]                       # the toy graph on the same market
tv, tsl = evaluate(TOY, ty)
tg, (tops, tedges) = sweep(TOY, tsl), counts(TOY, tsl)
gr = exp((ty[1] - ty[2]) * ty[3])
tcl = [gr, ty[0] * ty[3] * gr, -ty[0] * ty[3] * gr, ty[0] * (ty[1] - ty[2]) * gr]
print(f"the toy graph: forward price F = S e^((r-q)T), {tops} operations, {tedges} edges")
row("F, forward pass through the tape", tv[len(TOY) - 1])
for nm, a, b in zip(("dF/dS", "dF/dr", "dF/dq", "dF/dT"), tg, tcl):
    print(f"  {nm} by sweep {a:>14.6f}    the same by hand {b:>14.6f}")

v, sl = evaluate(BS, X)
ops, edges = counts(BS, sl)
C, g, cl = v[len(BS) - 1], sweep(BS, sl), closed(*X)   # g[0..5] are the six Greeks
bp, fm = [bumped(k, 1.0e-4) for k in range(6)], [tangent(BS, sl, k) for k in range(6)]
print(f"\nthe Black-Scholes tape: 6 inputs, {ops} operations, {edges} edges")
print(f"  d1 {v[16]:.6f}   d2 {v[17]:.6f}   N(d1) {v[18]:.6f}   N(d2) {v[19]:.6f}")
row("call price, forward pass, then the house number", C, 9.227005508154)
print("\nfive Greeks and the strike sensitivity, from ONE backward sweep")
print(f"  {'input':<7}{'sweep':>13}{'by hand':>14}{'bumped':>13}{'forward mode':>14}")
for nm, a, b, c2, d in zip(NAMES, g, cl, bp, fm):
    print(f"  {nm:<7}{a:>13.6f}{b:>14.6f}{c2:>13.6f}{d:>14.6f}")
print("\nthe same five, named and scaled the way a desk quotes them")
for lab, val in (("delta, per $1 on Acme", g[0]), ("vega, per volatility point", g[4] / 100.0),
                 ("rho, per basis point on r", g[2] / 10000.0), ("psi, per basis point on q", g[3] / 10000.0),
                 ("theta, per calendar day", -g[5] / 365.0)):
    row(lab, val)

gam = (grad([X[0] + 0.01] + X[1:])[0] - grad([X[0] - 0.01] + X[1:])[0]) / 0.02
gcl = exp(-X[3] * X[5]) * npdf(v[16]) / (X[0] * X[4] * sqrt(X[5]))
pde = -g[5] + (X[2] - X[3]) * X[0] * g[0] + 0.5 * X[4] * X[4] * X[0] * X[0] * gam - X[2] * C
print("\nadjoints picked out of the sweep, on the way to the Greeks")
print(f"  adj N(d1) {g[18]:>12.6f}   adj N(d2) {g[19]:>12.6f}"
      f"   phi(d1) {npdf(v[16]):>10.6f}   phi(d2) {npdf(v[17]):>10.6f}")
print(f"  adj d1 {g[16]:>15.6f}   adj d2 {g[17]:>12.6f}   adj one wiggle unit {g[7]:>12.6f}")
print("\nfirst derivatives only: gamma costs a second pass")
row("gamma, two sweeps a bump apart, then its formula", gam, gcl)
row("size of the Black-Scholes equation residual", abs(pde))
row("S dC/dS + K dC/dK, then the price itself", X[0] * g[0] + X[1] * g[1], C)

print("\ncost, counted in forward passes through the tape")
print(f"  {'forward pass, operations':<48}{ops:>13d}")
print(f"  {'backward sweep, multiply-and-adds':<48}{edges:>13d}")
row("the sweep alone", edges / ops)
row("price and all six derivatives, adjoint", 1.0 + edges / ops)
row("price and all six by central differences", 13.0)
print("chart, sensitivities asked for " + "".join(f"{k:>6d}" for k in (1, 2, 3, 4, 5, 6)))
print("chart, central differences     " + "".join(f"{2.0 * k + 1.0:>6.2f}" for k in (1, 2, 3, 4, 5, 6)))
print("chart, adjoint, one sweep      " + "".join(f"{1.0 + edges / ops:>6.2f}" for _ in range(6)))

print("\nwhat breaks")
row("overwrite instead of add: dC/dsigma, then right", grad(X, add=False)[4], g[4])
row("swept forward, not in reverse: dC/dS, then right", grad(X, back=False)[0], g[0])
row("theta taken as +dC/dT per year, then right", g[5], -g[5])
row("delta from a $10 bump, then right", bumped(0, 10.0), g[0])

assert abs(C - 9.227005508154) < 1e-9,                    "tape price vs the house number"
assert max(abs(a - b) for a, b in zip(g, cl)) < 1e-9,     "sweep vs the hand-differentiated forms"
assert max(abs(a - b) for a, b in zip(g, bp)) < 1e-5,     "sweep vs central differences"
assert max(abs(a - b) for a, b in zip(g, fm)) < 1e-12,    "sweep vs forward mode"
assert abs(X[0] * g[0] + X[1] * g[1] - C) < 1e-9,         "S dC/dS + K dC/dK must be the price"
assert abs(gam - gcl) < 1e-7 and abs(pde) < 1e-6,         "gamma, and the Black-Scholes equation"
assert max(abs(a - b) for a, b in zip(tg, tcl)) < 1e-12,  "toy sweep vs its hand-made forms"
assert (ops, edges) == (26, 42),                          "the tape this card describes"
print("ALL CHECKS PASS")
