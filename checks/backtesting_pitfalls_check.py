# Backtesting pitfalls -- the check behind the card.  Standard library only.
# A model market of 50 stock slots over ten years, one reversal strategy, five backtests
# that each drop one pitfall.  Road 1 simulates 40 ten-year histories with a home-made
# random number generator; road 2 computes every Sharpe ratio exactly from the model.
from math import sqrt, log, exp, cos, sin, pi, acos

SF, SE1, SE2, B, K = 0.015, 0.012, 0.006, 0.5, 20  # fundamental wobble, mispricing shock (yrs 1-5, 6-10), carry-over, lookback
M, FAIL, L, MU, C = 50, 15, 250, -0.005, 0.0005     # slots, failures, days of decline, daily decline, cost per unit traded
N, W, H, BP = 2520, K + 2, 40, 1e4                  # days in ten years, warm-up days, simulated histories, bp
NAMES = ("look-ahead", "survivors, no costs", "survivors, costs", "all firms, no costs", "honest")
FLAGS = ((1, 0, 0), (2, 0, 0), (2, 0, 1), (2, 1, 0), (2, 1, 1))  # (lag, failures kept, costs charged)

def pdf(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def ncdf(x):                                          # bell-curve area left of x, by its power series
    term = total = x; k = 1
    while abs(term) > 1e-17: term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + pdf(x) * total
def deaths(fail): return [int(L + (N - L) * (j + 1) / fail) for j in range(fail)]

def regime(se, b):                                    # model pieces for one stretch of years
    vz = se * se / (1 - b * b)                        # steady spread^2 of the mispricing
    vr = SF * SF + 2 * vz * (1 - b)                   # spread^2 of one day's return
    sS = sqrt(K * SF * SF + 2 * vz * (1 - b ** K))    # spread of the 20-day signal
    g2 = -vz * b * (1 - b) * (1 - b ** K)             # covariance: signal with the return two days on
    rho = ((K - 1) * SF * SF + vz * (2 * b - b ** (K + 1) - b ** (K - 1))) / sS ** 2
    return vr, sS, g2, g2 / b, acos(rho) / pi         # last two: look-ahead covariance, flip chance

def bet(vr, sS, g, j, mu):                            # mean and variance of one bet: -sign(signal) x return
    m = j * mu / sS
    e = -mu * (2 * ncdf(m) - 1) - g / sS * 2 * pdf(m)
    return e, vr + mu * mu - e * e
def sharpe_parts(ms, vs):
    mean = sum(ms) / len(ms)
    s = sqrt(sum(vs) / len(vs) + sum((x - mean) ** 2 for x in ms) / len(ms))
    return mean / s * sqrt(252), mean, s

def exact(c=C, b=B, se2=SE2):                         # road 2: every day's mean and variance, from the model
    R = [regime(SE1, b), regime(se2, b)]; dd = deaths(FAIL); out = {}
    for name, (lag, dead, cost) in zip(NAMES, FLAGS):
        ms, vs = [], []
        for t in range(N):
            vr, sS, g2, g1, p = R[t >= N // 2]; g = g1 if lag == 1 else g2
            e0, v0 = bet(vr, sS, g, 0, 0.0); tot, var = e0 * M, v0 * M
            for d in dd if dead else []:
                if d - L <= t < d:
                    j = max(0, t - lag - max(t - lag - K + 1, d - L) + 1)   # declining days inside the signal
                    e, v = bet(vr, sS, g, j, MU); tot += e - e0; var += v - v0
            ms.append(tot / M - (2 * p * c if cost and t > 0 else 0.0)); vs.append(var / M / M)
        out[name] = [sharpe_parts(ms[a:z], vs[a:z]) for a, z in ((0, N), (0, N // 2), (N // 2, N))], ms
    return out, R
class Rng:                                            # splitmix64 uniforms, Box-Muller bell-curve draws
    def __init__(self, seed): self.x, self.spare = seed, None
    def u(self):
        self.x = (self.x + 0x9E3779B97F4A7C15) & (2 ** 64 - 1); z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def n(self):
        if self.spare is not None: v, self.spare = self.spare, None; return v
        r, a = sqrt(-2 * log(1.0 - self.u())), 2 * pi * self.u(); self.spare = r * sin(a); return r * cos(a)

def path(g, end):                                     # one firm's log price: fundamental plus mispricing
    f, z = 0.0, g.n() * SE1 / sqrt(1 - B * B); p = [f + z]
    for i in range(1, N + W):
        t = i - W
        f += (MU if end is not None and end - L <= t < end else 0.0) + SF * g.n()
        z = B * z + (SE1 if t < N // 2 else SE2) * g.n(); p.append(f + z)
    return p

def history(seed):                                    # road 1: run the five backtests on one history
    g, dd = Rng(seed), deaths(FAIL)
    surv = [path(g, None) for _ in range(M)]; doom = [path(g, d) for d in dd]
    out, pos_n, pos_h, turn = [[] for _ in NAMES], [0.0] * M, [0.0] * M, 0.0
    for t in range(N):
        i, day, tn, th = t + W, [0.0] * 3, 0.0, 0.0
        for s in range(M):
            p = surv[s]; q = doom[s] if s < FAIL and t < dd[s] else p
            wl = -1.0 if p[i - 1] > p[i - 1 - K] else 1.0          # decided at the close it fills at
            wn = -1.0 if p[i - 2] > p[i - 2 - K] else 1.0          # decided a day before the fill
            wh = -1.0 if q[i - 2] > q[i - 2 - K] else 1.0
            day[0] += wl * (p[i] - p[i - 1]); day[1] += wn * (p[i] - p[i - 1]); day[2] += wh * (q[i] - q[i - 1])
            tn += abs(wn - pos_n[s]); th += abs(wh - pos_h[s]); pos_n[s], pos_h[s] = wn, wh
        cn, ch = (C * tn / M, C * th / M) if t > 0 else (0.0, 0.0)
        turn += tn / M if t > 0 else 0.0
        for k, v in enumerate((day[0] / M, day[1] / M, day[1] / M - cn, day[2] / M, day[2] / M - ch)): out[k].append(v)
    return out, turn / (N - 1)

def sim_sharpe(x): mean = sum(x) / len(x); return mean / sqrt(sum((v - mean) ** 2 for v in x) / len(x)) * sqrt(252), mean

ex, R = exact()
pool, halves, turns = [[] for _ in NAMES], [([], []) for _ in NAMES], 0.0
for h in range(H):
    runs, tv = history(2026 + h); turns += tv / H
    if h == 0: one = [sim_sharpe(x)[0] for x in runs]
    for k, x in enumerate(runs): pool[k] += x; halves[k][0].extend(x[:N // 2]); halves[k][1].extend(x[N // 2:])
sim = [[sim_sharpe(pool[k]), sim_sharpe(halves[k][0]), sim_sharpe(halves[k][1])] for k in range(5)]

print(f"model: {M} slots, 10 years, {FAIL} failures falling {-MU * 100:.2f}% a day for {L} days, lookback {K} days, cost {C * BP:.1f} bp")
print(f"model: fundamental {SF * 100:.2f}% a day, carry-over b {B:.2f}; {H} histories = {10 * H} years; sqrt(2/pi) {sqrt(2 / pi):.3f}, sqrt(252) {sqrt(252):.2f}")
for lab, (vr, sS, g2, g1, p), sh in (("years 1-5 ", R[0], SE1), ("years 6-10", R[1], SE2)):
    e, e1 = bet(vr, sS, g2, 0, 0.0)[0], bet(vr, sS, g1, 0, 0.0)[0]
    print(f"{lab}: shock {sh * 100:.2f}%  v_z {sh * sh / (1 - B * B) * BP:.3f} %^2  sigma_S {sS * 100:.2f}%  "
          f"gamma {g2 * BP:.3f} %^2  look-ahead {g1 * BP:.3f} %^2  p {p:.4f}")
    print(f"{lab}: edge e {e * BP:.2f} bp  look-ahead {e1 * BP:.2f} bp  one bet {sqrt(vr) * 100:.2f}%  "
          f"s {sqrt((vr - e * e) / M) * BP:.1f} bp")
turn_exact, fac = R[0][4] + R[1][4], sqrt(252) / (ex[NAMES[4]][0][0][2] * BP)   # fac: Sharpe per bp a day
print(f"turnover per day: exact {turn_exact:.4f}, simulated {turns:.4f}; cost per day {turn_exact * C * BP:.3f} bp "
      f"= {turn_exact * C * BP * fac:.3f} Sharpe")
vr, sS, g2 = R[0][:3]; mf = K * MU / sS
print(f"failing firm, fully in decline (years 1-5): signal mean {K * MU * 100:.1f}% = {mf:.3f} spreads, "
      f"N {ncdf(mf):.4f}, long {1 - ncdf(mf):.4f}")
print(f"failing firm: drift part {-MU * (2 * ncdf(mf) - 1) * BP:.2f} bp, "
      f"edge part {-g2 / sS * 2 * pdf(mf) * BP:.2f} bp, total {bet(vr, sS, g2, K, MU)[0] * BP:.2f} bp")
gain_x, gain_s = (sum(ex[NAMES[1]][1]) - sum(ex[NAMES[3]][1])) / N * BP, (sim[1][0][1] - sim[3][0][1]) * BP
print(f"survivor gain per day: exact {gain_x:.3f} bp = {gain_x * fac:.3f} Sharpe, simulated {gain_s:.3f} bp")
print("Sharpe ratio           exact: 10y  yrs1-5 yrs6-10 | simulated 400y: 10y  yrs1-5 yrs6-10")
for k, name in enumerate(NAMES):
    a = ex[name][0]
    print(f"{name:<21} {a[0][0]:9.3f} {a[1][0]:7.3f} {a[2][0]:7.3f} | {sim[k][0][0]:12.3f} {sim[k][1][0]:7.3f} {sim[k][2][0]:7.3f}")
for k in (1, 4):
    sr, mean, s = ex[NAMES[k]][0][0]
    print(f"{NAMES[k]:<21} 10y daily mean {mean * BP:.3f} bp, spread s {s * BP:.3f} bp, 1 bp a day = {sqrt(252) / (s * BP):.3f} Sharpe")
print("one 10-year history:   " + "  ".join(f"{v:.2f}" for v in one) + "; one decade's standard error: "
      + ", ".join(f"{sqrt((1 + x * x / 2) / 10):.3f}" for x in (ex[NAMES[1]][0][0][0], ex[NAMES[4]][0][0][0])))
print(f"wrong: 365 days a year {(hon := ex[NAMES[4]][0][0][0]) * sqrt(365 / 252):.3f}; "
      f"wrong: times 252, not its root {hon * sqrt(252):.3f}; "
      f"wrong: years 1-5 only {ex[NAMES[4]][0][1][0]:.3f}")
tries = (("cost 2.5 bp", exact(c=0.00025)), ("cost 10 bp", exact(c=0.001)),
         ("carry-over b 0.8", exact(b=0.8)), ("no regime change", exact(se2=SE1)))
print("try, honest 10y: " + "; ".join(f"{lab} {o[0][NAMES[4]][0][0][0]:.3f}" for lab, o in tries))
print(f"chart, {'year':<20}" + " ".join(f"{y:6d}" for y in range(11)))
for k in (0, 1, 4):
    ms = ex[NAMES[k]][1]
    print(f"chart, {NAMES[k]:<20}" + " ".join(f"{sum(ms[:252 * y]) * 100:6.2f}" for y in range(11)))

se = lambda sr: 3 * sqrt((1 + sr * sr / 2) / (10 * H))           # three standard errors, 400 years
for k in (0, 1, 4): assert abs(sim[k][0][0] - ex[NAMES[k]][0][0][0]) < se(ex[NAMES[k]][0][0][0]), NAMES[k]
assert abs(turns - turn_exact) < 0.01 * turn_exact, "flip chance from arccos vs counted flips"
assert abs(gain_s - gain_x) < 0.05 * gain_x, "survivor gain, simulated vs exact"
print("ALL CHECKS PASS")
