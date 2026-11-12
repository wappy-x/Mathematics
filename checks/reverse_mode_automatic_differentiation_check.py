# Reverse mode -- the check behind the card.  Standard library only.
# A bond book priced off a forward-rate curve with 50 nodes, one every 0.6 years
# out to 30 years (illustrative).  Four bonds, 60 half-year periods.  The tape is
# built by operator overloading as the pricing loop runs.  Roads: one reverse
# sweep; 50 forward-mode runs with dual numbers; a closed form; 100 bumped prices.
import math
NODES, STEPS, C = 50, 60, 8
F0 = [0.03 + 0.015 * (1 - math.exp(-0.6 * k / 6)) for k in range(1, NODES + 1)]
CPN, MAT = (4.0, 3.5, 3.0, 4.5), (60, 20, 10, 40)        # % a year; maturity in half-years
HOLD = (500000.0, 300000.0, -400000.0, 200000.0)         # units of $100 face; negative = short
def flows(m): return [c / 2 + (100.0 if m == n else 0.0) if m <= n else 0.0 for c, n in zip(CPN, MAT)]
def weights(m):            # midpoint of period m, (2m-1)/4 years, read off the node grid
    k, r = divmod(5 * (2 * m - 1), 12)
    return ((0, 1.0),) if k == 0 else ((k - 1, 1 - r / 12), (k, r / 12))   # flat before node 1
TAPE = []                  # one entry per value: its (parent, local slope) pairs
class V:
    def __init__(s, v, parents=()): s.v, s.i = v, len(TAPE); TAPE.append(parents)
    def __add__(a, b): return V(a.v + b.v, ((a.i, 1.0), (b.i, 1.0)))
    def __mul__(a, b): return V(a.v * b.v, ((a.i, b.v), (b.i, a.v))) if isinstance(b, V) else V(a.v * b, ((a.i, b),))
def vexp(a): e = math.exp(a.v); return V(e, ((a.i, e),))
class Du:                  # dual number a + b eps, eps^2 = 0
    def __init__(s, a, b=0.0): s.a, s.b = a, b
    def __add__(x, y): return Du(x.a + y.a, x.b + y.b)
    def __mul__(x, y): return Du(x.a * y.a, x.a * y.b + x.b * y.a) if isinstance(y, Du) else Du(x.a * y, x.b * y)
def dexp(x): e = math.exp(x.a); return Du(e, e * x.b)
def run(F, ex, D, vals, m0=1, m1=STEPS):   # the pricer: one loop, one branch, no derivative code
    for m in range(m0, m1 + 1):
        f = None
        for j, w in weights(m):
            f = F[j] * w if f is None else f + F[j] * w
        D = D * ex(f * -0.5)
        vals = [v + D * c if c else v for v, c in zip(vals, flows(m))]
    return D, vals
def sweep(seed, order=-1):  # seed: {tape index: adjoint}; order=+1 is the mistake
    bar = [0.0] * len(TAPE)
    for i, s in seed.items(): bar[i] += s
    for i in (range(len(TAPE) - 1, -1, -1) if order < 0 else range(len(TAPE))):
        for p, d in TAPE[i]: bar[p] += bar[i] * d
    return bar
def tot(xs):               # plain left-to-right sum (Python's sum() compensates)
    t = 0.0
    for x in xs: t += x
    return t
def sci(v): m, e = f"{v:.1e}".split("e"); return f"{m}e{int(e)}"
def price(F): return tot(q * v for q, v in zip(HOLD, run(F, math.exp, 1.0, [0.0] * 4)[1]))
def dv(g): return " ".join(f"{x * 1e-4:9.2f}" for x in g)
# 1 reverse mode: record once, sweep once, seeded with the holdings vector q
TAPE.clear(); Fv = [V(x) for x in F0]; D0 = V(1.0); z = [V(0.0) for _ in range(4)]
P = run(Fv, vexp, D0, z)[1]
L = sum(1 for e in TAPE if e); E = sum(len(e) for e in TAPE); size = len(TAPE)
bar = sweep({p.i: q for p, q in zip(P, HOLD)}); g_rev = [bar[x.i] for x in Fv]
rows = [[sweep({P[b].i: 1.0})[x.i] for x in Fv] for b in range(4)]
g_ones = [sweep({p.i: 1.0 for p in P})[x.i] for x in Fv]
g_fwd_order = [sweep({p.i: q for p, q in zip(P, HOLD)}, +1)[x.i] for x in Fv]
print("bond prices per $100: " + " ".join(f"{p.v:.6f}" for p in P))
print(f"book value ${price(F0):.2f}; nodes F1 {F0[0]:.6f}, F49 {F0[48]:.6f}, F50 {F0[49]:.6f}")
print(f"tape: {size} entries ({NODES + 5} inputs), {L} operations, {E} edges")
print("key-rate DV01, $ per bp, nodes 1..50 (10 a line):")
for r in range(5): print(dv(g_rev[10 * r:10 * r + 10]))
# 2 forward mode: 50 runs, each seeded on one node; each run gives a Jacobian column
cols = []
for k in range(NODES):
    Fd = [Du(x, 1.0 if j == k else 0.0) for j, x in enumerate(F0)]
    cols.append([v.b for v in run(Fd, dexp, Du(1.0), [Du(0.0)] * 4)[1]])
g_fwd = [tot(q * c for q, c in zip(HOLD, col)) for col in cols]
# 3 closed form: dD_m/dF_j = -0.5 D_m (sum over periods i <= m of weight on node j)
g_cf, acc, D = [0.0] * NODES, [0.0] * NODES, 1.0
for m in range(1, STEPS + 1):
    for j, w in weights(m): acc[j] += w
    D *= math.exp(-0.5 * tot(F0[j] * w for j, w in weights(m)))
    cash = tot(q * c for q, c in zip(HOLD, flows(m)))
    for j in range(NODES): g_cf[j] += -0.5 * D * acc[j] * cash
# 4 bump and revalue, central, h = 1e-6 per node: 100 extra pricings
def bumped(h): return [(price([x + h * (j == k) for j, x in enumerate(F0)])
                         - price([x - h * (j == k) for j, x in enumerate(F0)])) / (2 * h) for k in range(NODES)]
g_bump = bumped(1e-6)
def gap(a, b): return max(abs(x - y) for x, y in zip(a, b)) / max(abs(y) for y in b)
print(f"largest gap / largest DV01: forward mode {sci(gap(g_fwd, g_rev))}, closed form {sci(gap(g_cf, g_rev))}, "
      f"bump {sci(gap(g_bump, g_rev))}")
vjp = [tot(q * r[j] for q, r in zip(HOLD, rows)) for j in range(NODES)]
print(f"q^T J from 4 row sweeps vs 1 seeded sweep: gap {sci(gap(vjp, g_rev))}")
print(f"30-year bond row, node 50: reverse {rows[0][49] * 1e-4:.6f}, forward column {cols[49][0] * 1e-4:.6f} per $100 per bp")
# house example: the whole curve up 1 bp, by repricing, against the sum of 50 sensitivities
up, dn = price([x + 1e-4 for x in F0]), price([x - 1e-4 for x in F0])
par = up - price(F0); s = tot(g_rev) * 1e-4; cvx = (up + dn - 2 * price(F0)) / 2
print(f"parallel +1bp: repriced change {par:.2f}, sum of 50 DV01s {s:.2f}, gap {par - s:.2f}, convexity term {cvx:.2f}")
# by hand: node 50 enters only period 60, weight 7/12; only the 30-year bond pays then (102)
D59 = run(F0, math.exp, 1.0, [0.0] * 4, 1, 59)[0]; f60 = 5 / 12 * F0[48] + 7 / 12 * F0[49]
e60 = math.exp(-0.5 * f60); Db = HOLD[0] * 102.0; gb = e60 * D59 * Db; Fb = 7 / 12 * -0.5 * gb
print(f"hand, period 60: f {f60:.6f}, e {e60:.6f}, D59 {D59:.6f}, D60 {D59 * e60:.6f}, Dbar {Db:.0f}, "
      f"gbar {gb:.2f}, fbar {-0.5 * gb:.2f}, F50bar {Fb:.2f}, DV01 {Fb * 1e-4:.2f}, D59bar from here {e60 * Db:.2f}")
# checkpointing: keep the 5-number state every C steps, re-record one segment at a time
def checkpointed(c, keep_D=True):
    cps, st = [], (1.0, [0.0] * 4)
    for m0 in range(1, STEPS + 1, c):
        cps.append((m0, st)); st = run(F0, math.exp, st[0], st[1], m0, min(m0 + c - 1, STEPS))
    gF, dbar, vbar, peak = [0.0] * NODES, 0.0, list(HOLD), 0
    for m0, (d, vs) in reversed(cps):
        TAPE.clear(); Fs = [V(x) for x in F0]; Ds = V(d); Vs = [V(x) for x in vs]
        D1, V1 = run(Fs, vexp, Ds, Vs, m0, min(m0 + c - 1, STEPS)); peak = max(peak, len(TAPE))
        seed = {p.i: q for p, q in zip(V1, vbar)}; seed[D1.i] = seed.get(D1.i, 0.0) + dbar
        b = sweep(seed); gF = [x + b[y.i] for x, y in zip(gF, Fs)]
        dbar, vbar = (b[Ds.i] if keep_D else 0.0), [b[y.i] for y in Vs]
    return gF, len(cps), peak
for c in (60, 15, C, 4, 1):
    gc, ncp, peak = checkpointed(c)
    print(f"checkpoint every {c:2d} steps: {ncp:2d} stored states, peak tape {peak:4d} entries, gap {sci(gap(gc, g_rev))}")
g_drop, g_drop1 = checkpointed(C, False)[0], checkpointed(1, False)[0]
print(f"cost in pricings: record + 1 sweep {(L + 2 * E) / L:.2f}, record + 4 sweeps {(L + 8 * E) / L:.2f}, "
      f"forward mode {NODES * (L + 2 * E) / L:.1f}, bumps {2 * NODES + 1}; edges per operation {E / L:.2f}")
g_tiny = bumped(1e-12)
print(f"wrong: seed 1 on every bond: {tot(g_ones) * 1e-4:.2f}; sweep in recording order: {tot(g_fwd_order) * 1e-4:.2f}; "
      f"drop D-bar at checkpoints: {tot(g_drop) * 1e-4:.2f}; at every step: {tot(g_drop1) * 1e-4:.2f}")
print(f"trap: per unit rate {tot(g_rev):.2f}; bump h = 1e-12, total {tot(g_tiny) * 1e-4:.2f}, worst gap {sci(gap(g_tiny, g_rev))}")
assert gap(g_cf, g_rev) < 1e-12, "closed form"
assert gap(g_fwd, g_rev) < 1e-12, "forward mode"
assert gap(g_bump, g_rev) < 1e-6, "bump and revalue"
assert gap(vjp, g_rev) < 1e-12, "one seeded sweep = q^T J"
assert abs(par - s - cvx) < 0.01 * abs(cvx), "parallel bp: first order plus convexity"
assert abs(Fb - g_rev[49]) < 1e-9 * abs(Fb), "hand sweep for node 50"
assert gap(checkpointed(C)[0], g_rev) < 1e-12, "checkpointed sweep"
assert gap(g_drop, g_rev) > 0.01, "the state's adjoint must cross segment boundaries"
print("ALL CHECKS PASS")
