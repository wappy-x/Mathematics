# Mean reversion -- the check behind the card.  Standard library only.
# A spread between two petrol retailers is simulated from a known Ornstein-
# Uhlenbeck model, then fitted blind.  The random numbers, the bell-curve area
# and both integrals are written here; nothing imported knows the answer.
from math import log, exp, sqrt, cos, pi

MASK = (1 << 64) - 1
state = 20260928
def uniform():                                  # splitmix64, top 53 bits into (0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0
def normal():                                   # Box-Muller: two uniforms, one bell-curve draw
    u1, u2 = uniform(), uniform()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
def ncdf(x):                                    # bell-curve area left of x, by its power series
    term, total, k = x, x, 1
    while abs(term) > 1e-17 * (1.0 + abs(total)):
        term *= x * x / (2 * k + 1); total += term; k += 1
    return 0.5 + exp(-0.5 * x * x) / sqrt(2.0 * pi) * total
def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3.0

# ---- the true model: dollars and trading days ----
theta, sd, half = 10.0, 2.0, 12.0               # long-run mean, long-run spread, half-life
kappa = log(2.0) / half                         # pull speed per day
beta = exp(-kappa)                              # share of a gap left after one day
alpha = (1.0 - beta) * theta
eps_sd = sd * sqrt(1.0 - beta * beta)           # one day's fresh noise
sigma = sqrt(2.0 * kappa) * sd                  # noise per square-root day
def step(x): return alpha + beta * x + eps_sd * normal()
def slope(a, b):                                # least-squares slope and intercept of b on a
    n = len(a); ma, mb = sum(a) / n, sum(b) / n
    sab = sum((p - ma) * (q - mb) for p, q in zip(a, b))
    saa = sum((p - ma) * (p - ma) for p in a)
    return sab / saa, mb - sab / saa * ma
def fit(xs):                                    # road 1: tomorrow on today, then map to OU
    b, a = slope(xs[:-1], xs[1:])
    q = sum((y - a - b * x) * (y - a - b * x) for x, y in zip(xs[:-1], xs[1:])) / (len(xs) - 1)
    k = -log(b)
    return b, a, sqrt(q), k, log(2.0) / k, a / (1.0 - b), sqrt(q / (1.0 - b * b))
def trade(xs, th, s, enter):                    # short at z >= +enter, long at z <= -enter, out at 0
    pos, x0, t0, gains, holds = 0, 0.0, 0, [], []
    for t, x in enumerate(xs):
        z = (x - th) / s
        if pos == 0 and abs(z) >= enter:
            pos, x0, t0 = (-1 if z > 0 else 1), x, t
        elif pos != 0 and pos * z >= 0.0:
            gains.append(pos * (x - x0)); holds.append(t - t0); pos = 0
    return gains, holds

print(f"hand: beta {beta:.6f}  alpha {alpha:.6f}  one-day noise {eps_sd:.6f}  ln 2 {log(2.0):.6f}")
print(f"hand: 1 - beta {1 - beta:.6f}  -ln beta {kappa:.6f}  1 - beta^2 {1 - beta * beta:.6f}")
print(f"hand: half-life {log(2.0) / -log(beta):.4f}  mean {alpha / (1 - beta):.4f}  "
      f"long-run sd {eps_sd / sqrt(1 - beta * beta):.4f}  sigma {sigma:.6f}")
print(f"hand: enter short at {theta + 2 * sd:.2f}  enter long at {theta - 2 * sd:.2f}  exit at {theta:.2f}  gain to the mean {2 * sd:.2f}")
e12 = exp(-12.0 * kappa)
print(f"hand: from 14, day 12 mean {theta + 4.0 * e12:.4f}  sd {sd * sqrt(1.0 - e12 * e12):.4f}")
for name, f in (("day", lambda t: t), ("expected", lambda t: theta + 4.0 * exp(-kappa * t)),
                ("plus one sd", lambda t: theta + 4.0 * exp(-kappa * t) + sd * sqrt(1.0 - exp(-2.0 * kappa * t))),
                ("minus one sd", lambda t: theta + 4.0 * exp(-kappa * t) - sd * sqrt(1.0 - exp(-2.0 * kappa * t)))):
    print(f"chart, {name:<12}" + "".join(f"{f(float(t)):7.2f}" for t in range(0, 37, 6)))

# ---- road 1 and road 2 on one ten-year record, fitted on the first five ----
xs = [theta + sd * normal()]
for _ in range(2520): xs.append(step(xs[-1]))
train, test = xs[:1261], xs[1260:]
bh, ah, qh, kh, hh, th, sdh = fit(train)
print(f"record: {len(xs) - 1} days; fitted on the first {len(train) - 1}, traded on the last {len(test) - 1}")
b12, _ = slope(train[:-12], train[12:])
h12 = 12.0 * log(2.0) / -log(b12)
print(f"fit, 1260 days: beta {bh:.6f}  alpha {ah:.6f}  one-day noise {qh:.6f}  kappa {kh:.6f}")
print(f"fit, 1260 days: half-life {hh:.2f} d  mean {th:.4f}  long-run sd {sdh:.4f}")
print(f"road 2, 12-day slope {b12:.4f}  half-life from it {h12:.2f} d")
hs = []
for _ in range(300):
    ys = [theta + sd * normal()]
    for _ in range(1260): ys.append(step(ys[-1]))
    hs.append(fit(ys)[4])
hs.sort()
print(f"300 records of 1260 days: fitted half-life 5th pct {hs[14]:.2f}  median {hs[149]:.2f}  95th pct {hs[284]:.2f}")

# ---- the model's promises, checked against simulation ----
ends = []
for _ in range(20000):
    x = 14.0
    for _ in range(12): x = step(x)
    ends.append(x)
mc_mean = sum(ends) / 20000
mc_sd = sqrt(sum((e - mc_mean) * (e - mc_mean) for e in ends) / 19999)
print(f"from 14, day 12, 20000 paths: mean {mc_mean:.4f}  sd {mc_sd:.4f}")
tail = 2.0 * (1.0 - ncdf(2.0))
tail_int = 1.0 - simpson(lambda u: exp(-0.5 * u * u) / sqrt(2.0 * pi), -2.0, 2.0, 2000)
x, far = theta + sd * normal(), 0
for _ in range(200000):
    x = step(x); far += abs(x - theta) >= 2.0 * sd
print(f"share of days |z| >= 2: series {tail:.6f}  integral {tail_int:.6f}  200000 days {far / 200000:.4f}")
def mills(s): return (1.0 - ncdf(s)) * sqrt(2.0 * pi) * exp(0.5 * s * s)
wait = simpson(mills, 0.0, 2.0, 400) / kappa     # mean wait from z = 2 down to 0, watched always
def sim_wait(sub, trials, bridge):              # the same wait, simulated in `sub` slices a day
    bs = exp(-kappa / sub); es = sd * sqrt(1.0 - bs * bs); tot = 0.0
    for _ in range(trials):
        x, k = 14.0, 0
        while True:
            y = theta + bs * (x - theta) + es * normal(); k += 1
            if y <= theta: break
            if bridge and uniform() < exp(-2.0 * (x - theta) * (y - theta) / (es * es)): break
            x = y
        tot += k - (0.5 if bridge else 0.0)
    return tot / trials / sub
w4, w1 = sim_wait(4, 10000, True), sim_wait(1, 20000, False)
print(f"wait z 2 -> 0: formula {wait:.2f} d  simulated, watched always {w4:.2f} d  checked at each close {w1:.2f} d")
xs = [theta + sd * normal()]                      # one long record: both roads should land on 12
for _ in range(1000000): xs.append(step(xs[-1]))
r1, r2 = fit(xs)[4], 12.0 * log(2.0) / -log(slope(xs[:-12], xs[12:])[0])
print(f"1000000 days: half-life by road 1 {r1:.2f} d  by road 2 {r2:.2f} d")

# ---- thresholds: fitted on years 1-5, traded on years 6-10, $1.00 cost a round trip ----
print("enter  trades  hold d  gain/trade $  total $  after 1.00 a trade $")
for e in (1.0, 1.5, 2.0, 2.5, 3.0):
    g, hd = trade(test, th, sdh, e)
    print(f"{e:5.1f}  {len(g):6d}  {sum(hd) / len(g):6.2f}  {sum(g) / len(g):12.2f}  {sum(g):7.2f}  {sum(g) - len(g):20.2f}")

# ---- what breaks ----
print(f"wrong: half-life from the Euler slope, ln 2 / (1 - beta) = {log(2.0) / (1.0 - beta):.2f} d")
print(f"wrong: z from one-day noise, 4 / {eps_sd:.4f} = {4.0 / eps_sd:.2f}")

assert abs(mc_mean - (theta + 4.0 * e12)) < 0.05          # simulated mean vs the transition formula
assert abs(mc_sd - sd * sqrt(1.0 - e12 * e12)) < 0.04    # simulated spread vs the transition formula
assert abs(tail - tail_int) < 1e-9                       # series vs integral for the bell-curve tail
assert abs(far / 200000 - tail) < 0.01                   # time beyond 2 sd vs the long-run bell curve
assert abs(w4 - wait) < 1.0                              # simulated wait vs the Mills-ratio integral
assert hs[14] < half < hs[284] and abs(hs[149] - half) < 1.5   # the regression recovers 12 days
assert abs(r1 - half) < 0.2 and abs(r2 - half) < 0.2 and abs(r1 - r2) < 0.15  # two roads, one answer
print("ALL CHECKS PASS")
