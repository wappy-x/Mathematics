# Commodity swap and average-price forward -- the check behind the card.  Standard library only.
# Twelve-month jet fuel swap, 10,000 bbl a month, 22 pricing days a month, paid at each month end.
# Nothing imported knows the answer: the random numbers come from a splitmix64 generator written
# out, the root finder is bisection written out, and the paths are simulated day by day.
from math import log, sqrt, exp, cos, pi

N_BBL, r, DAYS = 10000.0, 0.05, 22
STRIP = [100.00, 100.36, 100.73, 101.09, 101.45, 101.82, 102.18, 102.55, 102.91, 103.27, 103.64, 104.00]
MOVED = [103.00, 103.18, 103.36, 103.55, 103.73, 103.91, 104.09, 104.27, 104.45, 104.64, 104.82, 105.00]
REALISED, DONE = 102.60, 11                   # mid-month 1: 11 of 22 fixings banked, averaging 102.60

def disc(t0, rate=r): return [exp(-rate * ((i + 1) / 12.0 - t0)) for i in range(12)]

def fair(curve, D): return sum(d * f for d, f in zip(D, curve)) / sum(D)       # road 1

def pv(curve, K, D): return N_BBL * sum(d * (f - K) for d, f in zip(D, curve))  # fixed payer's value

def bisect(g, lo, hi):                                                         # road 2: pv(K) = 0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (g(lo) > 0) == (g(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

class Rng:                                                                     # splitmix64 + Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def z(self): return sqrt(-2.0 * log(1.0 - self.u())) * cos(2.0 * pi * self.u())

def simulate(curve, sigma, pairs, payoff, t0=0.0, banked=0, banked_avg=0.0):
    # road 3: month i's contract wanders as F_i exp(sigma W - sigma^2 (t - t0) / 2), one shared W;
    # a fixing on a day in month i reads month i's contract that day.  Antithetic pairs.
    rng, h, k = Rng(7), 1.0 / (12.0 * DAYS), len(payoff([curve[0]] * 12))
    acc, acc2 = [0.0] * k, [0.0] * k
    for _ in range(pairs):
        zs = [rng.z() for _ in range(12 * DAYS)]
        pair = [0.0] * k
        for sgn in (1.0, -1.0):
            w, t, avgs = 0.0, t0, []
            for i in range(12):
                s, n0 = (banked_avg * banked, banked) if i == 0 else (0.0, 0)
                for j in range(n0, DAYS):
                    tj = (i * DAYS + j + 1) * h
                    w += sgn * sigma * sqrt(tj - t) * zs[i * DAYS + j]
                    t = tj
                    s += curve[i] * exp(w - 0.5 * sigma * sigma * (tj - t0))
                avgs.append(s / DAYS)
            pair = [p + 0.5 * v for p, v in zip(pair, payoff(avgs))]
        acc = [a + p for a, p in zip(acc, pair)]
        acc2 = [a + p * p for a, p in zip(acc2, pair)]
    means = [a / pairs for a in acc]
    return means, [sqrt((b / pairs - m * m) / pairs) for b, m in zip(acc2, means)]

# ---- at inception ----
D0 = disc(0.0)
K = fair(STRIP, D0)
K_root = bisect(lambda k: pv(STRIP, k, D0), 90.0, 110.0)
annuity, simple = sum(D0), sum(STRIP) / 12.0
print(f"annuity, sum of 12 discount factors    {annuity:14.6f}")
print(f"sum of D(t_i) F_i over the 12 months   {sum(d * f for d, f in zip(D0, STRIP)):14.6f}")
print(f"road 1  fair fixed price, weighted     {K:14.6f}")
print(f"road 2  fair fixed price, bisection    {K_root:14.6f}")
sim = {}
for sig in (0.20, 0.40):
    cap = lambda a: [fair(a, D0), pv(a, K, D0), N_BBL * D0[11] * max(a[11] - K, 0.0)]
    sim[sig] = simulate(STRIP, sig, 20000, cap)
    (f, v, c), (sf, sv, sc) = sim[sig]
    print(f"road 3  vol {sig:.2f}: fair price          {f:14.6f}   se {sf:.6f}")
    print(f"        vol {sig:.2f}: swap value at K, $  {v:14.2f}   se {sv:.2f}")
    print(f"        vol {sig:.2f}: month-12 cap, $     {c:14.2f}   se {sc:.2f}")
print("month  forward   D(t_i)    gap F-K   PV of gap $   delta $ per $1")
for i in range(12):
    print(f"{i + 1:5d} {STRIP[i]:8.2f} {D0[i]:8.5f} {STRIP[i] - K:10.4f} {N_BBL * D0[i] * (STRIP[i] - K):13.2f} {N_BBL * D0[i]:13.2f}")
print(f"parallel delta, $ per $1 on all months {N_BBL * annuity:14.2f}")
print(f"rho, $ for rates up 1 percent          {pv(STRIP, K, disc(0.0, r + 0.01)):14.2f}")
print(f"chart, one month's net cash at avg 96..108, $000: " + " ".join(f"{N_BBL * (a - K) / 1000:.2f}" for a in range(96, 109, 2)))

# ---- that afternoon the strip moves: front up 3, back up 1 ----
K_new = fair(MOVED, D0)
m_gaps, m_offset = pv(MOVED, K, D0), N_BBL * (K_new - K) * annuity
print(f"moved: new fair fixed price            {K_new:14.6f}")
print(f"moved: gap, new fair price minus K    {K_new - K:14.6f}")
print(f"moved: mark, discounted sum of gaps, $ {m_gaps:14.2f}")
print(f"moved: mark, offsetting swap, $        {m_offset:14.2f}")

# ---- mid-month 1: 11 fixings banked at 102.60, curve as moved ----
t0 = DONE / (12.0 * DAYS)
D1 = disc(t0)
E = [(DONE * REALISED + (DAYS - DONE) * MOVED[0]) / DAYS] + MOVED[1:]
mark_mid = pv(E, K, D1)
mark_off = N_BBL * (fair(E, D1) - K) * sum(D1)
(mc_mid,), (se_mid,) = simulate(MOVED, 0.20, 20000, lambda a: [pv(a, K, D1)], t0, DONE, REALISED)
bumped = [MOVED[0] + 1.0] + MOVED[1:]
E_b = [(DONE * REALISED + (DAYS - DONE) * bumped[0]) / DAYS] + bumped[1:]
delta1 = pv(E_b, K, D1) - mark_mid
wrong_unbanked = pv(MOVED, K, D1)
print(f"mid-month: month 1 expected average    {E[0]:14.6f}")
print(f"mid-month: month 1 discount factor    {D1[0]:14.6f}")
print(f"mid-month: mark, formula, $            {mark_mid:14.2f}")
print(f"mid-month: mark, offsetting swap, $    {mark_off:14.2f}")
print(f"mid-month: mark, simulated, $          {mc_mid:14.2f}   se {se_mid:.2f}")
print(f"mid-month: month 1 delta by bump, $    {delta1:14.2f}")
print(f"wrong: plain average as fixed price    {simple:14.6f}")
print(f"  its value to the fixed payer, $      {pv(STRIP, simple, D0):14.2f}")
print(f"wrong: fixed at today's front 100, $   {pv(STRIP, 100.0, D0):14.2f}")
print(f"wrong: moved mark undiscounted, $      {N_BBL * sum(f - K for f in MOVED):14.2f}")
print(f"wrong: mid-month, banked half ignored  {wrong_unbanked:14.2f}")
print(f"try: rates at zero, fair price        {fair(STRIP, disc(0.0, 0.0)):14.6f}")
print(f"try: strip reversed, fair price        {fair(STRIP[::-1], D0):14.6f}")
print(f"try: rates at 10 percent, fair price   {fair(STRIP, disc(0.0, 0.10)):14.6f}")
print("bars, month 1 barrels still exposed, fixings left 22 16 11 6 0: " +
      " ".join(f"{N_BBL * n / DAYS:.2f}" for n in (22, 16, 11, 6, 0)))

assert abs(K - K_root) < 1e-9, "closed form vs bisection on the value"
assert abs(annuity - exp(-r / 12) * (1 - exp(-r)) / (1 - exp(-r / 12))) < 1e-9, "annuity vs geometric series"
assert abs(sim[0.20][0][0] - K) < 4 * sim[0.20][1][0], "simulated fair price at 20% vol"
assert abs(sim[0.40][0][0] - K) < 4 * sim[0.40][1][0], "simulated fair price at 40% vol"
assert sim[0.40][0][2] > 1.5 * sim[0.20][0][2], "a cap on the average does depend on vol"
assert abs(m_gaps - m_offset) < 1e-6, "sum of gaps vs offsetting swap"
assert abs(mark_off - mark_mid) < 1e-6, "mid-month mark vs offsetting swap"
assert abs(mc_mid - mark_mid) < 4 * se_mid, "simulated mid-month mark"
assert abs(delta1 - N_BBL * D1[0] * (DAYS - DONE) / DAYS) < 1e-6, "month-1 delta scales with fixings left"
print("ALL CHECKS PASS")
