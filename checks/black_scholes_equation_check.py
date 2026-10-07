# The Black-Scholes equation -- the check behind the card.  Standard library only,
# and nothing imported that already knows the answer: the bell-curve area N(x) is
# built here by Simpson's rule on the bell curve's own height, and road three
# marches the equation itself back from the payoff wall with no pricing formula
# inside it at all.  Every number quoted on the card is printed below.
from math import log, sqrt, exp, pi

S0, K, R, Q, SG, T, MU = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 0.10
DS, DT, DAY = 1.0e-2, 1.0e-6, 1.0 / 252.0   # two nudges, and one trading day

def phi(x):                  # the bell curve's height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def ncdf(x):                 # area under the bell curve left of x, by Simpson
    if x < -12.0: return 0.0
    if x > 12.0: return 1.0
    n, s, h = 4000, phi(0.0) + phi(x), x / 4000.0
    for i in range(1, n): s += (4.0 if i % 2 == 1 else 2.0) * phi(h * i)
    return 0.5 + s * h / 3.0

def d1d2(S, t):              # t is the life left to expiry, in years
    v, m = SG * sqrt(t), log(S / K) + (R - Q + 0.5 * SG * SG) * t
    return m / v, m / v - v

def call(S, t):
    d1, d2 = d1d2(S, t)
    return S * exp(-Q * t) * ncdf(d1) - K * exp(-R * t) * ncdf(d2)

def put(S, t):
    d1, d2 = d1d2(S, t)
    return K * exp(-R * t) * ncdf(-d2) - S * exp(-Q * t) * ncdf(-d1)

def forward(S, t):           # a prepaid share less a loan: no curvature at all
    return S * exp(-Q * t) - K * exp(-R * t)

def greeks(S, t):            # theta, delta, gamma of the call, from the formula
    d1, d2 = d1d2(S, t)
    dq, dr = exp(-Q * t), exp(-R * t)
    theta = (-S * dq * phi(d1) * SG / (2.0 * sqrt(t))
             + Q * S * dq * ncdf(d1) - R * K * dr * ncdf(d2))
    return theta, dq * ncdf(d1), dq * phi(d1) / (S * SG * sqrt(t))

def slopes(price, S, t):     # road two: the three slopes by nudging the price
    V = price(S, t)
    vt = (price(S, t - DT) - price(S, t + DT)) / (2.0 * DT)   # clock on = life down
    vs = (price(S + DS, t) - price(S - DS, t)) / (2.0 * DS)
    vss = (price(S + DS, t) - 2.0 * V + price(S - DS, t)) / (DS * DS)
    return V, vt, vs, vss

def leftover(price, S, t):   # what the equation fails by, using nudged slopes
    V, vt, vs, vss = slopes(price, S, t)
    return vt + (R - Q) * S * vs + 0.5 * SG * SG * S * S * vss - R * V

def grid(is_call, m=600, steps=2000, L=1.5):
    # Road three: the equation alone, marched back from the payoff wall on a grid
    # of x = ln(S/K), spaced dx apart.  No d1, no d2, no bell curve anywhere.
    dx, dt = 2.0 * L / m, T / steps
    a, b = 0.5 * SG * SG, R - Q - 0.5 * SG * SG
    v = [max(K * exp(-L + i * dx) - K, 0.0) if is_call
         else max(K - K * exp(-L + i * dx), 0.0) for i in range(m + 1)]
    for s in range(steps):
        tl = (s + 1) * dt                            # life left after this step
        nv = [0.0] * (m + 1)
        for i in range(1, m):
            nv[i] = v[i] + dt * (a * (v[i + 1] - 2.0 * v[i] + v[i - 1]) / (dx * dx)
                                 + b * (v[i + 1] - v[i - 1]) / (2.0 * dx) - R * v[i])
        nv[m] = K * exp(L - Q * tl) - K * exp(-R * tl) if is_call else 0.0
        nv[0] = 0.0 if is_call else K * exp(-R * tl) - K * exp(-L - Q * tl)
        v = nv
    return v[m // 2]

def hedged_day(dS):          # road four: revalue the hedged book one day later
    return ((call(S0 + dS, T - DAY) - De * (S0 + dS)) - (C - De * S0)
            + (De * S0 - C) * (exp(R * DAY) - 1.0) - Q * De * S0 * DAY)

def show(title, rows):
    print(title)
    for name, v in rows: print(f"{name:<34}{v:>18.12f}")

C, P, d1, d2 = call(S0, T), put(S0, T), *d1d2(S0, T)
Th, De, Ga = greeks(S0, T)
A, B, Cu, D = Th, (R - Q) * S0 * De, 0.5 * SG * SG * S0 * S0 * Ga, R * C
cash, be = C - De * S0, SG * S0 * sqrt(DAY)
V, vt, vs, vss = slopes(call, S0, T)
gC, gP = grid(True), grid(False)
still = -0.5 * Ga * SG * SG * S0 * S0 * DAY

show("Black-Scholes equation, house market: S=K=100 r=5% q=2% sigma=20% T=1",
     (("call V", C), ("put V", P), ("d1", d1), ("d2", d2)))
show("-- road one: the three slopes from the closed formula --",
     (("theta  dV/dt, dollars a year", Th), ("delta  dV/dS", De),
      ("gamma  d(delta)/dS", Ga), ("A  theta", A), ("B  (r-q) S delta", B),
      ("C  half sigma^2 S^2 gamma", Cu), ("A + B + C", A + B + Cu), ("D  r V", D),
      ("call leftover A+B+C-D", A + B + Cu - D), ("cash in the mix, V - S delta", cash),
      ("A + C, theta plus gamma", A + Cu), ("r(V - S delta) + q S delta", R * cash + Q * S0 * De)))
show("-- road two: the same slopes by nudging, no Greek named --",
     (("call dV/dt by nudging", vt), ("call dV/dS by nudging", vs),
      ("call d2V/dS2 by nudging", vss), ("call leftover by nudging", leftover(call, S0, T)),
      ("put leftover by nudging", leftover(put, S0, T)),
      ("prepaid share less loan, leftover", leftover(forward, S0, T))))
show("-- road three: the equation marched back from the payoff wall --",
     (("call from the grid", gC), ("put from the grid", gP),
      ("worst gap to the formula", max(abs(gC - C), abs(gP - P)))))
show("-- road four: one hedged day, revalued against the forecast --",
     (("break-even move sigma S sqrt(day)", be), ("still day, hedged P&L", hedged_day(0.0)),
      ("still day, forecast from gamma", still), ("break-even day, hedged P&L", hedged_day(be))))
show("-- what breaks: each wrong equation's leftover, dollars a year --",
     (("clock sign flipped", -vt + (R - Q) * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * V),
      ("Ito half dropped", vt + (R - Q) * S0 * vs + SG * SG * S0 * S0 * vss - R * V),
      ("real drift mu = 10% for r - q", vt + MU * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * V),
      ("q dropped from the equation", vt + R * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * V)))

g6 = [(S, greeks(S, T)) for S in [80.0 + 10.0 * i for i in range(6)]]
print("-- the three terms across the share price, for the chart --")
print(f"{'share price':<14}" + "".join(f"{S:>9.0f}" for S, g in g6))
print(f"{'theta':<14}" + "".join(f"{g[0]:>9.2f}" for S, g in g6))
print(f"{'gamma term':<14}" + "".join(f"{0.5 * SG * SG * S * S * g[2]:>9.2f}" for S, g in g6))
print(f"{'carry term':<14}" + "".join(f"{(R - Q) * S * g[1]:>9.2f}" for S, g in g6))
print(f"{'r V':<14}" + "".join(f"{R * call(S, T):>9.2f}" for S, g in g6))
print("-- the same budget in cents a day, as expiry comes --")
print(f"{'months left':<14}{'theta':>9}{'gamma':>9}{'carry':>9}{'r V':>9}")
for mo in (12, 9, 6, 3, 1):
    t = mo / 12.0
    th, de, ga = greeks(S0, t)
    cells = (th, 0.5 * SG * SG * S0 * S0 * ga, (R - Q) * S0 * de, R * call(S0, t))
    print(f"{mo:<14d}" + "".join(f"{100.0 * x * DAY:>9.2f}" for x in cells))

assert abs(vt - Th) < 1e-6, "nudged dV/dt against the closed theta"
assert abs(vs - De) < 1e-6, "nudged dV/dS against the closed delta"
assert abs(vss - Ga) < 1e-6, "nudged d2V/dS2 against the closed gamma"
assert abs(A + B + Cu - D) < 1e-12, "the closed call's slopes satisfy the equation"
assert abs(leftover(put, S0, T)) < 1e-6, "the put satisfies it too"
assert abs(leftover(forward, S0, T)) < 1e-6, "so does a prepaid share less a loan"
assert abs(gC - 9.227005508154) < 1e-3, "the marched grid lands on the card's call price"
assert abs(gP - 6.330080627550) < 1e-3, "and on the card's put price"
assert abs(hedged_day(0.0) - still) < 1e-3, "revalued still day against the gamma forecast"
assert abs(hedged_day(be)) < 5e-3, "a break-even move leaves the hedged day flat"
assert abs(A + Cu - (R * cash + Q * S0 * De)) < 1e-12, "the trader's reading of the line"
print("ALL CHECKS PASS")
