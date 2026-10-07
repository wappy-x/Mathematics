# Futures against forwards -- the check behind the card.  Standard library only.
# A made-up discount curve, the Hull-White model fitted to it, and the three-month
# rate that fixes in 3 years.  Road 1: the closed formula.  Road 2: a trinomial tree
# fitted to the curve by itself.  Road 3: Monte Carlo with home-made random numbers.
from math import exp, log, sqrt, cos, pi

KAPPA, SIGMA, T, U, ALPHA = 0.2, 0.0143, 3.0, 3.25, 0.25   # mean reversion, rate vol, fix, pay, accrual
def D(s):  return exp(-0.03 * s - 0.002 * s * s)             # today's discount curve
def b(k, v): return (1.0 - exp(-k * v)) / k                  # Hull-White loading

def closed(k, sig, t, u, al):                                 # road 1: the card's formula
    h = u - t; bh = b(k, h)
    q = sig * sig * (1.0 - exp(-2.0 * k * t)) / (2.0 * k)    # variance of X_T
    c = sig * sig * b(k, t) ** 2 / 2.0                       # covariance of X_T with the bank's log
    C = bh * bh * q + bh * c
    G = D(t) / D(u)
    return dict(bh=bh, q=q, c=c, C=C, G=G, K=(G - 1.0) / al, R=(G * exp(C) - 1.0) / al,
                cc=(C - bh * bh * q / 2.0) / h)              # continuously compounded version

def tree(k, sig, t, u, al, n):                                # road 2: Hull-White trinomial tree
    dt = 1.0 / n; nT, nU = round(t * n), round(u * n); dx = sig * sqrt(3.0 * dt)
    def pr(j):
        a = -k * dt * j
        return ((1, 1/6 + (a * a + a) / 2), (0, 2/3 - a * a), (-1, 1/6 + (a * a - a) / 2))
    Q, shift = {0: 1.0}, []
    for i in range(nU):                                       # fit each step's shift to D
        ai = log(sum(v * exp(-j * dx * dt) for j, v in Q.items()) / D((i + 1) * dt)) / dt
        shift.append(ai); nq = {}
        for j, v in Q.items():
            w = v * exp(-(ai + j * dx) * dt)
            for dj, p in pr(j): nq[j + dj] = nq.get(j + dj, 0.0) + p * w
        Q = nq
    def back(V, i1, i0, disc):
        for i in range(i1 - 1, i0 - 1, -1):
            V = {j: (exp(-(shift[i] + j * dx) * dt) if disc else 1.0)
                 * sum(p * V[j + dj] for dj, p in pr(j)) for j in range(-i, i + 1)}
        return V
    P = back({j: 1.0 for j in range(-nU, nU + 1)}, nU, nT, True)   # bond T->U at every node
    R = back({j: (1.0 / P[j] - 1.0) / al for j in P}, nT, 0, False)[0]   # futures: no discounting
    fra = back({j: 1.0 - P[j] for j in P}, nT, 0, True)[0] / (al * D(u))
    return R, fra

MASK = (1 << 64) - 1; seed = [20260928]
def unif():                                                   # splitmix64, written out
    seed[0] = (seed[0] + 0x9E3779B97F4A7C15) & MASK; z = seed[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
def gauss(): return sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())

def monte_carlo(k, sig, t, u, al, pairs, steps=60):          # road 3: simulate the short rate
    dt = t / steps; e = exp(-k * dt); sd = sig * sqrt((1.0 - e * e) / (2.0 * k)); bh = b(k, u - t)
    phi = lambda s: 0.03 + 0.004 * s + sig * sig * b(k, s) ** 2 / 2.0   # fitted drift of r
    m = 600; hs = t / m
    int_phi = hs / 3 * (phi(0) + phi(t) + sum((4 if i % 2 else 2) * phi(i * hs) for i in range(1, m)))
    lnA = log(D(u) / D(t)) - bh * bh * sig * sig * (1 - exp(-2 * k * t)) / (4 * k) \
          - bh * sig * sig * b(k, t) ** 2 / 2                 # bond formula from the Hull-White card
    rec = []
    for _ in range(pairs):
        zs = [gauss() for _ in range(steps)]; pair = []
        for sgn in (1.0, -1.0):                               # antithetic twin
            x = I = 0.0
            for z in zs:
                xn = x * e + sd * sgn * z; I += 0.5 * (x + xn) * dt; x = xn
            P = exp(lnA - bh * x)
            pair.append(((1.0 / P - 1.0) / al, P * exp(-int_phi - I)))   # rate, weight P/B_T
        rec.append(pair)
    n = 2 * pairs
    R = sum(L for pr in rec for L, w in pr) / n
    W = sum(w for pr in rec for L, w in pr) / n                # should reprice D(U)
    K = sum(L * w for pr in rec for L, w in pr) / n / W
    v = [sum(L * (1 - w / W) for L, w in pr) / 2 for pr in rec]
    mu = sum(v) / pairs; se = sqrt(sum((x - mu) ** 2 for x in v) / (pairs - 1) / pairs)
    return R, K, W, se

bp = 1e4
c = closed(KAPPA, SIGMA, T, U, ALPHA)
R80, K80 = tree(KAPPA, SIGMA, T, U, ALPHA, 80)
R160, K160 = tree(KAPPA, SIGMA, T, U, ALPHA, 160)
R_rich = 2 * R160 - R80                                       # Richardson: cancel the step-size error
Rm, Km, Wm, se = monte_carlo(KAPPA, SIGMA, T, U, ALPHA, 25000)
h = U - T
hull_cc = (c["bh"] / h) * (c["bh"] * (1 - exp(-2 * KAPPA * T)) + 2 * KAPPA * b(KAPPA, T) ** 2) \
          * SIGMA ** 2 / (4 * KAPPA)                          # Hull's textbook form, typed separately
ho_lee = 0.5 * SIGMA ** 2 * T * U
tiny = closed(1e-6, SIGMA, T, U, ALPHA)["cc"]                 # mean reversion switched off
pay_only = (c["G"] * exp(c["bh"] ** 2 * c["q"]) - 1) / ALPHA - c["K"]

rows = [("b(h), h = 0.25", c["bh"]), ("b(T), T = 3", b(KAPPA, T)), ("q_T  variance of X_T", c["q"]),
        ("c_T  covariance with bank log", c["c"]), ("C = b^2 q + b c", c["C"]), ("G0 = D(T)/D(U)", c["G"]),
        ("1 FRA rate K", c["K"]), ("1 futures rate R0", c["R"]), ("1 R0 - K, bp", (c["R"] - c["K"]) * bp),
        ("  futures quote 100(1-R0)", 100 * (1 - c["R"])), ("  FRA as a quote 100(1-K)", 100 * (1 - c["K"])),
        ("2 tree n=80, R0 - K, bp", (R80 - K80) * bp), ("2 tree n=160, R0 - K, bp", (R160 - K160) * bp),
        ("2 tree extrapolated, bp", (R_rich - K160) * bp), ("3 Monte Carlo R0 - K, bp", (Rm - Km) * bp),
        ("  Monte Carlo std error, bp", se * bp), ("  MC weight vs D(U)", Wm), ("  D(U)", D(U)),
        ("4 cc adjustment, bp", c["cc"] * bp), ("  Hull textbook form, bp", hull_cc * bp),
        ("5 kappa -> 0, cc, bp", tiny * bp), ("  Ho-Lee 1/2 s^2 T U, bp", ho_lee * bp),
        ("piece: payment date only, bp", pay_only * bp), ("piece: bank account, bp", (c["R"] - c["K"] - pay_only) * bp),
        ("dollars per contract, $25/bp", (c["R"] - c["K"]) * bp * 25),
        ("wrong: sign flipped, FRA est.", c["R"] + (c["R"] - c["K"])), ("wrong: Ho-Lee rule, bp", ho_lee * bp),
        ("wrong: cc formula on simple, bp", c["cc"] * bp)]
for sig, lab in ((0.0286, "try: sigma doubled, bp"), (0.01, "try: sigma = 0.01, bp")):
    x = closed(KAPPA, sig, T, U, ALPHA); rows.append((lab, (x["R"] - x["K"]) * bp))
x = closed(0.05, SIGMA, T, U, ALPHA); rows.append(("try: kappa = 0.05, bp", (x["R"] - x["K"]) * bp))
for name, v in rows: print(f"{name:<34} {v:>14.8f}")
print("\nchart, fixing year      " + " ".join(f"{t:6.1f}" for t in (0.5, 1, 2, 3, 4, 5, 7, 10)))
for lab, f in (("chart, exact simple bp ", lambda x: (x["R"] - x["K"]) * bp), ("chart, Hull-White cc bp", lambda x: x["cc"] * bp)):
    print(lab + " " + " ".join(f"{f(closed(KAPPA, SIGMA, t, t + h, ALPHA)):6.2f}" for t in (0.5, 1, 2, 3, 4, 5, 7, 10)))
print("chart, Ho-Lee rule bp   " + " ".join(f"{0.5 * SIGMA ** 2 * t * (t + h) * bp:6.2f}" for t in (0.5, 1, 2, 3, 4, 5, 7, 10)))

assert abs((R_rich - K160) - (c["R"] - c["K"])) < 0.01 / bp,  "tree, fitted by itself, lands on the formula"
assert abs((Rm - Km) - (c["R"] - c["K"])) < 4 * se,         "Monte Carlo within four standard errors"
assert abs(Wm / D(U) - 1) < 1e-3,                           "simulated bank reprices the curve"
assert abs(hull_cc - c["cc"]) < 1e-12,                      "Hull's printed formula equals the derived one"
assert abs(tiny - ho_lee) < 1e-3 * ho_lee,                  "no mean reversion gives the Ho-Lee rule"
print("ALL CHECKS PASS")
