# Timing and in-arrears adjustments -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF, the integrator and the
# random numbers are written out below.
from math import exp, log, sqrt, cos, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height at x

def N(x):                                                          # bell-curve area left of x, by its series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * abs(total):
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total

def simpson(f, a, b, n):                                           # area under f, thin slices
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

F, dl, T, vol, r, notional = 0.06, 0.25, 5.0, 0.20, 0.05, 10_000_000.0
P0T = exp(-r * T)                 # today's price of $1 paid at the fixing date T
P0U = P0T / (1.0 + dl * F)        # today's price of $1 paid at U = T + 0.25; the curve's forward is F
BP = 1e4

# ---- the three-state stand-in: the fixing is 2%, 6% or 10% with odds 1/4, 1/2, 1/4 (U-bond odds) ----
Ls, ps = (0.02, 0.06, 0.10), (0.25, 0.5, 0.25)
mean3 = sum(p * L for p, L in zip(ps, Ls))
var3 = sum(p * (L - mean3) ** 2 for p, L in zip(ps, Ls))
adj3_var = dl * var3 / (1.0 + dl * mean3)                         # road 1: the variance formula
w3 = [p * (1.0 + dl * L) for p, L in zip(ps, Ls)]                 # road 2: re-weight each state by 1 + dl L
q3 = [w / sum(w3) for w in w3]
adj3_rw = sum(q * L for q, L in zip(q3, Ls)) - mean3

# ---- the lognormal fixing: L_T = F exp(-vol^2 T / 2 + vol sqrt(T) z) under the U-bond odds ----
def L_of(z, T=T, vol=vol, F=F): return F * exp(-0.5 * vol * vol * T + vol * sqrt(T) * z)
def adj_closed(F=F, vol=vol, T=T):                                 # road 1: closed form
    return dl * F * F * (exp(vol * vol * T) - 1.0) / (1.0 + dl * F)
def weighted(W, T=T):                                              # road 2: E[L W] / E[W] - F by Simpson
    num = simpson(lambda z: L_of(z, T) * W(L_of(z, T)) * phi(z), -10.0, 10.0, 4000)
    den = simpson(lambda z: W(L_of(z, T)) * phi(z), -10.0, 10.0, 4000)
    return num / den - F
adj_simp = weighted(lambda L: 1.0 + dl * L)
def caplet(K):                                                     # undiscounted Black caplet on L_T
    if K <= 0.0: return F
    s = vol * sqrt(T); d1 = (log(F / K) + 0.5 * s * s) / s
    return F * N(d1) - K * N(d1 - s)
EL2 = 2.0 * simpson(caplet, 0.0, 1.2, 6000)                        # road 3: L^2 = 2 x (all caplets, every strike)
adj_cap = dl * (EL2 - F * F) / (1.0 + dl * F)

state = 20260928                                                   # road 4: Monte Carlo, home-made numbers
def unif():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2.0 ** 53
draws = []
for _ in range(100_000):
    z = sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
    draws += [L_of(z), L_of(-z)]                                   # each draw with its mirror image
def mc(W):                                                         # in-arrears average minus plain average, same paths
    sLW = sW = 0.0
    for L in draws:
        w = W(L); sLW += L * w; sW += w
    return sLW / sW - sum(draws) / len(draws)
adj_mc = mc(lambda L: 1.0 + dl * L)

# ---- money: $10m notional, one quarter ----
pv_via_adj = notional * dl * P0T * adj_closed()                    # extra fixed rate, paid at T
var_ln = F * F * (exp(vol * vol * T) - 1.0)
pv_rolled = notional * P0U * dl * dl * var_ln                      # the extra dl^2 L^2 at U, valued with U bonds

# ---- what breaks ----
hull = dl * F * F * vol * vol * T / (1.0 + dl * F)                 # e^x - 1 replaced by x
no_denominator = dl * var_ln                                       # forgot 1 / (1 + dl F)
wrong_T = adj_closed(T=T + dl)                                     # used the payment date U, not the fixing date

rows = [
    ("three-state mean fixing, %", 100 * mean3), ("three-state variance", var3),
    ("three-state T-odds for 2%, 6%, 10%", q3[0]), ("  6%", q3[1]), ("  10%", q3[2]),
    ("three-state adj, variance formula, bp", BP * adj3_var), ("three-state adj, re-weighted odds, bp", BP * adj3_rw),
    ("1 + dl F", 1.0 + dl * F), ("vol^2 T", vol * vol * T), ("lognormal variance of L_T", var_ln), ("e^(vol^2 T) - 1", exp(vol * vol * T) - 1.0),
    ("1 adj, closed form, bp", BP * adj_closed()), ("2 adj, Simpson integral, bp", BP * adj_simp),
    ("3 adj, strip of caplets, bp", BP * adj_cap), ("4 adj, Monte Carlo 200,000, bp", BP * adj_mc),
    ("in-arrears fair rate, %", 100 * (F + adj_closed())),
    ("P(0,T)", P0T), ("P(0,U)", P0U),
    ("extra PV via the adjustment, $", pv_via_adj), ("extra PV by rolling to U, $", pv_rolled),
    ("wrong: no adjustment, bp", 0.0), ("wrong: vol^2 T for e^(vol^2 T) - 1, bp", BP * hull),
    ("wrong: forgot 1/(1 + dl F), bp", BP * no_denominator), ("wrong: T = 5.25 in the variance, bp", BP * wrong_T),
    ("greek: vol 21% instead of 20%, bp", BP * adj_closed(vol=0.21)), ("greek: F 6.01% instead of 6%, bp", BP * adj_closed(F=0.0601)),
    ("try: vol 40%, bp", BP * adj_closed(vol=0.40)), ("try: F 3%, bp", BP * adj_closed(F=0.03)),
]
for name, v in rows:
    print(f"{name:<40} {v:>16.6f}")

print("payoff chart, extra $ at U for fixings 2..10%: " + ", ".join(f"{notional * dl * dl * L * L:.2f}" for L in (0.02, 0.04, 0.06, 0.08, 0.10)))
def bp(v): return 0.0 if abs(v) < 5e-13 else BP * v                 # basis points, with no "-0.0000"

print("\nyears to fixing: adjustment bp, closed form | Simpson")
for Tl in (5.0, 4.0, 3.0, 2.0, 1.0, 0.25):
    print(f"  {Tl:>4.2f}   {bp(adj_closed(T=Tl)):.4f} | {bp(weighted(lambda L: 1.0 + dl * L, T=Tl)):.4f}")

def moments(y, n=20):                                              # E[L W]/E[W] - F for W = 1/(1 + y L), no integral:
    mom = lambda k: F ** k * exp(0.5 * k * (k - 1) * vol * vol * T)  # E[L^k] = F^k e^(k(k-1) vol^2 T / 2)
    return sum((-y) ** k * mom(k + 1) for k in range(n)) / sum((-y) ** k * mom(k) for k in range(n)) - F

print("\npayment delay after T, months: adjustment bp, Simpson | Monte Carlo")
sweep, sweep_mc = [], []
for m in range(7):
    x = dl - m / 12.0                                              # years from the payment date D on to U
    W = (lambda L, x=x: 1.0 + x * L) if x >= 0 else (lambda L, x=x: 1.0 / (1.0 - x * L))
    a = weighted(W)                                                # early: roll forward to U; late: discount back
    if x >= 0: assert abs(a - x * var_ln / (1.0 + x * F)) < 1e-12 # closed form x Var / (1 + x F)
    else: assert abs(a - moments(-x)) < 1e-12                      # late: series in lognormal moments
    sweep.append(bp(a)); sweep_mc.append(bp(mc(W)))
    print(f"  {m}   {sweep[-1]:.4f} | {sweep_mc[-1]:.4f}")
print("chart: " + ", ".join(f"{v:.2f}" for v in sweep))

assert abs(adj3_var - adj3_rw) < 1e-15                             # variance formula = re-weighted odds
assert abs(adj_closed() - adj_simp) < 1e-12                        # closed form = integral
assert abs(adj_closed() - adj_cap) < 1e-9                          # closed form = strip of caplets
assert abs(adj_closed() - adj_mc) < 0.05 / BP                      # closed form = simulation, within noise
assert abs(pv_via_adj - pv_rolled) < 1e-6                          # two money routes agree
assert abs(sweep[6] - sweep_mc[6]) < 0.05                          # late payment: integral = simulation
print("all checks passed")
