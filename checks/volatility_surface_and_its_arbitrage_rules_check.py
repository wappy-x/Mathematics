# The volatility surface: assemble quotes, interpolate total variance against
# log-moneyness, test butterflies and calendars, repair a bad point.
from math import exp, log, sqrt, pi

S, r, q = 100.0, 0.05, 0.02                        # house market: spot, rate, dividend yield
KS = [80.0 + 5.0 * i for i in range(9)]            # strikes 80, 85, ..., 120
TS = [0.25, 0.5, 1.0]                              # expiries in years
QUOTES = {0.25: [28.61, 24.77, 21.61, 19.05, 17.00, 15.39, 14.17, 13.28, 12.69],  # implied vols, %
          0.5: [27.43, 24.38, 21.84, 19.73, 18.00, 16.59, 15.47, 14.60, 13.95],
          1.0: [27.79, 25.33, 23.24, 21.48, 20.00, 18.76, 17.74, 16.90, 16.22]}

def N(x):                                          # normal CDF, Marsaglia's series
    if abs(x) > 8.0:
        return 1.0 if x > 0 else 0.0
    s, t, n = x, x, 1
    while abs(t) > 1e-17:
        t *= x * x / (2 * n + 1); s += t; n += 1
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2 * pi)

def fwd(T): return S * exp((r - q) * T)

def call(K, T, vol):                               # Black-Scholes call, vol as a decimal
    F, v = fwd(T), vol * sqrt(T)
    d1 = (log(F / K) + 0.5 * v * v) / v
    return exp(-r * T) * (F * N(d1) - K * N(d1 - v))

def implied(price, K, T):                          # bisection: price rises strictly with vol
    lo, hi = 1e-4, 3.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if call(K, T, mid) < price else (lo, mid)
    return 0.5 * (lo + hi)

def nodes(T, vols):                                # (log-moneyness k, total variance w) per quote
    return [log(K / fwd(T)) for K in KS], [T * (v / 100) ** 2 for v in vols]

def interp(ks, ws, k):                             # linear in k; None outside the quoted range
    for i in range(len(ks) - 1):
        if ks[i] - 1e-12 <= k <= ks[i + 1] + 1e-12:
            return ws[i] + (ws[i + 1] - ws[i]) * (k - ks[i]) / (ks[i + 1] - ks[i])
    return None

def butterflies(T, vols):                          # road 1: price of the 1-2-1 butterfly, 5 wide
    c = [call(K, T, v / 100) for K, v in zip(KS, vols)]
    return [c[i - 1] - 2 * c[i] + c[i + 1] for i in range(1, 8)]

def durrleman(T, vols):                            # road 2: density from w, w', w'' (no prices)
    ks, ws = nodes(T, vols); out = []
    for i in range(1, 8):
        h1, h2, w = ks[i] - ks[i - 1], ks[i + 1] - ks[i], ws[i]
        w1 = (-h2 * ws[i - 1] / (h1 * (h1 + h2)) + (h2 - h1) * w / (h1 * h2)
              + h1 * ws[i + 1] / (h2 * (h1 + h2)))
        w2 = 2 * (h2 * ws[i - 1] - (h1 + h2) * w + h1 * ws[i + 1]) / (h1 * h2 * (h1 + h2))
        g = (1 - ks[i] * w1 / (2 * w)) ** 2 - w1 * w1 / 4 * (1 / w + 0.25) + w2 / 2
        d2 = -ks[i] / sqrt(w) - sqrt(w) / 2
        out.append(g * exp(-0.5 * d2 * d2) / sqrt(2 * pi) / (KS[i] * sqrt(w)))
    return out

def calendar(Ts, vs, Tl, vl):                      # at every node k both slices cover
    ks, ws = nodes(Ts, vs); kl, wl = nodes(Tl, vl); rows = []
    for k in sorted(set(ks + kl)):
        a, b = interp(ks, ws, k), interp(kl, wl, k)
        if a is not None and b is not None:        # road 2: forward-normalised call, dollars / (D F)
            cs = call(fwd(Ts) * exp(k), Ts, sqrt(a / Ts)) / (exp(-r * Ts) * fwd(Ts))
            cl = call(fwd(Tl) * exp(k), Tl, sqrt(b / Tl)) / (exp(-r * Tl) * fwd(Tl))
            rows.append((k, b - a, cl - cs, sqrt(b / Tl) - sqrt(a / Ts)))
    return rows

f = lambda xs, d=4: " ".join(f"{x:8.{d}f}" for x in xs)
print("strike        " + f(KS, 0))
for T in TS:
    print(f"vol % T={T:<4}   " + f(QUOTES[T], 2) + f"   forward {fwd(T):.4f}")
print("call $ T=1.0   " + f([call(K, 1.0, v / 100) for K, v in zip(KS, QUOTES[1.0])]))
for T in TS:
    print(f"w x100 T={T:<4}  " + f([100 * w for w in nodes(T, QUOTES[T])[1]]))
# -- butterfly test, clean surface, two roads
for T in TS:
    b, d = butterflies(T, QUOTES[T]), durrleman(T, QUOTES[T])
    gap = max(abs(x * exp(r * T) / 25 / y - 1) for x, y in zip(b, d))
    print(f"clean T={T:<4} min butterfly {min(b):.4f}  min density {min(d):.5f}  roads differ <= {100 * gap:.1f}%")
# -- plant a dip: 1-year 100-strike quoted 18.0 instead of 20.0
dip = QUOTES[1.0][:4] + [18.0] + QUOTES[1.0][5:]
b, d = butterflies(1.0, dip), durrleman(1.0, dip)
dp = [x * exp(r) / 25 for x in b]
print("dip   strikes   " + f(KS[1:8], 0))
print("dip   butterfly " + f(b)); print("dip   dens price" + f(dp, 5)); print("dip   dens w    " + f(d, 5))
# -- repair: the band the 100 quote must sit in, and the refill from total variance
c = [call(K, 1.0, v / 100) for K, v in zip(KS, dip)]
lo, hi = max(2 * c[3] - c[2], 2 * c[5] - c[6]), 0.5 * (c[3] + c[5])
vlo, vhi = implied(lo, 100.0, 1.0), implied(hi, 100.0, 1.0)
ks, ws = nodes(1.0, dip)
wfill = ws[3] + (ws[5] - ws[3]) * (ks[4] - ks[3]) / (ks[5] - ks[3])
vfill = 100 * sqrt(wfill)
fixed = dip[:4] + [vfill] + dip[5:]
print(f"band price {lo:.4f} to {hi:.4f}  vol {100 * vlo:.4f} to {100 * vhi:.4f}  dipped price {c[4]:.4f}")
bf_fix = butterflies(1.0, fixed)
print(f"refill vol {vfill:.4f}  butterflies 95/100/105 after {bf_fix[2]:.4f} {bf_fix[3]:.4f} {bf_fix[4]:.4f}")
# -- calendar test, clean surface, then with the 6-month row keyed 10 points high
for Ts, Tl, vs in ((0.25, 0.5, QUOTES[0.5]), (0.5, 1.0, QUOTES[1.0])):
    rows = calendar(Ts, QUOTES[Ts], Tl, vs)
    print(f"clean {Ts}->{Tl}: min w gap {min(x[1] for x in rows):.5f}  min price gap {min(x[2] for x in rows):.5f}"
          f"  vol falls at {sum(x[3] < 0 for x in rows)} of {len(rows)} nodes")
lift = [v + 10.0 for v in QUOTES[0.5]]
rows = calendar(0.5, lift, 1.0, QUOTES[1.0])
print("lift  k       " + f([x[0] for x in rows if x[1] < 0]))
print("lift  w gap   " + f([x[1] for x in rows if x[1] < 0], 5))
print("lift  price gp" + f([x[2] for x in rows if x[2] < 0], 5))
up = [0.5 * lift[i] ** 2 > QUOTES[1.0][i] ** 2 for i in range(9)]    # wrong road: same strike
print(f"same-strike test flags {sum(up)} of 9: " + " ".join(f"{K:.0f}" for K, u in zip(KS, up) if u))
fv = lambda w6, w1: (w1 - w6) / 0.5                # forward variance, 6 months to 1 year
w6a, w1a, w6l = nodes(0.5, QUOTES[0.5])[1][4], nodes(1.0, QUOTES[1.0])[1][4], nodes(0.5, lift)[1][4]
same_k = fv(w6l, interp(*nodes(1.0, QUOTES[1.0]), log(100.0 / fwd(0.5))))
print(f"forward var 6m-1y clean {fv(w6a, w1a):.6f} (vol {100 * sqrt(fv(w6a, w1a)):.4f})"
      f"  lifted: same strike {fv(w6l, w1a):.6f}  same k {same_k:.6f}")
# -- a 9-month vol at strike 100, between the rows
k9 = log(100.0 / fwd(0.75))
w6, w1 = interp(*nodes(0.5, QUOTES[0.5]), k9), interp(*nodes(1.0, QUOTES[1.0]), k9)
w9, naive = w6 + (w1 - w6) * 0.5, 0.5 * (QUOTES[0.5][4] + QUOTES[1.0][4])
print(f"9-month K=100: k {k9:.4f}  w6 {w6:.5f}  w1 {w1:.5f}  vol {100 * sqrt(w9 / 0.75):.4f}  naive vol {naive:.4f}")
# -- chart rows: total variance x100 on a shared k grid
grid = [-0.20 + 0.05 * i for i in range(8)]
print("chart k       " + f(grid, 2))
for lab, T, v in (("3m", 0.25, QUOTES[0.25]), ("6m", 0.5, QUOTES[0.5]), ("1y", 1.0, QUOTES[1.0]), ("6m+10", 0.5, lift)):
    print(f"chart w {lab:<6}" + f([100 * interp(*nodes(T, v), k) for k in grid], 2))
dens = lambda v: [100 * x * exp(r) / 25 for x in butterflies(1.0, v)]
for lab, v in (("clean", QUOTES[1.0]), ("dip", dip), ("refill", fixed)):
    print(f"chart dens {lab:<7}" + f(dens(v), 2))
assert abs(call(100.0, 1.0, 0.20) - 9.227005508154) < 1e-9, "house call from the pilot card"
assert abs(sqrt(fv(w6a, w1a)) - 0.2182) < 5e-5, "house forward vol 21.82%"
assert all(min(butterflies(T, QUOTES[T]) + durrleman(T, QUOTES[T])) > 0 for T in TS), "clean slices pass"
assert all(abs(x * exp(r * T) / 25 / y - 1) < 0.15 for T in TS
           for x, y in zip(butterflies(T, QUOTES[T]), durrleman(T, QUOTES[T]))), "two density roads agree"
assert [i for i, x in enumerate(b) if x < 0] == [i for i, x in enumerate(d) if x < 0] == [2, 4], "95 and 105"
assert 18.0 < 100 * vlo < 20.0 < vfill < 100 * vhi, "band from prices holds clean and refilled quote"
assert all(abs(min(butterflies(1.0, dip[:4] + [100 * v] + dip[5:])[2:5])) < 1e-9 for v in (vlo, vhi)), "band edge: a butterfly hits 0"
assert [x[1] < 0 for x in rows] == [x[2] < 0 for x in rows], "calendar: variance and price roads agree"
assert sum(x[1] < 0 for x in rows) == 9 and sum(up) == 4, "same forward moneyness sees more than same strike"
print("ALL CHECKS PASS")
