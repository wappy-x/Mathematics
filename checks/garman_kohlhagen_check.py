# Garman-Kohlhagen -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the normal CDF is a series written out, the integral is Simpson's rule, the tree is a loop.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)        # bell-curve height at x

def N(x):                                                     # bell-curve area left of x
    if x > 9.0: return 1.0
    if x < -9.0: return 0.0
    term, total, n = x, x, 0                                  # sum of x^(2n+1) / (1*3*...*(2n+1))
    while abs(term) > 1e-17 * abs(total):
        n += 1
        term *= x * x / (2 * n + 1)
        total += term
    return 0.5 + phi(x) * total

def d1d2(S, K, rd, rf, vol, T):
    d1 = (log(S / K) + (rd - rf + 0.5 * vol * vol) * T) / (vol * sqrt(T))
    return d1, d1 - vol * sqrt(T)

def gk_call(S, K, rd, rf, vol, T):     # right to BUY 1 EUR for K USD; USD per EUR
    d1, d2 = d1d2(S, K, rd, rf, vol, T)
    return S * exp(-rf * T) * N(d1) - K * exp(-rd * T) * N(d2)

def gk_put(S, K, rd, rf, vol, T):      # right to SELL 1 EUR for K USD; USD per EUR
    d1, d2 = d1d2(S, K, rd, rf, vol, T)
    return K * exp(-rd * T) * N(-d2) - S * exp(-rf * T) * N(-d1)

def average(S, rd, rf, vol, T, f, n=20000):
    # Road 2: Simpson's rule over the bell curve, spot drifting at rd - rf.  No d1, no d2.
    a, b = -10.0, 10.0
    h = (b - a) / n
    def g(z): return f(S * exp((rd - rf - 0.5 * vol * vol) * T + vol * sqrt(T) * z)) * phi(z)
    tot = g(a) + g(b)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * g(a + i * h)
    return tot * h / 3.0

def tree(S, K, rd, rf, vol, T, steps=2000):
    # Road 4: coin-flip tree; each step the expected spot grows at rd - rf.
    dt = T / steps
    u = exp(vol * sqrt(dt)); d = 1.0 / u
    p = (exp((rd - rf) * dt) - d) / (u - d)
    disc = exp(-rd * dt)
    v = [max(S * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for m in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(m)]
    return v[0]

# ---- house example: EURUSD 1.1000, strike 1.1000, USD 5%, EUR 3%, vol 10%, one year ----
S, K, rd, rf, vol, T = 1.10, 1.10, 0.05, 0.03, 0.10, 1.0
d1, d2 = d1d2(S, K, rd, rf, vol, T)
C, P = gk_call(S, K, rd, rf, vol, T), gk_put(S, K, rd, rf, vol, T)
Dd, Df = exp(-rd * T), exp(-rf * T)
C_int = Dd * average(S, rd, rf, vol, T, lambda x: max(x - K, 0.0))
P_int = Dd * average(S, rd, rf, vol, T, lambda x: max(K - x, 0.0))
F = S * exp((rd - rf) * T)                                    # covered interest parity
dF1 = (log(F / K) + 0.5 * vol * vol * T) / (vol * sqrt(T))
C_b76 = Dd * (F * N(dF1) - K * N(dF1 - vol * sqrt(T)))          # Road 3: Black-76 on F
C_tree = tree(S, K, rd, rf, vol, T)
mean_ST = average(S, rd, rf, vol, T, lambda x: x)
deposit = Dd * average(S, rd, rf, vol, T, lambda x: x * exp(rf * T))
h = 1e-4
delta_bump = (gk_call(S + h, K, rd, rf, vol, T) - gk_call(S - h, K, rd, rf, vol, T)) / (2 * h)

rows = [("d1", d1), ("d2", d2), ("N(d1)", N(d1)), ("N(d2)", N(d2)),
        ("D_f = e^-rf T", Df), ("D_d = e^-rd T", Dd),
        ("euro leg  S D_f N(d1)", S * Df * N(d1)), ("dollar leg  K D_d N(d2)", K * Dd * N(d2)),
        ("1 formula, EUR call", C), ("2 Simpson average", C_int),
        ("3 Black-76 on the forward", C_b76), ("4 tree, 2000 steps", C_tree),
        ("  EUR put, formula", P), ("  EUR put, Simpson", P_int),
        ("5 C - P", C - P_int), ("  S D_f - K D_d", S * Df - K * Dd),
        ("forward F, parity", F), ("  average S_T, Simpson", mean_ST),
        ("euro deposit, today's USD", deposit), ("spot delta D_f N(d1)", Df * N(d1)),
        ("  delta by bump", delta_bump),
        ("USD pips per EUR", C * 1e4), ("percent of EUR notional", 100 * C / S),
        ("USD on EUR 10m", C * 1e7), ("breakeven spot K + C", K + C),
        ("wrong: rates swapped", gk_call(S, K, rf, rd, vol, T)),
        ("  swapped / right", gk_call(S, K, rf, rd, vol, T) / C),
        ("wrong: EUR rate left out", gk_call(S, K, rd, 0.0, vol, T)),
        ("wrong: Black-76 discounted at rf", Df * (F * N(dF1) - K * N(dF1 - vol * sqrt(T)))),
        ("cross: house shares as FX", gk_call(100.0, 100.0, 0.05, 0.02, 0.20, 1.0)),
        ("cross: 1.20, USD 4%, EUR 2%", gk_call(1.20, 1.20, 0.04, 0.02, 0.10, 1.0)),
        ("try: EUR rate 5%", gk_call(S, K, rd, 0.05, vol, T)),
        ("try: T = 0.25", gk_call(S, K, rd, rf, vol, 0.25)),
        ("try: vol 20%", gk_call(S, K, rd, rf, 0.20, T)),
        ("try: K = 1.20 call", gk_call(S, 1.20, rd, rf, vol, T)),
        ("try: K = 1.20 put", gk_put(S, 1.20, rd, rf, vol, T))]
for name, v in rows:
    print(f"{name:<32} {v:>15.6f}")

print()
spots = [1.00 + 0.02 * i for i in range(11)]
print(f"{'chart, spot at expiry':<24}" + " ".join(f"{x:8.2f}" for x in spots))
print(f"{'chart, profit in pips':<24}" + " ".join(f"{1e4 * (max(x - K, 0.0) - C):8.2f}" for x in spots))
rates = [0.01 * i for i in range(9)]
print(f"{'chart, EUR rate %':<24}" + " ".join(f"{100 * x:8.0f}" for x in rates))
print(f"{'chart, call in pips':<24}" + " ".join(f"{1e4 * gk_call(S, K, rd, x, vol, T):8.2f}" for x in rates))
print(f"{'chart, put in pips':<24}" + " ".join(f"{1e4 * gk_put(S, K, rd, x, vol, T):8.2f}" for x in rates))

assert abs(C - 0.053555770634) < 1e-11,                  "call vs the audited house value"
assert abs(P - 0.032418050681) < 1e-11,                  "put vs the audited house value"
assert abs(P_int - P) < 1e-10,                            "Simpson put must land on the put formula"
assert abs(delta_bump - Df * N(d1)) < 1e-7,               "bumped spot confirms the spot delta"
assert abs(gk_call(S, K, rf, rd, vol, T) - P) < 1e-12,    "at S = K, rates swapped gives the put"
assert abs(C_int - C) < 1e-10,                            "Simpson average must land on the formula"
assert abs(C_b76 - C) < 1e-12,                            "Black-76 on the parity forward"
assert abs(C_tree - C) < 1e-4,                            "tree within one pip"
assert abs((C - P_int) - (S * Df - K * Dd)) < 1e-10,      "parity with an independently averaged put"
assert abs(mean_ST - F) < 1e-10,                          "average future spot is the parity forward"
assert abs(deposit - S) < 1e-10,                          "a euro on deposit is a fairly priced asset"
assert abs(gk_call(100.0, 100.0, 0.05, 0.02, 0.20, 1.0) - 9.227005508154) < 1e-11, "house call"
assert abs(gk_call(1.20, 1.20, 0.04, 0.02, 0.10, 1.0) - 0.059011653) < 1e-9, "DS number"
print("ALL CHECKS PASS")
