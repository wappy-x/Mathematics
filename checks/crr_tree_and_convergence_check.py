# Cox-Ross-Rubinstein -- the check behind the card.  Nothing is imported that
# already knows the answer: the area under the bell curve is Simpson's rule
# written out here, and the limit the tree chases is reached twice.  Acme:
# S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, one year, a call.
from math import exp, log, pi, sqrt

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
HOUSE = 9.227005508154                  # the shelf's Black-Scholes call price

def phi(x):                             # bell-curve height at x
    return exp(-0.5 * x * x) / sqrt(2.0 * pi)

def simpson(f, a, b, n):                # area under f from a to b, n panels
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0

def ncdf(x):                            # area under the bell curve left of x
    return 0.5 + simpson(phi, 0.0, x, 2000)

def bs_call():                          # road 3: the continuous formula
    vt = SIG * sqrt(T)
    d1 = (log(S / K) + (R - Q + 0.5 * SIG * SIG) * T) / vt
    return S * exp(-Q * T) * ncdf(d1) - K * exp(-R * T) * ncdf(d1 - vt)

def bs_slices():                        # road 4: average the payoff by brute force
    def f(z):
        st = S * exp((R - Q - 0.5 * SIG * SIG) * T + SIG * sqrt(T) * z)
        return max(st - K, 0.0) * phi(z)
    return exp(-R * T) * simpson(f, -9.0, 9.0, 36000)

def params(n, root=True, div=True):     # the CRR step: two sizes and a weight
    dt = T / n
    a = SIG * sqrt(dt) if root else SIG * dt      # one step's log move
    u, d = exp(a), exp(-a)
    grow = exp((R - Q) * dt) if div else exp(R * dt)
    return dt, a, u, d, (grow - d) / (u - d), exp(-R * dt)

def tree(n, coin=-1.0, root=True, div=True):      # road 1: walk it backwards
    _, a, _, _, p, disc = params(n, root, div)
    if coin >= 0.0:
        p = coin
    v = [max(S * exp((2 * j - n) * a) - K, 0.0) for j in range(n + 1)]
    for step in range(n, 0, -1):
        for j in range(step):
            v[j] = disc * (p * v[j + 1] + (1.0 - p) * v[j])
    return v[0]

def weights(n):                         # road 2: one weighted sum over the ends
    _, a, _, _, p, _ = params(n)
    w = [0.0] * (n + 1)
    mid = int(n * p)                    # start at the fattest end node, weight 1
    w[mid] = 1.0
    for j in range(mid, n):
        w[j + 1] = w[j] * (n - j) * p / ((j + 1) * (1.0 - p))
    for j in range(mid, 0, -1):
        w[j - 1] = w[j] * j * (1.0 - p) / ((n - j + 1) * p)
    total = price = mean = 0.0
    for j in range(n + 1):
        st = S * exp((2 * j - n) * a)
        total += w[j]
        price += w[j] * max(st - K, 0.0)
        mean += w[j] * st
    return exp(-R * T) * price / total, mean / total

def moments(n):                         # what one step's log move actually does
    dt, a, _, _, p, _ = params(n)
    mean = a * (2.0 * p - 1.0)
    return mean / dt, (a * a - mean * mean) / (SIG * SIG * dt)

def predicted(n):                       # the same two, from the expansion
    drift = R - Q - 0.5 * SIG * SIG
    return drift, 1.0 - (drift / SIG) ** 2 * (T / n)

def row(label, value, tail=""):
    print(f"{label:<46}{value:>11.6f}{tail}")

print(f"Acme on a tree: S {S:.2f}  K {K:.2f}  r 5%  q 2%  sigma 20%  T 1 year, a call")
for label, n in (("one step ", 1), ("two steps", 2)):
    dt, a, u, d, p, disc = params(n)
    ends = [S * exp((2 * j - n) * a) for j in range(n, -1, -1)]
    print(f"{label}  dt {dt:.6f}  u {u:.6f}  d {d:.6f}  grow {exp((R - Q) * dt):.6f}"
          f"  p {p:.6f}  discount {disc:.6f}")
    print("  ends at  " + ", ".join(f"{e:.6f}" for e in ends)
          + f"; the call pays {max(ends[0] - K, 0.0):.6f} at the top")
limit, slices = bs_call(), bs_slices()
forward, mean_2000 = S * exp((R - Q) * T), weights(2000)[1]
row("tree price, 1 step", tree(1))
row("tree price, 2 steps", tree(2))
row("Black-Scholes limit, by formula", limit)
row("the same limit, by brute-force average", slices)
row("tree average end price, 2000 steps", mean_2000)
row("the forward, S e^(r-q)T", forward)
print()
print("steps  tree price  weighted sum   error vs the limit")
gap, priced = 0.0, {}
for n in [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
          50, 100, 250, 500, 1000, 2000, 2001]:
    c, (w, _) = tree(n), weights(n)
    priced[n], gap = c, max(gap, abs(c - w))
    print(f"{n:>5}  {c:>10.6f}  {w:>12.6f}   {c - limit:>+12.6f}")
print("chart, steps 10 to 21, tree price to the cent")
print("  " + "  ".join(f"{priced[n]:.2f}" for n in range(10, 22)) + f"   the limit {limit:.2f}")
print()
pair = 0.5 * (priced[2000] + priced[2001])
row("average of the 2000- and 2001-step prices", pair)
row("its error, where 2000 steps alone is off by", pair - limit,
    f"   (2000 steps: {priced[2000] - limit:+.6f})")
straddle = sum(1 for n in range(10, 41)
               if (tree(n) - limit) * (tree(n + 1) - limit) < 0.0)
print(f"{'consecutive step counts on opposite sides, 10 to 41':<46}{straddle:>11d} of 31")
for n in (10, 2000):
    drift, spread = moments(n)
    p_drift, p_spread = predicted(n)
    row(f"one step log drift / dt, {n} steps", drift, f"   predicted {p_drift:.6f}")
    row(f"one step spread / (sigma^2 dt), {n} steps", spread, f"   predicted {p_spread:.6f}")
print()
row("wrong: dividend left out of p, 2000 steps", tree(2000, div=False))
row("wrong: jump sigma*dt, not sigma*sqrt(dt)", tree(2000, root=False))
row("wrong: a fair coin, p = 0.5, 2000 steps", tree(2000, coin=0.5))
row("wrong: stopping at 10 steps, calling it done", priced[10])
thin = 0.02                                    # a share that hardly moves at all
bad_p = (exp((R - Q) * T) - exp(-thin)) / (exp(thin) - exp(-thin))
row("wrong: sigma 2% on a year-long step, p =", bad_p)
assert bad_p > 1.0                             # too few steps and p stops being a weight
assert gap < 1e-9                              # recursion vs one weighted sum
assert abs(limit - HOUSE) < 1e-9               # own formula vs the house price
assert abs(slices - limit) < 1e-7              # brute-force average vs formula
assert abs(mean_2000 - forward) < 1e-9         # the tree's average end price is the forward
assert abs(priced[2000] - limit) < 1e-3        # 2000 steps, inside a tenth of a cent
assert abs(priced[2000] - limit) < abs(priced[250] - limit) < abs(priced[10] - limit)
assert straddle == 31                          # every consecutive pair straddles
assert abs(pair - limit) < 0.05 * abs(priced[2000] - limit)
assert all(abs(moments(n)[0] - predicted(n)[0]) < 1e-3 * T / n for n in (10, 250, 2000))
assert all(abs(moments(n)[1] - predicted(n)[1]) < 1e-3 * T / n for n in (10, 250, 2000))
print("ALL CHECKS PASS")
