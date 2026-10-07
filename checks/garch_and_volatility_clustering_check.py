# GARCH and volatility clustering -- the check behind the card.  Standard library
# only.  Returns are in percent a day, variances in percent-squared.  The share is
# simulated from a known GARCH(1,1), so every fitted number can be graded.
from math import log, sqrt, cos, pi
W, A, B, N = 0.05, 0.08, 0.90, 2500           # the true omega, alpha, beta; ten years

class SplitMix64:                             # random numbers, same in both languages
    def __init__(self, seed): self.s = seed
    def uniform(self):
        M = (1 << 64) - 1; self.s = z = (self.s + 0x9E3779B97F4A7C15) & M
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                         # Box-Muller, the cosine half only
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

rng, h, r = SplitMix64(2026), W / (1 - A - B), []
for t in range(250 + N):                      # road one: simulate; 250 warm-up days dropped
    x = sqrt(h) * rng.normal()
    if t >= 250: r.append(x)
    h = W + A * x * x + B * h
sq = [x * x for x in r]; S2 = sum(sq) / N     # variance about zero; also the seed h_1
def path(w, a, b):                            # h_1 .. h_{N+1}, each known the evening before
    hs = [S2]
    for x2 in sq: hs.append(w + a * x2 + b * hs[-1])
    return hs
def loglik(p):                                # Gaussian log-likelihood of all N days
    w, a, b = p
    if w < 0 or a < 0 or b < 0 or a + b > 1: return -1e300
    return -0.5 * sum(log(2 * pi * v) + x2 / v for v, x2 in zip(path(w, a, b), sq))

def nelder_mead(f, x0, step, iters=600):      # climb to the top without derivatives
    pts = [x0] + [[x0[j] + (step if j == i else 0.0) for j in range(3)] for i in range(3)]
    val = [f(p) for p in pts]
    for _ in range(iters):
        o = sorted(range(4), key=lambda i: -val[i])
        pts, val = [pts[i] for i in o], [val[i] for i in o]
        c = [(pts[0][j] + pts[1][j] + pts[2][j]) / 3 for j in range(3)]
        mv = lambda k: [c[j] + k * (pts[3][j] - c[j]) for j in range(3)]
        xr = mv(-1.0); fr = f(xr)
        if fr > val[0]:
            xe = mv(-2.0); fe = f(xe)
            pts[3], val[3] = (xe, fe) if fe > fr else (xr, fr)
        elif fr > val[2]: pts[3], val[3] = xr, fr
        else:
            xc = mv(0.5); fc = f(xc)
            if fc > val[3]: pts[3], val[3] = xc, fc
            else:                             # shrink everything towards the best point
                pts = [pts[0]] + [[(pts[0][j] + p[j]) / 2 for j in range(3)] for p in pts[1:]]
                val = [val[0]] + [f(p) for p in pts[1:]]
    return pts[0], val[0]
est, ll_g = nelder_mead(loglik, [0.1, 0.1, 0.8], 0.05)
w, a, b = est; phi = a + b; lr = w / (1 - phi); rho1 = a * (1 - a * b - b * b) / (1 - 2 * a * b - b * b)
psi = [1.0] + [(phi - b) * phi ** (j - 1) for j in range(1, 4001)]; rho1_w = sum(p * q for p, q in zip(psi, psi[1:])) / sum(p * p for p in psi)
d = [1e-3 * v for v in est]                   # curvature of the peak, by differences
def bump(i, j, si, sj):
    q = list(est); q[i] += si * d[i]; q[j] += sj * d[j]; return loglik(q)
H = [[-(bump(i, j, 1, 1) - bump(i, j, 1, -1) - bump(i, j, -1, 1) + bump(i, j, -1, -1))
      / (4 * d[i] * d[j]) for j in range(3)] for i in range(3)]
det = sum(H[0][j] * (H[1][(j + 1) % 3] * H[2][(j + 2) % 3] - H[1][(j + 2) % 3] * H[2][(j + 1) % 3]) for j in range(3))
V = [[(H[(j + 1) % 3][(i + 1) % 3] * H[(j + 2) % 3][(i + 2) % 3]
       - H[(j + 1) % 3][(i + 2) % 3] * H[(j + 2) % 3][(i + 1) % 3]) / det for j in range(3)] for i in range(3)]
se, se_phi = [sqrt(V[i][i]) for i in range(3)], sqrt(V[1][1] + V[2][2] + 2 * V[1][2])
g = [1 / (1 - phi), lr / (1 - phi), lr / (1 - phi)]   # delta method for the long-run level
se_lr = sqrt(sum(g[i] * V[i][j] * g[j] for i in range(3) for j in range(3)))

grid = max((loglik([S2 * (1 - ga - gb), ga, gb]), ga, gb)       # road two: a grid, with
           for ga in [0.01 * i for i in range(1, 21)]            # omega pinned by the
           for gb in [0.70 + 0.01 * j for j in range(30)] if ga + gb < 1)  # sample variance

lo, hi = 0.80, 0.999                          # EWMA's one knob, by golden section
ll_e = lambda lam: loglik([0.0, 1 - lam, lam])
for _ in range(60):
    m1, m2 = hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)
    if ll_e(m1) < ll_e(m2): lo = m1
    else: hi = m2
lam = (lo + hi) / 2; se_lam = sqrt(-1e-6 / (ll_e(lam + 1e-3) - 2 * ll_e(lam) + ll_e(lam - 1e-3)))
ll_c = -0.5 * N * (log(2 * pi * S2) + 1)
def acf(xs, k):
    m = sum(xs) / len(xs); dv = [x - m for x in xs]
    return sum(dv[i] * dv[i - k] for i in range(k, len(dv))) / sum(v * v for v in dv)
shuf = list(sq)
for i in range(N - 1, 0, -1):                 # Fisher-Yates: the same days, in a new order
    j = int(rng.uniform() * (i + 1)); shuf[i], shuf[j] = shuf[j], shuf[i]
hs, ew = path(w, a, b), path(0.0, 1 - lam, lam)       # GARCH and EWMA variances
fc = lambda h1, k: lr + phi ** (k - 1) * (h1 - lr)             # the forecast formula
def monte_carlo(h1, k, paths=20000):          # road three: simulate the future instead
    tot = tot2 = 0.0
    for _ in range(paths):
        hh = h1
        for _ in range(k - 1):
            z = rng.normal(); hh = w + a * hh * z * z + b * hh
        tot += hh; tot2 += hh * hh
    return tot / paths, sqrt((tot2 / paths - (tot / paths) ** 2) / paths)
wk, wg = ([sqrt(sum(v[5 * i:5 * i + 5]) / 5) for i in range(N // 5)] for v in (sq, hs))   # weekly
top = max(range(len(wk)), key=lambda i: wk[i]); storm = max(range(1, N + 1), key=lambda t: hs[t])   # evening of day t
hS, K = hs[storm], [1] + list(range(10, 130, 10)); var20 = sum(fc(hS, k) for k in range(1, 21))
mc5, mc20 = monte_carlo(hS, 5), monte_carlo(hS, 20); hand = W + A * 36 + B * 2.5   # by hand: a -6% day, long-run level

pr = lambda lab, xs, f: print(f"{lab:<29}" + "".join(f.format(v) for v in xs))
print(f"share: {N} days, seed 2026; true omega {W:.2f}, alpha {A:.2f}, beta {B:.2f}")
print(f"variance of returns {S2:.4f}; daily vol {sqrt(S2):.4f}%; no-correlation band 2/sqrt(N) {2 / sqrt(N):.4f}")
pr("lag", range(1, 11), "{:6d}")
pr("chart, acf of returns", [acf(r, k) for k in range(1, 11)], "{:6.2f}")
pr("chart, acf of squares", [acf(sq, k) for k in range(1, 11)], "{:6.2f}")
pr("chart, acf squares, model", [rho1 * phi ** (k - 1) for k in range(1, 11)], "{:6.2f}")
print(f"rho_1 of squares: formula {rho1:.6f}, from the ARMA(1,1) weights {rho1_w:.6f}")
pr("acf squares, days shuffled", [acf(shuf, k) for k in range(1, 11)], "{:6.2f}")
print(f"GARCH fit: omega {w:.4f} (se {se[0]:.4f}), alpha {a:.4f} (se {se[1]:.4f}), beta {b:.4f} (se {se[2]:.4f})")
print(f"persistence {phi:.4f} (se {se_phi:.4f}); half-life {log(0.5) / log(phi):.1f} days, "
      f"{log(0.5) / log(phi - 2 * se_phi):.1f} to {log(0.5) / log(phi + 2 * se_phi):.1f} at 2 se")
print(f"long-run variance {lr:.4f} (se {se_lr:.4f}); long-run vol {sqrt(lr):.4f}%")
print(f"grid, omega pinned: alpha {grid[1]:.2f}, beta {grid[2]:.2f}, log-likelihood {grid[0]:.2f}")
print(f"EWMA fit: lambda {lam:.4f} (se {se_lam:.4f})")
print(f"log-likelihood: constant {ll_c:.2f}, EWMA {ll_e(lam):.2f}, GARCH {ll_g:.2f}, GARCH at the truth {loglik([W, A, B]):.2f}")
print(f"GARCH gain over constant {ll_g - ll_c:.2f}, over EWMA {ll_g - ll_e(lam):.2f}")
pr("chart, week", range(top - 9, top + 21), "{:6d}")
pr("chart, weekly rms return %", wk[top - 10:top + 20], "{:6.2f}")
pr("chart, weekly GARCH vol %", wg[top - 10:top + 20], "{:6.2f}")
print(f"storm: evening of day {storm}, GARCH h {hS:.4f}, EWMA h {ew[storm]:.4f}")
pr("days ahead k", K, "{:6d}")
pr("chart, storm GARCH vol %", [sqrt(fc(hS, k)) for k in K], "{:6.2f}")
pr("chart, storm EWMA vol %", [sqrt(ew[storm])] * len(K), "{:6.2f}")
pr("chart, long-run vol %", [sqrt(lr)] * len(K), "{:6.2f}")
print(f"storm k=5: formula {fc(hS, 5):.4f}, simulated {mc5[0]:.4f} (se {mc5[1]:.4f})")
print(f"storm k=20: formula {fc(hS, 20):.4f}, simulated {mc20[0]:.4f} (se {mc20[1]:.4f})")
print(f"storm 20-day vol: sum of forecasts {sqrt(var20):.2f}%, with no pull home {sqrt(20 * hS):.2f}%")
print(f"end of sample: GARCH h {hs[N]:.4f} -> k=20 {fc(hs[N], 20):.4f}; EWMA h {ew[N]:.4f}")
print(f"hand: h after a -6% day {hand:.4f}; k=10 {W / (1 - A - B) + (A + B) ** 9 * (hand - 2.5):.4f}; "
      f"half-life {log(0.5) / log(A + B):.1f} days; that day's log-lik term {-0.5 * (log(2 * pi * 2.5) + 36 / 2.5):.4f}")
print(f"break: decay by beta alone, storm k=20: {lr + b ** 19 * (hS - lr):.4f}")
assert all(abs(p - t) < 3 * s for p, t, s in zip(est, (W, A, B), se))   # the truth is inside
assert abs(grid[1] - a) < 0.02 and abs(grid[2] - b) < 0.02 and grid[0] <= ll_g   # two fits agree
assert ll_c <= ll_e(lam) <= ll_g and loglik([W, A, B]) <= ll_g   # the peak beats its nested rivals
assert ll_e(lam) >= max(ll_e(lam - 0.01), ll_e(lam + 0.01))       # and EWMA's peak its neighbours
assert abs(fc(hS, 5) - mc5[0]) < 4 * mc5[1] and abs(fc(hS, 20) - mc20[0]) < 4 * mc20[1]
assert acf(sq, 1) > 4 / sqrt(N) and abs(acf(sq, 1) - rho1) < 4 / sqrt(N) and all(abs(acf(v, k)) < 4 / sqrt(N) for v in (r, shuf) for k in range(1, 11))
assert abs(rho1_w - rho1) < 1e-9          # Step 4's rho_1 against the squares' ARMA(1,1) as weights on past surprises
print("ALL CHECKS PASS")
