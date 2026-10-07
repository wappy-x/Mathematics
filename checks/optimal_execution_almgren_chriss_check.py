# Almgren-Chriss optimal execution -- the check behind the card.  Standard library only.
# Sell 100,000 Acme shares ($100, 1,000,000 traded a day) over one day in 13 half-hour slices.
# Roads: the sinh formula; coordinate descent on E + lambda V; a Monte Carlo of the trades
# themselves; random nudges that must never do better; the frontier's slope equal to -lambda.
from math import sqrt, sinh, acosh, log, cos, pi, exp, prod

X, N, T, S0 = 100_000.0, 13, 1.0, 100.0  # shares, slices, days, starting price
tau = T / N                              # one slice, in days
sig = S0 * 0.20 / sqrt(252.0)            # $ per share per sqrt(day): 20% a year on a $100 stock
eps, gam, eta = 0.01, 2e-7, 2e-6         # half-spread; permanent and temporary impact slopes
eta_t = eta - 0.5 * gam * tau            # temporary slope net of the permanent correction
LAM = 1e-5                               # the risk-averse trader: dollars of cost per dollar^2 of variance

def EV(x, s=sig, g=gam, e=eps, et=eta_t):          # expected cost and variance of a schedule
    n = [x[k - 1] - x[k] for k in range(1, N + 1)]
    E = 0.5 * g * X * X + e * X + et / tau * sum(v * v for v in n)
    V = s * s * tau * sum(v * v for v in x[1:])
    return E, V

def U(x, lam=LAM):
    E, V = EV(x)
    return E + lam * V

def kappas(lam, s=sig, et=eta_t):
    kt = sqrt(lam * s * s / et)                      # continuous-time urgency, per day
    return kt, acosh(1.0 + 0.5 * (kt * tau) ** 2) / tau  # and its discrete version

def closed_form(lam, s=sig, et=eta_t, discrete=True):  # road 1: holdings X sinh(k(T-t))/sinh(kT)
    if lam == 0: return [X * (1 - k / N) for k in range(N + 1)]
    kt, kap = kappas(lam, s, et)
    if not discrete: kap = kt
    return [X * sinh(kap * (T - k * tau)) / sinh(kap * T) for k in range(N + 1)]

def coordinate_descent(lam):   # road 2: set each holding to its best value given its neighbours, repeat
    x = [X * (1 - k / N) for k in range(N + 1)]
    a, b = eta_t / tau, lam * sig * sig * tau
    for sweep in range(1, 100001):
        change = 0.0
        for k in range(1, N):
            new = a * (x[k - 1] + x[k + 1]) / (2 * a + b)
            change, x[k] = max(change, abs(new - x[k])), new
        if change < 1e-9: return x, sweep

M64, st = (1 << 64) - 1, [20260928]
def uniform():                                      # splitmix64, written out
    st[0] = (st[0] + 0x9E3779B97F4A7C15) & M64
    z = st[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def normal(): return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())  # Box-Muller

def simulate(x, paths=200000, noise=1.0):  # road 3: trade the schedule against random prices, add up the cash
    n = [x[k - 1] - x[k] for k in range(1, N + 1)]
    tot = tot2 = 0.0
    for _ in range(paths):
        S, cash = S0, 0.0
        for k in range(N):
            cash += n[k] * (S - eps - eta * n[k] / tau)          # half-spread and temporary impact
            S += noise * sig * sqrt(tau) * normal() - gam * n[k]  # the price wanders, keeps the dent
        short = X * S0 - cash
        tot, tot2 = tot + short, tot2 + short * short
    m = tot / paths
    return m, sqrt(tot2 / paths - m * m)

def fmt(x): return " ".join(f"{v:.0f}" for v in x)
kt, kap = kappas(LAM)
x_opt, x_cd = closed_form(LAM), coordinate_descent(LAM)
E, V = EV(x_opt)
print(f"sigma {sig:.6f}  eta_tilde (millionths) {eta_t * 1e6:.6f}  kappa_tilde {kt:.6f}  kappa {kap:.6f}")
print(f"sigma^2 {sig * sig:.6f}  kappa_tilde^2 {kt * kt:.6f}  cosh(kappa*tau) {1 + 0.5 * (kt * tau) ** 2:.6f}")
print(f"kappa*tau {kap * tau:.6f}  holdings fall by e^-kappa*tau = {exp(-kap * tau):.6f} a slice at first")
for lab, lam in (("0", 0.0), ("1e-5", LAM), ("1e-4", 1e-4)):
    print(f"holdings lambda={lab}: {fmt(closed_form(lam))}")
print("trades lambda=1e-5:", fmt([x_opt[k - 1] - x_opt[k] for k in range(1, N + 1)]))
gap = max(abs(a - b) for a, b in zip(x_opt, x_cd[0]))
print(f"road 2 coordinate descent: {x_cd[1]} sweeps, largest gap to sinh schedule {gap:.9f} shares")
perm, spread = 0.5 * gam * X * X, eps * X
print(f"E parts: permanent {perm:.2f}  spread {spread:.2f}  temporary {E - perm - spread:.2f}")
print(f"optimal  E {E:.2f}  sd {sqrt(V):.2f}  lambda*V {LAM * V:.2f}  U {E + LAM * V:.2f}")
m0 = simulate(x_opt, paths=1, noise=0.0)[0]
print(f"road 3, the same trades with the noise switched off: shortfall {m0:.2f}")
m, sd = simulate(x_opt)
print(f"road 3 Monte Carlo, 200000 days: mean {m:.2f}  sd {sd:.2f}  (standard error of mean {sd / sqrt(200000):.2f})")
worse, best = 0, float("inf")
for _ in range(2000):                   # road 4: nudge every interior holding by up to 2,000 shares
    y = [x_opt[0]] + [x_opt[k] + 4000.0 * (uniform() - 0.5) for k in range(1, N)] + [0.0]
    worse, best = worse + (U(y) > U(x_opt)), min(best, U(y))
print(f"road 4: {worse} of 2000 nudged schedules cost more; cheapest is {best - U(x_opt):.2f} above the optimum")
h = 1e-8
(E1, V1), (E2, V2) = EV(closed_form(LAM - h)), EV(closed_form(LAM + h))
slope = (E2 - E1) / (V2 - V1)
print(f"road 5: frontier slope dE/dV at lambda=1e-5, divided by -lambda: {slope / -LAM:.6f}")
a, b = eta_t / tau, LAM * sig * sig * tau
D0, D1, ok = 1.0, 2 * (2 * a + b), True  # leading minors of the Hessian, which is tridiagonal
for k in range(2, N):
    D0, D1 = D1, 2 * (2 * a + b) * D1 - 4 * a * a * D0
    ok = ok and D1 > 0
print(f"smallest Hessian eigenvalue (millionths) {(2 * a * (2 - 2 * cos(pi / N)) + 2 * b) * 1e6:.6f}; leading minors positive: {'yes' if ok else 'no'}")

def lam_for_sd(target):                 # sd falls as lambda rises: bisect on log lambda
    lo, hi = log(1e-10), log(1e-2)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if sqrt(EV(closed_form(exp(mid)))[1]) > target else (lo, mid)
    return exp(lo)
E0, V0 = EV(closed_form(0.0))
print(f"frontier end, sell evenly: E {E0:.2f}  sd {sqrt(V0):.2f}")
for t in range(20000, 65001, 5000):
    L = lam_for_sd(t)
    print(f"frontier sd {t}  lambda (x1e-5) {L * 1e5:.4f}  E {EV(closed_form(L))[0]:.0f}")
print(f"versus selling evenly: E +{E - E0:.2f}  sd -{sqrt(V0) - sqrt(V):.2f}  U saved {E0 + LAM * V0 - E - LAM * V:.2f}")
print(f"first step off the even end, sd {sqrt(V0):.0f} -> 65000: E +{EV(closed_form(lam_for_sd(65000)))[0] - E0:.2f}")

def report(name, x):
    e, v = EV(x)
    print(f"{name:<34} E {e:>10.2f}  sd {sqrt(v):>9.2f}  U {e + LAM * v:>10.2f}")
report("optimal", x_opt)
report("wrong: sell evenly, ignore risk", closed_form(0.0))
report("wrong: sell it all in slice one", [X] + [0.0] * N)
report("wrong: sigma per year as per day", closed_form(LAM, s=S0 * 0.20))
report("wrong: continuous kappa", closed_form(LAM, discrete=False))
report("wrong: eta in place of eta_tilde", closed_form(LAM, et=eta))
for name, kw, et in (("try: sigma doubled", {"s": 2 * sig}, eta_t), ("try: eta halved", {}, 0.5 * eta - 0.5 * gam * tau),
                     ("try: gamma doubled", {"g": 2 * gam}, eta - gam * tau), ("try: eps doubled", {"e": 2 * eps}, eta_t)):
    x = closed_form(LAM, s=kw.get("s", sig), et=et)
    e, v = EV(x, et=et, **kw)
    print(f"{name:<20} E {e:.2f}  sd {sqrt(v):.2f}  held at 10:30 {x[2]:.0f}")

assert gap < 1e-3                                   # sinh formula and coordinate descent agree
assert abs(m0 - E) < 1e-6                                # the trades, noise off, cost exactly E
assert abs(m - E) < 4 * sd / sqrt(200000)                # the trades cost, on average, what E says
assert abs(sd / sqrt(V) - 1) < 0.01                      # and spread as widely as V says
assert worse == 2000                                # no nudge beats the optimum
assert abs(slope / -LAM - 1) < 1e-4                 # lambda is the price of variance on the frontier
assert ok and abs(prod(2 * a * (2 - 2 * cos(j * pi / N)) + 2 * b for j in range(1, N)) / D1 - 1) < 1e-9  # eigenvalues vs determinant
assert min(U(closed_form(0.0)), U(closed_form(LAM, s=S0 * 0.20)), U(closed_form(LAM, discrete=False)), U(closed_form(LAM, et=eta))) > U(x_opt)  # every mistake scores worse
