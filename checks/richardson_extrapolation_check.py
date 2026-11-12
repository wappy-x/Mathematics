# Richardson extrapolation -- the check behind the card.  Only math is imported,
# for log10 and pow in the reporting lines.  The bond (illustrative): $1,000 face,
# 30 years, a $40 coupon once a year, priced at a 5% yield.  x is the yield in
# basis points (bp, hundredths of a percent), so bumps h are in bp and every
# derivative is in dollars per bp.  Road 1: the price formula differentiated term
# by term.  Road 2: central differences, alone and combined (Richardson).  Road 3:
# the Taylor series, predicting each difference's error from P''' and P^(5).
import math
C, F, N, X0, BP = 40.0, 1000.0, 30, 500.0, 1e-4
def price(x):                                  # discount factors by repeated multiply
    v, d, s = 1.0 / (1.0 + x * BP), 1.0, 0.0
    for t in range(1, N + 1):
        d *= v
        s += C * d
    return s + F * d
def deriv(x, k):                               # k-th derivative of price, term by term
    v, s = 1.0 / (1.0 + x * BP), 0.0
    for t in range(1, N + 1):
        f, d = 1.0, 1.0
        for j in range(t + k): d *= v
        for j in range(k): f *= -(t + j) * BP
        s += (C + (F if t == N else 0.0)) * f * d
    return s
def cen(p, h, x=X0): return (p(x + h) - p(x - h)) / (2 * h)
def rich(p, h, x=X0): return (4 * cen(p, h, x) - cen(p, 2 * h, x)) / 3
def e(v): return f"{v:+.3e}"
P0, P1, P3, P5 = price(X0), deriv(X0, 1), deriv(X0, 3), deriv(X0, 5)
print(f"price at 5%, dollars                 {P0:.10f}")
print(f"exact P', dollars per bp             {P1:.10f}")
print(f"P''' per bp^3 and P^(5) per bp^5     {P3:.6e} {P5:.6e}")
D1, D2 = cen(price, 1.0), cen(price, 2.0)
R1 = (4 * D1 - D2) / 3
est = (D2 - D1) / 3                            # the free error estimate for D(1)
for name, val in [("central, 1 bp each way", D1), ("central, 2 bp each way", D2),
                  ("Richardson (4 D(1) - D(2))/3", R1)]:
    print(f"{name:<30}{val:.12f}  error {e(val - P1)}")
print(f"error ratio D(2)/D(1)                {(D2 - P1) / (D1 - P1):.4f}")
print(f"gap D(2)-D(1) {D2 - D1:.12f}, a third of it {est:.12f}")
print(f"free estimate (D(2)-D(1))/3          {e(est)}  ratio to true {est / (D1 - P1):.5f}")
print(f"series: P'''h^2/6 + P5 h^4/120, h=1  {e(P3 / 6 + P5 / 120)}")
print(f"series: -P5 h^4/30, h=1              {e(-P5 / 30)}")
r8 = (rich(price, 8.0) - P1) / (-P5 * 8.0 ** 4 / 30)
print(f"R(8) error over -P5 h^4/30, h=8      {r8:.5f}")
print(f"gain at 1 bp, central error / Richardson error  {abs((D1 - P1) / (R1 - P1)):.4e}")
S, Q1 = 10000.0, deriv(450.0, 1)               # the shelf's $10m position: 10,000 bonds at 4.50%
print(f"shelf $10m at 4.50%: price {S * price(450.0):.6f}; error central {S * (cen(price, 1.0, 450.0) - Q1):+.6f}, "
      f"Richardson {e(S * (rich(price, 1.0, 450.0) - Q1))} $/bp")
print("h bp, log10 h, central error, Richardson error, log10 of each")
sweep = [4.0 ** k for k in range(3, -9, -1)]
ce, re = [], []
for h in sweep:
    a, b = cen(price, h) - P1, rich(price, h) - P1
    ce.append(abs(a)); re.append(abs(b))
    print(f"{h:12.9f} {math.log10(h):6.2f} {e(a)} {e(b)} {math.log10(abs(a)):6.2f} {math.log10(abs(b)):6.2f}")
u = 2.0 ** -53                                 # unit roundoff, written out
eta = u * (1 + X0 * BP) * abs(P1) / BP         # price moved by one rounding of 1 + y
hr = (45 * eta / (4 * abs(P5))) ** 0.2         # minimise |P5| h^4/30 + 1.5 eta/h
hc = (3 * eta / abs(P3)) ** (1 / 3)            # minimise |P3| h^2/6 + eta/h
print(f"rounding per price eta, dollars      {eta:.3e}")
print(f"best h, Richardson and central, bp   {hr:.3f} {hc:.4f}")
mr, mc = abs(P5) * hr ** 4 / 30 + 1.5 * eta / hr, abs(P3) * hc ** 2 / 6 + eta / hc
print(f"error model at best h, R and central {mr:.2e} {mc:.2e}")
print(f"observed best: Richardson {min(re):.2e} at h {sweep[re.index(min(re))]:.4f}, "
      f"central {min(ce):.2e} at h {sweep[ce.index(min(ce))]:.4f}")
print(f"u {u:.3e}; model over measured best, R and central {mr / min(re):.1f} "
      f"{mc / min(ce):.1f}; best-step ratio {hr / hc:.0f}; R(4^-8) over R(1) {re[-1] / re[3]:.0f}")
# what breaks
def fwd(h): return (price(X0 + h) - P0) / h
w1 = 2 * D1 - D2                               # treats the error as size h, not h^2
w2 = (4 * fwd(1.0) - fwd(2.0)) / 3             # forward difference: error is size h
w3 = (4 * D1 - cen(price, 3.0)) / 3            # bumps 1 and 3 with the factor for 1 and 2
ok3 = (9 * D1 - cen(price, 3.0)) / 8           # the right factor, 3^2 = 9
w4 = rich(price, 4.0 ** -8)
def cents(x): return math.floor(price(x) * 100 + 0.5) / 100
w5 = rich(cents, 1.0)
print(f"prices to the cent: central 1 bp {e(cen(cents, 1.0) - P1)}, central 8 bp "
      f"{e(cen(cents, 8.0) - P1)}, Richardson 32 bp {e(rich(cents, 32.0) - P1)}")
cap = price(X0 - 0.5)                          # a cap half a bp below: a kink
def capped(x): return min(price(x), cap)
w6 = rich(capped, 1.0)
for name, val in [("weights 2 and 1", w1), ("forward differences, 4 and 3", w2),
                  ("bumps 1 and 3, factor 4", w3), ("bumps 1 and 3, factor 9", ok3),
                  ("Richardson at h = 4^-8 bp", w4), ("prices to the cent", w5),
                  ("capped price, kink at 499.5 bp", w6)]:
    print(f"{name:<32}{val:.10f}  error {e(val - P1)}")
assert abs(R1 - P1) < 1e-10 and abs(D1 - P1) > 1e-7             # the gain is real
assert abs((D2 - P1) / (D1 - P1) - 4) < 0.01                    # central: order 2
assert abs(re[1] / re[2] / 256 - 1) < 0.01                       # Richardson: order 4
assert abs((D1 - P1) / (P3 / 6 + P5 / 120) - 1) < 1e-3          # series predicts error
assert abs(r8 - 1) < 1e-2                                       # series predicts R's error
assert abs(est / (D1 - P1) - 1) < 1e-3                          # free estimate
assert 0.25 <= sweep[re.index(min(re))] <= 4 and re[-1] > 100 * re[3]  # rounding stops it
assert min(abs(w1 - P1), abs(w2 - P1), abs(w3 - P1), abs(w5 - P1), abs(w6 - P1)) > 1e-7
assert abs(ok3 - P1) < 1e-10 and abs(w6 - P1) > 0.01
print("ALL CHECKS PASS")
