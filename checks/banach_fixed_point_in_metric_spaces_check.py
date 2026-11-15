# Banach's fixed point theorem -- the check behind the card.  Standard library only.
# Four cafes reset their coffee prices each morning: half their own target price,
# plus half the average of the other three cafes' prices.  Prices are in cents.
# Road one runs the passes exactly (prices times 6^n are whole numbers).  Road two
# solves for the settled prices by hand's closed form.  Road three predicts every
# error from the rule's two shrink rates, 1/2 and -1/6.  The theorem's bound is
# then set beside the true error.  Exact numbers print by integer rounding.
import math

TGT = [280, 315, 350, 420]     # each cafe's target price, cents
P0 = [300, 300, 300, 300]      # today's prices, cents

def fmt(num, den, k):          # num/den to k decimals, half rounded up
    s = '-' if num < 0 else ''
    v = (abs(num) * 10 ** k * 2 + den) // (2 * den)
    return s + (f"{v // 10 ** k}.{v % 10 ** k:0{k}d}" if k else str(v))

def step(P, D):                # one pass on prices P/D; returns new P, new D = 6D
    s = sum(P)
    return [3 * t * D + s - x for t, x in zip(TGT, P)], 6 * D

def dist(a, b):                # worst-case distance d_inf between two lists
    return max(abs(x - y) for x, y in zip(a, b))

# ---- road two: the settled prices, (3 c_i + sum of targets) / 7 ----
for t in TGT:
    assert (3 * t + sum(TGT)) % 7 == 0
PS = [(3 * t + sum(TGT)) // 7 for t in TGT]
assert step(PS, 1)[0] == [6 * x for x in PS]       # the rule leaves them unchanged
print(f"settled prices (3 c + {sum(TGT)}) / 7, cents:", ", ".join(map(str, PS)))

# ---- the contraction constant: a formula, 1000 random pairs, one bad pair ----
st = 2026
def rnd():                     # SplitMix64
    global st
    st = (st + 0x9E3779B97F4A7C15) % 2 ** 64
    z = st
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return z ^ (z >> 31)
def ratio(p, r):               # d(Tp, Tr) / d(p, r) as (num, den)
    return dist(step(p, 1)[0], step(r, 1)[0]), 6 * dist(p, r)
bn, bd = 0, 1
for _ in range(1000):
    p = [200 + rnd() % 301 for _ in range(4)]
    r = [200 + rnd() % 301 for _ in range(4)]
    if p != r:
        n, d = ratio(p, r)
        if n * bd > bn * d:
            bn, bd = n, d
assert 2 * bn <= bd                                 # no pair shrinks by less than half
sn, sd = ratio([x + 10 for x in P0], P0)
assert 2 * sn == sd                                 # an even shift shrinks by exactly half
on, od = ratio([310, 290, 300, 300], P0)
print(f"q by formula: 1/2 x (3 x 1/3) = 1/2; worst of 1000 random pairs: {fmt(bn, bd, 6)}")
print(f"even 10-cent shift: ratio {fmt(sn, sd, 6)}; pair (310, 290, 300, 300): ratio {fmt(on, od, 6)}")

# ---- the passes, the true error, and the theorem's two bounds ----
P, D, prev = P0[:], 1, None
d01 = dist(step(P0, 1)[0], [6 * x for x in P0])     # first step, times 6
print(f"first step d(p1, p0) = {fmt(d01, 6, 2)} cents; first-step bound = {fmt(d01, 3, 0)} / 2^n cents")
print("n, p_n (cents), true error, first-step bound, last-step bound")
need = {}
logs_e, logs_b = [], []
for n in range(21):
    E = [x - s * D for x, s in zip(P, PS)]
    e0 = [x - s for x, s in zip(P0, PS)]
    for e, z in zip(E, e0):                         # road three: 1/2 and -1/6 rates
        assert 4 * e == -165 * 3 ** n + (-1) ** n * (4 * z + 165)
    err = max(abs(e) for e in E)
    assert err * 3 * 2 ** n <= d01 * D              # first-step bound holds
    last = dist(P, [6 * x for x in prev]) if prev else None
    if last is not None:
        assert err <= last                          # last-step bound holds (q/(1-q) = 1)
    for key, ok in [("first", d01 <= 3 * 2 ** n), ("last", last is not None and last <= D),
                    ("true", err <= D)]:
        if ok and key not in need:
            need[key] = n
    if n == 5:
        e5 = fmt(err, D, 4)
    if n <= 10:
        print(n, " ".join(fmt(x, D, 2) for x in P), fmt(err, D, 4), fmt(d01, 3 * 2 ** n, 4),
              fmt(last, D, 4) if last is not None else "-", sep=", ")
        logs_e.append(f"{math.log10(err / D):.2f}")
        logs_b.append(f"{math.log10(d01 / 3 / 2 ** n):.2f}")
    prev, (P, D) = P, step(P, D)
print(f"within 1 cent: promised by first-step bound at n = {need['first']}, "
      f"by last-step bound at n = {need['last']}, true at n = {need['true']}")
print("chart, log10 true error:", ", ".join(logs_e))
print("chart, log10 first-step bound:", ", ".join(logs_b))

# ---- what breaks ----
q6 = fmt(d01, 5 * 6 ** 5, 4)                        # (1/6)^5 / (5/6) x first step
print(f"trusting the one pair, q = 1/6: 'bound' at n = 5 is {q6} cents; true error {e5}")
m = P0[:]
for _ in range(10):
    m = [(sum(m) - x) // 3 + 10 for x in m]         # match the rivals' average, plus 10
assert m == [400] * 4
print("rivals' average plus 10 cents, q = 1: after 10 passes", ", ".join(map(str, m)), "and climbing")
a, b, gaps = 1, 1, []
for _ in range(4):                                  # x/2 + 1/x on the fractions in [1, 2]
    a2, b2 = a * a + 2 * b * b, 2 * a * b
    g = math.gcd(a2, b2)
    a2, b2 = a2 // g, b2 // g
    gaps.append((abs(a2 * b - a * b2), b * b2))
    a, b = a2, b2
for (g1, h1), (g2, h2) in zip(gaps, gaps[1:]):
    assert 2 * g2 * h1 <= g1 * h2                   # each gap at most half the last
print(f"fractions only: x4 = {a}/{b}, x4^2 - 2 = {a * a - 2 * b * b}/{b * b}; the limit is sqrt 2, not a fraction")
w = 1.0
for _ in range(1000):
    w += 1 / w                                      # x + 1/x on [1, infinity): every gap shrinks
assert w * w >= 2001                                # x_n^2 >= 1 + 2n: it never settles
print(f"x + 1/x from 1: x_1000 = {w:.4f}, still climbing; gap 100 to 101 shrinks to {(101 + 1 / 101) - (100 + 1 / 100):.6f}")

# ---- curves: Picard's map for y' = y on [0, 1/2] halves the largest gap ----
ex = math.exp(0.5)
s, term = 0.0, 1.0
for k in range(1, 30):
    s, term = s + term, term * 0.5 / k
assert abs(s - ex) < 1e-15                          # e^(1/2) two ways
row = []
for n in range(1, 7):
    num = sum(2 ** (n - k) * math.factorial(n) // math.factorial(k) for k in range(n + 1))
    err = ex - num / (2 ** n * math.factorial(n))   # largest gap sits at t = 1/2
    assert 0 < err <= 0.5 ** n                      # bound: q^n / (1 - q) x d(y1, y0)
    row.append(f"{err:.8f} <= {0.5 ** n:.8f}")
print(f"e^(1/2) = {ex:.10f}; Picard error, bound, n = 1..6:")
print("; ".join(row[:3]))
print("; ".join(row[3:]))
print("ALL CHECKS PASS")
