# Structured rate notes priced by their parts: range accrual, inverse floater, target redemption note.
# Python standard library only. Normal CDF, integrator and random numbers are written here.
from math import exp, log, sqrt, pi, cos

def N(x):                                   # normal CDF: series near 0, continued fraction in the tails
    if abs(x) <= 3.0:
        term, total, k = x, x, 0
        while abs(term) > 1e-17:
            k += 1
            term *= -x * x / (2 * k)
            total += term / (2 * k + 1)
        return 0.5 + total / sqrt(2 * pi)
    y = f = abs(x)
    for k in range(150, 0, -1):
        f = y + k / f
    tail = exp(-y * y / 2) / sqrt(2 * pi) / f
    return 1.0 - tail if x > 0 else tail

def simpson(fn, lo, hi, m=2000):
    h = (hi - lo) / m
    return (fn(lo) + fn(hi) + sum((4 if i % 2 else 2) * fn(lo + i * h) for i in range(1, m))) * h / 3

M, c, a, b = 1000.0, 0.06, 0.04, 0.06       # face, coupon rate, band a <= L < b
F, sig, r, n = 0.05, 0.20, 0.05, 12         # forward rate, rate volatility, discount rate, monthly fixings
D1, D2, ts = exp(-r), exp(-2 * r), [(j + 1) / n for j in range(n)]   # discount factors, fixing times

def d(K, t, f=F, s=sig):                    # the cut-off: L(t) >= K exactly when a standard normal draw < d
    return (log(f / K) - 0.5 * s * s * t) / (s * sqrt(t))

def range_value(f=F, s=sig):                # road 1: long a digital at a, short a digital at b, each month
    return M * c * D1 * sum(N(d(a, t, f, s)) - N(d(b, t, f, s)) for t in ts) / n

def floorlet(K, f=F, s=sig):                # E[(K - L)+] for the fixing at year 1
    return K * N(-d(K, 1, f, s)) - f * N(-d(K, 1, f, s) - s)

def caplet(K, f=F, s=sig):                  # E[(L - K)+] for the fixing at year 1
    return f * N(d(K, 1, f, s) + s) - K * N(d(K, 1, f, s))

def g(L):                                   # inverse coupon rate: 10% - 2L, floored at 0, capped at 8%
    return min(0.08, max(0.0, 0.10 - 2 * L))

def inverse_value(f=F, s=sig):              # road 1: two floorlets at 5%, short two floorlets at 1%
    return M * D2 * 2 * (floorlet(0.05, f, s) - floorlet(0.01, f, s))

def pdf(y, t):                              # density of log L(t)
    v = sig * sqrt(t)
    return exp(-0.5 * ((y - log(F) + 0.5 * v * v) / v) ** 2) / (v * sqrt(2 * pi))

V_rng, V_inv = range_value(), inverse_value()
V_cap = M * D2 * (0.08 + 2 * caplet(0.05) - 2 * caplet(0.01))           # road 2: fixed 8% plus caplets
V_rng_int = M * c * D1 * sum(simpson(lambda y: pdf(y, t), log(a), log(b)) for t in ts) / n
V_inv_int = M * D2 * (0.08 * simpson(lambda y: pdf(y, 1), log(F) - 3, log(0.01))
                      + simpson(lambda y: (0.10 - 2 * exp(y)) * pdf(y, 1), log(0.01), log(0.05)))

st = 20260928                                # road 4: simulate rate paths with a hand-written generator
def rnd():
    global st
    st = (st * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((st >> 11) + 0.5) / 2 ** 53
paths, sr, sr2, sg, sg2 = 100000, 0.0, 0.0, 0.0, 0.0
for p in range(paths):
    w, hits = 0.0, 0
    for j in range(n):
        w += sqrt(1 / n) * sqrt(-2 * log(rnd())) * cos(2 * pi * rnd())
        L = F * exp(sig * w - 0.5 * sig * sig * ts[j])
        hits += a <= L < b
    vr, vg = M * c * D1 * hits / n, M * D2 * g(L)
    sr, sr2, sg, sg2 = sr + vr, sr2 + vr * vr, sg + vg, sg2 + vg * vg
mc_r, mc_g = sr / paths, sg / paths
se_r, se_g = sqrt((sr2 / paths - mc_r ** 2) / paths), sqrt((sg2 / paths - mc_g ** 2) / paths)

# target redemption note on a coin: raw coupon 30 when in band, target 50, face 1000, discount .98 a period
D, G, R = 0.98, 50, {1: 980.0, 2: 985.0}
def node(pre, earned, call):                 # backward road: value just before the coupon at date len(pre)
    i = len(pre)
    cpn = min(30 if pre[-1] else 0, G - earned)
    if earned + cpn == G or i == 3:
        return cpn + 1000.0
    alive = keep(pre, earned + cpn, call)
    return cpn + (min(R[i], alive) if call else alive)
def keep(pre, earned, call):                 # value of staying alive after this date's coupon
    return D * (node(pre + (1,), earned, call) + node(pre + (0,), earned, call)) / 2
def path_pv(bits, policy):                   # forward road: walk one coin path, call where the policy says
    earned, pv = 0, 0.0
    for i in (1, 2, 3):
        cpn = min(30 if bits[i - 1] else 0, G - earned)
        earned += cpn
        prin = 1000.0 if earned == G or i == 3 else (R[i] if bits[:i] in policy else 0.0)
        pv += D ** i * (cpn + prin)
        if prin:
            return pv
coins = [(x >> 2 & 1, x >> 1 & 1, x & 1) for x in range(8)]
tree_plain = D * (node((1,), 0, False) + node((0,), 0, False)) / 2
tree_call = D * (node((1,), 0, True) + node((0,), 0, True)) / 2
paths_plain = sum(path_pv(k, set()) for k in coins) / 8
spots = [(1,), (0,), (1, 0), (0, 1), (0, 0)]   # every place the issuer could call
paths_call = min(sum(path_pv(k, {spots[i] for i in range(5) if m >> i & 1}) for k in coins) / 8 for m in range(32))
cpn_pv = sum(path_pv(k, set()) - D ** (2 if k[:2] == (1, 1) else 3) * 1000 for k in coins) / 8

rows = [("range accrual: 6% on 1000 while 4% <= L < 6%", None),
        ("month 12: d(4%)", d(a, 1)), ("month 12: d(6%)", d(b, 1)), ("month 12: N(d(4%))", N(d(a, 1))),
        ("month 12: N(d(6%))", N(d(b, 1))), ("month 1: chance in band", N(d(a, ts[0])) - N(d(b, ts[0]))),
        ("average chance in band", V_rng / (M * c * D1)), ("month 12: chance in band", N(d(a, 1)) - N(d(b, 1))), ("discount D(1)", D1),
        ("long 12 digitals at 4%", M * c * D1 * sum(N(d(a, t)) for t in ts) / n),
        ("short 12 digitals at 6%", M * c * D1 * sum(N(d(b, t)) for t in ts) / n),
        ("1 digitals formula", V_rng), ("2 Simpson over the band", V_rng_int),
        ("3 simulation, 100000 paths", mc_r), ("  standard error", se_r),
        ("delta per 1bp of F", (range_value(F + 1e-4) - range_value(F - 1e-4)) / 2),
        ("vega per vol point", (range_value(F, 0.21) - range_value(F, 0.19)) / 2),
        ("wrong: valued at the forward", M * c * D1), ("wrong: every fixing at month 12", M * c * D1 * (N(d(a, 1)) - N(d(b, 1)))),
        ("inverse floater: 1000 x min(8%, max(0, 10% - 2L))", None), ("discount D(2)", D2),
        ("1 floorlet spread", V_inv), ("2 fixed 8% plus caplets", V_cap), ("3 Simpson over L", V_inv_int),
        ("4 simulation, 100000 paths", mc_g), ("  standard error", se_g),
        ("delta per 1bp of F", (inverse_value(F + 1e-4) - inverse_value(F - 1e-4)) / 2),
        ("vega per vol point", (inverse_value(F, 0.21) - inverse_value(F, 0.19)) / 2),
        ("wrong: valued at the forward", M * D2 * g(F)), ("target note on a coin: 30 in band, target 50", None),
        ("uncalled, backward tree", tree_plain), ("uncalled, 8 paths", paths_plain),
        ("  coupons alone", cpn_pv), ("  principal alone", paths_plain - cpn_pv),
        ("date 1 after a hit: stay alive", keep((1,), 30, True)), ("date 1 after a miss: stay alive", keep((0,), 0, True)),
        ("date 2 at 30 earned: stay alive", keep((1, 0), 30, True)), ("date 2 at 0 earned: stay alive", keep((0, 0), 0, True)),
        ("callable, backward tree", tree_call), ("callable, best of 32 policies", paths_call),
        ("  cost of the call right", tree_plain - tree_call),
        ("wrong: principal always at date 3", cpn_pv + 1000 * D ** 3),
        ("wrong: no target clip", 15 * (D + D ** 2 + D ** 3) + 1000 * D ** 3)]
for lab, v in rows:
    print(lab if v is None else f"{lab:<40}{v:>14.6f}")
print("chart, vol %:     " + " ".join(f"{5 * k:6d}" for k in range(1, 9)))
print("chart, range $:   " + " ".join(f"{range_value(F, 0.05 * k):6.2f}" for k in range(1, 9)))
print("chart, L %:       " + " ".join(f"{k / 2:5.1f}" for k in range(0, 21)))
print("chart, range %:   " + " ".join(f"{100 * c * (a <= k / 200 < b):5.1f}" for k in range(0, 21)))
print("chart, inverse %: " + " ".join(f"{100 * g(k / 200):5.1f}" for k in range(0, 21)))

assert abs(V_rng - V_rng_int) < 1e-8, "digital formula vs integral of the density"
assert abs(mc_r - V_rng) < 4 * se_r, "range accrual simulation within 4 standard errors"
assert abs(mc_g - V_inv) < 4 * se_g, "inverse floater simulation within 4 standard errors"
assert abs(V_inv - V_cap) < 1e-9, "floor spread vs fixed coupon plus caplets (parity)"
assert abs(V_inv - V_inv_int) < 1e-8, "floor spread vs integral of the payoff"
assert abs(tree_plain - paths_plain) < 1e-9, "backward tree vs 8 enumerated paths"
assert abs(tree_call - paths_call) < 1e-9, "backward tree vs brute-force search over call policies"
print("ALL CHECKS PASS")
