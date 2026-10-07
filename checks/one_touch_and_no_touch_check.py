# One-touch and no-touch -- the check behind the card.  Standard library only.
# Roads: (1) reflection formulas, (2) Simpson integrals of the first-passage
# density and of the no-touch end density, (3) a simulation with its own random
# numbers.  The bell-curve area N(x) is Simpson's rule, written out below.
from math import log, sqrt, exp, cos, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height at x
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def N(x):                                                         # bell-curve area left of x
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

def touch_prob(S, H, q_, r, sig, T, nu=None):                     # road 1: reflection formula
    b, v = log(H / S), (r - q_ - 0.5 * sig * sig) if nu is None else nu
    if b <= 0.0: return 1.0
    st = sig * sqrt(T)
    return N((v * T - b) / st) + exp(2 * v * b / sig ** 2) * N((-b - v * T) / st)
def one_touch_expiry(S, H, q_, r, sig, T): return exp(-r * T) * touch_prob(S, H, q_, r, sig, T)
def no_touch(S, H, q_, r, sig, T):                                # written out on its own
    b, v, st = log(H / S), r - q_ - 0.5 * sig * sig, sig * sqrt(T)
    if b <= 0.0: return 0.0
    return exp(-r * T) * (N((b - v * T) / st) - exp(2 * v * b / sig ** 2) * N((-b - v * T) / st))
def one_touch_hit(S, H, q_, r, sig, T):                           # paid the moment the line is hit
    b, v = log(H / S), r - q_ - 0.5 * sig * sig
    if b <= 0.0: return 1.0
    vt = sqrt(v * v + 2 * r * sig * sig)                          # the steeper drift
    return exp(b * (v - vt) / sig ** 2) * touch_prob(S, H, 0, 0, sig, T, nu=vt)

S, H, r, q, sig, T = 100.0, 120.0, 0.05, 0.02, 0.20, 1.0
b, nu, D = log(H / S), r - q - 0.5 * sig * sig, exp(-r * T)
w = exp(2 * nu * b / sig ** 2)
def fpt(t):                                                       # first-passage density at time t
    return 0.0 if t <= 0 else b / (sig * sqrt(2 * pi * t ** 3)) * exp(-(b - nu * t) ** 2 / (2 * sig * sig * t))
Q1, Q2 = touch_prob(S, H, q, r, sig, T), simpson(fpt, 0.0, T, 20000)
hit1, hit2 = one_touch_hit(S, H, q, r, sig, T), simpson(lambda t: exp(-r * t) * fpt(t), 0.0, T, 20000)
st = sig * sqrt(T)                                                # road 2 for the no-touch: end density of paths that never touched
alive = lambda x: (phi((x - nu * T) / st) - w * phi((x - 2 * b - nu * T) / st)) / st
NT1, NT2 = no_touch(S, H, q, r, sig, T), D * simpson(alive, b - 12 * st, b, 20000)

state = 20260924                                                  # road 3: simulation, own generator
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
paths, steps = 20000, 250
dt = T / steps
hits, pv, pv2 = 0, 0.0, 0.0
for _ in range(paths):
    x = 0.0
    for k in range(steps):
        z = sqrt(-2 * log(unif())) * cos(2 * pi * unif())
        y = x + nu * dt + sig * sqrt(dt) * z
        u = unif()                                                # bridge: did it touch between steps?
        if y >= b or u < exp(-2 * (b - x) * (b - y) / (sig * sig * dt)):
            hits += 1; g = exp(-r * (k + 0.5) * dt); pv += g; pv2 += g * g
            break
        x = y
Q3, hit3 = hits / paths, pv / paths
seQ, seH = sqrt(Q3 * (1 - Q3) / paths), sqrt((pv2 / paths - hit3 ** 2) / paths)

vt = sqrt(nu * nu + 2 * r * sig * sig)
def row(label, v): print(f"{label:<42} {v:>10.6f}")
print("house market, S=100 H=120 r=0.05 q=0.02 sigma=0.20 T=1, $1 paid")
for lab, v in (("log distance b = ln(H/S)", b), ("log drift nu = r - q - sigma^2/2", nu),
               ("reflection weight (H/S)^(2 nu/sigma^2)", w), ("mirror start H^2/S", H * H / S), ("discount D(T) = e^-rT", D),
               ("z-score, end beyond 120", (nu * T - b) / st), ("z-score, mirror term", (-b - nu * T) / st),
               ("paths ending beyond 120", N((nu * T - b) / st)), ("touched, ending below (mirror term)", w * N((-b - nu * T) / st)),
               ("touch prob, 1 reflection formula", Q1), ("touch prob, 2 first-passage integral", Q2),
               ("touch prob, 3 simulation", Q3), ("  simulation standard error", seQ),
               ("one-touch at expiry, D(T) x Q", D * Q1), ("no-touch, 1 formula", NT1), ("no-touch, 2 surviving-path integral", NT2),
               ("one-touch + no-touch", D * Q1 + NT2), ("one-touch at hit, 1 formula", hit1),
               ("one-touch at hit, 2 discounted density", hit2), ("one-touch at hit, 3 simulation", hit3),
               ("  simulation standard error", seH), ("steeper drift sqrt(nu^2 + 2 r sigma^2)", vt),
               ("at-hit weight e^(b(nu - nut)/sigma^2)", exp(b * (nu - vt) / sig ** 2)), ("touch prob with the steeper drift", touch_prob(S, H, 0, 0, sig, T, nu=vt)),
               ("wrong: no mirror term, D(T) x P(end>=120)", D * N((nu * T - b) / st)),
               ("wrong: mirror weight set to 1", D * (N((nu * T - b) / st) + N((-b - nu * T) / st))),
               ("wrong: drift r - q, no -sigma^2/2", D * touch_prob(S, H, q, r, sig, T, nu=r - q)),
               ("rule of thumb: 2 x digital at 120", 2 * D * N((nu * T - b) / st)),
               ("try: sigma = 0.30", one_touch_expiry(S, H, q, r, 0.30, T)), ("try: H = 110", one_touch_expiry(S, 110.0, q, r, sig, T)),
               ("try: T = 2", one_touch_expiry(S, H, q, r, sig, 2.0)), ("try: r=0.04, q=0.02 (nu=0), touch prob", touch_prob(S, H, q, 0.04, sig, T)),
               ("try: nu=0, 2 x P(end>=120)", 2 * N(-b / st))):
    row(lab, v)
print("greeks by nudging            one-touch(exp)    no-touch")
for lab, f in (("delta, per $1 of S", lambda g: (g(S + 0.01, H, q, r, sig, T) - g(S - 0.01, H, q, r, sig, T)) / 0.02),
               ("gamma, per $1 of S", lambda g: (g(S + 0.5, H, q, r, sig, T) - 2 * g(S, H, q, r, sig, T) + g(S - 0.5, H, q, r, sig, T)) / 0.25),
               ("vega, per 1 vol point", lambda g: (g(S, H, q, r, sig + 0.0001, T) - g(S, H, q, r, sig - 0.0001, T)) / 0.02),
               ("theta, per day", lambda g: g(S, H, q, r, sig, T - 1 / 365) - g(S, H, q, r, sig, T))):
    print(f"{lab:<28} {f(one_touch_expiry):>14.6f} {f(no_touch):>11.6f}")
spots = [80.0 + 5 * i for i in range(9)]
print("chart, Acme price       " + " ".join(f"{s:5.0f}" for s in spots))
for lab, t in (("chart, 12 months left", 1.0), ("chart, 6 months left", 0.5), ("chart, 1 month left", 1 / 12)):
    print(f"{lab:<24}" + " ".join(f"{one_touch_expiry(s, H, q, r, sig, t):5.2f}" for s in spots))
highs = [100, 105, 110, 115, 119, 120, 125, 130]
print("payoff, year's high     " + " ".join(f"{h:5d}" for h in highs))
print("payoff, one-touch       " + " ".join(f"{1 if h >= 120 else 0:5d}" for h in highs))
print("payoff, no-touch        " + " ".join(f"{0 if h >= 120 else 1:5d}" for h in highs))

assert abs(Q1 - 0.378622) < 5e-7, "formula vs the spec's touch probability"
assert abs(NT1 - NT2) < 1e-7, "no-touch formula vs surviving-path integral"
assert abs(Q1 - Q2) < 1e-7, "reflection formula vs integrated first-passage density"
assert abs(hit1 - hit2) < 1e-7, "at-hit formula vs discounted density integral"
assert abs(D * Q1 + NT2 - D) < 1e-7, "one-touch plus independently integrated no-touch is a sure dollar"
assert abs(Q3 - Q1) < 4 * seQ, "simulated touch probability within four standard errors"
assert abs(hit3 - hit1) < 4 * seH, "simulated at-hit price within four standard errors"
print("ALL CHECKS PASS")
