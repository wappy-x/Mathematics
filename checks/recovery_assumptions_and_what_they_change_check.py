# Recovery assumptions -- the check behind the card.  Standard library only.
# Northwind five-year CDS quoted at 300 bp a year: premiums at each quarter end,
# protection paid at default, flat hazard, r = 5% continuous.  Each assumed
# recovery is turned into a hazard three ways: the closed-form par equation,
# legs built by brute force (a quarterly sum and Simpson's rule), and a
# simulation of default times with a hand-written random number generator.
from math import exp, log

s, r, dq, T, M = 0.03, 0.05, 0.25, 5.0, 10_000_000     # quote, rate, quarter, years, notional

def bisect(f, lo, hi):                     # root of an increasing f with f(lo) < 0 < f(hi)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return 0.5 * (lo + hi)

def par(lam, R):                           # road 1: s = (1 - R) lam F, F = (e^x - 1) / x
    x = (r + lam) * dq
    return (1 - R) * lam * (exp(x) - 1) / x

def annuity(lam):                          # road 2: premium leg per unit spread, quarter by quarter
    return sum(dq * exp(-(r + lam) * dq * j) for j in range(1, 21))

def protection(lam, R, n=4000):            # road 2: Simpson's rule on (1 - R) lam e^{-(r + lam) t}
    f = lambda t: (1 - R) * lam * exp(-(r + lam) * t)
    h = T / n
    return h / 3 * (f(0) + f(T) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n)))

def secant(f, a, b):
    for _ in range(60):
        fa, fb = f(a), f(b)
        if fb == fa: break
        a, b = b, b - fb * (b - a) / (fb - fa)
    return b

state = 20260928                           # road 3: a 64-bit linear congruential generator
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53

U = [uniform() for _ in range(200_000)]
disc = [0.0]                               # disc[j] = premium PV per unit spread for j quarters paid
for j in range(1, 21): disc.append(disc[-1] + dq * exp(-r * dq * j))

def simulate(lam, R):                      # default times tau = -ln(U) / lam
    prot = prem = died = 0.0
    for u in U:
        tau = -log(u) / lam
        if tau < T:
            died += 1; prot += (1 - R) * exp(-r * tau); prem += disc[int(tau / dq)]
        else:
            prem += disc[20]
    return died / len(U), 1e4 * prot / prem

print(f"Northwind 5y CDS at 300 bp; r = 5%; quarterly premiums; notional $10m; premium ${s * M:,.0f} a year")
print("R     hazard:formula  hazard:legs  triangle  5y default  simulated  sim spread bp  loss $m")
rows = {}
for R in (0.0, 0.4, 0.7):
    lam = bisect(lambda l: par(l, R) - s, 0.0, 1.0)
    lam2 = secant(lambda l: protection(l, R) - s * annuity(l), 0.01, 0.2)
    pd, sim = simulate(lam, R)
    rows[R] = (lam, lam2, 1 - exp(-lam * T), pd, sim)
    print(f"{R:<5.0%} {lam:14.6f} {lam2:12.6f} {s / (1 - R):9.4f} {1 - exp(-lam * T):11.4f}"
          f" {pd:10.4f} {sim:14.1f} {(1 - R) * M / 1e6:8.1f}")
print(f"house check, hazard 2%, R 40%: par {1e4 * par(0.02, 0.4):.2f} bp  legs {1e4 * protection(0.02, 0.4) / annuity(0.02):.2f} bp  annuity {annuity(0.02):.4f}")
seed = s / 0.6; F1 = (exp((r + seed) * dq) - 1) / ((r + seed) * dq); h1 = seed / F1
F2 = (exp((r + h1) * dq) - 1) / ((r + h1) * dq)
print(f"by hand, R 40%: seed {seed:.6f}  F {F1:.6f}  hazard {h1:.6f}  F again {F2:.6f}  hazard {seed / F2:.6f}")
print("chart, recovery %      " + " ".join(f"{10 * i:6d}" for i in range(10)))
print("chart, hazard % dated  " + " ".join(f"{100 * bisect(lambda l: par(l, i / 10) - s, 0, 5):6.2f}" for i in range(10)))
print("chart, hazard % triang " + " ".join(f"{100 * s / (1 - i / 10):6.2f}" for i in range(10)))
up = [(s - 0.01) * annuity(rows[R][0]) * M for R in (0.0, 0.4, 0.7)]
print(f"upfront at a 100 bp coupon, $: R 0% {up[0]:,.0f}  R 40% {up[1]:,.0f}  R 70% {up[2]:,.0f}")

# ---- recovery when the hazard is known: R = 1 - s / B(lam) ----
for lam in (0.05, 0.025):
    print(f"known hazard {lam:.3f}: triangle R {1 - s / lam:.4f}  dated R {1 - s / par(lam, 0.0):.4f}"
          f"  legs R {1 - s * annuity(lam) / protection(lam, 0.0):.4f}")

# ---- a five-year zero-coupon bond, $100 face, continuous premiums: s = (1 - R) lam ----
def closed(lam, R):                        # prices per $1 face: face, treasury, market value
    k = r + lam
    return (exp(-k * T) + R * lam * (1 - exp(-k * T)) / k,
            exp(-r * T) * (R + (1 - R) * exp(-lam * T)), exp(-(r + lam * (1 - R)) * T))

def backward(lam, R, n=20000):             # road 2: step back from maturity on a time grid
    h, k = T / n, r + lam
    stay, hit = exp(-k * h), lam / k * (1 - exp(-k * h))
    f = t = m = 1.0
    for i in range(n - 1, -1, -1):
        mid = (i + 0.5) * h
        f = stay * f + hit * R
        t = stay * t + hit * R * exp(-r * (T - mid))
        m = stay * m + hit * R * m
    return f, t, m

lam0, R0 = 0.05, 0.40
print("bond at hazard 5%, R 40%, per $100: face / treasury / market value")
print("  closed form    " + "  ".join(f"{100 * p:.4f}" for p in closed(lam0, R0)))
print("  backward steps " + "  ".join(f"{100 * p:.4f}" for p in backward(lam0, R0)))
v2 = exp(-(r + lam0 * (1 - R0)) * 3)
print(f"paid on default at year 2: face {100 * R0:.2f}  treasury {100 * R0 * exp(-r * 3):.2f}  market value {100 * R0 * v2:.2f}")
curve = lambda lam: closed(lam, 1 - 0.03 / lam)
print("chart, hazard %        " + " ".join(f"{h:6d}" for h in range(3, 16, 2)))
for j, name in enumerate(("face", "treasury", "market value")):
    print(f"chart, {name:<16}" + " ".join(f"{100 * curve(h / 100)[j]:6.2f}" for h in range(3, 16, 2)))
p0 = closed(lam0, R0)[0]
fits = [bisect(lambda l: curve(l)[0] - p, 0.03, 5.0) for p in (p0, p0 - 0.005, p0 + 0.005)]
for p, l in zip((p0, p0 - 0.005, p0 + 0.005), fits):
    print(f"joint fit, price {100 * p:.2f}: hazard {l:.4f}  recovery {1 - 0.03 / l:.4f}")
slope = (r + 0.03) * (1 - (1 + (r + lam0) * T) * exp(-(r + lam0) * T)) / (r + lam0) ** 2
print(f"face price slope along the CDS curve at 5%: {slope:.4f} per unit hazard")

# ---- what breaks ----
print(f"wrong: triangle at R 70%: hazard {s / 0.3:.4f}  5y default {1 - exp(-T * s / 0.3):.4f}")
print(f"wrong: spread read as the hazard: 5y default {1 - exp(-T * s):.4f}")
print(f"wrong: face bond priced with treasury rule: {100 * closed(lam0, R0)[1]:.2f} not {100 * p0:.2f}")

for R in (0.0, 0.4, 0.7):
    lam, lam2, pd, pds, sim = rows[R]
    assert abs(lam - lam2) < 1e-9, "closed-form hazard vs brute-force legs"
    assert abs(pd - pds) < 0.005 and abs(sim - 300) < 6, "simulation vs formula"
assert all(abs(a - b) < 1e-5 for a, b in zip(closed(lam0, R0), backward(lam0, R0))), "bond prices, two roads"
assert abs(fits[0] - lam0) < 1e-9 and abs((1 - 0.03 / fits[0]) - R0) < 1e-8, "joint fit returns the pair"
flat = [backward(h / 100, 1 - 0.03 / (h / 100))[2] for h in (3, 5, 10, 15)]
assert max(flat) - min(flat) < 1e-5 and abs(curve(0.15)[0] - curve(0.05)[0]) > 0.03, "only face recovery separates"
assert abs(par(0.02, 0.4) - protection(0.02, 0.4) / annuity(0.02)) < 1e-9 and abs(1e4 * par(0.02, 0.4) - 121.06) < 0.005 \
    and abs(annuity(0.02) - 4.1819) < 5e-5, "house contract: 121.06 bp, annuity 4.1819"
assert all(abs(s / par(l, 0.0) - s * annuity(l) / protection(l, 0.0)) < 1e-9 for l in (0.05, 0.025)), "known-hazard recovery, two roads"
assert abs((curve(lam0 + 1e-5)[0] - curve(lam0 - 1e-5)[0]) / 2e-5 - slope) < 1e-6, "slope formula vs finite difference"
print("ALL CHECKS PASS")
