# Collateral and the residual exposure -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Nothing imported knows the answer: the normal CDF,
# the root finder, the integrator and the random numbers are all written below.
from math import exp, log, sqrt, pi, cos

def N(x):  # normal CDF, Hart's rational approximation (double precision)
    a = abs(x); e = exp(-a * a / 2)
    if a > 37: c = 0.0
    elif a < 7.07106781186547:
        p = (((((0.0352624965998911 * a + 0.700383064443688) * a + 6.37396220353165) * a + 33.912866078383) * a + 112.079291497871) * a + 221.213596169931) * a + 220.206867912376
        s = ((((((0.0883883476483184 * a + 1.75566716318264) * a + 16.064177579207) * a + 86.7807322029461) * a + 296.564248779674) * a + 637.333633378831) * a + 793.826512519948) * a + 440.413735824752
        c = e * p / s
    else: c = e / (a + 1 / (a + 2 / (a + 3 / (a + 4 / (a + 0.65))))) / 2.506628274631
    return 1 - c if x > 0 else c

def Ninv(p):  # root finder: bisection on N
    lo, hi = -10.0, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return (lo + hi) / 2

S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
lam, R = 0.02, 0.40; LGD = 1 - R
H, M, lag = 2.0, 0.5, 10 / 252           # threshold, minimum transfer, margin period (ten trading days)
mu = r - q - sig * sig / 2

def V(S, t):  # the call's clean value at date t when Acme is at S
    u = T - t
    if u <= 1e-12: return max(S - K, 0.0)
    d1 = (log(S / K) + (r - q + sig * sig / 2) * u) / (sig * sqrt(u))
    return S * exp(-q * u) * N(d1) - K * exp(-r * u) * N(d1 - sig * sqrt(u))

# ---- Road 1: Simpson over the bell curve, one date per month ----
NZ, L = 80, 8.0; hz = 2 * L / NZ
Z = [-L + i * hz for i in range(NZ + 1)]
W = [(1 if i in (0, NZ) else 4 if i % 2 else 2) * hz / 3 * exp(-z * z / 2) / sqrt(2 * pi) for i, z in enumerate(Z)]

def ee(t, H, lag):  # discounted expected residual at date t; lag = 0 means margin arrives instantly
    tl = max(t - lag, 0.0); dl = t - tl; tot = 0.0
    for z1, w1 in zip(Z, W):
        s1 = S0 * exp(mu * tl + sig * sqrt(tl) * z1)
        if lag == 0: tot += w1 * min(V(s1, t), H); continue
        c = max(V(s1, tl) - H, 0.0)       # collateral held: set at the last margin call, frozen since
        tot += w1 * sum(w2 * max(V(s1 * exp(mu * dl + sig * sqrt(dl) * z2), t) - c, 0.0) for z2, w2 in zip(Z, W))
    return exp(-r * t) * tot

NB = 12; mids = [(i + 0.5) / NB for i in range(NB)]
def cva(H, lag, lam=lam):
    prof = [ee(t, H, lag) for t in mids]
    return LGD * sum((exp(-lam * i / NB) - exp(-lam * (i + 1) / NB)) * e for i, e in enumerate(prof)), prof

# ---- Road 2: daily Monte Carlo paths, margin called every day, default on any day ----
st = 0x2545F4914F6CDD1D; MASK = (1 << 64) - 1
def unif():  # xorshift64*, top 53 bits, never 0
    global st
    st ^= st >> 12; st ^= (st << 25) & MASK; st ^= st >> 27
    return ((((st * 2685821657736338717) & MASK) >> 11) + 0.5) / 9007199254740992.0

ND, LAGD, PAIRS = 252, 10, 2500; dt = T / ND
wk = [exp(-lam * (k - 1) * dt) - exp(-lam * k * dt) for k in range(ND + 1)]
dk = [exp(-r * k * dt) for k in range(ND + 1)]
cases = ("none", "thr", "thr_mpor", "zero_mpor", "thr_mpor_mta")
acc = {c: [] for c in cases}; moves = []; worst = -1.0
for _ in range(PAIRS):
    zs = [sqrt(-2 * log(unif())) * cos(2 * pi * unif()) for _ in range(ND)]
    pair = {c: 0.0 for c in cases}
    for sgn in (1.0, -1.0):                   # antithetic: the same path and its mirror image
        S = S0; v = [V(S, 0.0)]
        for k in range(1, ND + 1):
            S *= exp(mu * dt + sig * sqrt(dt) * sgn * zs[k - 1]); v.append(V(S, k * dt))
        moves.append(v[LAGD] - v[0])
        c2 = [max(x - H, 0.0) for x in v]; c0 = v; cm = []; held = 0.0
        for x in v:
            tgt = max(x - H, 0.0)
            if abs(tgt - held) >= M: held = tgt
            cm.append(held)
        for k in range(1, ND + 1):
            j = max(k - LAGD, 0); f = wk[k] * dk[k] / 2
            res = max(v[k] - cm[j], 0.0)
            worst = max(worst, res - (H + M + max(v[k] - v[j], 0.0)))
            pair["none"] += f * v[k]; pair["thr"] += f * min(v[k], H)
            pair["thr_mpor"] += f * max(v[k] - c2[j], 0.0); pair["zero_mpor"] += f * max(v[k] - c0[j], 0.0)
            pair["thr_mpor_mta"] += f * res
    for c in cases: acc[c].append(LGD * pair[c])
mc = {c: sum(a) / PAIRS for c, a in acc.items()}
se = {c: sqrt(sum((x - mc[c]) ** 2 for x in a) / (PAIRS - 1) / PAIRS) for c, a in acc.items()}

# ---- the numbers ----
C0 = V(S0, 0.0); pd1 = 1 - exp(-lam * T)
d1 = (log(S0 / K) + (r - q + sig * sig / 2) * T) / (sig * sqrt(T)); delta = exp(-q * T) * N(d1)
cva_none = LGD * C0 * pd1
cva_thr, prof_thr = cva(H, 0.0)
cva_mp, prof_mp = cva(H, lag)
cva_zero, prof_zero = cva(0.0, lag)
cap = LGD * H * lam * (1 - exp(-(lam + r) * T)) / (lam + r)     # threshold-only can never exceed this
z99 = Ninv(0.99); move_delta = z99 * delta * S0 * sig * sqrt(lag)
move_full = V(S0 * exp(mu * lag + sig * sqrt(lag) * z99), lag) - C0
moves.sort(); move_mc = moves[int(0.99 * len(moves)) - 1]
envelope = LGD * pd1 * delta * S0 * sig * sqrt(lag) / sqrt(2 * pi)   # back of envelope for zero threshold
vm0 = C0 - H; h, fall = 0.04, 0.03; bonds = vm0 / (1 - h)
wrong_q99 = LGD * sum((exp(-lam * i / NB) - exp(-lam * (i + 1) / NB)) * exp(-r * t) for i, t in enumerate(mids)) * (H + move_delta)

rows = [("clean call C0", C0), ("default chance in the year", pd1), ("call delta", delta),
        ("margin period in years (10/252)", lag),
        ("CVA, no collateral: closed form", cva_none), ("CVA, no collateral: Monte Carlo", mc["none"]),
        ("  Monte Carlo standard error", se["none"]),
        ("CVA, threshold 2, instant: Simpson", cva_thr), ("CVA, threshold 2, instant: Monte Carlo", mc["thr"]),
        ("  ceiling LGD x H x discounted PD", cap),
        ("CVA, threshold 2 + 10 days: Simpson", cva_mp), ("CVA, threshold 2 + 10 days: Monte Carlo", mc["thr_mpor"]),
        ("  Monte Carlo standard error", se["thr_mpor"]),
        ("CVA, threshold 0 + 10 days: Simpson", cva_zero), ("CVA, threshold 0 + 10 days: Monte Carlo", mc["zero_mpor"]),
        ("  Monte Carlo standard error", se["zero_mpor"]), ("  back of envelope", envelope),
        ("CVA, threshold 2 + 10 days + MTA 0.5: MC", mc["thr_mpor_mta"]),
        ("worst residual minus bound H+M+move", worst),
        ("z at 99%", z99), ("99% ten-day move, delta rule", move_delta),
        ("99% ten-day move, full revaluation", move_full), ("99% ten-day move, Monte Carlo", move_mc),
        ("99% residual, threshold 2", H + move_delta),
        ("margin called today, threshold 2", vm0), ("bonds posted at 4% haircut", bonds),
        ("  after a 3% fall", bonds * (1 - fall)),
        ("  shortfall with no haircut", vm0 * fall),
        ("wrong: 99% move in place of average", wrong_q99),
        ("try: 20-day margin period, threshold 2", cva(H, 2 * lag)[0]),
        ("try: 20-day margin period, threshold 0", cva(0.0, 2 * lag)[0]),
        ("try: hazard 4%, threshold 2 + 10 days", cva(H, lag, 0.04)[0])]
for name, x in rows: print(f"{name:<42} {x:>12.6f}")
print("CVA against threshold H, 10-day margin period: dollars, cents")
for hh in (0.0, 0.5, 1.0, 2.0, 3.0, 5.0, 10.0, float("inf")):
    x = cva(hh, lag)[0] if hh != H else cva_mp; print(f"  H = {hh:>4.1f} {x:>12.6f} {100 * x:>8.2f}")
print("discounted expected residual, cents: instant thr 2 | thr 2 + 10d | thr 0 + 10d")
for t, a, b, c in zip(mids, prof_thr, prof_mp, prof_zero): print(f"  t = {t:.4f} {100 * a:>8.2f} {100 * b:>8.2f} {100 * c:>8.2f}")

assert abs(C0 - 9.227005508154) < 1e-9                                  # house call, from the pilot card
assert abs(mc["none"] - cva_none) < 4 * se["none"] + 2e-4               # simulation meets the closed form
assert abs(mc["thr"] - cva_thr) < 4 * se["thr"] + 2e-5                  # simulation meets Simpson
assert abs(mc["thr_mpor"] - cva_mp) < 4 * se["thr_mpor"] + 2e-5
assert abs(mc["zero_mpor"] - cva_zero) < 4 * se["zero_mpor"] + 2e-5
assert cva_thr < cap; assert worst <= 1e-12                             # the two bounds proved on the card
assert abs(envelope / cva_zero - 1) < 0.1; assert abs(move_mc - move_full) < 0.4
print("all checks passed")
