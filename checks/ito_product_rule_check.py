# Ito's product rule -- the check behind the card.  Only math is imported.
# A share starts at $100 with volatility 0.20 a year; the bank pays r = 0.05.
# D_t = S_t e^(-rt) is the discounted share.  The product rule gives
# dD = D((mu - r) dt + sigma dW): a fair game exactly when mu = r.
# Roads: (A) the formulas; (B) the exact step-by-step identity on one path;
# (C) 20000 simulated paths; (D) Euler steps of the product-rule equations.
# Floats are added in plain loops, never with sum(), which adds with extra
# precision in Python and would part company with the Rust twin.
import math

S0, SIG, R, MU, T, SEED = 100.0, 0.20, 0.05, 0.08, 1.0, 20260930
MASK = (1 << 64) - 1
state = SEED

def uniform():                               # SplitMix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def normal():                                # Box-Muller, cosine half only
    u1 = 1.0 - uniform()
    u2 = uniform()
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def share(mu, t, w):                         # S_t on a path whose W_t is w
    return S0 * math.exp((mu - 0.5 * SIG * SIG) * t + SIG * w)

def mean_se(xs):
    m = 0.0
    for x in xs: m += x
    m /= len(xs)
    v = 0.0
    for x in xs: v += (x - m) * (x - m)
    return m, math.sqrt(v / (len(xs) - 1) / len(xs))

def row(label, v): print(f"{label:<46}{v:>11.4f}")
def row_se(label, m, se): print(f"{label:<46}{m:>11.4f}  se {se:.4f}")

print("A  formulas")
fd8, fd5 = S0 * math.exp((MU - R) * T), S0 * math.exp((R - R) * T)
fs2, fs2_wrong = S0 * S0 * math.exp((2.0 * R + SIG * SIG) * T), S0 * S0 * math.exp(2.0 * R * T)
fgap = SIG * SIG * S0 * S0 * (math.exp((2.0 * MU + SIG * SIG) * T) - 1.0) / (2.0 * MU + SIG * SIG)
row("E[D_1], mu = 0.08", fd8)
row("E[D_1], mu = r = 0.05", fd5)
row("E[S_1^2], mu = 0.05, product rule", fs2)
row("E[S_1^2], mu = 0.05, covariation dropped", fs2_wrong)
row("E[W_1^2], product rule", T)
row("E[W_1^2], ordinary rule", 0.0)
row("mu = 0.08: sigma^2 E[integral of S^2 dt]", fgap)
row("try: E[S_1^2], sigma = 0.40, product rule", S0 * S0 * math.exp((2.0 * R + 0.16) * T))
print(f"hand: mu - r {MU - R:.4f}, 2r + sigma^2 {2.0 * R + SIG * SIG:.4f}, e^(mu - r) {math.exp(MU - R):.4f}")

NF = 4096
dtf = T / NF
w = [0.0]
for k in range(NF): w.append(w[k] + math.sqrt(dtf) * normal())
s = [share(R, k * dtf, w[k]) for k in range(NF + 1)]
target = 0.0                                 # sigma^2 times the integral of S^2 dt (trapezoids)
for k in range(NF): target += SIG * SIG * 0.5 * (s[k] * s[k] + s[k + 1] * s[k + 1]) * dtf
print("B  one path, mu = 0.05: steps, sum dS d(e^-rt), sum (dS)^2, identity gap")
cross_b, sq_b, gap_b = [], [], 0.0
for n in (16, 64, 256, 1024, 4096):
    p = s[::NF // n]
    b = [math.exp(-R * k * T / n) for k in range(n + 1)]
    xdy, ydx, cross, sq = 0.0, 0.0, 0.0, 0.0
    for k in range(n):
        ds, db = p[k + 1] - p[k], b[k + 1] - b[k]
        xdy += p[k] * db; ydx += b[k] * ds; cross += ds * db; sq += ds * ds
    gap = abs((p[n] * b[n] - p[0] * b[0]) - (xdy + ydx + cross))
    cross_b.append(cross); sq_b.append(sq); gap_b = max(gap_b, gap)
    print(f"   n {n:>5}   {cross:>10.6f}   {sq:>10.4f}   {gap:.9f}")
row("   sigma^2 * integral of S^2 dt, this path", target)
row("   share at t = 1, this path", s[NF])
row("   discounted share at t = 1, this path", s[NF] * math.exp(-R * T))

NP = 20000
dq = [[[] for _ in range(4)] for _ in range(2)]
fair, s2, w2 = [[], []], [], []
for i in range(NP):
    wq, ws = [], 0.0
    for j in range(4):
        ws += 0.5 * normal()                 # quarter-year steps: sd = sqrt(0.25)
        wq.append(ws)
    for a, mu in enumerate((R, MU)):
        d = [share(mu, 0.25 * (j + 1), wq[j]) * math.exp(-R * 0.25 * (j + 1)) for j in range(4)]
        for j in range(4): dq[a][j].append(d[j])
        fair[a].append(d[3] - d[1] if d[1] > 100.0 else 0.0)
    s1 = share(R, 1.0, wq[3])
    s2.append(s1 * s1); w2.append(wq[3] * wq[3])
print("C  20000 paths: mean discounted share each quarter")
ch5, ch8 = [100.0], [100.0]
for j in range(4):
    m5, e5 = mean_se(dq[0][j]); m8, e8 = mean_se(dq[1][j])
    ch5.append(m5); ch8.append(m8)
    print(f"   t {0.25 * (j + 1):.2f}   mu 0.05 {m5:9.4f} se {e5:.4f}   mu 0.08 {m8:9.4f} se {e8:.4f}")
fg5, fg8, ms2, mw2 = mean_se(fair[0]), mean_se(fair[1]), mean_se(s2), mean_se(w2)
row_se("fair game, mu 0.05: E[(D_1 - D_.5) if D_.5>100]", *fg5)
row_se("fair game, mu 0.08: E[(D_1 - D_.5) if D_.5>100]", *fg8)
row_se("E[S_1^2], mu = 0.05, simulated", *ms2)
row_se("E[W_1^2], simulated", *mw2)
print("chart, mean D, mu 0.05 " + " ".join(f"{v:.2f}" for v in ch5))
print("chart, mean D, mu 0.08 " + " ".join(f"{v:.2f}" for v in ch8))

ns = (16, 64, 256, 1024, 4096)
errd, erry, errn = [0.0] * 5, [0.0] * 5, [0.0] * 5
for i in range(200):
    wc = [0.0]
    for k in range(NF): wc.append(wc[k] + math.sqrt(dtf) * normal())
    sp = [share(MU, k * dtf, wc[k]) for k in range(NF + 1)]
    d_exact, y_exact = sp[NF] * math.exp(-R * T), sp[NF] * sp[NF]
    for a, n in enumerate(ns):
        h, st = T / n, NF // n
        d, y, yn = S0, S0 * S0, S0 * S0
        for k in range(n):
            x0, x1 = sp[k * st], sp[(k + 1) * st]
            d += d * ((MU - R) * h + SIG * (wc[(k + 1) * st] - wc[k * st]))
            y += 2.0 * x0 * (x1 - x0) + SIG * SIG * x0 * x0 * h
            yn += 2.0 * x0 * (x1 - x0)
        errd[a] += abs(d - d_exact) / 200.0
        erry[a] += abs(y - y_exact) / 200.0
        errn[a] += abs(yn - y_exact) / 200.0
print("D  200 paths, mu = 0.08: mean |error| at t = 1; steps, D, S^2 with term, S^2 without")
for a, n in enumerate(ns):
    print(f"   n {n:>5}   {errd[a]:8.4f}   {erry[a]:9.2f}   {errn[a]:9.2f}")

assert abs(ch5[4] - fd5) < 4 * mean_se(dq[0][3])[1], "mu = r: discounted share keeps its mean"
assert abs(ch8[4] - fd8) < 4 * mean_se(dq[1][3])[1], "mu = 0.08: mean grows at mu - r"
assert abs(fg5[0]) < 4 * fg5[1] and fg8[0] > 4 * fg8[1], "fair game only when mu = r"
assert abs(ms2[0] - fs2) < 4 * ms2[1], "E[S^2] needs the covariation term"
assert abs(mw2[0] - T) < 4 * mw2[1], "E[W^2] = T, not 0"
assert gap_b < 1e-9, "algebra check of Step 1: the grid identity is exact"
assert abs(sq_b[4] - target) < 0.05 * target, "(dS)^2 sums to the covariation term"
assert abs(cross_b[4]) < 0.01 * abs(cross_b[0]), "share times discount: no covariation"
assert erry[4] < erry[0] / 4 and errd[4] < errd[0] / 4, "Euler errors shrink with the term"
assert abs(errn[4] - fgap) < 0.1 * fgap, "without the term the error stays at the covariation"
print("ALL CHECKS PASS")
