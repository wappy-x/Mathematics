# Reserving check: chain ladder, Bornhuetter-Ferguson and Mack's standard error.
# Standard library only.  Amounts in thousands of dollars.  Nothing imported knows
# the answer: the factors, the marginal-totals fit, the random numbers are all here.
from math import sqrt, log, cos, pi, prod

# Cumulative reported claims: accident years 2016..2025 down, development age 1..10 across.
TRI = [[3616, 6170, 6846, 7304, 7832, 8130, 8305, 8382, 8437, 8464],
       [3533, 4868, 5650, 6167, 6581, 6875, 7053, 7133, 7174],
       [3476, 4613, 5100, 5596, 5869, 6038, 6189, 6259],
       [3772, 5320, 5880, 6386, 6644, 6858, 7040],
       [3975, 5516, 6749, 7584, 8097, 8441],
       [4171, 6842, 7869, 8959, 9658],
       [3918, 6369, 7638, 8379], [4308, 6531, 8018],
       [4438, 7358], [4486]]
PREM = [11000.0 + 500.0 * i for i in range(10)]          # earned premium, $000
ELR = 0.70                                               # planning loss ratio
# Taylor & Ashe (1983), the triangle Mack (1993) used; his Tables 2 and 3 are checked below.
TA = [[357848, 1124788, 1735330, 2218270, 2745596, 3319994, 3466336, 3606286, 3833515, 3901463],
      [352118, 1236139, 2170033, 3353322, 3799067, 4120063, 4647867, 4914039, 5339085],
      [290507, 1292306, 2218525, 3235179, 3985995, 4132918, 4628910, 4909315],
      [310608, 1418858, 2195047, 3757447, 4029929, 4381982, 4588268],
      [443160, 1136350, 2128333, 2897821, 3402672, 3873311],
      [396132, 1333217, 2180715, 2985752, 3691712],
      [440832, 1288463, 2419861, 3483130], [359480, 1421128, 2864498],
      [376686, 1363294], [344014]]
def factors(t, how="volume"):                            # age-to-age factors f_1..f_9
    f = []
    for k in range(len(t) - 1):
        rows = [r for r in t if len(r) > k + 1]
        if how == "volume": f.append(sum(r[k + 1] for r in rows) / sum(r[k] for r in rows))
        if how == "simple": f.append(sum(r[k + 1] / r[k] for r in rows) / len(rows))
        if how == "zeros": f.append(sum(r[k + 1] for r in rows) / sum(r[k] for r in t if len(r) > k))
    return f
def to_ult(f, a): return prod(f[a:])                   # F: product of the factors still to come
def sigmas(t, f):                                        # Mack's sigma_k^2, last one extrapolated
    s2 = []
    for k in range(len(t) - 2):
        rows = [r for r in t if len(r) > k + 1]
        s2.append(sum(r[k] * (r[k + 1] / r[k] - f[k]) ** 2 for r in rows) / (len(rows) - 1))
    s2.append(min(s2[-1] ** 2 / s2[-2], s2[-2], s2[-1]))
    return s2
def mack(t, f, s2):                                      # road 1: Mack's closed formula
    n = len(t); S = [sum(r[k] for r in t if len(r) > k + 1) for k in range(n - 1)]
    U, mse, proc = [], [], []
    for r in t:
        c, a, pe, pa = float(r[-1]), len(r) - 1, 0.0, 0.0
        for k in range(a, n - 1):
            pe += s2[k] / f[k] ** 2 / c; pa += s2[k] / f[k] ** 2 / S[k]; c *= f[k]
        U.append(c); mse.append(c * c * (pe + pa)); proc.append(c * c * pe)
    cross = sum(2 * U[i] * U[j] * sum(s2[k] / f[k] ** 2 / S[k] for k in range(len(t[i]) - 1, n - 1))
                for i in range(n) for j in range(i + 1, n))
    return U, mse, proc, cross
def mack_recursive(t, f, s2):                            # road 2: carry the variance forward a year at a time
    n = len(t); S = [sum(r[k] for r in t if len(r) > k + 1) for k in range(n - 1)]
    total, grad = 0.0, [0.0] * (n - 1)                   # grad[k]: all years' sensitivity to f_k
    for r in t:
        c, v = float(r[-1]), 0.0
        for k in range(len(r) - 1, n - 1):
            v = f[k] ** 2 * v + s2[k] * c; c *= f[k]     # process variance, one year on
        total += v
        for k in range(len(r) - 1, n - 1): grad[k] += c / f[k]
    return total + sum(grad[k] ** 2 * s2[k] / S[k] for k in range(n - 1))  # plus factor error, shared
def marginal_totals(t, E=None):                          # road 2 for CL and BF: fit x_i * y_k to increments
    n = len(t); inc = [[r[0]] + [r[k] - r[k - 1] for k in range(1, len(r))] for r in t]
    rs = [sum(r) for r in inc]; cs = [sum(r[k] for r in inc if len(r) > k) for k in range(n)]
    y = [1.0 / n] * n
    for _ in range(4000):
        x = [rs[i] / sum(y[:len(inc[i])]) for i in range(n)]
        y = [cs[k] / sum(x[i] for i in range(n) if len(inc[i]) > k) for k in range(n)]
    y = [v / sum(y) for v in y]; x = [rs[i] / sum(y[:len(inc[i])]) for i in range(n)]
    base = x if E is None else E
    return [base[i] * sum(y[len(inc[i]):]) for i in range(n)]
def cl_bf(t, E):                                         # road 1: the chain-ladder and BF formulas
    f = factors(t)
    F = [to_ult(f, len(r) - 1) for r in t]
    return f, F, [r[-1] * (Fi - 1) for r, Fi in zip(t, F)], [e * (1 - 1 / Fi) for e, Fi in zip(E, F)]
E = [ELR * p for p in PREM]; f, F, R_cl, R_bf = cl_bf(TRI, E)
s2 = sigmas(TRI, f); U, mse, proc, cross = mack(TRI, f, s2)
R_cl2, R_bf2 = marginal_totals(TRI), marginal_totals(TRI, E)
mse_tot, mse_rec = sum(mse) + cross, mack_recursive(TRI, f, s2)
seed = 20260928                                          # road 3: simulate the process part (Mack's model, f fixed)
def unif():
    global seed
    seed = (6364136223846793005 * seed + 1442695040888963407) % 2 ** 64
    return ((seed >> 11) + 0.5) / 2 ** 53
N, s_sum, s_sq = 40000, 0.0, 0.0
for _ in range(N):
    tot = 0.0
    for r in TRI:
        c = float(r[-1])
        for k in range(len(r) - 1, 9):
            z = sqrt(-2 * log(unif())) * cos(2 * pi * unif())
            c = f[k] * c + sqrt(s2[k] * c) * z
        tot += c - r[-1]
    s_sum += tot; s_sq += tot * tot
sim_mean, sim_sd = s_sum / N, sqrt((s_sq - s_sum * s_sum / N) / (N - 1))

print("age   f_k      F to ult  % reported  sigma_k^2")
for k in range(10):
    Fk = to_ult(f, k)
    print(f"{k + 1:>3}  {f[k] if k < 9 else 1.0:7.4f}  {Fk:8.4f}  {100 / Fk:9.2f}  " + (f"{s2[k]:9.4f}" if k < 9 else "        -"))
print("year  latest   F      CL ult   CL IBNR   prior E   BF IBNR  Mack se")
for i, r in enumerate(TRI):
    print(f"{2016 + i}  {r[-1]:6d}  {F[i]:6.4f} {U[i]:8.1f}  {R_cl[i]:8.2f}  {E[i]:7.1f}  {R_bf[i]:8.2f}  {sqrt(mse[i]):6.1f}")
sd_proc = sqrt(sum(proc))
wrong = [sum(r[-1] * (to_ult(factors(TRI, how), len(r) - 1) - 1) for r in TRI) for how in ("simple", "zeros")]
shock = [r[:] for r in TRI]; shock[9][0] = round(1.2 * TRI[9][0])  # a large claim lands in 2025
_, _, Rc_s, Rb_s = cl_bf(shock, E); _, _, _, R_bk = cl_bf(TRI, [r[-1] + b for r, b in zip(TRI, R_bf)])  # Benktander
_, _, _, R_bf60 = cl_bf(TRI, [0.60 * p for p in PREM])
fT = factors(TA); UT, mT, _, cT = mack(TA, fT, sigmas(TA, fT))
ta_R, ta_se = sum(u - r[-1] for u, r in zip(UT, TA)), sqrt(sum(mT) + cT)
rows = [("f_1: age-2 total, 2016-2024", sum(r[1] for r in TRI[:9])), ("f_1: age-1 total, 2016-2024", sum(r[0] for r in TRI[:9])),
        ("CL IBNR, factors", sum(R_cl)), ("CL IBNR, marginal totals", sum(R_cl2)),
        ("BF IBNR, formula", sum(R_bf)), ("BF IBNR, marginal totals", sum(R_bf2)),
        ("Mack se total, closed form", sqrt(mse_tot)), ("Mack se total, recursion", sqrt(mse_rec)),
        ("  cross-year term in mse", cross), ("  process se, formula", sd_proc),
        ("  process se, 40000 sims", sim_sd), ("  mean reserve, 40000 sims", sim_mean),
        ("  se as % of CL IBNR", 100 * sqrt(mse_tot) / sum(R_cl)),
        ("wrong: simple-average factors", wrong[0]), ("wrong: empty cells as zeros", wrong[1]),
        ("wrong: BF with reported share", sum(e / Fi for e, Fi in zip(E, F))),
        ("wrong: se, process only", sd_proc), ("wrong: se, no cross term", sqrt(sum(mse))),
        ("wrong: se, ten se's added", sum(sqrt(m) for m in mse)),
        ("try: 2025 reported 5383, CL IBNR", sum(Rc_s)), ("try: 2025 reported 5383, BF IBNR", sum(Rb_s)),
        ("try: ELR 0.60, BF IBNR", sum(R_bf60)), ("try: Benktander IBNR", sum(R_bk)),
        ("Taylor-Ashe CL reserve", ta_R), ("Taylor-Ashe Mack se", ta_se), ("Taylor-Ashe se, % of reserve", 100 * ta_se / ta_R)]
for name, v in rows:
    print(f"{name:<34} {v:14.1f}")

assert abs(sum(R_cl) - sum(R_cl2)) < 1e-3,        "marginal totals must reproduce chain ladder"
assert abs(sum(R_bf) - sum(R_bf2)) < 1e-3,        "marginal-totals pattern must reproduce BF"
assert abs(mse_tot - mse_rec) < 1e-6 * mse_tot,   "recursion must reproduce Mack's closed form"
assert abs(sim_sd / sd_proc - 1) < 0.02,          "simulated process se within 2%"
assert abs(sim_mean / sum(R_cl) - 1) < 0.002,     "simulated mean reserve within 0.2%"
ta_k = [round((u - r[-1]) / 1000) for u, r in zip(UT[1:], TA[1:])]
ta_pct = [round(100 * sqrt(m) / (u - r[-1])) for m, u, r in zip(mT[1:], UT[1:], TA[1:])]
assert ta_k == [95, 470, 710, 985, 1419, 2178, 3920, 4279, 4626], "Mack (1993) Table 2, reserves in $000"
assert ta_pct == [80, 26, 19, 27, 29, 26, 22, 23, 29],            "Mack (1993) Table 3, se as % of reserve"
assert round(100 * ta_se / ta_R) == 13,                           "Mack (1993) Table 3, overall 13%"
assert abs(sum(Rb_s) - sum(R_bf)) < 1e-9,        "a 2025 surprise leaves BF where it was"
print("ALL CHECKS PASS")
