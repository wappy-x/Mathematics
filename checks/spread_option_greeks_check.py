# Greeks of a spread option -- the check behind the card.  Standard library only.
# Nothing imported holds an answer: the bell-curve area is a series written out
# here, the integral is Simpson's rule, the random numbers come from splitmix64.
from math import exp, log, sqrt, pi, cos
F1, F2, S1, S2, RHO, T, R = 100.0, 90.0, 0.30, 0.25, 0.5, 0.5, 0.05   # house crack
D = exp(-R * T)                                             # discount factor to expiry

def n(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)         # bell-curve height
def N(x):                                                   # bell-curve area left of x
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):                   # x + x^3/3 + x^5/(3*5) + ...
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + n(x) * total

def spread_vol(s1, s2, rho): return sqrt(s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2)
def margrabe(f1, f2, s1=S1, s2=S2, rho=RHO):               # road 1: the closed form
    v = spread_vol(s1, s2, rho) * sqrt(T)
    d1 = (log(f1 / f2) + 0.5 * v * v) / v
    return D * (f1 * N(d1) - f2 * N(d1 - v))
def greeks(f1, f2, s1=S1, s2=S2, rho=RHO):                 # closed-form Greeks
    s = spread_vol(s1, s2, rho); v = s * sqrt(T)
    d1 = (log(f1 / f2) + 0.5 * v * v) / v; d2 = d1 - v
    dvs = D * f1 * n(d1) * sqrt(T)                          # dV / d(spread vol)
    return {"delta gasoline": D * N(d1), "delta crude": -D * N(d2),
            "gamma 11": D * n(d1) / (f1 * v), "gamma 12": -D * n(d1) / (f2 * v),
            "gamma 22": D * n(d1) * f1 / (f2 * f2 * v),
            "vega gasoline": dvs * (s1 - rho * s2) / s, "vega crude": dvs * (s2 - rho * s1) / s,
            "corr sensitivity": -dvs * s1 * s2 / s}
def kirk(f1, f2, K, s1=S1, s2=S2, rho=RHO):                # Kirk's approximation
    b = f2 / (f2 + K); v = sqrt(s1 * s1 - 2 * rho * s1 * s2 * b + s2 * s2 * b * b) * sqrt(T)
    d1 = (log(f1 / (f2 + K)) + 0.5 * v * v) / v
    return D * (f1 * N(d1) - (f2 + K) * N(d1 - v))
def exact(f1, f2, K, s1=S1, s2=S2, rho=RHO, m=400):        # road 2: fix crude's shock z,
    def given(z):                                           # then gasoline is lognormal: Black
        c2 = f2 * exp(-0.5 * s2 * s2 * T + s2 * sqrt(T) * z) + K
        c1 = f1 * exp(-0.5 * rho * rho * s1 * s1 * T + rho * s1 * sqrt(T) * z)
        w = s1 * sqrt(1.0 - rho * rho) * sqrt(T)
        e1 = (log(c1 / c2) + 0.5 * w * w) / w
        return (c1 * N(e1) - c2 * N(e1 - w)) * n(z)
    a, h = -9.0, 18.0 / m                                   # Simpson's rule over z
    tot = given(a) + given(-a) + sum((4 if i % 2 else 2) * given(a + i * h) for i in range(1, m))
    return D * tot * h / 3.0
def bumped(p, K):                                           # Greeks by bump-and-reprice
    h, e = 0.1, 1e-4
    V = lambda a=0.0, b=0.0, **kw: p(F1 + a, F2 + b, K, **kw)
    return {"delta gasoline": (V(h) - V(-h)) / (2 * h), "delta crude": (V(0, h) - V(0, -h)) / (2 * h),
            "gamma 11": (V(h) - 2 * V() + V(-h)) / h ** 2,
            "gamma 12": (V(h, h) - V(h, -h) - V(-h, h) + V(-h, -h)) / (4 * h * h),
            "gamma 22": (V(0, h) - 2 * V() + V(0, -h)) / h ** 2,
            "vega gasoline": (V(s1=S1 + e) - V(s1=S1 - e)) / (2 * e),
            "vega crude": (V(s2=S2 + e) - V(s2=S2 - e)) / (2 * e),
            "corr sensitivity": (V(rho=RHO + e) - V(rho=RHO - e)) / (2 * e)}
mar3 = lambda f1, f2, K, **kw: margrabe(f1, f2, **kw)      # Margrabe with a dummy strike slot

state = [20260927]                                          # splitmix64, then Box-Muller
def unif():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
def hedge_sim(rho_real, paths=2000, steps=63):             # road 3: sell, hedge both legs daily-ish
    dt, pnl, raw = T / steps, [], []
    for _ in range(paths):
        f1, f2, cash = F1, F2, margrabe(F1, F2)
        for k in range(steps):
            t_left = T - k * dt
            v = spread_vol(S1, S2, RHO) * sqrt(t_left)
            d1 = (log(f1 / f2) + 0.5 * v * v) / v
            a1, a2 = exp(-R * t_left) * N(d1), -exp(-R * t_left) * N(d1 - v)
            g1 = gauss(); g2 = rho_real * g1 + sqrt(1 - rho_real ** 2) * gauss()
            n1 = f1 * exp(-0.5 * S1 * S1 * dt + S1 * sqrt(dt) * g1)
            n2 = f2 * exp(-0.5 * S2 * S2 * dt + S2 * sqrt(dt) * g2)
            cash = cash * exp(R * dt) + a1 * (n1 - f1) + a2 * (n2 - f2)
            f1, f2 = n1, n2
        pnl.append(D * (cash - max(f1 - f2, 0.0))); raw.append(margrabe(F1, F2) - D * max(f1 - f2, 0.0))
    se = lambda xs, mu: sqrt(sum((x - mu) ** 2 for x in xs) / (paths - 1) / paths)
    mu = sum(pnl) / paths; return mu, se(pnl, mu), se(raw, sum(raw) / paths)   # hedged, unhedged se

P = print
def row(lab, *v): P(f"{lab:<32}" + "".join(f"{x:12.6f}" for x in v))
V0, G, sv = margrabe(F1, F2), greeks(F1, F2), spread_vol(S1, S2, RHO) * sqrt(T)
Gm, Gx, d1 = bumped(mar3, 0.0), bumped(exact, 0.0), (log(F1 / F2) + 0.5 * sv * sv) / sv
P("house crack: F1 100, F2 90, vols 0.30 0.25, corr 0.5, T 0.5, r 0.05; sim 2000 paths x 63 hedges")
row("spread vol sigma", spread_vol(S1, S2, RHO)); row("D = e^-rT, v = sigma*sqrt(T)", D, sv)
row("d1, d2", d1, d1 - sv); row("N(d1), N(d2), n(d1)", N(d1), N(d1 - sv), n(d1))
sg = spread_vol(S1, S2, RHO); row("ln(F1/F2), sigma^2, v^2/2", log(F1 / F2), sg * sg, 0.5 * sv * sv)
row("dV/dsigma, dsigma/ds1, ds2, drho", D * F1 * n(d1) * sqrt(T), (S1 - RHO * S2) / sg, (S2 - RHO * S1) / sg, -S1 * S2 / sg)
row("price  Margrabe formula", V0); row("price  integral over crude", exact(F1, F2, 0.0))
P(f"{'greek at K = 0':<20}{'closed form':>12}{'bump formula':>14}{'bump integral':>15}")
for k in G: P(f"{k:<20}{G[k]:12.6f}{Gm[k]:14.6f}{Gx[k]:15.6f}")
euler, bridge = F1 * G["delta gasoline"] + F2 * G["delta crude"], S1 * S2 * T * F1 * F2 * G["gamma 12"]
row("F1*delta1 + F2*delta2", euler); row("F1*gamma11 + F2*gamma12", F1 * G["gamma 11"] + F2 * G["gamma 12"])
row("s1*s2*T*F1*F2*gamma12", bridge)
book = lambda f1, f2, rho=RHO: -(margrabe(f1, f2, rho=rho) - V0) + G["delta gasoline"] * (f1 - F1) + G["delta crude"] * (f2 - F2)
P("hedged short book, instant moves (USD per bbl of spread)")
row("  both legs +5%", book(105.0, 94.5)); row("  both legs +5 USD", book(105.0, 95.0))
row("  gasoline +5%, crude -5%", book(105.0, 85.5))
row("  gamma estimate of that", -0.5 * (G["gamma 11"] * 25 + 2 * G["gamma 12"] * 5 * -4.5 + G["gamma 22"] * 4.5 ** 2))
row("  correlation 0.5 -> 0.3", book(F1, F2, 0.3)); row("  corr sensitivity x 0.2", G["corr sensitivity"] * 0.2)
xs, rs = range(0, 9, 2), [i / 10 for i in range(0, 11, 2)]
P("chart, move x %           " + "".join(f"{x:8d}" for x in xs))
P("chart, together +x/+x     " + "".join(f"{book(F1 * (1 + x / 100), F2 * (1 + x / 100)):8.2f}" for x in xs))
P("chart, apart +x/-x        " + "".join(f"{book(F1 * (1 + x / 100), F2 * (1 - x / 100)):8.2f}" for x in xs))
P("chart, correlation        " + "".join(f"{x:8.1f}" for x in rs))
P("chart, Margrabe K = 0     " + "".join(f"{margrabe(F1, F2, rho=x):8.2f}" for x in rs))
P("chart, Kirk K = 10        " + "".join(f"{kirk(F1, F2, 10.0, rho=x):8.2f}" for x in rs))
Gk, Ge = bumped(kirk, 10.0), bumped(exact, 10.0)
P(f"{'strike K = 10':<20}{'Kirk bump':>12}{'exact bump':>14}")
P(f"{'price':<20}{kirk(F1, F2, 10.0):12.6f}{exact(F1, F2, 10.0):14.6f}")
for k in G: P(f"{k:<20}{Gk[k]:12.6f}{Ge[k]:14.6f}")
kbridge = S1 * S2 * T * F1 * F2 * Ge["gamma 12"]; row("K=10 s1*s2*T*F1*F2*gamma12", kbridge)
(m5, e5, u5), (m2, e2, u2) = hedge_sim(0.5), hedge_sim(0.2)
P(f"sim: realised corr 0.5, mean    {m5:12.6f}  se {e5:.6f}  unhedged se {u5:.6f}")
P(f"sim: realised corr 0.2, mean    {m2:12.6f}  se {e2:.6f}  unhedged se {u2:.6f}")
row("price at 0.5 minus price at 0.2", V0 - margrabe(F1, F2, rho=0.2))
w_d2, w_plus, w_nodisc = D * N(d1 - sv), margrabe(F1, F2, rho=-RHO), G["delta gasoline"] / D
w_same = book(105.0, 94.5) - (G["delta crude"] + G["delta gasoline"]) * 4.5
row("wrong: N(d2) as gasoline delta", w_d2); row("wrong: +2 rho s1 s2, price", w_plus)
row("wrong: no discount, delta", w_nodisc); row("wrong: crude hedge = -delta1", w_same)
row("try: rho 0.9, vega crude", greeks(F1, F2, rho=0.9)["vega crude"])
row("try: crude 100, delta gasoline", greeks(F1, 100.0)["delta gasoline"])
assert abs(V0 - exact(F1, F2, 0.0)) < 1e-8, "Margrabe vs integral over crude"
for k in G: assert abs(G[k] - Gx[k]) < 2e-4 * max(1.0, abs(G[k])), "closed-form Greek vs bumped integral: " + k
assert abs(euler - exact(F1, F2, 0.0)) < 1e-8, "deltas rebuild the price (Euler)"
assert abs(kbridge - Ge["corr sensitivity"]) < 1e-3, "bridge: corr sensitivity = s1 s2 T F1 F2 gamma12, K=10"
assert abs(m5) < 4 * e5 + 0.02 and m2 < -1.0 and e5 < 0.1 * u5 and e2 < 0.1 * u2, "hedged book: flat at the priced correlation, loses when legs decouple"
assert abs(w_d2 - G["delta gasoline"]) > 0.05 and abs(w_plus - V0) > 1 and abs(w_same) > 0.1, "each mistake moves a number"
P("ALL CHECKS PASS")
