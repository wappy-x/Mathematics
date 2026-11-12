# Softmax and cross-entropy -- the check behind the card.  Standard library only.
# 20,000 synthetic orders (SplitMix64, seed 2026), one feature: weight in kg.
# Classes 0 letter, 1 parcel, 2 pallet.  Letter's score is pinned at 0.
from math import exp, log, log2, inf
M64 = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
def softmax(z):                        # subtract the largest score, exponentiate, divide by the total
    m = max(z); e = [exp(t - m) for t in z]; s = sum(e)
    return [t / s for t in e]
def naive_softmax(z):                  # no shift: fails once a score passes about 709
    try: e = [exp(t) for t in z]
    except OverflowError: return None
    return [t / sum(e) for t in e]
def ce_bits(p, q):                     # cross-entropy H(p, q) in bits; infinite if q misses a p outcome
    if any(pk > 0 and qk == 0 for pk, qk in zip(p, q)): return inf
    return -sum(pk * log2(qk) for pk, qk in zip(p, q) if pk > 0)
def scores(th, x): return [0.0, th[0] + th[1] * x, th[2] + th[3] * x]
TRUE = [-3.0, 2.0, -13.0, 2.5]         # the rule the synthetic orders were drawn from
def out(label, *v): print(f"{label:<34}" + "".join(f"{t:>10.4f}" for t in v))
s, X, Y = 2026, [], []
for i in range(20000):
    s, u = splitmix(s); x = 0.1 * 500.0 ** u          # weights spread evenly in ratio, 0.1 to 50 kg
    s, u = splitmix(s); p = softmax(scores(TRUE, x))
    X.append(x); Y.append(0 if u < p[0] else (1 if u < p[0] + p[1] else 2))
n = len(X); counts = [Y.count(k) for k in range(3)]
def nll_bits(z, c):                    # -log2 of softmax(z)[c] in one step: -z_c + log-sum-exp, shifted
    m = max(z); return (m - z[c] + log(sum(exp(t - m) for t in z))) / log(2)
def risk(th, labels=None):             # average loss in bits over the orders
    return sum(nll_bits(scores(th, x), c) for x, c in zip(X, labels or Y)) / n
def grad_hess(th):                     # gradient and curvature of the average loss, in nats
    g = [0.0] * 4; H = [[0.0] * 4 for _ in range(4)]
    for x, c in zip(X, Y):
        q = softmax(scores(th, x)); f = (1.0, x)
        for a in range(2):
            for i in range(2):
                g[2*a+i] += (q[a+1] - (c == a + 1)) * f[i] / n
                for b in range(2):
                    for j in range(2):
                        H[2*a+i][2*b+j] += q[a+1] * ((a == b) - q[b+1]) * f[i] * f[j] / n
    return g, H
def solve(H, g):                       # Gaussian elimination, 4 by 4
    A = [H[r][:] + [g[r]] for r in range(4)]
    for c in range(4):
        for r in range(c + 1, 4):
            m = A[r][c] / A[c][c]
            for k in range(c, 5): A[r][k] -= m * A[c][k]
    d = [0.0] * 4
    for r in range(3, -1, -1):
        d[r] = (A[r][4] - sum(A[r][k] * d[k] for k in range(r + 1, 4))) / A[r][r]
    return d
th, trace = [0.0] * 4, []
for step in range(30):                 # road 1: Newton's method on the average cross-entropy
    trace.append(risk(th)); g, H = grad_hess(th)
    if max(abs(t) for t in g) < 1e-10: break
    th = [a - d for a, d in zip(th, solve(H, g))]
R = trace[-1]
print("orders by class (letter, parcel, pallet):", *counts)
out("fitted b_parcel w_parcel", th[0], th[1]); out("fitted b_pallet w_pallet", th[2], th[3]); out("true rule b1 w1 b2 w2", *TRUE)
out("class boundaries, kg", -th[0] / th[1], (th[0] - th[2]) / (th[3] - th[1]))
print("loss by Newton step, bits:", " ".join(f"{t:.4f}" for t in trace))
out("fitted loss R, bits; perplexity", R, 2 ** R)
out("blind guess log2 3; perplexity", log2(3), 3.0)
# road 2: nudge every parameter both ways; the loss must rise each time
nudged = [risk([t + (h if k == j else 0) for k, t in enumerate(th)]) for j in range(4) for h in (0.01, -0.01)]
out("smallest nudge rise, micro-bits", (min(nudged) - R) * 1e6); assert min(nudged) > R
# road 3: at the minimum the predicted counts equal the observed counts
pred = [sum(softmax(scores(th, x))[k] for x in X) for k in range(3)]
out("predicted counts", *pred); assert all(abs(a - b) < 1e-6 for a, b in zip(pred, counts))
# consistency check: class shares only; their loss is the entropy of the shares
sh = [c / n for c in counts]
th0 = [log(sh[1] / sh[0]), 0.0, log(sh[2] / sh[0]), 0.0]
out("shares only: loss; entropy H", risk(th0), ce_bits(sh, sh)); assert abs(risk(th0) - ce_bits(sh, sh)) < 1e-9
out("bits saved by knowing weight", risk(th0) - R)
# road 4: truth against fit.  H(p, q) = H(p) + D(p || q), order by order, is a consistency check
Hp = Hpq = Dpq = sq = 0.0
for x in X:
    p, q = softmax(scores(TRUE, x)), softmax(scores(th, x))
    Hp += ce_bits(p, p) / n; Hpq += ce_bits(p, q) / n
    Dpq += sum(pk * log2(pk / qk) for pk, qk in zip(p, q)) / n
for x, c in zip(X, Y): sq += (nll_bits(scores(th, x), c) - R) ** 2 / n
se = (sq / n) ** 0.5
out("floor H(p); H(p,q); D(p||q)", Hp, Hpq, Dpq); out("true rule's loss on the orders", risk(TRUE))
assert abs(Hpq - (Hp + Dpq)) < 1e-9 and Dpq > 0
out("fitted loss vs H(p,q): gap, SE", R - Hpq, se); assert abs(R - Hpq) < 4 * se
W = 2 * n * log(2) * (risk(TRUE) - R)  # Wilks: twice the fit's log-likelihood gain over the rule, in nats
chance = exp(-W / 2) * (1 + W / 2)     # chi-square, 4 degrees of freedom: the chance of a gain above W
out("fit vs rule: 2 ln LR; chance", W, chance); assert chance > 0.001
# the worked order: 2 kg, packed as a parcel
z = scores(th, 2.0); q = softmax(z); m = max(z); e = [exp(t - m) for t in z]
out("2 kg: scores", *z); out("2 kg: shifted scores", *[t - m for t in z]); out("2 kg: exp", *e)
out("2 kg: total; probabilities", sum(e), *q)
out("2 kg: odds parcel to letter", q[1] / q[0], exp(z[1] - z[0])); assert abs(q[1] / q[0] - exp(z[1] - z[0])) < 1e-12
out("2 kg: loss bits if L, P, Pal", *[-log2(t) for t in q]); out("2 kg: loss in nats if parcel", -log(q[1]))
gz = [qk - (k == 1) for k, qk in enumerate(q)]; out("2 kg: gradient q - y", *gz)
fd = []
for k in range(3):                     # road 5: the gradient by finite differences, in nats
    zp = z[:]; zm = z[:]; zp[k] += 1e-6; zm[k] -= 1e-6
    fd.append((log(softmax(zm)[1]) - log(softmax(zp)[1])) / 2e-6)
out("2 kg: gradient by nudging", *fd); assert all(abs(a - b) < 1e-6 for a, b in zip(gz, fd))
lam = 1 / (1 + exp(-(z[1] - z[0])))    # road 6: two classes give the logistic curve
out("two classes: softmax; logistic", softmax(z[:2])[1], lam); assert abs(softmax(z[:2])[1] - lam) < 1e-12
# what breaks
raw = [t / sum(z) + 0.0 for t in z]; out("wrong: scores / their sum", *raw)
big = scores(th, 400.0); print(f"{'wrong: no shift, 400 kg':<34}", "overflow" if naive_softmax(big) is None else "ok")
out("400 kg pallet score; right answer", big[2], *softmax(big))
out("wrong: ln as bits; nats per bit", -log(q[1]), log(2)); out("wrong: arguments swapped H(q, y)", ce_bits(q, [0.0, 1.0, 0.0]))
out("2 kg order labelled pallet, bits", -log2(q[2])); out("  = this many average orders", -log2(q[2]) / R)
out("loss at 0.51, 0.99; at 0.49, 0.01", *[-log2(t) for t in (0.51, 0.99, 0.49, 0.01)])
# try changing
out("try: 20 kg order", *softmax(scores(th, 20.0)))
out("try: every score + 100", *softmax([t + 100 for t in z])); out("try: every score x 2", *softmax([2 * t for t in z]))
print("chart, kg", *range(0, 37, 2))
for k, name in enumerate(("letter", "parcel", "pallet")):
    print(f"chart, {name}", " ".join(f"{softmax(scores(th, float(w)))[k]:.2f}" for w in range(0, 37, 2)))
print("ALL CHECKS PASS")
