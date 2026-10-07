# Asian Greeks and the running average -- the check behind the card.  Standard library only.
# Jet fuel: 52 weekly fixings, each lognormal around its own forward price (Black-76 style).
# Road 1: Monte Carlo on common random numbers, bumped, with the geometric average as control.
# Road 2: the moment-matched (Levy) formula and its closed-form Greeks.  No erf, no random module.
# Delta is per $1 on jet fuel with the whole forward curve moving in proportion.
from math import exp, log, sqrt, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def N(x):                                   # normal CDF from its power series
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total

def fwd(S, r, t): return [S * exp(r * ti) for ti in t]      # the forward for each fixing still to come
def moments(F, t, sig):                      # M1, M2 and dM2/dsigma of the open average
    m = len(F); M2 = dM2 = 0.0
    for i in range(m):
        for j in range(m):
            c = min(t[i], t[j]); e = F[i] * F[j] * exp(sig * sig * c)
            M2 += e; dM2 += e * 2 * sig * c
    return sum(F) / m, M2 / m / m, dM2 / m / m

def levy(S, F, t, sig, w, Ks, disc):         # price, delta, gamma, vega per vol point
    M1, M2, dM2 = moments(F, t, sig)
    if Ks <= 0: return disc * w * (M1 - Ks), disc * w * M1 / S, 0.0, 0.0
    v = sqrt(log(M2 / M1 / M1)); d1 = (log(M1 / Ks) + 0.5 * v * v) / v
    return (disc * w * (M1 * N(d1) - Ks * N(d1 - v)), disc * w * M1 / S * N(d1),
            disc * w * M1 / S * phi(d1) / (S * v), disc * w * M1 * phi(d1) * dM2 / (2 * M2 * v) / 100)

def geo(F, t, sig, w, Ks, disc):             # exact price of the geometric-average version (the control)
    m = len(F); mu = sum(log(f) for f in F) / m - 0.5 * sig * sig * sum(t) / m
    s2 = sig * sig * sum(min(a, b) for a in t for b in t) / m / m; G = exp(mu + 0.5 * s2)
    if Ks <= 0: return disc * w * (G - Ks)
    d1 = (log(G / Ks) + 0.5 * s2) / sqrt(s2)
    return disc * w * (G * N(d1) - Ks * N(d1 - sqrt(s2)))

def sim(F, t, sig, pairs, q):                # per path: open average, log geometric average, sum per quarter
    st, out, m = 20260927, [], len(F)
    def u():
        nonlocal st
        st = (st + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = st
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    for _ in range(pairs):
        zs = []
        while len(zs) < m:
            a, b = 1.0 - u(), u(); R = sqrt(-2.0 * log(a)); zs += [R * cos(2 * pi * b), R * sin(2 * pi * b)]
        for sgn in (1.0, -1.0):
            W, prev, A, L, Q = 0.0, 0.0, 0.0, 0.0, [0.0] * 4
            for i in range(m):
                W += sgn * zs[i] * sqrt(t[i] - prev); prev = t[i]
                x = F[i] * exp(sig * W - 0.5 * sig * sig * t[i]); A += x; L += log(x); Q[q[i]] += x
            out.append((A / m, L / m, Q))
    return out

def mc(P, F, t, sig, fixed, w, K, disc, scale=1.0, q=None, qb=-1, b=1.0):   # controlled price, shared draws
    m, Ks = len(F), (K - fixed) / w
    Fb = [f * scale * (b if qi == qb else 1.0) for f, qi in zip(F, q or [-1] * m)]
    tot = 0.0
    for A, L, Q in P:
        a = scale * (A + ((b - 1.0) * Q[qb] / m if qb >= 0 else 0.0))
        g = exp(L + log(scale) + (log(b) * q.count(qb) / m if qb >= 0 else 0.0))
        tot += max(fixed + w * a - K, 0.0) - w * max(g - Ks, 0.0)
    return disc * tot / len(P) + geo(Fb, t, sig, w, Ks, disc)

S, K, r, sig, n, pairs = 100.0, 100.0, 0.05, 0.20, 52, 20000
out = lambda lab, a, b: print(f"{lab:<34}{a:>11.4f}{b:>11.4f}")
# ---- fresh contract: 52 fixings to come, nothing banked ----
t = [(i + 1) / n for i in range(n)]; F = fwd(S, r, t); qid = [i // 13 for i in range(n)]; D = exp(-r)
P0, Pu, Pd = (sim(F, t, s, pairs, qid) for s in (sig, sig + 0.01, sig - 0.01))
v0, vu, vd = mc(P0, F, t, sig, 0, 1, K, D), mc(P0, F, t, sig, 0, 1, K, D, 1.01), mc(P0, F, t, sig, 0, 1, K, D, 0.99)
mcg = ((vu - vd) / 2, (vu - 2 * v0 + vd), (mc(Pu, F, t, sig + .01, 0, 1, K, D) - mc(Pd, F, t, sig - .01, 0, 1, K, D)) / 2)
lf = levy(S, F, t, sig, 1, K, D)
d1 = (log(F[-1] / K) + 0.5 * sig * sig) / sig; bl = D * (F[-1] * N(d1) - K * N(d1 - sig))
print(f"{'fresh, 52 fixings to come':<34}{'MC bumped':>11}{'formula':>11}")
out("price", v0, lf[0]); out("delta", mcg[0], lf[1]); out("gamma", mcg[1], lf[2]); out("vega per vol point", mcg[2], lf[3])
gx, gmc = geo(F, t, sig, 1, K, D), D * sum(max(exp(L) - K, 0) for A, L, Q in P0) / len(P0)
out("geometric control, exact / MC", gx, gmc)
out("plain Black-76 call: price, delta", bl, N(d1)); out("plain call: gamma, vega/point", phi(d1) / (S * sig), S * phi(d1) / 100)
def ladder(P, F, t, fixed, w, disc, q):     # delta per quarter: that quarter's forwards moved 1 percent
    if not P: return [0.0] * 4
    Ks = (K - fixed) / w; bump = lambda j, b: [f * (b if qi == j else 1.0) for f, qi in zip(F, q)]
    return [((mc(P, F, t, sig, fixed, w, K, disc, 1, q, j, 1.01) - mc(P, F, t, sig, fixed, w, K, disc, 1, q, j, 0.99)) / 2,
             (levy(S, bump(j, 1.01), t, sig, w, Ks, disc)[0] - levy(S, bump(j, 0.99), t, sig, w, Ks, disc)[0]) / 2)
            if j in q else (0.0, 0.0) for j in range(4)]
# ---- seasoned: 26 fixings banked at an average of 103, jet fuel back at 100, half a year left ----
lad0 = ladder(P0, F, t, 0, 1, D, qid); k, abar = 26, 103.0; fixed, w = k / n * abar, (n - k) / n; Ks = (K - fixed) / w
t2 = [(i + 1) / n for i in range(n - k)]; F2 = fwd(S, r, t2); D2 = exp(-r * t2[-1])
q2 = [(k + i) // 13 for i in range(n - k)]
Q0, Qu, Qd = (sim(F2, t2, s, pairs, q2) for s in (sig, sig + 0.01, sig - 0.01))
s0, su, sd = (mc(Q0, F2, t2, sig, fixed, w, K, D2, x) for x in (1.0, 1.01, 0.99))
sv = (mc(Qu, F2, t2, sig + .01, fixed, w, K, D2) - mc(Qd, F2, t2, sig - .01, fixed, w, K, D2)) / 2
ls = levy(S, F2, t2, sig, w, Ks, D2)
print(f"seasoned: banked part {fixed:.2f}, weight {w:.2f}, new strike {Ks:.2f}")
out("price, full payoff vs rewritten", s0, ls[0]); out("delta", (su - sd) / 2, ls[1])
out("gamma", su - 2 * s0 + sd, ls[2]); out("vega per vol point", sv, ls[3])
out("delta, seasoned / fresh", ((su - sd) / 2) / mcg[0], ls[1] / lf[1]); lad2 = ladder(Q0, F2, t2, fixed, w, D2, q2)
fx2 = k / n * 205.0; fwd_mc = mc(Q0, F2, t2, sig, fx2, w, K, D2); fwd_lv = levy(S, F2, t2, sig, w, (K - fx2) / w, D2)[0]
out("banked at 205: strike -5, price", fwd_mc, fwd_lv)
for lab, FF, tt, KK, dd in (("fresh", F, t, K, D), ("seasoned", F2, t2, Ks, D2)):
    M1, M2, _ = moments(FF, tt, sig); v = sqrt(log(M2 / M1 / M1)); e = (log(M1 / KK) + 0.5 * v * v) / v
    print(f"{lab + ': M1 v d1 N(d1) N(d1-v) D':<34}" + "".join(f"{x:>9.4f}" for x in (M1, v, e, N(e), N(e - v), dd)))
print(f"{'delta ladder, quarter':<22}{'fresh MC':>10}{'formula':>10}{'seas. MC':>10}{'formula':>10}")
for j in range(4):
    print(f"{'Q' + str(j + 1):<22}" + "".join(f"{x:>10.4f}" for x in lad0[j] + lad2[j]))
# ---- risk draining as fixings are set: jet fuel and the running average both held at 100 ----
print(f"{'fixings in':>10}{'price':>9}{'delta':>9}{'vega/pt':>9}{'call dlt':>9}{'call vg':>9}")
va, vc = [], []
for kk in (0, 13, 26, 39, 48):
    tk = [(i + 1) / n for i in range(n - kk)]; tau = tk[-1]; e1 = (r + 0.5 * sig * sig) * tau / (sig * sqrt(tau))
    p = levy(S, fwd(S, r, tk), tk, sig, (n - kk) / n, K, exp(-r * tau))
    print(f"{kk:>10}{p[0]:>9.4f}{p[1]:>9.4f}{p[3]:>9.4f}{N(e1):>9.4f}{S * phi(e1) * sqrt(tau) / 100:>9.4f}")
    va.append(100 * p[3]); vc.append(S * phi(e1) * sqrt(tau))
xs = [85.0 + 5 * i for i in range(7)]
for lab, row in (("chart, remaining average", xs), ("chart, seasoned payoff", [w * max(x - Ks, 0) for x in xs]),
                 ("chart, banked ignored", [max(x - K, 0) for x in xs]), ("chart, Asian vega cents", va), ("chart, call vega cents", vc)):
    print(f"{lab:<25}" + " ".join(f"{v:6.2f}" for v in row))
# ---- what breaks, and try changing ----
two = lambda lab, x: out(lab, x[0], x[1])
two("wrong: ignore banked, fresh 26 at 100", levy(S, F2, t2, sig, 1, K, D2))
two("wrong: strike 97 but full weight", levy(S, F2, t2, sig, 1, Ks, D2))
two("wrong: strike 100-51.5, not /0.5", levy(S, F2, t2, sig, w, K - fixed, D2))
two("wrong: flat curve at 100, fresh", levy(S, [S] * n, t, sig, 1, K, D))
two("try: banked at 97, strike 103", levy(S, F2, t2, sig, w, (K - k / n * 97) / w, D2))
tm = [(i + 1) / 12 for i in range(12)]; two("try: 12 monthly fixings, fresh", levy(S, fwd(S, r, tm), tm, sig, 1, K, D))
two("try: sigma 0.40, fresh", levy(S, F, t, 0.40, 1, K, D))
assert abs(gmc - gx) < 0.02, "raw simulator, no control: geometric average vs its exact price"
assert abs(v0 - lf[0]) < 0.03, "controlled simulation vs moment formula, fresh price"
assert abs(mcg[0] - lf[1]) < 0.01, "bumped delta vs formula delta"
assert abs(mcg[2] - lf[3]) < 0.005, "bumped vega vs formula vega"
assert abs(mcg[1] / lf[2] - 1) < 0.1, "bumped gamma vs formula gamma, within 10 percent"
assert abs(s0 - ls[0]) < 0.03, "full seasoned payoff simulated vs half an option struck at 97"
assert abs((su - sd) / 2 - ls[1]) < 0.01, "seasoned delta, bumped vs formula"
assert abs(sum(x[0] for x in lad0) - mcg[0]) < 0.002 and abs(sum(x[0] for x in lad2) - (su - sd) / 2) < 0.002, "rungs add up to delta"
assert abs(fwd_mc - fwd_lv) < 0.02, "strike below zero: simulated vs the certain-payout forward value"
assert abs(bl - 10.450583572185565) < 1e-9, "plain call against the house number"
print("ALL CHECKS PASS")
