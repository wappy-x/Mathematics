# Change of numeraire -- the check behind the card.  Standard library only, and
# nothing imported that already knows the answer: the bell-curve area N(x) comes
# from math.erf and every average is Simpson's rule, written out below.  One Acme
# call is priced five independent ways in three units of account, the chance three
# ways, and a two-outcome toy plus a two-state rate curve carry the bond unit and
# the annuity unit.
from math import log, sqrt, exp, erf, pi
def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))        # bell-curve area left of x
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x
def simpson(f, a, b, n):                                   # the only integrator used here
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n): s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0   # the house market
vt = sig * sqrt(T)                                         # one wiggle unit, sigma root T
d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / vt
d2 = d1 - vt
call = S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
F = S * exp((r - q) * T)                                   # the forward price
def acme(z, odds): return S * exp((r - q + odds * 0.5 * sig * sig) * T + vt * z)   # +1 share, -1 bank
def payoff(x): return max(x - K, 0.0)
def tilt(x):   return exp(-(r - q) * T) * x / S            # share unit measured against the bank

# unit 1, a dollar in the bank; unit 2, one share with its dividends reinvested; unit 3, the bond
c_bank = exp(-r * T) * simpson(lambda z: payoff(acme(z, -1)) * phi(z), -10.0, 10.0, 40000)
c_share = S * simpson(lambda z: payoff(acme(z, 1)) / (exp(q * T) * acme(z, 1)) * phi(z),
                      -10.0, 10.0, 40000)
c_bond = exp(-r * T) * (F * N(d1) - K * N(d2))
mean_fwd = simpson(lambda z: acme(z, -1) * phi(z), -10.0, 10.0, 40000)
# the tilt averages one, and reweighting the exercise region gives the share-odds chance
tilt_mean = simpson(lambda z: tilt(acme(z, -1)) * phi(z), -10.0, 10.0, 40000)
zb = (log(K / S) - (r - q - 0.5 * sig * sig) * T) / vt     # the draw that lands Acme on the strike
p_bank = simpson(phi, zb, 10.0, 4000)
p_share = simpson(lambda z: tilt(acme(z, -1)) * phi(z), zb, 10.0, 4000)

def terminal(p, steps):                                    # weights on the steps+1 end nodes
    w = [1.0]
    for _ in range(steps):
        nxt = [0.0] * (len(w) + 1)
        for j, x in enumerate(w):
            nxt[j] += x * (1.0 - p); nxt[j + 1] += x * p
        w = nxt
    return w
STEPS = 801                                                # odd, so no node lands on the strike
dt = T / STEPS
up = exp(sig * sqrt(dt)); dw = 1.0 / up
p_up = (exp((r - q) * dt) - dw) / (up - dw)                # bank odds on one step
p_share_step = p_up * up * exp(-(r - q) * dt)              # the same step, tilted by the share
ends = [S * up ** j * dw ** (STEPS - j) for j in range(STEPS + 1)]
wb, ws = terminal(p_up, STEPS), terminal(p_share_step, STEPS)
t_bank = exp(-r * T) * sum(w * payoff(x) for w, x in zip(wb, ends))
t_share = S * sum(w * payoff(x) / (exp(q * T) * x) for w, x in zip(ws, ends))
t_pb = sum(w for w, x in zip(wb, ends) if x > K); t_ps = sum(w for w, x in zip(ws, ends) if x > K)

# a two-outcome toy: bank unit 2 -> 2, asset unit 3 -> 2 or 4, contract pays 0 or 12
bq, nT, pay = (0.5, 0.5), (2.0, 4.0), (0.0, 12.0)
lt = tuple((n / 3.0) / (2.0 / 2.0) for n in nT)            # how the asset beat the bank
aq = tuple(w * l for w, l in zip(bq, lt))                  # the asset unit's own odds
def bill(u0, odds, uT): return u0 * sum(a * x / n for a, x, n in zip(odds, pay, uT))
toy_bank, toy_asset = bill(2.0, bq, (2.0, 2.0)), bill(3.0, aq, nT)
toy_wrong, toy_hedge = bill(3.0, bq, nT), 6.0 * 3.0 - 6.0 * 2.0

def P(t): return exp(-r * t)                               # a flat 5 percent curve
A0 = P(2.0) + P(3.0)
fl_two = 100.0 * (P(1.0) - P(3.0))
fl_each = 100.0 * sum((P(a) / P(b) - 1.0) * P(b) for a, b in ((1.0, 2.0), (2.0, 3.0)))
swap = (P(1.0) - P(3.0)) / A0
hi = (P(2.0) * exp(r) - 0.02, P(3.0) * exp(r) - 0.04)      # year-1 bonds, rates-up state
lo = (P(2.0) * exp(r) + 0.02, P(3.0) * exp(r) + 0.04)      # year-1 bonds, rates-down state
A1, wT = (hi[0] + hi[1], lo[0] + lo[1]), tuple(0.5 * b / (P(3.0) * exp(r)) for b in (hi[1], lo[1]))
s1 = ((1.0 - hi[1]) / A1[0], (1.0 - lo[1]) / A1[1])        # next year's forward swap rate
wA = tuple(0.5 * a / (A0 * exp(r)) for a in A1)            # annuity odds
mart = wA[0] * s1[0] + wA[1] * s1[1]
w_keep = S * simpson(lambda z: payoff(acme(z, -1)) / (exp(q * T) * acme(z, -1)) * phi(z),
                     -10.0, 10.0, 40000)                   # the new unit, the old odds
w_nd1 = S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1)  # N(d1) read as the dollar chance
w_loose = c_share * exp((r - q) * T)                       # weights left adding to e^{(r-q)T}
w_twice = c_share * exp(-r * T)                            # the unit already carries the discount

rows = ["Acme: S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year", "one call, three units of account",
    ("  formula  S e^-qT N(d1) - K e^-rT N(d2)", call), ("  unit a dollar in the bank", c_bank),
    ("  unit one share, dividends reinvested", c_share),
    ("  unit the 1-year bond, e^-rT (F N1 - K N2)", c_bond),
    ("  an 801-step tree, bank weights", t_bank), ("  the same tree, share weights", t_share),
    ("  the call counted in share units", call / S),
    ("  the call counted in one-year bonds", call / exp(-r * T)), "chance Acme finishes above the strike",
    ("  bank odds, integrated from the strike draw", p_bank), ("  N(d2)", N(d2)),
    ("  share odds, every outcome reweighted", p_share), ("  N(d1)", N(d1)),
    ("  bank odds on the 801-step tree", t_pb), ("  share odds on the same tree", t_ps),
    "the pieces", ("  d1 and d2", (d1, d2)),
    ("  e^-rT, e^-qT and e^qT", (exp(-r * T), exp(-q * T), exp(q * T))),
    ("  forward F, then Acme's average under bond odds", (F, mean_fwd)),
    ("  average tilt, must be 1", tilt_mean),
    "the tilt outcome by outcome: the share unit's weight multiplier",
] + [(f"  Acme at {x:.0f}", tilt(x)) for x in (60.0, 80.0, 100.0, 120.0, 140.0)] + [
    "two outcomes: bank unit 2 -> 2, asset unit 3 -> 2 or 4, contract pays 0 or 12",
    ("  bank odds, the bill and the hedge's cost", (toy_bank, toy_hedge)),
    ("  the two tilts, 2/3 and 4/3", (lt[0], lt[1])),
    (f"  asset odds {aq[0]:.6f} and {aq[1]:.6f}, bill", toy_asset),
    ("  asset units with the old odds kept", toy_wrong),
    "flat 5% curve, two-year swap starting in one year, notional 100",
    ("  annuity A(0) = P(0,2) + P(0,3)", A0), ("  floating leg from two bonds", fl_two),
    ("  floating leg from its forward rates", fl_each),
    ("  forward swap rate from the bond ratio", swap), ("  e^r - 1", exp(r) - 1.0),
    "a two-state curve at year 1: the three sets of odds stop agreeing",
    ("  bank odds on the rates-up state", 0.5), ("  three-year bond odds on that state", wT[0]),
    ("  annuity odds on that state", wA[0]), ("  forward swap rate now", swap),
    ("  annuity-odds average of next year's rate", mart), "what breaks",
    ("  unit changed, old odds kept", w_keep), ("  N(d1) used for both halves", w_nd1),
    ("  tilt left unnormalised", w_loose),
    ("  share-unit answer discounted a second time", w_twice)]
for item in rows:
    if isinstance(item, str): print(item); continue
    name, v = item
    print(f"{name:<44}" + "".join(f"{x:>14.6f}" for x in (v if isinstance(v, tuple) else (v,))))
spots = [80.0 + 5.0 * i for i in range(9)]
print(f"{'chart, Acme now':<36}" + "".join(f"{s:>7.2f}" for s in spots))
for lab, o in (("chart, exercise chance, bank odds %", -1), ("chart, exercise chance, share odds %", 1)):
    vals = [100.0 * N((log(s / K) + (r - q + o * 0.5 * sig * sig) * T) / vt) for s in spots]
    print(f"{lab:<36}" + "".join(f"{v:>7.2f}" for v in vals))

assert abs(call - 9.227005508154) < 1e-9,  "formula vs the number the shelf quotes"
assert abs(c_bank - call) < 1e-7,          "bank unit, brute force, vs the formula"
assert abs(c_share - call) < 1e-7,         "share unit, brute force, vs the formula"
assert abs(c_bond - call) < 1e-9,          "bond unit, forward form, vs the formula"
assert abs(mean_fwd - F) < 1e-7,           "bond odds average Acme to the forward"
assert abs(tilt_mean - 1.0) < 1e-9,        "the tilt must average one"
assert abs(p_bank - N(d2)) < 1e-9 and abs(p_share - N(d1)) < 1e-9, "the two chances, by integral"
assert abs(t_pb - N(d2)) < 0.001 and abs(t_ps - N(d1)) < 0.001, "the two chances, on the tree"
assert abs(t_share - t_bank) < 1e-9,       "one tree, two units, one price"
assert abs(t_bank - call) < 0.005,         "the tree road lands near the formula"
assert N(d1) > N(d2),                      "the share unit tilts the odds upward"
assert abs(toy_asset - toy_bank) < 1e-12 and abs(toy_hedge - toy_bank) < 1e-12, "the toy's one bill"
assert abs(toy_wrong - 4.5) < 1e-12,       "keeping the old odds misprices the toy"
assert abs(fl_each - fl_two) < 1e-12,      "forward rates paid and discounted vs two bonds"
assert abs(swap - (exp(r) - 1.0)) < 1e-12, "flat curve: the par rate is e^r - 1"
assert abs(mart - swap) < 1e-12,           "annuity odds make the par rate a fair bet"
assert abs(wA[0] + wA[1] - 1.0) < 1e-12,   "the annuity odds are a probability"
assert abs(wT[0] - 0.5) > 0.02,            "with moving rates the bond odds are not the bank's"
print("ALL CHECKS PASS")
