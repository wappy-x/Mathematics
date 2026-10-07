# Estimation error and Ledoit-Wolf shrinkage -- the check behind the card.  Standard
# library only.  A made-up market of 20 stocks whose true covariance is known; five-year
# (60-month) histories are drawn from it with a home-made random generator, and the
# minimum-variance portfolio is rebuilt from each.  Returns are in percent per month.
from math import sqrt, log, cos, pi
P, N, H, B = 20, 60, 300, 300                 # stocks, months, fresh histories, bootstrap draws
BETA = [0.6 + 0.8 * i / 19 for i in range(P)]              # market sensitivity of each stock
IDIO = [10.0 + 5.0 * (i % 4) for i in range(P)]            # own risk, % a year
MKT, MU = 16.0, 0.8                                         # market risk % a year; mean % a month
SIG = [[MKT**2 / 12 * BETA[i] * BETA[j] + (IDIO[i]**2 / 12 if i == j else 0.0)
        for j in range(P)] for i in range(P)]
state = 20260928
def rand():                                   # splitmix64, then a uniform in (0, 1)
    global state
    state = z = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 2.0**53 + 2.0**-54
def normal():                                 # Box-Muller, one draw per pair of uniforms
    u1, u2 = rand(), rand(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
def history(n):                               # n months: one market shock, then 20 own shocks
    rows = []                                 # r = mean + beta * market shock + own shock
    for _ in range(n):
        f = MKT / sqrt(12) * normal()
        rows.append([MU + BETA[i] * f + IDIO[i] / sqrt(12) * normal() for i in range(P)])
    return rows
def cov(X):                                   # centre each stock, divide by n (as Ledoit-Wolf)
    n = len(X); m = [sum(r[i] for r in X) / n for i in range(P)]
    Xc = [[r[i] - m[i] for i in range(P)] for r in X]
    return [[sum(r[i] * r[j] for r in Xc) / n for j in range(P)] for i in range(P)], Xc
def ledoit_wolf(S, Xc):                       # target tau*I; intensity b2/d2, capped at 1
    n, tau = len(Xc), sum(S[i][i] for i in range(P)) / P
    d2 = sum((S[i][j] - (tau if i == j else 0.0))**2 for i in range(P) for j in range(P)) / P
    b2bar = sum((x[i] * x[j] - S[i][j])**2 for x in Xc for i in range(P) for j in range(P)) / P / n**2
    b2 = min(b2bar, d2); a = b2 / d2
    return [[(1 - a) * S[i][j] + (a * tau if i == j else 0.0) for j in range(P)] for i in range(P)], a, tau, d2, b2bar, b2
def gmv(M):                                   # road 1: solve M w = 1 by elimination, rescale
    A = [row[:] + [1.0] for row in M]
    for c in range(P):
        p = max(range(c, P), key=lambda r: abs(A[r][c]))
        A[c], A[p] = A[p], A[c]
        for r in range(c + 1, P):
            f = A[r][c] / A[c][c]; A[r] = [A[r][k] - f * A[c][k] for k in range(P + 1)]
    x = [0.0] * P
    for c in reversed(range(P)):
        x[c] = (A[c][P] - sum(A[c][k] * x[k] for k in range(c + 1, P))) / A[c][c]
    return [v / sum(x) for v in x]
def jacobi(M):                                # eigenvalues and eigenvectors by Jacobi rotations
    A = [row[:] for row in M]
    V = [[1.0 if i == j else 0.0 for j in range(P)] for i in range(P)]
    for _ in range(100):
        if sum(A[i][j]**2 for i in range(P) for j in range(P) if i != j) < 1e-22: break
        for p in range(P):
            for q in range(p + 1, P):
                if abs(A[p][q]) < 1e-300: continue
                th = 0.5 * (A[q][q] - A[p][p]) / A[p][q]
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + sqrt(th * th + 1.0))
                c = 1.0 / sqrt(t * t + 1.0); s = t * c
                for M in (A, V):                          # rotate columns p, q
                    for k in range(P): M[k][p], M[k][q] = c * M[k][p] - s * M[k][q], s * M[k][p] + c * M[k][q]
                for k in range(P): A[p][k], A[q][k] = c * A[p][k] - s * A[q][k], s * A[p][k] + c * A[q][k]
    return [A[i][i] for i in range(P)], V
def gmv_eigen(M):                             # road 2: w ~ sum over directions of (v.1) v / lambda
    lam, V = jacobi(M); x = [sum(V[i][k] * sum(V[j][k] for j in range(P)) / lam[k] for k in range(P)) for i in range(P)]
    return [v / sum(x) for v in x]
def quad(w, M): return sum(w[i] * M[i][j] * w[j] for i in range(P) for j in range(P))
def vol(v): return sqrt(12.0 * v)             # monthly variance in %^2 -> % a year
def stats(v):
    m = sum(v) / len(v); return m, sqrt(sum((x - m)**2 for x in v) / len(v)), min(v), max(v)
def row(label, vals, fmt): print(f"{label:<30}" + " ".join(format(v, fmt) for v in vals))
w_true = gmv(SIG); true_min = quad(w_true, SIG)
X1 = history(N); S1, Xc1 = cov(X1); L1, a1, tau1, d21, bb1, b21 = ledoit_wolf(S1, Xc1)
ws1, wl1 = gmv(S1), gmv(L1)
e_true, e_s, e_l = (sorted(jacobi(M)[0]) for M in (SIG, S1, L1))
road2 = max(abs(x - y) for x, y in zip(ws1 + wl1, gmv_eigen(S1) + gmv_eigen(L1)))
half = gmv([[0.5 * v for v in r] for r in S1])
GRID = [k / 100 for k in range(101)]
loss = [0.0] * 101; num = den = 0.0
keep = {k: [] for k in ("w1s", "w1l", "gs", "gl", "rs", "ts", "rl", "tl", "a", "fs", "fl")}
for h in range(H):
    S, Xc = (S1, Xc1) if h == 0 else cov(history(N))
    L, a, tau = ledoit_wolf(S, Xc)[:3]; ws, wl = gmv(S), gmv(L)
    for k, v in (("w1s", ws[0]), ("w1l", wl[0]), ("gs", sum(map(abs, ws))), ("gl", sum(map(abs, wl))),
                 ("rs", quad(ws, S)), ("ts", quad(ws, SIG)), ("rl", quad(wl, L)), ("tl", quad(wl, SIG)), ("a", a)):
        keep[k].append(v)
    E = [[S[i][j] - SIG[i][j] for j in range(P)] for i in range(P)]      # sample error
    D = [[S[i][j] - (tau if i == j else 0.0) for j in range(P)] for i in range(P)]  # sample minus target
    num += sum(E[i][j] * D[i][j] for i in range(P) for j in range(P))
    den += sum(D[i][j]**2 for i in range(P) for j in range(P))
    for k, g in enumerate(GRID):                                       # brute force: every intensity
        loss[k] += sum((E[i][j] - g * D[i][j])**2 for i in range(P) for j in range(P)) / P / H
    keep["fs"].append(sum(E[i][j]**2 for i in range(P) for j in range(P)) / P)
    keep["fl"].append(sum((L[i][j] - SIG[i][j])**2 for i in range(P) for j in range(P)) / P)
boot = []
for _ in range(B):                                                      # resample history 1's months
    boot.append(gmv(cov([X1[int(rand() * N)] for _ in range(N)])[0])[0])
mean = {k: sum(v) / H for k, v in keep.items()}
a_grid = GRID[min(range(101), key=lambda k: loss[k])]
X240 = history(240); S240, Xc240 = cov(X240); L240, a240 = ledoit_wolf(S240, Xc240)[:2]
X15 = history(15); S15, Xc15 = cov(X15); L15, a15 = ledoit_wolf(S15, Xc15)[:2]
print(f"market: {P} stocks, {N} months, {H} fresh histories, {B} bootstrap resamples")
row("weights %, true", [100 * v for v in w_true], "5.0f")
row("weights %, history 1 sample", [100 * v for v in ws1], "5.0f")
row("weights %, history 1 shrunk", [100 * v for v in wl1], "5.0f")
print(f"road 2, eigen expansion vs elimination, agree to 1e-9: {'yes' if road2 < 1e-9 else 'no'}")
row("eigenvalues, true", e_true, "7.2f")
row("eigenvalues, history 1 sample", e_s, "7.2f")
row("eigenvalues, history 1 shrunk", e_l, "7.2f")
print(f"history 1: tau {tau1:.4f}  d2 {d21:.4f}  b2bar {bb1:.4f}  b2 {b21:.4f}  intensity a {a1:.4f}")
print(f"smallest eigenvalue: true {e_true[0]:.2f}  sample {e_s[0]:.2f}  shrunk {e_l[0]:.2f}"
      f"  check (1-a)*{e_s[0]:.2f}+a*tau = {(1 - a1) * e_s[0] + a1 * tau1:.2f}")
print(f"largest over smallest: true {e_true[-1] / e_true[0]:.1f}  sample {e_s[-1] / e_s[0]:.1f}  shrunk {e_l[-1] / e_l[0]:.1f}")
print(f"true minimum variance {true_min:.4f} %^2 a month = {vol(true_min):.2f}% a year")
print(f"history 1 sample portfolio: reported {vol(quad(ws1, S1)):.2f}%  true {vol(quad(ws1, SIG)):.2f}%")
print(f"history 1 shrunk portfolio: reported {vol(quad(wl1, L1)):.2f}%  true {vol(quad(wl1, SIG)):.2f}%")
print(f"average over {H}: sample reported {vol(mean['rs']):.2f}%  sample true {vol(mean['ts']):.2f}%")
print(f"average over {H}: shrunk reported {vol(mean['rl']):.2f}%  shrunk true {vol(mean['tl']):.2f}%")
print(f"equal weights (intensity 1): true {vol(quad([1.0 / P] * P, SIG)):.2f}%")
for lab, v in (("stock 1 weight %, sample", keep["w1s"]), ("stock 1 weight %, shrunk", keep["w1l"])):
    m, s, lo, hi = stats([100 * x for x in v])
    print(f"{lab}: mean {m:.1f}  sd {s:.1f}  min {lo:.1f}  max {hi:.1f}  (true {100 * w_true[0]:.1f})")
print(f"stock 1 weight %, sd over bootstrap of history 1: {100 * stats(boot)[1]:.1f}")
print(f"gross exposure sum|w|: true {sum(map(abs, w_true)):.2f}  sample {mean['gs']:.2f}  shrunk {mean['gl']:.2f}")
print(f"intensity: Ledoit-Wolf average {mean['a']:.3f}  oracle from the truth {num / den:.3f}  grid best {a_grid:.2f}")
print(f"covariance loss per stock: sample {mean['fs']:.2f}  shrunk {mean['fl']:.2f}")
row("loss curve a=0,0.1..1", [loss[10 * k] for k in range(11)], "7.2f")
print(f"mistake, shrink toward zero (S/2): largest weight change {max(abs(x - y) for x, y in zip(ws1, half)):.4f}")
print(f"try 240 months: intensity {a240:.3f}  stock 1 sample {100 * gmv(S240)[0]:.1f}%  shrunk {100 * gmv(L240)[0]:.1f}%")
print(f"try 15 months: smallest sample eigenvalue {abs(sorted(jacobi(S15)[0])[0]):.4f}  intensity {a15:.3f}"
      f"  shrunk stock 1 {100 * gmv(L15)[0]:.1f}%")
assert road2 < 1e-9, "eigen expansion must reproduce elimination"
assert abs(sum(e_s) - sum(S1[i][i] for i in range(P))) < 1e-8, "eigenvalues must add to the trace"
assert abs(e_l[0] - ((1 - a1) * e_s[0] + a1 * tau1)) < 1e-8, "shrinkage moves each eigenvalue toward tau"
assert mean["rs"] < true_min, "reported risk of the sample optimum sits below the true minimum"
assert mean["ts"] > true_min, "its true risk sits above the true minimum"
assert abs(mean["a"] - num / den) < 0.05, "one-history estimate vs the oracle built from the truth"
assert abs(a_grid - num / den) < 0.02, "brute-force grid vs the oracle formula"
assert mean["tl"] < mean["ts"], "shrinkage must lower the true risk on average"
print("ALL CHECKS PASS")
