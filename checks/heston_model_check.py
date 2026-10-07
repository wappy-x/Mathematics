# The Heston model -- the check behind the card.  Standard library only: the normal CDF is its
# own series, random numbers are splitmix64 made normal by the polar method, implied vols come
# from bisection.  rho = 0 by three roads: (1) Black-Scholes averaged over simulated average
# variance, (2) plain Monte Carlo, (3) the Hull-White expansion.  rho = -0.7 by two roads.
from math import log, exp, sqrt, pi
S, r, q, T = 100.0, 0.05, 0.02, 1.0                # the house market: Acme, one year
V0, THETA, KAPPA, XI, RHO = 0.04, 0.04, 2.0, 0.3, -0.7
STRIKES = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0]
PATHS, STEPS = 100000, 50
FWD, DT, M64 = S * exp((r - q) * T), T / STEPS, (1 << 64) - 1

def mean_vbar(v0, k, t): return THETA + (v0 - THETA) * (1.0 - exp(-k * t)) / (k * t)   # E of average variance
def stepped_vbar(v0, k, t, n=100000):              # the same, by stepping d E[v] = kappa (theta - E[v]) dt
    m, acc, h = v0, 0.0, t / n
    for _ in range(n): acc += m * h; m += k * (THETA - m) * h
    return acc / t
def N(x):                                          # normal CDF: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 1.0 if x > 0.0 else 0.0
    term, total, n = x, x, 1
    while abs(term) > 1e-17:
        term *= x * x / (2 * n + 1); total += term; n += 1
    return 0.5 + exp(-0.5 * x * x) / sqrt(2.0 * pi) * total
def bs(s, k, w, put=False):                        # Black-Scholes; w = total variance over the life
    sd = sqrt(w); d1 = (log(s / k) + (r - q) * T + 0.5 * w) / sd
    call = s * exp(-q * T) * N(d1) - k * exp(-r * T) * N(d1 - sd)
    return call - s * exp(-q * T) + k * exp(-r * T) if put else call
def implied(price, k, put):                        # bisection: price rises with sigma, so one sigma fits
    assert bs(S, k, 1e-4 * T, put) < price < bs(S, k, T, put), "price inside the bracket, 1% to 100%"
    lo, hi = 0.01, 1.0
    for _ in range(60): mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if bs(S, k, mid * mid * T, put) < price else (lo, mid)
    return 0.5 * (lo + hi)
def normals(seed):                                 # splitmix64 uniforms on (-1, 1), polar method
    state = seed
    def uniform():
        nonlocal state
        state = (state + 0x9E3779B97F4A7C15) & M64
        z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return 2.0 * ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 - 1.0
    while True:
        a, b = uniform(), uniform(); s = a * a + b * b
        if 0.0 < s < 1.0:
            f = sqrt(-2.0 * log(s) / s); yield a * f; yield b * f
class Acc:                                         # running mean and standard error
    def __init__(self): self.n, self.s, self.s2 = 0, 0.0, 0.0
    def add(self, x): self.n += 1; self.s += x; self.s2 += x * x
    def mean(self): return self.s / self.n
    def se(self): return sqrt((self.s2 - self.n * self.mean() * self.mean()) / (self.n - 1) / self.n)
def variance_path(nxt, xi):                        # full-truncation Euler: v_T, I = sum of v dt, cut steps
    v, I, cut = V0, 0.0, 0
    for _ in range(STEPS):
        vp = v if v > 0.0 else 0.0; cut += v <= 0.0
        I += vp * DT
        v += KAPPA * (THETA - vp) * DT + xi * sqrt(vp * DT) * nxt()
    return v, I, cut
def mixing_road(seed, xi, paths):                  # road 1: variance paths only, then Black-Scholes
    nxt = normals(seed).__next__
    mix0, mix7, plus7 = [Acc() for _ in STRIKES], [Acc() for _ in STRIKES], [Acc(), Acc()]
    atm, term, avg, hist, cut = Acc(), Acc(), Acc(), [0] * 7, 0
    for _ in range(paths):
        vT, I, c = variance_path(nxt, xi); cut += c
        J = (vT - V0 - KAPPA * THETA * T + KAPPA * I) / xi     # the variance's own noise, read off its path
        avg.add(I / T); atm.add(bs(S, 100.0, I)); term.add(bs(S, 100.0, max(vT, 1e-10) * T))
        hist[min(6, max(0, int((sqrt(I / T) * 100.0 - 13.0) / 2.0)))] += 1
        s7 = S * exp(RHO * J - 0.5 * RHO * RHO * I)             # rho = -0.7: the spot shifted by that noise
        for j, k in enumerate(STRIKES):
            mix0[j].add(bs(S, k, I, k < FWD)); mix7[j].add(bs(s7, k, (1.0 - RHO * RHO) * I, k < FWD))
        for j, k in enumerate((80.0, 120.0)):                    # try: rho = +0.7 on the same paths
            plus7[j].add(bs(S * exp(0.7 * J - 0.245 * I), k, 0.51 * I, k < FWD))
    return mix0, mix7, plus7, atm, term, avg, hist, cut
def var_I(xi):                                     # exact variance of I when v0 = theta (the house case)
    e1, e2 = exp(-KAPPA * T), exp(-2.0 * KAPPA * T)
    bracket = T - (1.0 - e2) / (2.0 * KAPPA) - (1.0 - e1) / KAPPA + e1 * (1.0 - e1) / KAPPA
    return THETA * xi * xi / (KAPPA * KAPPA) * bracket, bracket
def hull_white(k, put, var):                       # road 3: Black-Scholes at the mean, plus half the bend times var
    w = THETA * T; sd = sqrt(w); d1 = (log(S / k) + (r - q) * T + 0.5 * w) / sd
    cw = S * exp(-q * T) * exp(-0.5 * d1 * d1) / sqrt(2.0 * pi) / (2.0 * sd)
    cww = cw * (d1 * (d1 - sd) - 1.0) / (2.0 * w)
    return bs(S, k, w, put) + 0.5 * cww * var, d1, cw, cww
mix0, mix7, plus7, atm, term, avg, hist, cut = mixing_road(1, XI, PATHS)
atm6, cut5 = mixing_road(4, 0.6, 20000)[3], mixing_road(3, 0.5, 20000)[7]
nxt, c, disc = normals(2).__next__, sqrt(1.0 - RHO * RHO), exp(-r * T)
pl0, pl7, atm_plain = [Acc() for _ in STRIKES], [Acc() for _ in STRIKES], Acc()
for _ in range(PATHS):                             # road 2: price and variance simulated together
    v, x0, x7 = V0, log(S), log(S)
    for _ in range(STEPS):
        vp = v if v > 0.0 else 0.0
        sd, z2, zp = sqrt(vp * DT), nxt(), nxt()
        x0 += (r - q - 0.5 * vp) * DT + sd * zp                    # rho = 0: its own noise only
        x7 += (r - q - 0.5 * vp) * DT + sd * (RHO * z2 + c * zp)   # rho = -0.7: shares the variance's
        v += KAPPA * (THETA - vp) * DT + XI * sd * z2
    s0, s7 = exp(x0), exp(x7); atm_plain.add(disc * max(s0 - 100.0, 0.0))
    for j, k in enumerate(STRIKES):
        pl0[j].add(disc * (max(k - s0, 0.0) if k < FWD else max(s0 - k, 0.0)))
        pl7[j].add(disc * (max(k - s7, 0.0) if k < FWD else max(s7 - k, 0.0)))
(vI, bracket), sd_sim = var_I(XI), avg.se() * sqrt(PATHS)
(hw, d1, cw, cww), iv0, iv7 = hull_white(100.0, False, vI), [], []
toy = [bs(S, 100.0, w) for w in (0.02, 0.04, 0.06)]
print(f"house call at 20%, own normal CDF; forward    {bs(S, 100.0, 0.04):10.6f}; {FWD:.4f}")
print(f"Feller 2 kappa theta, xi^2; half-life, years  {2 * KAPPA * THETA:10.4f} {XI * XI:.4f}; {log(2.0) / KAPPA:.4f}")
print(f"average variance: formula, simulated, se      {mean_vbar(V0, KAPPA, T):10.6f} {avg.mean():.6f} {avg.se():.6f}")
print(f"its sd: formula, simulated                    {sqrt(vI) / T:10.6f} {sd_sim:.6f}")
print(f"truncated steps, %: xi = 0.3, xi = 0.5        {100.0 * cut / (PATHS * STEPS):10.4f} {100.0 * cut5 / (20000 * STEPS):.4f}")
print(f"average vol over the year, % of {PATHS} years:")
for j, lab in enumerate(["below 15%", "15 to 17%", "17 to 19%", "19 to 21%", "21 to 23%", "23 to 25%", "25% and up"]):
    print(f"  {lab:<12}{100.0 * hist[j] / PATHS:6.2f}")
print(f"years at variance 0.02, 0.04, 0.06; average   {toy[0]:10.4f} {toy[1]:.4f} {toy[2]:.4f}; {(toy[0] + toy[1] + toy[2]) / 3.0:.4f}")
print(f"rho = 0, 100 call: mixing, plain; se          {atm.mean():10.4f} {atm_plain.mean():.4f}; {atm.se():.4f} {atm_plain.se():.4f}")
print(f"Hull-White: d1, d2, phi(d1), C_w, C_ww        {d1:10.4f} {d1 - sqrt(THETA * T):.4f} {exp(-0.5 * d1 * d1) / sqrt(2.0 * pi):.4f} {cw:.2f} {cww:.1f}")
print(f"Hull-White: bracket, var I, correction, price {bracket:10.6f} {vI:.8f} {0.5 * cww * vI:.4f} {hw:.4f}")
for rho, mix, pl, ivs in ((0.0, mix0, pl0, iv0), (RHO, mix7, pl7, iv7)):
    print(f"rho = {rho:4.1f}:  K opt    mixing     se    plain     se   vol: mix plain" + ("   H-W" if rho == 0.0 else ""))
    for j, k in enumerate(STRIKES):
        p, a, b = k < FWD, mix[j], pl[j]
        ivs.append([implied(a.mean(), k, p), implied(b.mean(), k, p)] + ([implied(hull_white(k, p, vI)[0], k, p)] if rho == 0.0 else []))
        print(f"          {k:4.0f} {'put ' if p else 'call'} {a.mean():8.4f} {a.se():.4f} {b.mean():8.4f} {b.se():.4f}" + "".join(f" {100 * v:6.2f}" for v in ivs[j]))
print("root of expected average variance, %: T; v0 .09 kappa 2; v0 .09 kappa .5; v0 .01 kappa 2")
for t in (0.25, 0.5, 1.0, 2.0, 3.0, 5.0):
    ts = [100.0 * sqrt(mean_vbar(v, k, t)) for v, k in ((0.09, 2.0), (0.09, 0.5), (0.01, 2.0))]
    print(f"  {t:4.2f} {ts[0]:6.2f} {ts[1]:6.2f} {ts[2]:6.2f}")
gap = max(abs(mean_vbar(v, k, t) - stepped_vbar(v, k, t)) for t in (0.25, 0.5, 1.0, 2.0, 3.0, 5.0) for v, k in ((0.09, 2.0), (0.09, 0.5), (0.01, 2.0)))
print(f"term structure: formula against stepping, largest gap  {gap:.8f}")
print(f"wrong: Black-Scholes at the average variance  {bs(S, 100.0, mean_vbar(V0, KAPPA, T) * T):.4f}")
print(f"wrong: terminal variance, not the average     {term.mean():.4f}")
print(f"wrong: rho ignored, vol at 80 and 120         {100 * iv0[1][0]:.2f} {100 * iv0[5][0]:.2f}")
print(f"wrong: variance 0.04 fed in as the vol        {bs(S, 100.0, 0.04 * 0.04 * T):.4f}")
print(f"try: rho = +0.7, vol at 80 and 120            {100 * implied(plus7[0].mean(), 80.0, True):.2f} {100 * implied(plus7[1].mean(), 120.0, False):.2f}")
print(f"try: xi = 0.6: sd of average variance; mixing, se, Hull-White  {sqrt(var_I(0.6)[0]) / T:.6f}; {atm6.mean():.4f} {atm6.se():.4f} {hull_white(100.0, False, var_I(0.6)[0])[0]:.4f}")
assert abs(bs(S, 100.0, 0.04) - 9.227005508154) < 1e-9, "own normal CDF against the house call"
assert abs(avg.mean() - mean_vbar(V0, KAPPA, T)) < 3.0 * avg.se(), "simulated average variance against its formula"
assert gap < 1e-6, "term structure: formula against stepping the averaged equation"
assert abs(sd_sim / (sqrt(vI) / T) - 1.0) < 0.02, "simulated spread of average variance against its formula"
assert abs(atm.mean() - atm_plain.mean()) < 3.0 * sqrt(atm.se() ** 2 + atm_plain.se() ** 2), "road 1 against road 2"
for mix, pl in ((mix0, pl0), (mix7, pl7)):
    for a, b in zip(mix, pl): assert abs(a.mean() - b.mean()) < 3.0 * sqrt(a.se() ** 2 + b.se() ** 2), "mixing against plain"
assert abs(hw - atm.mean()) < 0.05, "road 3, the Hull-White expansion, against road 1"
assert atm.se() < atm_plain.se() / 5.0, "mixing removes most of the noise"
assert all(iv7[j][i] > iv7[j + 1][i] for j in range(6) for i in (0, 1)), "rho = -0.7: vol falls with strike"
assert iv0[0][0] > iv0[3][0] < iv0[6][0], "rho = 0: both wings above the middle"
print("ALL CHECKS PASS")
