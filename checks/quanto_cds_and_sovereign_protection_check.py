# Quanto CDS -- the check behind the card.  Standard library only.
# One sovereign, protection paid in dollars or in euros; the euro drops by gam
# at the default instant.  Roads to the two spreads: the closed form, both legs
# added up in dollars (Simpson's rule and a premium-date sum), and a Monte Carlo
# of default dates and exchange-rate paths.  Then the inverse: gam from quotes.
from math import exp, log, sqrt, cos, sin, pi

R, lam, gam = 0.40, 0.025, 0.20       # recovery, hazard (dollar world), drop at default
rd, rf, X0, sig = 0.04, 0.02, 1.10, 0.08  # dollar rate, euro rate, $ per EUR, FX volatility
T, dl, n = 5.0, 0.25, 20              # tenor, quarter, premium dates
L, bp = 1.0 - R, 1e4

def F(x):                             # (e^x - 1)/x: the quarter-end delay factor
    return 1.0 if x == 0.0 else (exp(x) - 1.0) / x

def closed(lam, gam, r, dated=True, acc=False):  # road 1: par spread; gam=0, r=rd gives dollars
    le = lam * (1.0 - gam)            # hazard seen by a holder of the payout currency
    x = (r + le) * dl
    g = F(x) / (1.0 + le / (r + le) * (F(x) - 1.0)) if acc else F(x)  # accrued premium pulls it back
    return L * le * (g if dated else 1.0)

def legs(lam, gam, r, m=200):         # road 2: both legs in dollars per $ of notional
    drift = rd - r + gam * lam        # pre-default drift of the payout currency in dollars
    w = lambda t: exp(-rd * t) * exp(drift * t) * exp(-lam * t)  # discount x E[X/X0, alive]
    h, prot, cont, accr = dl / m, 0.0, 0.0, 0.0
    for j in range(n):                # Simpson's rule over the default date, a quarter at a time
        for i in range(m + 1):
            c = (1 if i in (0, m) else (4 if i % 2 else 2)) * h / 3 * w(j * dl + i * h)
            cont += c                                 # premium paid continuously
            prot += c * L * (1.0 - gam) * lam         # payout at default, after the drop
            accr += c * i * h * (1.0 - gam) * lam     # premium accrued in the quarter, paid at default
    ann = sum(dl * w(j * dl) for j in range(1, n + 1))  # premiums at quarter ends
    return prot / ann, prot / (ann + accr), prot, cont

def monte_carlo(paths=400_000, seed=20261123):  # road 3: simulate default and the jump
    s = seed
    def unif():
        nonlocal s
        s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF          # splitmix64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0
    mu = rd - rf + gam * lam - 0.5 * sig * sig   # log-drift of X before default
    nu = rd - rf - 0.5 * sig * sig               # after default: no jump left to pay for
    PU, AU, PE, AE, D = [], [], [], [], []
    for _ in range(paths):
        tau = -log(unif()) / lam
        lx, oU, oE, bU, bE = 0.0, 0.0, 0.0, 0.0, 0.0
        for j in range(1, n + 1):
            u1, u2 = unif(), unif()                                 # Box-Muller: two normals
            z, z2 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2), sqrt(-2.0 * log(u1)) * sin(2.0 * pi * u2)
            t = j * dl
            if tau > t:
                lx += mu * dl + sig * sqrt(dl) * z
                bU += dl * exp(-rd * t); bE += dl * exp(-rd * t + lx)
            elif tau > t - dl:
                hh = tau - (j - 1) * dl                             # walk X to the default date
                lx += mu * hh + sig * sqrt(hh) * z
                oU = L * exp(-rd * tau)
                oE = L * (1.0 - gam) * exp(-rd * tau + lx)          # the euro drops by gam
                lx += log(1.0 - gam) + nu * (t - tau) + sig * sqrt(t - tau) * z2
            else:
                lx += nu * dl + sig * sqrt(dl) * z
        PU.append(oU); AU.append(bU); PE.append(oE); AE.append(bE)
        D.append(exp(lx + (rf - rd) * T))                           # euro deposit in $, discounted, / X0
    def ratio(P, A):                  # sum P / sum A, and each path's share of its error
        r, ma = sum(P) / sum(A), sum(A) / paths
        return r, [(p - r * a) / ma for p, a in zip(P, A)]
    se = lambda e: sqrt(sum(x * x for x in e)) / paths
    (sU, eU), (sE, eE), dm = ratio(PU, AU), ratio(PE, AE), sum(D) / paths
    eG = [sE / sU * (e / sE - u / sU) for u, e in zip(eU, eE)]      # the drop 1 - sE/sU
    return sU, se(eU), sE, se(eE), se(eG), dm, se([d - dm for d in D])

def solve(f, target, lo=0.0, hi=1.0):  # bisection for an increasing f
    while hi - lo > 1e-15:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return 0.5 * (lo + hi)

# ---- the triangle: one name, two currencies ----
sU, sE = closed(lam, 0, rd, False), closed(lam, gam, rf, False)
print(f"dollar spread, triangle (1-R)*lam: {sU*bp:.2f} bp")
print(f"euro spread, triangle (1-gam)*(1-R)*lam: {sE*bp:.2f} bp")
print(f"implied drop from 150 and 120: 1 - 120/150 = {1-120/150:.4f}")
print(f"euro-world hazard (1-gam)*lam: {lam*(1-gam):.4f}")
print(f"payout on $11m: ${L*11:.2f}m; on EUR 10m: EUR {L*10:.2f}m = ${L*10*X0*(1-gam):.2f}m at {X0*(1-gam):.2f}")
print(f"pre-default euro drift rd - rf + gam*lam: {rd-rf+gam*lam:.4f}; jump term -gam*lam: {-gam*lam:.4f}")
for g, r, name in ((0, rd, "dollar"), (gam, rf, "euro")):  # Simpson against the integrals in closed form
    k = r + (1 - g) * lam             # payout-currency rate plus the hazard its holder sees
    _, _, pr, cn = legs(lam, g, r)
    print(f"{name} legs, Simpson vs closed: protection {pr:.8f} vs {L*(1-g)*lam*(1-exp(-k*T))/k:.8f}, "
          f"annuity {cn:.6f} vs {(1-exp(-k*T))/k:.6f}")
    assert abs(pr - L * (1 - g) * lam * (1 - exp(-k * T)) / k) < 1e-9 and abs(cn - (1 - exp(-k * T)) / k) < 1e-9
# ---- quarter-end premiums, without and with the accrued premium at default ----
qU, qE, aU, aE = closed(lam, 0, rd), closed(lam, gam, rf), closed(lam, 0, rd, acc=True), closed(lam, gam, rf, acc=True)
lU, lE = legs(lam, 0, rd), legs(lam, gam, rf)
print(f"dated closed form: dollar {qU*bp:.4f} bp, euro {qE*bp:.4f} bp, ratio {qE/qU:.6f}")
print(f"dated legs: dollar {lU[0]*bp:.4f} bp, euro {lE[0]*bp:.4f} bp")
print(f"delay factors: dollar x {(rd+lam)*dl:.5f} -> {F((rd+lam)*dl):.6f}, euro x {(rf+lam*(1-gam))*dl:.5f} -> {F((rf+lam*(1-gam))*dl):.6f}")
print(f"with accrued premium, closed form: dollar {aU*bp:.4f} bp, euro {aE*bp:.4f} bp, ratio {aE/aU:.6f}")
print(f"with accrued premium, legs: dollar {lU[1]*bp:.4f} bp, euro {lE[1]*bp:.4f} bp")
print(f"delay factors with accrual: dollar {aU/sU:.6f}, euro {aE/sE:.6f}; 1 + r*dl/2: {1+rd*dl/2:.4f}, {1+rf*dl/2:.4f}")
assert max(abs(a - b) for a, b in ((lU[0], qU), (lE[0], qE), (lU[1], aU), (lE[1], aE))) < 1e-9  # legs vs closed
mU, seU, mE, seE, seG, dep, seD = monte_carlo()
print(f"Monte Carlo, 400,000 paths: dollar {mU*bp:.2f} bp (se {seU*bp:.2f}), euro {mE*bp:.2f} bp (se {seE*bp:.2f})")
print(f"Monte Carlo implied drop 1 - sE/sU: {1-mE/mU:.4f} (se {seG:.4f}); dated model: {1-qE/qU:.4f}")
print(f"Monte Carlo euro deposit in dollars at 5 years, discounted, over X0: {dep:.4f} (se {seD:.4f})")
assert abs(mU - qU) < 4 * seU and abs(mE - qE) < 4 * seE  # road 3 against road 1
assert abs((1 - mE / mU) - (1 - qE / qU)) < 3 * seG < abs((1 - mE / mU) - 0.2)  # model, not shortcut
assert abs(dep - 1.0) < 4 * seD                           # the drift a makes the deposit fair
# ---- the inverse: drop from the two quotes ----
lq, le = solve(lambda x: closed(x, 0, rd), 0.0150), solve(lambda x: closed(x, 0, rf), 0.0120)
la, ea = solve(lambda x: closed(x, 0, rd, acc=True), 0.0150), solve(lambda x: closed(x, 0, rf, acc=True), 0.0120)
g0, g1, g2 = 1 - 0.0120 / 0.0150, 1 - le / lq, 1 - ea / la
rU, rE, xU, xE = legs(lq, 0, rd)[0], legs(lq, g1, rf)[0], legs(la, 0, rd)[1], legs(la, g2, rf)[1]
print(f"inverse: shortcut {g0:.4f}; dated quotes: lam {lq:.6f}, euro-world lam {le:.6f}, drop {g1:.4f}")
print(f"re-priced through the legs: {rU*bp:.4f} bp and {rE*bp:.4f} bp")
print(f"inverse with accrued premium: lam {la:.6f}, euro-world lam {ea:.6f}, drop {g2:.4f}; "
      f"re-priced {xU*bp:.4f} bp and {xE*bp:.4f} bp")
assert max(abs(v - q) for v, q in ((rU, 0.0150), (rE, 0.0120), (xU, 0.0150), (xE, 0.0120))) < 1e-9
print(f"Italy, first week of May 2012: 1 - 350/440 = {1-350/440:.4f}")
# ---- what breaks ----
print(f"break: spread same in any currency: euro {sU*bp:.2f} bp, drop 0")
print(f"break: drop measured as the dollar's rise: 150/120 - 1 = {150/120-1:.4f}")
print(f"break: hazard from the euro quote: {0.0120/L:.4f} vs {0.0150/L:.4f}; "
      f"5-year default {1-exp(-5*0.0120/L):.4f} vs {1-exp(-5*0.0150/L):.4f}")
print(f"break: euro spread converted at 1.10: {120*X0:.2f} bp, drop {1-120*X0/150:.4f}")
# ---- try changing ----
print(f"try: gam 0.50 -> euro {closed(lam, 0.5, rf, False)*bp:.2f} bp")
print(f"try: R 0.25 -> dollar {0.75*lam*bp:.2f} bp, euro {0.75*lam*0.8*bp:.2f} bp, drop {1-0.8:.4f}")
r10, a10 = closed(0.10, gam, rf) / closed(0.10, 0, rd), closed(0.10, gam, rf, acc=True) / closed(0.10, 0, rd, acc=True)
print(f"try: lam 0.10 dated -> dollar {closed(0.10,0,rd)*bp:.2f} bp, euro {closed(0.10,gam,rf)*bp:.2f} bp, "
      f"shortcut drop {1-r10:.4f}; with accrual {1-a10:.4f} (at 0.025: {1-aE/aU:.4f})")
assert abs(a10 - aE / aU) < 1e-4 < abs(r10 - qE / qU)     # accrual takes the hazard out of the error
print(f"try: gam -0.10 -> euro {closed(lam, -0.1, rf, False)*bp:.2f} bp")
# ---- chart: euro spread against the drop ----
for g in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]:
    print(f"chart, drop {g:.1f}: triangle {closed(lam, g, rf, False)*bp:.2f} bp, dated {closed(lam, g, rf)*bp:.2f} bp")
print("ALL CHECKS PASS")
