# The VIX recipe on the house index: Cboe's discrete strip, two expiries, 30-day blend.
# Roads: 1 the exchange's discrete sum, 2 a fine Simpson integral of the strip, 3 the
# density read off call prices (second difference) averaged against the log payoff.
from math import exp, log, sqrt, pi

S, r, q = 100.0, 0.05, 0.02          # house index level, rate, dividend yield
N1, N2, N30, N365 = 23, 37, 30, 365  # days to the two expiries, target, days per year
T1, T2 = N1 / N365, N2 / N365
CUT = 0.001                          # an option worth under a tenth of a cent has a zero bid

def ncdf(x):                         # normal CDF by Marsaglia's series, no library
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, n = x, x, 1
    while abs(t) > 1e-17 * abs(s):
        n += 2; t *= x * x / n; s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)

def flat(k): return 0.20
def skew(k): return sqrt(0.0325 + 0.15 * (-0.7 * k + sqrt(k * k + 0.0025)))  # 20% at k = 0

def fwd(T): return S * exp((r - q) * T)
def price(K, T, vol, call):          # Black-Scholes on the forward, vol read at k = ln(K/F)
    F = fwd(T); sd = vol(log(K / F)) * sqrt(T)
    d1 = (log(F / K) + 0.5 * sd * sd) / sd; d2 = d1 - sd
    if call: return exp(-r * T) * (F * ncdf(d1) - K * ncdf(d2))
    return exp(-r * T) * (K * ncdf(-d2) - F * ncdf(-d1))

def listed(wide=False):             # $0.10 apart from 80 to 120 and $0.50 outside; or $5 everywhere
    if wide: return [10 + 5.0 * i for i in range(49)]
    return ([10 + 0.5 * i for i in range(140)] + [(800 + i) / 10 for i in range(400)]
            + [120 + 0.5 * i for i in range(261)])

def cboe(T, vol, Ks=None, fix=True, cut=CUT, itm=False):
    Ks = Ks or listed()
    C = [price(K, T, vol, True) for K in Ks]; P = [price(K, T, vol, False) for K in Ks]
    j = min(range(len(Ks)), key=lambda i: abs(C[i] - P[i]))      # where call and put are closest
    F = Ks[j] + exp(r * T) * (C[j] - P[j])                        # parity gives the forward
    i0 = max(i for i in range(len(Ks)) if Ks[i] <= F); K0 = Ks[i0]
    use = [i0]
    for step in (-1, 1):                 # walk outward; stop after two zero bids in a row
        i, zeros = i0 + step, 0
        while 0 <= i < len(Ks) and zeros < 2:
            if (P[i] if step < 0 else C[i]) < cut: zeros += 1
            else: zeros = 0; use.append(i)
            i += step
    use.sort(); total = 0.0
    for n, i in enumerate(use):
        K = Ks[i]; Q = C[i] if K > K0 or (itm and K < K0) else P[i] if K < K0 else 0.5 * (P[i] + C[i])
        lo = Ks[use[max(n - 1, 0)]]; hi = Ks[use[min(n + 1, len(use) - 1)]]
        dK = (hi - lo) / (2 if 0 < n < len(use) - 1 else 1)
        total += dK / (K * K) * exp(r * T) * Q
    corr = (F / K0 - 1) ** 2 / T
    return dict(F=F, K0=K0, n=len(use), lo=Ks[use[0]], hi=Ks[use[-1]], strip=2 * total / T,
                corr=corr, var=2 * total / T - (corr if fix else 0.0))

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def strip_integral(T, vol):          # (2 e^{rT}/T) * integral of Q(K)/K^2, K = F e^u, exact F
    F = fwd(T)
    put = lambda u: price(F * exp(u), T, vol, False) * exp(-u) / F
    call = lambda u: price(F * exp(u), T, vol, True) * exp(-u) / F
    return 2 * exp(r * T) / T * (simpson(put, -3.0, 0.0, 3000) + simpson(call, 0.0, 3.0, 3000))

def density_road(T, vol):            # q(K) = e^{rT} C''(K); average 2/T (K/F - 1 - ln K/F)
    F = fwd(T)
    def g(u):
        K = F * exp(u); h = 2e-4 * K
        dens = exp(r * T) * (price(K + h, T, vol, True) - 2 * price(K, T, vol, True)
                             + price(K - h, T, vol, True)) / (h * h)
        return dens * (K / F - 1 - u) * K          # dK = K du
    bad = sum(1 for i in range(1, 460) if price(20 + 0.5 * i - 0.5, T, vol, True) - 2 * price(20 + 0.5 * i, T, vol, True)
              + price(20 + 0.5 * i + 0.5, T, vol, True) < -1e-12)   # butterflies must not cost less than zero
    return 2 / T * simpson(g, -3.0, 3.0, 6000), bad

def vix(v1, v2, by_vol=False):       # interpolate in total variance to 30 days, annualise
    w1 = (N2 - N30) / (N2 - N1)
    if by_vol: return 100 * (w1 * sqrt(v1) + (1 - w1) * sqrt(v2))
    return 100 * sqrt((T1 * v1 * w1 + T2 * v2 * (1 - w1)) * N365 / N30)

rows = {}
for name, vol in (("flat", flat), ("skew", skew)):
    for T, lab in ((T1, "23d"), (T2, "37d")):
        c = cboe(T, vol); d, bad = density_road(T, vol)
        rows[name + " " + lab] = (T, c["F"], fwd(T), c["K0"], c["n"], c["lo"], c["hi"], c["strip"], c["corr"],
                                  c["var"], strip_integral(T, vol), d, bad)
labels = ("years to expiry T", "forward by parity", "forward S e^(r-q)T", "K0, strike below F", "strikes used", "lowest strike used",
          "highest strike used", "strip term (2/T) sum", "correction (F/K0-1)^2/T", "1 Cboe variance",
          "2 Simpson strip variance", "3 density road variance", "negative butterflies")
print(f"{'house index, per expiry':<26}" + "".join(f"{k:>11}" for k in rows))
for i, lab in enumerate(labels):
    print(f"{lab:<26}" + "".join((f"{v[i]:>11.0f}" if i in (4, 12) else f"{v[i]:>11.6f}") for v in rows.values()))

vx = {}
for name, vol in (("flat", flat), ("skew", skew)):
    a, b = rows[name + " 23d"], rows[name + " 37d"]
    vx[name] = [vix(a[9], b[9]), vix(a[10], b[10]), vix(a[11], b[11])]
print()
print(f"weights on 23d and 37d: {(N2 - N30) / (N2 - N1):.2f} and {(N30 - N1) / (N2 - N1):.2f}")
for name in vx:
    w1 = (N2 - N30) / (N2 - N1)
    p1, p2 = T1 * rows[name + " 23d"][9] * w1, T2 * rows[name + " 37d"][9] * (1 - w1)
    print(f"{name} blend: 23d part {p1:.6f}  37d part {p2:.6f}  times 365/30 {(p1 + p2) * N365 / N30:.6f}")
    print(f"{name} VIX: 1 Cboe {vx[name][0]:.4f}   2 Simpson {vx[name][1]:.4f}   3 density {vx[name][2]:.4f}")
print(f"at-the-money vol on both surfaces: {100 * skew(0.0):.4f}   30-day forward {fwd(N30 / N365):.4f}")

def broke(vol, **kw):
    return vix(cboe(T1, vol, **kw)["var"], cboe(T2, vol, **kw)["var"])
print()
print(f"wrong: in-the-money calls below K0, flat {broke(flat, itm=True):.4f}")
print(f"wrong: strikes $5 apart, flat            {broke(flat, Ks=listed(True)):.4f}")
print(f"wrong: strikes $5 apart, skew            {broke(skew, Ks=listed(True)):.4f}")
print(f"wrong: blend vols not variances, skew    {vix(rows['skew 23d'][9], rows['skew 37d'][9], True):.4f}")
print(f"wrong: 23-day strip alone, skew          {100 * sqrt(rows['skew 23d'][9]):.4f}")
print(f"try: keep near-zero bids too, skew       {broke(skew, cut=0.0):.4f}")
print(f"try: drop the (F/K0-1)^2 term, flat      {broke(flat, fix=False):.4f}")

print()
chart = [80 + 5 * i for i in range(9)]
F30 = fwd(N30 / N365)
print("chart, strike           " + " ".join(f"{K:6.0f}" for K in chart))
print("chart, skew vol %, 30d  " + " ".join(f"{100 * skew(log(K / F30)):6.2f}" for K in chart))
for name, vol in (("flat", flat), ("skew", skew)):
    F = fwd(T1)
    w = [2 * exp(r * T1) / T1 * price(K, T1, vol, K > F) / (K * K) * 1e4 for K in chart]
    print(f"chart, {name} weight x1e4 " + " ".join(f"{x:6.2f}" for x in w))

f23, s23 = rows["flat 23d"], rows["skew 23d"]
assert abs(f23[1] - f23[2]) < 1e-9, "parity forward must equal S e^(r-q)T"
assert abs(rows["flat 37d"][10] - 0.04) < 1e-7, "Simpson strip on a flat 20% surface must give 0.04"
assert abs(s23[10] - s23[11]) < 1e-6, "23-day strip integral vs density road"
assert abs(rows["skew 37d"][10] - rows["skew 37d"][11]) < 1e-6, "37-day strip integral vs density road"
assert abs(vx["flat"][0] - 20.0) < 0.005, "Cboe recipe on the flat surface must print 20.00"
assert abs(vx["skew"][0] - vx["skew"][1]) < 0.01, "discrete recipe within a hundredth of the integral"
assert vx["skew"][0] > 100 * skew(0.0) + 0.5, "skew must lift the VIX above the at-the-money vol"
e = lambda fix: abs(cboe(T1, flat, Ks=[0.4 + i for i in range(1, 300)], fix=fix)["var"] - f23[10])
assert e(True) < e(False) / 3, "on $1 strikes with K0 = 99.40 the (F/K0-1)^2 term must cut the error"
print("ALL CHECKS PASS")
