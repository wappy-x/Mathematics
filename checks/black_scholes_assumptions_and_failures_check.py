# The Black-Scholes assumptions -- the check behind the card.  Standard library only, and
# nothing imported that already knows an answer: the bell-curve area is a series written
# out here, the daily moves come from a generator written here, the American put is a
# tree.  Acme is the house market: S = K = 100, r = 5%, q = 2%, sigma = 20%, one year; one
# call is sold at the model premium and hedged 252 times, on 200 records, in three worlds.
from math import cos, exp, log, log10, pi, sin, sqrt
S0, STRIKE, RATE, Q, SIG, T, N = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 252
MU, COST, H, RECS = 0.08, 0.001, 1.0 / 252, 200   # drift, 10bp a trade, a day, records
def phi(x):                                       # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def ncdf(x):                                      # the area to the LEFT of x
    a = abs(x)
    if a > 8.0:                                   # out here the tail is under 1e-15
        return 1.0 if x > 0.0 else 0.0
    term, tot, k = a, a, 1                        # a series, every term positive
    while term > 1e-19 * tot:
        term *= a * a / (2 * k + 1); tot += term; k += 1
    p = 0.5 + phi(a) * tot
    return p if x > 0.0 else 1.0 - p
def bs(s, k, r, q, sg, t):                        # call value and its share count
    if t <= 0.0:
        return max(s - k, 0.0), (1.0 if s > k else 0.0)
    a, drag = sg * sqrt(t), exp(-q * t)
    d1 = (log(s / k) + (r - q + 0.5 * sg * sg) * t) / a
    return s * drag * ncdf(d1) - k * exp(-r * t) * ncdf(d1 - a), drag * ncdf(d1)
def mark(t, s): return bs(s, STRIKE, RATE, Q, SIG, T - t)     # the mark, always 20%
def normals(seed, m):                             # own generator, then Box-Muller
    out, st = [], seed
    while len(out) < m:
        u = []
        for _ in range(2):
            st = (1664525 * st + 1013904223) % 4294967296
            u.append((st + 0.5) / 4294967296.0)
        rad, ang = sqrt(-2.0 * log(u[0])), 2.0 * pi * u[1]
        out += [rad * cos(ang), rad * sin(ang)]
    return out[:m]
def account(kind, z):
    """Hedge the sold call once a day, then settle it: what is left over?"""
    grow, paid = exp(RATE * H), exp(Q * H) - 1.0
    s, jump, month = S0, (0.0, 0.0, 0.0, 0.0), [0.0]
    v, d = mark(0.0, s)
    wealth, carried, bill, cash = v, 0.0, COST * abs(d) * s, v - d * s
    for i, zi in enumerate(z):
        vol = 0.30 if kind == "switch" and i >= N // 2 else SIG    # realised vol
        t, bank = (i + 1) * H, exp(RATE * (i + 1) * H)
        nxt = s * exp((MU - 0.5 * vol * vol) * H + vol * sqrt(H) * zi)
        income = d * s * paid                                      # the day's dividend
        vn, dn = mark(t, nxt)
        carried = grow * carried + d * (nxt - s) + income \
            + (grow - 1.0) * (v - d * s) - (vn - v)                # road 2: the defects
        wealth = d * nxt + cash * grow + income                    # road 1: the account
        if kind == "gap" and i + 1 == N // 2:                      # a 10% overnight gap
            after, j = 0.9 * nxt, -0.1 * nxt
            va, da = mark(t, after)
            jump = (j, (d - dn) * j, va - vn - dn * j, d * j - (va - vn))
            wealth += d * j; carried += jump[3]
            nxt, vn, dn = after, va, da
        bill += COST * abs(dn - d) * nxt / bank                    # the trading bill
        s, v, d = nxt, vn, dn
        cash = wealth - d * s
        if (i + 1) % 21 == 0: month.append(wealth - v)
    pay = max(s - STRIKE, 0.0)                    # the call is settled at expiry
    return s, wealth, pay, wealth - pay, carried, bill, jump, month
def tree_put(steps, american):                    # a CRR tree: an independent road
    dt, u = T / steps, exp(SIG * sqrt(T / steps))
    p, disc = (exp((RATE - Q) * dt) - 1.0 / u) / (u - 1.0 / u), exp(-RATE * dt)
    v = [max(STRIKE - S0 * u ** (2 * j - steps), 0.0) for j in range(steps + 1)]
    for st in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(st)]
        if american:
            v = [max(v[j], STRIKE - S0 * u ** (2 * j - st + 1)) for j in range(st)]
    return v[0]
def stats(x):                                     # mean, spread, worst, best
    m = sum(x) / len(x); sq = sum((a - m) ** 2 for a in x) / (len(x) - 1)
    return m, sqrt(sq), min(x), max(x)
C0, D0 = bs(S0, STRIKE, RATE, Q, SIG, T)
P0 = C0 - S0 * exp(-Q * T) + STRIKE * exp(-RATE * T)       # the put, by parity
d1 = (log(S0 / STRIKE) + (RATE - Q + 0.5 * SIG * SIG) * T) / (SIG * sqrt(T))
GAMMA, VEGA = exp(-Q * T) * phi(d1) / (S0 * SIG * sqrt(T)), S0 * exp(-Q * T) * phi(d1)
KINDS, stream = ("matched", "gap", "switch"), normals(20260919, N * RECS)
runs = {k: [account(k, stream[N * i:N * (i + 1)]) for i in range(RECS)] for k in KINDS}
res = {k: stats([a[3] for a in runs[k]]) for k in KINDS}
traced = min(i for i, a in enumerate(runs["matched"]) if abs(a[0] - STRIKE) <= 5.0)
BE, bill = sqrt(pi / (4.0 * N)) * VEGA * SIG, stats([a[5] for a in runs["matched"]])
lel = SIG * sqrt(1.0 + sqrt(2.0 / pi) * 2.0 * COST / (SIG * sqrt(H)))     # Leland's vol
leland, rms = bs(S0, STRIKE, RATE, Q, lel, T)[0] - C0, sqrt(0.5 * SIG * SIG + 0.5 * 0.09)
rms_c = bs(S0, STRIKE, RATE, Q, rms, T)[0]        # the switch world's whole-year price
stale, bend = stats([a[6][1] for a in runs["gap"]]), stats([a[6][2] for a in runs["gap"]])
sd_day = (log(0.9) - (MU - 0.5 * SIG * SIG) * H) / (SIG * sqrt(H))    # a 10% fall, in sd
p_day = phi(sd_day) / -sd_day * (1.0 - 1.0 / sd_day ** 2 + 3.0 / sd_day ** 4)  # Mills
borrow, lend = bs(S0, STRIKE, 0.07, Q, SIG, T)[0], bs(S0, STRIKE, 0.03, Q, SIG, T)[0]
eu, am = tree_put(1200, False), tree_put(1200, True)
print(f"Acme house market: S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year;"
      f" {N} daily hedges, {RECS} records, real drift 8% a year")
print(f"  call C {C0:.6f}  put by parity P {P0:.6f}  delta {D0:.6f}"
      f"  gamma {GAMMA:.6f}  vega {VEGA:.6f}")
print(f"leftover after settling, over {RECS} records:")
for k in KINDS:
    print(f"  {k:<8} mean {res[k][0]:>10.6f}  spread {res[k][1]:>9.6f}"
          f"  worst {res[k][2]:>10.6f}  best {res[k][3]:>10.6f}")
print(f"record {traced} is the first to finish within $5 of the strike:")
for k in KINDS:
    s, w, pay, left, car, b, jump, month = runs[k][traced]
    print(f"  {k:<8} stock {s:>10.6f}  account {w:>10.6f}  call pays {pay:>9.6f}"
          f"  leftover {left:>10.6f}  carried defects {car:>10.6f}")
j = runs["gap"][traced][6]
print(f"  its gap: stock moved {j[0]:.6f}, stale-delta term {j[1]:.6f},"
      f" bend's bill {j[2]:.6f}, together {j[3]:.6f}")
print("what one broken assumption costs, on the same option:")
print(f"  1 vol switched to 30%: the whole year's volatility {rms:.6f}, the right"
      f" premium {rms_c:.6f}, dearer than 9.227006 by {rms_c - C0:.6f}")
print(f"  2 the 10% gap: bend's bill, mean {bend[0]:.6f}, largest {bend[3]:.6f};"
      f" stale-delta term, mean {stale[0]:.6f}")
print(f"  3 daily, not continuous: Boyle-Emanuel spread {BE:.6f}; at 10bp a trade the"
      f" bill is {bill[0]:.6f}, less the opening purchase {bill[0] - COST * D0 * S0:.6f},"
      f" against Leland's {leland:.6f}")
print(f"  4 two rates: borrowing at 7% {borrow:.6f}, lending at 3% {lend:.6f},"
      f" band {borrow - lend:.6f} wide")
print(f"  5 lognormal moves: a 10% down day is {-sd_day:.6f} standard deviations, chance"
      f" 10^{log10(p_day):.3f}, one such day per 10^{-log10(p_day * N):.3f} years")
print(f"  6 European exercise: the put on a 1200-step tree {eu:.6f}, the American"
      f" {am:.6f}, early exercise worth {am - eu:.6f}")
print(f"bars, dollars on a $9.23 option: vol switch {-res['switch'][0]:.2f}, gap"
      f" {-res['gap'][0]:.2f}, daily not continuous {BE:.2f}, trading at 10bp"
      f" {bill[0]:.2f}, funding band {borrow - lend:.2f}, early exercise {am - eu:.2f}")
print(f"{'chart, months gone':<26}" + "".join(f"{i:>7d}" for i in range(13)))
for k in KINDS:
    print(f"{'chart, ' + k:<26}" + "".join(f"{v:>7.2f}" for v in runs[k][traced][7]))
assert abs(C0 - 9.227005508154) < 1e-9, "the call against the house number"
assert abs(D0 - 0.5 * (mark(0.0, 101.0)[0] - mark(0.0, 99.0)[0])) < 1e-3, "delta by a bump"
assert abs(eu - P0) < 0.01, "the tree must reproduce the put, 6.330081"
assert am > eu + 0.05, "early exercise must be worth something"
assert all(abs(a[3] - a[4]) < 1e-7 for k in KINDS for a in runs[k]), "account vs defects"
assert bend[2] > 0.0, "a gap costs the hedger whichever way it goes"
assert all(abs(a[6][3] - a[6][1] + a[6][2]) < 1e-9 for a in runs["gap"]), "each gap splits"
assert abs(res["matched"][1] / BE - 1.0) < 0.15, "the spread against Boyle-Emanuel"
assert abs(res["matched"][0]) < 4.0 * res["matched"][1] / sqrt(RECS), "daily is unbiased"
assert abs(-res["switch"][0] / (rms_c - C0) - 1.0) < 0.10, "the loss against the price gap"
assert abs((bill[0] - COST * D0 * S0) / leland - 1.0) < 0.15, "the bill against Leland"
print("ALL CHECKS PASS")
