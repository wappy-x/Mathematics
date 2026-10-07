# Lebesgue's theorem on monotone functions -- the check behind the card.
# Standard library only: a hand-written exponential, Cantor staircase and Simpson
# rule; exact fractions for the Takagi counterexample.  Claims in thousands of dollars.
from fractions import Fraction as Fr

def exp_pos(x):                               # e^x for x >= 0, summed term by term
    total, term, k = 1.0, 1.0, 0
    while term > 1e-17 * total:
        k += 1
        term *= x / k
        total += term
    return total

def e_neg(x): return 1.0 / exp_pos(x)         # e^(-x) for x >= 0

def cantor(p, q, digits=40):                  # Cantor staircase C at p/q >= 0, base-3 digits
    if p >= q: return 1.0
    value, half = 0.0, 0.5
    for _ in range(digits):
        p *= 3
        d, p = p // q, p % q
        if d == 1: return value + half        # inside a removed middle third: C is flat there
        if d == 2: value += half
        half /= 2
    return value

def self_similar(k, n):                       # 2^n C(k / 3^n) by C(x) = C(3x)/2, 1/2, 1/2 + C(3x - 2)/2
    if k == 0 or k == 3**n: return 2**n if k else 0
    third = 3**(n - 1)
    if k <= third: return self_similar(k, n - 1)
    return 2**(n - 1) if k <= 2 * third else 2**(n - 1) + self_similar(k - 2 * third, n - 1)

def simpson(g, a, b, m=6000):                 # Simpson's rule, m even
    h = (b - a) / m
    return (g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, m))) * h / 3

N = 7                                         # road B grid: cells of width 3^-7, all points over Q = 4 * 3^8
T, Q = 3**N, 4 * 3**(N + 1)
def road_b(F, lo, hi):                        # integral of F' read off F alone, plus the largest cell rise
    total, big, at = 0.0, 0.0, None
    for j in range(lo * T, hi * T):           # midpoint (2j+1)/(2T) = 6(2j+1)/Q; step 1/Q either side
        m = 6 * (2 * j + 1)
        total += (F(m + 1) - F(m - 1)) * Q / 2 / T
        rise = F(12 * (j + 1)) - F(12 * j)
        if rise > big: big, at = rise, Fr(j + 1, T)
    return total, big, at

# ---- The Cantor staircase ----
print("chart, Cantor staircase C at x = k/27, k = 0..27, in % of the climb: "
      + ", ".join(f"{100 * cantor(k, 27):.2f}" for k in range(28)))
print("road A, stages: cells of width 3^-n on [0, 1]; C rises on some and is flat on the rest")
for n in (1, 2, 3, 4, 6, 8, 10):
    t = 3**n
    rises = [cantor(j + 1, t) - cantor(j, t) for j in range(t)]
    up = [r for r in rises if r > 0]
    print(f"  n = {n:2d}: rising {len(up):4d} of {t:5d}, slope there {up[0] * t:9.4f}, their length "
          f"{len(up) / t:.6f}, flat length {1 - len(up) / t:.6f}, integral of stage slopes {sum(rises):.6f}")
    assert len(up) == 2**n and all(r == 0.5**n for r in up)   # count and size match the construction
    assert all(cantor(k, t) * 2**n == self_similar(k, n) for k in range(t + 1))   # digits agree with self-similarity
flat = sum(cantor(6 * (2 * j + 1) + 1, Q) == cantor(6 * (2 * j + 1) - 1, Q) for j in range(T))
cb, _, _ = road_b(lambda p: cantor(p, Q) if p > 0 else 0.0, 0, 1)
print(f"road B, midpoints: C is flat around {flat} of {T} midpoints of width-3^-{N} cells; "
      f"midpoint sum of C' = {cb:.6f}")
assert flat == T
print(f"Cantor: C(1) - C(0) = {cantor(1, 1) - cantor(0, 1):.6f}; integral of C' = {cb:.6f}; "
      f"shortfall {cantor(1, 1) - cb:.6f}, all of it singular")
at0 = [cantor(1, 3**n) * 3**n for n in range(1, 7)]
print("Cantor at x = 0: C(3^-n) / 3^-n for n = 1..6: " + ", ".join(f"{v:.6f}" for v in at0))
assert at0 == [1.5**n for n in range(1, 7)]

# ---- The insurance claim: 0.3 chance of no claim, else exponential with mean 1 ----
Fc = lambda x: 0.0 if x < 0 else 0.3 + 0.7 * (1 - e_neg(x))
dens = lambda x: 0.7 * e_neg(x)               # F' away from 0, from the decomposition
pts = [-1, -0.5, None, 0, 0.5, 1, 2, 3, 4, 5]
lab = "at -1, -0.5, just below 0, 0, 0.5, 1, 2, 3, 4, 5"
print(f"chart, claim F(x) - F(-1) {lab}: "
      + ", ".join(f"{Fc(-1e-9 if x is None else x) - Fc(-1):.2f}" for x in pts))
print(f"chart, claim integral of F' from -1 to x {lab}: "
      + ", ".join(f"{simpson(dens, 0.0, x) if x and x > 0 else 0.0:.2f}" for x in pts))
ca = simpson(dens, 0.0, 5.0)
cB, cjump, cat = road_b(lambda p: Fc(p / Q), -1, 5)
cgap = Fc(5) - Fc(-1)
print(f"claim, road A (density 0.7 e^(-x), Simpson over (0, 5]): {ca:.6f}")
print(f"claim, road B (F alone, {6 * T} midpoints): {cB:.6f}; largest cell rise {cjump:.6f}, cell ending at {cat}")
print(f"claim: F(5) - F(-1) = {cgap:.6f}; shortfall {cgap - cB:.6f}; F(1) = {Fc(1):.6f}")
assert abs(cB - ca) < 1e-7 and abs(cgap - cB - cjump) < 1e-7 and cat == 0

# ---- Three pieces: 0.3 jump at 0, 0.5 exponential, 0.2 Cantor on [0, 1] ----
F3 = lambda p: 0.0 if p < 0 else 0.3 + 0.5 * (1 - e_neg(p / Q)) + 0.2 * cantor(p, Q)
ta = simpson(lambda x: 0.5 * e_neg(x), 0.0, 1.0)
tB, tjump, tat = road_b(F3, -1, 1)
tgap = F3(Q) - F3(-Q)
print(f"three-piece on [-1, 1]: road A {ta:.6f}, road B {tB:.6f}; F(1) - F(-1) = {tgap:.6f}")
print(f"three-piece: shortfall {tgap - tB:.6f} = largest cell rise {tjump:.6f} (cell ending at {tat}) "
      f"+ staircase {tgap - tB - tjump:.6f}")
assert abs(tB - ta) < 1e-7 and abs(tgap - tB - tjump - 0.2) < 1e-7

# ---- What breaks ----
def s(y): r = y - (y.numerator // y.denominator); return min(r, 1 - r)   # distance to nearest whole number
def takagi(j, n):                             # T(j / 2^n) exactly: terms k >= n vanish at a dyadic point
    return sum(s(Fr(j * 2**k, 2**n)) / 2**k for k in range(n))
tq, walk, third = [], [], Fr(1, 3)            # cells [j/2^n, (j+1)/2^n] around 1/3
for n in range(1, 13):
    j = (2**n) // 3
    tq.append((takagi(j + 1, n) - takagi(j, n)) * 2**n)
    walk.append(sum(1 - 2 * (int(third * 2**i) % 2) for i in range(1, n + 1)))   # +1 per binary 0, -1 per 1
print("Takagi T (not monotone): slope of T across the width-2^-n cell holding 1/3, n = 1..12: "
      + ", ".join(str(v) for v in tq))
assert tq == walk                             # the zeros-minus-ones count of the binary digits
print(f"mistake 1, integral of F' taken as F(b) - F(a): Cantor {cb:.6f} vs 1; claim {cB:.6f} vs {cgap:.6f}")
print(f"mistake 2, stage slopes integrate to 1 at every n; their a.e. limit integrates to {cb:.6f}")
print(f"mistake 3, slope expected everywhere: at 0, Cantor quotient {at0[-1]:.6f} at h = 3^-6; "
      f"claim quotient {Fc(1e-6) / 1e-6:.1f} at h = 10^-6")
print("ALL CHECKS PASS")
