# Implied volatility -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the
# answer: the normal CDF is a series written out, the brute-force price is
# Simpson's rule, the root finder is bisection.
from math import log, sqrt, exp, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x

def N(x):                        # bell-curve area left of x: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + phi(x) * total

def call(S, K, r, q, s, T):                               # road 1: the formula
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - s * sqrt(T))

def put(S, K, r, q, s, T):                                # the put formula, written separately
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T))
    return K * exp(-r * T) * N(s * sqrt(T) - d1) - S * exp(-q * T) * N(-d1)

def call_by_integral(S, K, r, q, s, T, n=20000):          # road 2: average the payoff, no d1, no d2
    a, b = -10.0, 10.0; h = (b - a) / n
    def f(z):
        return max(S * exp((r - q - 0.5 * s * s) * T + s * sqrt(T) * z) - K, 0.0) * phi(z)
    tot = f(a) + f(b)
    for i in range(1, n): tot += (4 if i % 2 else 2) * f(a + i * h)
    return exp(-r * T) * tot * h / 3.0

def bisect(price, quote, lo, hi, steps=60):               # halve the bracket, keep the half holding the quote
    for _ in range(steps):
        mid = 0.5 * (lo + hi)
        if price(mid) < quote: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def implied(quote, floor, ceiling, price, lo=1e-6, hi=10.0):
    if not floor < quote < ceiling: return None           # outside the range: no volatility exists
    return bisect(price, quote, lo, hi)

S, K, r, q, T = 100.0, 100.0, 0.05, 0.02, 1.0
A, B = S * exp(-q * T), K * exp(-r * T)                    # prepaid share, discounted strike
floor_c, ceil_c = max(A - B, 0.0), A
floor_p, ceil_p = max(B - A, 0.0), B
QC, QP = 9.227005508154, 6.330080627550                   # the house call and put quotes
C = lambda s: call(S, K, r, q, s, T)
iv1 = implied(QC, floor_c, ceil_c, C)
iv2 = bisect(lambda s: call_by_integral(S, K, r, q, s, T), QC, 0.05, 1.0, 40)
iv3 = implied(QP, floor_p, ceil_p, lambda s: put(S, K, r, q, s, T))
d1 = (log(S / K) + (r - q + 0.5 * iv1 * iv1) * T) / (iv1 * sqrt(T))
vega_an = A * phi(d1) * sqrt(T)
vega_fd = (C(0.2 + 1e-4) - C(0.2 - 1e-4)) / 2e-4

rows = [("floor, sigma -> 0: max(A - B, 0)", floor_c), ("ceiling, sigma -> oo: A = S e^-qT", ceil_c),
        ("  price at sigma = 0.01", C(0.01)), ("  price at sigma = 20", C(20.0)),
        ("put floor", floor_p), ("put ceiling: B = K e^-rT", ceil_p),
        ("1 implied vol, formula + bisection", iv1), ("2 implied vol, Simpson price", iv2),
        ("3 implied vol of the put quote", iv3),
        ("vega at 0.20, A phi(d1) sqrt(T)", vega_an), ("vega at 0.20, by bump", vega_fd),
        ("dollars per vol point", vega_an / 100), ("d1 at 0.20", d1), ("phi(d1)", phi(d1)),
        ("forward F = S e^(r-q)T", S * exp((r - q) * T)), ("discount e^-rT", exp(-r * T)),
        ("free money, call quoted at 2.80", floor_c - 2.80), ("free money, call quoted at 99", 99.0 - ceil_c)]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")

print("\nquote -> implied vol (call, house inputs)")
ladder = (2.80, 2.90, 3.00, 5.00, 9.23, 15.00, 25.00, 50.00, 90.00, 98.00, 99.00)
ivs = {}
for Q in ladder:
    ivs[Q] = implied(Q, floor_c, ceil_c, C)
    print(f"  quote {Q:6.2f}  " + ("no implied vol" if ivs[Q] is None else f"sigma {ivs[Q]:.6f}  repriced {C(ivs[Q]):.6f}"))

print("\nchart: call price as sigma climbs (sigma in %)")
grid = [25 * i for i in range(13)]
prices = [floor_c if g == 0 else C(g / 100) for g in grid]
print("  sigma % " + " ".join(f"{g:6d}" for g in grid))
print("  price   " + " ".join(f"{p:6.2f}" for p in prices))
print(f"  flat lines: floor {floor_c:.2f}, ceiling {ceil_c:.2f}, quote {QC:.2f}")
zoom = [5 * i for i in range(9)]
print("  sigma % " + " ".join(f"{g:6d}" for g in zoom))
print("  price   " + " ".join(f"{(floor_c if g == 0 else C(g / 100)):6.2f}" for g in zoom))

print("\nwhat breaks (house call quote 9.227006 unless stated)")
wrong = [("forgot the 2% dividend", implied(QC, max(S - B, 0), S, lambda s: call(S, K, r, 0.0, s, T))),
         ("rate ln(1.05) = 4.879% for the 5%", implied(QC, floor_c, ceil_c, lambda s: call(S, K, log(1.05), q, s, T))),
         ("put quote 6.33 fed to the call", implied(QP, floor_c, ceil_c, C)),
         ("2.80, floor taken as S - K = 0", bisect(C, 2.80, 1e-6, 10.0)),
         ("99, ceiling taken as S = 100", bisect(C, 99.0, 1e-6, 10.0))]
for name, v in wrong: print(f"  {name:<42} {v:>10.6f}")

print("\ntry: T = 0.25, quote 4.00 ->", f"{implied(4.0, max(S*exp(-q/4)-K*exp(-r/4), 0), S*exp(-q/4), lambda s: call(S, K, r, q, s, 0.25)):.6f}")
print("try: K = 120, quote 2.711776 ->", f"{implied(2.711776, 0.0, A, lambda s: call(S, 120.0, r, q, s, T)):.6f}")

assert abs(iv1 - 0.20) < 1e-9, "the quote was made at 20%; bisection must recover it"
assert abs(iv2 - iv1) < 1e-7, "a price built by brute-force averaging must give the same volatility"
assert abs(iv3 - iv1) < 1e-9, "the put quote, inverted on its own formula, must agree (parity)"
assert abs(vega_fd - vega_an) < 1e-6, "bumped slope vs A phi(d1) sqrt(T)"
assert abs(C(0.01) - (A - B)) < 1e-3, "near sigma = 0 the price sits on the floor"
assert abs(C(20.0) - A) < 1e-9, "at huge sigma the price sits under the ceiling"
assert ivs[2.80] is None and ivs[99.00] is None, "quotes outside the range have no volatility"
assert all(v is None or abs(C(v) - Q) < 1e-9 for Q, v in ivs.items()), "every ladder volatility must reprice to its quote"
assert C(1e-6) > 2.80 and C(10.0) < 99.0 and wrong[3][1] < 1e-5 and wrong[4][1] > 9.99, "no root: the solver stops at a search edge"
assert all(x < y for x, y in zip(prices, prices[1:])), "price must climb with volatility"
print("ALL CHECKS PASS")
