# Tomorrow's volatility: EWMA, GARCH and realised measures -- the check behind
# the card.  Standard library only.  Every number quoted on the card is printed.
# Variances print in percent-squared: a 1% daily return, squared, is 1.00.
# The random numbers are a 64-bit xorshift and Box-Muller, written out here.
from math import log, sqrt, cos, pi

R = [0.01, -0.02, 0.015, -0.005, 0.03, -0.025, 0.01, -0.015]  # Acme's daily log returns
A = [0.003, 0.004, 0.002, 0.003, 0.01, 0.008, 0.004, 0.005]    # each day's intraday swing
LAM, OMEGA, ALPHA, BETA, SEED = 0.94, 0.00001, 0.10, 0.85, 0.0002
P, M64 = 1e4, (1 << 64) - 1                                    # decimal -> percent-squared

state = [0x9E3779B97F4A7C15]
def normal():                                   # one standard bell-curve draw
    def unif():
        x = state[0]
        x ^= (x << 13) & M64; x ^= x >> 7; x ^= (x << 17) & M64
        state[0] = x
        return ((x >> 11) + 0.5) / 9007199254740992.0
    u1, u2 = unif(), unif()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def pieces(r, a):                               # four intraday log returns summing to r
    return (r / 4 + a, r / 4 - a, r / 4 + a / 2, r / 4 - a / 2)

# ---- road 1: the three rules, one close at a time ----
e, g, p, rv = [SEED], [SEED], [SEED], []        # e[i], g[i], p[i]: forecasts for day i+1
for r, a in zip(R, A):
    rv.append(sum(x * x for x in pieces(r, a)))
    e.append(LAM * e[-1] + (1 - LAM) * r * r)
    g.append(OMEGA + ALPHA * r * r + BETA * g[-1])
    p.append(rv[-1])
print(f"rules: lambda {LAM:.2f}; omega {P*OMEGA:.4f}, alpha {ALPHA:.2f}, beta {BETA:.2f}; seed {P*SEED:.4f}")
print("day  return%   realised   EWMA  GARCH  lag-RV   (variances in percent-squared)")
for i in range(8):
    print(f"{i+1:>3} {100*R[i]:>+8.2f} {P*rv[i]:>10.4f} {P*e[i]:>6.4f} {P*g[i]:>6.4f} {P*p[i]:>7.4f}")
print(f"day 9 forecasts: EWMA {P*e[8]:.4f}  GARCH {P*g[8]:.4f}  lag-RV {P*p[8]:.4f}")
print(f"day 9 as daily vol: EWMA {100*sqrt(e[8]):.4f}%  GARCH {100*sqrt(g[8]):.4f}%;"
      f" on a $100 share ${100*sqrt(e[8]):.2f} and ${100*sqrt(g[8]):.2f}")
for lab, xs in (("realised", rv), ("EWMA", e), ("GARCH", g)):
    print(f"chart {lab:<8} days 1-8: " + " ".join(f"{P*x:.2f}" for x in xs[:8]))

# ---- road 2: the same forecasts as one weighted sum, no recursion ----
n = len(R)
e_sum = LAM**n * SEED + sum((1 - LAM) * LAM**(n-1-j) * R[j]**2 for j in range(n))
g_sum = OMEGA * (1 - BETA**n) / (1 - BETA) + BETA**n * SEED \
        + sum(ALPHA * BETA**(n-1-j) * R[j]**2 for j in range(n))
rv_id = [r * r / 4 + 2.5 * a * a for r, a in zip(R, A)]
print(f"unrolled sums, day 9: EWMA {P*e_sum:.4f}  GARCH {P*g_sum:.4f}")
print(f"weight on newest square: EWMA {1-LAM:.2f}  GARCH {ALPHA:.2f}; on seed after 8 days: "
      f"EWMA {LAM**n:.4f}  GARCH {BETA**n:.4f}")

# ---- scoring days 2..8 against realised variance ----
names, fc = ("EWMA", "GARCH", "lag-RV"), (e, g, p)
mse = [sum((P*f[i] - P*rv[i])**2 for i in range(1, 8)) / 7 for f in fc]
qlk = [sum(rv[i]/f[i] - log(rv[i]/f[i]) - 1 for i in range(1, 8)) / 7 for f in fc]
usual = [sum(log(P*f[i]) + rv[i]/f[i] for i in range(1, 8)) / 7 for f in fc]
for k in range(3):
    print(f"score {names[k]:<6} MSE {mse[k]:.4f}   QLIKE {qlk[k]:.4f}   log f + RV/f {usual[k]:.4f}")
print(f"QLIKE gap GARCH - EWMA {qlk[1]-qlk[0]:.6f}; same gap in log f + RV/f {usual[1]-usual[0]:.6f}")
print(f"QLIKE for one day, forecast half of RV {2 - log(2) - 1:.4f}; forecast double RV {0.5 - log(0.5) - 1:.4f}")

# ---- several days ahead: closed form, iterated, simulated ----
rho, anchor = ALPHA + BETA, OMEGA / (1 - ALPHA - BETA)
closed = [anchor + rho**(k-1) * (g[8] - anchor) for k in range(1, 21)]
it = [g[8]]
for k in range(19):
    it.append(OMEGA + rho * it[-1])
paths, sim = 20000, [0.0] * 20
for _ in range(paths):
    h = g[8]
    for k in range(20):
        sim[k] += h / paths
        z = normal()
        h = OMEGA + ALPHA * h * z * z + BETA * h
print(f"GARCH anchor {P*anchor:.4f} (daily vol {100*sqrt(anchor):.4f}%, a year {100*sqrt(252*anchor):.2f}%);"
      f" half-life {log(0.5)/log(rho):.2f} days")
for k in (1, 2, 5, 10, 20):
    print(f"k={k:>2} days ahead: closed {P*closed[k-1]:.4f}  iterated {P*it[k-1]:.4f}  "
          f"simulated {P*sim[k-1]:.4f}  EWMA {P*e[8]:.4f}")
ten_g, ten_e = sum(closed[:10]), 10 * e[8]
print(f"10-day variance: GARCH sum {P*ten_g:.4f}  EWMA {P*ten_e:.4f}  10 x GARCH tomorrow {10*P*g[8]:.4f}")
print("chart GARCH k=1..20: " + " ".join(f"{P*c:.2f}" for c in closed))
print(f"chart EWMA k=1..20: flat at {P*e[8]:.2f}")

# ---- why score against realised variance: its noise, by simulation ----
h0, days, stats = SEED, 40000, {}
for m in (1, 4, 16):
    s1 = s2 = 0.0
    for _ in range(days):
        v = sum((sqrt(h0 / m) * normal())**2 for _ in range(m))
        s1 += P * v; s2 += (P * v)**2
    stats[m] = (s1 / days, s2 / days - (s1 / days)**2)
    print(f"proxy, {m:>2} pieces a day: mean {stats[m][0]:.4f}  variance {stats[m][1]:.4f}"
          f"  theory 2h^2/m {2*(P*h0)**2/m:.4f}")

# ---- a longer race: 2,500 days simulated from the GARCH rule itself ----
h, fe, fp, sc = anchor, anchor, anchor, [[0.0] * 6 for _ in range(3)]
for day in range(2750):
    xs = [sqrt(h / 4) * normal() for _ in range(4)]
    r, v = sum(xs), sum(x * x for x in xs)
    if day >= 250:                                # first 250 days only warm the rules up
        for k, f in enumerate((fe, h, fp)):       # GARCH's forecast is the true h here
            for j, tgt in enumerate((v, h)):
                sc[k][j] += (P*f - P*tgt)**2 / 2500
                sc[k][2 + j] += (log(P*f) + tgt / f) / 2500
    fe, fp, h = LAM * fe + (1 - LAM) * r * r, v, OMEGA + ALPHA * r * r + BETA * h
print("race, 2,500 days    MSE vs RV   MSE vs h   log f+RV/f   log f+h/f")
for k in range(3):
    print(f"race {names[k]:<6} {sc[k][0]:>17.4f} {sc[k][1]:>10.4f} {sc[k][2]:>12.4f} {sc[k][3]:>11.4f}")

# ---- what breaks ----
lam_flip = [SEED]
for r in R:
    lam_flip.append((1 - LAM) * lam_flip[-1] + LAM * r * r)
g90 = SEED
for r in R:
    g90 = OMEGA + ALPHA * r * r + 0.90 * g90
igarch = g90 + 19 * OMEGA                         # alpha + beta = 1: no pull, drift up by omega a day
peek = sum((P*p[i+1] - P*rv[i])**2 for i in range(1, 8)) / 7
print(f"wrong: lambda and 1-lambda swapped, day 9 {P*lam_flip[8]:.4f}; day 6 {P*lam_flip[5]:.4f}")
print(f"wrong: beta 0.90 (alpha+beta=1), day 9 {P*g90:.4f}, 20 days ahead {P*igarch:.4f}, still rising")
print(f"wrong: forecast scored against its own day, MSE {peek:.4f}")
print(f"wrong: 365-day year, annual vol from day 9 GARCH {100*sqrt(365*g[8]):.2f}% not {100*sqrt(252*g[8]):.2f}%")

assert max(abs(x - y) for x, y in zip(rv, rv_id)) < 1e-15, "realised sum vs its identity"
assert abs(e[8] - e_sum) < 1e-15, "EWMA recursion vs unrolled sum"
assert abs(g[8] - g_sum) < 1e-15, "GARCH recursion vs unrolled sum"
assert abs(P*it[19] - P*closed[19]) < 1e-9, "iterated vs closed-form term structure"
assert abs(sim[9] / closed[9] - 1) < 0.01, "simulated vs closed-form 10-day forecast"
assert abs((qlk[1]-qlk[0]) - (usual[1]-usual[0])) < 1e-12, "QLIKE ranking vs usual score"
assert all(abs(sum((P*f[i])**2 - 2*P*f[i]*P*rv[i] + (P*rv[i])**2 for i in range(1, 8)) / 7 - mse[k]) < 1e-9 for k, f in enumerate(fc)), "MSE vs expanded square"
assert sorted(range(3), key=lambda k: sc[k][0]) == sorted(range(3), key=lambda k: sc[k][1]), "RV ranks as h does"
assert all(abs(stats[m][1] / (2*(P*h0)**2/m) - 1) < 0.05 for m in stats), "proxy noise vs 2h^2/m"
print("ALL CHECKS PASS")
