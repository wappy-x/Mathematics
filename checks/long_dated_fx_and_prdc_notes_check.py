# Long-dated FX and PRDC notes -- the check behind the card.  Standard library only.
# Three factors: EURUSD spot (lognormal), USD and EUR short rates (Hull-White, no
# mean reversion).  The normal CDF, the integrals and the random numbers are
# written out here; nothing imported knows the answer.
from math import log, sqrt, exp, pi, cos
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3.0
def N(x): return 0.0 if x < -12 else 1.0 if x > 12 else 0.5 + simpson(phi, 0.0, x, 2000)
S0, sS, sd, sf = 1.10, 0.10, 0.01, 0.01        # spot USD per EUR; spot vol; USD and EUR rate vols
rSd, rSf, rdf = 0.2, -0.2, 0.5                 # correlations spot-USD, spot-EUR, USD-EUR
rd, rf = 0.035, 0.020                          # flat USD and EUR curves, continuously compounded
cf, cd, NOTE = 0.06, 0.03, 10_000_000          # coupon 6% x S_T/1.10 - 3%, floored at 0
g = cf / S0; K = cd / g                        # coupon = g max(S_T - K, 0), K = 0.55
def B(a, tau): return tau if a == 0 else (1 - exp(-a * tau)) / a
def inst_var(tau, a=0.0, s=sS, rho=(rSd, rSf, rdf)):   # variance rate of the forward, tau years before T
    bd, bf = B(a, tau), B(a, tau)
    return (s * s + sd * sd * bd * bd + sf * sf * bf * bf + 2 * rho[0] * s * sd * bd
            - 2 * rho[1] * s * sf * bf - 2 * rho[2] * sd * sf * bd * bf)
def var_closed(T, s=sS):                       # road 1: the integral done by hand (a = 0)
    return (s * s * T, s * (rSd * sd - rSf * sf) * T ** 2, (sd * sd + sf * sf - 2 * rdf * sd * sf) * T ** 3 / 3)
def vol_eff(T, **kw): return sqrt(simpson(lambda u: inst_var(u, **kw), 0.0, T, 600) / T)   # road 2
def coupon(T, v, rd=rd, rf=rf, disc=None):     # Black on the forward: (value, linear part, floor)
    F, Pd = S0 * exp((rd - rf) * T), exp(-(rd if disc is None else disc) * T)
    d1 = (log(F / K) + 0.5 * v * v * T) / (v * sqrt(T)); d2 = d1 - v * sqrt(T)
    return g * Pd * (F * N(d1) - K * N(d2)), Pd * (g * F - cd), g * Pd * (K * N(-d2) - F * N(-d1))
# ---- road 3: simulate all three factors in the dollar pricing world ----
state = 0x2545F4914F6CDD1D
def unif():                                    # xorshift64, a uniform in (0, 1)
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7
    state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
def normal_pair():
    r, t = sqrt(-2.0 * log(unif())), 2.0 * pi * unif()
    return r * cos(t), r * cos(t - 0.5 * pi)
l21, l31 = rSd, rSf                            # Cholesky factor of the 3 x 3 correlation matrix
l22 = sqrt(1 - l21 * l21); l32 = (rdf - l31 * l21) / l22; l33 = sqrt(1 - l31 * l31 - l32 * l32)
PAIRS, DT, MARKS = 20000, 0.25, (1, 10, 30)
acc = {T: [0.0, 0.0] for T in MARKS}           # sum ln S, sum ln S^2
prs = {T: [] for T in MARKS}                   # per antithetic pair: mean D, D S, floor
for p in range(PAIRS):
    zs = []
    for k in range(int(30 / DT)):
        a, b = normal_pair(); c, _ = normal_pair(); zs.append((a, b, c))
    fl = {T: [0.0, 0.0, 0.0] for T in MARKS}
    for sign in (1.0, -1.0):
        x, ud, uf, I, t = log(S0), rd, rf, 0.0, 0.0
        for k, (z1, z2, z3) in enumerate(zs):
            w1 = sign * z1; w2 = sign * (l21 * z1 + l22 * z2); w3 = sign * (l31 * z1 + l32 * z2 + l33 * z3)
            nd = ud + sd * sd * (t + 0.5 * DT) * DT + sd * sqrt(DT) * w2              # Ho-Lee drift
            nf = uf + (sf * sf * (t + 0.5 * DT) - rSf * sS * sf) * DT + sf * sqrt(DT) * w3   # quanto shift
            x += 0.5 * ((ud - uf) + (nd - nf)) * DT - 0.5 * sS * sS * DT + sS * sqrt(DT) * w1
            I += 0.5 * (ud + nd) * DT; ud, uf, t = nd, nf, t + DT
            if abs(t - round(t)) < 1e-9 and round(t) in MARKS:
                T, D, ST = round(t), exp(-I), exp(x)
                acc[T][0] += x; acc[T][1] += x * x
                for i, v in enumerate((D, D * ST, D * g * max(K - ST, 0.0))): fl[T][i] += 0.5 * v
    for T in MARKS: prs[T].append(fl[T])
n = 2 * PAIRS
def mean_se(xs):
    m = sum(xs) / len(xs); return m, sqrt(sum((v - m) ** 2 for v in xs) / (len(xs) - 1) / len(xs))
def mc(T):                                     # spread of ln S_T, and (mean, standard error) of D, D S, floor
    m1, m2 = (v / n for v in acc[T])
    return (sqrt((m2 - m1 * m1) / T),) + tuple(mean_se([q[i] for q in prs[T]]) for i in range(3))
grid = (1, 5, 10, 15, 20, 25, 30)
for T in (1, 10, 30):
    print(f"forward variance at {T}y: spot, cross, rates, total ", " ".join(f"{v:.6f}" for v in var_closed(T)),
          f"{sum(var_closed(T)):.6f} rest {var_closed(T)[1] + var_closed(T)[2]:.6f}")
print("coupon % at S_T = 1.10, 1.21, 1.40, 0.55:", " ".join(f"{100 * max(0.0, cf * x / S0 - cd):.2f}" for x in (1.10, 1.21, 1.40, 0.55)),
      f"| 10% euro rise lifts it {100 * ((cf * 1.21 / S0 - cd) / (cf - cd) - 1):.2f}% | EUR rate drift shift {-rSf * sS * sf:.6f} | half V at 10y {0.5 * sum(var_closed(10)):.6f}")
print("year  vol closed  vol Simpson  bond vol  spot share  rates+cross share")
for T in grid:
    v = var_closed(T); vc = sqrt(sum(v) / T)
    print(f"{T:4d} {vc:11.6f} {vol_eff(T):12.6f} {sd * B(0.0, T):9.4f} {v[0] / sum(v):11.4f} {(v[1] + v[2]) / sum(v):18.4f}")
def crossover(s):                              # bisection: the year the spot's share drops below half
    lo, hi = 1.0, 60.0
    for _ in range(60):
        mid = 0.5 * (lo + hi); v = var_closed(mid, s); lo, hi = (mid, hi) if v[0] > v[1] + v[2] else (lo, mid)
    return lo
lo = crossover(sS)
print(f"spot share falls below half at year {lo:.4f}; quadratic root {(-12 + sqrt(1344)) / 2:.4f}")
print("year  MC vol    D(T) MC   exp(-rd T)  D S MC    S0 exp(-rf T)  floor MC   +- se     floor Black")
for T in MARKS:
    v, (mD, _), (mDS, _), (mfl, se) = mc(T)
    print(f"{T:4d} {v:9.6f} {mD:9.6f} {exp(-rd * T):10.6f} {mDS:9.6f} {S0 * exp(-rf * T):13.6f}"
          f" {mfl:9.6f} {se:9.6f} {coupon(T, vol_eff(T))[2]:11.6f}")
for T in (10, 30):
    v = vol_eff(T); F = S0 * exp((rd - rf) * T); d1 = (log(F / K) + 0.5 * v * v * T) / (v * sqrt(T))
    c, lin, fl = coupon(T, v)
    print(f"{T}y coupon: forward {F:.6f} D(T) {exp(-rd * T):.6f} d1 {d1:.6f} d2 {d1 - v * sqrt(T):.6f}"
          f" N(d1) {N(d1):.6f} N(d2) {N(d1 - v * sqrt(T)):.6f}")
    print(f"{T}y coupon: g {g:.6f} K {K:.6f} g F {g * F:.6f} ln(F/K) {log(F / K):.6f} sd {v * sqrt(T):.6f}"
          f" F N(d1) - K N(d2) {F * N(d1) - K * N(d1 - v * sqrt(T)):.6f}")
    print(f"{T}y coupon: value {c:.6f} = linear {lin:.6f} + floor {fl:.6f}; USD on 10m {NOTE * c:,.2f}")
    print(f"{T}y coupon: spot vol only {coupon(T, sS)[0]:.6f}; USD on 10m {NOTE * coupon(T, sS)[0]:,.2f};"
          f" gap {NOTE * (c - coupon(T, sS)[0]):,.2f}")
print("strip year  vol      forward   value     floor     floor at spot vol")
tot = tot0 = 0.0
for T in range(1, 31):
    c, lin, fl = coupon(T, vol_eff(T)); c0, _, fl0 = coupon(T, sS); tot += c; tot0 += c0
    if T in grid: print(f"strip {T:4d} {vol_eff(T):8.6f} {S0 * exp((rd - rf) * T):8.6f} {c:9.6f} {fl:9.6f} {fl0:9.6f}")
print(f"strip of 30 coupons: {tot:.6f} (USD {NOTE * tot:,.2f}); spot vol only {tot0:.6f} (USD {NOTE * tot0:,.2f}); gap {NOTE * (tot - tot0):,.2f}")
v30 = vol_eff(30)
print(f"30y floor, full vol over spot vol: {coupon(30, v30)[2] / coupon(30, sS)[2]:.2f}")
wrong = [("spot vol only", sS), ("correlations dropped", vol_eff(30, rho=(0, 0, 0))),
         ("bond vol = rate vol, not rate vol x years", sqrt(inst_var(0.0) + (sd * sd + sf * sf - 2 * rdf * sd * sf) + 2 * sS * (rSd * sd - rSf * sf)))]
for name, v in wrong: print(f"wrong 30y: {name:<42} vol {v:.6f} value {coupon(30, v)[0]:.6f}")
print(f"wrong 30y: {'discounted at the EUR rate':<42} vol {v30:.6f} value {coupon(30, v30, disc=rf)[0]:.6f}")
print(f"try: a = 0.05 vol at 30y {vol_eff(30, a=0.05):.6f}; spot vol 15% crossover year {crossover(0.15):.4f}")
sw = [coupon(T, vol_eff(T), rd=rf, rf=rd) for T in range(1, 31)]
sw0 = [coupon(T, sS, rd=rf, rf=rd) for T in range(1, 31)]
print(f"try: rates swapped, 30y forward {S0 * exp((rf - rd) * 30):.6f}, 30y floor {sw[-1][2]:.6f} (spot vol {sw0[-1][2]:.6f}); strip {sum(c[0] for c in sw):.6f} (spot vol {sum(c[0] for c in sw0):.6f})")
print("chart, vol %  " + " ".join(f"{100 * vol_eff(T):6.2f}" for T in grid))
print("chart, spot % " + " ".join(f"{100 * sS:6.2f}" for T in grid))
print("chart, bond % " + " ".join(f"{100 * sd * B(0.0, T):6.2f}" for T in grid))
assert all(abs(sqrt(sum(var_closed(T)) / T) - vol_eff(T)) < 1e-9 for T in grid), "closed form vs Simpson"
assert [round(100 * vol_eff(T), 2) for T in MARKS] == [10.21, 13.17, 22.80], "the spec's three volatilities"
for T in MARKS:
    v, (mD, eD), (mDS, eDS), (mfl, se) = mc(T)
    assert abs(v - vol_eff(T)) < 4 * sqrt(0.5 / PAIRS) * vol_eff(T), "simulated spread of ln S_T vs the formula"
    if T == 1: continue                        # 1 year: printed for reference only (floor 0 on every path)
    assert abs(mD - exp(-rd * T)) < 4 * eD + 1e-6, "simulated dollar bond vs today's curve"
    assert abs(mDS - S0 * exp(-rf * T)) < 4 * eDS + 1e-6, "EUR deposit is worth S0 P_f in USD"
    assert abs(mfl - coupon(T, vol_eff(T))[2]) < 4 * se + 1e-6, "simulated floor vs Black floor"
assert abs(coupon(10, vol_eff(10))[0] - (coupon(10, vol_eff(10))[1] + coupon(10, vol_eff(10))[2])) < 1e-9, "coupon = linear + floor"
assert abs(lo - (-12 + sqrt(1344)) / 2) < 1e-6, "bisection vs the quadratic root"
print("ALL CHECKS PASS")
