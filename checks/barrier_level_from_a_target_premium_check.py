# Solving for the barrier -- the check behind the card.  Standard library only.
# EURUSD 1.10, USD rate 5%, EUR rate 3%, vol 10%, one year, 1 EUR notional, prices in USD.
# Nothing imported knows the answer: the normal CDF is a series, the integrals are
# Simpson's rule, the root finder is bisection, the random numbers are splitmix64.
from math import exp, log, sqrt, pi, cos
S, K, RD, RF, SIG, T = 1.10, 1.10, 0.05, 0.03, 0.10, 1.0
D, V = exp(-RD * T), SIG * sqrt(T)

def N(x):                                   # bell-curve area left of x, by its Taylor series
    if x < -9.0: return 0.0
    if x > 9.0: return 1.0
    t, s = x, x
    for k in range(1, 200):
        t *= x * x / (2 * k + 1); s += t
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def d2(x, k, rd=RD, rf=RF, s=SIG): return (log(x / k) + (rd - rf - 0.5 * s * s) * T) / (s * sqrt(T))
def call(x, k, rd=RD, rf=RF):
    return x * exp(-rf * T) * N(d2(x, k, rd, rf) + V) - k * exp(-rd * T) * N(d2(x, k, rd, rf))
def alpha(rd=RD, rf=RF): return 2.0 * (rd - rf - 0.5 * SIG * SIG) / (SIG * SIG)

# Road 1: closed forms by the method of images (a mirror start at H^2/S)
def do_img(H, rd=RD, rf=RF): return call(S, K, rd, rf) - (H / S) ** alpha(rd, rf) * call(H * H / S, K, rd, rf)
def ot_img(H): return D * (N(d2(S, H)) + (H / S) ** alpha() * N(-d2(H * H / S, H)))
def dig(k, s=SIG): return D * N(d2(S, k, s=s))

# Road 2: integrate the payoff against the density of paths that never met the wall (no N used)
MU = RD - RF - 0.5 * SIG * SIG
def simpson(f, a, b, n=4000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def alive(x, b): return (phi((x - MU * T) / V) - exp(2 * MU * b / SIG ** 2) * phi((x - 2 * b - MU * T) / V)) / V
def do_int(H):
    b = log(H / S); return D * simpson(lambda x: (S * exp(x) - K) * alive(x, b), log(K / S), MU * T + 10 * V)
def ot_int(H):
    b = log(H / S); return D * (1.0 - simpson(lambda x: alive(x, b), MU * T - 10 * V, b))
def dig_int(k): return D * simpson(lambda x: phi((x - MU * T) / V) / V, log(k / S), MU * T + 10 * V)

def bisect(f, lo, hi, target):             # f must change side of target between lo and hi
    flo = f(lo) - target
    for _ in range(80):
        mid = 0.5 * (lo + hi); fm = f(mid) - target
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
    return 0.5 * (lo + hi)

# Road 3: Monte Carlo, monthly steps, Brownian-bridge chance of touching between months
state = [20260927]
def unif():
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 1e-17
def mc(H, kind, paths=40000, steps=12):
    b, dt, tot, tot2 = log(H / S), T / steps, 0.0, 0.0
    for _ in range(paths):
        x, live = 0.0, 1.0
        for _ in range(steps):
            z = sqrt(-2.0 * log(unif())) * cos(2.0 * pi * unif())
            y = x + MU * dt + SIG * sqrt(dt) * z
            if (y - b) * (x - b) <= 0: live = 0.0
            else: live *= 1.0 - exp(-2.0 * (b - x) * (b - y) / (SIG * SIG * dt))
            x = y
        pay = live * max(S * exp(x) - K, 0.0) if kind == "do" else 1.0 - live
        tot += pay; tot2 += pay * pay
    m = tot / paths
    return D * m, D * sqrt((tot2 / paths - m * m) / paths)

vanilla = call(S, K); target = 0.5 * vanilla
H1, H2 = bisect(do_img, 0.5, S, target), bisect(do_int, 0.5, S, target)
U1, U2 = bisect(ot_img, S, 3.0, 0.30), bisect(ot_int, S, 3.0, 0.30)
K1 = S * exp((RD - RF - 0.5 * SIG * SIG) * T - V * bisect(N, -9.0, 9.0, 0.30 / D))
K2 = bisect(dig_int, 0.5, 3.0, 0.30)
p12 = dig(1.20); z = bisect(N, -9.0, 9.0, p12 / D); a = log(S / 1.20) + (RD - RF) * T
lo_q, hi_q = -z - sqrt(z * z + 2 * a), -z + sqrt(z * z + 2 * a)     # sigma*sqrt(T) = -z -/+ root
peak = sqrt(-2 * a / T)
lo_b, hi_b = bisect(lambda s: dig(1.20, s), 0.001, peak, p12), bisect(lambda s: dig(1.20, s), peak, 3.0, p12)
mc_do, se_do = mc(H1, "do"); mc_ot, se_ot = mc(U1, "ot")
h = 1e-5
rows = [("forward F = S e^((rd-rf)T)", S * exp((RD - RF) * T)), ("house: vanilla EUR call 1.10", vanilla), ("house: down-and-out, H 1.05, images", do_img(1.05)),
        ("house: down-and-out, H 1.05, integral", do_int(1.05)), ("house: one-touch 1.20, images", ot_img(1.20)),
        ("house: one-touch 1.20, integral", ot_int(1.20)), ("image exponent alpha", alpha()),
        ("target: half the vanilla", target), ("KO level, road 1 images", H1), ("KO level, road 2 integral", H2),
        ("  mirror start H^2/S", H1 * H1 / S), ("  (H/S)^alpha", (H1 / S) ** alpha()), ("  vanilla at mirror start", call(H1 * H1 / S, K)),
        ("KO price at level, road 1", do_img(H1)), ("KO price at level, road 3 MC", mc_do), ("  MC standard error", se_do),
        ("KO slope dP/dH at level, road 1", (do_img(H1 + h) - do_img(H1 - h)) / (2 * h)),
        ("KO slope dP/dH at level, road 2", (do_int(H1 + h) - do_int(H1 - h)) / (2 * h)),
        ("touch level for 0.30, road 1", U1), ("touch level for 0.30, road 2", U2),
        ("touch price at level, road 3 MC", mc_ot), ("  MC standard error", se_ot),
        ("touch ceiling D (level at spot)", D), ("digital strike for 0.30, road 1", K1),
        ("digital strike for 0.30, road 2", K2), ("digital at the touch level", dig(U1)),
        ("digital 1.20 at 10% vol", p12), ("vol root low, quadratic", lo_q), ("vol root high, quadratic", hi_q),
        ("vol root low, bisection", lo_b), ("vol root high, bisection", hi_b),
        ("vol at the peak", peak), ("digital 1.20 peak price", dig(1.20, peak)),
        ("wrong: rates swapped, KO level", bisect(lambda H: do_img(H, RF, RD), 0.5, S, target)),
        ("wrong: digital strike as touch level", ot_img(K1)),
        ("wrong: touch = 2 x digital, level", bisect(lambda H: 2 * dig(H), S, 3.0, 0.30)),
        ("  true touch price there", ot_img(bisect(lambda H: 2 * dig(H), S, 3.0, 0.30))),
        ("wrong: bracket 1%..200%, price at 1%", dig(1.20, 0.01)), ("  price at 200%", dig(1.20, 2.0))]
for name, v in rows: print(f"{name:<40}{v:>12.6f}")
for f in (0.10, 0.25, 0.75, 0.90): print(f"{'KO level for ' + format(f, '.0%') + ' of vanilla':<40}{bisect(do_img, 0.5, S, f * vanilla):>12.6f}")
lo, hi, tr = 1.00, 1.10, []
for _ in range(6):
    m = 0.5 * (lo + hi); tr.append((m, do_img(m)))
    lo, hi = (m, hi) if tr[-1][1] > target else (lo, m)
print("bisection H  " + " ".join(f"{m:.6f}" for m, _ in tr))
print("bisection P  " + " ".join(f"{p:.6f}" for _, p in tr))
lv = [0.95, 1.00, 1.02, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.10]
print("chart KO level  " + " ".join(f"{x:.2f}" for x in lv))
print("chart KO price  " + " ".join(f"{do_img(min(x, S)):.4f}" for x in lv))
up = [1.10, 1.15, 1.20, 1.25, 1.30, 1.35, 1.40]
print("chart up level  " + " ".join(f"{x:.2f}" for x in up))
print("chart touch %   " + " ".join(f"{100 * ot_img(x):.2f}" for x in up))
print("chart digital % " + " ".join(f"{100 * dig(x):.2f}" for x in up))
vs = [0.02, 0.05, 0.10, 0.20, 0.30, 0.40, 0.60, 0.80, 1.00, 1.34, 1.60, 2.00]
print("chart vol       " + " ".join(f"{x:.2f}" for x in vs))
print("chart dig 1.20 % " + " ".join(f"{100 * dig(1.20, x):.2f}" for x in vs))

assert abs(do_img(1.05) - 0.041661) < 5e-7, "house knock-out"
assert abs(ot_img(1.20) - 0.4142) < 5e-5, "house one-touch"
assert abs(H1 - H2) < 1e-6 and abs(U1 - U2) < 1e-6 and abs(K1 - K2) < 1e-6, "roads 1 and 2 agree on each level"
assert abs(mc_do - target) < 4 * se_do and abs(mc_ot - 0.30) < 4 * se_ot, "simulation lands on the targets"
assert abs(lo_q - lo_b) < 1e-6 and abs(hi_q - hi_b) < 1e-6 and abs(lo_q - SIG) < 1e-6, "two vols, two ways"
print("ALL CHECKS PASS")
