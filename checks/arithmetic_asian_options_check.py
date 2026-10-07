# Arithmetic Asian options -- the check behind the card.  Standard library only.
# House market, 52 weekly fixings.  Nothing imported knows the answer: the
# bell-curve area is a series written out, the random numbers come from a
# splitmix64 generator written out, and the paths are simulated step by step.
from math import log, sqrt, exp, cos, pi

S, K, r, q, sigma, T, n = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 52
disc = exp(-r * T)

def N(x):                                  # area left of x: Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0
        b *= x * x / i
        t, s = s, s + b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)

def black(F, v):                           # call on a lognormal with forward F, log-spread v
    d1 = (log(F / K) + 0.5 * v * v) / v
    return disc * (F * N(d1) - K * N(d1 - v))

def fixings(m):                            # m equally spaced dates, the last at T
    return [T * (i + 1) / m for i in range(m)]

def kemna_vorst(m, spot=S):                # geometric twin, exact (sibling card 01)
    tbar, var = T * (m + 1) / (2 * m), sigma * sigma * T * (m + 1) * (2 * m + 1) / (6 * m * m)
    F_G = spot * exp((r - q - 0.5 * sigma * sigma) * tbar + 0.5 * var)
    return black(F_G, sqrt(var)), F_G

def turnbull_wakeman(m, spot=S, vol=sigma):  # moment-matched lognormal for the average
    ts, M1, M2 = fixings(m), 0.0, 0.0
    for a in ts:                           # exact first and second moments of the average
        M1 += spot * exp((r - q) * a) / m
        for b in ts:
            M2 += spot * spot * exp((r - q) * (a + b) + vol * vol * min(a, b)) / (m * m)
    vA = sqrt(log(M2 / (M1 * M1)))
    return black(M1, vA), M1, vA, M2

state = 20260924                           # splitmix64: 64-bit integer mixing
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54

def normal():                              # Box-Muller, one draw per pair of uniforms
    return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())

# ---- roads 1 and 2: 50,000 weekly paths; the geometric payoff rides along as control
paths, dt = 50000, T / n
drift, step = (r - q - 0.5 * sigma * sigma) * dt, sigma * sqrt(dt)
kv, F_G = kemna_vorst(n)
tw, M1, vA, M2 = turnbull_wakeman(n)
e1 = (log(M1 / K) + 0.5 * vA * vA) / vA   # the two cut-offs, for the hand table
sx = sxx = sy = syy = sxy = sa = saa = sf = sff = sw = sww = sfw = 0.0
for _ in range(paths):
    x, tot, totlog = log(S), 0.0, 0.0
    for _ in range(n):
        x += drift + step * normal()
        tot += exp(x)
        totlog += x
    A, G, ST = tot / n, exp(totlog / n), exp(x)
    X, Y = disc * max(A - K, 0.0), disc * max(G - K, 0.0)    # arithmetic, geometric
    Fl, W = disc * max(ST - A, 0.0), disc * (ST - A)         # floating strike, its forward
    sx += X; sxx += X * X; sy += Y; syy += Y * Y; sxy += X * Y
    sa += A; saa += A * A; sf += Fl; sff += Fl * Fl; sw += W; sww += W * W; sfw += Fl * W

def cv(s1, s11, s2, s22, s12, known):      # mean, plain error bar, controlled mean and bar, rho
    m1, m2 = s1 / paths, s2 / paths
    v1, v2, c12 = s11 / paths - m1 * m1, s22 / paths - m2 * m2, s12 / paths - m1 * m2
    beta = c12 / v2
    return m1, sqrt(v1 / paths), m1 - beta * (m2 - known), sqrt((v1 - beta * c12) / paths), c12 / sqrt(v1 * v2), m2, sqrt(v2 / paths)

plain, se_plain, ctrl, se_ctrl, rho, geo_sim, se_geo = cv(sx, sxx, sy, syy, sxy, kv)
F_T = S * exp((r - q) * T)                 # floating strike: control S_T - A is worth disc*(F - M1)
fwd_known = disc * (F_T - M1)
fplain, fse, fctrl, fse_c, _, fwd_sim, fwd_se = cv(sf, sff, sw, sww, sfw, fwd_known)
mean_A, se_A = sa / paths, sqrt((saa / paths - (sa / paths) * (sa / paths)) / paths)
vanilla = turnbull_wakeman(1)[0]
upper = kv + disc * (M1 - F_G)             # A - G >= (A-K)+ - (G-K)+ >= 0, path by path
ts, M3 = fixings(n), 0.0                   # M3: exact third moment, each pair of three dates sharing shoves
for a, b, c in ((a, b, c) for a in ts for b in ts for c in ts):
    M3 += S * S * S * exp((r - q) * (a + b + c) + sigma * sigma * (min(a, b) + min(a, c) + min(b, c))) / (n * n * n)
skew, skew_fit = (M3 - 3 * M1 * M2 + 2 * M1 * M1 * M1) / (M2 - M1 * M1) ** 1.5, (M2 / (M1 * M1) + 2) * sqrt(M2 / (M1 * M1) - 1)

print(f"{'fixings, first and last (years)':<38}{fixings(n)[0]:>12.6f}{fixings(n)[-1]:>12.6f}")
rows = [("vanilla call, Black-Scholes", vanilla), ("mean of the average M1, exact", M1),
    ("  simulated", mean_A), ("  its error bar", se_A), ("second moment M2, exact", M2),
    ("M2 / M1^2", M2 / (M1 * M1)), ("log-spread of the average vA", vA),
    ("log-spread of one price, sigma*sqrt(T)", sigma * sqrt(T)),
    ("cut-off e1", e1), ("cut-off e2 = e1 - vA", e1 - vA), ("N(e1)", N(e1)), ("N(e2)", N(e1 - vA)),
    ("discount e^-rT", disc), ("geometric twin, Kemna-Vorst", kv), ("  simulated", geo_sim), ("  its error bar", se_geo),
    ("geometric forward F_G", F_G), ("1 plain simulation", plain), ("  its error bar", se_plain),
    ("2 control-variate simulation", ctrl), ("  its error bar", se_ctrl), ("  correlation rho", rho),
    ("  error bar shrinks by", se_plain / se_ctrl), ("3 Turnbull-Wakeman", tw),
    ("  minus road 2", tw - ctrl), ("  skewness of the average, exact", skew),
    ("  skewness of the fitted lognormal", skew_fit), ("4 floor: geometric twin", kv),
    ("  ceiling: twin + disc*(M1 - F_G)", upper), ("arithmetic / vanilla", ctrl / vanilla),
    ("floating strike, plain", fplain), ("  its error bar", fse), ("floating strike, controlled", fctrl),
    ("  its error bar", fse_c), ("expiry forward F", F_T),
    ("dial: lower spread only", black(F_T, vA)), ("dial: lower forward only", black(M1, sigma * sqrt(T))),
    ("wrong: fixings as independent draws", black(M1, sigma * sqrt(T / n))),
    ("house check: continuous geometric", kemna_vorst(10 ** 7)[0])]
for name, v in rows:
    print(f"{name:<38}{v:>12.6f}")

h, hv = 0.01, 0.0001                       # bumps for the Greeks, on Turnbull-Wakeman
def greeks(m):
    up, mid, dn = (turnbull_wakeman(m, S * (1 + s))[0] for s in (h, 0.0, -h))
    vup, vdn = turnbull_wakeman(m, S, sigma + hv)[0], turnbull_wakeman(m, S, sigma - hv)[0]
    return (up - dn) / (2 * S * h), (up - 2 * mid + dn) / ((S * h) * (S * h)), (vup - vdn) / (2 * hv) / 100
for label, m in (("greeks, Asian (delta gamma vega/pt)", n), ("greeks, vanilla", 1)):
    print(f"{label:<38}" + "".join(f"{g:>10.4f}" for g in greeks(m)))

print(f"{'chart, fixings n':<38}" + "".join(f"{m:>8d}" for m in (1, 4, 12, 52, 252)))
print(f"{'chart, Turnbull-Wakeman':<38}" + "".join(f"{turnbull_wakeman(m)[0]:>8.2f}" for m in (1, 4, 12, 52, 252)))
print(f"{'chart, Kemna-Vorst':<38}" + "".join(f"{kemna_vorst(m)[0]:>8.2f}" for m in (1, 4, 12, 52, 252)))
ladder = (vanilla, black(F_T, vA), black(M1, sigma * sqrt(T)), tw, ctrl, kv)
print(f"{'bars, price ladder':<38}" + "".join(f"{v:>8.2f}" for v in ladder))
avgs = [80 + 5 * i for i in range(11)]
print(f"{'chart, average at expiry':<38}" + "".join(f"{a:>7d}" for a in avgs))
print(f"{'chart, profit after premium':<38}" + "".join(f"{max(a - K, 0.0) - ctrl:>7.2f}" for a in avgs))

assert abs(vanilla - 9.227005508154) < 1e-9, "one fixing: the average is S_T, so Black-Scholes"
assert abs(kemna_vorst(10 ** 7)[0] - 4.985760) < 2e-6, "many fixings: the shelf's continuous geometric"
assert abs(geo_sim - kv) < 3 * se_geo, "the paths reproduce the exact geometric price"
assert abs(mean_A - M1) < 3 * se_A, "the paths reproduce the exact mean of the average"
assert kv < ctrl < upper, "controlled price inside the AM-GM floor and ceiling"
assert abs(ctrl - plain) < 3 * se_plain, "the control moves the price by less than the plain bar"
assert se_plain / se_ctrl > 10, "the control shrinks the error bar at least tenfold"
assert abs(tw - ctrl) < 0.03, "moment matching within three cents of the simulation"
assert abs(fwd_sim - fwd_known) < 3 * fwd_se, "the paths reproduce the exact value of S_T - A"
assert abs(fctrl - fplain) < 3 * fse, "floating strike: control agrees with plain"
assert skew > skew_fit, "the true average is more lopsided than the fitted lognormal"
print("ALL CHECKS PASS")
