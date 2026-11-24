# Boosting -- the check behind the card.  Standard library only.
# Ten toy orders worked by hand, then 20,000 SYNTHETIC shop orders made from a
# stated rule with SplitMix64 (seed 2026), written out so Rust sees the same data.
from math import exp, log, sqrt
MASK = (1 << 64) - 1
def splitmix64(s):
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield z ^ (z >> 31)

def best_stump(cols, y, w, nv):
    # stump (j, c, s): say s if number j >= c, else -s.  Returns (weighted error, j, c, s).
    best = (2.0, 0, 0, 1)
    for j, col in enumerate(cols):
        wp, wm, cnt = [0.0] * nv, [0.0] * nv, [0] * nv
        for b, wi, yi in zip(col, w, y):
            cnt[b] += 1
            if yi > 0: wp[b] += wi
            else: wm[b] += wi
        below_p, above_m, tot = 0.0, sum(wm), sum(wp) + sum(wm)
        for c in range(nv):
            if cnt[c] > 0:
                for s, e in ((1, below_p + above_m), (-1, tot - below_p - above_m)):
                    if e < best[0] - 1e-12: best = (e, j, c, s)
            below_p += wp[c]; above_m -= wm[c]
    return best
def h(st, x): return st[3] if x[st[1]] >= st[2] else -st[3]
def name(st, names, lo):
    if st[2] == lo[st[1]]: return "every order " + ("returned" if st[3] > 0 else "kept")
    return names[st[1]] + (">=" if st[3] > 0 else "<") + str(st[2])
def err(F, ys): return sum(1 for f, yi in zip(F, ys) if f * yi <= 0) / len(ys)

def adaboost(X, y, T, nv, report=None, sign=1.0, half=0.5, Xt=()):
    n, cols = len(X), [[x[j] for x in X] for j in range(len(X[0]))]
    w, F, Ft, prodZ, gam2, hist = [1.0 / n] * n, [0.0] * n, [0.0] * len(Xt), 1.0, 0.0, []
    for t in range(1, T + 1):
        st = best_stump(cols, y, w, nv); e = st[0]
        a = half * log((1 - e) / e) if 0 < e < 0.5 else 0.0
        hv = [h(st, x) for x in X]
        new = [wi * exp(-sign * a * yi * hi) for wi, yi, hi in zip(w, y, hv)]; Z = sum(new)
        if report: report(t, st, e, a, w, hv, Z, F)
        w = [v / Z for v in new]; prodZ *= Z; gam2 += (0.5 - e) ** 2
        F = [f + a * hi for f, hi in zip(F, hv)]
        Ft = [f + a * h(st, x) for f, x in zip(Ft, Xt)]
        hist.append((t, st, e, a, Z, prodZ, gam2, F, w, Ft))
    return hist

# ---- ten orders: (items in basket, average price in pounds); +1 returned, -1 kept ----
TOY = [(1, 50), (1, 60), (1, 80), (1, 90), (3, 30), (4, 30), (4, 40), (4, 60), (5, 60), (6, 40)]
TY, TN, TL = [-1, -1, 1, 1, -1, 1, 1, -1, 1, 1], ["items", "price"], [1, 30]
def toy_report(t, st, e, a, w, hv, Z, F):
    Zof = lambda al: sum(wi * exp(-al * yi * hi) for wi, yi, hi in zip(w, TY, hv))
    lo, hi_ = 0.0, 3.0                    # road 2 for alpha: golden-section search, no formula
    for _ in range(200):
        c, d = hi_ - 0.618034 * (hi_ - lo), lo + 0.618034 * (hi_ - lo)
        if Zof(c) < Zof(d): hi_ = d
        else: lo = c
    wrong = [i for i in range(10) if hv[i] != TY[i]]; share = sum(w[i] * exp(a) for i in wrong) / Z
    print(f"toy round {t}: {name(st, TN, TL):<20} error {e:.4f}  alpha {a:.4f}  by search {(lo + hi_) / 2:.4f}"
          f"  Z {Z:.4f}  2sqrt(e(1-e)) {2 * sqrt(e * (1 - e)):.4f}  wrong after update hold {share:.4f}  wrong: {''.join('ABCDEFGHIJ'[i] for i in wrong)}")
    assert abs((lo + hi_) / 2 - a) < 1e-6, "alpha formula = the minimum of Z found by search"
    assert abs(Z - 2 * sqrt(e * (1 - e))) < 1e-12 and abs(share - 0.5) < 1e-12
    # road 3, function space: brute-force the stump best aligned with minus the exp-loss gradient
    grad = [-yi * exp(-yi * f) for yi, f in zip(TY, F)]
    cands = [(0, j, c, s) for j in range(2) for c in sorted({x[j] for x in TOY}) for s in (1, -1)]
    al = max(cands, key=lambda q: sum(-g * h(q, x) for g, x in zip(grad, TOY)))
    assert [h(al, x) for x in TOY] == hv, "least weighted error = steepest way down"
hist = adaboost(TOY, TY, 3, 100, toy_report)
a1, F3, pz3 = hist[0][3], hist[2][7], hist[2][5]
print(f"round 1 by hand: grow e^alpha {exp(a1):.4f}  shrink e^-alpha {exp(-a1):.4f}  wrong each {1/6:.4f}  right each {1/14:.4f}  e^(-2*0.2^2) {exp(-0.08):.4f}  rounds at 0.3 to force 0 errors on 16000: {int(log(16000) / -log(2 * sqrt(0.21))) + 1}")
expl = sum(exp(-yi * f) for yi, f in zip(TY, F3)) / 10
print("toy scores after 3 rounds: " + " ".join(f"{'ABCDEFGHIJ'[i]} {F3[i]:+.4f}" for i in range(10)))
print(f"toy after 3 rounds: training errors {err(F3, TY):.1f}  bound prod Z {pz3:.4f}  mean e^(-yF) {expl:.4f}")
assert abs(a1 - 0.423649) < 1e-6 and abs(expl - pz3) < 1e-12 and err(F3, TY) <= pz3
h100 = adaboost(TOY, TY, 100, 100)[-1]
print(f"toy after 100 rounds: training errors {err(h100[7], TY):.1f}  order H holds {h100[8][7]:.4f} of the weight  bound {h100[5]:.6f}")
# ---- what breaks ----
flip = adaboost(TOY, TY, 2, 100, sign=-1.0)[1]
xor = adaboost([(0, 0), (0, 1), (1, 0), (1, 1)], [-1, 1, 1, -1], 1, 2)[0]
print(f"wrong: alpha without the 1/2: Z {adaboost(TOY, TY, 1, 100, half=1.0)[0][4]:.4f}")
print(f"wrong: grow the right orders: round 2 picks {name(flip[1], TN, TL)} again, error {flip[2]:.4f}")
print(f"no weak learner (returned if phone xor weekend): best error {xor[2]:.4f}  alpha {xor[3]:.4f}  Z {xor[4]:.4f}")
# ---- the shop: 20,000 synthetic orders, 12 numbers each stored as a decile 0..9 ----
SN = ["items", "price", "past", "gap", "phone", "hour", "code", "dist", "wkend", "age", "news", "viewed"]
def chance(x): return 1 / (1 + exp(4.5 - 3 * (x[0] >= 6) - 3 * (x[1] >= 7) - 3 * (x[9] <= 2)))
rng, X, Y = splitmix64(2026), [], []
for _ in range(20000):
    x = [next(rng) % 10 for _ in range(12)]
    X.append(x); Y.append(1 if (next(rng) >> 11) / 2.0 ** 53 < chance(x) else -1)
Xtr, Ytr, Xte, Yte = X[:16000], Y[:16000], X[16000:], Y[16000:]
bayes = sum(min(chance((a, b) + (0,) * 7 + (c,)), 1 - chance((a, b) + (0,) * 7 + (c,)))
            for a in range(10) for b in range(10) for c in range(10)) / 1000
ideal = err([chance(x) - 0.5 for x in Xte], Yte)
print(f"shop: returned {sum(1 for v in Y if v > 0)} of 20000  best possible error {bayes:.4f}  ideal rule on test {ideal:.4f}")
CHECK = (1, 2, 3, 5, 10, 20, 50, 200)
print(" round  stump        error   train   prod Z  e^-2sum(g^2)  test")
for t, st, e, a, Z, pz, g2, F, w, Ft in adaboost(Xtr, Ytr, 200, 10, Xt=Xte):
    assert err(F, Ytr) <= pz <= exp(-2 * g2), "training error <= prod Z <= exp(-2 sum gamma^2)"
    if t in CHECK:
        u = [exp(-yi * f) / (16000 * pz) for yi, f in zip(Ytr, F)]   # weights rebuilt from scores
        assert abs(sum(u) - 1) < 1e-9 and max(abs(p - q) for p, q in zip(u, w)) < 1e-12
        print(f"{t:>6}  {name(st, SN, [0] * 12):<11} {e:.4f}  {err(F, Ytr):.4f}  {pz:.4f}  {exp(-2 * g2):.4f}       {err(Ft, Yte):.4f}")
ada_test = err(Ft, Yte)
# ---- gradient boosting: log loss, regression stumps fitted to minus the gradient ----
def loss(yi, f): return log(1 + exp(-yi * f))
def gboost(X, y, T, nv, eta, Xt=()):
    n, cols = len(X), [[x[j] for x in X] for j in range(len(X[0]))]
    F, Ft, out = [0.0] * n, [0.0] * len(Xt), []
    for t in range(1, T + 1):
        r = [yi / (1 + exp(yi * f)) for yi, f in zip(y, F)]     # minus the slope of the loss
        best = (-1.0, 0, 0, 0.0, 0.0)
        for j, col in enumerate(cols):
            S, N = [0.0] * nv, [0] * nv
            for b, ri in zip(col, r): S[b] += ri; N[b] += 1
            tot, sl, nl = sum(S), 0.0, 0
            for c in range(nv):
                if N[c] == 0: continue
                gain = (sl * sl / nl if nl else 0.0) + (tot - sl) ** 2 / (n - nl)
                if gain > best[0] + 1e-12: best = (gain, j, c, sl / nl if nl else 0.0, (tot - sl) / (n - nl))
                sl += S[c]; nl += N[c]
        _, j, c, vlo, vhi = best
        F = [f + eta * (vhi if x[j] >= c else vlo) for f, x in zip(F, X)]
        Ft = [f + eta * (vhi if x[j] >= c else vlo) for f, x in zip(Ft, Xt)]
        out.append((t, j, c, vlo, vhi, r, F, Ft))
    return out
g1 = gboost(TOY, TY, 1, 100, 1.0)[0]
print(f"gradient boosting, toy round 1: residuals +-{abs(g1[5][0]):.4f}  split {TN[g1[1]]}>={g1[2]}  leaves {g1[3]:+.4f} {g1[4]:+.4f}")
gb = gboost(Xtr, Ytr, 200, 10, 0.5, Xte)
print(" round  split     train log loss  train   test")
for t, j, c, vlo, vhi, r, F, Ft in gb:
    if t in CHECK:
        print(f"{t:>6}  {SN[j] + '>=' + str(c):<9} {sum(loss(yi, f) for yi, f in zip(Ytr, F)) / 16000:.4f}"
              f"          {err(F, Ytr):.4f}  {err(Ft, Yte):.4f}")
fd = max(abs(-(loss(yi, f + 1e-6) - loss(yi, f - 1e-6)) / 2e-6 - ri) for yi, f, ri in zip(Ytr, gb[-2][6], gb[-1][5]))
print(f"residual vs finite-difference slope, worst gap {fd:.2e}")
assert fd < 1e-6, "residuals are minus the slope of the loss"
assert abs(ada_test - ideal) < 0.02 and abs(err(gb[-1][7], Yte) - ideal) < 0.02, "both near the ideal rule"
print("ALL CHECKS PASS")
