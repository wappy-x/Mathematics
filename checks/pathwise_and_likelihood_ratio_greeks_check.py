# Greeks inside the simulation -- the check behind the card.  Standard library
# only, and nothing imported that already knows an answer: the bell-curve area
# is Simpson's rule written out here, the normal draws come from a generator
# written out here.  Four roads to every Greek: the closed form, a bump on the
# exact price, the pathwise average, the score average.
from math import log, sqrt, exp, pi, cos, sin

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
CASH = 1.0                                  # the digital pays one dollar
HS, HV, HP = 0.01, 0.0001, 0.000001         # bumps: spot, volatility, per path
NPATH, SEED, MOD = 65536, 20260919, 1 << 32

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def nz(v): return 0.0 if v == 0.0 else v                   # print 0, never -0

def simpson(f, a, b, n):
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n): s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                                # bell-curve area to the left of x
    if x < -12.0 or x > 12.0: return 0.0 if x < 0.0 else 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)

def dees(s, sig, t):                        # the two distances, d1 and d2
    d2 = (log(s / K) + (R - Q - 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return d2 + sig * sqrt(t), d2

def call_px(s, sig, t):
    d1, d2 = dees(s, sig, t)
    return s * exp(-Q * t) * ncdf(d1) - K * exp(-R * t) * ncdf(d2)

def dig_px(s, sig, t): return CASH * exp(-R * t) * ncdf(dees(s, sig, t)[1])
def terminal(z, s, sig, t): return s * exp((R - Q - 0.5 * sig * sig) * t + sig * sqrt(t) * z)
def payoffs(st): return max(st - K, 0.0), (CASH if st > K else 0.0)   # call, digital

def estimators(z, s, sig, t):
    st = terminal(z, s, sig, t)
    on = 1.0 if st > K else 0.0             # the switch: Acme above the strike
    disc = exp(-R * t)
    dst_ds, dst_dsig = st / s, st * (sqrt(t) * z - sig * t)   # the path's slopes
    call_slope, dig_slope = on, 0.0         # payoff slopes: a kink, and a jump
    pay_call, pay_dig = payoffs(st)
    w_s = z / (s * sig * sqrt(t))                            # score for spot
    w_sig = (z * z - 1.0) / sig - sqrt(t) * z                # score for vol
    return (disc * call_slope * dst_ds,   disc * pay_call * w_s,
            disc * call_slope * dst_dsig, disc * pay_call * w_sig,
            disc * dig_slope * dst_ds,    disc * pay_dig * w_s,
            disc * dig_slope * dst_dsig,  disc * pay_dig * w_sig)

def quad(s, sig, t, n=4000):
    # Exact average and second moment of all eight estimators.  Every one of
    # them is zero below the strike crossing, so the panel starts just above it.
    lo = -dees(s, sig, t)[1] + 1e-11
    h, m1, m2 = (12.0 - lo) / n, [0.0] * 8, [0.0] * 8
    for i in range(n + 1):
        z = lo + i * h
        p = (1.0 if i in (0, n) else (4.0 if i % 2 else 2.0)) * phi(z)
        for j, y in enumerate(estimators(z, s, sig, t)):
            m1[j] += p * y; m2[j] += p * y * y
    return [v * h / 3.0 for v in m1], [v * h / 3.0 for v in m2]

def draws(n, seed):        # a linear step for the uniforms, then Box-Muller
    out, st = [], seed
    while len(out) < n:
        st = (1664525 * st + 1013904223) % MOD
        u = (st + 0.5) / MOD
        st = (1664525 * st + 1013904223) % MOD
        rad, ang = sqrt(-2.0 * log(u)), 2.0 * pi * ((st + 0.5) / MOD)
        out.append(rad * cos(ang)); out.append(rad * sin(ang))
    return out

d1, d2 = dees(S, SIG, T)
LO, DISC = -d2 + 1e-11, exp(-R * T)
exact = (exp(-Q * T) * ncdf(d1), S * exp(-Q * T) * phi(d1) * sqrt(T),
         CASH * DISC * phi(d2) / (S * SIG * sqrt(T)), -CASH * DISC * phi(d2) * d1 / SIG)
bumped = ((call_px(S + HS, SIG, T) - call_px(S - HS, SIG, T)) / (2 * HS),
          (call_px(S, SIG + HV, T) - call_px(S, SIG - HV, T)) / (2 * HV),
          (dig_px(S + HS, SIG, T) - dig_px(S - HS, SIG, T)) / (2 * HS),
          (dig_px(S, SIG + HV, T) - dig_px(S, SIG - HV, T)) / (2 * HV))
m1, m2 = quad(S, SIG, T)
sd = [sqrt(max(m2[j] - m1[j] * m1[j], 0.0)) for j in range(8)]
names = ("call delta pathwise", "call delta score", "call vega pathwise",
         "call vega score", "digital delta score", "digital vega score")
cols, aims = (0, 1, 2, 3, 5, 7), (exact[0], exact[0], exact[1], exact[1], exact[2], exact[3])
print("Acme: S=100 K=100 r=5% q=2% sigma=20% T=1; the digital pays $1 if Acme ends above 100")
print(f"d1 {d1:.6f}   d2 {d2:.6f}   call {call_px(S, SIG, T):.6f}   digital {dig_px(S, SIG, T):.6f}")
print(f"{'Greek':<16}{'closed form':>14}{'price bump':>14}{'pathwise':>14}{'score':>14}")
for name, j in (("call delta", 0), ("call vega", 2), ("digital delta", 4), ("digital vega", 6)):
    print(f"{name:<16}{exact[j // 2]:>14.6f}{bumped[j // 2]:>14.6f}{nz(m1[j]):>14.6f}{m1[j + 1]:>14.6f}")
print(f"five fixed draws, spot nudged {HS:.2f} either way, the same draw kept:")
print(f"{'Z':>7}{'Acme at expiry':>16}{'call payoff slope':>19}{'digital payoff slope':>22}")
for z in (-1.0, -0.06, -0.04, 0.5, 2.0):
    up, dn = payoffs(terminal(z, S + HS, SIG, T)), payoffs(terminal(z, S - HS, SIG, T))
    print(f"{z:>7.2f}{terminal(z, S, SIG, T):>16.4f}{(up[0] - dn[0]) / (2 * HS):>19.6f}{(up[1] - dn[1]) / (2 * HS):>22.6f}")
print(f"by hand: e^-rT {DISC:.6f}   e^-qT {exp(-Q * T):.6f}   N(d1) {ncdf(d1):.6f}"
      f"   phi(d2) {phi(d2):.6f}   S sigma sqrt(T) {S * SIG * sqrt(T):.6f}")
print("estimator spread per path, and the paths needed to pin the answer to 1 percent:")
for name, j in zip(names, cols):
    print(f"{name:<22}{'average':>9}{m1[j]:>13.6f}{'spread':>9}{sd[j]:>12.6f}{'paths':>7}{int((100.0 * sd[j] / abs(m1[j])) ** 2) + 1:>9d}")
def wrong(f, lo): return simpson(lambda z: f(z) * phi(z), lo, 12.0, 4000)
st_ = lambda z: terminal(z, S, SIG, T)
print("what breaks:")
for name, right, got in (
        ("switch dropped from the call's pathwise delta", exact[0], wrong(lambda z: DISC * st_(z) / S, -12.0)),
        ("sigma-T term dropped from the call's pathwise vega", exact[1], wrong(lambda z: DISC * st_(z) * sqrt(T) * z, LO)),
        ("drift term dropped from the digital's score vega", exact[3], wrong(lambda z: DISC * CASH * (z * z - 1.0) / SIG, LO)),
        ("discount forgotten in the digital's score delta", exact[2], wrong(lambda z: CASH * z / (S * SIG * sqrt(T)), LO))):
    print(f"{name:<52}{'right':>7}{right:>12.6f}{'wrong':>7}{got:>12.6f}")
tot, totsq, flips = [0.0] * 8, [0.0] * 8, 0
for z in draws(NPATH, SEED):
    for j, y in enumerate(estimators(z, S, SIG, T)):
        tot[j] += y; totsq[j] += y * y
    if (terminal(z, S + HP, SIG, T) > K) != (terminal(z, S - HP, SIG, T) > K): flips += 1
print(f"{NPATH} draws from the generator written above, shared by every estimator:")
mc, se = [], []
for name, j, aim in zip(names, cols, aims):
    mean = tot[j] / NPATH
    err = sqrt(max(totsq[j] - NPATH * mean * mean, 0.0) / (NPATH - 1) / NPATH)
    mc.append(mean); se.append(err)
    print(f"{name:<22}{'mean':>7}{mean:>13.6f}{'std err':>10}{err:>11.6f}{'target':>9}{aim:>13.6f}")
print(f"paths whose digital payoff moved when spot moved by {HP:.6f}: {flips} of {NPATH}")
spots, grid = [80.0 + 5.0 * i for i in range(9)], [-1.0 + 0.5 * i for i in range(9)]
for label, vals in (("chart, Acme's price now:        ", spots),
                    ("chart, digital payoff at expiry:", [payoffs(x)[1] for x in spots]),
                    ("chart, digital price today:     ", [dig_px(x, SIG, T) for x in spots]),
                    ("chart, the draw Z:              ", grid),
                    ("chart, call delta pathwise:     ", [estimators(z, S, SIG, T)[0] for z in grid]),
                    ("chart, call delta score:        ", [estimators(z, S, SIG, T)[1] for z in grid])):
    print(label + " ".join(f"{nz(v):>7.2f}" for v in vals))
assert abs(m1[0] - exact[0]) < 1e-6 and abs(m1[1] - exact[0]) < 1e-6, "both delta roads vs e^-qT N(d1)"
assert abs(m1[2] - exact[1]) < 1e-5 and abs(m1[3] - exact[1]) < 1e-5, "both vega roads vs S e^-qT phi(d1) sqrt(T)"
assert abs(m1[5] - exact[2]) < 1e-8, "score digital delta vs e^-rT phi(d2)/(S sigma sqrt T)"
assert abs(m1[7] - exact[3]) < 1e-8, "score digital vega vs -e^-rT phi(d2) d1/sigma"
assert m1[4] == 0.0 and m1[6] == 0.0 and bumped[2] - m1[4] > 0.018, "pathwise is zero on the digital; the price slope is not"
assert flips == 0, "no path's digital payoff moved under a millionth-dollar nudge"
assert all(abs(bumped[i] - exact[i]) < 1e-5 * max(1.0, abs(exact[i])) for i in range(4)), "price bumps vs closed forms"
assert abs(mc[0] - exact[0]) < 4.0 * se[0], "simulated pathwise delta within four standard errors"
assert sd[1] > 2.0 * sd[0], "the score's spread is more than double the pathwise spread"
print("ALL CHECKS PASS")
