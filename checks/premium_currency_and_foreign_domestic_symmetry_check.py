# One option, two currencies -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  The normal CDF is built from
# its own series, the integrals are Simpson's rule written out, nothing is imported
# that already knows the answer.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height at x

def N(x):   # bell-curve area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...), all terms one sign
    if abs(x) > 9.0: return 1.0 if x > 0 else 0.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total) and k < 500:
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def gk(S, K, rd, rf, vol, T, call):   # Garman-Kohlhagen: premium in domestic per 1 unit of foreign
    v = vol * sqrt(T)
    d1 = (log(S / K) + (rd - rf + 0.5 * vol * vol) * T) / v
    d2 = d1 - v
    if call: return S * exp(-rf * T) * N(d1) - K * exp(-rd * T) * N(d2)
    return K * exp(-rd * T) * N(-d2) - S * exp(-rf * T) * N(-d1)

def by_integral(S, K, rd, rf, vol, T, call, n=2000):
    # Average the payoff over the bell curve, discount at the domestic rate.  No d1, d2 or N.
    # The payoff switches on at z0; integrate only where it pays, so Simpson sees no kink.
    m, v = (rd - rf - 0.5 * vol * vol) * T, vol * sqrt(T)
    z0 = (log(K / S) - m) / v
    a, b = (z0, 12.0) if call else (-12.0, z0)
    h = (b - a) / n
    def f(z):
        ST = S * exp(m + v * z)
        return (ST - K if call else K - ST) * phi(z)
    total = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-rd * T) * total * h / 3.0

S, rd, rf, vol, T = 1.10, 0.05, 0.03, 0.10, 1.0          # EURUSD, USD rate, EUR rate
rows = []
def out(label, v): rows.append(f"{label:<34} {v:>14.8f}")
def money(label, v): rows.append(f"{label:<34} {v:>14.2f}")

def four_quotes(K, tag):
    C = gk(S, K, rd, rf, vol, T, True)                     # road 1: USD side, USD per EUR
    p_eur = gk(1 / S, 1 / K, rf, rd, vol, T, False)          # road 2: EUR side, EUR per USD
    out(f"{tag} 1 GK call, USD per EUR", C)
    out(f"{tag} 2 USD put from EUR side", p_eur)
    out(f"{tag} 3 S*K*(2), USD per EUR", S * K * p_eur)
    out(f"{tag} 4 integral, USD side", by_integral(S, K, rd, rf, vol, T, True))
    pe_int = by_integral(1 / S, 1 / K, rf, rd, vol, T, False)
    out(f"{tag} 5 integral, EUR side, *S*K", S * K * pe_int)
    for name, a, b in (("USD pips", C * 1e4, S * K * p_eur * 1e4), ("% EUR notional", C / S * 100, K * p_eur * 100),
                       ("% USD notional", C / K * 100, S * p_eur * 100), ("EUR pips", C / (S * K) * 1e4, p_eur * 1e4)):
        rows.append(f"{tag}   {name:<16} {a:>12.4f} {b:>12.4f}")
    assert abs(by_integral(S, K, rd, rf, vol, T, True) - C) < 1e-11, "integral road, USD side"
    assert abs(S * K * pe_int - C) < 1e-11, "integral road, EUR side, converted"
    assert abs(S * K * p_eur - C) < 1e-12, "symmetry: C(S,K,rd,rf) = S K P(1/S,1/K,rf,rd)"
    return C, p_eur

# the hand table at strike 1.20, both sides
v = vol * sqrt(T)
lnSK = log(S / 1.20)
d1 = (lnSK + (rd - rf + 0.5 * vol * vol) * T) / v
e1 = (log((1 / S) / (1 / 1.20)) + (rf - rd + 0.5 * vol * vol) * T) / v    # EUR side: 1/S, 1/K, rates swapped
for label, x in (("hand 1/S, EUR per USD", 1 / S), ("hand 1/K, EUR per USD", 1 / 1.20), ("hand ln(S/K)", lnSK), ("hand d1, USD side", d1), ("hand d2, USD side", d1 - v),
                 ("hand N(d1)", N(d1)), ("hand N(d2)", N(d1 - v)), ("hand e^-rfT", exp(-rf * T)),
                 ("hand e^-rdT", exp(-rd * T)), ("hand share half S e^-rfT N(d1)", S * exp(-rf * T) * N(d1)),
                 ("hand cash half K e^-rdT N(d2)", 1.20 * exp(-rd * T) * N(d1 - v)),
                 ("hand d1, EUR side", e1), ("hand d2, EUR side", e1 - v)):
    out(label, x)
C12, p12 = four_quotes(1.20, "K1.20")
C11, p11 = four_quotes(1.10, "K1.10")
assert abs(C11 - 0.053556) < 5e-7, "house call at strike 1.10"

# the mirror: EUR put / USD call, priced three ways
P11 = gk(S, 1.10, rd, rf, vol, T, False)
out("mirror EUR put, USD per EUR", P11)
P11_eur = S * 1.10 * gk(1 / S, 1 / 1.10, rf, rd, vol, T, True)
out("mirror S*K*USD call from EUR side", P11_eur)
out("mirror integral, USD side", by_integral(S, 1.10, rd, rf, vol, T, False))
assert abs(P11 - 0.032418) < 5e-7, "house put at strike 1.10"
assert abs(P11_eur - P11) < 1e-12, "mirror: a EUR put is a USD call"

# the payoff identity, path by path, at strike 1.20
agree = 0
for i in range(81):
    ST = 0.80 + 0.01 * i
    usd = max(ST - 1.20, 0.0)                              # EUR call, paid in USD per 1 EUR
    eur = 1.20 * max(1 / 1.20 - 1 / ST, 0.0)               # USD put on 1.20 USD, paid in EUR
    agree += abs(eur * ST - usd) < 1e-14
rows.append(f"{'payoffs agree, of 81 expiry rates':<34} {agree:>14d}")
assert agree == 81, "the two payoffs agree at every expiry rate"

out("S*K, USD pips per EUR pip", S * 1.20)
# a 10 million EUR ticket at strike 1.20
money("ticket USD notional", 1.20 * 1e7)
money("ticket premium, USD", C12 * 1e7)
money("ticket premium, EUR", C12 / S * 1e7)

# what breaks, strike 1.20
out("wrong: USD notional at spot, %", C12 / S * 100)
out("wrong: rates not swapped, USD", S * 1.20 * gk(1 / S, 1 / 1.20, rd, rf, vol, T, False))
out("wrong: %EUR read as %USD, USD", C12 / S * 1.20)
out("wrong: USD pips read as EUR pips", C12 * S * 1.20)

# try changing
C10 = gk(S, 1.00, rd, rf, vol, T, True)
out("try: K 1.00, % EUR notional", C10 / S * 100)
out("try: K 1.00, % USD notional", C10 / 1.00 * 100)
C20v = gk(S, 1.20, rd, rf, 0.20, T, True)
out("try: vol 20%, K 1.20, USD pips", C20v * 1e4)
out("try: vol 20%, K 1.20, EUR pips", C20v / (S * 1.20) * 1e4)
C1212 = gk(1.20, 1.20, rd, rf, vol, T, True)
out("try: S 1.20, K 1.20, % EUR", C1212 / 1.20 * 100)
out("try: S 1.20, K 1.20, % USD", C1212 / 1.20 * 100)

# chart: the two percentages across strikes
ks = [1.00 + 0.05 * i for i in range(6)]
rows.append("chart, strike      " + " ".join(f"{k:6.2f}" for k in ks))
rows.append("chart, % EUR       " + " ".join(f"{gk(S, k, rd, rf, vol, T, True) / S * 100:6.2f}" for k in ks))
rows.append("chart, % USD       " + " ".join(f"{gk(S, k, rd, rf, vol, T, True) / k * 100:6.2f}" for k in ks))
print("\n".join(rows))
print("ALL CHECKS PASS")
