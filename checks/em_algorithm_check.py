# EM for two kinds of shopper -- the check behind the card.  Standard library only.
# The 20,000 order totals are synthetic: made by a stated rule and seed (SplitMix64, Box-Muller).
from math import exp, log, sqrt, pi, cos

MASK = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = z = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def uniform(self): return (self.next() >> 11) * 2.0 ** -53
    def normal(self):                                  # Box-Muller: two uniforms -> one bell draw
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def orders(n, share, m1, s1, m2, s2, seed=2026):       # spends, and the hidden label of each
    g, xs, weekly = SplitMix64(seed), [], []
    for _ in range(n):
        w = g.uniform() < share
        xs.append(m2 + s2 * g.normal() if w else m1 + s1 * g.normal()); weekly.append(w)
    return xs, weekly

def log_bell(x, m, s): return -0.5 * ((x - m) / s) * ((x - m) / s) - log(s * sqrt(2.0 * pi))
def mix(x, th):                    # ln of the two-bell density at x, and r = chance x is weekly
    a, m1, s1, m2, s2 = th
    l1, l2 = log(1.0 - a) + log_bell(x, m1, s1), log(a) + log_bell(x, m2, s2)
    hi = max(l1, l2); e1, e2 = exp(l1 - hi), exp(l2 - hi)
    return hi + log(e1 + e2), e2 / (e1 + e2)
def loglik(xs, th): return sum(mix(x, th)[0] for x in xs)

def m_step(xs, rs):                # weighted maximum likelihood: order i counts r_i as weekly
    n2 = sum(rs); n1 = len(xs) - n2
    m1 = sum((1 - r) * x for r, x in zip(rs, xs)) / n1
    m2 = sum(r * x for r, x in zip(rs, xs)) / n2
    s1 = sqrt(sum((1 - r) * (x - m1) * (x - m1) for r, x in zip(rs, xs)) / n1)
    s2 = sqrt(sum(r * (x - m2) * (x - m2) for r, x in zip(rs, xs)) / n2)
    return (n2 / len(xs), m1, s1, m2, s2)
def em_round(xs, th, hard=False, share_in_e=True):
    t = th if share_in_e else (0.5,) + th[1:]          # mistake: E-step ignores the share
    rs = [mix(x, t)[1] for x in xs]
    if hard: rs = [1.0 if r > 0.5 else 0.0 for r in rs]   # mistake: hard labels
    return m_step(xs, rs)
def run(xs, th, tol=1e-9, cap=1000, **kw):            # repeat until no parameter moves 1e-9
    lls, path = [loglik(xs, th)], [th]
    for k in range(1, cap + 1):
        new = em_round(xs, th, **kw); moved = max(abs(u - v) for u, v in zip(th, new)); th = new
        lls.append(loglik(xs, th)); path.append(th)
        if moved < tol: break
    return th, lls, k, path
def bound(xs, rs, th):             # the lower bound B: sum of r ln(part / r), 0 ln 0 = 0
    a, m1, s1, m2, s2 = th; b = 0.0
    for r, x in zip(rs, xs):
        if r < 1: b += (1 - r) * (log(1 - a) + log_bell(x, m1, s1) - log(1 - r))
        if r > 0: b += r * (log(a) + log_bell(x, m2, s2) - log(r))
    return b
def slopes(xs, th, h=1e-5):        # road 2: slope of ln-likelihood by nudging, no EM formulas
    out = []
    for i in range(5):
        up = list(th); dn = list(th); up[i] += h; dn[i] -= h
        out.append((loglik(xs, up) - loglik(xs, dn)) / (2 * h))
    return out
def show(th): return "share %.4f  top-up %.2f sd %.2f  weekly %.2f sd %.2f" % th

# ---- by hand: six orders, one round from a start of 20 and 60, spread 10, share 0.5 ----
six, start6 = [15.0, 22.0, 28.0, 40.0, 60.0, 75.0], (0.5, 20.0, 10.0, 60.0, 10.0)
r6 = [mix(x, start6)[1] for x in six]
for x, r in zip(six, r6):
    print("hand E  order %5.2f  x-40 %6.2f  odds e^(0.4(x-40)) %15.6f  r %.6f" % (x, x - 40, exp(0.4 * (x - 40)), r))
new6 = m_step(six, r6)
print("hand M  soft count weekly %.6f  top-up %.6f" % (sum(r6), 6 - sum(r6)))
print("hand M  sum of r*spend weekly %.6f  top-up %.6f" % (sum(r * x for r, x in zip(r6, six)), sum((1 - r) * x for r, x in zip(r6, six))))
print("hand M ", show(new6))
l_old, b_old, b_new, l_new = loglik(six, start6), bound(six, r6, start6), bound(six, r6, new6), loglik(six, new6)
print("hand ln-lik before %.6f  bound before %.6f  bound after %.6f  ln-lik after %.6f" % (l_old, b_old, b_new, l_new))
fit6, lls6, k6, _ = run(six, start6)
print("six orders settle after %d rounds: %s  ln-lik %.6f" % (k6, show(fit6), lls6[-1]))

# ---- the shop: 20,000 orders, 35% weekly shoppers N(70, 15), the rest top-ups N(25, 6) ----
xs, weekly = orders(20000, 0.35, 25.0, 6.0, 70.0, 15.0)
print("orders %d  hidden weekly %d  smallest %.2f  largest %.2f" % (len(xs), sum(weekly), min(xs), max(xs)))
start = (0.5, 30.0, 20.0, 50.0, 20.0)
fit, lls, rounds, path = run(xs, start)
for k in (0, 1, 2, 3, 5, 10, 20):
    print("round %2d  %s  ln-lik %.1f" % (k, show(path[k]), lls[k]))
print("settled after %d rounds: %s  ln-lik %.1f" % (rounds, show(fit), lls[-1]))
gains = [lls[k + 1] - lls[k] for k in range(rounds)]
print("chart, ln-lik rounds 0-15:", " ".join("%.0f" % v for v in lls[:16]))
print("rounds where ln-lik fell: %d of %d" % (sum(1 for g in gains if g < -1e-9), rounds))
lab = m_step(xs, [1.0 if w else 0.0 for w in weekly])
print("labels known: %s" % show(lab))
sl_fit, sl_start = slopes(xs, fit), slopes(xs, start)
print("largest slope at the fit %.6f  at the start %.1f" % (max(abs(v) for v in sl_fit), max(abs(v) for v in sl_start)))
rr = [mix(x, fit)[1] for x in (30.0, 35.0, 40.0, 45.0, 50.0)]
print("r at 30 35 40 45 50:", " ".join("%.3f" % v for v in rr))
lo, hi = 30.0, 60.0
for _ in range(60):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if mix(mid, fit)[1] < 0.5 else (lo, mid)
print("an order is even odds at %.2f" % lo)

# ---- what breaks ----
hard, _, _, _ = run(xs, start, hard=True)
print("hard labels: %s  ln-lik %.1f" % (show(hard), loglik(xs, hard)))
noshare, _, _, _ = run(xs, start, share_in_e=False)
print("share left out of E: %s  ln-lik %.1f" % (show(noshare), loglik(xs, noshare)))
sym, lsym, ks, _ = run(xs, (0.5, 40.0, 20.0, 40.0, 20.0))
print("same start for both: %s  ln-lik %.1f  after %d rounds" % (show(sym), lsym[-1], ks))
th, sig, ll = (0.05, 40.0, 25.0, 130.0, 2.0), [], []
while th[4] > 0 and len(sig) < 12:                    # run until the spread is exactly zero
    th = em_round(xs, th); sig.append(th[4]); ll.append(loglik(xs, th) if th[4] > 0 else float("nan"))
print("needle start: weekly sd by round", " ".join("%.4f" % v for v in sig[:-2]), "then %.2e, then exactly %.1f" % (sig[-2], sig[-1]))
print("needle start: ln-lik by round", " ".join("%.1f" % v for v in ll[:-1]), "then none: the bell formula divides by the zero spread")
print("needle start: weekly bell sits on %.2f, share %.6f" % (th[3], th[0]))

# ---- the picture: spend histogram in 10-pound bins, and the fitted two-bell curve ----
counts = [sum(1 for x in xs if 10 * b <= x < 10 * b + 10) for b in range(14)]
area = lambda a, b, n=100: sum((1 if j in (0, n) else 4 if j % 2 else 2) * exp(mix(a + j * (b - a) / n, fit)[0]) for j in range(n + 1)) * (b - a) / (3 * n)
print("chart, orders per bin:", " ".join(str(c) for c in counts))
print("chart, fitted per bin:", " ".join("%.0f" % (20000 * area(10 * b, 10 * b + 10)) for b in range(14)))

# ---- try changing ----
near, _ = orders(20000, 0.35, 25.0, 6.0, 45.0, 15.0)
fn, _, kn2, _ = run(near, start)
print("try: weekly mean 45, rounds %d: %s" % (kn2, show(fn)))
small, _ = orders(200, 0.35, 25.0, 6.0, 70.0, 15.0)
fs, _, _, _ = run(small, start)
print("try: 200 orders: %s" % show(fs))
sw, _, _, _ = run(xs, (0.5, 50.0, 20.0, 30.0, 20.0))
print("try: starts swapped: %s" % show(sw))

assert all(g > -1e-9 for g in gains) and all(b - a > -1e-9 for a, b in zip(lls6, lls6[1:])), "EM never lowers ln-lik"
assert abs(b_old - l_old) < 1e-9 and l_old < b_new <= l_new, "bound touches before, sandwiched after"
assert max(abs(v) for v in sl_fit) < 0.01 < max(abs(v) for v in sl_start), "fit is a flat point; start is not"
assert abs(fit[0] - lab[0]) < 0.01 and all(abs(fit[i] - lab[i]) < 0.5 for i in range(1, 5)), "EM finds the labelled fit"
assert abs(sym[1] - sym[3]) < 1e-9 and lsym[-1] < lls[-1] - 1000, "identical start never splits"
assert sig[-1] == 0.0 and all(b > a for a, b in zip(ll, ll[1:-1])), "needle start climbs, then collapses onto one order"
print("ALL CHECKS PASS")
