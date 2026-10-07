# Asset-or-nothing digital -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area is a power series written
# out, the integrals are Simpson's rule, the random numbers are a xorshift generator.
from math import exp, log, sqrt, pi, cos

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x

def N(x):                                                    # area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if abs(x) > 9.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def d1d2(S, K, r, q, sig, T):
    vt = sig * sqrt(T)
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / vt
    return d1, d1 - vt

def aon(S, K, r, q, sig, T, put=False):                     # road 1: the formula
    d1, _ = d1d2(S, K, r, q, sig, T)
    return S * exp(-q * T) * N(-d1 if put else d1)

def con(S, K, r, q, sig, T, put=False):                     # cash digital, one dollar
    _, d2 = d1d2(S, K, r, q, sig, T)
    return exp(-r * T) * N(-d2 if put else d2)

def call(S, K, r, q, sig, T):
    d1, d2 = d1d2(S, K, r, q, sig, T)
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)

def simpson(f, a, b, n=20000):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
mu, vt = (r - q - 0.5 * sig * sig) * T, sig * sqrt(T)
ST = lambda z: S * exp(mu + vt * z)                          # Acme at expiry, z wiggle-units from the centre
zK = (log(K / S) - mu) / vt                                  # Acme finishes above K exactly when z > zK
d1, d2 = d1d2(S, K, r, q, sig, T)
A, Ap = aon(S, K, r, q, sig, T), aon(S, K, r, q, sig, T, True)
B, Bp = con(S, K, r, q, sig, T), con(S, K, r, q, sig, T, True)
# road 2: average the payoff over the bell curve, no d1 anywhere
A_int  = exp(-r * T) * simpson(lambda z: ST(z) * phi(z), zK, 10.0)
Ap_int = exp(-r * T) * simpson(lambda z: ST(z) * phi(z), -10.0, zK)
C_int  = exp(-r * T) * simpson(lambda z: (ST(z) - K) * phi(z), zK, 10.0)
P_int  = exp(-r * T) * simpson(lambda z: (K - ST(z)) * phi(z), -10.0, zK)
p_cash = simpson(phi, zK, 10.0)                              # plain chance of finishing above
F_int  = simpson(lambda z: ST(z) * phi(z), -10.0, 10.0)     # average share at expiry = the forward
p_shr  = simpson(lambda z: ST(z) * phi(z), zK, 10.0) / F_int  # chance weighted by the share's value
cond   = simpson(lambda z: ST(z) * phi(z), zK, 10.0) / p_cash  # average share, given it finishes above
# road 3: the call minus K times its slope in the strike (a tight call spread)
h = 0.01
A_slope = call(S, K, r, q, sig, T) - K * (call(S, K + h, r, q, sig, T) - call(S, K - h, r, q, sig, T)) / (2 * h)
# road 4: simulation, xorshift random numbers, Box-Muller bell-curve draws, antithetic pairs
state, M, tot, tot2 = 88172645463325252, 2 ** 64 - 1, 0.0, 0.0
def rnd():
    global state
    state ^= state >> 12; state ^= (state << 25) & M; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & M) >> 11) / 2.0 ** 53
n = 200000
for i in range(n):
    u1, u2 = 1.0 - rnd(), rnd()
    z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
    x = 0.5 * sum(ST(w) for w in (z, -z) if ST(w) > K) * exp(-r * T)
    tot += x; tot2 += x * x
A_mc = tot / n
se = sqrt((tot2 / n - A_mc * A_mc) / n)
# Greeks: formula, and by nudging the price
delta = exp(-q * T) * (N(d1) + phi(d1) / vt)
vega = -S * exp(-q * T) * phi(d1) * d2 / sig
delta_b = (aon(S + h, K, r, q, sig, T) - aon(S - h, K, r, q, sig, T)) / (2 * h)
vega_b = (aon(S, K, r, q, sig + 1e-4, T) - aon(S, K, r, q, sig - 1e-4, T)) / 2e-4

rows = [("d1", d1), ("d2", d2), ("e^-qT", exp(-q * T)), ("e^-rT", exp(-r * T)),
    ("N(d1)  chance counted in shares", N(d1)), ("N(d2)  chance counted in cash", N(d2)),
    ("1 asset call, formula", A), ("2 asset call, Simpson", A_int), ("3 asset call, C - K dC/dK", A_slope),
    ("4 asset call, simulation", A_mc), ("  simulation standard error", se),
    ("asset put, formula", Ap), ("asset put, Simpson", Ap_int), ("asset call + asset put", A + Ap),
    ("  S e^-qT, prepaid share", S * exp(-q * T)),
    ("cash call, one dollar", B), ("cash put, one dollar", Bp), ("cash call + cash put", B + Bp),
    ("call = asset - 100 x cash", A - K * B), ("call by Simpson", C_int),
    ("put = 100 x cash put - asset put", K * Bp - Ap), ("put by Simpson", P_int),
    ("plain chance above, Simpson", p_cash), ("share-weighted chance, Simpson", p_shr),
    ("forward F by Simpson", F_int), ("  S e^(r-q)T", S * exp((r - q) * T)),
    ("average share given above", cond), ("  N(d1) / N(d2)", N(d1) / N(d2)), ("  average above / F", cond / F_int),
    ("delta, formula", delta), ("delta, nudged", delta_b), ("  share part, e^-qT N(d1)", exp(-q * T) * N(d1)),
    ("asset put delta", exp(-q * T) - delta),
    ("vega per 1.00 of vol, formula", vega), ("vega, nudged", vega_b), ("  vega per vol point (0.01)", vega / 100),
    ("wrong: N(d2) in the asset digital", S * exp(-q * T) * N(d2)),
    ("wrong: no e^-qT", S * N(d1)), ("wrong: today's S x cash digital", S * B),
    ("wrong: e^-rT in place of e^-qT", S * exp(-r * T) * N(d1)), ("wrong: asset - cash, no K", A - B),
    ("try: sigma = 0.40", aon(S, K, r, q, 0.40, T)), ("try: sigma = 0.10", aon(S, K, r, q, 0.10, T)),
    ("try: K = 120", aon(S, 120.0, r, q, sig, T)), ("try: q = 0", aon(S, K, r, 0.0, sig, T))]
for name, v in rows: print(f"{name:<36} {v:>14.6f}")

print()
xs = [80.0 + 5.0 * i for i in range(11)]                     # payoff chart, Acme at expiry
print(f"{'chart, Acme at expiry':<24}" + "".join(f"{x:7.0f}" for x in xs))
print(f"{'chart, asset payoff':<24}" + "".join(f"{(x if x > K else 0.0):7.2f}" for x in xs))
print(f"{'chart, 100 cash payoff':<24}" + "".join(f"{(K if x > K else 0.0):7.2f}" for x in xs))
print(f"{'chart, call payoff':<24}" + "".join(f"{max(x - K, 0.0):7.2f}" for x in xs))
zb = lambda x: (log(x / S) - mu) / vt                        # price band edge -> wiggle units
edges = [60.0 + 10.0 * i for i in range(11)]
plain = [100 * simpson(phi, zb(a), zb(b), 2000) for a, b in zip(edges, edges[1:])]
share = [100 * simpson(lambda z: ST(z) * phi(z), zb(a), zb(b), 2000) / F_int for a, b in zip(edges, edges[1:])]
print(f"{'band centre ($)':<24}" + "".join(f"{a + 5:7.0f}" for a in edges[:-1]))
print(f"{'band, plain chance %':<24}" + "".join(f"{v:7.2f}" for v in plain))
print(f"{'band, share-weighted %':<24}" + "".join(f"{v:7.2f}" for v in share))

assert abs(A_int - A) < 1e-8,                  "Simpson road must land on the formula"
assert abs(A_slope - A) < 1e-5,                "call minus K times slope must land on the formula"
assert abs(A_mc - A) < 4 * se,                 "simulation within four standard errors"
assert abs((A - K * B) - 9.227005508154) < 1e-9, "asset minus 100 cash must be the house call"
assert abs((K * Bp - Ap) - 6.330080627550) < 1e-9, "100 cash puts minus asset put must be the house put"
assert abs((A_int + Ap_int) - S * exp(-q * T)) < 1e-8, "the two asset digitals by Simpson must make the prepaid share"
assert abs(p_shr - N(d1)) < 1e-9,              "share-weighted chance by Simpson vs N(d1)"
assert abs(p_cash - N(d2)) < 1e-9,             "plain chance by Simpson vs N(d2)"
assert abs(C_int - 9.227005508154) < 1e-8,     "call by Simpson must be the house call"
assert abs(cond / F_int - N(d1) / N(d2)) < 1e-8, "average above / F must equal N(d1) / N(d2)"
assert abs(delta_b - delta) < 1e-5,            "nudged delta vs formula"
assert abs(vega_b - vega) < 1e-4,              "nudged vega vs formula"
print("ALL CHECKS PASS")
