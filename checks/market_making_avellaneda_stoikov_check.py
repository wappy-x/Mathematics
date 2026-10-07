# Market making, Avellaneda-Stoikov -- the check behind the card.  Standard library only.
# Units: one lot = 100 shares; prices, sigma, distances in dollars per lot; time in trading days;
# gamma per dollar.  The normal average, maximiser, ODE solver and random numbers are written here.
from math import exp, log, sqrt, cos, pi

S0, SIG, GAM, K, A, Q0, T = 10000.0, 20.0, 0.001, 0.5, 30.0, 5, 1.0
STEPS, QCAP, QM = 1000, 10, 30               # time steps a day, inventory cap, exact-solve range

def conc(g, k): return log(1.0 + g / k) / g  # c: the price of being filled less often

def quotes(s, q, tau, g=GAM, sig=SIG, k=K, skew=True):   # road 1: the closed form
    risk = g * sig * sig * tau
    r = s - q * risk if skew else s          # reservation centre
    w = risk + 2.0 * conc(g, k)              # full spread
    return r - w / 2, r + w / 2, r, w

def cert_equiv(q, tau):                      # road 2: frozen inventory, averaged over the bell curve
    f = lambda z: exp(-GAM * q * SIG * sqrt(tau) * z - z * z / 2) / sqrt(2 * pi)
    n, a, b = 4000, -12.0, 12.0
    h = (b - a) / n
    m = (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
    return q * S0 - log(m) / GAM             # dollars for sure that the dealer rates as equal

def gain(delta, d, a=A):                     # expected utility gain rate from one side
    return a / GAM * exp(-K * delta) * (1.0 - exp(-GAM * (delta + d)))

def golden_max(f, lo, hi):                   # road 2 to the best distance: golden-section search
    g = (sqrt(5.0) - 1.0) / 2.0
    for _ in range(120):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(x1) < f(x2): lo = x1
        else: hi = x2
    return (lo + hi) / 2

def exact_v(tau, a=A, n=2000):               # road 3: full HJB, linear after v = e^{k h}; RK4
    eta = a * (1 + GAM / K) ** -(1 + K / GAM)
    alf = K * GAM * SIG * SIG / 2
    qs = range(-QM, QM + 1)
    def rhs(v):
        return [-alf * q * q * v[i] + eta * ((v[i - 1] if i > 0 else 0.0) + (v[i + 1] if i < 2 * QM else 0.0))
                for i, q in enumerate(qs)]
    v, h = [1.0] * (2 * QM + 1), tau / n
    for _ in range(n):
        k1 = rhs(v); k2 = rhs([x + h / 2 * y for x, y in zip(v, k1)])
        k3 = rhs([x + h / 2 * y for x, y in zip(v, k2)]); k4 = rhs([x + h * y for x, y in zip(v, k3)])
        v = [x + h / 6 * (p + 2 * r + 2 * s + t) for x, p, r, s, t in zip(v, k1, k2, k3, k4)]
    return v

def exact_quotes(v, q):                      # distances from mid: ask, bid
    i = q + QM
    return conc(GAM, K) + log(v[i] / v[i - 1]) / K, conc(GAM, K) + log(v[i] / v[i + 1]) / K

class Lcg:                                   # 32-bit linear congruential generator
    def __init__(self, seed): self.state = seed
    def uniform(self):
        self.state = (1664525 * self.state + 1013904223) & 0xFFFFFFFF
        return (self.state + 0.5) / 4294967296.0
    def normal(self):                        # Box-Muller
        u1, u2 = self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def day(seed, skew):                         # one day: at most one fill per step, then the mid moves
    rng, s, q, cash, path, dt = Lcg(seed), S0, Q0, 0.0, [], T / STEPS
    for i in range(STEPS):
        if i % 100 == 0: path.append(q)
        bid, ask, _, _ = quotes(s, q, T - i * dt, skew=skew)
        ra = A * exp(-K * (ask - s)) if q > -QCAP else 0.0
        rb = A * exp(-K * (s - bid)) if q < QCAP else 0.0
        u = rng.uniform()
        if u < ra * dt: cash += ask; q -= 1
        elif u < (ra + rb) * dt: cash -= bid; q += 1
        s += SIG * sqrt(dt) * rng.normal()
    path.append(q)
    return cash + q * s - Q0 * S0, q, path

def show(label, *vals, fmt="{:.6f}"): print(f"{label:<48}" + "  ".join(fmt.format(v) for v in vals))

bid, ask, r, w = quotes(S0, Q0, T)
rb_q = cert_equiv(Q0 + 1, T) - cert_equiv(Q0, T)      # most the dealer pays for one more lot
ra_q = cert_equiv(Q0, T) - cert_equiv(Q0 - 1, T)      # least the dealer takes for one lot fewer
risk = GAM * SIG * SIG * T
da_g = golden_max(lambda x: gain(x, risk * (Q0 - 0.5)), -50.0, 50.0)
db_g = golden_max(lambda x: gain(x, -risk * (Q0 + 0.5)), -50.0, 50.0)
v_full, v_none = exact_v(T), exact_v(T, a=1e-9)       # with fills, and with none at all
(ea, eb), (ta, tb) = exact_quotes(v_full, Q0), exact_quotes(v_none, Q0)
hs = [[log(x) / K for x in v] for v in (exact_v(T - 1e-3), v_full, exact_v(T + 1e-3))]   # h_q = ln(v_q)/k
i5 = Q0 + QM; da_x, db_x = [golden_max(lambda x: gain(x, hs[1][j] - hs[1][i5]), -50.0, 50.0) for j in (i5 - 1, i5 + 1)]
hjb = -GAM * SIG * SIG * Q0 * Q0 / 2 + gain(da_x, hs[1][i5 - 1] - hs[1][i5]) + gain(db_x, hs[1][i5 + 1] - hs[1][i5])
show("concession c = ln(1 + gamma/k)/gamma", conc(GAM, K))
show("risk per lot gamma sigma^2 T", risk)
show("1 closed form: centre r = S - q gamma sigma^2 T", r)
show("2 bell-curve average: reservation bid, ask", rb_q, ra_q)
show("2 bell-curve average: centre, gap", (rb_q + ra_q) / 2, ra_q - rb_q)
show("spread w = gamma sigma^2 T + 2c", w)
show("quotes per share, long 5 lots: bid, ask", bid / 100, ask / 100, fmt="{:.4f}")
fb, fa, _, _ = quotes(S0, 0, T)
show("quotes per share, flat: bid, ask", fb / 100, fa / 100, fmt="{:.4f}")
show("ask distance: closed form, golden search", ask - S0, da_g)
show("bid distance: closed form, golden search", S0 - bid, db_g)
show("fills per day at those distances: ask, bid", A * exp(-K * (ask - S0)), A * exp(-K * (S0 - bid)), fmt="{:.2f}")
show("3 full HJB solve: ask distance, bid distance", ea, eb)
show("3 full HJB: centre shift, spread", (ea - eb) / 2, ea + eb)
show("3 full HJB with no fills: ask, bid distance", ta, tb)
show("3 golden search on solved h: ask, bid distance", da_x, db_x)
show("3 dh/dtau: finite difference, HJB right side", (hs[2][i5] - hs[0][i5]) / 2e-3, hjb)
cents = lambda x: x - S0                     # dollars per lot from $10,000 = cents per share from $100
line = lambda name, xs, f="6.2f": print(f"{name:<32}" + " ".join(format(x, f) for x in xs))
line("chart, inventory q (lots)", range(-5, 6), "6d")
line("chart, bid, cents from $100", [cents(quotes(S0, q, T)[0]) for q in range(-5, 6)])
line("chart, ask, cents from $100", [cents(quotes(S0, q, T)[1]) for q in range(-5, 6)])
line("chart, inventory q (lots)", range(0, 11), "6d")
line("chart, closed-form centre shift", [cents(quotes(S0, q, T)[2]) for q in range(0, 11)])
line("chart, full-HJB centre shift", [(lambda a, b: (a - b) / 2)(*exact_quotes(v_full, q)) for q in range(0, 11)])
for tau in (1.0, 0.5, 0.1):
    b5, a5, _, _ = quotes(S0, 5, tau); b0, a0, _, _ = quotes(S0, 0, tau)
    show(f"time left {tau:.1f}: long bid, ask; flat bid, ask", b5 / 100, a5 / 100, b0 / 100, a0 / 100, fmt="{:.4f}")
for name, cen in (("wrong: skew added, not subtracted", S0 + Q0 * risk), ("wrong: sigma for sigma^2", S0 - Q0 * GAM * SIG),
                  ("wrong: tau left at 1 when 0.1 remains", S0 - Q0 * risk), ("  right at tau = 0.1", quotes(S0, Q0, 0.1)[2])):
    show(name + ", centre", cen / 100, fmt="{:.4f}")
(pnl_s, _, path_s), (pnl_m, _, path_m) = day(20260928, True), day(20260928, False)
line("story, fraction of the day", [i / 10 for i in range(11)])
line("story, lots, skewed quotes", path_s, "6d")
line("story, lots, centred quotes", path_m, "6d")
show("story P&L: skewed, centred", pnl_s, pnl_m, fmt="{:.2f}")
stats = {}
for skew in (True, False):
    runs = [day(1000 + j, skew) for j in range(400)]
    mean = sum(p for p, _, _ in runs) / 400
    sd = sqrt(sum((p - mean) ** 2 for p, _, _ in runs) / 399)
    stats[skew] = (mean, sd, sum(abs(q) for _, q, _ in runs) / 400)
    show(("400 days skewed" if skew else "400 days centred") + ": mean P&L, sd, mean |q| end", *stats[skew], fmt="{:.2f}")
show("try: gamma 0.002: centre, spread per share", quotes(S0, Q0, T, g=0.002)[2] / 100, quotes(S0, Q0, T, g=0.002)[3] / 100, fmt="{:.4f}")
show("try: k 0.25: spread per share", quotes(S0, Q0, T, k=0.25)[3] / 100, fmt="{:.4f}")
show("try: sigma 40: centre, spread per share", quotes(S0, Q0, T, sig=40.0)[2] / 100, quotes(S0, Q0, T, sig=40.0)[3] / 100, fmt="{:.4f}")
assert abs((rb_q + ra_q) / 2 - r) < 1e-6 and abs(ra_q - rb_q - risk) < 1e-6, "quadrature vs closed form"
assert abs(da_g - (ask - S0)) < 1e-5 and abs(db_g - (S0 - bid)) < 1e-5, "golden search vs c - d"
assert abs(ta - (ask - S0)) < 1e-6 and abs(tb - (S0 - bid)) < 1e-6, "HJB with no fills = frozen inventory"
assert abs(da_x - ea) < 1e-5 and abs(db_x - eb) < 1e-5 and abs((hs[2][i5] - hs[0][i5]) / 2e-3 - hjb) < 1e-4, "full solve satisfies the HJB"
assert stats[True][1] < stats[False][1] and stats[True][2] < stats[False][2], "skew cuts risk and inventory"
print("ALL CHECKS PASS")
