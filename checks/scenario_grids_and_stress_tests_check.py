# Stress tests on the Acme options book: grid, replays, reverse stress.
# Standard library only. The normal CDF, the integrator and the searches are
# written out here; nothing imported already knows the answer.
from math import exp, log, sqrt, pi, cos, sin

R, Q, S0, VOL0 = 0.05, 0.02, 100.0, 0.20            # the house market

def N(x):                                            # bell-curve area left of x, by Marsaglia's series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * abs(total):
        k += 2; term *= x * x / k; total += term
    return 0.5 + total * exp(-0.5 * x * x) / sqrt(2.0 * pi)

def put(S, K, vol, T):                               # road 1: Black-Scholes put formula
    d1 = (log(S / K) + (R - Q + 0.5 * vol * vol) * T) / (vol * sqrt(T))
    d2 = d1 - vol * sqrt(T)
    return K * exp(-R * T) * N(-d2) - S * exp(-Q * T) * N(-d1)

def put_simpson(S, K, vol, T, n=4000):               # road 2: average the payoff over the bell curve
    drift, w = (R - Q - 0.5 * vol * vol) * T, vol * sqrt(T)
    zk = (log(K / S) - drift) / w                    # the put pays only below this z
    a, h = -12.0, (zk + 12.0) / n
    f = lambda z: (K - S * exp(drift + w * z)) * exp(-0.5 * z * z) / sqrt(2.0 * pi)
    tot = f(a) + f(zk) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return exp(-R * T) * tot * h / 3.0

def greeks(S, K, vol, T):                            # delta, gamma, vega per vol point
    d1 = (log(S / K) + (R - Q + 0.5 * vol * vol) * T) / (vol * sqrt(T))
    pdf = exp(-0.5 * d1 * d1) / sqrt(2.0 * pi)
    return (-exp(-Q * T) * N(-d1), exp(-Q * T) * pdf / (S * vol * sqrt(T)),
            S * exp(-Q * T) * pdf * sqrt(T) / 100.0)

# the book: sold 380,000 one-year $90 puts, bought 140,000 three-month $100 puts, shares hedge delta
OPTS = [(-380000.0, 90.0, 1.0), (140000.0, 100.0, 0.25)]
hedge = lambda opts: -round(sum(n * greeks(S0, K, VOL0, T)[0] for n, K, T in opts))
SHARES = hedge(OPTS)

def value(S, vol, opts, pricer, sh):
    return sum(n * pricer(S, K, vol, T) for n, K, T in opts) + sh * S

def loss(s, v, opts=OPTS, pricer=put, sh=SHARES):    # s: spot move in percent, v: vol move in points
    return value(S0 * (1 + s / 100), VOL0 + v / 100, opts, pricer, sh) - value(S0, VOL0, opts, pricer, sh)

G = [sum(n * greeks(S0, K, VOL0, T)[j] for n, K, T in OPTS) + (SHARES if j == 0 else 0) for j in range(3)]
def taylor(s, v):                                    # the book's Greeks, as a second-order estimate
    dS = S0 * s / 100
    return G[0] * dS + 0.5 * G[1] * dS * dS + G[2] * v

M = lambda x: f"{x / 1e6:8.2f}"
print(f"house put, formula        {put(100.0, 100.0, 0.2, 1.0):.12f}")
print(f"book: {OPTS[0][0]:.0f} x 1y $90 put at {put(S0, 90.0, VOL0, 1.0):.4f}   "
      f"{OPTS[1][0]:.0f} x 3m $100 put at {put(S0, 100.0, VOL0, 0.25):.4f}   shares {SHARES:.0f}")
print(f"book delta {G[0]:.1f}   gamma {G[1]:.1f}   vega per point {G[2]:.0f}")
SPOTS, VOLS = (-30, -20, -10, 0, 10, 20), (-5, 0, 5, 10, 15)
print("grid, $ million, vol points across" + "".join(f"{v:>+8d}" for v in VOLS))
for s in SPOTS:
    print(f"  spot move {s:+4d}%" + " " * 14 + "".join(M(loss(s, v)) for v in VOLS))
L1, L2 = loss(-20, 15), loss(-20, 15, pricer=put_simpson)
print(f"headline -20%, +15 vol: formula {L1:.2f}   Simpson {L2:.2f}")
p1, p2 = put(80.0, 90.0, 0.35, 1.0), put(80.0, 100.0, 0.35, 0.25)
print(f"stressed at $80, 35%: 1y $90 put {p1:.4f}   3m $100 put {p2:.4f}")
print(f"by position: 1y puts {OPTS[0][0] * (p1 - put(S0, 90.0, VOL0, 1.0)):.2f}   "
      f"3m puts {OPTS[1][0] * (p2 - put(S0, 100.0, VOL0, 0.25)):.2f}   shares {SHARES * -20.0:.2f}")
print(f"book vega per point at $80, 20%: {sum(n * greeks(80.0, K, VOL0, T)[2] for n, K, T in OPTS):.0f}")
a, b = loss(-20, 0), loss(0, 15)
print(f"spot alone {a:.2f}   vol alone {b:.2f}   sum {a + b:.2f}   joint minus sum {L1 - a - b:.2f}")
print(f"Greeks estimate at -20%, +15 vol {taylor(-20, 15):.2f}   wrong: vol +15% of 20 (to 23%) {loss(-20, 3):.2f}")
print(f"tiny move -0.05%, +0.01 vol: full {loss(-0.05, 0.01):.4f}   Greeks {taylor(-0.05, 0.01):.4f}")

MS, MV, RHO, LIMIT = 20 / sqrt(12), 4.0, -0.7, -3.0e6  # one-month typical moves, their correlation

def dist(s, v, rho=RHO):                             # how many typical months away (s, v) lies
    zs, zv = s / MS, v / MV
    return sqrt((zs * zs - 2 * rho * zs * zv + zv * zv) / (1 - rho * rho))

REPLAYS = [("2008", 2261.270, 1649.510, 25.66, 69.95), ("2020", 9817.180, 6860.670, 14.38, 61.59)]
RL = [loss(100 * (n1 / n0 - 1), x1 - x0) for _, n0, n1, x0, x1 in REPLAYS]
for (name, n0, n1, x0, x1), lr in zip(REPLAYS, RL):  # Nasdaq for spot, VIX change for vol points
    s, v = 100 * (n1 / n0 - 1), x1 - x0
    print(f"replay {name} inputs: Nasdaq {n0:.2f} -> {n1:.2f}   VIX {x0:.2f} -> {x1:.2f}   book vol to {20 + v:.2f}%")
    print(f"replay {name}: spot {s:.4f}%  vol {v:+.2f} pts  formula {lr:.2f}  "
          f"Simpson {loss(s, v, pricer=put_simpson):.2f}  Greeks {taylor(s, v):.2f}")
    print(f"replay {name} distance {dist(s, v):.3f}   log10 of chance bound {-dist(s, v) ** 2 / (2 * log(10)):.2f}")

def rays(rho=RHO, limit=LIMIT):                     # reverse road 1: walk out along 720 rays, bisect
    best = (99.0, 0.0, 0.0)
    for k in range(720):
        th = 2 * pi * k / 720
        pt = lambda d: (MS * d * cos(th), MV * (rho * d * cos(th) + sqrt(1 - rho * rho) * d * sin(th)))
        lo, d = 0.0, 0.1
        while d < best[0]:
            s, v = pt(d)
            if s <= -99 or v <= -19: d = 99.0; break
            if loss(s, v) <= limit: break
            lo, d = d, d + 0.1
        if d >= best[0]: continue
        for _ in range(40):
            mid = 0.5 * (lo + d)
            s, v = pt(mid)
            lo, d = (lo, mid) if loss(s, v) <= limit else (mid, d)
        best = (d,) + pt(d)
    return best

def brute():                                         # reverse road 2: every point on a 0.25 grid
    best = (99.0, 0.0, 0.0)
    for i in range(241):
        for j in range(241):
            s, v = -60 + 0.25 * i, -15 + 0.25 * j
            dd = dist(s, v)
            if dd < best[0] and loss(s, v) <= LIMIT: best = (dd, s, v)
    return best

r1, r2, t1, t3 = rays(), brute(), rays(rho=0.0), rays(limit=-2.0e6)
print(f"reverse inputs: limit {LIMIT:.0f}   typical month: spot {MS:.4f}%  vol {MV:.2f} pts  correlation {RHO:.2f}")
print(f"reverse, rays:  distance {r1[0]:.3f}  spot {r1[1]:+.2f}%  vol {r1[2]:+.2f} pts  loss {loss(r1[1], r1[2]):.0f}")
print(f"reverse, grid:  distance {r2[0]:.3f}  spot {r2[1]:+.2f}%  vol {r2[2]:+.2f} pts  loss {loss(r2[1], r2[2]):.0f}")
print(f"reverse, check: distance of ray point by formula {dist(r1[1], r1[2]):.3f}")
print(f"chance bound exp(-d^2/2) per million months {1e6 * exp(-0.5 * r1[0] ** 2):.2f}   one month in {exp(0.5 * r1[0] ** 2):.0f}")
print(f"distance of -20%, +15 vol {dist(-20, 15):.3f}   one month in {exp(0.5 * dist(-20, 15) ** 2):.0f}")
print(f"bars, $ million: Greeks {-taylor(-20, 15) / 1e6:.2f}  one at a time {-(a + b) / 1e6:.2f}  full {-L1 / 1e6:.2f}  "
      f"2008 {-RL[0] / 1e6:.2f}  2020 {-RL[1] / 1e6:.2f}")
print("chart, spot move       " + "".join(f"{s:8d}" for s in SPOTS))
print("chart, full, vol +0    " + "".join(M(loss(s, 0)) for s in SPOTS))
print("chart, full, vol +15   " + "".join(M(loss(s, 15)) for s in SPOTS))
print("chart, Greeks, vol +15 " + "".join(M(taylor(s, 15)) for s in SPOTS))
t2 = loss(-20, 15, opts=OPTS[:1], sh=hedge(OPTS[:1]))
print(f"try: correlation 0 -> distance {t1[0]:.3f}  spot {t1[1]:+.2f}%  vol {t1[2]:+.2f} pts")
print(f"try: no 3m puts, shares re-hedged {hedge(OPTS[:1])} -> headline {t2:.2f}")
print(f"try: limit $2m -> distance {t3[0]:.3f}  spot {t3[1]:+.2f}%  vol {t3[2]:+.2f} pts")

assert abs(put(100.0, 100.0, 0.2, 1.0) - 6.330080627550) < 1e-9, "house put"
assert abs(L1 - L2) < 1.0 and round(L1 / 1e6, 1) == -2.1, "two revaluations agree; the headline loses 2.1 million"
assert abs(loss(-0.05, 0.01) - taylor(-0.05, 0.01)) < 0.01 * abs(loss(-0.05, 0.01)), "Greeks right for tiny moves"
fd = lambda f, h=0.01: ((f(h, 0) - f(-h, 0)) / (2 * h), (f(h, 0) + f(-h, 0) - 2 * f(0, 0)) / h ** 2, (f(0, h) - f(0, -h)) / (2 * h))
assert all(abs(x - y) < 0.01 * max(1, abs(y)) for x, y in zip(fd(loss), fd(taylor))), "Greeks match slopes of the repricing"
assert abs(r1[0] - r2[0]) < 0.05, "ray search and grid search find the same nearest scenario"
assert loss(r1[1], r1[2]) <= LIMIT < loss(r1[1] * 0.999, r1[2] * 0.999), "the reverse scenario sits on the edge"
print("ALL CHECKS PASS")
