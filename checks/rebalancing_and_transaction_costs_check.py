# Rebalancing and transaction costs -- the check behind the card.  Standard
# library only; nothing imported knows the answer.  A 60-40 fund has drifted
# to 65-35.  Roads: the exact sale by formula and by bisection; the one-shot
# band by formula and by grid search; the lifelong band by the cube-root rule
# and by simulating ten-year daily paths with a random generator written here.
from math import log, cos, sqrt, exp, pi

W, S = 100000.0, 65000.0                  # fund value, shares; bonds are the rest
c, w, gam, sig, r = 0.001, 0.60, 2.5, 0.20, 0.03
mu = r + gam * sig * sig * w              # excess return making 60% Merton's fraction
x0 = S / W
lam = gam * sig * sig                     # loss rate: (lam/2)(x - w)^2 per year

def sale_formula(z):                      # dollars of shares sold to land at z after the fee
    return (S - z * W) / (1.0 - c * z)

def sale_bisect(z):                       # road 2: search for the sale, no formula
    lo, hi = 0.0, S
    for _ in range(200):
        q = 0.5 * (lo + hi)
        if (S - q) / (W - c * q) > z: lo = q
        else: hi = q
    return 0.5 * (lo + hi)

def clamp(x, h): return min(w + h, max(w - h, x))

def J(z, x, kap): return 0.5 * kap * (z - w) ** 2 + c * abs(z - x)

s = w * (1 - w) * sig                     # how fast the weight wanders, per root-year
def h_cube(cc): return (3.0 * cc * s * s / (2.0 * lam)) ** (1.0 / 3.0)
def L(h): return 0.5 * lam * h * h / 3.0 + c * s * s / (2.0 * h)
h = h_cube(c)

state = 20260928                          # splitmix64 random numbers, written out
def u01():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

DAYS, YEARS, PATHS = 252, 10, 500
dt = 1.0 / DAYS
gb = exp(r * dt)
def path():                               # one ten-year path of daily share growth factors
    out = []
    for _ in range(DAYS * YEARS):
        z = sqrt(-2.0 * log(1.0 - u01())) * cos(2.0 * pi * u01())
        out.append(exp((mu - 0.5 * sig * sig) * dt + sig * sqrt(dt) * z))
    return out

def run(rule, arg, gs, tot):              # tot: turnover, cost, loss, squared deviation
    x = w
    for t, g in enumerate(gs):
        tot[2] += 0.5 * lam * (x - w) ** 2 * dt
        tot[3] += (x - w) ** 2 * dt
        x = x * g / (x * g + (1.0 - x) * gb)
        z = x
        if rule == "calendar" and (t + 1) % arg == 0: z = w
        elif rule == "threshold" and abs(x - w) > arg: z = w
        elif rule == "band": z = clamp(x, arg)
        tot[0] += abs(z - x)
        tot[1] += c * abs(z - x)
        x = z

rules = [("never rebalance", "never", 0), ("calendar, yearly", "calendar", 252),
         ("calendar, quarterly", "calendar", 63), ("calendar, monthly", "calendar", 21),
         ("threshold 5 pts, to target", "threshold", 0.05), ("band +-3.26 pts, to edge", "band", h)]
sweep = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.08]
acc = {k: [0.0] * 4 for k in [a for a, _, _ in rules] + sweep}
for p in range(PATHS):
    gs = path()
    for name, rule, arg in rules: run(rule, arg, gs, acc[name])
    for hh in sweep: run("band", hh, gs, acc[hh])
yrs = float(PATHS * YEARS)
def per(k, i): return acc[k][i] / yrs    # per year, fraction of the fund

qf, qb = sale_formula(w), sale_bisect(w)
qe, qeb = sale_formula(w + h), sale_bisect(w + h)
grid = [i / 100000.0 for i in range(40000, 80001)]
k1 = lam * 1.0                            # one-shot model: the gap is held for one year
zs = min(grid, key=lambda z: J(z, x0, k1))
print(f"fund {W:.2f}  shares {S:.2f}  bonds {W - S:.2f}  target {w:.2f}  drifted {x0:.2f}")
print(f"cost per dollar traded {c:.4f}  gamma {gam:.2f}  sigma {sig:.2f}  r {r:.2f}  mu {mu:.2f}")
print(f"gamma sigma^2 {lam:.4f}  Merton fraction (mu-r)/(gamma sigma^2) {(mu - r) / lam:.4f}")
print(f"paths {PATHS}  years {YEARS}  days per year {DAYS}")
print(f"loss rate at 65%, per $100,000 per year {W * 0.5 * lam * (x0 - w) ** 2:9.2f}")
print(f"sell to 60%: formula {qf:10.2f}  bisection {qb:10.2f}  fee {c * qf:6.2f}")
print(f"one-shot kappa {k1:.4f}  half-width c/kappa {c / k1:.4f}  clamp {clamp(x0, c / k1):.5f}  grid {zs:.5f}")
for lab, z in (("wait", x0), ("to target", w), ("to edge 61%", clamp(x0, c / k1))):
    print(f"  one-shot loss, {lab:<12} per $100,000 {W * J(z, x0, k1):8.2f}")
print(f"weight's spread s = w(1-w)sigma {s:.4f}  w^2(1-w)^2 {(w * (1 - w)) ** 2:.4f}  h^3 {h ** 3:.7f}")
hL = min((i / 100000.0 for i in range(100, 20001)), key=L)   # road 2 to h: brute-force minimum
print(f"lifelong half-width h {h:.5f}  brute-force minimum of L {hL:.5f}")
print(f"band {100 * (w - h):.2f}% to {100 * (w + h):.2f}%")
print(f"sell to edge {100 * (w + h):.2f}%: formula {qe:9.2f}  bisection {qeb:9.2f}  fee {c * qe:5.2f}")
print(f"formula at h: turnover {s * s / (2 * h):.4f}  mean sq dev {h * h / 3:.6f}  $/yr {W * L(h):.2f}")
bh = acc[rules[-1][0]]
print(f"simulated at h: turnover {bh[0] / yrs:.4f}  mean sq dev {bh[3] / yrs:.6f}  $/yr {W * (bh[1] + bh[2]) / yrs:.2f}")
print(f"simulated / formula: turnover {bh[0] / yrs / (s * s / (2 * h)):.3f}  mean sq dev {bh[3] / yrs / (h * h / 3):.3f}")
print("what breaks, $ per year per $100,000 (formula L):")
for lab, hh in (("one-shot width c/kappa", c / k1), ("sigma in place of s", (3 * c / (2 * gam)) ** (1 / 3)),
                ("cost counted twice", h_cube(2 * c))):
    print(f"  {lab:<24} h {hh:.4f}  {W * L(hh):6.2f}   right {W * L(h):.2f}")
print("rules over 10 years, daily prices, per $100,000 per year:")
print(f"  {'rule':<28}{'turnover':>9}{'cost':>8}{'drift':>8}{'total':>8}")
for name, _, _ in rules:
    print(f"  {name:<28}{per(name, 0):9.4f}{W * per(name, 1):8.2f}{W * per(name, 2):8.2f}"
          f"{W * (per(name, 1) + per(name, 2)):8.2f}")
print("band sweep, simulated, per $100,000 per year:")
for hh in sweep:
    print(f"  h {100 * hh:4.1f} pts  cost {W * per(hh, 1):6.2f}  drift {W * per(hh, 2):6.2f}"
          f"  total {W * (per(hh, 1) + per(hh, 2)):6.2f}  formula {W * L(hh):6.2f}")
def h_of(cc, g, p): return (1.5 * cc * (p * (1 - p)) ** 2 / g) ** (1.0 / 3.0)
for lab, cc, g, p in (("c = 0.0001", 0.0001, gam, w), ("c = 0.01", 0.01, gam, w),
                      ("gamma = 5", c, 5.0, w), ("target 0.50", c, gam, 0.5)):
    v = h_of(cc, g, p)
    print(f"try: {lab:<12} h {v:.4f}  band {100 * (p - v):.2f}% to {100 * (p + v):.2f}%")
print(f"ten times the cost widens the band by {h_of(0.01, gam, w) / h:.3f}")
pol = [0.50 + 0.02 * i for i in range(11)]
print("chart, weight before " + " ".join(f"{100 * x:5.0f}" for x in pol))
print("chart, band to edge  " + " ".join(f"{100 * clamp(x, h):5.2f}" for x in pol))
print("chart, threshold     " + " ".join(f"{100 * (w if abs(x - w) > 0.05 + 1e-12 else x):5.2f}" for x in pol))
best = min(sweep, key=lambda k: per(k, 1) + per(k, 2))
tots = {n: per(n, 1) + per(n, 2) for n, _, _ in rules}
assert abs(qf - qb) < 1e-6 and abs(qe - qeb) < 1e-6,   "exact sale: formula vs bisection"
assert abs(hL - h) < 2e-5,                             "cube-root rule vs brute-force minimum of L"
assert abs(zs - clamp(x0, c / k1)) < 2e-5,             "one-shot band: clamp vs grid search"
assert abs(bh[0] / yrs / (s * s / (2 * h)) - 1) < 0.15, "turnover: walls vs simulation"
assert abs(bh[3] / yrs / (h * h / 3) - 1) < 0.20,      "time spread evenly: h^2/3 vs simulation"
assert abs(best - h) <= 0.011,                         "simulated best width near the cube-root rule"
assert all(tots[rules[-1][0]] < tots[n] for n, _, _ in rules[:-1]), "band beats every other rule"
print("ALL CHECKS PASS")
