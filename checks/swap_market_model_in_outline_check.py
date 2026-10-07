# Swap market model in outline -- the check behind the card.  Standard library only.
# Two annual forwards, L1 (year 1 to 2) and L2 (year 2 to 3), each lognormal on its own
# independent shock: a forward market model.  The two-coupon swap rate built from them
# is then shown not to be lognormal, by formula, by nudging, and by pricing swaptions.
from math import log, exp, sqrt, pi, cos

L1, L2, S1, S2, T = 0.03, 0.04, 0.20, 0.10, 1.0     # forwards, their vols, expiry in years
D1, NOTIONAL = 1 / 1.025, 10_000_000.0               # today's price of $1 paid in one year

def phi(z): return exp(-0.5 * z * z) / sqrt(2 * pi)  # bell-curve height
def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3
def N(x):                                            # bell-curve area left of x, by slices
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    return 0.5 + simpson(phi, 0.0, x, 200)
def black(F, K, vol, t):                             # undiscounted Black call on lognormal F
    if K <= 0: return F - K
    sd = vol * sqrt(t); d1 = (log(F / K) + 0.5 * sd * sd) / sd
    return F * N(d1) - K * N(d1 - sd)

def bonds(l1, l2):                  # bond prices at T1, T2, T3, each in units of the T1 bond
    p2 = 1 / (1 + l1)
    return 1.0, p2, p2 / (1 + l2)
def swap_from_bonds(l1, l2):        # road 1: (P(T1) - P(T3)) / (P(T2) + P(T3))
    p1, p2, p3 = bonds(l1, l2)
    return (p1 - p3) / (p2 + p3)
def swap_formula(l1, l2): return (l1 + l2 + l1 * l2) / (2 + l2)       # road 2: the algebra
def gamma(l1, l2, s1=S1, s2=S2):    # the swap rate's percentage vol, one entry per shock
    d = l1 + l2 + l1 * l2
    return s1 * l1 * (1 + l2) / d, s2 * l2 * (l1 + 2) / ((2 + l2) * d)
def gamma_bump(l1, l2, h=1e-5):     # the same by nudging each forward by a tiny percentage
    g1 = log(swap_from_bonds(l1 * exp(h), l2) / swap_from_bonds(l1 * exp(-h), l2)) / (2 * h)
    g2 = log(swap_from_bonds(l1, l2 * exp(h)) / swap_from_bonds(l1, l2 * exp(-h))) / (2 * h)
    return S1 * g1, S2 * g2
def size(g): return sqrt(g[0] ** 2 + g[1] ** 2)

def payer_integral(K, s1=S1, s2=S2, t=T):
    # Road A.  Terminal-bond measure: both forwards driftless, independent.  Given L2 = y
    # at expiry, (2 + y)(S - K)+ = (1 + y)(L1 - x*)+, a Black call on L1 with strike x*.
    def f(z):
        y = L2 * exp(s2 * sqrt(t) * z - 0.5 * s2 * s2 * t)
        xs = (K * (2 + y) - y) / (1 + y)
        return (1 + y) * black(L1, xs, s1, t) * phi(z)
    return simpson(f, -8.0, 8.0, 400)
state = 88172645463325252
def uniform():                      # xorshift64, our own random numbers
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 2.0 ** 53
def payer_mc(strikes, paths=1_000_000):   # Road B: draw both shocks, and their mirror image
    sums = [0.0] * len(strikes); sq = [0.0] * len(strikes); ann = 0.0
    for _ in range(paths):
        u1, u2 = uniform(), uniform()
        r = sqrt(-2 * log(u1))
        z1, z2 = r * cos(2 * pi * u2), r * cos(2 * pi * u2 - pi / 2)
        v = [0.0] * len(strikes)
        for sign in (1.0, -1.0):
            x = L1 * exp(sign * S1 * sqrt(T) * z1 - 0.5 * S1 * S1 * T)
            y = L2 * exp(sign * S2 * sqrt(T) * z2 - 0.5 * S2 * S2 * T)
            s = swap_formula(x, y); ann += 0.5 * (2 + y) * s
            for i, K in enumerate(strikes): v[i] += 0.5 * (2 + y) * max(s - K, 0.0)
        for i in range(len(strikes)): sums[i] += v[i]; sq[i] += v[i] * v[i]
    means = [a / paths for a in sums]
    ses = [sqrt((q / paths - m * m) / paths) for q, m in zip(sq, means)]
    return means, ses, ann / paths
def implied(target, K, t=T):        # Black vol that reproduces a price, by halving
    lo, hi = 1e-4, 1.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if black(S0, K, mid, t) < target else (lo, mid)
    return 0.5 * (lo + hi)

S0, S0b = swap_formula(L1, L2), swap_from_bonds(L1, L2)
A0 = D1 * (bonds(L1, L2)[1] + bonds(L1, L2)[2])   # annuity today, dollars per $1 of rate
P3 = D1 * bonds(L1, L2)[2]
g, gb = gamma(L1, L2), gamma_bump(L1, L2)
g6, g6b = gamma(0.06, L2), gamma_bump(0.06, L2)
money = lambda e: NOTIONAL * P3 * e                # expectation in T3 units -> dollars
print(f"{'swap rate from bonds':<34}{S0b:>14.6f}")
print(f"{'swap rate from the algebra':<34}{S0:>14.6f}")
print(f"{'bonds P(T1) P(T2) P(T3) today':<34}" + "".join(f"{D1 * p:>10.6f}" for p in bonds(L1, L2)))
print(f"{'annuity today A(0)':<34}{A0:>14.6f}")
print(f"{'average weights P(T2)/A, P(T3)/A':<34}{D1 * bonds(L1, L2)[1] / A0:>14.6f}{P3 / A0:>10.6f}")
for lab, a, b in (("gamma1 at L1 = 3%", g[0], gb[0]), ("gamma2 at L1 = 3%", g[1], gb[1]),
                  ("gamma1 at L1 = 6%", g6[0], g6b[0]), ("gamma2 at L1 = 6%", g6[1], g6b[1])):
    print(f"{lab:<24}formula{a:>11.6f}  nudge{b:>11.6f}")
print(f"{'swap vol size at L1 = 3%':<34}{size(g):>14.6f}")
print(f"{'swap vol size at L1 = 6%':<34}{size(g6):>14.6f}")
print(f"{'weights dlnS/dlnL1, dlnS/dlnL2':<34}{g[0] / S1:>14.6f}{g[1] / S2:>10.6f}")
one = lambda l: (bonds(l, L2)[0] - bonds(l, L2)[1]) / bonds(l, L2)[1]     # one-coupon swap rate
g_one = S1 * log(one(L1 * exp(1e-5)) / one(L1 * exp(-1e-5))) / 2e-5
print(f"{'one coupon: swap vol by nudging':<34}{g_one:>14.6f}")
print("chart, swap vol (%) as L1 runs 1..8%, L2 = 4%:")
print("  forward model " + " ".join(f"{100 * size(gamma(i / 100, L2)):.2f}" for i in range(1, 9)))
print("  swap model    " + " ".join(f"{100 * size(g):.2f}" for i in range(1, 9)))

strikes = [0.025, 0.03, 0.035, 0.04, 0.045, 0.05, S0]
exact = [payer_integral(K) for K in strikes]
mc, se, ann = payer_mc(strikes)
print(f"{'annuity measure: E[S] by draws':<34}{ann / (2 + L2):>14.6f}")
print("strike %   integral $    draws $  std error $  implied Black vol %")
vols = []
for K, e, m, s in zip(strikes, exact, mc, se):
    v = implied(e / (2 + L2), K); vols.append(v)
    print(f"{100 * K:8.4f}{money(e):>13.2f}{money(m):>11.2f}{money(s):>11.2f}{100 * v:>18.4f}")
atm = vols[-1]
print("chart, implied vol (%) strikes 2.5..5.0: " + " ".join(f"{100 * v:.2f}" for v in vols[:6]))
flat = lambda K, v: money(black(S0, K, v, T) * (2 + L2))
print(f"{'frozen sensitivities: vol, ATM $':<34}{size(g):>14.6f}{flat(S0, size(g)):>14.2f}")
w1, w2 = D1 * bonds(L1, L2)[1] / A0, P3 / A0      # Rebonato: freeze the averaging weights
reb = size((S1 * w1 * L1 / S0, S2 * w2 * L2 / S0))
print(f"{'frozen weights (Rebonato): vol, $':<34}{reb:>14.6f}{flat(S0, reb):>14.2f}")
print(f"{'wrong: flat ATM vol, 5% strike $':<34}{flat(0.05, atm):>14.2f}")
print(f"{'wrong: flat ATM vol, 4.5% strike $':<34}{flat(0.045, atm):>14.2f}")
print(f"{'wrong: vols added, not combined':<34}{g[0] + g[1]:>14.6f}{flat(S0, g[0] + g[1]):>14.2f}")
xs = (0.01 * (2 + L2) - L2) / (1 + L2)
p1 = 0.01 * (2 + L2) + 1.0                          # swap model state back to bonds: P(T1)
print(f"{'swap model, S = 1%, L2 = 4%: L1':<34}{xs:>14.6f}{p1 / (1 + L2) - 1:>12.6f}")
tv = [implied(payer_integral(K, S1, 0.20) / (2 + L2), K) for K in (0.025, 0.05)]
t5 = [implied(payer_integral(K, t=5.0) / (2 + L2), K, 5.0) for K in (0.025, 0.05)]
print(f"{'try: sigma2 = 20%, vol at 2.5%, 5%':<34}{100 * tv[0]:>14.4f}{100 * tv[1]:>10.4f}")
print(f"{'try: expiry 5 years, vol 2.5%, 5%':<34}{100 * t5[0]:>14.4f}{100 * t5[1]:>10.4f}")

assert abs(S0 - S0b) < 1e-14, "bond road and algebra road must agree"
assert max(abs(a - b) for a, b in zip(g + g6, gb + g6b)) < 1e-8, "closed-form vol vs nudging"
assert all(abs(e - m) < 4 * s for e, m, s in zip(exact, mc, se)), "integral vs draws"
assert abs(ann / (2 + L2) - S0) < 3e-5, "swap rate is driftless in annuity units"
assert vols[0] < atm - 0.002 and vols[5] > atm + 0.002, "a lognormal swap rate has no skew"
assert abs(g_one - S1) < 1e-8, "one coupon: the swap rate is the forward, same vol"
assert abs(swap_from_bonds(xs, L2) - 0.01) < 1e-14, "recovered L1 reprices the 1% swap through bonds"
assert abs(p1 / (1 + L2) - 1 - xs) < 1e-14, "L1 from the formula and from rebuilt bonds agree"
assert size(g6) > size(g) + 0.02, "the swap rate's vol moves with L1, so no fixed gamma fits both"
assert min(abs(reb - atm), abs(size(g) - atm)) > 2e-5, "frozen approximations are not exact"
print("ALL CHECKS PASS")
