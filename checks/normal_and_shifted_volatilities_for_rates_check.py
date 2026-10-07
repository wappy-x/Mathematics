# Rate volatilities: one 1-into-5 payer swaption quoted lognormal, normal and shifted,
# converted at the money and away from it. Standard library only; N(x), the root
# finder and the integrator are written here.
from math import sqrt, exp, log, pi

def phi(x):                      # bell-curve height
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def N(x):                        # bell-curve area left of x: 1/2 + phi(x) * sum x^(2n+1)/(1*3*...*(2n+1))
    if x < 0.0:
        return 1.0 - N(-x)
    if x > 9.0:
        return 1.0
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def bisect(f, lo, hi):           # f rises from below zero to above zero on [lo, hi]
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(mid) < 0.0: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def simpson(g, a, b, n=4000):
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3.0

# Road 1: closed forms, payer premium in rate units (multiply by notional x annuity for dollars)
def black(F, K, s, T):
    w = s * sqrt(T); d1 = (log(F / K) + 0.5 * w * w) / w
    return F * N(d1) - K * N(d1 - w)
def bachelier(F, K, sn, T):
    v = sn * sqrt(T); d = (F - K) / v
    return (F - K) * N(d) + v * phi(d)
def shifted(F, K, s, T, a):
    return black(F + a, K + a, s, T)

# Road 2: the same premiums as averages of the payoff over each model's spread of outcomes
def black_int(F, K, s, T):
    w = s * sqrt(T); z0 = (log(K / F) + 0.5 * w * w) / w
    return simpson(lambda z: (F * exp(-0.5 * w * w + w * z) - K) * phi(z), z0, z0 + 16.0)
def bachelier_int(F, K, sn, T):
    v = sn * sqrt(T); z0 = (K - F) / v
    return simpson(lambda z: (F + v * z - K) * phi(z), z0, z0 + 16.0)

def implied_normal(F, K, p, T):    return bisect(lambda s: bachelier(F, K, s, T) - p, 1e-9, 0.5)
def implied_black(F, K, p, T):     return bisect(lambda s: black(F, K, s, T) - p, 1e-9, 20.0)
def implied_shifted(F, K, p, T, a): return bisect(lambda s: shifted(F, K, s, T, a) - p, 1e-9, 20.0)
def log_mean(x, y):
    return x if abs(x - y) < 1e-14 else (x - y) / log(x / y)

# The swaption: 1-year expiry into a 5-year swap, annual fixed payments, flat curve at 4.4% annual
T, sig, a, notional = 1.0, 0.30, 0.02, 10_000_000
D = [1.044 ** -t for t in range(7)]
A = sum(D[2:7])                                   # annuity: one unit of rate paid at years 2..6
F = (D[1] - D[6]) / A                             # forward swap rate, from the curve
bp = 1e4
def show(label, v, fmt="{:>14.6f}"): print(f"{label:<40}" + fmt.format(v))

show("annuity A, years", A)
show("forward swap rate F, bp", F * bp)
p = black(F, F, sig, T)
show("  N(w/2), w = sigma*sqrt(T) = 0.30", N(0.5 * sig * sqrt(T)))
show("  bracket 2N(w/2) - 1", 2 * N(0.5 * sig * sqrt(T)) - 1)
show("  sqrt(2 pi / T)", sqrt(2 * pi / T))
show("  shrink 1 - w^2/24", 1 - sig * sig * T / 24)
show("1 ATM premium, Black formula, bp", p * bp)
show("2 ATM premium, Black integral, bp", black_int(F, F, sig, T) * bp)
show("  premium, dollars", notional * A * p, "{:>14.2f}")
sn_root = implied_normal(F, F, p, T)
sn_exact = F * sqrt(2 * pi / T) * (2 * N(0.5 * sig * sqrt(T)) - 1)
show("3 normal vol, root finder, bp", sn_root * bp)
show("4 normal vol, exact ATM formula, bp", sn_exact * bp)
show("  rule F*sigma, bp", F * sig * bp)
show("  rule F*sigma*(1 - w^2/24), bp", F * sig * (1 - sig * sig * T / 24) * bp)
show("5 Bachelier integral at that vol, bp", bachelier_int(F, F, sn_root, T) * bp)
for sh in (0.01, 0.02, 0.03):
    show(f"  shifted vol, shift {sh * bp:.0f} bp, %", implied_shifted(F, F, p, T, sh) * 100)
    show(f"  rule sigma*F/(F+a), shift {sh * bp:.0f} bp, %", sig * F / (F + sh) * 100)
ss = implied_shifted(F, F, p, T, a)
show("  shifted bracket p/(F+a), 200 bp", p / (F + a))
show("  log mean of F and K = 540, bp", log_mean(F, 0.054) * bp)

print()
print("flat 30% lognormal, by strike (bp; vols: normal in bp, shifted 200 bp in %)")
print(f"{'K':>6}{'premium':>9}{'sN exact':>10}{'sN rule':>9}{'sS exact':>10}{'sS rule':>9}{'sB if sN flat':>15}")
sn_by_k, worst = [], 0.0
for i in range(9):
    K = 0.024 + 0.005 * i
    pk = black(F, K, sig, T)
    snk = implied_normal(F, K, pk, T)
    rule_n = sig * log_mean(F, K) * (1 - sig * sig * T / 24)
    ssk = implied_shifted(F, K, pk, T, a)
    rule_s = sig * log_mean(F, K) / log_mean(F + a, K + a)
    sbk = implied_black(F, K, bachelier(F, K, sn_root, T), T)
    worst = max(worst, abs(rule_n - snk))
    sn_by_k.append(snk)
    print(f"{K * bp:>6.0f}{pk * bp:>9.2f}{snk * bp:>10.2f}{rule_n * bp:>9.2f}{ssk * 100:>10.2f}{rule_s * 100:>9.2f}{sbk * 100:>15.2f}")
show("worst gap, log-mean rule vs exact, bp", worst * bp)

print()
K_lo = bisect(lambda k: F - bachelier(F, k, sn_root, T), 1e-9, F)
show("flat normal: no lognormal vol below K, bp", K_lo * bp)
r1 = notional * A * (bachelier(F, 0.024, F * sig, T) - (F - 0.024))     # receiver = payer - (F - K)
r0 = notional * A * (black(F, 0.024, sig, T) - (F - 0.024))
show("wrong: 132 bp receiver at K = 240, $", r1, "{:>14.2f}")
show("  right: 30% lognormal receiver, $", r0, "{:>14.2f}")
show("wrong: 2%-shift vol used with 1% shift, $", notional * A * shifted(F, F, ss, T, 0.01), "{:>14.2f}")
show("wrong: 1.3151% read as lognormal, $", notional * A * black(F, F, sn_root, T), "{:>14.2f}")
p10 = black(F, F, sig, 10.0)
show("wrong: F*sigma at 10 years, bp", F * sig * bp)
show("  right: exact at 10 years, bp", implied_normal(F, F, p10, 10.0) * bp)
show("try: F = 100 bp, 30% lognormal -> sN, bp", implied_normal(0.01, 0.01, black(0.01, 0.01, sig, T), T) * bp)
show("try: F = 340 bp, 30% lognormal -> sN, bp", implied_normal(0.034, 0.034, black(0.034, 0.034, sig, T), T) * bp)
show("try: sN held at 131.51, F = 340 -> sB, %", implied_black(0.034, 0.034, bachelier(0.034, 0.034, sn_root, T), T) * 100)

assert abs(F - 0.044) < 1e-15,                                  "the curve prices the forward at 4.4%"
assert abs(black_int(F, F, sig, T) - p) < 1e-12,                 "Black integral road meets the formula"
assert abs(sn_root - sn_exact) < 1e-12,                          "root finder meets the exact ATM conversion"
assert abs(bachelier_int(F, F, sn_root, T) - p) < 1e-12,         "normal model at the implied vol reprices by integral"
assert abs(black_int(F + a, F + a, ss, T) - p) < 1e-12,         "shifted model at the implied vol reprices by integral"
assert worst < 1e-6,                                             "log-mean rule within 0.01 bp, 240 to 640"
assert all(x < y for x, y in zip(sn_by_k, sn_by_k[1:])),          "flat lognormal means normal vol rising with strike"
print("ALL CHECKS PASS")
