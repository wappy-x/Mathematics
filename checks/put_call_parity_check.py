# Put-call parity -- the check behind the card.  Standard library only.  Every number
# quoted on the card is printed here.  Nothing imported already knows the answer: the
# bell-curve area comes from math.erf, the call and the put are priced again by Simpson's
# rule and by a coin-flip tree, and the payoff identity is checked price by price.
from math import log, sqrt, exp, erf, pi

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
STEPS, PANELS, QUOTE = 1000, 40000, 6.0

def N(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))       # bell-curve area left of x
def phi(x):  return exp(-0.5 * x * x) / sqrt(2.0 * pi)     # bell-curve height at x
def cpay(x): return max(x - K, 0.0)                        # call payoff on expiry day
def ppay(x): return max(K - x, 0.0)                        # put payoff on expiry day
def row(name, v): print(f"{name:<40}{v:>14.6f}")

def d1d2(s, k, rr, qq, sg, t):
    vt = sg * sqrt(t)
    d1 = (log(s / k) + (rr - qq + 0.5 * sg * sg) * t) / vt
    return d1, d1 - vt
def call(s, k, rr, qq, sg, t):                             # road 2: the call card's formula
    d1, d2 = d1d2(s, k, rr, qq, sg, t)
    return s * exp(-qq * t) * N(d1) - k * exp(-rr * t) * N(d2)
def put(s, k, rr, qq, sg, t):                              # road 2: the put card's formula
    d1, d2 = d1d2(s, k, rr, qq, sg, t)
    return k * exp(-rr * t) * N(-d2) - s * exp(-qq * t) * N(-d1)
def by_integral(payoff, n=PANELS):
    # Road 3: average the payoff over the bell curve by brute force (Simpson's
    # rule).  Uses no d1, no d2 and no parity -- nothing borrowed from road 2.
    a, b = -10.0, 10.0
    h = (b - a) / n
    def f(z):
        st = S * exp((r - q - 0.5 * sigma * sigma) * T + sigma * sqrt(T) * z)
        return payoff(st) * phi(z)
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return exp(-r * T) * total * h / 3.0

def by_tree(payoff, steps=STEPS, early=False):
    # Road 4: the coin-flip tree (Cox-Ross-Rubinstein).  Up or down each step,
    # then average back.  early=True also allows exercise at every node.
    dt = T / steps
    u = exp(sigma * sqrt(dt)); d = 1.0 / u
    p = (exp((r - q) * dt) - d) / (u - d)
    disc = exp(-r * dt)
    v = [payoff(S * u ** j * d ** (steps - j)) for j in range(steps + 1)]
    for step in range(steps, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(step)]
        if early:
            v = [max(v[j], payoff(S * u ** j * d ** (step - 1 - j))) for j in range(step)]
    return v[0]

disc_r, disc_q, dear_q = exp(-r * T), exp(-q * T), exp(-(q + 0.01) * T)  # dear_q: the yield guessed 1% high
C, P = call(S, K, r, q, sigma, T), put(S, K, r, q, sigma, T)
rhs = S * disc_q - K * disc_r
c_int, p_int = by_integral(cpay), by_integral(ppay)
c_tree, p_tree = by_tree(cpay), by_tree(ppay)
c_amer, p_amer = by_tree(cpay, early=True), by_tree(ppay, early=True)
cash = C - QUOTE - S * disc_q + K * disc_r

print(f"house market: S {S:.2f}  K {K:.2f}  r {r * 100:.2f}%  q {q * 100:.2f}%  "
      f"volatility {sigma * 100:.2f}%  T {T:.2f} years")
print("road 1: on expiry day a long call minus a short put is S_T - K, and box A = box B")
print(f"{'share at expiry':>16}{'long call':>11}{'short put':>11}{'sum':>11}"
      f"{'S_T - K':>11}{'box A':>11}{'box B':>11}")
for st in (60.0, 80.0, 99.99, 100.0, 100.01, 120.0, 140.0):
    print(f"{st:>16.2f}{cpay(st):>11.2f}{0.0 - ppay(st):>11.2f}{cpay(st) - ppay(st):>11.2f}"
          f"{st - K:>11.2f}{cpay(st) + K:>11.2f}{ppay(st) + st:>11.2f}")
grid = [0.01] + [25.0 * i for i in range(1, 41)]
gap_id = max(abs((cpay(x) - ppay(x)) - (x - K)) for x in grid)
gap_box = max(abs((cpay(x) + K) - (ppay(x) + x)) for x in grid)
print(f"worst gap over {len(grid)} prices from {min(grid):.2f} to {max(grid):.2f}: "
      f"identity {gap_id:.6f}, boxes {gap_box:.6f}")
print()
print("roads 2, 3 and 4: the two prices, and the two sides of the parity line")
print(f"{'discount factors e^-qT and e^-rT':<40}{disc_q:>14.6f}{disc_r:>14.6f}")
for name, v in (("call, formula", C), ("put, formula", P), ("C - P", C - P),
                ("S e^-qT, the prepaid share", S * disc_q),
                ("K e^-rT, the loan that repays K", K * disc_r),
                ("S e^-qT - K e^-rT", rhs),
                ("call, Simpson integral", c_int), ("put, Simpson integral", p_int),
                ("C - P, from the integrals", c_int - p_int),
                (f"call, {STEPS}-step tree", c_tree), (f"put, {STEPS}-step tree", p_tree),
                ("C - P, from the tree", c_tree - p_tree),
                ("forward, K + (C - P) e^rT", K + (C - P) * exp(r * T)),
                ("forward, S e^(r-q)T", S * exp((r - q) * T))):
    row(name, v)
print(f"the gap in two pieces: interest not paid early on K {K * (1.0 - disc_r):.6f} "
      f"minus dividends missed on S {S * (1.0 - disc_q):.6f} = {rhs:.6f}")
print()
print("C - P does not move when the volatility moves (each step doubles it)")
print(f"{'volatility':>12}{'call':>10}{'put':>10}{'C - P':>10}")
flat = 0.0
for sg in (0.05, 0.10, 0.20, 0.40, 0.80):
    cv, pv = call(S, K, r, q, sg, T), put(S, K, r, q, sg, T)
    flat = max(flat, abs((cv - pv) - rhs))
    print(f"{sg * 100:>11.2f}%{cv:>10.2f}{pv:>10.2f}{cv - pv:>10.2f}")
print()
print(f"the conversion trade: the put is quoted at {QUOTE:.2f}, parity says {P:.6f}")
print(f"today: sell the call +{C:.6f}, buy the put -{QUOTE:.6f}, "
      f"buy e^-qT shares -{S * disc_q:.6f}, borrow +{K * disc_r:.6f}")
print(f"cash banked today {cash:.6f}, which is the put's shortfall {P - QUOTE:.6f}")
print(f"{'share at expiry':>16}{'short call':>12}{'long put':>12}{'share':>12}"
      f"{'loan':>12}{'net':>12}")
worst_net = 0.0
for st in (60.0, 100.0, 140.0):
    net = 0.0 - cpay(st) + ppay(st) + st - K
    worst_net = max(worst_net, abs(net))
    print(f"{st:>16.2f}{0.0 - cpay(st):>12.2f}{ppay(st):>12.2f}{st:>12.2f}"
          f"{0.0 - K:>12.2f}{net:>12.2f}")
print()
print(f"what breaks: the wrong right-hand side, and the put it backs out of a call of {C:.6f}")
for name, side in (("strike not discounted, S - K", S - K),
                   ("dividend dropped, S - K e^-rT", S - K * disc_r),
                   ("sides swapped, K e^-rT - S e^-qT", K * disc_r - S * disc_q),
                   ("yield 1% too high, wrong S e^-qT", S * dear_q - K * disc_r)):
    print(f"{name:<40}{side:>14.6f}{C - side:>14.6f}")
print(f"early exercise: {STEPS}-step American put {p_amer:.6f} against European "
      f"{p_tree:.6f}, so C_A - P_A is {c_amer - p_amer:.6f}, not {rhs:.6f}")
print(f"try changing: r = 0 gives C - P {call(S, K, 0.0, q, sigma, T) - put(S, K, 0.0, q, sigma, T):.6f}; "
      f"q = r gives call {call(S, K, r, r, sigma, T):.6f} and put {put(S, K, r, r, sigma, T):.6f}; "
      f"K = 120 gives C - P {call(S, 120.0, r, q, sigma, T) - put(S, 120.0, r, q, sigma, T):.6f}")

assert abs(C - 9.227005508154) < 1e-9,       "the call formula against the shelf's house number"
assert abs(P - 6.330080627550) < 1e-9,       "the put formula against the shelf's house number"
assert abs((C - P) - rhs) < 1e-12,           "two formula prices against plain discounting"
assert abs((c_int - p_int) - rhs) < 1e-7,    "two brute-force integrals against discounting"
assert abs((c_tree - p_tree) - rhs) < 1e-9,  "the tree's two prices against discounting"
assert abs(c_tree - C) > 1e-4,               "the tree's own call price is off, yet parity held"
assert gap_id < 1e-12,                       "the payoff identity at every price on the grid"
assert gap_box < 1e-12,                      "box A against box B at every price on the grid"
assert flat < 1e-9,                          "C - P unmoved across five volatilities"
assert abs(cash - (P - QUOTE)) < 1e-12,      "the trade's opening cash against the put's shortfall"
assert worst_net < 1e-12,                    "the trade pays nothing at expiry, at every price"
assert 0.3 < p_amer - p_tree < 0.5,          "the early-exercise right, a third of a dollar on a fine tree"
assert rhs - (c_amer - p_amer) > 0.1,        "and it breaks the equality by a visible amount"
assert abs((K + (C - P) * exp(r * T)) - S * exp((r - q) * T)) < 1e-9, "forward two ways"
assert (C - (S * dear_q - K * disc_r)) - P > 0.9, "a yield 1% too high backs out a dearer put, not a cheaper one"
print("ALL CHECKS PASS")
