# Monte Carlo pricing -- the check behind the card.  Standard library only.
# Nothing is imported that already knows the answer: the uniform numbers come
# from the recurrence printed on the card, the normals from Box-Muller, and the
# bell-curve area and the reference integral from Simpson's rule written out.
from math import cos, exp, log, pi, sin, sqrt

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0   # the house market
SEED, PATHS = 20260914, 100000
MARKS = (1000, 5000, 10000, 25000, 50000, 75000, 100000)   # where the chart reads
PREFIX = (1000, 10000, 25000, 100000)                      # where the table reads
EXACT = 9.227005508154                 # the formula's price, from the call card
MOD = 1 << 32

def uniform(state):                    # one step of the recurrence, whole numbers
    state = (1664525 * state + 1013904223) % MOD
    return state, (state + 0.5) / MOD                   # lands strictly inside 0, 1

def normal_pair(state):                # Box-Muller: two uniforms -> two normals
    state, u = uniform(state)
    state, v = uniform(state)
    radius, angle = sqrt(-2.0 * log(u)), 2.0 * pi * v
    return state, radius * cos(angle), radius * sin(angle)

def simpson(f, a, b, n):               # the integrator, written out here
    h = (b - a) / n
    total = f(a) + f(b)
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return total * h / 3.0

def phi(x):                            # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def n_cdf(x):                          # bell-curve area to the left of x
    if x < -12.0:
        return 0.0
    if x > 12.0:
        return 1.0
    return 0.5 + simpson(phi, 0.0, x, 4000)

def call_formula(s, k, r, q, sig, t):  # road 2: the closed form, own CDF
    vt = sig * sqrt(t)
    d1 = (log(s / k) + (r - q + 0.5 * sig * sig) * t) / vt
    return s * exp(-q * t) * n_cdf(d1) - k * exp(-r * t) * n_cdf(d1 - vt)

def payoff_integral(s, k, r, q, sig, t):   # road 3: the same average, by slices
    drift = (r - q - 0.5 * sig * sig) * t
    def f(z):
        return max(s * exp(drift + sig * sqrt(t) * z) - k, 0.0) * phi(z)
    return exp(-r * t) * simpson(f, -10.0, 10.0, 40000)

def run(drift, disc, paths, marks=()):     # road 1: the simulation
    state, n, mean, m2, stock = SEED, 0, 0.0, 0.0, 0.0
    marked = []
    while n < paths:
        state, z1, z2 = normal_pair(state)
        for z in (z1, z2):
            st = S * exp(drift + SIG * sqrt(T) * z)     # one simulated ending price
            pay = disc * max(st - K, 0.0)               # its discounted payoff
            stock += disc * st
            n += 1
            delta = pay - mean                          # running mean and spread
            mean += delta / n
            m2 += delta * (pay - mean)
            if n in marks:
                sd = sqrt(m2 / (n - 1))
                marked.append((n, mean, sd, sd / sqrt(n)))
    return mean, stock / n, marked

disc = exp(-R * T)
drift = (R - Q - 0.5 * SIG * SIG) * T
mc, stock_mean, marked = run(drift, disc, PATHS, MARKS)
table = {n: (m, sd, se) for n, m, sd, se in marked}
se_end = table[PATHS][2]
formula = call_formula(S, K, R, Q, SIG, T)
integral = payoff_integral(S, K, R, Q, SIG, T)
wrong_real = run((0.10 - Q - 0.5 * SIG * SIG) * T, disc, PATHS)[0]
wrong_drag = run((R - Q) * T, disc, PATHS)[0]
wrong_disc = run(drift, 1.0, PATHS)[0]
wrong_one = disc * max(S * exp((R - Q) * T) - K, 0.0)

print(f"Acme: S = {S:.2f}  K = {K:.2f}  r = {R * 100:.0f}%  q = {Q * 100:.0f}%  "
      f"sigma = {SIG * 100:.0f}%  T = {T:.0f} year")
print(f"{PATHS} draws from seed {SEED}, in Box-Muller pairs from the printed recurrence")
print()
state, shown, first_mean = SEED, [], 0.0         # the first four draws, one by one
while len(shown) < 4:
    state, za, zb = normal_pair(state)
    for z in (za, zb):
        st = S * exp(drift + SIG * sqrt(T) * z)
        pay = disc * max(st - K, 0.0)
        first_mean += (pay - first_mean) / (len(shown) + 1)
        shown.append((z, st, max(st - K, 0.0), pay, first_mean))
print("  draw           z   ending price       payoff    discounted   running mean")
for i, (z, st, raw, pay, avg) in enumerate(shown):
    print(f"{i + 1:>6}  {z:>10.6f}  {st:>13.6f}  {raw:>11.6f}  {pay:>12.6f}  {avg:>12.6f}")
print(f"one year's discount factor e^-rT                    {disc:>12.6f}")
print(f"pretend-world drift (r - q - sigma^2/2)T            {drift:>12.6f}")
print(f"one wiggle unit sigma sqrt(T)                       {SIG * sqrt(T):>12.6f}")
print()
print(f"road 1  simulation, {PATHS} paths                  {mc:>12.6f}")
print(f"road 2  closed form, own bell-curve area          {formula:>12.6f}")
print(f"road 3  the same average by Simpson slices        {integral:>12.6f}")
print(f"sampler check  average of e^-rT S_T              {stock_mean:>13.6f}")
print(f"               the market's S e^-qT              {S * exp(-Q * T):>13.6f}")
print()
print("  paths     estimate    payoff sd    std error   two-SE low  two-SE high   gap to road 2")
for n in PREFIX:
    m, sd, se = table[n]
    print(f"{n:>7}  {m:>11.6f}  {sd:>11.6f}  {se:>11.6f}  {m - 2 * se:>11.6f}  "
          f"{m + 2 * se:>11.6f}  {m - formula:>13.6f}")
print()
print(f"root-n law, same draws:  SE(1000) / SE(100000) = {table[1000][2] / se_end:>6.3f}   (theory 10.000)")
print(f"                        SE(25000) / SE(100000) = {table[25000][2] / se_end:>6.3f}   (theory  2.000)")
print()
print("what breaks")
print(f"  a 10% real-world drift in place of r - q                   {wrong_real:>12.6f}")
print(f"  drift without the -sigma^2/2 drag                         {wrong_drag:>12.6f}")
print(f"  no discount factor e^-rT                                  {wrong_disc:>12.6f}")
print(f"  payoff of the average ending, not average of payoffs      {wrong_one:>12.6f}")
print()
print("bar, standard error in dollars at " + ", ".join(str(n) for n in PREFIX)
      + " paths: " + "  ".join(f"{table[n][2]:.2f}" for n in PREFIX))
print("chart, paths             " + " ".join(f"{n:>7}" for n in MARKS))
print("chart, running estimate  " + " ".join(f"{table[n][0]:>7.2f}" for n in MARKS))
print("chart, road 2 price      " + " ".join(f"{formula:>7.2f}" for _ in MARKS))

assert abs(formula - EXACT) < 1e-9, "closed form vs the call card's price"
assert abs(integral - EXACT) < 1e-7, "Simpson average vs the call card's price"
assert abs(mc - formula) < 3.0 * se_end, "simulation within three standard errors"
assert abs(stock_mean - S * exp(-Q * T)) < 0.5, "the sampler drifts as the pretend world does"
assert 1.7 < table[25000][2] / se_end < 2.3, "four times the paths, half the error"
assert abs(wrong_one - 2.896925) < 1e-6, "one average future prices the forward, not the option"
assert wrong_real > wrong_drag > mc, "each broken drift lifts the estimate"
print("ALL CHECKS PASS")
