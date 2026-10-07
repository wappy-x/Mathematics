# Black-Scholes by hedging -- the check behind the card.  Standard library only.
# Nothing is imported that already knows the answer: the bell-curve area N(x) is
# built from its own series, the slope and the bend are taken from prices alone,
# and the grid road reaches the price from the equation and the payoff, never
# from the closed formula.  Acme is the house market: S = K = 100, r = 5%,
# q = 2%, sigma = 20%, one year.
from math import log, sqrt, exp, pi
S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
H, KT = 0.20, 0.001                      # price step and time step for the differences

def erf_series(x):                       # the error function as its own series
    term, total, n = x, 0.0, 0
    while abs(term) > 1e-19 * (abs(total) + 1.0) and n < 300:
        total += term / (2 * n + 1)
        n += 1
        term *= -x * x / n
    return 2.0 / sqrt(pi) * total
def N(x):    return 0.5 * (1.0 + erf_series(x / sqrt(2.0)))   # bell-curve area left of x
def phi(x):  return exp(-0.5 * x * x) / sqrt(2.0 * pi)        # bell-curve height at x
def d12(S, tau):
    v = SIG * sqrt(tau)
    return (log(S / K) + (R - Q + 0.5 * SIG * SIG) * tau) / v, v
def call(S, tau):
    d1, v = d12(S, tau)
    return S * exp(-Q * tau) * N(d1) - K * exp(-R * tau) * N(d1 - v)
def put(S, tau):
    d1, v = d12(S, tau)
    return K * exp(-R * tau) * N(v - d1) - S * exp(-Q * tau) * N(-d1)
def forward(S, tau):                     # one funded share minus the funded strike
    return S * exp(-Q * tau) - K * exp(-R * tau)
def call_greeks(S, tau):                 # clock, slope, bend, each from its own formula
    d1, v = d12(S, tau)
    dq, dr = exp(-Q * tau), exp(-R * tau)
    theta = -S*dq*phi(d1)*SIG/(2.0*sqrt(tau)) + Q*S*dq*N(d1) - R*K*dr*N(d1 - v)
    return theta, dq * N(d1), dq * phi(d1) / (S * SIG * sqrt(tau))
def put_greeks(S, tau):
    d1, v = d12(S, tau)
    dq, dr = exp(-Q * tau), exp(-R * tau)
    theta = -S*dq*phi(d1)*SIG/(2.0*sqrt(tau)) - Q*S*dq*N(-d1) + R*K*dr*N(v - d1)
    return theta, dq * (N(d1) - 1.0), dq * phi(d1) / (S * SIG * sqrt(tau))
def forward_greeks(S, tau):              # no bend at all: the value is a straight line
    return Q * S * exp(-Q * tau) - R * K * exp(-R * tau), exp(-Q * tau), 0.0
def left(S, g):                          # clock + carry + bend
    return g[0] + (R - Q) * S * g[1] + 0.5 * SIG * SIG * S * S * g[2]
def stencil(f, S, tau, h, k):            # value, clock, slope, bend, from prices alone
    v = f(S, tau)
    return (v, (f(S, tau - k) - f(S, tau + k)) / (2.0 * k),
            (f(S + h, tau) - f(S - h, tau)) / (2.0 * h),
            (f(S + h, tau) - 2.0 * v + f(S - h, tau)) / (h * h))
def refined(f, S, tau, h, k):            # two step sizes, leading step error cancelled
    _, t1, s1, b1 = stencil(f, S, tau, h, k)
    _, t2, s2, b2 = stencil(f, S, tau, 2.0 * h, 2.0 * k)
    return (4.0*t1 - t2)/3.0, (4.0*s1 - s2)/3.0, (4.0*b1 - b2)/3.0
def grid(M, Smax, steps):                # march the equation back from the payoff
    ds, dt = Smax / M, T / steps
    v = [max(i * ds - K, 0.0) for i in range(M + 1)]
    for n in range(1, steps + 1):
        new = [0.0] * (M + 1)
        for i in range(1, M):
            s = i * ds
            new[i] = v[i] + dt * (0.5*SIG*SIG*s*s*(v[i-1] - 2.0*v[i] + v[i+1])/(ds*ds)
                                  + (R - Q)*s*(v[i+1] - v[i-1])/(2.0*ds) - R*v[i])
        new[M] = forward(Smax, n * dt)
        v = new
    return v[int(round(S0 / ds))]
def yn(claim):  return "yes" if claim else "no"

d1, v1 = d12(S0, T)
C, P, F = call(S0, T), put(S0, T), forward(S0, T)
theta, delta, gamma = call_greeks(S0, T)
carry, bend = (R - Q) * S0 * delta, 0.5 * SIG * SIG * S0 * S0 * gamma
res_c = left(S0, call_greeks(S0, T)) - R * C
res_p = left(S0, put_greeks(S0, T)) - R * P
res_f = left(S0, forward_greeks(S0, T)) - R * F
_, pt, ps, pb = stencil(call, S0, T, H, KT)
vt, vs, vb = refined(call, S0, T, H, KT)
res_plain = pt + (R - Q)*S0*ps + 0.5*SIG*SIG*S0*S0*pb - R*C
res_fine = vt + (R - Q)*S0*vs + 0.5*SIG*SIG*S0*S0*vb - R*C
g1, g2 = grid(300, 300.0, 3601), grid(600, 300.0, 14401)
wrong_clock = -theta + carry + bend - R*C            # calendar clock read backwards
drop_half = theta + carry + 2.0*bend - R*C           # Ito's one half thrown away
real_drift = theta + 0.10*S0*delta + bend - R*C      # a 10% opinion where r - q belongs
no_q = theta + R*S0*delta + bend - R*C               # dividend dropped from the equation

rows = [("d1", d1), ("d2", d1 - v1), ("N(d1)", N(d1)), ("N(d2)", N(d1 - v1)),
        ("call C", C), ("put P", P), ("prepaid forward", F),
        ("Delta, shares of Acme per option", delta), ("Gamma, bend of the price", gamma),
        ("clock  Theta", theta), ("cash in the hedge, C - S Delta", C - delta * S0),
        ("carry  (r - q) S Delta", carry), ("bend   1/2 sig^2 S^2 Gamma", bend),
        ("clock + carry + bend", left(S0, (theta, delta, gamma))), ("r C", R * C),
        ("wrong: clock read backwards", wrong_clock),
        ("wrong: Ito's one half dropped", drop_half),
        ("wrong: real drift 0.10 for r - q", real_drift),
        ("wrong: dividend dropped", no_q)]
for name, v in rows:
    print(f"{name:<42}{v:>18.12f}")
print(f"{'price from the equation on a grid':<42}{g1:>18.6f}{g2:>12.6f}")
print(f"{'  gap to the closed call':<42}{g1 - C:>18.6f}{g2 - C:>12.6f}")
print(f"residual under 1e-10 with the closed Greeks: call {yn(abs(res_c) < 1e-10)}, "
      f"put {yn(abs(res_p) < 1e-10)}, prepaid forward {yn(abs(res_f) < 1e-10)}")
print(f"{'clock, slope, bend from prices alone':<42}{vt:>18.9f}{vs:>14.9f}{vb:>14.9f}")
print(f"residual from prices alone under 1e-4: {yn(abs(res_plain) < 1e-4)}; "
      f"two step sizes combined, under 1e-8: {yn(abs(res_fine) < 1e-8)}")
print()
spots = [90.0 + 2.0 * i for i in range(11)]
print(f"{'hedge picture, Acme price':<30}" + "".join(f"{s:>7.2f}" for s in spots))
print(f"{'hedge picture, the call C':<30}" + "".join(f"{call(s, T):>7.2f}" for s in spots))
print(f"{'hedge picture, the hedge line':<30}"
      + "".join(f"{C + delta * (s - S0):>7.2f}" for s in spots))
print()
print("across Acme's price, 12 months to go, dollars per year")
print(f"{'Acme':>11}{'clock':>10}{'carry':>10}{'bend':>10}{'r C':>10}")
for s in (80.0, 90.0, 100.0, 110.0, 120.0):
    th, de, ga = call_greeks(s, T)
    print(f"{s:>11.2f}{th:>10.2f}{(R - Q) * s * de:>10.2f}"
          f"{0.5 * SIG * SIG * s * s * ga:>10.2f}{R * call(s, T):>10.2f}")
print()
print("as the clock runs down, Acme at 100, dollars per year")
print(f"{'months left':>11}{'clock':>10}{'carry':>10}{'bend':>10}{'r C':>10}")
for m in (12, 9, 6, 3, 1):
    th, de, ga = call_greeks(S0, m / 12.0)
    print(f"{m:>11d}{th:>10.2f}{(R - Q) * S0 * de:>10.2f}"
          f"{0.5 * SIG * SIG * S0 * S0 * ga:>10.2f}{R * call(S0, m / 12.0):>10.2f}")

assert abs(res_c) < 1e-10 and abs(res_p) < 1e-10, "closed call and put: left side must equal r V"
assert abs(res_f) < 1e-10, "the prepaid forward obeys it with no bend at all"
assert abs(vt - theta) < 1e-9 and abs(vs - delta) < 1e-8, "prices alone reproduce clock and slope"
assert abs(vb - gamma) < 1e-10, "prices alone reproduce the bend"
assert abs(res_fine) < 1e-8, "prices alone satisfy the equation"
assert abs(g2 - C) < 0.001 and abs(g1 - C) < 0.005, "the grid road lands on the formula"
assert abs(g1 - C) > 3.5 * abs(g2 - C), "halving the price step quarters the gap"
assert wrong_clock > 10.0 and drop_half > 3.0, "a backwards clock and a lost half cost dollars"
assert real_drift > 4.0 and no_q > 1.0, "an opinion and a missing dividend cost dollars"
print("ALL CHECKS PASS")
