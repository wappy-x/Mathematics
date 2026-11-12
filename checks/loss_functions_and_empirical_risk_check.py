# Loss and empirical risk -- the check behind the card.  Standard library only.
# Data: 20,000 SYNTHETIC orders from a stated rule and seed (SplitMix64, written out).
from math import log, exp

MASK = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.x = seed
    def u(self):                                   # a uniform number in [0, 1)
        self.x = (self.x + 0x9E3779B97F4A7C15) & MASK
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

# the hidden rule: bias 4, then one weight per number; 5 of the 12 numbers do nothing
TRUE = [4.0, 6.0, 1.1, 0.4, -0.05, 0.0, 0.0, 3.0, 0.0, 2.0, 0.0, 0.0, 0.2]
def order(g):   # 1, items, avg price, past orders, days since last, mobile, hour,
    x = [1.0, 1 + int(8 * g.u()), 5 + 40 * g.u(), int(21 * g.u()), int(91 * g.u()),   # discount,
         float(g.u() < 0.6), int(24 * g.u()), float(g.u() < 0.25), 1 + 49 * g.u(),     # distance,
         float(g.u() < 0.3), 10 * g.u(), float(g.u() < 0.4), 1 + int(40 * g.u())]       # weekend, ...
    x = [float(v) for v in x]
    return x, sum(w * v for w, v in zip(TRUE, x)) - 30.0 * log(1.0 - g.u())   # skewed extra spend

def sq_risk(c, ys): return sum((y - c) ** 2 for y in ys) / len(ys)      # squared loss, averaged
def abs_risk(c, ys): return sum(abs(y - c) for y in ys) / len(ys)       # absolute loss, averaged
def median(ys):
    s = sorted(ys); n = len(s)
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2
def ternary(f, lo, hi):                            # road 2: search the bowl, no formula used
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if f(a) <= f(b): hi = b
        else: lo = a
    return (lo + hi) / 2

def fit(rows):                                     # least squares: solve (X^T X) w = X^T y
    p = len(rows[0][0])
    A = [[0.0] * (p + 1) for _ in range(p)]
    for x, y in rows:
        for i in range(p):
            for j in range(p): A[i][j] += x[i] * x[j]
            A[i][p] += x[i] * y
    for c in range(p):                             # Gaussian elimination, partial pivoting
        r = max(range(c, p), key=lambda k: abs(A[k][c])); A[c], A[r] = A[r], A[c]
        for k in range(c + 1, p):
            f = A[k][c] / A[c][c]
            for j in range(c, p + 1): A[k][j] -= f * A[c][j]
    w = [0.0] * p
    for c in range(p - 1, -1, -1):
        w[c] = (A[c][p] - sum(A[c][j] * w[j] for j in range(c + 1, p))) / A[c][c]
    return w
def risk(w, rows): return sum((y - sum(a * b for a, b in zip(w, x))) ** 2 for x, y in rows) / len(rows)

def show(label, *vals, d=2): print(f"{label:<36}" + " ".join(f"{v:10.{d}f}" for v in vals))

five = [14.0, 22.0, 27.0, 35.0, 102.0]             # worked by hand on the card
m5, d5 = sum(five) / 5, median(five)
show("five orders: mean, median", m5, d5)
show("five: squared sum at mean, median", 5 * sq_risk(m5, five), 5 * sq_risk(d5, five))
show("five: absolute sum at mean, median", 5 * abs_risk(m5, five), 5 * abs_risk(d5, five))
for c in (m5, d5):
    print(f"five at {c:.0f}: squared misses".ljust(36) + " ".join(f"{(y - c) ** 2:7.0f}" for y in five))
    print(f"five at {c:.0f}: absolute misses".ljust(36) + " ".join(f"{abs(y - c):7.0f}" for y in five))
show("five: squared risk at mean, median", sq_risk(m5, five), sq_risk(d5, five))
show("five: absolute risk at mean, median", abs_risk(m5, five), abs_risk(d5, five))
assert sq_risk(m5, five) < sq_risk(d5, five) and abs_risk(d5, five) < abs_risk(m5, five)

g = SplitMix64(20261111)
rows = [order(g) for _ in range(20000)]
train, test = rows[:16000], rows[16000:]          # the last 4,000 are never used to fit
ys, yt = [y for _, y in train], [y for _, y in test]
mean, med = sum(ys) / len(ys), median(ys)
t_sq, t_ab = ternary(lambda c: sq_risk(c, ys), 0, 500), ternary(lambda c: abs_risk(c, ys), 0, 500)
show("train: mean, median order value", mean, med)
show("ternary search: squared, absolute", t_sq, t_ab)
show("constant = mean: sq risk, abs risk", sq_risk(mean, ys), abs_risk(mean, ys))
show("constant = median: sq risk, abs risk", sq_risk(med, ys), abs_risk(med, ys))
assert abs(t_sq - mean) < 1e-6 and abs(abs_risk(t_ab, ys) - abs_risk(med, ys)) < 1e-9
assert sq_risk(mean, ys) < sq_risk(med, ys) and abs_risk(med, ys) < abs_risk(mean, ys)
gap = sq_risk(med, ys) - sq_risk(mean, ys)        # Step 1: the gap is exactly (median - mean)^2
show("sq risk gap, (median - mean)^2", gap, (med - mean) ** 2)
assert abs(gap - (med - mean) ** 2) < 1e-6
grid = [60 + 5 * i for i in range(15)]
print("chart, constant guess (pounds)     " + " ".join(f"{c:6d}" for c in grid))
print("chart, root mean square miss       " + " ".join(f"{sq_risk(c, ys) ** 0.5:6.2f}" for c in grid))
print("chart, mean absolute miss          " + " ".join(f"{abs_risk(c, ys):6.2f}" for c in grid))

w = fit(train)                                    # 13 weights: bias + one per number
show("fitted bias, items, avg price", w[0], w[1], w[2])
show("fitted mobile, hour, distance", w[5], w[6], w[8])
r_tr, r_te, r_true = risk(w, train), risk(w, test), risk([TRUE[0] + 30.0] + TRUE[1:], test)
show("12 numbers: train risk, test risk", r_tr, r_te)
show("true rule + 30 on test; 900(1+13/n)", r_true, 900 * (1 + 13 / 16000))
assert abs(w[1] - 6.0) < 0.3 and abs(w[2] - 1.1) < 0.05 and abs(w[6]) < 0.1   # the truth comes back
assert abs(r_te - 900 * (1 + 13 / 16000)) < 4 * 8 ** 0.5 * 900 / 4000 ** 0.5   # 4 SEs; (E - 30)^2 has SD sqrt(8) * 900
assert r_tr < sq_risk(mean, ys)
grad = [sum(2 * (sum(a * b for a, b in zip(w, x)) - y) * x[i] for x, y in train) / 16000 for i in range(13)]
show("largest slope of risk at the fit", max(abs(v) for v in grad))
assert max(abs(v) for v in grad) < 1e-6
pred = [sum(a * b for a, b in zip(w, x)) for x, _ in test]
show("test revenue: actual, linear", sum(yt), sum(pred))
show("test revenue: x mean, x median", 4000 * mean, 4000 * med)
show("pred - actual: linear, mean, median", sum(pred) - sum(yt), 4000 * mean - sum(yt), 4000 * med - sum(yt))

w20 = fit(train[:20])                             # what breaks: 13 weights from 20 orders
show("20-order fit: train risk, test risk", risk(w20, train[:20]), risk(w20, test))
assert risk(w20, train[:20]) < 0.5 * r_tr and risk(w20, test) > 1.5 * r_te
for k in (13, 100):                               # try: as many orders as weights, then more
    wk = fit(train[:k]); show(f"try: {k}-order fit: train, test risk", risk(wk, train[:k]), risk(wk, test))
typo = [y * 100 for y in ys[:100]] + ys[100:]    # 100 orders keyed in pence, not pounds
show("100 typos: mean, median", sum(typo) / len(typo), median(typo))
show("mean shift: run, 99*sum(first 100)/n", sum(typo) / len(typo) - mean, 99 * sum(ys[:100]) / 16000)
assert abs(sum(typo) / len(typo) - mean - 99 * sum(ys[:100]) / 16000) < 1e-9 and median(typo) - med < 1

margins = [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0]   # yes/no: will the order be returned?
print("margin m = y*s       " + " ".join(f"{m:7.4f}" for m in margins))
print("zero-one loss        " + " ".join(f"{float(m <= 0):7.4f}" for m in margins))
print("hinge max(0, 1-m)    " + " ".join(f"{max(0.0, 1 - m):7.4f}" for m in margins))
print("log ln(1+e^-m)       " + " ".join(f"{log(1 + exp(-m)):7.4f}" for m in margins))
ll = lambda p, q: -(q * log(p) + (1 - q) * log(1 - p))   # average log loss when a chance q comes true
hinge = lambda s, q: q * max(0.0, 1 - s) + (1 - q) * max(0.0, 1 + s)
for q in (0.1, 0.4):                              # 1 in 10 such orders comes back; try 4 in 10
    best_p = min((k / 1000 for k in range(1, 1000)), key=lambda p: ll(p, q))
    best_s = min((k / 100 for k in range(-300, 301)), key=lambda s: hinge(s, q))
    show(f"q = {q}: best p by grid, its log loss", best_p, ll(best_p, q), d=4)
    show(f"q = {q}: best score, its hinge", best_s, hinge(best_s, q), d=4)
    assert abs(best_p - q) < 1e-9 and abs(best_s + 1) < 1e-9 and abs(hinge(best_s, q) - 2 * q) < 1e-9
show("q = 0.1: log loss at p = 0.3, 0.5", ll(0.3, 0.1), ll(0.5, 0.1), d=4)
print("ALL CHECKS PASS")
