# Propensity scores and weighting -- the check behind the card.  Standard library only.
# Kidney stones (Charig et al. 1986): treatment A = open surgery, B = keyhole surgery.
from math import exp, log, sqrt
from bisect import bisect_left

def logistic(z): return 1.0 / (1.0 + exp(-z))

def fit(xs, ts):  # logistic regression of treatment on one covariate, Newton's method
    b0 = b1 = 0.0
    for _ in range(40):
        g0 = g1 = h00 = h01 = h11 = 0.0
        for x, t in zip(xs, ts):
            p = logistic(b0 + b1 * x); w = p * (1 - p)
            g0 += t - p; g1 += (t - p) * x; h00 += w; h01 += w * x; h11 += w * x * x
        det = h00 * h11 - h01 * h01
        b0 += (h11 * g0 - h01 * g1) / det; b1 += (h00 * g1 - h01 * g0) / det
    return b0, b1

def ipw(es, ts, ys):  # weighted means of Y(A), Y(B), each over its own weights; ATE and its SE
    n = len(ts)
    mA = sum(t * y / e for e, t, y in zip(es, ts, ys)) / sum(t / e for e, t in zip(es, ts))
    mB = sum((1 - t) * y / (1 - e) for e, t, y in zip(es, ts, ys)) / sum((1 - t) / (1 - e) for e, t in zip(es, ts))
    terms = [t * (y - mA) / e - (1 - t) * (y - mB) / (1 - e) for e, t, y in zip(es, ts, ys)]
    se = sqrt(sum(v * v for v in terms) / (n - 1) / n)
    return mA, mB, mA - mB, se

def match(es, ts, ys):  # fill each patient's missing outcome from the other arm at the nearest score
    pool = {0: {}, 1: {}}  # arm -> score -> [cured, patients]; tied scores are averaged
    for e, t, y in zip(es, ts, ys):
        c = pool[t].setdefault(e, [0, 0]); c[0] += y; c[1] += 1
    keys = {a: sorted(pool[a]) for a in (0, 1)}
    total = 0.0
    for e, t, y in zip(es, ts, ys):
        k = keys[1 - t]; j = bisect_left(k, e)
        if j == len(k) or (j > 0 and e - k[j - 1] <= k[j] - e): j -= 1
        c = pool[1 - t][k[j]]; other = c[0] / c[1]
        total += (y - other) if t == 1 else (other - y)
    return total / len(ts)

# ---- the table: (stone large?, got A?, patients, cured) ----
TABLE = [(0, 1, 87, 81), (1, 1, 263, 192), (0, 0, 270, 234), (1, 0, 80, 55)]
xs, ts, ys = [], [], []
for large, a, n, c in TABLE:
    for i in range(n): xs.append(large); ts.append(a); ys.append(1 if i < c else 0)
N, cnt = len(ts), {(l, a): (n, c) for l, a, n, c in TABLE}
nA = sum(ts); naive_A = sum(t * y for t, y in zip(ts, ys)) / nA
naive_B = sum((1 - t) * y for t, y in zip(ts, ys)) / (N - nA)
print(f"patients {N}; naive cure rate A {naive_A:.4f}, B {naive_B:.4f}, gap {100*(naive_A-naive_B):+.2f} points")
for l, name in ((0, "small"), (1, "large")):
    (na, ca), (nb, cb) = cnt[(l, 1)], cnt[(l, 0)]
    print(f"{name}: A {ca}/{na} = {ca/na:.4f}, B {cb}/{nb} = {cb/nb:.4f}, e = {na}/{na+nb} = {na/(na+nb):.4f}, "
          f"weights 1/e = {(na+nb)/na:.4f}, 1/(1-e) = {(na+nb)/nb:.4f}")
e_count = {l: cnt[(l, 1)][0] / (cnt[(l, 1)][0] + cnt[(l, 0)][0]) for l in (0, 1)}
b0, b1 = fit(xs, ts)
e_fit = {l: logistic(b0 + b1 * l) for l in (0, 1)}
print(f"logistic fit: b0 {b0:.4f}, b1 {b1:.4f}; e(small) {e_fit[0]:.4f}, e(large) {e_fit[1]:.4f}")
es = [e_fit[x] for x in xs]
mA, mB, ate, se = ipw(es, ts, ys)
print(f"1 IPW over {N} records: A {mA:.4f}, B {mB:.4f}, ATE {100*ate:+.2f} points (SE {100*se:.2f})")
for a, arm, f in ((1, "A", lambda e: 1 / e), (0, "B", lambda e: 1 / (1 - e))):
    parts = [(cnt[(l, a)][1], f(e_fit[l]), cnt[(l, a)][0]) for l in (0, 1)]
    print(f"  {arm}: cured " + " + ".join(f"{c} x {w:.4f} = {c*w:.1f}" for c, w, _ in parts)
          + f" -> {sum(c*w for c, w, _ in parts):.1f} / {N}; weights " + " + ".join(f"{n} x {w:.4f} = {n*w:.1f}" for _, w, n in parts))
share = {l: sum(cnt[(l, a)][0] for a in (0, 1)) / N for l in (0, 1)}
rate = {(l, a): cnt[(l, a)][1] / cnt[(l, a)][0] for l in (0, 1) for a in (0, 1)}  # cure rate by size and arm
bdA, bdB = (sum(share[l] * rate[l, a] for l in (0, 1)) for a in (1, 0))
se_bd = sqrt(sum(share[l] * ((rate[l, 1] - rate[l, 0] - bdA + bdB) ** 2 + rate[l, 1] * (1 - rate[l, 1]) / e_fit[l]
                 + rate[l, 0] * (1 - rate[l, 0]) / (1 - e_fit[l])) for l in (0, 1)) / N)  # size by size: score counted as fitted
print(f"2 back-door: A {bdA:.4f}, B {bdB:.4f}, ATE {100*(bdA-bdB):+.2f} points (SE {100*se_bd:.2f}, size by size); "
      f"size shares {share[0]:.4f}, {share[1]:.4f}")
m = match(es, ts, ys)
print(f"3 matching on the score, every patient: ATE {100*m:+.2f} points")
attm = sum(t * (y - (cnt[(x, 0)][1] / cnt[(x, 0)][0])) for x, t, y in zip(xs, ts, ys)) / nA
wB = [(1 - t) * e / (1 - e) for e, t in zip(es, ts)]
att_w = naive_A - sum(w * y for w, y in zip(wB, ys)) / sum(wB)
print(f"ATT (A patients only): matching {100*attm:+.2f} points, odds weights e/(1-e) {100*att_w:+.2f} points")
wsumA = sum(t / e for e, t in zip(es, ts)); wsumB = sum((1 - t) / (1 - e) for e, t in zip(es, ts))
bal = [sum(t * x for x, t in zip(xs, ts)) / nA, sum((1 - t) * x for x, t in zip(xs, ts)) / (N - nA),
       sum(t * x / e for x, e, t in zip(xs, es, ts)) / wsumA, sum((1 - t) * x / (1 - e) for x, e, t in zip(xs, es, ts)) / wsumB]
print(f"weights add to: A {wsumA:.1f}, B {wsumB:.1f}")
print("bars, cure percent, raw A, raw B, weighted A, weighted B: " + ", ".join(f"{100*v:.1f}" for v in (naive_A, naive_B, mA, mB)))
print("large-stone share, raw A, raw B, weighted A, weighted B: " + ", ".join(f"{100*v:.1f}" for v in bal))
essA = wsumA ** 2 / sum((t / e) ** 2 for e, t in zip(es, ts))
essB = wsumB ** 2 / sum(((1 - t) / (1 - e)) ** 2 for e, t in zip(es, ts))
print(f"overlap: e from {min(es):.4f} to {max(es):.4f}; largest weight {max(t / e + (1 - t) / (1 - e) for e, t in zip(es, ts)):.4f}; "
      f"effective sizes A {essA:.1f} of {nA}, B {essB:.1f} of {N-nA}")
# ---- what breaks ----
eA = sum(t * e * y for e, t, y in zip(es, ts, ys)) / sum(t * e for e, t in zip(es, ts))
eB = sum((1 - t) * (1 - e) * y for e, t, y in zip(es, ts, ys)) / sum((1 - t) * (1 - e) for e, t in zip(es, ts))
oneB = sum((1 - t) * y / e for e, t, y in zip(es, ts, ys)) / N
print(f"wrong: weight by e, not 1/e: A {eA:.4f}, B {eB:.4f}, gap {100*(eA-eB):+.2f} points")
print(f"wrong: 1/e for B patients too: B 'cure rate' {oneB:.4f}")

# ---- simulation: stone diameter in mm, a covariate with no strata ----
state = 20261123
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

NS = 20000
print(f"simulation: SplitMix64 seed 20261123, {NS} patients, diameter 2-20 mm")
res = {}
for label, slope in (("mild", 0.25), ("steep", 0.9)):
    d, t, y, truth = [], [], [], 0.0
    for _ in range(NS):
        x = 2.0 + 18.0 * rand()
        pA, pB = logistic(3.2 - 0.2 * x), logistic(2.6 - 0.2 * x)
        a = 1 if rand() < logistic(slope * (x - 11.0)) else 0
        u = rand()
        d.append(x); t.append(a); y.append(1 if u < (pA if a else pB) else 0); truth += pA - pB
    truth /= NS
    c0, c1 = fit(d, t); es = [logistic(c0 + c1 * x) for x in d]
    _, _, sate, sse = ipw(es, t, y)
    sm, na = match(es, t, y), sum(t)
    nv = sum(a * v for a, v in zip(t, y)) / na - sum((1 - a) * v for a, v in zip(t, y)) / (NS - na)
    print(f"  {label}: fitted slope {c1:.4f} (true {slope}); truth {100*truth:+.2f}; naive {100*nv:+.2f}; "
          f"IPW {100*sate:+.2f} (SE {100*sse:.2f}); matching {100*sm:+.2f}")
    w = [a / e + (1 - a) / (1 - e) for e, a in zip(es, t)]          # the weight each patient carries
    for g in (1, 0):                                                 # each arm: weights, effective size, balance
        r = [(v, x) for v, x, a in zip(w, d, t) if a == g]; tw, top = sum(v for v, _ in r), max(r)[0]
        print(f"    arm {'BA'[g]}: largest weight {top:.1f} ({100*top/tw:.1f}% of the arm's weight); "
              f"effective size {tw*tw / sum(v*v for v, _ in r):.0f} of {len(r)}; mean diameter "
              f"{sum(x for _, x in r)/len(r):.2f} mm raw, {sum(v*x for v, x in r)/tw:.2f} weighted")
    res[label] = (truth, nv, sate, sse, sm, c1, slope)

assert all(abs(e_fit[l] - e_count[l]) < 1e-9 for l in (0, 1)), "logistic fit must reproduce the counted shares"
assert abs(mA - bdA) < 1e-12 and abs(mB - bdB) < 1e-12, "IPW over records must equal the back-door formula"
assert abs(m - (bdA - bdB)) < 1e-12, "matching on the score must equal the back-door ATE"
assert abs(attm - att_w) < 1e-12, "ATT by matching must equal ATT by odds weights"
assert abs(bal[2] - share[1]) < 1e-12 and abs(bal[3] - share[1]) < 1e-12, "weighting must balance stone size"
assert naive_A < naive_B and bdA > bdB, "Simpson reversal: B looks better raw, A is better adjusted"
for truth, nv, sate, sse, sm, c1, slope in res.values():
    assert abs(sate - truth) < 4 * sse and abs(sm - truth) < 4 * sse, "IPW and matching within 4 SE of truth"
    assert abs(nv - truth) > 4 * sse, "the naive gap must be visibly biased"
assert res["steep"][3] > res["mild"][3], "poorer overlap must widen the standard error"
print("ALL CHECKS PASS")
