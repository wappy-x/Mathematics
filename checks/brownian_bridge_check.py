# Brownian bridge -- the check behind the card.  Standard library only.
# A simulated pollen grain: position W_t in micrometres, t in seconds, Var W_t = t.  Pinned at W_0 = 0 and W_10 = 2.
# Road 1: the bridge formulas, mean a + (t - t1)/(t2 - t1) (b - a), covariance (s - t1)(t2 - t)/(t2 - t1).
# Road 2: Gaussian conditioning by linear algebra, Sigma_11 - Sigma_12 Sigma_22^-1 Sigma_21, Cov(W_s, W_t) = min(s, t).
# Road 3: a coin-flip walk pinned at both ends, counted exactly over every path, at three step sizes.
# Road 4: seeded simulations (SplitMix64 and Box-Muller, written out): selection, construction, refinement.
from math import cos, exp, log, pi, sqrt

T, B = 10.0, 2.0
def mean_f(t, a=0.0, b=B, t1=0.0, t2=T): return a + (t - t1) / (t2 - t1) * (b - a)
def cov_f(s, t, t1=0.0, t2=T): return (min(s, t) - t1) * (t2 - max(s, t)) / (t2 - t1)
def phi_cdf(x, m=2000):                  # Simpson's rule on the bell curve from 0 to x
    h = x / m
    return 0.5 + h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * exp(-(i * h) ** 2 / 2) for i in range(m + 1)) / sqrt(2 * pi)
def solve(A, Y):                         # Gauss-Jordan elimination with partial pivoting; Y lists right-hand sides
    n = len(A); M = [A[i][:] + [y[i] for y in Y] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]; M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    return [[M[i][n + j] / M[i][i] for i in range(n)] for j in range(len(Y))]
def condition(targets, given):           # road 2: weights on the given values, and the covariance left over
    W = solve([[min(a, b) for b in given] for a in given], [[min(t, g) for g in given] for t in targets])
    return W, [[min(s, t) - sum(w * min(g, t) for w, g in zip(W[i], given)) for t in targets] for i, s in enumerate(targets)]
lf = [0.0]
for i in range(1, 1001): lf.append(lf[-1] + log(i))
def walk_bridge(n):                      # road 3: n coin-flip steps of size sqrt(T/n), pinned to end at 2, looked at t = 4
    h = sqrt(T / n); m = round(B / h); k = 4 * n // 10; u = (n + m) // 2
    ps = {2 * up - k: exp(lf[k] - lf[up] - lf[k - up] + lf[n - k] - lf[u - up] - lf[n - k - u + up] - lf[n] + lf[u] + lf[n - u])
          for up in range(max(0, u - (n - k)), min(k, u) + 1)}
    mu = sum(p * j * h for j, p in ps.items())
    return sum(ps.values()), mu, sum(p * (j * h) ** 2 for j, p in ps.items()) - mu ** 2

MASK, state = (1 << 64) - 1, 20260930
def unif():                              # SplitMix64, top 53 bits, never exactly 0 or 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2 ** 53
def normal():                            # Box-Muller, one normal from two uniforms
    r = sqrt(-2 * log(unif())); return r * cos(2 * pi * unif())
def select(drift, n=500000, eps=0.1):    # road 4a: draw free paths, keep those that end within eps of 2
    acc = []
    for _ in range(n):
        w4 = 4 * drift + 2 * normal(); w10 = w4 + 6 * drift + sqrt(6) * normal()
        if abs(w10 - B) < eps: acc.append(w4)
    k = len(acc); mu = sum(acc) / k; var = sum((x - mu) ** 2 for x in acc) / (k - 1); lo = sum(x < 0 for x in acc) / k
    return k, mu, sqrt(var / k), var, var * sqrt(2 / (k - 1)), lo, sqrt(lo * (1 - lo) / k)
def refine(path, dt, sd):                # insert a midpoint in every gap: neighbours' average plus sd times a normal
    out = [path[0]]
    for a, b in zip(path, path[1:]): out += [(a + b) / 2 + sd * normal(), b]
    return out
qv = lambda p: sum((y - x) ** 2 for x, y in zip(p, p[1:]))

sd4 = sqrt(cov_f(4, 4))
print(f"pinned W_0 = 0, W_10 = 2, at t = 4: mean (t/T) b {mean_f(4):.6f}  var t(T-t)/T {cov_f(4, 4):.6f}  sd {sd4:.6f}")
W, C = condition([4.0, 3.0, 7.0], [T])
print(f"road 2, given W_10: weight on W_10 {W[0][0]:.6f}, mean {W[0][0] * B:.6f}, var {C[0][0]:.6f}")
print(f"Cov(W_3, W_7 | W_10 = 2): formula s(T-t)/T {cov_f(3, 7):.6f}; road 2 {C[1][2]:.6f}")
z = -mean_f(4) / sd4
print(f"P(W_4 < 0 | W_10 = 2) = Phi({z:.6f}) = {phi_cdf(z):.6f}; wrong var 4: Phi({-mean_f(4) / 2:.6f}) = {phi_cdf(-mean_f(4) / 2):.6f}")
Wf, Cf = condition([4.5], [float(i) for i in range(1, 11)])
print(f"fill 4.5 s between 1.3 at 4 s and 0.5 at 5 s: mean {mean_f(4.5, 1.3, 0.5, 4, 5):.6f} sd {sqrt(cov_f(4.5, 4.5, 4, 5)):.6f}")
rec = [0.4, -0.2, 0.7, 1.3, 0.5, 1.1, -0.6, 0.2, 0.9, 2.0]   # a record with 1.3 at 4 s and 0.5 at 5 s
mf = sum(w * v for w, v in zip(Wf[0], rec))
print("road 2, weights on W_1..W_10 " + " ".join(f"{w:.3f}" for w in Wf[0]) + f"; mean {mf:.6f} var {Cf[0][0]:.6f}")
print(f"chance the path touched 2 inside that second, exp(-2 (2-1.3)(2-0.5)/1) = {exp(-2 * 0.7 * 1.5):.6f}")
print("coin-flip walk pinned at 2, at t = 4    steps n   total chance   mean      var       error")
walk = [walk_bridge(n) for n in (10, 90, 1000)]
for n, (tot, mu, var) in zip((10, 90, 1000), walk): print(f"{'':<40}{n:>7}{tot:>12.6f}{mu:>11.6f}{var:>10.6f}{var - 2.4:>10.6f}")
print("selection, 500000 free paths   kept   mean W_4   se       var W_4   se       P(W_4 < 0)  se")
sel = [select(d) for d in (0.0, 0.3)]
for d, s in zip((0.0, 0.3), sel): print(f"  drift {d:.1f} per second  {s[0]:>11}" + "".join(f"{x:>10.6f}" for x in s[1:]))
NP, s1, s2, s37 = 100000, [0.0] * 11, [0.0] * 11, 0.0
for _ in range(NP):                      # road 4b: a free path minus the straight line through its own end, plus the pin
    w = [0.0]
    for _ in range(10): w.append(w[-1] + normal())
    br = [w[i] - i / T * w[10] + i / T * B for i in range(11)]
    for i in range(11): s1[i] += br[i]; s2[i] += br[i] ** 2
    s37 += br[3] * br[7]
vs = [s2[i] / NP - (s1[i] / NP) ** 2 for i in range(11)]
c37 = s37 / NP - s1[3] * s1[7] / NP ** 2; se37 = sqrt((vs[3] * vs[7] + c37 ** 2) / NP)
print(f"construction, {NP} paths: Cov(B_3, B_7) {c37:.6f} se {se37:.6f}; mean B_4 {s1[4] / NP:.6f} se {sqrt(vs[4] / NP):.6f}")
print(" t   free var t   bridge formula   road 2     simulated   se")
road2 = condition([float(t) for t in range(1, 10)], [T])[1]
for t in range(1, 10): print(f"{t:>2}{t:>12.6f}{cov_f(t, t):>16.6f}{road2[t - 1][t - 1]:>11.6f}{vs[t]:>13.6f}{vs[t] * sqrt(2 / NP):>9.6f}")
NR, tot = 20000, {"bridge, half": [], "bridge, quarter": [], "straight lines, half": [], "straight lines, quarter": [], "free var 0.5, half": []}
lag = cnt = 0.0
for p in range(NR):                      # road 4c: refine a coarse path recorded every second
    w = [0.0]
    for _ in range(10): w.append(w[-1] + normal())
    half = refine(w, 1.0, 0.5); quarter = refine(half, 0.5, sqrt(0.125)); wrong = refine(w, 1.0, sqrt(0.5))
    line_h = refine(w, 1.0, 0.0); line_q = refine(line_h, 0.5, 0.0)
    for key, path in zip(tot, (half, quarter, line_h, line_q, wrong)): tot[key].append(qv(path))
    d = [y - x for x, y in zip(quarter, quarter[1:])]; lag += sum(x * y for x, y in zip(d, d[1:])); cnt += len(d) - 1
    if p == 0: fig = (line_h, half)
print("refinement, 20000 coarse paths   squared steps summed over 10 s   se       exact")
exact = (10.0, 10.0, 5.0, 2.5, 15.0)
for (key, v), ex in zip(tot.items(), exact):
    m = sum(v) / NR; tot[key] = (m, sqrt((sum(x * x for x in v) / NR - m * m) / NR))
    print(f"  {key:<34}{m:>15.6f}{tot[key][1]:>13.6f}{ex:>9.1f}")
rho = lag / cnt / 0.25
print(f"  bridge, quarter: correlation of neighbouring steps {rho:.6f} se {1 / sqrt(cnt):.6f}")
print("chart, time    " + " ".join(f"{i / 2:5.1f}" for i in range(21)))
print("chart, straight" + " ".join(f"{x:6.2f}" for x in fig[0]))
print("chart, filled  " + " ".join(f"{x:6.2f}" for x in fig[1]))
print("chart, var free   " + " ".join(f"{t:5.2f}" for t in range(11)))
print("chart, var bridge " + " ".join(f"{cov_f(t, t):5.2f}" for t in range(11)))
print("chart, var sim    " + " ".join(f"{v:5.2f}" for v in vs))
print(f"try: pin at -3, mean at 4 s {mean_f(4, b=-3.0):.6f} var {cov_f(4, 4):.6f}; midpoint of a 10 s gap sd {sqrt(cov_f(5, 5)):.6f}; var rate 4, var at 4 s {4 * cov_f(4, 4):.6f}")

assert all(abs(road2[t - 1][t - 1] - cov_f(t, t)) < 1e-12 for t in range(1, 10)) and abs(C[1][2] - cov_f(3, 7)) < 1e-12, "road 2 vs formula"
assert abs(Wf[0][3] - 0.5) < 1e-12 and abs(Wf[0][4] - 0.5) < 1e-12 and max(abs(Wf[0][i]) for i in (0, 1, 2, 5, 6, 7, 8, 9)) < 1e-12, "neighbours only"
assert abs(Cf[0][0] - cov_f(4.5, 4.5, 4, 5)) < 1e-12 and abs(mf - mean_f(4.5, 1.3, 0.5, 4, 5)) < 1e-12, "fill-in: linear algebra vs bridge between neighbours"
errs = [v - cov_f(4, 4) for _, _, v in walk]
assert errs[0] > errs[1] > errs[2] > 0 and errs[2] < 0.002 and all(abs(mu - mean_f(4)) < 1e-9 for _, mu, _ in walk), "walk bridge converges"
for k, mu, smu, var, svar, lo, slo in sel:
    assert abs(mu - mean_f(4)) < 4 * smu and abs(var - cov_f(4, 4)) < 4 * svar and abs(lo - phi_cdf(z)) < 4 * slo, "selection vs formula"
assert all(abs(vs[t] - cov_f(t, t)) < 4 * vs[t] * sqrt(2 / NP) for t in range(1, 10)) and abs(c37 - cov_f(3, 7)) < 4 * se37, "construction"
for (m, s), ex in zip(tot.values(), exact): assert abs(m - ex) < 4 * s, "squared steps summed vs exact"
assert abs(rho) < 4 / sqrt(cnt), "refined steps uncorrelated"
print("ALL CHECKS PASS")
