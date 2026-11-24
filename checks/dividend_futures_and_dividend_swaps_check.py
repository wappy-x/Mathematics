# Dividend futures and swaps -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the bell-curve area comes from math.erf, the brute-force prices are Simpson's rule
# written out, and the dividend list that built the quotes is checked, never reused.
from math import erf, exp, log, sqrt, pi

S, r, sig, K = 100.0, 0.05, 0.20, 100.0
DIVS = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.20)]       # (paid at, dollars): hidden truth
EXP = [1.0, 2.0, 3.0]                                   # option expiries, years

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def pv_divs(T, divs): return sum(d * exp(-r * t) for t, d in divs if t < T)
def d1(T, K, divs): return (log((S - pv_divs(T, divs)) / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T))
def bs(T, K, divs, b=0.0):                              # escrowed spot; fee b a year on the share's value
    Ss = S * exp(-b * T) - sum(d * exp(-r * t - b * (T - t)) for t, d in divs if t < T)
    a = (log(Ss / K) + (r + 0.5 * sig * sig) * T) / (sig * sqrt(T)); c = a - sig * sqrt(T)
    return Ss * N(a) - K * exp(-r * T) * N(c), K * exp(-r * T) * N(-c) - Ss * N(-a)
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def simpson_pair(T, K, divs):                           # road 2: both legs by brute force
    Ss, v = S - pv_divs(T, divs), sig * sqrt(T)         # no d1, no N: average the payoff
    ST = lambda z: Ss * exp((r - 0.5 * sig * sig) * T + v * z)
    phi = lambda z: exp(-0.5 * z * z) / sqrt(2 * pi)
    zk = (log(K / Ss) - (r - 0.5 * sig * sig) * T) / v  # where the payoff kinks
    c = simpson(lambda z: (ST(z) - K) * phi(z), zk, 9.0)
    p = simpson(lambda z: (K - ST(z)) * phi(z), -9.0, zk)
    return exp(-r * T) * c, exp(-r * T) * p

def strip(quotes, K):                                   # road 1: parity solved for the dividends
    return [S - K * exp(-r * T) - (C - P) for T, (C, P) in zip(EXP, quotes)]
def futures(Dcum, tpay):                                # difference, then carry to the pay date
    prev = [0.0] + Dcum[:-1]
    return [(a - b) * exp(r * t) for a, b, t in zip(Dcum, prev, tpay)]

quotes = [bs(T, K, DIVS) for T in EXP]
D1 = strip(quotes, K)
tpay = [t for t, _ in DIVS]
FUT = futures(D1, tpay)
for T, (C, P), D in zip(EXP, quotes, D1):
    print(f"expiry {T:.0f}y: call {C:.6f}  put {P:.6f}  C-P {C - P:.6f}  K e^-rT {K * exp(-r * T):.6f}  PV of dividends {D:.6f}")
for i, (a, f) in enumerate(zip([D1[0], D1[1] - D1[0], D1[2] - D1[1]], FUT)):
    print(f"year {i+1}: PV {a:.6f}  carry e^(r*{tpay[i]}) {exp(r*tpay[i]):.6f}  dividend future {f:.6f}")
    assert abs(f - DIVS[i][1]) < 1e-5                   # recovers the hidden dividend list
SWAP = sum(FUT)
print(f"3-year dividend swap fair strike {SWAP:.6f}")

# road 2: brute-force prices at a different strike, same parity inversion
D2 = strip([simpson_pair(T, 90.0, DIVS) for T in EXP], 90.0)
print("road 2, Simpson prices at strike 90: " + "  ".join(f"{x:.6f}" for x in D2))
assert all(abs(a - b) < 1e-5 for a, b in zip(D1, D2))
# road 3: forwards from parity, dividends from forward differences
F = [K + (C - P) * exp(r * T) for T, (C, P) in zip(EXP, quotes)]
prevF = [S] + F[:-1]
FUT3 = [(pf * exp(r) - f) * exp(-r * (T - t)) for pf, f, T, t in zip(prevF, F, EXP, tpay)]
print("road 3, forwards " + "  ".join(f"{x:.6f}" for x in F) + "  futures " + "  ".join(f"{x:.6f}" for x in FUT3))
assert all(abs(a - b) < 1e-9 for a, b in zip(FUT, FUT3))
assert abs(sum(FUT3) - sum(d for _, d in DIVS)) < 1e-5     # swap strike = the listed total

# dividend delta: dollars of option per $1 more on dividend i
print("dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)")
for T in EXP:
    row = [-N(d1(T, K, DIVS)) * exp(-r * t) if t < T else 0.0 for t in tpay]
    bump = []
    for i in range(3):
        up = [(t, d + (0.01 if j == i else 0)) for j, (t, d) in enumerate(DIVS)]
        dn = [(t, d - (0.01 if j == i else 0)) for j, (t, d) in enumerate(DIVS)]
        bump.append((simpson_pair(T, K, up)[0] - simpson_pair(T, K, dn)[0]) / 0.02)
    assert all(abs(a - b) < 1e-4 for a, b in zip(row, bump))
    print(f"  {T:.0f}y call  formula " + " ".join(f"{x:+.4f}" for x in row) + "  bump " + " ".join(f"{x:+.4f}" for x in bump) + f"  total {sum(row):+.4f}")
row3 = [-N(d1(3.0, K, DIVS)) * exp(-r * t) for t in tpay]
cut = [(t, 0.9 * d) for t, d in DIVS]
gain = bs(3.0, K, cut)[0] - quotes[2][0]
print(f"3y call N(d1) {N(d1(3.0, K, DIVS)):.6f}; all dividends cut 10%: call gains {gain:.6f}, delta predicts {sum(-x * 0.1 * d for x, (t, d) in zip(row3, DIVS)):.6f}")
print("3y put dividend delta " + " ".join(f"{N(-d1(3.0, K, DIVS)) * exp(-r * t):+.4f}" for t in tpay))

# what breaks
print(f"break: future left at PV, year 2 {D1[1] - D1[0]:.6f}")
print(f"break: carried to year end, year 2 {(D1[1] - D1[0]) * exp(r * 2.0):.6f}")
print(f"break: swap strike as sum of PVs {D1[2]:.6f}; carried to year 3 {D1[2] * exp(3 * r):.6f}")
qb = [bs(T, K, DIVS, b=0.01) for T in EXP]
Fb = futures(strip(qb, K), tpay)
print("break: 1% borrow fee read as dividends, futures " + "  ".join(f"{x:.6f}" for x in Fb))
assert Fb[1] - FUT[1] > 0.9                             # the fee shows up as about $1 a year
print(f"house: forward with borrow {S * exp(0.02):.4f}, without {S * exp(0.03):.4f}")

# try changing
q120 = [bs(T, 120.0, DIVS) for T in EXP]
print("try: strike 120 strip " + "  ".join(f"{x:.6f}" for x in strip(q120, 120.0)))
hi = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.50)]
print(f"try: year-3 dividend 2.50: 3y call {bs(3.0, K, hi)[0]:.6f} from {quotes[2][0]:.6f}")
print("try: strike 80: 3y call delta " + " ".join(f"{-N(d1(3.0, 80.0, DIVS)) * exp(-r * t):+.4f}" for t in tpay) + "  full short " + " ".join(f"{-exp(-r * t):+.4f}" for t in tpay))
print("ALL CHECKS PASS")
