# Option-adjusted spread -- the check behind the card.  Standard library only; the tree, root finder
# and random numbers are written out.  30-year pool, 6% coupon, 8% a year prepaid plus more when rates fall.
from math import exp, log

N, C, BASE, SLOPE, KNEE = 30, 0.06, 0.08, 14.0, 0.05    # years, coupon, prepayment rule
SIG, PRICE = 0.22, 103.06                               # rate volatility, market price per $100

def zero(t): return 0.035 + 0.0005 * t                  # the curve: zero rate for t years, continuous
D = [exp(-zero(t) * t) for t in range(N + 1)]           # discount factors D(t)
FWD = [log(D[i] / D[i + 1]) for i in range(N)]          # one-year forward rates
def sched(i): return C / ((1 + C) ** (N - i) - 1)       # scheduled principal per $1 of balance, year i+1
def prepay(r): return BASE + SLOPE * max(0.0, KNEE - r) # share of the rest repaid early this year

def bisect(f, target, lo=-0.05, hi=0.30):               # f falls as its input rises
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if f(mid) > target: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def calibrate(sig, fitted=True):
    # Tree of one-year rates r(i,j) = a_i e^{sig(2j-i)}; each a_i found so the tree reprices D(i+1).
    rates, q = [], [1.0]                                 # q[j]: today's price of $1 paid only at node (i,j)
    for i in range(N):
        zc = lambda a: sum(q[j] * exp(-a * exp(sig * (2 * j - i))) for j in range(i + 1))
        a = bisect(zc, D[i + 1]) if fitted else zero(1)
        row = [a * exp(sig * (2 * j - i)) for j in range(i + 1)]
        nq = [0.0] * (i + 2)
        for j in range(i + 1):
            nq[j] += 0.5 * q[j] * exp(-row[j]); nq[j + 1] += 0.5 * q[j] * exp(-row[j])
        rates.append(row); q = nq
    return rates

def tree_price(rates, s, spread_moves_prepay=False, slope=SLOPE):
    # Road 1: walk back through the tree.  Value per $1 of balance still outstanding at each node.
    v = [0.0] * (N + 1)
    for i in range(N - 1, -1, -1):
        g, nv = sched(i), []
        for j in range(i + 1):
            r = rates[i][j]
            p = BASE + slope * max(0.0, KNEE - (r + s if spread_moves_prepay else r))
            nv.append(exp(-(r + s)) * (C + g + p * (1 - g) + (1 - g) * (1 - p) * 0.5 * (v[j] + v[j + 1])))
        v = nv
    return 100 * v[0]

def static_flows(slope=SLOPE):
    # The z-spread's cash flows: one path, rates sitting on the forwards.
    bal, flows = 100.0, []
    for i in range(N):
        g, p = sched(i), BASE + slope * max(0.0, KNEE - FWD[i])
        flows.append(bal * (C + g + p * (1 - g))); bal *= (1 - g) * (1 - p)
    return flows
def static_price(flows, z): return sum(f * D[t + 1] * exp(-z * (t + 1)) for t, f in enumerate(flows))

def mc_weights(rates, paths, seed=20260928):
    # Road 2: simulate paths through the same rates, forward in time, tracking the balance.
    # Returns w[t] = average over paths of (cash flow at t+1) x (path discount to t+1).
    x, w, M = seed, [0.0] * N, (1 << 64) - 1
    for _ in range(paths // 2):
        coins = []
        for i in range(N):
            x = (x * 6364136223846793005 + 1442695040888963407) & M
            coins.append(x >> 63)                        # top bit: 1 = rates step up
        for flip in (0, 1):                              # each path and its mirror image
            j, bal, disc = 0, 100.0, 1.0
            for i in range(N):
                r, g = rates[i][j], sched(i)
                p = prepay(r)
                disc *= exp(-r)
                w[i] += bal * (C + g + p * (1 - g)) * disc
                bal *= (1 - g) * (1 - p)
                j += coins[i] ^ flip
    return [wi / paths for wi in w]
def mc_price(w, s): return sum(wi * exp(-s * (t + 1)) for t, wi in enumerate(w))

flat, tree = calibrate(0.0), calibrate(SIG)
flows = static_flows()
z_static = bisect(lambda z: static_price(flows, z), PRICE)
z_tree0 = bisect(lambda s: tree_price(flat, s), PRICE)
oas = bisect(lambda s: tree_price(tree, s), PRICE)
w, w_few = mc_weights(tree, 20000), mc_weights(tree, 20)
oas_mc = bisect(lambda s: mc_price(w, s), PRICE)
oas_few = bisect(lambda s: mc_price(w_few, s), PRICE)
opt_dollars = static_price(flows, oas) - PRICE
flows0 = static_flows(0.0)
z_noopt = bisect(lambda z: static_price(flows0, z), PRICE)
oas_noopt = bisect(lambda s: tree_price(tree, s, slope=0.0), PRICE)
oas_wrong_prepay = bisect(lambda s: tree_price(tree, s, True), PRICE)
oas_unfitted = bisect(lambda s: tree_price(calibrate(SIG, False), s), PRICE)

r0, g0, p0 = tree[0][0], sched(0), prepay(tree[0][0])
flow1 = 100 * (C + g0 + p0 * (1 - g0))
pw = [1.0]                                              # chance of each year-16 node: coin flips
for _ in range(15): pw = [0.5 * ((pw[j] if j < len(pw) else 0.0) + (pw[j - 1] if j > 0 else 0.0)) for j in range(len(pw) + 1)]
rows = [
    ("zero rate 1y / 10y / 30y (%)", f"{100*zero(1):.2f} {100*zero(10):.2f} {100*zero(30):.2f}"),
    ("year 1: short rate r0 (%)", f"{100*r0:.4f}"),
    ("year 1: prepayment rate (%)", f"{100*p0:.4f}"),
    ("year 1: scheduled principal ($)", f"{100*g0:.4f}"),
    ("year 1: prepaid ($)", f"{100*p0*(1-g0):.4f}"),
    ("year 1: cash flow ($)", f"{flow1:.4f}"),
    ("year 1: D(1), e^-z, flow x both ($)", f"{D[1]:.6f} {exp(-z_static):.6f} {flow1*D[1]*exp(-z_static):.4f}"),
    ("year 2 up / down rate (%)", f"{100*tree[1][1]:.4f} {100*tree[1][0]:.4f}"),
    ("year 2 up / down prepay (%)", f"{100*prepay(tree[1][1]):.4f} {100*prepay(tree[1][0]):.4f}"),
    ("year 16 forward rate (%)", f"{100*FWD[15]:.4f}"),
    ("year 16 prepay at the forward (%)", f"{100*prepay(FWD[15]):.4f}"),
    ("year 16 prepay, tree average (%)", f"{100*sum(pw[j]*prepay(tree[15][j]) for j in range(16)):.4f}"),
    ("static price at spread 0 ($)", f"{static_price(flows, 0.0):.4f}"),
    ("tree price at spread 0 ($)", f"{tree_price(tree, 0.0):.4f}"),
    ("z-spread, static flows (bp)", f"{1e4*z_static:.4f}"),
    ("z-spread, tree at vol 0 (bp)", f"{1e4*z_tree0:.4f}"),
    ("OAS, tree (bp)", f"{1e4*oas:.4f}"),
    ("OAS, 20000 simulated paths (bp)", f"{1e4*oas_mc:.4f}"),
    ("option cost z - OAS (bp)", f"{1e4*(z_static-oas):.4f}"),
    ("option cost in price ($)", f"{opt_dollars:.4f}"),
    ("no option: z-spread (bp)", f"{1e4*z_noopt:.4f}"),
    ("no option: OAS on tree (bp)", f"{1e4*oas_noopt:.4f}"),
    ("wrong: spread moves prepayment (bp)", f"{1e4*oas_wrong_prepay:.4f}"),
    ("wrong: tree not fitted to curve (bp)", f"{1e4*oas_unfitted:.4f}"),
    ("wrong: only 20 paths (bp)", f"{1e4*oas_few:.4f}"),
]
for name, v in rows: print(f"{name:<37} {v}")
print()
spreads = [40 + 10 * k for k in range(11)]
print("chart, spread (bp)  " + " ".join(f"{b:6d}" for b in spreads))
print("chart, static ($)   " + " ".join(f"{static_price(flows, b/1e4):6.2f}" for b in spreads))
print("chart, tree ($)     " + " ".join(f"{tree_price(tree, b/1e4):6.2f}" for b in spreads))
vols = [0.05 * k for k in range(7)]
print("chart, vol (%)      " + " ".join(f"{100*v:6.0f}" for v in vols))
print("chart, OAS (bp)     " + " ".join(f"{1e4*bisect(lambda s: tree_price(calibrate(v), s), PRICE):6.2f}" for v in vols))

assert max(abs(FWD[i] - flat[i][0]) for i in range(N)) < 1e-12, "vol-0 tree must sit on the forwards"
assert abs(z_tree0 - z_static) < 1e-10, "z-spread two ways: tree at vol 0 vs static sum"
assert abs(oas_noopt - z_noopt) < 1e-10, "no option: OAS on the tree must equal the z-spread"
assert abs(oas_mc - oas) < 2e-4, "simulated OAS within 2 bp of the tree"
assert 0.0 < oas < z_static, "the borrower's option must cost the investor spread"
bal, level = 100.0, 100 * C / (1 - (1 + C) ** -N)          # no prepayment: a level annuity payment
for i in range(N): assert abs(bal * (C + sched(i)) - level) < 1e-9, "scheduled payment must be level"; bal *= 1 - sched(i)
assert abs(bal) < 1e-9, "no prepayment: the balance must be paid off in exactly 30 years"
print("ALL CHECKS PASS")
