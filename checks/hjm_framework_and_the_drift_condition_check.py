# HJM drift condition -- the check behind the card.  Standard library only.
# One-factor HJM, exponential volatility sigma(t,T) = 0.01 e^{-0.3 (T - t)},
# today's forward curve f(0,T) = 0.05 - 0.01 e^{-0.3 T}.  Four roads:
# 1 drift from the volatility: closed form against quadrature
# 2 the exact bell-curve law of the discounted bond: E[D(1) P(1,5)] = P(0,5)?
# 3 Monte Carlo: 100,000 simulated curves, same question
# 4 Hull-White inside HJM: theta(t), convexity, and the bond from r(1) alone
from math import exp, log, sqrt, cos, pi

A, SIG = 0.3, 0.01                       # fade speed per year, front volatility

def f0(T): return 0.05 - 0.01 * exp(-0.3 * T)                 # today's forward curve
def f0_area(T): return 0.05 * T - 0.01 * (1 - exp(-0.3 * T)) / 0.3
def P0(T): return exp(-f0_area(T))                          # today's bond prices
def vol(t, T): return SIG * exp(-A * (T - t))
def b(h): return (1 - exp(-A * h)) / A

def simpson(g, lo, hi, n=200):
    if hi <= lo: return 0.0
    h = (hi - lo) / n
    s = g(lo) + g(hi) + sum((4 if k % 2 else 2) * g(lo + k * h) for k in range(1, n))
    return s * h / 3

def alpha(t, T): return SIG * SIG * exp(-A * (T - t)) * b(T - t)   # drift condition, closed
def alpha_quad(t, T): return vol(t, T) * simpson(lambda u: vol(t, u), t, T)

# ---- road 1: the drift is the volatility times the volatility area ----
print("road 1: alpha(t,T) = sigma(t,T) x A(t,T), per year")
print(" (t,T)     sigma(t,T)    A(t,T)      closed         quadrature")
gap1 = 0.0
for t, T in ((0, 1), (0, 5), (1, 5), (0, 10), (0, log(2) / A)):
    ac, aq = alpha(t, T), alpha_quad(t, T)
    gap1 = max(gap1, abs(ac - aq))
    print(f" ({t},{T:5.2f})  {vol(t, T):.7f}  {SIG * b(T - t):.7f}  {ac:.10f}  {aq:.10f}")
print(f" peak drift sigma^2/(4a) = {SIG * SIG / (4 * A):.10f}")

# ---- road 2: exact law. log of D(1)P(1,5) is a bell curve; mean from drift, spread from vol ----
def drift_area(dr):          # int_0^1 int_0^u dr(v,u) dv du  +  int_1^5 int_0^1 dr(v,s) dv ds
    front = simpson(lambda u: simpson(lambda v: dr(v, u), 0, u, 60), 0, 1, 60)
    back = simpson(lambda s: simpson(lambda v: dr(v, s), 0, 1, 60), 1, 5, 60)
    return front + back
V = simpson(lambda v: simpson(lambda u: vol(v, u), v, 5) ** 2, 0, 1)   # variance of the exponent
def expect(dr): return P0(5) * exp(-drift_area(dr) + V / 2)
E_right = expect(alpha)
print()
print("road 2: exact bell-curve law of D(1) P(1,5)")
print(f" P(0,5) market                    {P0(5):.9f}   exponent {f0_area(5):.6f}")
print(f" drift area M                     {drift_area(alpha):.9f}")
print(f" half variance V/2                {V / 2:.9f}")
print(f" E[D(1)P(1,5)] drift condition    {E_right:.9f}")
wrongs = (("zero drift", lambda v, u: 0.0), ("drift sign flipped", lambda v, u: -alpha(v, u)),
          ("drift 1/2 sigma^2", lambda v, u: 0.5 * vol(v, u) ** 2))
for name, dr in wrongs:
    e = expect(dr)
    print(f" wrong: {name:<20} {e:.9f}  per $1m: {1e6 * (e - P0(5)):+8.2f}")

# ---- road 3: Monte Carlo of the whole curve (state X_t = int_0^t e^{-a(t-u)} dW_u) ----
state = 2026
def normal():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % (1 << 64)
    u1 = ((state >> 11) + 0.5) / 9007199254740992.0
    state = (state * 6364136223846793005 + 1442695040888963407) % (1 << 64)
    u2 = ((state >> 11) + 0.5) / 9007199254740992.0
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2)
def G(t, T):                              # int_0^t alpha(u,T) du, closed form
    return SIG * SIG / A * ((exp(-A * (T - t)) - exp(-A * T)) / A
                            - (exp(-2 * A * (T - t)) - exp(-2 * A * T)) / (2 * A))
N, M = 100000, 25
dt = 1.0 / M
fade, kick = exp(-A * dt), sqrt((1 - exp(-2 * A * dt)) / (2 * A))
r_det = [f0(k * dt) + G(k * dt, k * dt) for k in range(M + 1)]
r_nod = [f0(k * dt) for k in range(M + 1)]
back_det = f0_area(5) - f0_area(1) + simpson(lambda s: G(1, s), 1, 5)
back_nod = f0_area(5) - f0_area(1)
disc_det = sum(0.5 * (r_det[k - 1] + r_det[k]) * dt for k in range(1, M + 1))
disc_nod = sum(0.5 * (r_nod[k - 1] + r_nod[k]) * dt for k in range(1, M + 1))
s1 = s2 = z1 = fm = fs = 0.0
for _ in range(N):
    X, I = 0.0, 0.0                       # state, and the area under it over the year
    for _k in range(M):
        Xn = fade * X + kick * normal()
        I += 0.5 * (X + Xn) * dt
        X = Xn
    shock_d, shock_p = SIG * I, SIG * b(4) * X
    y = exp(-(disc_det + shock_d)) * exp(-(back_det + shock_p))
    s1 += y; s2 += y * y
    z1 += exp(-(disc_nod + shock_d)) * exp(-(back_nod + shock_p))
    f15 = f0(5) + G(1, 5) + SIG * exp(-4 * A) * X
    fm += f15; fs += f15 * f15
mc = s1 / N
se = sqrt((s2 / N - mc * mc) / N)
mc_zero = z1 / N
f_mean, f_sd = fm / N, sqrt(fs / N - (fm / N) ** 2)
sd_exact = SIG * exp(-4 * A) * sqrt((1 - exp(-2 * A)) / (2 * A))
print()
print(f"road 3: Monte Carlo, {N} curves, {M} steps in the year")
print(f" f(1,5) mean   exact {f0(5) + G(1, 5):.6f}   simulated {f_mean:.6f}")
print(f" f(1,5) sd     exact {sd_exact:.6f}   simulated {f_sd:.6f}")
print(f" E[D(1)P(1,5)] drift condition  {mc:.6f}  SE {se:.6f}  off by {(mc - P0(5)) / se:+.2f} SE")
print(f" E[D(1)P(1,5)] zero drift       {mc_zero:.6f}  SE {se:.6f}  off by {(mc_zero - P0(5)) / se:+.2f} SE")

# ---- road 4: Hull-White inside HJM ----
def mean_r(t): return f0(t) + simpson(lambda u: alpha(u, t), 0, t)   # expected r(t), HJM side
def theta_hw(t): return 0.003 * exp(-0.3 * t) + A * f0(t) + SIG * SIG / (2 * A) * (1 - exp(-2 * A * t))
print()
print("road 4: Hull-White inside HJM")
gap4 = 0.0
for t in (1.0, 2.0, 5.0, 10.0):
    h = 1e-4
    th = (mean_r(t + h) - mean_r(t - h)) / (2 * h) + A * mean_r(t)
    gap4 = max(gap4, abs(th - theta_hw(t)))
    print(f" theta({t:4.1f})  Hull-White {theta_hw(t):.8f}   from HJM curve {th:.8f}")
conv_hjm = simpson(lambda u: alpha(u, 1), 0, 1)
conv_hw = SIG * SIG / (2 * A * A) * (1 - exp(-A)) ** 2
print(f" convexity at t=1   HJM {conv_hjm:.10f}   Hull-White {conv_hw:.10f}")
X1 = sqrt((1 - exp(-2 * A)) / (2 * A))           # a one-sd upward shock of the state
def f1(s, x): return f0(s) + simpson(lambda u: alpha(u, s), 0, 1, 100) + SIG * exp(-A * (s - 1)) * x
p_curve = exp(-simpson(lambda s: f1(s, X1), 1, 5, 100))
r1 = f1(1, X1)
p_hw = P0(5) / P0(1) * exp(b(4) * f0(1) - SIG * SIG / (4 * A) * (1 - exp(-2 * A)) * b(4) ** 2 - b(4) * r1)
print(f" after +1 sd: r(1) {r1:.6f}   P(1,5) from curve {p_curve:.9f}   from r(1) {p_hw:.9f}")

# ---- chart points ----
print()
print("chart, maturity T (years)   " + " ".join(f"{T:5d}" for T in range(1, 11)))
print("chart, f(0,T) percent       " + " ".join(f"{100 * f0(T):5.2f}" for T in range(1, 11)))
print("chart, f(1,T) +1 sd percent " + " ".join(f"{100 * f1(T, X1):5.2f}" for T in range(1, 11)))
print("chart, f(1,T) -1 sd percent " + " ".join(f"{100 * f1(T, -X1):5.2f}" for T in range(1, 11)))
print("chart, alpha(0,T) bp/year   " + " ".join(f"{1e4 * alpha(0, T):5.2f}" for T in range(0, 11)))

assert gap1 < 1e-12,                        "drift: closed form vs quadrature"
assert abs(E_right - P0(5)) < 1e-10,        "exact law: drift condition makes the discounted bond fair"
assert abs(mc - P0(5)) < 3 * se,            "Monte Carlo lands on today's bond price"
assert (mc_zero - P0(5)) > 3 * se,          "zero drift leaves a detectable free return"
assert gap4 < 1e-7,                        "Hull-White theta from the HJM curve"
assert abs(p_curve - p_hw) < 1e-9,          "the whole HJM curve is priced by r(1) alone"
print("ALL CHECKS PASS")
