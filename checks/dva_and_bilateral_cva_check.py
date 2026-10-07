# DVA and bilateral CVA -- the check behind the card.  Standard library only.
# Three roads: closed forms; Simpson integrals over the bell curve and over time;
# a simulation of both default dates with a home-made random number generator.
from math import exp, log, sqrt, erf, pi, cos

S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
lamN, RN = 0.02, 0.40                  # Northwind: hazard per year, recovery
lamB, RB = 0.01, 0.40                  # the bank: hazard per year, recovery
F = S * exp((r - q) * T)               # forward delivery price: forward worth 0 today

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def phi(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)

def call(s, tau):                      # Black-Scholes call, tau years left
    if tau <= 0.0: return max(s - K, 0.0)
    v = sig * sqrt(tau)
    d1 = (log(s / K) + (r - q + 0.5 * sig * sig) * tau) / v
    return s * exp(-q * tau) * N(d1) - K * exp(-r * tau) * N(d1 - v)

def fwd(s, tau): return s * exp(-q * tau) - F * exp(-r * tau)   # to the bank, who buys Acme

def simpson(vals, h):
    n = len(vals) - 1
    return h / 3.0 * (vals[0] + vals[n] + sum((4 if i % 2 else 2) * vals[i] for i in range(1, n)))

def ee(value, t, side):                # discounted expected exposure: side +1 owed to us, -1 we owe
    if t == 0.0: return max(side * value(S, T), 0.0)
    g = lambda z: side * value(S * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z), T - t)
    a, b = -8.0, 8.0
    if g(a) <= 0.0 and g(b) <= 0.0: return 0.0
    if g(a) <= 0.0 or g(b) <= 0.0:      # exposure starts at a kink: find it by bisection, integrate past it
        lo, hi = a, b
        for _ in range(80):
            mid = 0.5 * (lo + hi)
            if (g(mid) > 0.0) == (g(hi) > 0.0): hi = mid
            else: lo = mid
        a, b = (hi, b) if g(b) > 0.0 else (a, lo)
    h = (b - a) / 400
    return exp(-r * t) * simpson([max(g(a + i * h), 0.0) * phi(a + i * h) for i in range(401)], h)

NT = 200; HU = sqrt(T) / NT            # time grid t = u^2, which smooths the sqrt(t) start
TS = [(i * HU) ** 2 for i in range(NT + 1)]
def over_time(profile, lam_def, lam_other, R):   # (1-R) * integral of lam e^-(lam+other)t * profile dt
    return simpson([(1 - R) * lam_def * exp(-(lam_def + lam_other) * t) * p * 2 * sqrt(t) for t, p in zip(TS, profile)], HU)

C0 = call(S, T)
# road 1: closed forms
cva_uni = (1 - RN) * C0 * (1 - exp(-lamN * T))
cva_bil = (1 - RN) * C0 * lamN / (lamN + lamB) * (1 - exp(-(lamN + lamB) * T))
fwd_pe = [S * exp(-q * T) * (2 * N(0.5 * sig * sqrt(t)) - 1) for t in TS]   # EPE = ENE for the forward
f_cva1, f_dva1 = over_time(fwd_pe, lamN, lamB, RN), over_time(fwd_pe, lamB, lamN, RB)
# road 2: exposure profiles by integrating over the bell curve at every date
call_pe = [ee(call, t, +1) for t in TS]
call_ne = [ee(call, t, -1) for t in TS]
f_pe2 = [ee(fwd, t, +1) for t in TS]
f_ne2 = [ee(fwd, t, -1) for t in TS]
cva_uni2 = over_time(call_pe, lamN, 0.0, RN)
cva_bil2, dva_call_B = over_time(call_pe, lamN, lamB, RN), over_time(call_ne, lamB, lamN, RB)
f_cva2, f_dva2 = over_time(f_pe2, lamN, lamB, RN), over_time(f_ne2, lamB, lamN, RB)
# Northwind's own books: sold call and sold forward, values the other way round
sold = lambda s, tau: -call(s, tau)
sfwd = lambda s, tau: -fwd(s, tau)
nw_cva = over_time([ee(sold, t, +1) for t in TS], lamB, 0.0, RB)
nw_dva_uni = over_time([ee(sold, t, -1) for t in TS], lamN, 0.0, RN)
nw_dva_bil = over_time([ee(sold, t, -1) for t in TS], lamN, lamB, RN)
nw_f_cva = over_time([ee(sfwd, t, +1) for t in TS], lamB, lamN, RB)
nw_f_dva = over_time([ee(sfwd, t, -1) for t in TS], lamN, lamB, RN)

# road 3: simulate both default dates; close out at the first one if it comes before T
M = (1 << 64) - 1
state = 20260928
def rnd():                             # splitmix64, then a uniform strictly inside (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & M
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
PATHS = 4_000_000
sc = scc = sf = sff = 0.0
for _ in range(PATHS):
    tN, tB = -log(rnd()) / lamN, -log(rnd()) / lamB
    t = min(tN, tB)
    if t >= T: continue
    z = sqrt(-2.0 * log(rnd())) * cos(2.0 * pi * rnd())
    st = S * exp((r - q - 0.5 * sig * sig) * t + sig * sqrt(t) * z)
    vc, vf, d = call(st, T - t), fwd(st, T - t), exp(-r * t)
    if tN < tB: xc, xf = (1 - RN) * d * max(vc, 0.0), (1 - RN) * d * max(vf, 0.0)
    else: xc, xf = -(1 - RB) * d * max(-vc, 0.0), -(1 - RB) * d * max(-vf, 0.0)
    sc += xc; scc += xc * xc; sf += xf; sff += xf * xf
mc_c, mc_f = sc / PATHS, sf / PATHS
se_c, se_f = sqrt((scc / PATHS - mc_c ** 2) / PATHS), sqrt((sff / PATHS - mc_f ** 2) / PATHS)

bil_f = f_cva1 - f_dva1
rows = [
    ("call C0", C0), ("forward price F", F), ("discount D(1)", exp(-r * T)),
    ("Northwind defaults by 1y", 1 - exp(-lamN * T)), ("Northwind defaults first by 1y", lamN / (lamN + lamB) * (1 - exp(-(lamN + lamB) * T))),
    ("call, bank CVA unilateral, closed", cva_uni), ("call, bank CVA unilateral, integral", cva_uni2),
    ("call, bank risky price unilateral", C0 - cva_uni),
    ("call, Northwind CVA", nw_cva), ("call, Northwind DVA unilateral", nw_dva_uni),
    ("call, bank CVA bilateral, closed", cva_bil), ("call, bank CVA bilateral, integral", cva_bil2),
    ("call, bank DVA", dva_call_B), ("call, Northwind DVA bilateral", nw_dva_bil),
    ("call, price both agree on", C0 - cva_bil),
    ("call, bank BCVA simulated", mc_c), ("  standard error", se_c),
    ("fwd EPE at 1y, closed", fwd_pe[-1]), ("fwd EPE at 1y, integral", f_pe2[-1]),
    ("fwd ENE at 1y, integral", f_ne2[-1]),
    ("fwd, bank CVA, road 1", f_cva1), ("fwd, bank CVA, road 2", f_cva2),
    ("fwd, bank DVA, road 1", f_dva1), ("fwd, bank DVA, road 2", f_dva2),
    ("fwd, bank BCVA", bil_f), ("fwd, bank BCVA simulated", mc_f), ("  standard error", se_f),
    ("fwd, Northwind CVA", nw_f_cva), ("fwd, Northwind DVA", nw_f_dva),
    ("fwd, Northwind BCVA", nw_f_cva - nw_f_dva),
]
for name, v in rows: print(f"{name:<38}{v:>12.6f}")
print()
for lam in (0.0, 0.01, 0.02, 0.04, 0.08):     # Northwind's own credit worsens: sold call on its books
    dva = (1 - RN) * C0 * (1 - exp(-lam * T))
    print(f"own hazard {lam:4.2f}  Northwind DVA {dva:8.4f}  sold call booked at {-C0 + dva:9.4f}")
for lb in (0.01, 0.02, 0.03):                        # the bank's own credit worsens: the forward on its books
    b = over_time(fwd_pe, lamN, lb, RN) - over_time(fwd_pe, lb, lamN, RB)
    print(f"bank hazard {lb:4.2f}  fwd BCVA {b:8.4f}  forward booked at {-b:8.4f}")
print()
wrong = [
    ("wrong: fwd, CVA alone, DVA left out", over_time(fwd_pe, lamN, 0.0, RN)),
    ("wrong: fwd, DVA added not subtracted", f_cva1 + f_dva1),
    ("wrong: call, undiscounted exposure", (1 - RN) * lamN * C0 * (exp((r - lamN) * T) - 1) / (r - lamN)),
    ("wrong: call, buyer charged a DVA", cva_bil - (1 - RB) * C0 * lamB / (lamN + lamB) * (1 - exp(-(lamN + lamB) * T))),
]
for name, v in wrong: print(f"{name:<38}{v:>12.6f}")
print()
grid = [i / 10 for i in range(11)]
print("chart, years      " + " ".join(f"{t:5.1f}" for t in grid))
for lab, fn, sd in (("chart, call EPE   ", call, 1), ("chart, fwd EPE    ", fwd, 1), ("chart, fwd ENE    ", fwd, -1), ("chart, call ENE   ", call, -1)):
    print(lab + " ".join(f"{ee(fn, t, sd):5.2f}" for t in grid))

assert abs(cva_uni - 0.1096) < 5e-5, "house CVA from the shelf"
assert abs(cva_uni2 - cva_uni) < 1e-7 and abs(cva_bil2 - cva_bil) < 1e-7, "flat discounted exposure: integral road meets closed form"
assert abs(f_cva2 - f_cva1) < 1e-7 and abs(f_dva2 - f_dva1) < 1e-7, "forward: bell-curve road meets closed-form road"
assert abs(nw_dva_bil - cva_bil) < 1e-7 and abs(nw_f_cva - f_dva2) < 1e-7 and nw_cva + dva_call_B < 1e-12, "mirror: one side's CVA is the other's DVA"
assert abs(mc_c - cva_bil) < 4 * se_c and abs(mc_f - bil_f) < 4 * se_f, "simulation within 4 standard errors"
print("ALL CHECKS PASS")
