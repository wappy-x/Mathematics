# Cliquets -- the check behind the card.  Standard library only; nothing imported knows the answer: bell-curve area
# by its series, random numbers by a 64-bit congruential recurrence and Box-Muller, implied vol by bisection.
from math import log, exp, sqrt, cos, sin, pi

S0, r, q, sig, T = 100.0, 0.05, 0.02, 0.20, 1.0        # the house market
NQ, M = 4, 8; tau = T / NQ; dt = tau / M; NS = NQ * M   # four quarters, eight steps each
CAP, FLO = 0.05, -0.05                                  # local cap and floor; the global floor is 0
kap, th, xi, rho, v0 = 2.0, 0.04, 0.3, -0.7, 0.04       # the house Heston model
NP, NB, W = 100000, 50, 0.04                            # paths; local-vol table: 50 bins of 0.04 in ln(S/S0)
KS = (0.90, 0.95, 1.00, 1.05, 1.10)

def N(x):                                               # bell-curve area left of x, Marsaglia's series
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    s, t, b, xx, i = x, 0.0, x, x * x, 1.0
    while s != t:
        t = s; i += 2.0; b *= xx / i; s = t + b
    return 0.5 + s * exp(-0.5 * xx - 0.91893853320467274178)

def unit_call(k, ta, sg, rr=r):                         # Black-Scholes call on a $1 share, strike k
    d1 = (-log(k) + (rr - q + 0.5 * sg * sg) * ta) / (sg * sqrt(ta)); d2 = d1 - sg * sqrt(ta)
    return exp(-q * ta) * N(d1) - k * exp(-rr * ta) * N(d2), d1, d2

def implied(price, k, ta):                              # bisection: the flat vol that gives this price
    lo, hi = 0.01, 1.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if unit_call(k, ta, mid)[0] > price: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def conv_price(sg, cap=CAP, flo=FLO, gf=0.0, rr=r, h=0.00025):
    # Road 2, flat model only: the quarter's capped coupon on a grid, four copies added by convolution
    mu, s = (rr - q - 0.5 * sg * sg) * tau, sg * sqrt(tau)
    F = lambda a: N((log(1.0 + a) - mu) / s)            # chance the quarter's return is below a
    m = int(round((cap - flo) / h))
    p = [F(flo + h / 2)] + [F(flo + i * h + h / 2) - F(flo + i * h - h / 2) for i in range(1, m)] + [1.0 - F(cap - h / 2)]
    d = p
    for _ in range(NQ - 1):
        out = [0.0] * (len(d) + m)
        for i, a in enumerate(d):
            for j, b in enumerate(p): out[i + j] += a * b
        d = out
    ev = sum(w * max(NQ * flo + n * h, gf) for n, w in enumerate(d))
    ec = sum(w * (flo + n * h) for n, w in enumerate(p)); ep = sum(w * max(flo + n * h, 0.0) for n, w in enumerate(p))
    return 100.0 * exp(-rr * T) * ev, 1.0 - p[-1] - p[0], p[0], p[-1], ec, ep

st = [0x2545F4914F6CDD1D]
def pair():                                             # two independent standard normal draws
    st[0] = (st[0] * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    u1 = ((st[0] >> 11) + 0.5) / 9007199254740992.0
    st[0] = (st[0] * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
    u2 = ((st[0] >> 11) + 0.5) / 9007199254740992.0
    rr = sqrt(-2.0 * log(u1)); return rr * cos(2.0 * pi * u2), rr * sin(2.0 * pi * u2)

def payoffs(xs):                                        # xs = ln(S/S0) at 0, 0.25, 0.5, 0.75, 1
    R = [exp(xs[i + 1] - xs[i]) - 1.0 for i in range(NQ)]
    c = sum(min(max(x, FLO), CAP) for x in R)
    return (max(c, 0.0), sum(max(x, 0.0) for x in R), [max(1.0 + R[3] - k, 0.0) for k in KS],
            [max(exp(xs[NQ]) - k, 0.0) for k in KS], c, sum(x > CAP for x in R), sum(x < FLO for x in R))

# ---- Road 3: Heston paths; the same pass records the average variance at each price and date ----
rq = sqrt(1.0 - rho * rho)
sv = [[0.0] * NB for _ in range(NS)]; cn = [[0.0] * NB for _ in range(NS)]
H = []
for _ in range(NP):
    X, v, xs = 0.0, v0, [0.0]
    for j in range(NS):
        vp = v if v > 0.0 else 0.0
        b = min(max(int((X + 1.0) / W), 0), NB - 1)
        sv[j][b] += vp; cn[j][b] += 1.0
        z1, z2 = pair()
        X += (r - q - 0.5 * vp) * dt + sqrt(vp * dt) * z1
        v += kap * (th - vp) * dt + xi * sqrt(vp * dt) * (rho * z1 + rq * z2)
        if (j + 1) % M == 0: xs.append(X)
    H.append(payoffs(xs))
# local variance = average Heston variance of the paths at that price and date (Gyongy), shrunk to the date's mean
L = [[(sv[j][b] + 50.0 * sum(sv[j]) / NP) / (cn[j][b] + 50.0) for b in range(NB)] for j in range(NS)]

# ---- Roads 4 and 1b: local-vol paths and flat paths, driven by the same share shocks as Heston ----
st[0] = 0x2545F4914F6CDD1D
LV, FL = [], []
for _ in range(NP):
    X, Y, xs, ys = 0.0, 0.0, [0.0], [0.0]
    for j in range(NS):
        lv = L[j][min(max(int((X + 1.0) / W), 0), NB - 1)]
        z1, z2 = pair()
        X += (r - q - 0.5 * lv) * dt + sqrt(lv * dt) * z1
        Y += (r - q - 0.5 * sig * sig) * dt + sig * sqrt(dt) * z1
        if (j + 1) % M == 0: xs.append(X); ys.append(Y)
    LV.append(payoffs(xs)); FL.append(payoffs(ys))

D = exp(-r * T)
def stats(a):
    m = sum(a) / len(a); return m, sqrt(sum((x - m) * (x - m) for x in a) / (len(a) - 1) / len(a))
def show(label, *vals, dp=6): print(f"{label:<44}" + "".join(f"{v:>11.{dp}f}" for v in vals))

# ---- Road 1: the uncapped cliquet is four forward-start calls, closed form ----
u, d1, d2 = unit_call(1.0, tau, sig)
leg = 100.0 * exp(-r * (T - tau)) * u
fs_house = 100.0 * exp(-q * 0.5) * unit_call(1.0, 0.5, sig)[0]    # the shelf's forward-start, reset 0.5 year
show("d1, d2, N(d1), N(d2) (one quarter)", d1, d2, N(d1), N(d2))
show("unit call C(1,1,0.25), e^-r(T-tau)", u, exp(-r * (T - tau))); show("house check: forward-start reset 0.5y", fs_house)
show("uncapped leg, each of four", leg); show("uncapped: sum of four legs", 4 * leg)
unc, unc_se = stats([100 * D * a[1] for a in FL]); show("uncapped: flat simulation, std error", unc, unc_se)
show("wrong: notional carried as a share", sum(100 * exp(-q * i * tau - r * (T - (i + 1) * tau)) * u for i in range(NQ)))
show("monthly resets, uncapped (12 legs)", 12 * 100 * exp(-r * (T - T / 12)) * unit_call(1.0, T / 12, sig)[0])
cv, pin, pfl, pcap, ec, ep = conv_price(sig)
show("flat: P(floor), P(inside), P(cap), E[c]", pfl, pin, pcap, ec); show("capped: flat, convolution", cv)
fl, fl_se = stats([100 * D * a[0] for a in FL]); show("capped: flat simulation, std error", fl, fl_se)
he, he_se = stats([100 * D * a[0] for a in H]); show("capped: Heston simulation, std error", he, he_se)
lo, lo_se = stats([100 * D * a[0] for a in LV]); show("capped: local vol simulation, std error", lo, lo_se)
gap, gap_se = stats([100 * D * (H[i][0] - LV[i][0]) for i in range(NP)]); show("Heston minus local vol, std error", gap, gap_se)
show("Heston minus flat", he - fl)
for nm, A in (("Heston", H), ("local vol", LV), ("flat", FL)):
    show(f"{nm}: P(cap), P(floor), no floor", sum(a[5] for a in A) / (4 * NP), sum(a[6] for a in A) / (4 * NP), 100 * D * sum(a[4] for a in A) / NP)
show("wrong: no global floor", 100 * D * NQ * ec); show("wrong: local floor 0, no global", 100 * D * NQ * ep)
ivs = {}
for nm, A in (("Heston", H), ("local vol", LV), ("flat", FL)):
    ivs[nm] = [100 * implied(sum(a[2][i] for a in A) / NP * exp(-r * tau), KS[i], tau) for i in range(5)]
    show(f"forward smile Q4, {nm} (%)", *ivs[nm], dp=2)
for nm, A in (("Heston", H), ("local vol", LV)):
    ivs[nm + " 1y"] = [100 * implied(sum(a[3][i] for a in A) / NP * D, KS[i], T) for i in range(5)]
    show(f"1-year smile, {nm} (%)", *ivs[nm + " 1y"], dp=2)
show("flat price at vol 10,15,20,25,30%", *[conv_price(s)[0] for s in (0.10, 0.15, 0.20, 0.25, 0.30)], dp=2)
show("vega per vol point (19% to 21%)", (conv_price(0.21)[0] - conv_price(0.19)[0]) / 2)
show("rho per rate point (4% to 6%)", (conv_price(sig, rr=0.06)[0] - conv_price(sig, rr=0.04)[0]) / 2)
show("try: global floor 2%", conv_price(sig, gf=0.02)[0]); show("try: cap 10%, floor -10%", conv_price(sig, 0.10, -0.10)[0])
RS = (-10, -7.5, -5, -2.5, 0, 2.5, 5, 7.5, 10)
show("coupon (%) at return -10..10 by 2.5", *[100 * min(max(x / 100, FLO), CAP) for x in RS], dp=2)
show("uncapped coupon (%), same returns", *[100 * max(x / 100, 0.0) for x in RS], dp=2)
cs = sum(min(max(x, FLO), CAP) for x in (0.08, -0.03, 0.02, -0.07))
show("path +8,-3,+2,-7%: sum, paid, uncapped", 100 * cs, 100 * max(cs, 0.0), 100 * sum(max(x, 0.0) for x in (0.08, -0.03, 0.02, -0.07)))

assert abs(unc - 4 * leg) < 3 * unc_se, "uncapped: simulation must match four forward-start closed forms"
assert abs(fl - cv) < 3 * fl_se, "capped, flat: simulation must match convolution"
assert abs(fs_house - 6.244873) < 1e-6, "forward-start must match the shelf's house number"
assert abs(ivs["Heston 1y"][2] - ivs["local vol 1y"][2]) < 0.3, "local vol must reprice Heston's 1-year ATM call"
assert gap > 5 * gap_se, "Heston and local vol must disagree on the cliquet"
print("All checks passed.")
