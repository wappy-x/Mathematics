# Support vector machines -- the check behind the card.  Standard library only.
# The solver is a pair-at-a-time climb on the dual (SMO), written out; the data
# come from a SplitMix64 generator written out, so Python and Rust agree.
from math import exp, sqrt, cos, sin, pi

M64 = (1 << 64) - 1
class Rng:                                       # SplitMix64, seed stated below
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def ring(rng, n, lo, hi):                        # n orders, uniform where lo <= distance < hi
    out = []
    while len(out) < n:
        a, b = 6 * rng.u() - 3, 6 * rng.u() - 3
        if lo * lo <= a * a + b * b < hi * hi: out.append((a, b))
    return out

def dot(p, q): return p[0] * q[0] + p[1] * q[1]
def rbf(g): return lambda p, q: exp(-g * ((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2))

def smo(X, y, K, C):                             # maximise sum(al) - 1/2 sum al_i al_j y_i y_j K_ij
    n = len(X); Kx = [[K(p, q) for q in X] for p in X]
    al, G = [0.0] * n, [-1.0] * n                # G: slope of the dual, tracked as al moves
    while True:
        up = [t for t in range(n) if (y[t] > 0 and al[t] < C) or (y[t] < 0 and al[t] > 0)]
        dn = [t for t in range(n) if (y[t] < 0 and al[t] < C) or (y[t] > 0 and al[t] > 0)]
        i = max(up, key=lambda t: -y[t] * G[t]); j = min(dn, key=lambda t: -y[t] * G[t])
        hi, lo = -y[i] * G[i], -y[j] * G[j]
        if hi - lo < 1e-9: break                 # no pair can still raise the dual
        t = (hi - lo) / max(Kx[i][i] + Kx[j][j] - 2 * Kx[i][j], 1e-12)
        t = min(t, C - al[i] if y[i] > 0 else al[i], al[j] if y[j] > 0 else C - al[j])
        al[i] += y[i] * t; al[j] -= y[j] * t
        for k in range(n): G[k] += y[k] * t * (Kx[k][i] - Kx[k][j])
    return al, (hi + lo) / 2, Kx

def score(X, y, al, b, K, x): return sum(al[k] * y[k] * K(X[k], x) for k in range(len(X)) if al[k] > 0) + b
def errors(X, y, al, b, K, T, z): return sum(1 for x, s in zip(T, z) if s * score(X, y, al, b, K, x) <= 0)
def weights(X, y, al): return [sum(al[k] * y[k] * X[k][d] for k in range(len(X))) for d in (0, 1)]

def widest_by_scan(H, F):                        # road 2: try every direction round the circle, 0.01 degree apart
    best, at = -1e9, 0
    for k in range(36000):
        u = (cos(k * pi / 18000), sin(k * pi / 18000))
        gap = min(dot(u, f) for f in F) - max(dot(u, h) for h in H)
        if gap > best: best, at = gap, k
    return best, at / 100

# ---- six orders: (amount score, hour score); honest -1, fraud +1 ----
H, F = [(0, 0), (1, 0), (0, 1)], [(2, 2), (3, 3), (4, 1)]
X6, y6 = H + F, [-1] * 3 + [1] * 3
al6, b6, _ = smo(X6, y6, dot, float('inf'))
w6 = weights(X6, y6, al6); nw = sqrt(dot(w6, w6))
scan, angle = widest_by_scan(H, F)
print("hard margin: alphas", " ".join(f"{a:.4f}" for a in al6))
print(f"w = ({w6[0]:.4f}, {w6[1]:.4f})  b = {b6:.4f}  |w| = {nw:.4f}  |w|^2 = {nw * nw:.4f}  sum of alphas = {sum(al6):.4f}")
print(f"widest margin: 2/|w| = {2 / nw:.4f}   scan = {scan:.4f} at {angle:.2f} deg   by hand 3/sqrt2 = {3 / sqrt(2):.4f}")
pw, pb, sweeps = [0.0, 0.0], 0.0, 0                # a perceptron's line, for contrast
while any(s * (dot(pw, x) + pb) <= 0 for x, s in zip(X6, y6)):
    sweeps += 1
    for x, s in zip(X6, y6):
        if s * (dot(pw, x) + pb) <= 0: pw, pb = [pw[0] + s * x[0], pw[1] + s * x[1]], pb + s
pgap = min(s * (dot(pw, x) + pb) for x, s in zip(X6, y6)) / sqrt(dot(pw, pw))
print(f"perceptron after {sweeps} sweeps: w = ({pw[0]:.0f}, {pw[1]:.0f}) b = {pb:.0f}  nearest order {pgap:.4f} away, svm {1 / nw:.4f}")
print(f"figure, centre x1 + x2 = {-b6 / w6[0]:.4f}, edges x1 + x2 = {(-1 - b6) / w6[0]:.4f} and {(1 - b6) / w6[0]:.4f}")

# ---- add a genuine big, late order in the middle of the fraud: slack ----
X7, y7 = X6 + [(3, 2)], y6 + [-1]
gap7, _ = widest_by_scan(H + [(3, 2)], F)
print(f"with honest (3, 2): best hard gap, scan = {gap7:.4f}, by hand -1/sqrt5 = {-1 / sqrt(5):.4f} (negative: no line works)")
for C in (1.0, 0.1):
    al, b, _ = smo(X7, y7, dot, C); w = weights(X7, y7, al)
    xi = [max(0.0, 1 - s * score(X7, y7, al, b, dot, x)) for x, s in zip(X7, y7)]
    print(f"C = {C:.1f}: w = ({w[0]:.4f}, {w[1]:.4f}) b = {b:.4f} width {2 / sqrt(dot(w, w)):.4f} slacks", " ".join(f"{v:.2f}" for v in xi))

# ---- the kernel trick: the same number from features and from the shortcut ----
p, q = (1.0, 0.0), (2.0, 2.0)
lift = lambda x: (x[0] * x[0], sqrt(2) * x[0] * x[1], x[1] * x[1])
print(f"(p.q)^2 = {dot(p, q) ** 2:.4f}  lift(p).lift(q) = {sum(a * c for a, c in zip(lift(p), lift(q))):.4f}")
term, total = 1.0, 0.0                          # e^(p.q) as 1 + p.q + (p.q)^2/2! + ...: one term per feature group
for k in range(1, 31): total, term = total + term, term * dot(p, q) / k
series = exp(-0.5 * dot(p, p)) * exp(-0.5 * dot(q, q)) * total
print(f"radial K(p, q), gamma 0.5: exp(-0.5*5) = {rbf(0.5)(p, q):.6f}  as 30-term feature series = {series:.6f}")
rng = Rng(2026); lifts = []
for _ in range(200):
    a, c = (6 * rng.u() - 3, 6 * rng.u() - 3), (6 * rng.u() - 3, 6 * rng.u() - 3)
    lifts.append(abs(dot(a, c) ** 2 - sum(s * t for s, t in zip(lift(a), lift(c)))))

print(f"generator: honest within 1.6, fraud from 1.2 to 3.0; in the overlap honest is {(120 / 2.56) / (40 / (9 - 1.44)):.2f}x as dense")
# ---- the fraud ring: 160 training orders, 400 test orders, all synthetic, seed 2026 ----
TR = ring(rng, 120, 0.0, 1.6) + ring(rng, 40, 1.2, 3.0); ytr = [-1] * 120 + [1] * 40
TE = ring(rng, 300, 0.0, 1.6) + ring(rng, 100, 1.2, 3.0); yte = [-1] * 300 + [1] * 100
def run(name, K, C, tr=TR, te=TE):
    al, b, Kx = smo(tr, ytr, K, C)
    sv = sum(1 for a in al if a > 1e-9)
    miss, alarm = errors(tr, ytr, al, b, K, te[300:], yte[300:]), errors(tr, ytr, al, b, K, te[:300], yte[:300])
    print(f"{name:<25} SVs {sv:>3}  train errors {errors(tr, ytr, al, b, K, tr, ytr):>2}/160  test: missed "
          f"fraud {miss:>3}/100, false alarms {alarm:>2}/300, total {miss + alarm:>3}/400")
    return al, b, Kx, miss
al, b, Kx, miss_rbf = run("radial, gamma 0.5, C 10", rbf(0.5), 10.0)
n = len(TR); quad = sum(al[i] * al[j] * ytr[i] * ytr[j] * Kx[i][j] for i in range(n) for j in range(n))
hinge = sum(max(0.0, 1 - ytr[i] * score(TR, ytr, al, b, rbf(0.5), TR[i])) for i in range(n))
primal, dual = quad / 2 + 10.0 * hinge, sum(al) - quad / 2
print(f"primal {primal:.6f}  dual {dual:.6f}  gap {primal - dual:.9f}")
for name, x in (("100 pounds, usual hour", (2.0, 0.0)), ("5 pounds, 9pm", (-2.75, 0.5)), ("70 pounds, 7pm", (0.5, -0.5))):
    print(f"order {name:<22} at ({x[0]:.2f}, {x[1]:.2f}): score {score(TR, ytr, al, b, rbf(0.5), x):+.4f}")
ideal = sum(1 for a, c in TE[300:] if a * a + c * c < 1.6 * 1.6)
print(f"ideal rule, flag beyond 1.6, on the test orders: missed fraud {ideal}/100, false alarms 0/300, total {ideal}/400")
radii = [next(r / 100 for r in range(400) if score(TR, ytr, al, b, rbf(0.5), (r / 100 * cos(d * pi / 180), r / 100 * sin(d * pi / 180))) > 0) for d in range(360)]
print(f"boundary radius on 360 rays: amount axis {radii[0]:.2f}, smallest {min(radii):.2f}, largest {max(radii):.2f}, mean {sum(radii) / 360:.2f}")
al_l, b_l, _, miss_line = run("linear SVM, C 10", dot, 10.0); w_l = weights(TR, ytr, al_l)
print(f"linear SVM answer: |w| = {sqrt(dot(w_l, w_l)):.6f}  b = {b_l:.4f}")
cut = (161, 0, 0.0)                              # every straight cut round the circle: the fewest training errors
for k in range(3600):
    u, e = (cos(2 * pi * k / 3600), sin(2 * pi * k / 3600)), 120     # cut below every order: all 120 honest flagged
    for t, s in sorted((dot(u, x), s) for x, s in zip(TR, ytr)):
        e += s; cut = min(cut, (e, k, t))        # move the cut past this order; flag only u.x > t
cut_err, k, t = cut; u = (cos(2 * pi * k / 3600), sin(2 * pi * k / 3600)); flag = lambda pts: sum(1 for x in pts if dot(u, x) > t)
cut_miss, cut_alarm, recount = 100 - flag(TE[300:]), flag(TE[:300]), 40 - flag(TR[120:]) + flag(TR[:120])
print(f"best straight cut, 3600 directions: flag u.x > {t:.4f} at {k / 10:.1f} deg  train errors {cut_err}/160  "
      f"test: missed fraud {cut_miss}/100, false alarms {cut_alarm}/300, total {cut_miss + cut_alarm}/400")
run("radial, gamma 50", rbf(50.0), 10.0)
run("radial, amount in pounds", rbf(0.5), 10.0, [(20 * a, c) for a, c in TR], [(20 * a, c) for a, c in TE])
run("try: radial, C 0.1", rbf(0.5), 0.1)
run("try: radial, gamma 2", rbf(2.0), 10.0)
print(f"full shop: kernel table 20000 x 20000 = {20000 * 20000 / 1e6:.0f} million entries, {20000 * 20000 * 8 / 1e9:.1f} GB")

assert abs(2 / nw - 3 / sqrt(2)) < 1e-9 and abs(scan - 3 / sqrt(2)) < 1e-6, "dual, scan and hand must agree"
assert abs(nw * nw - sum(al6)) < 1e-9, "at the optimum |w|^2 equals the sum of the alphas"
assert pgap < 1 / nw - 0.1, "the perceptron's line is a worse fit than the widest one"
assert abs(gap7 + 1 / sqrt(5)) < 1e-3, "scan meets the hand value: the seventh order makes the data inseparable"
assert max(lifts) < 1e-9 and abs(series - exp(-2.5)) < 1e-12, "kernel equals a dot product of features"
assert 0 <= primal - dual < 1e-6 * primal, "primal and dual meet at the optimum"
assert recount == cut_err and miss_rbf < cut_miss < miss_line, "recount meets the sweep; the radial loop misses less than the best straight cut"
assert abs(sum(radii) / 360 - 1.6) < 0.2, "the radial loop sits near the circle the data were cut at"
print("ALL CHECKS PASS")
