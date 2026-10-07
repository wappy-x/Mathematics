# Known cash dividends -- the check behind the card.  Standard library only, and
# nothing imported that already knows the answer: the bell-curve area is built from
# thin slices under the curve, every average is Simpson's rule written out, every tree
# is a loop.  Acme trades at 100.00 and pays one cash dividend of 2.00 six months from
# now; the option is a one-year 100-strike European call.  Two models, two roads each.
from math import log, sqrt, exp, pi
S, K, R, SIG, T = 100.0, 100.0, 0.05, 0.20, 1.0
D1, TD, STEPS = 2.0, 0.5, 2000

def phi(x):                                        # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def simpson(f, a, b, n):                           # add up thin slices under f
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def ncdf(x):                                       # bell-curve area to the left of x
    if x < -12.0 or x > 12.0: return 0.0 if x < 0.0 else 1.0
    return 0.5 + simpson(phi, 0.0, x, 2000)
def parts(steps):                                  # a step up, a step down, the odds
    u, dt = exp(SIG * sqrt(T / steps)), T / steps
    return dt, u, 1.0 / u, (exp(R * dt) - 1.0 / u) / (u - 1.0 / u)
def weights(n, p):                                 # binomial weights, no factorials
    w = [(1.0 - p) ** n]
    for j in range(n):
        w.append(w[-1] * p / (1.0 - p) * (n - j) / (j + 1))
    return w

def bs(s0, k, q, t, kind="call"):                  # ROAD 1: the formula, fed s0
    vt = SIG * sqrt(t)
    d1 = (log(s0 / k) + (R - q + 0.5 * SIG * SIG) * t) / vt
    if kind == "call":
        return s0 * exp(-q * t) * ncdf(d1) - k * exp(-R * t) * ncdf(d1 - vt)
    return k * exp(-R * t) * ncdf(vt - d1) - s0 * exp(-q * t) * ncdf(-d1)
def by_average(s0, k, t, kind="call"):             # ROAD 2: average the payoff itself
    vt, mu = SIG * sqrt(t), (R - 0.5 * SIG * SIG) * t
    zk = (log(k / s0) - mu) / vt                   # the z where the payoff switches on
    grow = lambda z: s0 * exp(mu + vt * z)
    if kind == "call":
        return exp(-R * t) * simpson(lambda z: (grow(z) - k) * phi(z), zk, 10.0, 2000)
    return exp(-R * t) * simpson(lambda z: (k - grow(z)) * phi(z), -10.0, zk, 2000)
def escrow_tree(s0, steps):                        # ROAD 3: recombining tree on s0
    dt, u, d, p = parts(steps)
    disc = exp(-R * dt)
    v = [max(s0 * u ** j * d ** (steps - j) - K, 0.0) for j in range(steps + 1)]
    for layer in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(layer)]
    return v[0]
def drop_tree(steps):                              # ROAD 4: cash off every node at TD
    m = int(round(steps * TD / T)); n2 = steps - m
    _, u, d, p = parts(steps)
    w1, w2 = weights(m, p), weights(n2, p)
    grow = [u ** j * d ** (n2 - j) for j in range(n2 + 1)]
    total = 0.0
    for j1 in range(m + 1):
        s1 = S * u ** j1 * d ** (m - j1) - D1      # the cash leaves the share here
        total += w1[j1] * sum(w * max(s1 * g - K, 0.0) for w, g in zip(w2, grow))
    return exp(-R * T) * total, (m + 1) * (n2 + 1)
def drop_average():                                # ROAD 5: same model, nested averages
    vt, mu = SIG * sqrt(T - TD), (R - 0.5 * SIG * SIG) * (T - TD)
    def inner(z1):
        s1 = S * exp((R - 0.5 * SIG * SIG) * TD + SIG * sqrt(TD) * z1) - D1
        zk = min((log(K / s1) - mu) / vt, 10.0) if s1 > 0.0 else 10.0
        return simpson(lambda z2: (s1 * exp(mu + vt * z2) - K) * phi(z2), zk, 10.0, 400)
    return exp(-R * T) * simpson(lambda z1: inner(z1) * phi(z1), -10.0, 10.0, 200)
def twins(s0, drop, steps):                        # two paths that ought to meet
    m = int(round(steps * TD / T)); j = m // 2
    _, u, d, _ = parts(steps)
    return ((s0 * u ** j * d ** (m - j) - drop) * u,
            (s0 * u ** (j + 1) * d ** (m - j - 1) - drop) * d, j)

pvd = D1 * exp(-R * TD); sx = S - pvd; vt = SIG * sqrt(T)
d1 = (log(sx / K) + (R + 0.5 * SIG * SIG) * T) / vt
c_form, p_form = bs(sx, K, 0.0, T), bs(sx, K, 0.0, T, "put")
c_avg, p_avg = by_average(sx, K, T), by_average(sx, K, T, "put")
c_tree, c_drop_avg = escrow_tree(sx, STEPS), drop_average()
c_drop_tree, nodes_drop = drop_tree(STEPS)
q_eq = -log(sx / S) / T
c_yield, p_yield = bs(S, K, 0.02, T), bs(S, K, 0.02, T, "put")
up_d, down_d, node = twins(S, D1, STEPS)
up_e, down_e, _ = twins(sx, 0.0, STEPS)
print(f"Acme S = {S:.2f}, K = {K:.2f}, r = 5%, sigma = 20%, T = 1 year\none cash dividend D1 = {D1:.2f} paid at t1 = {TD:.2f} years")
rows = [
    ("PV of the dividend   D1 e^-r t1", pvd), ("escrowed spot        S* = S - D0", sx),
    ("d1 on the escrowed spot", d1), ("d2 on the escrowed spot", d1 - vt),
    ("1 escrowed formula, call", c_form), ("2 payoff average on S*, call", c_avg),
    (f"3 escrowed tree, {STEPS} steps, call", c_tree), ("4 escrowed formula, put", p_form),
    ("5 payoff average on S*, put", p_avg), ("  parity  C - P", c_form - p_avg),
    ("  parity  S* - K e^-rT", sx - K * exp(-R * T)),
    ("6 cash-drop model, exploded tree, call", c_drop_tree),
    ("7 cash-drop model, nested averages, call", c_drop_avg),
    ("  cash-drop minus escrowed, call", c_drop_avg - c_form),
    ("equivalent yield, -ln(S*/S)/T, percent", 100.0 * q_eq),
    ("  the yield formula at that q, call", bs(S, K, q_eq, T)),
    ("house yield q = 2%, call", c_yield), ("house yield q = 2%, put", p_yield),
    ("forward with the cash dividend, S* e^rT", sx * exp(R * T)),
    ("  the same forward from the carry ledger", S * exp(R * T) - D1 * exp(R * (T - TD))),
    ("forward with the house yield, S e^(r-q)T", S * exp((R - 0.02) * T)),
    ("wrong: dividend not discounted, call", bs(S - D1, K, 0.0, T)),
    ("wrong: escrowed and q = 2% as well, call", bs(sx, K, 0.02, T)),
    ("wrong: a 2.00 dividend at 18m escrowed", bs(sx - D1 * exp(-R * 1.5), K, 0.0, T)),
    (f"dividend layer, up from node {node}", up_d),
    (f"dividend layer, down from node {node + 1}", down_d),
    ("  the would-be twins differ by", down_d - up_d),
    ("escrowed layer, the same twins differ by", abs(down_e - up_e))]
for name, v in rows:
    print(f"{name:<44}{v:>14.6f}")
print(f"{'escrowed tree, nodes in the last layer':<44}{STEPS + 1:>14d}\n{'exploded tree, nodes in the last layer':<44}{nodes_drop:>14d}")
print()
print("across the ex-dividend date, six months to expiry")
for label, quoted, ahead in (("day before, 2.00 due at once", S, D1),
                             ("day after, nothing left", S - D1, 0.0),
                             ("a share that never pays", S, 0.0)):
    print(f"  {label:<30} Acme {quoted:6.2f}  escrowed {quoted - ahead:6.2f}"
          f"  call {bs(quoted - ahead, K, 0.0, 0.5):5.2f}")
print()
print("bars: one dividend paid at six months, escrowed call")
for size in (0.0, 2.0, 5.0, 10.0, 20.0):
    print(f"  dividend {size:5.2f}   call {bs(S - size * exp(-R * TD), K, 0.0, T):5.2f}")
print()
share = [S * exp(R * m / 12.0) - (0.0 if m <= 6 else D1 * exp(R * (m / 12.0 - TD))) for m in range(13)]
print(f"{'chart, month':<30}" + "".join(f"{m:>7d}" for m in range(13)))
print(f"{'chart, Acme with the dividend':<30}" + "".join(f"{v:>7.2f}" for v in share))
print(f"{'chart, the escrowed part':<30}" + "".join(f"{sx * exp(R * m / 12.0):>7.2f}" for m in range(13)))
strikes = [80.0 + 5.0 * i for i in range(9)]
print(f"{'chart, strike':<30}" + "".join(f"{k:>7.0f}" for k in strikes))
print(f"{'chart, no dividend':<30}" + "".join(f"{bs(S, k, 0.0, T):>7.2f}" for k in strikes))
print(f"{'chart, 2.00 cash dividend':<30}" + "".join(f"{bs(sx, k, 0.0, T):>7.2f}" for k in strikes))
assert abs((S * exp(R * T) - D1 * exp(R * (T - TD))) - sx * exp(R * T)) < 1e-9, "carry ledger against the escrowed spot"
assert abs(c_form - c_avg) < 1e-7, "formula against the payoff average, escrowed model"
assert abs(p_form - p_avg) < 1e-7, "put formula against the put's own payoff average"
assert abs(c_form - c_tree) < 0.005, "formula against the recombining tree"
assert abs((c_form - p_avg) - (sx - K * exp(-R * T))) < 1e-6, "parity, put from the average"
assert abs(c_drop_avg - c_drop_tree) < 0.005, "two roads to the cash-drop model"
assert abs(c_yield - 9.227005508154) < 1e-9, "the shelf's yield call, from this machinery"
assert c_drop_avg > c_form, "escrowing must price under the cash-drop model"
assert abs(down_d - up_d) > 1e-3, "paying cash at a node must break the meeting"
assert abs(down_e - up_e) < 1e-6, "with no cash paid, the same two paths must meet"
print("ALL CHECKS PASS")
