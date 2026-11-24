# Convertible bonds on a tree -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is a series written out
# here, and both trees are loops.  Money is per bond, face 100, converting into 1 share.
from math import exp, sqrt, log, pi, ceil
def N(x):                                   # bell-curve area left of x, built here:
    if abs(x) > 3.0:                        # far out, a continued fraction for the tail
        f = abs(x)
        for k in range(80, 0, -1): f = abs(x) + k / f
        tail = exp(-x * x / 2.0) / sqrt(2.0 * pi) / f; return tail if x < 0 else 1.0 - tail
    term, total, k = x, x, 0                # near the middle, the Taylor series
    while abs(term) > 1e-17:
        k += 1; term *= -x * x / 2.0 / k; total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2.0 * pi)
S0, F, c, T, r, q, sig, s = 100.0, 100.0, 2.0, 5, 0.05, 0.02, 0.20, 0.03
def floor_at(t):                            # straight bond: coupons and face at r + s
    return sum(c * exp(-(r + s) * (k - t)) for k in range(1, T + 1) if k > t + 1e-12) + F * exp(-(r + s) * (T - t))
def last_step(S, tau, rc, re):              # maturity payoff max(102, share), split:
    K = F + c                               # cash 102 below, share above; Black-Scholes
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * tau) / (sig * sqrt(tau)); d2 = d1 - sig * sqrt(tau)
    return K * exp(-rc * tau) * N(-d2), S * exp((r - q - re) * tau) * N(d1)
def tree(S, steps, american=True, call=None, put=None, mode="tf", smooth=True):
    # call = (price, first year, share trigger), put = (price, year), each also paying any coupon
    # due.  mode "tf": cash at r + s, shares at r ("risky", "safe": all at r + s, all at r).
    dt = T / steps
    u = exp(sig * sqrt(dt)); d = 1.0 / u; p = (exp((r - q) * dt) - d) / (u - d)
    dc = exp(-(r + s) * dt) if mode != "safe" else exp(-r * dt); de = exp(-r * dt) if mode != "risky" else dc
    per = steps // T                        # steps per year: coupon dates are nodes
    spot = [S * u ** j * d ** (steps - j) for j in range(steps + 1)]
    V, B, bad = [max(F + c, x) for x in spot], [F + c if F + c > x else 0.0 for x in spot], 0
    for i in range(steps - 1, -1, -1):
        t, spot = i * dt, [x / d for x in spot[:i + 1]]
        cpn = c if i % per == 0 and i > 0 else 0.0
        fl = floor_at(t) + cpn
        nV, nB = [], []
        for j in range(i + 1):
            if i == steps - 1 and smooth:    # last step: the exact one-step split
                b, e = last_step(spot[j], dt, -log(dc) / dt, -log(de) / dt); b += cpn
            else:                            # plain step: average the two branches
                b = dc * (p * B[j + 1] + (1 - p) * B[j]) + cpn
                e = de * (p * (V[j + 1] - B[j + 1]) + (1 - p) * (V[j] - B[j]))
            v = b + e
            if put and abs(t - put[1]) < 1e-9 and v < put[0] + cpn:
                v = b = put[0] + cpn         # holder hands the bond back for cash
            if call and t >= call[1] - 1e-9 and v > call[0] + cpn and spot[j] >= call[2]:
                v = b = call[0] + cpn        # issuer buys it back for cash
            if american and spot[j] > v:
                v, b = spot[j], 0.0          # holder converts: all equity
            nV.append(v); nB.append(b)
            cash = (put and put[0] + cpn, call and call[0] + cpn)     # a choice leaves one kind:
            if v < max(fl, spot[j]) - 1e-9 or (b != 0.0 if spot[j] >= v else v in cash and b != v): bad += 1
        V, B = nV, nB
    return V[0], B[0], bad
def tri(S, rungs, call=None, put=None, level=130.0):
    # three branches, one ladder of prices with a rung on the call level; a tie there converts
    dx = log(level / S) / rungs; w = 1.25 * sig / dx   # a rung is 1.25 standard deviations of a step
    steps = 5 * ceil(T * w * w / 5)                    # a multiple of 5: coupon dates are nodes
    dt = T / steps; nu = r - q - sig * sig / 2; a = (sig * sig * dt + nu * dt * nu * dt) / (dx * dx)
    pu, pm, pd = (a + nu * dt / dx) / 2, 1 - a, (a - nu * dt / dx) / 2
    K, per, bad = int(6 * sig * sqrt(T) / dx), steps // T, 0   # rungs kept: six standard deviations
    lv = [S * exp(k * dx) for k in range(-K, K + 1)]; lv[K + rungs] = level
    walk = lambda W, f: [f * W[0]] + [f * (pu * W[k + 1] + pm * W[k] + pd * W[k - 1]) for k in range(1, 2 * K)]
    B, E = zip(*[last_step(x, dt, r + s, r) for x in lv])  # last step: the exact one-step split
    for i in range(steps - 1, -1, -1):
        t, cpn, nB, nE = i * dt, (c if i % per == 0 and i > 0 else 0.0), [], []
        if i < steps - 1: B, E = walk(B, exp(-(r + s) * dt)) + [0.0], walk(E, exp(-r * dt)) + [lv[-1]]
        for x, b, e in zip(lv, B, E):
            b += cpn; v = b + e
            if put and abs(t - put[1]) < 1e-9 and v < put[0] + cpn: v = b = put[0] + cpn
            if call and t >= call[1] - 1e-9 and v > call[0] + cpn and x >= call[2]: v = b = call[0] + cpn
            if x >= v: v, b = x, 0.0
            nB.append(b); nE.append(v - b)
            bad += b != 0.0 if x >= v else (v in (put and put[0] + cpn, call and call[0] + cpn) and b != v)
        B, E = nB, nE
    return B[K] + E[K], B[K], bad
def euro_closed(S):                         # conversion only at maturity, no call
    cash, share = last_step(S, T, r + s, r)
    cash += sum(c * exp(-(r + s) * k) for k in range(1, T)); return cash + share, cash
n, hard, soft, put3 = 1000, (130.0, 2, 0.0), (100.0, 2, 130.0), (100.0, 3)
floor0, parity = floor_at(0), S0 * 1.0
plain, plain_cash, bad = tree(S0, n)
called, _, bad_c = tree(S0, n, call=hard)
soft_v, putted, bad_b = tree(S0, n, call=soft)[0], tree(S0, n, put=put3)[0], tree(S0, n, call=hard, put=put3)[2]
(euro_tree, euro_tree_cash, _), (euro_cf, euro_cf_cash) = tree(S0, n, american=False), euro_closed(S0)
risky, safe = tree(S0, n, mode="risky")[0], tree(S0, n, mode="safe")[0]
tri40 = [tri(S0, 40, call=k, put=h) for k, h in [(None, None), (hard, None), (soft, None), (None, put3), (hard, put3)]]
t_plain, t_call, t_soft, t_put, t_both = [x[0] for x in tri40]
cost60 = tri(S0, 60)[0] - tri(S0, 60, call=hard)[0]
print("market: S 100, r 5%, q 2%, sigma 20%; bond: face 100, coupon 2, 5 years, 1 share")
for name, val in [("bond floor at r + s = 8%", floor0), ("parity: 1 share x 100", parity),
                  ("tree price, 1000 steps", plain), ("  cash part", plain_cash), ("  share part", plain - plain_cash),
                  ("premium over parity, %", 100 * (plain / parity - 1)), ("three-branch tree, 40 rungs to 130", t_plain),
                  ("with issuer call 130 from year 2", t_call), ("  cost of that call", t_plain - t_call),
                  ("  the same cost, 60 rungs to 130", cost60), ("with holder put 100 at year 3", t_put),
                  ("  value of that put", t_put - t_plain), ("with the call and the put", t_both),
                  ("soft call: 100 once share >= 130", soft_v), ("  three-branch tree", t_soft),
                  ("two-branch tree, call 130", called), ("two-branch tree, put 100", putted),
                  ("convert at maturity only, tree", euro_tree), ("  the same, closed form", euro_cf),
                  ("  tree cash part", euro_tree_cash), ("  closed-form cash part", euro_cf_cash),
                  ("right to convert early is worth", plain - euro_tree), ("everything at 8%", risky),
                  ("everything at 5%", safe), ("5-step tree, plain last step", tree(S0, 5, smooth=False)[0])]:
    print(f"{name:<38}{val:>11.4f}")
print(f"nodes below max(floor, parity) or mislabelled: {bad}, {bad_c} with the call, {bad_b} with call and put")
saw = sorted((tree(S0, k, call=hard)[0], k) for k in range(1000, 1201, 5))
print(f"two-branch tree, call 130, 1000 to 1200 steps: {saw[0][0]:.4f} at {saw[0][1]} to {saw[-1][0]:.4f} at {saw[-1][1]}")
u, d = exp(sig), exp(-sig); p = (exp(r - q) - d) / (u - d)
cash_h, eq_h = exp(-(r + s)) * (1 - p) * (F + c), exp(-r) * p * 100 * u; print("by hand: the year-4 node at S = 100, one step a year")
for name, val in [("up factor u", u), ("down factor d", d), ("up weight p", p), ("share after an up", 100 * u),
                  ("share after a down", 100 * d), ("cash: e^-0.08 x (1-p) x 102", cash_h),
                  ("share: e^-0.05 x p x 122.14", eq_h), ("hold: cash + share + coupon 2", cash_h + eq_h + c),
                  ("the same node, all at 8%", exp(-(r + s)) * (p * 100 * u + (1 - p) * (F + c)) + c)]:
    print(f"{name:<38}{val:>11.4f}")
counts = (100, 250, 500, 1000, 2000); conv = [tree(S0, k)[0] for k in counts]
print("steps     " + "".join(f"{k:>9d}" for k in counts))
print("price     " + "".join(f"{v:>9.4f}" for v in conv))
spots = [40.0 + 20.0 * i for i in range(7)]; curve = [tree(x, n)[0] for x in spots]
print("chart, Acme today     " + "".join(f"{x:>8.0f}" for x in spots))
print("chart, convertible    " + "".join(f"{v:>8.2f}" for v in curve))
print(f"chart, bond floor     {floor0:>8.2f} at every share price; parity = share price")
sig = 0.30; try_vol = tree(S0, n)[0]; sig = 0.20
s = 0.06; try_spr, try_fl = tree(S0, n)[0], floor_at(0); s = 0.03
q = 0.0; try_q0 = tree(S0, n)[0]; try_q0e = try_q0 - tree(S0, n, american=False)[0]; q = 0.02
try_c115, _, bad_t = tri(S0, 21, call=(115.0, 2, 0.0), level=115.0); bad_t += sum(x[2] for x in tri40)
print(f"try: sigma 30% {try_vol:.4f}; spread 6% {try_spr:.4f} (floor {try_fl:.4f})")
print(f"try: no dividend {try_q0:.4f} (early conversion {try_q0e:.4f}); call at 115 {try_c115:.4f} (cost {t_plain - try_c115:.4f})")
assert abs(N(0.3) - 0.617911422188953) < 1e-12, "the series against a tabled bell-curve area"
assert abs(euro_tree - euro_cf) < 0.005, "tree without early conversion vs the closed form"
assert abs(euro_tree_cash - euro_cf_cash) < 0.02, "the two cash parts agree too"
assert abs(plain - t_plain) < 0.01, "two-branch and three-branch trees: one American price"
assert abs(soft_v - t_soft) < 0.01, "and one soft-call price: the trigger only forces conversion"
assert abs(putted - t_put) < 0.05, "and one put price, to the two-branch tree's wobble"
assert abs(cost60 - (t_plain - t_call)) < 0.02, "the call's cost has settled on the three-branch tree"
assert bad + bad_c + bad_b + bad_t == 0, "never below floor or parity, never mislabelled, at any node"
assert risky < plain < safe, "between the all-at-8% and all-at-5% trees"
assert t_call < t_plain < t_both < t_put and soft_v < plain, "a call takes value away, a put adds it"
assert abs(conv[-1] - conv[-2]) < 0.01, "the tree has settled"
assert all(curve[i] >= max(floor0, spots[i]) for i in range(7)), "chart above both bounds"
assert try_q0e < 1e-9 < plain - euro_tree, "no dividend: early conversion is worth nothing"
print("ALL CHECKS PASS")
