# One-touch and no-touch on EURUSD -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the bell-curve area, both integrals and the
# random numbers are written out below.  Four roads: the mirror formula, the
# first-passage-time integral, the bridge integral over the end point, a simulation.
from math import log, exp, sqrt, pi, cos

S, H, rd, rf, sig, T = 1.10, 1.20, 0.05, 0.03, 0.10, 1.0
nu_d = rd - rf - 0.5 * sig * sig          # drift of log EURUSD when counting in dollars
nu_f = rd - rf + 0.5 * sig * sig          # the same drift when counting in euros

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def N(x):                                 # bell-curve area left of x
    half = simpson(lambda z: exp(-0.5 * z * z), 0.0, abs(x), 2000) / sqrt(2.0 * pi)
    return 0.5 + half if x >= 0 else 0.5 - half

# ---- road 1: the mirror formula ----
def touch(S, H, nu, sig, T):              # chance log EURUSD, drift nu, reaches ln(H/S) by T
    b, v = log(H / S), sig * sqrt(T)
    return N((nu * T - b) / v) + exp(2.0 * nu * b / (sig * sig)) * N((-b - nu * T) / v)

def at_hit(S, H, nu, r, sig, T):          # value of 1 paid at the touch: tilt the drift to nu2
    nu2 = sqrt(nu * nu + 2.0 * r * sig * sig)
    return exp(log(H / S) * (nu - nu2) / (sig * sig)) * touch(S, H, nu2, sig, T)

b = log(H / S)
p_d, p_f = touch(S, H, nu_d, sig, T), touch(S, H, nu_f, sig, T)
ot_usd, ot_eur = exp(-rd * T) * p_d, exp(-rf * T) * p_f
hit_usd = at_hit(S, H, nu_d, rd, sig, T)
hit_eur = H / S * hit_usd                 # at the touch one euro is worth exactly H dollars
nt_usd = exp(-rd * T) - ot_usd

# ---- road 2: integrate the first-passage-time density over the year ----
def fpt(t, nu):                           # density of the first time log EURUSD reaches b
    if t <= 0.0: return 0.0
    return b / (sig * sqrt(2.0 * pi * t ** 3)) * exp(-(b - nu * t) ** 2 / (2.0 * sig * sig * t))
def by_time(nu, r): return simpson(lambda t: exp(-r * t) * fpt(t, nu), 0.0, T, 20000)
p_d2, p_f2 = by_time(nu_d, 0.0), by_time(nu_f, 0.0)
hit_usd2, hit_eur2 = by_time(nu_d, rd), by_time(nu_f, rf)

# ---- road 3: no-touch as end points below the wall, times the bridge's chance of never crossing ----
v2 = sig * sig * T
def end_no_touch(x):
    dens = exp(-(x - nu_d * T) ** 2 / (2.0 * v2)) / sqrt(2.0 * pi * v2)
    return dens * (1.0 - exp(-2.0 * b * (b - x) / v2))
nt_usd3 = exp(-rd * T) * simpson(end_no_touch, -1.0, b, 20000)

# ---- road 4: simulate 50,000 years of daily EURUSD; bridge between days for continuous touches ----
M64, state = (1 << 64) - 1, 20260927
def uniform():                            # splitmix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(1.0 - uniform())) * cos(2.0 * pi * uniform())
paths, n = 50000, 252
dt = T / n
cont = disc = cont_sq = 0.0
for _ in range(paths):
    x, surv, hit = 0.0, 1.0, 0.0
    for _ in range(n):
        y = x + nu_d * dt + sig * sqrt(dt) * gauss()
        if y >= b:
            hit, surv = 1.0, 0.0
            break
        surv *= 1.0 - exp(-2.0 * (b - x) * (b - y) / (sig * sig * dt))
        x = y
    disc += hit
    cont += 1.0 - surv
    cont_sq += (1.0 - surv) ** 2
p_mc, p_daily = cont / paths, disc / paths
se = sqrt((cont_sq / paths - p_mc ** 2) / paths)
beta = 0.5826                             # Broadie-Glasserman-Kou: move the wall away by beta*sig*sqrt(dt)
H_shift = H * exp(beta * sig * sqrt(dt))
ot_bgk = exp(-rd * T) * touch(S, H_shift, nu_d, sig, T)

# ---- Greeks by bumping, what breaks, try changing ----
def ot(S=S, H=H, sig=sig, T=T): return exp(-rd * T) * touch(S, H, rd - rf - 0.5 * sig * sig, sig, T)
delta = (ot(S=S + 1e-4) - ot(S=S - 1e-4)) / 2e-4 * 0.01
vega = (ot(sig=sig + 1e-4) - ot(sig=sig - 1e-4)) / 2e-4 * 0.01
dig = exp(-rd * T) * N((nu_d * T - b) / (sig * sqrt(T)))
weight = (H / S) ** (2.0 * nu_d / (sig * sig))    # the mirror weight (H/S)^(2 lambda)
mirror = exp(-rd * T) * weight * N((-b - nu_d * T) / (sig * sqrt(T)))

rows = [
    ("ln(H/S)", b), ("drift in dollars nu_d", nu_d), ("drift in euros nu_f", nu_f),
    ("lambda = nu_d / sig^2", nu_d / (sig * sig)), ("tilted drift for pay-at-hit", sqrt(nu_d ** 2 + 2 * rd * sig * sig)),
    ("argument, finish above", (nu_d * T - b) / (sig * sqrt(T))), ("argument, mirror", (-b - nu_d * T) / (sig * sqrt(T))),
    ("chance: finish above 1.20", N((nu_d * T - b) / (sig * sqrt(T)))),
    ("chance: touch and come back", weight * N((-b - nu_d * T) / (sig * sqrt(T)))),
    ("1 touch chance, dollars, mirror", p_d), ("2 touch chance, dollars, time integral", p_d2),
    ("4 touch chance, simulation", p_mc), ("  simulation standard error", se),
    ("one-touch USD at expiry", ot_usd), ("no-touch USD, discount minus one-touch", nt_usd),
    ("3 no-touch USD, end-point integral", nt_usd3), ("discount factor e^-rdT", exp(-rd * T)),
    ("1 one-touch USD at hit, tilted mirror", hit_usd), ("2 one-touch USD at hit, time integral", hit_usd2),
    ("1 touch chance, euros, mirror", p_f), ("2 touch chance, euros, time integral", p_f2),
    ("one-touch EUR at expiry, in EUR", ot_eur),
    ("1 one-touch EUR at hit, H/S x USD at hit", hit_eur), ("2 one-touch EUR at hit, time integral", hit_eur2),
    ("digital USD above 1.20", dig), ("mirror weight (H/S)^(2 lambda)", weight),
    ("mirror digital, weighted", mirror),
    ("daily: simulated touch chance", p_daily), ("daily: simulated one-touch USD", exp(-rd * T) * p_daily),
    ("daily: shifted wall", H_shift), ("daily: one-touch USD, shifted wall", ot_bgk),
    ("delta per 0.01 rise in EURUSD", delta), ("vega per 1 vol point", vega),
    ("wrong: drift dropped", exp(-rd * T) * 2.0 * N(-b / (sig * sqrt(T)))),
    ("wrong: twice the digital", 2.0 * dig), ("wrong: no-touch as 1 - one-touch", 1.0 - ot_usd),
    ("wrong: euro drift for a dollar payout", exp(-rd * T) * p_f),
    ("try: vol 15%", ot(sig=0.15)), ("try: wall 1.15", ot(H=1.15)), ("try: three months", ot(T=0.25)),
]
for name, v in rows:
    print(f"{name:<42} {v:>10.6f}")
print("ladder: EURUSD today, one-touch USD, no-touch USD")
for k in range(11):
    s = 1.00 + 0.02 * k
    print(f"  {s:.2f} {ot(S=s):>6.2f} {exp(-rd * T) - ot(S=s):>6.2f}")

assert abs(p_d - p_d2) < 1e-7                                         # mirror = first-passage integral
assert abs(p_f - p_f2) < 1e-7                                         # same, counting in euros
assert abs(hit_usd - hit_usd2) < 1e-7                                 # tilted mirror = discounted integral
assert abs(hit_eur - hit_eur2) < 1e-7                                 # H/S identity = euro-measure integral
assert abs(nt_usd - nt_usd3) < 1e-7                                   # complement = end-point integral
assert abs(p_mc - p_d) < 3.0 * se                                     # simulation agrees with the formula
assert abs(exp(-rd * T) * p_daily - ot_bgk) < 0.004                   # shifted wall matches daily checks
print("all checks passed")
