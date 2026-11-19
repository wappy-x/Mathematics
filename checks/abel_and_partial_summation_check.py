# Partial summation (Abel's identity) in both directions: prime count pi(x) <-> log sum theta(x).
# Roads: a direct sum over sieved primes; Abel's identity with its integral done exactly on the steps;
# Abel's identity with the integral done by a midpoint rule that knows nothing about where the steps are.
from math import log, exp

X = 1_000_000
sieve = bytearray([1]) * (X + 1)
sieve[0] = sieve[1] = 0
for i in range(2, int(X ** 0.5) + 1):
    if sieve[i]:
        sieve[i * i :: i] = bytearray(len(range(i * i, X + 1, i)))
primes = [n for n in range(X + 1) if sieve[n]]
pc = [0] * (X + 1)     # pc[n] = pi(n), the running count
th = [0.0] * (X + 1)   # th[n] = theta(n), the running log sum
c, s = 0, 0.0
for n in range(X + 1):
    if sieve[n]:
        c += 1
        s += log(n)
    pc[n], th[n] = c, s

def add(values):   # plain left-to-right sum (Python's sum() compensates; Rust's loop does not)
    total = 0.0
    for v in values:
        total += v
    return total

def abel_theta(x, ps):
    """theta(x) = pi(x) log x - integral_2^x pi(t)/t dt, integral exact: pi(t) = k on [p_k, p_k+1)."""
    integral = add(k * (log(ps[k]) - log(ps[k - 1])) for k in range(1, len(ps)))
    integral += len(ps) * (log(x) - log(ps[-1]))
    return len(ps) * log(x) - integral, integral

def abel_pi(x, ps):
    """pi(x) = theta(x)/log x + integral_2^x theta(t)/(t log^2 t) dt; on a step, antiderivative is -1/log t."""
    run, integral = 0.0, 0.0
    for k in range(len(ps)):
        run += log(ps[k])
        top = ps[k + 1] if k + 1 < len(ps) else x
        integral += run * (1 / log(ps[k]) - 1 / log(top))
    return run / log(x) + integral, integral

def midpoint(g, a, b, m):
    h = (b - a) / m
    return h * add(g(a + (i + 0.5) * h) for i in range(m))

def simpson(g, a, b, m):
    h = (b - a) / m
    return h / 3 * (g(a) + g(b) + add((4 if i % 2 else 2) * g(a + i * h) for i in range(1, m)))

# ---- by hand: x = 10, primes 2, 3, 5, 7 ----
small = [2, 3, 5, 7]
th10, i10 = abel_theta(10, small)
pi10, j10 = abel_pi(10, small)
print("hand, x = 10, primes 2 3 5 7")
ends = small + [10]
for k in range(1, 5):
    label = f"hand, pi = {k} on [{ends[k-1]}, {ends[k]}): {k} log({ends[k]}/{ends[k-1]})"
    print(f"{label:<36} {k * log(ends[k] / ends[k-1]):10.4f}")
print(f"hand, pi(10) log 10                  {4 * log(10):10.4f}")
print(f"hand, integral of pi(t)/t, 2 to 10   {i10:10.4f}")
print(f"hand, theta(10) by Abel              {th10:10.4f}")
print(f"hand, theta(10) = log 210            {log(210):10.4f}")
print(f"hand, theta(10)/log 10               {th10 / log(10):10.4f}")
print(f"hand, integral theta/(t log^2 t)     {j10:10.4f}")
print(f"hand, pi(10) by Abel                 {pi10:10.4f}")

# ---- a million: count -> log sum ----
L = log(X)
theta_direct = th[X]
theta_abel, int1 = abel_theta(X, primes)
int1_mid = midpoint(lambda u: pc[int(exp(u))], log(2), L, 400_000)
print()
print(f"pi(1000000) by sieve                 {len(primes):14d}")
print(f"1 theta, direct sum of log p         {theta_direct:14.3f}")
print(f"  log x                              {L:14.4f}")
print(f"  pi(x) log x                        {len(primes) * L:14.3f}")
print(f"  integral pi(t)/t, exact steps      {int1:14.3f}")
print(f"  integral pi(t)/t, midpoint rule    {int1_mid:14.3f}")
print(f"  area / x, the gap between ratios   {int1 / X:14.4f}")
print(f"2 theta by Abel, exact steps         {theta_abel:14.3f}")
print(f"3 theta by Abel, midpoint rule       {len(primes) * L - int1_mid:14.3f}")
# ---- a million: log sum -> count ----
pi_abel, int2 = abel_pi(X, primes)
int2_mid = midpoint(lambda u: th[int(exp(u))] / (u * u), log(2), L, 400_000)
print(f"  theta(x)/log x                     {theta_direct / L:14.3f}")
print(f"  integral theta/(t log^2 t), steps  {int2:14.3f}")
print(f"  integral, midpoint rule            {int2_mid:14.3f}")
print(f"2 pi by Abel, exact steps            {pi_abel:14.3f}")
print(f"3 pi by Abel, midpoint rule          {theta_direct / L + int2_mid:14.3f}")
# ---- where x/log x loses 7.8 percent: pi = x/log x + (theta - x)/log x + integral ----
li_off = simpson(lambda u: exp(u) / u, log(2), L, 20_000)
sub = X / L + simpson(lambda u: exp(u) / (u * u), log(2), L, 20_000)
print(f"  x/log x                            {X / L:14.3f}")
print(f"  (theta(x) - x)/log x               {(theta_direct - X) / L:14.3f}")
print(f"  theta(t) = t put in: x/log x + int {sub:14.3f}")
print(f"  Li(x) by Simpson                   {li_off:14.3f}")
print(f"  Li(x) + 2/log 2                    {li_off + 2 / log(2):14.3f}")

# ---- the two ratios at several sizes ----
print()
print(f"{'x':>9} {'pi(x)':>7} {'theta(x)':>12} {'theta/x':>8} {'x - theta':>10} {'pi log x/x':>11}")
for x in (100, 1000, 10_000, 100_000, X):
    print(f"{x:>9} {pc[x]:>7} {th[x]:>12.3f} {th[x] / x:>8.4f} {x - th[x]:>10.3f} {pc[x] * log(x) / x:>11.4f}")

# ---- what breaks ----
half = pc[X // 2]
jump_true = sum(1 if p <= X // 2 else 2 for p in primes)   # weight 1 up to 500,000, then 2
jump_naive = 2 * len(primes)                               # A(x) f(x), f' = 0 away from the jump
jump_stieltjes = jump_naive - half * 1                     # the jump of size 1 adds -A(500000) x 1
print()
print(f"wrong: theta = pi(x) log x           {len(primes) * L:14.3f}")
print(f"  overshoot, percent of theta        {100 * (len(primes) * L - theta_direct) / theta_direct:14.3f}")
print(f"wrong: integral added, not taken     {len(primes) * L + int1:14.3f}")
print(f"wrong: pi = theta(x)/log x           {theta_direct / L:14.3f}")
print(f"  shortfall, percent of pi(x)        {100 * (len(primes) - theta_direct / L) / len(primes):14.3f}")
print(f"  x/log x shortfall, percent         {100 * (len(primes) - X / L) / len(primes):14.3f}")
print(f"jump weight: A(500000) = pi(500000)  {half:14d}")
print(f"jump weight: true sum                {jump_true:14d}")
print(f"jump weight: f' only, jump ignored   {jump_naive:14d}")
print(f"jump weight: jump term -A(500000)    {jump_stieltjes:14d}")
# ---- try changing ----
recip_direct = add(1 / p for p in primes)
recip_abel = len(primes) / X + add(k * (1 / primes[k - 1] - 1 / primes[k]) for k in range(1, len(primes))) \
    + len(primes) * (1 / primes[-1] - 1 / X)
print(f"try: sum of 1/p, direct              {recip_direct:14.6f}")
print(f"try: sum of 1/p, Abel                {recip_abel:14.6f}")
print(f"try: theta by midpoint, 4000 steps  {len(primes) * L - midpoint(lambda u: pc[int(exp(u))], log(2), L, 4000):14.3f}")

assert len(primes) == 78498,                        "the published count of primes below a million"
assert abs(th10 - log(210)) < 1e-12,                "hand case: Abel equals the log of 2*3*5*7"
assert abs(theta_abel - theta_direct) < 1e-6,       "Abel with exact steps vs direct sum"
assert abs(len(primes) * L - int1_mid - theta_direct) < 0.5, "Abel by blind midpoint rule vs direct sum"
assert abs(pi_abel - len(primes)) < 1e-6,           "reverse direction returns the sieve count"
assert abs(theta_direct / L + int2_mid - len(primes)) < 0.5, "reverse, midpoint rule"
assert abs(sub - (li_off + 2 / log(2))) < 1e-6,     "theta = t gives Li(x) + 2/log 2"
assert jump_stieltjes == jump_true != jump_naive,   "a jump in the weight needs its own term"
assert abs(recip_abel - recip_direct) < 1e-9,       "sum of 1/p two ways"
print("ALL CHECKS PASS")
