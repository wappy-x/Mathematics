# Backtesting VaR -- the check behind the card.  Python standard library only.
# Own normal CDF (series), own root finder, own integrator, own random numbers.
from math import log, exp, sqrt, pi, comb, sin, cos

n, p = 250, 0.01
ISO, RUN = (40, 90, 140, 200), (40, 41, 42, 43)
days = lambda hit: [1 if t in hit else 0 for t in range(1, n + 1)]

def Phi(x):                                  # normal CDF: 1/2 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    term, s, k = x, x, 1
    while abs(term) > 1e-17 * max(1.0, abs(s)):
        term *= x * x / (2 * k + 1); s += term; k += 1
    return 0.5 + exp(-x * x / 2) / sqrt(2 * pi) * s
def simpson(f, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))
def bisect(f, lo, hi):
    for _ in range(200):
        mid = (lo + hi) / 2
        if f(lo) * f(mid) <= 0: hi = mid
        else: lo = mid
    return (lo + hi) / 2
def golden_max(f, lo=1e-12, hi=1 - 1e-12):
    g = (sqrt(5) - 1) / 2
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) > f(b): hi = b
        else: lo = a
    return f((lo + hi) / 2)
def xlog(c, q): return 0.0 if c == 0 else c * log(q)      # 0 log 0 = 0
def lr_uc(K, m=n, p0=p):                     # Kupiec, closed form
    ph = K / m
    return 2 * (xlog(K, ph) + xlog(m - K, 1 - ph) - xlog(K, p0) - xlog(m - K, 1 - p0))
def counts(seq):                             # road 1: walk the 249 pairs of neighbouring days
    c = [0, 0, 0, 0]
    for a, b in zip(seq, seq[1:]): c[2 * a + b] += 1
    return c
def counts_by_runs(hit):                     # road 2: count runs of exceptions (none touch day 1 or 250)
    runs = sum(1 for t in hit if t - 1 not in hit)
    return [n - 1 - len(hit) - runs, runs, runs, len(hit) - runs]
def lr_ind_cc(c):                            # Christoffersen, closed form
    n00, n01, n10, n11 = c
    p01, p11, ph = n01 / (n00 + n01), n11 / (n10 + n11), (n01 + n11) / (n - 1)
    markov = xlog(n00, 1 - p01) + xlog(n01, p01) + xlog(n10, 1 - p11) + xlog(n11, p11)
    common, fixed = xlog(n00 + n10, 1 - ph) + xlog(n01 + n11, ph), xlog(n00 + n10, 1 - p) + xlog(n01 + n11, p)
    return 2 * (markov - common), 2 * (markov - fixed), (markov, common, fixed)
def ll(q, pairs, rows): return sum(b * log(q) + (1 - b) * log(1 - q) for a, b in pairs if a in rows)
def lr_ind_search(seq):                      # road 2: maximise the likelihoods numerically, from the days
    pr = list(zip(seq, seq[1:]))
    markov = golden_max(lambda q: ll(q, pr, (0,))) + golden_max(lambda q: ll(q, pr, (1,)))
    return 2 * (markov - golden_max(lambda q: ll(q, pr, (0, 1))))

pmf = [comb(n, k) * p ** k * (1 - p) ** (n - k) for k in range(n + 1)]
cdf = [sum(pmf[:k + 1]) for k in range(n + 1)]
def zone_table(k): return "G" if k <= 4 else ("Y" if k <= 9 else "R")    # Basel 1996, Table 2
def zone_cut(k): return "G" if cdf[k] < 0.95 else ("Y" if cdf[k] < 0.9999 else "R")
PLUS = {5: 0.40, 6: 0.50, 7: 0.65, 8: 0.75, 9: 0.85, 10: 1.00}
c1 = bisect(lambda x: 2 * (1 - Phi(sqrt(x))) - 0.05, 0.5, 10.0)         # chi-square(1) 5% cutoff
tail1 = 2 * simpson(lambda z: exp(-z * z / 2) / sqrt(2 * pi), sqrt(c1), 12.0)
c2 = bisect(lambda x: exp(-x / 2) - 0.05, 0.5, 20.0); r2 = sqrt(c2)    # chi-square(2) 5% cutoff; road 2: P(Z1^2 + Z2^2 > c2)
tail2 = 2 * (1 - Phi(r2)) + 4 * simpson(lambda a: exp(-(r2 * sin(a)) ** 2 / 2) / sqrt(2 * pi) * (1 - Phi(r2 * cos(a))) * r2 * cos(a), 0.0, pi / 2)
rej = [k for k in range(n + 1) if lr_uc(k) > c1]
def prob(q, ks): return sum(comb(n, j) * q ** j * (1 - q) ** (n - j) for j in ks)

state, M64, YEARS = 20260928, 2 ** 64 - 1, 20000                        # splitmix64 random numbers
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
sim = [0] * (n + 1)
for _ in range(YEARS): sim[sum(1 for _ in range(n) if rnd() < p)] += 1
sim_size = sum(sim[k] for k in rej) / YEARS

si, sr = days(ISO), days(RUN)
ci, cr = counts(si), counts(sr)
(ind_i, cc_i, ll_i), (ind_r, cc_r, ll_r) = lr_ind_cc(ci), lr_ind_cc(cr)
uc249_i, uc249_r = lr_uc(ci[1] + ci[3], n - 1), lr_uc(cr[1] + cr[3], n - 1)
uc_search = 2 * (golden_max(lambda q: ll(q, [(0, b) for b in si], (0,))) - ll(p, [(0, b) for b in si], (0,)))
f6 = lambda v: f"{v:.6f}"
rows = [
    ("days n, promised rate p", f"{n} {p:.2f}"), ("expected count n p", f6(n * p)),
    ("exception days isolated | clustered; K", f"{' '.join(map(str, ISO))} | {' '.join(map(str, RUN))}; {sum(si)} {sum(sr)}"),
    ("pmf % k=0..10, exact", " ".join(f"{100 * v:.2f}" for v in pmf[:11])),
    ("pmf % k=0..10, simulated", " ".join(f"{100 * v / YEARS:.2f}" for v in sim[:11])),
    ("cdf % k=0..10", " ".join(f"{100 * v:.2f}" for v in cdf[:11])),
    ("zones k=0..12, Basel table", " ".join(zone_table(k) for k in range(13))),
    ("zones k=0..12, 95%/99.99% cut", " ".join(zone_cut(k) for k in range(13))),
    ("K=4: zone, plus factor, multiplier", f"{zone_cut(4)} {PLUS.get(4, 0.0):.2f} {3 + PLUS.get(4, 0.0):.2f}"),
    ("plus factors k=5..9, 10+", " ".join(f"{PLUS[k]:.2f}" for k in range(5, 11))),
    ("P(K>=4) exact", f6(1 - cdf[3])), ("P(K>=5) exact", f6(1 - cdf[4])),
    ("p-hat, K ln(p-hat/p), (n-K) ln(ratio)", f"{4 / n:.6f} {xlog(4, 4 / n / p):.6f} {xlog(n - 4, (1 - 4 / n) / (1 - p)):.6f}"),
    ("Kupiec LR, closed form / by search", f"{lr_uc(4):.6f} {uc_search:.6f}"),
    ("chi2(1) 5% cutoff; tail beyond, Simpson", f"{c1:.6f} {tail1:.6f}"),
    ("Kupiec p-value, chi2(1)", f6(2 * (1 - Phi(sqrt(lr_uc(4)))))),
    ("Kupiec LR at k=0,1,2,3,5,6,7", " ".join(f"{lr_uc(k):.3f}" for k in (0, 1, 2, 3, 5, 6, 7))),
    ("Kupiec rejects at k", " ".join(str(k) for k in rej[:4]) + " ..."),
    ("Kupiec false alarms: exact / 20000 years", f"{prob(p, rej):.6f} {sim_size:.6f}"),
    ("n00 n01 n10 n11 isolated: pairs | runs", f"{' '.join(map(str, ci))} | {' '.join(map(str, counts_by_runs(ISO)))}"),
    ("n00 n01 n10 n11 clustered: pairs | runs", f"{' '.join(map(str, cr))} | {' '.join(map(str, counts_by_runs(RUN)))}"),
    ("p01 p11 isolated", f"{ci[1] / (ci[0] + ci[1]):.6f} {ci[3] / (ci[2] + ci[3]):.6f}"),
    ("p01 p11 clustered", f"{cr[1] / (cr[0] + cr[1]):.6f} {cr[3] / (cr[2] + cr[3]):.6f}"),
    ("LR_IND isolated, closed / search", f"{ind_i:.6f} {lr_ind_search(si):.6f}"),
    ("LR_IND clustered, closed / search", f"{ind_r:.6f} {lr_ind_search(sr):.6f}"),
    ("log-lik Markov, common, fixed p; iso", " ".join(f"{v:.6f}" for v in ll_i)),
    ("log-lik Markov, common, fixed p; clu", " ".join(f"{v:.6f}" for v in ll_r)),
    ("LR_UC on the 249 pairs, both series", f6(uc249_r)),
    ("LR_CC isolated, direct / IND+UC249", f"{cc_i:.6f} {ind_i + uc249_i:.6f}"),
    ("LR_CC clustered, direct / IND+UC249", f"{cc_r:.6f} {ind_r + uc249_r:.6f}"),
    ("LR_CC clustered, IND+UC250 shortcut", f6(ind_r + lr_uc(4))),
    ("chi2(2) 5% cutoff; tail of Z1^2+Z2^2", f"{c2:.6f} {tail2:.6f}"),
    ("p-value IND clustered, chi2(1)", f"{2 * (1 - Phi(sqrt(ind_r))):.3e}"),
    ("p-value CC clustered, chi2(2)", f"{exp(-cc_r / 2):.3e}"),
    ("C(250,4); run of 4 given K=4: 247/C", f"{comb(n, 4)} {(n - 3) / comb(n, 4):.3e}"),
]
for q in (0.01, 0.015, 0.02, 0.03, 0.04):
    rows.append((f"true {100 * q:.1f}%: % not green, red, Kupiec",
                 f"{100 * prob(q, range(5, n + 1)):.2f} {100 * prob(q, range(10, n + 1)):.2f} {100 * prob(q, rej):.2f}"))
rows += [("wrong: p = 5% for a 99% VaR, LR", f6(lr_uc(4, n, 0.05))),
         ("wrong: drop the (n-K) term, LR", f6(2 * 4 * log((4 / n) / p))),
         ("wrong: count only, clustered LR", f6(lr_uc(sum(sr)))),
         ("try: p = 2.5%, K = 4, Kupiec LR", f6(lr_uc(4, n, 0.025))), ("try: n = 500, K = 8, Kupiec LR", f6(lr_uc(8, 500))),
         ("try: days 40 41 90 140, LR_IND", f6(lr_ind_cc(counts(days((40, 41, 90, 140))))[0]))]
for lab, v in rows: print(f"{lab:<42} {v}")

assert all(abs(sim[k] / YEARS - pmf[k]) < 0.01 for k in range(11))      # simulation agrees with exact
assert [zone_table(k) for k in range(40)] == [zone_cut(k) for k in range(40)]
assert abs(lr_uc(4) - uc_search) < 1e-9
assert abs(tail1 - 0.05) < 1e-9
assert abs(tail2 - 0.05) < 1e-9
assert abs(prob(p, rej) - sim_size) < 0.01
assert ci == counts_by_runs(ISO)
assert cr == counts_by_runs(RUN)
assert abs(ind_i - lr_ind_search(si)) < 1e-8
assert abs(ind_r - lr_ind_search(sr)) < 1e-8
assert abs(cc_r - (ind_r + uc249_r)) < 1e-9
m, subsets = 20, [(a, b, c, d) for a in range(20) for b in range(a + 1, 20) for c in range(b + 1, 20) for d in range(c + 1, 20)]
assert sum(1 for s in subsets if s[3] - s[0] == 3) / len(subsets) == (m - 3) / comb(m, 4)   # run formula, brute force
print("ALL CHECKS PASS")
