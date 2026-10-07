# Kelly criterion -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the search, the log series, the random
# numbers, the ruin sums and the integral are all written out below.
from math import log, exp, sqrt, pi

p, q, b = 0.55, 0.45, 1.0                      # a 55% coin paying even odds

def g(f):                                      # expected log growth per bet
    return p * log(1 + b * f) + q * log(1 - f)

def ln_series(x):                              # ln x = 2(z + z^3/3 + ...), z = (x-1)/(x+1)
    z = (x - 1) / (x + 1)
    return 2 * sum(z ** (2 * k + 1) / (2 * k + 1) for k in range(40))

def golden_max(fn, lo, hi):                    # road 2: search the hill, no calculus
    r = (sqrt(5) - 1) / 2
    for _ in range(200):
        a, c = hi - r * (hi - lo), lo + r * (hi - lo)
        if fn(a) < fn(c): lo = a
        else: hi = c
    return (lo + hi) / 2

def median_wins(n):                            # exact binomial median, summed in logs
    lp, best = [0.0], 0.0
    for k in range(n):
        lp.append(lp[-1] + log((n - k) / (k + 1)) + log(p / q))
    top = max(lp); w = [exp(v - top) for v in lp]; tot = sum(w); run = 0.0
    for k in range(n + 1):
        run += w[k] / tot
        if run >= 0.5: return k

def splitmix(state):                           # road 3's random numbers, same in Rust
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def chance_ever_below(f, x=0.5, horizon=4000):  # exact: sum the surviving paths bet by bet
    up, dn, bar, alive, hit = log(1 + b * f), log(1 - f), log(x), [1.0], 0.0
    for n in range(1, horizon + 1):
        new = [0.0] * (n + 1)
        for k, m in enumerate(alive):
            new[k + 1] += p * m; new[k] += q * m
        for k in range(n + 1):
            if new[k] > 0 and k * up + (n - k) * dn <= bar: hit += new[k]; new[k] = 0.0
        alive = new
    return hit

def brownian_ever_below(f, x=0.5):            # approximation: log wealth as drift plus noise
    s2 = p * q * log((1 + b * f) / (1 - f)) ** 2
    return min(1.0, exp(-2 * g(f) * log(1 / x) / s2))

# ---- the coin ----
f_star = p - q / b
f_gold = golden_max(g, 0.0, 0.99)
n = 1000; k_med = median_wins(n)
grid = [i / 1000 for i in range(300)]
f_med = max(grid, key=lambda f: k_med * log(1 + b * f) + (n - k_med) * log(1 - f))
g_log, g_ser = g(f_star), p * ln_series(1 + b * f_star) + q * ln_series(1 - f_star)
state, paths, wins = 20260928, 2000, []
for _ in range(paths):
    k = 0
    for _ in range(n):
        state, u = splitmix(state)
        k += u < p
    wins.append(k)
g_sim = sum(k * log(1.1) + (n - k) * log(0.9) for k in wins) / (paths * n)
se = sqrt(p * q) * log(1.1 / 0.9) / sqrt(paths * n)
rows = [("f* road 1, formula p - q/b", f_star), ("f* road 2, golden-section search", f_gold),
        ("f* road 3, best median, 1000 bets", f_med), ("median wins in 1000 bets", k_med),
        ("ln(1 + b f*), a win", log(1 + b * f_star)), ("ln(1 - f*), a loss", log(1 - f_star)),
        ("p ln(1 + b f*)", p * log(1 + b * f_star)), ("q ln(1 - f*)", q * log(1 - f_star)),
        ("g(f*) per bet, library log", g_log), ("g(f*) per bet, own log series", g_ser),
        ("g(f*) simulated, 2000 x 1000 bets", g_sim), ("  its standard error", se),
        ("bets to double at f*, ln 2 / g", log(2) / g_log),
        ("simple mean return per bet at f*", f_star * (b * p - q)),
        ("mean wealth x after 1000 bets", exp(n * log(1 + f_star * (b * p - q)))),
        ("median wealth x after 1000 bets", exp(k_med * log(1 + b * f_star) + (n - k_med) * log(1 - f_star))),
        ("$100, win then loss, full Kelly", 100 * (1 + b * f_star) * (1 - f_star)),
        ("$100, win then loss, half Kelly", 100 * (1 + b * f_star / 2) * (1 - f_star / 2))]
for name, v in rows: print(f"{name:<36} {v:>16.12f}")

# ---- fractional Kelly: c times the Kelly stake ----
print()
print(f"{'c':>5} {'stake':>6} {'g x1000':>9} {'of best':>8} {'c(2-c)':>7} {'spread':>7} {'halve,exact':>11} {'approx':>7} {'0.5^(2/c-1)':>11}")
frac = {}
for c in (0.25, 0.5, 1.0, 1.5, 2.0):
    f = c * f_star
    frac[c] = (g(f), chance_ever_below(f), brownian_ever_below(f))
    spread = sqrt(p * q) * log((1 + b * f) / (1 - f))
    print(f"{c:>5.2f} {f:>6.3f} {1000 * g(f):>9.4f} {g(f) / g_log:>8.4f} {c * (2 - c):>7.4f} {spread:>7.4f} {frac[c][1]:>11.3f} {frac[c][2]:>7.3f} {min(1.0, 0.5 ** (2 / c - 1)):>11.3f}")

# ---- what breaks ----
print()
print(f"{'wrong: bet it all, survive 20 bets':<36} {p ** 20:>16.12f}")
print(f"{'wrong: believe 60%, stake 0.20, g':<36} {g(0.20):>16.12f}")
print(f"{'wrong: mean wealth, 20 bets all in':<36} {(1 + (b * p - q)) ** 20:>16.12f}")
print("chart f      " + " ".join(f"{i * 0.02:5.2f}" for i in range(13)))
print("chart g x1000" + " ".join(f"{1000 * g(i * 0.02):5.2f}" for i in range(13)))

# ---- the saver: deposit 4%, fund mean 8%, spread 15%, rebalanced daily ----
r, mu, sig = 0.04, 0.08, 0.15
F = (mu - r) / sig ** 2
G = lambda f: r + f * (mu - r) - 0.5 * f * f * sig * sig
def G_quad(f, dt=1 / 252, m=4000):               # road 2: average ln(new/old) over one day
    h, tot = 20.0 / m, 0.0
    for i in range(m + 1):
        z = -10.0 + i * h
        R = exp((mu - 0.5 * sig * sig) * dt + sig * sqrt(dt) * z) - 1
        wgt = (1 if i in (0, m) else 4 if i % 2 else 2) * exp(-z * z / 2) / sqrt(2 * pi)
        tot += wgt * log(1 + f * R + (1 - f) * r * dt)
    return tot * h / 3 / dt
F_gold = golden_max(G_quad, 0.0, 4.0)
print()
for name, v in (("saver f* = (mu - r)/sigma^2", F), ("saver f*, search on daily quadrature", F_gold), ("saver g at f*, formula", G(F)),
                ("saver g at f*, daily quadrature", G_quad(F)), ("saver half Kelly stake", F / 2), ("saver g at half Kelly", G(F / 2)),
                ("saver g all in the fund", G(1.0)), ("saver twice Kelly stake", 2 * F),
                ("saver g at twice Kelly", G(2 * F))):
    print(f"{name:<36} {v:>16.12f}")

assert abs(f_gold - f_star) < 1e-6,                  "search lands on p - q/b"
assert abs(f_med - f_star) < 5e-4,                   "median path peaks at p - q/b"
assert abs(g_ser - g_log) < 1e-13,                   "log series agrees with library log"
assert abs(g_sim - g_log) < 4 * se,                  "simulation agrees with g(f*)"
assert abs(frac[0.5][0] / g_log - 0.75) < 0.01,      "half Kelly keeps about 3/4 of the growth"
assert abs(frac[1.0][1] - frac[1.0][2]) < 0.03,      "exact halving chance near the Brownian one"
assert abs(G_quad(F) - G(F)) < 1e-5,                 "daily rebalancing near the continuous formula"
assert abs(F_gold - F) < 1e-3,                       "daily search lands on (mu - r)/sigma^2"
print("ALL CHECKS PASS")
