# Forward CDS on Northwind: protection from year 1 to year 5, knocked out by an earlier default.
# Quarterly premiums paid while alive, protection paid at the default date. Standard library only.
from math import exp, log, sqrt
RATE, DT, NOTIONAL = 0.05, 0.25, 10_000_000.0          # riskless rate, premium period, dollars
QUOTES = [(1.0, 0.0120), (3.0, 0.0200), (5.0, 0.0250)]  # (tenor, par spread) for Northwind
T1, T2, K = 1.0, 5.0, 0.0250                            # forward window; contract spread 250 bp

def surv(t, c):                                         # S(t) = exp(-area under the step hazard)
    return exp(-sum(h * max(min(t, b) - a, 0.0) for a, b, h in c))

def ann(a, b, c):                                       # premium-years paid on dates in (a, b]
    return sum(DT * exp(-RATE * j * DT) * surv(j * DT, c) for j in range(round(a / DT) + 1, round(b / DT) + 1))

def prot(a, b, c, loss):                                # protection for defaults in (a, b], closed form per piece
    tot = 0.0
    for p, q, h in c:
        u0, u1 = max(a, p), min(b, q)
        if u1 > u0:
            k = RATE + h
            tot += loss * exp(-RATE * u0) * surv(u0, c) * h / k * (1.0 - exp(-k * (u1 - u0)))
    return tot

def prot_simpson(a, b, c, loss, n=2000):                # road 2: integrate L lambda S D, one piece at a time
    tot = 0.0
    for p, q, h in c:
        u0, u1 = max(a, p), min(b, q)
        if u1 <= u0: continue
        w = (u1 - u0) / n
        f = lambda t: loss * h * surv(t, c) * exp(-RATE * t)
        tot += w / 3 * (f(u0) + f(u1) + sum((4 if i % 2 else 2) * f(u0 + i * w) for i in range(1, n)))
    return tot

def boot(quotes, loss):                                 # one flat piece per quote, bisection, earlier pieces frozen
    c, start = [], 0.0
    for T, s in quotes:
        lo, hi = 0.0, 5.0
        for _ in range(200):
            m = 0.5 * (lo + hi); trial = c + [(start, 1e9, m)]
            if prot(0.0, T, trial, loss) > s * ann(0.0, T, trial): hi = m
            else: lo = m
        c.append((start, T, 0.5 * (lo + hi))); start = T
    c[-1] = (c[-1][0], 1e9, c[-1][2])                   # last piece carried on
    return c

def fwd(a, b, c, loss):                                 # forward par spread = forward protection / forward annuity
    return (prot(0.0, b, c, loss) - prot(0.0, a, c, loss)) / (ann(0.0, b, c) - ann(0.0, a, c))

def fwd_value(c, loss, k):                              # long T2 protection minus long T1 protection, both at k
    return ((prot(0.0, T2, c, loss) - k * ann(0.0, T2, c)) - (prot(0.0, T1, c, loss) - k * ann(0.0, T1, c))) * NOTIONAL

L = 0.60
cv = boot(QUOTES, L)
A1, A2, P1, P2 = ann(0, T1, cv), ann(0, T2, cv), prot(0, T1, cv, L), prot(0, T2, cv, L)
Af, Pf = A2 - A1, P2 - P1
F1 = Pf / Af
print("Northwind: r 0.05, recovery 0.40, quarterly premiums, quotes 120/200/250 bp; forward window 1y to 5y")
print(f"curve: hazards {cv[0][2]:.6f} {cv[1][2]:.6f} {cv[2][2]:.6f}  S(1) {surv(1, cv):.6f}  S(5) {surv(5, cv):.6f}")
print(f"spot legs: A(1) {A1:.6f}  P(1) {P1:.6f}  A(5) {A2:.6f}  P(5) {P2:.6f}")
print(f"road 1, legs subtracted: forward annuity {Af:.6f}  forward protection {Pf:.6f}  forward spread {F1 * 1e4:.4f} bp")
Pf2 = prot_simpson(T1, T2, cv, L)
F2 = Pf2 / ann(T1, T2, cv)
print(f"road 2, window priced directly (Simpson): forward protection {Pf2:.6f}  forward spread {F2 * 1e4:.4f} bp")
s1, s2 = QUOTES[0][1], QUOTES[2][1]
F3 = s2 + (s2 - s1) * A1 / Af
print(f"road 3, annuity-weighted quotes: 250 + 130 x {A1 / Af:.6f} = {F3 * 1e4:.4f} bp")
# road 4: Monte Carlo default dates; a default before year 1 cancels the forward (both legs zero)
x = 20260928
def unif():
    global x
    x = (6364136223846793005 * x + 1442695040888963407) % 2**64
    return ((x >> 11) + 0.5) / 2**53
paths, sp, sa, spp, saa, spa, early = 400_000, 0.0, 0.0, 0.0, 0.0, 0.0, 0
for _ in range(paths):
    e, tau = -log(unif()), 1e9                          # exponential draw; tau where the hazard area reaches e
    for a, b, h in cv:
        if e <= h * (b - a): tau = a + e / h; break
        e -= h * (b - a)
    if tau <= T1: early += 1; continue
    pr = L * exp(-RATE * tau) if tau <= T2 else 0.0
    an = sum(DT * exp(-RATE * j * DT) for j in range(5, 21) if j * DT < tau)
    sp += pr; sa += an; spp += pr * pr; saa += an * an; spa += pr * an
mp, ma = sp / paths, sa / paths
F4 = mp / ma
var = (spp / paths - mp * mp) - 2 * F4 * (spa / paths - mp * ma) + F4 * F4 * (saa / paths - ma * ma)
se = sqrt(var / paths) / ma
print(f"road 4, Monte Carlo {paths} default dates: forward spread {F4 * 1e4:.2f} bp (standard error {se * 1e4:.2f})  knocked out {early / paths:.4f}")
print(f"  chance of default before year 1, 1 - S(1) = {1 - surv(1, cv):.4f}")
W = exp(-RATE * T1) * surv(T1, cv)
print(f"knock-out: D(1) {exp(-RATE * T1):.6f}  weight D(1)S(1) {W:.6f}  annuity at year 1 if alive {Af / W:.6f}  protection {Pf / W:.6f}  spread {Pf / Af * 1e4:.4f} bp")
print(f"triangle on the window's average hazard: 0.60 x {(2 * cv[1][2] + 2 * cv[2][2]) / 4:.6f} = {L * (2 * cv[1][2] + 2 * cv[2][2]) / 4 * 1e4:.2f} bp")
flat = [(0.0, 1e9, 0.02)]
fs, ff = prot(0, 5, flat, L) / ann(0, 5, flat), fwd(1, 5, flat, L)
kf = RATE + 0.02
fc = L * 0.02 / kf * (1 - exp(-kf * DT)) / (DT * exp(-kf * DT))
print(f"flat 2% hazard: spot 5y {fs * 1e4:.4f} bp  forward 1y-5y {ff * 1e4:.4f} bp  tenor-free formula {fc * 1e4:.4f} bp")
V = fwd_value(cv, L, K)
print(f"forward protection bought at 250 bp on $10m: value ${V:.2f}  = (F - K) x A_f x N ${(F1 - K) * Af * NOTIONAL:.2f}")
print(f"  front-end protection P(1) x N, what a no-knock-out contract adds: ${P1 * NOTIONAL:.2f}")
print("risk, forward bought at 250 bp on $10m, each quote bumped 1 bp and the curve rebuilt")
bumps = {"1y": [1, 0, 0], "3y": [0, 1, 0], "5y": [0, 0, 1], "all": [1, 1, 1]}
for name, bmp in bumps.items():
    cb = boot([(T, s + 1e-4 * d) for (T, s), d in zip(QUOTES, bmp)], L)
    print(f"  {name:>3} quote +1 bp: forward spread {(fwd(T1, T2, cb, L) - F1) * 1e4:+.4f} bp  value ${round(fwd_value(cb, L, K) - V, 2) + 0.0:+.2f}")
print(f"  annuity rule A_f x 1 bp x N: ${Af * 1e-4 * NOTIONAL:.2f}; default before year 1: value ${-V:+.2f}")
print("what breaks")
print(f"  forward taken as the spot 5y quote: {s2 * 1e4:.2f} bp; value at 250 bp read as $0.00")
print(f"  time weights instead of annuity weights: (5 x 250 - 1 x 120) / 4 = {(5 * s2 - s1) / 4 * 1e4:.2f} bp")
print(f"  forward protection over the full A(5): {Pf / A2 * 1e4:.2f} bp")
print(f"  today's protection over the year-1 annuity: {Pf / (Af / W) * 1e4:.2f} bp")
print("try")
ci = boot([(1.0, 0.0300), (3.0, 0.0250), (5.0, 0.0200)], L)
print(f"  inverted quotes 300/250/200: forward 1y-5y {fwd(T1, T2, ci, L) * 1e4:.2f} bp")
c8 = boot(QUOTES, 0.80)
print(f"  recovery 20%, same quotes: forward 1y-5y {fwd(T1, T2, c8, 0.80) * 1e4:.2f} bp")
starts = [0, 1, 2, 3, 4]
print("chart, forward start (years) " + " ".join(f"{t:7d}" for t in starts))
print("chart, forward to 5y (bp)    " + " ".join(f"{fwd(t, 5, cv, L) * 1e4:7.2f}" for t in starts))
print("chart, flat 2% forward (bp)  " + " ".join(f"{fwd(t, 5, flat, L) * 1e4:7.2f}" for t in starts))
spreads = [100, 150, 200, 250, 300, 350, 400, 450, 500]
vals = []
for sp_bp in spreads:                                   # year-1 value if alive: flat curve fitted to a 4y quote
    lo, hi = 0.0, 1.0
    for _ in range(100):
        m = 0.5 * (lo + hi); cm = [(0.0, 1e9, m)]
        if prot(0, 4, cm, L) > sp_bp * 1e-4 * ann(0, 4, cm): hi = m
        else: lo = m
    cm = [(0.0, 1e9, 0.5 * (lo + hi))]
    vals.append((sp_bp * 1e-4 - F1) * ann(0, 4, cm) * NOTIONAL / 1000)
print("chart, 4y spread at year 1   " + " ".join(f"{s:7d}" for s in spreads))
print("chart, value at year 1 ($k)  " + " ".join(f"{v:7.2f}" for v in vals))
assert abs(F2 - F1) < 1e-9, "direct Simpson forward must match the subtracted legs"
assert abs(F3 - F1) < 1e-9, "annuity-weighted quotes must match the forward legs"
assert abs(F4 - F1) < 4 * se, "Monte Carlo with knock-out within four standard errors"
assert abs(V - (K - s1) * A1 * NOTIONAL) < 1e-4, "at K = s2 the forward is worth the one-year leg alone"
assert abs(ff - fc) < 1e-12 and abs(fs - fc) < 1e-12, "flat curve: forward and spot equal the tenor-free formula"
assert F1 > s2 and fwd(T1, T2, ci, L) < QUOTES[2][1] - 0.0050, "rising curve lifts the forward, falling lowers it"
print("ALL CHECKS PASS")
