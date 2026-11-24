# Caplets on compounded SOFR -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the normal CDF is the Taylor series of erf written out,
# the integrals are Simpson's rule, the random numbers come from a xorshift generator.
from math import log, sqrt, exp, pi, cos, sin

def N(x):                                            # bell-curve area left of x (erf series)
    if abs(x) > 8.0: return 0.0 if x < 0 else 1.0
    y = x / sqrt(2.0); term = y; s = y; n = 0
    while abs(term) > 1e-17:
        n += 1; term *= -y * y / n; s += term / (2 * n + 1)
    return 0.5 + s / sqrt(pi)

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def black(F, K, sig, T):                             # caplet per unit of rate, before discounting
    v = sig * sqrt(T); d1 = (log(F / K) + 0.5 * v * v) / v
    return F * N(d1) - K * N(d1 - v)

def bachelier(F, K, sn, T):                          # normal model: m N(d) + s phi(d)
    s = sn * sqrt(T); d = (F - K) / s
    return (F - K) * N(d) + s * phi(d)

def simpson(f, a, b, n=2000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def show(label, x, d=7): print(f"{label:<44}{x:>14.{d}f}")

F = K = 0.05; sig = 0.30; Ts = 1.75; Te = 2.0; tau = Te - Ts; notional = 10_000_000; days = 63
g = lambda t: 1.0 if t <= Ts else max(Te - t, 0.0) / tau   # volatility shape: flat, then a straight fall

# Road 1: the one-third rule in closed form.  Road 2: Simpson's rule on the squared shape.
T_fwd = Ts; T_bwd = Ts + tau / 3.0
T_simp = simpson(lambda t: g(t) ** 2, 0.0, Ts) + simpson(lambda t: g(t) ** 2, Ts, Te)
# Road 3: brute force.  Average 63 daily rates, rate j set at the start of day j by a random walk
# (end = 1: set at the end of day j); variance of the average = Ts + (1/n^2) * sum of min(j, k) * h.
def fixings_time(n, end=0):
    h = tau / n; r = range(end, n + end); return Ts + sum(min(j, k) * h for j in r for k in r) / (n * n)
T_day = fixings_time(days); T_end = fixings_time(days, 1)
assert abs(T_simp - T_bwd) < 1e-9 and abs(T_day - (Ts + tau * (days - 1) * (2 * days - 1) / (6 * days * days))) < 1e-12
assert abs(T_end - (Ts + tau * (days + 1) * (2 * days + 1) / (6 * days * days))) < 1e-12 and T_day < T_bwd < T_end
assert abs(fixings_time(1) - T_fwd) < 1e-15 and abs(fixings_time(400) - T_bwd) < 5e-4
show("variance time, forward-looking (years)", T_fwd, 6)
show("variance time, Ts + tau/3 (years)", T_bwd, 6)
show("variance time, Simpson on g squared", T_simp, 6)
show("variance time, 63 daily fixings", T_day, 6)
show("variance time, 63 fixings set at day end", T_end, 6)
for n in (1, 3, 13): show(f"variance time, {n} fixings", fixings_time(n), 6)
show("share of variance inside the period, %", 100 * (tau / 3) / T_bwd, 2)
show("log-sd still to come at Ts", sig * sqrt(tau / 3), 6)
show("rate move of one sd at Ts, % points", 100 * F * sig * sqrt(tau / 3), 4)

# Prices per unit notional, before discounting.  Road 4: Simpson over the lognormal, no N.
p_fwd = tau * black(F, K, sig, T_fwd); p_bwd = tau * black(F, K, sig, T_bwd)
v = sig * sqrt(T_bwd); kink = (log(K / F) + 0.5 * v * v) / v      # payoff starts above the kink
p_int = tau * simpson(lambda z: (F * exp(-0.5 * v * v + v * z) - K) * phi(z), kink, 10.0, 8000)
assert abs(p_int - p_bwd) < 1e-10 and abs(p_bwd / p_fwd - 1 - 0.0232) < 1e-3
for lab, T in (("forward", T_fwd), ("backward", T_bwd)):
    sd = sig * sqrt(T); d1 = (log(F / K) + 0.5 * sd * sd) / sd
    show(f"sd of log rate, {lab}", sd, 6); show(f"d1, {lab}", d1, 6); show(f"d2, {lab}", d1 - sd, 6)
    show(f"N(d1), {lab}", N(d1), 6)
show("Black caplet, forward-looking", p_fwd)
show("Black caplet, backward-looking", p_bwd)
show("Black caplet, backward, Simpson", p_int)
show("Black caplet, 63 daily fixings", tau * black(F, K, sig, T_day))
show("Black uplift, %", 100 * (p_bwd / p_fwd - 1), 2)
show("on $10m, forward-looking, $", notional * p_fwd, 2)
show("on $10m, backward-looking, $", notional * p_bwd, 2)
show("on $10m, difference, $", notional * (p_bwd - p_fwd), 2)

# Bachelier: the normal volatility that matches the forward-looking price, then the one-third clock.
sN = p_fwd / tau * sqrt(2 * pi / T_fwd)              # at the money: price = tau * sN * sqrt(T / 2 pi)
q_fwd = tau * bachelier(F, K, sN, T_fwd); q_bwd = tau * bachelier(F, K, sN, T_bwd)
assert abs(q_fwd - p_fwd) < 1e-12 and abs(q_bwd / q_fwd - sqrt(T_bwd / T_fwd)) < 1e-12
show("normal volatility matched, bp", 1e4 * sN, 2)
show("Bachelier caplet, forward-looking", q_fwd)
show("Bachelier caplet, backward-looking", q_bwd)
show("Bachelier uplift, %", 100 * (q_bwd / q_fwd - 1), 2)

# Road 5: Monte Carlo of the rate itself, one shock a day; during day j its log-volatility is
# sig times the share of days still unset.  Antithetic pairs; no variance formula used.
state = 88172645463325252
def uniform():
    global state
    state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 7; state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
    return ((state >> 11) + 0.5) / 9007199254740992.0
h = tau / days; vols = [sig * sqrt(Ts)] + [sig * (days - j) / days * sqrt(h) for j in range(1, days + 1)]
drift = -0.5 * sum(s * s for s in vols); pairs = 100_000; total = 0.0; total2 = 0.0
for _ in range(pairs):
    x = drift; y = drift
    for k in range(0, len(vols), 2):
        r = sqrt(-2.0 * log(uniform())); a = 2.0 * pi * uniform()
        x += vols[k] * r * cos(a); y -= vols[k] * r * cos(a)
        if k + 1 < len(vols): x += vols[k + 1] * r * sin(a); y -= vols[k + 1] * r * sin(a)
    pay = 0.5 * tau * (max(F * exp(x) - K, 0.0) + max(F * exp(y) - K, 0.0)); total += pay; total2 += pay * pay
mc = total / pairs; se = sqrt((total2 / pairs - mc * mc) / pairs)
assert abs(mc - tau * black(F, K, sig, T_day)) < 3 * se and abs(mc - p_fwd) > 3 * se
show("Monte Carlo caplet, 63 daily shocks", mc); show("Monte Carlo standard error", se)

# What breaks, and the experiments on the card.
show("wrong: full vol to the period end", tau * black(F, K, sig, Te))
show("wrong: average the vol, Ts + tau/2", tau * black(F, K, sig, Ts + tau / 2))
show("wrong: discount D(Ts), overprice %", 100 * tau * F, 2)      # D(Ts) / D(Te) = 1 + tau F
show("wrong: discount D(Ts), in D(Te) units", (1 + tau * F) * p_bwd)
show("try: first caplet, 0.25 to 0.5, fwd", tau * black(F, K, sig, 0.25))
show("try: first caplet, 0.25 to 0.5, bwd", tau * black(F, K, sig, 0.25 + tau / 3))
show("try: period starting today, bwd", tau * black(F, K, sig, tau / 3))
show("try: six-month period 1.75 to 2.25, bwd", 0.5 * black(F, K, sig, Ts + 0.5 / 3))
show("try: six-month period, fwd", 0.5 * black(F, K, sig, Ts))
times = [0.25 * i for i in range(8)] + [1.8125, 1.875, 1.9375, 2.0]
print("chart, time    ", " ".join(f"{t:g}" for t in times))
print("chart, term vol", " ".join(f"{100 * sig * (t <= Ts):g}" for t in times))
print("chart, sofr vol", " ".join(f"{100 * sig * g(t):g}" for t in times))
cum = [Ts + simpson(lambda t: g(t) ** 2, Ts, u) for u in times[7:]]
print("moves, var time", " ".join(f"{c:.6f}" for c in cum))
print("moves, added   ", " ".join(f"{b - a:.6f}" for a, b in zip(cum, cum[1:])))
print("ALL CHECKS PASS")
