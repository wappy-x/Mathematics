# Forecasting with exponential smoothing -- the check behind the card.  Standard library only.
# Monthly airline passengers, thousands, 1949-1960 (Box-Jenkins series G); Holt-Winters on the logs, fitted to 1949-1959.
# Interval width three ways: a loop over the error weights, their closed form, 20,000 simulated years (SplitMix64 below).
from math import log, exp, sqrt, cos, pi

P = [112, 118, 132, 129, 121, 135, 148, 148, 136, 119, 104, 118, 115, 126, 141, 135, 125, 149, 170, 170, 158, 133, 114, 140,
     145, 150, 178, 163, 172, 178, 199, 199, 184, 162, 146, 166, 171, 180, 193, 181, 183, 218, 230, 242, 209, 191, 172, 194,
     196, 196, 236, 235, 229, 243, 264, 272, 237, 211, 180, 201, 204, 188, 235, 227, 234, 264, 302, 293, 259, 229, 203, 229,
     242, 233, 267, 269, 270, 315, 364, 347, 312, 274, 237, 278, 284, 277, 317, 313, 318, 374, 413, 405, 355, 306, 271, 306,
     315, 301, 356, 348, 355, 422, 465, 467, 404, 347, 305, 336, 340, 318, 362, 348, 363, 435, 491, 505, 404, 359, 310, 337,
     360, 342, 406, 396, 420, 472, 548, 559, 463, 407, 362, 405, 417, 391, 419, 461, 472, 535, 622, 606, 508, 461, 390, 432]
M, Z, MON = 12, 1.96, "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split()  # season length; 95% normal quantile

def run(y, a, b, g, seasons=True):    # Holt-Winters over y; returns final state and the one-step squared errors
    lev = sum(y[:M]) / M
    tr = (sum(y[M:2 * M]) - sum(y[:M])) / (M * M)
    sea = [v - lev if seasons else 0.0 for v in y[:M]]
    sse = 0.0
    for t in range(M, len(y)):
        s = sea[t % M]
        e = y[t] - lev - tr - s
        sse += e * e
        sea[t % M] = g * (y[t] - lev - tr) + (1 - g) * s
        new = a * (y[t] - s) + (1 - a) * (lev + tr)
        tr, lev = b * (new - lev) + (1 - b) * tr, new
    return lev, tr, sea, sse

def fit(y):                           # coarse grid in tenths, then hundredths around the best point
    best = (1e9, 0, 0, 0)
    for i in range(1, 10):
        for j in range(10):
            for k in range(10):
                best = min(best, (run(y, i / 10, j / 10, k / 10)[3], i * 10, j * 10, k * 10))
    _, i0, j0, k0 = best
    for i in range(max(i0 - 9, 1), min(i0 + 10, 100)):
        for j in range(max(j0 - 9, 0), min(j0 + 10, 100)):
            for k in range(max(k0 - 9, 0), min(k0 + 10, 100)):
                best = min(best, (run(y, i / 100, j / 100, k / 100)[3], i, j, k))
    return best[1] / 100, best[2] / 100, best[3] / 100

Y = [log(p) for p in P]
FIT, ACT = Y[:132], P[132:]
a, b, g = fit(FIT)
lev, tr, sea, sse = run(FIT, a, b, g)
n, sig = len(FIT) - M, sqrt(sse / (len(FIT) - M))
print(f"fit     alpha {a:.2f}  beta {b:.2f}  gamma {g:.2f}  one-step errors {n}  sigma {sig:.6f}  se {sig / sqrt(2 * n):.6f}")
print(f"state   Dec 1959: level {lev:.6f}  trend {tr:.6f}  s_Jan {sea[0]:.6f}  s_Jul {sea[6]:.6f}  s_Dec {sea[11]:.6f}")
L2, T2 = sum(FIT[:M]) / M, (sum(FIT[M:2 * M]) - sum(FIT[:M])) / (M * M)
S2 = [v - L2 for v in FIT[:M]]
for t in range(M, 132):               # Step 3's error-correction form: a second road to the same state
    e = FIT[t] - L2 - T2 - S2[t % M]
    L2, T2, S2[t % M] = L2 + T2 + a * e, T2 + a * b * e, S2[t % M] + g * e
print(f"ec      error-correction form, Dec 1959: level {L2:.6f}  trend {T2:.6f}  s_Jul {S2[6]:.6f}")

c = [1.0] + [a * (1 + j * b) for j in range(1, M)]           # weight of a shock j months back
v_loop = [sum(c[j] * c[j] for j in range(h)) for h in range(1, M + 1)]
v_closed = [1 + (h - 1) * (a * a + a * a * b * h + a * a * b * b * h * (2 * h - 1) / 6) for h in range(1, M + 1)]
f = [lev + h * tr + sea[(h - 1) % M] for h in range(1, M + 1)]

state = [0x2026092905]                  # SplitMix64, seed 0x2026092905
def u01():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    x = state[0]
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((x ^ (x >> 31)) >> 11) / 9007199254740992.0 + 1.1102230246251565e-16
def normal(): return sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())

N = 20000
err = [[0.0] * N for _ in range(M)]
tot = []
for p in range(N):                    # run the same smoothing equations forward on simulated months
    L, T, S, total = lev, tr, sea[:], 0.0
    for h in range(M):
        s = S[h]
        yv = L + T + s + sig * normal()
        err[h][p] = yv - f[h]
        total += exp(yv)
        S[h] = g * (yv - L - T) + (1 - g) * s
        new = a * (yv - s) + (1 - a) * (L + T)
        T, L = b * (new - L) + (1 - b) * T, new
    tot.append(total)

print(" h month  forecast   lower   upper  actual  in | sd loop  sd closed  sd sim  cover sim  cover flat")
inside, cov12, flat12, sd_sim = 0, 0.0, 0.0, []
for h in range(M):
    w = Z * sig * sqrt(v_loop[h])
    lo, hi = exp(f[h] - w), exp(f[h] + w)
    ok = lo <= ACT[h] <= hi
    inside += ok
    mean = sum(err[h]) / N
    sd_sim.append(sqrt(sum((e - mean) * (e - mean) for e in err[h]) / (N - 1)))
    cover = sum(1 for e in err[h] if abs(e) <= w) / N
    flat = sum(1 for e in err[h] if abs(e) <= Z * sig) / N
    print(f"{h + 1:2d} {MON[h]}  {exp(f[h]):9.2f} {lo:7.2f} {hi:7.2f} {ACT[h]:7d}  {'yes' if ok else 'NO ':3s}|"
          f" {sig * sqrt(v_loop[h]):.5f}  {sig * sqrt(v_closed[h]):.5f}    {sd_sim[h]:.5f}  {cover:.4f}    {flat:.4f}")
    if h == M - 1: cov12, flat12, mean12 = cover, flat, mean

tot.sort()
F = [exp(x) for x in f]
var_tot = sum(F[h] * F[k] * sig * sig * sum(c[h - i] * c[k - i] for i in range(min(h, k) + 1))
              for h in range(M) for k in range(M))
lin_lo, lin_hi = sum(F) - Z * sqrt(var_tot), sum(F) + Z * sqrt(var_tot)
print(f"total   1960 forecast {sum(F):.1f}  simulated 95% band {tot[int(0.025 * N)]:.1f} to {tot[int(0.975 * N)]:.1f}"
      f"  linearised {lin_lo:.1f} to {lin_hi:.1f}  actual {sum(ACT)}")
print(f"hand    Jan log forecast {f[0]:.6f}  half-width {Z * sig:.6f}   Jul log forecast {f[6]:.6f}  v_7 {v_loop[6]:.5f}"
      f"  half-width {Z * sig * sqrt(v_loop[6]):.6f}")
print(f"check   1960 months inside the 95% band: {inside} of 12   h=12 mean simulated log error {mean12:.5f}")

ses_l = FIT[0]                         # simple smoothing, level only: recursion against explicit weights
for t in range(1, 132): ses_l = a * FIT[t] + (1 - a) * ses_l
ses_w = sum(a * (1 - a) ** k * FIT[131 - k] for k in range(131)) + (1 - a) ** 131 * FIT[0]
print(f"ses     recursion {ses_l:.10f}  weighted sum {ses_w:.10f}")
print("weights " + "  ".join(f"j={k} {a * (1 - a) ** k:.4f}" for k in range(6)))

ar, br, gr = fit([float(p) for p in P[:132]])  # what breaks: additive seasons on the raw counts
lr, tr_r, sr, _ = run([float(p) for p in P[:132]], ar, br, gr)
raw = [lr + (h + 1) * tr_r + sr[h] for h in range(M)]
mape = lambda fc: 100 * sum(abs(fc[h] - ACT[h]) / ACT[h] for h in range(M)) / M
print(f"try     log-scale error {mape(F):.2f}%   raw-count fit ({ar:.2f}, {br:.2f}, {gr:.2f}) error {mape(raw):.2f}%"
      f"   July raw {raw[6]:.2f}")
print(f"breaks  same month last year: 1960 total {sum(P[120:132])}  short by {sum(ACT) - sum(P[120:132])}"
      f"   Holt-Winters over by {sum(F) - sum(ACT):.1f}")
k80 = sum(1 for h in range(M) if abs(log(ACT[h]) - f[h]) <= 1.2816 * sig * sqrt(v_loop[h]))
a8, b8, g8 = fit(Y[:120])                     # the same method one year earlier: fit to 1949-1958, forecast 1959
l8, t8, s8, e8 = run(Y[:120], a8, b8, g8)
v8 = lambda h: 1 + sum(a8 * (1 + j * b8) * a8 * (1 + j * b8) for j in range(1, h))
in59 = sum(1 for h in range(M) if abs(Y[120 + h] - l8 - (h + 1) * t8 - s8[h]) <= Z * sqrt(e8 / 108) * sqrt(v8(h + 1)))
print(f"try     80% band holds {k80} of 12   alpha 0.9 sigma {sqrt(run(FIT, 0.9, b, g)[3] / n):.6f}"
      f"   fit to 1958 ({a8:.2f}, {b8:.2f}, {g8:.2f}): 1959 inside {in59} of 12")
l0, t0, _, _ = run(FIT, a, b, 0.0, seasons=False)
print(f"breaks  unwidened band at h=12 covers {flat12:.4f}   July with no season {exp(l0 + 7 * t0):.2f}")

assert all(abs(v_loop[h] - v_closed[h]) < 1e-12 for h in range(M))              # two formulas, one width
assert all(abs(sd_sim[h] / (sig * sqrt(v_loop[h])) - 1) < 4 / sqrt(2 * N) for h in range(M))  # simulation vs formula
assert abs(cov12 - 0.95) < 4 * sqrt(0.95 * 0.05 / N)                             # the band covers 95%
assert abs(mean12) < 4 * sd_sim[-1] / sqrt(N)                                     # simulated paths centre on f
assert max([abs(L2 - lev), abs(T2 - tr)] + [abs(S2[i] - sea[i]) for i in range(M)]) < 1e-12  # two update forms agree
assert abs(ses_l - ses_w) < 1e-9                                                   # recursion = fading weights
print("all checks passed")
