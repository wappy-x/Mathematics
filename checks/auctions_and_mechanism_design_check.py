# Auctions and mechanism design -- the check behind the card.  Standard library only.
# Money in thousands of pounds.  Five firms; each value spread evenly between 0 and 100.
from math import sqrt

N, TOP = 5, 100.0
DAY = [("A", 82.0), ("B", 71.0), ("C", 64.0), ("D", 55.0), ("E", 40.0)]
BETA = (N - 1) / N                                    # first-price shading factor, derived on the card

def top_two(xs):                                      # largest and second largest, no sorting
    a = b = -1.0
    for x in xs:
        if x > a: a, b = x, a
        elif x > b: b = x
    return a, b

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def P(v):       return (v / TOP) ** (N - 1)           # chance a value v is the highest of five
def m(v, r=0.0):                                      # expected payment, any auction (envelope)
    return v * P(v) - simpson(P, r, v, 200) if v >= r else 0.0

# ---- the day: five sealed bids ----
vals = [v for _, v in DAY]
hi, second = top_two(vals)
fp_hi, fp_second = top_two([BETA * v for v in vals])
print("day, values:      " + "  ".join(f"{k} {v:.0f}" for k, v in DAY))
print("day, first-price bids at 0.8 v: " + "  ".join(f"{k} {BETA * v:.1f}" for k, v in DAY))
print(f"day, Vickrey: A wins, pays {second:.2f}, profit {hi - second:.2f}")
print(f"day, first-price: A wins, pays {fp_hi:.2f}, profit {hi - fp_hi:.2f}")

# ---- road 1: closed forms ----
rev_v = (N - 1) / (N + 1) * TOP                       # average second-highest of five: k/(n+1)
rev_f = BETA * N / (N + 1) * TOP                      # 0.8 times the average highest
U82 = 82.0 ** N / (N * TOP ** (N - 1))                # area under P from 0 to 82
print(f"road 1, Vickrey revenue (n-1)/(n+1) x 100   {rev_v:.4f}")
print(f"road 1, first-price revenue 0.8 x n/(n+1) x 100 {rev_f:.4f}")
print(f"road 1, firm A: win chance P(82) {P(82):.4f}, profit U(82) {U82:.4f}, payment m(82) {82 * P(82) - U82:.4f}")

# ---- road 2: exhaustive grids and integrals ----
grid = [0.5 * i for i in range(201)]
def vick(v, b, c): return v - c if b > c else 0.0    # c: the highest rival bid
gap = min(vick(v, v, c) - vick(v, b, c) for v in (82.0, 60.0) for b in grid for c in grid)
print(f"road 2, Vickrey: truth minus best other bid, worst case over {2 * len(grid) ** 2} cases {gap:.4f}")
def vick_exp(v, b):                                   # rivals truthful: pay their highest when below b
    c = min(b, TOP)
    return simpson(lambda y: (v - y) * (N - 1) * y ** (N - 2) / TOP ** (N - 1), 0.0, c, 400)
def fp_exp(v, b, beta=BETA, rho=1.0):                 # rivals bid beta x value; rho < 1 is risk aversion
    w = min(b / (beta * TOP), 1.0) ** (N - 1)
    return (v - b) ** rho * w if b < v else (v - b) * w
fine = [0.01 * i for i in range(10001)]
best_v = max(grid, key=lambda b: vick_exp(82.0, b))
best_f = max(fine, key=lambda b: fp_exp(82.0, b))
print(f"road 2, firm A best bid: Vickrey {best_v:.2f} (profit {vick_exp(82.0, best_v):.4f}), "
      f"first-price {best_f:.2f} (profit {fp_exp(82.0, best_f):.4f})")
pay_v = simpson(lambda y: y * (N - 1) * y ** (N - 2) / TOP ** (N - 1), 0.0, 82.0)
print(f"road 2, firm A expected payment: Vickrey {pay_v:.4f}, first-price {best_f * P(best_f / BETA):.4f}")
rev_env = N * simpson(lambda v: m(v), 0.0, TOP, 400) / TOP
rev_os = simpson(lambda y: y * N * (N - 1) * (y / TOP) ** (N - 2) * (1 - y / TOP) / TOP, 0.0, TOP)
print(f"road 2, revenue: envelope integral {rev_env:.4f}, second-highest integral {rev_os:.4f}")
bids = [40 + 5 * i for i in range(13)]
print("chart, bid      " + " ".join(f"{b:6.0f}" for b in bids))
print("chart, Vickrey  " + " ".join(f"{vick_exp(82.0, b):6.2f}" for b in bids))
print("chart, first    " + " ".join(f"{fp_exp(82.0, b):6.2f}" for b in bids))

# ---- road 3: simulation, SplitMix64 seed 20261111 ----
state = 20261111
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
M = 200000
print(f"road 3, {M} synthetic auctions of {N} values, SplitMix64 seed {state}")
acc = {"Vickrey": [0.0, 0.0], "first-price": [0.0, 0.0], "all-pay": [0.0, 0.0],
       "Vickrey, reserve 50": [0.0, 0.0], "first-price, reserve 50": [0.0, 0.0]}  # bid v - (v^5 - 50^5) / (5 v^4)
for _ in range(M):
    vs = [TOP * unif() for _ in range(N)]
    h, s = top_two(vs)
    allpay = sum(BETA * v ** N / TOP ** (N - 1) for v in vs)   # each bids m(v) = 0.8 v^5 / 100^4
    for k, x in (("Vickrey", s), ("first-price", BETA * h), ("all-pay", allpay),
                 ("Vickrey, reserve 50", max(s, 50.0) if h >= 50.0 else 0.0),
                 ("first-price, reserve 50", h - (h ** N - 50.0 ** N) / (N * h ** (N - 1)) if h >= 50.0 else 0.0)):
        acc[k][0] += x; acc[k][1] += x * x
sim = {}
for k, (s1, s2) in acc.items():
    mean = s1 / M; sd = sqrt(s2 / M - mean * mean); sim[k] = (mean, sd / sqrt(M))
    print(f"road 3, {k:<23} mean {mean:8.4f}  sd {sd:7.4f}  standard error {sd / sqrt(M):.4f}")

# ---- what breaks, and the try-changing box ----
rho, beta_r = 0.5, (N - 1) / (N - 1 + 0.5)
best_r = max(fine, key=lambda b: fp_exp(82.0, b, beta_r, rho))
print(f"break, seller reads first-price bids as values: expects {N / (N + 1) * TOP:.4f}")
print(f"break, A bids its value 82 in first-price: profit {fp_exp(82.0, 82.0):.4f}")
print(f"break, A shades to 65.6 in Vickrey today: {'wins' if 65.6 > 71 else 'loses'}, profit {vick(82.0, 65.6, 71.0):.2f}")
print(f"break, E (value 40) bids 90 in Vickrey today: profit {vick(40.0, 90.0, 82.0):.2f}")
print(f"break, risk-averse (square-root) first-price: A bids {best_r:.2f}, revenue {beta_r * N / (N + 1) * TOP:.4f}")
rev_res = N * simpson(lambda v: m(v, 50.0), 50.0, TOP, 400) / TOP
print(f"try, reserve 50: envelope revenue {rev_res:.4f}")
for n in (2, 10):
    print(f"try, {n} firms: shading {(n - 1) / n:.2f}, revenue {(n - 1) / (n + 1) * TOP:.4f}")
# two identical contracts, one each at most: VCG = what each winner's presence costs the others
def best_total(skip):
    xs = [v for k, v in DAY if k != skip]
    return max(xs[i] + xs[j] for i in range(len(xs)) for j in range(i + 1, len(xs)))
for k, v in DAY[:2]:
    print(f"VCG, two contracts: {k} pays {best_total(k) - (best_total('') - v):.2f}")

assert gap >= 0.0,                                     "truth is never beaten in Vickrey"
assert best_v == 82.0 and abs(best_f - 65.6) < 0.011,  "grid best responses: 82 and 0.8 x 82"
assert abs(vick_exp(82.0, best_v) - U82) < 1e-6 and abs(fp_exp(82.0, best_f) - U82) < 1e-3, "envelope profit"
assert abs(pay_v - (82 * P(82) - U82)) < 1e-6,         "Vickrey payment by integral vs envelope m(v)"
assert abs(rev_env - rev_v) < 1e-6 and abs(rev_os - rev_v) < 1e-6, "revenue equivalence, two integrals"
assert all(abs(sim[k][0] - rev_v) < 4 * sim[k][1] for k in ("Vickrey", "first-price", "all-pay"))
assert all(abs(sim[k][0] - rev_res) < 4 * sim[k][1] for k in ("Vickrey, reserve 50", "first-price, reserve 50"))
assert abs(best_r - 82.0 * beta_r) < 0.011,            "risk-averse best response 4v/4.5"
print("ALL CHECKS PASS")
