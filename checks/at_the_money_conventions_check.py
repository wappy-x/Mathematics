# Three meanings of at-the-money on EURUSD: spot, forward, delta-neutral straddle.
# Road 1: closed forms. Road 2: prices by integrating the payoff, deltas by nudging spot,
# strikes by bisection on those nudged deltas. Road 3: the cheapest straddle by golden section.
import math

S, RD, RF, VOL, T = 1.10, 0.05, 0.03, 0.10, 1.0

def ncdf(x):  # normal CDF from its Taylor series, no library erf
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi) * total

def d1d2(s, k, vol=VOL, t=T):
    w = vol * math.sqrt(t)
    d1 = (math.log(s / k) + (RD - RF + 0.5 * vol * vol) * t) / w
    return d1, d1 - w

def gk(s, k, vol=VOL):  # road 1: Garman-Kohlhagen call and put, USD per EUR
    d1, d2 = d1d2(s, k, vol)
    c = s * math.exp(-RF * T) * ncdf(d1) - k * math.exp(-RD * T) * ncdf(d2)
    return c, c - s * math.exp(-RF * T) + k * math.exp(-RD * T)

def net_delta(k, vol=VOL):  # straddle spot delta, premium not adjusted
    return math.exp(-RF * T) * (2 * ncdf(d1d2(S, k, vol)[0]) - 1)

def net_pa(k, vol=VOL):  # straddle spot delta, premium-adjusted
    return k * math.exp(-RD * T) / S * (2 * ncdf(d1d2(S, k, vol)[1]) - 1)

def simpson(f, a, b, n=1200):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def integ(s, k):  # road 2: average the payoffs over the bell curve, split at the kink
    w, fwd = VOL * math.sqrt(T), s * math.exp((RD - RF) * T)
    st = lambda z: fwd * math.exp(w * z - 0.5 * w * w)
    phi = lambda z: math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi)
    zk = (math.log(k / fwd) + 0.5 * w * w) / w
    put = simpson(lambda z: (k - st(z)) * phi(z), -12.0, zk)
    call = simpson(lambda z: (st(z) - k) * phi(z), zk, 12.0)
    return math.exp(-RD * T) * call, math.exp(-RD * T) * put

def bump(k, adjusted, h=1e-4):  # straddle delta by nudging spot, strike held fixed
    v = lambda s: sum(integ(s, k)) / (s if adjusted else 1.0)
    return (S if adjusted else 1.0) * (v(S + h) - v(S - h)) / (2 * h)

def bisect(f, lo, hi):
    for _ in range(40):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

def golden(f, lo, hi):
    g = (math.sqrt(5) - 1) / 2
    for _ in range(50):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        lo, hi = (lo, b) if f(a) < f(b) else (a, hi)
    return 0.5 * (lo + hi)

def row(label, *vals, p=6):  # a value that rounds to zero prints as 0, never -0
    print(f"{label:<34}" + "".join(f"{(v if abs(v) >= 0.5 * 10**-p else 0.0):>11.{p}f}" for v in vals))

F = S * math.exp((RD - RF) * T)
k_dns = F * math.exp(0.5 * VOL * VOL * T)
k_pa = F * math.exp(-0.5 * VOL * VOL * T)
k_dns2 = bisect(lambda k: bump(k, False), 1.05, 1.20)
k_pa2 = bisect(lambda k: bump(k, True), 1.05, 1.20)
k_min = golden(lambda k: sum(integ(S, k)), 1.05, 1.20)
row("forward F = S e^(rd-rf)T", F)
row("strike: spot ATM, K = S", S)
row("strike: forward ATM, K = F", F)
row("strike: DNS, formula | bisection", k_dns, k_dns2)
row("strike: DNS p.a., formula | bisect", k_pa, k_pa2)
row("strike: cheapest straddle, golden", k_min)
row("e^.02, e^.005, e^-.005, e^-.03", F / S, k_dns / F, k_pa / F, math.exp(-RF * T))
row("gaps in pips: DNS-S DNS-F F-p.a.", 1e4 * (k_dns - S), 1e4 * (k_dns - F), 1e4 * (F - k_pa), p=1)
names = [("spot ATM", S), ("forward ATM", F), ("DNS", k_dns), ("DNS p.a.", k_pa)]
print("at each strike                     d1         call       put        straddle   by integral")
for nm, k in names:
    c, p = gk(S, k)
    row(f"  {nm}", d1d2(S, k)[0], c, p, c + p, sum(integ(S, k)))
print("net straddle delta                 formula    by nudge   p.a. form  p.a. nudge")
for nm, k in names:
    row(f"  {nm}", net_delta(k), bump(k, False), net_pa(k), bump(k, True))
row("DNS call, put spot delta", math.exp(-RF * T) * ncdf(0.0), -math.exp(-RF * T) * ncdf(0.0), p=4)
half = k_pa * math.exp(-RD * T) / S * ncdf(0.0)
row("p.a. call, put delta at DNS p.a.", half, -half, p=4)
row("  same by e^-rfT N(d1) - C/S", math.exp(-RF * T) * ncdf(d1d2(S, k_pa)[0]) - gk(S, k_pa)[0] / S, p=4)
k_wrong = S * math.exp(0.5 * VOL * VOL * T)
row("wrong: S in place of F, strike", k_wrong)
row("  its net delta", net_delta(k_wrong), p=4)
row("wrong: p.a. strike, USD premium", net_delta(k_pa), p=4)
k_nosq = F * math.exp(0.5 * VOL * T)
row("wrong: vol not squared, strike", k_nosq)
row("  its net delta", net_delta(k_nosq), p=4)
for v in (0.05, 0.20):
    row(f"try: vol {v:.2f}, DNS | DNS p.a.", F * math.exp(0.5 * v * v * T), F * math.exp(-0.5 * v * v * T))
f5 = S * math.exp((RD - RF) * 5.0)
row("try: 5 years, F | DNS | DNS p.a.", f5, f5 * math.exp(0.5 * VOL * VOL * 5.0), f5 * math.exp(-0.5 * VOL * VOL * 5.0))
row("try: rd = rf = 3%, F | DNS", S, S * math.exp(0.5 * VOL * VOL * T))
smile = lambda k: 0.10 - 0.20 * math.log(k / F) + 1.0 * math.log(k / F) ** 2
k_s = F
for _ in range(60):
    k_s = F * math.exp(0.5 * smile(k_s) ** 2 * T)
row("smile: ATM strike by iteration", k_s)
row("  vol there | vol at F", smile(k_s), smile(F))
row("  formula at that quoted vol", F * math.exp(0.5 * smile(k_s) ** 2 * T))
row("  formula at vol read at F", F * math.exp(0.5 * smile(F) ** 2 * T))
grid = [1.08 + 0.01 * i for i in range(10)]
print("chart, strike    " + "".join(f"{k:>8.2f}" for k in grid))
print("chart, net delta " + "".join(f"{net_delta(k):>8.2f}" for k in grid))
print("chart, p.a. net  " + "".join(f"{net_pa(k):>8.2f}" for k in grid))
print("chart, straddle  " + "".join(f"{sum(gk(S, k)):>8.4f}" for k in grid))
assert abs(k_dns - k_dns2) < 1e-6 and abs(k_pa - k_pa2) < 1e-6, (k_dns2, k_pa2)
assert abs(k_min - k_pa) < 1e-6, k_min
assert abs(sum(gk(S, k_dns)) - sum(integ(S, k_dns))) < 1e-9
assert abs(gk(S, F)[0] - integ(S, F)[1]) < 1e-9
assert abs(bump(k_dns, False)) < 1e-6 and abs(net_delta(S) - bump(S, False)) < 1e-6
assert abs(net_pa(k_pa2)) < 1e-6 and abs(net_pa(S) - bump(S, True)) < 1e-6
print("ALL CHECKS PASS")
