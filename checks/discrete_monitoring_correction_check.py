# Daily monitoring of a barrier: the Broadie-Glasserman-Kou shift, checked three ways.
# Standard library only.  Our own normal CDF (from erf), our own random numbers
# (a 64-bit linear congruential generator), our own tree.  Nothing imported knows the answer.
from math import log, sqrt, exp, expm1, erf, pi, cos, sin

S, K, r, q, sigma, T, H = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 80.0
DAYS = 252

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))

def call(s, k):                                     # plain Black-Scholes call on the house market
    d1 = (log(s / k) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * sqrt(T))
    return s * exp(-q * T) * N(d1) - k * exp(-r * T) * N(d1 - sigma * sqrt(T))

LAM = (r - q - 0.5 * sigma * sigma) / (sigma * sigma)
def doc(h):                                         # continuous down-and-out call, barrier h <= K
    return call(S, K) - (h / S) ** (2 * LAM) * call(h * h / S, K)

def beta_from_zeta(terms=40):                       # beta = -zeta(1/2)/sqrt(2 pi), zeta built by hand
    sums, total = [], 0.0                           # eta(1/2) = 1 - 1/sqrt2 + 1/sqrt3 - ...
    for n in range(1, terms + 1):
        total += (-1) ** (n - 1) / sqrt(n); sums.append(total)
    while len(sums) > 1:                            # repeated averaging tames the alternating series
        sums = [0.5 * (a + b) for a, b in zip(sums, sums[1:])]
    zeta = sums[0] / (1.0 - sqrt(2.0))              # zeta(s) = eta(s) / (1 - 2^(1-s))
    return zeta, -zeta / sqrt(2.0 * pi)

def beta_from_integral(X=40.0, n=4000):            # the same constant as an integral (Siegmund's formula)
    def f(x): return -0.25 if x == 0 else log(-2.0 * expm1(-x * x / 2) / (x * x)) / (x * x)
    h = X / n                                       # Simpson on [0, X], then the tail past X exactly
    body = (f(0.0) + f(X) + sum((4 if i % 2 else 2) * f(i * h) for i in range(1, n))) * h / 3
    return -(body + (log(2.0) - 2 * log(X) - 2) / X) / pi

def bridge_dip(a_close, b_close, dt):               # chance a path dipped to H between two closes
    return exp(-2 * log(a_close / H) * log(b_close / H) / (sigma * sigma * dt))

def shifted(h, m, beta=0.5826, span=None):          # BGK: move a DOWN barrier down by beta sigma sqrt(dt)
    return h * exp(-beta * sigma * sqrt(span if span else T / m))

def tree(h, n, every, layer):
    # Trinomial tree on log price, n steps.  The barrier is checked only on steps that are
    # multiples of `every`.  layer=True puts the barrier ON a node layer; False puts it halfway
    # between two layers, which is where a check that happens only now and then belongs.
    dt = T / n; nu = r - q - 0.5 * sigma * sigma; lnh = log(h / S)
    j = round(lnh / (sigma * sqrt(3 * dt)))
    dx = lnh / j if layer else lnh / (j + 0.5)
    a = (sigma * sigma * dt + nu * nu * dt * dt) / (dx * dx)
    pu, pd, pm = 0.5 * (a + nu * dt / dx), 0.5 * (a - nu * dt / dx), 1.0 - a
    disc = exp(-r * dt)
    v = [max(S * exp(i * dx) - K, 0.0) for i in range(-n, n + 1)]
    for step in range(n - 1, -1, -1):               # nodes i = -step .. step, v[k] is i = k - step
        v = [disc * (pd * v[k] + pm * v[k + 1] + pu * v[k + 2]) for k in range(len(v) - 2)]
        if step > 0 and step % every == 0:
            for k in range(min(j + step + 1, len(v))):
                v[k] = 0.0                          # every node at or below layer j is knocked out
    return v[0]

def simulate(m, pairs, seed):
    # Daily-checked paths, antithetic pairs, our own normals (LCG + Box-Muller).
    # Control variate: the vanilla call on the same paths, whose price is known.
    x = seed; dt = T / m; drift = (r - q - 0.5 * sigma * sigma) * dt; vol = sigma * sqrt(dt)
    lnh = log(H / S); disc = exp(-r * T); M64 = (1 << 64) - 1
    sy = sy2 = sr = sr2 = 0.0; touched = 0
    for _ in range(pairs):
        a = b = mina = minb = 0.0
        for _ in range(m // 2):
            x = (6364136223846793005 * x + 1442695040888963407) & M64; u1 = ((x >> 11) + 0.5) / 2.0 ** 53
            x = (6364136223846793005 * x + 1442695040888963407) & M64; u2 = ((x >> 11) + 0.5) / 2.0 ** 53
            rad, th = sqrt(-2.0 * log(u1)), 2.0 * pi * u2
            for z in (rad * cos(th), rad * sin(th)):
                a += drift + vol * z; b += drift - vol * z
                if a < mina: mina = a
                if b < minb: minb = b
        y = rr = 0.0
        for end, low in ((a, mina), (b, minb)):
            pay = disc * max(S * exp(end) - K, 0.0)
            if low <= lnh: touched += 1; y -= 0.5 * pay        # knocked out: loses the vanilla payoff
            else: rr += 0.5 * pay
        sy += y; sy2 += y * y; sr += rr; sr2 += rr * rr
    my, mr = sy / pairs, sr / pairs
    return (call(S, K) + my, sqrt((sy2 / pairs - my * my) / pairs),
            mr, sqrt((sr2 / pairs - mr * mr) / pairs), touched / (2 * pairs))

def touch_prob(h):                                  # chance a continuous path ever reaches h below S
    nu, b, v = r - q - 0.5 * sigma * sigma, log(h / S), sigma * sqrt(T)
    return N((b - nu * T) / v) + exp(2 * nu * b / sigma ** 2) * N((b + nu * T) / v)

zeta, beta = beta_from_zeta()
cont = doc(H)
Hd = shifted(H, DAYS)
bgk = doc(Hd)
STEPS = 3276                                        # 13 tree steps a day; divisible by 12, 52 and 252
tree_daily = tree(H, STEPS, STEPS // DAYS, False)
tree_cont = tree(H, STEPS, 1, True)
mc, mc_se, raw, raw_se, touch_daily = simulate(DAYS, 100000, 20260924)
beta_int = beta_from_integral()
rows = [("zeta(1/2), by hand", zeta), ("beta = -zeta(1/2)/sqrt(2 pi)", beta), ("beta, by Siegmund's integral", beta_int),
        ("dip chance, closes 81 then 81", bridge_dip(81.0, 81.0, T / DAYS)), ("dip chance, closes 82 then 82", bridge_dip(82.0, 82.0, T / DAYS)),
        ("one day's wiggle sigma sqrt(dt)", sigma * sqrt(T / DAYS)), ("shift beta sigma sqrt(dt)", 0.5826 * sigma * sqrt(T / DAYS)),
        ("shifted barrier, daily", Hd), ("2 lambda", 2 * LAM), ("(H*/S)^(2 lambda)", (Hd / S) ** (2 * LAM)), ("H*^2/S", Hd * Hd / S),
        ("image call C(H*^2/S)", call(Hd * Hd / S, K)), ("vanilla call", call(S, K)),
        ("1 continuous formula, H = 80", cont), ("2 BGK shifted formula, daily", bgk),
        ("3 tree, checked daily", tree_daily), ("4 simulation, daily, 200,000 paths", mc), ("  std error", mc_se),
        ("  raw average, no control", raw), ("  std error, no control", raw_se),
        ("5 tree, checked every step", tree_cont), ("daily minus continuous", bgk - cont),
        ("BGK minus daily tree", bgk - tree_daily), ("down-and-in, daily", call(S, K) - bgk), ("down-and-in, continuous", call(S, K) - cont),
        ("touch chance, continuous at 80", touch_prob(H)), ("touch rate, daily simulation", touch_daily),
        ("touch chance, continuous at H*", touch_prob(Hd))]
extra_bgk, extra_tree = [], []                      # chart: cents above the continuous price
for months, label in ((12, "monthly"), (52, "weekly")):
    b_m, t_m = doc(shifted(H, months)), tree(H, STEPS, STEPS // months, False)
    rows += [(f"shifted barrier, {label}", shifted(H, months)), (f"BGK, {label}", b_m), (f"tree, checked {label}", t_m)]
    extra_bgk.append(100 * (b_m - cont)); extra_tree.append(100 * (t_m - cont))
extra_bgk += [100 * (bgk - cont), 0.0]; extra_tree += [100 * (tree_daily - cont), 100 * (tree_cont - cont)]
wrong_sign = doc(H * exp(0.5826 * sigma * sqrt(T / DAYS)))
wrong_T = doc(shifted(H, DAYS, span=T))
node_daily = tree(H, STEPS, STEPS // DAYS, True)
rows += [("wrong: no shift", cont), ("wrong: shift toward the spot", wrong_sign),
         ("wrong: sigma sqrt(T), not sigma sqrt(dt)", wrong_T), ("wrong: daily tree, barrier on a layer", node_daily),
         ("try: beta = 1", doc(shifted(H, DAYS, beta=1.0))), ("try: H = 95, continuous", doc(95.0)),
         ("try: H = 95, BGK daily", doc(shifted(95.0, DAYS))), ("try: H = 95, tree daily", tree(95.0, STEPS, STEPS // DAYS, False))]
for name, val in rows:
    print(f"{name:<42} {val:>12.6f}")
print("chart, checks a year        12      52     252   every")
print("chart, BGK cents  " + "".join(f"{v:8.2f}" for v in extra_bgk))
print("chart, tree cents " + "".join(f"{v:8.2f}" for v in extra_tree))

assert abs(call(S, K) - 9.227005508154) < 1e-9, "house call must match the pilot"
assert abs(cont - 9.133306) < 5e-7, "continuous down-and-out must match the barrier-formulas card"
assert abs(beta - 0.5826) < 5e-5, "hand-built zeta must give the published constant"
assert abs(beta - beta_int) < 1e-6, "zeta road and integral road to beta must agree"
assert abs(tree_cont - cont) < 0.002, "a tree checked every step must land on the continuous formula"
assert abs(bgk - tree_daily) < 0.001, "shifted formula vs a daily-checked tree"
assert abs(mc - bgk) < 3 * mc_se, "shifted formula vs the daily simulation"
assert mc - cont > 3 * mc_se, "daily checking must be worth measurably more than continuous"
assert abs(touch_daily - touch_prob(Hd)) < 0.003, "daily touch rate vs continuous touch at the shifted barrier"
print("ALL CHECKS PASS")
