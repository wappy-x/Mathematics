from math import exp, log, sqrt, pi, cos
S, r, q, sig, T = 100.0, 0.05, 0.02, 0.20, 1.0            # the house market
F, G = S * exp((r - q) * T), exp(r * T)                    # forward; growth from today to expiry
M64 = (1 << 64) - 1
def N(x):                        # normal CDF from the erf series that converges everywhere
    z = abs(x) / sqrt(2.0)
    term, total, n = z, z, 0
    while z <= 9.0 and term > 1e-17 * total:
        n += 1
        term *= 2.0 * z * z / (2 * n + 1)
        total += term
    e = 1.0 if z > 9.0 else 2.0 / sqrt(pi) * exp(-z * z) * total
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)
def bs(K, v=sig):                # Black-Scholes call and put on Acme with the house r, q, T
    sd = v * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * v * v) * T) / sd
    return (S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sd),
            K * exp(-r * T) * N(sd - d1) - S * exp(-q * T) * N(-d1))
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def strip(lo, hi, calls_only=False):   # road 1: 2e^{rT}/T times the 1/K^2 strip on strikes lo..hi only
    def g(k):                          # in log-strike k = ln K:  Q(K)/K^2 dK = Q(K)/K dk
        c, p = bs(exp(k))
        return (c if calls_only or k >= log(F) else p) / exp(k)
    cuts = [log(lo), log(F), log(hi)] if lo < F < hi and not calls_only else [log(lo), log(hi)]
    return 2.0 * G / T * sum(simpson(g, x, y) for x, y in zip(cuts, cuts[1:]))
def occupancy(lo, hi, on_share=False):   # road 2: sigma^2 times the year's average chance of being inside
    def p(u):                            # time t = u^2, which keeps Simpson smooth near t = 0
        t = u * u
        sd, mu = sig * sqrt(t), log(F) - 0.5 * sig * sig * t
        sh = (r - q) * (T - t) if on_share else 0.0     # share inside [lo, hi] = forward inside, grown
        return 2.0 * u * (N((log(hi) + sh - mu) / sd) - N((log(lo) + sh - mu) / sd))
    return sig * sig * simpson(p, 1e-9, sqrt(T), 400) / T
def black_var(m, C, w):          # call on realised variance: lognormal, mean m, volatility of variance w
    d1 = (log(m / C) + 0.5 * w * w) / w
    return m * N(d1) - C * N(d1 - w)
def simpson_var(m, C, w):        # the same call, integrating the payoff against the bell curve
    f = lambda z: (m * exp(w * z - 0.5 * w * w) - C) * exp(-0.5 * z * z) / sqrt(2 * pi)
    return simpson(f, (log(C / m) + 0.5 * w * w) / w, 12.0, 4000)
st = [0x2545F4914F6CDD1D]
def u01():                       # splitmix64, a written-out generator of uniform numbers
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & M64
    z = ((st[0] ^ (st[0] >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
gauss = lambda: sqrt(-2.0 * log(u01())) * cos(2.0 * pi * u01())   # Box-Muller: two uniforms, one bell draw
def mean_se(a):
    m = sum(a) / len(a)
    return m, sqrt(sum((x - m) ** 2 for x in a) / (len(a) - 1) / len(a))
clamp = lambda x, lo, hi: min(max(x, lo), hi)
def gfun(x, lo, hi):             # corridor log contract: curvature 2/x^2 inside, none outside, flat at F
    J = lambda y: (y - lo) / lo if y < lo else (log(y / lo) if y <= hi else log(hi / lo) + (y - hi) / hi)
    return 2.0 * ((x - F) / clamp(F, lo, hi) - (J(x) - J(F)))
def gslope(x, lo, hi):
    return 2.0 * (1.0 / clamp(F, lo, hi) - 1.0 / clamp(x, lo, hi))
BOOKS = [(80.0, 120.0), (1e-9, F)]     # the corridor; down variance, below today's forward
def simulate(paths, days=252):   # road 3: daily paths at 20%, corridor variance and its hedge
    dt, out = T / days, [[] for _ in range(6)]
    for _ in range(paths):
        f, cv, pl, cs, rv = F, [0.0, 0.0], [0.0, 0.0], 0.0, 0.0
        for i in range(days):
            y = -0.5 * sig * sig * dt + sig * sqrt(dt) * gauss()   # the forward's daily log move
            x2 = (y + (r - q) * dt) ** 2 / T                        # the share's, squared, per year
            rv += x2
            for j, (lo, hi) in enumerate(BOOKS):
                cv[j] += x2 if lo <= f <= hi else 0.0               # counted if yesterday was inside
                pl[j] -= gslope(f, lo, hi) * (f * exp(y) - f)       # the daily forward hedge
            cs += x2 if 80.0 <= f * exp(-(r - q) * (T - i * dt)) <= 120.0 else 0.0
            f *= exp(y)
        for j, (lo, hi) in enumerate(BOOKS):
            out[2 * j].append(cv[j])
            out[2 * j + 1].append((gfun(f, lo, hi) + pl[j]) / T)
        out[4].append(cs - cv[0])
        out[5].append(rv)
    return out
def simulate_cap(paths, m, w, C, days=252):   # road 3 for the cap: each year draws its own variance
    dt, rvs = T / days, []
    for _ in range(paths):
        v = sqrt(m * exp(w * gauss() - 0.5 * w * w))
        rvs.append(sum((-0.5 * v * v * dt + v * sqrt(dt) * gauss() + (r - q) * dt) ** 2 for _ in range(days)) / T)
    return mean_se([min(x, C) for x in rvs]) + mean_se([max(x - C, 0.0) for x in rvs])
plain, L, U, W, CAP = strip(F * exp(-4.0), F * exp(4.0)), 80.0, 120.0, 0.8, 2.5 ** 2 * 0.04
corr, corr_occ, down, down_occ = strip(L, U), occupancy(L, U), strip(F * exp(-4.0), F), occupancy(1e-9, F)
up, shift = strip(F, F * exp(4.0)), occupancy(L, U, True) - occupancy(L, U)
sim = simulate(4000)
(c_m, c_se), (d_m, d_se), (sh_m, sh_se) = mean_se(sim[0]), mean_se(sim[2]), mean_se(sim[4])
gaps = [max(abs(a - b) for a, b in zip(sim[k], sim[k + 1])) for k in (0, 2)]
above = sum(1 for x in sim[5] if x > CAP)
c20, c20s, c60, c60s = black_var(0.04, CAP, W), simpson_var(0.04, CAP, W), black_var(0.36, CAP, W), simpson_var(0.36, CAP, W)
kc = 0.04
for _ in range(60):              # term sheet: the cap is 2.5^2 times the capped swap's own strike
    kc = 0.04 - black_var(0.04, 6.25 * kc, W)
s20, s20e, t20, t20e = simulate_cap(4000, 0.04, W, CAP)
s60, s60e, t60, t60e = simulate_cap(4000, 0.36, W, CAP)
hand = [10.0 / K ** 2 * (bs(K)[1] if K < F else bs(K)[0]) for K in (85.0, 95.0, 105.0, 115.0)]
def out(name, *vals):
    print(f"{name:<52}" + "".join(f"{v:>11.6f}" for v in vals))
out("forward F", F)
out("plain strip, fair variance", plain)
out("corridor 80-120: strip, occupation, sim, se", corr, corr_occ, c_m, c_se)
out("  worst path gap; as a vol, percent; share of plain", gaps[0], 100 * sqrt(corr), corr / plain)
out("down variance: strip, occupation, sim, se", down, down_occ, d_m, d_se)
out("  worst path gap; up variance; down + up", gaps[1], up, down + up)
out("cap; constant 20%: years above it", CAP, above)
out("at 20: call on variance, Simpson, sim, se", c20, c20s, t20, t20e)
out("  capped strike, sim, se; as a vol", 0.04 - c20, s20, s20e, 100 * sqrt(0.04 - c20))
d1 = (log(0.04 / CAP) + 0.5 * W * W) / W
out("  d1, d2, N(d1), N(d2)", d1, d1 - W, N(d1), N(d1 - W))
out("  cap set off the capped strike itself", kc)
out("at 60: call on variance, Simpson, sim, se", c60, c60s, t60, t60e)
out("  capped strike, sim, se", 0.36 - c60, s60, s60e)
out("by hand: P85, P95, C105, C115", *[(bs(K)[1] if K < F else bs(K)[0]) for K in (85.0, 95.0, 105.0, 115.0)])
out("  each times 10/K^2", *hand)
out("  sum; 2 e^rT / T; product", sum(hand), 2.0 * G / T, 2.0 * G / T * sum(hand))
out("wrong: calls across the corridor", strip(L, U, True))
out("share-price corridor less forward: formula, sim, se", shift, sh_m, sh_se)
out("try: corridor 90-110; w = 1.2 capped strike", strip(90.0, 110.0), 0.04 - black_var(0.04, CAP, 1.2))
print(f"{"strike band x1000":<18}" + "".join(f"{a:>4.0f}-{a + 10:<3.0f}" for a in range(50, 160, 10)))
print(f"{"  contribution":<18}" + "".join(f"{1000 * strip(a, a + 10.0):>8.2f}" for a in range(50, 160, 10)))
print(f"{"market vol, pct":<18}" + "".join(f"{v:>8.0f}" for v in (20, 30, 40, 50, 60)))
print(f"{"  plain strike":<18}" + "".join(f"{v * v / 1e4:>8.4f}" for v in (20, 30, 40, 50, 60)))
print(f"{"  capped strike":<18}" + "".join(f"{v * v / 1e4 - black_var(v * v / 1e4, CAP, W):>8.4f}" for v in (20, 30, 40, 50, 60)))
print(f"{"realised vol":<18}" + "".join(f"{v:>8.0f}" for v in (10, 20, 30, 40, 50, 60, 70)))
print(f"{"  plain, $000":<18}" + "".join(f"{2.5 * (v * v - 400):>8.1f}" for v in (10, 20, 30, 40, 50, 60, 70)))
print(f"{"  capped, $000":<18}" + "".join(f"{2.5 * (min(v * v, 2500) - 1e4 * (0.04 - c20)):>8.2f}" for v in (10, 20, 30, 40, 50, 60, 70)))
assert abs(plain - sig * sig) < 1e-9, "the full strip returns the flat surface's variance"
assert abs(corr - corr_occ) < 1e-6 and abs(down - down_occ) < 1e-6, "restricted strip = variance x time inside"
assert abs(c_m - corr) < 4 * c_se and abs(d_m - down) < 4 * d_se, "simulated corridor variance averages to the strip"
assert gaps[0] < 0.006 and gaps[1] < 0.006, "the corridor hedge tracks corridor variance path by path"
assert abs(sh_m - shift) < 4 * sh_se + 1e-5, "the share-price corridor shift matches its formula"
assert abs(c20 - c20s) < 1e-8 and abs(c60 - c60s) < 1e-8, "Black on variance = direct integral"
assert abs(t20 - c20) < 4 * t20e + 2e-5 and abs(t60 - c60) < 4 * t60e + 2e-3, "simulated cap value agrees"
assert abs(s60 - (0.36 - c60)) < 4 * s60e + 2e-3, "capped strike = plain minus the call"
assert above == 0, "with no volatility of variance the cap never binds"
print("ALL CHECKS PASS")
