# Pricing with local volatility -- the check behind the card.  Standard library only; nothing imported
# knows the answer: the bell-curve area is its power series, the random numbers the Monte Carlo card's
# recurrence, the grid a Crank-Nicolson march.  Two roads to every price: simulated paths, and a grid.
from math import cos, exp, log, pi, sin, sqrt

S0, R, Q, SIG, RHO, ETA, T1, T = 100.0, 0.05, 0.02, 0.20, -0.7, 0.5, 0.5, 1.0
DZ, ZL, NZ, DT, NT, PATHS = 0.01, -3.0, 600, 0.01, 100, 20000     # grid: log(K/100) from -3 to 3
Z, KS, KAPS = [ZL + DZ * j for j in range(NZ + 1)], [80.0 + 5.0 * i for i in range(9)], [0.8 + 0.05 * i for i in range(9)]

def ncdf(x):                                   # bell-curve area left of x, by its power series
    term, total = x, x
    for n in range(1, 150):
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2.0 * pi) if abs(x) < 9.0 else float(x > 0.0)
def bs(s, k, t, vol):                          # Black-Scholes call
    d1 = (log(s / k) + (R - Q) * t) / (vol * sqrt(t)) + 0.5 * vol * sqrt(t)
    return s * exp(-Q * t) * ncdf(d1) - k * exp(-R * t) * ncdf(d1 - vol * sqrt(t))
def implied(price, s, k, t, lo=0.01, hi=1.5):  # bisection: the one vol that gives this price
    for _ in range(60):
        lo, hi = (lo, 0.5 * (lo + hi)) if bs(s, k, t, 0.5 * (lo + hi)) > price else (0.5 * (lo + hi), hi)
    return 0.5 * (lo + hi)
def w(x, t, eta=ETA):                          # the skewed surface: total variance at x = log(K/100)
    th, p = SIG * SIG * t, eta / (SIG * sqrt(t))
    return 0.5 * th * (1.0 + RHO * p * x + sqrt((p * x + RHO) * (p * x + RHO) + 1.0 - RHO * RHO))
ivol = lambda k, t: sqrt(w(log(k / S0), t) / t)                  # the surface's vol at strike k
fwd = lambda kap, vol: S0 * exp(-Q * T1) * bs(1.0, kap, T - T1, vol)   # forward start at one flat vol
def lv(z, t, eta=ETA):                         # Dupire in implied-vol terms, slopes by small steps
    ww = lambda k, tt: w(k + (R - Q) * tt, tt, eta)            # the surface against log(K/forward)
    k, h, e = z - (R - Q) * t, 1e-4, 1e-5
    w0, w1, w2 = ww(k, t), (ww(k + h, t) - ww(k - h, t)) / (2 * h), (ww(k + h, t) - 2 * ww(k, t) + ww(k - h, t)) / (h * h)
    g = (1.0 - k * w1 / (2.0 * w0)) * (1.0 - k * w1 / (2.0 * w0)) - w1 * w1 / 4.0 * (1.0 / w0 + 0.25) + w2 / 2.0
    wt = (ww(k, t + e) - ww(k, t - e)) / (2.0 * e)
    return sqrt(wt / g), g, wt
def march(n0, s, tab, n1=NT):                  # Dupire's forward equation from price s, step n0 to n1
    c = [max(s - S0 * exp(z), 0.0) for z in Z]
    c[round((log(s / S0) - ZL) / DZ)] = s * (0.5 * DZ - 1.0 + exp(-0.5 * DZ)) / DZ   # kink cell averaged
    for n in range(n0, n1):
        lo = s * exp(-Q * (n + 1 - n0) * DT) - S0 * exp(ZL) * exp(-R * (n + 1 - n0) * DT)
        cp, dp, new = [0.0] * (NZ + 1), [lo] * (NZ + 1), [lo] + [0.0] * NZ
        for j in range(1, NZ):                 # Thomas sweep down, then back up
            p, adv = 0.5 * tab[n][j] * tab[n][j] / (DZ * DZ), (0.5 * tab[n][j] * tab[n][j] + R - Q) / (2.0 * DZ)
            a, b, cc = p + adv, -2.0 * p - Q, p - adv
            m = 1.0 - 0.5 * DT * b + 0.5 * DT * a * cp[j - 1]
            cp[j], dp[j] = -0.5 * DT * cc / m, (c[j] + 0.5 * DT * (a * c[j - 1] + b * c[j] + cc * c[j + 1]) + 0.5 * DT * a * dp[j - 1]) / m
        for j in range(NZ - 1, 0, -1):
            new[j] = dp[j] - cp[j] * new[j + 1]
        c = new
    return c
def at(c, k):                                  # read the grid at strike k, three-point fit
    u = (log(k / S0) - ZL) / DZ
    f, j = u - round(u), round(u)
    return c[j] + 0.5 * f * (c[j + 1] - c[j - 1]) + 0.5 * f * f * (c[j + 1] - 2.0 * c[j] + c[j - 1])
def twin(k):                                   # coin-flip vol, 40% w.p. 0.12 else 15%, and its twin
    c = lambda kk, t: 0.12 * bs(S0, kk, t, 0.40) + 0.88 * bs(S0, kk, t, 0.15)
    h, e, x = 0.001 * k, 1e-4, log(k / S0) - R + Q         # each world's chance per dollar of ending at k
    fa, fb = [p * exp(-0.5 * (x + 0.5 * v * v) * (x + 0.5 * v * v) / (v * v)) / (k * v * sqrt(2.0 * pi)) for p, v in ((0.12, 0.40), (0.88, 0.15))]
    num = (c(k, T + e) - c(k, T - e)) / (2 * e) + (R - Q) * k * (c(k + h, T) - c(k - h, T)) / (2 * h) + Q * c(k, T)
    dup = sqrt(2.0 * num / (k * k * (c(k + h, T) - 2.0 * c(k, T) + c(k - h, T)) / (h * h)))   # Dupire from prices
    return fa, fb, fa / (fa + fb), dup, sqrt((fa * 0.16 + fb * 0.0225) / (fa + fb))

LVS = [[lv(z, (n + 0.5) * DT) for z in Z] for n in range(NT)]
TAB = [[v[0] for v in row] for row in LVS]
full, half = march(0, S0, TAB), march(0, S0, TAB, NT // 2)
grid, surf, gap6 = [at(full, k) for k in KS], [bs(S0, k, T, ivol(k, T)) for k in KS], max(abs(at(half, k) - bs(S0, k, T1, ivol(k, T1))) for k in KS)

state, cv, fs, acc = 20260924, [0.0] * 9, [0.0] * 9, [0.0] * 8
for _ in range(PATHS // 2):
    zs, pv = [], [0.0] * 4                     # pv: the pair's averages of four payoffs
    for _ in range(NT // 2):                   # the recurrence, then Box-Muller: two fractions, two draws
        state = (1664525 * state + 1013904223) % 4294967296
        u, state = (state + 0.5) / 4294967296, (1664525 * state + 1013904223) % 4294967296
        rad, ang = sqrt(-2.0 * log(u)), 2.0 * pi * (state + 0.5) / 4294967296
        zs += [rad * cos(ang), rad * sin(ang)]
    for sign in (1.0, -1.0):                   # each path and its mirror image
        x, y, sh, sfh = 0.0, 0.0, 0.0, 0.0     # log(price/100): local vol, and flat 20% on the same draws
        for n in range(NT):
            u = (x - ZL) / DZ
            vol = TAB[n][int(u)] + (u - int(u)) * (TAB[n][int(u) + 1] - TAB[n][int(u)])
            x += (R - Q - 0.5 * vol * vol) * DT + vol * sign * zs[n] * sqrt(DT)
            y += (R - Q - 0.5 * SIG * SIG) * DT + SIG * sign * zs[n] * sqrt(DT)
            sh, sfh = (S0 * exp(x), S0 * exp(y)) if n == NT // 2 - 1 else (sh, sfh)
        st, sf = S0 * exp(x), S0 * exp(y)
        for i in range(9):                     # payoff under local vol minus payoff under flat 20%
            cv[i] += max(st - KS[i], 0.0) - max(sf - KS[i], 0.0)
            fs[i] += max(st - KAPS[i] * sh, 0.0) - max(sf - KAPS[i] * sfh, 0.0)
        pl, fl = max(st - 100.0, 0.0), max(sf - sfh, 0.0)        # plain payoff; the flat control's own forward start
        pv = [pv[0] + 0.5 * pl, pv[1] + 0.5 * (pl - max(sf - 100.0, 0.0)), pv[2] + 0.5 * (max(st - sh, 0.0) - fl), pv[3] + 0.5 * fl]
    acc = [acc[i] + (pv[i // 2] if i % 2 == 0 else pv[i // 2] * pv[i // 2]) for i in range(8)]   # sums, sums of squares
se = lambda m, h=PATHS // 2: exp(-R * T) * sqrt((acc[2 * m + 1] / h - (acc[2 * m] / h) * (acc[2 * m] / h)) / h)   # from pair averages
mc, mcfs = [exp(-R * T) * cv[i] / PATHS + bs(S0, KS[i], T, SIG) for i in range(9)], [exp(-R * T) * fs[i] / PATHS + fwd(KAPS[i], SIG) for i in range(9)]

fsg, reset, avg = [0.0] * 9, [], [0.0] * 4     # road 2: where Acme stands at the reset, times the grid from there
for i, j in enumerate(range(200, 371, 5)):
    s, c = S0 * exp(Z[j]), march(NT // 2, S0 * exp(Z[j]), TAB)
    dens = exp(R * T1) * (bs(S0, 1.01 * s, T1, ivol(1.01 * s, T1)) - 2 * bs(S0, s, T1, ivol(s, T1)) + bs(S0, 0.99 * s, T1, ivol(0.99 * s, T1))) / ((0.01 * s) * (0.01 * s))
    wgt = (1.0 if i in (0, 34) else (4.0 if i % 2 else 2.0)) * 5.0 * DZ / 3.0 * s * dens * exp(-R * T1)   # Simpson
    fsg = [fsg[m] + wgt * at(c, KAPS[m] * s) for m in range(9)]
    v = implied(at(c, s), s, s, T - T1)        # the at-the-money vol for the second half-year, from s
    avg, reset = [avg[0] + wgt * v, avg[1] + wgt, avg[2] + wgt * s * v, avg[3] + wgt * s], reset + ([(s, v)] if j in (280, 290, 300, 310, 320) else [])
fvol = lambda p, kap: implied(p / (S0 * exp(-Q * T1)), 1.0, kap, T - T1)
wrong = [march(0, S0, tb) for tb in ([[ivol(S0 * exp(z), (n + 0.5) * DT) for z in Z] for n in range(NT)], [[row[300]] * (NZ + 1) for row in TAB], [TAB[8]] * NT)]
row = lambda label, vals, f: print(label + "".join(format(v, f) for v in vals))
row("local vol from the skewed surface, %; Acme's price across, date down\nprice    ", range(70, 131, 10), "7d")
for n in (9, 49, 99):
    row(f"t = {(n + 0.5) * DT:.3f}", [100 * lv(log(p / S0), (n + 0.5) * DT)[0] for p in range(70, 131, 10)], "7.2f")
print(f"flat 20% surface, local vol at (80, 0.5) and (120, 1.0)  {lv(log(0.8), 0.5, 0.0)[0]:.6f}  {lv(log(1.2), 1.0, 0.0)[0]:.6f}"
      f"\nno arbitrage on the grid: least g {min(v[1] for r in LVS for v in r):.6f}, least dw/dT {min(v[2] for r in LVS for v in r):.6f}")
print("1-year strip  surface vol  surface price   grid price   MC price   MC vol")
for i, k in enumerate(KS):
    print(f"{k:8.0f}{100 * ivol(k, T):12.2f}{surf[i]:15.6f}{grid[i]:13.6f}{mc[i]:11.4f}{100 * implied(mc[i], S0, k, T):9.2f}")
print(f"6-month strip, largest gap grid vs surface  {gap6:.6f}\n$100 call: plain MC {2 * exp(-R * T) * acc[0] / PATHS:.4f} s.e. {se(0):.4f}; flat-20% control s.e. {se(1):.4f}")
print("coin-flip twin, strike  40% world  15% world  share of 40%  Dupire vol  E[vol^2 | S_T = K]")
for k in (70.0, 100.0, 140.0):
    print(f"{k:22.0f}{twin(k)[0]:11.6f}{twin(k)[1]:11.6f}{twin(k)[2]:14.4f}{100 * twin(k)[3]:12.2f}{100 * twin(k)[4]:12.2f}")
d1 = (R - Q) * (T - T1) / (SIG * sqrt(T - T1)) + 0.5 * SIG * sqrt(T - T1)
print(f"forward start at flat 20% by hand: d1 {d1:.6f} d2 {d1 - SIG * sqrt(T - T1):.6f} N(d1) {ncdf(d1):.6f} N(d2) {ncdf(d1 - SIG * sqrt(T - T1)):.6f}"
      f"\n  per-dollar call {bs(1.0, 1.0, T - T1, SIG):.6f} x S0 e^-qT1 {S0 * exp(-Q * T1):.6f} = {fwd(1.0, SIG):.6f}")
print("forward start, strike % of reset  today 6m vol  grid price  MC price  grid vol  MC vol")
for m in (0, 2, 4, 6, 8):
    print(f"{100 * KAPS[m]:24.0f}{100 * ivol(100 * KAPS[m], T1):14.2f}{fsg[m]:12.4f}{mcfs[m]:10.4f}{100 * fvol(fsg[m], KAPS[m]):10.2f}{100 * fvol(mcfs[m], KAPS[m]):8.2f}")
print(f"at the money: flat 20% {fwd(1.0, SIG):.6f} (flat paths alone {2 * exp(-R * T) * acc[6] / PATHS:.4f} s.e. {se(3):.4f})"
      f"\n  local vol: grid {fsg[4]:.6f}, MC {mcfs[4]:.4f} s.e. {se(2):.4f}, gap {fsg[4] - fwd(1.0, SIG):.4f}")
print("reset level  " + "".join(f"{s:8.2f}" for s, _ in reset) + "\nATM vol after" + "".join(f"{100 * v:8.2f}" for _, v in reset))
print(f"ATM vol after the reset, averaged over where Acme stands: plain {100 * avg[0] / avg[1]:.2f}%, weighted by its price {100 * avg[2] / avg[3]:.2f}%")
row("chart, strike % of reset", [100 * kap for kap in KAPS], "7.0f")
row("chart, today's 6m vol % ", [100 * ivol(100 * kap, T1) for kap in KAPS], "7.2f")
row("chart, forward vol %    ", [100 * fvol(fsg[m], KAPS[m]) for m in range(9)], "7.2f")
for name, c in zip(("implied vol as local vol", "local vol by date only", "one-month local vol all year"), wrong):
    print(f"wrong: {name:<29}$80 {at(c, 80.0):.4f} ({100 * implied(at(c, 80.0), S0, 80.0, T):.2f}%)  $120 {at(c, 120.0):.4f} ({100 * implied(at(c, 120.0), S0, 120.0, T):.2f}%)")
assert max(abs(a - b) for a, b in zip(grid, surf)) < 0.005 and gap6 < 0.005   # the grid gives the surface back
assert all(abs(a - b) < 0.1 for a, b in zip(mc, surf))                        # so do the simulated paths
assert abs(mc[4] - 9.227005508154) < 3.0 * se(1) + 0.005                      # the house call: 3 s.e. and half a cent
assert abs(mcfs[4] - fsg[4]) < 3.0 * se(2) + 0.005                            # two roads to the forward start
assert abs(2 * exp(-R * T) * acc[6] / PATHS - fwd(1.0, SIG)) < 3.0 * se(3)         # the control is honest
assert fsg[4] < fwd(1.0, SIG) - 0.1 and mcfs[4] < fwd(1.0, SIG) - 0.1         # both below the flat value
assert fvol(fsg[2], 0.9) - fvol(fsg[6], 1.1) < 0.7 * (ivol(90.0, T1) - ivol(110.0, T1))   # forward smile flatter
assert abs(avg[2] / avg[3] - fvol(fsg[4], 1.0)) < 5e-4 and avg[0] / avg[1] > avg[2] / avg[3] + 0.005   # Step 7's weighting
assert all(abs(twin(k)[3] - twin(k)[4]) < 5e-4 for k in (70.0, 100.0, 140.0)) # Gyongy: two roads, one twin
print("ALL CHECKS PASS")
