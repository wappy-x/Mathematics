# Implied forward and dividend from parity -- the check behind the card.  Standard library
# only.  Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the bell-curve area is added up slice by slice (Simpson), the root finder is a bisection
# written here, and the random quote errors come from a hand-written generator.
from math import log, sqrt, exp, pi

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
STRIKES = [80.0 + 5.0 * i for i in range(9)]

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)           # bell-curve height at x
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def N(x):                                                        # bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 4000)
def call(s, k, t):                                               # the call card's formula
    vt = sigma * sqrt(t); d1 = (log(s / k) + (r - q + 0.5 * sigma * sigma) * t) / vt
    return s * exp(-q * t) * N(d1) - k * exp(-r * t) * N(d1 - vt)
def put(s, k, t):                                                # the put card's formula
    vt = sigma * sqrt(t); d1 = (log(s / k) + (r - q + 0.5 * sigma * sigma) * t) / vt
    return k * exp(-r * t) * N(vt - d1) - s * exp(-q * t) * N(-d1)
def by_integral(k, sign):    # road 4's prices: payoff averaged over the bell curve, no formula
    def f(z):
        st = S * exp((r - q - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)
        return max(sign * (st - k), 0.0) * phi(z)
    return exp(-r * T) * simpson(f, -10.0, 10.0, 20000)

def fwd(c, p, k, rr, t): return k + (c - p) * exp(rr * t)       # road 1: parity turned round
def yld(f, rr, t): return rr - log(f / S) / t                   # the yield a forward implies
def bisect_q(gap, rr, t):    # road 2: hunt q in S e^-qT - K e^-rT = C - P; no logarithm used
    lo, hi = -1.0, 1.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if S * exp(-mid * t) - K * exp(-rr * t) > gap: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def line_fit(ks, gaps):      # road 4: least-squares line gap = a - D K, then F = a / D
    n = len(ks); mk = sum(ks) / n; mg = sum(gaps) / n
    slope = sum((x - mk) * (y - mg) for x, y in zip(ks, gaps)) / sum((x - mk) ** 2 for x in ks)
    return -slope, (mg - slope * mk) / (-slope)
state = 20260919
def noise():                 # a 64-bit linear congruential generator: a quote error in +-0.05
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % (1 << 64)
    return ((state >> 11) / float(1 << 53) - 0.5) * 0.10
def row(name, v): print(f"{name:<40}{v:>14.6f}")
def pct(name, v): print(f"{name:<40}{v * 100:>13.4f}%")

C, P = call(S, K, T), put(S, K, T)
F1 = fwd(C, P, K, r, T); q1 = yld(F1, r, T); q2 = bisect_q(C - P, r, T)
g90, g110 = call(S, 90.0, T) - put(S, 90.0, T), call(S, 110.0, T) - put(S, 110.0, T)
D3 = (g90 - g110) / (110.0 - 90.0); r3 = -log(D3) / T; F3 = 90.0 + g90 / D3; q3 = yld(F3, r3, T)
gaps4 = [by_integral(k, 1.0) - by_integral(k, -1.0) for k in STRIKES]
D4, F4 = line_fit(STRIKES, gaps4); r4 = -log(D4) / T; q4 = yld(F4, r4, T)
carry = S * exp((r - q) * T)

print(f"house market: S {S:.2f}  K {K:.2f}  r {r * 100:.2f}%  q {q * 100:.2f}%  T {T:.2f} years")
print("road 1: one strike, rate given")
for name, v in (("call C", C), ("put P", P), ("C - P", C - P), ("e^rT", exp(r * T)),
                ("(C - P) e^rT", (C - P) * exp(r * T)), ("forward F = K + (C - P) e^rT", F1),
                ("F / S", F1 / S), ("share grown at the rate, S e^rT", S * exp(r * T))): row(name, v)
pct("carry r - q = ln(F/S) / T", log(F1 / S) / T); pct("yield q = r - ln(F/S) / T", q1)
pct("road 2: q by bisection on parity", q2)
print("road 3: the box, strikes 90 and 110, no rate given")
for name, v in (("C - P at 90", g90), ("C - P at 110", g110), ("discount factor D", D3),
                ("forward F", F3)): row(name, v)
pct("rate r = -ln D / T", r3); pct("yield q", q3)
print("road 4: nine strikes priced by integral, straight-line fit")
row("discount factor D", D4); row("forward F", F4); pct("rate r", r4); pct("yield q", q4)
row("check: cash and carry S e^(r-q)T", carry)
print("chart, strike    " + "".join(f"{k:>7.0f}" for k in STRIKES))
print("chart, C - P     " + "".join(f"{call(S, k, T) - put(S, k, T):>7.2f}" for k in STRIKES))

print("what breaks")
Fh = fwd(C, P + 0.10, K, r, T); qh = yld(Fh, r, T)
Fs = fwd(call(99.0, K, T), P, K, r, T); qs = yld(Fs, r, T)
row("put 0.10 too high: F", Fh); pct("put 0.10 too high: q", qh)
pct("  straight-line guess 0.10 e^rT / (F T)", 0.10 * exp(r * T) / (F1 * T))
pct("no carry forward, F = K + C - P: q", yld(K + C - P, r, T))
pct("sign swapped, r + ln(F/S) / T", r + log(F1 / S) / T)
row("stale call, priced at Acme 99", call(99.0, K, T)); row("stale call: F", Fs); pct("stale call: q", qs)
Cw, Pw = call(S, K, 1.0 / 52.0), put(S, K, 1.0 / 52.0)
pct("one week, put 0.10 too high: q", yld(fwd(Cw, Pw + 0.10, K, r, 1.0 / 52.0), r, 1.0 / 52.0))
print("bid and ask: call 9.18 / 9.28, put 6.28 / 6.38; crossed put 6.45 / 6.25")
flo, fhi = fwd(9.18, 6.38, K, r, T), fwd(9.28, 6.28, K, r, T)
fxlo, fxhi = fwd(9.18, 6.25, K, r, T), fwd(9.28, 6.45, K, r, T)
print(f"F band {flo:.6f} to {fhi:.6f}, q band {yld(fhi, r, T) * 100:.4f}% to {yld(flo, r, T) * 100:.4f}%")
print(f"crossed: F low {fxlo:.6f} above F high {fxhi:.6f}")

print("nine strikes, each leg off by up to 0.05 at random")
gaps_n = [call(S, k, T) + noise() - put(S, k, T) - noise() for k in STRIKES]
qs_n = [yld(k + g * exp(r * T), r, T) for k, g in zip(STRIKES, gaps_n)]
Dn, Fn = line_fit(STRIKES, gaps_n); rn = -log(Dn) / T; qn = yld(Fn, rn, T)
print("chart, q by strike %" + "".join(f"{v * 100:>6.2f}" for v in qs_n))
worst, q_avg = max(abs(v - q) for v in qs_n), sum(qs_n) / len(qs_n)
pct("worst single-strike error in q", worst); pct("average of the nine, rate given", q_avg)
row("fit, rate not given: forward F", Fn); pct("fit: rate r", rn); pct("fit: yield q", qn)
pct("fit: carry r - q", rn - qn)
Db = (gaps_n[3] - gaps_n[5]) / 10.0
print(f"box on 95 and 105 only: r {-log(Db) / T * 100:.4f}%")
print(f"try: K = 120 alone gives F {fwd(call(S, 120.0, T), put(S, 120.0, T), 120.0, r, T):.6f}")

assert abs(C - 9.227005508154) < 1e-9,               "the call against the shelf's house number"
assert abs(P - 6.330080627550) < 1e-9,               "the put against the shelf's house number"
assert abs(F1 - carry) < 1e-9,                       "one-strike forward against cash and carry"
assert abs(q1 - q) < 1e-9,                           "the yield comes back out of the two prices"
assert abs(q2 - q1) < 1e-12,                         "bisection against the logarithm formula"
assert abs(r3 - r) < 1e-9,                           "the box recovers the rate with no rate given"
assert abs(q3 - q) < 1e-9,                           "and the yield from its own rate"
assert abs(q4 - q) < 1e-6,                           "integral prices and a line fit: same yield"
assert abs((qh - q1) - 0.10 * exp(r * T) / (F1 * T)) < 2e-5, "a put error moves q by e^rT / (F T) a dollar"
assert qs > q + 0.005,                               "a stale call drags the implied yield up"
assert flo < F1 < fhi,                               "the live bid-ask band brackets the true forward"
assert fxhi < F1 < fxlo,                             "a crossed quote turns the band inside out"
assert abs(q_avg - q) < worst / 3,                   "averaging nine strikes cuts the worst error threefold"
assert abs(Fn - F1) < 0.05,                          "the fitted forward survives the noise"
assert abs(-log(Db) / T - r) > 5 * abs(rn - r),     "close strikes magnify the noise in the rate"
print("ALL CHECKS PASS")
