# Autocallables and Phoenix notes -- the check behind the card.  Standard library only.
# Uniforms: the printed recurrence; normals: Box-Muller; bell-curve area: its own series.
from math import cos, exp, log, pi, sin, sqrt

S0, R, Q, SIG = 100.0, 0.05, 0.02, 0.20       # the house market
CALL, KI, ISSUE = 100.0, 70.0, 98.0           # autocall level, knock-in level, target price
SEED, PATHS, DT = 20261123, 100000, 0.25      # twelve quarterly steps per path
COUPONS, PHX = (0.05, 0.06, 0.07, 0.08, 0.09, 0.10), 0.02   # PHX: Phoenix coupon a quarter
MOD, MU = 1 << 32, R - Q - 0.5 * SIG * SIG    # MU: pricing-world growth per year

def uniform(state):                           # one step of the recurrence
    state = (1664525 * state + 1013904223) % MOD
    return state, (state + 0.5) / MOD

def normal_pair(state):                       # Box-Muller: two uniforms -> two normals
    state, u = uniform(state)
    state, v = uniform(state)
    rad, ang = sqrt(-2.0 * log(u)), 2.0 * pi * v
    return state, rad * cos(ang), rad * sin(ang)

def ncdf(x):                                  # bell-curve area left of x, Taylor series
    if x < -9.0 or x > 9.0:
        return 0.0 if x < 0 else 1.0
    s, t, b, i = x, 0.0, x, 1
    while s != t:
        t, i = s, i + 2
        b *= x * x / i
        s = t + b
    return 0.5 + s * exp(-0.5 * x * x - 0.91893853320467274178)

def at_maturity(s):                           # year 2, not called: year 3 valued at year 2
    d2 = lambda k: (log(s / k) + MU) / SIG
    a = 100.0 - 100.0 * ncdf(-d2(KI)) + s * exp(R - Q) * ncdf(-d2(KI) - SIG)
    return exp(-R) * a, exp(-R) * 300.0 * ncdf(d2(CALL))

def roll(cont, year, s, n=160):               # one year back: call region exact, rest by Simpson
    zc = min((log(CALL / s) - MU) / SIG, 9.0)
    h, sa, sb = (zc + 9.0) / n, 0.0, 0.0
    for i in range(n + 1):
        z = -9.0 + i * h
        w = (1.0 if i in (0, n) else 4.0 if i % 2 else 2.0) * exp(-0.5 * z * z) / sqrt(2.0 * pi)
        a, b = cont(s * exp(MU + SIG * z))
        sa, sb = sa + w * a, sb + w * b
    up = 1.0 - ncdf(zc)                       # chance of being called at this date
    return exp(-R) * (sa * h / 3.0 + up * 100.0), exp(-R) * (sb * h / 3.0 + up * 100.0 * year)
QA, QB = roll(lambda s: roll(at_maturity, 2, s), 1, S0)   # road 2: quadrature
e = [exp(-R * DT * j) for j in range(13)]                 # quarterly discount factors
acc, state, first = [0.0] * 22, SEED, None
for p in range(PATHS):
    s, path = S0, []
    for _ in range(6):
        state, z1, z2 = normal_pair(state)
        for z in (z1, z2):
            s *= exp(MU * DT + SIG * sqrt(DT) * z)
            path.append(s)
    y1, y2, y3 = path[3], path[7], path[11]
    end3 = 100.0 if y3 >= KI else y3                     # redemption at year 3, S0 = 100
    k = 1 if y1 >= CALL else 2 if y2 >= CALL else 3
    a = 100.0 * e[4 * k] if k < 3 else e[12] * end3
    b = 100.0 * k * e[4 * k] if (k < 3 or y3 >= CALL) else 0.0
    a_d3, b_d3 = a * e[12] / e[4 * k], b * e[12] / e[4 * k]
    a_ki = e[12] * (100.0 - (KI - y3)) if (k == 3 and y3 < KI) else a
    loss = e[12] * (100.0 - y3) if (k == 3 and y3 < KI) else 0.0
    owed, pa, pb, pbn, last = 0, 0.0, 0.0, 0.0, 12        # Phoenix, road 1: a ledger
    for j, sj in enumerate(path, 1):
        owed += 1
        if sj >= KI:
            pb, pbn, owed = pb + 100.0 * owed * e[j], pbn + 100.0 * e[j], 0
        if j in (4, 8) and sj >= CALL:
            pa, last = 100.0 * e[j], j
            break
        if j == 12:
            pa = e[12] * (100.0 if sj >= KI else sj)
    pb2, nxt = 0.0, 0                                     # road 2: each quarter's coupon
    for j in range(last, 0, -1):                          # is paid at the next good date
        nxt = j if path[j - 1] >= KI else nxt
        pb2 += 100.0 * e[nxt] if nxt else 0.0
    dig = e[1] if path[0] >= KI else 0.0
    row = (a, b, a * a, a * b, b * b, a_d3, b_d3, a_ki, loss, pa, pb, pbn, pb2,
           dig, k == 1, k == 2, k == 3 and y3 >= CALL, k == 3 and KI <= y3 < CALL,
           k == 3 and y3 < KI, float(k), e[4] * y1, e[4] * y1 * e[4] * y1)
    acc = [x + float(v) for x, v in zip(acc, row)]
    if first is None:
        first = (path, k, a, b, pa, pb)
m = [x / PATHS for x in acc]
A, B, P1, P2, P3U, P3M, P3D = m[0], m[1], m[14], m[15], m[16], m[17], m[18]
B_SURE = 100.0 * (e[4] + e[8] + e[12])        # coupon read as certain, every year
def se(c):                                    # standard error of the price at coupon c
    return sqrt((m[2] + 2 * c * m[3] + c * c * m[4] - (A + c * B) ** 2) / (PATHS - 1))
fair = (ISSUE - A) / B                        # the price is A + cB: solve the line
lo, hi = 0.0, 0.5                             # a search on the same line, for illustration
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if A + mid * B < ISSUE else (lo, mid)
fair_q, d2q, d2c = (ISSUE - QA) / QB, (log(S0 / KI) + MU * DT) / (SIG * sqrt(DT)), (log(S0 / CALL) + MU) / SIG
print(f"house: S0 = 100  r = 5%  q = 2%  sigma = 20%   autocall 100, knock-in 70, target {ISSUE:.0f}")
print(f"{PATHS} paths of 12 quarterly steps from seed {SEED}")
print("first path, Acme each quarter: " + " ".join(f"{x:.2f}" for x in first[0]))
print(f"first path: ends in year {first[1]}, autocall redemption {first[2]:.6f}  coupon part {first[3]:.6f}")
print(f"            Phoenix redemption {first[4]:.6f}  coupon units {first[5]:.6f}")
print(f"outcomes   called year 1 {P1:.6f}  (closed form N({d2c:.2f}) {ncdf(d2c):.6f})  year 2 {P2:.6f}")
print(f"           year 3 at or above 100 {P3U:.6f}   70 to 100 {P3M:.6f}   below 70 {P3D:.6f}")
print(f"expected life in years {m[19]:.6f}")
print(f"discount factors year 1 {e[4]:.6f}  year 2 {e[8]:.6f}  year 3 {e[12]:.6f}")
print(f"Acme at year 1, discounted  MC {m[20]:.6f}  se {sqrt((m[21] - m[20] * m[20]) / (PATHS - 1)):.6f}"
      f"  S0 e^-q {S0 * exp(-Q):.6f}")
print(f"A, redemption value      MC {A:.6f}   quadrature {QA:.6f}")
print(f"B, value per unit coupon MC {B:.6f}   quadrature {QB:.6f}")
print(f"knock-in loss L, discounted MC {m[8]:.6f}")
print(f"by hand, B: {100 * e[4] * P1:.6f} + {200 * e[8] * P2:.6f} + {300 * e[12] * P3U:.6f}")
print(f"by hand, A: {100 * (e[4] * P1 + e[8] * P2 + e[12] * (P3U + P3M + P3D)):.6f} - L;"
      f"  gap 98 - A {ISSUE - A:.6f}")
print("coupon   MC price   std error   quadrature")
for c in COUPONS:
    print(f"{c * 100:5.0f}%  {A + c * B:10.6f}  {se(c):10.6f}  {QA + c * QB:11.6f}")
print(f"fair coupon for {ISSUE:.0f}: line {fair * 100:.6f}%  bisection {0.5 * (lo + hi) * 100:.6f}%"
      f"  quadrature {fair_q * 100:.6f}%")
print(f"std error of the price at the fair coupon {se(fair):.6f}; of the coupon {se(fair) / B * 100:.6f}%")
print(f"Phoenix first coupon as a digital, per $1  MC {m[13]:.6f}   closed form {e[1] * ncdf(d2q):.6f}")
print(f"  chance Acme is below 70 at quarter 1  MC {1 - m[13] / e[1]:.6f}   closed form {ncdf(-d2q):.6f}")
print(f"Phoenix coupon units  ledger {m[10]:.6f}   next-good-date scan {m[12]:.6f}")
print(f"Phoenix redemption {m[9]:.6f}  price at 2% a quarter {m[9] + PHX * m[10]:.6f}")
print(f"Phoenix fair quarterly coupon for {ISSUE:.0f}: {(ISSUE - m[9]) / m[10] * 100:.6f}%"
      f"  four quarters {4 * (ISSUE - m[9]) / m[10] * 100:.6f}%")
print("what breaks")
print(f"  coupon read as certain for 3 years: fair coupon {(ISSUE - A) / B_SURE * 100:.6f}%")
print(f"  every payment discounted from year 3: fair coupon {(ISSUE - m[5]) / m[6] * 100:.6f}%")
print(f"  loss counted only below 70: fair coupon {(ISSUE - m[7]) / B * 100:.6f}%")
print(f"  Phoenix without memory, 2% a quarter: price {m[9] + PHX * m[11]:.6f}")
print("chart, coupon %   " + " ".join(f"{c * 100:6.0f}" for c in COUPONS))
print("chart, MC price   " + " ".join(f"{A + c * B:6.2f}" for c in COUPONS))

assert abs(A - QA) < 4 * se(0.0), "redemption value: simulation agrees with quadrature"
assert abs(B - QB) < 4 * sqrt((m[4] - B * B) / (PATHS - 1)), "coupon value: the same"
assert abs(fair - fair_q) < 0.002, "fair coupon: simulation agrees with quadrature"
assert abs(P1 - ncdf(d2c)) < 0.005, "year-1 call chance is a digital"
assert abs(m[13] / e[1] - ncdf(d2q)) < 4 * sqrt(ncdf(d2q) * ncdf(-d2q) / PATHS), "first Phoenix coupon is a digital"
assert abs(m[10] - m[12]) < 1e-9, "memory ledger equals the next-good-date scan"
assert abs(m[20] - S0 * exp(-Q)) < 4 * sqrt((m[21] - m[20] * m[20]) / (PATHS - 1)), "pricing-world growth: Acme vs S0 e^-q"
print("ALL CHECKS PASS")
