# Reverse convertibles -- the check behind the card.  Standard library only.
# House market: Acme S = 100, strike K = 100, r = 5%, q = 2%, sigma = 20%, one year.
# A note of face F = 100 pays its coupon in cash, then 100 back if Acme ends at or above K,
# or F/K shares if it ends below.  The barrier note delivers shares only if Acme also
# touched H = 80 during the year.  Four roads: closed forms, digitals, an integral over the
# end-price density, and a 20,000-path daily simulation.  Coupons are solved by bisection.
from math import log, exp, sqrt, pi, cos, sin

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)            # bell-curve height
def N(x):                                                          # bell-curve area, power series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    term, s, k = x, x, 0
    while k < 400 and abs(term) > 1e-17 * abs(s):
        k += 1; term *= x * x / (2 * k + 1); s += term
    return 0.5 + phi(x) * s

def d12(S, K, r, q, v, T):
    d1 = (log(S / K) + (r - q + 0.5 * v * v) * T) / (v * sqrt(T)); return d1, d1 - v * sqrt(T)
def put(S, K, r, q, v, T):                                         # Black-Scholes put
    d1, d2 = d12(S, K, r, q, v, T); return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
def call(S, K, r, q, v, T):                                        # Black-Scholes call, for the covered call
    d1, d2 = d12(S, K, r, q, v, T); return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def dip(S, K, H, r, q, v, T):                                      # down-and-in put, H <= K, H < S
    sT, lam = v * sqrt(T), (r - q + 0.5 * v * v) / (v * v)
    x1 = log(S / H) / sT + lam * sT; y = log(H * H / (S * K)) / sT + lam * sT; y1 = log(H / S) / sT + lam * sT
    return (-S * exp(-q * T) * N(-x1) + K * exp(-r * T) * N(-x1 + sT)
            + S * exp(-q * T) * (H / S) ** (2 * lam) * (N(y) - N(y1))
            - K * exp(-r * T) * (H / S) ** (2 * lam - 2) * (N(y - sT) - N(y1 - sT)))

def fair(F, B, opt): return (F - B + opt) / B                     # (face - bond + option) / bond

def simpson(f, a, b, n=20000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

def by_density(S, K, H, r, q, v, T, F):
    # Road 3: the shortfall F/K (K - S_T) averaged over where ln(S_T/S) ends.  No option formula.
    nu, sd = r - q - 0.5 * v * v, v * sqrt(T); b, k = log(H / S), log(K / S)
    p = lambda x: phi((x - nu * T) / sd) / sd
    short = lambda x: F / K * (K - S * exp(x))
    lo = nu * T - 12.0 * sd
    plain = simpson(lambda x: short(x) * p(x), lo, k)
    w = exp(2 * nu * b / (v * v))                                  # reflection weight for touched paths
    touched = simpson(lambda x: short(x) * p(x), lo, b) + simpson(lambda x: short(x) * w * p(x - 2 * b), b, k)
    p_plain = simpson(p, lo, k); p_touch = simpson(p, lo, b) + simpson(lambda x: w * p(x - 2 * b), b, k)
    return exp(-r * T) * plain, exp(-r * T) * touched, p_plain, p_touch

def by_simulation(S, K, H, r, q, v, T, F, paths=20000, days=252, seed=20261123):
    # Road 4: daily closes; the barrier is watched continuously by a Brownian-bridge weight.
    state = [seed]
    def unif():                                                    # splitmix64, written out
        state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = state[0]
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
    dt = T / days; mu = (r - q - 0.5 * v * v) * dt; sd = v * sqrt(dt); h = log(H / S)
    sums = [[0.0, 0.0] for _ in range(4)]
    for _ in range(paths):
        x, surv, daily, z2 = 0.0, 1.0, 1.0, None
        for _ in range(days):
            if z2 is None:
                u1, u2 = unif(), unif(); rad = sqrt(-2.0 * log(u1))
                z, z2 = rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)
            else: z, z2 = z2, None
            nx = x + mu + sd * z
            if nx <= h: surv = 0.0; daily = 0.0
            elif surv > 0.0: surv *= 1.0 - exp(-2.0 * (x - h) * (nx - h) / (v * v * dt))
            x = nx
        loss = exp(-r * T) * F / K * max(K - S * exp(x), 0.0)
        for j, y in enumerate((loss, -loss * surv, -loss * daily, loss * (daily - surv))):  # put; DIP - P, two ways; their gap
            sums[j][0] += y; sums[j][1] += y * y
    return [(s / paths, sqrt((s2 / paths - (s / paths) ** 2) / (paths - 1))) for s, s2 in sums]

def bisect(value, target, lo=0.0, hi=1.0):                         # coupon c with value(c) = target
    for _ in range(100):
        mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if value(mid) < target else (lo, mid)
    return 0.5 * (lo + hi)

S, K, H, r, q, v, T, F = 100.0, 100.0, 80.0, 0.05, 0.02, 0.20, 1.0, 100.0
B = F * exp(-r * T); P = put(S, K, r, q, v, T); DIP = dip(S, K, H, r, q, v, T)
c_rc, c_brc = fair(F, B, F / K * P), fair(F, B, F / K * DIP); d1, d2 = d12(S, K, r, q, v, T)
cash_dig, asset_dig = exp(-r * T) * N(d2), S * exp(-q * T) * N(-d1)          # Road 2 pieces
c_dig = (F - F * cash_dig - F / K * asset_dig) / B
P_int, DIP_int, prob_rc, prob_brc = by_density(S, K, H, r, q, v, T, F)
c_bis_rc = bisect(lambda c: B * (1 + c) - P_int, F); c_bis_brc = bisect(lambda c: B * (1 + c) - DIP_int, F)
mc = by_simulation(S, K, H, r, q, v, T, F)                                  # DIP = exact P + simulated (DIP - P)
DIP_d = dip(S, K, H * exp(-0.5826 * v * sqrt(T / 252)), r, q, v, T)          # daily closes: the shifted barrier
rows = [("bond F e^-rT", B), ("put P", P), ("down-and-in put, H = 80", DIP),
    ("down-and-out put = P - DIP", P - DIP), ("F - B", F - B), ("F - B + P", F - B + P), ("F - B + DIP", F - B + DIP),
    ("1 fair coupon %, plain", 100 * c_rc), ("1 fair coupon %, barrier", 100 * c_brc),
    ("2 cash digital e^-rT N(d2)", cash_dig), ("2 asset digital S e^-qT N(-d1)", asset_dig),
    ("2 note before coupon, digitals", F * cash_dig + F / K * asset_dig),
    ("2 same, covered call S e^-qT - C", F / K * (S * exp(-q * T) - call(S, K, r, q, v, T))),
    ("2 fair coupon %, plain, digitals", 100 * c_dig),
    ("3 put, density integral", P_int), ("3 DIP, density integral", DIP_int),
    ("3 coupon % by bisection, plain", 100 * c_bis_rc), ("3 coupon % by bisection, barrier", 100 * c_bis_brc),
    ("4 put, simulation", mc[0][0]), ("  its error bar (1 s.e.)", mc[0][1]),
    ("4 DIP, simulation, continuous", P + mc[1][0]), ("  its error bar (1 s.e.)", mc[1][1]),
    ("4 DIP, simulation, daily closes", P + mc[2][0]), ("  its error bar (1 s.e.)", mc[2][1]),
    ("4 continuous - daily, same paths", mc[3][0]), ("  its error bar (1 s.e.)", mc[3][1]),
    ("DIP, daily, shifted barrier formula", DIP_d), ("fair coupon %, daily closes", 100 * fair(F, B, DIP_d)),
    ("coupon cash at T, plain", F * c_rc), ("coupon cash at T, barrier", F * c_brc), ("coupon gap, plain - barrier", F * (c_rc - c_brc)),
    ("chance of shares, plain", prob_rc), ("chance of shares, barrier", prob_brc),
    ("put carried to T, P e^rT", P * exp(r * T)), ("check: F(1+c) - P e^rT", F * (1 + c_rc) - P * exp(r * T)),
    ("  F e^rT", F * exp(r * T)),
    ("wrong %: divide by face, not bond", 100 * (F - B + P) / F), ("wrong %: bond only, no put", 100 * fair(F, B, 0.0)),
    ("wrong %: knock-out put for barrier", 100 * fair(F, B, P - DIP)),
    ("wrong %: dividend left out of put", 100 * fair(F, B, put(S, K, r, 0.0, v, T))),
    ("try %: sigma 30%, plain", 100 * fair(F, B, put(S, K, r, q, .3, T))),
    ("try %: sigma 30%, barrier", 100 * fair(F, B, dip(S, K, H, r, q, .3, T))),
    ("try %: strike 90, plain", 100 * fair(F, B, F / 90 * put(S, 90.0, r, q, v, T))),
    ("try %: two years, plain", 100 * fair(F, F * exp(-2 * r), put(S, K, r, q, v, 2.0)))]
for name, val in rows: print(f"{name:<36} {val:>11.6f}")
vols = (0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40)
print("chart, sigma %    :" + "".join(f"{100 * s:>7.0f}" for s in vols))
print("chart, plain %    :" + "".join(f"{100 * fair(F, B, put(S, K, r, q, s, T)):>7.2f}" for s in vols))
print("chart, barrier %  :" + "".join(f"{100 * fair(F, B, dip(S, K, H, r, q, s, T)):>7.2f}" for s in vols))
print("story, put P      :" + "".join(f"{put(S, K, r, q, s, T):>7.2f}" for s in vols))
print("story, DIP        :" + "".join(f"{dip(S, K, H, r, q, s, T):>7.2f}" for s in vols))
hs = (50.0, 60.0, 70.0, 80.0, 90.0, 95.0)
print("bars, barrier H   :" + "".join(f"{h:>7.0f}" for h in hs))
print("bars, coupon %    :" + "".join(f"{100 * fair(F, B, dip(S, K, h, r, q, v, T)):>7.2f}" for h in hs))
ends = [50.0 + 10 * i for i in range(9)]
print("payoff, S_T       :" + "".join(f"{s:>7.0f}" for s in ends))
print("payoff, plain     :" + "".join(f"{F * min(1, s / K) + F * c_rc:>7.2f}" for s in ends))
print("payoff, touched   :" + "".join(f"{F * min(1, s / K) + F * c_brc:>7.2f}" for s in ends))
assert abs(P - 6.330080627550) < 1e-9, "put vs the Black-Scholes card"
assert abs(DIP - 4.597403) < 1e-6, "down-and-in put vs the eight-barrier card"
assert abs(c_dig - c_rc) < 1e-10, "digitals road vs the put road"
assert abs(P_int - P) < 1e-7, "density integral vs the put formula"
assert abs(DIP_int - DIP) < 1e-7, "density integral with reflection vs the closed-form DIP"
assert abs(P + mc[1][0] - DIP) < 3 * mc[1][1], "simulated DIP, barrier watched by the bridge, vs the closed form"
assert abs(P + mc[2][0] - DIP_d) < 3 * mc[2][1], "simulated DIP on daily closes vs the shifted-barrier formula"
assert abs(mc[3][0] - (DIP - DIP_d)) < 3 * mc[3][1], "touches between closes: the bridge vs the two formulas"
assert abs(c_rc - 0.1178) < 5e-5, "plain coupon vs the hand value 11.78%"
assert abs(c_brc - 0.0996) < 5e-5, "barrier coupon vs the hand value 9.96%"
print("ALL CHECKS PASS")
