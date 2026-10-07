# Basket options -- the check behind the card.  Nothing is imported but math's
# log, exp, sqrt, cos, sin and pi.  The normal CDF is a series written out
# here, the random numbers come from a hand-written generator, and the
# integral is Simpson's rule.  Three roads to one price: moment matching,
# correlated simulation, and an exact integral over the first share's shock.
from math import log, exp, sqrt, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height

def N(x):                           # bell-curve area left of x: Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    if x < 0.0: return 1.0 - N(-x)
    term, total, n = x, x, 1
    while term > 1e-17 * total:
        term *= x * x / (2 * n + 1); total += term; n += 1
    return 0.5 + phi(x) * total

S, SIG, Q, W = [100.0, 100.0], [0.20, 0.20], [0.02, 0.02], [0.5, 0.5]
R, T, K, RHO = 0.05, 1.0, 100.0, 0.5

def fwd(s, sig, q): return [s[i] * exp((R - q[i]) * T) for i in range(2)]
def cor(i, j, rho): return 1.0 if i == j else rho

def moments(s, sig, q, rho, w=W):   # exact E[B], E[B^2], E[B^3] of the basket at T
    F = fwd(s, sig, q); I = range(2)
    c = lambda i, j: cor(i, j, rho) * sig[i] * sig[j] * T
    m1 = sum(w[i] * F[i] for i in I)
    m2 = sum(w[i] * w[j] * F[i] * F[j] * exp(c(i, j)) for i in I for j in I)
    m3 = sum(w[i] * w[j] * w[k] * F[i] * F[j] * F[k] * exp(c(i, j) + c(i, k) + c(j, k))
             for i in I for j in I for k in I)
    return m1, m2, m3

def road1_mm(s=S, sig=SIG, q=Q, rho=RHO, k=K, w=W, spot=False):   # moment matching
    m1, m2, _ = moments(s, sig, q, rho, w)
    if spot: m2, m1 = m2 * (sum(w[i] * s[i] for i in range(2)) / m1) ** 2, sum(w[i] * s[i] for i in range(2))
    v = log(m2 / (m1 * m1))                  # total log-variance of the fitted share
    d1 = (log(m1 / k) + 0.5 * v) / sqrt(v); d2 = d1 - sqrt(v)
    return exp(-R * T) * (m1 * N(d1) - k * N(d2))

def road3_int(s=S, sig=SIG, q=Q, rho=RHO, k=K, w=W, n=2000):     # exact 1-D integral
    F = fwd(s, sig, q); rt = sqrt(T); sd = sig[1] * rt * sqrt(max(0.0, 1.0 - rho * rho))
    def f(z):                                 # share 2's own shock done in closed form
        c = w[0] * F[0] * exp(-0.5 * sig[0] ** 2 * T + sig[0] * rt * z)
        a = w[1] * F[1] * exp(-0.5 * sig[1] ** 2 * T + sig[1] * rt * rho * z)
        kk = k - c
        if kk <= 0.0: v = a * exp(0.5 * sd * sd) - kk
        elif sd < 1e-12: v = max(a - kk, 0.0)
        else:
            b = log(kk / a) / sd
            v = a * exp(0.5 * sd * sd) * N(sd - b) - kk * N(-b)
        return v * phi(z)
    lo, hi = -9.0, 9.0; h = (hi - lo) / n
    tot = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return exp(-R * T) * tot * h / 3.0

state = [20260924]
def uniform():                               # splitmix64, then 53 bits into (0, 1)
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 0.5 / 9007199254740992.0

def road2_mc(paths, rho=RHO, bug=False):     # correlated simulation, Cholesky by hand
    F = fwd(S, SIG, Q); state[0] = 20260924
    s1 = s2 = 0.0; l22 = 1.0 if bug else sqrt(1.0 - rho * rho)
    for _ in range(paths):
        u1, u2 = uniform(), uniform(); rad = sqrt(-2.0 * log(u1))
        z1, z2 = rad * cos(2.0 * pi * u2), rad * sin(2.0 * pi * u2)   # Box-Muller
        x2 = rho * z1 + l22 * z2
        b = sum(W[i] * F[i] * exp(-0.5 * SIG[i] ** 2 * T + SIG[i] * sqrt(T) * x)
                for i, x in ((0, z1), (1, x2)))
        p = max(b - K, 0.0); s1 += p; s2 += p * p
    mean = s1 / paths; se = sqrt((s2 / paths - mean * mean) / paths)
    return exp(-R * T) * mean, exp(-R * T) * se

m1, m2, m3 = moments(S, SIG, Q, RHO)
v = log(m2 / m1 ** 2); m3_logn = m1 ** 3 * (m2 / m1 ** 2) ** 3
mm, ex, ex_half = road1_mm(), road3_int(), road3_int(n=1000)
mc, se = road2_mc(400000)
bs_house = 9.227005508154                    # the pilot card's house call, typed in
print(f"forward of each share        {fwd(S, SIG, Q)[0]:.6f}")
print(f"E[B] and E[B^2]              {m1:.6f}  {m2:.6f}")
Fw = fwd(S, SIG, Q)[0]
print(f"E[B^2] own, own, cross       {W[0] ** 2 * Fw * Fw * exp(SIG[0] ** 2 * T):.6f}  "
      f"{W[1] ** 2 * Fw * Fw * exp(SIG[1] ** 2 * T):.6f}  {2 * W[0] * W[1] * Fw * Fw * exp(RHO * SIG[0] * SIG[1] * T):.6f}")
d1 = (log(m1 / K) + 0.5 * v) / sqrt(v)
print(f"E[B^2]/E[B]^2 and v = ln     {m2 / m1 ** 2:.6f}  {v:.6f}")
print(f"basket vol sigma_B           {sqrt(v / T):.6f}")
print(f"d1 d2 N(d1) N(d2)            {d1:.6f}  {d1 - sqrt(v):.6f}  {N(d1):.6f}  {N(d1 - sqrt(v)):.6f}")
print(f"E[B^3] exact                 {m3:.4f}")
print(f"E[B^3] fitted lognormal      {m3_logn:.4f}")
print(f"1 moment match               {mm:.6f}")
print(f"2 simulation, 400000 paths   {mc:.6f} +- {se:.6f}")
print(f"3 exact integral, n = 2000   {ex:.6f}")
print(f"  same, n = 1000             {ex_half:.6f}")
print(f"  moment match minus exact   {mm - ex:.6f}")
floor = fwd(S, SIG, Q)[0] * exp(-0.5 * SIG[0] ** 2 * T)      # rho = -1: B = floor * cosh(...)
m1n, m2n, _ = moments(S, SIG, Q, -1.0); sure = exp(-R * T) * (m1n - K)
vn = log(m2n / m1n ** 2); below = N(-(log(m1n / K) - 0.5 * vn) / sqrt(vn))
print(f"rho = -1: B never below      {floor:.6f}")
print(f"rho = -1: e^-rT (E[B] - K)   {sure:.6f}")
print(f"rho = -1: fit's P(B < K)     {below:.6f}")
print("rho    moment   exact    gap")
chart = []
for rho in [(-1.0 + 0.25 * i) for i in range(9)]:
    a, e = road1_mm(rho=rho), road3_int(rho=rho); chart.append((a, e))
    print(f"{rho:5.2f}  {a:7.4f}  {e:7.4f}  {a - e:7.4f}")
print("chart, moment match  " + " ".join(f"{a:.2f}" for a, _ in chart))
print("chart, exact         " + " ".join(f"{e:.2f}" for _, e in chart))
g = {}
for name, fn in (("moment", road1_mm), ("exact ", road3_int)):
    d = (fn(s=[100.01, 100.0]) - fn(s=[99.99, 100.0])) / 0.02
    vg = (fn(sig=[0.201, 0.2]) - fn(sig=[0.199, 0.2])) / 0.002 * 0.01
    rg = (fn(rho=0.51) - fn(rho=0.49)) / 0.02 * 0.01
    g[name] = (d, vg, rg)
    print(f"greeks {name} delta1 {d:.6f} vega1/pt {vg:.6f} rho/0.01 {rg:.6f}")
print(f"swing, rho 0.3 to 0.7        {road3_int(rho=0.7) - road3_int(rho=0.3):.6f}")
print(f"swing, sigma1 19% to 21%     {road3_int(sig=[0.21, 0.2]) - road3_int(sig=[0.19, 0.2]):.6f}")
print(f"wrong: rho set to 0          {road3_int(rho=0.0):.6f}")
print(f"wrong: spot not forward      {road1_mm(spot=True):.6f}")
print(f"wrong: no discount           {mm * exp(R * T):.6f}")
bug, bug_se = road2_mc(400000, bug=True)
print(f"wrong: rho matrix as mixer   {bug:.6f} +- {bug_se:.6f}")
print(f"  its share-2 vol and rho    {SIG[1] * sqrt(1 + RHO ** 2):.6f}  {RHO / sqrt(1 + RHO ** 2):.6f}")
print(f"wrong: two calls, half each  {0.5 * road1_mm(rho=1.0) + 0.5 * road1_mm(rho=1.0):.6f}")
print(f"try: K = 110                 {road3_int(k=110.0):.6f}")
print(f"try: weights 0.8/0.2         {road3_int(w=[0.8, 0.2]):.6f}")
print(f"try: sigma2 = 30%            {road3_int(sig=[0.2, 0.3]):.6f}  mm {road1_mm(sig=[0.2, 0.3]):.6f}")
print(f"story: Acme 130, Birch 80    basket {0.5 * 130 + 0.5 * 80:.0f}, call {max(0.5 * 130 + 0.5 * 80 - K, 0.0):.0f}, "
      f"two half calls {0.5 * max(130 - K, 0.0) + 0.5 * max(80 - K, 0.0):.0f}")
print("payoff at B = 80..130        " + " ".join(f"{max(b - K, 0.0):.0f}" for b in range(80, 131, 5)))
assert abs(mc - ex) < 3.0 * se, "simulation and exact integral disagree"
assert abs(ex - ex_half) < 1e-7, "integral not settled on its grid"
assert abs(road1_mm(rho=1.0) - bs_house) < 1e-9 and abs(road3_int(rho=1.0) - bs_house) < 1e-4
assert abs(road3_int(rho=-1.0) - sure) < 1e-9 and road1_mm(rho=-1.0) - sure > 0.1, "floor case"
assert abs(g["moment"][2] - g["exact "][2]) < 0.001 and abs(mm - ex) < 0.001
print("ALL CHECKS PASS")
