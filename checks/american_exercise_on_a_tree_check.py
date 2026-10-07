# American exercise on a tree -- the check behind the card.  Standard library only.
# Nothing is imported that already knows the answer: the bell-curve area comes from
# math.erf, and every tree and grid below is a loop written out here.
from math import log, sqrt, exp, erf
def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))    # bell-curve area left of x
def bs(S, K, r, q, sigma, T, put):            # the closed form, used as an anchor
    vt = sigma * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * sigma * sigma) * T) / vt
    d2 = d1 - vt
    if put:
        return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def moves(r, q, sigma, dt, kind):             # up factor, down factor, up chance
    if kind == "crr":                         # Cox-Ross-Rubinstein: mirror moves
        u = exp(sigma * sqrt(dt))
        return u, 1.0 / u, (exp((r - q) * dt) - 1.0 / u) / (u - 1.0 / u)
    nu = (r - q - 0.5 * sigma * sigma) * dt   # Jarrow-Rudd: even odds, tilted moves
    return exp(nu + sigma * sqrt(dt)), exp(nu - sigma * sqrt(dt)), 0.5
def tree(S, K, r, q, sigma, T, steps, rule, put=True, kind="crr", bar=0.0):
    # Backward induction.  rule "hold" never exercises early (the European price),
    # "max" takes the larger of holding and exercising (the American price), "bar"
    # follows a fixed line: exercise at or below bar, hold above it.  Returns the
    # price and the highest stock price exercised at each step.
    dt = T / steps
    u, d, p = moves(r, q, sigma, dt, kind)
    disc = exp(-r * dt)
    pay = (lambda s: max(K - s, 0.0)) if put else (lambda s: max(s - K, 0.0))
    spot = [S * u ** j * d ** (steps - j) for j in range(steps + 1)]
    v = [pay(s) for s in spot]
    edge = [0.0] * (steps + 1)
    for i in range(steps - 1, -1, -1):
        spot = [s / d for s in spot[:i + 1]]                  # this step's prices
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(i + 1)]
        if rule != "hold":
            for j in range(i + 1):
                x = pay(spot[j])
                take = (x > v[j]) if rule == "max" else (spot[j] <= bar)
                if take:
                    v[j] = x
                    edge[i] = max(edge[i], spot[j])
    return v[0], edge
def grid(S, K, r, q, sigma, T, nx=301, half=1.5):
    # Road three: no tree at all.  A row of log-spaced prices marched back through
    # time by the rule the Black-Scholes equation gives, taking the larger of
    # holding and exercising at every price after every step.
    dx = 2.0 * half / (nx - 1)
    nt = int(T * sigma * sigma / (0.4 * dx * dx)) + 1     # small steps stay stable
    dt, sp = T / nt, [S * exp(-half + i * dx) for i in range(nx)]
    a, b = 0.5 * sigma * sigma * dt / (dx * dx), (r - q - 0.5 * sigma * sigma) * dt / (2.0 * dx)
    v = [max(K - s, 0.0) for s in sp]
    for _ in range(nt):
        w = [v[i] for i in range(nx)]
        for i in range(1, nx - 1):
            w[i] = (v[i] + a * (v[i+1] - 2.0 * v[i] + v[i-1]) + b * (v[i+1] - v[i-1])) / (1.0 + r * dt)
        w[0], w[nx - 1] = K - sp[0], 0.0
        v = [max(w[i], K - sp[i], 0.0) for i in range(nx)]
    return v[(nx - 1) // 2]

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0    # the house market
u, d, p = moves(r, q, sigma, T / 4, "crr")
low = S * d ** 3                                       # three down moves in a row
kids = (max(K - low * u, 0.0), max(K - low * d, 0.0))
hold = exp(-r * T / 4) * (p * kids[0] + (1.0 - p) * kids[1])
am4, eu4 = tree(S, K, r, q, sigma, T, 4, "max")[0], tree(S, K, r, q, sigma, T, 4, "hold")[0]
eu_tree, eu_bs = tree(S, K, r, q, sigma, T, 2000, "hold")[0], bs(S, K, r, q, sigma, T, True)
am, edge = tree(S, K, r, q, sigma, T, 2000, "max")
am_jr = tree(S, K, r, q, sigma, T, 2000, "max", kind="jr")[0]
am_grid = grid(S, K, r, q, sigma, T)
for name, val in [
        ("up move u, one quarter", u), ("down move d, one quarter", d), ("chance of an up move p", p),
        ("three downs: the price at 9 months", low), ("hold: discounted average of the two", hold),
        ("exercise now: K - S", K - low), ("the larger of the two: exercise", max(hold, K - low)),
        ("4-step tree, American put", am4), ("4-step tree, European put", eu4),
        ("2000-step tree, European put", eu_tree), ("Black-Scholes European put", eu_bs),
        ("2000-step tree, American put", am), ("Jarrow-Rudd tree, American put", am_jr),
        ("grid, no tree, American put", am_grid), ("early-exercise premium", am - eu_tree),
        ("the most it could be, K(1 - e^-rT)", K * (1.0 - exp(-r * T)))]:
    print(f"{name:<38}{val:>13.6f}")
print(f"{'  the two payoffs at expiry, up then down':<38}{kids[0]:>13.6f}{kids[1]:>13.6f}")
print()
counts = (10, 25, 50, 100, 250, 500, 1000, 2000)
print("steps       " + "".join(f"{n:>9d}" for n in counts))
print("American put" + "".join(f"{tree(S, K, r, q, sigma, T, n, 'max')[0]:>9.4f}" for n in counts))
print()
bars = (95.0, 90.0, 85.0, 82.0, 75.0)
fixed = [tree(S, K, r, q, sigma, T, 2000, "bar", bar=b)[0] for b in bars]
print("a fixed exercise line at " + "".join(f"{b:>9.0f}" for b in bars))
print("is worth                " + "".join(f"{val:>9.4f}" for val in fixed))
print()
print("exercise boundary: the highest price still worth exercising, 2000 steps")
months = (2, 4, 6, 8, 10, 12)
print("months gone " + "".join(f"{m:>9d}" for m in months))
print("price       " + "".join(f"{(edge[m * 2000 // 12] if m < 12 else K):>9.2f}" for m in months))
print()
c_am0, c_bs0 = tree(S, K, r, 0.0, sigma, T, 2000, "max", put=False)[0], bs(S, K, r, 0.0, sigma, T, False)
c_am = tree(S, K, r, q, sigma, T, 2000, "max", put=False)[0]
c_eu = tree(S, K, r, q, sigma, T, 2000, "hold", put=False)[0]
for name, val in [("American call, no dividend, tree", c_am0),
                  ("Black-Scholes call, no dividend", c_bs0),
                  ("American call, 2% dividend, tree", c_am), ("European call, the same tree", c_eu)]:
    print(f"{name:<38}{val:>13.6f}")
print(f"{'American minus European call, 2% dividend':<38}{c_am - c_eu:>13.9f}")
print()
print("premium against the rate, at the money, per $100 of strike")
prem_r = []
for rate in (0.00, 0.02, 0.05, 0.10):
    a1, e1 = tree(S, K, rate, q, sigma, T, 1000, "max")[0], tree(S, K, rate, q, sigma, T, 1000, "hold")[0]
    prem_r.append(a1 - e1)
    print(f"  r = {rate:.2f}    premium {a1 - e1:8.4f}")
print("premium against volatility: at the money at $100, then deep in at $75")
prem_atm, prem_itm = [], []
for sg in (0.10, 0.20, 0.30, 0.40):
    a1, e1 = tree(S, K, r, q, sg, T, 1000, "max")[0], tree(S, K, r, q, sg, T, 1000, "hold")[0]
    a2, e2 = tree(75.0, K, r, q, sg, T, 1000, "max")[0], tree(75.0, K, r, q, sg, T, 1000, "hold")[0]
    prem_atm.append(a1 - e1)
    prem_itm.append(a2 - e2)
    print(f"  sigma = {sg:.2f} premium {a1 - e1:8.4f} at $100,{a2 - e2:8.4f} at $75")
print()
spots = [60.0 + 5.0 * i for i in range(9)]
am_curve = [tree(s, K, r, q, sigma, T, 1000, "max")[0] for s in spots]
eu_curve = [tree(s, K, r, q, sigma, T, 1000, "hold")[0] for s in spots]
print("chart, Acme price     " + "".join(f"{s:>8.0f}" for s in spots))
print("chart, American put   " + "".join(f"{v:>8.2f}" for v in am_curve))
print("chart, European put   " + "".join(f"{v:>8.2f}" for v in eu_curve))
print("chart, exercise now   " + "".join(f"{max(K - s, 0.0):>8.2f}" for s in spots))
assert abs(eu_bs - 6.330080627550) < 1e-9, "the closed form vs the house put price"
assert abs(eu_tree - eu_bs) < 0.005, "the tree without the max vs the closed form"
assert abs(am - am_jr) < 0.01, "two lattices, one American price"
assert abs(am - am_grid) < 0.02, "lattice against grid"
assert abs(c_am0 - c_bs0) < 0.005, "no dividend: the American call equals the European"
assert am - eu_tree > 0.3, "the right to exercise early is worth real money"
assert max(fixed) < am - 0.01, "every fixed line is beaten by the moving one"
assert all(am_curve[i] >= max(K - spots[i], 0.0) - 1e-9 for i in range(9)), "never below intrinsic"
assert all(edge[m * 2000 // 12] < edge[(m + 2) * 2000 // 12] for m in (2, 4, 6, 8)), "the boundary climbs"
assert prem_r[0] < 1e-9 < prem_r[3], "no premium at a zero rate, a large one at 10%"
assert prem_itm[0] > prem_itm[3], "deep in the money, volatility cuts the premium"
assert prem_atm[0] < prem_atm[3], "at the money, volatility lifts it"
print("ALL CHECKS PASS")
