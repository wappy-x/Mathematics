# Rank tests -- the check behind the card.  Standard library only.  Two coffee
# shops, 8 waits each; a before/after pair; the 3/pi efficiency against the t-test.
# Normal and t tail areas are Simpson integrals written out; the random numbers
# come from a hand-written generator, so the Rust check repeats them exactly.
import math
from itertools import combinations
A = [1.2, 1.9, 2.4, 2.8, 3.1, 3.5, 4.2, 5.0]
B = [2.6, 3.3, 3.9, 4.4, 4.8, 5.5, 6.1, 7.0]
m = n = 8; N = m + n
def simpson(f, a, b, k=2000):
    h = (b - a) / k
    return h / 3 * sum((1 if i in (0, k) else 4 if i % 2 else 2) * f(a + i * h) for i in range(k + 1))
def norm_tail(z):                             # area beyond |z| under the standard bell
    return 0.5 - simpson(lambda x: math.exp(-x * x / 2) / math.sqrt(2 * math.pi), 0, abs(z))
def norm_cdf(z): return 1 - norm_tail(z) if z > 0 else norm_tail(z)
def t_tail(t, df):                            # area beyond |t|, with t = sqrt(df) tan(theta)
    g = lambda th: math.cos(th) ** (df - 1)
    return simpson(g, math.atan(abs(t) / math.sqrt(df)), math.pi / 2) / (2 * simpson(g, 0, math.pi / 2))
def midranks(xs):                             # ranks 1..len; tied values share the average rank
    order = sorted(xs); return [order.index(x) + 1 + (order.count(x) - 1) / 2 for x in xs]
def mean_var(xs):
    mu = sum(xs) / len(xs); return mu, sum((x - mu) ** 2 for x in xs) / (len(xs) - 1)
def welch(x, y):
    (mx, vx), (my, vy) = mean_var(x), mean_var(y); se2 = vx / len(x) + vy / len(y)
    df = se2 ** 2 / ((vx / len(x)) ** 2 / (len(x) - 1) + (vy / len(y)) ** 2 / (len(y) - 1))
    return (mx - my) / math.sqrt(se2), df
def U_pairs(x, y): return sum((a > b) + 0.5 * (a == b) for a in x for b in y)
def exact_p(x, y):                            # road 2: list all C(16,8) splits of the pooled ranks
    r = midranks(x + y); obs = abs(sum(r[:m]) - 36 - 32); hit = 0
    for c in combinations(range(N), m): hit += abs(sum(r[i] for i in c) - 36 - 32) >= obs - 1e-9
    return hit / math.comb(N, m)
def show(label, v): print(f"{label:<50}{v}")
r = midranks(A + B); RA = sum(r[:m]); UA = RA - m * (m + 1) / 2
show("shop A ranks among all 16", " ".join(f"{x:g}" for x in r[:m]))
show("rank sums A, B; all 16", f"{RA:g}, {sum(r[m:]):g}; {sum(r):g}")
show("U = rank sum - 36; pairs where A waited longer", f"{UA:g}; {U_pairs(A, B):g} of {m * n} = {UA / (m * n):.4f}")
mu, sd = m * n / 2, math.sqrt(m * n * (N + 1) / 12)
show("null mean, variance, spread of U", f"{mu:g}, {sd * sd:.3f}, {sd:.2f}")
z, zc = (UA - mu) / sd, (UA + 0.5 - mu) / sd
show("z plain, z with half-step", f"{z:.2f}, {zc:.3f}")
show("mistake: rank sum 48 used as U, z", f"{(RA - mu) / sd:+.2f}")
show("bell p two-sided: plain, half-step", f"{2 * norm_tail(z):.4f}, {2 * norm_tail(zc):.4f}")
ways = [[0] * (N * (N + 1) // 2 + 1) for _ in range(m + 1)]; ways[0][0] = 1
for k in range(1, N + 1):                     # road 1: count rank sets by size and sum
    for j in range(min(k, m), 0, -1):
        for s in range(len(ways[0]) - 1, k - 1, -1): ways[j][s] += ways[j - 1][s - k]
cU = [ways[m][u + 36] for u in range(m * n + 1)]   # rank sum = U + 36
total, low = sum(cU), sum(cU[:int(UA) + 1])
show("rank sets in all; with U <= 12", f"{total}; {low}")
p_exact = 2 * low / total
show("exact p one-sided, two-sided", f"{low / total:.4f}, {p_exact:.4f}")
show("two-sided p by listing every split", f"{exact_p(A, B):.4f}")
emu = sum(u * c for u, c in enumerate(cU)) / total
evar = sum((u - emu) ** 2 * c for u, c in enumerate(cU)) / total
show("mean and variance of U over all sets", f"{emu:g}, {evar:.3f}")
tw, dfw = welch(A, B)
show("Welch t, df, p on the raw minutes", f"{tw:.3f}, {dfw:.2f}, {2 * t_tail(tw, dfw):.4f}")
bins = [sum(cU[5 * i:5 * i + 5]) for i in range(13)]
bell = [round(total * (norm_cdf((5 * i + 4.5 - mu) / sd) - norm_cdf((5 * i - 0.5 - mu) / sd))) for i in range(13)]
print("chart, U in 0-4 ... 60-64, exact:", bins); print("chart, same bins, bell:", bell)
crit = max(u for u in range(33) if 2 * sum(cU[:u + 1]) / total <= 0.05)
show("5% cut-off: reject when U <=, exact level", f"{crit}, {2 * sum(cU[:crit + 1]) / total:.4f}")
A2 = A[:-1] + [50.0]; t2, df2 = welch(A2, B)
show("A's 5.0 typed as 50.0: U, exact p, Welch p", f"{U_pairs(A2, B):g}, {exact_p(A2, B):.4f}, {2 * t_tail(t2, df2):.4f}")
after = [2.9, 2.5, 3.4, 3.2, 4.0, 3.9, 3.8, 5.1]   # shop B's 8 regulars, after a second barista
d = [round(b - a, 2) for b, a in zip(B, after)]
rd = midranks([abs(x) for x in d])
Wp, Wm = sum(q for q, x in zip(rd, d) if x > 0), sum(q for q, x in zip(rd, d) if x < 0)
show("paired drops, before - after", " ".join(f"{x:g}" for x in d))
show("ranks of the sizes (ties share 3.5)", " ".join(f"{x:g}" for x in rd))
show("W+ and W-", f"{Wp:g}, {Wm:g}")
pats = [sum(q for i, q in enumerate(rd) if mask >> i & 1) for mask in range(256)]   # every sign flip
k = sum(1 for w in pats if w <= Wm)
show("sign patterns in all; with W- <= 1", f"{len(pats)}; {k}")
show("exact signed-rank p two-sided", f"{2 * k / 256:.4f}")
wmu, wv = 8 * 9 / 4, 8 * 9 * 17 / 24; wvt = wv - (2 ** 3 - 2) / 48
evw = sum((w - wmu) ** 2 for w in pats) / 256
show("W null mean, variance, tie-corrected", f"{wmu:g}, {wv:g}, {wvt:.3f}")
zw = (Wp - 0.5 - wmu) / math.sqrt(wvt)
show("signed-rank z with half-step, bell p", f"{zw:.3f}, {2 * norm_tail(zw):.4f}")
md, vd = mean_var(d); tp = md / math.sqrt(vd / 8)
show("paired t, p (7 df)", f"{tp:.3f}, {2 * t_tail(tp, 7):.4f}")
show("pairing ignored: U after vs before, exact p", f"{U_pairs(after, B):g}, {exact_p(after, B):.4f}")
shapes = {"normal": (lambda x: math.exp(-x * x / 2) / math.sqrt(2 * math.pi), 1.0, 12),
          "logistic": (lambda x: math.exp(-x) / (1 + math.exp(-x)) ** 2, math.pi ** 2 / 3, 40),
          "Laplace": (lambda x: 0.5 * math.exp(-abs(x)), 2.0, 40), "uniform": (lambda x: 1.0, 1 / 12, 0.5)}
are = {nm: 12 * var * simpson(lambda x: f(x) ** 2, -L, L) ** 2 for nm, (f, var, L) in shapes.items()}
print("efficiency of rank test vs t:", ", ".join(f"{nm} {v:.3f}" for nm, v in are.items()))
show("3/pi; rank-test sample matching t-test's 100", f"{3 / math.pi:.4f}; {100 / are['normal']:.1f}")
tcut = 2.0
for i in range(60):                           # bisect the t cut-off with 2.5% beyond, 14 df
    tcut += 2.0 ** -(i + 1) * (1 if t_tail(tcut, 14) > 0.025 else -1)
show("lowest efficiency over all shapes, 108/125", f"{108 / 125:.3f}")
show("t cut-off, 14 df", f"{tcut:.4f}")
chi14 = lambda v: v ** 6 * math.exp(-v / 2) / (2 ** 7 * math.factorial(6))   # chi-square density, 14 df
nc = 1 / math.sqrt(2 / 8)                     # a shift of one spread over its standard error
exact_pow = simpson(lambda v: chi14(v) * (norm_cdf(nc - tcut * math.sqrt(v / 14)) + norm_cdf(-nc - tcut * math.sqrt(v / 14))), 0, 100)
show("t-test power at 1 spread, exact (noncentral t)", f"{exact_pow:.3f}")
def unif():                                   # 64-bit linear congruential generator
    global s; s = (s * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((s >> 11) + 1) / 2 ** 53
def draw(kind):
    if kind == "normal": return math.sqrt(-2 * math.log(unif())) * math.cos(2 * math.pi * unif())
    return math.log(unif() / unif()) / math.sqrt(2)   # Laplace with spread 1
for shift in (1.0, 0.0):
    s = 20261123                              # each pass reruns the same random stream
    for kind in ("normal", "Laplace"):
        hits_t = hits_u = 0
        for _ in range(20000):                # 8 waits per shop, B slower by the shift, in spreads
            x = [draw(kind) for _ in range(8)]; y = [draw(kind) + shift for _ in range(8)]
            t = (sum(y) - sum(x)) / 8 / math.sqrt((mean_var(x)[1] + mean_var(y)[1]) / 8)
            u = U_pairs(x, y); hits_t += abs(t) > tcut; hits_u += u <= crit or u >= m * n - crit
        if (shift, kind) == (1.0, "normal"): power_t = hits_t / 20000
        show(f"power at {shift:g} spread, {kind}: t-test, rank test", f"{hits_t / 20000:.3f}, {hits_u / 20000:.3f}")
B70 = B[:-1] + [70.0]; t3, df3 = welch(A, B70)
show("try: B's 7.0 typed as 70.0: U, exact p, Welch p", f"{U_pairs(A, B70):g}, {exact_p(A, B70):.4f}, {2 * t_tail(t3, df3):.4f}")
d3 = [round(b - a, 2) for b, a in zip(B, [2.3] + after[1:])]; r3 = midranks([abs(x) for x in d3])
w3 = sum(q for q, x in zip(r3, d3) if x < 0); k3 = sum(1 for mk in range(256) if sum(q for i, q in enumerate(r3) if mk >> i & 1) <= w3)
show("try: first after-wait 2.3: W-, patterns, p", f"{w3:g}, {k3}, {2 * k3 / 256:.4f}")
assert cU[::-1] == cU and total == math.comb(16, 8) and U_pairs(A, B) == UA   # symmetry; pairs = ranks
assert abs(exact_p(A, B) - p_exact) < 1e-12   # DP count against the full list of splits
assert abs(emu - mu) < 1e-9 and abs(evar - sd * sd) < 1e-9   # null mean and variance by formula
assert k == 2 and abs(sum(pats) / 256 - wmu) < 1e-9 and abs(evw - wvt) < 1e-9
assert abs(are["normal"] - 3 / math.pi) < 1e-6 and abs(are["Laplace"] - 1.5) < 1e-6
assert abs(2 * norm_tail(zc) - p_exact) < 0.01 and abs(tcut - 2.144787) < 1e-5
assert abs(power_t - exact_pow) < 0.02        # simulated t-test power against the noncentral t law
print("ALL CHECKS PASS")
