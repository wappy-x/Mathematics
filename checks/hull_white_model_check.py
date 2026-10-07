# Hull-White check: Vasicek's spring with a moving anchor theta(t), fitted to the slice E
# curve.  Standard library only; nothing imported that already knows an answer.  Roads:
# (1) the A, B closed form; (2) theta(t) fed into the mean-rate equation, integrated by
# RK4, kicks at the pillars; (3) Monte Carlo of the spring noise, own random numbers;
# (4) Monte Carlo of a discounted bond price 18 months out; (5) theta read off plain
# Vasicek's own curve by numerical differentiation, which must come out flat at a*b.
from math import exp, log, sqrt, cos, pi

DEPOSITS = ((0.5, 0.0400), (1.0, 0.0420))            # (years, simple rate)
SWAPS = ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465))   # (years, par rate)
A, SIG = 0.3, 0.01                    # reversion speed and volatility: the shelf's house pair
VB, VR0 = 0.05, 0.04                  # plain Vasicek: fixed anchor and starting rate
LOAN = 10_000_000.0

D = {0.0: 1.0}                        # the bootstrap ladder, as on the slice E card
for T, r in DEPOSITS: D[T] = 1.0 / (1.0 + T * r)
for n, S in SWAPS: D[float(n)] = (1.0 - S * sum(D[float(j)] for j in range(1, n))) / (1.0 + S)
PIL = sorted(D)                                       # 0, 0.5, 1, 2, 3, 4, 5
FW = [log(D[PIL[i]] / D[PIL[i + 1]]) / (PIL[i + 1] - PIL[i]) for i in range(6)]

def gap(t): return min(sum(1 for p in PIL[1:] if t >= p), 5)   # which gap t sits in
def f0(t): return FW[gap(t)]                          # forward rate f(0,t), flat in each gap
def Dt(t): i = gap(t); return D[PIL[i]] * exp(-FW[i] * (t - PIL[i]))
def Bf(t, T): return (1.0 - exp(-A * (T - t))) / A
def V(T): return SIG**2 / A**2 * (T - 2.0 * Bf(0.0, T) + (1.0 - exp(-2.0 * A * T)) / (2.0 * A))
def lift(t): return SIG**2 / (2.0 * A**2) * (1.0 - exp(-A * t))**2   # mean rate minus forward
def conv(t): return SIG**2 / (2.0 * A) * (1.0 - exp(-2.0 * A * t))
def closed(t, T, r):                                  # road 1: P(t,T) = A(t,T) exp(-B r)
    B = Bf(t, T)
    return Dt(T) / Dt(t) * exp(B * f0(t) - SIG**2 / (4.0 * A) * (1.0 - exp(-2.0 * A * t)) * B * B - B * r)

def road2(r0, use_conv=True, kicks=True):             # dm/dt = theta - a m, dI/dt = m
    m, I, out = r0, 0.0, {}
    for i in range(6):
        t0, n = PIL[i], int(400 * (PIL[i + 1] - PIL[i])); h = (PIL[i + 1] - t0) / n
        th = lambda t: A * FW[i] + (conv(t) if use_conv else 0.0)  # f' = 0 inside a gap
        for k in range(n):
            t = t0 + k * h
            k1 = th(t) - A * m;                 j1 = m
            k2 = th(t + h / 2) - A * (m + h / 2 * k1); j2 = m + h / 2 * k1
            k3 = th(t + h / 2) - A * (m + h / 2 * k2); j3 = m + h / 2 * k2
            k4 = th(t + h) - A * (m + h * k3);  j4 = m + h * k3
            m += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4); I += h / 6 * (j1 + 2 * j2 + 2 * j3 + j4)
        out[PIL[i + 1]] = exp(-I + 0.5 * V(PIL[i + 1]))
        if kicks and i < 5: m += FW[i + 1] - FW[i]      # f' at a pillar: the rate steps
    return out

def simpson(g, a, b, n=200):
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, n)))
def ncdf(x): return 0.5 + (1 if x > 0 else -1) * simpson(lambda u: exp(-u * u / 2) / sqrt(2 * pi), 0.0, abs(x), 2000)

state = 20260928                                      # 64-bit LCG, then Box-Muller
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def gauss(): u1 = unif(); u2 = unif(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

NP, STEPS, TS = 20000, 50, 1.5                        # antithetic pairs, steps a year, scenario date
dt = 1.0 / STEPS; ea = exp(-A * dt); sd = SIG * sqrt((1.0 - exp(-2.0 * A * dt)) / (2.0 * A))
iphi = {T: -log(Dt(T)) + simpson(lift, 0.0, T) for T in (1.0, TS, 5.0)}   # integral of the mean path
stats = {1.0: [0.0, 0.0], 5.0: [0.0, 0.0], TS: [0.0, 0.0]}
for _ in range(NP):
    x = I = 0.0
    for k in range(1, 5 * STEPS + 1):
        nx = x * ea + sd * gauss(); I += 0.5 * dt * (x + nx); x = nx   # exact spring step
        if k in (STEPS, 5 * STEPS):
            v = 0.5 * (exp(-I) + exp(I)); s = stats[k / STEPS]; s[0] += v; s[1] += v * v
        if k == int(TS * STEPS):                      # road 4: discount, then price the bond
            rp = f0(TS) + lift(TS)
            v = 0.5 * (exp(-iphi[TS] - I) * closed(TS, 5.0, rp + x) + exp(-iphi[TS] + I) * closed(TS, 5.0, rp - x))
            s = stats[TS]; s[0] += v; s[1] += v * v
def mc(T): s = stats[T]; mu = s[0] / NP; return mu, sqrt((s[1] / NP - mu * mu) / NP)

def lnDV(T): B = Bf(0.0, T); return (VB - SIG**2 / (2 * A**2)) * (B - T) - SIG**2 * B * B / (4 * A) - B * VR0
def vas_theta(t, h=1e-3):                             # road 5: theta from Vasicek's own curve
    f = -(lnDV(t + h) - lnDV(t - h)) / (2 * h); fp = -(lnDV(t + h) - 2 * lnDV(t) + lnDV(t - h)) / (h * h)
    return fp + A * f + conv(t)

R2 = road2(FW[0])
print("the slice E curve: pillar, D(T), forward % in the gap ending there")
for i, T in enumerate(PIL[1:]): print(f"  {T:3.1f}  {D[T]:.8f}  {100 * FW[i]:.4f}")
print("theta % a year: gap, at its start, at its end, kick at its end")
for i in range(6):
    kick = f"{100 * (FW[i + 1] - FW[i]):+.4f}" if i < 5 else "  none"
    print(f"  {PIL[i]:3.1f}-{PIL[i + 1]:3.1f}  {100 * (A * FW[i] + conv(PIL[i])):.4f}  {100 * (A * FW[i] + conv(PIL[i + 1])):.4f}  {kick}")
print(f"theta at 2.5 y %: a f {100 * A * f0(2.5):.4f} + convexity {100 * conv(2.5):.4f} = {100 * (A * f0(2.5) + conv(2.5)):.4f}; "
      f"anchor theta/a {100 * (f0(2.5) + conv(2.5) / A):.4f}")
print(f"pieces: half-life {log(2) / A:.2f} y; B(0,5) {Bf(0.0, 5.0):.6f}; V(5) {V(5.0):.6f}; lift(5) % {100 * lift(5.0):.4f}")
il = simpson(lift, 0.0, 5.0)
print("5-year zero, by hand: integral of forward, integral of lift, half variance, price")
print(f"  {-log(D[5.0]):.6f}  {il:.6f}  {0.5 * V(5.0):.6f}  {exp(log(D[5.0]) - il + 0.5 * V(5.0)):.8f}")
print("pillar: market, road 1 closed form, road 2 theta integrated, Vasicek; Vasicek miss $ on 10m")
for T in PIL[1:]:
    dv = exp(lnDV(T))
    print(f"  {T:3.1f}  {D[T]:.8f}  {closed(0.0, T, FW[0]):.8f}  {R2[T]:.8f}  {dv:.8f}  {LOAN * (dv - D[T]):.2f}")
for T in (1.0, 5.0):
    mu, se = mc(T)
    print(f"road 3, {T:.0f} y: E[exp(-int x)] {mu:.8f} se {se:.8f}; exp(V/2) {exp(0.5 * V(T)):.8f}; "
          f"price {exp(-iphi[T]) * mu:.8f}")
mu4, se4 = mc(TS)
print(f"road 4: E[discount to 1.5 y x P(1.5,5)] {mu4:.8f} se {se4:.8f}; market D(5) {D[5.0]:.8f}")
rs = f0(TS) + lift(TS)
print(f"at 1.5 y: expected rate % {100 * rs:.4f}; P(1.5,5) there {closed(TS, 5.0, rs):.6f}; at 6% {closed(TS, 5.0, 0.06):.6f}")
th5 = [vas_theta(t) for t in (1.0, 2.5, 4.0)]
print("road 5, theta from Vasicek's curve at 1, 2.5, 4 y: " + " ".join(f"{v:.8f}" for v in th5) + f"; a*b {A * VB:.8f}")
m5, s5 = f0(5.0) + lift(5.0), sqrt(conv(5.0))
print(f"r(5): mean % {100 * m5:.4f}, sd % {100 * s5:.4f}, chance below zero {ncdf(-m5 / s5):.6f}")
print("what breaks, 5-year price and $ error on 10m:")
for lab, p in (("no convexity term", road2(FW[0], use_conv=False)[5.0]), ("no kicks", road2(FW[0], kicks=False)[5.0]),
               ("start at 4%", road2(VR0)[5.0]), ("plain Vasicek", exp(lnDV(5.0)))):
    print(f"  {lab:<18} {p:.8f}  {LOAN * (p - D[5.0]):.2f}")
tg = [0.25 * k for k in range(21)]
print("chart, years      " + " ".join(f"{t:5.2f}" for t in tg))
print("chart, market f % " + " ".join(f"{100 * f0(t):5.2f}" for t in tg))
print("chart, Vasicek f %" + " ".join(f"{100 * (VR0 * exp(-A * t) + VB * (1 - exp(-A * t)) - lift(t)):5.2f}" for t in tg))

assert all(abs(R2[T] / D[T] - 1.0) < 1e-9 for T in PIL[1:]), "theta integrated must land on every pillar"
for T in (1.0, 5.0):
    mu, se = mc(T); assert abs(mu - exp(0.5 * V(T))) < 4 * se, "spring noise must lift the price by exp(V/2)"
assert abs(mu4 - D[5.0]) < 4 * se4, "discounted bond price must average back to today's price"
assert all(abs(v - A * VB) < 1e-7 for v in th5), "Vasicek's own curve must return its constant anchor"
print("ALL CHECKS PASS")
