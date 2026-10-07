# Asian Greeks and implied volatility -- the check behind the card.  Standard library only.
# House market, 52 weekly fixings.  Nothing imported knows an answer: the bell-curve area
# is a series written out, the normal draws come from a splitmix64 generator written out,
# the paths are stepped by hand, and the root finders are bisection and Newton.
from math import exp, log, sqrt, pi, cos, sin

S, K, r, q, sig, n = 100.0, 100.0, 0.05, 0.02, 0.20, 52
dt, PAIRS = 1.0 / n, 65536                              # weekly step; antithetic pairs

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)   # bell-curve height
def N(x):                                               # bell-curve area left of x (series)
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    s, t, b, i = x, 0.0, x, 1.0
    while s != t:
        i += 2.0; b *= x * x / i; t, s = s, s + b
    return 0.5 + s * phi(x)

M64, state = (1 << 64) - 1, 20260924
def u01():                                              # splitmix64, uniform in (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
Z = []
while len(Z) < PAIRS * n:                               # Box-Muller: two normals per two uniforms
    rad, ang = sqrt(-2.0 * log(u01())), 2.0 * pi * u01()
    Z += [rad * cos(ang), rad * sin(ang)]

def paths(sg, m, h=dt):                                 # per path: A/S0 and (dA/dsigma)/S0
    c, sd, a, b = (r - q - 0.5 * sg * sg) * h, sqrt(h), [], []
    for p in range(PAIRS):
        for sgn in (1.0, -1.0):                         # each draw and its mirror image
            w = sa = sb = 0.0
            for j in range(m):
                w += sgn * sd * Z[p * n + j]
                e = exp(c * (j + 1) + sg * w)
                sa += e; sb += e * (w - sg * (j + 1) * h)
            a.append(sa / m); b.append(sb / m)
    return a, b

def value(ab, s0, wt, fx, tau):                         # price, pathwise delta, pathwise vega
    pay = dl = vg = 0.0
    for ai, bi in zip(*ab):
        x = fx + wt * s0 * ai - K                       # fixed part + weight * the rest - strike
        if x > 0.0: pay += x; dl += wt * ai; vg += wt * s0 * bi
    d = exp(-r * tau) / len(ab[0])
    return pay * d, dl * d, vg * d

def mc(m, fx, sg=sig, hs=1.0, hv=0.001):                # every Greek two ways, on one set of draws
    wt, tau, ab = m / n, m * dt, paths(sg, m)
    p0, dpw, vpw = value(ab, S, wt, fx, tau)
    pu, du, _ = value(ab, S + hs, wt, fx, tau); pd, dd, _ = value(ab, S - hs, wt, fx, tau)
    vu = value(paths(sg + hv, m), S, wt, fx, tau)[0]; vd = value(paths(sg - hv, m), S, wt, fx, tau)[0]
    tu, tv = value(ab, S + 1e-7, wt, fx, tau)[1], value(ab, S - 1e-7, wt, fx, tau)[1]
    return dict(p=p0, d_pw=dpw, d_b=(pu - pd) / (2 * hs), g_b=(pu - 2 * p0 + pd) / hs ** 2,
                g_pwb=(du - dd) / (2 * hs), g_naive=(tu - tv) / 2e-7, v_pw=vpw, v_b=(vu - vd) / (2 * hv), ab=ab)

def mm(m, fx, sg=sig, nn=n):                            # third road: lognormal with the average's two moments
    wt, h = m / nn, 1.0 / nn; tau, ks = m * h, (K - fx) * nn / m    # ks: strike the unfixed rest must beat
    M1 = S * sum(exp((r - q) * h * i) for i in range(1, m + 1)) / m
    M2 = S * S * sum(exp((r - q) * h * (i + j) + sg * sg * h * min(i, j))
                     for i in range(1, m + 1) for j in range(1, m + 1)) / (m * m)
    v = sqrt(log(M2 / (M1 * M1))); d1 = (log(M1 / ks) + 0.5 * v * v) / v; D = wt * exp(-r * tau)
    return D * (M1 * N(d1) - ks * N(d1 - v)), D * M1 / S * N(d1), D * M1 / S * phi(d1) / (S * v), M1
def mm_vega(m, fx, nn=n, h=1e-4): return (mm(m, fx, sig + h, nn)[0] - mm(m, fx, sig - h, nn)[0]) / (2 * h)

def bs(sg, tau):                                        # the vanilla yardstick: price, delta, gamma, vega
    d1 = (log(S / K) + (r - q + 0.5 * sg * sg) * tau) / (sg * sqrt(tau)); d2 = d1 - sg * sqrt(tau)
    return (S * exp(-q * tau) * N(d1) - K * exp(-r * tau) * N(d2), exp(-q * tau) * N(d1),
            exp(-q * tau) * phi(d1) / (S * sg * sqrt(tau)), S * exp(-q * tau) * phi(d1) * sqrt(tau))

def bisect(f, target, lo=0.01, hi=1.0, tol=1e-7):      # f rises in sigma: halve the bracket
    while hi - lo > tol:
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < target else (lo, mid)
    return 0.5 * (lo + hi)

def out(label, *v): print(f"{label:<36}" + "".join(f"{x:>11.6f}" for x in v))
van = bs(sig, 1.0); pv = value(paths(sig, 1, 1.0), S, 1.0, 0.0, 1.0)
out("vanilla: price delta gamma vega", *van)
out("vanilla by paths: delta vega", pv[1], pv[2])
F, Fm = mc(n, 0.0), mm(n, 0.0)
out("fresh price: paths, moments", F["p"], Fm[0])
out("fresh delta: pathwise bump moments", F["d_pw"], F["d_b"], Fm[1])
out("fresh gamma: bump pw-bump moments", F["g_b"], F["g_pwb"], Fm[2])
out("fresh vega: pathwise bump moments", F["v_pw"], F["v_b"], mm_vega(n, 0.0))
c52 = (n + 1) * (2 * n + 1) / (6 * n * n)
out("by hand: share c, sqrt c, 37.90*sqrt c", c52, sqrt(c52), van[3] * sqrt(c52))
fx = 26 / n * 105.0
out("seasoned: fixed part, strike, weight", fx, (K - fx) * n / 26, 26 / n)
H, Hm = mc(26, fx), mm(26, fx)
out("seasoned price: paths, moments", H["p"], Hm[0])
out("seasoned delta: pathwise bump mom", H["d_pw"], H["d_b"], Hm[1])
out("seasoned gamma: bump pw-bump mom", H["g_b"], H["g_pwb"], Hm[2])
out("seasoned vega: pathwise bump mom", H["v_pw"], H["v_b"], mm_vega(26, fx))
out("vanilla 6 months: delta gamma vega", *bs(sig, 0.5)[1:])
ign = value(H["ab"], S, 1.0, 0.0, 0.5)
out("wrong: fixings ignored: price vega", ign[0], ign[2])
out("wrong: pathwise gamma, naive", F["g_naive"])
out("wrong: vanilla delta - Asian delta", van[1] - F["d_pw"])

Q = F["p"]; M1 = Fm[3]; D1 = exp(-r)                    # the quote: the paths price at 20%
out("quote; floor; ceiling; mean average", Q, D1 * max(M1 - K, 0.0), D1 * M1, M1)
def P(sg): return value(paths(sg, n), S, 1.0, 0.0, 1.0)
iv_b = bisect(lambda sg: P(sg)[0], Q)
sg, steps = 0.30, 0
while True:                                             # Newton, steered by the pathwise vega
    p, _, v = P(sg); steps += 1
    if abs(p - Q) < 1e-10 or steps > 10: break
    sg -= (p - Q) / v
out("implied vol: bisection, Newton, steps", iv_b, sg, steps)
iv_m = bisect(lambda s: mm(n, 0.0, s)[0], Q); iv_v = bisect(lambda s: bs(s, 1.0)[0], Q)
out("implied vol: moments; wrong: vanilla", iv_m, iv_v)
out("try: monthly vega; avg-in 90 vega", mm_vega(12, 0.0, 12), mm_vega(26, 26 / n * 90.0))

sgs = [0.05 * i for i in range(1, 9)]; curve = [P(s)[0] for s in sgs]
print("chart, sigma                  " + " ".join(f"{s:6.2f}" for s in sgs))
print("chart, price by paths         " + " ".join(f"{c:6.2f}" for c in curve))
ks = [0, 13, 26, 39, 48]
va_pw = [value(paths(sig, n - k), S, (n - k) / n, k / n * 100.0, (n - k) * dt)[2] for k in ks]
print("chart, fixings in             " + " ".join(f"{k:6d}" for k in ks))
print("chart, Asian vega, paths      " + " ".join(f"{v:6.2f}" for v in va_pw))
print("chart, Asian vega, moments    " + " ".join(f"{mm_vega(n - k, k / n * 100.0):6.2f}" for k in ks))
print("chart, vanilla vega, same left" + " ".join(f"{bs(sig, (n - k) * dt)[3]:6.2f}" for k in ks))
rest = [85.0 + 5.0 * i for i in range(7)]
print("chart, average of the rest    " + " ".join(f"{x:6.0f}" for x in rest))
print("chart, seasoned payoff        " + " ".join(f"{max(fx + 0.5 * x - K, 0.0):6.2f}" for x in rest))

assert abs(pv[2] - van[3]) < 0.5, "pathwise vega on one fixing vs the closed-form vanilla vega"
assert abs(F["d_pw"] - Fm[1]) < 0.01, "pathwise delta vs the moments road"
assert abs(H["d_pw"] - Hm[1]) < 0.01, "seasoned pathwise delta vs the moments road"
assert abs(F["v_pw"] - mm_vega(n, 0.0)) < 0.5, "pathwise vega vs the moments road"
assert abs(F["g_b"] - Fm[2]) < 0.002, "bumped gamma vs the moments gamma, fresh"
assert abs(H["g_b"] - Hm[2]) < 0.002, "bumped gamma vs the moments gamma, seasoned"
assert H["v_pw"] < F["v_pw"] < van[3], "averaging and seasoning both cut vega"
assert abs(iv_b - sig) < 1e-6, "bisection returns the vol that made the quote"
assert abs(sg - sig) < 1e-6, "Newton returns the vol that made the quote"
assert all(a < b for a, b in zip(curve, curve[1:])), "price rises with vol: the inverse is unique"
print("ALL CHECKS PASS")
