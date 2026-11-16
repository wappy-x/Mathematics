# Pricing by transform: one fingerprint, sixty-four strikes, one pass.  Standard library only.
# Model: Merton's jump-diffusion for Acme.  Road 1 pairs the damped payoff's transform with the
# fingerprint (Parseval); road 2 is Merton's series of Black-Scholes prices; road 3 pairs the
# payoff with the density itself, by Simpson's rule.  Phi is a series written out.
from math import exp, log, sqrt, pi, factorial
from cmath import exp as cexp

S, r, q, T = 100.0, 0.05, 0.02, 1.0
SIG, LAM, MJ, DJ = 0.20, 0.5, -0.10, 0.15        # wiggle; jumps a year; jump log mean, log spread
AVGJ = exp(MJ + 0.5 * DJ * DJ) - 1.0               # the average jump, as a fraction of the price
STRIKES = [70.0 + i for i in range(64)]           # $70, $71, ..., $133
A, H, NF = 1.5, 1.0 / 64.0, 512                   # damping, frequency step, samples: cut-off 8

def mgf(z, lam=LAM, fix=True):                    # E[e^{zX}], X = ln(S_T/S); fingerprint is z = iu
    mu = r - q - 0.5 * SIG * SIG - (lam * AVGJ if fix else 0.0)
    jump = cexp(MJ * z + 0.5 * DJ * DJ * z * z) - 1.0
    return cexp(T * (mu * z + 0.5 * SIG * SIG * z * z + lam * jump))

calls = [0]
def products(a=A, h=H, n=NF, m=mgf):              # the one pass: payoff transform times fingerprint
    calls[0] += n
    return [S * exp(-r * T) * m(z) / ((z - 1.0) * z) for z in (a + 2j * pi * (j + 0.5) * h for j in range(n))]

def ladder(a=A, h=H, n=NF, strikes=STRIKES, m=mgf):
    psi = products(a, h, n, m)
    out = []
    for K in strikes:                             # each strike only turns the phase
        k = log(K / S)
        s = sum(p * cexp(-2j * pi * (j + 0.5) * h * k) for j, p in enumerate(psi))
        out.append(exp((1.0 - a) * k) * 2.0 * h * s.real)
    return out

def Phi(x):                                       # bell-curve area left of x, Taylor series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, s, n = x, x, 0
    while abs(term) > 1e-17 * abs(s):
        n += 1; term *= x * x / (2 * n + 1); s += term
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)

def bs(K, qq, sig):
    d1 = (log(S / K) + (r - qq + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-qq * T) * Phi(d1) - K * exp(-r * T) * Phi(d1 - sig * sqrt(T))

def merton(K):                                    # road 2: Poisson-weighted Black-Scholes
    tot = 0.0
    for n in range(41):
        w = exp(-LAM * T) * (LAM * T) ** n / factorial(n)
        tot += w * bs(K, q + LAM * AVGJ - n * log(1.0 + AVGJ) / T, sqrt(SIG ** 2 + n * DJ ** 2 / T))
    return tot

def density(x):                                   # Poisson mixture of bell curves for X
    mu, tot = r - q - 0.5 * SIG * SIG - LAM * AVGJ, 0.0
    for n in range(21):
        w = exp(-LAM * T) * (LAM * T) ** n / factorial(n)
        m, v = mu * T + n * MJ, SIG * SIG * T + n * DJ * DJ
        tot += w * exp(-(x - m) ** 2 / (2.0 * v)) / sqrt(2.0 * pi * v)
    return tot

def pairing(K, n=2000, top=3.0):                  # road 3: <payoff, density> by Simpson
    lo = log(K / S); h = (top - lo) / n
    f = lambda x: (S * exp(x) - K) * density(x)
    s = f(lo) + f(top) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return exp(-r * T) * s * h / 3.0

def implied(C, K):                                # Black-Scholes volatility by bisection
    lo, hi = 0.01, 1.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if bs(K, q, mid) < C else (lo, mid)
    return 0.5 * (lo + hi)

road1 = ladder(); one_pass = calls[0]
fine = ladder(h=H / 2, n=3 * NF)                  # second cut-off 12, half the step
road2 = [merton(K) for K in STRIKES]
road3 = [pairing(K) for K in STRIKES]
i100 = STRIKES.index(100.0)
MU = r - q - 0.5 * SIG * SIG - LAM * AVGJ
print(f"average jump m {AVGJ:.6f}   drift mu {MU:.6f}")
print(f"at a = 1.5: log E[e^(aX)] {log(mgf(A).real):.6f}   E[e^(aX)] {mgf(A).real:.6f}")
print(f"Psi(0) = S e^-rT E[e^(aX)] / ((a-1) a) {S * exp(-r * T) * mgf(A).real / ((A - 1.0) * A):.6f}")
print(f"fingerprint values: one pass {one_pass}; strike by strike {64 * NF}")
psi = products()
print("K = 100, sum cut off at Xi: " + "  ".join(f"{n * H:g}: {2 * H * sum(p.real for p in psi[:n]):.6f}" for n in (32, 64, 128, 256, 512)))
print("call prices, road 1 (transform), strikes across")
for row in range(8):
    print(f"K {70 + 8 * row:>3}-{77 + 8 * row:<3}" + "".join(f"{c:8.4f}" for c in road1[8 * row:8 * row + 8]))
g12 = max(abs(x - y) for x, y in zip(road1, road2))
g13 = max(abs(x - y) for x, y in zip(road1, road3))
gfine = max(abs(x - y) for x, y in zip(road1, fine))
print(f"K = 100: road 1 {road1[i100]:.6f}  road 2 {road2[i100]:.6f}  road 3 {road3[i100]:.6f}")
print(f"largest gap over 64 strikes: 1 vs 2 {g12:.9f}  1 vs 3 {g13:.9f}  cut-off 8 vs 12 {gfine:.9f}")
bs100 = bs(100.0, q, SIG)
ln100 = ladder(strikes=[100.0], m=lambda z: mgf(z, lam=0.0))[0]
print(f"no jumps, K = 100: transform {ln100:.6f}  Black-Scholes {bs100:.6f}  jump premium {road1[i100] - bs100:.6f}")
c_a3 = ladder(a=3.0, strikes=[100.0])[0]
fwd = S * exp(-q * T); put = road2[i100] - fwd + 100.0 * exp(-r * T)
print(f"damping a = 3.0: {c_a3:.6f}   (a = 1.5 gave {road1[i100]:.6f})")
c_a1 = ladder(a=1.0, strikes=[100.0])[0]
c_a05 = ladder(a=0.5, strikes=[100.0])[0]
c_am = ladder(a=-0.5, strikes=[100.0])[0]
print(f"wrong: a = 1.0, line through the pole {c_a1:.6f}   C - S e^-qT / 2 = {road2[i100] - fwd / 2:.6f}")
print(f"wrong: a = 0.5, line past the pole   {c_a05:.6f}   C - S e^-qT     = {road2[i100] - fwd:.6f}")
print(f"a = -0.5, past both poles            {c_am:.6f}   put P           = {put:.6f}")
c_ns = ladder(strikes=[100.0], m=lambda z: mgf(z - A))[0]
c_nf = ladder(strikes=[100.0], m=lambda z: mgf(z, fix=False))[0]
c_alias = ladder(h=1.0 / 16, n=128, strikes=[100.0])[0]
print(f"wrong: fingerprint not shifted to the damped line {c_ns:.6f}")
print(f"wrong: drift not corrected for the jumps          {c_nf:.6f}")
print(f"step 1/16 instead of 1/64 (copies 16 apart)       {c_alias:.6f}  gap {road1[i100] - c_alias:.6f}")
ivk = [70.0 + 9 * j for j in range(8)]
ivs = [implied(road1[STRIKES.index(K)], K) for K in ivk]
print("chart, strike    " + "".join(f"{K:7.0f}" for K in ivk))
print("chart, implied % " + "".join(f"{100 * v:7.2f}" for v in ivs))
fly = min(road1[i - 1] - 2 * road1[i] + road1[i + 1] for i in range(1, 63))
print(f"smallest butterfly C(K-1) - 2C(K) + C(K+1): {fly:.6f}")

assert g12 < 1e-8, "transform road must land on Merton's series"
assert g13 < 1e-7, "transform road must land on the payoff paired with the density"
assert abs(ln100 - bs100) < 1e-8, "no jumps: transform must give Black-Scholes"
assert abs(c_a3 - road1[i100]) < 1e-8, "the damping line slides without changing the price"
assert abs(c_a1 - (road2[i100] - fwd / 2)) < 1e-6, "on the pole at 1 the sum lands halfway"
assert abs(c_a05 - (road2[i100] - fwd)) < 1e-6, "crossing the pole at 1 subtracts S e^-qT"
assert abs(c_am - put) < 1e-6, "crossing both poles prices the put"
assert abs(road2[i100] - 10.42) < 0.005, "Merton card's $10.42"
assert fly > 0, "prices bend upward: no butterfly has a negative price"
print("ALL CHECKS PASS")
