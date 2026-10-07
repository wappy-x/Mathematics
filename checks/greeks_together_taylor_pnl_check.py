# The Greeks together -- the check behind the card.  Standard library only.
# The house call is repriced after a day with spot +5 and vol +1 point, and the
# move is estimated from stored Greeks.  Roads: closed-form Greeks, Greeks by
# bump-and-reprice, the price by formula and by a bell-curve integral, and the
# cube law predicted from a third derivative taken along the move.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x):                                                   # bell-curve area, own series
    term, total, n = x, x, 0                                # 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def call(S, sg, T, r, K=100.0, q=0.02):                     # Black-Scholes call
    d1 = (log(S / K) + (r - q + 0.5 * sg * sg) * T) / (sg * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sg * sqrt(T))

def call_integral(S, sg, T, r, K=100.0, q=0.02, n=20000):  # payoff averaged by Simpson
    a, b = -10.0, 10.0; h = (b - a) / n
    f = lambda z: max(S * exp((r - q - 0.5 * sg * sg) * T + sg * sqrt(T) * z) - K, 0.0) * phi(z)
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-r * T) * s * h / 3.0

S, sg, T, r, K, q = 100.0, 0.20, 1.0, 0.05, 100.0, 0.02
d1 = (log(S / K) + (r - q + 0.5 * sg * sg) * T) / (sg * sqrt(T)); d2 = d1 - sg * sqrt(T)
eq, er, rt = exp(-q * T), exp(-r * T), sqrt(T)
G = {"delta": eq * N(d1), "gamma": eq * phi(d1) / (S * sg * rt), "vega": S * eq * phi(d1) * rt,
     "theta": -S * eq * phi(d1) * sg / (2 * rt) - r * K * er * N(d2) + q * S * eq * N(d1),
     "rho": K * T * er * N(d2), "vanna": -eq * phi(d1) * d2 / sg,
     "volga": S * eq * phi(d1) * rt * d1 * d2 / sg,
     "charm": q * eq * N(d1) - eq * phi(d1) * (2 * (r - q) * T - d2 * sg * rt) / (2 * T * sg * rt)}
V = lambda s=S, v=sg, t=0.0, rr=r: call(s, v, T - t, rr)   # t = calendar time elapsed
hs, hv, ht, hr = 0.01, 1e-3, 1e-4, 1e-4
B = {"delta": (V(S + hs) - V(S - hs)) / (2 * hs), "gamma": (V(S + hs) - 2 * V() + V(S - hs)) / hs**2,
     "vega": (V(v=sg + hv) - V(v=sg - hv)) / (2 * hv), "theta": (V(t=ht) - V(t=-ht)) / (2 * ht),
     "rho": (V(rr=r + hr) - V(rr=r - hr)) / (2 * hr),
     "vanna": (V(S + hs, sg + hv) - V(S + hs, sg - hv) - V(S - hs, sg + hv) + V(S - hs, sg - hv)) / (4 * hs * hv),
     "volga": (V(v=sg + hv) - 2 * V() + V(v=sg - hv)) / hv**2,
     "charm": (V(S + hs, t=ht) - V(S - hs, t=ht) - V(S + hs, t=-ht) + V(S - hs, t=-ht)) / (4 * hs * ht)}

def terms(g, dS, dv, dt, dr=0.0):                           # the card's formula, term by term
    return [("delta x dS", g["delta"] * dS), ("1/2 gamma x dS^2", 0.5 * g["gamma"] * dS * dS),
            ("vega x dsigma", g["vega"] * dv), ("theta x dt", g["theta"] * dt), ("rho x dr", g["rho"] * dr),
            ("vanna x dS x dsigma", g["vanna"] * dS * dv), ("1/2 volga x dsigma^2", 0.5 * g["volga"] * dv * dv)]

dS, dv, dt = 5.0, 0.01, 1 / 365
V0 = V()
exact = V(S + dS, sg + dv, dt) - V0
exact_int = call_integral(S + dS, sg + dv, T - dt, r) - call_integral(S, sg, T, r)
tm, tmB = terms(G, dS, dv, dt), terms(B, dS, dv, dt)
est, estB = sum(v for _, v in tm), sum(v for _, v in tmB)
dgv = tm[0][1] + tm[1][1] + tm[2][1]
def p(lab, *vals): print(f"{lab:<38}" + "".join(f" {v:>11.6f}" for v in vals))
p("price today: formula, integral", V0, call_integral(S, sg, T, r))
print("greek: closed form, by bump")
for k in G: p("  " + k, G[k], B[k])
print("move: spot +5, vol +1 point, one day, term by term")
for lab, v in tm: p(lab, v)
p("charm x dS x dt (dropped)", G["charm"] * dS * dt)
p("estimate: closed-form, bumped Greeks", est, estB)
p("exact reprice: formula, integral", exact, exact_int)
p("error, exact - estimate", exact - est)
print("terms kept: estimate, estimate - exact")
for lab, v in (("delta only", tm[0][1]), ("delta-gamma", tm[0][1] + tm[1][1]), ("delta-gamma-vega", dgv),
               ("plus theta", dgv + tm[3][1]), ("all seven", est)): p("  " + lab, v, v - exact)
p("delta term share of estimate", tm[0][1] / est)
p("typical day's move, sigma S sqrt(dt)", sg * S * sqrt(dt))
p("wrong: no 1/2 on gamma", est + tm[1][1]); p("wrong: vol point as 1", est - tm[2][1] + G["vega"])
p("wrong: theta x 1 (day as 1)", est - tm[3][1] + G["theta"]); p("wrong: no vanna", est - tm[5][1])
wr = 0.0025
p("try: rates +0.25%: rho, est, exact", G["rho"] * wr, est + G["rho"] * wr, V(S + dS, sg + dv, dt, r + wr) - V0)

# cube law: scale the whole move (dS, dsigma) = k x (5, 0.01), no time passing
g = lambda k: V(S + 5 * k, sg + 0.01 * k)
h3 = 0.05
g3 = (g(2 * h3) - 2 * g(h3) + 2 * g(-h3) - g(-2 * h3)) / (2 * h3**3)   # third derivative along the move
p("third-order coefficient g3/6", g3 / 6)
print("   k  spot  vol pts     exact  estimate     error  error/k^3")
errs = {}
for k in (0.5, 1.0, 2.0, 4.0):
    e = V(S + 5 * k, sg + 0.01 * k) - V0
    a = sum(v for _, v in terms(G, 5 * k, 0.01 * k, 0.0))
    errs[k] = e - a
    print(f"{k:4.1f} {5 * k:+5.1f} {k:+8.1f} {e:9.4f} {a:9.4f} {e - a:9.5f} {(e - a) / k**3:10.6f}")
for k in (0.5, 1.0, 2.0): p("error ratio, move x2 from k = " + format(k, ".1f"), errs[2 * k] / errs[k])
p("error ratio, move x4 from k = 1.0", errs[4.0] / errs[1.0])
print("chart, spot move ($)      " + " ".join(f"{x:6.0f}" for x in range(-20, 21, 5)))
rows = {"chart, exact": [], "chart, delta only": [], "chart, full estimate": []}
for x in range(-20, 21, 5):
    rows["chart, exact"].append(V(S + x, sg + 0.01, dt) - V0)
    t = terms(G, x, 0.01, dt); rows["chart, delta only"].append(t[0][1])
    rows["chart, full estimate"].append(sum(v for _, v in t))
for lab, vals in rows.items(): print(f"{lab:<26}" + " ".join(f"{v:6.2f}" for v in vals))
p("at +20: full - exact, delta - exact", rows["chart, full estimate"][-1] - rows["chart, exact"][-1],
  rows["chart, delta only"][-1] - rows["chart, exact"][-1])

assert abs(V0 - 9.227005508154) < 1e-9, "own normal CDF reproduces the house call"
assert all(abs(G[k] - B[k]) < 1e-4 * max(1.0, abs(G[k])) for k in G), "closed-form Greeks vs bumps"
assert abs(exact - exact_int) < 1e-6, "formula reprice vs integral reprice"
assert abs(est - exact) < 0.02 * abs(exact), "second-order estimate within 2% of the reprice"
assert abs(errs[0.5] / 0.125 - g3 / 6) < 0.05 * abs(g3 / 6), "error at small moves follows g3/6 k^3"
assert 7.0 < errs[1.0] / errs[0.5] < 9.0, "halving the move cuts the error about eightfold"
print("ALL CHECKS PASS")
