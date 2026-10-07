# Kalman-Bucy filter -- the check behind the card.  Only math is imported.
# A hidden rate X_t (percentage points, t in years) follows dX = -A (X - TH) dt + SIG dW.
# Quotes arrive as dY = X dt + RHO dB: one trading day's quotes average to the rate plus an
# error of S_Q = 0.5 points.  Roads: the Riccati equation's closed form; the same equation by
# RK4; the discrete Kalman filter with shrinking steps; the best constant gain by golden
# section; 2000 simulated years from a SplitMix64 generator and Box-Muller normals.
import math

A, TH, SIG, S_Q, DAY = 2.0, 4.0, 1.0, 0.5, 1 / 250      # per year, points, points/sqrt(yr), points, years
RHO2, P0, M0 = S_Q * S_Q * DAY, SIG * SIG / (2 * A), TH  # quote noise rho^2; prior variance and mean
LAM = math.sqrt(A * A + SIG * SIG / RHO2)               # the filter's forgetting rate, per year
PP, PM = RHO2 * (LAM - A), -RHO2 * (LAM + A)            # the two roots of the Riccati right side
SEED, MASK, PATHS, SUB = 20260930, (1 << 64) - 1, 2000, 10    # 10 simulation steps per trading day

def p_closed(t):                        # Riccati solution: (P - PP)/(P - PM) decays like e^(-2 LAM t)
    c = (P0 - PP) / (P0 - PM) * math.exp(-2 * LAM * t)
    return (PP - PM * c) / (1 - c)

def ric(p, sig2): return -2 * A * p + sig2 - p * p / RHO2

def rk4(f, y, t, n=4000):               # integrate y' = f(y) from 0 to t; y is a tuple
    h = t / n
    for _ in range(n):
        k1 = f(y); k2 = f(tuple(a + h / 2 * b for a, b in zip(y, k1)))
        k3 = f(tuple(a + h / 2 * b for a, b in zip(y, k2))); k4 = f(tuple(a + h * b for a, b in zip(y, k3)))
        y = tuple(a + h / 6 * (b + 2 * c + 2 * d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4))
    return y

def discrete_kf(h, t):                  # predict with the exact OU step, update on y = x + noise, R = RHO2/h
    phi, p, r = math.exp(-A * h), P0, RHO2 / h
    q = SIG * SIG * (1 - phi * phi) / (2 * A)
    for _ in range(round(t / h)):
        p = phi * phi * p + q
        p = p * r / (p + r)
    return p

def v_const(k): return (SIG * SIG + k * k * RHO2) / (2 * (A + k))   # steady error variance, fixed gain k

class SplitMix64:                       # the wing's generator, written out
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):                   # Box-Muller, cosine half only
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def total(xs):                          # plain left-to-right sum (Python's sum() compensates)
    s = 0.0
    for x in xs: s += x
    return s

def mse(xs):                            # mean of squared errors and its standard error
    n = len(xs); m = total(xs) / n
    return m, math.sqrt(total([(x - m) * (x - m) for x in xs]) / (n - 1) / n)

print(f"pull A {A}/yr, level {TH}, noise {SIG}, quote error {S_Q} per day, rho^2 {RHO2:.6f}, prior var {P0:.4f}")
print(f"forgetting rate lambda {LAM:.6f}/yr = 1 / {250 / LAM:.4f} trading days; roots {PP:.6f}, {PM:.6f}")
print(f"one trading day {DAY:.3f} years; gain at the start P0/rho^2 {P0 / RHO2:.1f}/yr")
print(f"steady state: P {PP:.6f}, sd {math.sqrt(PP):.4f} points, gain K {PP / RHO2:.6f}/yr, worth {S_Q * S_Q / PP:.4f} days of quotes")
print(f"hand: sigma^2/rho^2 {SIG * SIG / RHO2:.1f}, a^2 + that {A * A + SIG * SIG / RHO2:.1f}, P0 - PP {P0 - PP:.6f}, P0 - PM {P0 - PM:.6f}, c {(P0 - PP) / (P0 - PM):.6f}")
e5 = math.exp(-2 * LAM * 5 * DAY); c5 = (P0 - PP) / (P0 - PM) * e5
print(f"hand, day 5: 2 lambda t {2 * LAM * 5 * DAY:.6f}, e^-that {e5:.6f}, c e^-that {c5:.6f}, P {(PP - PM * c5) / (1 - c5):.6f}")
for d in (0, 1, 2, 5, 10, 20, 250):
    t = d * DAY
    (pr,) = rk4(lambda y: (ric(y[0], SIG * SIG),), (P0,), t) if d else (P0,)
    print(f"day {d:3d}: P closed {p_closed(t):.6f}, RK4 {pr:.6f}, sd {math.sqrt(p_closed(t)):.4f} points")
    if d: assert abs(pr - p_closed(t)) < 1e-12              # day 0 is the start itself: nothing to test
errs = []
for n in (1, 10, 100, 1000):
    pd = discrete_kf(DAY / n, 5 * DAY)
    errs.append(abs(pd - p_closed(5 * DAY)))
    print(f"discrete filter, {n:4d} quotes a day: P at day 5 {pd:.8f}, off by {errs[-1]:.8f}")
assert errs[3] < errs[2] / 5 < errs[1] / 25 < errs[0] / 125
dd = discrete_kf(DAY, 1.0); pb = math.exp(-2 * A * DAY) * dd + SIG * SIG * (1 - math.exp(-2 * A * DAY)) / (2 * A)
print(f"discrete daily filter, steady after-quote P {dd:.6f}; before the quote {pb:.6f}")
assert abs(pb * S_Q * S_Q / (pb + S_Q * S_Q) - dd) < 1e-12 and dd < PP < pb   # a fixed point, around the continuous P
lo, hi, gr = 0.0, 200.0, (math.sqrt(5) - 1) / 2          # golden section for the best fixed gain
for _ in range(200):
    k1, k2 = hi - gr * (hi - lo), lo + gr * (hi - lo)
    lo, hi = (lo, k2) if v_const(k1) < v_const(k2) else (k1, hi)
print(f"best fixed gain by golden section {lo:.6f}/yr, error var {v_const(lo):.6f}; gain x rho^2 {lo * RHO2:.6f}")
assert abs(lo - (LAM - A)) < 1e-6 and abs(v_const(lo) - PP) < 1e-12
for k in (0.0, 10.0, 100.0, 1000.0):
    print(f"fixed gain {k:6.1f}/yr: steady error var {v_const(k):.6f}")
lw = math.sqrt(A * A + SIG * SIG / (S_Q * S_Q))           # mistake: per-quote variance in place of rho^2
print(f"mistake, S_Q^2 in place of rho^2: gain {lw - A:.6f}/yr, steady error var {v_const(lw - A):.6f}")
for sq, sg in ((1.0, SIG), (S_Q, 2.0)):                 # try changing: noisier quotes; a livelier rate
    r2 = sq * sq * DAY; lt = math.sqrt(A * A + sg * sg / r2)
    print(f"try: quote error {sq}, noise {sg}: lambda {lt:.4f}, memory {250 / lt:.2f} days, gain {lt - A:.4f}, P {r2 * (lt - A):.6f}, sd {math.sqrt(r2 * (lt - A)):.4f}")
still = lambda y: (-2 * A * y[0] - y[0] * y[0] / RHO2,  # filter's own P if it assumes SIG = 0,
                   -2 * (A + y[0] / RHO2) * y[1] + SIG * SIG + (y[0] / RHO2) * (y[0] / RHO2) * RHO2)  # and its true error
s_own, s_true = rk4(still, (P0, P0), 1.0, 40000)
print(f"filter assuming no shocks (SIG = 0), at 1 year: claims var {s_own:.6f}, true error var {s_true:.6f}")
wide = lambda y: (ric(y[0], SIG * SIG), -2 * (A + 1.5 * y[0] / RHO2) * y[1] + SIG * SIG + (1.5 * y[0] / RHO2) * (1.5 * y[0] / RHO2) * RHO2)
w_true = rk4(wide, (P0, P0), 1.0, 40000)[1]             # true error of a filter run at 1.5 times the gain
print(f"filter at 1.5 times the Kalman-Bucy gain, at 1 year: true error var {w_true:.6f}")

g = SplitMix64(SEED)
dt, steps = DAY / SUB, 250 * SUB
phi = math.exp(-A * dt); q = math.sqrt(SIG * SIG * (1 - phi * phi) / (2 * A))
c0 = 1 / P0 + 1 / (2 * A * RHO2)                         # no-shock P in closed form: 1/P is linear in e^(2At)
gain = [p_closed(k * dt) / RHO2 for k in range(steps)]
gfro = [1 / (c0 * math.exp(2 * A * k * dt) - 1 / (2 * A * RHO2)) / RHO2 for k in range(steps)]
kal, quote, lvl, frozen, early, bias, fig, worse = [], [], [], [], [], [], [], []
for p in range(PATHS):
    x = TH + math.sqrt(P0) * g.normal()
    m, mf, mw, ydays = M0, M0, M0, 0.0
    for k in range(steps):
        dy = x * dt + math.sqrt(RHO2 * dt) * g.normal()
        m += -A * (m - TH) * dt + gain[k] * (dy - m * dt)
        mf += -A * (mf - TH) * dt + gfro[k] * (dy - mf * dt)
        mw += -A * (mw - TH) * dt + 1.5 * gain[k] * (dy - mw * dt)
        ydays += dy
        x = TH + phi * (x - TH) + q * g.normal()
        if (k + 1) % SUB == 0:
            qd, ydays = ydays / DAY, 0.0
            if (k + 1) // SUB == 5: early.append((x - m) * (x - m))
            if p == 0 and ((k + 1) // SUB) % 3 == 0 and (k + 1) // SUB <= 60: fig.append((x, qd, m))
    kal.append((x - m) * (x - m)); quote.append((x - qd) * (x - qd)); lvl.append((x - TH) * (x - TH))
    frozen.append((x - mf) * (x - mf)); bias.append(x - m); worse.append((x - mw) * (x - mw) - (x - m) * (x - m))
for lab, xs, ref in (("Kalman-Bucy at day 5", early, p_closed(5 * DAY)), ("Kalman-Bucy at 1 year", kal, p_closed(1.0)),
                     ("latest daily quote", quote, S_Q * S_Q + SIG * SIG * DAY / 3), ("long-run level 4", lvl, P0),
                     ("no-shock filter", frozen, s_true), ("1.5x gain minus K-B", worse, w_true - p_closed(1.0))):  # same draws
    v, se = mse(xs)
    print(f"simulated error var, {lab:21s}: {v:.6f} +- {se:.6f} (formula {ref:.6f})")
    assert abs(v - ref) < 4 * se
b, sb = total(bias) / PATHS, math.sqrt(mse(kal)[0] / PATHS)
print(f"simulated mean error at 1 year {b:.4f} +- {sb:.4f} points")
assert abs(b) < 4 * sb
print("figure, trading day: " + ", ".join(str(3 * i + 3) for i in range(len(fig))))
print("figure, true rate: " + ", ".join(f"{r[0]:.2f}" for r in fig))
print("figure, daily quote: " + ", ".join(f"{r[1]:.2f}" for r in fig))
print("figure, filter estimate: " + ", ".join(f"{r[2]:.2f}" for r in fig))
print("figure, sd in basis points by day 0..20: " + ", ".join(f"{100 * math.sqrt(p_closed(d * DAY)):.2f}" for d in range(21)))
print("ALL CHECKS PASS")
