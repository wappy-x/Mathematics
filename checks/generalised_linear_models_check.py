# Generalised linear models -- the check behind the card.  Standard library only.
# Help-desk emails per hour against staff on shift, fitted as a Poisson GLM with a log link.
# Roads: IRLS, a Newton step from the slope and curvature formulas, and a one-unknown root search;
# the deviance from its formula and from log-likelihoods; least squares as the same recipe.
import math

def irls(x, y, off, b, steps, family="poisson"):
    trace = []
    for _ in range(steps):
        eta = [b[0] + b[1] * xi + o for xi, o in zip(x, off)]
        if family == "poisson":   # log link: mu = e^eta, V(mu) = mu, g'(mu) = 1/mu, weight mu
            mu = [math.exp(e) for e in eta]
            z = [e - o + (yi - m) / m for e, o, yi, m in zip(eta, off, y, mu)]
            w = mu
        else:                     # normal family, identity link: weight 1, working response y
            z, w = list(y), [1.0] * len(y)
        s0 = sum(w); s1 = sum(wi * xi for wi, xi in zip(w, x)); s2 = sum(wi * xi * xi for wi, xi in zip(w, x))
        t0 = sum(wi * zi for wi, zi in zip(w, z)); t1 = sum(wi * xi * zi for wi, xi, zi in zip(w, x, z))
        det = s0 * s2 - s1 * s1
        b = [(s2 * t0 - s1 * t1) / det, (s0 * t1 - s1 * t0) / det]
        trace.append(b)
    return b, trace

def means(x, off, b): return [math.exp(b[0] + b[1] * xi + o) for xi, o in zip(x, off)]
def deviance(y, mu): return 2 * sum((yi * math.log(yi / m) if yi > 0 else 0.0) - (yi - m) for yi, m in zip(y, mu))
def loglik(y, mu): return sum(yi * math.log(m) - m - sum(math.log(k) for k in range(2, yi + 1)) for yi, m in zip(y, mu))
def phi(v):               # normal CDF from the Taylor series of erf
    u = v / math.sqrt(2); term = u; s = u
    for n in range(1, 120):
        term *= -u * u / n; s += term / (2 * n + 1)
    return 0.5 + s / math.sqrt(math.pi)
def info_inv11(x, mu):    # the slope's entry of the inverse of the information table X'WX
    s0 = sum(mu); s1 = sum(m * xi for m, xi in zip(mu, x)); s2 = sum(m * xi * xi for m, xi in zip(mu, x))
    return s0 / (s0 * s2 - s1 * s1)
f4 = lambda v: f"{0.0 if abs(v) < 5e-5 else v:.4f}"
j4 = lambda vs: " ".join(f4(v) for v in vs)

x, y, n = [1, 2, 3, 4], [14, 10, 7, 5], 4
zero = [0.0] * n
ybar = sum(y) / n
b_start = [math.log(ybar), 0.0]
print("data: staff", x, "emails", y, "| mean", f4(ybar), "| start b0 = ln(mean)", f4(b_start[0]))

# ---- one IRLS step by hand: every mean is 9, every weight 9, so the step is plain least squares ----
zs = [b_start[0] + (yi - ybar) / ybar for yi in y]
print("step 1 working response z:", j4(zs), "| weights all", f4(ybar))
print("  z - ln(mean):", j4([(yi - ybar) / ybar for yi in y]), "| mean staff 2.5000 | Sxz",
      f4(sum((xi - 2.5) * (zi - b_start[0]) for xi, zi in zip(x, zs))), "| Sxx 5.0000")
b1, _ = irls(x, y, zero, b_start, 1)
hand_slope = sum((xi - 2.5) * (yi - ybar) for xi, yi in zip(x, y)) / ybar / 5.0
print("after step 1: b0", f4(b1[0]), "b1", f4(b1[1]), "| by hand, Sxz/Sxx =", f4(hand_slope))
assert abs(b1[1] - hand_slope) < 1e-12

# ---- road 1 and road 2: the same step as Newton's method on the log-likelihood ----
mu0 = means(x, zero, b_start)
g0 = sum(yi - m for yi, m in zip(y, mu0)); g1 = sum(xi * (yi - m) for xi, yi, m in zip(x, y, mu0))
h00 = sum(mu0); h01 = sum(m * xi for m, xi in zip(mu0, x)); h11 = sum(m * xi * xi for m, xi in zip(mu0, x))
det = h00 * h11 - h01 * h01
newton = [b_start[0] + (h11 * g0 - h01 * g1) / det, b_start[1] + (h00 * g1 - h01 * g0) / det]
print("Newton step from slopes", f4(g0), f4(g1), "->", f4(newton[0]), f4(newton[1]))
assert abs(newton[0] - b1[0]) < 1e-12 and abs(newton[1] - b1[1]) < 1e-12

b, trace = irls(x, y, zero, b_start, 25)
print("IRLS slope b1 after steps 1-4:", " ".join(f"{t[1]:.10f}" for t in trace[:4]))
mu = means(x, zero, b)
print("fit: b0", f4(b[0]), "b1", f4(b[1]), "| multiplier e^b1", f4(math.exp(b[1])), "| e^b0", f4(math.exp(b[0])))
print("fitted means:", j4(mu), "| sum", f4(sum(mu)), "observed", sum(y))
assert abs(sum(mu) - sum(y)) < 1e-9

# ---- road 3: the intercept equation solved exactly, then one unknown by bisection ----
def slope_eq(c):
    a = math.log(sum(y) / sum(math.exp(c * xi) for xi in x))
    return sum(xi * (yi - math.exp(a + c * xi)) for xi, yi in zip(x, y))
lo, hi = -2.0, 2.0
for _ in range(200):
    mid = (lo + hi) / 2
    if slope_eq(mid) > 0: lo = mid
    else: hi = mid
print("bisection on the slope equation: b1", f"{lo:.10f}", "| IRLS", f"{b[1]:.10f}")
assert abs(lo - b[1]) < 1e-9

# ---- standard error, Wald interval ----
se = math.sqrt(info_inv11(x, mu))
zw = b[1] / se
print("SE(b1)", f4(se), "| z", f4(zw), "| two-sided p", f4(2 * phi(zw)))
print("95% interval for the multiplier:", f4(math.exp(b[1] - 1.96 * se)), "to", f4(math.exp(b[1] + 1.96 * se)))
lo_z, steps = -8.0, 4000; h = (zw - lo_z) / steps     # Simpson's rule on the bell curve, a second road to Phi
simpson = sum((1 if k in (0, steps) else 4 if k % 2 else 2) * math.exp(-(lo_z + k * h) ** 2 / 2)
              for k in range(steps + 1)) * h / 3 / math.sqrt(2 * math.pi)
assert abs(simpson - phi(zw)) < 1e-4
def prof(c):              # log-likelihood with the intercept set by its own equation: a second road to the SE
    a = math.log(sum(y) / sum(math.exp(c * xi) for xi in x)); return loglik(y, [math.exp(a + c * xi) for xi in x])
dc = 1e-4; curv = (prof(b[1] + dc) - 2 * prof(b[1]) + prof(b[1] - dc)) / dc ** 2
assert abs(1 / math.sqrt(-curv) - se) < 1e-5

# ---- deviance, two roads ----
D0 = deviance(y, [ybar] * n); D = deviance(y, mu); drop = D0 - D
lr = 2 * (loglik(y, mu) - loglik(y, [ybar] * n))
p_drop = 2 * (1 - phi(math.sqrt(drop)))
print("null deviance", f4(D0), "on 3 df | residual deviance", f4(D), "on 2 df")
print("drop", f4(drop), "| 2 x log-likelihood gain", f4(lr), "| chi-square(1) p", f4(p_drop))
print("residual deviance chi-square(2) p", f4(math.exp(-D / 2)))
assert abs(drop - lr) < 1e-9
x2 = sum((yi - m) ** 2 / m for yi, m in zip(y, mu))
print("Pearson X2", f"{x2:.6f}", "| dispersion X2/(n-2)", f"{x2 / 2:.6f}")

# ---- prediction, and the same recipe as least squares ----
print("Poisson prediction at 6 staff", f4(math.exp(b[0] + 6 * b[1])))
bl, _ = irls(x, y, zero, [0.0, 0.0], 1, family="normal")
ols_b1 = sum((xi - 2.5) * (yi - ybar) for xi, yi in zip(x, y)) / 5.0
print("normal family, identity link, one step: b0", f4(bl[0]), "b1", f4(bl[1]), "| closed form b1", f4(ols_b1))
print("straight-line prediction at 6 staff", f4(bl[0] + 6 * bl[1]))
print("chart, staff 1-6: Poisson", " ".join(f"{math.exp(b[0] + b[1] * s):.2f}" for s in range(1, 7)),
      "| line", " ".join(f"{bl[0] + bl[1] * s:.2f}" for s in range(1, 7)))
assert abs(bl[1] - ols_b1) < 1e-12

# ---- an offset for exposure: totals over different hours ----
hours, tot = [1, 2, 1, 3], [14, 20, 7, 15]
logh = [math.log(t) for t in hours]
bo, _ = irls(x, tot, logh, [math.log(sum(tot) / sum(hours)), 0.0], 25)
bn, _ = irls(x, tot, zero, [math.log(sum(tot) / n), 0.0], 25)
print("hours", hours, "totals", tot, "| with offset ln(hours): b1", f4(bo[1]), "multiplier", f4(math.exp(bo[1])))
print("offset dropped: b1", f4(bn[1]), "multiplier", f4(math.exp(bn[1])))
eqs = lambda ys, f: abs(sum(yi - m for yi, m in zip(ys, f))) + abs(sum(xi * (yi - m) for xi, yi, m in zip(x, ys, f)))
assert eqs(tot, means(x, logh, bo)) < 1e-9 and eqs(tot, means(x, zero, bn)) < 1e-9   # both fits solve their likelihood equations

# ---- overdispersion: a noisier week ----
yn = [18, 7, 10, 3]
bw, _ = irls(x, yn, zero, [math.log(sum(yn) / n), 0.0], 25)
mw = means(x, zero, bw)
phw = sum((yi - m) ** 2 / m for yi, m in zip(yn, mw)) / 2
sw = math.sqrt(info_inv11(x, mw))
print("noisy week", yn, ": b1", f4(bw[1]), "| dispersion", f4(phw), "| SE", f4(sw), "-> scaled", f4(sw * math.sqrt(phw)))
assert eqs(yn, mw) < 1e-9 and abs(phw * (n - 2) - (sum(yi * yi / m for yi, m in zip(yn, mw)) - sum(yn))) < 1e-9   # X2 = sum y^2/mu - sum y at the fit

# ---- what breaks ----
print("mistake: b1 read as emails per person", f4(b[1]), "| fitted change 1 -> 2 staff", f4(mu[1] - mu[0]))
print("ALL CHECKS PASS")
